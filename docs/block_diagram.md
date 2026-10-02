# BPSK Communication System - Block Diagram


## 1. System Overview
The project implements a digital Binary Phase Shift Keying (BPSK) communication system using Verilog HDL.
The system consists of five main stages:
1. Binary Data
2. BPSK Modulator
3. Communication Channel
4. BPSK Demodulator
5. BER Counter


## 2. Detailed Block Diagram


## 3. Block Descriptions
3.1 Binary Data
The Binary Data block provides the input digital data sequence to the BPSK modulator.
Example:
10110010
Each input bit is transmitted as one BPSK symbol.

3.2 BPSK Modulator
The BPSK Modulator converts each binary input bit into a BPSK waveform.
The selected mapping is:
Input Bit	BPSK Signal
0	         +Carrier
1	         -Carrier
A digital carrier is represented using an 8-sample lookup table (LUT):
[0, 707, 1000, 707, 0, -707, -1000, -707]
Each input bit is represented by 8 samples.
For bit 0, the modulator outputs the carrier samples directly.
For bit 1, the modulator outputs the negative of the carrier samples.

3.3 Channel
The Channel block represents the transmission path between the transmitter and receiver.
To keep the project suitable for a basic Verilog HDL implementation, the channel uses a controlled digital error model.
Two modes are considered:
Normal Mode
RX sample = TX sample
The transmitted samples are passed directly to the receiver.
Error Mode
A selected symbol can be inverted:
RX sample = -TX sample
This controlled error allows the system to demonstrate error detection and BER calculation without implementing a complete analog noise model.

3.4 BPSK Demodulator
The BPSK Demodulator recovers the transmitted binary data from the received samples.
The demodulator uses correlation-based detection.
For each group of 8 received samples:

correlation =
r[0] × c[0] +
r[1] × c[1] +
...
r[7] × c[7]
where:
r[i] is the received sample.
c[i] is the reference carrier sample.
The decision rule is:
correlation > 0  →  recovered bit = 0
correlation < 0  →  recovered bit = 1
This works because bit 0 is represented by the positive carrier and bit 1 is represented by the inverted carrier.

3.5 BER Counter
The BER Counter compares the original transmitted bit with the recovered bit.

TX Bit ──────┐
             │
             ▼
          Compare ────> Error?
             ▲
             │
RX Bit ──────┘

If the two bits are different, the error counter is incremented.
The system keeps track of:
- Total transmitted bits
- Number of error bits
The Bit Error Rate is calculated as:
BER = Number of Error Bits / Total Number of Bits


## 4. Data flow
Input Bit -> Bit Mapping -> Carrier LUT -> BPSK Samples -> Channel -> Received Sammples -> Correlation -> Bit Decision -> Recovered Bit -> BER Calculation 


## 5. Main Design Parameters
| Parameter           | Value                    |
| ------------------- | ------------------------ |
| Modulation          | BPSK                     |
| Bits per Symbol     | 1                        |
| Samples per Symbol  | 8                        |
| Carrier Samples     | 8                        |
| Bit `0` Mapping     | +Carrier                 |
| Bit `1` Mapping     | -Carrier                 |
| Demodulation Method | Correlation              |
| Channel Model       | Controlled Digital Error |
| Performance Metric  | BER                      |


## 6. System Objective
The main objective of the project is to demonstrate the implementation of a basic digital BPSK communication system using Verilog HDL.
The project focuses on:
BPSK modulation
Digital signal representation
BPSK demodulation
Controlled transmission errors
BER measurement
RTL implementation and simulation
