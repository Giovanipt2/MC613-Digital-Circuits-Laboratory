# MC613-Digital-Circuits-Laboratory
This repository showcases all the laboratory assignments developed during the MC613 - Laboratório de Circuitos Digitais course at Unicamp. It reflects our understanding of digital design methodologies, programmable logic techniques, and hardware description using VHDL. The goal is to demonstrate the practical application of these concepts through the completed lab work.

## 🔬 Labs Overview
### 🧪 Lab 1: Combinational Logic Basics
This lab introduces fundamental combinational logic circuits. It includes projects such as a keypad decoder (`key2dec.vhd`), an LED shifter (`ledshift.vhd`), and a simple XOR gate implementation using switches (`swxor.vhd`).
### 🧮 Lab 2: Arithmetic Logic Unit (ALU)
Focuses on designing and implementing an Arithmetic Logic Unit (ALU). This lab explores how different arithmetic and logical operations are performed in a digital system (`alu.vhd`). It also includes displaying results on a 7-segment display (`two_comp_to_7seg.vhd`).
### 🔄 Lab 3: Finite State Machines (FSM)
This lab deals with the design and implementation of Finite State Machines (FSMs). It involves creating a specific FSM (`fsm.vhd`) and interfacing it with the development board.
### ✖️ Lab 4: Multiplier Design
Covers the design of a digital multiplier (`multiplier.vhd`). This lab explores the process of multiplying binary numbers and includes displaying the unsigned result on a 7-segment display (`unsigned_to_7seg.vhd`).
### ⏱️ Lab 5: Stopwatch
Involves designing a stopwatch (`stopwatch.vhd`). This project includes handling time (`time.vhd`), clock signals (`clock.vhd`), and displaying time on 7-segment displays (`unsigned_to_7seg.vhd`).
### 📡 Lab 6: UART Communication
Focuses on implementing a Universal Asynchronous Receiver/Transmitter (UART) for serial communication (`uart.vhd`). This lab is crucial for enabling data exchange between the digital circuit and external devices.
### 💾 Lab 7: Cache Memory Systems
Explores the concepts of cache memory. This lab involves designing and simulating a cache system, including inner cache (`inner_cache.vhd`) and outer cache (`outer_cache.vhd`) components, to understand memory hierarchy.

## 📁 Repository Structure
Each lab within this repository is organized into its own directory (e.g., `Lab1/`, `Lab2/`, etc.). Inside each lab directory, you will typically find:
*   **VHDL Source Files (`.vhd`):** These are the core design files for the digital circuits.
*   **Testbenches (`_tb.vhd`):** VHDL files used for simulating and verifying the functionality of the designs.
*   **PDF Documents (`.pdf`):** These often contain lab guides, diagrams, or theoretical explanations related to the lab exercises.
This structure is intended to keep the resources for each lab self-contained and easy to navigate.

## 📚 Key Topics Covered
- 💡 Combinational Logic Design: Decoders, multiplexers, arithmetic circuits.
- 🔄 Sequential Logic Design: Flip-flops, counters, state machines.
- 💾 Memory Systems: Design and implementation of memory components.
- ✍️ VHDL Modeling: Hardware description and simulation.
