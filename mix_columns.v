module mix_columns (
    input  wire [127:0] data_in,
    output wire [127:0] data_out
);

    genvar i;
    generate
        
        for (i = 0; i < 4; i = i + 1) begin : gen_mix_col
            mix_column_32bit u_mix_col (
               
                .col_in (data_in[(i*32)+31 : i*32]),
                .col_out(data_out[(i*32)+31 : i*32])
            );
        end
    endgenerate

endmodule