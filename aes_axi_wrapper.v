`timescale 1ns / 1ps

module axi_aes_wrapper #(
    parameter integer C_S_AXI_DATA_WIDTH = 32,
    parameter integer C_S_AXI_ADDR_WIDTH = 8
)(
   
    input wire  S_AXI_ACLK,
    input wire  S_AXI_ARESETN,

    
    input wire [C_S_AXI_ADDR_WIDTH-1 : 0] S_AXI_AWADDR,
    input wire  S_AXI_AWVALID,
    output wire S_AXI_AWREADY,

   
    input wire [C_S_AXI_DATA_WIDTH-1 : 0] S_AXI_WDATA,
    input wire [(C_S_AXI_DATA_WIDTH/8)-1 : 0] S_AXI_WSTRB,
    input wire  S_AXI_WVALID,
    output wire S_AXI_WREADY,

   
    output wire [1 : 0] S_AXI_BRESP,
    output wire S_AXI_BVALID,
    input wire  S_AXI_BREADY,

    
    input wire [C_S_AXI_ADDR_WIDTH-1 : 0] S_AXI_ARADDR,
    input wire  S_AXI_ARVALID,
    output wire S_AXI_ARREADY,

    
    output wire [C_S_AXI_DATA_WIDTH-1 : 0] S_AXI_RDATA,
    output wire [1 : 0] S_AXI_RRESP,
    output wire S_AXI_RVALID,
    input wire  S_AXI_RREADY
);

    
    reg axi_awready;
    reg axi_wready;
    reg axi_bvalid;
    reg axi_arready;
    reg axi_rvalid;
    reg [C_S_AXI_DATA_WIDTH-1 : 0] axi_rdata;

    assign S_AXI_AWREADY = axi_awready;
    assign S_AXI_WREADY  = axi_wready;
    assign S_AXI_BRESP   = 2'b00; 
    assign S_AXI_BVALID  = axi_bvalid;
    assign S_AXI_ARREADY = axi_arready;
    assign S_AXI_RDATA   = axi_rdata;
    assign S_AXI_RRESP   = 2'b00; 
    assign S_AXI_RVALID  = axi_rvalid;

    reg  [127:0] slv_reg_key;
    reg  [127:0] slv_reg_pt;
    reg  [127:0] slv_reg_ct; 
    reg          slv_reg_control; 
    reg          status_done;     

    reg          new_key_valid_pulse;
    reg          data_valid_in_pulse;

    wire [127:0] aes_ciphertext;
    wire         aes_ciphertext_valid;
    wire         aes_pipeline_empty;

  
    wire slv_reg_wren = axi_wready && S_AXI_WVALID && axi_awready && S_AXI_AWVALID;

    always @(posedge S_AXI_ACLK) begin
        if (S_AXI_ARESETN == 1'b0) begin
            axi_awready <= 1'b0;
            axi_wready  <= 1'b0;
            axi_bvalid  <= 1'b0;
        end else begin
          
            if (~axi_awready && S_AXI_AWVALID && S_AXI_WVALID)
                axi_awready <= 1'b1;
            else
                axi_awready <= 1'b0;

         
            if (~axi_wready && S_AXI_WVALID && S_AXI_AWVALID)
                axi_wready <= 1'b1;
            else
                axi_wready <= 1'b0;

            
            if (axi_awready && S_AXI_AWVALID && ~axi_bvalid && axi_wready && S_AXI_WVALID)
                axi_bvalid <= 1'b1;
            else if (S_AXI_BREADY && axi_bvalid)
                axi_bvalid <= 1'b0;
        end
    end

    
    always @(posedge S_AXI_ACLK) begin
        if (S_AXI_ARESETN == 1'b0) begin
            slv_reg_control     <= 1'b0;
            slv_reg_key         <= 128'b0;
            slv_reg_pt          <= 128'b0;
            new_key_valid_pulse <= 1'b0;
            data_valid_in_pulse <= 1'b0;
        end else begin
            
            new_key_valid_pulse <= 1'b0;
            data_valid_in_pulse <= 1'b0;

            if (slv_reg_wren) begin
                case (S_AXI_AWADDR[7:0])
                    8'h00: slv_reg_control <= S_AXI_WDATA[0]; 
                    
                   
                    8'h10: slv_reg_key[31:0]   <= S_AXI_WDATA;
                    8'h14: slv_reg_key[63:32]  <= S_AXI_WDATA;
                    8'h18: slv_reg_key[95:64]  <= S_AXI_WDATA;
                    8'h1C: begin
                        slv_reg_key[127:96] <= S_AXI_WDATA;
                        new_key_valid_pulse <= 1'b1;
                    end

                   
                    8'h20: slv_reg_pt[31:0]   <= S_AXI_WDATA;
                    8'h24: slv_reg_pt[63:32]  <= S_AXI_WDATA;
                    8'h28: slv_reg_pt[95:64]  <= S_AXI_WDATA;
                    8'h2C: begin
                        slv_reg_pt[127:96]  <= S_AXI_WDATA;
                        data_valid_in_pulse <= 1'b1; 
                    end
                endcase
            end
        end
    end

    
    wire slv_reg_rden = axi_arready & S_AXI_ARVALID & ~axi_rvalid;

    always @(posedge S_AXI_ACLK) begin
        if (S_AXI_ARESETN == 1'b0) begin
            axi_arready <= 1'b0;
            axi_rvalid  <= 1'b0;
            axi_rdata   <= 32'b0;
        end else begin
           
            if (~axi_arready && S_AXI_ARVALID)
                axi_arready <= 1'b1;
            else
                axi_arready <= 1'b0;

           
            if (axi_arready && S_AXI_ARVALID && ~axi_rvalid)
                axi_rvalid <= 1'b1;
            else if (axi_rvalid && S_AXI_RREADY)
                axi_rvalid <= 1'b0;

           
            if (slv_reg_rden) begin
                case (S_AXI_ARADDR[7:0])
                    8'h04: axi_rdata <= {28'b0, aes_pipeline_empty, status_done, 1'b0, 1'b0}; 
                
                    8'h30: axi_rdata <= slv_reg_ct[31:0];
                    8'h34: axi_rdata <= slv_reg_ct[63:32];
                    8'h38: axi_rdata <= slv_reg_ct[95:64];
                    8'h3C: begin 
                           axi_rdata <= slv_reg_ct[127:96];
                          
                    end
                    default: axi_rdata <= 32'b0;
                endcase
            end
        end
    end

 
    always @(posedge S_AXI_ACLK) begin
        if (S_AXI_ARESETN == 1'b0) begin
            slv_reg_ct  <= 128'b0;
            status_done <= 1'b0;
        end else begin
            if (aes_ciphertext_valid) begin
                slv_reg_ct  <= aes_ciphertext;
                status_done <= 1'b1;
            end else if (slv_reg_rden && S_AXI_ARADDR[7:0] == 8'h3C) begin
               
                status_done <= 1'b0; 
            end
        end
    end


    aes_128_datapath u_aes_core (
        .clk              (S_AXI_ACLK),
        .rst_n            (S_AXI_ARESETN),
        
        .enable           (slv_reg_control),
        .data_valid_in    (data_valid_in_pulse),
        .plaintext        (slv_reg_pt),
        
        .new_key          (slv_reg_key),
        .new_key_valid    (new_key_valid_pulse),
        
        .ciphertext       (aes_ciphertext),
        .ciphertext_valid (aes_ciphertext_valid),
        .pipeline_empty   (aes_pipeline_empty)
    );

endmodule