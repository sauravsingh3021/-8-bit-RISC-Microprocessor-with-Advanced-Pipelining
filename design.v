module RISC8_Pipelined (
    input  wire clk,
    input  wire reset
);

    // =====================================================
    // ISA (16 instructions)
    // opcode = instr[7:4]
    // rd     = instr[3:2]
    // rs/imm = instr[1:0]
    //
    // 0000 ADD   rd = rd + rs
    // 0001 SUB
    // 0010 AND
    // 0011 OR
    // 0100 XOR
    // 0101 ADDI
    // 0110 SLT
    // 0111 SLL
    // 1000 LOAD
    // 1001 STORE
    // 1010 LOADB
    // 1011 STOREB
    // 1100 BEQ
    // 1101 BNE
    // 1110 JUMP (PC-relative)
    // 1111 NOP
    // =====================================================

    // -------------------------
    // STATE
    // -------------------------
    reg [7:0] PC;
    reg [7:0] instr_mem [0:255];
    reg [7:0] data_mem  [0:255];
    reg [7:0] regfile   [0:3];
    integer i;

    // -------------------------
    // PIPELINE REGISTERS
    // -------------------------
    reg [7:0] IF_ID_instr, IF_ID_PC;

    reg [7:0] ID_EX_PC;
    reg [3:0] ID_EX_op;
    reg [1:0] ID_EX_rd, ID_EX_rs;
    reg [7:0] ID_EX_rd_val, ID_EX_rs_val;
    reg       ID_EX_regWrite, ID_EX_memRead, ID_EX_memWrite;
    reg       ID_EX_memToReg;

    reg [7:0] EX_MEM_ALUout, EX_MEM_rs_val;
    reg [1:0] EX_MEM_rd;
    reg       EX_MEM_regWrite, EX_MEM_memRead, EX_MEM_memWrite;
    reg       EX_MEM_memToReg;

    reg [7:0] MEM_WB_memData, MEM_WB_ALUout;
    reg [1:0] MEM_WB_rd;
    reg       MEM_WB_regWrite, MEM_WB_memToReg;

    // -------------------------
    // CONTROL
    // -------------------------
    reg stall, flush;
    reg branch_taken;
    reg [7:0] branch_target;

    // -------------------------
    // INIT
    // -------------------------
    initial begin
        PC = 0;
        IF_ID_instr = 8'hFF;

        for (i = 0; i < 4; i = i + 1)
            regfile[i] = 0;

        for (i = 0; i < 256; i = i + 1)
            data_mem[i] = 0;

        // Known values
        regfile[1] = 5;
        regfile[2] = 3;
    end

    // =====================================================
    // IF
    // =====================================================
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            PC <= 0;
            IF_ID_instr <= 8'hFF;
        end
        else if (branch_taken) begin
            PC <= branch_target;
            IF_ID_instr <= 8'hFF;   // flush
        end
        else if (!stall) begin
            IF_ID_instr <= instr_mem[PC];
            IF_ID_PC    <= PC;
            PC <= PC + 1;
        end
    end

    // =====================================================
    // ID
    // =====================================================
    always @(posedge clk) begin
        if (flush || stall) begin
            ID_EX_op <= 4'hF; // NOP
            ID_EX_regWrite <= 0;
            ID_EX_memRead  <= 0;
            ID_EX_memWrite <= 0;
            ID_EX_memToReg <= 0;
        end
        else begin
            ID_EX_PC     <= IF_ID_PC;
            ID_EX_op     <= IF_ID_instr[7:4];
            ID_EX_rd     <= IF_ID_instr[3:2];
            ID_EX_rs     <= IF_ID_instr[1:0];
            ID_EX_rd_val <= regfile[IF_ID_instr[3:2]];
            ID_EX_rs_val <= regfile[IF_ID_instr[1:0]];

            ID_EX_regWrite <= (IF_ID_instr[7:4] <= 4'b0111);
            ID_EX_memRead  <= (IF_ID_instr[7:4] == 4'b1000);
            ID_EX_memWrite <= (IF_ID_instr[7:4] == 4'b1001);
            ID_EX_memToReg <= (IF_ID_instr[7:4] == 4'b1000);
        end
    end

    // =====================================================
    // LOAD-USE STALL
    // =====================================================
    always @(*) begin
        stall = 0;
        if (ID_EX_memRead &&
           ((ID_EX_rd == IF_ID_instr[3:2]) ||
            (ID_EX_rd == IF_ID_instr[1:0])))
            stall = 1;
    end

    // =====================================================
    // EX
    // =====================================================
    reg [7:0] aluA, aluB, ALU_result;

  always @(*) begin
    aluA = ID_EX_rd_val;
    aluB = ID_EX_rs_val;

    // ---------- EX/MEM forwarding ----------
    if (EX_MEM_regWrite && EX_MEM_rd == ID_EX_rd)
        aluA = EX_MEM_ALUout;
    if (EX_MEM_regWrite && EX_MEM_rd == ID_EX_rs)
        aluB = EX_MEM_ALUout;

    // ---------- MEM/WB forwarding ----------
    if (MEM_WB_regWrite && MEM_WB_rd == ID_EX_rd)
        aluA = MEM_WB_memToReg ? MEM_WB_memData : MEM_WB_ALUout;
    if (MEM_WB_regWrite && MEM_WB_rd == ID_EX_rs)
        aluB = MEM_WB_memToReg ? MEM_WB_memData : MEM_WB_ALUout;
end


    always @(*) begin
        branch_taken  = 0;
        branch_target = 0;

        case (ID_EX_op)
            4'h0: ALU_result = aluA + aluB;
            4'h1: ALU_result = aluA - aluB;
            4'h2: ALU_result = aluA & aluB;
            4'h3: ALU_result = aluA | aluB;
            4'h4: ALU_result = aluA ^ aluB;
            4'h5: ALU_result = aluA + aluB;
            4'h6: ALU_result = (aluA < aluB);
            4'h7: ALU_result = aluA << aluB;

            // BEQ
            4'hC: begin
                ALU_result = 0;
                if (aluA == aluB) begin
                    branch_taken  = 1;
                    branch_target = ID_EX_PC + {{6{ID_EX_rs[1]}}, ID_EX_rs};
                end
            end

            // BNE
            4'hD: begin
                ALU_result = 0;
                if (aluA != aluB) begin
                    branch_taken  = 1;
                    branch_target = ID_EX_PC + {{6{ID_EX_rs[1]}}, ID_EX_rs};
                end
            end

            // JUMP (PC-relative)
            4'hE: begin
                ALU_result = 0;
                branch_taken  = 1;
                branch_target = ID_EX_PC + {{6{ID_EX_rs[1]}}, ID_EX_rs};
            end

            default: ALU_result = 0;
        endcase
    end

    always @(posedge clk) begin
        EX_MEM_ALUout    <= ALU_result;
        EX_MEM_rs_val   <= aluB;
        EX_MEM_rd       <= ID_EX_rd;
        EX_MEM_regWrite <= ID_EX_regWrite;
        EX_MEM_memRead  <= ID_EX_memRead;
        EX_MEM_memWrite <= ID_EX_memWrite;
        EX_MEM_memToReg <= ID_EX_memToReg;
    end

    assign flush = branch_taken;

    // =====================================================
    // MEM
    // =====================================================
    always @(posedge clk) begin
        if (EX_MEM_memWrite)
            data_mem[EX_MEM_ALUout] <= EX_MEM_rs_val;

        MEM_WB_memData  <= data_mem[EX_MEM_ALUout];
        MEM_WB_ALUout   <= EX_MEM_ALUout;
        MEM_WB_rd       <= EX_MEM_rd;
        MEM_WB_regWrite <= EX_MEM_regWrite;
        MEM_WB_memToReg <= EX_MEM_memToReg;
    end

    // =====================================================
    // WB
    // =====================================================
    always @(posedge clk) begin
        if (MEM_WB_regWrite)
            regfile[MEM_WB_rd] <=
                MEM_WB_memToReg ? MEM_WB_memData : MEM_WB_ALUout;
    end

endmodule
