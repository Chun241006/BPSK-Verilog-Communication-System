# BPSK Communication System - Channel Design

## 1. Purpose
The Channel module represents the digital transmission path between the BPSK Modulator and the BPSK Demodulator.
The purpose of the Channel module is to:
1. Pass transmitted BPSK samples to the receiver.
2. Support controlled error injection.
3. Allow a selected BPSK symbol to be inverted.
4. Provide a deterministic environment for BER verification.
The channel does not implement a physical analog communication channel.


## 2. Channel Concept
The basic signal flow is:
BPSK Modulator
      |
      | tx_sample
      v
+----------------+
|    Channel     |
+----------------+
      |
      | rx_sample
      v
BPSK Demodulator

The Channel receives one BPSK sample per clock cycle and produces one received sample.


## 3. Channel Modes
The Channel supports two operating modes.
3.1 Normal Mode
When:
error_enable = 0
the channel does not modify the transmitted signal.
Therefore:
rx_sample = tx_sample

Example:
TX sample:  707
RX sample:  707

Another example:
TX sample: -1000
RX sample: -1000

3.2 Error Injection Mode
When:
error_enable = 1
the channel inverts the samples belonging to the selected symbol.
The inversion operation is:
rx_sample = -tx_sample

Example:
TX sample:  707
RX sample: -707

Another example:
TX sample: -1000
RX sample: 1000

This operation is equivalent to changing the phase of the BPSK symbol by 180 degrees.


## 4. Symbol Definition
One input bit represents one BPSK symbol.
The project uses:
1 bit = 1 symbol
Each symbol contains exactly 8 samples:
1 symbol = 8 samples
Therefore:
8 clock cycles = 1 BPSK symbol
The sample positions inside one symbol are:
Sample index:
0
1
2
3
4
5
6
7
After sample index 7, the next valid sample belongs to the next symbol.


## 5. Symbol Counter
The Channel maintains a symbol counter.
The counter starts from:
0
and identifies the symbol currently being transmitted.

Example:
Symbol 0 → samples 0 to 7
Symbol 1 → samples 0 to 7
Symbol 2 → samples 0 to 7
Symbol 3 → samples 0 to 7
The symbol counter increments after the eighth valid sample of a symbol.

Therefore:
8 valid samples → symbol counter + 1
The counter wraps around naturally when the maximum counter value is reached.


## 6. Error Symbol Selection
The signal:
error_symbol_index
specifies which symbol should be inverted when error injection is enabled.
The first symbol has index:
0
The second symbol:
1
The third symbol:
2
and so on.

For example:
error_enable = 1
error_symbol_index = 2
means:
Symbol 0 → normal
Symbol 1 → normal
Symbol 2 → inverted
Symbol 3 → normal
Symbol 4 → normal
...


## 7. Sample Processing
For every valid transmitted sample:
sample_valid = 1
the Channel performs the following operation.

Case 1: Error Disabled
if error_enable = 0

rx_sample = tx_sample

Case 2: Error Enabled but Current Symbol is Not Selected
if error_enable = 1
and current_symbol != error_symbol_index

rx_sample = tx_sample

Case 3: Error Enabled and Current Symbol is Selected
if error_enable = 1
and current_symbol == error_symbol_index

rx_sample = -tx_sample

The output valid signal follows the input valid signal:
rx_valid = sample_valid


## 8. Channel Processing Flow
The complete channel processing flow is:

             tx_sample
                 |
                 v
        +----------------+
        | sample_valid ? |
        +-------+--------+
                |
             valid
                |
                v
        +----------------+
        | Check Channel  |
        | Error Enable   |
        +-------+--------+
                |
        +-------+-------+
        |               |
     Disabled         Enabled
        |               |
        |               v
        |       Compare Current
        |       Symbol Index
        |               |
        |        +------+------+
        |        |             |
        |      Match        No Match
        |        |             |
        |        v             v
        |    -tx_sample     tx_sample
        |        |             |
        +--------+-------------+
                 |
                 v
             rx_sample

             
