module dual_port_ram (
    	input  wire         clk,       		// system clock
    	input  wire         rst,       		// synchronous active-high reset

    	input  wire         we_A,        	// write enable of Port A
    	input  wire  [9:0]  addr_A,     	// address of Port A
    	input  wire  [7:0]  din_A,       	// write data of Port A
	output reg   [7:0]  dout_A,			// read data of Port A

    	input  wire         we_B,        	// write enable of Port B
    	input  wire  [9:0]  addr_B,     	// address Port B
    	input  wire  [7:0]  din_B,       	// write data Port B
	output reg   [7:0]  dout_B,		// read data Port B
	
	output reg busy_B			// port A is given priority, if Port A is writing data, 
						// busy_B signal will be asserted which may be connected to the device connected to Port B
						// and the device connected to Port B may wait till the busy_B signal goes down to do read/write.
);

// 1KB memory array
reg [7:0] mem [0:1023];

always @(posedge clk) begin
    if (rst) begin
        dout_A <= 8'd0;                 			// clear only o/p on reset
	dout_B <= 8'b0;
    end 
	else begin
        if (we_A) begin						// Port A writing data
			mem[addr_A] <= din_A;
			
			if (addr_A == addr_B)
				busy_B = 1'b1;			// if Port B tries to read/write the same address as Port A, busy_B is asserted 
			else begin
			    busy_B = 1'b0; 
				if (we_B) begin			// port B writing data
					mem[addr_B] <= din_B;
				end
				else if(!we_B) begin			// port B reading data
					dout_B <= mem[addr_B];
				end
				else dout_B <= 0;
			end
		end
		else if(!we_A) begin 					// Port A reading Data
			dout_A <= mem[addr_A];
			
			if (we_B) begin				// Port B writing Data
				if (addr_A == addr_B)	
					busy_B = 1'b1;		// Port B writing data of the same address as Port A reading, as Port A has high priority- busy_B is asserted
				else begin			// Port B reading Data
				    busy_B = 1'b0; 
					mem[addr_B] <= din_B;
				end
			end
			else if(!we_B) begin				// Port B reading data
		        busy_B = 1'b0;
				dout_B <= mem[addr_B];
			end
			else dout_B <= 0;
		end
		else dout_A <= 0;
	end	
end

endmodule