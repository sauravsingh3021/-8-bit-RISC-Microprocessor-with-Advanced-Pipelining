module Pipelined_Processor (
    input clk,
    input reset
);

// Instruction Memory (16 x 8)
reg [7:0] instruction_memory [0:15];
reg [7:0] instruction;  // Current instruction in IF stage

// Data Memory (16 x 8)
reg [7:0] data_memory [0:15];

// Register Bank (4 registers, each 8 bits)
reg [7:0] register_bank [0:3];

// Pipeline registers
reg [7:0] IF_ID_IR;  // Instruction Register between IF and ID stages
reg [7:0] ID_EX_A, ID_EX_B;  // Operands between ID and EX stages
reg [1:0] ID_EX_rd;  // Destination register between ID and EX stages
reg [3:0] ID_EX_opcode;  // Opcode between ID and EX stages
reg [7:0] EX_MEM_ALUOut;  // ALU output between EX and MEM stages
reg [1:0] EX_MEM_rd;  // Destination register between EX and MEM stages
reg [7:0] MEM_WB_LMD;  // Loaded data between MEM and WB stages
reg [7:0] MEM_WB_ALUOut;  // ALU output between MEM and WB stages
reg [1:0] MEM_WB_rd;  // Destination register between MEM and WB stages
reg MEM_WB_memToReg;  // Control signal for write-back MUX

// Control signals (simplified)
reg memRead, memWrite, regWrite, memToReg;

// Program counter
reg [3:0] pc;  // Limited to 16 addresses

// Forwarding operands
reg [7:0] operandA, operandB;

