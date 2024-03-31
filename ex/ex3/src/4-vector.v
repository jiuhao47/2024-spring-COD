module top_module (
    input  [4:0] a,
    b,
    c,
    d,
    e,
    f,
    output [7:0] w,
    x,
    y,
    z
);
  wire [31:0] vec;
  assign vec = {a, b, c, d, e, f, 2'b11};
  assign w   = vec[31:24];
  assign x   = vec[23:16];
  assign y   = vec[15:8];
  assign z   = vec[7:0];
endmodule
