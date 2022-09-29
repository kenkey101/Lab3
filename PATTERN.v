`ifdef RTL
	`timescale 1ns/10ps
	`include "SD.v"
    `define CYCLE_TIME 7.0
`endif

`ifdef GATE
	`timescale 1ns/10ps
	`include "SD_SYN.v"
    `define CYCLE_TIME 7.0
`endif


module PATTERN(
    // Output signals
	clk,
    rst_n,
	in_valid,
	in,
    // Input signals
    out_valid,
    out
);

//================================================================ 
//   INPUT AND OUTPUT DECLARATION
//================================================================
output reg clk, rst_n, in_valid;
output reg [3:0] in;
input out_valid;
input [3:0] out;

//================================================================
// parameters & integer
//================================================================
//integer PATNUM;
integer pat_file;
integer ans_file;

integer total_cycles;
integer total_pat;

integer cycles;

integer gap;

integer input_number;


integer a;
integer c;

integer patcount;	// counter for pattern
 
integer arr_count;  // counter for array

integer ans_count;  // counter for answer

parameter PATNUM = 523; 	// currently 103

parameter array_len = 81;

//================================================================
// wire & registers 
//================================================================

reg [3:0] ans [14:0];  	   // 15 answers each 4 bits 
reg [3:0] gold_ans[14:0];  // 15 real answers each 4 bits

reg ans_wrong;

reg spec_5_function;

reg output_cycle;



//================================================================
// clock
//================================================================
always	#(`CYCLE_TIME/2.0) clk = ~clk;
initial	clk = 0;
//================================================================
// initial
//================================================================
initial
begin
	pat_file = $fopen("../00_TESTBED/input.txt", "r");
	ans_file = $fopen("../00_TESTBED/output.txt", "r");
	// output reset
	rst_n = 1;
	in_valid = 0;
	in = 4'bx;
	spec_5_function = 0;
	output_cycle = 0;
	
	for(ans_count = 0; ans_count < 14; ans_count = ans_count + 1)
		begin
			ans[ans_count] = 0;
			gold_ans[ans_count] = 0;
		end
		
	ans_wrong = 0;
	
	force clk = 0;
	reset_task;     	// test for spec 3
	total_cycles = 0;
	total_pat = 0;
	
	
	
	@(negedge clk);
	for(patcount = 0; patcount < PATNUM; patcount = patcount + 1)   	// for 100 games
		begin
		
			//spec_4_task;        // test for spec 4
			input_task;			// test for spec 4 and 5 at the same time
			//spec_5_task;        // test for spec 5
			wait_outvalid;      // test for spec 6
			check_ans;			// test for spec and spec 8
			delay_task;
		
		end
	#(1000);
	YOU_PASS_task;
	$finish;
	

end



//================================================================
// input task
//================================================================

task input_task;
begin
	
		in_valid = 1;
		
				
		
		for(arr_count = 0; arr_count < array_len; arr_count = arr_count + 1)  	// for 81 number in each game
				begin
				
					if((out_valid === 0) && (out !== 0))
						begin
							$display ("--------------------------------------------------------------------------------------------------------------------------------------------\n");
							$display ("                                                                    SPEC 4 FAIL!                                                            \n");
							$display ("                                                  Output signal should be 0 when out_valid isn't high                                       \n");
							$display ("--------------------------------------------------------------------------------------------------------------------------------------------\n");
							#(100);
							$finish ;
						end
					
					else if(out_valid === 1)
					begin
						fail;
						$display ("--------------------------------------------------------------------------------------------------------------------------------------------\n");
						$display ("                                                                    SPEC 5 FAIL!                                                            \n");
						$display ("                                    	out_valid should not overlap with in_valid when in_valid is high                                       \n");
						$display ("--------------------------------------------------------------------------------------------------------------------------------------------\n");
						#(100);
						$finish ;
					end
					a = $fscanf(pat_file,"%d",input_number);
					in = input_number;
					@(negedge clk);
				end
		in_valid = 0;
		in = 4'bx;

end
endtask

//================================================================
// reset and delay task
//================================================================


task reset_task ; 
begin     				// spec_3 test
	#(0.5); rst_n = 0;

	#(2.0);
	if((out !== 0) || (out_valid !== 0)) 
	begin
		fail;
		$display ("--------------------------------------------------------------------------------------------------------------------------------------------\n");
		$display ("                                                                    SPEC 3 FAIL!                                                            \n");
		$display ("                                                  Output signal should be 0 after initial RESET at %8t                                      \n",$time);
		$display ("--------------------------------------------------------------------------------------------------------------------------------------------\n");
		#(100);
	    $finish ;
	end
	
	#(1.0); rst_n = 1 ;
	#(3.0); release clk;
