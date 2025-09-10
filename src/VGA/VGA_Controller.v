// --------------------------------------------------------------------
// Copyright (c) 2010 by Terasic Technologies Inc. 
// --------------------------------------------------------------------
//
// Permission:
//
//   Terasic grants permission to use and modify this code for use
//   in synthesis for all Terasic Development Boards and Altera Development 
//   Kits made by Terasic.  Other use of this code, including the selling 
//   ,duplication, or modification of any portion is strictly prohibited.
//
// Disclaimer:
//
//   This VHDL/Verilog or C/C++ source code is intended as a design reference
//   which illustrates how these types of functions can be implemented.
//   It is the user's responsibility to verify their design for
//   consistency and functionality through the use of formal
//   verification methods.  Terasic provides no warranty regarding the use 
//   or functionality of this code.
//
// --------------------------------------------------------------------
//           
//                     Terasic Technologies Inc
//                     356 Fu-Shin E. Rd Sec. 1. JhuBei City,
//                     HsinChu County, Taiwan
//                     302
//
//                     web: http://www.terasic.com/
//                     email: support@terasic.com
//
// --------------------------------------------------------------------
//
// Major Functions:	VGA_Controller
//
// --------------------------------------------------------------------
//
// Revision History :
// --------------------------------------------------------------------
//   Ver  :| Author            :| Mod. Date :| Changes Made:
//   V1.0 :| Johnny FAN Peli Li:| 22/07/2010:| Initial Revision
// --------------------------------------------------------------------

module	VGA_Controller(	//	Host Side
						iRed,
						iGreen,
						iBlue,
						oRequest,
						//	VGA Side
						oVGA_R,
						oVGA_G,
						oVGA_B,
						oVGA_H_SYNC,
						oVGA_V_SYNC,
						oVGA_SYNC,
						oVGA_BLANK,

						//	Control Signal
						iCLK,
						iRST_N,
						// iZOOM_MODE_SW
                        i_speed,
						i_forward,
						i_distance_digit
						// i_prev_distance_digit
						// i_distance
							);
`include "VGA_Param.h"

`ifdef VGA_640x480p60
//	Horizontal Parameter	( Pixel )
parameter	H_SYNC_CYC	=	96;
parameter	H_SYNC_BACK	=	48;
parameter	H_SYNC_ACT	=	640;	
parameter	H_SYNC_FRONT=	16;
parameter	H_SYNC_TOTAL=	800;

//	Virtical Parameter		( Line )
parameter	V_SYNC_CYC	=	2;
parameter	V_SYNC_BACK	=	33;
parameter	V_SYNC_ACT	=	480;	
parameter	V_SYNC_FRONT=	10;
parameter	V_SYNC_TOTAL=	525;

`elsif VGA_1920x1080p60 // 148.5M Hz
//    Horizontal Parameter    ( Pixel )
parameter H_SYNC_CYC   = 44;
parameter H_SYNC_BACK  = 148;
parameter H_SYNC_ACT   = 1920;    
parameter H_SYNC_FRONT = 88;
parameter H_SYNC_TOTAL = 2200;

//    Virtical Parameter        ( Line )
parameter V_SYNC_CYC   = 5;
parameter V_SYNC_BACK  = 36;
parameter V_SYNC_ACT   = 1080;
parameter V_SYNC_FRONT = 4;
parameter V_SYNC_TOTAL = 1125; 


`elsif VGA_1280x720p60 // 74.25M Hz
//    Horizontal Parameter    ( Pixel )
parameter H_SYNC_CYC   = 40;
parameter H_SYNC_BACK  = 220;
parameter H_SYNC_ACT   = 1280;    
parameter H_SYNC_FRONT = 110;
parameter H_SYNC_TOTAL = 1650;

//    Virtical Parameter        ( Line )
parameter V_SYNC_CYC   = 5;
parameter V_SYNC_BACK  = 20;
parameter V_SYNC_ACT   = 720;
parameter V_SYNC_FRONT = 5;
parameter V_SYNC_TOTAL = 750; 

