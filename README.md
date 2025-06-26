# 8-bit RISC Microprocessor with Advanced Pipelining
---
- Designed and implemented an 8-bit RISC processor with a custom 16-instruction set architecture to enhance performance.  
- Developed a 5-stage pipeline (Fetch, Decode, Execute, Memory, Writeback) for efficient parallel processing and reduced cycle time.  
- Implemented hazard detection and mitigation techniques, including data forwarding, stalling, and branch prediction, to resolve data and control hazards.  
- Optimized processor performance by minimizing instruction cycle time and improving throughput.  
- Exposure to Verilog, Xilinx Vivado, FPGA (Nexys 4 DDR), Microprocessor Design, Instruction Pipelining, and Hazard Handling.  


## Overview

This project implements an **8-bit RISC microprocessor** with a custom 16-instruction set architecture (ISA) using Verilog. The processor features a **5-stage pipeline** architecture designed to improve instruction throughput and minimize execution latency. It also includes advanced hazard handling techniques such as **data forwarding**, **stalling**, and **branch control** to mitigate data and control hazards efficiently.

## Pipeline Stages

The processor operates in the following pipeline stages:

1. **Instruction Fetch (IF):** Fetches the instruction from instruction memory.
2. **Instruction Decode (ID):** Decodes the instruction and reads operands from the register bank.
3. **Execution (EX):** Performs arithmetic and logical operations using an ALU.
4. **Memory (MEM):** Handles memory access operations (load/store).
5. **Write Back (WB):** Writes results back to the register file.

## Features

- Custom 16-instruction set (e.g., add, sub, mul, div, and, or, xor, load, store, branch).
- 5-stage pipelined architecture for efficient instruction execution.
- 4 general-purpose 8-bit registers.
- 16-byte instruction and data memory.
- Data forwarding to reduce pipeline stalls.
- Basic branch control and flushing on branch taken.
- Performance metrics tracking: IPC, CPI, cycle count, stall count.
- Testbench to simulate and monitor processor behavior.

Instruction Format
Each 8-bit instruction is formatted as:

less
Copy
Edit
[7:4] Opcode | [3:2] Destination Register | [1:0] Source Register
Supported Opcodes
Opcode	Operation	Description
0000	ADD	Add two registers
0001	SUB	Subtract
0010	MUL	Multiply
0011	DIV	Divide
0100	MOD	Modulus
0101	AND	Bitwise AND
0110	OR	Bitwise OR
0111	XOR	Bitwise XOR
1000	NOT	Bitwise NOT (unary)
1001	EQ	Equality check
1010	INC	Increment
1011	DEC	Decrement
1100	POW	Exponentiation
1101	JUMP	Branch/Jump to target
1110	STORE	Store to data memory
1111	SHL	Shift left

Performance Metrics
During simulation, the following metrics are tracked and printed:

Total Cycles

Instructions Retired

IPC (Instructions Per Cycle)

CPI (Cycles Per Instruction)

Total Stalls

Simulation Output Example
yaml
Copy
Edit
Time: 50 | PC: 3
Registers: R0=10 | R1=7 | R2=15 | R3=1
------------------------------------------------
...
======== Performance Metrics ========
Total Cycles        : 50
Instructions Retired: 10
IPC (Instr/Cycle)   : 0.20
CPI (Cycle/Instr)   : 5.00
Total Stalls        : 5
Tools & Technologies
Language: Verilog

Simulation Tool: ModelSim / Icarus Verilog / Vivado

Target Platform: FPGA (e.g., Nexys 4 DDR)

Concepts: Microprocessor Design, Instruction Pipelining, Hazard Handling, Performance Optimization