## 9. Timing Example
Assume:
error_enable = 1
error_symbol_index = 1
The input contains three symbols:
Symbol 0
Symbol 1
Symbol 2
Each symbol contains 8 samples.
The Channel behavior is:

Clock       Symbol       Operation
-----------------------------------
0           0            Normal
1           0            Normal
2           0            Normal
3           0            Normal
4           0            Normal
5           0            Normal
6           0            Normal
7           0            Normal

8           1            Invert
9           1            Invert
10          1            Invert
11          1            Invert
12          1            Invert
13          1            Invert
14          1            Invert
15          1            Invert

16          2            Normal
17          2            Normal
18          2            Normal
19          2            Normal
20          2            Normal
21          2            Normal
22          2            Normal
23          2            Normal

Therefore, only Symbol 1 is inverted.


## 10. Example
Assume the transmitted bit sequence is:
1 0 1 1
The symbols are:
Symbol 0 → bit 1
Symbol 1 → bit 0
Symbol 2 → bit 1
Symbol 3 → bit 1
If:
error_enable = 1
error_symbol_index = 1
then Symbol 1 is inverted.
The effective received symbol sequence becomes:
Symbol 0 → normal
Symbol 1 → inverted
Symbol 2 → normal
Symbol 3 → normal
Since BPSK uses opposite polarities for the two bits, the inverted Symbol 1 is detected as the opposite bit by the demodulator.
Therefore:
TX:
1 0 1 1
RX:
1 1 1 1
There is one bit error.


## 11. Relation to BER
The Channel is designed specifically to support deterministic BER testing.
For example, if the testbench transmits:
10110010
and selects:
error_symbol_index = 2
then the third symbol is inverted.
The expected recovered sequence becomes:
10010010
Therefore:
Total bits = 8
Error bits = 1
and:
BER = 1 / 8 = 0.125
This provides a predictable result that can be checked automatically by the testbench.


## 12. Channel Interface
The Channel module uses the following interface:
module channel (
    input  logic               clk,
    input  logic               reset,
    input  logic signed [15:0] tx_sample,
    input  logic               sample_valid,
    input  logic               error_enable,
    input  logic        [7:0]  error_symbol_index,
    output logic signed [15:0] rx_sample,
    output logic               rx_valid
);


## 13. Reset Behavior
When:
reset = 1
the Channel shall:
Clear the symbol counter.
Set rx_sample to zero.
Set rx_valid to zero.
After reset is released:
reset = 0
the Channel is ready to process valid samples.


## 14. Design Constraints
The Channel implementation follows these constraints:
One clock cycle represents one sample.
One symbol contains 8 samples.
The symbol counter increments every 8 valid samples.
Symbol indexing starts from 0.
Error injection is controlled by error_enable.
The affected symbol is selected by error_symbol_index.
Error injection is implemented by sign inversion.
No random noise is required.
No AWGN model is required.
The Channel must preserve the sample timing.
rx_valid follows sample_valid.
The design must use signed arithmetic for BPSK samples.


## 15. Verification Requirements
The Channel should be tested using at least the following cases.

Test Case 1: No Error
error_enable = 0
Expected:
rx_sample = tx_sample
for every valid sample.

Test Case 2: Error on First Symbol
error_enable = 1
error_symbol_index = 0
Expected:
Symbol 0 → inverted
Symbol 1 → normal
Symbol 2 → normal
...

Test Case 3: Error on Middle Symbol
error_enable = 1
error_symbol_index = 2
Expected:
Symbol 0 → normal
Symbol 1 → normal
Symbol 2 → inverted
Symbol 3 → normal
...

Test Case 4: Error on Last Tested Symbol
For a test sequence containing 8 symbols:
error_symbol_index = 7
Expected:
Symbol 7 → inverted
and all previous symbols remain unchanged.


## 16. Summary
The Channel provides a simple and deterministic transmission model.
Its main operation is:
Normal:
TX sample ───────────────> RX sample
Selected error:
TX sample ───> Sign Inversion ───> RX sample

The controlled error model allows the team to verify the BPSK receiver and BER calculation without introducing the additional complexity of a physical noise model.