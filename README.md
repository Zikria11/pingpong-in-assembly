# Ping Pong Game in Assembly


## 1. Introduction

Boot Sector Pong is a minimalistic implementation of the classic Pong game, written entirely in x86 Assembly to fit within a single 512-byte boot sector. This project demonstrates the feasibility of creating an interactive game that runs directly on hardware in 16-bit Real Mode, without requiring an operating system. The game leverages BIOS interrupts for input, output, and timing, delivering a nostalgic yet functional gaming experience using ASCII characters in text mode.

This project showcases low-level programming techniques, efficient memory management, and direct hardware interaction, making it an excellent educational tool for understanding computer architecture and assembly programming.

## 2. Project Objectives
The primary objectives of this project are:
- To develop a fully functional Pong clone that operates within the constraints of a 512-byte boot sector.
- To implement classic Pong gameplay with player and AI-controlled paddles, ball movement, and collision detection.
- To utilize BIOS interrupts for video rendering, keyboard input, and frame rate control.
- To ensure smooth gameplay by capping the frame rate at approximately 18 FPS using BIOS timer ticks.
- To create a bootable program that runs on real hardware or emulators like QEMU, Bochs, or VirtualBox.

## 3. System Design
### 3.1. Architecture

The game operates in 16-bit Real Mode, a legacy mode of x86 processors, allowing direct access to hardware resources via BIOS interrupts. The entire program, including code and data, is constrained to 512 bytes, the size of a single boot sector, and includes the mandatory 0xAA55 boot signature.
### 3.2. Components
- **Paddle:** Two paddles are implemented:

     - **Left Paddle:**  Controlled by the player using W (up) and S (down) keys.

     - **Right Paddle:** Controlled by a simple AI that tracks the ball's vertical position.

- **Ball:** A single character that moves across the screen, bouncing off paddles and top/bottom walls. If the ball goes out of bounds, it resets to the center with reversed direction.

- **Rendering:** Uses 80x25 text mode (BIOS video mode 3) with direct writes to video memory at 0xB800:0000.

- **Input Handling:** Uses INT 16h for non-blocking keyboard input to detect W, S, and Esc keys.

- **Timing:** Frame rate is capped using INT 1Ah (BIOS timer) to achieve approximately 18 FPS (~55ms per frame).

- **Game Logic:** Handles paddle movement, ball physics, collision detection, and game state resets.

### 3.3. Memory Layout

- **Code Section:** Contains the game loop, input handling, and rendering logic.

- **Data Section:** Stores paddle positions, ball coordinates, and velocity.

- **Stack:** Minimal stack usage for BIOS interrupt calls.

- **Video Memory:** Directly manipulated at 0xB800:0000 for rendering ASCII characters.

## 4. Implementation Details

### 4.1. Tools and Environment
- **Assembler:** NASM (Netwide Assembler) for compiling the x86 Assembly code.

- **Output Format:** Binary (-f bin) to produce a raw 512-byte bootable image.

- **Testing Environment:** QEMU emulator (qemu-system-i386) for development and testing, with compatibility for Bochs and VirtualBox.

- **Hardware Requirements:** Any x86-compatible system or emulator supporting boot sector execution.

### 4.2. BIOS Interrupts

The game relies on the following BIOS interrupts:

- **INT 10h:** Sets video mode (80x25 text mode) and updates the screen cursor.

- **INT 16h:** Reads keyboard input for paddle control (W, S, Esc).

- **INT 1Ah:** Retrieves system timer ticks for frame rate regulation.

### 4.3. Gameplay Mechanics
#### Paddle Movement:

- Left paddle moves vertically within screen bounds based on W/S key presses.

- Right paddle follows the ball’s Y-coordinate with a simple AI algorithm.

#### Ball Movement:

- The ball moves diagonally with a fixed velocity, updated every frame.

- Collision detection checks for paddle and wall hits, reversing the ball’s direction as needed.

- Out-of-bounds detection resets the ball to the center with reversed horizontal velocity.

#### Rendering:

- ASCII characters are used: | for paddles, O for the ball, and spaces for the background.

- The screen is cleared and redrawn each frame by writing to video memory.

### 4.4. Constraints
- Size Limit: The entire program, including code, data, and boot signature, must fit within 512 bytes.

- Performance: Frame rate is limited by BIOS timer ticks, ensuring smooth gameplay without overwhelming the CPU.

- Input: Limited to keyboard input due to boot sector constraints, with no support for mouse or advanced peripherals.

## 5. Build and Run Instructions

### 5.1. Prerequisites

- Install NASM: sudo apt-get install nasm (Linux) or equivalent for your OS.

- Install QEMU: sudo apt-get install qemu-system-x86 (Linux) or equivalent.

### 5.2. Build Process

- Save the source code as pong.asm.
- Compile using NASM:

```bash
nasm -f bin pong.asm -o pong.bin
```
- Verify the output file (pong.bin) is exactly 512 bytes.

## 6. Challenges and Solutions

- **Challenge:** Fitting all game logic within 512 bytes.

    - **Solution:** Optimized assembly code with minimal instructions, reused registers, and avoided redundant operations.

- **Challenge:** Smooth frame rate in a boot sector environment.
     - **Solution:** Used INT 1Ah to synchronize game updates with BIOS timer ticks (~18.2 Hz).
- **Challenge:** Implementing AI for the right paddle in limited space.
   - **Solution:** Simplified AI to track the ball’s Y-coordinate, requiring minimal code.
- **Challenge:** Handling keyboard input without an OS.
    - **Solution:** Used INT 16h for non-blocking input, checking for specific keys (W, S, Esc).
## 7. Future Improvements
To enhance Boot Sector Pong, the following features could be implemented:

- **Score Counter:** Track and display player and AI scores.
- **Improved AI:** Introduce difficulty levels by adjusting AI reaction speed or accuracy.
- **Sound Effects:** Add beeps via the PC speaker for ball hits and out-of-bounds events.
- **Two-Player Mode:** Allow right paddle control using arrow keys for multiplayer gameplay.
- **Graphical Mode:** Transition to a graphical video mode (e.g., 320x200 VGA) for enhanced visuals, though this may exceed boot sector constraints.


## 8. Author

### Zikria Akhtar
