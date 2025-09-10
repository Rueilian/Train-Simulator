module ads1115_controller (
    input  logic        i_clk_100k,     // system clock (100 kHz)
    input  logic        i_rst_n,        // active low reset
    inout  logic        io_sda,         // I2C data line (bidirectional)
    output logic        o_scl,          // I2C clock line
    output logic [15:0] o_adc_data,     // 16-bit conversion result
    output logic        o_adc_chn       // indicates adc channel
);


parameter ADDR_W     = 8'b1001_0000; // 0x48, 0
parameter ADDR_R     = 8'b1001_0001; // 0x49, 1
parameter REG_CONFIG = 8'b0000_0001; // 0x01
parameter REG_CONV   = 8'b0000_0000; // 0x00
parameter DATA0_1    = 8'b1100_0001; // 0xC1
parameter DATA0_2    = 8'b1000_1011; // 0x8B
parameter DATA1_1    = 8'b1101_0001; // 0xD1
parameter DATA1_2    = 8'b1000_1011; // 0x8B

parameter A_START = 2'b00;
parameter A_WRITE = 2'b01;
parameter A_READ = 2'b10;
parameter A_STOP = 2'b11;

parameter S_INIT = 0;
parameter S_CONFIG1 = 1;
parameter S_CONFIG2 = 2;
parameter S_CONFIG3 = 3;
parameter S_CONFIG4 = 4;
parameter S_SEL_CONFIG1 = 5;
parameter S_SEL_CONFIG2 = 6;
parameter S_READ_CONFIG1 = 7;
parameter S_READ_CONFIG2 = 8;
parameter S_READ_CONFIG3 = 9;
parameter S_SEL_CONV1 = 10;
parameter S_SEL_CONV2 = 11;
parameter S_READ_CONV1 = 12;
parameter S_READ_CONV2 = 13;
parameter S_READ_CONV3 = 14;

assign o_scl = (scl_sel_r) ? i_clk_100k : scl_r;
assign io_sda = (sda_sel_r) ? sda_r : 1'bz; // 1: output, 0: input
assign o_adc_chn = ~chn_sel_r;
assign o_adc_data = output_r;

logic [3:0] state_r, state_w;
logic [1:0] action_r, action_w;
logic [3:0] cnt_r, cnt_w;
logic       sda_r, sda_w;
logic       scl_r, scl_w;
logic       scl_sel_r, scl_sel_w; // select between i_clk_100k and sda_r
logic       sda_sel_r, sda_sel_w; // select between input and output
logic       chn_sel_r, chn_sel_w; // select between channel 0 and channel 1
logic [15:0] value_r, value_w;
logic [15:0] output_r, output_w;

