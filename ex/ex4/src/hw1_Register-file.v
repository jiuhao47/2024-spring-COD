`timescale 10 ns / 1 ns
`define DATA_WIDTH 32
`define ADDR_WIDTH 5
module top_module (
    input clk,
    input rst,
    input wen,
    input [`ADDR_WIDTH - 1:0] waddr,
    input [`ADDR_WIDTH - 1:0] raddr1,
    input [`ADDR_WIDTH - 1:0] raddr2,
    input [`DATA_WIDTH - 1:0] wdata,
    output [`DATA_WIDTH - 1:0] rdata1,
    output [`DATA_WIDTH - 1:0] rdata2
);
  reg [`DATA_WIDTH-1:0] mem[2**`ADDR_WIDTH-1:1];  // 寄存器堆空间（32*32bit）
  always @(posedge clk) begin
    if (wen == 1'b1 && waddr != 5'b0) begin
      mem[waddr] <= wdata;
    end  //数据写入
  end
  assign rdata1 = (raddr1 == 5'b0) ? 32'b0 : mem[raddr1];  //数据读出
  assign rdata2 = (raddr2 == 5'b0) ? 32'b0 : mem[raddr2];  //数据读出
endmodule
