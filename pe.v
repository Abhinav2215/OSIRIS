module PE #(
    parameter DATA_WIDTH = 16,
    parameter ACC_WIDTH = 32
)(
    input wire clk,
    input wire rst_n,
    
    // Control signals
    input wire enable,
    input wire load_weight,
    input wire clear_acc,
    input wire acc_enable,
    
    // Data inputs
    input wire [DATA_WIDTH-1:0] in_left,      // Activation from left
    input wire [DATA_WIDTH-1:0] in_top,       // Weight from top
    input wire [ACC_WIDTH-1:0] partial_sum_in, // Partial sum from top
    
    // Data outputs
    output reg [DATA_WIDTH-1:0] out_right,    // Activation to right
    output reg [DATA_WIDTH-1:0] out_bottom,   // Weight to bottom
    output reg [ACC_WIDTH-1:0] partial_sum_out // Partial sum to bottom
);

    // Internal registers
    reg [DATA_WIDTH-1:0] weight_reg;
    reg [ACC_WIDTH-1:0] accumulator;
    wire [ACC_WIDTH-1:0] mac_result;
    
    // MAC computation
    assign mac_result = accumulator + ($signed(in_left) * $signed(weight_reg));
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            weight_reg <= 0;
            accumulator <= 0;
            out_right <= 0;
            out_bottom <= 0;
            partial_sum_out <= 0;
        end else begin
            // Weight loading
            if (load_weight) begin
                weight_reg <= in_top;
            end
            
            // Accumulator control
            if (clear_acc) begin
                accumulator <= 0;
            end else if (enable && acc_enable) begin
                accumulator <= mac_result;
            end
            
            // Data propagation (pipelined)
            out_right <= in_left;
            out_bottom <= in_top;
            partial_sum_out <= accumulator + partial_sum_in;
        end
    end
endmodule
