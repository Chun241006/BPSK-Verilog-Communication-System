# BPSK Communication System - Interface Specification

## 1. Purpose
This document defines the interfaces between the main RTL modules of the BPSK communication system.
The interface specification is used as a common contract for all team members.
The following modules are covered:
- bpsk_modulator.v
- channel.v
- bpsk_demodulator.v
- ber_counter.v
- bpsk_top.v
All team members should follow these interfaces during implementation.



## 2. System-Level Connection
The main signal flow is:
data_bit -> BPSK Modulator -> bpsk_sample -> Channel -> rx_sample -> BPSK Demodulator -> recovered_bit -> BER Counter
The valid signals are used to indicate when input or output data is valid.


## 3. Common Signal Conventions
3.1 Clock
All RTL modules use a common clock:
clk
The system operates on the rising edge of clk.

3.2 Reset
All main RTL modules use:
reset
The reset is active high.
When:
reset = 1
internal counters, accumulators, state variables, and output valid signals are initialized.
When:
reset = 0
the module operates normally.

3.3 Sample Width
All BPSK samples use a signed 16-bit representation:
signed [15:0]
Therefore:
Sample range = -32768 to +32767
The carrier LUT uses the following values:
[0, 707, 1000, 707, 0, -707, -1000, -707]


## 4. BPSK Modulator Interface
4.1 Module
bpsk_modulator.v

4.2 Purpose
The BPSK Modulator converts one binary input bit into an 8-sample BPSK symbol.
The mapping is:
0 → +Carrier
1 → -Carrier

4.3 Port Definition
| Port           | Direction | Width | Type   | Description                   |
| -------------- | --------- | ----- | ------ | ----------------------------- |
|  clk           | input     | 1     | logic  | System clock                  |
|  reset         | input     | 1     | logic  | Active-high reset             |
|  data_bit      | input     | 1     | logic  | Input binary data             |
|  data_valid    | input     | 1     | logic  | Indicates a new input bit     |
|  bpsk_sample   | output    | 16    | signed | Generated BPSK sample         |
|  sample_valid  | output    | 1     | logic  | Indicates valid output sample |

4.4 Interface
The module interface should follow:
module bpsk_modulator (
    input  logic               clk,
    input  logic               reset,
    input  logic               data_bit,
    input  logic               data_valid,
    output logic signed [15:0] bpsk_sample,
    output logic               sample_valid
);

4.5 Operation
When:
data_valid = 1
the modulator accepts data_bit.
The modulator then generates 8 samples.

For:
data_bit = 0
the output is:
[0, 707, 1000, 707, 0, -707, -1000, -707]

For:
data_bit = 1
the output is:
[0, -707, -1000, -707, 0, 707, 1000, 707]
sample_valid must be asserted when bpsk_sample contains a valid sample.

## 5. Channel Interface

5.1 Module
channel.v

5.2 Purpose
The Channel transfers BPSK samples from the transmitter to the receiver.
It can operate in:
Normal mode
Controlled error mode

5.3 Port Definition
| Port                 | Direction | Width | Type   | Description               |
| -------------------- | --------- | ----- | ------ | ------------------------- |
|  clk                 | input     | 1     | logic  | System clock              |
|  reset               | input     | 1     | logic  | Active-high reset         |
|  tx_sample           | input     | 16    | signed | Transmitted BPSK sample   |
|  sample_valid        | input     | 1     | logic  | Indicates valid TX sample |
|  error_enable        | input     | 1     | logic  | Enables controlled error  |
|  error_symbol_index  | input     | 8     | logic  | Symbol index to invert    |
|  rx_sample           | output    | 16    | signed | Received BPSK sample      |
|  rx_valid            | output    | 1     | logic  | Indicates valid RX sample |

5.4 Interface
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

5.5 Normal Operation
When:
error_enable = 0
the channel passes the sample without modification:
rx_sample = tx_sample

5.6 Error Operation
When:
error_enable = 1
the channel inverts the samples belonging to the selected symbol:
rx_sample = -tx_sample
The symbol to be affected is selected using:
error_symbol_index
The channel maintains a symbol counter.

For example:
error_symbol_index = 3
means that the fourth transmitted symbol is inverted.
The first symbol has index:
0
The second symbol:
1
and so on.


## 6. BPSK Demodulator Interface

6.1 Module
bpsk_demodulator.v

6.2 Purpose
The BPSK Demodulator converts received BPSK samples back into binary data.
The demodulator uses correlation-based detection.

6.3 Port Definition
| Port            | Direction | Width | Type   | Description                   |
| --------------- | --------- | ----- | ------ | ----------------------------- |
|  clk            | input     | 1     | logic  | System clock                  |
|  reset          | input     | 1     | logic  | Active-high reset             |
|  rx_sample      | input     | 16    | signed | Received BPSK sample          |
|  sample_valid   | input     | 1     | logic  | Indicates valid RX sample     |
|  recovered_bit  | output    | 1     | logic  | Recovered binary bit          |
|  bit_valid      | output    | 1     | logic  | Indicates valid recovered bit |

