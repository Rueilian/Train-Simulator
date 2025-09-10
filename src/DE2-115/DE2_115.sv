`resetall
`timescale 1ns / 1ps
`default_nettype none
`include "../src/VGA/VGA_Param.h"

module DE2_115 (
	input CLOCK_50,
	input CLOCK2_50,
	input CLOCK3_50,
	input ENETCLK_25,
	input SMA_CLKIN,
	output SMA_CLKOUT,
	output [8:0] LEDG,
	output [17:0] LEDR,
	input [3:0] KEY,
	input [17:0] SW,
	output [6:0] HEX0,
	output [6:0] HEX1,
	output [6:0] HEX2,
	output [6:0] HEX3,
	output [6:0] HEX4,
	output [6:0] HEX5,
	output [6:0] HEX6,
	output [6:0] HEX7,
	output LCD_BLON,
	inout [7:0] LCD_DATA,
	output LCD_EN,
	output LCD_ON,
	output LCD_RS,
	output LCD_RW,
	output UART_CTS,
	input UART_RTS,
	input UART_RXD,
	output UART_TXD,
	inout PS2_CLK,
	inout PS2_DAT,
	inout PS2_CLK2,
	inout PS2_DAT2,
	output SD_CLK,
	inout SD_CMD,
	inout [3:0] SD_DAT,
	input SD_WP_N,
	output [7:0] VGA_B,
	output VGA_BLANK_N,
	output VGA_CLK,
	output [7:0] VGA_G,
	output VGA_HS,
	output [7:0] VGA_R,
	output VGA_SYNC_N,
	output VGA_VS,
	input AUD_ADCDAT,
	inout AUD_ADCLRCK,
	inout AUD_BCLK,
	output AUD_DACDAT,
	inout AUD_DACLRCK,
	output AUD_XCK,
	output EEP_I2C_SCLK,
	inout EEP_I2C_SDAT,
	output I2C_SCLK,
	inout I2C_SDAT,

	output ENET0_GTX_CLK,
	input ENET0_INT_N,
	output ENET0_MDC,
	input ENET0_MDIO,
	output ENET0_RST_N,
	input ENET0_RX_CLK,
	input ENET0_RX_COL,
	input ENET0_RX_CRS,
	input [3:0] ENET0_RX_DATA,
	input ENET0_RX_DV,
	input ENET0_RX_ER,
	input ENET0_TX_CLK,
	output [3:0] ENET0_TX_DATA,
	output ENET0_TX_EN,
	output ENET0_TX_ER,
	input ENET0_LINK100,
	output ENET1_GTX_CLK,
	input ENET1_INT_N,
	output ENET1_MDC,
	input ENET1_MDIO,
	output ENET1_RST_N,
	input ENET1_RX_CLK,
	input ENET1_RX_COL,
	input ENET1_RX_CRS,
	input [3:0] ENET1_RX_DATA,
	input ENET1_RX_DV,
	input ENET1_RX_ER,
	input ENET1_TX_CLK,
	output [3:0] ENET1_TX_DATA,
	output ENET1_TX_EN,
	output ENET1_TX_ER,
	input ENET1_LINK100,
	input TD_CLK27,
	input [7:0] TD_DATA,
	input TD_HS,
	output TD_RESET_N,
	input TD_VS,
	inout [15:0] OTG_DATA,
	output [1:0] OTG_ADDR,
	output OTG_CS_N,
	output OTG_WR_N,
	output OTG_RD_N,
	input OTG_INT,
	output OTG_RST_N,
	input IRDA_RXD,
	output [12:0] DRAM_ADDR,
	output [1:0] DRAM_BA,
	output DRAM_CAS_N,
	output DRAM_CKE,
	output DRAM_CLK,
	output DRAM_CS_N,
	inout [31:0] DRAM_DQ,
	output [3:0] DRAM_DQM,
	output DRAM_RAS_N,
	output DRAM_WE_N,
	output [19:0] SRAM_ADDR,
	output SRAM_CE_N,
	inout [15:0] SRAM_DQ,
	output SRAM_LB_N,
	output SRAM_OE_N,
	output SRAM_UB_N,
	output SRAM_WE_N,
	output [22:0] FL_ADDR,
	output FL_CE_N,
	inout [7:0] FL_DQ,
	output FL_OE_N,
	output FL_RST_N,
	input FL_RY,
	output FL_WE_N,
	output FL_WP_N,
	inout [35:0] GPIO,
	input HSMC_CLKIN_P1,
	input HSMC_CLKIN_P2,
	input HSMC_CLKIN0,
	output HSMC_CLKOUT_P1,
	output HSMC_CLKOUT_P2,
	output HSMC_CLKOUT0,
	inout [3:0] HSMC_D,
	input [16:0] HSMC_RX_D_P,
	output [16:0] HSMC_TX_D_P,
	inout [6:0] EX_IO
);

