# Basys3 FPGA Digital Clock & Stopwatch

## Project Overview
This repository contains a VHDL-based Digital Clock and Stopwatch designed for the Digilent Basys 3 FPGA development board . The core of this system is a custom Finite State Machine (FSM) that reliably handles user inputs for setting the time, toggling display modes, and controlling a stopwatch, all multiplexed onto a 4-digit 7-segment display.

## Hardware & Software Configuration
* **Board:** Digilent Basys 3 (Artix-7 FPGA)
* **Development Environment:** Xilinx Vivado
* **Clock:** 100 MHz internal oscillator
* **Inputs:** 5 Push Buttons (`btnC`, `btnU`, `btnL`, `btnR`, `btnD`) and 1 Slide Switch (`SW0`)
* **Outputs:** 4-digit 7-segment display (`an`, `seg`, `dp`)

## Deep Dive: The Finite State Machine (FSM) Architecture
The system logic is strictly governed by a centralized FSM, which splits the application into two primary operating modes based on the position of switch `SW0`.

### Global Controls
* **Initialization/Reset:** Pressing `btnC` triggers a global reset (`r`), returning the system to its baseline state regardless of the current mode.
* **Mode Switch:** Toggling `sw 0` routes the FSM either to the Clock branch (off) or the Stopwatch branch (on).

### Branch 1: Clock Mode (`sw 0` OFF)
This branch handles timekeeping and time configuration.
* **State: `DISPLAY CLOCK TIME`**
  * The default state. It actively displays the time.
  * Pressing `btnD` triggers a secondary view, toggling the display from `hh:mm` to `00:ss` (seconds view).
  * Pressing `btnL` advances the FSM to the configuration states.
* **State: `SET HOUR`**
  * The user can increment the current hour by pressing `btnR`.
  * Pressing `btnL` locks the hour and advances the FSM to the minutes configuration.
* **State: `SET MINUTES`**
  * The user can increment the current minutes by pressing `btnR` again.
  * Pressing `btnL` saves the complete time and returns the FSM safely to the `DISPLAY CLOCK TIME` state.

### Branch 2: Stopwatch Mode (`sw 0` ON)
This branch acts independently to provide precision timing.
* **State: `IDLE STOPWATCH STATE`**
  * The stopwatch is at zero and waiting for user input. A reset (`btnC`) will ensure it is cleared.
  * Pressing `btnU` transitions the system to the active counting state.
* **State: `START STOPWATCH`**
  * The timer actively increments. 
  * Pressing `btnU` intercepts the counting and forces the FSM into the paused state.
* **State: `PAUSE`**
  * The current elapsed time is frozen on the display.
  * Pressing `btnU` resumes the timer, sending the FSM back to the `START STOPWATCH` state.
