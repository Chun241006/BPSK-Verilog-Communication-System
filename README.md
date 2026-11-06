
# BPSK Modulator and Demodulator using Verilog HDL

COS201 - Communication Systems

## Overview

This project implements a basic BPSK communication system using Verilog HDL. The system takes binary input data, generates BPSK samples, passes them through a controlled channel, recovers the bits, and counts bit errors.

## System Design

The system has four main modules:

1. BPSK Modulator
2. Channel
3. BPSK Demodulator
4. BER Counter

Each bit is represented by 8 signed 16-bit samples.

Carrier values:
`[0, 707, 1000, 707, 0, -707, -1000, -707]`

- Bit 0: positive carrier
- Bit 1: negative carrier

The channel can invert a selected symbol to simulate a transmission error. The demodulator uses correlation to recover the transmitted bit.

## RTL Files

| File | Description |
|---|---|
| `bpsk_modulator.v` | Generates BPSK samples |
| `channel.v` | Passes or inverts the samples |
| `bpsk_demodulator.v` | Recovers bits using correlation |
| `ber_counter.v` | Counts total bits and bit errors |
| `bpsk_top.v` | Connects all modules |

RTL source code is in the `rtl/` folder.

## Golden Model

The Python golden model is in `model/golden_model.py`.

It calculates the expected outputs independently from the Verilog design:

1. Generate input bit sequences
2. Modulate bits into BPSK samples
3. Apply channel error settings
4. Recover bits using correlation
5. Count bit errors
6. Generate reference files for the testbench

The reference data is stored in `model/reference/`.

The file `model/test_golden_model.py` contains 7 unit tests for the Python model.

## Verification

The Verilog testbench compares RTL results with the Python golden model.

The integrated ModelSim simulation on November 1, 2026 passed all 17 defined test cases.

Result: **17/17 PASS, 0 mismatches**

Simulation logs and CSV files are available in `docs/results/`.

## How to Run

Generate reference data:

`python model/golden_model.py`

Run Python unit tests:

`python -B -m unittest discover -s model -p "test_golden_model.py" -v`

The integrated Verilog testbench is `tb/tb_bpsk_system.v` and can be simulated using ModelSim.

## Diagrams

Draw.io diagrams are stored in `docs/diagrams/`.

- [BER Counter](docs/diagrams/ber_counter.png)
- [Golden Model](docs/diagrams/golden_model.png)

## Report

[Final Project Report](docs/COS201_BPSK_Final_Report.docx)

## Limitations

The channel uses controlled symbol inversion rather than AWGN. The current implementation is verified through RTL simulation, without FPGA deployment.