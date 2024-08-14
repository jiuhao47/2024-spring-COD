module top_module (
    input a,
    input b,
    input sel_b1,
    input sel_b2,
    output wire out_assign,
    output reg out_always
);
  assign out_assign = (sel_b1 & sel_b2) ? b : a;
  always @(a, b, sel_b2, sel_b1) begin
    if (sel_b2 & sel_b1) begin
      out_always = b;
    end else begin
      out_always = a;
    end
  end

endmodule
