// COS201 - BPSK correlator/demodulator, 16-bit signed, 8 samples/symbol.
// Pause/resume across rx_valid=0 gaps; one bit_valid pulse per 8 samples.
module bpsk_demodulator (
    input  wire               clk,
    input  wire               reset, // active high
    input  wire signed [15:0] rx_sample,
    input  wire               sample_valid,
    output reg                recovered_bit,
    output reg                bit_valid
);
    reg [2:0] sample_cnt;
    reg signed [35:0] accumulator;

    function signed [15:0] carrier;
        input [2:0] idx;
        begin
            case (idx)
                3'd0: carrier = 16'sd0;
                3'd1: carrier = 16'sd707;
                3'd2: carrier = 16'sd1000;
                3'd3: carrier = 16'sd707;
                3'd4: carrier = 16'sd0;
                3'd5: carrier = -16'sd707;
                3'd6: carrier = -16'sd1000;
                3'd7: carrier = -16'sd707;
            endcase
        end
    endfunction

    wire signed [31:0] product;
    wire signed [35:0] product_ext;
    wire signed [35:0] correlation_sum;
    assign product = rx_sample * carrier(sample_cnt);
    assign product_ext = {{4{product[31]}}, product};
    assign correlation_sum = accumulator + product_ext;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            sample_cnt    <= 3'd0;
            accumulator   <= 36'sd0;
            recovered_bit <= 1'b0;
            bit_valid     <= 1'b0;
        end else begin
            bit_valid <= 1'b0;
            if (sample_valid) begin
                if (sample_cnt == 3'd7) begin
                    recovered_bit <= (correlation_sum < 0);
                    bit_valid     <= 1'b1;
                    sample_cnt    <= 3'd0;
                    accumulator   <= 36'sd0;
                end else begin
                    sample_cnt  <= sample_cnt + 3'd1;
                    accumulator <= correlation_sum;
                end
            end
        end
    end
endmodule
