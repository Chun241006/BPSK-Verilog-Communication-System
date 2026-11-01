`timescale 1ns/1ps
module tb_demodulator_ber;
reg clk=0;
always #5 clk=~clk;
reg reset=1, sample_valid=0;
reg signed [15:0] rx_sample=0;
wire recovered_bit, bit_valid;
bpsk_demodulator dut(.clk(clk),.reset(reset),.rx_sample(rx_sample),
    .sample_valid(sample_valid),.recovered_bit(recovered_bit),.bit_valid(bit_valid));

reg [15:0] bits=16'b0110010110110010; // bit index 0 = LSB
integer scenario, idx, j, got, wrong, checks, expected, expected_errors;
integer trace, summary, failures=0;
reg signed [15:0] carrier[0:7];
reg signed [15:0] s;
reg [1023:0] trace_path, summary_path, vcd_path;
initial begin
 carrier[0]=0; carrier[1]=707; carrier[2]=1000; carrier[3]=707;
 carrier[4]=0; carrier[5]=-707; carrier[6]=-1000; carrier[7]=-707;
 trace_path="simulation/results/demod_trace.csv";
 summary_path="simulation/results/demod_results.csv";
 vcd_path="simulation/results/demod_waveform.vcd";
 $dumpfile(vcd_path); $dumpvars(0,tb_demodulator_ber);
 trace=$fopen(trace_path,"w"); summary=$fopen(summary_path,"w");
 if(!trace || !summary) $fatal(1,"Cannot open outputs: run from project root; create simulation/results");
 $fdisplay(trace,"time_ns,scenario,symbol_index,sample_index,tx_bit,rx_sample,sample_valid,recovered_bit,bit_valid,correlation_sum");
 $fdisplay(summary,"scenario,bits,expected_bit_errors,observed_bit_errors,ber,rtl_mismatches,status");
 for(scenario=0;scenario<2;scenario=scenario+1) begin
  reset=1;sample_valid=0;rx_sample=0;
  repeat(3) @(negedge clk);
  reset=0; got=0;wrong=0;checks=0;
  for(idx=0;idx<16;idx=idx+1) begin
   for(j=0;j<8;j=j+1) begin
    s=bits[idx] ? -carrier[j] : carrier[j];
    if(scenario==1 && idx==3) s=-s; // flip exactly one complete BPSK symbol
    @(negedge clk); rx_sample=s; sample_valid=1;
    @(posedge clk); #1;
    $fdisplay(trace,"%0t,%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d",
       $time,scenario,idx,j,bits[idx],$signed(rx_sample),sample_valid,
       recovered_bit,bit_valid,$signed(dut.correlation_sum));
    if(j==7) begin
      expected=bits[idx] ^ (scenario==1 && idx==3);
      if(bit_valid!==1 || recovered_bit!==expected) begin
       checks=checks+1;
       $display("FAIL scenario=%0d bit=%0d expected=%0d recovered=%b valid=%b",
         scenario,idx,expected,recovered_bit,bit_valid);
      end else $display("PASS scenario=%0d bit=%0d recovered=%b",scenario,idx,recovered_bit);
      if(bit_valid===1) begin
       got=got+1;
       if(recovered_bit!==bits[idx]) wrong=wrong+1;
      end
    end else if(bit_valid!==0) begin
      checks=checks+1; $display("FAIL unexpected bit_valid scenario=%0d idx=%0d sample=%0d",scenario,idx,j);
    end
    @(negedge clk); sample_valid=0; rx_sample=0;
    @(posedge clk); #1;
    if(bit_valid!==0) begin
      checks=checks+1; $display("FAIL bit_valid not single-cycle pulse");
    end
   end
  end
  expected_errors=scenario;
  if(got!=16 || wrong!=expected_errors) checks=checks+1;
  $display("RESULT scenario=%0d decoded=%0d bit_errors=%0d BER=%0.4f mismatches=%0d %s",
      scenario,got,wrong,wrong/16.0,checks,checks==0?"PASS":"FAIL");
  $fdisplay(summary,"%0d,16,%0d,%0d,%0.6f,%0d,%s",
      scenario,expected_errors,wrong,wrong/16.0,checks,checks==0?"PASS":"FAIL");
  failures=failures+checks;
 end
 $fclose(trace); $fclose(summary);
 if(failures) $fatal(1,"DEMODULATOR FAIL mismatches=%0d",failures);
 $display("DEMODULATOR PASS: bit 0/1, clean BER=0, injected BER=1/16");
 $finish;
end
initial begin #1000000; $fatal(1,"WATCHDOG TIMEOUT"); end
endmodule
