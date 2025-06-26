`timescale 1ns/1ps

module processor_tb;
    reg clk;
    reg reset;

    // Performance metrics
    integer cycle_count = 0;
    integer instr_count = 0;
    integer stall_count = 0;
    reg [3:0] prev_pc;

    // Instantiate the processor
    Pipelined_Processor uut (
        .clk(clk),
        .reset(reset)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;  // 10 ns clock
    end

    // Simulation control
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

    // Monitor
    always @(posedge clk) begin
        cycle_count = cycle_count + 1;

        if (uut.regWrite)
            instr_count = instr_count + 1;

        if (reset == 0 && uut.pc == prev_pc)
            stall_count = stall_count + 1;

        prev_pc = uut.pc;

        $display("Time: %0t | PC: %0d", $time, uut.pc);
        $display("Registers: R0=%d | R1=%d | R2=%d | R3=%d",
                 uut.register_bank[0],
                 uut.register_bank[1],
                 uut.register_bank[2],
                 uut.register_bank[3]);
        $display("------------------------------------------------");
    end
endmodule
