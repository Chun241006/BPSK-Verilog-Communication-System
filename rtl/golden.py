import numpy as np

# System Specifications & Contract Constants
CARRIER_LUT = np.array([0, 707, 1000, 707, 0, -707, -1000, -707], dtype=int)
SAMPLES_PER_SYM = 8

def bpsk_modulator_golden(input_bits):
    """
    BPSK Modulator Golden Model:
    Bit 0 -> +carrier (LUT)
    Bit 1 -> -carrier (-LUT)
    """
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

def calculate_ber(sent_bits, recovered_bits):
    bit_errors = np.sum(sent_bits != recovered_bits)
    total_bits = len(sent_bits)
    ber = bit_errors / total_bits if total_bits > 0 else 0.0
    return bit_errors, total_bits, ber

def run_golden_model():
    print("BPSK GOLDEN MODEL SIMULATION")
    
    # Test vector (16 test bits)
    tx_bits = np.array([0, 1, 0, 0, 1, 1, 0, 1, 1, 0, 1, 0, 0, 1, 1, 0], dtype=int)
    print(f"[*] Input Bits ({len(tx_bits)} bits): {tx_bits.tolist()}")

    # 1. Modulation
    tx_samples = bpsk_modulator_golden(tx_bits)
    print(f"[*] Generated {len(tx_samples)} BPSK 16-bit signed samples.")

    # 2. Channel Transmission (Invert symbol #3)
    error_idx = 3
    rx_samples = channel_golden(tx_samples, error_symbol_index=error_idx)
    print(f"[*] Channel Status: Injected symbol error at index #{error_idx}")

    # 3. Demodulation
    rx_bits = bpsk_demodulator_golden(rx_samples)
    print(f"[*] Recovered Bits: {rx_bits.tolist()}")

    # 4. BER Evaluation
    bit_errs, total_b, ber_val = calculate_ber(tx_bits, rx_bits)
    print(f"[*] BER Result: {bit_errs}/{total_b} error bits | BER = {ber_val:.4f}")

    # 5. Export Expected Test Vectors for Verilog Testbench
    import os
    os.makedirs("simulation", exist_ok=True)
    np.savetxt("simulation/expected_tx_bits.txt", tx_bits, fmt='%d')
    np.savetxt("simulation/expected_tx_samples.txt", tx_samples, fmt='%d')
    np.savetxt("simulation/expected_rx_bits.txt", rx_bits, fmt='%d')
    print("[+] Test vectors exported successfully to 'simulation/' directory.")
    print("==================================================")

if __name__ == "__main__":
    run_golden_model()
