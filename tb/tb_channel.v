`timescale 1ns/1ps

module tb_channel;

    reg clk = 0;
    always #5 clk = ~clk;

    reg reset = 1;
    reg signed [15:0] tx_sample = 0;
    reg sample_valid = 0;
    reg error_enable = 0;
    reg [7:0] error_symbol_index = 8'd1;

    wire signed [15:0] rx_sample;
    wire rx_valid;

    integer i;
    integer errors = 0;

    channel dut (
        .clk(clk),
        .reset(reset),
        .tx_sample(tx_sample),
        .sample_valid(sample_valid),
        .error_enable(error_enable),
        .error_symbol_index(error_symbol_index),
        .rx_sample(rx_sample),
        .rx_valid(rx_valid)
    );

    task send_sample;
        input signed [15:0] value;
        input signed [15:0] expected;
        begin
            @(negedge clk);
            tx_sample = value;
            sample_valid = 1;

            @(posedge clk);
            #1;

            if (rx_valid !== 1'b1 ||
                rx_sample !== expected) begin
                $display("FAIL: Got %0d, Expected %0d",
                         rx_sample, expected);
                errors = errors + 1;
            end
        end
    endtask

    initial begin
        repeat (2) @(negedge clk);
        reset = 0;

        // Test 1: Normal transmission
        $display("Test 1: Normal Channel");

        for (i = 0; i < 8; i = i + 1)
            send_sample(16'sd707, 16'sd707);

        // Test idle cycle
        @(negedge clk);
        sample_valid = 0;
        tx_sample = 0;

        @(posedge clk);
        #1;

        if (rx_valid !== 0 || rx_sample !== 0)
            errors = errors + 1;

        // Test 2: Invert symbol index 1
        error_enable = 1;

        $display("Test 2: Invert Symbol 1");

        for (i = 0; i < 8; i = i + 1)
            send_sample(16'sd707, -16'sd707);

        // Test 3: Symbol 2 must remain normal
        $display("Test 3: Normal Symbol 2");

        for (i = 0; i < 8; i = i + 1)
            send_sample(16'sd707, 16'sd707);

        @(negedge clk);
        sample_valid = 0;

        if (errors == 0)
            $display("CHANNEL TEST PASS");
        else
            $fatal(1, "CHANNEL TEST FAIL: %0d errors", errors);

        $finish;
    end

endmodule