# BPSK Communication System - BER Design

## 1. Purpose
The BER Counter measures the bit error performance of the BPSK communication system.
The BER calculation compares:
- The original transmitted bit.
- The recovered bit from the BPSK Demodulator.
The BER block keeps track of:
- Total number of compared bits.
- Number of incorrect bits.
The Bit Error Rate is then calculated as:
BER = Error Bits / Total Bits


## 2. BER Concept
The basic BER processing flow is:

        TX Bit
           |
           v
    +--------------+
    | Store TX Bit |
    +------+-------+
           |
           | wait for recovered bit
           |
           v
     RX Recovered Bit
           |
           v
    +--------------+
    |    Compare   |
    +------+-------+
           |
       +---+---+
       |       |
      Same   Different
       |       |
       v       v
    No Error  +1 Error
       |       |
       +---+---+
           |
           v
      Total Bits
      Error Bits


## 3. BER Definition
The Bit Error Rate is defined as:
BER = Number of Error Bits / Total Number of Compared Bits

For example:
Total bits = 1000
Error bits = 10
Then:
BER = 10 / 1000
    = 0.01
Therefore:
BER = 1%


## 4. Inputs and Outputs
The BER Counter uses the following signals:
| Signal       | Direction | Width | Description              |
| ------------ | --------- | ----- | ------------------------ |
|  clk         | input     | 1     | System clock             |
|  reset       | input     | 1     | Active-high reset        |
|  tx_bit      | input     | 1     | Original transmitted bit |
|  tx_valid    | input     | 1     | Indicates new TX bit     |
|  rx_bit      | input     | 1     | Recovered bit            |
|  rx_valid    | input     | 1     | Indicates recovered bit  |
|  total_bits  | output    | 32    | Number of compared bits  |
|  error_bits  | output    | 32    | Number of incorrect bits |


## 5. BER Counter Interface
The module interface is:
module ber_counter (
    input  logic        clk,
    input  logic        reset,
    input  logic        tx_bit,
    input  logic        tx_valid,
    input  logic        rx_bit,
    input  logic        rx_valid,
    output logic [31:0] total_bits,
    output logic [31:0] error_bits
);

## 6. TX Bit Storage
The transmitted bit and recovered bit do not necessarily become valid at the same clock cycle.
One transmitted bit generates 8 BPSK samples.
The demodulator then processes these 8 samples before producing the recovered bit.
Therefore, the BER Counter needs to store the transmitted bit.
The basic process is:
TX bit
  |
  | tx_valid
  v
+----------------+
| TX Bit Register|
+----------------+
        |
        | wait
        v
Recovered Bit
        |
        | rx_valid
        v
     Compare

When:
tx_valid = 1
the BER Counter stores:
stored_tx_bit = tx_bit
The stored bit remains available until the corresponding recovered bit is received.


## 7. Bit Comparison
When:
rx_valid = 1
the BER Counter compares:
stored_tx_bit
with:
rx_bit

Case 1: Correct Bit
If:
stored_tx_bit == rx_bit
then:
total_bits = total_bits + 1
and:
error_bits
remains unchanged.

Case 2: Incorrect Bit
If:
stored_tx_bit != rx_bit
then:
total_bits = total_bits + 1
and:
error_bits = error_bits + 1


## 8. Counter Behavior
The BER Counter maintains two counters.
Total Bit Counter
total_bits
This counter represents the number of successfully compared TX/RX bit pairs.
It increments once for every:
rx_valid = 1
event.

Error Bit Counter
error_bits
This counter represents the number of mismatched TX/RX bit pairs.
It increments only when:
stored_tx_bit != rx_bit


## 9. Counter Example
Suppose the transmitted sequence is:
TX:
1 0 1 1 0
and the recovered sequence is:
RX:
1 0 0 1 0

Comparison:
Bit       TX       RX       Result
-----------------------------------
0         1        1        Correct
1         0        0        Correct
2         1        0        Error
3         1        1        Correct
4         0        0        Correct

