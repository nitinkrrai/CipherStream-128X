`timescale 1ns / 1ps

module tb_axi_aes_regression();

    
    reg         clk;
    reg         rst_n;

    reg  [7:0]  awaddr;
    reg         awvalid;
    wire        awready;

    reg  [31:0] wdata;
    reg  [3:0]  wstrb;
    reg         wvalid;
    wire        wready;

    wire [1:0]  bresp;
    wire        bvalid;
    reg         bready;

    reg  [7:0]  araddr;
    reg         arvalid;
    wire        arready;

    wire [31:0] rdata;
    wire [1:0]  rresp;
    wire        rvalid;
    reg         rready;


    axi_aes_wrapper u_dut (
        .S_AXI_ACLK    (clk),
        .S_AXI_ARESETN (rst_n),
        .S_AXI_AWADDR  (awaddr),  .S_AXI_AWVALID (awvalid), .S_AXI_AWREADY (awready),
        .S_AXI_WDATA   (wdata),   .S_AXI_WSTRB   (wstrb),   .S_AXI_WVALID  (wvalid),  .S_AXI_WREADY  (wready),
        .S_AXI_BRESP   (bresp),   .S_AXI_BVALID  (bvalid),  .S_AXI_BREADY  (bready),
        .S_AXI_ARADDR  (araddr),  .S_AXI_ARVALID (arvalid), .S_AXI_ARREADY (arready),
        .S_AXI_RDATA   (rdata),   .S_AXI_RRESP   (rresp),   .S_AXI_RVALID  (rvalid),  .S_AXI_RREADY  (rready)
    );

   
    initial begin
        clk = 0;
        forever #2 clk = ~clk;
    end

  
    task axi_write;
        input [7:0]  addr;
        input [31:0] data;
        begin
            @(negedge clk);
            awaddr = addr; awvalid = 1'b1;
            wdata  = data; wvalid  = 1'b1; wstrb = 4'hF; bready = 1'b1;
            wait(awready == 1'b1 && wready == 1'b1);
            @(posedge clk);
            @(negedge clk);
            awvalid = 1'b0; wvalid = 1'b0;
            wait(bvalid == 1'b1);
            @(posedge clk);
            @(negedge clk);
            bready = 1'b0;
        end
    endtask

    task axi_read;
        input  [7:0]  addr;
        output [31:0] data;
        begin
            @(negedge clk);
            araddr = addr; arvalid = 1'b1; rready = 1'b1;
            wait(arready == 1'b1);
            @(posedge clk);
            @(negedge clk);
            arvalid = 1'b0;
            wait(rvalid == 1'b1);
            @(posedge clk);
            data = rdata;
            @(negedge clk);
            rready = 1'b0;
        end
    endtask

    task wait_for_done;
        reg [31:0] status;
        begin
            status = 32'h0;
            while ((status & 32'h00000004) == 0) begin 
                axi_read(8'h04, status);
                if ((status & 32'h00000004) == 0) @(negedge clk);
            end
        end
    endtask

    
    reg [127:0] ct_buffer;
    integer tests_passed = 0;
    integer tests_failed = 0;

    initial begin
        
        rst_n = 0; awaddr = 0; awvalid = 0; wdata = 0; wvalid = 0; wstrb = 0; bready = 0; araddr = 0; arvalid = 0; rready = 0;
        #20 rst_n = 1; #20;

        $display("==================================================");
        $display("   STARTING I-CHIP CIPHERSTREAM STRESS TESTS");
        $display("==================================================");

        axi_write(8'h00, 32'h00000001); 

      
        $display("\n--- TEST 1: Baseline FIPS-197 ---");
        axi_write(8'h10, 32'h0c0d0e0f); axi_write(8'h14, 32'h08090a0b); axi_write(8'h18, 32'h04050607); axi_write(8'h1C, 32'h00010203);
        axi_write(8'h20, 32'hccddeeff); axi_write(8'h24, 32'h8899aabb); axi_write(8'h28, 32'h44556677); axi_write(8'h2C, 32'h00112233);
        
        wait_for_done();
        
        axi_read(8'h30, ct_buffer[31:0]); axi_read(8'h34, ct_buffer[63:32]); axi_read(8'h38, ct_buffer[95:64]); axi_read(8'h3C, ct_buffer[127:96]);
        
        if (ct_buffer == 128'h69c4e0d86a7b0430d8cdb78070b4c55a) begin
            $display("    PASS: Output is correct."); tests_passed = tests_passed + 1;
        end else begin
            $display("    FAIL: Expected 69c4e0d86a7b0430d8cdb78070b4c55a, got %h", ct_buffer); tests_failed = tests_failed + 1;
        end


       
        $display("\n--- TEST 2: Backpressure Simulation ---");
       
        axi_write(8'h20, 32'hccddeeff); axi_write(8'h24, 32'h8899aabb); axi_write(8'h28, 32'h44556677); axi_write(8'h2C, 32'h00112233);
        
        repeat(5) @(posedge clk); 
        
        $display("    Freezing pipeline (enable = 0)...");
        axi_write(8'h00, 32'h00000000); 
        
        repeat(20) @(posedge clk); 
        
        $display("    Unfreezing pipeline (enable = 1)...");
        axi_write(8'h00, 32'h00000001); 
        
        wait_for_done();
        axi_read(8'h30, ct_buffer[31:0]); axi_read(8'h34, ct_buffer[63:32]); axi_read(8'h38, ct_buffer[95:64]); axi_read(8'h3C, ct_buffer[127:96]);
        
        if (ct_buffer == 128'h69c4e0d86a7b0430d8cdb78070b4c55a) begin
            $display("    PASS: Pipeline survived backpressure freeze without data loss."); tests_passed = tests_passed + 1;
        end else begin
            $display("    FAIL: Data corrupted during freeze."); tests_failed = tests_failed + 1;
        end


        
        $display("\n--- TEST 3: Mid-Flight Dynamic Key Update ---");
        
        
        axi_write(8'h20, 32'hccddeeff); axi_write(8'h24, 32'h8899aabb); axi_write(8'h28, 32'h44556677); axi_write(8'h2C, 32'h00112233);
        
        
        repeat(3) @(posedge clk);
        
        
        $display("    Writing New Key to AXI while Block A is in Stage 3...");
        axi_write(8'h10, 32'hFFFFFFFF); axi_write(8'h14, 32'hEEEEEEEE); axi_write(8'h18, 32'hDDDDDDDD); axi_write(8'h1C, 32'hCCCCCCCC);
        
        
        wait_for_done();
        axi_read(8'h30, ct_buffer[31:0]); axi_read(8'h34, ct_buffer[63:32]); axi_read(8'h38, ct_buffer[95:64]); axi_read(8'h3C, ct_buffer[127:96]);
        
        if (ct_buffer == 128'h69c4e0d86a7b0430d8cdb78070b4c55a) begin
            $display("    PASS: Mid-flight data was protected! Shadow register successfully delayed the key update."); tests_passed = tests_passed + 1;
        end else begin
            $display("    FAIL: Data was corrupted mid-flight by the new key."); tests_failed = tests_failed + 1;
        end


        $display("\n==================================================");
        $display("   FINAL RESULTS: %0d PASSED, %0d FAILED", tests_passed, tests_failed);
        $display("==================================================");
        
        #50;
        $finish;
    end
endmodule