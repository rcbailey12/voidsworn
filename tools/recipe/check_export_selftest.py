# Ship recipe, stage 7: prove the export check can fail. Takes a real written ship folder (one that passes), makes broken copies
# in a scratch folder next to it and runs check_export.py on each:
#   pass       the folder as written                                   must PASS
#   no_slot    every hard point of the last weapon slot renamed away   must FAIL (a weapon slot with no hard point)
#   off_mesh   the first weapon hard point moved 0.05 off the hull     must FAIL (a hard point off the mesh)
#   backward   the first weapon hard point turned to aim aft           must FAIL (a weapon resting aimed backward)
# usage: python check_export_selftest.py SHIP_JSON EXPORT_DIR      (exit code 1 when any case does not behave)
import os, sys, json, struct, shutil, subprocess
HERE = os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0, HERE)
import check_export as CE, gamedata
shipj, src = sys.argv[1], sys.argv[2]; ship = json.load(open(shipj)); code = ship.get('game_code') or ship['ship']
last = len(gamedata.weapons(ship['game_ship'])) - 1

def write_glb(path, g, blob):
    js = json.dumps(g, separators=(',', ':')).encode(); js += b' ' * (-len(js) % 4)
    with open(path, 'wb') as f:
        f.write(struct.pack('<4sII', b'glTF', 2, 12 + 8 + len(js) + 8 + len(blob))); f.write(struct.pack('<I4s', len(js), b'JSON')); f.write(js)
        f.write(struct.pack('<I4s', len(blob), b'BIN\0')); f.write(blob)

def no_slot(g):
    for n in g['nodes']:
        if str(n.get('name', '')).startswith(f'hp_w{last}_'): n['name'] = 'x' + n['name']
def off_mesh(g):
    n = next(n for n in g['nodes'] if str(n.get('name', '')).startswith('hp_w')); t = n['translation']; n['translation'] = [t[0], t[1] + .05, t[2] + (.05 if t[2] > 0 else -.05)]
def backward(g):
    n = next(n for n in g['nodes'] if str(n.get('name', '')).startswith('hp_w')); n['rotation'] = [0, .7071068, 0, .7071068]   # a quarter turn about +Y: the node's -Z now points along -X (aft)
CASES = (('pass', None, 0), ('no_slot', no_slot, 1), ('off_mesh', off_mesh, 1), ('backward', backward, 1))
bad = 0; base = os.path.join(src, '_selftest')
for name, fn, want in CASES:
    d = os.path.join(base, name); os.makedirs(d, exist_ok=True)
    for f in os.listdir(src):
        if os.path.isfile(os.path.join(src, f)) and not f.endswith('.glb'): shutil.copyfile(os.path.join(src, f), os.path.join(d, f))
    g, blob = CE.read_glb(os.path.join(src, code + '.glb'))
    if fn: fn(g)
    write_glb(os.path.join(d, code + '.glb'), g, blob)
    r = subprocess.run([sys.executable, os.path.join(HERE, 'check_export.py'), shipj, d] + sys.argv[3:], capture_output=True, text=True)
    why = [l for l in r.stdout.splitlines() if 'PROBLEM' in l][:1]
    ok = (r.returncode == want); bad += not ok
    print(('ok  ' if ok else 'WRONG'), f'{name}: the check ' + ('passed' if r.returncode == 0 else 'failed') + (' as it must' if ok else ', and it must not'), '|', (why[0][8:] if why else ''))
print('PASS the export check fails when it should' if not bad else 'FAIL the export check let a broken export through (or refused a good one)')
sys.exit(1 if bad else 0)
