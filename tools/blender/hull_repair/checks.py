"""Run PR checks with all generated rules fixtures and logs under TEMP."""
import argparse
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys

HERE = Path(__file__).resolve().parent
REPO = HERE.parents[2]
PC = Path.home()/'Downloads/voidsworn_test'


def summary(work,node):
    raw=(work/'standing_checks.log').read_bytes()
    text=raw.decode('utf-16') if raw.startswith(b'\xff\xfe') else raw.decode('utf-8',errors='replace')
    rows=[line for line in text.splitlines() if ' | PASS | ' in line]
    assert rows and not any(' | FAIL | ' in line for line in text.splitlines())
    assert (work/'parity.txt').read_text().rstrip().endswith('PASS: all CI rules parity checks')
    scenarios=json.loads((REPO/'godot/rules/test/scenarios.json').read_text())
    result=dict(result='PASS',standing_checks=len(rows),node=subprocess.check_output([node,'--version'],text=True).strip(),
                prng_seeds=3,draws_per_seed=10000,scenarios=len(scenarios),threat_maps=3,
                threads_and_hard_stop='PASS',parity_subprocesses=1+9+2+3*len(scenarios)+6+1)
    (work/'checks.json').write_text(json.dumps(result,indent=2)+'\n')
    print(json.dumps(result))


def main():
    ap=argparse.ArgumentParser();ap.add_argument('--work',type=Path,required=True)
    ap.add_argument('--parity-only',action='store_true')
    ap.add_argument('--summarize-only',action='store_true');a=ap.parse_args()
    work=a.work.resolve();assert work.is_relative_to(Path(os.environ['TEMP']).resolve())
    work.mkdir(parents=True,exist_ok=True)
    node=PC/'node/node.exe';godot=PC/'godot/Godot_v4.7.2-stable_win64_console.exe'
    if a.summarize_only:
        summary(work,node)
        return
    env=dict(os.environ);env['PATH']=str(node.parent)+os.pathsep+env['PATH']
    env['APPDATA']=str(work/'check_user')
    if not a.parity_only:
        with (work/'standing_checks.log').open('w') as out:
            result=subprocess.run([str(node),'contrib/opus/tools/run_all_checks.js'],cwd=REPO,
                                  env=env,stdout=out,stderr=subprocess.STDOUT)
        assert result.returncode==0,'Standing checks failed'
    project=work/'parity';project.mkdir(exist_ok=True)
    shutil.copytree(REPO/'godot/rules',project/'rules',dirs_exist_ok=True,
                    ignore=shutil.ignore_patterns('out','golden','*.log'))
    (project/'project.godot').write_text('config_version=5\n[application]\nconfig/name="Repair129Parity"\n'
        '[debug]\ngdscript/warnings/inference_on_variant=0\ngdscript/warnings/integer_division=0\n')
    test=project/'rules/test';out=test/'out';gold=test/'golden'
    out.mkdir(exist_ok=True);gold.mkdir(exist_ok=True)
    results=[]
    with (work/'parity.txt').open('w',encoding='utf-8') as transcript:
        def run(command, name, stdout=None):
            r=subprocess.run(list(map(str,command)),cwd=test,env=env,stdout=subprocess.PIPE,
                             stderr=subprocess.STDOUT,text=True,encoding='utf-8',errors='replace',timeout=120)
            if stdout:stdout.write_text(r.stdout,encoding='utf-8')
            transcript.write(name+'\n'+r.stdout+'\n');transcript.flush()
            assert r.returncode==0, name+' failed; see '+str(work/'parity.txt')
            results.append(name)
            return r.stdout
        def js(script,*args):return [node,test/'node'/script,*args]
        def gd(*args):return [godot,'--headless','--path',project,'--script','res://rules/test/parity_main.gd','--',*args]
        run(js('export_data.js',project/'rules/data/tables.json'),'tables')
        for seed in [1001,7,4242424242]:
            expected=gold/f'prng_{seed}.txt';actual=out/f'prng_{seed}.txt'
            run(js('golden.js','prng',seed,10000,expected),'golden prng '+str(seed))
            run(gd('prng',seed,10000,actual),'Godot prng '+str(seed))
            run(js('compare.js','same',expected,actual),'compare prng '+str(seed))
        run(js('golden.js','math',gold/'math.txt'),'golden math')
        run(gd('math',gold/'math.txt'),'Godot math')
        scenarios=json.loads((test/'scenarios.json').read_text())
        for name in scenarios:
            expected=gold/(name+'.jsonl');actual=out/(name+'.jsonl')
            run(js('golden.js','scenario',name,expected),'golden '+name)
            run(gd('scenario',name,actual),'Godot '+name)
            run(js('compare.js','scenario',expected,actual),'compare '+name)
        for name in ['s4','s19','s23']:
            expected=gold/('threat_'+name+'.json');actual=out/('threat_'+name+'.json')
            run(js('golden.js','threat',name,expected),'golden threat '+name)
            run(gd('threat',name,actual),'Godot threat '+name)
            assert expected.read_bytes()==actual.read_bytes(),'Threat map differs: '+name
        run([godot,'--headless','--path',project,'--script','res://rules/test/thread_test.gd','--','s4','s23'],
            'threads and hard stop')
        transcript.write('PASS: all CI rules parity checks\n')
    summary(work,node)


if __name__=='__main__':main()
