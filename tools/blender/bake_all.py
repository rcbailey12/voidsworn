# Voidsworn: bake every game hull on this PC's GPU. Writes Downloads\voidsworn_test\bake\{CODE.json,CODE_n.webp,CODE_m.webp,*_lo.webp}
import os, sys, json, glob, subprocess, time
ROOT = os.path.join(os.environ['USERPROFILE'], 'Downloads'); T = os.path.join(ROOT, 'voidsworn_test')
BL = open(os.path.join(T, 'blender_path.txt')).read().strip(); PICKS = os.path.join(ROOT, 'voidsworn_meshes', 'picks')
REFS = os.path.join(T, 'build', os.environ.get('BAKE_REFS', 'hulls_hi')); OUT = os.path.join(T, os.environ.get('BAKE_OUT', 'bake')); DIV = int(os.environ.get('BAKE_DIV', '1')); os.makedirs(OUT, exist_ok=True)
LOG = open(os.path.join(T, 'bake_log.txt'), 'a', encoding='utf-8', buffering=1)
CODES='B16_23,B19_11,B20_11,B21_11,B22_11,B23_51,C13s_23,C14s_23,C15s_23,C16s_23,C19_51,D20_23,D21_23,D22_23,D9_23,H10_23,H4_11,H7_23,H8_23,H9_23,I11_37,I14_23,I15_11,I16_11,I8_37,O1_37,O2_37,O3_11,S1_51,S2_23,V14_23,V15_37,V16_37,V17_37,V18_51,V1b_r_23'.split(',')
force = sys.argv[1].split(',') if len(sys.argv) > 1 else []
only = force or CODES
OPS = {'O3_11': 'keep_main,tall', 'O1_37': 'keep_main'}
for ref in sorted(glob.glob(os.path.join(REFS, '*.json'))):
    code = os.path.basename(ref)[:-5]
    if code == 'index' or (only and code not in only): continue
    if os.path.exists(os.path.join(OUT, code + '_n.webp')) and code not in force: continue
    hs = [f for f in glob.glob(os.path.join(PICKS, '*.glb')) if os.path.basename(f)[:-4] == code or os.path.basename(f)[:-4].endswith('_' + code)]
    if not hs: LOG.write(f'{code}: no high-poly found\n'); continue
    t = json.load(open(os.path.join(T, 'build', 'hulls_hi', code + '.json'))).get('t', 0); res = (2048 if t >= 26000 else 1024 if t >= 9000 else 512) // DIV
    t0 = time.time()
    r = subprocess.run([BL, '-b', '--factory-startup', '-P', os.path.join(T, 'hullbake.py'), '--', hs[0], ref, OUT, str(res), OPS.get(code, '')], capture_output=True, text=True, encoding='utf-8', errors='replace')
    lines = [l for l in (r.stdout + r.stderr).splitlines() if '[bake]' in l or 'Error' in l or 'Traceback' in l]
    LOG.write(f'== {code} res {res} rc {r.returncode} {time.time()-t0:.0f}s\n' + '\n'.join(lines[-12:]) + '\n')
LOG.write('BAKE ALL DONE\n')
