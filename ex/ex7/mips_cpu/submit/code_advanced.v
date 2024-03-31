`timescale 10ns / 1ns
`define DATA_WIDTH 32
`define ADDR_WIDTH 5
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
    wire        OF;
    wire        CF;
    wire        ZF;
    wire        SF;

    alu alu_instant (
        .A       (alu_oprandA),
        .B       (alu_oprandB),
        .ALUop   (alu_op),
        .Overflow(OF),
        .CarryOut(CF),
        .Zero    (ZF),
        .Sign    (SF),
        .Result  (alu_result)
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
    always @(posedge clk) begin
        if (rst) begin
            PC <= 32'd0;
        end
        else begin
            PC <= PC_next;
        end
    end

    Controler Controler_instant (
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

    wire_connector wire_connector_instant (
        .Branch         (Branch),
        .Jump           (Jump),
        .Jump_Reg       (Jump_Reg),
        .RegDest        (RegDest),
        .MemtoReg       (MemtoReg),
        .ALUsrc         (ALUsrc),
        .Shift          (Shift),
        .Move           (Move),
        .RegWrite       (RegWrite),
        .Instruction    (Instruction),
        .Rs_data        (reg_file_rd1),
        .Rt_data        (reg_file_rd2),
        .Alu_result     (alu_result),
        .Mem_read_data  (Read_data),
        .PC_now         (PC_now),
        .shifter_result (shifter_result),
        .RF_waddr       (RF_waddr),
        .RF_wdata       (RF_wdata),
        .PC_Imm_addr    (Imm_addr),
        .alu_oprandA    (alu_oprandA),
        .alu_oprandB    (alu_oprandB),
        .RF_raddr1      (reg_file_ra1),
        .RF_raddr2      (reg_file_ra2),
        .Address        (Address),
        .Write_data     (Write_data),
        .Write_strb     (Write_strb),
        .shifter_oprand1(shifter_oprand1),
        .shifter_oprand2(shifter_oprand2),
        .RF_wen         (RF_wen)
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
    // Imm_addr输入为branch的偏移量，jump的目标地址（未左移），jump_reg的寄存器值
    wire [31:0] PC_plus;
    assign PC_plus = PC_now + 4;
    // XXX: 4的魔数处理;
    assign PC_next = (branch) ? PC_plus + Imm_addr : (jump) ? PC_plus[31:28] | Imm_addr : (jump_reg) ? Imm_addr : PC_plus;
endmodule

module reg_file (
    input                      clk,
    input                      rst,
    input                      wen,
    input  [`ADDR_WIDTH - 1:0] waddr,
    input  [`ADDR_WIDTH - 1:0] raddr1,
    input  [`ADDR_WIDTH - 1:0] raddr2,
    input  [`DATA_WIDTH - 1:0] wdata,
    output [`DATA_WIDTH - 1:0] rdata1,
    output [`DATA_WIDTH - 1:0] rdata2
);
    reg [`DATA_WIDTH-1:0] mem[2**`ADDR_WIDTH-1:1];
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
    input  [`DATA_WIDTH - 1:0] A,
    input  [`DATA_WIDTH - 1:0] B,
    input  [              2:0] ALUop,
    output                     Overflow,
    output                     CarryOut,
    output                     Sign,
    output                     Zero,
    output [`DATA_WIDTH - 1:0] Result
);
    wire                   C_wire;
    wire                   CF_wire;
    wire                   OF_wire;
    wire                   ZF_wire;
    wire                   isSUB;
    wire [`DATA_WIDTH-1:0] add_result;
    wire [`DATA_WIDTH-1:0] B_NXOR;
    wire                   slt_judge;

    assign ADD                  = ALUop == 3'b001;
    assign SLT                  = ALUop == 3'b010;
    assign SLTU                 = ALUop == 3'b011;
    assign SUB                  = ALUop == 3'b111;
    // XXX: SUB SLT SLTU 整合方式
    assign AND                  = ALUop == 3'b100;
    assign OR                   = ALUop == 3'b101;
    assign XOR                  = ALUop == 3'b110;
    assign NOR                  = ALUop == 3'b000;
    assign isSUB                = SLT | SLTU | SUB;

    assign B_NXOR               = B ^ {`DATA_WIDTH{isSUB}};
    assign {C_wire, add_result} = A + B_NXOR + isSUB;
    assign slt_judge            = add_result[`DATA_WIDTH-1] ^ OF_wire;
    assign sltu_judge           = CF_wire;

    assign Result               = ({32{AND}} & (A & B)) | ({32{OR}} & (A | B)) | ({32{XOR}} & (A ^ B)) | ({32{ADD}} & add_result) | ({32{SUB}} & add_result) | ({32{SLT}} & slt_judge) | ({32{SLTU}} & {sltu_judge} | ({32{NOR}} & (~(A | B))));
    assign Sign                 = Result[`DATA_WIDTH-1];
    assign ZF_wire              = (Result == 32'b0) & 1'b1;
    assign OF_wire              = (A[`DATA_WIDTH-1] & B_NXOR[`DATA_WIDTH-1] & (~(add_result[`DATA_WIDTH-1]))) + ((~(A[`DATA_WIDTH-1])) & (~(B_NXOR[`DATA_WIDTH-1])) & add_result[`DATA_WIDTH-1]);
    assign CF_wire              = C_wire ^ isSUB;
    assign Zero                 = ZF_wire;
    assign Overflow             = (ADD | SUB) & (OF_wire);
    assign CarryOut             = CF_wire;
    // TEST: ALU Write XOR NOR SLTU
endmodule



module shifter (
    input  [`DATA_WIDTH - 1:0] A,
    input  [`ADDR_WIDTH - 1:0] B,
    input  [              1:0] Shiftop,
    output [`DATA_WIDTH - 1:0] Result
);
    wire SL;
    wire SRL;
    wire SRA;
    assign SLL = Shiftop == 2'b00;
    assign SRL = Shiftop == 2'b10;
    assign SRA = Shiftop == 2'b11;

    wire [31:0] SRA_result;
    assign SRA_result = $signed(A) >>> B;
    assign Result     = ({32{SLL}} & (A << B)) | ({32{SRL}} & (A >> B)) | ({32{SRA}} & (SRA_result));
    // TEST: Shifter SLL,SLA,SRL,SRA
