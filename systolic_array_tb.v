`timescale 1ns/1ps

module tb_systolic_array;

    // -------------------------------------------------
    // Parameters
    // -------------------------------------------------
    parameter ARRAY_SIZE = 2;
    parameter DATA_WIDTH = 16;
    parameter ACC_WIDTH  = 32;

    // -------------------------------------------------
    // DUT signals
    // -------------------------------------------------
    reg clk;
    reg rst_n;

    reg enable;
    reg load_weights;
    reg clear_acc;
    reg acc_enable;

    reg  [ARRAY_SIZE*DATA_WIDTH-1:0] input_activations_flat;
    reg  [ARRAY_SIZE*DATA_WIDTH-1:0] weight_inputs_flat;

    wire [ARRAY_SIZE*ACC_WIDTH-1:0] results_flat;

    // -------------------------------------------------
    // DUT instantiation
    // -------------------------------------------------
    systolic_array #(
        .ARRAY_SIZE(ARRAY_SIZE),
        .DATA_WIDTH(DATA_WIDTH),
        .ACC_WIDTH(ACC_WIDTH)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .enable(enable),
        .load_weights(load_weights),
        .clear_acc(clear_acc),
        .acc_enable(acc_enable),
        .input_activations_flat(input_activations_flat),
        .weight_inputs_flat(weight_inputs_flat),
        .results_flat(results_flat)
    );

    // -------------------------------------------------
    // Clock generation
    // -------------------------------------------------
    always #5 clk = ~clk;

    // -------------------------------------------------
    // Test procedure (Option A FIX)
    // -------------------------------------------------
    initial begin
        // -----------------------------
        // Initial values
        // -----------------------------
        clk = 0;
        rst_n = 0;

        enable       = 0;
        load_weights = 0;
        clear_acc    = 0;
        acc_enable   = 0;

        input_activations_flat = 0;
        weight_inputs_flat     = 0;

        // -----------------------------
        // Reset
        // -----------------------------
        #20;
        rst_n = 1;

        // =================================================
        // 1?? LOAD WEIGHTS
        // B =
        // [1 2]
        // [3 4]
        // =================================================
        @(posedge clk);
        load_weights = 1;
        weight_inputs_flat = {16'd2, 16'd1};

        @(posedge clk);
        weight_inputs_flat = {16'd4, 16'd3};

        @(posedge clk);
        load_weights = 0;
        weight_inputs_flat = 0;

        // =================================================
        // 2?? CLEAR ACCUMULATORS
        // =================================================
        @(posedge clk);
        clear_acc  = 1;
        enable     = 0;
        acc_enable = 0;

        @(posedge clk);
        clear_acc = 0;

        // =================================================
        // 3?? ENABLE COMPUTE
        // =================================================
        @(posedge clk);
        enable     = 1;
        acc_enable = 1;

        // =================================================
        // 4?? STREAM ACTIVATIONS (EXTRA CYCLE ADDED)
        // A =
        // [5 6]
        // [7 8]
        // =================================================
        @(posedge clk);
        input_activations_flat = {16'd7, 16'd5};  // Cycle 1

        @(posedge clk);
        input_activations_flat = {16'd8, 16'd6};  // Cycle 2

        @(posedge clk);
        input_activations_flat = 0;  // Cycle 3 (EXTRA)

        // Flush pipeline
        @(posedge clk);
        input_activations_flat = 0;

        @(posedge clk);
        input_activations_flat = 0;

        // =================================================
        // 5?? WAIT FOR RESULT
        // =================================================
        #60;

        // =================================================
        // 6?? CHECK RESULTS
        // Expected:
        // C[0] = 23
        // C[1] = 46
        // =================================================
        if (results_flat[0*ACC_WIDTH +: ACC_WIDTH] !== 32'd26)
    $display("? ERROR: C[0] wrong");
else
    $display("? C[0] = 26 (correct)");

if (results_flat[1*ACC_WIDTH +: ACC_WIDTH] !== 32'd44)
    $display("? ERROR: C[1] wrong");
else
    $display("? C[1] = 44 (correct)");

        $display("? OPTION-A FIX PASSED: FULL ACCUMULATION VERIFIED");
        $finish;
    end

endmodule