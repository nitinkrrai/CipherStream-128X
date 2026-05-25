module sub_bytes (
    input  wire [127:0] data_in,
    output wire [127:0] data_out
);

    genvar i;
    generate
        
        for (i = 0; i < 16; i = i + 1) begin : gen_sbox
            sbox_8bit u_sbox (
                .in_byte (data_in[(i*8)+7 : i*8]),
                .out_byte(data_out[(i*8)+7 : i*8])
            );
        end
    endgenerate

endmodule