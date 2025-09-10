module Letter_cm_display (
    input i_en,
    input [12:0] i_H_Cont,
    input [12:0] i_V_Cont,
    input [12:0] i_x,
    input [12:0] i_y,
    output reg o_valid
);

parameter WIDTH = 21;
parameter HEIGHT = 15;

wire [WIDTH*HEIGHT-1:0] cm;
reg [WIDTH*HEIGHT-1:0] index;

assign cm = 315'b000000000000000000000_000000000000000000000_000000000000000000000_000000000000000000000_000011110110110111000_000100000111011001000_000100000110010001000_001000000100010001000_001000000100010001000_001100100100110010000_000111000100100011000_000000000000000000000_000000000000000000000_000000000000000000000_000000000000000000000;

always @(*) begin

    index = (WIDTH*HEIGHT - ( (i_V_Cont-i_y)*WIDTH+(i_H_Cont-i_x)+1 ));

    // valid
    if (i_en && i_H_Cont-i_x >= 0 && i_H_Cont-i_x < WIDTH && i_V_Cont-i_y >= 0 && i_V_Cont-i_y < HEIGHT) begin
        o_valid = cm[index];
    end else begin
        o_valid = 0;
    end
end

endmodule