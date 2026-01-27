`timescale 1ns / 1ps

module gemm_accelerator_top #(
    parameter N  = 4,   // 4x4 Array (Change to 32 for final proposal)
    parameter DW = 16,  // 16-bit precision
    parameter DEPTH = 256 // Buffer Depth
)(
    input         clk,
    input         rst_n,
    
    // --- Host Interface (AXI-Lite like) ---
    input         start_accel,
    output        done_accel,
    
    // SRAM Write Port (Host writes A and B here)
    input         host_we_a,
    input  [7:0]  host_addr_a,
    input  [N*DW-1:0] host_wdata_a,
    
    input         host_we_b,
    input  [7:0]  host_addr_b,
    input  [N*DW-1:0] host_wdata_b,
    
    // Result Read Port (Host reads C from here)
    input  [7:0]  host_addr_c,
    output [N*DW-1:0] host_rdata_c
);

    // --- Internal Signals ---
    wire load_weights;
    wire [7:0] ctrl_addr_a, ctrl_addr_b, ctrl_addr_c;
    wire       ctrl_we_c;
    wire [N*DW-1:0] ram_a_out, ram_b_out, array_out;
    
    // Muxing Addresses: Host (Setup) vs Controller (Run)
    wire [7:0] mux_addr_a = (start_accel) ? ctrl_addr_a : host_addr_a;
    wire [7:0] mux_addr_b = (start_accel) ? ctrl_addr_b : host_addr_b;
    wire [7:0] mux_addr_c = (ctrl_we_c)   ? ctrl_addr_c : host_addr_c;

    // --- 1. Input Buffer (Matrix A) ---
    bram_buffer #(.WIDTH(N*DW), .DEPTH(DEPTH)) buff_A (
        .clk(clk), .we(host_we_a), .addr(mux_addr_a), 
        .din(host_wdata_a), .dout(ram_a_out)
    );

    // --- 2. Weight Buffer (Matrix B) ---
    bram_buffer #(.WIDTH(N*DW), .DEPTH(DEPTH)) buff_B (
        .clk(clk), .we(host_we_b), .addr(mux_addr_b), 
        .din(host_wdata_b), .dout(ram_b_out)
    );

    // --- 3. Output Buffer (Matrix C) ---
    // Controller writes results here, Host reads them later
    bram_buffer #(.WIDTH(N*DW), .DEPTH(DEPTH)) buff_C (
        .clk(clk), .we(ctrl_we_c), .addr(mux_addr_c), 
        .din(array_out), .dout(host_rdata_c)
    );

    // --- 4. Systolic Array Core ---
    systolic_array #(.N(N), .DW(DW)) array_core (
        .clk(clk), .rst_n(rst_n),
        .load_weights(load_weights),
        .A_flat(ram_a_out),
        .B_flat(ram_b_out),
        .C_flat(array_out)
    );

    // --- 5. Controller ---
    gemm_controller #(.N(N), .K(N), .ADDR_WIDTH(8)) ctrl_unit (
        .clk(clk), .rst_n(rst_n),
        .start(start_accel),
        .done(done_accel),
        .load_weights(load_weights),
        .addr_a(ctrl_addr_a),
        .addr_b(ctrl_addr_b),
        .addr_c(ctrl_addr_c),
        .we_c(ctrl_we_c)
    );

endmodule