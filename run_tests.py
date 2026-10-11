"""Run from any directory: python run_tests.py [--fixture] [--mutations]."""
import argparse, csv, hashlib, json, os, shutil, subprocess, sys
from pathlib import Path
ROOT=Path(__file__).resolve().parent

def command(args,path):
    result=subprocess.run([str(x) for x in args],cwd=ROOT,text=True,stdout=subprocess.PIPE,stderr=subprocess.STDOUT)
    path.write_text(result.stdout)
    print(result.stdout[-2500:])
    return result.returncode

def main():
    p=argparse.ArgumentParser()
    p.add_argument('--fixture',action='store_true',help='explicit harness self-test; does NOT verify team RTL')
    p.add_argument('--mutations',action='store_true',help='requires --fixture; prove checkers reject five deliberate faults')
    a=p.parse_args()
    if a.mutations and not a.fixture: p.error('--mutations requires --fixture')
    compiler=os.environ.get('IVERILOG','iverilog');runtime=os.environ.get('VVP','vvp')
    if not shutil.which(compiler) or not shutil.which(runtime):
        print('ERROR: Install Icarus Verilog; put iverilog and vvp on PATH, or set IVERILOG/VVP.');return 2
    scope='fixture_selftest' if a.fixture else 'team_rtl'
    out=ROOT/'simulation/results'/scope;out.mkdir(parents=True,exist_ok=True)
    if command([sys.executable,'model/golden_model.py'],out/'model.log'):return 2
    rtl=[ROOT/'verification_support/contract_fixture.v'] if a.fixture else sorted((ROOT/'rtl').glob('*.v'))
    manifest=dict(scope=scope,fixture=a.fixture,python=sys.version,rtl_sha256={str(x.relative_to(ROOT)):hashlib.sha256(x.read_bytes()).hexdigest() for x in rtl})
    try: manifest['repository_commit']=subprocess.check_output(['git','rev-parse','HEAD'],cwd=ROOT,text=True).strip()
    except subprocess.CalledProcessError:manifest['repository_commit']='see supplied provenance.json'
    manifest['iverilog_version']=subprocess.run([compiler,'-V'],capture_output=True,text=True).stdout.splitlines()[0]
    (out/'provenance.json').write_text(json.dumps(manifest,indent=2)+'\n')
    # Clear old evidence so a failed run cannot retain stale PASS tables/waveforms.
    for name in ['test_results.txt','test_results.csv','sample_trace.csv','bpsk_system.vcd','transcript.log','test_results.md']:
        (out/name).unlink(missing_ok=True)
    exe=ROOT/'simulation'/f'{scope}.vvp'
    flags=[compiler]
    if os.environ.get('IVERILOG_IVL'):flags+=['-B',os.environ['IVERILOG_IVL']]
    flags+=['-g2012','-Wall','-s','tb_bpsk_system','-I',ROOT,'-o',exe]
    rc=command(flags+rtl+[ROOT/'tb/tb_bpsk_system.v'],out/'compile.log')
    if rc:
        (out/'test_results.txt').write_text(f'BLOCKED: {scope} compile failed (exit={rc}).\nNo test case ran; no functional PASS is claimed.\nSee compile.log and provenance.json.\n')
        return rc
    rc=command([runtime,exe,f'+RESULTS_DIR={out}',f'+SCOPE={scope}'],out/'transcript.log')
    # Post-process even on failure to preserve actual failing results.
    if (out/'test_results.csv').exists():
        from verification_support.plot_results import generate
        generate(out)
    if a.mutations and rc==0:
        source=(ROOT/'verification_support/contract_fixture.v').read_text()
        changes={
          'tx_amplitude':('1:carrier=707','1:carrier=708'),
          'rx_inversion':('? -tx_sample : tx_sample','? tx_sample : tx_sample'),
          'bit_decision':('recovered_bit<=(sum<0)','recovered_bit<=(sum>0)'),
          'ber_increment':('error_bits<=error_bits+1','error_bits<=error_bits+2'),
          'rx_valid':('rx_valid<=tx_valid','rx_valid<=0'),
        }
        rows=[]
        for name,(before,after) in changes.items():
            if before not in source:raise RuntimeError('mutation target missing')
            md=out/'mutations'/name;md.mkdir(parents=True,exist_ok=True)
            mutated=md/'mutated_fixture.v';mutated.write_text(source.replace(before,after,1))
            mutation_exe=md/'mutant.vvp'
            c=command(flags[:-1]+[mutation_exe,mutated,ROOT/'tb/tb_bpsk_system.v'],md/'compile.log')
            r=command([runtime,mutation_exe,f'+RESULTS_DIR={md}',f'+SCOPE=mutation_{name}'],md/'transcript.log') if not c else None
            detected=c==0 and r is not None and r!=0 and 'FAIL case=' in (md/'transcript.log').read_text()
            rows.append(dict(mutation=name,compile_exit=c,simulation_exit=r,detected=detected))
            # Keep failure logs/tables, avoid shipping redundant mutation waveforms.
            (md/'bpsk_system.vcd').unlink(missing_ok=True);(md/'sample_trace.csv').unlink(missing_ok=True)
        with (out/'mutation_results.csv').open('w',newline='') as f:
            writer=csv.DictWriter(f,fieldnames=rows[0]);writer.writeheader();writer.writerows(rows)
        if not all(x['detected'] for x in rows):return 1
    return rc
if __name__=='__main__':sys.exit(main())
