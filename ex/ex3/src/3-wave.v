module top_module (
    input  sel,
    input  a,
    input  b,
    output out
);
  assign out = sel ? b : a;
endmodule
