
/*
 * COS201 - BPSK Communication System
 * Top-Level Integration
 */

module bpsk_top (
    input  wire        clk,
    input  wire        reset,
    input  wire        data_bit,
    input  wire        data_valid,
    input  wire        error_enable,
    input  wire [7:0]  error_symbol_index,

    output wire        recovered_bit,
    output wire        bit_valid,
    output wire [31:0] total_bits,
    output wire [31:0] error_bits
);

    // Internal connections
    wire signed [15:0] tx_sample;
    wire               tx_sample_valid;

    wire signed [15:0] rx_sample;
    wire               rx_sample_valid;

    // 1. BPSK Modulator
    bpsk_modulator u_modulator (
        .clk(clk),
        .reset(reset),
        .data_bit(data_bit),
        .data_valid(data_valid),
        .bpsk_sample(tx_sample),
        .sample_valid(tx_sample_valid)
    );

    // 2. Channel
    channel u_channel (
        .clk(clk),
        .reset(reset),
        .tx_sample(tx_sample),
        .sample_valid(tx_sample_valid),
        .error_enable(error_enable),
        .error_symbol_index(error_symbol_index),
        .rx_sample(rx_sample),
        .rx_valid(rx_sample_valid)
    );

    // 3. BPSK Demodulator
    bpsk_demodulator u_demodulator (
        .clk(clk),
        .reset(reset),
        .rx_sample(rx_sample),
        .sample_valid(rx_sample_valid),
        .recovered_bit(recovered_bit),
        .bit_valid(bit_valid)
    );

    // 4. BER Counter
    ber_counter u_ber_counter (
        .clk(clk),
        .reset(reset),
        .tx_bit(data_bit),
        .tx_valid(data_valid),
        .rx_bit(recovered_bit),
        .rx_valid(bit_valid),
        .total_bits(total_bits),
        .error_bits(error_bits)
    );

endmodule
