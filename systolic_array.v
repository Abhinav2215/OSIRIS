`timescale 1ns / 1ps

module systolic_array #(
    parameter N  = 4,  // Array Size (e.g., 4x4, 8x8, 32x32)
    parameter DW = 16  // Data Width
)(
    input                     clk,
    input                     rst_n,
    input                     load_weights,
    
    // Flat Interfaces for simplified top-level connection
    input      [N*DW-1:0]     A_flat, // Current column of Matrix A
    input      [N*DW-1:0]     B_flat, // Current row of Matrix B (Weights)
    output     [N*DW-1:0]     C_flat  // Result row (Partial Sums) exiting bottom
);

    // Unpacking
    wire [DW-1:0] A_in [0:N-1];
    wire [DW-1:0] B_in [0:N-1];
    wire [DW-1:0] C_out [0:N-1];

    genvar k;
    generate
        for (k=0; k<N; k=k+1) begin : UNPACK
            assign A_in[k] = A_flat[k*DW +: DW];
            assign B_in[k] = B_flat[k*DW +: DW];
            assign C_flat[k*DW +: DW] = C_out[k];
        end
    endgenerate

    // Interconnect Wires
    wire [DW-1:0] pe_a   [0:N-1][0:N];   // Horizontal wires (N rows, N+1 cols)
    wire [DW-1:0] pe_sum [0:N][0:N-1];   // Vertical Sum wires (N+1 rows, N cols)
    wire [DW-1:0] pe_w   [0:N][0:N-1];   // Vertical Weight wires

    // --- Input Skew Buffers for A ---
    // In a systolic array, Row i of A must be delayed by i cycles.
    reg [DW-1:0] a_skew_buf [0:N-1][0:N-1]; // Max delay needed is N-1
    
    integer i_s, j_s;
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            for(i_s=0; i_s<N; i_s=i_s+1)
                for(j_s=0; j_s<N; j_s=j_s+1)
                    a_skew_buf[i_s][j_s] <= 0;
        end else begin
            for(i_s=0; i_s<N; i_s=i_s+1) begin
                // Chain of registers for delay
                a_skew_buf[i_s][0] <= A_in[i_s];
                for(j_s=1; j_s<N; j_s=j_s+1)
                    a_skew_buf[i_s][j_s] <= a_skew_buf[i_s][j_s-1];
            end
        end
    end

    // --- PE Instantiation ---
    genvar r, c;
    generate
        for (r=0; r<N; r=r+1) begin : ROW
            for (c=0; c<N; c=c+1) begin : COL
                
                // Map Inputs
                // A input: Row 0 is direct, Rows > 0 come from skew buffer tap (r-1)
                assign pe_a[r][0] = (r==0) ? A_in[0] : a_skew_buf[r][r-1];
                
                // Top Boundary: Sums=0, Weights=B_in
                if (r == 0) begin
                    assign pe_sum[0][c] = {DW{1'b0}};
                    assign pe_w[0][c]   = B_in[c];
                end

                pe #(.DW(DW)) pe_core (
                    .clk(clk), .rst_n(rst_n), .load_w(load_weights),
                    .a_in    (pe_a[r][c]),
                    .sum_in  (pe_sum[r][c]),
                    .w_in    (pe_w[r][c]),
                    .a_out   (pe_a[r][c+1]),
                    .sum_out (pe_sum[r+1][c]),
                    .w_out   (pe_w[r+1][c])
                );
            end
            
            // Map Bottom Outputs
            assign C_out[r] = pe_sum[N][r]; // Result exits at bottom
        end
    endgenerate

endmodule