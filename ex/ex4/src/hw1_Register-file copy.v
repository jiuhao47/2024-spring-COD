`timescale 10 ns / 1 ns
`define DATA_WIDTH 32
`define ADDR_WIDTH 5
module top_module(
    input clk,
    input rst,
    input [`ADDR_WIDTH - 1:0] waddr,
    input [`ADDR_WIDTH - 1:0] raddr1,
    input [`ADDR_WIDTH - 1:0] raddr2,
    input wen,
    input [`DATA_WIDTH - 1:0] wdata,
    output [`DATA_WIDTH - 1:0] rdata1,
    output [`DATA_WIDTH - 1:0] rdata2
);
    reg [31:0] r [31:0] ;  
    always @(posedge clk or posedge rst) begin
        if(wen == 1'b1&&waddr!=5'b0) 
            r[waddr]<=wdata;//直接写入，0号寄存器问题在读取时解决
    end
  
    
//利用assign,实现组合逻辑的异步读取，同时在此解决零号寄存器的问题
    assign rdata1 =(raddr1 == 5'b0) ? 32'b0 :r[raddr1];
    assign rdata2 =(raddr2 == 5'b0) ? 32'b0 :r[raddr2];
endmodule