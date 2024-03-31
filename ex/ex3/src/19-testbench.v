module tb ();
  reg a;
  reg b;

  initial begin
    a = 1'b1;
    b = 1'b0;
    #10 b = 1'b1;
    #10 a = 1'b0;
    #10 b = 1'b0;
    #10 a = 1'b1;
    #10 $finish();
  end
endmodule