`else
 // SVGA_800x600p60
////	Horizontal Parameter	( Pixel )
parameter	H_SYNC_CYC	=	128;         //Peli
parameter	H_SYNC_BACK	=	88;
parameter	H_SYNC_ACT	=	800;	
parameter	H_SYNC_FRONT=	40;
parameter	H_SYNC_TOTAL=	1056;
//	Virtical Parameter		( Line )
parameter	V_SYNC_CYC	=	4;
parameter	V_SYNC_BACK	=	23;
parameter	V_SYNC_ACT	=	600;	
parameter	V_SYNC_FRONT=	1;
parameter	V_SYNC_TOTAL=	628;

`endif
//	Start Offset
parameter	X_START		=	H_SYNC_CYC+H_SYNC_BACK;
parameter	Y_START		=	V_SYNC_CYC+V_SYNC_BACK;
//	Host Side
input		[9:0]	iRed;
input		[9:0]	iGreen;
input		[9:0]	iBlue;
output	reg			oRequest;
//	VGA Side
output	reg	[9:0]	oVGA_R;
output	reg	[9:0]	oVGA_G;
output	reg	[9:0]	oVGA_B;
output	reg			oVGA_H_SYNC;
output	reg			oVGA_V_SYNC;
output	reg			oVGA_SYNC;
output	reg			oVGA_BLANK;

reg		[7:0]	mVGA_R;
reg		[7:0]	mVGA_G;
reg		[7:0]	mVGA_B;
reg					mVGA_H_SYNC;
reg					mVGA_V_SYNC;
wire				mVGA_SYNC;
wire				mVGA_BLANK;

//	Control Signal
input				iCLK;
input				iRST_N;

// Detected Variables
input [12:0] i_speed;
input        i_forward;
input [23:0] i_distance_digit;
// input [23:0] i_prev_distance_digit;
// input [23:0] i_distance;

//	Internal Registers and Wires
reg		[12:0]		H_Cont;
reg		[12:0]		V_Cont;

wire	[12:0]		v_mask;

parameter IMG_HEIGHT = 360;
parameter V_IMG_HEIGHT_OFFSET = (V_SYNC_ACT - IMG_HEIGHT) / 2;

// Speed

reg [12:0] speed_r, speed_w;
wire [20:0] speed_factor;
wire [3:0] speed_digit0, speed_digit1, speed_digit2;
reg speed_en_2, speed_en_1, speed_en_0;
wire speed_display_valid_2, speed_display_valid_1, speed_display_valid_0;

parameter SPEED_BG_L = 536 + H_SYNC_CYC + H_SYNC_BACK;
parameter SPEED_BG_U = 324 + V_SYNC_CYC + V_SYNC_BACK + V_IMG_HEIGHT_OFFSET;
parameter SPEED_BG_R = 600 + H_SYNC_CYC + H_SYNC_BACK;
parameter SPEED_BG_D = 355 + V_SYNC_CYC + V_SYNC_BACK + V_IMG_HEIGHT_OFFSET;

parameter SPEED2_X = 540 + H_SYNC_CYC + H_SYNC_BACK;
parameter SPEED2_Y = 325 + V_SYNC_CYC + V_SYNC_BACK + V_IMG_HEIGHT_OFFSET;
parameter SPEED1_X = 558 + H_SYNC_CYC + H_SYNC_BACK;
parameter SPEED1_Y = 325 + V_SYNC_CYC + V_SYNC_BACK + V_IMG_HEIGHT_OFFSET;
parameter SPEED0_X = 576 + H_SYNC_CYC + H_SYNC_BACK;
parameter SPEED0_Y = 325 + V_SYNC_CYC + V_SYNC_BACK + V_IMG_HEIGHT_OFFSET;