end 
endtask



task delay_task ; begin
	gap = $urandom_range(2, 4);
	repeat(gap)@(negedge clk);
end endtask




//================================================================
// ans task
//================================================================
task wait_outvalid ; 
begin               	// spec_6 test
	cycles = 0;
	while(out_valid !== 1)
		begin
			cycles = cycles + 1;
			
			if((out_valid === 0) && (out !== 0))
				begin
					$display ("--------------------------------------------------------------------------------------------------------------------------------------------\n");
					$display ("                                                                    SPEC 4 FAIL!                                                            \n");
					$display ("                                                  Output signal should be 0 when out_valid isn't high                                       \n");
					$display ("--------------------------------------------------------------------------------------------------------------------------------------------\n");
					#(100);
					$finish ;
				end
			else
				begin
					if(cycles == 600) 
						begin
							fail;
							$display ("--------------------------------------------------------------------------------------------------------------------------------------------\n");
							$display ("                                                      SPEC 6 FAIL!                                                                          \n");
							$display ("                                                     The execution latency are over 600 cycles                                              \n");
							$display ("--------------------------------------------------------------------------------------------------------------------------------------------\n");
							repeat(2)@(negedge clk);
							$finish;
						end
				end
		
		@(negedge clk);
		end
	total_cycles = total_cycles + cycles;
end 
endtask




task check_ans ; 
begin
	output_cycle = 0;
    while(out_valid === 1) 
	begin
		c = $fscanf(ans_file,"%d",gold_ans[0]);
		ans[0] = out;
		ans_wrong = 0;
		output_cycle = output_cycle + 1;
		@(negedge clk);    		// delay one clk
		
		if(	(gold_ans[0] === 10) && ( ans[0] !==10 ))  	// the answer is no solution but the output does not equal to 10
			begin 	
				fail;
				$display ("--------------------------------------------------------------------------------------------------------------------------------------------\n");
				$display ("                                                                 SPEC 7 FAIL!                                                               \n");
				$display ("                                                                Pattern NO.%03d 			                                                   \n", patcount);
				$display ("                                                       Your first output -> :  %d            	                               			   \n", ans[0]);
				$display ("                                                    	  Golden output -> 	%d                                               				   \n", gold_ans[0]);
				$display ("--------------------------------------------------------------------------------------------------------------------------------------------\n");
				@(negedge clk);
				$finish;
			end
		else if((gold_ans[0] === 10) && ( ans[0] === 10))
			begin
				if(output_cycle >= 2)
					begin
						$display ("--------------------------------------------------------------------------------------------------------------------------------------------\n");
						$display ("                                                                 SPEC 7 FAIL!                                                               \n");
						$display ("                                                        Output should be no more than 1 cycle		                                       \n");
						$display ("--------------------------------------------------------------------------------------------------------------------------------------------\n");
						@(negedge clk);
						$finish;
					end
				else
					begin
						$display (" PASS PATTERN NO. %d	 ", patcount);  	// only for self test need to remove
						@(negedge clk);
					end
			end
			
		else  				// the answer is have solution start to match the whole answer
			begin
				c = $fscanf(ans_file,"%d%d%d%d%d%d%d%d%d%d%d%d%d%d",gold_ans[1], gold_ans[2], gold_ans[3], gold_ans[4], gold_ans[5], gold_ans[6], gold_ans[7],
																	gold_ans[8], gold_ans[9], gold_ans[10], gold_ans[11], gold_ans[12], gold_ans[13], gold_ans[14]);
				for(ans_count = 1; ans_count <15; ans_count = ans_count + 1)
					begin
						ans[ans_count] = out;
						@(negedge clk);
					end
					
				for(ans_count = 0; ans_count < 15 ; ans_count = ans_count + 1)
					begin
						if(ans[ans_count] === gold_ans[ans_count])
							begin
								// answer is still right
							end
						else 
							begin
								// answer is wrong
								ans_wrong = 1;
							end
					end
					
				if(ans_wrong === 1)
					begin
						fail;
						$display ("--------------------------------------------------------------------------------------------------------------------------------------------\n");
						$display ("                                                                 SPEC 8 FAIL!                                                               \n");
						$display ("                                                                Pattern NO.%03d 			                                                   \n", patcount);
						$display ("                       Your  output -> :  %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d             	                               		   \n", 
										ans[0], ans[1], ans[2], ans[3], ans[4], ans[5], ans[6], ans[7], ans[8], ans[9], ans[10], ans[11], ans[12], ans[13], ans[14]);
						$display ("                      Golden output -> :  %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d                                              		   \n", 
										gold_ans[0], gold_ans[1], gold_ans[2], gold_ans[3], gold_ans[4], gold_ans[5], gold_ans[6], gold_ans[7], gold_ans[8], gold_ans[9],
										gold_ans[10], gold_ans[11], gold_ans[12], gold_ans[13], gold_ans[14]);
						$display ("--------------------------------------------------------------------------------------------------------------------------------------------\n");
						@(negedge clk);
						$finish;
					end
				else if(ans_wrong === 0 )
					begin
						if(output_cycle >= 15)
							begin
								$display ("--------------------------------------------------------------------------------------------------------------------------------------------\n");
								$display ("                                                                 SPEC 8 FAIL!                                                               \n");
								$display ("                                                  	   Output should be no more than 15 cycles		                                       \n");
								$display ("--------------------------------------------------------------------------------------------------------------------------------------------\n");
								@(negedge clk);
								$finish;
							end
						else
							begin
								$display (" PASS PATTERN NO. %d	 ", patcount);  	// only for self test need to remove
								@(negedge clk);
							end
					end
				
				
			end
			
		
		
		
		
    end
