// COS201 - BPSK Communication System
// Channel: Pass-through or controlled symbol inversion

module channel (
    input  wire               clk,
    input  wire               reset,
    input  wire signed [15:0] tx_sample,
    input  wire               sample_valid,
    input  wire               error_enable,
    input  wire [7:0]         error_symbol_index,

    output reg signed [15:0]  rx_sample,
    output reg                rx_valid
);

    // Count samples within one symbol: 0 to 7
    reg [2:0] sample_cnt;

    // Count transmitted symbols: 0 to 255
    reg [7:0] symbol_cnt;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            sample_cnt <= 3'd0;
            symbol_cnt <= 8'd0;
            rx_sample  <= 16'sd0;
            rx_valid   <= 1'b0;
        end
        else begin
            rx_valid <= 1'b0;
            rx_sample <= 16'sd0;

            if (sample_valid) begin

                // Invert the selected symbol
                if (error_enable &&
                    symbol_cnt == error_symbol_index) begin
                    rx_sample <= -tx_sample;
                end
                else begin
                    rx_sample <= tx_sample;
                end

                rx_valid <= 1'b1;

                // Advance counters
                if (sample_cnt == 3'd7) begin
                    sample_cnt <= 3'd0;
                    symbol_cnt <= symbol_cnt + 8'd1;
                end
                else begin
                    sample_cnt <= sample_cnt + 3'd1;
                end

            end
        end
    end

endmodule