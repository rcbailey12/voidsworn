# bake the asteroid library: rocks_uv/*.json (desktop 1024) and rocks_uv_lo (phone 512) against rocks_hi/*_hi.glb
import os, glob, subprocess, time
T = os.path.join(os.environ['USERPROFILE'], 'Downloads', 'voidsworn_test'); R = os.path.join(T, 'rocks'); BL = open(os.path.join(T, 'blender_path.txt')).read().strip()
LOG = open(os.path.join(T, 'rocks_log.txt'), 'w', encoding='utf-8', buffering=1)
env = dict(os.environ); env.pop('PYTHONPATH', None)
for refdir, out, res in (('rocks_uv', 'rocks_bake', 1024), ('rocks_uv_lo', 'rocks_bake_lo', 512)):
    os.makedirs(os.path.join(R, out), exist_ok=True)
    for ref in sorted(glob.glob(os.path.join(R, refdir, '*.json'))):
        code = os.path.basename(ref)[:-5]; t0 = time.time()
        r = subprocess.run([BL, '-b', '--factory-startup', '-P', os.path.join(T, 'hullbake.py'), '--', os.path.join(R, 'rocks_hi', code + '_hi.glb'), ref, os.path.join(R, out), str(res), ''], capture_output=True, text=True, encoding='utf-8', errors='replace', env=env)
        lines = [l for l in (r.stdout + r.stderr).splitlines() if '[bake]' in l or 'Traceback' in l or 'Error:' in l]
        LOG.write(f'== {code} {out} rc {r.returncode} {time.time()-t0:.0f}s\n' + '\n'.join(lines[-6:]) + '\n')
LOG.write('ROCKS DONE\n')
