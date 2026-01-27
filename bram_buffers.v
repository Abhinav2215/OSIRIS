`timescale 1ns / 1ps

module bram_buffer #(
    parameter WIDTH = 64,   // N * DW
    parameter DEPTH = 256
)(
    input                        clk,
    input                        we,    // Write Enable
    input  [$clog2(DEPTH)-1:0]   addr,  // Address
    input  [WIDTH-1:0]           din,   // Data In
    output reg [WIDTH-1:0]       dout   // Data Out
);

    // Vivado Attribute to force BRAM inference
    (* ram_style = "block" *) 
    reg [WIDTH-1:0] mem [0:DEPTH-1];

    always @(posedge clk) begin
        if (we)
            mem[addr] <= din;
        dout <= mem[addr];
    end

endmodule