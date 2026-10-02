# BPSK Communication System - System Specification


## 1. Project Title
**BPSK Modulator and Demodulator using Verilog HDL**


## 2. Project Objective
The objective of this project is to design and simulate a basic digital Binary Phase Shift Keying (BPSK) communication system using Verilog HDL.
The system demonstrates the complete digital communication flow:
Binary Data -> BPSK Modulation -> Communication Channel -> BPSK Demodulation -> Recovered Data -> BER Calculation
The project focuses on RTL design, digital signal representation, simulation, and performance evaluation using Bit Error Rate (BER).


## 3. BPSK Principle
Binary Phase Shift Keying (BPSK) represents binary information using two carrier phases separated by 180 degrees.
The selected mapping is:
Input Bit	Phase	Digital Representation
0	        0°	    +Carrier
1	        180°    -Carrier

Therefore:
Bit 0 → +Carrier
Bit 1 → -Carrier
The project uses a digital carrier represented by a lookup table (LUT).


## 4. System Parameters
The following parameters are fixed for the initial project implementation.
Parameter	                                         Value
Modulation	                                         BPSK
Bits per Symbol	                                     1
Samples per Symbol	                                 8
Carrier LUT Size	                                 8 samples
Sample Width	                                     16 bits
Bit 0 Mapping	                                     +Carrier
Bit 1 Mapping	                                     -Carrier
Demodulation Method	                                 Correlation-based detection
Channel Model	                                     Controlled digital error model
BER Metric	                                         Bit Error Rate
Clock	                                             1 clock cycle per sample


## 5. Carrier Representation
The carrier is represented using an 8-sample lookup table.
The reference carrier is:
[0, 707, 1000, 707, 0, -707, -1000, -707]
The values represent a scaled digital sinusoidal waveform.
For a transmitted bit of 0, the modulator outputs the carrier directly:
0 → [0, 707, 1000, 707, 0, -707, -1000, -707]
For a transmitted bit of 1, the modulator outputs the inverted carrier:
1 → [0, -707, -1000, -707, 0, 707, 1000, 707]
Each bit is therefore represented by exactly 8 samples.



## 6. Modulator Specification
The BPSK Modulator converts one input bit into one 8-sample BPSK symbol.
Input
clk
reset
data_bit
data_valid

Output
bpsk_sample
sample_valid

Operation
When data_valid is asserted, the modulator accepts the input bit.
The modulator then generates 8 consecutive samples corresponding to one BPSK symbol.

For:
data_bit = 0
the carrier samples are transmitted without inversion. 

For:
data_bit = 1
the carrier samples are inverted.

The sample index runs from:
0 → 1 → 2 → ... → 7
After the eighth sample, the modulator finishes the current symbol and waits for the next valid input bit.


## 7. Channel Specification
The Channel block represents the digital transmission path between the BPSK Modulator and BPSK Demodulator.
The initial implementation uses a controlled error model rather than a complete analog noise model.

Normal Mode
When error injection is disabled:
rx_sample = tx_sample

Error Mode
When error injection is enabled for a selected symbol:
rx_sample = -tx_sample

This effectively changes the phase of the selected BPSK symbol by 180 degrees.
The controlled error model is used to demonstrate the effect of transmission errors and verify BER calculation.


## 8. Demodulator Specification
The BPSK Demodulator recovers the transmitted bit from 8 received samples.
The selected detection method is correlation-based detection.
For each received symbol:
correlation =
r[0] × c[0] +
r[1] × c[1] +
r[2] × c[2] +
...
r[7] × c[7]

where:
r[i] = received sample
c[i] = reference carrier sample

Decision Rule
correlation > 0 → recovered_bit = 0
correlation < 0 → recovered_bit = 1
The correlation value is calculated using signed arithmetic.
After all 8 samples of a symbol have been processed, the demodulator generates a recovered bit and asserts bit_valid.

## 9. BER Specification
The BER block compares the transmitted bit with the recovered bit.

For every received bit:
total_bits = total_bits + 1
If:
tx_bit != recovered_bit
then:
error_bits = error_bits + 1

The Bit Error Rate is:
BER = error_bits / total_bits
The project will use the error count and total bit count as the primary simulation results.

## 10. Reset Specification
The system uses a common reset signal:
reset
When reset is asserted:
Internal counters are cleared.
Accumulators are cleared.
Valid signals are deasserted.
Output data is returned to a known state.
After reset is released, the system is ready for normal operation.


## 11. Timing Model
The project uses a simplified synchronous digital timing model.
One clock cycle represents one sample period.
For each transmitted bit:
1 bit = 1 symbol = 8 samples
Therefore:
8 clock cycles = 1 BPSK symbol

Example:
Input bits:

1    0    1

Each bit:

8 samples
8 samples
8 samples

Total:

24 sample clock cycles


## 12. Data Flow
The complete data flow is:

             1 bit
               |
               v
      +----------------+
      | BPSK Modulator |
      +----------------+
               |
               | 8 samples
               v
      +----------------+
      |    Channel     |
      +----------------+
               |
               | 8 samples
               v
      +------------------+
      | BPSK Demodulator |
      +------------------+
               |
               | 1 recovered bit
               v
      +----------------+
      |   BER Counter  |
      +----------------+


## 13. Module List
The RTL implementation consists of the following main modules.
Module	                         Purpose
bpsk_modulator.v	             Converts input bits into BPSK samples
channel.v	                     Passes samples and optionally introduces controlled errors
bpsk_demodulator.v	             Recovers bits using correlation
ber_counter.v	                 Counts total bits and error bits
bpsk_top.v	                     Connects the complete communication system

The testbench is:
tb_bpsk_system.v
and is responsible for generating input data, controlling simulation, and checking the system behavior.

## 14. Verification Requirements
The system should be verified using several deterministic test patterns.

The minimum test patterns are:
Test Case	Input Data
Test 1	00000000
Test 2	11111111
Test 3	10101010
Test 4	10110010
Test 5	Random bit sequence

The verification should check:
Correct BPSK modulation.
Correct sample generation.
Correct channel operation.
Correct BPSK demodulation.
Correct recovered bits.
Correct BER calculation.

## 15. Expected Results
No Channel Error
When the channel does not introduce errors:
TX bits = RX bits
Therefore:
error_bits = 0
BER = 0

Controlled Channel Error
When a selected symbol is inverted:
TX bit ≠ RX bit
for the affected symbol.
Therefore:
error_bits > 0
and the calculated BER should reflect the number of affected bits.


## 16. Project Scope
The initial project implementation includes:
BPSK modulation
Digital carrier LUT
8 samples per symbol
Correlation-based BPSK demodulation
Controlled digital channel errors
BER calculation
RTL simulation
Functional verification

The following features are outside the initial project scope:
AWGN channel modeling
PLL
Costas loop
Carrier recovery
Timing recovery
QPSK
Adaptive equalization
FPGA hardware implementation
These features may be considered future extensions but are not required for the initial project.


## 17. Design Constraints
The following design decisions are fixed for the initial implementation:
One input bit represents one BPSK symbol.
Each symbol contains 8 samples.
The carrier is represented by an 8-entry LUT.
Bit 0 uses the positive carrier.
Bit 1 uses the inverted carrier.
The demodulator uses correlation-based detection.
The channel uses a controlled digital error model.
The system is implemented using synchronous Verilog RTL.
The system is verified using simulation.
BER is used as the main performance metric.
Any change to these core specifications should be discussed and agreed upon by the team before implementation.