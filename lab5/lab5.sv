// A full memory hierarchy. 
//
// Parameter:
// MODEL_NUMBER: A number used to specify a specific instance of the memory.  Different numbers give different hierarchies and settings.
//   This should be set to your student ID number.
// DMEM_ADDRESS_WIDTH: The number of bits of address for the memory.  Sets the total capacity of main memory.
//
// Accesses: To do an access, set address, data_in, byte_access, and write to a desired value, and set start_access to 1.
//   All these signals must be held constant until access_done, at which point the operation is completed.  On a read,
//   data_out will be set to the correct data for the single cycle when access_done is true.  Note that you can do
//   back-to-back accesses - when access_done is true, if you keep start_access true the memory will start the next access.
// 
//   When start_access = 0, the other input values do not matter.
//   bytemask controls which bytes are actually written (ignored on a read).
//     If bytemask[i] == 1, we do write the byte from data_in[8*i+7 : 8*i] to memory at the corresponding position.  If == 0, that byte not written.
//   To do a read: write = 0,  data_in does not matter.  data_out will have the proper data for the single cycle where access_done==1.
//   On a write, write = 1 and data_in must have the data to write.
//
//   Addresses must be aligned.  Since this is a 64-bit memory (8 bytes), the bottom 3 bits of each address must be 0.
//
//   It is an error to set start_access to 1 and then either set start_access to 0 or change any other input before access_done = 1.
//
//   Accessor tasks (essentially subroutines for testbenches) are provided below to help do most kinds of accesses.

