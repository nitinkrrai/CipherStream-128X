module mix_column_32bit (
    input  wire [31:0] col_in,
    output wire [31:0] col_out
);
  
    wire [7:0] s0, s1, s2, s3;
    assign {s0, s1, s2, s3} = col_in;

    function [7:0] xtime;
        input [7:0] b;
        begin
           
            xtime = (b[7]) ? ({b[6:0], 1'b0} ^ 8'h1b) : {b[6:0], 1'b0};
        end
    endfunction

    
    assign col_out[31:24] = xtime(s0) ^ (xtime(s1) ^ s1) ^ s2 ^ s3; 
    
    
    assign col_out[23:16] = s0 ^ xtime(s1) ^ (xtime(s2) ^ s2) ^ s3; 
    
    
    assign col_out[15:8]  = s0 ^ s1 ^ xtime(s2) ^ (xtime(s3) ^ s3); 
    
    
    assign col_out[7:0]   = (xtime(s0) ^ s0) ^ s1 ^ s2 ^ xtime(s3); 

endmodule