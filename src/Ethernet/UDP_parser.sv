module UDP_parser( 
    input i_clk, 
    input i_rst_n, 
    input i_udp_rx_valid, 
    input i_udp_rx_last, 
    input [7:0] i_udp_rx_data, 
    output [7:0] o_channel_B, 
    output [7:0] o_channel_G, 
    output [7:0] o_channel_R, 
    output o_valid // this is the valid signal for the RGB data
);

// parameters
localparam S_IDLE = 1'b0;
localparam S_READ = 1'b1;

// regs and wires
logic state_r, state_w;
logic valid_r, valid_w;
logic [1:0] cnt_r, cnt_w;
logic [23:0] RGB_data_r, RGB_data_w;

// wire assignment
assign o_channel_B = RGB_data_r[23:16];
assign o_channel_G = RGB_data_r[15:8];
assign o_channel_R = RGB_data_r[7:0];
assign o_valid = valid_r;

// finite state machine
always_comb begin
    state_w = state_r;
    case (state_r)
        S_IDLE : if (i_udp_rx_valid) state_w = S_READ;
        S_READ : if (i_udp_rx_last)  state_w = S_IDLE;
    endcase
end

// combinational
always_comb begin
    RGB_data_w = RGB_data_r;
    cnt_w = cnt_r;
    valid_w = 1'b0;

    case (state_r)
        S_IDLE : begin
            if (i_udp_rx_valid) begin
                cnt_w = cnt_r + 1;
            end
            else begin
                RGB_data_w = 24'h0;
                cnt_w = 2'b0;
            end
        end
        S_READ : begin
            if (i_udp_rx_valid) begin
                cnt_w = cnt_r + 1;
                if (cnt_r == 2'd2) begin
                    valid_w = 1'b1;
                    cnt_w = 2'd0;
                end
                if (i_udp_rx_last) cnt_w = 0;
            end
        end
    endcase

    if (i_udp_rx_valid) begin
        case (cnt_r)
            2'd0: begin
                RGB_data_w[23:16] = i_udp_rx_data;
            end
            2'd1: begin
                RGB_data_w[15:8] = i_udp_rx_data;
            end
            2'd2: begin
                RGB_data_w[7:0] = i_udp_rx_data;
            end
        endcase
    end
end

// sequential
always_ff @(posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n) begin
        state_r <= S_IDLE;
        RGB_data_r <= 24'h0;
        cnt_r <= 2'b0;
        valid_r <= 1'b0;
    end
    else begin
        state_r <= state_w;
        RGB_data_r <= RGB_data_w;
        cnt_r <= cnt_w;
        valid_r <= valid_w;
    end
end

endmodule
