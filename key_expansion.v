module key_expansion (
    input  wire [127:0] initial_key,
    output wire [1407:0] expanded_keys 
);
    
    
    wire [127:0] round_keys[0:10];
    
  
    assign round_keys[0] = initial_key;


    wire [7:0] rcon [1:10];
    assign rcon[1]  = 8'h01;
    assign rcon[2]  = 8'h02;
    assign rcon[3]  = 8'h04;
    assign rcon[4]  = 8'h08;
    assign rcon[5]  = 8'h10;
    assign rcon[6]  = 8'h20;
    assign rcon[7]  = 8'h40;
    assign rcon[8]  = 8'h80;
    assign rcon[9]  = 8'h1b;
    assign rcon[10] = 8'h36;

    
    genvar i;
    generate
        for (i = 1; i <= 10; i = i + 1) begin : gen_key_exp
            key_expansion_round u_key_round (
                .key_in(round_keys[i-1]),
                .rcon(rcon[i]),
                .key_out(round_keys[i])
            );
        end
    endgenerate

  
  
  
    assign expanded_keys = {
        round_keys[10], round_keys[9], round_keys[8], round_keys[7],
        round_keys[6],  round_keys[5], round_keys[4], round_keys[3],
        round_keys[2],  round_keys[1], round_keys[0]
    };

endmodule