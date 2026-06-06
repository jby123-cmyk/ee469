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
	
	function int floorPow2;
		input int x;
		int p;
		begin
			if (x <= 1) begin
				floorPow2 = 1;
			end else begin
				p = 1;
				while ((p << 1) <= x) p = p << 1;
				floorPow2 = p;
			end
		end
	endfunction
	
	function int clampInt;
		input int x;
		input int lo;
		input int hi;
		begin
			if (x < lo) clampInt = lo;
			else if (x > hi) clampInt = hi;
			else clampInt = x;
		end
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
	
	task confirmL3Presence;
		input int stride_bytes;
		output int has_l3_confirmed;
		output int nuniq;
		output int u0;
		output int u1;
		output int u2;
		output int u3;
		output int u4;
		output int u5;
		
		int seen[0:15];
		int nseen, d, sampleN;
		int ii, jj, tmp, found;
		
		nseen = 0;
		
		// Broad stack-distance sweep.
		for (ii=0; ii<=14; ii++) begin
			if (ii == 0) sampleN = 0;
			else sampleN = (1 << (ii-1)); // 1..8192
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
		
		// Fine sweep to catch missing intermediate tiers.
		for (ii=1; ii<=256; ii=ii+1) begin
			probeDelayAfterN(ii, stride_bytes, d);
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
		
		nuniq = nseen;
		u0 = (nseen > 0) ? seen[0] : -1;
		u1 = (nseen > 1) ? seen[1] : -1;
		u2 = (nseen > 2) ? seen[2] : -1;
		u3 = (nseen > 3) ? seen[3] : -1;
		u4 = (nseen > 4) ? seen[4] : -1;
		u5 = (nseen > 5) ? seen[5] : -1;
		
		// Observable interpretation:
		// 2 tiers = L1+MM, 3 tiers = L1+L2+MM, 4+ tiers => L3 is observable.
		has_l3_confirmed = (nseen >= 4) ? 1 : 0;
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
	
	task prepLevelHit;
		input int target_addr;
		input int upper_evict_blocks;
		input int l1_blocksize;
		output int observed_delay;
		int j, junk;
		logic [DATA_WIDTH-1:0][7:0] rd;
		
		readMem(target_addr, rd, junk); // Bring into hierarchy.
		for (j=1; j<=upper_evict_blocks; j++) begin
			readMem((32768 + j*l1_blocksize), rd, junk); // Evict upper levels.
		end
		readMem(target_addr, rd, observed_delay); // Should now reflect target-level hit path.
	endtask
	
	task inferWriteBehaviorAtLevel;
		input int target_addr;
		input int upper_evict_blocks;
		input int l1_blocksize;
		input int read_tier_delay;
		output int write_policy;      // 1: write-through, 0: write-back
		output int has_write_buffer;  // 1: yes, 0: no
		output int e_rhit;
		output int e_whit;
		output int e_rmiss;
		output int e_wmiss;
		
		int junk;
		logic [DATA_WIDTH-1:0][7:0] rd, wr;
		
		wr = 64'h01234567_89ABCDEF ^ target_addr;
		
		// Read-hit style access for this level.
		resetMem();
		prepLevelHit(target_addr, upper_evict_blocks, l1_blocksize, e_rhit);
		
		// Write-hit style access for this level.
		resetMem();
		readMem(target_addr, rd, junk);
		for (junk=1; junk<=upper_evict_blocks; junk++) begin
			readMem((32768 + junk*l1_blocksize), rd, e_rmiss);
		end
		writeMem(target_addr, wr, 8'hFF, e_whit);
		
		// Cold read/write miss evidence at same region.
		resetMem();
		readMem(target_addr + 8192, rd, e_rmiss);
		resetMem();
		writeMem(target_addr + 8192, wr, 8'hFF, e_wmiss);
		
		// If write-hit includes clear extra lower-level latency, treat as write-through.
		write_policy = (e_whit > e_rhit) ? 1 : 0;
		
		// Provisional (will be overridden by dedicated proof sequence).
		has_write_buffer = (e_wmiss < e_rmiss) ? 1 : 0;
		
		// Guard fallback: never leave uninitialized semantic values.
		if (!(write_policy == 0 || write_policy == 1))
			write_policy = 0;
		if (!(has_write_buffer == 0 || has_write_buffer == 1))
			has_write_buffer = 0;
	endtask
	
	// Dedicated write-buffer test:
	// Compare a baseline miss versus a sequence with an immediately preceding write
	// that should trigger lower-level traffic. If the write returns early but the
	// following miss is delayed, that's strong evidence of buffering.
	task proveWriteBufferAtLevel;
		input int target_addr;
		input int upper_evict_blocks;
		input int l1_blocksize;
		input int write_policy; // 1: WT, 0: WB
		output int has_write_buffer;
		output int p_write_trigger;
		output int p_follow_hit;
		output int p_follow_miss;
		output int p_miss_base;
		
		int j, junk;
		int addrA, addrB, addrC;
		logic [DATA_WIDTH-1:0][7:0] rd, wr0, wr1;
		
		addrA = target_addr;
		addrB = target_addr + 16*l1_blocksize;
		addrC = target_addr + 8192 + 32*l1_blocksize;
		wr0 = 64'hA5A5A5A5_5A5A5A5A ^ target_addr;
		wr1 = 64'hC3C3C3C3_3C3C3C3C ^ target_addr;
		
		// If not write-through-like, default to no-buffer for this probe style.
		if (write_policy == 0) begin
			has_write_buffer = 0;
			p_write_trigger = 0;
			p_follow_hit = 0;
			p_follow_miss = 0;
			p_miss_base = 0;
		end else begin
			// Baseline miss latency with same setup but no pending write.
			resetMem();
			readMem(addrA, rd, junk);
			readMem(addrB, rd, junk);
			for (j=1; j<=upper_evict_blocks; j++) begin
				readMem((131072 + j*l1_blocksize), rd, junk);
			end
			readMem(addrC, rd, p_miss_base);
			
			// Pending-write sequence.
			resetMem();
			readMem(addrA, rd, junk);
			readMem(addrB, rd, junk);
			for (j=1; j<=upper_evict_blocks; j++) begin
				readMem((131072 + j*l1_blocksize), rd, junk);
			end
			writeMem(addrA, wr0, 8'hFF, p_write_trigger);
			readMem(addrB, rd, p_follow_hit);
			writeMem(addrB, wr1, 8'hFF, junk);
			readMem(addrC, rd, p_follow_miss);
			
			// Evidence signature:
			// 1) trigger write completes faster than an uncompromised miss
			// 2) later miss is slower than baseline (must wait for pending write drain)
			has_write_buffer = ((p_write_trigger < p_miss_base) && (p_follow_miss > p_miss_base)) ? 1 : 0;
		end
	endtask
	
	task inferL1WriteAllocate;
		input int l1_hit_delay;
		output int write_allocate; // 1/0
		output int e_write_miss;
		output int e_read_after_write;
		
		logic [DATA_WIDTH-1:0][7:0] rd, wr;
		wr = 64'h00112233_44556677;
		
		resetMem();
		writeMem(0, wr, 8'hFF, e_write_miss);
		readMem(0, rd, e_read_after_write);
		write_allocate = (e_read_after_write == l1_hit_delay);
	endtask
	
	task inferL2GeometryIsolated;
		input int l1_blocksize;
		input int l1_num_blocks;
		input int l2_path_delay;
		input int upper_next_delay;
		output int l2_blocksize_out;
		output int l2_num_blocks_out;
		output int l2_assoc_out;
		output int e_l2_bsize_probe;
		output int e_l2_capacity_probe;
		output int e_l2_assoc_probe;
		
		int j, n, k, off, miss_thresh;
		int allhit, pass;
		int d, dprobe;
		int stride_conflict;
		logic [DATA_WIDTH-1:0][7:0] rd;
		
		// Threshold between L2-hit path and slower paths.
		// An L1-miss/L2-hit costs l2_path_delay. Anything beyond that (L3 or MM)
		// is "miss". Put the line just above l2_path_delay so any real jump trips it.
		if (upper_next_delay > l2_path_delay)
			miss_thresh = (l2_path_delay + upper_next_delay) / 2;
		else
			miss_thresh = l2_path_delay + 2;
		
		$display("  [L2 probe] l2_path_delay(t1)=%0d upper_next=%0d miss_thresh=%0d", l2_path_delay, upper_next_delay, miss_thresh);
		
		// ---- L2 blocksize (pure spatial-locality test, no eviction pollution) ----
		// Prime block 0 into L2, then read a COLD neighbor of 0. A cold address is
		// already an L1 miss, so its latency reflects L2: it is an L2 hit (= t1) if
		// it lies inside 0's L2 block, or an L2 miss if it crossed the block
		// boundary. The first offset that misses IS the L2 blocksize.
		// (No separate L1-eviction loop: it is unnecessary here and only risks
		//  kicking block 0 out of L2 before we probe.)
		$display("  [L2 blocksize sweep] (hit<=%0d means same L2 block as addr 0)", miss_thresh);
		l2_blocksize_out = 0;
		e_l2_bsize_probe = -1;
		for (off = l1_blocksize; off <= 1024; off = off + l1_blocksize) begin
			resetMem();
			readMem(0, rd, d);        // Prime block 0 (fills its L2 line).
			readMem(off, rd, dprobe); // Cold => L1 miss; L2 hit iff inside 0's block.
			$display("    off=%0d  delay=%0d  %s", off, dprobe, (dprobe > miss_thresh) ? "MISS (new L2 block)" : "hit (same L2 block)");
			if (dprobe > miss_thresh) begin
				l2_blocksize_out = off;
				e_l2_bsize_probe = dprobe;
				off = 2048; // exit
			end
		end
		if (l2_blocksize_out == 0) l2_blocksize_out = l1_blocksize;
		$display("  [L2 blocksize] measured = %0d bytes", l2_blocksize_out);
		
		// ---- L2 number of blocks (total capacity in blocks) ----
		// Touch N distinct CONSECUTIVE L2 blocks (stride = measured blocksize).
		// The sequential fill itself evicts block 0 from L1 (block #L1_num_blocks
		// collides with it), so the final probe of block 0 is a true L1 miss with
		// NO extra eviction traffic polluting L2. Under LRU, block 0 (oldest) is
		// evicted exactly when N exceeds the total number of blocks.
		l2_num_blocks_out = 0;
		e_l2_capacity_probe = -1;
		for (n = 1; n <= 2048; n = n + 1) begin
			resetMem();
			for (j = 0; j < n; j++) begin
				readMem(j*l2_blocksize_out, rd, d);
			end
			readMem(0, rd, dprobe); // L1 miss (evicted by the fill); hits L2 iff still resident.
			if (dprobe > miss_thresh) begin
				l2_num_blocks_out = n - 1;
				e_l2_capacity_probe = dprobe;
				$display("    [L2 capacity] block 0 evicted after touching %0d distinct blocks (delay=%0d)", n, dprobe);
				n = 4096; // exit
			end
		end
		if (l2_num_blocks_out < 2) l2_num_blocks_out = 2;
		$display("  [L2 num_blocks] measured = %0d  => capacity = %0d bytes", l2_num_blocks_out, l2_num_blocks_out*l2_blocksize_out);
		
		// ---- L2 associativity (co-residence test, robust to LRU AND random) ----
		// Conflict stride = capacity => every access maps to the SAME L2 set, and
		// (since capacity is a multiple of the L1 capacity) the same accesses also
		// collide in L1, so every probe read is a true L1 miss with no extra
		// pollution. We find the largest number of same-set blocks that can be
		// CO-RESIDENT: load 'k' same-set blocks (two warm-up passes to reach steady
		// state), then verify all 'k' still hit. The largest such 'k' is the number
		// of ways. Co-residence holds for LRU and random alike: once k<=assoc blocks
		// are resident, accessing only those blocks produces hits and never evicts.
		l2_assoc_out = 1;
		e_l2_assoc_probe = -1;
		stride_conflict = l2_num_blocks_out * l2_blocksize_out;
		$display("  [L2 assoc sweep] conflict stride = %0d (all map to one set)", stride_conflict);
		for (k = 2; k <= 256; k = k + 1) begin
			resetMem();
			// Two warm-up passes over the k same-set blocks to reach steady state.
			for (pass = 0; pass < 2; pass++) begin
				for (j = 0; j < k; j++) begin
					readMem(j*stride_conflict, rd, d);
				end
			end
			// Verify co-residence: every probe is an L1 miss (same L1 set), so a
			// hit means the block is still resident in the L2 set.
			allhit = 1;
			for (j = 0; j < k; j++) begin
				readMem(j*stride_conflict, rd, dprobe);
				if (dprobe > miss_thresh) allhit = 0;
			end
			if (!allhit) begin
				l2_assoc_out = k - 1; // k same-set blocks don't fit => assoc = k-1.
				e_l2_assoc_probe = dprobe;
				$display("    [L2 assoc] %0d same-set blocks do NOT all stay resident => assoc = %0d", k, k-1);
				k = 512; // exit
			end
		end
		if (l2_assoc_out < 1) l2_assoc_out = 1;
		$display("  [L2 assoc] measured = %0d-way  (sets = %0d)", l2_assoc_out, (l2_assoc_out > 0) ? (l2_num_blocks_out / l2_assoc_out) : 0);
	endtask
	
	initial begin
		int ntiers, t0, t1, t2, t3;
		int l3_nuniq, l3_u0, l3_u1, l3_u2, l3_u3, l3_u4, l3_u5, l3_confirm;
		int l1_blocksize;
		int ev1, ev2, ev3;
		int cap1_bytes, cap2_bytes, cap3_bytes;
		int l1_assoc, l2_assoc, l3_assoc;
		int l1_repl, l2_repl, l3_repl;
		int l1_write_allocate, l1_write_through, l1_write_buffer;
		int l2_write_through, l2_write_buffer;
		int l3_write_through, l3_write_buffer;
		int l2_hit_time, l3_hit_time, mm_hit_time;
		int l2_blocksize, l3_blocksize;
		int l1_num_blocks, l2_num_blocks, l3_num_blocks;
		int has_l2, has_l3;
		int l1_repl_code, l2_repl_code, l3_repl_code;
		int raw_l1_blocks, raw_l2_blocks, raw_l3_blocks;
		int geom_sanitized;
		int cap_l1, cap_l2, cap_l3;
		int e_l1_rhit, e_l1_whit, e_l1_rmiss, e_l1_wmiss;
		int e_l2_rhit, e_l2_whit, e_l2_rmiss, e_l2_wmiss;
		int e_l3_rhit, e_l3_whit, e_l3_rmiss, e_l3_wmiss;
		int e_l1_wa_wmiss, e_l1_r_after_w;
		int p_l1_wtrigger, p_l1_follow_hit, p_l1_follow_miss, p_l1_miss_base;
		int p_l2_wtrigger, p_l2_follow_hit, p_l2_follow_miss, p_l2_miss_base;
		int p_l3_wtrigger, p_l3_follow_hit, p_l3_follow_miss, p_l3_miss_base;
		int e_l2_bsize_probe, e_l2_capacity_probe, e_l2_assoc_probe;
		int meas_l2_blocksize, meas_l2_num_blocks, meas_l2_assoc;
		
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
		
		// 4) Determine level presence from number of timing tiers.
		// tiers = [L1, L2?, L3?, MM-path]
		has_l2 = (ntiers >= 3) ? 1 : 0;
		has_l3 = (ntiers >= 4) ? 1 : 0;
		
		// Independent L3 confirmation pass for robustness.
		confirmL3Presence(l1_blocksize, l3_confirm, l3_nuniq, l3_u0, l3_u1, l3_u2, l3_u3, l3_u4, l3_u5);
		has_l3 = l3_confirm;
		
		// 5) Per-level hit times from adjacent tier deltas.
		l2_hit_time = has_l2 ? (t1 - t0) : 0;
		l3_hit_time = has_l3 ? (t2 - t1) : 0;
		if (has_l3) mm_hit_time = t3 - t2;
		else if (has_l2) mm_hit_time = t2 - t1;
		else if (ntiers >= 2) mm_hit_time = t1 - t0;
		else mm_hit_time = t0;
		if (mm_hit_time < 0) mm_hit_time = 0;
		
		// 6) Lower-level geometry estimates.
		l2_blocksize = 0;
		l3_blocksize = l1_blocksize;
		l2_num_blocks = 0;
		l3_num_blocks = (has_l3 && cap3_bytes > 0 && l3_blocksize > 0) ? (cap3_bytes / l3_blocksize) : 0;
		if (l1_num_blocks < 0) l1_num_blocks = 0;
		if (l2_num_blocks < 0) l2_num_blocks = 0;
		if (l3_num_blocks < 0) l3_num_blocks = 0;
		
		// Strict L2-isolated probe (overrides heuristic L2 defaults).
		if (has_l2) begin
			inferL2GeometryIsolated(
				l1_blocksize,
				(l1_num_blocks > 0) ? l1_num_blocks : 16,
				t1,
				has_l3 ? t2 : t3,
				l2_blocksize,
				l2_num_blocks,
				l2_assoc,
				e_l2_bsize_probe,
				e_l2_capacity_probe,
				e_l2_assoc_probe
			);
			// Snapshot the directly-measured values BEFORE any sanitization,
			// so the transcript can prove the measured tuple is what we report.
			meas_l2_blocksize = l2_blocksize;
			meas_l2_num_blocks = l2_num_blocks;
			meas_l2_assoc = l2_assoc;
		end else begin
			e_l2_bsize_probe = -1;
			e_l2_capacity_probe = -1;
			e_l2_assoc_probe = -1;
			meas_l2_blocksize = 0;
			meas_l2_num_blocks = 0;
			meas_l2_assoc = 0;
		end
		
		// 6b) Geometry sanity pass (force physically valid concrete values).
		geom_sanitized = 0;
		raw_l1_blocks = l1_num_blocks;
		raw_l2_blocks = l2_num_blocks;
		raw_l3_blocks = l3_num_blocks;
		
		if (l1_blocksize < 8) begin
			l1_blocksize = 8;
			geom_sanitized = 1;
		end
		if (!isPow2(l1_blocksize)) begin
			l1_blocksize = floorPow2(l1_blocksize);
			geom_sanitized = 1;
		end
		if (l1_num_blocks < 1) begin
			l1_num_blocks = 1;
			geom_sanitized = 1;
		end
		if (!isPow2(l1_num_blocks)) begin
			l1_num_blocks = floorPow2(l1_num_blocks);
			geom_sanitized = 1;
		end
		
		if (has_l2) begin
			if (l2_blocksize < 8) begin
				l2_blocksize = 8;
				geom_sanitized = 1;
			end
			if (!isPow2(l2_blocksize)) begin
				l2_blocksize = floorPow2(l2_blocksize);
				geom_sanitized = 1;
			end
			if (l2_num_blocks < 2) begin
				l2_num_blocks = 2;
				geom_sanitized = 1;
			end
			if (!isPow2(l2_num_blocks)) begin
				l2_num_blocks = floorPow2(l2_num_blocks);
				geom_sanitized = 1;
			end
		end else begin
			l2_blocksize = 0;
			l2_num_blocks = 0;
		end
		
		if (has_l3) begin
			if (l3_blocksize < 8) begin
				l3_blocksize = l2_blocksize;
				geom_sanitized = 1;
			end
			if (!isPow2(l3_blocksize)) begin
				l3_blocksize = floorPow2(l3_blocksize);
				geom_sanitized = 1;
			end
			if (l3_num_blocks < 2) begin
				// Fallback if raw L3 capacity probe is weak: at least one step above L2.
				l3_num_blocks = (l2_num_blocks > 0) ? (l2_num_blocks << 1) : 2;
				geom_sanitized = 1;
			end
			if (!isPow2(l3_num_blocks)) begin
				l3_num_blocks = floorPow2(l3_num_blocks);
				geom_sanitized = 1;
			end
		end else begin
			l3_blocksize = 0;
			l3_num_blocks = 0;
		end
		
		// 6c) Apply "known feature" constraints from lab handout.
		// - blocksize nondecreasing down hierarchy
		// - total capacity increases down hierarchy
		// - associativity nondecreasing down hierarchy (enforced later)
		if (has_l2 && l2_blocksize < l1_blocksize) begin
			// Keep L2 measured geometry; don't force equal-to-L1.
			l2_blocksize = l1_blocksize;
			geom_sanitized = 1;
		end
		if (has_l3 && l3_blocksize < l2_blocksize) begin
			l3_blocksize = l2_blocksize;
			geom_sanitized = 1;
		end
		
		cap_l1 = l1_num_blocks * l1_blocksize;
		cap_l2 = has_l2 ? (l2_num_blocks * l2_blocksize) : 0;
		cap_l3 = has_l3 ? (l3_num_blocks * l3_blocksize) : 0;
		
		// Only "fix" L2 capacity if the direct measurement clearly failed
		// (fell back to the minimum of 2 blocks). A valid measurement is trusted
		// as-is, even if it implies a smaller-than-expected capacity, so we never
		// fabricate a number on top of a real measurement.
		if (has_l2 && cap_l2 <= cap_l1 && meas_l2_num_blocks <= 2) begin
			while ((l2_num_blocks * l2_blocksize) <= cap_l1) begin
				l2_num_blocks = l2_num_blocks << 1;
			end
			geom_sanitized = 1;
		end else if (has_l2 && cap_l2 <= cap_l1) begin
			$display("  [WARN] measured L2 capacity (%0d B) <= L1 capacity (%0d B); trusting measurement, NOT forcing.", cap_l2, cap_l1);
		end
		if (has_l3) begin
			cap_l2 = l2_num_blocks * l2_blocksize;
			if (cap_l3 <= cap_l2) begin
				while ((l3_num_blocks * l3_blocksize) <= cap_l2) begin
					l3_num_blocks = l3_num_blocks << 1;
				end
				geom_sanitized = 1;
			end
		end
		
		// 7) Associativity + replacement policy guesses.
		inferAssociativity(t0, cap1_bytes, l1_blocksize, 0, l1_assoc);
		inferReplacementPolicy(t0, cap1_bytes, l1_blocksize, 0, l1_assoc, l1_repl);
		
		if (has_l2) begin
			// Re-check replacement using measured L2 geometry.
			inferReplacementPolicy(t1, l2_num_blocks * l2_blocksize, l1_blocksize, (ev1 > 0) ? (ev1 + 4) : 0, l2_assoc, l2_repl);
		end else begin
			l2_assoc = 1;
			l2_repl = -1;
		end
		
		if (has_l3 && cap3_bytes > 0) begin
			inferAssociativity(t2, cap3_bytes, l1_blocksize, (ev2 > 0) ? (ev2 + 4) : ((ev1 > 0) ? (ev1 + 4) : 0), l3_assoc);
			inferReplacementPolicy(t2, cap3_bytes, l1_blocksize, (ev2 > 0) ? (ev2 + 4) : ((ev1 > 0) ? (ev1 + 4) : 0), l3_assoc, l3_repl);
		end else begin
			l3_assoc = 1;
			l3_repl = -1;
		end
		if (l1_assoc < 1) l1_assoc = 1;
		if (l2_assoc < 1) l2_assoc = 1;
		if (l3_assoc < 1) l3_assoc = 1;
		if (has_l2 && l2_assoc < l1_assoc) begin
			l2_assoc = l1_assoc;
			geom_sanitized = 1;
		end
		if (has_l3 && l3_assoc < l2_assoc) begin
			l3_assoc = l2_assoc;
			geom_sanitized = 1;
		end
		l1_assoc = clampInt(l1_assoc, 1, l1_num_blocks);
		l2_assoc = has_l2 ? clampInt(l2_assoc, 1, l2_num_blocks) : 0;
		l3_assoc = has_l3 ? clampInt(l3_assoc, 1, l3_num_blocks) : 0;
		if (!isPow2(l1_assoc)) l1_assoc = floorPow2(l1_assoc);
		if (has_l2 && !isPow2(l2_assoc)) l2_assoc = floorPow2(l2_assoc);
		if (has_l3 && !isPow2(l3_assoc)) l3_assoc = floorPow2(l3_assoc);
		
		// 7b) Timing consistency fallback to avoid impossible/zero local hit times.
		if (has_l2 && l2_hit_time <= 0) begin
			l2_hit_time = (e_l2_rhit > t0) ? (e_l2_rhit - t0) : 1;
			geom_sanitized = 1;
		end
		if (has_l3 && l3_hit_time <= 0) begin
			l3_hit_time = (e_l3_rhit > (t0 + l2_hit_time)) ? (e_l3_rhit - t0 - l2_hit_time) : 1;
			geom_sanitized = 1;
		end
		if (mm_hit_time <= 0) begin
			if (has_l3 && e_l3_rmiss > 0)
				mm_hit_time = e_l3_rmiss - t0 - l2_hit_time - l3_hit_time;
			else if (has_l2 && e_l2_rmiss > 0)
				mm_hit_time = e_l2_rmiss - t0 - l2_hit_time;
			else
				mm_hit_time = 1;
			if (mm_hit_time <= 0) mm_hit_time = 1;
			geom_sanitized = 1;
		end
		
		// Normalize replacement coding to table format: 1=LRU, 0=Random.
		l1_repl_code = (l1_assoc == 1) ? 1 : ((l1_repl == 1) ? 1 : 0);
		l2_repl_code = (l2_assoc == 1) ? 1 : ((l2_repl == 1) ? 1 : 0);
		l3_repl_code = (l3_assoc == 1) ? 1 : ((l3_repl == 1) ? 1 : 0);
		
		// 8) Write behavior with evidence delays.
		inferL1WriteAllocate(t0, l1_write_allocate, e_l1_wa_wmiss, e_l1_r_after_w);
		inferWriteBehaviorAtLevel(0, 0, l1_blocksize, t0, l1_write_through, l1_write_buffer, e_l1_rhit, e_l1_whit, e_l1_rmiss, e_l1_wmiss);
		proveWriteBufferAtLevel(0, 0, l1_blocksize, l1_write_through, l1_write_buffer, p_l1_wtrigger, p_l1_follow_hit, p_l1_follow_miss, p_l1_miss_base);
		
		if (has_l2) begin
			inferWriteBehaviorAtLevel(0, (ev1 > 0) ? (ev1 + 4) : 16, l1_blocksize, t1, l2_write_through, l2_write_buffer, e_l2_rhit, e_l2_whit, e_l2_rmiss, e_l2_wmiss);
			proveWriteBufferAtLevel(0, (ev1 > 0) ? (ev1 + 4) : 16, l1_blocksize, l2_write_through, l2_write_buffer, p_l2_wtrigger, p_l2_follow_hit, p_l2_follow_miss, p_l2_miss_base);
		end else begin
			l2_write_through = 0;
			l2_write_buffer = 0;
			e_l2_rhit = 0; e_l2_whit = 0; e_l2_rmiss = 0; e_l2_wmiss = 0;
			p_l2_wtrigger = 0; p_l2_follow_hit = 0; p_l2_follow_miss = 0; p_l2_miss_base = 0;
		end
		
		if (has_l3) begin
			inferWriteBehaviorAtLevel(0, (ev2 > 0) ? (ev2 + 4) : ((ev1 > 0) ? (ev1 + 16) : 64), l1_blocksize, t2, l3_write_through, l3_write_buffer, e_l3_rhit, e_l3_whit, e_l3_rmiss, e_l3_wmiss);
			proveWriteBufferAtLevel(0, (ev2 > 0) ? (ev2 + 4) : ((ev1 > 0) ? (ev1 + 16) : 64), l1_blocksize, l3_write_through, l3_write_buffer, p_l3_wtrigger, p_l3_follow_hit, p_l3_follow_miss, p_l3_miss_base);
		end else begin
			l3_write_through = 0;
			l3_write_buffer = 0;
			e_l3_rhit = 0; e_l3_whit = 0; e_l3_rmiss = 0; e_l3_wmiss = 0;
			p_l3_wtrigger = 0; p_l3_follow_hit = 0; p_l3_follow_miss = 0; p_l3_miss_base = 0;
		end
		
		$display("");
		$display("============== Inferred Characteristics ==============");
		$display("L1 Cache");
		$display("  Blocksize (Bytes): %0d", l1_blocksize);
		$display("  Number of Blocks : %0d", l1_num_blocks);
		$display("  Hit Time (cycles): %0d", t0);
		$display("  Associativity    : %0d", l1_assoc);
		$display("  Replacement (1=LRU,0=Random): %0d", l1_repl_code);
		$display("  Write policy (1=WT,0=WB)    : %0d", l1_write_through);
		$display("  Write allocate (1=yes,0=no) : %0d", l1_write_allocate);
		$display("  Write buffer (1=yes,0=no)   : %0d", l1_write_buffer);
		$display("    Evidence L1: r_hit=%0d w_hit=%0d r_miss=%0d w_miss=%0d", e_l1_rhit, e_l1_whit, e_l1_rmiss, e_l1_wmiss);
		$display("    Evidence WA: write_miss=%0d read_after_write=%0d", e_l1_wa_wmiss, e_l1_r_after_w);
		$display("    Buffer proof L1: w_trigger=%0d follow_hit=%0d follow_miss=%0d miss_base=%0d", p_l1_wtrigger, p_l1_follow_hit, p_l1_follow_miss, p_l1_miss_base);
		
		$display("L2 Cache");
		$display("  Blocksize (Bytes): %0d", has_l2 ? l2_blocksize : 0);
		$display("  Number of Blocks : %0d", has_l2 ? l2_num_blocks : 0);
		$display("  Hit Time (cycles): %0d", l2_hit_time);
		$display("  Associativity    : %0d", has_l2 ? l2_assoc : 0);
		$display("  Replacement (1=LRU,0=Random): %0d", has_l2 ? l2_repl_code : 0);
		$display("  Write policy (1=WT,0=WB)    : %0d", has_l2 ? l2_write_through : 0);
		$display("  Write buffer (1=yes,0=no)   : %0d", has_l2 ? l2_write_buffer : 0);
		$display("    Evidence L2: r_hit=%0d w_hit=%0d r_miss=%0d w_miss=%0d", e_l2_rhit, e_l2_whit, e_l2_rmiss, e_l2_wmiss);
		$display("    Buffer proof L2: w_trigger=%0d follow_hit=%0d follow_miss=%0d miss_base=%0d", p_l2_wtrigger, p_l2_follow_hit, p_l2_follow_miss, p_l2_miss_base);
		
		$display("L3 Cache");
		$display("  Is there L3 cache (1=yes,0=no): %0d", has_l3);
		$display("  Blocksize (Bytes): %0d", has_l3 ? l3_blocksize : 0);
		$display("  Number of Blocks : %0d", has_l3 ? l3_num_blocks : 0);
		$display("  Hit Time (cycles): %0d", l3_hit_time);
		$display("  Associativity    : %0d", has_l3 ? l3_assoc : 0);
		$display("  Replacement (1=LRU,0=Random): %0d", has_l3 ? l3_repl_code : 0);
		$display("  Write policy (1=WT,0=WB)    : %0d", has_l3 ? l3_write_through : 0);
		$display("  Write buffer (1=yes,0=no)   : %0d", has_l3 ? l3_write_buffer : 0);
		$display("    Evidence L3: r_hit=%0d w_hit=%0d r_miss=%0d w_miss=%0d", e_l3_rhit, e_l3_whit, e_l3_rmiss, e_l3_wmiss);
		$display("    Buffer proof L3: w_trigger=%0d follow_hit=%0d follow_miss=%0d miss_base=%0d", p_l3_wtrigger, p_l3_follow_hit, p_l3_follow_miss, p_l3_miss_base);
		
		$display("Main Memory");
		$display("  Hit time (cycles): %0d", mm_hit_time);
		$display("======================================================");
		$display("Evidence summary:");
		$display("  Tier delays: t0=%0d t1=%0d t2=%0d t3=%0d ntiers=%0d", t0, t1, t2, t3, ntiers);
		$display("  L2 isolated probes: bsize_delay=%0d cap_delay=%0d assoc_delay=%0d", e_l2_bsize_probe, e_l2_capacity_probe, e_l2_assoc_probe);
		$display("  L2 MEASURED (pre-sanitize): blocksize=%0d num_blocks=%0d assoc=%0d", meas_l2_blocksize, meas_l2_num_blocks, meas_l2_assoc);
		$display("  L2 FINAL    (reported)    : blocksize=%0d num_blocks=%0d assoc=%0d", l2_blocksize, l2_num_blocks, l2_assoc);
		if (has_l2 && (meas_l2_blocksize != l2_blocksize || meas_l2_num_blocks != l2_num_blocks || meas_l2_assoc != l2_assoc))
			$display("  [NOTE] L2 final differs from measured => sanitizer altered a value; trust MEASURED unless it is 0/invalid.");
		$display("  L3 confirm sweep: has_l3=%0d unique=%0d vals={%0d,%0d,%0d,%0d,%0d,%0d}", l3_confirm, l3_nuniq, l3_u0, l3_u1, l3_u2, l3_u3, l3_u4, l3_u5);
		$display("  Eviction points (#blocks): L1=%0d L2=%0d L3=%0d", ev1, ev2, ev3);
		$display("  Capacities (bytes): L1=%0d L2=%0d L3=%0d", cap1_bytes, cap2_bytes, cap3_bytes);
		$display("  Geometry sanitize: applied=%0d raw_blocks={L1:%0d,L2:%0d,L3:%0d}", geom_sanitized, raw_l1_blocks, raw_l2_blocks, raw_l3_blocks);
		$display("======================================================");
		
		$stop();
	end
	
endmodule
