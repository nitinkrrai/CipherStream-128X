module aes_128_datapath (
    input  wire          clk,
    input  wire          rst_n,
    
    input  wire          enable,
    input  wire          data_valid_in,
    input  wire [127:0]  plaintext,
    
    input  wire [127:0]  new_key,
    input  wire          new_key_valid,
    
    output reg  [127:0]  ciphertext,
    output wire          ciphertext_valid,
    output wire          pipeline_empty
);

  
    reg [10:0] valid_pipeline;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) valid_pipeline <= 11'b0;
        else if (enable) valid_pipeline <= {valid_pipeline[9:0], data_valid_in};
    end
    assign pipeline_empty   = (valid_pipeline == 11'b0);
    assign ciphertext_valid = valid_pipeline[10];

    reg [127:0] active_key;
    reg [127:0] shadow_key;
    reg         key_update_pending;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            active_key <= 128'b0; shadow_key <= 128'b0; key_update_pending <= 1'b0;
        end else begin
            if (new_key_valid) begin
                shadow_key <= new_key; key_update_pending <= 1'b1; 
            end
            if (key_update_pending && pipeline_empty) begin
                active_key <= shadow_key; key_update_pending <= 1'b0;
            end
        end
    end


    wire [7:0] rcon [1:10];
    assign rcon[1] = 8'h01; assign rcon[2] = 8'h02; assign rcon[3] = 8'h04; 
    assign rcon[4] = 8'h08; assign rcon[5] = 8'h10; assign rcon[6] = 8'h20; 
    assign rcon[7] = 8'h40; assign rcon[8] = 8'h80; assign rcon[9] = 8'h1B; 
    assign rcon[10]= 8'h36;

   
    reg [127:0] stage_data [0:10];
    reg [127:0] stage_key  [0:10];

    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage_data[0] <= 128'b0;
            stage_key[0]  <= 128'b0;
        end else if (enable) begin
            stage_data[0] <= plaintext ^ active_key;
            stage_key[0]  <= active_key; 
        end
    end

   
    genvar i;
    generate
        for (i = 1; i < 10; i = i + 1) begin : gen_aes_rounds
            
          
            wire [127:0] next_key;
            key_expansion_round u_key_round (
                .key_in  (stage_key[i-1]), 
                .rcon      (rcon[i]),        
                .key_out (next_key)         
            );

            wire [127:0] next_data;
            aes_standard_round u_data_round (
                .state_in  (stage_data[i-1]),
                .round_key (next_key),            
                .state_out (next_data)
            );

            
            always @(posedge clk or negedge rst_n) begin
                if (!rst_n) begin
                    stage_data[i] <= 128'b0;
                    stage_key[i]  <= 128'b0;
                end else if (enable) begin
                    stage_data[i] <= next_data;
                    stage_key[i]  <= next_key;
                end
            end
        end
    endgenerate

  
    wire [127:0] final_key;
    key_expansion_round u_final_key_round (
        .key_in  (stage_key[9]),
        .rcon      (rcon[10]),
        .key_out (final_key)
    );

    wire [127:0] final_data;
    aes_final_round u_final_round (
        .state_in  (stage_data[9]),
        .round_key (final_key),
        .state_out (final_data)
    );

   
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)      ciphertext <= 128'b0;
        else if (enable) ciphertext <= final_data;
    end

endmodule