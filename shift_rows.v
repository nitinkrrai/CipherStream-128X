module shift_rows (
    input  wire [127:0] data_in,
    output wire [127:0] data_out
);

    
    assign data_out = {
     
        data_in[127:120], 
        data_in[ 87: 80], 
        data_in[ 47: 40], 
        data_in[  7:  0], 

      
        data_in[ 95: 88],
        data_in[ 55: 48], 
        data_in[ 15:  8], 
        data_in[103: 96], 

        
        data_in[ 63: 56], 
        data_in[ 23: 16], 
        data_in[111:104], 
        data_in[ 71: 64], 

      
        data_in[ 31: 24], 
        data_in[119:112], 
        data_in[ 79: 72], 
        data_in[ 39: 32]  
    };

endmodule