//**************************************************PLL**************************************************//

// All Clock
logic CLK_100K, CLK_25M, CLK_40M, sdram_ctrl_clk, clk_100M, clk_120M, clk_75M, clk_800k;

PLL pll0 (
	.clk_clk (CLOCK_50),
	.reset_reset_n (KEY[3]),
	.altpll_100k_clk(CLK_100K)
);

sdram_pll u6(
	.inclk0(CLOCK2_50),
	.c0(sdram_ctrl_clk),
	.c1(DRAM_CLK),
	.c2(),            //25M
	.c3(CLK_25M),     //25M 
	.c4(CLK_40M)      //40M 	
);

VGA_pll pll(
	.clk_clk(CLOCK_50),
	.clk_100m_clk(clk_100M),
	.clk_120m_clk(clk_120M),
	.clk_75m_clk(clk_75M),
	.clk_800k_clk(clk_800k),
	.reset_reset_n(KEY[0])
);

//**************************************************ADS**************************************************//

logic [15:0] data;
logic channel;

ads1115_controller ads0(
    .i_clk_100k(CLK_100K),     // system clock (100 kHz)
    .i_rst_n(KEY[3]),        // active low reset
    .io_sda(GPIO[1]),         // I2C data line (bidirectional)
    .o_scl(GPIO[0]),          // I2C clock line
    .o_adc_data(data),     // 16-bit conversion result
    .o_adc_chn(channel)       // indicates adc channel
);

//*************************************************SPEED*************************************************//

logic [1:0] forward;	// 0: backward, 1: stop, 3: forward
logic [12:0] speed;

SpeedCtrl sc0(
    .i_clk(CLK_100K),
    .i_rst_n(KEY[0]),
    .i_channel(channel),
    .i_data(data),
    .o_speed(speed),
    .o_forward(forward)
);

// test
logic [7:0] leftstick_w, leftstick_r, rightstick_w, rightstick_r;


hex_display user_speed_display4(
	.enable(1),
	.in(rightstick_r[3:0]),
	.out(HEX4)
);
hex_display user_speed_display5(
	.enable(1),
	.in(rightstick_r[7:4]),
	.out(HEX5)
);
hex_display user_speed_display6(
	.enable(1),
	.in(leftstick_r[3:0]),
	.out(HEX6)
);
hex_display user_speed_display7(
	.enable(1),
	.in(leftstick_r[7:4]),
	.out(HEX7)
);
always_comb begin
	leftstick_w = leftstick_r;
	rightstick_w = rightstick_r;
	if (channel == 0) begin
		leftstick_w = data[15:8];
	end else begin
		rightstick_w = data[15:8];
	end
end
always_ff @(posedge CLK_100K or negedge KEY[0]) begin
	if (~KEY[0]) begin
		leftstick_r <= 0;
		rightstick_r <= 0;
	end else begin
		leftstick_r <= leftstick_w;
		rightstick_r <= rightstick_w;
	end