Speed_display speed2(
	.i_en(speed_en_2),
    .i_H_Cont(H_Cont),
    .i_V_Cont(V_Cont),
    .i_x(SPEED2_X),
    .i_y(SPEED2_Y),
    .i_speed(speed_digit2),
    .o_valid(speed_display_valid_2)
);
Speed_display speed1(
	.i_en(speed_en_1),
    .i_H_Cont(H_Cont),
    .i_V_Cont(V_Cont),
    .i_x(SPEED1_X),
    .i_y(SPEED1_Y),
    .i_speed(speed_digit1),
    .o_valid(speed_display_valid_1)
);
Speed_display speed0(
	.i_en(speed_en_0),
    .i_H_Cont(H_Cont),
    .i_V_Cont(V_Cont),
    .i_x(SPEED0_X),
    .i_y(SPEED0_Y),
    .i_speed(speed_digit0),
    .o_valid(speed_display_valid_0)
);

assign v_mask = 13'd0 ;//iZOOM_MODE_SW ? 13'd0 : 13'd26;
assign mVGA_BLANK	=	mVGA_H_SYNC & mVGA_V_SYNC;
assign mVGA_SYNC	=	1'b0;

assign speed_digit0 = speed_r[12:4]%10;
assign speed_digit1 = (speed_r[12:4]/10)%10;
assign speed_digit2 = speed_r[12:4]/100;

assign speed_factor = speed_r * 8'd255;

// Distance

reg [23:0] distance_pack;
reg correct_stop_r, correct_stop_w;
wire [3:0] distance_digit[0:5];
reg distance_en_5, distance_en_4, distance_en_3, distance_en_2, distance_en_1, distance_en_0;
reg distance_minus_5, distance_minus_4, distance_minus_3, distance_minus_2, distance_minus_1, distance_minus_0;
wire distance_digit_valid_5, distance_digit_valid_4, distance_digit_valid_3, distance_digit_valid_2, distance_digit_valid_1, distance_digit_valid_0;
wire letter_cm_valid;

parameter DIST_BG_L = 16 + H_SYNC_CYC + H_SYNC_BACK;
parameter DIST_BG_U = V_SYNC_CYC + V_SYNC_BACK + V_IMG_HEIGHT_OFFSET - 40;
parameter DIST_BG_R = 147 + H_SYNC_CYC + H_SYNC_BACK;
parameter DIST_BG_D = V_SYNC_CYC + V_SYNC_BACK + V_IMG_HEIGHT_OFFSET - 6;

parameter DIST5_X = 16 + H_SYNC_CYC + H_SYNC_BACK;
parameter DIST5_Y = V_SYNC_CYC + V_SYNC_BACK + V_IMG_HEIGHT_OFFSET - 40;
parameter DIST4_X = 34 + H_SYNC_CYC + H_SYNC_BACK;
parameter DIST4_Y = V_SYNC_CYC + V_SYNC_BACK + V_IMG_HEIGHT_OFFSET - 40;
parameter DIST3_X = 52 + H_SYNC_CYC + H_SYNC_BACK;
parameter DIST3_Y = V_SYNC_CYC + V_SYNC_BACK + V_IMG_HEIGHT_OFFSET - 40;
parameter DIST2_X = 70 + H_SYNC_CYC + H_SYNC_BACK;
parameter DIST2_Y = V_SYNC_CYC + V_SYNC_BACK + V_IMG_HEIGHT_OFFSET - 40;
parameter DIST1_X = 88 + H_SYNC_CYC + H_SYNC_BACK;
parameter DIST1_Y = V_SYNC_CYC + V_SYNC_BACK + V_IMG_HEIGHT_OFFSET - 40;
parameter DIST0_X = 106 + H_SYNC_CYC + H_SYNC_BACK;
parameter DIST0_Y = V_SYNC_CYC + V_SYNC_BACK + V_IMG_HEIGHT_OFFSET - 40;
parameter LETTER_CM_X = 126 + H_SYNC_CYC + H_SYNC_BACK;
parameter LETTER_CM_Y = V_SYNC_CYC + V_SYNC_BACK + V_IMG_HEIGHT_OFFSET - 30;

assign distance_digit[5] = i_distance_digit[23:20];
assign distance_digit[4] = i_distance_digit[19:16];
assign distance_digit[3] = i_distance_digit[15:12];
assign distance_digit[2] = i_distance_digit[11:8];
assign distance_digit[1] = i_distance_digit[7:4];
assign distance_digit[0] = i_distance_digit[3:0];

