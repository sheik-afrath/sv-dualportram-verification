program dual_ram_test(dual_ram_io.TB ram_intf);

int repeat_n_times; // Controls how many times the main test loop runs

// Local "shadow" memory to store expected data (what was written)
logic [7:0] MEM_WR[1024];
// Local memory to store actual data (what was read back)
logic [7:0] MEM_RD[1024];
// Bit-vector to track which addresses have been successfully written to
logic [1023:0] wr_done = '0;
// Bit-vector to track which addresses have been successfully read from
logic [1023:0] rd_done = '0;
logic error_flag = 0; // Set to 1 if any data mismatch occurs

logic [7:0]din_i1,din_i2; // Temporary variables for randomized data
logic [9:0]addr_i1,addr_i2; // Temporary variables for randomized addresses

// Enum to make port selection in tasks more readable
typedef enum {portA,portB} port_type;


// Task to reset the DUT (Design Under Test)
task reset();
	@(ram_intf.cb);
	ram_intf.cb.rst <= 1; // Assert reset
	repeat (2) @(ram_intf.cb); // Hold reset for 2 clock cycles
	ram_intf.cb.rst <= 0; // De-assert reset
	@(ram_intf.cb);
endtask: reset

// Task to generate new random addresses and data
task gen();
	din_i1 = $urandom_range(255);
	addr_i1 = $urandom_range(1024);
	din_i2 = $urandom_range(255);
	addr_i2 = $urandom_range(1024);
endtask: gen

// Task to perform a write operation on a specified port
task automatic write(input logic [9:0]addr, input logic [7:0]din, input port_type port);
	if (port == portA) begin // Write operation for Port A
		ram_intf.cb.we_A <= 1;
		ram_intf.cb.addr_A <= addr;
		ram_intf.cb.din_A <= din;
		wr_done[addr] = 1; // Mark this address as written in the shadow memory
		MEM_WR[addr] = din;
		repeat(2) @(ram_intf.cb); // Wait for the write to register
		$display("Data: %0d, written at address: %0d", din,addr);
	end
	else if (port == portB) begin // Write operation for Port B
		ram_intf.cb.we_B <= 1;
		ram_intf.cb.addr_B <= addr;
		ram_intf.cb.din_B <= din;
		repeat(2) @(ram_intf.cb); // Wait for the write to register
		if(!ram_intf.cb.busy_B) begin // Only log the write if Port B was not blocked by Port A
			wr_done[addr] = 1;
			MEM_WR[addr] = din;
			$display("Data: %0d, written at address: %0d", din,addr);
		end
	end
endtask: write

// Task to perform a read operation on a specified port
task automatic read(input logic [9:0]addr, input port_type port);
	if (port == portA) begin // Read operation for Port A
		ram_intf.cb.we_A <= 0;
		ram_intf.cb.addr_A <= addr;
		repeat(2) @(ram_intf.cb); // Wait for read data to appear on dout
		if(wr_done[addr] == 1) begin // Only store read data if we know a valid write occurred here
			rd_done[addr] = 1; // Mark this address as read
			MEM_RD[addr] = ram_intf.cb.dout_A; // Store the read-back data
		end
	end
	else if (port == portB) begin // Read operation for Port B
		ram_intf.cb.we_B <= 0;
		ram_intf.cb.addr_B <= addr;
		repeat(2) @(ram_intf.cb); // Wait for read data to appear on dout
		if(!ram_intf.cb.busy_B && wr_done[addr] == 1) begin // Only store if not busy and valid write occurred
			rd_done[addr] = 1;
			MEM_RD[addr] = ram_intf.cb.dout_B;
		end
	end
endtask: read

// Task to test concurrent writes to both ports
task automatic writenwrite(input port_type port1, input port_type port2, input logic [9:0]addr1,
						   input logic [7:0]din1, input logic [9:0]addr2, input logic [7:0]din2);
	fork // Execute both write operations concurrently
		if(!wr_done[addr1]) write(.addr(addr1),.din(din1),.port(port1));
		if(!wr_done[addr2]) write(.addr(addr2),.din(din2),.port(port2));
	join
endtask: writenwrite

