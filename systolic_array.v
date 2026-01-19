module systolic_array #(
    parameter ARRAY_SIZE = 4,
    parameter DATA_WIDTH = 16,
    parameter ACC_WIDTH  = 32
)(
    input  wire clk,
    input  wire rst_n,

    // Control signals
    input  wire enable,
    input  wire load_weights,
    input  wire clear_acc,
    input  wire acc_enable,

    // Flattened inputs
    input  wire [ARRAY_SIZE*DATA_WIDTH-1:0] input_activations_flat,
    input  wire [ARRAY_SIZE*DATA_WIDTH-1:0] weight_inputs_flat,

    // Flattened outputs
    output wire [ARRAY_SIZE*ACC_WIDTH-1:0] results_flat
);

    // ------------------------------------
    // Internal unpacked arrays
    // ------------------------------------
    wire [DATA_WIDTH-1:0] input_activations [0:ARRAY_SIZE-1];
    wire [DATA_WIDTH-1:0] weight_inputs     [0:ARRAY_SIZE-1];
    wire [ACC_WIDTH-1:0]  results           [0:ARRAY_SIZE-1];

    genvar i;

    // Unpack flattened inputs
    generate
        for (i = 0; i < ARRAY_SIZE; i = i + 1) begin
            assign input_activations[i] =
                input_activations_flat[i*DATA_WIDTH +: DATA_WIDTH];

            assign weight_inputs[i] =
                weight_inputs_flat[i*DATA_WIDTH +: DATA_WIDTH];

            assign results_flat[i*ACC_WIDTH +: ACC_WIDTH] =
                results[i];
        end
    endgenerate

    // ------------------------------------
    // Internal buses
    // ------------------------------------
    wire [DATA_WIDTH-1:0] horizontal_bus [0:ARRAY_SIZE-1][0:ARRAY_SIZE];
    wire [DATA_WIDTH-1:0] vertical_bus   [0:ARRAY_SIZE][0:ARRAY_SIZE-1];
    wire [ACC_WIDTH-1:0]  partial_sum_bus[0:ARRAY_SIZE][0:ARRAY_SIZE-1];

    genvar row, col;

    // PE grid
    generate
        for (row = 0; row < ARRAY_SIZE; row = row + 1) begin : gen_rows
            for (col = 0; col < ARRAY_SIZE; col = col + 1) begin : gen_cols
                PE #(
                    .DATA_WIDTH(DATA_WIDTH),
                    .ACC_WIDTH(ACC_WIDTH)
                ) pe_inst (
                    .clk(clk),
                    .rst_n(rst_n),
                    .enable(enable),
                    .load_weight(load_weights),
                    .clear_acc(clear_acc),
                    .acc_enable(acc_enable),

                    .in_left(horizontal_bus[row][col]),
                    .out_right(horizontal_bus[row][col+1]),

                    .in_top(vertical_bus[row][col]),
                    .out_bottom(vertical_bus[row+1][col]),

                    .partial_sum_in(partial_sum_bus[row][col]),
                    .partial_sum_out(partial_sum_bus[row+1][col])
                );
            end
        end
    endgenerate

    // Boundary connections
    generate
        for (row = 0; row < ARRAY_SIZE; row = row + 1) begin
            assign horizontal_bus[row][0] = input_activations[row];
        end

        for (col = 0; col < ARRAY_SIZE; col = col + 1) begin
            assign vertical_bus[0][col]   = weight_inputs[col];
            assign partial_sum_bus[0][col]= {ACC_WIDTH{1'b0}};
            assign results[col]           = partial_sum_bus[ARRAY_SIZE][col];
        end
    endgenerate

endmodule