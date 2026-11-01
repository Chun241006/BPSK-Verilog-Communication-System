# COS201 – BPSK Demodulator Verification Results

## 1. Objective
Verify the BPSK demodulator with a 16-bit reference sequence, using eight signed RX samples per symbol. Compare a clean channel (Scenario 0) with a channel that intentionally inverts the samples of one symbol (Scenario 1). Confirm the recovered bits, correlation decisions, error counting, and bit error rate (BER).

## 2. Test setup
- **Reference TX bits (indices 0–15):** `0,1,0,0,1,1,0,1,1,0,1,0,0,1,1,0`
- **Samples per symbol:** 8; **samples per scenario:** 16 × 8 = 128.
- **Reference carrier LUT:** `[0, 707, 1000, 707, 0, -707, -1000, -707]`.
- **Scenario 0:** clean RX, no intentionally inverted symbol.
- **Scenario 1:** all eight RX samples of symbol index 3 (zero-based, the fourth bit) are sign-inverted to create one controlled bit error.

## 3. Simulation results

| Scenario | Decoded bits | Errors vs original TX | BER | RTL mismatches | Result |
|---|---:|---:|---:|---:|---|
| 0 – Clean | 16 | 0 | 0/16 = 0.00% | 0 | PASS |
| 1 – One inverted symbol | 16 | 1 | 1/16 = 6.25% | 0 | PASS |

The results above are recorded in `demod_results.csv`. `scenario1_16bits.csv` contains one row for each of the 16 recovered bits. Its only error is at **bit index 3**: original TX bit `0`, recovered bit `1`. The other 15 bits match the original TX sequence.

### Scenario 1 – bit-by-bit evidence

| Bit index | TX | Recovered | Error |
|---:|---:|---:|---:|
| 0 | 0 | 0 | 0 |
| 1 | 1 | 1 | 0 |
| 2 | 0 | 0 | 0 |
| 3 | 0 | 1 | **1 (injected)** |
| 4 | 1 | 1 | 0 |
| 5 | 1 | 1 | 0 |
| 6 | 0 | 0 | 0 |
| 7 | 1 | 1 | 0 |
| 8 | 1 | 1 | 0 |
| 9 | 0 | 0 | 0 |
| 10 | 1 | 1 | 0 |
| 11 | 0 | 0 | 0 |
| 12 | 0 | 0 | 0 |
| 13 | 1 | 1 | 0 |
| 14 | 1 | 1 | 0 |
| 15 | 0 | 0 | 0 |

## 4. Correlation and BPSK decision

For each 8-sample symbol, the demodulator correlates the received samples against the known carrier:

`C = sum(RX[k] × Carrier[k]), for k = 0..7`

- **C >= 0:** decide bit `0`.
- **C < 0:** decide bit `1`.

For the supplied ideal samples, the reference correlation magnitude is **3,999,396**. A positive-phase symbol gives `+3,999,396` (bit 0); an inverted-phase symbol gives `−3,999,396` (bit 1). In Scenario 1, symbol index 3 was originally TX bit 0, so its correlation changes from **+3,999,396** to **−3,999,396** after the intentional sign inversion. The demodulator therefore recovers bit 1 at this position, as expected.

**Evidence distinction:** The correlation bars in `waveform_scenario0_full16.png` and `waveform_scenario1_full16.png` are recomputed from the RX samples in `demod_trace.csv` using the reference carrier. They are a mathematical verification of the decoding rule, not a direct capture of the RTL correlation register at `bit_valid`. The ModelSim waveform/VCD can be used to inspect the internal `dut/correlation_sum`, `dut/accumulator`, and `dut/product` signals over time. An internal accumulator may reset at symbol completion, so its value sampled after `bit_valid` can be zero without invalidating the prior decision.

## 5. How errors are counted and BER is calculated

Each time the demodulator asserts `bit_valid = 1`, one `recovered_bit` is counted. The recovered bit is compared against the **original transmitted TX bit** at the same index:

`bit_error[i] = 1 if recovered_bit[i] != tx_bit[i], else 0`

`total_bit_errors = sum(bit_error[i])`

`BER = total_bit_errors / total_decoded_bits`

- **Scenario 0:** `0 / 16 = 0 = 0.00%`.
- **Scenario 1:** `1 / 16 = 0.0625 = 6.25%`.

`rtl_mismatches = 0` means the RTL recovered bits agree with the expected decisions for the *received* (possibly corrupted) symbols. This is distinct from BER, which compares the recovered bits with the *original* TX bits. Therefore **Scenario 1 can legitimately have BER 6.25%, RTL mismatches 0, and status PASS simultaneously**.

## 6. Submitted evidence and conclusion

- `demod_results.csv`: overall results for Scenario 0 and Scenario 1.
- `scenario1_16bits.csv`: all 16 decoded bits with the single injected error marked.
- `demod_trace.csv`: RX sample trace, `bit_valid`, recovered bits, and other logged signals.
- `waveform_scenario0_full16.png`: full clean-case waveform, TX/RX comparison, reference correlation.
- `waveform_scenario1_full16.png`: full 1-error waveform, TX/RX comparison, reference correlation; symbol index 3 highlighted.
- `demod_waveform.vcd`: simulation trace for inspection in a waveform viewer.

**Conclusion:** Both test scenarios PASS. The 16-bit clean scenario yields BER 0%; the controlled one-symbol inversion yields exactly one error in 16 bits, BER **6.25%**. The results demonstrate the expected correlation-based BPSK demodulation behavior and correct error counting for this test vector.
