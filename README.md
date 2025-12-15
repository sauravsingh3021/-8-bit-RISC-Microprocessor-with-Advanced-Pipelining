# 8-bit RISC Processor with 5-Stage Pipelining

## Overview
This project implements an **8-bit pipelined RISC processor** using **Verilog HDL**, designed to demonstrate core concepts of **computer architecture, pipelining, and hazard management**. The processor supports a **custom 16-instruction ISA** and is verified through simulation using a comprehensive testbench.

---

## Features
- **5-Stage Pipeline Architecture**
  - Instruction Fetch (IF)
  - Instruction Decode (ID)
  - Execute (EX)
  - Memory Access (MEM)
  - Write Back (WB)

- **Custom 8-bit ISA (16 Instructions)**
  - Arithmetic & Logic: ADD, SUB, AND, OR, XOR, ADDI, SLT, SLL
  - Memory Operations: LOAD, STORE, LOADB, STOREB
  - Control Flow: BEQ, BNE, JUMP
  - NOP

- **Hazard Handling**
  - Data hazard resolution using **EX/MEM and MEM/WB forwarding**
  - **Load-use hazard detection** with pipeline stalling
  - **Control hazard handling** via branch detection and pipeline flushing

- **Performance Measurement**
  - Cycle count
  - Instruction count
  - IPC (Instructions Per Cycle)
  - Stall count

- **Verification**
  - Directed testbench executing all ISA instructions
  - Waveform generation (VCD) for debugging
  - Watchdog timer to prevent deadlock during simulation

---

## Architecture Overview
- 8-bit Program Counter
- 4-entry general-purpose register file
- Instruction and data memory (256 bytes each)
- Fully synchronous pipeline registers between stages
- PC-relative branching and jumping

---

## Pipeline Stages

| Stage | Description |
|-----|------------|
| IF  | Fetch instruction and update PC |
| ID  | Decode instruction and read registers |
| EX  | Perform ALU operations and branch evaluation |
| MEM | Access data memory for load/store |
| WB  | Write results back to register file |

---

## Hazard Management
- **Data Hazards:** Resolved using forwarding paths from EX/MEM and MEM/WB stages
- **Load-Use Hazards:** Detected in decode stage and handled with pipeline stall
- **Control Hazards:** Branch decisions made in EX stage with pipeline flush on taken branch

---

## Simulation & Testing
- Simulated using **EDA Playground**
- Includes waveform dumping (`dump.vcd`)
- Testbench tracks:
  - Total cycles
  - Instructions executed
  - IPC
  - Number of stalls

---

## How to Run
1. Load `RISC8_Pipelined.v` and `tb_RISC8.v` into your Verilog simulator
2. Run simulation
3. View waveforms using a VCD viewer (GTKWave)
4. Observe console output for performance metrics

---

## Technologies Used
- Verilog HDL
- RTL Design
- Computer Architecture
- Digital Design Verification
- EDA Playground

---

## Future Improvements
- True byte-level LOADB/STOREB implementation
- Branch prediction (static or dynamic)
- Pipeline bypass optimization
- Parameterized data width and register file size

---

## Author
[Saurav Singh]
