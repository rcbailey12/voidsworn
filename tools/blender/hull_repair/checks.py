"""Run PR checks against the saved Godot results, with logs under TEMP."""
import argparse
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile

HERE = Path(__file__).resolve().parent
REPO = HERE.parents[2]
PC = Path.home()/'Downloads/voidsworn_test'


def summary(work,node):
    raw=(work/'standing_checks.log').read_bytes()
    text=raw.decode('utf-16') if raw.startswith(b'\xff\xfe') else raw.decode('utf-8',errors='replace')
    rows=[line for line in text.splitlines() if ' | PASS | ' in line]
    assert rows and not any(' | FAIL | ' in line for line in text.splitlines())
    assert (work/'parity.txt').read_text(encoding='utf-8').rstrip().endswith(
        'PASS: every Godot battle matches the reviewed saved results.')
    parity=json.loads((work/'parity_summary.json').read_text(encoding='utf-8'))
    assert parity['failures']==0
    result=dict(result='PASS',standing_checks=len(rows),node=subprocess.check_output([node,'--version'],text=True).strip(),
                prng_seeds=3,draws_per_seed=10000,scenarios=parity['battles'],threat_maps=3,
                threads_and_hard_stop='PASS')
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
    env['XDG_DATA_HOME']=env['APPDATA']
    if not a.parity_only:
        with (work/'standing_checks.log').open('w') as out:
            result=subprocess.run([str(node),'contrib/opus/tools/run_all_checks.js'],cwd=REPO,
                                  env=env,stdout=out,stderr=subprocess.STDOUT)
        assert result.returncode==0,'Standing checks failed'
    env['GODOT']=str(godot)
    env.pop('RULES_TWIN', None)
    # A new folder per run keeps repeated checks in the same work folder usable.
    parity=Path(tempfile.mkdtemp(prefix='parity-',dir=work))
    env['PARITY_RUN_ROOT']=str(parity)
    with (work/'parity.txt').open('wb') as transcript:
        result=subprocess.run([str(node),'godot/rules/test/node/run_parity.js'],cwd=REPO,
                              env=env,stdout=transcript,stderr=subprocess.STDOUT)
    assert result.returncode==0,'Godot rules check failed; see '+str(work/'parity.txt')
    (work/'parity_summary.json').write_bytes((parity/'summary.json').read_bytes())
    summary(work,node)


if __name__=='__main__':main()