Distance_display distance5(
	.i_en(distance_en_5),
	.i_minus(distance_minus_5),
    .i_H_Cont(H_Cont),
    .i_V_Cont(V_Cont),
    .i_x(DIST5_X),
    .i_y(DIST5_Y),
    .i_distance(distance_digit[5]),
    .o_valid(distance_digit_valid_5)
);
Distance_display distance4(
	.i_en(distance_en_4),
	.i_minus(distance_minus_4),
    .i_H_Cont(H_Cont),
    .i_V_Cont(V_Cont),
    .i_x(DIST4_X),
    .i_y(DIST4_Y),
    .i_distance(distance_digit[4]),
    .o_valid(distance_digit_valid_4)
);
Distance_display distance3(
	.i_en(distance_en_3),
	.i_minus(distance_minus_3),
    .i_H_Cont(H_Cont),
    .i_V_Cont(V_Cont),
    .i_x(DIST3_X),
    .i_y(DIST3_Y),
    .i_distance(distance_digit[3]),
    .o_valid(distance_digit_valid_3)
);
Distance_display distance2(
	.i_en(distance_en_2),
	.i_minus(distance_minus_2),
    .i_H_Cont(H_Cont),
    .i_V_Cont(V_Cont),
    .i_x(DIST2_X),
    .i_y(DIST2_Y),
    .i_distance(distance_digit[2]),
    .o_valid(distance_digit_valid_2)
);
Distance_display distance1(
	.i_en(distance_en_1),
	.i_minus(distance_minus_1),
    .i_H_Cont(H_Cont),
    .i_V_Cont(V_Cont),
    .i_x(DIST1_X),
    .i_y(DIST1_Y),
    .i_distance(distance_digit[1]),
    .o_valid(distance_digit_valid_1)
);
Distance_display distance0(
	.i_en(distance_en_0),
	.i_minus(distance_minus_0),
    .i_H_Cont(H_Cont),
    .i_V_Cont(V_Cont),
    .i_x(DIST0_X),
    .i_y(DIST0_Y),
    .i_distance(distance_digit[0]),
    .o_valid(distance_digit_valid_0)
);
Letter_cm_display letter_cm0(
	.i_en(1),
    .i_H_Cont(H_Cont),
    .i_V_Cont(V_Cont),
    .i_x(LETTER_CM_X),
    .i_y(LETTER_CM_Y),
    .o_valid(letter_cm_valid)
);

// Time
reg [7:0] second_r, second_w;
reg [7:0] initial_second_r, initial_second_w;
reg second_sign_r, second_sign_w;
reg [25:0] second_cnt_r, second_cnt_w;
reg time_minus_en, time_en_2, time_en_1, time_en_0;
reg time_minus_2, time_minus_1, time_minus_0;
wire time_minus_valid, time_digit_valid_2, time_digit_valid_1, time_digit_valid_0;
wire [3:0] time_digit2, time_digit1, time_digit0;
wire [7:0] time_color;

parameter TIME_BG_L = 552 + H_SYNC_CYC + H_SYNC_BACK;
parameter TIME_BG_U = V_SYNC_CYC + V_SYNC_BACK + V_IMG_HEIGHT_OFFSET - 40;
parameter TIME_BG_R = 635 + H_SYNC_CYC + H_SYNC_BACK;
parameter TIME_BG_D = V_SYNC_CYC + V_SYNC_BACK + V_IMG_HEIGHT_OFFSET - 10;

parameter TIMEMINUS_X = 552 + H_SYNC_CYC + H_SYNC_BACK;
parameter TIMEMINUS_Y = V_SYNC_CYC + V_SYNC_BACK + V_IMG_HEIGHT_OFFSET - 40;
parameter TIME2_X = 570 + H_SYNC_CYC + H_SYNC_BACK;
parameter TIME2_Y = V_SYNC_CYC + V_SYNC_BACK + V_IMG_HEIGHT_OFFSET - 40;
parameter TIME1_X = 588 + H_SYNC_CYC + H_SYNC_BACK;
parameter TIME1_Y = V_SYNC_CYC + V_SYNC_BACK + V_IMG_HEIGHT_OFFSET - 40;
parameter TIME0_X = 606 + H_SYNC_CYC + H_SYNC_BACK;
parameter TIME0_Y = V_SYNC_CYC + V_SYNC_BACK + V_IMG_HEIGHT_OFFSET - 40;

