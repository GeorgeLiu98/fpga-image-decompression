

`timescale 1ns/100ps
`ifndef DISABLE_DEFAULT_NET
`default_nettype none
`endif

`include "define_state.h"

module Milestone2(
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
m2_state_type m2_state;


////////////////////////////////////////////////////////////////////////////////////////
//dual port RAM for T

//declear signals for T dual port ram
logic [6:0] address_T_a;
logic [6:0] address_T_b;
logic [31:0] write_data_T_a;
logic [31:0] write_data_T_b;
logic write_enable_T_a;
logic write_enable_T_b;
logic [31:0] read_data_T_a;
logic [31:0] read_data_T_b;

dual_port_RAM_T dual_port_RAM_inst0 (
	.address_a ( address_T_a ),
	.address_b ( address_T_b ),
	.clock ( CLOCK_50 ),
	.data_a ( write_data_T_a ),
	.data_b ( write_data_T_b ),
	.wren_a ( write_enable_T_a ),
	.wren_b ( write_enable_T_b ),
	.q_a ( read_data_T_a ),
	.q_b ( read_data_T_b )
);
////////////////////////////////////////////////////////////////////////////////////////
//declear signals for C dual port ram
logic [6:0] address_C_a;
logic [6:0] address_C_b;
logic [31:0] write_data_C_a;
logic [31:0] write_data_C_b;
logic write_enable_C_a;
logic write_enable_C_b;
logic [31:0] read_data_C_a;
logic [31:0] read_data_C_b;

dual_port_RAM_C dual_port_RAM_inst1 (
	.address_a ( address_C_a ),
	.address_b ( address_C_b ),
	.clock ( CLOCK_50 ),
	.data_a ( write_data_C_a ),
	.data_b ( write_data_C_b ),
	.wren_a ( write_enable_C_a ),
	.wren_b ( write_enable_C_b ),
	.q_a ( read_data_C_a ),
	.q_b ( read_data_C_b )
);


////////////////////////////////////////////////////////////////////////////////////////
//declear signals for S dual port ram
logic [6:0] address_S_a;
logic [6:0] address_S_b;
logic [31:0] write_data_S_a;
logic [31:0] write_data_S_b;
logic write_enable_S_a;
logic write_enable_S_b;
logic [31:0] read_data_S_a;
logic [31:0] read_data_S_b;
logic [17:0] SRAM_read_addr;
logic [17:0] SRAM_write_addr;

dual_port_RAM_S dual_port_RAM_inst2 (
	.address_a ( address_S_a ),
	.address_b ( address_S_b ),
	.clock ( CLOCK_50 ),
	.data_a ( write_data_S_a ),
	.data_b ( write_data_S_b ),
	.wren_a ( write_enable_S_a ),
	.wren_b ( write_enable_S_b ),
	.q_a ( read_data_S_a ),
	.q_b ( read_data_S_b )
);
/////////////////////////////////////////////////////////////////////////////////////////////
//four multipliers
logic [31:0] op1,op2,op3,op4,op5,op6,op7,op8;
logic [31:0] m1,m2,m3,m4;

assign m1=op1*op2;
assign m2=op3*op4;
assign m3=op5*op6;
assign m4=op7*op8;

//comb logic for multipliers
always_comb begin
	op1=32'd0;
	op2=32'd0;
	op3=32'd0;
	op4=32'd0;
	op5=32'd0;
	op6=32'd0;
	op7=32'd0;
	op8=32'd0;
	
	if (m2_state==S_m2_lead_in_CT || m2_state==S_m2_CT_WS) begin
		op1= {{16{read_data_S_a[31]}},read_data_S_a[31:16]};
		op2= {{16{read_data_C_a[31]}},read_data_C_a[31:16]};
		
		op3= {{16{read_data_S_a[31]}},read_data_S_a[31:16]};
		op4= {{16{read_data_C_a[15]}},read_data_C_a[15:0]};
		
		op5= {{16{read_data_S_a[15]}},read_data_S_a[15:0]};
		op6= {{16{read_data_C_b[31]}},read_data_C_b[31:16]};
		
		op7= {{16{read_data_S_a[15]}},read_data_S_a[15:0]};
		op8= {{16{read_data_C_b[15]}},read_data_C_b[15:0]};
		
	end
	
	else if (m2_state==S_m2_CS_FS || m2_state==S_m2_lead_out_CS ) begin
		op1= read_data_T_a;
		op2= {{16{read_data_C_a[31]}},read_data_C_a[31:16]};
		
		op3= read_data_T_a;
		op4= {{16{read_data_C_a[15]}},read_data_C_a[15:0]};
		
		op5= read_data_T_b;
		op6= {{16{read_data_C_b[31]}},read_data_C_b[31:16]};
		
		op7= read_data_T_b;
		op8= {{16{read_data_C_b[15]}},read_data_C_b[15:0]};
	
	end 


end


logic [7:0] step_counter;
logic [31:0] T0_result, T1_result;
logic [31:0] S0_result, S1_result;
logic [7:0] S1_finish_buf;
logic [11:0] matrix_counter;
logic [7:0] S_write_buf;


//address ref regisiters
logic [6:0] T_addr_ref_a, T_addr_ref_b,S_addr_ref_a, S_addr_ref_b, C_addr_ref_a,C_addr_ref_b;

//8 bits signals after cliping and divide by 16 is done
logic [7:0] S0_finish, S1_finish;

//cliping, tranform 32 bits to 8 bits and perform dividing of 16
assign S0_finish=(S0_result[31]==1'b1)?8'd0:((|S0_result[30:24])?8'd255:S0_result[23:16]);
assign S1_finish=(S1_result[31]==1'b1)?8'd0:((|S1_result[30:24])?8'd255:S1_result[23:16]);


//FSM for Milestone 2
always_ff @ (posedge CLOCK_50 or negedge Resetn) begin
	if (~Resetn) begin
		step_counter<=8'd0;
		
		finish<=1'b0;
		SRAM_we_n <= 1'b1; //read initially 
		SRAM_write_data <= 16'd0;
		SRAM_address <= 18'd0;
		
		//initialization for dual_port_RAM_S
		address_S_a<=7'd0;
		address_S_b<=7'd0;
		write_data_S_a<=32'd0;
		write_data_S_b<=32'd0;
		write_enable_S_a<=1'b1;
		write_enable_S_b<=1'b0;
		
		//initialization for dual_port_RAM_C
		address_C_a<=7'd0;
		address_C_b<=7'd1;
		write_data_C_a<=32'd0;
		write_data_C_b<=32'd0;
		write_enable_C_a<=1'b0;
		write_enable_C_b<=1'b0;
		
		
		//initialization for dual_port_RAM_T
		address_T_a<=7'd0;
		address_T_b<=7'd1;
		write_data_T_a<=32'd0;
		write_data_T_b<=32'd0;
		write_enable_T_a<=1'b1;
		write_enable_T_b<=1'b1;
		
		//initialization for accumulaters for T
		T0_result<=32'd0;
		T1_result<=32'd0;
		
		matrix_counter<=12'd0;//counter for matrix excutated, total 2400 matrix 
		
		//initialize addr ref registers
		T_addr_ref_a<=7'd0;
		T_addr_ref_b<=7'd1;
		S_addr_ref_a<=7'd0;
		S_addr_ref_b<=7'd0;
		C_addr_ref_a<=7'd0;
		C_addr_ref_b<=7'd1;
		
		S1_finish_buf<=8'd0;
		S_write_buf<=8'd0;
		
		
		m2_state<=S_m2_lead_in_FS;
	end 
	else begin
		
		case (m2_state)
		
			S_m2_lead_in_FS: begin
				if (start==1'b1)begin
				
					//step_counter<=step_counter+8'd1;
					//SRAM_we_n <= 1'b1;
					if (step_counter<=8'd2)begin
						SRAM_address<=SRAM_read_addr;
						
						step_counter<=step_counter+8'd1;
						SRAM_we_n <= 1'b1;
						
						m2_state<=S_m2_lead_in_FS;
					end	
					else if(step_counter<=8'd63)begin
						if (step_counter[0]==1'b1)begin //for odd numbers, 3, 5,7...
							SRAM_address<=SRAM_read_addr;
							write_enable_S_a<=1'b0;
							address_S_a<=S_addr_ref_a;
							write_data_S_a[31:16]<=SRAM_read_data;
							m2_state<=S_m2_lead_in_FS;
							
							step_counter<=step_counter+8'd1;
							SRAM_we_n <= 1'b1;
							
						end
						else begin
							SRAM_address<=SRAM_read_addr;//for even numbers, 4,6,8....
							write_enable_S_a<=1'b1;
							address_S_a<=S_addr_ref_a;
							S_addr_ref_a<=S_addr_ref_a+7'd1;
							write_data_S_a[15:0]<=SRAM_read_data;
							m2_state<=S_m2_lead_in_FS;
							
							step_counter<=step_counter+8'd1;
							SRAM_we_n <= 1'b1;
						
						end
					
					end
					else if (step_counter<=8'd66)begin //cyc 64, 65 ,66
					
						if (step_counter[0]==1'b1)begin //for odd numbers, 65
							write_enable_S_a<=1'b1;
							address_S_a<=S_addr_ref_a;
							write_data_S_a[31:16]<=SRAM_read_data;
							m2_state<=S_m2_lead_in_FS;
							
							step_counter<=step_counter+8'd1;
							SRAM_we_n <= 1'b1;
							
						end
						else begin//for even numbers, 64,66
							write_enable_S_a<=1'b1;
							address_S_a<=S_addr_ref_a;
							S_addr_ref_a<=S_addr_ref_a+7'd1;
							write_data_S_a[15:0]<=SRAM_read_data;
							m2_state<=S_m2_lead_in_FS;
							
							
							step_counter<=step_counter+8'd1;
							SRAM_we_n <= 1'b1;
						
						end
					end
					else if (step_counter==8'd67) begin
						//inital reading for DP-ram S
						write_enable_S_a<=1'b0;
						address_S_a<=7'd0;
						step_counter<=8'd0;
						S_addr_ref_a<=7'd1;
						
						//inital reading for DP-ram C
						write_enable_C_a<=1'b0;
						write_enable_C_b<=1'b0;
						address_C_a<=C_addr_ref_a;
						C_addr_ref_a<=C_addr_ref_a+7'd2;
						address_C_b<=C_addr_ref_b;
						C_addr_ref_b<=C_addr_ref_b+7'd2;
						
						matrix_counter<=matrix_counter+12'd1;
						m2_state<=S_m2_lead_in_CT;
					
					end	
				end
			end
			
/////////////////////////////////////////////////////////////////////////////////////////////////////			
			S_m2_lead_in_CT: begin
			if (step_counter<=8'd129)begin
				step_counter<=step_counter+8'd1;
				if (step_counter==8'd0)begin
					
					//reading from C
					write_enable_C_a<=1'b0;
					write_enable_C_b<=1'b0;
					address_C_a<=C_addr_ref_a; //2
					C_addr_ref_a<=C_addr_ref_a+7'd2;//4
					address_C_b<=C_addr_ref_b;//3
					C_addr_ref_b<=C_addr_ref_b+7'd2;//5
					
					//reading from S	
					write_enable_S_a<=1'b0;
					address_S_a<=S_addr_ref_a;//1
					S_addr_ref_a<=S_addr_ref_a+7'd1;//2
					
					m2_state<=S_m2_lead_in_CT;
					
				end
				else if (step_counter==8'd1) begin
					//calculate T values,dont write into T
					write_enable_T_a<=1'b0;
					write_enable_T_b<=1'b0;
					T0_result<=m1+m3;
					T1_result<=m2+m4;
					
					//reading from C
					write_enable_C_a<=1'b0;
					write_enable_C_b<=1'b0;
					address_C_a<=C_addr_ref_a;//4
					C_addr_ref_a<=C_addr_ref_a+7'd2;//6
					address_C_b<=C_addr_ref_b;//5
					C_addr_ref_b<=C_addr_ref_b+7'd2;//7
					
					//reading from S	
					write_enable_S_a<=1'b0;
					address_S_a<=S_addr_ref_a;//2
					S_addr_ref_a<=S_addr_ref_a+7'd1;//3
					
					m2_state<=S_m2_lead_in_CT;
				end
				else if (step_counter%4==3) begin
					//determine read address
					
					//if (step_counter==change_row_cyc && change_row_cyc!=8'd127)begin
					if ((C_addr_ref_a >7'd30 || C_addr_ref_b >7'd31) && step_counter!=8'd127)begin
						//changing row of S' matrix,C go back to 0,0 position
						
						//read from C DP-ram
						write_enable_C_a<=1'b0;
						write_enable_C_b<=1'b0;
						address_C_a<=7'd0;
						address_C_b<=7'd1;
						C_addr_ref_a<=7'd2;
						C_addr_ref_b<=7'd3;
						
						//read from S DP-ram, go to the next row
						write_enable_S_a<=1'b0;
						address_S_a<=S_addr_ref_a;
						S_addr_ref_a<=S_addr_ref_a+7'd1;
						
						write_enable_T_a<=1'b0;
						write_enable_T_b<=1'b0;
						T0_result<=T0_result+m1+m3;
						T1_result<=T1_result+m2+m4;
						
						//change_row_cyc<=change_row_cyc+8'd16;
						
						m2_state<=S_m2_lead_in_CT;
					end
					else if (step_counter==8'd127)begin //last address of C matrix
						//no reading address needed
						
						write_enable_T_a<=1'b0;
						write_enable_T_b<=1'b0;
						T0_result<=T0_result+m1+m3;
						T1_result<=T1_result+m2+m4;
						
						m2_state<=S_m2_lead_in_CT;
					end
					else begin //C move on to the next col, S' stay in the same row
						//read from DP-sram C
						write_enable_C_a<=1'b0;
						write_enable_C_b<=1'b0;
						address_C_a<=C_addr_ref_a;//8
						C_addr_ref_a<=C_addr_ref_a+7'd2;//10
						address_C_b<=C_addr_ref_b;//9
						C_addr_ref_b<=C_addr_ref_b+7'd2;//11
					
						//read from DP-sram S	
						write_enable_S_a<=1'b0;
						address_S_a<=S_addr_ref_a-7'd4;//0
						S_addr_ref_a<=S_addr_ref_a-7'd3;//1
					
						//not writing into T
						write_enable_T_a<=1'b0;
						write_enable_T_b<=1'b0;
						T0_result<=T0_result+m1+m3;
						T1_result<=T1_result+m2+m4;
						
						m2_state<=S_m2_lead_in_CT;
						
					end
					
				end
				else if ((step_counter%4==1) && step_counter!=8'd129) begin
					//two T values are ready to be written into T DP-RAM,read from S and C 
					
					//read from DP-ram C
					write_enable_C_a<=1'b0;
					write_enable_C_b<=1'b0;
					address_C_a<=C_addr_ref_a;   //12
					C_addr_ref_a<=C_addr_ref_a+7'd2;  //14
					address_C_b<=C_addr_ref_b;  //13
					C_addr_ref_b<=C_addr_ref_b+7'd2;  //15
					
					//read from DP-ram S
					write_enable_S_a<=1'b0;
					address_S_a<=S_addr_ref_a;//2
					S_addr_ref_a<=S_addr_ref_a+7'd1; //3
					
					//write T values
					write_enable_T_a<=1'b1;
					write_enable_T_b<=1'b1;
					
					write_data_T_a<={{8{T0_result[31]}},T0_result[31:8]}; //perform division
					write_data_T_b<={{8{T1_result[31]}},T1_result[31:8]}; //perform division
					address_T_a<=T_addr_ref_a;
					T_addr_ref_a<=T_addr_ref_a+7'd2;
					address_T_b<=T_addr_ref_b;
					T_addr_ref_b<=T_addr_ref_b+7'd2;
					
					T0_result<=m1+m3;
					T1_result<=m2+m4;
					
					m2_state<=S_m2_lead_in_CT;
				end
				else if (step_counter==8'd128)begin
					
					//accumulating value of T, not writing into T DP-RAM
					write_enable_T_a<=1'b0;
					write_enable_T_b<=1'b0;
					T0_result<=T0_result+m1+m3;
					T1_result<=T1_result+m2+m4;
					
					m2_state<=S_m2_lead_in_CT;
					
				end
				else if (step_counter==8'd129) begin
						//write T values
					write_enable_T_a<=1'b1;
					write_enable_T_b<=1'b1;
					
					write_data_T_a<={{8{T0_result[31]}},T0_result[31:8]}; //perform division
					write_data_T_b<={{8{T1_result[31]}},T1_result[31:8]}; //perform division
					
					address_T_a<=T_addr_ref_a;
					address_T_b<=T_addr_ref_b;
					
					//clear all values and ready for next state
					step_counter<=8'd0;
					
					T_addr_ref_a<=7'd0;
					T_addr_ref_b<=7'd8;
					S_addr_ref_a<=7'd0;
					S_addr_ref_b<=7'd64; //start writing calcuated S values from DP s-ram address 64 
					C_addr_ref_a<=7'd0;
					C_addr_ref_b<=7'd1;
					//change_row_cyc<=8'12;
					
					m2_state<=S_m2_CS_FS_dummy_read;
					
				end
				else begin //for %4==0 and %4==2 
					//regular case, S and C stay in the same row or col, accumulate T results
					
					//read from DP-ram C
					write_enable_C_a<=1'b0;
					write_enable_C_b<=1'b0;
					address_C_a<=C_addr_ref_a;//6   //10
					C_addr_ref_a<=C_addr_ref_a+7'd2;//8   //12
					address_C_b<=C_addr_ref_b;//7    //11
					C_addr_ref_b<=C_addr_ref_b+7'd2;//9   //13
					
					//read from DP-ram S
					write_enable_S_a<=1'b0;
					address_S_a<=S_addr_ref_a;//3   //1
					S_addr_ref_a<=S_addr_ref_a+7'd1;//4   //2
					
					//not writing into T
					write_enable_T_a<=1'b0;
					write_enable_T_b<=1'b0;
					T0_result<=T0_result+m1+m3;
					T1_result<=T1_result+m2+m4;
						
					m2_state<=S_m2_lead_in_CT;
				
				end
				end
			end
	
///////////////////////////////////////////////////////////////////////////////////////////////////			
			S_m2_CS_FS_dummy_read: begin
			//initiate read from T
				write_enable_T_a<=1'b0;
				write_enable_T_b<=1'b0;
				address_T_a<=T_addr_ref_a;//0
				address_T_b<=T_addr_ref_b;//8
				T_addr_ref_a<=T_addr_ref_a+7'd16;//16
				T_addr_ref_b<=T_addr_ref_b+7'd16;//24
			
			//initiate read from C
				write_enable_C_a<=1'b0;
				write_enable_C_b<=1'b0;
				address_C_a<=C_addr_ref_a;//0
				address_C_b<=C_addr_ref_b;//1
				C_addr_ref_a<=C_addr_ref_a+7'd2;//2
				C_addr_ref_b<=C_addr_ref_b+7'd2;//3
				
			//initiate read from SRAM
				SRAM_address<=SRAM_read_addr;
				SRAM_we_n <= 1'b1;
				
				m2_state<=S_m2_CS_FS;
			end

/////////////////////////////////////////////////////////////////////////////////////////////////////////////
			S_m2_CS_FS: begin
				if (step_counter<=8'd130) begin
			
					step_counter<=step_counter+8'd1;
		////////////////////////////////////////////////////////////////////////////////////
					//logic for initiate reading
					if ((step_counter%4==0|| step_counter%4==3) && step_counter!=8'd128) begin
						//SRAM_we_n <= 1'b1;
						SRAM_address<=SRAM_read_addr;
					end
				
					
		///////////////////////////////////////////////////////////////////////////////////
					//logic for write into DP-ram, FS
					if (step_counter%4==2  && step_counter!=8'd130) begin
						//write S' into [31:16] 
						write_enable_S_a<=1'b1;
						address_S_a<=S_addr_ref_a;
						write_data_S_a[31:16]<=SRAM_read_data;
						
					
					end
					else if (step_counter%4==3) begin //if (step_counter%4==3  && step_counter!=8'd131) begin
						//write S' into [15:0] 
						write_enable_S_a<=1'b1;
						address_S_a<=S_addr_ref_a;
						S_addr_ref_a<=S_addr_ref_a+7'd1;
						write_data_S_a[15:0]<=SRAM_read_data;
					end 
					else 
						write_enable_S_a<=1'b0;
				
					
		//////////////////////////////////////////////////////////////////////////////////
					//logic for calculating S, S=C(t)*T
					if (step_counter==8'd0)begin
					
					//reading from T
					write_enable_T_a<=1'b0;
					write_enable_T_b<=1'b0;
					address_T_a<=T_addr_ref_a; //16
					T_addr_ref_a<=T_addr_ref_a+7'd16;//32
					address_T_b<=T_addr_ref_b;//24
					T_addr_ref_b<=T_addr_ref_b+7'd16;//40
					
					//reading from C	
					write_enable_C_a<=1'b0;
					write_enable_C_b<=1'b0;
					address_C_a<=C_addr_ref_a;//2
					address_C_b<=C_addr_ref_b;//3
					C_addr_ref_a<=C_addr_ref_a+7'd2;//4
					C_addr_ref_b<=C_addr_ref_b+7'd2;//5
					
					m2_state<=S_m2_CS_FS;
					
				end
				else if (step_counter==8'd1)begin
					
					//reading from T
					write_enable_T_a<=1'b0;
					write_enable_T_b<=1'b0;
					address_T_a<=T_addr_ref_a; //32
					T_addr_ref_a<=T_addr_ref_a+7'd16;//48
					address_T_b<=T_addr_ref_b;//40
					T_addr_ref_b<=T_addr_ref_b+7'd16;//56
					
					//reading from C	
					write_enable_C_a<=1'b0;
					write_enable_C_b<=1'b0;
					address_C_a<=C_addr_ref_a;//4
					address_C_b<=C_addr_ref_b;//5
					C_addr_ref_a<=C_addr_ref_a+7'd2;//6
					C_addr_ref_b<=C_addr_ref_b+7'd2;//7
					
					S0_result<=m1+m3;
					S1_result<=m2+m4;
					
					m2_state<=S_m2_CS_FS;
					
				end
				else if (step_counter%4==3) begin
					//determine read address
					
					if ((C_addr_ref_a >7'd30 || C_addr_ref_b >7'd31) && step_counter!=8'd127)begin
						//changing col of T matrix,C go back to 0,0 position
						
						//read from C DP-ram
						write_enable_C_a<=1'b0;
						write_enable_C_b<=1'b0;
						address_C_a<=7'd0;
						address_C_b<=7'd1;
						C_addr_ref_a<=7'd2;
						C_addr_ref_b<=7'd3;
						
						//read from T DP-ram, go to the next col
						write_enable_T_a<=1'b0;
						write_enable_T_b<=1'b0;
						address_T_a<=T_addr_ref_a-7'd63; //48+16-1=63
						T_addr_ref_a<=T_addr_ref_a-7'd47;//48+16-17
						address_T_b<=T_addr_ref_b-7'd63;//56+16-9=63
						T_addr_ref_b<=T_addr_ref_b-7'd47;//56+16-25
						
						S0_result<=S0_result+m1+m3;
						S1_result<=S1_result+m2+m4;
						
						m2_state<=S_m2_CS_FS;
					end
					else if (step_counter==8'd127)begin //last address of C matrix
						//no reading address needed
					
						S0_result<=S0_result+m1+m3;
						S1_result<=S1_result+m2+m4;
						
						m2_state<=S_m2_CS_FS;
					end
					else begin//C move on to the next row, T stay in the same col
						//read from DP-sram C
						write_enable_C_a<=1'b0;
						write_enable_C_b<=1'b0;
						address_C_a<=C_addr_ref_a;//8
						C_addr_ref_a<=C_addr_ref_a+7'd2;//10
						address_C_b<=C_addr_ref_b;//9
						C_addr_ref_b<=C_addr_ref_b+7'd2;//11
					
						//reading from T
						write_enable_T_a<=1'b0;
						write_enable_T_b<=1'b0;
						address_T_a<=T_addr_ref_a-7'd64; //0
						T_addr_ref_a<=T_addr_ref_a-7'd48;//16
						address_T_b<=T_addr_ref_b-7'd64;//8
						T_addr_ref_b<=T_addr_ref_b-7'd48;//24
					
						//not writing into S
						S0_result<=S0_result+m1+m3;
						S1_result<=S1_result+m2+m4;
						
						m2_state<=S_m2_CS_FS;
						
					end
				end
				else if (step_counter%4==1 && step_counter!=8'd129) begin
					//two T values are ready to be written into T DP-RAM,read from S and C 
					
					//read from DP-ram C
					write_enable_C_a<=1'b0;
					write_enable_C_b<=1'b0;
					address_C_a<=C_addr_ref_a;   //12
					C_addr_ref_a<=C_addr_ref_a+7'd2;  //14
					address_C_b<=C_addr_ref_b;  //13
					C_addr_ref_b<=C_addr_ref_b+7'd2;  //15
					
					//reading from T
					write_enable_T_a<=1'b0;
					write_enable_T_b<=1'b0;
					address_T_a<=T_addr_ref_a; //32
					T_addr_ref_a<=T_addr_ref_a+7'd16;//48
					address_T_b<=T_addr_ref_b;//40
					T_addr_ref_b<=T_addr_ref_b+7'd16;//56
													
					S1_finish_buf<=S1_finish;//buffer S1 value after clipping is done
					
					S0_result<=m1+m3;
					S1_result<=m2+m4;
					
					m2_state<=S_m2_CS_FS;
				end
				else if (step_counter==8'd128)begin
					
					//accumulating value of S, not writing into S DP-RAM
					S0_result<=S0_result+m1+m3;
					S1_result<=S1_result+m2+m4;
					
					m2_state<=S_m2_CS_FS;
					
				end
				else if (step_counter==8'd129) begin				
					
					//buffer S1 value after clipping is done
					S1_finish_buf<=S1_finish;
					
					m2_state<=S_m2_CS_FS;
					
				end
				else if (step_counter==8'd130) begin				
					//perform write S values into DP-ram, ready for nex state
					step_counter<=8'd0;
					
					//initiate reading from S port a and C port a and b for CT calculation
					
					//inital reading from DP-ram S port a 
					write_enable_S_a<=1'b0;
					address_S_a<=8'd0;
					S_addr_ref_a<=7'd1;
					
						
					//inital reading for DP-ram C
					write_enable_C_a<=1'b0;
					write_enable_C_b<=1'b0;
					address_C_a<=7'd0;
					C_addr_ref_a<=7'd2;
					address_C_b<=7'd1;
					C_addr_ref_b<=7'd3;	
				
					//initial writing for DP-ram T
					write_enable_T_a<=1'b0;
					write_enable_T_b<=1'b0;
					address_T_a<=7'd0;
					T_addr_ref_a<=7'd0;
					address_T_b<=7'd1;
					T_addr_ref_b<=7'd1;	
					
					//initial address for reading from S dp-ram port b
					S_addr_ref_b<=7'd64;
					write_enable_S_b<=1'b0;
					
					matrix_counter<=matrix_counter+12'd1;
					
					m2_state<=S_m2_CT_WS;
					
				end
				else begin //for %4==0 and %4==2 
					//regular case, T and C stay in the same row or col, accumulate S results
					
					//read from DP-ram C
					write_enable_C_a<=1'b0;
					write_enable_C_b<=1'b0;
					address_C_a<=C_addr_ref_a;//6   //10
					C_addr_ref_a<=C_addr_ref_a+7'd2;//8   //12
					address_C_b<=C_addr_ref_b;//7    //11
					C_addr_ref_b<=C_addr_ref_b+7'd2;//9   //13
					
					//reading from T
					address_T_a<=T_addr_ref_a; //32
					T_addr_ref_a<=T_addr_ref_a+7'd16;//48
					address_T_b<=T_addr_ref_b;//40
					T_addr_ref_b<=T_addr_ref_b+7'd16;//56
					
					//not writing into S
					S0_result<=S0_result+m1+m3;
					S1_result<=S1_result+m2+m4;
						
					m2_state<=S_m2_CS_FS;
				
				end	
					
		////////////////////////////////////////////////////////////////////////////////
					//code for providing address and write into S dp-ram
					write_enable_S_b<=1'b0;
					if (step_counter%4==1 && step_counter!=8'd1)begin
						
							//write S values
							write_enable_S_b<=1'b1;
							write_data_S_b<={24'd0,S0_finish}; 
							
							address_S_b<=S_addr_ref_b;
							S_addr_ref_b<=S_addr_ref_b+7'd8;
						
					
					end 
					else if (step_counter%4==2 && step_counter!=8'd2)begin
						if (step_counter==8'd18 ||step_counter==8'd50 
						 || step_counter==8'd82||step_counter==8'd114) begin
							//write S values
							write_enable_S_b<=1'b1;
							write_data_S_b<={24'd0,S1_finish_buf}; 
							
							address_S_b<=S_addr_ref_b;
							S_addr_ref_b<=S_addr_ref_b-7'd55;
					
						end
						else if (step_counter==8'd34 ||step_counter==8'd66
							||step_counter==8'd98 /*||step_counter==8'd130*/)begin
							
							//write S values
							write_enable_S_b<=1'b1;
							write_data_S_b<={24'd0,S1_finish_buf}; 
							
							address_S_b<=S_addr_ref_b;
							S_addr_ref_b<=S_addr_ref_b-7'd55;
						end
						else if (step_counter==8'd130)begin
							
							//write S values
							write_enable_S_b<=1'b1;
							write_data_S_b[7:0]<=S1_finish_buf; 
							
							address_S_b<=S_addr_ref_b;
						end
						else begin
							//write S values
							write_enable_S_b<=1'b1;
							write_data_S_b<={24'd0,S1_finish_buf}; 
							
							address_S_b<=S_addr_ref_b;
							S_addr_ref_b<=S_addr_ref_b+7'd8;
						end
					
					
					end
			
				end
			end	
			
////////////////////////////////////////////////////////////////////////////////////////////////////			
			S_m2_CT_WS: begin
			if (step_counter<=8'd129)begin
				step_counter<=step_counter+8'd1;	
			////////////////////////////////////////////////////////////
			//logic for WS, read from dp-rams 
				if (step_counter==8'd0)begin
					write_enable_S_b<=1'b0;
					address_S_b<=S_addr_ref_b;//64
					S_addr_ref_b<=S_addr_ref_b+7'd1;//65
					
				end
				else if (step_counter%4==2 && step_counter!=8'd128)begin
					//init iate read from S dp-ram port b
					write_enable_S_b<=1'b0;
					address_S_b<=S_addr_ref_b;//65
					S_addr_ref_b<=S_addr_ref_b+7'd1;//66
					
					S_write_buf<=read_data_S_b[7:0];
					
				end
				//logic for write into sram
				
				else if (step_counter%4==0)begin
					//write into SRAM
					SRAM_address<=SRAM_write_addr;
					SRAM_we_n <= 1'b0;
					SRAM_write_data<={S_write_buf,read_data_S_b[7:0]};
					
					write_enable_S_b<=1'b0;
					address_S_b<=S_addr_ref_b;//65
					S_addr_ref_b<=S_addr_ref_b+7'd1;//66

				end
				else begin
					write_enable_S_b<=1'b0;
					SRAM_we_n <= 1'b1;
				end
		
			///////////////////////////////////////////////////////////////////////////
			//logic for CT calculation
				if (step_counter==8'd0)begin
					
					//reading from C
					write_enable_C_a<=1'b0;
					write_enable_C_b<=1'b0;
					address_C_a<=C_addr_ref_a; //2
					C_addr_ref_a<=C_addr_ref_a+7'd2;//4
					address_C_b<=C_addr_ref_b;//3
					C_addr_ref_b<=C_addr_ref_b+7'd2;//5
					
					//reading from S	
					write_enable_S_a<=1'b0;
					address_S_a<=S_addr_ref_a;//1
					S_addr_ref_a<=S_addr_ref_a+7'd1;//2
					
					m2_state<=S_m2_CT_WS;
					
				end
				else if (step_counter==8'd1) begin
					//calculate T values,dont write into T
					write_enable_T_a<=1'b0;
					write_enable_T_b<=1'b0;
					T0_result<=m1+m3;
					T1_result<=m2+m4;
					
					//reading from C
					write_enable_C_a<=1'b0;
					write_enable_C_b<=1'b0;
					address_C_a<=C_addr_ref_a;//4
					C_addr_ref_a<=C_addr_ref_a+7'd2;//6
					address_C_b<=C_addr_ref_b;//5
					C_addr_ref_b<=C_addr_ref_b+7'd2;//7
					
					//reading from S	
					write_enable_S_a<=1'b0;
					address_S_a<=S_addr_ref_a;//2
					S_addr_ref_a<=S_addr_ref_a+7'd1;//3
					
					m2_state<=S_m2_CT_WS;
				end
				else if (step_counter%4==3) begin
					//determine read address
					
					//if (step_counter==change_row_cyc && change_row_cyc!=8'd127)begin
					if ((C_addr_ref_a >7'd30 || C_addr_ref_b >7'd31) && step_counter!=8'd127)begin
						//changing row of S' matrix,C go back to 0,0 position
						
						//read from C DP-ram
						write_enable_C_a<=1'b0;
						write_enable_C_b<=1'b0;
						address_C_a<=7'd0;
						address_C_b<=7'd1;
						C_addr_ref_a<=7'd2;
						C_addr_ref_b<=7'd3;
						
						//read from S DP-ram, go to the next row
						write_enable_S_a<=1'b0;
						address_S_a<=S_addr_ref_a;
						S_addr_ref_a<=S_addr_ref_a+7'd1;
						
						write_enable_T_a<=1'b0;
						write_enable_T_b<=1'b0;
						T0_result<=T0_result+m1+m3;
						T1_result<=T1_result+m2+m4;
						
						//change_row_cyc<=change_row_cyc+8'd16;
						
						m2_state<=S_m2_CT_WS;
					end
					else if (step_counter==8'd127)begin //last address of C matrix
						//no reading address needed
						
						write_enable_T_a<=1'b0;
						write_enable_T_b<=1'b0;
						T0_result<=T0_result+m1+m3;
						T1_result<=T1_result+m2+m4;
						
						m2_state<=S_m2_CT_WS;
					end
					else begin //C move on to the next col, S' stay in the same row
						//read from DP-sram C
						write_enable_C_a<=1'b0;
						write_enable_C_b<=1'b0;
						address_C_a<=C_addr_ref_a;//8
						C_addr_ref_a<=C_addr_ref_a+7'd2;//10
						address_C_b<=C_addr_ref_b;//9
						C_addr_ref_b<=C_addr_ref_b+7'd2;//11
					
						//read from DP-sram S	
						write_enable_S_a<=1'b0;
						address_S_a<=S_addr_ref_a-7'd4;//0
						S_addr_ref_a<=S_addr_ref_a-7'd3;//1
					
						//not writing into T
						write_enable_T_a<=1'b0;
						write_enable_T_b<=1'b0;
						T0_result<=T0_result+m1+m3;
						T1_result<=T1_result+m2+m4;
						
						m2_state<=S_m2_CT_WS;
						
					end
					
				end
				else if ((step_counter%4==1) && step_counter!=8'd129) begin
					//two T values are ready to be written into T DP-RAM,read from S and C 
					
					//read from DP-ram C
					write_enable_C_a<=1'b0;
					write_enable_C_b<=1'b0;
					address_C_a<=C_addr_ref_a;   //12
					C_addr_ref_a<=C_addr_ref_a+7'd2;  //14
					address_C_b<=C_addr_ref_b;  //13
					C_addr_ref_b<=C_addr_ref_b+7'd2;  //15
					
					//read from DP-ram S
					write_enable_S_a<=1'b0;
					address_S_a<=S_addr_ref_a;//2
					S_addr_ref_a<=S_addr_ref_a+7'd1; //3
					
					//write T values
					write_enable_T_a<=1'b1;
					write_enable_T_b<=1'b1;
					
					write_data_T_a<={{8{T0_result[31]}},T0_result[31:8]}; //perform division
					write_data_T_b<={{8{T1_result[31]}},T1_result[31:8]}; //perform division
					address_T_a<=T_addr_ref_a;
					T_addr_ref_a<=T_addr_ref_a+7'd2;
					address_T_b<=T_addr_ref_b;
					T_addr_ref_b<=T_addr_ref_b+7'd2;
					
					T0_result<=m1+m3;
					T1_result<=m2+m4;
					
					m2_state<=S_m2_CT_WS;
				end
				else if (step_counter==8'd128)begin
					
					//accumulating value of T, not writing into T DP-RAM
					write_enable_T_a<=1'b0;
					write_enable_T_b<=1'b0;
					T0_result<=T0_result+m1+m3;
					T1_result<=T1_result+m2+m4;
					
					m2_state<=S_m2_CT_WS;
					
				end
				else if (step_counter==8'd129) begin
					
					if (matrix_counter<13'd2400) begin
						
						//write T values
						write_enable_T_a<=1'b1;
						write_enable_T_b<=1'b1;
					
						write_data_T_a<={{8{T0_result[31]}},T0_result[31:8]}; //perform division
						write_data_T_b<={{8{T1_result[31]}},T1_result[31:8]}; //perform division
					
						address_T_a<=T_addr_ref_a;
						address_T_b<=T_addr_ref_b;
						
						//clear all values and ready for next state
						step_counter<=8'd0;
						
						T_addr_ref_a<=7'd0;
						T_addr_ref_b<=7'd8;
						S_addr_ref_a<=7'd0;
						S_addr_ref_b<=7'd64; //start writing calcuated S values from DP s-ram address 64 
						C_addr_ref_a<=7'd0;
						C_addr_ref_b<=7'd1;
					
						m2_state<=S_m2_CS_FS_dummy_read;
		
					end
					else begin
					
						//write T values
						write_enable_T_a<=1'b1;
						write_enable_T_b<=1'b1;
					
						write_data_T_a<={{8{T0_result[31]}},T0_result[31:8]}; //perform division
						write_data_T_b<={{8{T1_result[31]}},T1_result[31:8]}; //perform division
					
						address_T_a<=T_addr_ref_a;
						address_T_b<=T_addr_ref_b;
						
						//clear all values and ready for next state
						step_counter<=8'd0;
						
						T_addr_ref_a<=7'd0;
						T_addr_ref_b<=7'd8;
						S_addr_ref_a<=7'd0;
						S_addr_ref_b<=7'd64; //start writing calcuated S values from DP s-ram address 64 
						C_addr_ref_a<=7'd0;
						C_addr_ref_b<=7'd1;
						//change_row_cyc<=8'12;
						
						m2_state<=S_m2_dummy_lead_out_CS;
					end
				end
				else begin //for %4==0 and %4==2 
					//regular case, S and C stay in the same row or col, accumulate T results
					
					//read from DP-ram C
					write_enable_C_a<=1'b0;
					write_enable_C_b<=1'b0;
					address_C_a<=C_addr_ref_a;//6   //10
					C_addr_ref_a<=C_addr_ref_a+7'd2;//8   //12
					address_C_b<=C_addr_ref_b;//7    //11
					C_addr_ref_b<=C_addr_ref_b+7'd2;//9   //13
					
					//read from DP-ram S
					write_enable_S_a<=1'b0;
					address_S_a<=S_addr_ref_a;//3   //1
					S_addr_ref_a<=S_addr_ref_a+7'd1;//4   //2
					
					//not writing into T
					write_enable_T_a<=1'b0;
					write_enable_T_b<=1'b0;
					T0_result<=T0_result+m1+m3;
					T1_result<=T1_result+m2+m4;
						
					m2_state<=S_m2_CT_WS;
				
				end
				end
			
			
			end
		
////////////////////////////////////////////////////////////////////////////////////////////////////		
			S_m2_dummy_lead_out_CS: begin
				//initiate read from T
				write_enable_T_a<=1'b0;
				write_enable_T_b<=1'b0;
				address_T_a<=T_addr_ref_a;//0
				address_T_b<=T_addr_ref_b;//8
				T_addr_ref_a<=T_addr_ref_a+7'd16;//16
				T_addr_ref_b<=T_addr_ref_b+7'd16;//24
			
				//initiate read from C
				write_enable_C_a<=1'b0;
				write_enable_C_b<=1'b0;
				address_C_a<=C_addr_ref_a;//0
				address_C_b<=C_addr_ref_b;//1
				C_addr_ref_a<=C_addr_ref_a+7'd2;//2
				C_addr_ref_b<=C_addr_ref_b+7'd2;//3
				
				m2_state<=S_m2_lead_out_CS;
			
			end
			
//////////////////////////////////////////////////////////////////////////////////////////////////////			
			S_m2_lead_out_CS: begin
			if (step_counter<=8'd130) begin
					step_counter<=step_counter+8'd1;
		//////////////////////////////////////////////////////////////////////////////////
					//logic for calculating S, S=C(t)*T
					if (step_counter==8'd0)begin
					
					//reading from T
					write_enable_T_a<=1'b0;
					write_enable_T_b<=1'b0;
					address_T_a<=T_addr_ref_a; //16
					T_addr_ref_a<=T_addr_ref_a+7'd16;//32
					address_T_b<=T_addr_ref_b;//24
					T_addr_ref_b<=T_addr_ref_b+7'd16;//40
					
					//reading from C	
					write_enable_C_a<=1'b0;
					write_enable_C_b<=1'b0;
					address_C_a<=C_addr_ref_a;//2
					address_C_b<=C_addr_ref_b;//3
					C_addr_ref_a<=C_addr_ref_a+7'd2;//4
					C_addr_ref_b<=C_addr_ref_b+7'd2;//5
					
					m2_state<=S_m2_lead_out_CS;
					
				end
				else if (step_counter==8'd1)begin
					
					//reading from T
					write_enable_T_a<=1'b0;
					write_enable_T_b<=1'b0;
					address_T_a<=T_addr_ref_a; //32
					T_addr_ref_a<=T_addr_ref_a+7'd16;//48
					address_T_b<=T_addr_ref_b;//40
					T_addr_ref_b<=T_addr_ref_b+7'd16;//56
					
					//reading from C	
					write_enable_C_a<=1'b0;
					write_enable_C_b<=1'b0;
					address_C_a<=C_addr_ref_a;//4
					address_C_b<=C_addr_ref_b;//5
					C_addr_ref_a<=C_addr_ref_a+7'd2;//6
					C_addr_ref_b<=C_addr_ref_b+7'd2;//7
					
					S0_result<=m1+m3;
					S1_result<=m2+m4;
					
					m2_state<=S_m2_lead_out_CS;
					
				end
				else if (step_counter%4==3) begin
					//determine read address
					
					if ((C_addr_ref_a >7'd30 || C_addr_ref_b >7'd31) && step_counter!=8'd127)begin
						//changing col of T matrix,C go back to 0,0 position
						
						//read from C DP-ram
						write_enable_C_a<=1'b0;
						write_enable_C_b<=1'b0;
						address_C_a<=7'd0;
						address_C_b<=7'd1;
						C_addr_ref_a<=7'd2;
						C_addr_ref_b<=7'd3;
						
						//read from T DP-ram, go to the next col
						write_enable_T_a<=1'b0;
						write_enable_T_b<=1'b0;
						address_T_a<=T_addr_ref_a-7'd63; //48+16-1=63
						T_addr_ref_a<=T_addr_ref_a-7'd47;//48+16-17
						address_T_b<=T_addr_ref_b-7'd63;//56+16-9=63
						T_addr_ref_b<=T_addr_ref_b-7'd47;//56+16-25
						
						S0_result<=S0_result+m1+m3;
						S1_result<=S1_result+m2+m4;
						
						m2_state<=S_m2_lead_out_CS;
					end
					else if (step_counter==8'd127)begin //last address of C matrix
						//no reading address needed
						
						S0_result<=S0_result+m1+m3;
						S1_result<=S1_result+m2+m4;
						
						m2_state<=S_m2_lead_out_CS;
					end
					else begin//C move on to the next row, T stay in the same col
						//read from DP-sram C
						write_enable_C_a<=1'b0;
						write_enable_C_b<=1'b0;
						address_C_a<=C_addr_ref_a;//8
						C_addr_ref_a<=C_addr_ref_a+7'd2;//10
						address_C_b<=C_addr_ref_b;//9
						C_addr_ref_b<=C_addr_ref_b+7'd2;//11
					
						//reading from T
						write_enable_T_a<=1'b0;
						write_enable_T_b<=1'b0;
						address_T_a<=T_addr_ref_a-7'd64; //0
						T_addr_ref_a<=T_addr_ref_a-7'd48;//16
						address_T_b<=T_addr_ref_b-7'd64;//8
						T_addr_ref_b<=T_addr_ref_b-7'd48;//24
					
						//not writing into S
						S0_result<=S0_result+m1+m3;
						S1_result<=S1_result+m2+m4;
						
						m2_state<=S_m2_lead_out_CS;
						
					end
				end
				else if (step_counter%4==1 && step_counter!=8'd129) begin
					//two T values are ready to be written into T DP-RAM,read from S and C 
					
					//read from DP-ram C
					write_enable_C_a<=1'b0;
					write_enable_C_b<=1'b0;
					address_C_a<=C_addr_ref_a;   //12
					C_addr_ref_a<=C_addr_ref_a+7'd2;  //14
					address_C_b<=C_addr_ref_b;  //13
					C_addr_ref_b<=C_addr_ref_b+7'd2;  //15
					
					//reading from T
					write_enable_T_a<=1'b0;
					write_enable_T_b<=1'b0;
					address_T_a<=T_addr_ref_a; //32
					T_addr_ref_a<=T_addr_ref_a+7'd16;//48
					address_T_b<=T_addr_ref_b;//40
					T_addr_ref_b<=T_addr_ref_b+7'd16;//56
													
					S1_finish_buf<=S1_finish;//buffer S1 value after clipping is done
					
					S0_result<=m1+m3;
					S1_result<=m2+m4;
					
					m2_state<=S_m2_lead_out_CS;
				end
				else if (step_counter==8'd128)begin
					
					//accumulating value of S, not writing into S DP-RAM
					S0_result<=S0_result+m1+m3;
					S1_result<=S1_result+m2+m4;
					
					m2_state<=S_m2_lead_out_CS;
					
				end
				else if (step_counter==8'd129) begin				
					
					//buffer S1 value after clipping is done
					S1_finish_buf<=S1_finish;
					
					m2_state<=S_m2_lead_out_CS;
					
				end
				else if (step_counter==8'd130) begin				
					//perform write S values into DP-ram, ready for nex state
					step_counter<=8'd0;
					
					//initiate reading from S port a and C port a and b for CT calculation
					
					//inital reading from DP-ram S port a 
					write_enable_S_a<=1'b0;
					address_S_a<=8'd0;
					S_addr_ref_a<=7'd1;
					
						
					//inital reading for DP-ram C
					write_enable_C_a<=1'b0;
					write_enable_C_b<=1'b0;
					address_C_a<=7'd0;
					C_addr_ref_a<=7'd2;
					address_C_b<=7'd1;
					C_addr_ref_b<=7'd3;	
				
					//initial writing for DP-ram T
					write_enable_T_a<=1'b0;
					write_enable_T_b<=1'b0;
					address_T_a<=7'd0;
					T_addr_ref_a<=7'd0;
					address_T_b<=7'd1;
					T_addr_ref_b<=7'd1;	
					
					//initial address for reading from S dp-ram port b
					S_addr_ref_b<=7'd64;
					write_enable_S_b<=1'b0;
					
					matrix_counter<=matrix_counter+12'd1;
					
					m2_state<=S_m2_lead_out_WS;
					
				end
				else begin //for %4==0 and %4==2 
					//regular case, T and C stay in the same row or col, accumulate S results
					
					//read from DP-ram C
					write_enable_C_a<=1'b0;
					write_enable_C_b<=1'b0;
					address_C_a<=C_addr_ref_a;//6   //10
					C_addr_ref_a<=C_addr_ref_a+7'd2;//8   //12
					address_C_b<=C_addr_ref_b;//7    //11
					C_addr_ref_b<=C_addr_ref_b+7'd2;//9   //13
					
					//reading from T
					address_T_a<=T_addr_ref_a; //32
					T_addr_ref_a<=T_addr_ref_a+7'd16;//48
					address_T_b<=T_addr_ref_b;//40
					T_addr_ref_b<=T_addr_ref_b+7'd16;//56
					
					//not writing into S
					S0_result<=S0_result+m1+m3;
					S1_result<=S1_result+m2+m4;
						
					m2_state<=S_m2_lead_out_CS;
				
				end		
					
				////////////////////////////////////////////////////////////////////////////////
					//code for providing address and write into S dp-ram
					write_enable_S_b<=1'b0;
					if (step_counter%4==1 && step_counter!=8'd1)begin
						
							//write S values
							write_enable_S_b<=1'b1;
							write_data_S_b<={24'd0,S0_finish}; 
							
							address_S_b<=S_addr_ref_b;
							S_addr_ref_b<=S_addr_ref_b+7'd8;
						
					
					end 
					else if (step_counter%4==2 && step_counter!=8'd2)begin
						if (step_counter==8'd18 ||step_counter==8'd50 
						 || step_counter==8'd82||step_counter==8'd114) begin
							//write S values
							write_enable_S_b<=1'b1;
							write_data_S_b<={24'd0,S1_finish_buf}; 
							
							address_S_b<=S_addr_ref_b;
							S_addr_ref_b<=S_addr_ref_b-7'd55;
					
						end
						else if (step_counter==8'd34 ||step_counter==8'd66
							||step_counter==8'd98 /*||step_counter==8'd130*/)begin
							
							//write S values
							write_enable_S_b<=1'b1;
							write_data_S_b<={24'd0,S1_finish_buf}; 
							
							address_S_b<=S_addr_ref_b;
							S_addr_ref_b<=S_addr_ref_b-7'd55;
						end
						else if (step_counter==8'd130)begin
							
							//write S values
							write_enable_S_b<=1'b1;
							write_data_S_b[7:0]<=S1_finish_buf; 
							
							address_S_b<=S_addr_ref_b;
						end
						else begin
							//write S values
							write_enable_S_b<=1'b1;
							write_data_S_b<={24'd0,S1_finish_buf}; 
							
							address_S_b<=S_addr_ref_b;
							S_addr_ref_b<=S_addr_ref_b+7'd8;
						end
					
					
					end
				end
			
			end
/////////////////////////////////////////////////////////////////////////////////////////////////////			
			S_m2_lead_out_WS: begin
			if (step_counter<=8'd129)begin  //originally 129, need to be fixed???????????????
				step_counter<=step_counter+8'd1;
			////////////////////////////////////////////////////////////
			//logic for WS, read from dp-rams 
				if (step_counter==8'd0)begin
					write_enable_S_b<=1'b0;
					address_S_b<=S_addr_ref_b;//64
					S_addr_ref_b<=S_addr_ref_b+7'd1;//65
					
				end
				else if (step_counter%4==2 && step_counter!=8'd128)begin
					//init iate read from S dp-ram port b
					write_enable_S_b<=1'b0;
					address_S_b<=S_addr_ref_b;//65
					S_addr_ref_b<=S_addr_ref_b+7'd1;//66
					
					S_write_buf<=read_data_S_b[7:0];
					
				end
				//logic for write into sram
				
				else if (step_counter%4==0)begin
					//write into SRAM
					SRAM_address<=SRAM_write_addr;
					SRAM_we_n <= 1'b0;
					SRAM_write_data<={S_write_buf,read_data_S_b[7:0]};
					
					write_enable_S_b<=1'b0;
					address_S_b<=S_addr_ref_b;//65
					S_addr_ref_b<=S_addr_ref_b+7'd1;//66

				end
				else if (step_counter==8'd129) begin
					finish<=1'b1;
					SRAM_we_n <= 1'b1;
				end
				else begin
					write_enable_S_b<=1'b0;
					SRAM_we_n <= 1'b1;
				end
		end
			
			
			end
		
		default: m2_state <= S_m2_lead_in_FS;	
		endcase
	end
end


///////////////////////////////////////////////////////////////////////////////////////////////////
//always_ff block to calculate SRAM fetch address

logic [5:0]sample_counter;
logic [5:0]col_block_counter;
logic [4:0]row_block_counter;
logic [17:0] base_read_addr;


logic [5:0]col_block_counter_W;
logic [4:0]row_block_counter_W;
logic [17:0] base_write_addr;

logic [5:0]end_of_col_read; //assign to 39 or 19
logic [5:0] end_of_col_write; 

logic [8:0] col_addr;
logic [7:0] row_addr;
logic [7:0] col_addr_W;
logic [7:0] row_addr_W;

always_comb begin
	
	end_of_col_read=6'd0;
	col_addr=9'd0;
	row_addr=8'd0;
	SRAM_read_addr=18'd0;
	
	end_of_col_write=6'd0;
	col_addr_W=8'd0;
	row_addr_W=8'd0;
	SRAM_write_addr=18'd0;
	
	if (((m2_state==S_m2_lead_in_FS) && step_counter<=8'd63) 
				|| ((m2_state==S_m2_CS_FS) && step_counter%4==3 && step_counter!=8'd127 && step_counter!=8'd131) ||
				 ((m2_state==S_m2_CS_FS) && step_counter%4==0 &&step_counter!=8'd128)|| m2_state==S_m2_CS_FS_dummy_read)begin
	
		end_of_col_read=((base_read_addr==18'd76800)? 6'd39: 6'd19);
		col_addr={col_block_counter,sample_counter[2:0]};
		row_addr={row_block_counter,sample_counter[5:3]};
		SRAM_read_addr=(base_read_addr==18'd76800)? ({2'd0,row_addr,8'd0}+{4'd0,row_addr,6'd0}+{9'd0,col_addr}+base_read_addr):
													({3'd0,row_addr,7'd0}+{5'd0,row_addr,5'd0}+{9'd0,col_addr}+base_read_addr);
	end
	else begin
		if ((m2_state==S_m2_lead_out_WS && (step_counter%4==0 && step_counter!=8'd0)) 
				|| (m2_state==S_m2_CT_WS  && step_counter%4==0 && step_counter!=8'd0))begin
				
			end_of_col_write=((base_write_addr==18'd0)? 6'd39: 6'd19);
			col_addr_W={col_block_counter_W,sample_counter[1:0]};
			row_addr_W={row_block_counter_W,sample_counter[4:2]};
			SRAM_write_addr=(base_write_addr==18'd0)? ({3'd0,row_addr_W,7'd0}+{5'd0,row_addr_W,5'd0}+{10'd0,col_addr_W}+base_write_addr):
												({4'd0,row_addr_W,6'd0}+{6'd0,row_addr_W,4'd0}+{10'd0,col_addr_W}+base_write_addr);
		end
	end
end
								

always_ff @ (posedge CLOCK_50 or negedge Resetn) begin
	if (~Resetn) begin
		//sample counter, col block and row block counters for read
		sample_counter<=6'd0;
		col_block_counter<=6'd0;
		row_block_counter<=5'd0;
		
		//first read addr of pre-IDCT addr
		base_read_addr<=18'd76800;
		
		//col block and row block counters for write
		col_block_counter_W<=6'd0;
		row_block_counter_W<=5'd0;
		
		//first write addr
		base_write_addr<=18'd0;
		
		
	end
	else begin
		if (start==1'b1)begin
			
			if (((m2_state==S_m2_lead_in_FS) && step_counter<=8'd63) 
				|| ((m2_state==S_m2_CS_FS) && step_counter%4==3 && step_counter!=8'd127&& step_counter!=8'd131) ||
				 ((m2_state==S_m2_CS_FS) && step_counter%4==0 &&step_counter!=8'd128)||m2_state==S_m2_CS_FS_dummy_read)begin
			
				sample_counter<=sample_counter+6'd1;
				if (sample_counter==6'd63)begin
					if (col_block_counter<end_of_col_read) begin
						col_block_counter<=col_block_counter+6'd1;
					end
					else begin
						col_block_counter<=6'd0;
						row_block_counter<=row_block_counter+5'd1;
						if (row_block_counter==5'd29)begin
							base_read_addr<=(base_read_addr==18'd153600)?18'd192000:18'd153600;
							row_block_counter<=5'd0;
							
							sample_counter<=6'd0;
						end
						
					end
				end
			end
			else begin
				if ((m2_state==S_m2_lead_out_WS && (step_counter%4==0 && step_counter!=8'd0)) 
				|| (m2_state==S_m2_CT_WS && step_counter%4==0 && step_counter!=8'd0))begin
				
				sample_counter<=sample_counter+6'd1;
				if (sample_counter==6'd31)begin
					sample_counter<=6'd0;
					
					if (col_block_counter_W<end_of_col_write) begin
						col_block_counter_W<=col_block_counter_W+6'd1;
					end
					else begin
						col_block_counter_W<=6'd0;
						row_block_counter_W<=row_block_counter_W+5'd1;
						if (row_block_counter_W==5'd29)begin
						
							base_write_addr<=(base_write_addr==18'd38400)?18'd57600:18'd38400;
							row_block_counter_W<=5'd0;
							
							sample_counter<=6'd0;
						end
						
					end
				end
			end
			
			
		end
	
		
	end
end 

end

endmodule