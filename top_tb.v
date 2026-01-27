`timescale 1ns / 1ps

module tb_gemm_accelerator;

    parameter N = 2;
    parameter DW = 16;
    
    reg clk, rst_n;
    reg start;
    wire done;
    
    reg we_a, we_b;
    reg [7:0] addr_a, addr_b, addr_c;
    reg [N*DW-1:0] wdata_a, wdata_b;
    wire [N*DW-1:0] rdata_c;

    gemm_accelerator_top #(.N(N), .DW(DW)) dut (
        .clk(clk), .rst_n(rst_n),
        .start_accel(start), .done_accel(done),
        .host_we_a(we_a), .host_addr_a(addr_a), .host_wdata_a(wdata_a),
        .host_we_b(we_b), .host_addr_b(addr_b), .host_wdata_b(wdata_b),
        .host_addr_c(addr_c), .host_rdata_c(rdata_c)
    );

    always #5 clk = ~clk; 

    initial begin
        clk = 0; rst_n = 0; start = 0;
        we_a = 0; we_b = 0; addr_a = 0; addr_b = 0; addr_c = 0;
        
        #20 rst_n = 1;

        // --- 1. Load Matrix B (Weights) ---
        // B = [5 6] (Row 0)
        //     [7 8] (Row 1)
        // Load Row 1 first (Bottom PE), then Row 0 (Top PE)
        $display("Loading Weights...");
        we_b = 1; 
        addr_b = 0; wdata_b = {16'd8, 16'd7}; #10; // Row 1
        addr_b = 1; wdata_b = {16'd6, 16'd5}; #10; // Row 0
        we_b = 0;

        // --- 2. Load Matrix A (Inputs) ---
        // A = [1 2]
        //     [3 4]
        // Load Row 0, then Row 1
        $display("Loading Inputs...");
        we_a = 1; 
        // Row 0: {2, 1}
        addr_a = 0; wdata_a = {16'd2, 16'd1}; #10;
        // Row 1: {4, 3}
        addr_a = 1; wdata_a = {16'd4, 16'd3}; #10;
        we_a = 0;

        // --- 3. Run ---
        $display("Starting...");
        start = 1; #10 start = 0;
        wait(done);
        
        // --- 4. Check Results ---
        #20;
        $display("Checking Results (Expected: 19, 22 then 43, 50)");
        
        // Row 0
        addr_c = 0; #10;
        $display("Row 0 Hex: %h (Expect 00160013)", rdata_c);
        
        // Row 1
        addr_c = 1; #10;
        $display("Row 1 Hex: %h (Expect 0032002B)", rdata_c);
        
        $finish;
    end
endmodule