module bpsk_demodulator #(
    parameter DATA_WIDTH = 8,          // Bit resolution of input signal
    parameter SAMPLES_PER_SYM = 8      // 8 samples per symbol
)(
    input  wire                         clk,
    input  wire                         rst_n,
    input  wire signed [DATA_WIDTH-1:0] received_in,
    input  wire                         sample_valid,

    output reg                          recovered_bit,
    output reg                          bit_valid
);

    // 1. Sample Counter & Correlation Accumulator
    reg [2:0] sample_cnt;

    // Accumulator stores the sum of correlation products
    reg signed [DATA_WIDTH*2+3:0] accumulator;

    // 2. Carrier Look-Up Table (LUT)
    reg signed [DATA_WIDTH-1:0] carrier_lut [0:SAMPLES_PER_SYM-1];

    initial begin
        carrier_lut[0] =  8'sd0;    //   0 deg
        carrier_lut[1] =  8'sd90;   //  45 deg
        carrier_lut[2] =  8'sd127;  //  90 deg
        carrier_lut[3] =  8'sd90;   // 135 deg
        carrier_lut[4] =  8'sd0;    // 180 deg
        carrier_lut[5] = -8'sd90;   // 225 deg
        carrier_lut[6] = -8'sd127;  // 270 deg
        carrier_lut[7] = -8'sd90;   // 315 deg
    end

    // 3. Correlation Logic
    wire signed [DATA_WIDTH*2-1:0] correlation_product;
    wire signed [DATA_WIDTH*2+3:0] correlation_sum;

    assign correlation_product =
        received_in * carrier_lut[sample_cnt];

    // Add current product to previous accumulated value
    assign correlation_sum = accumulator + correlation_product;

    // 4. Accumulation & Decision Logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sample_cnt    <= 3'd0;
            accumulator   <= 0;
            recovered_bit <= 1'b0;
            bit_valid     <= 1'b0;
        end else begin
            bit_valid <= 1'b0;

            if (sample_valid) begin
                if (sample_cnt == SAMPLES_PER_SYM - 1) begin
                    // Complete one symbol (8 samples)
                    // Make decision using the full correlation result
                    if (correlation_sum < 0)
                        recovered_bit <= 1'b1;
                    else
                        recovered_bit <= 1'b0;

                    bit_valid   <= 1'b1;
                    sample_cnt  <= 3'd0;
                    accumulator <= 0;
                end else begin
                    // Continue accumulating correlation products
                    accumulator <= correlation_sum;
                    sample_cnt  <= sample_cnt + 1'b1;
                end
            end
        end
    end

endmodule
