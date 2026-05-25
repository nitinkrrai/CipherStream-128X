module key_expansion_round (
    input  wire [127:0] key_in,
    input  wire [7:0]   rcon,
    output wire [127:0] key_out
);
    wire [31:0] w0, w1, w2, w3;
    wire [31:0] w4, w5, w6, w7;
    wire [31:0] rot_word, sub_word;

    
    assign {w0, w1, w2, w3} = key_in;

   
    assign rot_word = {w3[23:0], w3[31:24]};

   
    sbox_8bit sbox_0 (.in_byte(rot_word[31:24]), .out_byte(sub_word[31:24]));
    sbox_8bit sbox_1 (.in_byte(rot_word[23:16]), .out_byte(sub_word[23:16]));
    sbox_8bit sbox_2 (.in_byte(rot_word[15:8]),  .out_byte(sub_word[15:8]));
    sbox_8bit sbox_3 (.in_byte(rot_word[7:0]),   .out_byte(sub_word[7:0]));

    
    assign w4 = w0 ^ sub_word ^ {rcon, 24'h000000};
    assign w5 = w1 ^ w4;
    assign w6 = w2 ^ w5;
    assign w7 = w3 ^ w6;

   
    assign key_out = {w4, w5, w6, w7};

endmodule