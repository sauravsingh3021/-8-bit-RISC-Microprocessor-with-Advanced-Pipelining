`timescale 1ns/1ps

module tb_RISC8;

    // -------------------------------------------------
    // CLOCK / RESET
    // -------------------------------------------------
    reg clk, reset;

    // -------------------------------------------------
    // PERFORMANCE METRICS
    // -------------------------------------------------
    integer cycle_count = 0;
    integer instr_count = 0;   // ISA-level instruction count
    integer stall_count = 0;
    reg [7:0] prev_pc;

    // Watchdog (industry practice)
    parameter MAX_CYCLES = 200;

    // -------------------------------------------------
    // DUT
    // -------------------------------------------------
    RISC8_Pipelined dut (
        .clk   (clk),
        .reset (reset)
    );

    // -------------------------------------------------
    // CLOCK (10 ns)
    // -------------------------------------------------
    always #5 clk = ~clk;

    // -------------------------------------------------
    // RESET
    // -------------------------------------------------
    initial begin
        clk = 0;
        reset = 1;
        #10 reset = 0;
    end

    // -------------------------------------------------
    // WAVEFORM DUMP
    // -------------------------------------------------
    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, tb_RISC8);
    end

    // -------------------------------------------------
    // TEST PROGRAM (ALL 16 OPCODES)
    // -------------------------------------------------
    initial begin
        // Initial regfile from DUT:
        // R0 = 0, R1 = 5, R2 = 3, R3 = 0

        // -------- ALU --------
        dut.instr_mem[0]  = 8'b0000_00_01; // ADD
        dut.instr_mem[1]  = 8'b0001_10_01; // SUB
        dut.instr_mem[2]  = 8'b0010_11_01; // AND
        dut.instr_mem[3]  = 8'b0011_11_01; // OR
        dut.instr_mem[4]  = 8'b0100_00_01; // XOR
        dut.instr_mem[5]  = 8'b0101_00_01; // ADDI
        dut.instr_mem[6]  = 8'b0110_11_01; // SLT
        dut.instr_mem[7]  = 8'b0111_11_01; // SLL

        // -------- MEMORY --------
        dut.instr_mem[8]  = 8'b1001_00_11; // STORE
        dut.instr_mem[9]  = 8'b1000_01_00; // LOAD
        dut.instr_mem[10] = 8'b1010_10_00; // LOADB (alias)
        dut.instr_mem[11] = 8'b1011_00_10; // STOREB (alias)

        // -------- CONTROL --------
        dut.instr_mem[12] = 8'b1100_01_10; // BEQ (not taken)
        dut.instr_mem[13] = 8'b1111_00_00; // NOP
        dut.instr_mem[14] = 8'b1101_01_01; // BNE (not taken)
        dut.instr_mem[15] = 8'b1110_00_01; // JUMP +1

        // -------- FINAL --------
        dut.instr_mem[16] = 8'b0000_00_00; // ADD
    end

    // -------------------------------------------------
    // MONITOR + METRICS
    // -------------------------------------------------
    always @(posedge clk) begin
        cycle_count++;

        // ISA-level instruction count (fetch based)
        if (!reset)
            instr_count++;

        // Stall detection using PC hold
        if (!reset && dut.PC == prev_pc)
            stall_count++;

        prev_pc = dut.PC;

        // Per-cycle visibility
        $display("C%0d | PC=%0d | R0=%0d R1=%0d R2=%0d R3=%0d",
                 cycle_count, dut.PC,
                 dut.regfile[0], dut.regfile[1],
                 dut.regfile[2], dut.regfile[3]);

        // Normal program end
        if (dut.PC > 17) begin
            $display("\n==== NORMAL TERMINATION ====");
            $display("Total Cycles : %0d", cycle_count);
            $display("Instructions : %0d", instr_count);
            $display("IPC          : %0f",
                     instr_count * 1.0 / cycle_count);
            $display("Stalls       : %0d", stall_count);
            $finish;
        end

        // Watchdog safety
        if (cycle_count >= MAX_CYCLES) begin
            $display("\n==== WATCHDOG TIMEOUT ====");
            $display("Total Cycles : %0d", cycle_count);
            $display("Instructions : %0d", instr_count);
            $display("IPC          : %0f",
                     instr_count * 1.0 / cycle_count);
            $display("Stalls       : %0d", stall_count);
            $finish;
        end
    end

endmodule
