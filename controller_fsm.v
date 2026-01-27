`timescale 1ns / 1ps

module gemm_controller #(
    parameter N = 4,
    parameter K = 4,
    parameter ADDR_WIDTH = 8
)(
    input                     clk,
    input                     rst_n,
    input                     start,
    output reg                load_weights,
    output reg                done,
    output reg [ADDR_WIDTH-1:0] addr_a,
    output reg [ADDR_WIDTH-1:0] addr_b,
    output reg [ADDR_WIDTH-1:0] addr_c,
    output reg                  we_c
);
    localparam IDLE   = 0;
    localparam LOAD_W = 1;
    localparam EXEC   = 2;
    localparam DONE   = 3;

    reg [2:0] state;
    reg [15:0] counter;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            load_weights <= 0;
            done <= 0;
            addr_a <= 0;
            addr_b <= 0;
            addr_c <= 0;
            we_c <= 0;
            counter <= 0;
        end else begin
            we_c <= 0;
            done <= 0;

            case (state)
                IDLE: begin
                    if (start) begin
                        state <= LOAD_W;
                        counter <= 0;
                        addr_b <= 0; 
                        load_weights <= 1;
                    end
                end

                LOAD_W: begin
                    // Shift weights in
                    load_weights <= 1;
                    if (counter == N) begin
                        state <= EXEC;
                        counter <= 0;
                        load_weights <= 0; 
                        addr_a <= 0;
                    end else begin
                        if (addr_b < N-1) addr_b <= addr_b + 1;
                        counter <= counter + 1;
                    end
                end

                EXEC: begin
                    // Stream A
                    if (addr_a < K) 
                        addr_a <= addr_a + 1;
                    
                    if (counter == (K + 3*N + 1)) begin
                       state <= DONE; 
                    end else begin
                        counter <= counter + 1;
                    end

                    // FIX: Delayed Capture Logic (Wait N+1 cycles for BRAM+Pipe)
                    if (counter >= (N + 1) && counter < (N + K + 1)) begin
                         we_c <= 1;
                         addr_c <= (counter - (N + 1));
                    end
                end
                
                DONE: begin
                    done <= 1;
                    state <= IDLE;
                end
            endcase
        end
    end
endmodule
