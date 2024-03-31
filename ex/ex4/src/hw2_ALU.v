`define DATA_WIDTH 32
module top_module (
    input [`DATA_WIDTH - 1:0] A,
    input [`DATA_WIDTH - 1:0] B,
    input [2:0] ALUop,
    output Overflow,
    output CarryOut,
    output Zero,
    output [`DATA_WIDTH - 1:0] Result
);
    wire C_wire;  // 加法器进位输出
    wire CF_wire;  // Carry Flag 
    wire OF_wire;  // Overflow Flag
    wire ZF_wire;  // Zero Flag
    wire [`DATA_WIDTH-1:0] add_result;  // 加法结果
    wire [`DATA_WIDTH-1:0] B_NOR;  // B与ALUop异或 
    wire slt_judge;  // 比较器判据
    assign B_NOR = B ^ {`DATA_WIDTH{ALUop[2]}};
    assign {C_wire, add_result} = A + B_NOR + ALUop[2];
    assign slt_judge = add_result[`DATA_WIDTH-1] ^ OF_wire;
    assign AND = ALUop == 3'b000;
    assign OR = ALUop == 3'b001;
    assign ADD = ALUop == 3'b010;
    assign SUB = ALUop == 3'b110;
    assign SLT = ALUop == 3'b111;
    assign Result={32{AND}}&(A&B)|{32{OR}}&(A|B)|{32{ADD}}&add_result|{32{SUB}}&add_result|{32{SLT}}&{32{slt_judge}}&{31'b0,1'b1};
    assign ZF_wire = (Result == 32'b0) & 1'b1;
    assign OF_wire=(A[`DATA_WIDTH-1]&B_NOR[`DATA_WIDTH-1]&(~(add_result[`DATA_WIDTH-1])))+((~(A[`DATA_WIDTH-1]))&(~(B_NOR[`DATA_WIDTH-1]))&add_result[`DATA_WIDTH-1]);
    assign CF_wire = C_wire ^ ALUop[2];
    assign Zero = ZF_wire;
    assign Overflow = (ALUop == 3'b010 | ALUop == 3'b110) & (OF_wire);
    assign CarryOut = CF_wire;
endmodule
