`timescale 1ns / 1ps

module sram #(
    parameter WIDTH = 64,   // Data Width
    parameter DEPTH = 256   // Memory Depth
)(
    input                        clk,
    input                        we,    // Write Enable
    input  [$clog2(DEPTH)-1:0]   addr,  // Address
    input  [WIDTH-1:0]           din,   // Data In
    output reg [WIDTH-1:0]       dout   // Data Out
);

    // Standard Behavioral Memory Array
    // In actual ASIC P&R, this module is often replaced by a 
    // vendor-specific hard macro (e.g., from a Memory Compiler).
    reg [WIDTH-1:0] mem [0:DEPTH-1];

    always @(posedge clk) begin
        if (we) begin
            mem[addr] <= din;
        end
        // Synchronous Read (Standard for SRAM Macros)
        dout <= mem[addr];
    end

endmodule