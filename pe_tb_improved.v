`timescale 1ns/1ps

// ============================================================================
// IMPROVED PROCESSING ELEMENT (PE) TESTBENCH WITH BETTER MONITORING
// ============================================================================
module pe_tb;
    parameter DATA_WIDTH = 16;
    parameter ACC_WIDTH = 32;
    parameter CLK_PERIOD = 10;
    
    // DUT signals
    reg clk, rst_n;
    reg enable, load_weight, clear_acc, acc_enable;
    reg [DATA_WIDTH-1:0] in_left, in_top;
    reg [ACC_WIDTH-1:0] partial_sum_in;
    wire [DATA_WIDTH-1:0] out_right, out_bottom;
    wire [ACC_WIDTH-1:0] partial_sum_out;
    
    // Monitor internal signals (for waveform viewing)
    wire [DATA_WIDTH-1:0] internal_weight;
    wire [ACC_WIDTH-1:0] internal_accumulator;
    wire [ACC_WIDTH-1:0] internal_mac_result;
    
    // Assign internal signals for monitoring
    assign internal_weight = dut.weight_reg;
    assign internal_accumulator = dut.accumulator;
    assign internal_mac_result = dut.mac_result;
    
    // Instantiate DUT
    PE #(
        .DATA_WIDTH(DATA_WIDTH),
        .ACC_WIDTH(ACC_WIDTH)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .enable(enable),
        .load_weight(load_weight),
        .clear_acc(clear_acc),
        .acc_enable(acc_enable),
        .in_left(in_left),
        .in_top(in_top),
        .partial_sum_in(partial_sum_in),
        .out_right(out_right),
        .out_bottom(out_bottom),
        .partial_sum_out(partial_sum_out)
    );
    
    // Clock generation
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end
    
    // Test sequence
    integer test_num;
    integer pass_count;
    integer fail_count;
    
    initial begin
        $display("========================================");
        $display("PE TESTBENCH START");
        $display("Time: %0t", $time);
        $display("========================================");
        
        pass_count = 0;
        fail_count = 0;
        
        // Initialize all signals
        rst_n = 0;
        enable = 0;
        load_weight = 0;
        clear_acc = 0;
        acc_enable = 0;
        in_left = 0;
        in_top = 0;
        partial_sum_in = 0;
        
        // Apply Reset
        $display("\n[%0t] Applying Reset...", $time);
        #(CLK_PERIOD*2);
        rst_n = 1;
        #(CLK_PERIOD);
        $display("[%0t] Reset Released", $time);
        
        // ====================================================================
        // Test 1: Load Weight
        // ====================================================================
        test_num = 1;
        $display("\n========================================");
        $display("Test %0d: Load Weight", test_num);
        $display("========================================");
        $display("[%0t] Loading weight = 5", $time);
        
        @(posedge clk);
        #1; // Small delay after clock edge
        load_weight = 1;
        in_top = 16'd5;
        
        @(posedge clk);
        #1;
        load_weight = 0;
        
        @(posedge clk);
        #1;
        $display("[%0t] Weight Register = %0d (Expected: 5)", $time, internal_weight);
        if (internal_weight == 5) begin
            $display("✓ PASS: Weight loaded correctly");
            pass_count = pass_count + 1;
        end else begin
            $display("✗ FAIL: Weight = %0d, Expected = 5", internal_weight);
            fail_count = fail_count + 1;
        end
        
        // ====================================================================
        // Test 2: First MAC Operation (5 * 3 = 15)
        // ====================================================================
        test_num = 2;
        $display("\n========================================");
        $display("Test %0d: First MAC Operation", test_num);
        $display("========================================");
        $display("[%0t] Computing: weight(5) × in_left(3) = 15", $time);
        
        @(posedge clk);
        #1;
        enable = 1;
        acc_enable = 1;
        in_left = 16'd3;
        
        @(posedge clk);
        #1;
        $display("[%0t] MAC Result = %0d", $time, internal_mac_result);
        
        @(posedge clk);
        #1;
        $display("[%0t] Accumulator = %0d (Expected: 15)", $time, internal_accumulator);
        if (internal_accumulator == 15) begin
            $display("✓ PASS: MAC operation correct");
            pass_count = pass_count + 1;
        end else begin
            $display("✗ FAIL: Accumulator = %0d, Expected = 15", internal_accumulator);
            fail_count = fail_count + 1;
        end
        
        // ====================================================================
        // Test 3: Accumulation (15 + 5*4 = 35)
        // ====================================================================
        test_num = 3;
        $display("\n========================================");
        $display("Test %0d: Accumulation", test_num);
        $display("========================================");
        $display("[%0t] Computing: accumulator(15) + weight(5) × in_left(4) = 35", $time);
        
        @(posedge clk);
        #1;
        in_left = 16'd4;
        
        @(posedge clk);
        #1;
        $display("[%0t] MAC Result = %0d", $time, internal_mac_result);
        
        @(posedge clk);
        #1;
        $display("[%0t] Accumulator = %0d (Expected: 35)", $time, internal_accumulator);
        if (internal_accumulator == 35) begin
            $display("✓ PASS: Accumulation correct");
            pass_count = pass_count + 1;
        end else begin
            $display("✗ FAIL: Accumulator = %0d, Expected = 35", internal_accumulator);
            fail_count = fail_count + 1;
        end
        
        // ====================================================================
        // Test 4: Clear Accumulator
        // ====================================================================
        test_num = 4;
        $display("\n========================================");
        $display("Test %0d: Clear Accumulator", test_num);
        $display("========================================");
        $display("[%0t] Clearing accumulator (was %0d)", $time, internal_accumulator);
        
        @(posedge clk);
        #1;
        clear_acc = 1;
        
        @(posedge clk);
        #1;
        clear_acc = 0;
        
        @(posedge clk);
        #1;
        $display("[%0t] Accumulator = %0d (Expected: 0)", $time, internal_accumulator);
        if (internal_accumulator == 0) begin
            $display("✓ PASS: Accumulator cleared");
            pass_count = pass_count + 1;
        end else begin
            $display("✗ FAIL: Accumulator = %0d, Expected = 0", internal_accumulator);
            fail_count = fail_count + 1;
        end
        
        // ====================================================================
        // Test 5: Data Propagation
        // ====================================================================
        test_num = 5;
        $display("\n========================================");
        $display("Test %0d: Data Propagation", test_num);
        $display("========================================");
        $display("[%0t] Testing systolic data forwarding", $time);
        
        @(posedge clk);
        #1;
        in_left = 16'd100;
        in_top = 16'd200;
        $display("[%0t] Input: in_left=%0d, in_top=%0d", $time, in_left, in_top);
        
        @(posedge clk);
        #1;
        
        @(posedge clk);
        #1;
        $display("[%0t] Output: out_right=%0d (Expected: 100), out_bottom=%0d (Expected: 200)", 
                 $time, out_right, out_bottom);
        if (out_right == 100 && out_bottom == 200) begin
            $display("✓ PASS: Data propagation correct");
            pass_count = pass_count + 1;
        end else begin
            $display("✗ FAIL: out_right=%0d (Expected: 100), out_bottom=%0d (Expected: 200)", 
                     out_right, out_bottom);
            fail_count = fail_count + 1;
        end
        
        // ====================================================================
        // Test 6: Signed Arithmetic (-5 * -3 = 15)
        // ====================================================================
        test_num = 6;
        $display("\n========================================");
        $display("Test %0d: Signed Multiplication", test_num);
        $display("========================================");
        $display("[%0t] Testing negative × negative = positive", $time);
        
        // Clear accumulator first
        @(posedge clk);
        #1;
        clear_acc = 1;
        
        @(posedge clk);
        #1;
        clear_acc = 0;
        
        // Load negative weight
        @(posedge clk);
        #1;
        load_weight = 1;
        in_top = -16'd5;
        $display("[%0t] Loading weight = -5", $time);
        
        @(posedge clk);
        #1;
        load_weight = 0;
        $display("[%0t] Weight Register = %0d", $time, $signed(internal_weight));
        
        // Multiply with negative input
        @(posedge clk);
        #1;
        in_left = -16'd3;
        $display("[%0t] Computing: (-5) × (-3)", $time);
        
        @(posedge clk);
        #1;
        $display("[%0t] MAC Result = %0d", $time, $signed(internal_mac_result));
        
        @(posedge clk);
        #1;
        $display("[%0t] Accumulator = %0d (Expected: 15)", $time, $signed(internal_accumulator));
        if ($signed(internal_accumulator) == 15) begin
            $display("✓ PASS: Signed multiplication correct");
            pass_count = pass_count + 1;
        end else begin
            $display("✗ FAIL: Accumulator = %0d, Expected = 15", $signed(internal_accumulator));
            fail_count = fail_count + 1;
        end
        
        // ====================================================================
        // Test 7: Partial Sum Accumulation
        // ====================================================================
        test_num = 7;
        $display("\n========================================");
        $display("Test %0d: Partial Sum Accumulation", test_num);
        $display("========================================");
        $display("[%0t] Testing partial_sum_in + accumulator", $time);
        
        @(posedge clk);
        #1;
        clear_acc = 1;
        
        @(posedge clk);
        #1;
        clear_acc = 0;
        partial_sum_in = 32'd100;
        
        @(posedge clk);
        #1;
        // Load a simple weight
        load_weight = 1;
        in_top = 16'd2;
        
        @(posedge clk);
        #1;
        load_weight = 0;
        in_left = 16'd5;  // 2 × 5 = 10
        
        @(posedge clk);
        #1;
        
        @(posedge clk);
        #1;
        $display("[%0t] partial_sum_out = %0d (Expected: 100 + 10 = 110)", 
                 $time, partial_sum_out);
        if (partial_sum_out == 110) begin
            $display("✓ PASS: Partial sum accumulation correct");
            pass_count = pass_count + 1;
        end else begin
            $display("✗ FAIL: partial_sum_out = %0d, Expected = 110", partial_sum_out);
            fail_count = fail_count + 1;
        end
        
        // ====================================================================
        // Test Summary
        // ====================================================================
        $display("\n========================================");
        $display("PE TESTBENCH COMPLETE");
        $display("========================================");
        $display("Tests Passed: %0d", pass_count);
        $display("Tests Failed: %0d", fail_count);
        $display("Total Tests:  %0d", pass_count + fail_count);
        if (fail_count == 0) begin
            $display("✓✓✓ ALL TESTS PASSED ✓✓✓");
        end else begin
            $display("✗✗✗ SOME TESTS FAILED ✗✗✗");
        end
        $display("========================================\n");
        
        #(CLK_PERIOD*5);
        $finish;
    end
    
    // Continuous monitoring (appears in console during simulation)
    always @(posedge clk) begin
        if (rst_n && enable) begin
            $display("[%0t] MONITOR: weight=%0d, in_left=%0d, acc=%0d, mac_result=%0d", 
                     $time, $signed(internal_weight), $signed(in_left), 
                     $signed(internal_accumulator), $signed(internal_mac_result));
        end
    end
    
    // Waveform dump for viewing in simulator
    initial begin
        $dumpfile("pe_tb.vcd");
        $dumpvars(0, pe_tb);
        
        // Explicitly dump internal signals
        $dumpvars(1, internal_weight);
        $dumpvars(1, internal_accumulator);
        $dumpvars(1, internal_mac_result);
        $dumpvars(1, dut.weight_reg);
        $dumpvars(1, dut.accumulator);
        $dumpvars(1, dut.mac_result);
    end
    
    // Timeout watchdog
    initial begin
        #500000; // 500us timeout
        $display("\n✗✗✗ ERROR: Simulation timeout! ✗✗✗\n");
        $finish;
    end
    
endmodule
