module my_dff (
    input clk,
    input d,
    output reg q
);
  always @(posedge clk) q <= d;
endmodule

module top_module (
    input  clk,
    input  d,
    output q
);
  wire mid1, mid2;
  my_dff dff1 (
      clk,
      d,
      mid1
  );
  my_dff dff2 (
      clk,
      mid1,
      mid2
  );
  my_dff dff3 (
      clk,
      mid2,
      q
  );

endmodule
