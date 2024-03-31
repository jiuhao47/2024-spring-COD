module tb ();
  wire [2:0] out;  //必要输出信号
  reg clk;
  initial begin
    clk = 0;
    forever begin
      #5 clk = ~clk;
    end
  end
  dut dut1 (
      .clk(clk),
      .out(out)
  );
endmodule

module dut (
    input clk,
    output reg [2:0] out
);
  //测试模块
  always @(posedge clk) out <= out + 1'b1;
endmodule
