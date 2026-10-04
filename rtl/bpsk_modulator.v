module bpsk_modulator #(
    parameter DATA_WIDTH = 8,       // Bit resolution of output carrier
    parameter SAMPLES_PER_SYM = 8   // 8 samples per symbol
)(
    input  wire                    clk,
    input  wire                    rst_n,
    input  wire                    data_in,
    input  wire                    data_valid,
    output reg  signed [DATA_WIDTH-1:0] bpsk_out,
    output reg                    sample_valid
);

    // 1. Sample Counter (0 to 7) & Current Bit Latch
    reg [2:0] sample_cnt;
    reg       current_bit;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sample_cnt  <= 3'd0;
            current_bit <= 1'b0;
        end else if (data_valid) begin
            if (sample_cnt == SAMPLES_PER_SYM - 1) begin
                sample_cnt  <= 3'd0;
                current_bit <= data_in; // Chốt bit dữ liệu mới
            end else begin
                sample_cnt  <= sample_cnt + 1'b1;
            end
        end
    end

    // 2. Carrier Look-Up Table (LUT) - 8 samples of Sine wave
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
  
    wire signed [DATA_WIDTH-1:0] lut_val = carrier_lut[sample_cnt];

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            bpsk_out     <= {DATA_WIDTH{1'b0}};
            sample_valid <= 1'b0;
        end else if (data_valid) begin
            sample_valid <= 1'b1;
            if (current_bit == 1'b0) begin
                bpsk_out <= lut_val;   // Bit 0 -> +carrier
            end else begin
                bpsk_out <= -lut_val;  // Bit 1 -> -carrier
            end
        end else begin
            bpsk_out     <= {DATA_WIDTH{1'b0}};
            sample_valid <= 1'b0;
        end
    end

endmodule
