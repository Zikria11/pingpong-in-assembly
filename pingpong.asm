; ------------------------------------------------------------
; Tiny Pong (boot sector, 16-bit real mode, text mode 80x25)
; - Uses BIOS timer ticks (INT 1Ah) to cap speed (~18.2 FPS)
; - Fixes paddle drawing (center + neighbors) on both sides
; - Fixes AI compare logic
; ------------------------------------------------------------

[org 0x7C00]
bits 16

cli
xor ax, ax
mov ds, ax
mov es, ax
mov ss, ax
mov sp, 0x7C00
sti


; Video init: mode 3, hide cursor, clear screen

mov ax, 0x0003
int 0x10

mov ax, 0x0100            ; hide cursor
mov cx, 0x2000
int 0x10

mov ax, 0x0600            ; clear full screen once
mov bh, 0x07
xor cx, cx
mov dx, 0x184F
int 0x10

mov ax, 0xB800
mov es, ax

; Constants

ATTR        equ 0x0F
LEFT_X      equ 2
RIGHT_X     equ 77
TOP_PLAY    equ 1
BOT_PLAY    equ 23
PADDLE_MIN  equ 2
PADDLE_MAX  equ 22
MID_X       equ 40
MID_Y       equ 12

TICKS_PER_FRAME equ 1      ; 1 tick ≈ 55 ms → ~18 FPS. Increase to slow down.

; Init state

mov byte [lp_y],    MID_Y
mov byte [rp_y],    MID_Y
mov byte [ball_x],  MID_X
mov byte [ball_y],  MID_Y
mov byte [ball_dx], 1
mov byte [ball_dy], 1

; Main loop 


main_loop:
    call clear_frame

    ; ---- Draw paddles and ball ----
    mov bh, ATTR

    ; LEFT PADDLE (x=LEFT_X), 3 cells centered at lp_y
    mov dl, LEFT_X
    mov al, '|'                   ; paddle char
    mov bl, [lp_y]                ; center Y in BL

    mov dh, bl
    dec dh
    call plot                     ; y = center-1

    mov dh, bl
    call plot                     ; y = center

    mov dh, bl
    inc dh
    call plot                     ; y = center+1

    ; RIGHT PADDLE (x=RIGHT_X), 3 cells centered at rp_y
    mov dl, RIGHT_X
    mov bl, [rp_y]

    mov dh, bl
    dec dh
    call plot

    mov dh, bl
    call plot

    mov dh, bl
    inc dh
    call plot

    ; BALL
    mov al, 'o'
    mov dl, [ball_x]
    mov dh, [ball_y]
    call plot

    ; ---- Input (non-blocking) ----
    mov ah, 0x01
    int 0x16
    jz .no_key
    xor ah, ah
    int 0x16
    cmp al, 27
    je reboot
    cmp al, 'w'
    je .up
    cmp al, 'W'
    je .up
    cmp al, 's'
    je .down
    cmp al, 'S'
    je .down
    jmp .no_key

.up:
    mov al, [lp_y]
    cmp al, PADDLE_MIN
    jbe .no_key
    dec byte [lp_y]
    jmp .no_key

.down:
    mov al, [lp_y]
    cmp al, PADDLE_MAX
    jae .no_key
    inc byte [lp_y]

.no_key:
    ; ---- Simple AI: follow ball Y with clamp ----
    mov al, [rp_y]
    mov bl, [ball_y]
    cmp al, bl
    je .ai_done
    jb .ai_dn                      ; if rp_y < ball_y -> move down
    ; move up
    cmp al, PADDLE_MIN
    jbe .ai_done
    dec byte [rp_y]
    jmp .ai_done

.ai_dn:
    cmp al, PADDLE_MAX
    jae .ai_done
    inc byte [rp_y]

