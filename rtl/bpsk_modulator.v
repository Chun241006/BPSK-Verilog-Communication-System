module bpsk_modulator (
    input  wire               clk,
    input  wire               reset,        // Active-high synchronous/asynchronous reset
    input  wire               data_bit,
    input  wire               data_valid,   // 1-clock pulse for a NEW data bit
    output reg  signed [15:0] bpsk_sample,  // Signed 16-bit sample output
    output reg                sample_valid  // High when bpsk_sample is valid
);

    reg        active;
    reg [2:0]  sample_cnt;
    reg        current_bit;

    // 1. Carrier Look-Up Table (16-bit Signed LUT)
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
                default: carrier = 16'sd0;
            endcase
        end
    endfunction

    // 2. Modulator Sequential Logic
    // Bit 0 -> +carrier
    // Bit 1 -> -carrier
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            active       <= 1'b0;
            sample_cnt   <= 3'd0;
            current_bit  <= 1'b0;
            bpsk_sample  <= 16'sd0;
            sample_valid <= 1'b0;
        end else begin
            sample_valid <= 1'b0;
            bpsk_sample  <= 16'sd0;

            if (!active) begin
                if (data_valid) begin
                    current_bit  <= data_bit;
                    bpsk_sample  <= data_bit ? -carrier(3'd0) : carrier(3'd0);
                    sample_valid <= 1'b1;
                    sample_cnt   <= 3'd1;
                    active       <= 1'b1;
                end
            end else begin
                bpsk_sample  <= current_bit ? -carrier(sample_cnt) : carrier(sample_cnt);
                sample_valid <= 1'b1;

                if (sample_cnt == 3'd7) begin
                    sample_cnt <= 3'd0;
                    active     <= 1'b0; 
                end else begin
                    sample_cnt <= sample_cnt + 3'd1;
                end
            end
        end
    end

endmodule
