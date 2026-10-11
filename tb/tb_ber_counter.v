
`timescale 1ns/1ps

module tb_ber_counter;

    reg clk = 0;
    always #5 clk = ~clk;

    reg reset = 1;
    reg tx_bit = 0;
    reg tx_valid = 0;
    reg rx_bit = 0;
    reg rx_valid = 0;

    wire [31:0] total_bits;
    wire [31:0] error_bits;

    integer errors = 0;

    ber_counter dut (
        .clk(clk),
        .reset(reset),
        .tx_bit(tx_bit),
        .tx_valid(tx_valid),
        .rx_bit(rx_bit),
        .rx_valid(rx_valid),
        .total_bits(total_bits),
        .error_bits(error_bits)
    );

    // Apply inputs for one clock cycle
    task tick;
        input txv, txb, rxv, rxb;
        begin
            @(negedge clk);
            tx_valid = txv;
            tx_bit = txb;
            rx_valid = rxv;
            rx_bit = rxb;

            @(posedge clk);
            #1;
        end
    endtask

    task reset_dut;
        begin
            @(negedge clk);
            reset = 1;
            tx_valid = 0;
            rx_valid = 0;

            repeat (2) @(negedge clk);
            reset = 0;
        end
    endtask

    task check_result;
        input integer expected_total;
        input integer expected_errors;
        begin
            if (total_bits !== expected_total ||
                error_bits !== expected_errors) begin

                $display("FAIL: total=%0d errors=%0d, expected=%0d/%0d",
                    total_bits, error_bits,
                    expected_total, expected_errors);

                errors = errors + 1;
            end
            else begin
                $display("PASS: total=%0d errors=%0d",
                    total_bits, error_bits);
            end
        end
    endtask

    // Send 8 TX bits, then return 8 RX bits
    task run_case;
        input [7:0] bits;
        input [7:0] flip_mask;
        input integer expected_errors;
        integer i;
        begin
            reset_dut();

            $display("Test: TX=%b flip_mask=%b",
                bits, flip_mask);

            for (i = 7; i >= 0; i = i - 1)
                tick(1, bits[i], 0, 0);

            for (i = 7; i >= 0; i = i - 1)
                tick(0, 0, 1, bits[i] ^ flip_mask[i]);

            check_result(8, expected_errors);
        end
    endtask

    initial begin

        // Test 1: No errors
        run_case(8'b10110010, 8'b00000000, 0);

        // Test 2: One error
        run_case(8'b10110010, 8'b00100000, 1);

        // Test 3: Two errors
        run_case(8'b10110010, 8'b00100100, 2);

        // Test 4: All bits incorrect
        run_case(8'b10101010, 8'b11111111, 8);

        // Test 5: Simultaneous FIFO read/write
        reset_dut();
        $display("Test: Simultaneous TX/RX");

        tick(1, 1, 0, 0);
        tick(1, 0, 1, 1);
        tick(0, 0, 1, 1);

        check_result(2, 1);

        // Test 6: RX while FIFO is empty
        $display("Test: Empty FIFO");

        tick(0, 0, 1, 0);
        check_result(2, 1);

        if (errors == 0)
            $display("BER COUNTER TEST PASS");
        else
            $fatal(1, "BER COUNTER TEST FAIL");

        $finish;
    end

endmodule
