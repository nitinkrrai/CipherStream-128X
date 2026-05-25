`timescale 1ns / 1ps

module tb_aes_core();

    
    reg          clk;
    reg          rst_n;
    
   
    reg          enable;
    reg          data_valid_in;
    reg  [127:0] plaintext;
    
   
    reg  [127:0] new_key;
    reg          new_key_valid;
    
   
    wire [127:0] ciphertext;
    wire         ciphertext_valid;
    wire         pipeline_empty;

   
    aes_128_datapath u_dut (
        .clk(clk),
        .rst_n(rst_n),
        .enable(enable),
        .data_valid_in(data_valid_in),
        .plaintext(plaintext),
        .new_key(new_key),
        .new_key_valid(new_key_valid),
        .ciphertext(ciphertext),
        .ciphertext_valid(ciphertext_valid),
        .pipeline_empty(pipeline_empty)
    );

   
    initial begin
        clk = 0;
        forever #2 clk = ~clk; 
    end

   
    initial begin
      
        rst_n = 0;
        enable = 0;
        data_valid_in = 0;
        plaintext = 128'b0;
        new_key = 128'b0;
        new_key_valid = 0;

        
        #10;
        rst_n = 1;
        #10;
        
        @(negedge clk);
        
       
        new_key = 128'h00010203_04050607_08090a0b_0c0d0e0f;
        new_key_valid = 1'b1;
        @(negedge clk);
        new_key_valid = 1'b0; 
        
        
        @(negedge clk);


        plaintext     = 128'h00112233_44556677_8899aabb_ccddeeff;
        data_valid_in = 1'b1;
        enable        = 1'b1; 
        
        @(negedge clk);
        
        data_valid_in = 1'b0; 

     
        wait(ciphertext_valid == 1'b1);
        
       
        #1; 
        
        
        $display("--------------------------------------------------");
        $display("TEST RESULTS");
        $display("--------------------------------------------------");
        $display("Expected: 69c4e0d86a7b0430d8cdb78070b4c55a");
        $display("Actual:   %h", ciphertext);
        if (ciphertext == 128'h69c4e0d8_6a7b0430_d8cdb780_70b4c55a)
            $display("STATUS:   PASS");
        else
            $display("STATUS:   FAIL");
        $display("--------------------------------------------------");
        
        #20;
        $finish;
    end

endmodule