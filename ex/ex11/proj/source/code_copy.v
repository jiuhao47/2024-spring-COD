`timescale 10ns / 1ns
module top_module (
    input             rst,
    input             clk,
    input      [31:0] Instruction,
    input      [31:0] Read_data,
    output reg [31:0] PC,
    output     [31:0] Address,
    output            MemWrite,
    output     [31:0] Write_data,
    output     [ 3:0] Write_strb,
    output            MemRead
);

    // THESE THREE SIGNALS ARE USED IN OUR TESTBENCH
    // PLEASE DO NOT MODIFY SIGNAL NAMES
    // AND PLEASE USE THEM TO CONNECT PORTS
    // OF YOUR INSTANTIATION OF THE REGISTER FILE MODULE
    wire        RF_wen;  //reg_file_wen
    wire [ 4:0] RF_waddr;  //reg_file_waddr
    wire [31:0] RF_wdata;  //reg_file_wdata
    wire [ 4:0] reg_file_ra1;
    wire [ 4:0] reg_file_ra2;
    wire [31:0] reg_file_rd1;
    wire [31:0] reg_file_rd2;

    //Shadow Stack Defence
    reg  [31:0] Shadow_Stack_pointer;
    wire [31:0] Shadow_Stack_pointer_wire;
    assign Shadow_Stack_pointer_wire = Shadow_Stack_pointer;
    reg_file reg_file_instant (
        .clk   (clk),
        .rst   (rst),
        .wen   (RF_wen),
        .waddr (RF_waddr),
        .raddr1(reg_file_ra1),
        .raddr2(reg_file_ra2),
        .wdata (RF_wdata),
        .rdata1(reg_file_rd1),
        .rdata2(reg_file_rd2)
    );

    wire [31:0] alu_oprandA;
    wire [31:0] alu_oprandB;
    wire [31:0] alu_result;
    wire [ 2:0] alu_op;
    wire        ZF;
    wire        SF;

    alu alu_instant (
        .A     (alu_oprandA),
        .B     (alu_oprandB),
        .ALUop (alu_op),
        .Zero  (ZF),
        .Sign  (SF),
        .Result(alu_result)
    );

    wire [31:0] shifter_oprand1;
    wire [ 4:0] shifter_oprand2;
    wire [31:0] shifter_result;
    wire [ 1:0] shifter_op;
    shifter shifter_instant (
        .A      (shifter_oprand1),
        .B      (shifter_oprand2),
        .Shiftop(shifter_op),
        .Result (shifter_result)
    );

    wire [31:0] PC_now;
    wire [31:0] PC_next;
    wire [31:0] Imm_addr;
    wire        RegDest;
    wire        Branch;
    wire        MemtoReg;
    wire        ALUsrc;
    wire        Jump;
    wire        Jump_Reg;
    wire        Shift;
    wire        Move;
    wire        RegWrite;

    assign PC_now = PC;
    PC_next PC_next_instant (
        .branch  (Branch),
        .jump    (Jump),
        .jump_reg(Jump_Reg),
        .PC_now  (PC_now),
        .Imm_addr(Imm_addr),
        .PC_next (PC_next)
    );

    reg JALR_pre;
    always @(posedge clk) begin
        if (rst) begin
            PC                   <= 32'd0;
            // Shadow Stack Defence
            Shadow_Stack_pointer <= 32'h80000800;
        end
        else begin
            PC <= PC_next;
            //NX defence;
            /*
            if(PC_next<32'h0|PC_next>32'h80000600)begin
                PC <= 32'h80000068;
            end
            else begin
                PC <= PC_next;
            end
            */
            // Shadow Stack Defence
            if ((Jump & (Instruction[26] == 1'b1)) | Jump_Reg & (Instruction[0] == 1'b1)) begin
                Shadow_Stack_pointer <= Shadow_Stack_pointer + 32'd4;
            end
            if (Jump_Reg & (Instruction[0] == 1'b0)) begin
                Shadow_Stack_pointer <= Shadow_Stack_pointer - 32'd4;
            end
            //CFI defence 
            /*
            if(Jump_Reg & Instruction[0]==1'b1) begin
                JALR_pre <= 1'b1;
            end
            else begin
                JALR_pre <= 1'b0;
            end
            if(JALR_pre == 1'b1 & Instruction != 32'h24000000) begin
                PC <= 32'h800000e8;
            end
            else begin
                PC <=PC_next;
            end
            */
        end
    end

    Controller Controller_instant (
        .Instruction(Instruction),
        .ZF         (ZF),
        .SF         (SF),
        .RegDest    (RegDest),
        .Branch     (Branch),
        .MemRead    (MemRead),
        .MemtoReg   (MemtoReg),
        .MemWrite   (MemWrite),
        .ALUsrc     (ALUsrc),
        .ALUop      (alu_op),
        .Shift_op   (shifter_op),
        .RegWrite   (RegWrite),
        .Jump       (Jump),
        .Jump_Reg   (Jump_Reg),
        .Shift      (Shift),
        .Move       (Move)
    );

    Wire_connector Wire_connector_instant (
        .Branch              (Branch),
        .Jump                (Jump),
        .Jump_Reg            (Jump_Reg),
        .RegDest             (RegDest),
        .MemtoReg            (MemtoReg),
        .ALUsrc              (ALUsrc),
        .Shift               (Shift),
        .Move                (Move),
        .RegWrite            (RegWrite),
        .Instruction         (Instruction),
        .Rs_data             (reg_file_rd1),
        .Rt_data             (reg_file_rd2),
        .Alu_result          (alu_result),
        .Mem_read_data       (Read_data),
        .PC_now              (PC_now),
        .shifter_result      (shifter_result),
        .RF_waddr            (RF_waddr),
        .RF_wdata            (RF_wdata),
        .PC_Imm_addr         (Imm_addr),
        .alu_oprandA         (alu_oprandA),
        .alu_oprandB         (alu_oprandB),
        .RF_raddr1           (reg_file_ra1),
        .RF_raddr2           (reg_file_ra2),
        .Address             (Address),
        .Write_data          (Write_data),
        .Write_strb          (Write_strb),
        .shifter_oprand1     (shifter_oprand1),
        .shifter_oprand2     (shifter_oprand2),
        .RF_wen              (RF_wen),
        // Shadow Stack Defence
        .Shadow_Stack_pointer(Shadow_Stack_pointer_wire)
    );

endmodule

module PC_next (
    input         branch,
    input         jump,
    input         jump_reg,
    input  [31:0] PC_now,
    input  [31:0] Imm_addr,
    output [31:0] PC_next
);
    wire [31:0] PC_plus;
    assign PC_plus = PC_now + 32'd4;
    assign PC_next = ({32{branch}} & (PC_plus + Imm_addr)) | ({32{~branch & jump}} & (PC_plus[31:28] | Imm_addr)) | ({32{~branch & ~jump & jump_reg}} & Imm_addr) | ({32{~branch & ~jump & ~jump_reg}} & PC_plus);
endmodule

module reg_file (
    input         clk,
    input         rst,
    input         wen,
    input  [ 4:0] waddr,
    input  [ 4:0] raddr1,
    input  [ 4:0] raddr2,
    input  [31:0] wdata,
    output [31:0] rdata1,
    output [31:0] rdata2
);
    reg [31:0] mem[31:1];
    always @(posedge clk) begin
        if (wen == 1'b1 && waddr != 5'b0) begin
            mem[waddr] <= wdata;
        end
    end
    assign rdata1 = (raddr1 == 5'b0) ? 32'b0 : mem[raddr1];
    assign rdata2 = (raddr2 == 5'b0) ? 32'b0 : mem[raddr2];
    // TEST: Register File
endmodule


module alu (
    input  [31:0] A,
    input  [31:0] B,
    input  [ 2:0] ALUop,
    output        Sign,
    output        Zero,
    output [31:0] Result
);

    wire        C_wire;
    wire        CF_wire;
    wire        OF_wire;
    wire        ZF_wire;
    wire        ADD;
    wire        SLT;
    wire        SLTU;
    wire        SUB;
    wire        AND;
    wire        OR;
    wire        XOR;
    wire        NOR;
    wire        isSUB;
    wire        slt_judge;
    wire        sltu_judge;
    wire [31:0] add_result;
    wire [31:0] B_NXOR;
    assign ADD                  = ALUop == 3'b001;
    assign SLT                  = ALUop == 3'b010;
    assign SLTU                 = ALUop == 3'b011;
    assign SUB                  = ALUop == 3'b111;
    assign AND                  = ALUop == 3'b100;
    assign OR                   = ALUop == 3'b101;
    assign XOR                  = ALUop == 3'b110;
    assign NOR                  = ALUop == 3'b000;
    assign isSUB                = SLT | SLTU | SUB;
    assign B_NXOR               = B ^ {32{isSUB}};
    assign {C_wire, add_result} = A + B_NXOR + isSUB;
    assign slt_judge            = add_result[31] ^ OF_wire;
    assign sltu_judge           = CF_wire;

    assign Result               = ({32{AND}} & (A & B)) | ({32{OR}} & (A | B)) | ({32{XOR}} & (A ^ B)) | ({32{ADD}} & add_result) | ({32{SUB}} & add_result) | ({32{SLT}} & {31'b0, slt_judge}) | ({32{SLTU}} & {31'b0, sltu_judge} | ({32{NOR}} & (~(A | B))));
    assign Sign                 = Result[31];
    assign ZF_wire              = (Result == 32'b0) & 1'b1;
    assign OF_wire              = (A[31] & B_NXOR[31] & (~(add_result[31]))) ^ ((~(A[31])) & (~(B_NXOR[31])) & add_result[31]);
    assign CF_wire              = C_wire ^ isSUB;
    assign Zero                 = ZF_wire;
    // TEST: ALU Write XOR NOR SLTU
endmodule



module shifter (
    input  [31:0] A,
    input  [ 4:0] B,
    input  [ 1:0] Shiftop,
    output [31:0] Result
);
    wire        SL;
    wire        SRL;
    wire        SRA;
    wire [31:0] SRA_result;

    assign SLL        = Shiftop == 2'b00;
    assign SRL        = Shiftop == 2'b10;
    assign SRA        = Shiftop == 2'b11;
    assign SRA_result = $signed(A) >>> B;
    assign Result     = ({32{SLL}} & (A << B)) | ({32{SRL}} & (A >> B)) | ({32{SRA}} & (SRA_result));
endmodule

// TODO: Control Unit
module Controller (
    input  [31:0] Instruction,
    input         ZF,
    input         SF,
    output        RegDest,      // 寄存器堆写目标
    output        RegWrite,     // 寄存器堆写使能
    output        MemRead,      // 主存读使能
    output        MemtoReg,     // 主存写回寄存器
    output        MemWrite,     // 主存写使能
    output        Branch,       // 程序分支标识
    output        Jump,         // 程序跳转标识
    output        Jump_Reg,     // 寄存器跳转标识
    output        Move,         // 数据移动标识
    output        ALUsrc,       // ALU第二操作数来源
    output [ 2:0] ALUop,        // ALU操作码
    output        Shift,        // 移位运算标识
    output [ 1:0] Shift_op      // 移位操作码
);
    wire [2:0] ALU_op_code;
    wire [5:0] Instruction_OP;
    wire       R_type;
    wire       R_alu;
    wire       R_shift;
    wire       R_j;
    wire       R_m;
    wire       JR_I;
    wire       J_I;
    wire       JAL_I;
    wire       J;
    wire       I_read;
    wire       I_alu;
    wire       I_write;
    wire       I_branch;
    wire       BEQ;
    wire       BNE;
    wire       BLEZ;
    wire       BGTZ;
    wire       BLTZ;
    wire       BGEZ;
    wire       SUB_R;
    wire       NOR_R;

    assign Instruction_OP = Instruction[31:26];
    assign R_type         = (Instruction_OP == 6'b000000);
    assign R_alu          = (R_type && (Instruction[5] == 1'b1));
    assign R_shift        = (R_type && (Instruction[5] == 1'b0) && (Instruction[3] == 1'b0));
    assign R_j            = (R_type && (Instruction[5] == 1'b0) && (Instruction[3] == 1'b1) && (Instruction[1] == 1'b0));
    assign R_m            = (R_type && (Instruction[5] == 1'b0) && (Instruction[3] == 1'b1) && (Instruction[1] == 1'b1));
    assign JR_I           = R_j & (Instruction[0] == 1'b0);
    assign J_I            = (Instruction_OP == 6'b000010);
    assign JAL_I          = (Instruction_OP == 6'b000011);
    assign JALR_I         = R_j & (Instruction[0] == 1'b1);
    assign J              = J_I | JAL_I;
    assign I_read         = (Instruction_OP[5:3] == 3'b100);
    assign I_alu          = (Instruction_OP[5:3] == 3'b001);
    assign I_write        = (Instruction_OP[5:3] == 3'b101);
    assign I_branch       = (Instruction_OP[5:3] == 3'b000) && (~R_type) && (~J);
    assign BEQ            = Instruction[31:26] == 6'b000100;
    assign BNE            = Instruction[31:26] == 6'b000101;
    assign BLEZ           = Instruction[31:26] == 6'b000110;
    assign BGTZ           = Instruction[31:26] == 6'b000111;
    assign BLTZ           = (Instruction[31:26] == 6'b000001) & (Instruction[16] == 1'b0);
    assign BGEZ           = (Instruction[31:26] == 6'b000001) & (Instruction[16] == 1'b1);
    //XXX: Branch处理
    assign SUB_R          = R_alu & (Instruction[3:0] == 4'b0011);
    assign NOR_R          = R_alu & (Instruction[3:0] == 4'b0111);
    assign ALU_op_code    = ({3{SUB_R}} & 3'b111) | ({3{NOR_R}} & 3'b000) | ({3{~SUB_R & ~NOR_R}} & Instruction[2:0]);
    //XXX: Alu_op_code处理

    assign Branch         = BEQ & ZF | BNE & ~ZF | BLEZ & (SF | ZF) | BGTZ & (~SF | ZF) | BLTZ & SF | BGEZ & ~SF;
    assign RegDest        = R_type;

    assign MemtoReg       = I_read;

    // Shadow Stack Defence
    //assign MemWrite       = I_write;
    //assign MemRead        = I_read;
    assign MemRead        = I_read | JR_I;
    assign MemWrite       = I_write | JAL_I | JALR_I;
    assign ALUsrc         = I_read | I_alu | I_write;
    assign RegWrite       = ~(I_write | I_branch | J_I | JR_I);
    assign ALUop          = ({3{R_alu}} & ALU_op_code) | ({3{I_alu}} & Instruction_OP[2:0]) | ({3{(I_read | I_write)}} & 3'b001) | ({3{I_branch}} & 3'b111);
    assign Shift_op       = ({2{R_shift}} & Instruction[1:0]) | ({2{J_I | JAL_I}} & 2'b00);
    assign Jump           = J;
    assign Jump_Reg       = R_j;
    assign Shift          = R_shift;
    assign Move           = R_m;
endmodule


module Wire_connector (
    //Shadow Stack
    input [31:0] Shadow_Stack_pointer,
    //
    input        Branch,
    input        Jump,
    input        Jump_Reg,
    input        RegDest,
    input        MemtoReg,
    input        ALUsrc,
    input        Shift,
    input        Move,
    input        RegWrite,
    input [31:0] Instruction,
    input [31:0] Rs_data,
    input [31:0] Rt_data,
    input [31:0] Alu_result,
    input [31:0] Mem_read_data,
    input [31:0] PC_now,
    input [31:0] shifter_result,

    output [31:0] PC_Imm_addr,      // PC的下一个地址/立即数
    output [31:0] alu_oprandA,      // ALU的第一个操作数
    output [31:0] alu_oprandB,      // ALU的第二个操作数
    output [31:0] shifter_oprand1,  // 移位器的第一个操作数
    output [ 4:0] shifter_oprand2,  // 移位器的第二个操作数
    output        RF_wen,           // 寄存器堆写使能
    output [ 4:0] RF_waddr,         // 寄存器堆写地址
    output [31:0] RF_wdata,         // 寄存器堆写数据
    output [ 4:0] RF_raddr1,        // 寄存器堆读地址1
    output [ 4:0] RF_raddr2,        // 寄存器堆读地址2
    output [31:0] Address,          // 主存地址
    output [31:0] Write_data,       // 主存写数据
    output [ 3:0] Write_strb        // 主存写掩码
);
    wire [31:0] Instruction_15_0;
    wire [31:0] Instruction_15_0_U;

    wire        BGEZ;
    wire        JAL;
    wire        JALR;

    wire        I_read;
    wire        LB;
    wire        LH;
    wire        LWL;
    wire        LWR;
    wire        L_U;
    wire        LUI;
    wire        ORI;
    wire        ANDI;
    wire        XORI;
    wire [31:0] L_extend;

    wire        SB;
    wire        SH;
    wire        SWL;
    wire        SWR;

    wire        MOVZ;
    wire        MOVN;
    wire        MOV_SUCC;
    //wire [ 4:0] MOV_waddr;
    wire        MOV_wen;

    wire [ 3:0] LS_strb_B;
    wire [ 3:0] LS_strb_H;
    wire [ 3:0] LS_strb_SWL;
    wire [ 3:0] LS_strb_SWR;
    wire [31:0] Read_data_B;
    wire [31:0] Read_data_H;
    wire [31:0] Read_data_LWL;
    wire [31:0] Read_data_LWR;
    wire [31:0] Read_data_O;

    wire [31:0] Wirte_data_cut_B;
    wire [31:0] Wirte_data_cut_H;
    wire [31:0] Wirte_data_cut_SWL;


    assign Instruction_15_0   = $signed(Instruction[15:0]);
    assign Instruction_15_0_U = $unsigned(Instruction[15:0]);

    assign BGEZ               = (Instruction[31:26] == 6'b000001) & (Instruction[16] == 1'b1);
    assign JAL                = Jump & (Instruction[26] == 1'b1);
    assign JALR               = Jump_Reg & (Instruction[0] == 1'b1);

    assign I_write            = (Instruction[31:29] == 3'b101);
    assign LB                 = MemtoReg & (Instruction[28:26] == 3'b000 | Instruction[28:26] == 3'b100);
    assign LH                 = MemtoReg & (Instruction[28:26] == 3'b001 | Instruction[28:26] == 3'b101);
    assign LWL                = MemtoReg & (Instruction[28:26] == 3'b010);
    assign LWR                = MemtoReg & (Instruction[28:26] == 3'b110);
    assign L_U                = MemtoReg & (Instruction[28:26] == 3'b101 | Instruction[28:26] == 3'b100);
    assign LUI                = Instruction[29:26] == 4'b1111;
    assign ORI                = Instruction[31:26] == 6'b001101;
    assign ANDI               = Instruction[31:26] == 6'b001100;
    assign XORI               = Instruction[31:26] == 6'b001110;
    assign L_extend           = (L_U) ? 32'b0 : Mem_read_data;

    assign SB                 = I_write & (Instruction[28:26] == 3'b000);
    assign SH                 = I_write & (Instruction[28:26] == 3'b001);
    assign SWL                = I_write & (Instruction[28:26] == 3'b010);
    assign SWR                = I_write & (Instruction[28:26] == 3'b110);

    assign MOVZ               = Move & (Instruction[0] == 1'b0);
    assign MOVN               = Move & (Instruction[0] == 1'b1);
    assign MOV_SUCC           = (MOVZ & Rt_data == 32'b0) | (MOVN & Rt_data != 32'b0);
    assign MOV_wen            = (MOV_SUCC & 1'b1) | (~MOV_SUCC & 1'b0);

    assign LS_strb_B          = {Alu_result[1] & Alu_result[0], Alu_result[1] & ~Alu_result[0], ~Alu_result[1] & Alu_result[0], ~Alu_result[1] & ~Alu_result[0]};
    assign LS_strb_H          = {Alu_result[1] & ~Alu_result[0], Alu_result[1] & ~Alu_result[0], ~Alu_result[1] & ~Alu_result[0], ~Alu_result[1] & ~Alu_result[0]};
    assign LS_strb_SWL        = {Alu_result[1] & Alu_result[0], Alu_result[1], Alu_result[1] | Alu_result[0], 1'b1};
    assign LS_strb_SWR        = {1'b1, ~Alu_result[1] | ~Alu_result[0], ~Alu_result[0], ~Alu_result[1] & ~Alu_result[0]};
    assign Read_data_B        = ({32{LS_strb_B[3]}} & {{24{L_extend[31]}}, Mem_read_data[31:24]}) | ({32{(~LS_strb_B[3] & LS_strb_B[2])}} & {{24{L_extend[23]}}, Mem_read_data[23:16]}) | ({32{(~LS_strb_B[3] & ~LS_strb_B[2] & LS_strb_B[1])}} & {{24{L_extend[15]}}, Mem_read_data[15:8]}) | ({32{(~LS_strb_B[3] & ~LS_strb_B[2] & ~LS_strb_B[1])}} & {{24{L_extend[7]}}, Mem_read_data[7:0]});
    assign Read_data_H        = ({32{LS_strb_H[2]}} & {{16{L_extend[31]}}, Mem_read_data[31:16]}) | ({32{~LS_strb_H[2]}} & {{16{L_extend[15]}}, Mem_read_data[15:0]});
    assign Read_data_LWL      = ({32{LS_strb_B[3]}} & {Mem_read_data}) | ({32{~LS_strb_B[3] & LS_strb_B[2]}} & {Mem_read_data[23:0], Rt_data[7:0]}) | ({32{~LS_strb_B[3] & ~LS_strb_B[2] & LS_strb_B[1]}} & {Mem_read_data[15:0], Rt_data[15:0]}) | ({32{~LS_strb_B[3] & ~LS_strb_B[2] & ~LS_strb_B[1]}} & {Mem_read_data[7:0], Rt_data[23:0]});
    assign Read_data_LWR      = ({32{LS_strb_B[3]}} & {Rt_data[31:8], Mem_read_data[31:24]}) | ({32{~LS_strb_B[3] & LS_strb_B[2]}} & {Rt_data[31:16], Mem_read_data[31:16]}) | ({32{~LS_strb_B[3] & ~LS_strb_B[2] & LS_strb_B[1]}} & {Rt_data[31:24], Mem_read_data[31:8]}) | ({32{~LS_strb_B[3] & ~LS_strb_B[2] & ~LS_strb_B[1]}} & {Mem_read_data});
    assign Read_data_O        = ({32{LB}} & Read_data_B) | ({32{~LB & LH}} & Read_data_H) | ({32{~LB & ~LH & LWL}} & Read_data_LWL) | ({32{~LB & ~LH & ~LWL & LWR}} & Read_data_LWR) | ({32{~LB & ~LH & ~LWL & ~LWR}} & Mem_read_data);

    assign Wirte_data_cut_B   = ({32{LS_strb_B[3]}} & {Rt_data[7:0], 24'b0}) | ({32{LS_strb_B[2]}} & {Rt_data[15:0], 16'b0}) | ({32{LS_strb_B[1]}} & {Rt_data[23:0], 8'b0}) | ({32{~LS_strb_B[3] & ~LS_strb_B[2] & ~LS_strb_B[1]}} & Rt_data);
    assign Wirte_data_cut_H   = ({32{LS_strb_H[2]}} & {Rt_data[15:0], 16'b0}) | ({32{~LS_strb_H[2]}} & Rt_data);
    assign Wirte_data_cut_SWL = ({32{LS_strb_B[3]}} & {Rt_data}) | ({32{LS_strb_B[2]}} & {8'b0, Rt_data[31:8]}) | ({32{LS_strb_B[1]}} & {16'b0, Rt_data[31:16]}) | ({32{~LS_strb_B[3] & ~LS_strb_B[2] & ~LS_strb_B[1]}} & {24'b0, Rt_data[31:24]});

    // XXX: 关于使用三目运算符还是与或逻辑的纠结
    /*
  assign PC_Imm_addr           = ({32{Branch}} & (Instruction_15_0 << 2)) | ({32{Jump}} & {Instruction[25:0], 2'b00}) | ({32{Jump_Reg}} & Rs_data) | 32'b0;
  assign RF_wen                = Move ? MOV_wen : RegWrite;
  assign RF_waddr              = Move ? (MOV_waddr) : JAL ? (5'b11111) : RegDest ? Instruction[15:11] : Instruction[20:16];
  assign RF_wdata              = LUI ? ({Instruction[15:0], 16'b0}) : Move ? (Rs_data) : (JAL | JALR) ? (PC_now + 32'd8) : MemtoReg ? Read_data_O : (Shift) ? shifter_result : Alu_result;
  assign alu_oprandA           = Rs_data;
  assign alu_oprandB           = ALUsrc ? (ORI | ANDI ? Instruction_15_0_U : Instruction_15_0) : Rt_data;
  assign shifter_oprand1       = Rt_data;
  assign shifter_oprand2       = (Instruction[2] == 1'b1) ? Rs_data[4:0] : Instruction[10:6];
  assign RF_raddr1             = Instruction[25:21];
  assign RF_raddr2             = BGEZ ? 5'b00000 : Instruction[20:16];
  assign Address               = {Alu_result[31:2], 2'b00};
  assign Write_data            = SB ? Wirte_data_cut_B : SH ? Wirte_data_cut_H : SWL ? Wirte_data_cut_SWL : SWR ? Wirte_data_cut_B : Rt_data;
  assign Write_strb            = SB ? LS_strb_B : SH ? LS_strb_H : SWL ? LS_strb_SWL : SWR ? LS_strb_SWR : 4'b1111;
  */
    //assign PC_Imm_addr        = ({32{Branch}} & (Instruction_15_0 << 2)) | ({32{Jump}} & {Instruction[25:0], 2'b00}) | ({32{Jump_Reg}} & Rs_data) | ({32{~Branch & ~Jump & ~Jump_Reg}} & 32'b0);
    //Shadow Stack Defence
    assign PC_Imm_addr        = ({32{Branch}} & (Instruction_15_0 << 2)) | ({32{Jump}} & {Instruction[25:0], 2'b00}) | ({32{Jump_Reg}} & ((Instruction[0] == 1'b0 & (Read_data_O != Rs_data)) ? (32'h800000a8) : Rs_data)) | ({32{~Branch & ~Jump & ~Jump_Reg}} & 32'b0);
    assign alu_oprandA        = Rs_data;
    assign alu_oprandB        = ({32{ALUsrc}} & (ORI | ANDI | XORI ? Instruction_15_0_U : Instruction_15_0)) | ({32{~ALUsrc}} & Rt_data);
    assign shifter_oprand1    = Rt_data;
    assign shifter_oprand2    = ({5{Instruction[2]}} & Rs_data[4:0]) | ({5{~Instruction[2]}} & Instruction[10:6]);
    assign RF_wen             = (Move & MOV_wen) | (~Move & RegWrite);
    assign RF_waddr           = ({5{JAL}} & 5'b11111) | ({5{RegDest | MOV_SUCC}} & Instruction[15:11]) | ({5{~MOV_SUCC & ~JAL & ~RegDest}} & Instruction[20:16]);
    assign RF_wdata           = ({32{LUI}} & {Instruction[15:0], 16'b0}) | ({32{Move}} & Rs_data) | ({32{JAL | JALR}} & (PC_now + 32'd8)) | ({32{MemtoReg}} & Read_data_O) | ({32{Shift}} & shifter_result) | ({32{~LUI & ~Move & ~(JAL | JALR) & ~MemtoReg & ~Shift}} & Alu_result);
    assign RF_raddr1          = Instruction[25:21];
    assign RF_raddr2          = ({5{BGEZ}} & 5'b00000) | ({5{~BGEZ}} & Instruction[20:16]);


    //assign Address            = {Alu_result[31:2], 2'b00};
    //assign Write_data         = ({32{SB}} & Wirte_data_cut_B) | ({32{SH}} & Wirte_data_cut_H) | ({32{SWL}} & Wirte_data_cut_SWL) | ({32{SWR}} & Wirte_data_cut_B) | ({32{~SB & ~SH & ~SWL & ~SWR}} & Rt_data);
    //assign Write_strb         = ({4{SB}} & LS_strb_B) | ({4{SH}} & LS_strb_H) | ({4{SWL}} & LS_strb_SWL) | ({4{SWR}} & LS_strb_SWR) | ({4{~SB & ~SH & ~SWL & ~SWR}} & 4'b1111);

    //Shadow Stack Defence
    wire JR = Jump_Reg & Instruction[0] == 1'b0;
    assign Address    = (JAL | JALR) ? (Shadow_Stack_pointer) : (JR) ? (Shadow_Stack_pointer - 32'd4) : ({Alu_result[31:2], 2'b00});
    assign Write_data = (JAL | JALR) ? (PC_now + 32'd8) : ({32{SB}} & Wirte_data_cut_B) | ({32{SH}} & Wirte_data_cut_H) | ({32{SWL}} & Wirte_data_cut_SWL) | ({32{SWR}} & Wirte_data_cut_B) | ({32{~SB & ~SH & ~SWL & ~SWR}} & Rt_data);
    assign Write_strb = (JAL | JALR) ? (4'b1111) : ({4{SB}} & LS_strb_B) | ({4{SH}} & LS_strb_H) | ({4{SWL}} & LS_strb_SWL) | ({4{SWR}} & LS_strb_SWR) | ({4{~SB & ~SH & ~SWL & ~SWR}} & 4'b1111);


    // 4'b0001;4'b0011
endmodule

//TODO: 给ALUop编码更换为4位编码
