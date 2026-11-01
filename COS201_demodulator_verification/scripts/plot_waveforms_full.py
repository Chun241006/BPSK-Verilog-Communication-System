import csv
from pathlib import Path

import matplotlib.pyplot as plt

ROOT = Path("simulation/results")
TRACE = ROOT / "demod_trace.csv"

CARRIER = [0, 707, 1000, 707, 0, -707, -1000, -707]
TX_BITS = [0,1,0,0,1,1,0,1,1,0,1,0,0,1,1,0]

with TRACE.open(newline="", encoding="utf-8-sig") as f:
    rows = list(csv.DictReader(f))

def make_plot(scenario):
    data = [
        r for r in rows
        if int(r["scenario"]) == scenario
        and int(r["sample_valid"]) == 1
    ]

    data.sort(key=lambda r: (
        int(r["symbol_index"]),
        int(r["sample_index"])
    ))

    if len(data) != 128:
        raise ValueError(
            f"Scenario {scenario}: expected 128 samples, got {len(data)}"
        )

    decoded_rows = [
        r for r in rows
        if int(r["scenario"]) == scenario
        and int(r["bit_valid"]) == 1
    ]

    decoded_rows.sort(key=lambda r: int(r["time_ns"]))

    if len(decoded_rows) != 16:
        raise ValueError(
            f"Scenario {scenario}: expected 16 decoded bits, "
            f"got {len(decoded_rows)}"
        )

    rx_bits = [int(r["recovered_bit"]) for r in decoded_rows]

    correlation = []
    for bit in range(16):
        samples = [
            int(data[bit * 8 + k]["rx_sample"])
            for k in range(8)
        ]
        correlation.append(
            sum(samples[k] * CARRIER[k] for k in range(8))
        )

    errors = [
        int(TX_BITS[i] != rx_bits[i])
        for i in range(16)
    ]
    error_count = sum(errors)
    ber = error_count / 16 * 100

    if scenario == 0:
        assert error_count == 0, "Scenario 0 should have no errors"
    else:
        assert error_count == 1 and errors[3] == 1, \
            "Scenario 1 should have one error at index 3"

    fig, axes = plt.subplots(
        3, 1,
        figsize=(18, 10),
        gridspec_kw={"height_ratios": [2, 1.2, 1.3]},
        constrained_layout=True
    )

    x = list(range(128))
    y = [int(r["rx_sample"]) for r in data]

    # 1. RX waveform: 128 samples
    axes[0].plot(x, y, marker=".", linewidth=1.5)
    axes[0].set_ylabel("RX Sample (signed 16-bit)")
    axes[0].set_title("RX waveform - 8 samples per bit")
    axes[0].grid(True, alpha=0.3)

    for i in range(17):
        axes[0].axvline(i * 8 - 0.5, linestyle=":", alpha=0.35)

    if scenario == 1:
        axes[0].axvspan(23.5, 31.5, alpha=0.15)
        axes[0].annotate(
            "Injected error: bit index 3",
            xy=(27, -1000),
            xytext=(35, -850),
            arrowprops={"arrowstyle": "->"}
        )

    # 2. TX and recovered bits
    bit_x = list(range(16))

    axes[1].step(
        bit_x, TX_BITS,
        where="mid", label="TX Bit",
        linewidth=2
    )
    axes[1].step(
        bit_x, rx_bits,
        where="mid", label="Recovered Bit",
        linewidth=2, linestyle="--"
    )

    for i in range(16):
        if errors[i]:
            axes[1].scatter(
                [i], [rx_bits[i]],
                s=110, marker="x", zorder=5
            )

    axes[1].set_xticks(range(16))
    axes[1].set_yticks([0, 1])
    axes[1].set_ylim(-0.3, 1.3)
    axes[1].set_ylabel("Bit Value")
    axes[1].set_xlabel("Bit Index (0-15)")
    axes[1].set_title("TX vs Recovered Bits")
    axes[1].legend()
    axes[1].grid(True, alpha=0.3)

    # 3. Correlation per bit
    axes[2].bar(bit_x, correlation)
    axes[2].axhline(0, linewidth=1)
    axes[2].set_xticks(range(16))
    axes[2].set_xlabel("Bit Index (0-15)")
    axes[2].set_ylabel("Correlation")
    axes[2].set_title(
        "Correlation = sum(RX[k] * Carrier[k]), k=0..7"
    )
    axes[2].grid(True, axis="y", alpha=0.3)

    fig.suptitle(
        f"BPSK Demodulator - Scenario {scenario} | "
        f"{error_count}/16 errors | BER = {ber:.2f}% | PASS",
        fontsize=16,
        fontweight="bold"
    )

    output = ROOT / f"waveform_scenario{scenario}_full16.png"
    fig.savefig(output, dpi=180)
    plt.close(fig)

    print(f"Created: {output}")
    print(f"Decoded bits: {len(rx_bits)}")
    print(f"Errors: {error_count}")
    print(f"BER: {ber:.2f}%")
    print(f"Correlation: {correlation}")
    print()

make_plot(0)
make_plot(1)

print("ALL WAVEFORMS GENERATED SUCCESSFULLY")