endmodule

// TODO: Control Unit
module Controler (
    input  [31:0] Instruction,
    input         ZF,
    input         SF,
    output        RegDest,
    output        Branch,
    output        MemRead,
    output        MemtoReg,
    output        MemWrite,
    output        ALUsrc,
    output [ 2:0] ALUop,
    output [ 1:0] Shift_op,
    output        RegWrite,
    output        Jump,
    output        Jump_Reg,
    output        Shift,
    output        Move
);
    wire [5:0] Instruction_OP = Instruction[31:26];
    wire [5:0] Instruction_FUNCT = Instruction[5:0];
    wire       R_type = (Instruction_OP == 6'b000000);
    wire       R_alu = (R_type && (Instruction_FUNCT[5] == 1'b1));
    wire       R_shift = (R_type && (Instruction_FUNCT[5] == 1'b0) && (Instruction_FUNCT[3] == 1'b0));
    wire       R_j = (R_type && (Instruction_FUNCT[5] == 1'b0) && (Instruction_FUNCT[3] == 1'b1) && (Instruction_FUNCT[1] == 1'b0));
    wire       R_m = (R_type && (Instruction_FUNCT[5] == 1'b0) && (Instruction_FUNCT[3] == 1'b1) && (Instruction_FUNCT[1] == 1'b1));
    wire       JR_I = R_j & (Instruction_FUNCT[0] == 1'b0);
    wire       JALR_I = R_j & (Instruction_FUNCT[0] == 1'b1);
    wire       J_I = (Instruction_OP == 6'b000010);
    wire       JAL_I = (Instruction_OP == 6'b000011);
    wire       J = J_I | JAL_I;
    wire       I_read = (Instruction_OP[5:3] == 3'b100);
    wire       I_alu = (Instruction_OP[5:3] == 3'b001);
    wire       I_write = (Instruction_OP[5:3] == 3'b101);
    wire       I_branch = (Instruction_OP[5:3] == 3'b000) && (~R_type) && (~J);
    wire       BEQ = Instruction[31:26] == 6'b000100;
    wire       BNE = Instruction[31:26] == 6'b000101;
    wire       BLEZ = Instruction[31:26] == 6'b000110;
    wire       BGTZ = Instruction[31:26] == 6'b000111;
    wire       BLTZ = (Instruction[31:26] == 6'b000001) & (Instruction[16] == 1'b0);
    wire       BGEZ = (Instruction[31:26] == 6'b000001) & (Instruction[16] == 1'b1);
    wire       SUB_R = R_alu & (Instruction_FUNCT[3:0] == 4'b0011);
    wire       NOR_R = R_alu & (Instruction_FUNCT[3:0] == 4'b0111);
    wire [2:0] ALU_op_code;



    assign RegDest     = R_type;
    assign ALU_op_code = ({3{SUB_R}} & 3'b111) | ({3{NOR_R}} & 3'b000) | ({3{~SUB_R & ~NOR_R}} & Instruction_FUNCT[2:0]);
    assign Branch      = BEQ & ZF | BNE & ~ZF | BLEZ & (SF | ZF) | BGTZ & (~SF | ZF) | BLTZ & SF | BGEZ & ~SF;
    assign MemRead     = I_read;
    assign MemtoReg    = I_read;
    assign MemWrite    = I_write;
    assign ALUsrc      = I_read | I_alu | I_write;
    assign RegWrite    = ~(I_write | I_branch | J_I | JR_I);
    assign ALUop       = ({3{R_alu}} & ALU_op_code) | ({3{I_alu}} & Instruction_OP[2:0]) | ({3{(I_read | I_write)}} & 3'b001) | ({3{I_branch}} & 3'b111);
    assign Shift_op    = ({2{R_shift}} & Instruction_FUNCT[1:0]) | ({2{J}} & 2'b00);
    assign Jump        = J;
    assign Jump_Reg    = R_j;
    assign Shift       = R_shift;
    assign Move        = R_m;
endmodule

//TODO: 数据通路之连线模块

module wire_connector (
    input         Branch,
    input         Jump,
    input         Jump_Reg,
    input         RegDest,
    input         MemtoReg,
    input         ALUsrc,
    input         Shift,
    input         Move,
    input         RegWrite,
    input  [31:0] Instruction,
    input  [31:0] Rs_data,
    input  [31:0] Rt_data,
    input  [31:0] Alu_result,
    input  [31:0] Mem_read_data,
    input  [31:0] PC_now,
    input  [31:0] shifter_result,
    output [ 4:0] RF_waddr,
    output [31:0] RF_wdata,
    output [ 4:0] RF_raddr1,
    output [ 4:0] RF_raddr2,
    output [31:0] Write_data,
    output [ 3:0] Write_strb,
    output [31:0] Address,
    output [31:0] PC_Imm_addr,
    output [31:0] alu_oprandA,
    output [31:0] alu_oprandB,
    output [31:0] shifter_oprand1,
    output [ 4:0] shifter_oprand2,
    output        RF_wen
);
    wire [31:0] Instruction_15_0;
    wire [31:0] Instruction_15_0_U;
    wire        BGEZ = (Instruction[31:26] == 6'b000001) & (Instruction[16] == 1'b1);
    wire        JAL = Jump & (Instruction[26] == 1'b1);
    wire        JALR = Jump_Reg & (Instruction[0] == 1'b1);
    wire        MOVZ = Move & (Instruction[0] == 1'b0);
    wire        MOVN = Move & (Instruction[0] == 1'b1);

    wire        I_read = (Instruction[31:29] == 3'b101);
    wire        LB = MemtoReg & (Instruction[28:26] == 3'b000 | Instruction[28:26] == 3'b100);
    wire        LH = MemtoReg & (Instruction[28:26] == 3'b001 | Instruction[28:26] == 3'b101);
    wire        LWL = MemtoReg & (Instruction[28:26] == 3'b010);
    wire        LWR = MemtoReg & (Instruction[28:26] == 3'b110);
    wire        L_U = MemtoReg & (Instruction[28:26] == 3'b101 | Instruction[28:26] == 3'b100);
    wire        LUI = Instruction[29:26] == 4'b1111;
    wire        ORI = Instruction[31:26] == 6'b001101;
    wire        ANDI = Instruction[31:26] == 6'b001100;
    wire [31:0] L_extend = (L_U) ? 32'b0 : Mem_read_data;
    wire        SB = I_read & (Instruction[28:26] == 3'b000);
    wire        SH = I_read & (Instruction[28:26] == 3'b001);
    wire        SWL = I_read & (Instruction[28:26] == 3'b010);
    wire        SWR = I_read & (Instruction[28:26] == 3'b110);
    wire        MOV_SUCCESS = (MOVZ & Rt_data == 32'b0) | (MOVN & Rt_data != 32'b0);
    wire [ 4:0] MOV_waddr;
    wire        MOV_wen;
    wire [31:0] Read_data_out;
    wire [31:0] Read_data_out_cut_B = (LS_strb_B[3]) ? {{24{L_extend[31]}}, Mem_read_data[31:24]} : (LS_strb_B[2]) ? {{24{L_extend[23]}}, Mem_read_data[23:16]} : (LS_strb_B[1]) ? {{24{L_extend[15]}}, Mem_read_data[15:8]} : {{24{L_extend[7]}}, Mem_read_data[7:0]};
    wire [31:0] Read_data_out_cut_H = (LS_strb_H[2]) ? {{16{L_extend[31]}}, Mem_read_data[31:16]} : {{16{L_extend[15]}}, Mem_read_data[15:0]};
    wire [31:0] Read_data_out_cut_LWL = (LS_strb_B[3]) ? {Mem_read_data} : (LS_strb_B[2]) ? {Mem_read_data[23:0], Rt_data[7:0]} : (LS_strb_B[1]) ? {Mem_read_data[15:0], Rt_data[15:0]} : {Mem_read_data[7:0], Rt_data[23:0]};
    wire [31:0] Read_data_out_cut_LWR = (LS_strb_B[3]) ? {Rt_data[31:8], Mem_read_data[31:24]} : (LS_strb_B[2]) ? {Rt_data[31:16], Mem_read_data[31:16]} : (LS_strb_B[1]) ? {Rt_data[31:24], Mem_read_data[31:8]} : {Mem_read_data};
    wire [ 1:0] LS_offset = Alu_result[1:0];
    wire [ 3:0] LS_strb_B = {LS_offset[1] & LS_offset[0], LS_offset[1] & ~LS_offset[0], ~LS_offset[1] & LS_offset[0], ~LS_offset[1] & ~LS_offset[0]};
    wire [ 3:0] LS_strb_H = {LS_offset[1] & ~LS_offset[0], LS_offset[1] & ~LS_offset[0], ~LS_offset[1] & ~LS_offset[0], ~LS_offset[1] & ~LS_offset[0]};
    wire [ 3:0] LS_strb_SWL = {LS_offset[1] & LS_offset[0], LS_offset[1], ~LS_offset[1] | ~LS_offset[0], 1'b1};
    wire [ 3:0] LS_strb_SWR = {1'b1, ~LS_offset[1] | ~LS_offset[0], ~LS_offset[0], ~LS_offset[1] & ~LS_offset[0]};
    wire [31:0] Wirte_data_cut_B = (LS_strb_B[3]) ? {Rt_data[7:0], 24'b0} : (LS_strb_B[2]) ? {Rt_data[15:0], 16'b0} : (LS_strb_B[1]) ? {Rt_data[23:0], 8'b0} : Rt_data;
    wire [31:0] Wirte_data_cut_H = (LS_strb_H[2]) ? {Rt_data[15:0], 16'b0} : Rt_data;
    wire [31:0] Wirte_data_cut_SWL = (LS_strb_B[3]) ? {Rt_data} : (LS_strb_B[2]) ? {8'b0, Rt_data[31:8]} : (LS_strb_B[1]) ? {16'b0, Rt_data[31:16]} : {24'b0, Rt_data[31:24]};
    wire [31:0] Wirte_data_cut_SWR = (LS_strb_B[3]) ? {Rt_data[7:0], 24'b0} : (LS_strb_B[2]) ? {Rt_data[15:0], 16'b0} : (LS_strb_B[1]) ? {Rt_data[23:0], 8'b0} : Rt_data;


    assign Read_data_out      = LB ? Read_data_out_cut_B : LH ? Read_data_out_cut_H : LWL ? (Read_data_out_cut_LWL) : LWR ? (Read_data_out_cut_LWR) : Mem_read_data;
    assign MOV_waddr          = MOV_SUCCESS ? Instruction[15:11] : 5'b00000;
    assign MOV_wen            = MOV_SUCCESS ? 1'b1 : 1'b0;
    assign Instruction_15_0   = $signed(Instruction[15:0]);
    assign Instruction_15_0_U = $unsigned(Instruction[15:0]);
    assign PC_Imm_addr        = ({32{Branch}} & (Instruction_15_0 << 2)) | ({32{Jump}} & {Instruction[25:0], 2'b00}) | ({32{Jump_Reg}} & Rs_data) | 32'b0;
    assign RF_wen             = Move ? MOV_wen : RegWrite;
    assign RF_waddr           = Move ? (MOV_waddr) : JAL ? (5'b11111) : RegDest ? Instruction[15:11] : Instruction[20:16];
    assign RF_wdata           = LUI ? ({Instruction[15:0], 16'b0}) : Move ? (Rs_data) : (JAL | JALR) ? (PC_now + 32'd8) : MemtoReg ? Read_data_out : (Shift) ? shifter_result : Alu_result;
    assign alu_oprandA        = Rs_data;
    assign alu_oprandB        = ALUsrc ? (ORI | ANDI ? Instruction_15_0_U : Instruction_15_0) : Rt_data;
    assign shifter_oprand1    = Rt_data;
    assign shifter_oprand2    = (Instruction[2] == 1'b1) ? Rs_data[4:0] : Instruction[10:6];
    assign RF_raddr1          = Instruction[25:21];
    assign RF_raddr2          = BGEZ ? 5'b00000 : Instruction[20:16];
    assign Address            = {Alu_result[31:2], 2'b00};
    assign Write_data         = SB ? Wirte_data_cut_B : SH ? Wirte_data_cut_H : SWL ? Wirte_data_cut_SWL : SWR ? Wirte_data_cut_SWR : Rt_data;
    assign Write_strb         = SB ? LS_strb_B : SH ? LS_strb_H : SWL ? LS_strb_SWL : SWR ? LS_strb_SWR : 4'b1111;










    // 4'b0001;4'b0011
endmodule

//TODO: 给ALUop编码更换为4位编码
