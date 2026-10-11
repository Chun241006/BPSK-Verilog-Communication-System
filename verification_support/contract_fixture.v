`timescale 1ns/1ps
// HARNESS SELF-TEST FIXTURE ONLY. Not the team's RTL and not an integration sign-off.
module fixture_modulator(input clk,reset,data_bit,data_valid,
 output reg signed [15:0] bpsk_sample,output reg sample_valid);
 reg busy,current_bit;reg [2:0] index;
 function signed [15:0] carrier(input [2:0] n);
 begin case(n)
 0:carrier=0;1:carrier=707;2:carrier=1000;3:carrier=707;
 4:carrier=0;5:carrier=-707;6:carrier=-1000;7:carrier=-707;
 endcase end endfunction
 always @(posedge clk or posedge reset) begin
 if(reset) begin busy<=0;current_bit<=0;index<=0;bpsk_sample<=0;sample_valid<=0;end
 else begin
 sample_valid<=0;bpsk_sample<=0;
 if(!busy && data_valid) begin
   current_bit<=data_bit;bpsk_sample<=0;sample_valid<=1;index<=1;busy<=1;
 end else if(busy) begin
   bpsk_sample<=current_bit ? -carrier(index) : carrier(index);sample_valid<=1;
   if(index==7) begin busy<=0;index<=0;end else index<=index+1'b1;
 end
 end end
endmodule
module fixture_channel(input clk,reset,input signed [15:0] tx_sample,
 input tx_valid,error_enable,input [7:0] error_symbol_index,
 output reg signed [15:0] rx_sample,output reg rx_valid);
 reg [2:0] sample_index;reg [7:0] symbol_index;
 always @(posedge clk or posedge reset) begin
 if(reset) begin sample_index<=0;symbol_index<=0;rx_sample<=0;rx_valid<=0;end
 else begin
 rx_valid<=tx_valid;rx_sample<=0;
 if(tx_valid) begin
 rx_sample<=(error_enable && symbol_index==error_symbol_index) ? -tx_sample : tx_sample;
 if(sample_index==7) begin sample_index<=0;symbol_index<=symbol_index+1'b1;end
 else sample_index<=sample_index+1'b1;
 end end end
endmodule
module fixture_demodulator(input clk,reset,input signed [15:0] received_in,
 input sample_valid,output reg recovered_bit,bit_valid);
 reg [2:0] index; reg signed [35:0] accumulator;
 function signed [15:0] carrier(input [2:0] n);
 begin case(n)
 0:carrier=0;1:carrier=707;2:carrier=1000;3:carrier=707;
 4:carrier=0;5:carrier=-707;6:carrier=-1000;7:carrier=-707;
 endcase end endfunction
 wire signed [31:0] product=received_in*carrier(index);
 wire signed [35:0] sum=accumulator+{{4{product[31]}},product};
 always @(posedge clk or posedge reset) begin
 if(reset) begin index<=0;accumulator<=0;recovered_bit<=0;bit_valid<=0;end
 else begin bit_valid<=0;
 if(sample_valid) begin
 if(index==7) begin recovered_bit<=(sum<0);bit_valid<=1;index<=0;accumulator<=0;end
 else begin index<=index+1'b1;accumulator<=sum;end
 end end end
endmodule
module fixture_ber(input clk,reset,tx_bit,tx_valid,rx_bit,rx_valid,
 output reg [31:0] total_bits,error_bits);
 reg fifo[0:255];reg [7:0] wr,rd;reg [8:0] occupancy;
 always @(posedge clk or posedge reset) begin
 if(reset) begin wr<=0;rd<=0;occupancy<=0;total_bits<=0;error_bits<=0;end
 else begin
 if(tx_valid) begin fifo[wr]<=tx_bit;wr<=wr+1'b1;end
 if(rx_valid && occupancy!=0) begin
 rd<=rd+1'b1;total_bits<=total_bits+1;
 if(fifo[rd]!=rx_bit) error_bits<=error_bits+1;
 end
 case({tx_valid,(rx_valid && occupancy!=0)})
 2'b10:occupancy<=occupancy+1'b1;
 2'b01:occupancy<=occupancy-1'b1;
 default:occupancy<=occupancy;
 endcase
 end end
endmodule
module bpsk_top(input clk,reset,data_bit,data_valid,error_enable,
 input [7:0] error_symbol_index,output recovered_bit,bit_valid,
 output [31:0] total_bits,error_bits);
 wire signed [15:0] tx_sample,rx_sample;
 wire tx_valid,rx_valid;
 fixture_modulator tx(clk,reset,data_bit,data_valid,tx_sample,tx_valid);
 fixture_channel ch(clk,reset,tx_sample,tx_valid,error_enable,error_symbol_index,rx_sample,rx_valid);
 fixture_demodulator rx(clk,reset,rx_sample,rx_valid,recovered_bit,bit_valid);
 fixture_ber ber(clk,reset,data_bit,data_valid,recovered_bit,bit_valid,total_bits,error_bits);
endmodule
