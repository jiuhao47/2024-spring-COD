module top_module (
    input  clk,
    input  areset,  // Asynchronous reset to state B
    input  in,
    output out
);  //  

  parameter A = 0, B = 1;
  reg state, next_state;

  always @(*) begin
    if (state == B) begin
      if (in) begin
        next_state <= B;
      end else begin
        next_state <= A;
      end
    end else begin
      if (in) begin
        next_state <= A;
      end else begin
        next_state <= B;
      end
    end
  end

  always @(posedge clk, posedge areset) begin
    if (areset) begin
      state <= B;
      next_state <= B;
    end else begin
      state <= next_state;
    end
  end
  assign out = (state == B) ? 1 : 0;
endmodule
