module top_module (
    input  a,
    input  b,
    output out
);

  mod_a mod_a_1 (
      .in1(a),
      .in2(b),
      .out(out)
  );

endmodule


module mod_a (
    input  in1,
    input  in2,
    output out
);
  assign out = in1 & in2;
endmodule
