module aes_final_round (
    input  wire [127:0] state_in,
    input  wire [127:0] round_key,
    output wire [127:0] state_out
);
    wire [127:0] sub_bytes_out;
    wire [127:0] shift_rows_out;

    sub_bytes u_sub_bytes (
        .data_in(state_in),
        .data_out(sub_bytes_out)
    );

    shift_rows u_shift_rows (
        .data_in(sub_bytes_out),
        .data_out(shift_rows_out)
    );

    assign state_out = shift_rows_out ^ round_key;

endmodule