end 
endtask




task YOU_PASS_task;begin
//image_.success;
$display ("----------------------------------------------------------------------------------------------------------------------");
$display ("                                                  Congratulations!                						             ");
$display ("                                           You have passed all patterns!          						             ");
$display ("                                                                                 						             ");
$display ("                                        Your execution cycles   = %5d cycles      						             ", total_cycles);
$display ("                                        Your clock period       = %.1f ns        					                 ", `CYCLE_TIME);
$display ("                                        Total latency           = %.1f ns             						         ", (total_cycles + total_pat)*`CYCLE_TIME);
$display ("----------------------------------------------------------------------------------------------------------------------");

$finish;	
end endtask


task fail; begin
/*	
$display("@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@");
$display("@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@8Oo::::ooOOO8@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@");
$display("@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@o:   ..::..       .:o88@@@@@@@@@@@8OOoo:::..::oooOO8@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@");
$display("@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@8.   :8@@@@@@@@@@@@Oo..                   ..:.:..      .:O8@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@");
$display("@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@8.  .8@@@@@@@@@@@@@@@@@@@@@@88888888888@@@@@@@@@@@@@@@@@8.    :O@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@");
$display("@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@:. .@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@8.   :8@@@@@@@@@@@@@@@@@@@@@@@@@@@@@");
$display("@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@O  O@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@8.   :o@@@@@@@@@@@@@@@@@@@@@@@@@@");
$display("@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@o  8@@@@@@@@@@@@@8@@@@@@@@8o::o8@@@@@8ooO88@@@@@@@@@@@@@@@@@@@@@@@@8:.  .:ooO8@@@@@@@@@@@@@@@@@@@@");
$display("@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@o  :@@@@@@@@@@O      :@@@O   ..  :O@@@:       :@@@@OoO8@@@@@@@@@@@@@@@@Oo...     ..:o@@@@@@@@@@@@@@");
$display("@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@  :8@@@@@@@@@:  .@@88@@@8:  o@@o  :@@@. 0@@@.  O@@@      .O8@@@@@@@@@@@@@@@@@@8OOo.    O8@@@@@@@@@@");
$display("@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@  o@@@@@@@@@@O.      :8@8:  o@@O. .@@8  000o  .8@@O  O8O:  .@@o .O@@@@@@@@@@@@@@@@@@@o.  .o@@@@@@@@");
$display("@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@. :8@@@@@@@@@@@@@@@:  .o8:  o@@o. .@@O  ::  .O@@@O.  o0o.  :@@O. :8@8::8@@@@@@@@@@@@@@@8O  .:8@@@@@");
$display("@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@  o8@@@@@@@@@@@OO@@8.  o@8   ''  .O@@o  O@:  :O@@:  ::   .8@@@O. .:   .8@@@@@@@@@@@@@@@@@@O   8@@@@");
$display("@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@. .O@@@@@@@@@@O      .8@@@@Oo::oO@@@@O  8@8:  :@8  :@O. :O@@@@8:   .o@@@@@@@@@@@@@@@@@@@@@@o  :8@@@");
$display("@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@8:  8@@@@@@@@@@@@8@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@o:8@8:  :@@@@:  .O@@@@@@@@@@@@@@@@@@@@@@@@8:  o@@@");
$display("@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@:  .8@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@OoO@@@O  :8@@@@@@@@@@@@@@@@@@@@@@@@@@8o  8@@");
$display("@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@8.   o8@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@88@@@@@@@@@@@@@@@@@@@8::@@@@@88@@@@@@@@@@@@@@@@@@@@@@@  :8@");
$display("@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@O.  .:8@@@@@@@@@@@@@@@@@@@88OOoo::....:O88@@@@@@@@@@@@@@@@@@@@8o .8@@@@@@@@@@@@@@@@@@@@@@:  o@");
$display("@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@o.   ..:o8888888OO::.      ....:o:..     oO@@@@@@@@@@@@@@@@8O..@@ooO@@@@@@@@@@@@@@@@@@O. :@");
$display("@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@Oo::.          ..:OO@@@@@@@@@@@@@@@@O:  .o@@@@@@@@@@@@@@@@@@@O   8@@@@@@@@@@@@@@@@@. .O@");
$display("@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@8O   .8@@@@@@@@@@@@@@@@@@@@@O  O@@@@@@@@@@@@@. o8@");
$display("@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@O    .O@@@@@@@@@@@@@@@@@@8..8@@@@@@@@@@@@@. .O@");
$display("@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@O:           ..:O88@888@@@@@@@@@@@@@@@@@@@@@@@O  O@@");
$display("@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@o.                          ..:oO@@@@@@@@@@@@@@@o  @@@");
$display("@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@.                      .o@@8O::.    o8@@@@@@@@@@@O  8@@");
$display("@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@o                         :O@@@@@@@o.  :O8@@@@@@@@8  o8@");
$display("@@@@@@@@@@@@@@@@@@@@@@@@@88OO888@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@8888OOOOO8@@8888@@@@@O.                          .@@@@@@@@@:.  :@@@@@@@@@. .O@");
$display("@@@@@@@@@@@@@@@@@@@@8o:           O8@@@@@@@@@@@@@@@@@@@8OO:.                     .::                            :8@@@@@@@@@.  .O@@@@@@@o. o@");
$display("@@@@@@@@@@@@@@@@@@.                 o8@@@@@@@@@@@O:.         .::oOOO8Oo:..::::..                                 o@@@@@@@@@@8:  8@@@@@@o. o@");
$display("@@@@@@@@@@@@@@@@:                    .@@@@@Oo.        .:OO@@@@@@@@@@@@@@@@@@@@@@@@@o.                            O@@@@@@@@@@@@  o8@@@@@O. o@");
$display("@@@@@@@@@@@@@@:                       o88.     ..O88@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@888O.                     .8@@@@@@@@@@@@  o8@@@@@: .O@");
$display("@@@@@@@@@@@@O:                             :o8@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@:                  .8@@@@@@@@@@@8o  8@@@@@O  O@@");
$display("@@@@@@@@@@@O.                            :8@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@o.              :8@@@@@@@@@@8.  .O@@@@o.  :@@@");
$display("@@@@@@@@@@@:                          :O8@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@O:          .o@@@@@@@@@8o   .o@@@8:.  .@@@@@");
$display("@@@@@@@@@@@.                        O8@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@O.    .o8@@@@@@@@@@O  :O@@8o:   .O@@@@@@@");
$display("@@@@@@@@@@@.                      :O@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@O:   o8@@@@@@@@8           oO@@@@@@@@@@");
$display("@@@@@@@@@@@:                     o@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@.   .@@@@@@@O.      .:o8@@@@@@@@@@@@@");
$display("@@@@@@@@@@@8o                   8@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@o   :@@@@O     o8@@@@@@@@@@@@@@@@@@@");
$display("@@@@@@@@@@@@@8.               .O@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@:   .@@@8..:8@@@@@@@@@@@@@@@@@@@@@@");
$display("@@@@@@@@@@@@@@@8:            .o@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@O.  :8@@@@@@@@@@@@@@@@@@@@@@@@@@@@");
$display("@@@@@@@@@@@@@@@@@@8O.        8@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@   :@@@@@@@@@@@@@@@@@@@@@@@@@@@@");
$display("@@@@@@@@@@@@@@@@@@@@@@@8o   o@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@o   O@@@@@@@@@@@@@@@@@@@@@@@@@@@");
$display("@@@@@@@@@@@@@@@@@@@@@@@O   O@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@O   :@@@@@@@@@@@@@@@@@@@@@@@@@@");
$display("@@@@@@@@@@@@@@@@@@@@@@8   :@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@:   8@@@@@@@@@@@@@@@@@@@@@@@@@");
$display("@@@@@@@@@@@@@@@@@@@@@8o  :8@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@:..   .:o@@@@@@@@@@@@@@@@@@8.  O@@@@@@@@@@@@@@@@@@@@@@@@@");
$display("@@@@@@@@@@@@@@@@@@@@@8o  :8@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@O.         .:@@@@@@@@@@@@@@@@@:  :O@@@@@@@@@@@@@@@@@@@@@@@@");
$display("@@@@@@@@@@@@@@@@@@@@@O.  o@@@@@@@@@@@@@@@@@@@@@@8OOO8@@@@@@@@@@@@@@@@@@@@@@@@@@@8.             .@@@@@@@@@@@@@@@@.  .O@@@@@@@@@@@@@@@@@@@@@@@");
$display("@@@@@@@@@@@@@@@@@@@@o.  .@@@@@@@@@@@@@@@@@@@8:.       :8@@@@@@@@@@@@@@@@@@@@@@@@8.               o8@@@@@@@@@@@@@o. .:@@@@@@@@@@@@@@@@@@@@@@@");
$display("@@@@@@@@@@@@@@@@@@@@o.  :@@@@@@@@@@@@@@@@@O            .@@@@@@@@@@@@@@@@@@@@@@@@@:                .8@@@@@@@@@@@@O.  :@@@@@@@@@@@@@@@@@@@@@@@");
$display("@@@@@@@@@@@@@@@@@@@@O.  .@@@@@@@@@@@@@@@@:             .8@@@@@@@@@@@@@@@@@@@@@@@@O:                o@@@@@@@@@@@@O:  .@@@@@@@@@@@@@@@@@@@@@@@");
$display("@@@@@@@@@@@@@@@@@@@@O.  .@@@@@@@@@@@@@@8:               8@@@@@@@@@@@@@@@@@@@@@@@@@@.               o@@@@@@@@@@@@O:  .@@@@@@@@@@@@@@@@@@@@@@@");
$display("@@@@@@@@@@@@@@@@@@@@O.  .@@@@@@@@@@@@@o.                8@@@@@@@@@@@@@@@@@@@@@@@@@@8o             .8@@@@@@@@@@@@O.  .@@@@@@@@@@@@@@@@@@@@@@@");
$display("@@@@@@@@@@@@@@@@@@@@8:  .@@@@@@@@@@@@@                 :@@@@@@@@@@@@@@@@@@@@@@@@@@@@@8:.        O8@@@@@@@@@@@@@@o.  :@@@@@@@@@@@@@@@@@@@@@@@");
$display("@@@@@@@@@@@@@@@@@@@@@o   8@@@@@@@@@@@@.               :8@@@@@@@@@          :8@@@@@@@@@@@8OoooO@@@@@@@@@@@@@@@@@@.  .o@@@@@@@@@@@@@@@@@@@@@@@");
$display("@@@@@@@@@@@@@@@@@@88O:   O@@@@@@@@@@@@O:             .@@@@@@@@O             .8@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@8   :8@@@@@@@@@@@@@@@@@@@@@@@");
$display("@@@@@@@@@@@@@@@@O:.       :O8@@@@@@@@@@8o           :O@@@@@@@8:             :@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@8:       :o@@@@@@@@@@@@@@@@@@@");
$display("@@@@@@@@@@@@@@o              ..:8@@@@@@@@@8o:::.:O8@@@@@@@@@@@8.           :@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@O:.             o@@@@@@@@@@@@@@@@@");
$display("@@@@@@@@@@@@8o                   :@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@:.     .o@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@8                  o8@@@@@@@@@@@@@@@");
$display("8OOOooooOOoo:.                    :OOOOOOOOOO8888OOOOOOOOOOOoo:ooOOOo: .OOOOOOOOOO888OOooOO888OOOOOooO8:                   .:OOOOOOOOOOO88@@");
$display("            .                                                                                                                               ");
$display("@@@@@@@@@@@@@@8o                 .8@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@8                    :8@@@@@@@@@@@@@@@");
$display("@@@@@@@@@@@@@@@@8O.             o8@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@8o                 .@@@@@@@@@@@@@@@@@");
$display("@@@@@@@@@@@@@@@@@@@@::.       :O@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@O..         .:8@@@@@@@@@@@@@@@@@@");
$display("@@@@@@@@@@@@@@@@@@@@@@@@@88O8@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@88@@@@@@@@@@@@@@@@@@@@@@@@@@");
*/
//fail_.fail;
end endtask





endmodule
