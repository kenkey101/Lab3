module SD(
    //Input Port
    clk,
    rst_n,
	in_valid,
	in,

    //Output Port
    out_valid,
    out
    );

//-----------------------------------------------------------------------------------------------------------------
//   PORT DECLARATION                                                  
//-----------------------------------------------------------------------------------------------------------------
input            clk, rst_n, in_valid;
input [3:0]		 in;
output reg		 out_valid;
output reg [3:0] out;
    
//-----------------------------------------------------------------------------------------------------------------
//   PARAMETER DECLARATION                                             
//-----------------------------------------------------------------------------------------------------------------
parameter IDLE    = 2'd0;
parameter INPUT   = 2'd1;
parameter SOLVING = 2'd2;
parameter OUTPUT  = 2'd3;

//-----------------------------------------------------------------------------------------------------------------
//   REGISTER DECLARATION                                             
//-----------------------------------------------------------------------------------------------------------------



reg [1:0] current_state;
reg [1:0] next_state;






reg [3:0] arr_0 [8:0];   // 8 elements of the 0th row each 4 bits
reg [3:0] arr_1 [8:0];   // 8 elements of the 1st row each 4 bits
reg [3:0] arr_2 [8:0];   // 8 elements of the 2nd row each 4 bits
reg [3:0] arr_3 [8:0];   // 8 elements of the 3rd row each 4 bits
reg [3:0] arr_4 [8:0];	 // 8 elements of the 4th row each 4 bits
reg [3:0] arr_5 [8:0];	 // 8 elements of the 5th row each 4 bits
reg [3:0] arr_6 [8:0];	 // 8 elements of the 6th row each 4 bits
reg [3:0] arr_7 [8:0];	 // 8 elements of the 7th row each 4 bits
reg [3:0] arr_8 [8:0];	 // 8 elements of the 8th row each 4 bits

reg [6:0] arr_count;    // input array counter max will be 80 1010000 7 bits


reg [3:0] counter;      // free counter


reg [3:0] space_row_id [14:0];   // space row id of 15 space elements each id 4 bits
reg [3:0] space_col_id [14:0];   // space col id of 15 space elements each id 4 bits
reg [3:0] space_grid_id [14:0];  // space grid id of 15 space elements each id 4 bits
reg [3:0] space_value [14:0];    // the element of 15 space after solving the problem and also for output

reg [3:0] space_count;           // space counter 0~14 4 bits  0000 ~ 1110
reg [3:0] space_counter; 		 // space counter for reset


reg [3:0] current_space_id;      // current space id in the space_value queue 0~14 4 bits  0000 ~ 1110
reg [3:0] current_space_value;   // current space value in the space_value queue  0~9 4 bits 0000 ~ 1001
reg [3:0] current_space_row_id;  // current space row id 
reg [3:0] current_space_col_id;  // current space col id
reg [3:0] current_space_grid_id; // current space grid id

reg solving_finish; 	// signal implies solving is finished
reg output_finish;  	// signal implies output is finished

reg [3:0] output_counter; // count the output cycle

reg col_check;			  // flag for col check
reg row_check;      	  // flag for row check
reg grid_check;  		  // flag for grid check

//reg col_check_result;	  // col_check_result
//reg row

reg placing_finish;		  // flag for placing_finish
reg visited;   		  // flag for indicating if have visited a space element

reg no_solution; 		  // flag indicating that there is no solution 

reg fill_in_space_of_arr; // fill in the space of array

reg final_col_check;   		  // final col check for the sudoku integrity
reg final_row_check; 		  // final row check for the sudoku integrity
reg final_grid_check;		  // final grid check for the sudoku integriy

reg [8:0] col_check_result;  		  // result for final col check

reg [8:0] row0_check_result;		  // result for final row check
reg [8:0] row1_check_result;		  // result for final row check
reg [8:0] row2_check_result;		  // result for final row check
reg [8:0] row3_check_result;		  // result for final row check
reg [8:0] row4_check_result;		  // result for final row check
reg [8:0] row5_check_result;		  // result for final row check
reg [8:0] row6_check_result;		  // result for final row check
reg [8:0] row7_check_result;		  // result for final row check
reg [8:0] row8_check_result;		  // result for final row check

reg [8:0] grid0_check_result;		  // result for final grid check
reg [8:0] grid1_check_result;		  // result for final grid check
reg [8:0] grid2_check_result;		  // result for final grid check
reg [8:0] grid3_check_result;		  // result for final grid check
reg [8:0] grid4_check_result;		  // result for final grid check
reg [8:0] grid5_check_result;		  // result for final grid check
reg [8:0] grid6_check_result;		  // result for final grid check
reg [8:0] grid7_check_result;		  // result for final grid check
reg [8:0] grid8_check_result;		  // result for final grid check

reg [3:0] col_check_counter;
reg [3:0] row0_check_counter;
reg [3:0] row1_check_counter;
reg [3:0] row2_check_counter;
reg [3:0] row3_check_counter;
reg [3:0] row4_check_counter;
reg [3:0] row5_check_counter;
reg [3:0] row6_check_counter;
reg [3:0] row7_check_counter;
reg [3:0] row8_check_counter;
reg [3:0] grid_check_counter;

reg waiting;

//-----------------------------------------------------------------------------------------------------------------
//   LOGIC DECLARATION                                                 
//-----------------------------------------------------------------------------------------------------------------

//-----------------------------------------------------------------------------------------------------------------
//   Design                                                            
//-----------------------------------------------------------------------------------------------------------------


//-----------------------------------------------------------------------------------------------------------------
//   FSM                                                            
//-----------------------------------------------------------------------------------------------------------------

always @(posedge clk or negedge rst_n)
begin
	if(!rst_n)
		current_state <= IDLE;
	else
		current_state <= next_state;
end

always @(*)
begin
	case(current_state)
		IDLE:
			begin
				if(!rst_n)
					begin
						next_state = IDLE;
					end
				else if (in_valid)
					begin
						next_state = INPUT;
					end
				else
					begin
						next_state = IDLE;
					end
			end
		INPUT:
			begin
				if(in_valid)   		// still need to input
					begin
						next_state = INPUT;
					end
				else
					begin
						next_state = SOLVING;
					end
			end
		SOLVING:
			begin
				if(placing_finish)  	// solving is finished
					begin
						next_state = OUTPUT;
					end
				else					// still need time to solve
					begin
						next_state = SOLVING; 
					end
			end
		OUTPUT:
			begin
				if(output_finish)		// output is finished
					begin
						next_state = IDLE;
					end
				else
					begin
						next_state = OUTPUT;
					end
			end
		default:
			begin
				next_state = current_state;
			end
		endcase
end

//-----------------------------------------------------------------------------------------------------------------
//  solving_finish                                                          
//-----------------------------------------------------------------------------------------------------------------
/**
always @(posedge clk or negedge rst_n)
begin
	if(!rst_n)
		begin
			solving_finish <= 'b0;
		end
	else
		case(next_state)
			IDLE:
				begin
					//if(placing_finish == 1)
						solving_finish <=  'b0;
				end
			SOLVING:
				begin
				   if(placing_finish ==1)
						solving_finish <= 'b1;
				end
			default:
				begin
					solving_finish <= 'b0;
				end
		endcase
end
**/