// Branch control
wire isBranch = (IF_ID_IR[7:4] == 4'b1101);  // Example opcode for jump
reg branch_taken;
reg [3:0] branch_target;

// Instruction Fetch (IF) stage
always @(posedge clk or posedge reset) begin
    if (reset) begin
        pc <= 4'b0000;
        IF_ID_IR <= 8'b00000000;
    end else if (branch_taken) begin
        pc <= branch_target;
        IF_ID_IR <= 8'b00000000; // flush
    end else begin
        IF_ID_IR <= instruction_memory[pc];
        pc <= pc + 1;
    end
end

// Instruction Decode (ID) stage
always @(posedge clk) begin
    ID_EX_B <= register_bank[IF_ID_IR[1:0]];
    ID_EX_A <= register_bank[IF_ID_IR[3:2]];
    ID_EX_rd <= IF_ID_IR[3:2];
    ID_EX_opcode <= IF_ID_IR[7:4];

    case (IF_ID_IR[7:4])
        4'b0000, 4'b0001, 4'b0010, 4'b0011, 4'b0100, 4'b0101, 4'b0110, 4'b0111, 4'b1000, 4'b1001, 4'b1010, 4'b1011, 4'b1100, 4'b1111: begin
            regWrite <= 1;
        end
        4'b1101: begin
            regWrite <= 1;
        end
        default: begin
            regWrite <= 0;
        end
    endcase
end

// Execution (EX) stage
reg [7:0] ALU_result;
always @(*) begin
    operandA = ID_EX_A;
    operandB = ID_EX_B;

    // Forwarding from MEM stage
    if (EX_MEM_rd == ID_EX_rd && regWrite) operandA = EX_MEM_ALUOut;
    if (EX_MEM_rd == IF_ID_IR[1:0] && regWrite) operandB = EX_MEM_ALUOut;

    // Forwarding from WB stage
    if (MEM_WB_rd == ID_EX_rd && regWrite) operandA = (MEM_WB_memToReg) ? MEM_WB_LMD : MEM_WB_ALUOut;
    if (MEM_WB_rd == IF_ID_IR[1:0] && regWrite) operandB = (MEM_WB_memToReg) ? MEM_WB_LMD : MEM_WB_ALUOut;
end

always @(posedge clk) begin
    case (ID_EX_opcode)
        4'b0000: ALU_result = operandA + operandB;
        4'b0001: ALU_result = operandA - operandB;
        4'b0010: ALU_result = operandA * operandB;
        4'b0011: ALU_result = operandA / operandB;
        4'b0100: ALU_result = operandA % operandB;
        4'b0101: ALU_result = operandA & operandB;
        4'b0110: ALU_result = operandA | operandB;
        4'b0111: ALU_result = operandA ^ operandB;
        4'b1000: ALU_result = ~operandA;
        4'b1001: ALU_result = (operandA == operandB) ? 8'b1 : 8'b0;
        4'b1010: ALU_result = operandA + 1;
        4'b1011: ALU_result = operandA - 1;
        4'b1100: ALU_result = operandA ** operandB;
        4'b1101: begin
            memRead = 1;
            ALU_result = operandA;
            branch_taken = 1;
            branch_target = operandB[3:0];
        end
        4'b1110: begin
            memWrite = 1;
            ALU_result = operandA;
        end
        4'b1111: ALU_result = operandA << operandB;
        default: ALU_result = 8'b0;
    endcase
    EX_MEM_ALUOut <= ALU_result;
    EX_MEM_rd <= ID_EX_rd;
end

// Memory (MEM) stage
always @(posedge clk) begin
    if (memRead) begin
        MEM_WB_LMD <= data_memory[EX_MEM_ALUOut];
        MEM_WB_memToReg <= 1;
        memRead <= 0;
    end else if (memWrite) begin
        data_memory[EX_MEM_ALUOut] <= operandB;
        memWrite <= 0;
    end else begin
        MEM_WB_memToReg <= 0;
    end
    MEM_WB_ALUOut <= EX_MEM_ALUOut;
    MEM_WB_rd <= EX_MEM_rd;
end

// Write Back (WB) stage
always @(posedge clk) begin
    if (regWrite) begin
        if (MEM_WB_memToReg) begin
            register_bank[MEM_WB_rd] <= MEM_WB_LMD;
        end else begin
            register_bank[MEM_WB_rd] <= MEM_WB_ALUOut;
        end
    end
end

// Initialize memories
initial begin
    instruction_memory[0] = 8'b00000001;  
    instruction_memory[1] = 8'b00010001;  
    instruction_memory[2] = 8'b00101011;  
    instruction_memory[3] = 8'b00111001;
    instruction_memory[4] = 8'b01001011;  
    instruction_memory[5] = 8'b01111001;  
    instruction_memory[6] = 8'b01101011;  
    instruction_memory[7] = 8'b01111001;
    instruction_memory[8] = 8'b10001011;  
    instruction_memory[9] = 8'b10111001;  
    instruction_memory[10] = 8'b10101011;  
    instruction_memory[11] = 8'b10111001;
    instruction_memory[12] = 8'b11001011;  
    instruction_memory[13] = 8'b11011001;  
    instruction_memory[14] = 8'b11101011;  
    instruction_memory[15] = 8'b11111001;

    data_memory[0] = 8'h00;
    data_memory[1] = 8'h01;

    register_bank[0] = 8'h05;
    register_bank[1] = 8'h03;
    register_bank[2] = 8'h07;
    register_bank[3] = 8'h0F;
end

endmodule
`timescale 1ns/1ps

module processor_tb;
    reg clk;
    reg reset;

    // Performance metrics
    integer cycle_count = 0;
    integer instr_count = 0;
    integer stall_count = 0;
    reg [3:0] prev_pc;

    // Instantiate the processor module
    Pipelined_Processor uut (
        .clk(clk),
        .reset(reset)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;  // 10 time units period
    end

    // Reset and simulation control
    initial begin
        reset = 1;
        #10 reset = 0;
        #300
        $display("\n======== Performance Metrics ========");
        $display("Total Cycles        : %0d", cycle_count);
        $display("Instructions Retired: %0d", instr_count);
        $display("IPC (Instr/Cycle)   : %0f", instr_count * 1.0 / cycle_count);
        $display("CPI (Cycle/Instr)   : %0f", cycle_count * 1.0 / instr_count);
        $display("Total Stalls        : %0d", stall_count);
        $finish;
    end

    // Cycle, instruction, stall monitoring
    always @(posedge clk) begin
        cycle_count = cycle_count + 1;

        // Count instruction if write-back is enabled
        if (uut.regWrite)
            instr_count = instr_count + 1;

        // Stall detection if PC does not increment (excluding reset)
        if (reset == 0 && uut.pc == prev_pc)
            stall_count = stall_count + 1;

        prev_pc = uut.pc;

        // Print registers and PC every cycle
        $display("Time: %0t | PC: %0d", $time, uut.pc);
        $display("Registers: R0=%d | R1=%d | R2=%d | R3=%d", 
                 uut.register_bank[0], 
                 uut.register_bank[1], 
                 uut.register_bank[2], 
                 uut.register_bank[3]);
        $display("------------------------------------------------");
    end
endmodule
