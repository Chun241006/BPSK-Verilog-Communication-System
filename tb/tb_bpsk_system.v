`timescale 1ns/1ps

module tb_bpsk_system;
 reg clk=0;
 always #5 clk=~clk;

 reg rst_n=0, data_in=0, data_valid=0;
 wire signed [7:0] bpsk_out;
 wire sample_valid, recovered_bit, bit_valid;

 bpsk_modulator mod_dut(
  .clk(clk),
  .rst_n(rst_n),
  .data_in(data_in),
  .data_valid(data_valid),
  .bpsk_out(bpsk_out),
  .sample_valid(sample_valid)
 );

 bpsk_demodulator demod_dut(
  .clk(clk),
  .rst_n(rst_n),
  .received_in(bpsk_out),
  .sample_valid(sample_valid),
  .recovered_bit(recovered_bit),
  .bit_valid(bit_valid)
 );

 reg expected[0:2047];
 reg payload[0:2047];
 reg pending_bit=0, checking=0, expected_bit;
 reg [15:0] lfsr=16'hACE1;

 integer wr=0, rd=0, sample_index=0, sample_symbol=0;
 integer errors=0, bit_errors=0, checked=0, payload_checked=0;
 integer sample_checks=0, startup_checked=0, aborted_samples=0;
 integer reference_sample, i, before_checked;

 reg strict_mode=0, expected_valid=0;
 integer rx_sample_index=0;
 real ber;

 function integer carrier;
  input integer n;
  begin
   case(n)
    0: carrier=0;
    1: carrier=90;
    2: carrier=127;
    3: carrier=90;
    4: carrier=0;
    5: carrier=-90;
    6: carrier=-127;
    7: carrier=-90;
    default: carrier=0;
   endcase
  end
 endfunction

 always @(posedge clk) begin
  expected_valid=0;

  if(!rst_n)
   rx_sample_index=0;
  else if(checking && sample_valid===1) begin
   if(rx_sample_index==7) begin
    expected_valid=1;
    rx_sample_index=0;
   end else
    rx_sample_index=rx_sample_index+1;
  end

  #1;

  if(!rst_n) begin
   if(sample_valid!==0 || bit_valid!==0 || bpsk_out!==8'sd0 ||
      mod_dut.sample_cnt!==0 || demod_dut.sample_cnt!==0 ||
      demod_dut.accumulator!==0 || recovered_bit!==0) begin
    errors=errors+1;
    $display("FAIL: reset state at %0t",$time);
   end
  end else if(checking) begin
   if(bit_valid!==expected_valid) begin
    errors=errors+1;
    $display("FAIL: bit_valid timing at %0t",$time);
   end

   if(sample_valid!==data_valid) begin
    errors=errors+1;
    $display("FAIL: sample_valid at %0t",$time);
   end

   if(sample_valid===1) begin
    if(sample_symbol>=wr) begin
     errors=errors+1;
     $display("FAIL: unexpected symbol samples");
    end else begin
     reference_sample=carrier(sample_index);

     if(expected[sample_symbol])
      reference_sample=-reference_sample;

     if($signed(bpsk_out)!==reference_sample) begin
      errors=errors+1;
      $display(
       "FAIL: sample symbol=%0d index=%0d got=%0d expected=%0d",
       sample_symbol, sample_index,
       $signed(bpsk_out), reference_sample
      );
     end

     sample_checks=sample_checks+1;
    end

    if(sample_index==7) begin
     sample_index=0;
     sample_symbol=sample_symbol+1;
    end else
     sample_index=sample_index+1;
   end else if(bpsk_out!==8'sd0) begin
    errors=errors+1;
    $display("FAIL: idle output must be zero");
   end

   if(bit_valid===1) begin
    if(rd>=wr || rd>=sample_symbol) begin
     errors=errors+1;
     $display("FAIL: extra/early recovered bit");
    end else begin
     expected_bit=expected[rd];

     if(recovered_bit!==expected_bit) begin
      errors=errors+1;

      if(payload[rd])
       bit_errors=bit_errors+1;

      $display(
       "FAIL: bit %0d got=%b expected=%b",
       rd, recovered_bit, expected_bit
      );
     end

     if(payload[rd])
      payload_checked=payload_checked+1;
     else
      startup_checked=startup_checked+1;

     rd=rd+1;
     checked=checked+1;
    end
   end else if(bit_valid!==0) begin
    errors=errors+1;
    $display("FAIL: unknown bit_valid");
   end
  end
 end

 task reset_system;
  begin
   @(negedge clk);
   checking=0;
   rst_n=0;
   data_valid=0;
   data_in=0;

   repeat(3) @(negedge clk);

   wr=0;
   rd=0;
   sample_index=0;
   sample_symbol=0;
   pending_bit=0;
   rst_n=1;
   checking=1;
  end
 endtask

 task send_group;
  input next_bit;
  input integer stalls;
  integer k, g;
  begin
   expected[wr]=pending_bit;
   payload[wr]=(wr!=0);
   wr=wr+1;

   for(k=0;k<8;k=k+1) begin
    if(stalls!=0 && k==3) begin
     for(g=0;g<stalls;g=g+1) begin
      @(negedge clk);
      data_valid=0;
     end
    end

    @(negedge clk);
    data_valid=1;
    data_in=next_bit;
   end

   @(negedge clk);
   data_valid=0;
   pending_bit=next_bit;
  end
 endtask

 task drain;
  integer cycles;
  begin
   cycles=0;

   while(rd<wr && cycles<30) begin
    @(negedge clk);
    cycles=cycles+1;
   end

   repeat(3) @(negedge clk);

   if(rd!=wr || sample_symbol!=wr || sample_index!=0) begin
    errors=errors+1;
    $display(
     "FAIL: missing output sent_symbols=%0d received=%0d",
     wr, rd
    );
   end
  end
 endtask

 task run_pattern;
  input [7:0] bits;
  input integer stalls;
  begin
   reset_system;
   before_checked=checked;

   for(i=7;i>=0;i=i-1)
    send_group(bits[i],stalls);

   send_group(0,0);
   drain;

   $display(
    "Pattern %b stalls=%0d: checked=%0d symbols (startup + 8 payload)",
    bits, stalls, checked-before_checked
   );
  end
 endtask

 initial begin
  $dumpfile("bpsk_system.vcd");
  $dumpvars(0,tb_bpsk_system);

  strict_mode=$test$plusargs("STRICT_FIRST_BIT");

  if(strict_mode) begin
   reset_system;

   expected[0]=1;
   payload[0]=1;
   wr=1;

   repeat(8) begin
    @(negedge clk);
    data_in=1;
    data_valid=1;
   end

   @(negedge clk);
   data_valid=0;
   drain;
  end else begin
   run_pattern(8'b00000000,0);
   run_pattern(8'b11111111,0);
   run_pattern(8'b01010101,0);
   run_pattern(8'b00111001,0);
   run_pattern(8'b10110010,2);

   reset_system;

   for(i=0;i<100;i=i+1) begin
    lfsr={
     lfsr[14:0],
     lfsr[15]^lfsr[13]^lfsr[12]^lfsr[10]
    };
    send_group(lfsr[0],i%3);
   end

   send_group(0,0);
   drain;

   @(negedge clk);
   checking=0;

   repeat(4) begin
    @(negedge clk);
    data_valid=1;
    data_in=1;
   end

   @(negedge clk);
   data_valid=0;
   aborted_samples=4;

   reset_system;
   send_group(1,0);
   send_group(0,0);
   drain;
  end

  if(payload_checked>0)
   ber=1.0*bit_errors/payload_checked;
  else
   ber=0.0;

  $display(
   "SUMMARY checked=%0d payload=%0d startup=%0d sample_checks=%0d aborted_samples=%0d",
   checked, payload_checked, startup_checked,
   sample_checks, aborted_samples
  );

  $display(
   "Bit_errors=%0d BER=%f total_check_errors=%0d",
   bit_errors, ber, errors
  );

  if(errors!=0 || payload_checked==0)
   $fatal(1,"TEST FAIL");

  $display("TEST PASS (supplied RTL timing contract, ideal channel)");
  $finish;
 end

 initial begin
  #100000;
  $fatal(1,"TIMEOUT: simulation did not complete");
 end
endmodule