end

hex_display user_speed_display0(
	.enable(1),
	.in(speed[12:4]%10),
	.out(HEX0)
);
hex_display user_speed_display1(
	.enable(1),
	.in((speed[12:4]/10)%10),
	.out(HEX1)
);
hex_display user_speed_display2(
	.enable(1),
	.in(speed[12:4]/100),
	.out(HEX2)
);
hex_display user_speed_display3(
	.enable(1),
	.in({2'b0, forward}),
	.out(HEX3)
);

//**************************************************VGA**************************************************//


// Clock and reset
logic [9:0] i_VGA_R, i_VGA_G, i_VGA_B;
logic	[9:0]	oVGA_R;   				//	VGA Red[9:0]
logic	[9:0]	oVGA_G;	 				//	VGA Green[9:0]
logic	[9:0]	oVGA_B;   				//	VGA Blue[9:0]
logic VGA_request;
logic VGA_CTRL_CLK;
// logic play_clk;
logic			DLY_RST_0;
logic			DLY_RST_1;
logic			DLY_RST_2;
logic			DLY_RST_3;
logic			DLY_RST_4;

assign  VGA_CTRL_CLK = ~VGA_CLK;
assign	UART_TXD = UART_RXD;

//fetch the high 8 bits
assign  VGA_R = oVGA_R[9:2];
assign  VGA_G = oVGA_G[9:2];
assign  VGA_B = oVGA_B[9:2];

`ifdef VGA_640x480p60
	assign VGA_CLK = CLK_25M;
`else
	assign VGA_CLK = CLK_40M;
`endif

assign i_VGA_R = Read_DATA2[9:0] ; 						 //R_out;
assign i_VGA_G = {Read_DATA1[14:10], Read_DATA2[14:10]}; //G_out;
assign i_VGA_B = Read_DATA1[9:0]; 						 //B_out;

//Reset module
Reset_Delay	u2(
	.iCLK(CLOCK2_50),
	.iRST(KEY[0]),
	.oRST_0(DLY_RST_0),
	.oRST_1(DLY_RST_1),
	.oRST_2(DLY_RST_2),
	.oRST_3(DLY_RST_3),
	.oRST_4(DLY_RST_4)
);

VGA_Controller vga_inst(
    //	Host Side
	.oRequest(VGA_request),
	.iRed(i_VGA_R),
	.iGreen(i_VGA_G),
	.iBlue(i_VGA_B),
	//	VGA Side
	.oVGA_R(oVGA_R),
	.oVGA_G(oVGA_G),
	.oVGA_B(oVGA_B),
	.oVGA_H_SYNC(VGA_HS),
	.oVGA_V_SYNC(VGA_VS),
	.oVGA_SYNC(VGA_SYNC_N),
	.oVGA_BLANK(VGA_BLANK_N),
	//	Control Signal
	.iCLK(VGA_CTRL_CLK),
	.iRST_N(DLY_RST_2),

	// Detected Variables
    .i_speed(speed),
	.i_forward(forward[1]),
	.i_distance_digit(distance_pack_r)
	// .i_prev_distance_digit(prev_distance_pack_r)
	// .i_distance(dist_value_r)
);

// Distance Recieve Count
logic [3:0] distance_digit_cnt;
logic [3:0] distance [0:5];
logic [23:0] distance_pack_r, distance_pack_w;

always_comb begin
	distance_pack_w = distance_pack_r;
	if (distance_digit_cnt == 1) begin
		distance_pack_w = {distance[0], distance[1], distance[2], distance[3], distance[4], distance[5]};
	end
end

always @(posedge ethernet_clk or negedge KEY[0]) begin
	if (~KEY[0]) begin
		distance_digit_cnt <= 0;
		distance[0] <= 4'b0;
		distance[1] <= 4'b0;
		distance[2] <= 4'b0;
		distance[3] <= 4'b0;
		distance[4] <= 4'b0;
		distance[5] <= 4'b0;
		distance_pack_r <= 0;
	end
	else begin
		distance_digit_cnt <= distance_digit_cnt;
		distance[0] <= distance[0];
		distance[1] <= distance[1];
		distance[2] <= distance[2];
		distance[3] <= distance[3];
		distance[4] <= distance[4];
		distance[5] <= distance[5];
		distance_pack_r <= distance_pack_w;

		if (label_sending && ethernet_valid) begin
			if (distance_digit_cnt < 8) begin
                distance_digit_cnt <= distance_digit_cnt + 1;
				if (distance_digit_cnt >= 2) begin
                	distance[distance_digit_cnt-2] <= ethernet_data;
				end
            end
		end

        if (ethernet_last) distance_digit_cnt <= 0;
	end
end

//**************************************************ETH**************************************************//

// Internal 125 MHz clock
logic ethernet_clk;
logic ethernet_rst;

logic pll_rst;
logic pll_locked;

logic ethernet_clk90;
logic ethernet_valid, ethernet_last;
logic [7:0] ethernet_data;
logic [31:0] ethernet_dest_ip;

// ethernet parser
logic [7:0] test_len;
logic [7:0] test_last_byte, test_first_byte;
logic [7:0] eth_channel_R, eth_channel_G, eth_channel_B;
logic 		eth_valid;

//************************************************SDRAM**************************************************//
logic SDRAM_W_clk;
logic SDRAM_W_en;
logic Read;
logic [9:0] SDRAM_W_B, SDRAM_W_G, SDRAM_W_R;
logic [15:0] Read_DATA1, Read_DATA2;

assign SDRAM_W_clk = ethernet_clk;
assign SDRAM_W_en = eth_valid;
assign Read = VGA_request;
assign SDRAM_W_B = {eth_channel_B, 2'b0};
assign SDRAM_W_G = {eth_channel_G, 2'b0};
assign SDRAM_W_R = {eth_channel_R, 2'b0};
//*******************************************************************************************************//

assign pll_rst = ~KEY[3];

altpll #(
    .bandwidth_type("AUTO"),
    .clk0_divide_by(2),
    .clk0_duty_cycle(50),
    .clk0_multiply_by(5),
    .clk0_phase_shift("0"),
    .clk1_divide_by(2),
    .clk1_duty_cycle(50),
    .clk1_multiply_by(5),
    .clk1_phase_shift("2000"),
    .compensate_clock("CLK0"),
    .inclk0_input_frequency(20000),
    .intended_device_family("Cyclone IV E"),
    .operation_mode("NORMAL"),
    .pll_type("AUTO"),
    .port_activeclock("PORT_UNUSED"),
    .port_areset("PORT_USED"),
    .port_clkbad0("PORT_UNUSED"),
    .port_clkbad1("PORT_UNUSED"),
    .port_clkloss("PORT_UNUSED"),
    .port_clkswitch("PORT_UNUSED"),
    .port_configupdate("PORT_UNUSED"),
    .port_fbin("PORT_UNUSED"),
    .port_inclk0("PORT_USED"),
    .port_inclk1("PORT_UNUSED"),
    .port_locked("PORT_USED"),
    .port_pfdena("PORT_UNUSED"),
    .port_phasecounterselect("PORT_UNUSED"),
    .port_phasedone("PORT_UNUSED"),
    .port_phasestep("PORT_UNUSED"),
    .port_phaseupdown("PORT_UNUSED"),
    .port_pllena("PORT_UNUSED"),
    .port_scanaclr("PORT_UNUSED"),
    .port_scanclk("PORT_UNUSED"),
    .port_scanclkena("PORT_UNUSED"),
    .port_scandata("PORT_UNUSED"),
    .port_scandataout("PORT_UNUSED"),
    .port_scandone("PORT_UNUSED"),
    .port_scanread("PORT_UNUSED"),
    .port_scanwrite("PORT_UNUSED"),
    .port_clk0("PORT_USED"),
    .port_clk1("PORT_USED"),
    .port_clk2("PORT_UNUSED"),
    .port_clk3("PORT_UNUSED"),
    .port_clk4("PORT_UNUSED"),
    .port_clk5("PORT_UNUSED"),
    .port_clkena0("PORT_UNUSED"),
    .port_clkena1("PORT_UNUSED"),
    .port_clkena2("PORT_UNUSED"),
    .port_clkena3("PORT_UNUSED"),
    .port_clkena4("PORT_UNUSED"),
    .port_clkena5("PORT_UNUSED"),
    .port_extclk0("PORT_UNUSED"),
    .port_extclk1("PORT_UNUSED"),
    .port_extclk2("PORT_UNUSED"),
    .port_extclk3("PORT_UNUSED"),
    .self_reset_on_loss_lock("ON"),
    .width_clock(5)
)
altpll_component (
    .areset(pll_rst),
    .inclk({1'b0, CLOCK_50}),
    .clk({ethernet_clk90, ethernet_clk}),
    .locked(pll_locked),
    .activeclock(),
    .clkbad(),
    .clkena({6{1'b1}}),
    .clkloss(),
    .clkswitch(1'b0),
    .configupdate(1'b0),
    .enable0(),
    .enable1(),
    .extclk(),
    .extclkena({4{1'b1}}),
    .fbin(1'b1),
    .fbmimicbidir(),
    .fbout(),
    .fref(),
    .icdrclk(),
    .pfdena(1'b1),
    .phasecounterselect({4{1'b1}}),
    .phasedone(),
    .phasestep(1'b1),
    .phaseupdown(1'b1),
    .pllena(1'b1),
    .scanaclr(1'b0),
    .scanclk(1'b0),
    .scanclkena(1'b1),
    .scandata(1'b0),
    .scandataout(),
    .scandone(),
    .scanread(1'b0),
    .scanwrite(1'b0),
    .sclkout0(),
    .sclkout1(),
    .vcooverrange(),
    .vcounderrange()
);

sync_reset #(
    .N(4)
)
sync_reset_inst (
    .clk(ethernet_clk),
    .rst(~pll_locked),
    .out(ethernet_rst)
);

Ethernet_connection #(
    .TARGET("ALTERA")
)
ethernet_inst (
    /*
     * Clock: 125MHz
     * Synchronous reset
     */
    .i_clk(ethernet_clk),
    .i_clk90(ethernet_clk90),
    .rst(ethernet_rst),

	// output
	.o_udp_rx_valid(ethernet_valid),
	.o_udp_rx_data(ethernet_data),
	.o_udp_rx_last(ethernet_last),
	.o_ethernet_dest_ip(ethernet_dest_ip),

    .ledg(LEDG),
    .ledr(LEDR),

    /*
     * Ethernet: 1000BASE-T RGMII
     */
    .phy0_rx_clk(ENET0_RX_CLK),
    .phy0_rxd(ENET0_RX_DATA),
    .phy0_rx_ctl(ENET0_RX_DV),
    .phy0_tx_clk(ENET0_GTX_CLK),
    .phy0_txd(ENET0_TX_DATA),
    .phy0_tx_ctl(ENET0_TX_EN),
    .phy0_reset_n(ENET0_RST_N),
    .phy0_int_n(ENET0_INT_N),

	// Speed
	.speed_control({forward[1], speed})
);

// speed label
logic [9:0] packet_cnt;
logic label_sending, eth_parser_valid;

assign label_sending = (packet_cnt == 10'd635);
assign eth_parser_valid = ethernet_valid && (~label_sending);

always_ff @(posedge ethernet_clk or negedge KEY[0]) begin
	if (~KEY[0]) begin
		packet_cnt <= 10'b0;
	end
	else begin
		packet_cnt <= packet_cnt;
		if (ethernet_last)           packet_cnt <= packet_cnt + 1;
		if (packet_cnt == 10'd635 && ethernet_last) packet_cnt <= 10'b0;
	end
end

UDP_parser udp_inst(
    .i_clk(ethernet_clk),
    .i_rst_n(!ethernet_rst),
    .i_udp_rx_valid(eth_parser_valid),
    .i_udp_rx_last(ethernet_last),
    .i_udp_rx_data(ethernet_data),
    .o_channel_B(eth_channel_B),
    .o_channel_G(eth_channel_G),
    .o_channel_R(eth_channel_R),
    .o_valid(eth_valid)
);

//SDRam Read and Write as Frame Buffer
Sdram_Control u7(	//	HOST Side						
	.RESET_N(KEY[0]),
	.CLK(clk_100M),

	//FIFO Write Side 1
	.WR1_DATA({1'b0, SDRAM_W_G[9:5], SDRAM_W_B}), // 
	.WR1(SDRAM_W_en),
	.WR1_ADDR(23'h000000),
	`ifdef VGA_640x480p60
		.WR1_MAX_ADDR(23'h000000+640*480/2),
		.WR1_LENGTH(8'h50),
	`else
		.WR1_MAX_ADDR(23'h000000+800*600/2),
		.WR1_LENGTH(8'h80),
	`endif							
	.WR1_LOAD(!DLY_RST_0),
	.WR1_CLK(SDRAM_W_clk),

							
	//	FIFO Write Side 2
	.WR2_DATA({1'b0, SDRAM_W_G[4:0], SDRAM_W_R}), // 
	.WR2(SDRAM_W_en),
	.WR2_ADDR(23'h200000),
	`ifdef VGA_640x480p60
		.WR2_MAX_ADDR(23'h200000+640*480/2),
		.WR2_LENGTH(8'h50),			
	`else							
		.WR2_MAX_ADDR(23'h200000+800*600/2),
		.WR2_LENGTH(8'h80),
	`endif	
	.WR2_LOAD(!DLY_RST_0),
	.WR2_CLK(SDRAM_W_clk),

	//	FIFO Read Side 1
	.RD1_DATA(Read_DATA1),
	.RD1(Read),
	.RD1_ADDR(23'h000000),
	`ifdef VGA_640x480p60
		.RD1_MAX_ADDR(23'h000000+640*480/2), 
		.RD1_LENGTH(8'h50),
	`else
		.RD1_MAX_ADDR(23'h000000+800*600/2),
		.RD1_LENGTH(8'h80),
	`endif
	.RD1_LOAD(!DLY_RST_0),
	.RD1_CLK(~VGA_CTRL_CLK),
	// .RD1_CLK(~play_clk),
							
	//	FIFO Read Side 2
	.RD2_DATA(Read_DATA2),
	.RD2(Read),
	.RD2_ADDR(23'h200000),
	`ifdef VGA_640x480p60
		.RD2_MAX_ADDR(23'h200000+640*480/2), 
		.RD2_LENGTH(8'h50),
	`else
		.RD2_MAX_ADDR(23'h200000+800*600/2),
		.RD2_LENGTH(8'h80),
	`endif
	.RD2_LOAD(!DLY_RST_0),
	.RD2_CLK(~VGA_CTRL_CLK),
	// .RD2_CLK(~play_clk),
							
	//	SDRAM Side
	.SA(DRAM_ADDR),
	.BA(DRAM_BA),
	.CS_N(DRAM_CS_N),
	.CKE(DRAM_CKE),
	.RAS_N(DRAM_RAS_N),
	.CAS_N(DRAM_CAS_N),
	.WE_N(DRAM_WE_N),
	.DQ(DRAM_DQ),
	.DQM(DRAM_DQM)
);

endmodule

`resetall
