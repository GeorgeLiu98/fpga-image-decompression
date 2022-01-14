

`timescale 1ns/100ps
`ifndef DISABLE_DEFAULT_NET
`default_nettype none
`endif

`include "define_state.h"

module Milestone1(
			/////// board clocks                      ////////////
		input logic CLOCK_50,                   // 50 MHz clock
		input  logic		Resetn,						//reset
		
		//M1 start and finish signals 
		input logic start,
		output logic finish,
		
		//access to SRAM
		input logic [15:0] SRAM_read_data,
		output logic [17:0] SRAM_address,
		output logic [15:0] SRAM_write_data,
		output logic SRAM_we_n
);

//state register
m1_state_type state;

//reg to store U and V values
logic [7:0] sram_u_data [5:0];
logic [7:0] u0_buf;
logic [7:0] sram_v_data [5:0];

logic [15:0] u_buf;
logic [15:0] v_buf;

//reg to store Y even and Y odd values
logic [32:0] y_even;
logic [32:0] y_odd;

////u'even u'odd v'even v'odd
logic [31:0] u_prime_odd;
logic [31:0] u_prime_even;
logic [31:0] v_prime_odd;
logic [31:0] v_prime_even;

////reg for summuation process
logic [31:0] sum_u_prime;
logic [31:0] sum_v_prime;

//buffer for Y*76824
logic [31:0] y_multi_buf_even; 
logic [31:0] y_multi_buf_odd; 

//reg for summation process with colour conversion 
logic [31:0] multi_sum_even;
logic [31:0] multi_sum_odd;

//counter for address
logic [17:0] y_addr;
logic [17:0] u_addr;
logic [17:0] v_addr;
logic [17:0] RGB_addr;

//address counters for state transition
logic [17:0] uv_stop_addr;
logic [17:0] y_addr_finish_row;
logic [17:0] y_addr_into_common_out;

//reg for RGB values
logic [7:0] R_even;
logic [7:0] G_even;
logic [7:0] B_even;
logic [7:0] R_odd;
logic [7:0] G_odd;
logic [7:0] B_odd;
logic [7:0] R_odd_buf;

//comb logic signals for multiply coefficient and 4 multipliers
logic [31:0] op1,op2,op3,op4,op5,op6,op7,op8;
logic [31:0] m1,m2,m3,m4;

//comb logical signals for 8-bit signal after clipping is done
logic [7:0] R_even_data;
logic [7:0] G_even_data;
logic [7:0] B_even_data;
logic [7:0] R_odd_data;
logic [7:0] G_odd_data;
logic [7:0] B_odd_data;

//four multipliers
assign m1=op1*op2;
assign m2=op3*op4;
assign m3=op5*op6;
assign m4=op7*op8;

//comb signals for clipping, transfrom 32 bits to 8 bits, pass signals down for buffering
assign R_even_data=(multi_sum_even[31]==1'b1)?8'd0:((|multi_sum_even[30:24])?8'd255:multi_sum_even[23:16]);
assign G_even_data=(multi_sum_even[31]==1'b1)?8'd0:((|multi_sum_even[30:24])?8'd255:multi_sum_even[23:16]);
assign B_even_data=(multi_sum_even[31]==1'b1)?8'd0:((|multi_sum_even[30:24])?8'd255:multi_sum_even[23:16]);
assign R_odd_data=(multi_sum_odd[31]==1'b1)?8'd0:((|multi_sum_odd[30:24])?8'd255:multi_sum_odd[23:16]);
assign G_odd_data=(multi_sum_odd[31]==1'b1)?8'd0:((|multi_sum_odd[30:24])?8'd255:multi_sum_odd[23:16]);
assign B_odd_data=(multi_sum_odd[31]==1'b1)?8'd0:((|multi_sum_odd[30:24])?8'd255:multi_sum_odd[23:16]);

always_ff @ (posedge CLOCK_50 or negedge Resetn) begin
	if (~Resetn) begin
				
		finish<=1'b0;
		SRAM_we_n <= 1'b1; //read initially 
		SRAM_write_data <= 16'd0;
		SRAM_address <= 18'd0;
		
		sram_u_data[0]<=8'd0;
		sram_u_data[1]<=8'd0;
		sram_u_data[2]<=8'd0;
		sram_u_data[3]<=8'd0;
		sram_u_data[4]<=8'd0;
		sram_u_data[5]<=8'd0;
		u0_buf<=8'd0;
		
		sram_v_data[0]<=8'd0;
		sram_v_data[1]<=8'd0;
		sram_v_data[2]<=8'd0;
		sram_v_data[3]<=8'd0;
		sram_v_data[4]<=8'd0;
		sram_v_data[5]<=8'd0;
		
		u_buf<=16'd0;
		v_buf<=16'd0;
		y_even<=32'd0;
		y_odd<=32'd0;
		
		//u'even u'odd v'even v'odd
		u_prime_odd<=32'd0;
		u_prime_even<=32'd0;
		v_prime_odd<=32'd0;
		v_prime_even<=32'd0;
		
		//reg for summuation process
		sum_u_prime<=32'd0;
		sum_v_prime<=32'd0;
		
		//buffer for Y*76824
		y_multi_buf_even<=32'd0;
		y_multi_buf_odd<=32'd0;
		
		//reg for summation process with colour conversion 
		multi_sum_even<=32'd0;
		multi_sum_odd<=32'd0;
		
		//address reset
		y_addr<=18'd0;
		u_addr<=18'd38400;
		v_addr<=18'd57600;
		RGB_addr<=18'd146944;
		uv_stop_addr<=18'd79; //first U/V address to go from common to lead out common
		
		y_addr_finish_row<=18'd159; //first Y address to finish a row of pixels
		y_addr_into_common_out<=18'd156; //first Y address to go from common to lead out common
		
		//RGB reg reset
		R_even<=8'd0;
		G_even<=8'd0;
		B_even<=8'd0;
		R_odd<=8'd0;
		G_odd<=8'd0;
		B_odd<=8'd0;
		R_odd_buf<=8'd0;
		
		state<=S_m1_IDLE;
		
	end 
	else begin
	
	y_even[31:8] <= 24'd0;
	
	case (state)

		S_m1_IDLE: begin
		
			if (start==1'b1)begin
				SRAM_address<=u_addr;
				u_addr<=u_addr+18'd1;

				state<=S_lead_in_1;
			end

		end

		S_lead_in_1: begin
			SRAM_address<=v_addr;
			v_addr<=v_addr+18'd1;
			state<=S_lead_in_2;
		end
		
		S_lead_in_2: begin
			state<=S_lead_in_3;
		end
		
		S_lead_in_3: begin
			u_buf<=SRAM_read_data;
			
			//u shift reg
			sram_u_data[0]<= sram_u_data[1];
			sram_u_data[1]<= sram_u_data[2];
			sram_u_data[2]<= sram_u_data[3];
			sram_u_data[3]<= sram_u_data[4];
			sram_u_data[4]<= sram_u_data[5];
			sram_u_data[5]<= SRAM_read_data[15:8];
			
			state<=S_lead_in_4;
		end
		
		S_lead_in_4: begin
			v_buf<=SRAM_read_data;
			
			SRAM_address<=u_addr;
			u_addr<=u_addr+18'd1;
			
			//u shift reg
			sram_u_data[0]<= sram_u_data[1];
			sram_u_data[1]<= sram_u_data[2];
			sram_u_data[2]<= sram_u_data[3];
			sram_u_data[3]<= sram_u_data[4];
			sram_u_data[4]<= sram_u_data[5];
			sram_u_data[5]<= u_buf[15:8];
			
			//v shift reg
			sram_v_data[0]<= sram_v_data[1];
			sram_v_data[1]<= sram_v_data[2];
			sram_v_data[2]<= sram_v_data[3];
			sram_v_data[3]<= sram_v_data[4];
			sram_v_data[4]<= sram_v_data[5];
			sram_v_data[5]<= SRAM_read_data[15:8];
			
			state<=S_lead_in_5;
		
		end
		
		S_lead_in_5: begin
			SRAM_address<=v_addr;
			v_addr<=v_addr+18'd1;
		
			//u shift reg
			sram_u_data[0]<= sram_u_data[1];
			sram_u_data[1]<= sram_u_data[2];
			sram_u_data[2]<= sram_u_data[3];
			sram_u_data[3]<= sram_u_data[4];
			sram_u_data[4]<= sram_u_data[5];
			sram_u_data[5]<= u_buf[15:8];
		
			//v shift reg
			sram_v_data[0]<= sram_v_data[1];
			sram_v_data[1]<= sram_v_data[2];
			sram_v_data[2]<= sram_v_data[3];
			sram_v_data[3]<= sram_v_data[4];
			sram_v_data[4]<= sram_v_data[5];
			sram_v_data[5]<= v_buf[15:8];
			
			state<=S_lead_in_6;
		
		end
		
		S_lead_in_6: begin
			//u shift reg
			sram_u_data[0]<= sram_u_data[1];
			sram_u_data[1]<= sram_u_data[2];
			sram_u_data[2]<= sram_u_data[3];
			sram_u_data[3]<= sram_u_data[4];
			sram_u_data[4]<= sram_u_data[5];
			sram_u_data[5]<= u_buf[7:0];
		
			//v shift reg
			sram_v_data[0]<= sram_v_data[1];
			sram_v_data[1]<= sram_v_data[2];
			sram_v_data[2]<= sram_v_data[3];
			sram_v_data[3]<= sram_v_data[4];
			sram_v_data[4]<= sram_v_data[5];
			sram_v_data[5]<= v_buf[15:8];
			
			state<=S_lead_in_7;
		end
		
		S_lead_in_7: begin
			u_buf<=SRAM_read_data;
		
			//u shift reg
			sram_u_data[0]<= sram_u_data[1];
			sram_u_data[1]<= sram_u_data[2];
			sram_u_data[2]<= sram_u_data[3];
			sram_u_data[3]<= sram_u_data[4];
			sram_u_data[4]<= sram_u_data[5];
			sram_u_data[5]<= SRAM_read_data[15:8];
		
			//v shift reg 
			sram_v_data[0]<= sram_v_data[1];
			sram_v_data[1]<= sram_v_data[2];
			sram_v_data[2]<= sram_v_data[3];
			sram_v_data[3]<= sram_v_data[4];
			sram_v_data[4]<= sram_v_data[5];
			sram_v_data[5]<= v_buf[7:0];
			
			state<=S_lead_in_8;
			end
			
		S_lead_in_8: begin
			v_buf<=SRAM_read_data;
		
			//u shift reg
			sram_u_data[0]<= sram_u_data[1];
			sram_u_data[1]<= sram_u_data[2];
			sram_u_data[2]<= sram_u_data[3];
			sram_u_data[3]<= sram_u_data[4];
			sram_u_data[4]<= sram_u_data[5];
			sram_u_data[5]<= u_buf[7:0];
		
			//v shift reg
			sram_v_data[0]<= sram_v_data[1];
			sram_v_data[1]<= sram_v_data[2];
			sram_v_data[2]<= sram_v_data[3];
			sram_v_data[3]<= sram_v_data[4];
			sram_v_data[4]<= sram_v_data[5];
			sram_v_data[5]<= SRAM_read_data[15:8];
			
			state<=S_lead_in_9;
		end
		
		S_lead_in_9: begin
			//buffer U reg[0]
			u0_buf<=sram_u_data[0];
			
			//v shift reg
			sram_v_data[0]<= sram_v_data[1];
			sram_v_data[1]<= sram_v_data[2];
			sram_v_data[2]<= sram_v_data[3];
			sram_v_data[3]<= sram_v_data[4];
			sram_v_data[4]<= sram_v_data[5];
			sram_v_data[5]<= v_buf[7:0];
			
			state<=S_lead_in_10;
		end
		
		S_lead_in_10: begin
			
			//summing u and v to obtain u'and v'
			sum_u_prime<=m1;
			sum_v_prime<=m2;
			
			state<=S_lead_in_11;
		end
		
		S_lead_in_11:begin
			
			SRAM_address<=u_addr;
			
			//summing u and v to obtain u'and v'
			sum_u_prime<=sum_u_prime-m1;
			sum_v_prime<=sum_v_prime-m2;
			
			state<=S_lead_in_12;
		end
		
		S_lead_in_12:begin
			SRAM_address<=v_addr;
			
			//summing u and v to obtain u'and v'
			sum_u_prime<=sum_u_prime+m1;
			sum_v_prime<=sum_v_prime+m2;
			state<=S_lead_in_13;
		end
		
		S_lead_in_13:begin
			SRAM_address<=y_addr;
			y_addr<=y_addr+18'd1;
			
			//summing u and v to obtain u'and v'
			sum_u_prime<=sum_u_prime+m1;
			sum_v_prime<=sum_v_prime+m2;
			
			state<=S_lead_in_14;
		end
		
		S_lead_in_14:begin
			
			//summing u and v to obtain u'and v'
			sum_u_prime<=sum_u_prime-m1;
			sum_v_prime<=sum_v_prime-m2;
			
			//u shift reg
			sram_u_data[0]<= sram_u_data[1];
			sram_u_data[1]<= sram_u_data[2];
			sram_u_data[2]<= sram_u_data[3];
			sram_u_data[3]<= sram_u_data[4];
			sram_u_data[4]<= sram_u_data[5];
			sram_u_data[5]<= SRAM_read_data[15:8];
			
			state<=S_lead_in_15;
		end
		
		S_lead_in_15:begin
			//buffer U reg[0]
			u0_buf<=sram_u_data[0];
			
			//summing u and v to obtain u'and v'
			sum_u_prime<=sum_u_prime+m1+32'd128;
			sum_v_prime<=sum_v_prime+m2+32'd128;
			
			//v shift reg
			sram_v_data[0]<= sram_v_data[1];
			sram_v_data[1]<= sram_v_data[2];
			sram_v_data[2]<= sram_v_data[3];
			sram_v_data[3]<= sram_v_data[4];
			sram_v_data[4]<= sram_v_data[5];
			sram_v_data[5]<= SRAM_read_data[15:8];
			
			state<=S_lead_in_16;
		end
		
		S_lead_in_16:begin
			//buffer for Y odd and Y even
			y_even[7:0]<= SRAM_read_data[15:8];
			y_odd[7:0]<= SRAM_read_data[7:0];
			
			//buffer for U'odd and U'even
			u_prime_odd<={{8{sum_u_prime[31]}},sum_u_prime[31:8]}; //perform division
			u_prime_even<={24'd0,sram_u_data[1]};
			
			//buffer for V'odd and V'even
			v_prime_odd<={{8{sum_v_prime[31]}},sum_v_prime[31:8]}; //perform division
			v_prime_even<={24'd0,sram_v_data[1]};
			
			//summing u and v to obtain u'and v'
			sum_u_prime<=m1;
			sum_v_prime<=m2;
		
			state<=S_lead_in_17;
		end
		
		S_lead_in_17:begin
			SRAM_address<=u_addr;
			u_addr<=u_addr+18'd1;
			
			//summing u and v to obtain u'and v'
			sum_u_prime<=sum_u_prime-m1;
			sum_v_prime<=sum_v_prime-m2;
			
			//buffer Y odd and Y even values
			y_multi_buf_even<=m3;
			y_multi_buf_odd<=m4;
			
			//summing values for colour conversion 
			multi_sum_even<=m3;
			multi_sum_odd<=m4;
			
			state<=S_lead_in_18;
		end
		
		S_lead_in_18:begin
			SRAM_address<=v_addr;
			v_addr<=v_addr+18'd1;
			
			//summing u and v to obtain u'and v'
			sum_u_prime<=sum_u_prime+m1;
			sum_v_prime<=sum_v_prime+m2;
			
			//summing values for colour conversion 
			multi_sum_even<=multi_sum_even+m3;
			multi_sum_odd<=multi_sum_odd+m4;
			
			state<=S_lead_in_19;
		end
		
		S_lead_in_19:begin
			SRAM_address<=y_addr;
			y_addr<=y_addr+18'd1;
			
			//summing u and v to obtain u'and v'
			sum_u_prime<=sum_u_prime+m1;
			sum_v_prime<=sum_v_prime+m2;
			
			//summing values for colour conversion 
			multi_sum_even<=y_multi_buf_even-m3;
			multi_sum_odd<=y_multi_buf_odd-m4;
			
			//pass values into R_even and R_odd
			R_even<=R_even_data;
			R_odd<=R_odd_data;
			
			state<=S_lead_in_20;
		end
		
		S_lead_in_20:begin
		
			//u shift reg
			sram_u_data[0]<= sram_u_data[1];
			sram_u_data[1]<= sram_u_data[2];
			sram_u_data[2]<= sram_u_data[3];
			sram_u_data[3]<= sram_u_data[4];
			sram_u_data[4]<= sram_u_data[5];
			sram_u_data[5]<= SRAM_read_data[7:0];
			
			//summing u and v to obtain u'and v'
			sum_u_prime<=sum_u_prime-m1;
			sum_v_prime<=sum_v_prime-m2;
			
			//summing values for colour conversion 
			multi_sum_even<=multi_sum_even-m3;
			multi_sum_odd<=multi_sum_odd-m4;
			
			//buff R odd value
			R_odd_buf<=R_odd;
			
			state<=S_lead_in_21;
		end
		
		S_lead_in_21:begin
		
			//v shift reg
			sram_v_data[0]<= sram_v_data[1];
			sram_v_data[1]<= sram_v_data[2];
			sram_v_data[2]<= sram_v_data[3];
			sram_v_data[3]<= sram_v_data[4];
			sram_v_data[4]<= sram_v_data[5];
			sram_v_data[5]<= SRAM_read_data[7:0];
			
			//summing u and v to obtain u'and v'
			sum_u_prime<=sum_u_prime+m1+32'd128;
			sum_v_prime<=sum_v_prime+m2+32'd128;
			
			//buffer U[0] reg value
			u0_buf<=sram_u_data[0];
			
			//summing values for colour conversion 
			multi_sum_even<=y_multi_buf_even+m3;
			multi_sum_odd<=y_multi_buf_odd+m4;
			
			//pass values into G_even and G_odd
			G_even<=G_even_data;
			G_odd<=G_odd_data;
			
			state<=S_common_0;
		end
		
		//////////////////////////////////////////////////////////////////////////////////////
		//common case starts
		S_common_0:begin
			//buffer for Y odd and Y even
			y_even[7:0]<= SRAM_read_data[15:8];
			y_odd[7:0]<= SRAM_read_data[7:0];
			
			//buffer for U'odd and U'even
			u_prime_odd<={{8{sum_u_prime[31]}},sum_u_prime[31:8]}; //perform division
			u_prime_even<={24'd0,sram_u_data[1]};
			
			//buffer for V'odd and V'even
			v_prime_odd<={{8{sum_v_prime[31]}},sum_v_prime[31:8]}; //perform division
			v_prime_even<={24'd0,sram_v_data[1]};
			
			//summing u and v to obtain u'and v'
			sum_u_prime<=m1;
			sum_v_prime<=m2;
			
			//pass values into B_even and B_odd
			B_even<=B_even_data;
			B_odd<=B_odd_data;
			
			//write data
			SRAM_we_n <= 1'b0;
			
			//provide write address
			SRAM_address<=RGB_addr;
			RGB_addr<=RGB_addr+18'd1;
			
			//write R_even,G_even into memory
			SRAM_write_data <= {{R_even}, {G_even}};
			
			state<=S_common_1;
		end
		
		S_common_1:begin
			SRAM_address<=u_addr;
			
			//read data
			SRAM_we_n <= 1'b1;
			
			//summing u and v to obtain u'and v'
			sum_u_prime<=sum_u_prime-m1;
			sum_v_prime<=sum_v_prime-m2;
			
			//buffer Y odd and Y even values
			y_multi_buf_even<=m3;
			y_multi_buf_odd<=m4;
			
			//summing values for colour conversion 
			multi_sum_even<=m3;
			multi_sum_odd<=m4;
			
			state<=S_common_2;
		end
		
		S_common_2:begin
			SRAM_address<=v_addr;
			
			//summing u and v to obtain u'and v'
			sum_u_prime<=sum_u_prime+m1;
			sum_v_prime<=sum_v_prime+m2;
			
			//summing values for colour conversion 
			multi_sum_even<=multi_sum_even+m3;
			multi_sum_odd<=multi_sum_odd+m4;
			
			state<=S_common_3;
		end
		
		S_common_3:begin
			SRAM_address<=y_addr;
			y_addr<=y_addr+18'd1;
			
			//summing u and v to obtain u'and v'
			sum_u_prime<=sum_u_prime+m1;
			sum_v_prime<=sum_v_prime+m2;
			
			//summing values for colour conversion 
			multi_sum_even<=y_multi_buf_even-m3;
			multi_sum_odd<=y_multi_buf_odd-m4;
			
			//pass values into R_even and R_odd
			R_even<=R_even_data;
			R_odd<=R_odd_data;
			
			state<=S_common_4;
		end
		
		S_common_4:begin
		
			//u shift reg
			sram_u_data[0]<= sram_u_data[1];
			sram_u_data[1]<= sram_u_data[2];
			sram_u_data[2]<= sram_u_data[3];
			sram_u_data[3]<= sram_u_data[4];
			sram_u_data[4]<= sram_u_data[5];
			sram_u_data[5]<= SRAM_read_data[15:8];
			
			//summing u and v to obtain u'and v'
			sum_u_prime<=sum_u_prime-m1;
			sum_v_prime<=sum_v_prime-m2;
			
			//summing values for colour conversion 
			multi_sum_even<=multi_sum_even-m3;
			multi_sum_odd<=multi_sum_odd-m4;
			
			//buff R odd value
			R_odd_buf<=R_odd;
			
			//write data
			SRAM_we_n <= 1'b0;
			
			//provide write address
			SRAM_address<=RGB_addr;
			RGB_addr<=RGB_addr+18'd1;
			
			//write R_even,G_even into memory
			SRAM_write_data <= {{B_even}, {R_odd_buf}};
			
			state<=S_common_5;
		end
		
		S_common_5:begin
		
			//v shift reg
			sram_v_data[0]<= sram_v_data[1];
			sram_v_data[1]<= sram_v_data[2];
			sram_v_data[2]<= sram_v_data[3];
			sram_v_data[3]<= sram_v_data[4];
			sram_v_data[4]<= sram_v_data[5];
			sram_v_data[5]<= SRAM_read_data[15:8];
			
			//summing u and v to obtain u'and v'
			sum_u_prime<=sum_u_prime+m1+32'd128;
			sum_v_prime<=sum_v_prime+m2+32'd128;
			
			//buffer U[0] reg value
			u0_buf<=sram_u_data[0];
			
			//summing values for colour conversion 
			multi_sum_even<=y_multi_buf_even+m3;
			multi_sum_odd<=y_multi_buf_odd+m4;
			
			//pass values into G_even and G_odd
			G_even<=G_even_data;
			G_odd<=G_odd_data;
			
			//provide write address
			SRAM_address<=RGB_addr;
			RGB_addr<=RGB_addr+18'd1;
			
			//provide write address
			SRAM_address<=RGB_addr;
			RGB_addr<=RGB_addr+18'd1;
			
			//write R_even,G_even into memory
			SRAM_write_data <= {{G_odd}, {B_odd}};
			
			state<=S_common_6;
		end
		S_common_6:begin
			//buffer for Y odd and Y even
			y_even[7:0]<= SRAM_read_data[15:8];
			y_odd[7:0]<= SRAM_read_data[7:0];
			
			//buffer for U'odd and U'even
			u_prime_odd<={{8{sum_u_prime[31]}},sum_u_prime[31:8]}; //perform division
			u_prime_even<={24'd0,sram_u_data[1]};
			
			//buffer for V'odd and V'even
			v_prime_odd<={{8{sum_v_prime[31]}},sum_v_prime[31:8]}; //perform division
			v_prime_even<={24'd0,sram_v_data[1]};
			
			//summing u and v to obtain u'and v'
			sum_u_prime<=m1;
			sum_v_prime<=m2;		
			
			//pass values into B_even and B_odd
			B_even<=B_even_data;
			B_odd<=B_odd_data;
			
			//provide write address
			SRAM_address<=RGB_addr;
			RGB_addr<=RGB_addr+18'd1;
			
			//write R_even,G_even into memory
			SRAM_write_data <= {{R_even}, {G_even}};
			
			state<=S_common_7;
		end
		
		S_common_7:begin
			if (u_addr<uv_stop_addr+18'd38400)begin //UV_stop_addr=79, stop increasing addr
				SRAM_address<=u_addr;
				u_addr<=u_addr+18'd1;
			end
			else 
				SRAM_address<=u_addr;
			
			//read data
			SRAM_we_n <= 1'b1;
			
			//summing u and v to obtain u'and v'
			sum_u_prime<=sum_u_prime-m1;
			sum_v_prime<=sum_v_prime-m2;
			
			//buffer Y odd and Y even values
			y_multi_buf_even<=m3;
			y_multi_buf_odd<=m4;
			
			//summing values for colour conversion 
			multi_sum_even<=m3;
			multi_sum_odd<=m4;
			
			state<=S_common_8;
		end
		
		S_common_8:begin
			if (v_addr<uv_stop_addr+18'd57600)begin //UV_stop_addr=79, stop increasing addr
				SRAM_address<=v_addr;
				v_addr<=v_addr+18'd1;
			end
			else begin
				SRAM_address<=v_addr;
				uv_stop_addr<=uv_stop_addr+18'd80;
			end
			
			//summing u and v to obtain u'and v'
			sum_u_prime<=sum_u_prime+m1;
			sum_v_prime<=sum_v_prime+m2;
			
			//summing values for colour conversion 
			multi_sum_even<=multi_sum_even+m3;
			multi_sum_odd<=multi_sum_odd+m4;
			
			state<=S_common_9;
		end
		
		S_common_9:begin
			SRAM_address<=y_addr;
			y_addr<=y_addr+18'd1;
			
			//summing u and v to obtain u'and v'
			sum_u_prime<=sum_u_prime+m1;
			sum_v_prime<=sum_v_prime+m2;
			
			//summing values for colour conversion 
			multi_sum_even<=y_multi_buf_even-m3;
			multi_sum_odd<=y_multi_buf_odd-m4;
			
			//pass values into R_even and R_odd
			R_even<=R_even_data;
			R_odd<=R_odd_data;
			
			state<=S_common_10;
		end
		
		S_common_10:begin
		
			//u shift reg
			sram_u_data[0]<= sram_u_data[1];
			sram_u_data[1]<= sram_u_data[2];
			sram_u_data[2]<= sram_u_data[3];
			sram_u_data[3]<= sram_u_data[4];
			sram_u_data[4]<= sram_u_data[5];
			sram_u_data[5]<= SRAM_read_data[7:0];
			
			//summing u and v to obtain u'and v'
			sum_u_prime<=sum_u_prime-m1;
			sum_v_prime<=sum_v_prime-m2;
			
			//summing values for colour conversion 
			multi_sum_even<=multi_sum_even-m3;
			multi_sum_odd<=multi_sum_odd-m4;
			
			//buff R odd value
			R_odd_buf<=R_odd;
			
			//write data
			SRAM_we_n <= 1'b0;
			
			//provide write address
			SRAM_address<=RGB_addr;
			RGB_addr<=RGB_addr+18'd1;
			
			//write R_even,G_even into memory
			SRAM_write_data <= {{B_even}, {R_odd_buf}};
			
			state<=S_common_11;
		end
		
		S_common_11:begin
			
			//v shift reg
			sram_v_data[0]<= sram_v_data[1];
			sram_v_data[1]<= sram_v_data[2];
			sram_v_data[2]<= sram_v_data[3];
			sram_v_data[3]<= sram_v_data[4];
			sram_v_data[4]<= sram_v_data[5];
			sram_v_data[5]<= SRAM_read_data[7:0];
			
			//summing u and v to obtain u'and v'
			sum_u_prime<=sum_u_prime+m1+32'd128;
			sum_v_prime<=sum_v_prime+m2+32'd128;
			
			//buffer U[0] reg value
			u0_buf<=sram_u_data[0];
			
			//summing values for colour conversion 
			multi_sum_even<=y_multi_buf_even+m3;
			multi_sum_odd<=y_multi_buf_odd+m4;
			
			//pass values into G_even and G_odd
			G_even<=G_even_data;
			G_odd<=G_odd_data;
				
			//provide write address
			SRAM_address<=RGB_addr;
			RGB_addr<=RGB_addr+18'd1;
			
			//write R_even,G_even into memory
			SRAM_write_data <= {{G_odd}, {B_odd}};
			
			
			if (y_addr<y_addr_into_common_out)  //y_addr_into_common_out=156
				//go back to first common case 
				state<=S_common_0;
			else begin
			
				//enter lead out common case
				y_addr_into_common_out<=y_addr_into_common_out+18'd160;
				state<=S_lead_out_common_0;
			end
		end
		
		//////////////////////////////////////////////////////////////////////////////////////////////
		//lead out common case starts
		S_lead_out_common_0:begin
		
			//buffer for Y odd and Y even
			y_even[7:0]<= SRAM_read_data[15:8];
			y_odd[7:0]<= SRAM_read_data[7:0];
			
			//buffer for U'odd and U'even
			u_prime_odd<={{8{sum_u_prime[31]}},sum_u_prime[31:8]}; //perform division
			u_prime_even<={24'd0,sram_u_data[1]};
			
			//buffer for V'odd and V'even
			v_prime_odd<={{8{sum_v_prime[31]}},sum_v_prime[31:8]}; //perform division
			v_prime_even<={24'd0,sram_v_data[1]};
			
			//summing u and v to obtain u'and v'
			sum_u_prime<=m1;
			sum_v_prime<=m2;

			//pass values into B_even and B_odd
			B_even<=B_even_data;
			B_odd<=B_odd_data;
			
			//provide write address
			SRAM_address<=RGB_addr;
			RGB_addr<=RGB_addr+18'd1;
			
			//write R_even,G_even into memory
			SRAM_write_data <= {{R_even}, {G_even}};
			
			state<=S_lead_out_common_1;
		end
		
		S_lead_out_common_1:begin
			
			//read only, u address stays the same 
			SRAM_address<=u_addr;
				
			//read data
			SRAM_we_n <= 1'b1;
			
			//summing u and v to obtain u'and v'
			sum_u_prime<=sum_u_prime-m1;
			sum_v_prime<=sum_v_prime-m2;
			
			//buffer Y odd and Y even values
			y_multi_buf_even<=m3;
			y_multi_buf_odd<=m4;
			
			//summing values for colour conversion 
			multi_sum_even<=m3;
			multi_sum_odd<=m4;
			
			state<=S_lead_out_common_2;
		end
		
		S_lead_out_common_2:begin
			
			//read only, v address stays the same 
			SRAM_address<=v_addr;
			
			//summing u and v to obtain u'and v'
			sum_u_prime<=sum_u_prime+m1;
			sum_v_prime<=sum_v_prime+m2;
			
			//summing values for colour conversion 
			multi_sum_even<=multi_sum_even+m3;
			multi_sum_odd<=multi_sum_odd+m4;
			
			state<=S_lead_out_common_3;
		end
		
		S_lead_out_common_3:begin

			SRAM_address<=y_addr;//Y[158]
			
			//summing u and v to obtain u'and v'
			sum_u_prime<=sum_u_prime+m1;
			sum_v_prime<=sum_v_prime+m2;
			
			//summing values for colour conversion 
			multi_sum_even<=y_multi_buf_even-m3;
			multi_sum_odd<=y_multi_buf_odd-m4;
			
			//pass values into R_even and R_odd
			R_even<=R_even_data;
			R_odd<=R_odd_data;
			
			state<=S_lead_out_common_4;
		end
		
		S_lead_out_common_4:begin
		
			//u shift reg
			sram_u_data[0]<= sram_u_data[1];
			sram_u_data[1]<= sram_u_data[2];
			sram_u_data[2]<= sram_u_data[3];
			sram_u_data[3]<= sram_u_data[4];
			sram_u_data[4]<= sram_u_data[5];
			sram_u_data[5]<= SRAM_read_data[7:0];
			
			//summing u and v to obtain u'and v'
			sum_u_prime<=sum_u_prime-m1;
			sum_v_prime<=sum_v_prime-m2;
			
			//summing values for colour conversion 
			multi_sum_even<=multi_sum_even-m3;
			multi_sum_odd<=multi_sum_odd-m4;
			
			//buff R odd value
			R_odd_buf<=R_odd;
			
			//write data
			SRAM_we_n <= 1'b0;
			
			//provide write address
			SRAM_address<=RGB_addr;
			RGB_addr<=RGB_addr+18'd1;
			
			//write R_even,G_even into memory
			SRAM_write_data <= {{B_even}, {R_odd_buf}};
			
			state<=S_lead_out_common_5;
		end
		
		S_lead_out_common_5:begin
		
			//v shift reg
			sram_v_data[0]<= sram_v_data[1];
			sram_v_data[1]<= sram_v_data[2];
			sram_v_data[2]<= sram_v_data[3];
			sram_v_data[3]<= sram_v_data[4];
			sram_v_data[4]<= sram_v_data[5];
			sram_v_data[5]<= SRAM_read_data[7:0];
			
			//summing u and v to obtain u'and v'
			sum_u_prime<=sum_u_prime+m1+32'd128;
			sum_v_prime<=sum_v_prime+m2+32'd128;
			
			//buffer U[0] reg value
			u0_buf<=sram_u_data[0];
			
			//summing values for colour conversion 
			multi_sum_even<=y_multi_buf_even+m3;
			multi_sum_odd<=y_multi_buf_odd+m4;
			
			//pass values into G_even and G_odd
			G_even<=G_even_data;
			G_odd<=G_odd_data;
			
			//provide write address
			SRAM_address<=RGB_addr;
			RGB_addr<=RGB_addr+18'd1;
			
			//write R_even,G_even into memory
			SRAM_write_data <= {{G_odd}, {B_odd}};
			
			if (y_addr<y_addr_finish_row) begin
				y_addr<=y_addr+18'd1; 
				state<=S_lead_out_common_0;
			end
			else begin    //y_addr_finish_row=159
				state<=S_lead_out_0;
				y_addr_finish_row<=y_addr_finish_row+18'd160;
			end
			
		end
		
		
		/////////////////////////////////////////////////////////////////////////////////////////////
		//lead out cases starts
		S_lead_out_0:begin
			//buffer for Y odd and Y even
			y_even[7:0]<= SRAM_read_data[15:8];
			y_odd[7:0]<= SRAM_read_data[7:0];
			
			//buffer for U'odd and U'even
			u_prime_odd<={{8{sum_u_prime[31]}},sum_u_prime[31:8]}; //perform division
			u_prime_even<={24'd0,sram_u_data[1]};
			
			//buffer for V'odd and V'even
			v_prime_odd<={{8{sum_v_prime[31]}},sum_v_prime[31:8]}; //perform division
			v_prime_even<={24'd0,sram_v_data[1]};
			
			//pass values into B_even and B_odd
			B_even<=B_even_data;
			B_odd<=B_odd_data;
		
			//provide write address
			SRAM_address<=RGB_addr;
			RGB_addr<=RGB_addr+18'd1;
			
			//write R_even,G_even into memory
			SRAM_write_data <= {{R_even}, {G_even}};
			
			state<=S_lead_out_1;
		end
		
		S_lead_out_1:begin
		
			//buffer Y odd and Y even values
			y_multi_buf_even<=m3;
			y_multi_buf_odd<=m4;
			
			//summing values for colour conversion 
			multi_sum_even<=m3;
			multi_sum_odd<=m4;
			
			//provide write address
			SRAM_address<=RGB_addr;
			RGB_addr<=RGB_addr+18'd1;
			
			//write R_even,G_even into memory
			SRAM_write_data <= {{B_even}, {R_odd_buf}};
			
			state<=S_lead_out_2;
		end
		
		S_lead_out_2:begin
			
			//summing values for colour conversion 
			multi_sum_even<=multi_sum_even+m3;
			multi_sum_odd<=multi_sum_odd+m4;
			
			//provide write address
			SRAM_address<=RGB_addr;
			RGB_addr<=RGB_addr+18'd1;
			
			//write R_even,G_even into memory
			SRAM_write_data <= {{G_odd}, {B_odd}};
			
			state<=S_lead_out_3;
		end
		
		S_lead_out_3:begin
			
			//read data
			SRAM_we_n <= 1'b1;
			
			//summing values for colour conversion 
			multi_sum_even<=y_multi_buf_even-m3;
			multi_sum_odd<=y_multi_buf_odd-m4;
			
			//pass values into R_even and R_odd
			R_even<=R_even_data;
			R_odd<=R_odd_data;
			
			state<=S_lead_out_4;
		end
		
		S_lead_out_4:begin
			
			//summing values for colour conversion 
			multi_sum_even<=multi_sum_even-m3;
			multi_sum_odd<=multi_sum_odd-m4;
			
			//buffer R odd value
			R_odd_buf<=R_odd;
			
			state<=S_lead_out_5;
		end
		
		S_lead_out_5:begin
			
			//summing values for colour conversion 
			multi_sum_even<=y_multi_buf_even+m3;
			multi_sum_odd<=y_multi_buf_odd+m4;
			
			//pass values into G_even and G_odd
			G_even<=G_even_data;
			G_odd<=G_odd_data;
			
			state<=S_lead_out_6;
		end
		
		S_lead_out_6:begin
			
			//pass values into B_even and B_odd
			B_even<=B_even_data;
			B_odd<=B_odd_data;
			
			//write data
			SRAM_we_n <= 1'b0;
			
			//provide write address
			SRAM_address<=RGB_addr;
			RGB_addr<=RGB_addr+18'd1;
			
			//write R_even,G_even into memory
			SRAM_write_data <= {{R_even}, {G_even}};
			
			state<=S_lead_out_7;
		end
		
		S_lead_out_7:begin
			
			//provide write address
			SRAM_address<=RGB_addr;
			RGB_addr<=RGB_addr+18'd1;
			
			//write R_even,G_even into memory
			SRAM_write_data <= {{B_even}, {R_odd_buf}};
			
			state<=S_lead_out_8;
		end
		
		S_lead_out_8:begin
			
			//write data
			SRAM_we_n <= 1'b0;
			
			//provide write address
			SRAM_address<=RGB_addr;
			RGB_addr<=RGB_addr+18'd1;
			
			//write R_even,G_even into memory
			SRAM_write_data <= {{G_odd}, {B_odd}};
			
			state<=S_lead_out_9;
		
		end
		
		S_lead_out_9:begin
			
			//read data
			SRAM_we_n <= 1'b1;
			
			if(y_addr < 18'd38399) begin
				//increase U,V address all by one, ready for next interation 
				u_addr<=u_addr+18'd1;
				v_addr<=v_addr+18'd1;
				y_addr<=y_addr+18'd1;
				state<=S_m1_IDLE;
			end
			else 
			//finish all pixles, 
			finish<=1'b1;
			
		end
		
		default: state <= S_m1_IDLE;		
		
	endcase


	end
end

//comb logic for multipliers
always_comb begin
	//initialization (default values)
	op1=32'd0;
	op2=32'd0;
	op3=32'd0;
	op4=32'd0;
	op5=32'd0;
	op6=32'd0;
	op7=32'd0;
	op8=32'd0;
	
	//multiplication for lead in cases
	if (state==S_lead_in_10)begin
		op1={24'd0,sram_u_data[5]};
		op2=32'd21;
		
		op3={24'd0,sram_v_data[5]};
		op4=32'd21;
		
	end
	else if (state==S_lead_in_11) begin
		op1={24'd0,sram_u_data[4]};
		op2=32'd52;
		
		op3={24'd0,sram_v_data[4]};
		op4=32'd52;
	end
	else if (state==S_lead_in_12) begin
		op1={24'd0,sram_u_data[3]};
		op2=32'd159;
		
		op3={24'd0,sram_v_data[3]};
		op4=32'd159;
	end
	else if (state==S_lead_in_13) begin
		op1={24'd0,sram_u_data[2]};
		op2=32'd159;
		
		op3={24'd0,sram_v_data[2]};
		op4=32'd159;
	end
	else if (state==S_lead_in_14) begin
		op1={24'd0,sram_u_data[1]};
		op2=32'd52;
		
		op3={24'd0,sram_v_data[1]};
		op4=32'd52;
	end
	else if (state==S_lead_in_15) begin
		op1={24'd0,u0_buf};
		op2=32'd21;
		
		op3={24'd0,sram_v_data[0]};
		op4=32'd21;
	end
	
	else if ((state==S_lead_in_16) | (state==S_common_0) | (state==S_common_6)
				| (state==S_lead_out_common_0))begin
		
		op1={24'd0,sram_u_data[5]};
		op2=32'd21;
		
		op3={24'd0,sram_v_data[5]};
		op4=32'd21;
		
	end
	else if ((state==S_lead_in_17) | (state==S_common_1) | (state==S_common_7)
				| (state==S_lead_out_common_1))begin

		op1={24'd0,sram_u_data[4]};
		op2=32'd52;
		
		op3={24'd0,sram_v_data[4]};
		op4=32'd52;
		
		op5=y_even-32'd16;
		op6=32'd76284;
		
		op7=y_odd-32'd16;
		op8=32'd76284;
		
	end
	
	else if ((state==S_lead_in_18) | (state==S_common_2) | (state==S_common_8)
				| (state==S_lead_out_common_2))begin
		
		op1={24'd0,sram_u_data[3]};
		op2=32'd159;
		
		op3={24'd0,sram_v_data[3]};
		op4=32'd159;
		
		op5=v_prime_even-32'd128;
		op6=32'd104595;
		
		op7=v_prime_odd-32'd128;
		op8=32'd104595;
		
	end
	
	else if ((state==S_lead_in_19) | (state==S_common_3) | (state==S_common_9)
				| (state==S_lead_out_common_3))begin
		
		op1={24'd0,sram_u_data[2]};
		op2=32'd159;
		
		op3={24'd0,sram_v_data[2]};
		op4=32'd159;
		
		op5=u_prime_even-32'd128;
		op6=32'd25624;
		
		op7=u_prime_odd-32'd128;
		op8=32'd25624;
		
	end
	else if ((state==S_lead_in_20) | (state==S_common_4) | (state==S_common_10)
				| (state==S_lead_out_common_4))begin
		op1={24'd0,sram_u_data[1]};
		op2=32'd52;
		
		op3={24'd0,sram_v_data[1]};
		op4=32'd52;
		
		op5=v_prime_even-32'd128;
		op6=32'd53281;
		
		op7=v_prime_odd-32'd128;
		op8=32'd53281;
		
	end
	else if ((state==S_lead_in_21) | (state==S_common_5) | (state==S_common_11)
				| (state==S_lead_out_common_5))begin
		
		op1={24'd0,u0_buf};
		op2=32'd21;
		
		op3={24'd0,sram_v_data[0]};
		op4=32'd21;
		
		op5=u_prime_even-32'd128;
		op6=32'd132251;
		
		op7=u_prime_odd-32'd128;
		op8=32'd132251;
		
	end
	
	//////////////////////////////////
	//multiply for lead out states 
	else if (state==S_lead_out_1)begin
		op5=y_even-32'd16;
		op6=32'd76284;
		
		op7=y_odd-32'd16;
		op8=32'd76284;
	end
	else if (state==S_lead_out_2)begin
		op5=v_prime_even-32'd128;
		op6=32'd104595;
		
		op7=v_prime_odd-32'd128;
		op8=32'd104595;
	end
	else if (state==S_lead_out_3)begin
		op5=u_prime_even-32'd128;
		op6=32'd25624;
		
		op7=u_prime_odd-32'd128;
		op8=32'd25624;
	end
	else if (state==S_lead_out_4)begin
		op5=v_prime_even-32'd128;
		op6=32'd53281;
		
		op7=v_prime_odd-32'd128;
		op8=32'd53281;
	end
	else if (state==S_lead_out_5)begin
		op5=u_prime_even-32'd128;
		op6=32'd132251;
		
		op7=u_prime_odd-32'd128;
		op8=32'd132251;
	end


end 

endmodule