Therefore:
Total bits = 5
Error bits = 1
and:
BER = 1 / 5
    = 0.2


## 10. Example Without Channel Errors
Assume:
TX = 10110010
RX = 10110010
All bits are correct.
Therefore:
Total bits = 8
Error bits = 0
and:
BER = 0 / 8
    = 0

Expected result:
BER = 0


## 11. Example With One Channel Error
Assume:
TX = 10110010
The Channel inverts symbol index 2.
The expected recovered sequence is:
RX = 10010010

Comparison:
TX: 1 0 1 1 0 0 1 0
RX: 1 0 0 1 0 0 1 0
         ^
         |
       Error

Therefore:
Total bits = 8
Error bits = 1
and:
BER = 1 / 8
    = 0.125


## 12. Example With Multiple Errors
Assume:
TX = 10110010
and the Channel introduces errors at symbol indices:
2
5
The expected recovered sequence is:
RX = 10010110
There are two incorrect bits.
Therefore:
Total bits = 8
Error bits = 2
and:
BER = 2 / 8
    = 0.25


## 13. Reset Behavior
When:
reset = 1
the BER Counter clears:
total_bits = 0
error_bits = 0
stored_tx_bit = 0
After reset is released:
reset = 0
the BER Counter begins normal operation.


## 14. Valid Signal Timing
The BER Counter uses valid signals to determine when data should be processed.
TX Valid
When:
tx_valid = 1
a new transmitted bit is available.
The BER Counter stores the bit.
RX Valid
When:
rx_valid = 1
a recovered bit is available.
The BER Counter compares the recovered bit with the stored transmitted bit.
Therefore:
tx_valid
   |
   v
Store TX Bit
   |
   | 8 sample cycles
   v
rx_valid
   |
   v
Compare TX and RX


## 15. BER Calculation in RTL
The RTL block does not need to continuously calculate a floating-point BER value.
Instead, the RTL maintains:
total_bits
error_bits
The BER can be calculated later as:
BER = error_bits / total_bits
This approach keeps the RTL design simple and avoids unnecessary floating-point hardware.
For simulation and reporting, BER can be calculated using:
ModelSim transcript
Testbench calculations
Python
Spreadsheet


## 16. Counter Width
The project uses 32-bit counters:
logic [31:0] total_bits;
logic [31:0] error_bits;
This allows the simulation to process a large number of bits without quickly overflowing the counters.


## 17. BER Verification Requirements
The BER Counter must be verified using at least the following cases.

Test Case 1: No Error
TX = RX
Expected:
error_bits = 0
BER = 0

Test Case 2: One Error
For 8 transmitted bits:
error_bits = 1
total_bits = 8
Expected:
BER = 0.125

Test Case 3: Two Errors
For 8 transmitted bits:
error_bits = 2
total_bits = 8
Expected:
BER = 0.25

Test Case 4: All Bits Incorrect
For:
TX = 10101010
RX = 01010101
all 8 bits are incorrect.
Expected:
total_bits = 8
error_bits = 8
BER = 1.0


## 18. Important Design Rule
The BER Counter counts errors only when a TX/RX bit pair has been successfully compared.
Therefore:
total_bits
does not represent the number of clock cycles.
It represents:
Number of compared bit pairs
Similarly:
error_bits
represents:
Number of compared bit pairs that are different


## 19. Summary
The BER Counter provides a simple deterministic method for evaluating the BPSK communication system.
The main processing is:
TX Bit
   |
   v
Store TX Bit
   |
   v
Wait for RX Bit
   |
   v
Compare
   |
   +-------- Same --------> No Error
   |
   +-------- Different ---> Error + 1
   |
   v
Update Counters
   |
   +--> total_bits
   |
   +--> error_bits

The final BER is:
BER = error_bits / total_bits

The BER Counter does not implement floating-point arithmetic in RTL.
Only the integer counters are maintained by the hardware design.