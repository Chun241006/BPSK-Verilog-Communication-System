"""Plot measured simulation traces; not generated drawings or ModelSim screenshots."""
import csv,json
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
def generate(out):
    cases=json.loads((ROOT/'model/reference/cases.json').read_text())['cases']
    rows=list(csv.DictReader((out/'test_results.csv').open()))
    lines=['# Actual simulation results\n',f'Scope: **{rows[0]["scope"]}**. Fixture results do not sign off team RTL.\n',
           '| Case | Status | Bits | TX samples | RX samples | Recovered | Errors | BER | Mismatches |',
           '|---|---|---:|---:|---:|---:|---:|---:|---:|']
    for row in rows:
        lines.append('| '+' | '.join([cases[int(row['case_id'])]['name']]+[row[x] for x in ['status','bits','tx_samples','rx_samples','recovered_bits','error_bits','ber','mismatches']])+' |')
    (out/'test_results.md').write_text('\n'.join(lines)+'\n')
    try:
        import matplotlib
        matplotlib.use('Agg')
        import matplotlib.pyplot as plt
    except ImportError:
        print('Optional waveform PNGs skipped: pip install matplotlib. VCD and CSV are retained.');return
    trace=list(csv.DictReader((out/'sample_trace.csv').open()))
    target=out/'waveform_screenshots';target.mkdir(exist_ok=True)
    for cid in [0,6,13]:
        data=[x for x in trace if int(x['case_id'])==cid]
        if not data:continue
        t=[int(x['time_ns']) for x in data]; t0=t[0]; t=[v-t0 for v in t]
        fig,axes=plt.subplots(4,1,figsize=(13,8),sharex=True)
        for ax,cols in zip(axes,[['reset','data_valid','data_bit'],['tx_sample','rx_sample'],['bit_valid','recovered_bit'],['total_bits','error_bits']]):
            for col in cols:ax.step(t,[int(x[col]) for x in data],where='post',label=col)
            ax.legend(loc='upper right',ncol=2);ax.grid(alpha=.25)
        axes[-1].set_xlabel(f'Time since first logged point (ns); absolute start {t0} ns')
        axes[1].set_ylabel('Signed sample');axes[-1].set_ylabel('Bit counters')
        fig.suptitle(f'{cases[cid]["name"]} | {rows[cid]["scope"]} | sampled Icarus simulation trace')
        fig.tight_layout();fig.savefig(target/(cases[cid]['name']+'.png'),dpi=150);plt.close(fig)
    print(f'Results table and waveform plots: {out}')
