"""Independent integer BPSK model; emits immutable memories for RTL scoreboards."""
import json
from pathlib import Path
CARRIER = (0, 707, 1000, 707, 0, -707, -1000, -707)
ROOT = Path(__file__).resolve().parents[1]

def pattern(value):
    return [int(x) for x in f'{value:08b}']

def random_bits(n):
    state = 0xACE1
    bits = []
    for _ in range(n):
        feedback = ((state >> 15) ^ (state >> 13) ^ (state >> 12) ^ (state >> 10)) & 1
        state = ((state << 1) & 0xffff) | feedback
        bits.append(state & 1)
    return bits

def simulate(bits, error_index=-1):
    tx = [(-1 if b else 1)*c for b in bits for c in CARRIER]
    rx = [-s if i//8 == error_index else s for i,s in enumerate(tx)]
    correlations = [sum(s*c for s,c in zip(rx[i:i+8], CARRIER)) for i in range(0,len(rx),8)]
    recovered = [int(x < 0) for x in correlations]
    errors = sum(a != b for a,b in zip(bits,recovered))
    return tx, rx, recovered, errors, correlations

def main():
    defs = [
        ('first_bit_one',pattern(0x80),-1,8,0),
        ('all_zero',pattern(0),-1,8,0),
        ('all_one',pattern(255),-1,8,0),
        ('alternating',pattern(0xAA),-1,8,0),
        ('pattern_A5',pattern(0xA5),-1,8,0),
        ('pattern_B2',pattern(0xB2),-1,8,0),
        ('error_middle',pattern(0xB2),3,8,0),
        ('error_first',pattern(0xB2),0,8,0),
        ('error_last',pattern(0xB2),7,8,0),
        ('error_outside',pattern(0xB2),8,8,0),
        ('random_100',random_bits(100),-1,8,0),
        ('random_100_error',random_bits(100),99,8,0),
        ('gapped_input',pattern(0xB2),3,13,0),
        ('reset_mid_symbol',[1,0],-1,8,1),
        ('index_255',random_bits(256),255,8,0),
        ('fifo_wrap_300',random_bits(300),-1,8,0),
        ('idle_no_input',[],-1,8,0),
    ]
    out = ROOT/'model/reference'; out.mkdir(parents=True,exist_ok=True)
    memories = {x:[] for x in ['vectors','golden_tx_samples','golden_rx_samples','golden_rx_bits']}
    configs = {x:[] for x in ['case_lengths','case_offsets','case_error_index','case_errors','case_gaps','case_reset_mid']}
    cases=[]; offset=0
    for cid,(name,bits,index,gap,mid) in enumerate(defs):
        tx,rx,recovered,errors,corr=simulate(bits,index)
        assert len(tx)==len(rx)==len(bits)*8 and len(recovered)==len(bits)
        assert errors==int(0<=index<len(bits))
        for key,values in zip(memories,[bits,tx,rx,recovered]): memories[key].extend(values)
        for key,value in zip(configs,[len(bits),offset,index if index>=0 else 0xffff,errors,gap,mid]): configs[key].append(value)
        cases.append(dict(id=cid,name=name,length=len(bits),offset=offset,error_index=index,gap=gap,reset_mid=bool(mid),expected_errors=errors,expected_ber=errors/len(bits) if bits else None,bits=bits,recovered_bits=recovered,correlations=corr))
        offset+=len(bits)
    for name,values in {**memories,**configs}.items():
        (out/(name+'.mem')).write_text(''.join(f'{v & 0xffff:04x}\n' for v in values))
    (out/'cases.json').write_text(json.dumps(dict(carrier=CARRIER,cases=cases,total_reference_bits=offset),indent=2)+'\n')
    (out/'case_count.vh').write_text(f'`define CASE_COUNT {len(cases)}\n`define REF_BITS {offset}\n')
    print(f'Golden Model: {len(cases)} cases, {offset} bits, {offset*8} samples per TX/RX')
if __name__=='__main__': main()
