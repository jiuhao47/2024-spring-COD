module top_module (
    input      cpu_overheated,
    output reg shut_off_computer,
    input      arrived,
    input      gas_tank_empty,
    output reg keep_driving
);
  always @(*) begin
    shut_off_computer = (cpu_overheated) ? 1 : 0;
    keep_driving = (arrived) ? 0 : ~gas_tank_empty;
  end

endmodule
