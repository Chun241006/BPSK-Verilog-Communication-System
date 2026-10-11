`timescale 1ns/1ps
`include "model/reference/case_count.vh"
// Frozen 16-bit contract. Python-produced memories are the ONLY data oracle.
// Input on negedge; outputs sampled #1 after posedge to avoid NBA races.
module tb_bpsk_system;
 reg clk=0; always #5 clk=~clk;
 reg reset=1, data_bit=0, data_valid=0, error_enable=0;
 reg [7:0] error_symbol_index=0;
 wire recovered_bit,bit_valid;
 wire [31:0] total_bits,error_bits;
 bpsk_top dut(.clk(clk),.reset(reset),.data_bit(data_bit),.data_valid(data_valid),
 .error_enable(error_enable),.error_symbol_index(error_symbol_index),
 .recovered_bit(recovered_bit),.bit_valid(bit_valid),.total_bits(total_bits),.error_bits(error_bits));
 reg [15:0] vectors[0:`REF_BITS-1], golden_rx_bits[0:`REF_BITS-1];
 reg signed [15:0] golden_tx[0:`REF_BITS*8-1],golden_rx[0:`REF_BITS*8-1];
 reg [15:0] lengths[0:`CASE_COUNT-1],offsets[0:`CASE_COUNT-1],indices[0:`CASE_COUNT-1],
 errors[0:`CASE_COUNT-1],gaps[0:`CASE_COUNT-1],mid[0:`CASE_COUNT-1];
 integer cid=0,base=0,sent=0,decoded=0,ntx=0,nrx=0,failures=0;
 integer baseline=0,expected_total=0,expected_errors=0,k,waited,logfile,tablefile,tracefile;
 integer nbit,nsample;
 reg monitor=0,pending_valid,pending_bit;
 reg previous_tx_valid=0;
 reg signed [15:0] previous_tx_sample=0;
 reg [7:0] previous_symbol=0; integer channel_samples=0;
 reg previous_invert=0;
 string results_dir,scope_name,vcd_path,log_path,table_path,trace_path;
 task fail;
 input string reason;
 begin failures=failures+1; $display("FAIL case=%0d @%0t: %s",cid,$time,reason);
 $fdisplay(logfile,"FAIL case=%0d @%0t: %s",cid,$time,reason); end
 endtask
 always @(posedge clk) begin
 // BER consumes the previous cycle's bit_valid. Channel consumes previous TX.
 pending_valid=bit_valid; pending_bit=recovered_bit;
 #1;
 if(reset) begin
   if(dut.tx_valid!==0 || dut.rx_valid!==0 || bit_valid!==0 || total_bits!==0 || error_bits!==0)
     fail("reset did not clear valid/counters");
   previous_tx_valid=0; previous_tx_sample=0; channel_samples=0;
 end else if(monitor) begin
   if(dut.tx_valid!==1'b0 && dut.tx_valid!==1'b1) fail("unknown TX valid");
   if(dut.rx_valid!==1'b0 && dut.rx_valid!==1'b1) fail("unknown RX valid");
   if(bit_valid!==1'b0 && bit_valid!==1'b1) fail("unknown bit_valid");
   if(dut.rx_valid!==previous_tx_valid) fail("channel valid is not delayed by one clock");
   if(previous_tx_valid && $signed(dut.rx_sample)!==(previous_invert ? -previous_tx_sample : previous_tx_sample))
     fail("channel sample pipeline mismatch");
   if(dut.tx_valid===1) begin
     if(ntx>=sent*8) fail("extra TX sample");
     else if(dut.tx_sample!==golden_tx[base*8+ntx]) fail($sformatf("TX[%0d] RTL=%0d golden=%0d",ntx,$signed(dut.tx_sample),golden_tx[base*8+ntx]));
     ntx=ntx+1;
   end
   if(dut.rx_valid===1) begin
     if(nrx>=sent*8) fail("extra RX sample");
     else if(dut.rx_sample!==golden_rx[base*8+nrx]) fail($sformatf("RX[%0d] RTL=%0d golden=%0d",nrx,$signed(dut.rx_sample),golden_rx[base*8+nrx]));
     nrx=nrx+1;
   end
   if(pending_valid===1) begin
     if(expected_total>=sent) fail("BER consumed unexpected decoded bit");
     else begin
       // Expected counters use the golden bit, not the observed recovered bit.
       if(vectors[base+expected_total][0] != golden_rx_bits[base+expected_total][0]) expected_errors=expected_errors+1;
       expected_total=expected_total+1;
     end
   end
   if(total_bits!==expected_total || error_bits!==expected_errors) fail("BER counters mismatch at current clock");
   if(bit_valid===1) begin
     if(decoded>=sent) fail("extra recovered bit");
     else if(recovered_bit!==golden_rx_bits[base+decoded][0]) fail($sformatf("bit[%0d] RTL=%b golden=%b",decoded,recovered_bit,golden_rx_bits[base+decoded][0]));
     decoded=decoded+1;
   end
   previous_tx_valid=dut.tx_valid; previous_tx_sample=dut.tx_sample;
   previous_invert=error_enable && ((channel_samples/8)%256==error_symbol_index);
   if(dut.tx_valid===1) channel_samples=channel_samples+1;
 end
 if(monitor) begin
   $fdisplay(tracefile,"%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d",$time,cid,data_valid,data_bit,dut.tx_valid,$signed(dut.tx_sample),dut.rx_valid,$signed(dut.rx_sample),bit_valid,recovered_bit,total_bits,error_bits,reset);
 end
 end
 task do_reset;
 begin
 @(negedge clk); reset=1; monitor=1; data_valid=0;
 repeat(3) @(negedge clk);
 sent=0;decoded=0;ntx=0;nrx=0;expected_total=0;expected_errors=0;
 reset=0;
 end endtask
 task send_bit;
 input b; input integer gap;
 begin
 @(negedge clk); data_bit=b;data_valid=1;sent=sent+1;
 @(negedge clk);data_valid=0;
 repeat(gap-2) @(negedge clk);
 end endtask
 initial begin
 results_dir="simulation/results"; scope_name="team_rtl";
 if($value$plusargs("RESULTS_DIR=%s",results_dir)) begin end
 if($value$plusargs("SCOPE=%s",scope_name)) begin end
 vcd_path={results_dir,"/bpsk_system.vcd"};
 logfile=$fopen({results_dir,"/test_results.txt"},"w");
 tablefile=$fopen({results_dir,"/test_results.csv"},"w");
 tracefile=$fopen({results_dir,"/sample_trace.csv"},"w");
 if(!logfile || !tablefile || !tracefile) $fatal(1,"Cannot open result files");
 $dumpfile(vcd_path);$dumpvars(0,tb_bpsk_system);
 $fdisplay(logfile,"Scope: %s; no PASS applies to another RTL implementation",scope_name);
 $fdisplay(tablefile,"case_id,status,bits,tx_samples,rx_samples,recovered_bits,total_bits,error_bits,expected_errors,ber,mismatches,scope");
 $fdisplay(tracefile,"time_ns,case_id,data_valid,data_bit,tx_valid,tx_sample,rx_valid,rx_sample,bit_valid,recovered_bit,total_bits,error_bits,reset");
 $readmemh("model/reference/vectors.mem",vectors);
 $readmemh("model/reference/golden_tx_samples.mem",golden_tx);
 $readmemh("model/reference/golden_rx_samples.mem",golden_rx);
 $readmemh("model/reference/golden_rx_bits.mem",golden_rx_bits);
 $readmemh("model/reference/case_lengths.mem",lengths);
 $readmemh("model/reference/case_offsets.mem",offsets);
 $readmemh("model/reference/case_error_index.mem",indices);
 $readmemh("model/reference/case_errors.mem",errors);
 $readmemh("model/reference/case_gaps.mem",gaps);
 $readmemh("model/reference/case_reset_mid.mem",mid);
 for(cid=0;cid<`CASE_COUNT;cid=cid+1) begin
   baseline=failures;base=offsets[cid];monitor=0;
   do_reset;
   error_enable=(indices[cid]!=16'hffff);error_symbol_index=indices[cid][7:0];
   if(mid[cid]) begin
     @(negedge clk); data_bit=1; data_valid=1;sent=1;
     @(negedge clk);data_valid=0;
     repeat(2) @(negedge clk);
     do_reset; // partial TX/RX samples and BER FIFO are discarded
   end
   for(k=0;k<lengths[cid];k=k+1) send_bit(vectors[base+k][0],gaps[cid]);
   waited=0;
   while((decoded<sent || total_bits<sent) && waited<40) begin @(negedge clk);waited=waited+1;end
   if(waited==40) fail("drain timeout / missing decoded bits");
   repeat(16) @(negedge clk); // detect stale output or extra events during idle
   if(ntx!==sent*8 || nrx!==sent*8 || decoded!==sent || total_bits!==sent || error_bits!==errors[cid]) fail("final sample/bit/error counts mismatch");
   if(failures==baseline) begin
     $display("PASS case=%0d bits=%0d TX=%0d RX=%0d errors=%0d",cid,sent,ntx,nrx,error_bits);
     $fdisplay(logfile,"PASS case=%0d bits=%0d TX=%0d RX=%0d recovered=%0d total=%0d errors=%0d",cid,sent,ntx,nrx,decoded,total_bits,error_bits);
   end else $fdisplay(logfile,"FAIL case=%0d mismatches=%0d",cid,failures-baseline);
   if(sent>0) $fdisplay(tablefile,"%0d,%s,%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0.6f,%0d,%s",cid,failures==baseline ? "PASS":"FAIL",sent,ntx,nrx,decoded,total_bits,error_bits,errors[cid],1.0*error_bits/total_bits,failures-baseline,scope_name);
   else $fdisplay(tablefile,"%0d,%s,0,%0d,%0d,%0d,%0d,%0d,0,N/A,%0d,%s",cid,failures==baseline ? "PASS":"FAIL",ntx,nrx,decoded,total_bits,error_bits,failures-baseline,scope_name);
 end
 $fdisplay(logfile,"SUMMARY cases=%0d mismatches=%0d scope=%s",`CASE_COUNT,failures,scope_name);
 $fclose(logfile);$fclose(tablefile);$fclose(tracefile);
 if(failures) $fatal(1,"TEST FAIL: %0d mismatches",failures);
 $display("TEST PASS: %0d cases; scope=%s",`CASE_COUNT,scope_name);$finish;
 end
 initial begin #1000000; $fatal(1,"WATCHDOG TIMEOUT");end
endmodule