assign time_digit0 = second_r%10;
assign time_digit1 = (second_r/10)%10;
assign time_digit2 = second_r/100;

assign time_color = (second_r * 255) / initial_second_r;

Minus_display minus_time(
    .i_en(time_minus_en),
    .i_H_Cont(H_Cont),
    .i_V_Cont(V_Cont),
    .i_x(TIMEMINUS_X),
    .i_y(TIMEMINUS_Y),
    .o_valid(time_minus_valid)
);
Time_display time2(
	.i_en(time_en_2),
	.i_minus(time_minus_2),
    .i_H_Cont(H_Cont),
    .i_V_Cont(V_Cont),
    .i_x(TIME2_X),
    .i_y(TIME2_Y),
    .i_time(time_digit2),
    .o_valid(time_digit_valid_2)
);
Time_display time1(
	.i_en(time_en_1),
	.i_minus(time_minus_1),
    .i_H_Cont(H_Cont),
    .i_V_Cont(V_Cont),
    .i_x(TIME1_X),
    .i_y(TIME1_Y),
    .i_time(time_digit1),
    .o_valid(time_digit_valid_1)
);
Time_display time0(
	.i_en(time_en_0),
	.i_minus(time_minus_0),
    .i_H_Cont(H_Cont),
    .i_V_Cont(V_Cont),
    .i_x(TIME0_X),
    .i_y(TIME0_Y),
    .i_time(time_digit0),
    .o_valid(time_digit_valid_0)
);