6.4 Interface
module bpsk_demodulator (
    input  logic               clk,
    input  logic               reset,
    input  logic signed [15:0] rx_sample,
    input  logic               sample_valid,
    output logic               recovered_bit,
    output logic               bit_valid
);

6.5 Operation
The demodulator collects 8 received samples.
For each sample:
correlation += rx_sample × reference_carrier
After 8 samples:
if correlation > 0:
    recovered_bit = 0

if correlation < 0:
    recovered_bit = 1

Then:
bit_valid = 1
for one clock cycle.

## 7. BER Counter Interface

7.1 Module
ber_counter.v

7.2 Purpose
The BER Counter compares transmitted bits with recovered bits and counts the number of errors.
7.3 Port Definition
| Port         | Direction | Width | Type     | Description              |
| ------------ | --------- | ----- | -------- | ------------------------ |
|  clk         | input     | 1     | logic    | System clock             |
|  reset       | input     | 1     | logic    | Active-high reset        |
|  tx_bit      | input     | 1     | logic    | Transmitted bit          |
|  tx_valid    | input     | 1     | logic    | Indicates valid TX bit   |
|  rx_bit      | input     | 1     | logic    | Recovered bit            |
|  rx_valid    | input     | 1     | logic    | Indicates valid RX bit   |
|  total_bits  | output    | 32    | unsigned | Number of processed bits |
|  error_bits  | output    | 32    | unsigned | Number of incorrect bits |

7.4 Interface
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

7.5 Operation
When a new transmitted bit is accepted:
tx_valid = 1
the BER counter stores the transmitted bit.
When a recovered bit becomes available:
rx_valid = 1
the stored transmitted bit is compared with rx_bit.
If:
tx_bit == rx_bit
then:
error_bits remains unchanged
If:
tx_bit != rx_bit
then:
error_bits = error_bits + 1
For every successfully compared bit:
total_bits = total_bits + 1

## 8. Top-Level Interface

8.1 Module
bpsk_top.v

8.2 Purpose
The top-level module connects the BPSK Modulator, Channel, BPSK Demodulator, and BER Counter.

8.3 Proposed Port Definition
| Port                 | Direction | Width | Description               |
| -------------------- | --------- | ----- | ------------------------- |
|  clk                 | input     | 1     | System clock              |
|  reset               | input     | 1     | Active-high reset         |
|  data_bit            | input     | 1     | Input binary data         |
|  data_valid          | input     | 1     | New input bit valid       |
|  error_enable        | input     | 1     | Enable channel error      |
|  error_symbol_index  | input     | 8     | Symbol selected for error |
|  recovered_bit       | output    | 1     | Recovered binary data     |
|  bit_valid           | output    | 1     | Recovered bit valid       |
|  total_bits          | output    | 32    | Number of compared bits   |
|  error_bits          | output    | 32    | Number of error bits      |

8.4 Interface
module bpsk_top (
    input  logic        clk,
    input  logic        reset,
    input  logic        data_bit,
    input  logic        data_valid,
    input  logic        error_enable,
    input  logic [7:0]  error_symbol_index,
    output logic        recovered_bit,
    output logic        bit_valid,
    output logic [31:0] total_bits,
    output logic [31:0] error_bits
);


## 9. Interface Timing
The system uses one clock cycle per sample.
One input bit generates 8 samples.
Example:
Clock:       0 1 2 3 4 5 6 7
             | | | | | | | |
Sample:     S0 S1 S2 S3 S4 S5 S6 S7
After sample S7, the demodulator generates one recovered bit.
Therefore:
1 input bit
      ↓
8 BPSK samples
      ↓
8 received samples
      ↓
1 recovered bit

## 10. Valid Signal Convention
The valid signals are one-cycle pulses.

data_valid
Indicates that data_bit contains a new input bit.

sample_valid
Indicates that bpsk_sample contains a valid sample.

rx_valid
Indicates that rx_sample contains a valid received sample.

bit_valid
Indicates that recovered_bit contains a newly decoded bit.
The valid signals are used to control data flow between modules.

## 11. Interface Consistency Rules
All team members must follow these rules:
Module names must remain unchanged.
Port names must remain unchanged.
Port directions must remain unchanged.
Sample width must remain 16 bits.
BPSK samples must use signed arithmetic.
One bit must represent one symbol.
One symbol must contain 8 samples.
data_valid indicates a new input bit.
sample_valid indicates a valid BPSK sample.
bit_valid indicates a newly recovered bit.
Any interface change must be discussed with the project leader before implementation.


## 12. Module Responsibility
| Module               | Responsible Member   | Main Responsibility            |
| -------------------- | -------------------- | ------------------------------ |
|  bpsk_modulator.v    | Member 1             | BPSK modulation                |
|  channel.v           | Leader               | Controlled channel model       |
|  bpsk_demodulator.v  | Member 2             | Correlation-based demodulation |
|  ber_counter.v       | Leader               | BER calculation                |
|  bpsk_top.v          | Leader / Integration | System integration             |
|  tb_bpsk_system.v    | Member 3             | Verification and simulation    |

This responsibility assignment may be updated during project development, but interface compatibility must be maintained.