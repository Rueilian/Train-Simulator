module SpeedCtrl (
    input i_clk,
    input i_rst_n,
    input i_channel,
    input [15:0] i_data,
    output [12:0] o_speed,
    output [1:0] o_forward
);

logic [1:0] forward_r, forward_w;	// 0: backward, 1: stop, 3: forward
logic [12:0] speed_r, speed_w;
logic [15:0] speeddelay_cnt_r, speeddelay_cnt_w;

assign o_speed = speed_r;
assign o_forward = forward_r;

always_comb begin

	if (speeddelay_cnt_r >= 10000) begin
		speeddelay_cnt_w = 0;
	end else begin
		speeddelay_cnt_w = speeddelay_cnt_r + 1;
	end

	speed_w = speed_r;

	if (i_channel == 1 && speeddelay_cnt_r >= 10000 && (forward_r == 3 || forward_r == 0)) begin
		case (i_data[15:8])
			8'h4E, 8'h4D, 8'h4C, 8'h4B: begin if (speed_r >= 8) begin speed_w = speed_r - 8; end else begin speed_w = 0; end end
			8'h4A, 8'h49, 8'h48, 8'h47: begin if (speed_r >= 6) begin speed_w = speed_r - 6; end else begin speed_w = 0; end end
			8'h46, 8'h45, 8'h44, 8'h43: begin if (speed_r >= 5) begin speed_w = speed_r - 5; end else begin speed_w = 0; end end
			8'h42, 8'h41, 8'h40, 8'h3F: begin if (speed_r >= 4) begin speed_w = speed_r - 4; end else begin speed_w = 0; end end
			8'h3E, 8'h3D, 8'h3C, 8'h3B: begin if (speed_r >= 3) begin speed_w = speed_r - 3; end else begin speed_w = 0; end end
			8'h3A, 8'h39, 8'h38, 8'h37: begin if (speed_r >= 2) begin speed_w = speed_r - 2; end else begin speed_w = 0; end end
			8'h36, 8'h35, 8'h34, 8'h33: begin if (speed_r >= 1) begin speed_w = speed_r - 1; end else begin speed_w = 0; end end
			8'h32, 8'h31, 8'h30, 8'h2F: begin if (speed_r <= 8191) begin speed_w = speed_r ; end else begin speed_w = 8191; end end
			8'h2E, 8'h2D, 8'h2C, 8'h2B: begin if (speed_r <= 8190) begin speed_w = speed_r + 1; end else begin speed_w = 8191; end end
			8'h2A, 8'h29, 8'h28, 8'h27: begin if (speed_r <= 8189) begin speed_w = speed_r + 2; end else begin speed_w = 8191; end end
			8'h26, 8'h25, 8'h24, 8'h23: begin if (speed_r <= 8188) begin speed_w = speed_r + 3; end else begin speed_w = 8191; end end
			8'h22, 8'h21, 8'h20, 8'h1F, 8'h1E, 8'h1D: begin if (speed_r <= 8187) begin speed_w = speed_r + 4; end else begin speed_w = 8191; end end
		endcase
	end

	forward_w = forward_r;

	if (i_channel == 0 && speeddelay_cnt_r >= 10000 && speed_r == 0) begin
		if (i_data[15:8] >= 8'h32 && i_data[15:8] <= 8'h36 && forward_r == 3) begin
			forward_w = 2;
		end else if (i_data[15:8] >= 8'h32 && i_data[15:8] <= 8'h36 && forward_r == 0) begin
			forward_w = 1;
		end else if (i_data[15:8] > 8'h36) begin
			forward_w = 3;
		end else if (i_data[15:8] < 8'h32) begin
			forward_w = 0;
		end
	end
end

always_ff @(posedge i_clk or negedge i_rst_n) begin
	if (~i_rst_n) begin
		forward_r <= 2;
		speed_r <= 0;
		speeddelay_cnt_r <= 0;
	end
	else begin
		forward_r <= forward_w;
		speed_r <= speed_w;
		speeddelay_cnt_r <= speeddelay_cnt_w;
	end
end

endmodule