always @(*) begin

	speed_w = i_speed;
	second_w = second_r;
	initial_second_w = initial_second_r;
	second_sign_w = second_sign_r;

    if (H_Cont >= X_START && H_Cont < X_START+H_SYNC_ACT && V_Cont >= Y_START+v_mask && V_Cont < Y_START+V_SYNC_ACT) begin

        mVGA_R = iRed[9:2];
        mVGA_G = iGreen[9:2];
        mVGA_B = iBlue[9:2];

		// Speed
		speed_en_2 = 1;
		speed_en_1 = 1;
		speed_en_0 = 1;

		if (H_Cont >= SPEED_BG_L && H_Cont < SPEED_BG_R && V_Cont >= SPEED_BG_U && V_Cont < SPEED_BG_D) begin
			mVGA_R = 0;
			mVGA_G = 0;
			mVGA_B = 0;
			if (speed_display_valid_2 || speed_display_valid_1 || speed_display_valid_0) begin
				if (speed_r < 13'd2048) begin
					mVGA_R = speed_factor[18:11];
					mVGA_G = 8'd255 - speed_factor[18:11];
					mVGA_B = 0;
				end else begin
					mVGA_R = 8'd255;
					mVGA_G = 0;
					mVGA_B = 0;
				end
			end

			if (speed_digit2 == 4'd0 && speed_digit1 == 4'd0) begin
				speed_en_2 = 0;
				speed_en_1 = 0;
			end else if (speed_digit2 == 4'd0) begin
				speed_en_2 = 0;
			end
		end

		distance_en_5 = 1;
		distance_en_4 = 1;
		distance_en_3 = 1;
		distance_en_2 = 1;
		distance_en_1 = 1;
		distance_en_0 = 1;

		if (H_Cont >= DIST_BG_L && H_Cont < DIST_BG_R && V_Cont >= DIST_BG_U && V_Cont < DIST_BG_D ) begin
			if (distance_digit_valid_0 || distance_digit_valid_1 || distance_digit_valid_2 || distance_digit_valid_3 || distance_digit_valid_4 || distance_digit_valid_5 || letter_cm_valid) begin
				if (i_distance_digit <= 24'b001100000000) begin
					mVGA_R = 8'd0;
					mVGA_G = 8'd255;
					mVGA_B = 8'd0;
				end else begin
					mVGA_R = 8'd255;
					mVGA_G = 8'd255;
					mVGA_B = 8'd255;
				end
			end

			if (distance_digit[5] == 4'd0 && distance_digit[4] == 4'd0 && distance_digit[3] == 4'd0 && distance_digit[2] == 4'd0 && distance_digit[1] == 4'd0) begin
				distance_en_5 = 0;
				distance_en_4 = 0;
				distance_en_3 = 0;
				distance_en_2 = 0;
				distance_en_1 = 0;
			end else if (distance_digit[5] == 4'd0 && distance_digit[4] == 4'd0 && distance_digit[3] == 4'd0 && distance_digit[2] == 4'd0) begin
				distance_en_5 = 0;
				distance_en_4 = 0;
				distance_en_3 = 0;
				distance_en_2 = 0;
			end else if (distance_digit[5] == 4'd0 && distance_digit[4] == 4'd0 && distance_digit[3] == 4'd0) begin
				distance_en_5 = 0;
				distance_en_4 = 0;
				distance_en_3 = 0;
			end else if (distance_digit[5] == 4'd0 && distance_digit[4] == 4'd0) begin
				distance_en_5 = 0;
				distance_en_4 = 0;
			end else if (distance_digit[5] == 4'd0) begin
				distance_en_5 = 0;
			end
		end

		// Time
		second_cnt_w = second_cnt_r + 1;
		if (second_cnt_r >= 26'd25000000 && correct_stop_r == 0) begin
			second_cnt_w = 0;
			if (second_sign_r == 0) begin
				second_w = second_r - 1;
			end else begin
				second_w = second_r + 1;
			end
		end
		if (second_r == 0) begin
			second_sign_w = 1;
		end

		// Correct condition
		if (speed_r[12:4] == 0 && i_distance_digit <= 24'b001100000000) begin
			correct_stop_w = 1;
		end else if (correct_stop_r == 1 && i_distance_digit[19:16] > 4'd0 && speed_r[12:4] > 0) begin
			correct_stop_w = 0;
			second_w = i_distance_digit[23:20] * 30 + i_distance_digit[19:16] * 10 + 30;
			initial_second_w = i_distance_digit[23:20] * 30 + i_distance_digit[19:16] * 10 + 30;
			second_sign_w = 0;
			second_cnt_w = 0;
		end else begin
			correct_stop_w = correct_stop_r;
		end

		// if (correct_stop_r == 1 && i_distance_digit[19:16] > 4'd0 && speed_r[12:4] > 0) begin
		// end
		// if (distance_pack < i_distance) begin
		// 	second_w = i_distance_digit[23:20] * 100 + i_distance_digit[19:16] * 10 + i_distance_digit[15:12];
		// end

		time_minus_en = 0;
		time_en_2 = 1;
		time_en_1 = 1;
		time_en_0 = 1;
		time_minus_2 = 0;
		time_minus_1 = 0;
		time_minus_0 = 0;

		if (H_Cont >= TIME_BG_L && H_Cont < TIME_BG_R && V_Cont >= TIME_BG_U && V_Cont < TIME_BG_D) begin
			if (time_minus_valid || time_digit_valid_2 || time_digit_valid_1 || time_digit_valid_0) begin
				if (second_sign_r == 0) begin
					mVGA_R = 8'd255 - time_color;
					mVGA_G = time_color;
					mVGA_B = time_color;
				end else begin
					mVGA_R = 255;
					mVGA_G = 0;
					mVGA_B = 0;
				end
			end

			if (second_sign_r == 0) begin
				if (time_digit2 == 4'd0 && time_digit1 == 4'd0) begin
					time_en_2 = 0;
					time_en_1 = 0;
				end else if (time_digit2 == 4'd0) begin
					time_en_2 = 0;
				end
			end else begin
				if (time_digit2 == 4'd0 && time_digit1 == 4'd0) begin
					time_en_2 = 0;
					time_minus_1 = 1;
				end else if (time_digit2 == 4'd0) begin
					time_minus_2 = 1;
				end else begin
					time_minus_en = 1;
				end
			end
		end
    end else begin

        mVGA_R = 0;
        mVGA_G = 0;
        mVGA_B = 0;

		// speed enable
		speed_en_2 = 0;
		speed_en_1 = 0;
		speed_en_0 = 0;

		// distance enable
		distance_en_5 = 0;
		distance_en_4 = 0;
		distance_en_3 = 0;
		distance_en_2 = 0;
		distance_en_1 = 0;
		distance_en_0 = 0;

		// time
		time_en_2 = 0;
		time_en_1 = 0;
		time_en_0 = 0;
    end
end

// detected varible
always@(posedge iCLK or negedge iRST_N) begin
	if (!iRST_N) begin
		speed_r <= 0;
		distance_pack <= 0;
		second_r <= 0; //distance_pack_w[23:20] * 100 + distance_pack_w[19:16] * 10 + distance_pack_w[15:12];
		initial_second_r <= 255;
		second_sign_r <= 0;
		second_cnt_r <= 0;
		correct_stop_r <= 0;
	end else begin
		speed_r <= speed_w;
		distance_pack <= i_distance_digit; //distance_pack_w;
		second_r <= second_w;
		initial_second_r <= initial_second_w;
		second_sign_r <= second_sign_w;
		second_cnt_r <= second_cnt_w;
		correct_stop_r <= correct_stop_w;
	end
end

// VGA_SCREEN
always@(posedge iCLK or negedge iRST_N)
	begin
		if (!iRST_N)
			begin
				oVGA_R <= 0;
				oVGA_G <= 0;
                oVGA_B <= 0;
				oVGA_BLANK <= 0;
				oVGA_SYNC <= 0;
				oVGA_H_SYNC <= 0;
				oVGA_V_SYNC <= 0; 
			end
		else
			begin
				oVGA_R <= {mVGA_R,2'b0};
				oVGA_G <= {mVGA_G,2'b0};
                oVGA_B <= {mVGA_B,2'b0};
				oVGA_BLANK <= mVGA_BLANK;
				oVGA_SYNC <= mVGA_SYNC;
				oVGA_H_SYNC <= mVGA_H_SYNC;
				oVGA_V_SYNC <= mVGA_V_SYNC;				
			end               
	end



//	Pixel LUT Address Generator
always@(posedge iCLK or negedge iRST_N)
begin
	if(!iRST_N)
	oRequest	<=	0;
	else
	begin
		if(	H_Cont>=X_START-2 && H_Cont<X_START+H_SYNC_ACT-2 &&
			V_Cont>=Y_START && V_Cont<Y_START+V_SYNC_ACT )
		oRequest	<=	1;
		else
		oRequest	<=	0;
	end
end

//	H_Sync Generator, Ref. 40 MHz Clock
always@(posedge iCLK or negedge iRST_N)
begin
	if(!iRST_N)
	begin
		H_Cont		<=	0;
		mVGA_H_SYNC	<=	0;
	end
	else
	begin
		//	H_Sync Counter
		if( H_Cont < H_SYNC_TOTAL )
		H_Cont	<=	H_Cont+1;
		else
		H_Cont	<=	0;
		//	H_Sync Generator
		if( H_Cont < H_SYNC_CYC )
		mVGA_H_SYNC	<=	0;
		else
		mVGA_H_SYNC	<=	1;
	end
end

//	V_Sync Generator, Ref. H_Sync
always@(posedge iCLK or negedge iRST_N)
begin
	if(!iRST_N)
	begin
		V_Cont		<=	0;
		mVGA_V_SYNC	<=	0;
	end
	else
	begin
		//	When H_Sync Re-start
		if(H_Cont==0)
		begin
			//	V_Sync Counter
			if( V_Cont < V_SYNC_TOTAL )
			V_Cont	<=	V_Cont+1;
			else
			V_Cont	<=	0;
			//	V_Sync Generator
			if(	V_Cont < V_SYNC_CYC )
			mVGA_V_SYNC	<=	0;
			else
			mVGA_V_SYNC	<=	1;
		end
	end
end

endmodule
