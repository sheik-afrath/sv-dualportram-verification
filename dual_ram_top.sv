`timescale 1ns/100ps

module dual_ram_top();

bit clock = 0;

always #5 clock = ~clock;

dual_ram_io dr_io(clock);

dual_ram_test test(dr_io);

dual_port_ram dut (.clk(dr_io.clock),.rst(dr_io.rst),.we_A(dr_io.we_A),.we_B(dr_io.we_B),.addr_A(dr_io.addr_A),.addr_B(dr_io.addr_B),
.din_A(dr_io.din_A),.din_B(dr_io.din_B),.dout_A(dr_io.dout_A),.dout_B(dr_io.dout_B),.busy_B(dr_io.busy_B));

endmodule