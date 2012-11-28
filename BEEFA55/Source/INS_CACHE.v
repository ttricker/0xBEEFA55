////////////////////////////////////////////////////////////////////////////////
// ECE 485/585: Microprocessor System Design
// Portland State University - Fall 2012 
// Final Project: 
// 
// File:		INS_CACHE.v (Instruction Cache)
// Authors: 
// Description:
//
//
//
////////////////////////////////////////////////////////////////////////////////
`define LINES 1024*16
`define WAYS 2

module INS_CACHE(
	// INPUTS
	input clk,
	input [3:0] n,			// from trace file
	input [25:0] add_in,	// from trace file
	
	// OUTPUTS
	output reg [31:0] add_out,	// to next-level cache
	output reg hit,				// to statistics module
	output reg miss				// to statistics module
  );
	
	// instruction cache only reponds to following values of n
	parameter RESET = 4'd8;
	parameter INVALIDATE = 4'd3;
	parameter INST_FETCH = 4'd2;
	
	// instantiate cache
	//	size					lines			ways
	reg 				LRU 	[`LINES-1:0] 			;//  1=LRU is way 1.  0 = LRU way is 0
	reg  				Valid	[`LINES-1:0] [`WAYS-1:0];
	reg [23:0] 			Tag 	[`LINES-1:0] [`WAYS-1:0];
	
	// bit/byte selection
	// Data[2][1] = 512 bit array from line 2, way 1
	// Data[2][1][43] 43rd bit from above data array
	
	// loop counters
	integer i,j;
	
	// internal signals
	reg done = 1'b0;
	
	wire [11:0] curr_tag = add_in[31:20];
	wire [13:0] curr_index = add_in[19:6];
	
	always @*
	begin	
		add_out = 26'bZZ_ZZZZ_ZZZZ_ZZZZ_ZZZZ_ZZZZ_ZZZZ;
		done	= 1'b0;
		hit 	= 1'b0;
		miss 	= 1'b0;
				
		case(n)
			RESET:	// clear all bits in cache
			begin
				for (i = 0; i < 8; i = i+1'b1) 	// for every line
				begin
					LRU[i] = 1'b0;	
					for (j = 0; j < 2; j = j+1'b1)	// for all ways
					begin
						Valid	[i][j]	= 1'b0;	
						Tag  	[i][j]	= 24'b0;
					end
				end
			end
			
			INVALIDATE:
			begin
				for (j = 0; j < `WAYS; j = j+1'b1)			// for all ways
					if (Tag[curr_index][i] == curr_tag)
						Valid[curr_index][i] = 1'b0;
			end	
			
			INST_FETCH:
			begin
				//	look at all (both) ways.  if for either, the tags match
				//	and the valid bit is set, this is a hit.  on a hit, the 
				//  if(!done) will evaluate false and execution drops through.
				for (j = 0; j < 2; j = j+1'b1)
				begin
					if (!done)
						if (Tag[curr_index][j] == curr_tag && Valid[curr_index][j] == 1'b1)
						begin
							LRU[curr_index] 	= j[0]; // is this logic right?
							done 				= 1'b1;
							hit 				= 1'b1;
						end
					else ;
				end
				
				//	if execution exits this loop and done still == 0, then 
				// 	the ins. fetch was not a hit.  so assert miss.		
				if	(!done)	
					miss = 1'b1;	
				
				// look at both ways.  If either is empty (valid == 0) then 
				// do a read and and put it in the empty way.  If this happens,
				// done is set true, and execution will drop out of the loop.
				for (j = 0; j < 2; j = j+1'b1)
				begin
					if (!done)
						if (Valid[curr_index][j] == 1'b0)
						begin
							done 				= 1'b1;
							add_out				= add_in[25:0]; // is this right?
							Tag[curr_index][j] 	= curr_tag;
							Valid[curr_index][j]= 1'b1;
						end
				end
							
				// reaching this point means an eviction is needed
				// so evict the LRU
				if (!done)
					begin
						add_out	= add_in[25:0]; // is this right?
						Tag[curr_index][LRU[curr_index]] = curr_tag;  
						Valid[curr_index][LRU[curr_index]] = 1'b1;   
					end
				
			end
					
			default:	// commands this module doesn't respond to
			begin
				done = 1'b0;
				hit = 1'b0;
				miss = 1'b0;
			end
		endcase
	end		
	
endmodule