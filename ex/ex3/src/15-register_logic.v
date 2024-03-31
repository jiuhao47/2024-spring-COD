module top_module (
    input  clk,
    input  x,
    output z
);
  reg [2:0] Q;
  // 下面的语句是不可综合的，这个题目只是为了方便评测加上了下面的语句
  initial begin
    Q = 3'b0;
  end
  always @(posedge clk) begin
    Q[0] <= Q[0] ^ x;
    Q[1] <= (~Q[1]) & (x);
    Q[2] <= (~Q[2]) | (x);
  end

  assign z = ~(Q[0] | Q[1] | Q[2]);

endmodule