// Task to test concurrent reads from both ports
task automatic readnread(input port_type port1, input port_type port2, input logic [9:0]addr1, input logic [9:0]addr2);
	fork // Execute both read operations concurrently
		read(.addr(addr1),.port(port1));
		read(.addr(addr2),.port(port2));
	join
endtask: readnread

// Task to test concurrent read from one port and write to the other
task automatic readnwrite(input port_type port1, input port_type port2, input logic [9:0]addr1, input logic [9:0]addr2, input logic[7:0]din2);
	fork // Execute read and write operations concurrently
		read(.addr(addr1),.port(port1));
		if(!wr_done[addr2]) write(.addr(addr2),.din(din2),.port(port2));
	join
endtask: readnwrite

// Task to test concurrent write to one port and read from the other
task automatic writenread(input port_type port1, input port_type port2, input logic [9:0]addr1, input logic[7:0]din1, input logic [9:0]addr2);
	fork // Execute write and read operations concurrently
		if(!wr_done[addr1]) write(.addr(addr1),.din(din1),.port(port1));
		read(.addr(addr2),.port(port2));
	join
endtask: writenread


// Main test sequence task, combining all concurrent scenarios
task tester();
	gen(); // Generate new random addresses and data
	writenwrite(.port1(portA),.port2(portB),.addr1(addr_i1),.addr2(addr_i2),.din1(din_i1),.din2(din_i2));

	gen(); // Get new random values
	readnread(.port1(portA),.port2(portB),.addr1(addr_i1),.addr2(addr_i2));

	gen(); // Get new random values
	readnwrite(.port1(portA),.port2(portB),.addr1(addr_i1),.addr2(addr_i2),.din2(din_i2));

	gen(); // Get new random values
	writenread(.port1(portA),.port2(portB),.addr1(addr_i1),.addr2(addr_i2),.din1(din_i1));
endtask: tester


// Final check task to compare written and read data from the shadow memories
task check();
	for (int i = 0; i<1024; i++) begin
		if(wr_done[i] == 1 && rd_done[i] == 1) begin // Only check addresses that were both written and read
			if(MEM_WR[i] != MEM_RD[i]) begin
				$display("Error! Write and read data mismatch at address %0d!",i);
				error_flag = 1; // Set error flag on mismatch
			end
			else begin
				$display("MEM_WR[%0d] = %0d; MEM_RD[%0d] = %0d", i,MEM_WR[i], i, MEM_RD[i]);
				$display("Data at address %0d written and read correctly!", i);
			end
		end
	end

	if(!error_flag) $display("TEST PASSED!"); // Final test status
	else $display("TEST FAILED!");
endtask: check




// covergroup to collect functional coverage
    covergroup RamAccessCG @(ram_intf.cb);
        option.per_instance = 1;

        // This measures what Port A and Port B are doing
        cp_we_A  : coverpoint ram_intf.cb.we_A  { bins write = {1}; bins read = {0}; }
        cp_we_B  : coverpoint ram_intf.cb.we_B  { bins write = {1}; bins read = {0}; }
        
        // This checks if the addresses are the same or different
        cp_addr_match : coverpoint (ram_intf.cb.addr_A == ram_intf.cb.addr_B) {
            bins same_addr = {1};
            bins diff_addr = {0};
        }

        // This is the most powerful part. It measures combinations of events.
        cross cp_we_A, cp_we_B, cp_addr_match {
            // We want to ignore cases where nothing is happening (read/read)
            ignore_bins no_write = binsof(cp_we_A.read) && binsof(cp_we_B.read);
        }
    endgroup

    RamAccessCG ram_cg = new();



initial begin
	repeat_n_times = 2000; // Set the number of test iterations
	reset(); // Apply reset to the DUT

	repeat(repeat_n_times) begin // Main test loop
		tester(); // Run the combined test scenario
	end

	repeat(10) @(ram_intf.cb); // Wait for any pending operations to flush
	check(); // Run the final data comparison

	repeat(10) @(ram_intf.cb); // Wait a bit more

	$display("Functional Coverage: %f%%", ram_cg.get_coverage());

	$stop; // End simulation
end
endprogram