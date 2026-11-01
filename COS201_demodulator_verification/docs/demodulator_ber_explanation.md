# COS201 — Demodulator Verification, Correlation and BER

## Scope
This test verifies **the provided `rtl/bpsk_demodulator.v` alone**, not `bpsk_top`, the channel RTL, or the modulator RTL. The testbench drives 16-bit signed RX samples generated from the agreed carrier LUT. Do not describe these results as end-to-end system verification.

## BPSK and correlation
The reference carrier for one symbol has 8 samples:
`[0, 707, 1000, 707, 0, -707, -1000, -707]`.

- TX bit 0: carrier `+c[k]`.
- TX bit 1: inverted carrier `-c[k]`.
- The demodulator accumulates `R = sum(rx[k] * c[k])` for k=0..7.
- If `R < 0`, recovered bit = 1; otherwise recovered bit = 0.
- Ideal bit 0: `R = +3,999,396`; ideal bit 1: `R = -3,999,396`.
- `bit_valid` must pulse for one clock after every eighth valid RX sample. Pauses with `sample_valid=0` do not advance the sample counter.

## Tests
The testbench sends 16 bits, including both 0 and 1, twice:
1. **No error:** RX symbols equal the transmitted BPSK symbols. Expected 0 incorrect bits; BER = `0/16 = 0%`.
2. **One bit error:** the channel is modeled by inverting **all 8 samples of symbol index 3** (zero-based), changing the demodulated decision for exactly one bit. Expected 1 incorrect bit; BER = `1/16 = 6.25%`.

`BER = number of recovered bits differing from the original TX bits / total transmitted bits`.

**Important:** A successful test requires the RTL recovered bits to equal the independently computed expected RX bits in both scenarios, and the observed BER to match the expected BER. BER 6.25% is intentional in the injected-error scenario, not a failure of the demodulator.

## Evidence (generated only after running the simulation)
- `simulation/results/demod_results.csv`: case-level PASS/FAIL and BER.
- `simulation/results/demod_trace.csv`: samples, recovered bit, valid and correlation.
- `simulation/results/demod_waveform.vcd`: simulation waveform for GTKWave.
- `simulation/results/waveform_no_error.png`: RX/recovered bit waveform, clean.
- `simulation/results/waveform_one_bit_error.png`: RX/recovered bit waveform, one flipped symbol.

## Reproduction
From the project root in Windows PowerShell:

```powershell
powershell -ExecutionPolicy Bypass -File .\run_demodulator.ps1
```

Requirements: Icarus Verilog (`iverilog`, `vvp`) and Python with `matplotlib` (`python -m pip install matplotlib` if needed).

**Simulation status:** Not yet executed in the user's environment. Replace this line with the actual console result after running. Do not claim PASS until the simulator reports `DEMODULATOR PASS`.

## Notes
This isolated test does not use Hoàng's Python-generated `.mem` files: it directly creates the same agreed LUT and 16-bit sample contract, allowing both clean and injected-error scenarios without depending on the 17-case reference generator. The existing full-system testbench remains a separate verification task.