.ai_done:
    ; ---- Physics: x += dx, y += dy ----
    mov al, [ball_x]
    mov bl, [ball_dx]
    add al, bl
    mov [ball_x], al

    mov al, [ball_y]
    mov bl, [ball_dy]
    add al, bl
    mov [ball_y], al

    ; ---- Bounce off top/bottom (1..23) ----
    mov al, [ball_y]
    cmp al, TOP_PLAY
    jb .flip_dy
    cmp al, BOT_PLAY
    ja .flip_dy
    jmp .walls_done

.flip_dy:
    mov al, [ball_dy]
    neg al
    mov [ball_dy], al

.walls_done:
    ; ---- Paddle collisions ----
    ; LEFT: if x == LEFT_X+1 && dx<0 && y in [lp_y-1 .. lp_y+1] -> dx=+1
    mov al, [ball_x]
    cmp al, LEFT_X+1
    jne .check_right
    mov al, [ball_dx]
    cmp al, 0
    jge .check_right
    mov bl, [ball_y]
    mov al, [lp_y]
    dec al
    cmp bl, al
    jb .check_right
    mov al, [lp_y]
    inc al
    cmp bl, al
    ja .check_right
    mov byte [ball_dx], 1
    jmp .after_pads

.check_right:
    ; RIGHT: if x == RIGHT_X-1 && dx>0 && y in [rp_y-1 .. rp_y+1] -> dx=-1
    mov al, [ball_x]
    cmp al, RIGHT_X-1
    jne .after_pads
    mov al, [ball_dx]
    cmp al, 0
    jle .after_pads
    mov bl, [ball_y]
    mov al, [rp_y]
    dec al
    cmp bl, al
    jb .after_pads
    mov al, [rp_y]
    inc al
    cmp bl, al
    ja .after_pads
    mov byte [ball_dx], -1

.after_pads:
    ; ---- Out of bounds -> reset to center, reverse serve ----
    mov al, [ball_x]
    cmp al, 1
    jb .reset
    cmp al, 78
    ja .reset
    jmp .frame_delay

.reset:
    mov byte [ball_x], MID_X
    mov byte [ball_y], MID_Y
    mov al, [ball_dx]
    neg al
    mov [ball_dx], al

; Frame timing: wait TICKS_PER_FRAME BIOS ticks (~55ms each)
.frame_delay:
    mov cl, TICKS_PER_FRAME
.wait_loop:
    call wait_tick
    dec cl
    jnz .wait_loop

    jmp main_loop

; Subroutines

; Clear full screen (BIOS scroll)
clear_frame:
    push ax
    push bx
    push cx
    push dx
    mov ax, 0x0600
    mov bh, 0x07
    xor cx, cx
    mov dx, 0x184F
    int 0x10
    pop dx
    pop cx
    pop bx
    pop ax
    ret

; Plot:
;  IN: AL=char, BH=attr, DL=x (0..79), DH=y (0..24), ES=B800h
plot:
    push ax
    push bx
    push dx
    ; offset = (y*80 + x) * 2 -> DI
    mov al, dh
    xor ah, ah
    mov bl, 80
    mul bl
    mov bl, dl
    xor bh, bh
    add ax, bx
    shl ax, 1
    mov di, ax
    pop dx
    pop bx
    pop ax
    mov ah, bh
    stosw
    ret

; Wait for one BIOS timer tick (~55ms)
; Uses INT 1Ah, AH=00h (get ticks), waits until DX changes.
wait_tick:
    push ax
    push bx
    push cx
    push dx
    mov ah, 0
    int 1Ah              ; CX:DX = ticks since midnight
    mov bx, dx
.wt_loop:
    mov ah, 0
    int 1Ah
    cmp dx, bx
    je .wt_loop
    pop dx
    pop cx
    pop bx
    pop ax
    ret

; Reboot (Esc key)
reboot:
    int 0x19
    hlt


; Data

lp_y    db 0
rp_y    db 0
ball_x  db 0
ball_y  db 0
ball_dx db 0
ball_dy db 0


; Boot signature

times 510-($-$$) db 0
dw 0xAA55
