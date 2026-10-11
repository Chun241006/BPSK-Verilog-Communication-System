
/*
 * COS201 - BPSK Communication System
 * BER Counter with 16-entry TX Bit FIFO
 */

module ber_counter (
    input  wire        clk,
    input  wire        reset,
    input  wire        tx_bit,
    input  wire        tx_valid,
    input  wire        rx_bit,
    input  wire        rx_valid,

    output reg [31:0]  total_bits,
    output reg [31:0]  error_bits
);

    // Store up to 16 transmitted bits
    reg tx_fifo [0:15];

    // FIFO pointers and occupancy
    reg [3:0] write_ptr;
    reg [3:0] read_ptr;
    reg [4:0] fifo_count;

    wire fifo_empty;
    wire fifo_full;

    assign fifo_empty = (fifo_count == 5'd0);
    assign fifo_full  = (fifo_count == 5'd16);

    // Read an available TX bit when RX becomes valid
    wire do_read;
    wire do_write;

    assign do_read = rx_valid && !fifo_empty;

    // Allow simultaneous reading and writing,
    // including when FIFO was full.
    assign do_write = tx_valid && (!fifo_full || do_read);

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            write_ptr  <= 4'd0;
            read_ptr   <= 4'd0;
            fifo_count <= 5'd0;
            total_bits <= 32'd0;
            error_bits <= 32'd0;
        end
        else begin

            // Store accepted TX bit
            if (do_write) begin
                tx_fifo[write_ptr] <= tx_bit;
                write_ptr <= write_ptr + 4'd1;
            end

            // Compare oldest TX bit with RX bit
            if (do_read) begin
                if (tx_fifo[read_ptr] != rx_bit)
                    error_bits <= error_bits + 32'd1;

                total_bits <= total_bits + 32'd1;
                read_ptr <= read_ptr + 4'd1;
            end

            // Update FIFO occupancy
            case ({do_write, do_read})
                2'b10: fifo_count <= fifo_count + 5'd1;
                2'b01: fifo_count <= fifo_count - 5'd1;
                default: fifo_count <= fifo_count;
            endcase
        end
    end

endmodule
