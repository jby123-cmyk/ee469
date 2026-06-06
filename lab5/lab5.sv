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
	
	function int isPow2;
		input int x;
		isPow2 = (x > 0) && ((x & (x-1)) == 0);
	endfunction
	
	function int tierIndex;
		input int d;
		input int ntiers;
		input int t0;
		input int t1;
		input int t2;
		input int t3;
		
		if (ntiers <= 0) tierIndex = -1;
		else if (d == t0) tierIndex = 0;
		else if (ntiers > 1 && d == t1) tierIndex = 1;
		else if (ntiers > 2 && d == t2) tierIndex = 2;
		else if (ntiers > 3 && d == t3) tierIndex = 3;
		else if (d < t0) tierIndex = 0;
		else if (ntiers == 1) tierIndex = 0;
		else if (ntiers == 2) tierIndex = (d < t1) ? 0 : 1;
		else if (ntiers == 3) begin
			if (d < t1) tierIndex = 0;
			else if (d < t2) tierIndex = 1;
			else tierIndex = 2;
		end else begin
			if (d < t1) tierIndex = 0;
			else if (d < t2) tierIndex = 1;
			else if (d < t3) tierIndex = 2;
			else tierIndex = 3;
		end
	endfunction
	
	task probeDelayAfterN;
		input int n_blocks;
		input int stride_bytes;
		output int observed_delay;
		int j, warm_delay;
		logic [DATA_WIDTH-1:0][7:0] rd;
		
		resetMem();
		readMem(0, rd, warm_delay); // Pull base line into hierarchy.
		for (j=1; j<=n_blocks; j++) begin
			readMem((j*stride_bytes), rd, warm_delay);
		end
		readMem(0, rd, observed_delay);
	endtask
	
	task collectDelayTiers;
		input int stride_bytes;
		output int ntiers;
		output int t0;
		output int t1;
		output int t2;
		output int t3;
		
		int seen[0:15];
		int nseen, sampleN, d;
		int ii, jj, tmp, found;
		
		nseen = 0;
		for (ii=0; ii<=12; ii++) begin
			if (ii == 0) sampleN = 0;
			else sampleN = (1 << (ii-1)); // 1,2,4,...,2048
			probeDelayAfterN(sampleN, stride_bytes, d);
			found = 0;
			for (jj=0; jj<nseen; jj++) begin
				if (seen[jj] == d) found = 1;
			end
			if (!found && nseen < 16) begin
				seen[nseen] = d;
				nseen = nseen + 1;
			end
		end
		
		for (ii=0; ii<nseen; ii++) begin
			for (jj=ii+1; jj<nseen; jj++) begin
				if (seen[jj] < seen[ii]) begin
					tmp = seen[ii];
					seen[ii] = seen[jj];
					seen[jj] = tmp;
				end
			end
		end
		
		ntiers = nseen;
		t0 = (nseen > 0) ? seen[0] : -1;
		t1 = (nseen > 1) ? seen[1] : -1;
		t2 = (nseen > 2) ? seen[2] : -1;
		t3 = (nseen > 3) ? seen[3] : -1;
	endtask
	
	task inferL1Blocksize;
		input int l1_hit_delay;
		output int l1_blocksize;
		int off, d, warm_delay;
		logic [DATA_WIDTH-1:0][7:0] rd;
		
		l1_blocksize = -1;
		resetMem();
		readMem(0, rd, warm_delay);
		for (off=8; off<=2048; off=off+8) begin
			readMem(off, rd, d);
			if (d != l1_hit_delay) begin
				l1_blocksize = off;
				off = 4096; // loop exit sentinel
			end
		end
		if (l1_blocksize < 0) l1_blocksize = 8;
	endtask
	
	task findEvictionPoint;
		input int baseline_delay;
		input int stride_bytes;
		input int max_blocks;
		output int first_n;
		output int observed_delay;
		
		int lo, hi, mid, dmid;
		int dtmp;
		
		first_n = -1;
		observed_delay = -1;
		hi = 1;
		while (hi <= max_blocks) begin
			probeDelayAfterN(hi, stride_bytes, dtmp);
			if (dtmp > baseline_delay) begin
				first_n = hi;
				observed_delay = dtmp;
				hi = max_blocks + 1;
			end else begin
				hi = hi * 2;
			end
		end
		
		if (first_n == -1) begin
			probeDelayAfterN(max_blocks, stride_bytes, dtmp);
			observed_delay = dtmp;
		end else begin
			lo = (first_n/2) + 1;
			hi = first_n;
			while (lo <= hi) begin
				mid = (lo + hi)/2;
				probeDelayAfterN(mid, stride_bytes, dmid);
				if (dmid > baseline_delay) begin
					first_n = mid;
					observed_delay = dmid;
					hi = mid - 1;
				end else begin
					lo = mid + 1;
				end
			end
		end
	endtask
	
	task inferAssociativity;
		input int level_delay;
		input int level_capacity_bytes;
		input int l1_blocksize;
		input int upper_evict_blocks;
		output int assoc_guess;
		
		int k, j, d, warm_delay;
		int stride_conflict;
		logic [DATA_WIDTH-1:0][7:0] rd;
		
		assoc_guess = -1;
		if (level_capacity_bytes <= 0) begin
			assoc_guess = -1;
		end else begin
			stride_conflict = level_capacity_bytes;
			for (k=1; k<=32; k++) begin
				resetMem();
				readMem(0, rd, warm_delay);
				for (j=1; j<=k; j++) begin
					readMem(j*stride_conflict, rd, warm_delay);
				end
				// For lower levels, make sure the final probe is not hidden by an upper-level hit.
				for (j=1; j<=upper_evict_blocks; j++) begin
					readMem((16*stride_conflict) + j*l1_blocksize, rd, warm_delay);
				end
				readMem(0, rd, d);
				if (d > level_delay) begin
					assoc_guess = k;
					k = 1000; // loop exit sentinel
				end
			end
		end
	endtask
	
	task inferReplacementPolicy;
		input int level_delay;
		input int level_capacity_bytes;
		input int l1_blocksize;
		input int upper_evict_blocks;
		input int assoc_guess;
		output int lru_like;  // 1=LRU-like, 0=random-like/other, -1=unknown
		
		int trial, j, d, warm_delay, base_miss_count;
		int stride_conflict;
		logic [DATA_WIDTH-1:0][7:0] rd;
		
		lru_like = -1;
		if (assoc_guess <= 1 || level_capacity_bytes <= 0) begin
			lru_like = -1; // Direct mapped or unknown.
		end else begin
			base_miss_count = 0;
			stride_conflict = level_capacity_bytes;
			for (trial=0; trial<8; trial++) begin
				resetMem();
				readMem(0, rd, warm_delay);
				for (j=1; j<=assoc_guess-1; j++) begin
					readMem(j*stride_conflict + trial*64, rd, warm_delay);
				end
				readMem(0, rd, warm_delay); // Make base most-recently used.
				readMem((assoc_guess*stride_conflict) + trial*64, rd, warm_delay); // Force one eviction.
				for (j=1; j<=upper_evict_blocks; j++) begin
					readMem((24*stride_conflict) + j*l1_blocksize + trial*8, rd, warm_delay);
				end
				readMem(0, rd, d);
				if (d > level_delay) base_miss_count = base_miss_count + 1;
			end
			lru_like = (base_miss_count == 0) ? 1 : 0;
		end
	endtask
	
	task inferL1WriteBehavior;
		input int l1_hit_delay;
		input int l2_path_delay;
		output int write_allocate; // 1/0
		output int write_through;  // 1/0 (heuristic)
		output int has_write_buffer; // 1/0 (heuristic)
		
		int d_whit, d_wmiss, d_r_after_wmiss, d_r_miss;
		logic [DATA_WIDTH-1:0][7:0] rd, wr;
		
		wr = 64'h01234567_89ABCDEF;
		
		// Write-allocate test: write miss then read same address.
		resetMem();
		writeMem(0, wr, 8'hFF, d_wmiss);
		readMem(0, rd, d_r_after_wmiss);
		write_allocate = (d_r_after_wmiss == l1_hit_delay);
		
		// Write-through vs write-back heuristic:
		// If write-hit latency includes lower-level latency, it's likely write-through.
		resetMem();
		readMem(0, rd, d_r_miss); // Populate line.
		writeMem(0, wr, 8'hFF, d_whit);
		write_through = (d_whit >= l2_path_delay) ? 1 : 0;
		
		// Write-buffer heuristic:
		// If write miss is materially faster than read miss to same cold line, likely buffered.
		resetMem();
		readMem(1024, rd, d_r_miss);
		resetMem();
		writeMem(1024, wr, 8'hFF, d_wmiss);
		has_write_buffer = (d_wmiss < d_r_miss) ? 1 : 0;
	endtask
	
	initial begin
		int ntiers, t0, t1, t2, t3;
		int l1_blocksize;
		int ev1, ev2, ev3;
		int cap1_bytes, cap2_bytes, cap3_bytes;
		int l1_assoc, l2_assoc, l3_assoc;
		int l1_repl, l2_repl, l3_repl;
		int l1_write_allocate, l1_write_through, l1_write_buffer;
		int l2_hit_time, l3_hit_time, mm_hit_time;
		int l2_blocksize, l3_blocksize;
		int l1_num_blocks, l2_num_blocks, l3_num_blocks;
		
		dummy_data <= '0;
		$display("==============================================================");
		$display("Cache/Memory Profiler (black-box timing inference)");
		$display("==============================================================");
		
		// 1) Discover latency tiers from stack-distance probes.
		collectDelayTiers(8, ntiers, t0, t1, t2, t3);
		$display("Observed latency tiers (cycles): count=%0d values={%0d, %0d, %0d, %0d}", ntiers, t0, t1, t2, t3);
		
		// 2) L1 blocksize from first offset that loses L1-hit latency.
		inferL1Blocksize(t0, l1_blocksize);
		
		// Re-collect tiers using one-L1-block stride for cleaner transitions.
		collectDelayTiers(l1_blocksize, ntiers, t0, t1, t2, t3);
		$display("Refined latency tiers (cycles): count=%0d values={%0d, %0d, %0d, %0d}", ntiers, t0, t1, t2, t3);
		
		// 3) Eviction points in # of L1-sized blocks.
		findEvictionPoint(t0, l1_blocksize, 4096, ev1, delay);
		if (ntiers > 1) findEvictionPoint(t1, l1_blocksize, 4096, ev2, minval); else begin ev2 = -1; minval = -1; end
		if (ntiers > 2) findEvictionPoint(t2, l1_blocksize, 4096, ev3, maxval); else begin ev3 = -1; maxval = -1; end
		
		l1_num_blocks = (ev1 > 0) ? ev1 : -1;
		cap1_bytes = (ev1 > 0) ? (ev1 * l1_blocksize) : -1;
		cap2_bytes = (ev2 > 0) ? (ev2 * l1_blocksize) : -1;
		cap3_bytes = (ev3 > 0) ? (ev3 * l1_blocksize) : -1;
		
		// 4) Per-level hit times from tier differences.
		l2_hit_time = (ntiers > 1) ? (t1 - t0) : -1;
		l3_hit_time = (ntiers > 2) ? (t2 - t1) : -1;
		mm_hit_time = (ntiers > 2) ? (t3 - t2) : ((ntiers > 1) ? (t1 - t0) : -1);
		
		// 5) Lower-level blocksize estimates.
		// Reuse L1 blocksize unless we can confidently infer otherwise.
		l2_blocksize = l1_blocksize;
		l3_blocksize = l1_blocksize;
		l2_num_blocks = (cap2_bytes > 0 && l2_blocksize > 0) ? (cap2_bytes / l2_blocksize) : -1;
		l3_num_blocks = (cap3_bytes > 0 && l3_blocksize > 0) ? (cap3_bytes / l3_blocksize) : -1;
		
		// 6) Associativity + replacement policy guesses.
		inferAssociativity(t0, cap1_bytes, l1_blocksize, 0, l1_assoc);
		inferReplacementPolicy(t0, cap1_bytes, l1_blocksize, 0, l1_assoc, l1_repl);
		
		if (ntiers > 1 && cap2_bytes > 0) begin
			inferAssociativity(t1, cap2_bytes, l1_blocksize, (ev1 > 0) ? (ev1 + 4) : 0, l2_assoc);
			inferReplacementPolicy(t1, cap2_bytes, l1_blocksize, (ev1 > 0) ? (ev1 + 4) : 0, l2_assoc, l2_repl);
		end else begin
			l2_assoc = -1;
			l2_repl = -1;
		end
		
		if (ntiers > 2 && cap3_bytes > 0) begin
			inferAssociativity(t2, cap3_bytes, l1_blocksize, (ev2 > 0) ? (ev2 + 4) : ((ev1 > 0) ? (ev1 + 4) : 0), l3_assoc);
			inferReplacementPolicy(t2, cap3_bytes, l1_blocksize, (ev2 > 0) ? (ev2 + 4) : ((ev1 > 0) ? (ev1 + 4) : 0), l3_assoc, l3_repl);
		end else begin
			l3_assoc = -1;
			l3_repl = -1;
		end
		
		// 7) Write behavior (L1 directly inferred; lower-level fields remain inferred/unknown).
		inferL1WriteBehavior(t0, (ntiers > 1) ? t1 : t0+1, l1_write_allocate, l1_write_through, l1_write_buffer);
		
		$display("");
		$display("============== Inferred Characteristics ==============");
		$display("L1 Cache");
		$display("  Blocksize (Bytes): %0d", l1_blocksize);
		$display("  Number of Blocks : %0d", l1_num_blocks);
		$display("  Hit Time (cycles): %0d", t0);
		$display("  Associativity    : %0d%s", l1_assoc, (l1_assoc == 1) ? " (Direct Mapped)" : "");
		$display("  Replacement      : %s", (l1_assoc <= 1) ? "Skip (Direct Mapped)" : ((l1_repl == 1) ? "LRU-like" : ((l1_repl == 0) ? "Random-like/other" : "Unknown")));
		$display("  Write policy     : %s", (l1_write_through == 1) ? "Write-Through (heuristic)" : "Write-Back (heuristic)");
		$display("  Write allocate   : %s", (l1_write_allocate == 1) ? "Yes" : "No");
		$display("  Write buffer     : %s", (l1_write_buffer == 1) ? "Likely yes (heuristic)" : "Likely no (heuristic)");
		
		$display("L2 Cache");
		if (ntiers > 1) begin
			$display("  Blocksize (Bytes): %0d (estimated)", l2_blocksize);
			$display("  Number of Blocks : %0d (estimated)", l2_num_blocks);
			$display("  Hit Time (cycles): %0d (tier delta)", l2_hit_time);
			$display("  Associativity    : %0d (estimated)", l2_assoc);
			$display("  Replacement      : %s", (l2_assoc <= 1) ? "Skip (Direct Mapped or unknown)" : ((l2_repl == 1) ? "LRU-like (estimated)" : ((l2_repl == 0) ? "Random-like/other (estimated)" : "Unknown")));
			$display("  Write policy     : Unknown from strict black-box timing");
			$display("  Write buffer     : Unknown from strict black-box timing");
		end else begin
			$display("  Not detected");
		end
		
		$display("L3 Cache");
		if (ntiers > 2) begin
			$display("  Is there L3 cache: Yes");
			$display("  Blocksize (Bytes): %0d (estimated)", l3_blocksize);
			$display("  Number of Blocks : %0d (estimated)", l3_num_blocks);
			$display("  Hit Time (cycles): %0d (tier delta)", l3_hit_time);
			$display("  Associativity    : %0d (estimated)", l3_assoc);
			$display("  Replacement      : %s", (l3_assoc <= 1) ? "Skip (Direct Mapped or unknown)" : ((l3_repl == 1) ? "LRU-like (estimated)" : ((l3_repl == 0) ? "Random-like/other (estimated)" : "Unknown")));
			$display("  Write policy     : Unknown from strict black-box timing");
			$display("  Write buffer     : Unknown from strict black-box timing");
		end else begin
			$display("  Is there L3 cache: No (no 3rd cache-latency tier observed)");
		end
		
		$display("Main Memory");
		$display("  Hit time (cycles): %0d (estimated from slowest tier delta)", mm_hit_time);
		$display("======================================================");
		$display("Notes:");
		$display("  - Fields tagged 'estimated/heuristic' are inferred from timing behavior.");
		$display("  - L2/L3 write policy and write-buffer presence are not uniquely identifiable");
		$display("    from top-level timing alone without internal signal visibility.");
		$display("======================================================");
		
		$stop();
	end
	
endmodule