// Line to set up the timing of simulation: says units to use are ns, and smallest resolution is 10ps.
`timescale 1ns/10ps

module lab5 #(parameter [22:0] MODEL_NUMBER = 2335095, parameter DMEM_ADDRESS_WIDTH = 20) (
	// Commands:
	//   (Comes from processor).
	input		logic [DMEM_ADDRESS_WIDTH-1:0]	address,			// The byte address.  Must be word-aligned if byte_access != 1.
	input		logic [63:0]							data_in,			// The data to write.  Ignored on a read.
	input		logic [7:0]								bytemask,		// Only those bytes whose bit is set are written.  Ignored on a read.
	input		logic										write,			// 1 = write, 0 = read.
	input		logic										start_access,	// Starts a memory access.  Once this is true, all command inputs must be stable until access_done becomes 1. 
	output	logic										access_done,	// Set to true on the clock edge that the access is completed.
	output	logic	[63:0]							data_out,		// Valid when access_done == 1 and access is a read.
	// Control signals:
	input		logic										clk,
	input		logic										reset				// A reset will invalidate all cache entries, and return main memory to the default initial values.
); 
	
	DataMemory #(.MODEL_NUMBER(MODEL_NUMBER), .DMEM_ADDRESS_WIDTH(DMEM_ADDRESS_WIDTH)) dmem
		(.address, .data_in, .bytemask, .write, .start_access, .access_done, .data_out, .clk, .reset);
	
	always @(posedge clk)
		assert(reset !== 0 || start_access == 0 || address[2:0] == 0); // All accesses must be aligned.
	
endmodule

// Test the data memory, and figure out the settings.

module lab5_testbench ();
	localparam USERID = 2335095;  // Set to your student ID #
	localparam ADDRESS_WIDTH = 20;
	localparam DATA_WIDTH = 8;
	
	logic [ADDRESS_WIDTH-1:0]			address;		   // The byte address.  Must be word-aligned if byte_access != 1.
	logic [63:0]							data_in;			// The data to write.  Ignored on a read.
	logic [7:0]								bytemask;		// Only those bytes whose bit is set are written.  Ignored on a read.
	logic										write;			// 1 = write, 0 = read.
	logic										start_access;	// Starts a memory access.  Once this is true, all command inputs must be stable until access_done becomes 1. 
	logic										access_done;	// Set to true on the clock edge that the access is completed.
	logic	[63:0]							data_out;		// Valid when access_done == 1 and access is a read.
	// Control signals:
	logic										clk;
	logic										reset;				// A reset will invalidate all cache entries, and return main memory to the default initial values.

	lab5 #(.MODEL_NUMBER(USERID), .DMEM_ADDRESS_WIDTH(ADDRESS_WIDTH)) dut
		(.address, .data_in, .bytemask, .write, .start_access, .access_done, .data_out, .clk, .reset); 

	// Set up the clock.
	parameter CLOCK_PERIOD=10;
	initial begin
		clk <= 0;
		forever #(CLOCK_PERIOD/2) clk <= ~clk;
	end

	// Force %t's to print in a nice format.
	initial $timeformat(-9, 5, " ns", 10);

	// --- Keep track of number of clock cycles, for statistics.
	integer cycles;
	always @(posedge clk) begin
		if (reset)
			cycles <= 0;
		else
			cycles <= cycles + 1;
	end
		
	// --- Tasks are subroutines for doing various operations.  These provide read and write actions.
	
	// Set memory controls to an idle state, no accesses going.
	task mem_idle;
		address			<= 'x;
		data_in			<= 'x;
		bytemask			<= 'x;
		write				<= 'x;
		start_access	<= 0;
		#1;
	endtask
	
	// Perform a read, and return the resulting data in the read_data output.
	// Note: waits for complete cycle of "access_done", so spends 1 cycle more than the access time.
	task readMem;
		input		[ADDRESS_WIDTH-1:0]		read_addr;
		output	[DATA_WIDTH-1:0][7:0]	read_data;
		output	int							delay;		// Access time actually seen.
		
		int startTime, endTime;
		
		startTime = cycles;
		address			<= read_addr;
		data_in			<= 'x;
		bytemask			<= 'x;
		write				<= 0;
		start_access	<= 1;
		@(posedge clk);
		while (~access_done) begin
			@(posedge clk);
		end
		mem_idle(); #1;
		read_data = data_out;
		endTime = cycles;
		delay = endTime - startTime - 1;
	endtask
	
	function int min;
		input int x;
		input int y;
		
		min = ((x<y) ? x : y);
	endfunction
	function int max;
		input int x;
		input int y;
		
		max = ((x>y) ? x : y);
	endfunction
	
	// Perform a series of reads, and returns the min and max access times seen.
	// Accesses are at read_addr, read_addr+stride, read_addr+2*stride, ... read_addr+(num_reads-1)*stride.
	task readStride;
		input		[ADDRESS_WIDTH-1:0]		read_addr;
		input		int							stride;
		input		int							num_reads;
		output	int							min_delay;	// Fastest access time actually seen.
		output	int							max_delay;	// Slowest access time actually seen.
		
		int i, delay;
		logic [DATA_WIDTH-1:0][7:0]		read_data;
		
		//$display("%t readStride(%d, %d, %d)", $time, read_addr, stride, num_reads);
		readMem(read_addr, read_data, delay);
		min_delay = delay;
		max_delay = delay;
		//$display("1  delay: %d", delay);
		
		for(i=1; i<num_reads; i++) begin
			readMem(read_addr+stride*i, read_data, delay);
			min_delay = min(min_delay, delay);
			max_delay = max(max_delay, delay);
			//$display("2  delay: %d", delay);
		end
		//$display("%t min_delay: %d max_delay: %d", $time, min_delay, max_delay);

		mem_idle(); #1;
	endtask
	
	// Perform a write.
	// Note: waits for complete cycle of "access_done", so spends 1 cycle more than the access time.
	task writeMem;
		input [ADDRESS_WIDTH-1:0]			write_address;
		input [DATA_WIDTH-1:0][7:0]		write_data;
		input [DATA_WIDTH-1:0]				write_bytemask;
		output	int							delay;		// Access time actually seen.
		
		int	startTime, endTime;
		
		startTime = cycles;
		address			<= write_address;
		data_in			<= write_data;
		bytemask			<= write_bytemask;
		write				<= 1;
		start_access	<= 1;
		@(posedge clk);
		while (~access_done) begin
			@(posedge clk);
		end
		mem_idle(); #1;
		endTime = cycles;
		delay = endTime - startTime - 1;
	endtask
	
	// Perform a series of writes, and returns the min and max access times seen.
	// Accesses are at write_addr, write_addr+stride, write_addr+2*stride, ... write_addr+(num_writes-1)*stride.
	task writeStride;
		input		[ADDRESS_WIDTH-1:0]		write_addr;
		input		int							stride;
		input		int							num_writes;
		output	int							min_delay;	// Fastest access time actually seen.
		output	int							max_delay;	// Slowest access time actually seen.
		
		int i, delay;
		logic [DATA_WIDTH-1:0][7:0]		write_data;
		
		//$display("%t writeStride(%d, %d, %d)", $time, write_addr, stride, num_writes);
		writeMem(write_addr, write_data, 8'hFF, delay);
		min_delay = delay;
		max_delay = delay;
		//$display("1  delay: %d", delay);
		
		for(i=1; i<num_writes; i++) begin
			writeMem(write_addr+stride*i, write_data, 8'hFF, delay);
			min_delay = min(min_delay, delay);
			max_delay = max(max_delay, delay);
			//$display("2  delay: %d", delay);
		end
		//$display("%t min_delay: %d max_delay: %d", $time, min_delay, max_delay);

		mem_idle(); #1;
	endtask
	
	// Skip doing an access for a cycle.
	task noopMem;
		mem_idle();
		@(posedge clk); #1;
	endtask
	
	// Reset the memory.
	task resetMem;
		mem_idle();
		reset <= 1;
		@(posedge clk);
		reset <= 0;
		#1;
	endtask
	
	logic	[DATA_WIDTH-1:0][7:0]	dummy_data;
	logic [ADDRESS_WIDTH-1:0]		addr;
	int	i, delay, minval, maxval;
	int hit_time, l1_blocksize, l1_num_blocks, off, num_loaded;
	int l1_assoc, write_hit_delay, write_miss_delay, read_miss_delay;
	int conflict_stride, n;
	int l2_hit_time, l2_blocksize, l2_num_blocks, l2_assoc, l2_conflict_stride;
	int full_miss_time, l2_write_hit_delay;
	int l3_present, l3_hit_time, l3_blocksize, l3_num_blocks, l3_assoc, l3_conflict_stride;
	int l3_write_hit_delay;
	localparam int HIT_MARGIN = 2;
	localparam int L2_HIT_MARGIN = 4;
	localparam int L3_HIT_MARGIN = 4;
	
	initial begin
		dummy_data <= '0;
		resetMem();
		
		// --- L1 block size ---
		// Warm block 0, then scan aligned addresses until the first L1 miss.
		$display("=== L1 block size ===");
		readMem(0, dummy_data, delay);				// cold miss, loads block 0
		readMem(0, dummy_data, hit_time);			// L1 hit baseline
		$display("  L1 hit time: %0d cycles", hit_time);
		l1_blocksize = 0;
		for (off = 8; off < 4096; off = off + 8) begin
			readMem(off, dummy_data, delay);
			$display("  addr %0d => %0d cycles", off, delay);
			if (delay > hit_time + HIT_MARGIN) begin
				l1_blocksize = off;
				break;
			end
		end
		if (l1_blocksize == 0)
			$display("  Could not determine L1 block size");
		else
			$display("  L1 block size: %0d bytes", l1_blocksize);
		
		// --- L1 number of blocks ---
		// Fill the cache one block at a time; re-read block 0 after each load.
		if (l1_blocksize != 0) begin
			$display("=== L1 number of blocks ===");
			resetMem();
			l1_num_blocks = 0;
			for (num_loaded = 1; num_loaded <= 256; num_loaded = num_loaded + 1) begin
				readMem((num_loaded - 1) * l1_blocksize, dummy_data, delay);
				readMem(0, dummy_data, delay);
				if (delay > hit_time + HIT_MARGIN) begin
					l1_num_blocks = num_loaded - 1;
					break;
				end
			end
			if (l1_num_blocks == 0)
				$display("  L1 num blocks: >256 (or set-associative indexing)");
			else
				$display("  L1 num blocks: %0d", l1_num_blocks);
		end
		
		if (l1_blocksize != 0 && l1_num_blocks != 0) begin
			conflict_stride = l1_num_blocks * l1_blocksize;
			
			// --- L1 associativity ---
			// Addresses 0, conflict_stride, 2*conflict_stride, ... map to the same set.
			// Direct mapped: loading the 2nd evicts the 1st. N-way: N can coexist.
			$display("=== L1 associativity ===");
			resetMem();
			readMem(0, dummy_data, delay);
			readMem(conflict_stride, dummy_data, delay);
			readMem(0, dummy_data, delay);
			if (delay <= hit_time + HIT_MARGIN) begin
				l1_assoc = 0;
				resetMem();
				for (n = 1; n <= l1_num_blocks + 1; n = n + 1) begin
					readMem((n - 1) * conflict_stride, dummy_data, delay);
					readMem(0, dummy_data, delay);
					if (delay > hit_time + HIT_MARGIN) begin
						l1_assoc = n - 1;
						break;
					end
				end
				if (l1_assoc == 0)
					$display("  L1 associativity: >%0d (fully associative?)", l1_num_blocks);
				else if (l1_assoc == l1_num_blocks)
					$display("  L1 associativity: %0d (fully associative)", l1_assoc);
				else
					$display("  L1 associativity: %0d (%0d-way set associative)", l1_assoc, l1_assoc);
			end else begin
				l1_assoc = 1;
				$display("  L1 associativity: 1 (direct mapped)");
			end
			
			// --- L1 replacement strategy (skip if direct mapped) ---
			if (l1_assoc > 1) begin
				$display("=== L1 replacement strategy ===");
				// Fill one set, touch the first block to make it MRU, add one more to evict.
				// LRU evicts the untouched block; random may differ.
				resetMem();
				for (n = 0; n < l1_assoc; n = n + 1)
					readMem(n * conflict_stride, dummy_data, delay);
				readMem(0, dummy_data, delay);						// touch block 0 -> makes block 1 LRU (for 2-way)
				readMem(l1_assoc * conflict_stride, dummy_data, delay);	// force eviction in this set
				readMem(conflict_stride, dummy_data, delay);			// check block 1
				if (delay > hit_time + HIT_MARGIN)
					$display("  Replacement: 1 (LRU) - untouched block was evicted");
				else begin
					readMem(0, dummy_data, delay);
					if (delay > hit_time + HIT_MARGIN)
						$display("  Replacement: 0 (Random) - touched block was evicted");
					else
						$display("  Replacement: inconclusive");
				end
			end else
				$display("=== L1 replacement strategy === (skipped - direct mapped)");
			
			// --- L1 write policy ---
			// Write-back: write hit ~ read hit. Write-through: write hit must also reach L2 (slower).
			$display("=== L1 write policy ===");
			resetMem();
			readMem(0, dummy_data, read_miss_delay);
			readMem(0, dummy_data, delay);
			dummy_data = 64'hDEADBEEF_CAFEBABE;
			writeMem(0, dummy_data, 8'hFF, write_hit_delay);
			$display("  Write hit: %0d cycles (read hit: %0d)", write_hit_delay, hit_time);
			resetMem();
			dummy_data = 64'h12345678_9ABCDEF0;
			writeMem(0, dummy_data, 8'hFF, write_miss_delay);
			readMem(0, dummy_data, read_miss_delay);
			$display("  Write miss: %0d cycles, cold read: %0d cycles", write_miss_delay, read_miss_delay);
			if (write_hit_delay <= hit_time + HIT_MARGIN)
				$display("  Write policy: 0 (Write-Back) - write hit as fast as read hit");
			else
				$display("  Write policy: 1 (Write-Through) - write hit slower than read hit");
			
			// --- L1 write buffer (only applies to write-through) ---
			$display("=== L1 write buffer ===");
			if (write_hit_delay <= hit_time + HIT_MARGIN) begin
				// Write-back: dirty lines stay in L1; no write-through buffer needed.
				$display("  Write buffer: no (write-back cache)");
			end else begin
				resetMem();
				readMem(0, dummy_data, delay);
				dummy_data = 64'hAABBCCDD_EEFF0011;
				writeMem(0, dummy_data, 8'hFF, delay);
				dummy_data = 64'h11223344_55667788;
				writeMem(8, dummy_data, 8'hFF, write_hit_delay);
				dummy_data = 64'h99AABBCC_DDEEF011;
				writeMem(0, dummy_data, 8'hFF, write_miss_delay);
				$display("  Back-to-back write hits: %0d then %0d cycles", write_hit_delay, write_miss_delay);
				if (write_hit_delay <= hit_time + HIT_MARGIN && write_miss_delay <= hit_time + HIT_MARGIN)
					$display("  Write buffer: yes");
				else
					$display("  Write buffer: no");
			end
		end
		
		// --- L2 cache (observe via L1 misses) ---
		if (l1_blocksize != 0 && l1_num_blocks != 0) begin
			$display("");
			$display("=== L2 block size ===");
			resetMem();
			readMem(0, dummy_data, full_miss_time);
			readMem(l1_blocksize, dummy_data, l2_hit_time);
			$display("  Full miss: %0d cycles, L1-miss/L2-hit baseline: %0d cycles", full_miss_time, l2_hit_time);
			l2_blocksize = 0;
			for (off = 2 * l1_blocksize; off < 65536; off = off + l1_blocksize) begin
				readMem(off, dummy_data, delay);
				$display("  addr %0d => %0d cycles", off, delay);
				if (delay > l2_hit_time + L2_HIT_MARGIN) begin
					l2_blocksize = off;
					break;
				end
			end
			if (l2_blocksize == 0)
				$display("  Could not determine L2 block size");
			else
				$display("  L2 block size: %0d bytes", l2_blocksize);
			
			if (l2_blocksize != 0) begin
				$display("=== L2 hit time ===");
				$display("  L2 hit time: %0d cycles", l2_hit_time);
				
				$display("=== L2 number of blocks ===");
				resetMem();
				l2_num_blocks = 0;
				for (num_loaded = 1; num_loaded <= 512; num_loaded = num_loaded + 1) begin
					readMem((num_loaded - 1) * l2_blocksize, dummy_data, delay);
					readMem(0, dummy_data, delay);
					if (delay > l2_hit_time + L2_HIT_MARGIN) begin
						l2_num_blocks = num_loaded - 1;
						break;
					end
				end
				if (l2_num_blocks == 0)
					$display("  L2 num blocks: >512");
				else
					$display("  L2 num blocks: %0d", l2_num_blocks);
				
				if (l2_num_blocks != 0) begin
				l2_conflict_stride = l2_num_blocks * l2_blocksize;
				
				$display("=== L2 associativity ===");
				resetMem();
				readMem(0, dummy_data, delay);
				readMem(l2_conflict_stride, dummy_data, delay);
				readMem(0, dummy_data, delay);
				if (delay <= l2_hit_time + L2_HIT_MARGIN) begin
					l2_assoc = 0;
					resetMem();
					for (n = 1; n <= l2_num_blocks + 1; n = n + 1) begin
						readMem((n - 1) * l2_conflict_stride, dummy_data, delay);
						readMem(0, dummy_data, delay);
						if (delay > l2_hit_time + L2_HIT_MARGIN) begin
							l2_assoc = n - 1;
							break;
						end
					end
					if (l2_assoc == 0)
						$display("  L2 associativity: >%0d (fully associative?)", l2_num_blocks);
					else if (l2_assoc == l2_num_blocks)
						$display("  L2 associativity: %0d (fully associative)", l2_assoc);
					else
						$display("  L2 associativity: %0d (%0d-way set associative)", l2_assoc, l2_assoc);
				end else begin
					l2_assoc = 1;
					$display("  L2 associativity: 1 (direct mapped)");
				end
				
				if (l2_assoc > 1) begin
					$display("=== L2 replacement strategy ===");
					resetMem();
					for (n = 0; n < l2_assoc; n = n + 1)
						readMem(n * l2_conflict_stride, dummy_data, delay);
					readMem(0, dummy_data, delay);
					readMem(l2_assoc * l2_conflict_stride, dummy_data, delay);
					readMem(l2_conflict_stride, dummy_data, delay);
				if (delay > l2_hit_time + L2_HIT_MARGIN)
					$display("  Replacement: 1 (LRU) - untouched block was evicted");
				else begin
					readMem(0, dummy_data, delay);
					if (delay > l2_hit_time + L2_HIT_MARGIN)
						$display("  Replacement: 0 (Random) - touched block was evicted");
					else
						$display("  Replacement: inconclusive");
				end
				end else
					$display("=== L2 replacement strategy === (skipped - direct mapped)");
				
				$display("=== L2 write policy ===");
				resetMem();
				readMem(0, dummy_data, delay);
				readMem(conflict_stride, dummy_data, delay);
				dummy_data = 64'hDEADBEEF_CAFEBABE;
				writeMem(0, dummy_data, 8'hFF, l2_write_hit_delay);
				$display("  L2 write hit (L1 miss): %0d cycles (L2 read hit: %0d)", l2_write_hit_delay, l2_hit_time);
				if (l2_write_hit_delay <= l2_hit_time + L2_HIT_MARGIN)
					$display("  Write policy: 0 (Write-Back)");
				else
					$display("  Write policy: 1 (Write-Through)");
				
				$display("=== L2 write buffer ===");
				if (l2_write_hit_delay <= l2_hit_time + L2_HIT_MARGIN) begin
					$display("  Write buffer: no (write-back cache)");
				end else begin
					resetMem();
					readMem(0, dummy_data, delay);
					readMem(conflict_stride, dummy_data, delay);
					dummy_data = 64'hAABBCCDD_EEFF0011;
					writeMem(0, dummy_data, 8'hFF, delay);
					readMem(l1_blocksize, dummy_data, delay);
					dummy_data = 64'h11223344_55667788;
					writeMem(l1_blocksize, dummy_data, 8'hFF, write_hit_delay);
					dummy_data = 64'h99AABBCC_DDEEF011;
					writeMem(0, dummy_data, 8'hFF, write_miss_delay);
					$display("  Back-to-back L2 writes: %0d then %0d cycles", write_hit_delay, write_miss_delay);
					if (write_hit_delay <= l2_hit_time + L2_HIT_MARGIN && write_miss_delay <= l2_hit_time + L2_HIT_MARGIN)
						$display("  Write buffer: yes");
					else
						$display("  Write buffer: no");
				end
				end
			end
		end
		
		// --- L3 cache (observe via L1 and L2 misses) ---
		if (l2_blocksize != 0 && l2_hit_time != 0 && full_miss_time != 0) begin
			$display("");
			$display("=== L3 present? ===");
			resetMem();
			readMem(0, dummy_data, full_miss_time);
			readMem(l2_blocksize, dummy_data, delay);
			$display("  After cold read 0, read %0d => %0d cycles (L2 hit=%0d, full miss=%0d)",
				l2_blocksize, delay, l2_hit_time, full_miss_time);
			if (delay > l2_hit_time + L2_HIT_MARGIN && delay < full_miss_time - L3_HIT_MARGIN) begin
				l3_present = 1;
				l3_hit_time = delay;
				$display("  L3 cache: yes (L1/L2 miss, L3 hit = %0d cycles)", l3_hit_time);
			end else begin
				l3_present = 0;
				$display("  L3 cache: no (skip remaining L3 questions)");
			end
			
			if (l3_present) begin
				$display("=== L3 block size ===");
				resetMem();
				readMem(0, dummy_data, delay);
				readMem(l2_blocksize, dummy_data, l3_hit_time);
				l3_blocksize = 0;
				for (off = 2 * l2_blocksize; off < 262144; off = off + l2_blocksize) begin
					readMem(off, dummy_data, delay);
					$display("  addr %0d => %0d cycles", off, delay);
					if (delay >= full_miss_time - L3_HIT_MARGIN) begin
						l3_blocksize = off;
						break;
					end
				end
				if (l3_blocksize == 0)
					$display("  Could not determine L3 block size");
				else
					$display("  L3 block size: %0d bytes", l3_blocksize);
				
				if (l3_blocksize != 0) begin
					$display("=== L3 hit time ===");
					$display("  L3 hit time: %0d cycles", l3_hit_time);
					
					$display("=== L3 number of blocks ===");
					resetMem();
					l3_num_blocks = 0;
					for (num_loaded = 1; num_loaded <= 512; num_loaded = num_loaded + 1) begin
						readMem((num_loaded - 1) * l3_blocksize, dummy_data, delay);
						readMem(0, dummy_data, delay);
						if (delay >= full_miss_time - L3_HIT_MARGIN) begin
							l3_num_blocks = num_loaded - 1;
							break;
						end
					end
					if (l3_num_blocks == 0)
						$display("  L3 num blocks: >512");
					else
						$display("  L3 num blocks: %0d", l3_num_blocks);
					
					if (l3_num_blocks != 0) begin
						l3_conflict_stride = l3_num_blocks * l3_blocksize;
						
						$display("=== L3 associativity ===");
						resetMem();
						readMem(0, dummy_data, delay);
						readMem(l3_conflict_stride, dummy_data, delay);
						readMem(0, dummy_data, delay);
						if (delay < full_miss_time - L3_HIT_MARGIN) begin
							l3_assoc = 0;
							resetMem();
							for (n = 1; n <= l3_num_blocks + 1; n = n + 1) begin
								readMem((n - 1) * l3_conflict_stride, dummy_data, delay);
								readMem(0, dummy_data, delay);
								if (delay >= full_miss_time - L3_HIT_MARGIN) begin
									l3_assoc = n - 1;
									break;
								end
							end
							if (l3_assoc == 0)
								$display("  L3 associativity: >%0d (fully associative?)", l3_num_blocks);
							else if (l3_assoc == l3_num_blocks)
								$display("  L3 associativity: %0d (fully associative)", l3_assoc);
							else
								$display("  L3 associativity: %0d (%0d-way set associative)", l3_assoc, l3_assoc);
						end else begin
							l3_assoc = 1;
							$display("  L3 associativity: 1 (direct mapped)");
						end
						
						if (l3_assoc > 1) begin
							$display("=== L3 replacement strategy ===");
							resetMem();
							for (n = 0; n < l3_assoc; n = n + 1)
								readMem(n * l3_conflict_stride, dummy_data, delay);
							readMem(0, dummy_data, delay);
							readMem(l3_assoc * l3_conflict_stride, dummy_data, delay);
							readMem(l3_conflict_stride, dummy_data, delay);
							if (delay >= full_miss_time - L3_HIT_MARGIN)
								$display("  Replacement: 1 (LRU) - untouched block was evicted");
							else begin
								readMem(0, dummy_data, delay);
								if (delay >= full_miss_time - L3_HIT_MARGIN)
									$display("  Replacement: 0 (Random) - touched block was evicted");
								else
									$display("  Replacement: inconclusive");
							end
						end else
							$display("=== L3 replacement strategy === (skipped - direct mapped)");
						
						$display("=== L3 write policy ===");
						resetMem();
						readMem(0, dummy_data, delay);
						readMem(l2_conflict_stride, dummy_data, delay);
						dummy_data = 64'hDEADBEEF_CAFEBABE;
						writeMem(0, dummy_data, 8'hFF, l3_write_hit_delay);
						$display("  L3 write hit (L1/L2 miss): %0d cycles (L3 read hit: %0d)",
							l3_write_hit_delay, l3_hit_time);
						if (l3_write_hit_delay <= l3_hit_time + L3_HIT_MARGIN)
							$display("  Write policy: 0 (Write-Back)");
						else
							$display("  Write policy: 1 (Write-Through)");
						
						$display("=== L3 write buffer ===");
						if (l3_write_hit_delay <= l3_hit_time + L3_HIT_MARGIN)
							$display("  Write buffer: no (write-back cache)");
						else begin
							resetMem();
							readMem(0, dummy_data, delay);
							readMem(l2_conflict_stride, dummy_data, delay);
							dummy_data = 64'hAABBCCDD_EEFF0011;
							writeMem(0, dummy_data, 8'hFF, delay);
							readMem(l2_blocksize, dummy_data, delay);
							dummy_data = 64'h11223344_55667788;
							writeMem(l2_blocksize, dummy_data, 8'hFF, write_hit_delay);
							dummy_data = 64'h99AABBCC_DDEEF011;
							writeMem(0, dummy_data, 8'hFF, write_miss_delay);
							$display("  Back-to-back L3 writes: %0d then %0d cycles",
								write_hit_delay, write_miss_delay);
							if (write_hit_delay <= l3_hit_time + L3_HIT_MARGIN &&
							    write_miss_delay <= l3_hit_time + L3_HIT_MARGIN)
								$display("  Write buffer: yes");
							else
								$display("  Write buffer: no");
						end
					end
				end
			end
		end
		
		// --- Main memory hit time ---
		// Same convention as L2: time for a hit at this level, with all upper levels missing.
		// No L3 here, so L1 miss + L2 miss + main-memory hit.
		$display("");
		$display("=== Main memory hit time ===");
		resetMem();
		readMem(0, dummy_data, delay);
		$display("  Cold read (L1 miss, L2 miss, MM hit): %0d cycles", delay);
		if (l2_blocksize != 0) begin
			resetMem();
			readMem(l2_blocksize, dummy_data, read_miss_delay);
			$display("  Different block cold read: %0d cycles", read_miss_delay);
		end

		$stop();
	end
	
endmodule
