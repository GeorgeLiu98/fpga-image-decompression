`ifndef DEFINE_STATE

// for top state - we have more states than needed
typedef enum logic [2:0] {
	S_IDLE,
	S_UART_RX,
	S_Milestone_1,
	S_Milestone_2
} top_state_type;

typedef enum logic [1:0] {
	S_RXC_IDLE,
	S_RXC_SYNC,
	S_RXC_ASSEMBLE_DATA,
	S_RXC_STOP_BIT
} RX_Controller_state_type;

typedef enum logic [2:0] {
	S_US_IDLE,
	S_US_STRIP_FILE_HEADER_1,
	S_US_STRIP_FILE_HEADER_2,
	S_US_START_FIRST_BYTE_RECEIVE,
	S_US_WRITE_FIRST_BYTE,
	S_US_START_SECOND_BYTE_RECEIVE,
	S_US_WRITE_SECOND_BYTE
} UART_SRAM_state_type;

typedef enum logic [3:0] {
	S_VS_WAIT_NEW_PIXEL_ROW,
	S_VS_NEW_PIXEL_ROW_DELAY_1,
	S_VS_NEW_PIXEL_ROW_DELAY_2,
	S_VS_NEW_PIXEL_ROW_DELAY_3,
	S_VS_NEW_PIXEL_ROW_DELAY_4,
	S_VS_NEW_PIXEL_ROW_DELAY_5,
	S_VS_FETCH_PIXEL_DATA_0,
	S_VS_FETCH_PIXEL_DATA_1,
	S_VS_FETCH_PIXEL_DATA_2,
	S_VS_FETCH_PIXEL_DATA_3
} VGA_SRAM_state_type;

typedef enum logic [4:0] {
	S_m2_lead_in_FS,
	S_m2_lead_in_CT,
	S_m2_CS_FS_dummy_read,
	S_m2_CS_FS,
	S_m2_CT_WS_dummy_read,
	S_m2_CT_WS,
	S_m2_lead_out_CS,
	S_m2_lead_out_WS,
	S_m2_dummy_lead_out_CS
} m2_state_type;

typedef enum logic [5:0] {
	S_m1_IDLE,
	S_lead_in_1,
	S_lead_in_2,
	S_lead_in_3,
	S_lead_in_4,
	S_lead_in_5,
	S_lead_in_6,
	S_lead_in_7,
	S_lead_in_8,
	S_lead_in_9,
	S_lead_in_10,
	S_lead_in_11,
	S_lead_in_12,
	S_lead_in_13,
	S_lead_in_14,
	S_lead_in_15,
	S_lead_in_16,
	S_lead_in_17,
	S_lead_in_18,
	S_lead_in_19,
	S_lead_in_20,
	S_lead_in_21,
	S_lead_in_22,
	S_common_0,
	S_common_1,
	S_common_2,
	S_common_3,
	S_common_4,
	S_common_5,
	S_common_6,
	S_common_7,
	S_common_8,
	S_common_9,
	S_common_10,
	S_common_11,
	S_lead_out_common_0,
	S_lead_out_common_1,
	S_lead_out_common_2,
	S_lead_out_common_3,
	S_lead_out_common_4,
	S_lead_out_common_5,
	S_lead_out_0,
	S_lead_out_1,
	S_lead_out_2,
	S_lead_out_3,
	S_lead_out_4,
	S_lead_out_5,
	S_lead_out_6,
	S_lead_out_7,
	S_lead_out_8,
	S_lead_out_9
}m1_state_type;

parameter 
   VIEW_AREA_LEFT = 160,
   VIEW_AREA_RIGHT = 480,
   VIEW_AREA_TOP = 120,
   VIEW_AREA_BOTTOM = 360;

`define DEFINE_STATE 1
`endif
