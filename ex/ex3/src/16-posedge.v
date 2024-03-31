module top_module (
    input clk,
    input in,
    output reg out
);
  initial begin
    out <= 0;
  end
  // Write your code here
  reg mid;
  always @(posedge clk) begin
    mid <= in;
    if (in) begin
      out <= mid ^ in;
    end
  end

endmodule
