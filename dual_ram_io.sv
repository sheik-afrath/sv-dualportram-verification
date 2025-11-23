`timescale 1ns/100ps

interface dual_ram_io(input bit clock);

	logic 	    rst;
	logic 	    we_A;
	logic [9:0] addr_A;
	logic [7:0] din_A;
	logic [7:0] dout_A;

	logic 	    we_B;
	logic [9:0] addr_B;
	logic [7:0] din_B;
	logic [7:0] dout_B;

	logic 	    busy_B;

	clocking cb@(posedge clock);
		default input #1ns output #1ns;
		output rst;
		output we_A;
		output addr_A;
		output din_A;
		input dout_A;

		output we_B;
		output addr_B;
		output din_B;
		input dout_B;

		input busy_B;
	endclocking: cb
	
	modport TB(clocking cb);

endinterface: dual_ram_io