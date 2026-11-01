from pathlib import Path
import csv
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
root=Path(__file__).resolve().parents[1]
rows=list(csv.DictReader((root/"simulation/results/demod_trace.csv").open()))
for scenario in (0,1):
    data=[r for r in rows if int(r["scenario"])==scenario]
    # show first 5 bits, including flipped symbol index 3
    data=[r for r in data if int(r["symbol_index"])<5]
    x=list(range(len(data)))
    y=[int(r["rx_sample"]) for r in data]
    b=[int(r["recovered_bit"]) if int(r["bit_valid"]) else float("nan") for r in data]
    fig,axs=plt.subplots(2,1,figsize=(13,6),sharex=True,gridspec_kw={"height_ratios":[2,1]})
    axs[0].plot(x,y,marker="o",markersize=3)
    axs[0].set_ylabel("RX sample (signed 16-bit)")
    axs[0].grid(alpha=.25)
    axs[1].scatter(x,b,marker="s",s=55,label="recovered_bit (bit_valid=1)")
    axs[1].set_yticks([0,1]);axs[1].set_ylim(-.25,1.25)
    axs[1].set_ylabel("Recovered bit")
    axs[1].set_xlabel("Valid sample index (8 samples per bit)")
    axs[1].grid(alpha=.25)
    for a in axs:
        for k in range(1,5): a.axvline(k*8-.5,color="gray",linestyle=":",alpha=.6)
    fig.suptitle("Demodulator RX / recovered bits — "+("No errors (BER 0%)" if scenario==0 else "Symbol #3 inverted (BER 6.25%)"))
    fig.tight_layout()
    out=root/"simulation/results"/("waveform_no_error.png" if scenario==0 else "waveform_one_bit_error.png")
    fig.savefig(out,dpi=170);plt.close(fig)
    print("Created",out)