always_comb begin
    state_w = state_r;
    action_w = action_r;
	 output_w = output_r;
	 chn_sel_w = chn_sel_r;
    
    // FSM and action
    case (state_r)
        S_INIT: begin
            if (action_r == A_START && cnt_r == 0) begin
                action_w = A_WRITE;
            end else if (action_r == A_WRITE && cnt_r == 9) begin;
                action_w = A_STOP;
            end else if (action_r == A_STOP && cnt_r == 1) begin
                state_w = S_CONFIG1;
                action_w = A_START;
            end
        end
        S_CONFIG1: begin
            if (action_r == A_START && cnt_r == 0) begin
                action_w = A_WRITE;
            end else if (action_r == A_WRITE && cnt_r == 9) begin;
                state_w = S_CONFIG2;
                action_w = A_WRITE;
            end
        end
        S_CONFIG2: begin
            if (action_r == A_WRITE && cnt_r == 9) begin;
                state_w = S_CONFIG3;
                action_w = A_WRITE;
            end
        end
        S_CONFIG3: begin
            if (action_r == A_WRITE && cnt_r == 9) begin;
                state_w = S_CONFIG4;
                action_w = A_WRITE;
            end
        end
        S_CONFIG4: begin
            if (action_r == A_WRITE && cnt_r == 9) begin;
                action_w = A_STOP;
            end else if (action_r == A_STOP && cnt_r == 1) begin
                state_w = S_SEL_CONFIG1;
                action_w = A_START;
            end
        end
        S_SEL_CONFIG1: begin
            if (action_r == A_START && cnt_r == 0) begin
                action_w = A_WRITE;
            end else if (action_r == A_WRITE && cnt_r == 9) begin;
                state_w = S_SEL_CONFIG2;
                action_w = A_WRITE;
            end
        end
        S_SEL_CONFIG2: begin
            if (action_r == A_WRITE && cnt_r == 9) begin;
                action_w = A_STOP;
            end else if (action_r == A_STOP && cnt_r == 1) begin
                state_w = S_READ_CONFIG1;
                action_w = A_START;
            end
        end
        S_READ_CONFIG1: begin
            if (action_r == A_START && cnt_r == 0) begin
                action_w = A_WRITE;
            end else if (action_r == A_WRITE && cnt_r == 9) begin;
                state_w = S_READ_CONFIG2;
                action_w = A_READ;
            end
        end
        S_READ_CONFIG2: begin
            if (action_r == A_READ && cnt_r == 9) begin;
                state_w = S_READ_CONFIG3;
                action_w = A_READ;
            end
        end

        S_READ_CONFIG3: begin
            if (action_r == A_READ && cnt_r == 9) begin;
                action_w = A_STOP;
            end else if (action_r == A_STOP && cnt_r == 1 && chn_sel_r == 0 && value_r == 16'hC18B) begin
                state_w = S_SEL_CONV1;
                action_w = A_START;
            end else if (action_r == A_STOP && cnt_r == 1 && chn_sel_r == 0 && value_r != 16'hC18B) begin
                state_w = S_SEL_CONFIG1;
                action_w = A_START;
            end else if (action_r == A_STOP && cnt_r == 1 && chn_sel_r == 1 && value_r == 16'hD18B) begin
                state_w = S_SEL_CONV1;
                action_w = A_START;
            end else if (action_r == A_STOP && cnt_r == 1 && chn_sel_r == 1 && value_r != 16'hD18B) begin
                state_w = S_SEL_CONFIG1;
                action_w = A_START;
            end
        end

        S_SEL_CONV1: begin
            if (action_r == A_START && cnt_r == 0) begin
                action_w = A_WRITE;
            end else if (action_r == A_WRITE && cnt_r == 9) begin;
                state_w = S_SEL_CONV2;
                action_w = A_WRITE;
            end
        end
        S_SEL_CONV2: begin
            if (action_r == A_WRITE && cnt_r == 9) begin;
                action_w = A_STOP;
            end else if (action_r == A_STOP && cnt_r == 1) begin
                state_w = S_READ_CONV1;
                action_w = A_START;
            end
        end
        S_READ_CONV1: begin
            if (action_r == A_START && cnt_r == 0) begin
                action_w = A_WRITE;
            end else if (action_r == A_WRITE && cnt_r == 9) begin;
                state_w = S_READ_CONV2;
                action_w = A_READ;
            end
        end
        S_READ_CONV2: begin
            if (action_r == A_READ && cnt_r == 9) begin;
                state_w = S_READ_CONV3;
                action_w = A_READ;
            end
        end

        S_READ_CONV3: begin
            if (action_r == A_READ && cnt_r == 9) begin;
                action_w = A_STOP;
            end else if (action_r == A_STOP && cnt_r == 1) begin
                state_w = S_CONFIG1;
                action_w = A_START;
                output_w = value_r;
                chn_sel_w = ~chn_sel_r;
            end
        end
        
    endcase
end

always_comb begin
    // sda and scl
	scl_w = scl_r;
    sda_w = sda_r;
    scl_sel_w = scl_sel_r;
    sda_sel_w = sda_sel_r;
    cnt_w = cnt_r + 1;
	value_w = value_r;
	 
    case (action_r)   
        A_START: begin // 1 cycle
            if (cnt_r == 0) sda_w = 1'b0;
            if (cnt_r == 0) cnt_w = 0;
        end 

        A_WRITE: begin // 10 cycle
            // sda
            if (cnt_r < 8) begin
                sda_sel_w = 1'b1; // output
                case (state_r)
                    S_INIT: sda_w = ADDR_W[7 - cnt_r];
                    S_CONFIG1: sda_w = ADDR_W[7 - cnt_r];
                    S_CONFIG2: sda_w = REG_CONFIG[7 - cnt_r];
                    S_CONFIG3: sda_w = (chn_sel_r)? DATA1_1[7 - cnt_r]: DATA0_1[7 - cnt_r];
                    S_CONFIG4: sda_w = (chn_sel_r)? DATA1_2[7 - cnt_r]: DATA0_2[7 - cnt_r];
                    S_SEL_CONFIG1: sda_w = ADDR_W[7 - cnt_r];
                    S_SEL_CONFIG2: sda_w = REG_CONFIG[7 - cnt_r];
                    S_READ_CONFIG1: sda_w = ADDR_R[7 - cnt_r];
                    S_SEL_CONV1: sda_w = ADDR_W[7 - cnt_r];
                    S_SEL_CONV2: sda_w = REG_CONV[7 - cnt_r];
                    S_READ_CONV1: sda_w = ADDR_R[7 - cnt_r];
                endcase
            end else if (cnt_r == 8) begin
                sda_sel_w = 1'b0; // input
                sda_w = 1'b1;
            end else if (cnt_r == 9) begin
                sda_sel_w = 1'b1; // output
                sda_w = 1'b0;
            end

            // scl
            if (cnt_r == 0) scl_sel_w = 1'b1; // i_clk_100k
            else if (cnt_r == 9) begin
                scl_sel_w = 1'b0; // scl_r
                scl_w = 1'b0;
            end 

            // cnt
            if (cnt_r == 9) cnt_w = 0;
        end

        A_READ: begin //10 cycle
            // sda
            if (cnt_r < 8) begin
                sda_sel_w = 1'b0; // input
                sda_w = 1'b1;
            end else if (cnt_r == 8) begin
                sda_sel_w = 1'b1; // output
                sda_w = 1'b0;
            end 

            // read
            if (cnt_r >= 1 && cnt_r <= 8) begin
                case (state_r)
                    S_READ_CONFIG2: value_w[16 - cnt_r] = io_sda;
                    S_READ_CONFIG3: value_w[8 - cnt_r] = io_sda;
                    S_READ_CONV2: value_w[16 - cnt_r] = io_sda;
                    S_READ_CONV3: value_w[8 - cnt_r] = io_sda;
                endcase
            end

            // scl
            if (cnt_r == 0) scl_sel_w = 1'b1; // i_clk_100k
            else if (cnt_r == 9) begin
                scl_sel_w = 1'b0; // scl_r
                scl_w = 1'b0;
            end 

            // cnt
            if (cnt_r == 9) cnt_w = 0;
        end

        A_STOP: begin // 2 cycle
            // sda
            if (cnt_r == 1) sda_w = 1'b1;

            // scl
            if (cnt_r == 0) scl_w = 1'b1;

            // cnt
            if (cnt_r == 1) cnt_w = 0;
        end

    endcase
end

always_ff @(negedge i_clk_100k or negedge i_rst_n) begin
    if (!i_rst_n) begin
        state_r <= S_INIT;
        action_r <= A_START;
        scl_r <= 1'b1;
        sda_r <= 1'b1;
        cnt_r <= 4'd0;
        scl_sel_r <= 1'b0;
        sda_sel_r <= 1'b1;
        chn_sel_r <= 1'b0;
        value_r <= 16'b0;
        output_r <= 16'b0;

    end else begin
        state_r <= state_w;
        action_r <= action_w;
        scl_r <= scl_w;
        sda_r <= sda_w;
        cnt_r <= cnt_w;
        scl_sel_r <= scl_sel_w;
        sda_sel_r <= sda_sel_w;
        chn_sel_r <= chn_sel_w;
        value_r <= value_w;
        output_r <= output_w;
    end
end

endmodule
