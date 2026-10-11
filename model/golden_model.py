import os
import numpy as np

# System Specifications & Contract Constants
CARRIER_LUT = np.array([0, 707, 1000, 707, 0, -707, -1000, -707], dtype=int)
SAMPLES_PER_SYM = 8

def bpsk_modulator_golden(input_bits):
    mod_samples = []
    for bit in input_bits:
        if bit == 0:
            samples = CARRIER_LUT.copy()
        else:
            samples = -CARRIER_LUT.copy()
        mod_samples.extend(samples)
    return np.array(mod_samples, dtype=int)

def channel_golden(mod_samples, error_symbol_index=None):
    """
    Controlled Error Channel:
    Inverts sign of 8 samples belonging to error_symbol_index.
    """
    ch_samples = mod_samples.copy()
    if error_symbol_index is not None:
        start_idx = error_symbol_index * SAMPLES_PER_SYM
        end_idx = start_idx + SAMPLES_PER_SYM
        if end_idx <= len(ch_samples):
            ch_samples[start_idx:end_idx] = -ch_samples[start_idx:end_idx]
    return ch_samples

def bpsk_demodulator_golden(rx_samples):
    """
    Correlation-based Demodulator:
    Accumulates dot-product of 8 samples with CARRIER_LUT.
    Decision: if accumulated value < 0 -> Bit 1, else -> Bit 0.
    """
    num_bits = len(rx_samples) // SAMPLES_PER_SYM
    recovered_bits = []
    
    for i in range(num_bits):
        segment = rx_samples[i * SAMPLES_PER_SYM : (i + 1) * SAMPLES_PER_SYM]
        corr = np.sum(segment * CARRIER_LUT)
        if corr < 0:
            recovered_bits.append(1)
        else:
            recovered_bits.append(0)
            
    return np.array(recovered_bits, dtype=int)

def int16_to_hex(val):
    """Converts a signed 16-bit integer to 4-character Hex string (Mã bù 2)."""
    val = max(-32768, min(32767, int(val)))
    if val < 0:
        val += 0x10000
    return f"{val:04X}"

def run_golden_model():
    print("BPSK GOLDEN MODEL SIMULATION")
    
    # Target Reference Directory
    ref_dir = os.path.join("model", "reference")
    os.makedirs(ref_dir, exist_ok=True)

    # 1. Input Test Vectors (16 test bits)
    tx_bits = np.array([0, 1, 0, 0, 1, 1, 0, 1, 1, 0, 1, 0, 0, 1, 1, 0], dtype=int)
    print(f"[*] Input Bits ({len(tx_bits)} bits): {tx_bits.tolist()}")

    # 2. Modulation
    tx_samples = bpsk_modulator_golden(tx_bits)
    print(f"[*] Generated {len(tx_samples)} BPSK 16-bit signed samples.")

    # 3. Channel Transmission (Invert symbol #3 for error test)
    error_idx = 3
    rx_samples = channel_golden(tx_samples, error_symbol_index=error_idx)
    print(f"[*] Channel Status: Injected symbol error at index #{error_idx}")

    # 4. Demodulation
    rx_bits = bpsk_demodulator_golden(rx_samples)
    print(f"[*] Recovered Bits: {rx_bits.tolist()}")

    # 5. Export Reference Files (.mem format)
    # 5.1 Input bit vectors -> vectors.mem
    with open(os.path.join(ref_dir, "vectors.mem"), "w") as f:
        for b in tx_bits:
            f.write(f"{b}\n")

    # 5.2 Modulated TX samples (16-bit Hex) -> golden_tx_samples.mem
    with open(os.path.join(ref_dir, "golden_tx_samples.mem"), "w") as f:
        for s in tx_samples:
            f.write(f"{int16_to_hex(s)}\n")

    # 5.3 Received RX samples from Channel (16-bit Hex) -> golden_rx_samples.mem
    with open(os.path.join(ref_dir, "golden_rx_samples.mem"), "w") as f:
        for s in rx_samples:
            f.write(f"{int16_to_hex(s)}\n")

    # 5.4 Demodulated RX bits -> golden_rx_bits.mem
    with open(os.path.join(ref_dir, "golden_rx_bits.mem"), "w") as f:
        for b in rx_bits:
            f.write(f"{b}\n")

    print(f"[+] All reference files generated successfully in '{ref_dir}/':")
    print("    - vectors.mem")
    print("    - golden_tx_samples.mem")
    print("    - golden_rx_samples.mem")
    print("    - golden_rx_bits.mem")
    print("==================================================")

if __name__ == "__main__":
    run_golden_model()
