`timescale 1ns / 1ps

module pe #(
    parameter DW = 16,        // Data Width (8 or 16 bit)
    parameter USE_RELU = 0    // Set to 1 to enable ReLU activation
)(
    input               clk,
    input               rst_n,
    input               load_w,    // Control: 1 = Load Weight, 0 = Compute
    
    input      [DW-1:0] a_in,      // Activation input (from Left)
    input      [DW-1:0] sum_in,    // Partial Sum input (from Top)
    input      [DW-1:0] w_in,      // Weight input (from Top)
    
    output reg [DW-1:0] a_out,     // Pass Activation to Right
    output reg [DW-1:0] sum_out,   // Pass Sum to Bottom
    output reg [DW-1:0] w_out      // Pass Weight to Bottom
);

    // Internal storage
    reg [DW-1:0] weight_reg;
    wire [DW-1:0] mac_result;

    // Weight Stationary Logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            weight_reg <= 0;
            w_out      <= 0;
            a_out      <= 0;
            sum_out    <= 0;
        end else begin
            // 1. Weight Loading Path (Vertical Shift)
            if (load_w) begin
                weight_reg <= w_in;
                w_out      <= weight_reg; // Pass *previous* weight down (shift register chain)
            end
            
            // 2. Data Path (Horizontal A, Vertical Sum)
            a_out <= a_in;
            
            // 3. MAC Computation
            if (USE_RELU && (mac_result[DW-1] == 1'b1)) // Simple ReLU check (MSB is sign)
                sum_out <= 0;
            else
                sum_out <= mac_result;
        end
    end

    // MAC Arithmetic: sum_out = sum_in + (a * w)
    assign mac_result = sum_in + (a_in * weight_reg);

endmodule