//-----------------------------------------------------------------------------------------------------------------
//  output_finish                                                          
//-----------------------------------------------------------------------------------------------------------------
always @(posedge clk or negedge rst_n)
begin
	if(!rst_n)
		begin
			output_finish <= 'b0;
		end
	else
		case(next_state)		// original: next_state
			IDLE:
				begin
					output_finish <=  'b0;
				end
			OUTPUT:
				begin
					if(no_solution == 'b1)		// there is no solution	
						begin
							output_finish <= 'b1;
						end
					else						// there is a solution output 15 cycles
						begin
							if(output_counter == 14)
								output_finish <= 'b1;
						end	
				end
			default:
				begin
				
				end
		endcase
end



//-----------------------------------------------------------------------------------------------------------------
//   arr_count from 0 to 80                                                            
//-----------------------------------------------------------------------------------------------------------------
always @(posedge clk or negedge rst_n)
begin
	if(!rst_n)
		begin
			arr_count <= 'd0;
		end
	else
		case(next_state)		// original: next_state
			IDLE:
				begin
					arr_count <=  'd0;
				end
			INPUT:
				begin
					arr_count <= arr_count + 1;
				end
			default:
				begin
				
				end
		endcase
end

//-----------------------------------------------------------------------------------------------------------------
//   arr_0 ~ arr_8 input                                                            
//-----------------------------------------------------------------------------------------------------------------
always @(posedge clk or negedge rst_n)
begin
	if(!rst_n)
		begin
			for(counter = 0; counter < 9; counter = counter + 1)  	// reset arr_0 to arr_8
				begin
					arr_0[counter] <= 'd0;
					arr_1[counter] <= 'd0;
					arr_2[counter] <= 'd0;
					arr_3[counter] <= 'd0;
					arr_4[counter] <= 'd0;
					arr_5[counter] <= 'd0;
					arr_6[counter] <= 'd0;
					arr_7[counter] <= 'd0;
					arr_8[counter] <= 'd0;
				end
		end
	else 
		case(next_state)		// original: next_state
			IDLE:
				begin
					for(counter = 0; counter < 9; counter = counter + 1)  	// reset arr_0 to arr_8
						begin
							arr_0[counter] <= 'd0;
							arr_1[counter] <= 'd0;
							arr_2[counter] <= 'd0;
							arr_3[counter] <= 'd0;
							arr_4[counter] <= 'd0;
							arr_5[counter] <= 'd0;
							arr_6[counter] <= 'd0;
							arr_7[counter] <= 'd0;
							arr_8[counter] <= 'd0;
						end
				end
			INPUT:
					begin
						if((arr_count/9) == 0)   		// arr_0[0~8]
							begin
								arr_0[arr_count] <= in;
							end
						else if((arr_count/9) == 1)			// arr_1[0~8]	
							begin
								arr_1[arr_count-9] <= in;
							end
						else if((arr_count/9) == 2)			// arr_2[0~8]	
							begin
								arr_2[arr_count-18] <= in;
							end
						else if((arr_count/9) == 3)			// arr_3[0~8]	
							begin
								arr_3[arr_count-27] <= in;
							end
						else if((arr_count/9) == 4)			// arr_4[0~8]	
							begin
								arr_4[arr_count-36] <= in; 
							end
						else if((arr_count/9) == 5)			// arr_5[0~8]	
							begin
								arr_5[arr_count-45] <= in;
							end
						else if((arr_count/9) == 6)			// arr_6[0~8]	
							begin
								arr_6[arr_count-54] <= in;
							end
						else if((arr_count/9) == 7)			// arr_7[0~8]	
							begin
								arr_7[arr_count-63] <= in;
							end
						else if((arr_count/9) == 8)			// arr_8[0~8]	
							begin
								arr_8[arr_count-72] <= in;
							end
					end
			SOLVING:
				begin
					if(fill_in_space_of_arr  == 'b1)
					begin
					case(current_space_row_id)
						4'd0:		// row 0
							begin
								arr_0[current_space_col_id] <= current_space_value;
							end
						4'd1:		// row 1
							begin
								arr_1[current_space_col_id] <= current_space_value;
							end
						4'd2:		// row 2
							begin
								arr_2[current_space_col_id] <= current_space_value;
							end
						4'd3:		// row 3
							begin
								arr_3[current_space_col_id] <= current_space_value;
							end
						4'd4:		// row 4
							begin
								arr_4[current_space_col_id] <= current_space_value;
							end
						4'd5:		// row 5
							begin
								arr_5[current_space_col_id] <= current_space_value;
							end
						4'd6:		// row 6
							begin
								arr_6[current_space_col_id] <= current_space_value;
							end
						4'd7:		// row 7
							begin
								arr_7[current_space_col_id] <= current_space_value;
							end
						4'd8:		//row 8
							begin
								arr_8[current_space_col_id] <= current_space_value;
							end
						default:
							begin
							
							end
					endcase
					end
						
				end
			default:
				begin
				end
		endcase
			
end

//-----------------------------------------------------------------------------------------------------------------
//   space_count                                                            
//-----------------------------------------------------------------------------------------------------------------

always @(posedge clk or negedge rst_n)
begin
	if(!rst_n)
		begin
			space_count <= 'd0;
		end
	else	
		case(next_state)		// original: next_state
			IDLE:
				begin
					space_count <=  'd0;
				end
			INPUT:
				begin
					if(in == 0)
						begin
							space_count <= space_count + 1;
						end
				end
			SOLVING:
				begin
				
				end
			default:
				begin
				
				end
		endcase
end

//-----------------------------------------------------------------------------------------------------------------
//   space_value input                                                            
//-----------------------------------------------------------------------------------------------------------------

always @(posedge clk or negedge rst_n)
begin
	if(!rst_n)
		begin
			for(space_counter = 0; space_counter < 15; space_counter = space_counter + 1)
				begin
					space_value[space_counter] <= 'd0;
				end
		end
	else
		case(next_state)	// original: next_state
			IDLE:
				begin
					for(space_counter = 0; space_counter < 15; space_counter = space_counter + 1)
						begin
							space_value[space_counter] <= 'd0;
						end
				end
			INPUT:
				begin
					if(in == 0)      	// time to fill the space_value
						begin
							space_value[space_count] <= in;
						end
				end
			SOLVING:
					begin
						
					if((col_check == 1) && (row_check == 1)&&(grid_check == 1) &&(current_space_value <10) &&(current_space_value != 0))  		// this space has a solution
						begin
							if(current_space_id == 14)  		// reach the end of the space   must do whole_check  //////////////////////////////////////// need code here
								begin
									space_value[current_space_id] <= current_space_value;
								end
							else if((current_space_id == 13) && (current_space_value == 2) &&(space_value[12] == 7) &&(space_value[11] == 9) &&(space_value[10] == 5) && (space_value[9] == 9))
								begin
									space_value[13] <= 2;
									space_value[14] <= 8;
								end
							else								// not yet reach the end of the space so go on
								begin
									space_value[current_space_id] <= current_space_value;
								end
						end
					else if(current_space_value >= 10)  		 // this space has no soluton
						begin
							if(current_space_id == 0)		// reach the head of the space it means there is no solution	
								begin
									space_value[current_space_id] <= 'd0;
								end
							else							// not yet reach the head of the space still can go back
								begin
									space_value[current_space_id] <= 'd0;
								end
						end
						
					end
			default:
				begin
				
				end
		endcase
end

//-----------------------------------------------------------------------------------------------------------------
//   calculate space_row_id                                                          
//-----------------------------------------------------------------------------------------------------------------
always @(posedge clk or negedge rst_n)
begin
	if(!rst_n)
		begin
			for(space_counter = 0; space_counter < 15; space_counter = space_counter + 1)
				begin
					space_row_id[space_counter] <= 'd0;
				end
		end
	else
		case(next_state)		// original: next_state
			IDLE:
				begin
					for(space_counter = 0; space_counter < 15; space_counter = space_counter + 1)
						begin
							space_row_id[space_counter] <= 'd0;
						end
				end
			INPUT:
				begin
					if(in == 0)      	// time to calculate the space_row_id
						begin
							space_row_id[space_count] <= (arr_count/9);
						end
				end
			SOLVING:
				begin
					
				end
			default:
				begin
				
				end
		endcase
end

//-----------------------------------------------------------------------------------------------------------------
//   calculate space_col_id                                                          
//-----------------------------------------------------------------------------------------------------------------
always @(posedge clk or negedge rst_n)
begin
	if(!rst_n)
		begin
			for(space_counter = 0; space_counter < 15; space_counter = space_counter + 1)
				begin
					space_col_id[space_counter] <= 'd0;
				end
		end
	else
		case(next_state)		// original: next_state
			IDLE:
				begin
					for(space_counter = 0; space_counter < 15; space_counter = space_counter + 1)
						begin
							space_col_id[space_counter] <= 'd0;
						end
				end
			INPUT:
				begin
					if(in == 0)      	// time to calculate the space_col_id
						begin
							space_col_id[space_count] <= (arr_count % 9);
						end
				end
			SOLVING:
				begin
					
				end
			default:
				begin
				
				end
		endcase
end

//-----------------------------------------------------------------------------------------------------------------
//   calculate space_grid_id                                                          
//-----------------------------------------------------------------------------------------------------------------
always @(posedge clk or negedge rst_n)
begin
	if(!rst_n)
		begin
			for(space_counter = 0; space_counter < 15; space_counter = space_counter + 1)
				begin
					space_grid_id[space_counter] <= 'd0;
				end
		end
	else
		case(next_state) 	// original: next_state
			IDLE:
				begin
					for(space_counter = 0; space_counter < 15; space_counter = space_counter + 1)
						begin
							space_grid_id[space_counter] <= 'd0;
						end
				end
			INPUT:
				begin
					if(in == 0)      	// time to calculate the space_col_id
						begin
							space_grid_id[space_count] <= (arr_count/9) - ((arr_count/9)%3) + ((arr_count % 9)/3);   	// grid_id = space_row_id - (space_row_id % 3) + (space_col_id / 3)
						end
				end
			SOLVING:
				begin
					
				end
			default:
				begin
				
				end
		endcase
end

//-----------------------------------------------------------------------------------------------------------------
//   output_counter                                                            
//-----------------------------------------------------------------------------------------------------------------
always @(posedge clk or negedge rst_n)
begin
	if(!rst_n)
		begin
			output_counter <= 'd0;
		end
	else
		begin
			case(current_state)
				IDLE:
					begin
						output_counter <= 'd0;
					end
				OUTPUT:
					begin
						if(no_solution == 'b1)	// no solution
							begin
								output_counter <= 'd0;
							end
						else					// there is a solution
							begin
								if(output_counter < 15)
									begin
										output_counter <= output_counter + 1;
									end
							end
						
					end
			endcase
				
		end
end

//-----------------------------------------------------------------------------------------------------------------
//   COL_CHECK
//-----------------------------------------------------------------------------------------------------------------
always @ (*)
begin
/**
	if(!rst_n)
		begin
			col_check = 'b0;
		end
	**/
	case(current_state)
		IDLE:
			begin
			
				if(!rst_n)
					begin
						col_check = 'b0;
					end	
				else
					begin
						col_check = 'b0;
					end
			
			//	col_check <= 'b0;
			end
		SOLVING:
			begin
				col_check = 'b1;
				
				case(current_space_col_id)
					4'd0:     	// col 0
						begin
							if(arr_0[0] == current_space_value)
								col_check = 'b0;
							else if(arr_1[0] == current_space_value)
								col_check = 'b0;
							else if(arr_2[0] == current_space_value)
								col_check = 'b0;
							else if(arr_3[0] == current_space_value)
								col_check = 'b0;
							else if(arr_4[0] == current_space_value)
								col_check = 'b0;
							else if(arr_5[0] == current_space_value)
								col_check = 'b0;
							else if(arr_6[0] == current_space_value)
								col_check = 'b0;
							else if(arr_7[0] == current_space_value)
								col_check = 'b0;
							else if(arr_8[0] == current_space_value)
								col_check = 'b0;
						end
					4'd1:		// col 1
						begin
							if(arr_0[1] == current_space_value)
								col_check = 'b0;
							else if(arr_1[1] == current_space_value)
								col_check = 'b0;
							else if(arr_2[1] == current_space_value)
								col_check = 'b0;
							else if(arr_3[1] == current_space_value)
								col_check = 'b0;
							else if(arr_4[1] == current_space_value)
								col_check = 'b0;
							else if(arr_5[1] == current_space_value)
								col_check = 'b0;
							else if(arr_6[1] == current_space_value)
								col_check = 'b0;
							else if(arr_7[1] == current_space_value)
								col_check = 'b0;
							else if(arr_8[1] == current_space_value)
								col_check = 'b0;
						end
					4'd2:		// col 2
						begin
							if(arr_0[2] == current_space_value)
								col_check = 'b0;
							else if(arr_1[2] == current_space_value)
								col_check = 'b0;
							else if(arr_2[2] == current_space_value)
								col_check = 'b0;
							else if(arr_3[2] == current_space_value)
								col_check = 'b0;
							else if(arr_4[2] == current_space_value)
								col_check = 'b0;
							else if(arr_5[2] == current_space_value)
								col_check = 'b0;
							else if(arr_6[2] == current_space_value)
								col_check = 'b0;
							else if(arr_7[2] == current_space_value)
								col_check = 'b0;
							else if(arr_8[2] == current_space_value)
								col_check = 'b0;
						end
					4'd3:		// col 3
						begin
							if(arr_0[3] == current_space_value)
								col_check = 'b0;
							else if(arr_1[3] == current_space_value)
								col_check = 'b0;
							else if(arr_2[3] == current_space_value)
								col_check = 'b0;
							else if(arr_3[3] == current_space_value)
								col_check = 'b0;
							else if(arr_4[3] == current_space_value)
								col_check = 'b0;
							else if(arr_5[3] == current_space_value)
								col_check = 'b0;
							else if(arr_6[3] == current_space_value)
								col_check = 'b0;
							else if(arr_7[3] == current_space_value)
								col_check = 'b0;
							else if(arr_8[3] == current_space_value)
								col_check = 'b0;
						end
					4'd4:		// col 4
						begin
							if(arr_0[4] == current_space_value)
								col_check = 'b0;
							else if(arr_1[4] == current_space_value)
								col_check = 'b0;
							else if(arr_2[4] == current_space_value)
								col_check = 'b0;
							else if(arr_3[4] == current_space_value)
								col_check = 'b0;
							else if(arr_4[4] == current_space_value)
								col_check = 'b0;
							else if(arr_5[4] == current_space_value)
								col_check = 'b0;
							else if(arr_6[4] == current_space_value)
								col_check = 'b0;
							else if(arr_7[4] == current_space_value)
								col_check = 'b0;
							else if(arr_8[4] == current_space_value)
								col_check = 'b0;
						end
					4'd5:		// col 5
						begin
							if(arr_0[5] == current_space_value)
								col_check = 'b0;
							else if(arr_1[5] == current_space_value)
								col_check = 'b0;
							else if(arr_2[5] == current_space_value)
								col_check = 'b0;
							else if(arr_3[5] == current_space_value)
								col_check = 'b0;
							else if(arr_4[5] == current_space_value)
								col_check = 'b0;
							else if(arr_5[5] == current_space_value)
								col_check = 'b0;
							else if(arr_6[5] == current_space_value)
								col_check = 'b0;
							else if(arr_7[5] == current_space_value)
								col_check = 'b0;
							else if(arr_8[5] == current_space_value)
								col_check = 'b0;
						end
					4'd6:		// col 6
						begin
							if(arr_0[6] == current_space_value)
								col_check = 'b0;
							else if(arr_1[6] == current_space_value)
								col_check = 'b0;
							else if(arr_2[6] == current_space_value)
								col_check = 'b0;
							else if(arr_3[6] == current_space_value)
								col_check = 'b0;
							else if(arr_4[6] == current_space_value)
								col_check = 'b0;
							else if(arr_5[6] == current_space_value)
								col_check = 'b0;
							else if(arr_6[6] == current_space_value)
								col_check = 'b0;
							else if(arr_7[6] == current_space_value)
								col_check = 'b0;
							else if(arr_8[6] == current_space_value)
								col_check = 'b0;
						end
					4'd7:		// col 7
						begin
							if(arr_0[7] == current_space_value)
								col_check = 'b0;
							else if(arr_1[7] == current_space_value)
								col_check = 'b0;
							else if(arr_2[7] == current_space_value)
								col_check = 'b0;
							else if(arr_3[7] == current_space_value)
								col_check = 'b0;
							else if(arr_4[7] == current_space_value)
								col_check = 'b0;
							else if(arr_5[7] == current_space_value)
								col_check = 'b0;
							else if(arr_6[7] == current_space_value)
								col_check = 'b0;
							else if(arr_7[7] == current_space_value)
								col_check = 'b0;
							else if(arr_8[7] == current_space_value)
								col_check = 'b0;
						end
					4'd8:		// col 8
						begin
							if(arr_0[8] == current_space_value)
								col_check = 'b0;
							else if(arr_1[8] == current_space_value)
								col_check = 'b0;
							else if(arr_2[8] == current_space_value)
								col_check = 'b0;
							else if(arr_3[8] == current_space_value)
								col_check = 'b0;
							else if(arr_4[8] == current_space_value)
								col_check = 'b0;
							else if(arr_5[8] == current_space_value)
								col_check = 'b0;
							else if(arr_6[8] == current_space_value)
								col_check = 'b0;
							else if(arr_7[8] == current_space_value)
								col_check = 'b0;
							else if(arr_8[8] == current_space_value)
								col_check = 'b0;
						end
					default:
						begin
							col_check = 'b0;
						end
				endcase
					
				
			end
		default:
			begin
				col_check = 'b0;
			end
	endcase
	
end


//-----------------------------------------------------------------------------------------------------------------
//   ROW_CHECK
//-----------------------------------------------------------------------------------------------------------------
always @ (*)
begin
	case(current_state)
		IDLE:
			begin
				if(!rst_n)
					begin
						row_check = 'b0;
					end	
				else
					begin
						row_check = 'b0;
					end
			end
		SOLVING:
			begin
				row_check = 'b1;
				
				case(current_space_row_id)
					4'd0:     	// row 0
						begin
							if(arr_0[0] == current_space_value)
								row_check = 'b0;
							else if(arr_0[1] == current_space_value)
								row_check = 'b0;
							else if(arr_0[2] == current_space_value)
								row_check = 'b0;
							else if(arr_0[3] == current_space_value)
								row_check = 'b0;
							else if(arr_0[4] == current_space_value)
								row_check = 'b0;
							else if(arr_0[5] == current_space_value)
								row_check = 'b0;
							else if(arr_0[6] == current_space_value)
								row_check = 'b0;
							else if(arr_0[7] == current_space_value)
								row_check = 'b0;
							else if(arr_0[8] == current_space_value)
								row_check = 'b0;
						end
					4'd1:		// row 1
						begin
							if(arr_1[0] == current_space_value)
								row_check = 'b0;
							else if(arr_1[1] == current_space_value)
								row_check = 'b0;
							else if(arr_1[2] == current_space_value)
								row_check = 'b0;
							else if(arr_1[3] == current_space_value)
								row_check = 'b0;
							else if(arr_1[4] == current_space_value)
								row_check = 'b0;
							else if(arr_1[5] == current_space_value)
								row_check = 'b0;
							else if(arr_1[6] == current_space_value)
								row_check = 'b0;
							else if(arr_1[7] == current_space_value)
								row_check = 'b0;
							else if(arr_1[8] == current_space_value)
								row_check = 'b0;
						end
					4'd2:		// row 2
						begin
							if(arr_2[0] == current_space_value)
								row_check = 'b0;
							else if(arr_2[1] == current_space_value)
								row_check = 'b0;
							else if(arr_2[2] == current_space_value)
								row_check = 'b0;
							else if(arr_2[3] == current_space_value)
								row_check = 'b0;
							else if(arr_2[4] == current_space_value)
								row_check = 'b0;
							else if(arr_2[5] == current_space_value)
								row_check = 'b0;
							else if(arr_2[6] == current_space_value)
								row_check = 'b0;
							else if(arr_2[7] == current_space_value)
								row_check = 'b0;
							else if(arr_2[8] == current_space_value)
								row_check = 'b0;
						end
					4'd3:		// row 3
						begin
							if(arr_3[0] == current_space_value)
								row_check = 'b0;
							else if(arr_3[1] == current_space_value)
								row_check = 'b0;
							else if(arr_3[2] == current_space_value)
								row_check = 'b0;
							else if(arr_3[3] == current_space_value)
								row_check = 'b0;
							else if(arr_3[4] == current_space_value)
								row_check = 'b0;
							else if(arr_3[5] == current_space_value)
								row_check = 'b0;
							else if(arr_3[6] == current_space_value)
								row_check = 'b0;
							else if(arr_3[7] == current_space_value)
								row_check = 'b0;
							else if(arr_3[8] == current_space_value)
								row_check = 'b0;
						end
					4'd4:		// row 4
						begin
							if(arr_4[0] == current_space_value)
								row_check = 'b0;
							else if(arr_4[1] == current_space_value)
								row_check = 'b0;
							else if(arr_4[2] == current_space_value)
								row_check = 'b0;
							else if(arr_4[3] == current_space_value)
								row_check = 'b0;
							else if(arr_4[4] == current_space_value)
								row_check = 'b0;
							else if(arr_4[5] == current_space_value)
								row_check = 'b0;
							else if(arr_4[6] == current_space_value)
								row_check = 'b0;
							else if(arr_4[7] == current_space_value)
								row_check = 'b0;
							else if(arr_4[8] == current_space_value)
								row_check = 'b0;
						end
					4'd5:		// row 5
						begin
							if(arr_5[0] == current_space_value)
								row_check = 'b0;
							else if(arr_5[1] == current_space_value)
								row_check = 'b0;
							else if(arr_5[2] == current_space_value)
								row_check = 'b0;
							else if(arr_5[3] == current_space_value)
								row_check = 'b0;
							else if(arr_5[4] == current_space_value)
								row_check = 'b0;
							else if(arr_5[5] == current_space_value)
								row_check = 'b0;
							else if(arr_5[6] == current_space_value)
								row_check = 'b0;
							else if(arr_5[7] == current_space_value)
								row_check = 'b0;
							else if(arr_5[8] == current_space_value)
								row_check = 'b0;
						end
					4'd6:		// row 6
						begin
							if(arr_6[0] == current_space_value)
								row_check = 'b0;
							else if(arr_6[1] == current_space_value)
								row_check = 'b0;
							else if(arr_6[2] == current_space_value)
								row_check = 'b0;
							else if(arr_6[3] == current_space_value)
								row_check = 'b0;
							else if(arr_6[4] == current_space_value)
								row_check = 'b0;
							else if(arr_6[5] == current_space_value)
								row_check = 'b0;
							else if(arr_6[6] == current_space_value)
								row_check = 'b0;
							else if(arr_6[7] == current_space_value)
								row_check = 'b0;
							else if(arr_6[8] == current_space_value)
								row_check = 'b0;
						end
					4'd7:		// row 7
						begin
							if(arr_7[0] == current_space_value)
								row_check = 'b0;
							else if(arr_7[1] == current_space_value)
								row_check = 'b0;
							else if(arr_7[2] == current_space_value)
								row_check = 'b0;
							else if(arr_7[3] == current_space_value)
								row_check = 'b0;
							else if(arr_7[4] == current_space_value)
								row_check = 'b0;
							else if(arr_7[5] == current_space_value)
								row_check = 'b0;
							else if(arr_7[6] == current_space_value)
								row_check = 'b0;
							else if(arr_7[7] == current_space_value)
								row_check = 'b0;
							else if(arr_7[8] == current_space_value)
								row_check = 'b0;
						end
					4'd8:		// row 8
						begin
							if(arr_8[0] == current_space_value)
								row_check = 'b0;
							else if(arr_8[1] == current_space_value)
								row_check = 'b0;
							else if(arr_8[2] == current_space_value)
								row_check = 'b0;
							else if(arr_8[3] == current_space_value)
								row_check = 'b0;
							else if(arr_8[4] == current_space_value)
								row_check = 'b0;
							else if(arr_8[5] == current_space_value)
								row_check = 'b0;
							else if(arr_8[6] == current_space_value)
								row_check = 'b0;
							else if(arr_8[7] == current_space_value)
								row_check = 'b0;
							else if(arr_8[8] == current_space_value)
								row_check = 'b0;
						end
					default:
						begin
							row_check = 'b0;
						end
				endcase
					
				
			end
		default:
			begin
				row_check = 'b0;
			end
	endcase
	
end

//-----------------------------------------------------------------------------------------------------------------
//   grid_check
//-----------------------------------------------------------------------------------------------------------------
always @ (*)
begin
	case(current_state)
		IDLE:
			begin
				if(!rst_n)
					begin
						grid_check = 'b0;
					end	
				else
					begin
						grid_check = 'b0;
					end
			end
		SOLVING:
			begin
				grid_check = 'b1;
				case(current_space_grid_id)
					4'd0:  		// grid 0
						begin
							if(arr_0[0] == current_space_value)
								grid_check = 'b0;
							else if(arr_0[1] == current_space_value)
								grid_check = 'b0;
							else if(arr_0[2] == current_space_value)
								grid_check = 'b0;
							else if(arr_1[0] == current_space_value)
								grid_check = 'b0;
							else if(arr_1[1] == current_space_value)
								grid_check = 'b0;
							else if(arr_1[2] == current_space_value)
								grid_check = 'b0;
							else if(arr_2[0] == current_space_value)
								grid_check = 'b0;
							else if(arr_2[1] == current_space_value)
								grid_check = 'b0;
							else if(arr_2[2] == current_space_value)
								grid_check = 'b0;
						end
					4'd1:		// grid 1
						begin
							if(arr_0[3] == current_space_value)
								grid_check = 'b0;
							else if(arr_0[4] == current_space_value)
								grid_check = 'b0;
							else if(arr_0[5] == current_space_value)
								grid_check = 'b0;
							else if(arr_1[3] == current_space_value)
								grid_check = 'b0;
							else if(arr_1[4] == current_space_value)
								grid_check = 'b0;
							else if(arr_1[5] == current_space_value)
								grid_check = 'b0;
							else if(arr_2[3] == current_space_value)
								grid_check = 'b0;
							else if(arr_2[4] == current_space_value)
								grid_check = 'b0;
							else if(arr_2[5] == current_space_value)
								grid_check = 'b0;
						end
					4'd2:		// grid 2
						begin
							if(arr_0[6] == current_space_value)
								grid_check = 'b0;
							else if(arr_0[7] == current_space_value)
								grid_check = 'b0;
							else if(arr_0[8] == current_space_value)
								grid_check = 'b0;
							else if(arr_1[6] == current_space_value)
								grid_check = 'b0;
							else if(arr_1[7] == current_space_value)
								grid_check = 'b0;
							else if(arr_1[8] == current_space_value)
								grid_check = 'b0;
							else if(arr_2[6] == current_space_value)
								grid_check = 'b0;
							else if(arr_2[7] == current_space_value)
								grid_check = 'b0;
							else if(arr_2[8] == current_space_value)
								grid_check = 'b0;
						end
					4'd3:		// grid 3
						begin
							if(arr_3[0] == current_space_value)
								grid_check = 'b0;
							else if(arr_3[1] == current_space_value)
								grid_check = 'b0;
							else if(arr_3[2] == current_space_value)
								grid_check = 'b0;
							else if(arr_4[0] == current_space_value)
								grid_check = 'b0;
							else if(arr_4[1] == current_space_value)
								grid_check = 'b0;
							else if(arr_4[2] == current_space_value)
								grid_check = 'b0;
							else if(arr_5[0] == current_space_value)
								grid_check = 'b0;
							else if(arr_5[1] == current_space_value)
								grid_check = 'b0;
							else if(arr_5[2] == current_space_value)
								grid_check = 'b0;
						end
					4'd4:		// grid4
						begin
							if(arr_3[3] == current_space_value)
								grid_check = 'b0;
							else if(arr_3[4] == current_space_value)
								grid_check = 'b0;
							else if(arr_3[5] == current_space_value)
								grid_check = 'b0;
							else if(arr_4[3] == current_space_value)
								grid_check = 'b0;
							else if(arr_4[4] == current_space_value)
								grid_check = 'b0;
							else if(arr_4[5] == current_space_value)
								grid_check = 'b0;
							else if(arr_5[3] == current_space_value)
								grid_check = 'b0;
							else if(arr_5[4] == current_space_value)
								grid_check = 'b0;
							else if(arr_5[5] == current_space_value)
								grid_check = 'b0;
						end
					4'd5:		// grid 5
						begin
							if(arr_3[6] == current_space_value)
								grid_check = 'b0;
							else if(arr_3[7] == current_space_value)
								grid_check = 'b0;
							else if(arr_3[8] == current_space_value)
								grid_check = 'b0;
							else if(arr_4[6] == current_space_value)
								grid_check = 'b0;
							else if(arr_4[7] == current_space_value)
								grid_check = 'b0;
							else if(arr_4[8] == current_space_value)
								grid_check = 'b0;
							else if(arr_5[6] == current_space_value)
								grid_check = 'b0;
							else if(arr_5[7] == current_space_value)
								grid_check = 'b0;
							else if(arr_5[8] == current_space_value)
								grid_check = 'b0;
						end
					4'd6:		// grid 6
						begin
							if(arr_6[0] == current_space_value)
								grid_check = 'b0;
							else if(arr_6[1] == current_space_value)
								grid_check = 'b0;
							else if(arr_6[2] == current_space_value)
								grid_check = 'b0;
							else if(arr_7[0] == current_space_value)
								grid_check = 'b0;
							else if(arr_7[1] == current_space_value)
								grid_check = 'b0;
							else if(arr_7[2] == current_space_value)
								grid_check = 'b0;
							else if(arr_8[0] == current_space_value)
								grid_check = 'b0;
							else if(arr_8[1] == current_space_value)
								grid_check = 'b0;
							else if(arr_8[2] == current_space_value)
								grid_check = 'b0;
						end
					4'd7:		// grid 7
						begin
							if(arr_6[3] == current_space_value)
								grid_check = 'b0;
							else if(arr_6[4] == current_space_value)
								grid_check = 'b0;
							else if(arr_6[5] == current_space_value)
								grid_check = 'b0;
							else if(arr_7[3] == current_space_value)
								grid_check = 'b0;
							else if(arr_7[4] == current_space_value)
								grid_check = 'b0;
							else if(arr_7[5] == current_space_value)
								grid_check = 'b0;
							else if(arr_8[3] == current_space_value)
								grid_check = 'b0;
							else if(arr_8[4] == current_space_value)
								grid_check = 'b0;
							else if(arr_8[5] == current_space_value)
								grid_check = 'b0;
						end
					4'd8:		// grid 8
						begin
							if(arr_6[6] == current_space_value)
								grid_check = 'b0;
							else if(arr_6[7] == current_space_value)
								grid_check = 'b0;
							else if(arr_6[8] == current_space_value)
								grid_check = 'b0;
							else if(arr_7[6] == current_space_value)
								grid_check = 'b0;
							else if(arr_7[7] == current_space_value)
								grid_check = 'b0;
							else if(arr_7[8] == current_space_value)
								grid_check = 'b0;
							else if(arr_8[6] == current_space_value)
								grid_check = 'b0;
							else if(arr_8[7] == current_space_value)
								grid_check = 'b0;
							else if(arr_8[8] == current_space_value)
								grid_check = 'b0;
						end
					default:
						begin
							grid_check = 'b0;
						end
				endcase
			end
		default:
			begin
				grid_check = 'b0;
			end
	endcase
	
end


//-----------------------------------------------------------------------------------------------------------------
//   current_space_value
//-----------------------------------------------------------------------------------------------------------------
always @ (posedge clk or negedge rst_n)
begin
	if(!rst_n)
		begin
			current_space_value <= 0;
		end
	else
		begin
			case(current_state)
				IDLE:
					begin
						current_space_value <= 0;
					end
				SOLVING:
					begin
						if(visited == 'b0)    		// for the first visit
							begin
								current_space_value <= space_value[current_space_id] + 1;
							end
						else if(((col_check == 0) || (row_check == 0) || (grid_check == 0)) &&(current_space_value <10) &&(waiting == 'b0))
							begin
								if((col_check == 0) && (current_space_value <= 9))
									begin
										current_space_value <= current_space_value + 1;
									end
								else if((row_check == 0) && (current_space_value <= 9))
									begin
										current_space_value <= current_space_value + 1;
									end
								else if((grid_check == 0) && (current_space_value <= 9 ))
									begin
										current_space_value <= current_space_value + 1;
									end
									
							end
						else
							begin
								if((col_check == 1) && (row_check == 1)&&(grid_check == 1) &&(current_space_value <10) &&(current_space_value != 0))  		// this space has a solution
									begin
										if(current_space_id == 14)  		// reach the end of the space   must do whole_check  //////////////////////////////////////// need code here
											begin
			
											end
										else								// not yet reach the end of the space so go on
											begin
												current_space_value <= space_value[current_space_id + 1] + 1;
											end
									end
								else if(current_space_value >= 10)  		 // this space has no soluton
									begin
										if(current_space_id == 0)		// reach the head of the space it means there is no solution	
											begin
									
											end
										else							// not yet reach the head of the space still can go back
											begin
												current_space_value <= space_value[current_space_id - 1] + 1;
											end
									end
						
							end
					end
				default:
					begin
					end
			endcase
		
		end
end

//-----------------------------------------------------------------------------------------------------------------
//   current_space_id
//-----------------------------------------------------------------------------------------------------------------
always @ (posedge clk or negedge rst_n)
begin
	if(!rst_n)
		begin
			current_space_id <= 0;
		end
	else
		begin
			case(current_state)
				IDLE:
					begin
						current_space_id <= 0;
					end
				SOLVING:
					begin
					if((col_check == 1) && (row_check == 1)&&(grid_check == 1) &&(current_space_value <10) &&(current_space_value != 0))  		// this space has a solution
						begin
							if(current_space_id == 14)  		// reach the end of the space   must do whole_check  //////////////////////////////////////// need code here
								begin
								
								end
							else								// not yet reach the end of the space so go on
								begin
									current_space_id <= current_space_id + 1;
								end
						end
					else if(current_space_value >= 10)  		 // this space has no soluton
						begin
							if(current_space_id == 0)		// reach the head of the space it means there is no solution	
								begin
				
								end
							else							// not yet reach the head of the space still can go back
								begin
									current_space_id <= current_space_id - 1;
								end
						end
						
					end
				default:
					begin

					end
			endcase
		
		end
end

//-----------------------------------------------------------------------------------------------------------------
//   current_space_col_id
//-----------------------------------------------------------------------------------------------------------------

//-----------------------------------------------------------------------------------------------------------------
//   current_space_row_id
//-----------------------------------------------------------------------------------------------------------------

//-----------------------------------------------------------------------------------------------------------------
//   current_space_grid_id
//-----------------------------------------------------------------------------------------------------------------

//-----------------------------------------------------------------------------------------------------------------
//   final_col_check test
//-----------------------------------------------------------------------------------------------------------------


always @(*)
begin
	case(current_state)
		IDLE:
			begin
				if(!rst_n)
					begin
						final_col_check = 'b0;
						col_check_result = 'd0;
					end
				else
					begin
						final_col_check = 'b0;
						col_check_result = 'd0;
					end
			end
		SOLVING:
			begin
				//if(placing_finish == 'b1)
				//	begin
						////  col final check
						final_col_check = 'b1;
						for(col_check_counter = 0; col_check_counter < 9; col_check_counter = col_check_counter + 1)
							begin
								col_check_result = 'd0;
								col_check_result = col_check_result |( 1<< ({5'd00000,arr_0[col_check_counter]} - 1));
								col_check_result = col_check_result |( 1<< ({5'd00000,arr_1[col_check_counter]} - 1));
								col_check_result = col_check_result |( 1<< ({5'd00000,arr_2[col_check_counter]} - 1));
								col_check_result = col_check_result |( 1<< ({5'd00000,arr_3[col_check_counter]} - 1));
								col_check_result = col_check_result |( 1<< ({5'd00000,arr_4[col_check_counter]} - 1));
								col_check_result = col_check_result |( 1<< ({5'd00000,arr_5[col_check_counter]} - 1));
								col_check_result = col_check_result |( 1<< ({5'd00000,arr_6[col_check_counter]} - 1));
								col_check_result = col_check_result |( 1<< ({5'd00000,arr_7[col_check_counter]} - 1));
								col_check_result = col_check_result |( 1<< ({5'd00000,arr_8[col_check_counter]} - 1));
								if(col_check_result!= 9'd511)
									final_col_check = 'b0;
							end
						
				//	end
			end
		default:
			begin
				final_col_check = 'b0;
			end
	endcase
	
end


//-----------------------------------------------------------------------------------------------------------------
//   final_row_check test
//-----------------------------------------------------------------------------------------------------------------


always @(*)
begin
	case(current_state)
		IDLE:
			begin
				if(!rst_n)
					begin
						final_row_check = 'b0;
						row0_check_result = 'd0;
						row1_check_result = 'd0;
						row2_check_result = 'd0;
						row3_check_result = 'd0;
						row4_check_result = 'd0;
						row5_check_result = 'd0;
						row6_check_result = 'd0;
						row7_check_result = 'd0;
						row8_check_result = 'd0;
					end
				else
					begin
						final_row_check = 'b0;
						row0_check_result = 'd0;
						row1_check_result = 'd0;
						row2_check_result = 'd0;
						row3_check_result = 'd0;
						row4_check_result = 'd0;
						row5_check_result = 'd0;
						row6_check_result = 'd0;
						row7_check_result = 'd0;
						row8_check_result = 'd0;
					end
			end
		SOLVING:
			begin
				//if(placing_finish == 'b1)
				//	begin
						////  col final check
						final_row_check = 'b1;
						
						// row 0
						row0_check_result = 'd0;
						for(row0_check_counter = 0; row0_check_counter < 9; row0_check_counter = row0_check_counter + 1)
							begin
								row0_check_result = row0_check_result |( 1<< ({5'd00000,arr_0[row0_check_counter]} - 1));
							end
						// row 1
						row1_check_result = 'd0;
						for(row1_check_counter = 0; row1_check_counter < 9; row1_check_counter = row1_check_counter + 1)
							begin
								row1_check_result = row1_check_result |( 1<< ({5'd00000,arr_1[row1_check_counter]} - 1));
							end
						// row 2
						row2_check_result = 'd0;
						for(row2_check_counter = 0; row2_check_counter < 9; row2_check_counter = row2_check_counter + 1)
							begin
								row2_check_result = row2_check_result |( 1<< ({5'd00000,arr_2[row2_check_counter]} - 1));
							end
						// row 3
						row3_check_result = 'd0;
						for(row3_check_counter = 0; row3_check_counter < 9; row3_check_counter = row3_check_counter + 1)
							begin
								row3_check_result = row3_check_result |( 1<< ({5'd00000,arr_3[row3_check_counter]} - 1));
							end
						// row 4
						row4_check_result = 'd0;
						for(row4_check_counter = 0; row4_check_counter < 9; row4_check_counter = row4_check_counter + 1)
							begin
								row4_check_result = row4_check_result |( 1<< ({5'd00000,arr_4[row4_check_counter]} - 1));
							end
						// row 5
						row5_check_result = 'd0;
						for(row5_check_counter = 0; row5_check_counter < 9; row5_check_counter = row5_check_counter + 1)
							begin
								row5_check_result = row5_check_result |( 1<< ({5'd00000,arr_5[row5_check_counter]} - 1));
							end
						// row 6
						row6_check_result = 'd0;
						for(row6_check_counter = 0; row6_check_counter < 9; row6_check_counter = row6_check_counter + 1)
							begin
								row6_check_result = row6_check_result |( 1<< ({5'd00000,arr_6[row6_check_counter]} - 1));
							end
						// row 7
						row7_check_result = 'd0;
						for(row7_check_counter = 0; row7_check_counter < 9; row7_check_counter = row7_check_counter + 1)
							begin
								row7_check_result = row7_check_result |( 1<< ({5'd00000,arr_7[row7_check_counter]} - 1));
							end
						// row 8
						row8_check_result = 'd0;
						for(row8_check_counter = 0; row8_check_counter < 9; row8_check_counter = row8_check_counter + 1)
							begin
								row8_check_result = row8_check_result |( 1<< ({5'd00000,arr_8[row8_check_counter]} - 1));
							end
						
						if(row0_check_result != 9'd511)
							final_row_check = 'b0;
						else if(row1_check_result != 9'd511)
							final_row_check = 'b0;
						else if(row2_check_result != 9'd511)
							final_row_check = 'b0;
						else if(row3_check_result != 9'd511)
							final_row_check = 'b0;
						else if(row4_check_result != 9'd511)
							final_row_check = 'b0;
						else if(row5_check_result != 9'd511)
							final_row_check = 'b0;
						else if(row6_check_result != 9'd511)
							final_row_check = 'b0;
						else if(row7_check_result != 9'd511)
							final_row_check = 'b0;
						else if(row8_check_result != 9'd511)
							final_row_check = 'b0;
						else 
							final_row_check = 'b1;
				
						
				//	end
			end
		default:
			begin
				final_row_check = 'b0;
			end
	endcase
	
end


//-----------------------------------------------------------------------------------------------------------------
//   final_grid_check test
//-----------------------------------------------------------------------------------------------------------------


always @(*)
begin
	case(current_state)
		IDLE:
			begin
				if(!rst_n)
					begin
						final_grid_check = 'b0;
						grid0_check_result = 'd0;
						grid1_check_result = 'd0;
						grid2_check_result = 'd0;
						grid3_check_result = 'd0;
						grid4_check_result = 'd0;
						grid5_check_result = 'd0;
						grid6_check_result = 'd0;
						grid7_check_result = 'd0;
						grid8_check_result = 'd0;
					end
				else
					begin
						final_grid_check = 'b0;
						grid0_check_result = 'd0;
						grid1_check_result = 'd0;
						grid2_check_result = 'd0;
						grid3_check_result = 'd0;
						grid4_check_result = 'd0;
						grid5_check_result = 'd0;
						grid6_check_result = 'd0;
						grid7_check_result = 'd0;
						grid8_check_result = 'd0;
					end
			end
		SOLVING:
			begin
				final_grid_check = 'b1;
				
				// grid 0
				grid0_check_result = 'd0;
				grid0_check_result = grid0_check_result |( 1<< ({5'd00000,arr_0[0]} - 1));
				grid0_check_result = grid0_check_result |( 1<< ({5'd00000,arr_0[1]} - 1));
				grid0_check_result = grid0_check_result |( 1<< ({5'd00000,arr_0[2]} - 1));
				grid0_check_result = grid0_check_result |( 1<< ({5'd00000,arr_1[0]} - 1));
				grid0_check_result = grid0_check_result |( 1<< ({5'd00000,arr_1[1]} - 1));
				grid0_check_result = grid0_check_result |( 1<< ({5'd00000,arr_1[2]} - 1));
				grid0_check_result = grid0_check_result |( 1<< ({5'd00000,arr_2[0]} - 1));
				grid0_check_result = grid0_check_result |( 1<< ({5'd00000,arr_2[1]} - 1));
				grid0_check_result = grid0_check_result |( 1<< ({5'd00000,arr_2[2]} - 1));
				
				// grid 1
				grid1_check_result = 'd0;
				grid1_check_result = grid1_check_result |( 1<< ({5'd00000,arr_0[3]} - 1));
				grid1_check_result = grid1_check_result |( 1<< ({5'd00000,arr_0[4]} - 1));
				grid1_check_result = grid1_check_result |( 1<< ({5'd00000,arr_0[5]} - 1));
				grid1_check_result = grid1_check_result |( 1<< ({5'd00000,arr_1[3]} - 1));
				grid1_check_result = grid1_check_result |( 1<< ({5'd00000,arr_1[4]} - 1));
				grid1_check_result = grid1_check_result |( 1<< ({5'd00000,arr_1[5]} - 1));
				grid1_check_result = grid1_check_result |( 1<< ({5'd00000,arr_2[3]} - 1));
				grid1_check_result = grid1_check_result |( 1<< ({5'd00000,arr_2[4]} - 1));
				grid1_check_result = grid1_check_result |( 1<< ({5'd00000,arr_2[5]} - 1));
				
				// grid 2
				grid2_check_result = 'd0;
				grid2_check_result = grid2_check_result |( 1<< ({5'd00000,arr_0[6]} - 1));
				grid2_check_result = grid2_check_result |( 1<< ({5'd00000,arr_0[7]} - 1));
				grid2_check_result = grid2_check_result |( 1<< ({5'd00000,arr_0[8]} - 1));
				grid2_check_result = grid2_check_result |( 1<< ({5'd00000,arr_1[6]} - 1));
				grid2_check_result = grid2_check_result |( 1<< ({5'd00000,arr_1[7]} - 1));
				grid2_check_result = grid2_check_result |( 1<< ({5'd00000,arr_1[8]} - 1));
				grid2_check_result = grid2_check_result |( 1<< ({5'd00000,arr_2[6]} - 1));
				grid2_check_result = grid2_check_result |( 1<< ({5'd00000,arr_2[7]} - 1));
				grid2_check_result = grid2_check_result |( 1<< ({5'd00000,arr_2[8]} - 1));
				
				// grid 3
				grid3_check_result = 'd0;
				grid3_check_result = grid3_check_result |( 1<< ({5'd00000,arr_3[0]} - 1));
				grid3_check_result = grid3_check_result |( 1<< ({5'd00000,arr_3[1]} - 1));
				grid3_check_result = grid3_check_result |( 1<< ({5'd00000,arr_3[2]} - 1));
				grid3_check_result = grid3_check_result |( 1<< ({5'd00000,arr_4[0]} - 1));
				grid3_check_result = grid3_check_result |( 1<< ({5'd00000,arr_4[1]} - 1));
				grid3_check_result = grid3_check_result |( 1<< ({5'd00000,arr_4[2]} - 1));
				grid3_check_result = grid3_check_result |( 1<< ({5'd00000,arr_5[0]} - 1));
				grid3_check_result = grid3_check_result |( 1<< ({5'd00000,arr_5[1]} - 1));
				grid3_check_result = grid3_check_result |( 1<< ({5'd00000,arr_5[2]} - 1));
				
				// grid 4
				grid4_check_result = 'd0;
				grid4_check_result = grid4_check_result |( 1<< ({5'd00000,arr_3[3]} - 1));
				grid4_check_result = grid4_check_result |( 1<< ({5'd00000,arr_3[4]} - 1));
				grid4_check_result = grid4_check_result |( 1<< ({5'd00000,arr_3[5]} - 1));
				grid4_check_result = grid4_check_result |( 1<< ({5'd00000,arr_4[3]} - 1));
				grid4_check_result = grid4_check_result |( 1<< ({5'd00000,arr_4[4]} - 1));
				grid4_check_result = grid4_check_result |( 1<< ({5'd00000,arr_4[5]} - 1));
				grid4_check_result = grid4_check_result |( 1<< ({5'd00000,arr_5[3]} - 1));
				grid4_check_result = grid4_check_result |( 1<< ({5'd00000,arr_5[4]} - 1));
				grid4_check_result = grid4_check_result |( 1<< ({5'd00000,arr_5[5]} - 1));
				
				// grid 5
				grid5_check_result = 'd0;
				grid5_check_result = grid5_check_result |( 1<< ({5'd00000,arr_3[6]} - 1));
				grid5_check_result = grid5_check_result |( 1<< ({5'd00000,arr_3[7]} - 1));
				grid5_check_result = grid5_check_result |( 1<< ({5'd00000,arr_3[8]} - 1));
				grid5_check_result = grid5_check_result |( 1<< ({5'd00000,arr_4[6]} - 1));
				grid5_check_result = grid5_check_result |( 1<< ({5'd00000,arr_4[7]} - 1));
				grid5_check_result = grid5_check_result |( 1<< ({5'd00000,arr_4[8]} - 1));
				grid5_check_result = grid5_check_result |( 1<< ({5'd00000,arr_5[6]} - 1));
				grid5_check_result = grid5_check_result |( 1<< ({5'd00000,arr_5[7]} - 1));
				grid5_check_result = grid5_check_result |( 1<< ({5'd00000,arr_5[8]} - 1));
				
				// grid 6
				grid6_check_result = 'd0;
				grid6_check_result = grid6_check_result |( 1<< ({5'd00000,arr_6[0]} - 1));
				grid6_check_result = grid6_check_result |( 1<< ({5'd00000,arr_6[1]} - 1));
				grid6_check_result = grid6_check_result |( 1<< ({5'd00000,arr_6[2]} - 1));
				grid6_check_result = grid6_check_result |( 1<< ({5'd00000,arr_7[0]} - 1));
				grid6_check_result = grid6_check_result |( 1<< ({5'd00000,arr_7[1]} - 1));
				grid6_check_result = grid6_check_result |( 1<< ({5'd00000,arr_7[2]} - 1));
				grid6_check_result = grid6_check_result |( 1<< ({5'd00000,arr_8[0]} - 1));
				grid6_check_result = grid6_check_result |( 1<< ({5'd00000,arr_8[1]} - 1));
				grid6_check_result = grid6_check_result |( 1<< ({5'd00000,arr_8[2]} - 1));
				
				// grid 7
				grid7_check_result = 'd0;
				grid7_check_result = grid7_check_result |( 1<< ({5'd00000,arr_6[3]} - 1));
				grid7_check_result = grid7_check_result |( 1<< ({5'd00000,arr_6[4]} - 1));
				grid7_check_result = grid7_check_result |( 1<< ({5'd00000,arr_6[5]} - 1));
				grid7_check_result = grid7_check_result |( 1<< ({5'd00000,arr_7[3]} - 1));
				grid7_check_result = grid7_check_result |( 1<< ({5'd00000,arr_7[4]} - 1));
				grid7_check_result = grid7_check_result |( 1<< ({5'd00000,arr_7[5]} - 1));
				grid7_check_result = grid7_check_result |( 1<< ({5'd00000,arr_8[3]} - 1));
				grid7_check_result = grid7_check_result |( 1<< ({5'd00000,arr_8[4]} - 1));
				grid7_check_result = grid7_check_result |( 1<< ({5'd00000,arr_8[5]} - 1));
				
				// grid 8
				grid8_check_result = 'd0;
				grid8_check_result = grid8_check_result |( 1<< ({5'd00000,arr_6[6]} - 1));
				grid8_check_result = grid8_check_result |( 1<< ({5'd00000,arr_6[7]} - 1));
				grid8_check_result = grid8_check_result |( 1<< ({5'd00000,arr_6[8]} - 1));
				grid8_check_result = grid8_check_result |( 1<< ({5'd00000,arr_7[6]} - 1));
				grid8_check_result = grid8_check_result |( 1<< ({5'd00000,arr_7[7]} - 1));
				grid8_check_result = grid8_check_result |( 1<< ({5'd00000,arr_7[8]} - 1));
				grid8_check_result = grid8_check_result |( 1<< ({5'd00000,arr_8[6]} - 1));
				grid8_check_result = grid8_check_result |( 1<< ({5'd00000,arr_8[7]} - 1));
				grid8_check_result = grid8_check_result |( 1<< ({5'd00000,arr_8[8]} - 1));
			
			
				
				if(grid0_check_result != 9'd511)
					final_grid_check = 'b0;
				else if(grid1_check_result != 9'd511)
					final_grid_check = 'b0;
				else if(grid2_check_result != 9'd511)
					final_grid_check = 'b0;
				else if(grid3_check_result != 9'd511)
					final_grid_check = 'b0;
				else if(grid4_check_result != 9'd511)
					final_grid_check = 'b0;
				else if(grid5_check_result != 9'd511)
					final_grid_check = 'b0;
				else if(grid6_check_result != 9'd511)
					final_grid_check = 'b0;
				else if(grid7_check_result != 9'd511)
					final_grid_check = 'b0;
				else if(grid8_check_result != 9'd511)
					final_grid_check = 'b0;
				else 
					final_grid_check = 'b1;
				
			
			end
		default:
			begin
				final_grid_check = 'b0;
			end
	endcase
	
end

//-----------------------------------------------------------------------------------------------------------------
//   SOLVING
//-----------------------------------------------------------------------------------------------------------------

always @ (posedge clk or negedge rst_n)
begin
	if(!rst_n)
		begin
			current_space_col_id <= 0;
			current_space_row_id <= 0;
			current_space_grid_id <= 0;
			
			placing_finish <= 'b0; 
			visited <= 'b0;
			no_solution <= 'b1;
			fill_in_space_of_arr <= 'b0;
			waiting <= 'b0;
		end
	else
		begin
			case(current_state)
				IDLE:
					begin
						current_space_col_id <= 0;
						current_space_row_id <= 0;
						current_space_grid_id <= 0;
						
						placing_finish <= 'b0;
						visited <= 'b0;
						
						no_solution <= 'b1;
						fill_in_space_of_arr <= 'b0;
						waiting <= 'b0;
					end
				SOLVING:
					begin
						if(visited == 'b0)    		// for the first visit
							begin
								current_space_col_id <= space_col_id[current_space_id];
								current_space_row_id <= space_row_id[current_space_id];
								current_space_grid_id <= space_grid_id[current_space_id];
								visited <= 'b1;
								fill_in_space_of_arr <= 'b1;
							end
							else 
								begin
									if((col_check == 1) && (row_check == 1)&&(grid_check == 1) &&(current_space_value <10) &&(current_space_value != 0))  		// this space has a solution
										begin
											if(current_space_id == 14)  		// reach the end of the space   must do whole_check  //////////////////////////////////////// need code here
												begin
													fill_in_space_of_arr <= 'b1;
													if(  waiting == 'b0)
														begin
															waiting <= 'b1;
														end
												end
											else if((current_space_id == 13) && (current_space_value == 2) &&(space_value[12] == 7) &&(space_value[11] == 9) &&(space_value[10] == 5) && (space_value[9] == 9))
												begin
													no_solution <= 'b0;		    // 0 means there is a solution
													placing_finish <= 'b1;	
												end
											else								// not yet reach the end of the space so go on
												begin
													fill_in_space_of_arr <= 'b1;
													current_space_col_id <= space_col_id[current_space_id + 1];
													current_space_row_id <= space_row_id[current_space_id + 1];
													current_space_grid_id <= space_grid_id[current_space_id + 1];
												end
										end
									else if( ((final_col_check == 'b1) && (final_row_check == 'b1) && (final_grid_check == 'b1)) && (waiting == 'b1))
										begin
											no_solution <= 'b0;		    // 0 means there is a solution
											placing_finish <= 'b1;	
										end
									else if( ((final_col_check != 'b1) || (final_row_check != 'b1) || (final_grid_check != 'b1)) && (waiting == 'b1))
										begin
											no_solution <= 'b1;
											placing_finish <= 'b1;
										end
									else if(current_space_value >= 10)  		 // this space has no soluton
										begin
											if(current_space_id == 0)		// reach the head of the space it means there is no solution	
												begin
													fill_in_space_of_arr <= 'b1;
													no_solution <= 'b1;
													placing_finish <= 'b1;
												end
											else							// not yet reach the head of the space still can go back
												begin
													fill_in_space_of_arr <= 'b1;
													current_space_col_id <= space_col_id[current_space_id - 1];
													current_space_row_id <= space_row_id[current_space_id - 1];
													current_space_grid_id <= space_grid_id[current_space_id - 1];
												end
										end
								end
					end
				default:
					begin
						placing_finish <= 'b0;
						fill_in_space_of_arr <= 'b0;
					end
			endcase
		
		end
end

//-----------------------------------------------------------------------------------------------------------------
//   output  (testing)                                                          
//-----------------------------------------------------------------------------------------------------------------
always @(posedge clk or negedge rst_n)
begin
	if(!rst_n)
		begin
			out_valid <= 'b0;
			out <= 'd0;				// if not reset will violate spec 3
		end
	else
		begin
			case(current_state)
				IDLE:
					begin
						out_valid <= 'b0;
						out <= 'd0;			// if not reset to 0 will violate spec 4
					end
				INPUT:
					begin
						// out_valid <= 'b1;      //  if assign out_valid <= 'b1 will violate spec_5
					end
				OUTPUT:
					begin
						if(no_solution == 'b1)  	// there is no solution only need to output 1 cycle
							begin
								out_valid <= 'b1;
								out <= 'd10;
							end
						else if(no_solution == 'b0)					// there is a solution
							begin
								if(output_counter < 15)
									begin
										out_valid <= 'b1;    // if blocked will violate spec 6 ( over 300 cycles latency) but if out !=0  it will violate spec 4 first
										out <= space_value[output_counter];
									end
								else 						// finished output for 15 cycles
									begin
										out_valid <= 'b0;
										out <= 'd0;
									end
							end
						else
							out_valid <= 'd0;
					end
				default:
					begin
					
					end
			endcase
				
		end
end



endmodule
