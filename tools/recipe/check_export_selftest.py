# Ship recipe, stage 7: prove the export check can fail. Takes a real written ship folder (one that passes), makes broken copies
# in a scratch folder next to it and runs check_export.py on each. Every broken copy must fail, and for its own reason (the check's
# problems must name what was broken), so a copy refused for something else does not count:
#   pass            the folder as written                                          must PASS
#   no_slot         every hard point of the last weapon slot renamed away          must FAIL (a weapon slot with no hard point)
#   off_mesh        the first weapon hard point moved 0.05 of the ship's length    must FAIL (a hard point off the mesh)
#   backward        the first weapon hard point turned to aim aft                  must FAIL (a weapon resting aimed backward)
#   wrong_side      the first port weapon point mirrored to starboard              must FAIL (a port mount on the starboard side)
#   no_core         hp_core renamed away                                           must FAIL (a required hard point missing)
#   no_socket       extras.socket taken off the first weapon point                 must FAIL (a weapon extra missing)
#   no_engine       every hp_eng renamed away                                      must FAIL (a required hard point missing)
#   no_rcs          every hp_rcs renamed away                                      must FAIL (a required hard point missing)
#   no_board        every hp_board renamed away                                    must FAIL (a required hard point missing)
#   breach_count    the last breach anchor renamed away                            must FAIL (the class and faction count is not met)
#   breach_near     the first breach anchor moved onto the first weapon's muzzle   must FAIL (closer than 0.03 to a part)
#   breach_inward   the first breach anchor turned so +Y points into the ship      must FAIL (+Y is not the outward normal)
# usage: python check_export_selftest.py SHIP_JSON EXPORT_DIR [unbaked=1]      (exit code 1 when any case does not behave)
import os, sys, json, struct, shutil, subprocess, re
HERE = os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0, HERE)
import check_export as CE, gamedata
shipj, src = sys.argv[1], sys.argv[2]; ship = json.load(open(shipj)); code = ship.get('game_code') or ship['ship']
last = len(gamedata.weapons(ship['game_ship'])) - 1

def write_glb(path, g, blob):
    js = json.dumps(g, separators=(',', ':')).encode(); js += b' ' * (-len(js) % 4)
    with open(path, 'wb') as f:
        f.write(struct.pack('<4sII', b'glTF', 2, 12 + 8 + len(js) + 8 + len(blob))); f.write(struct.pack('<I4s', len(js), b'JSON')); f.write(js)
        f.write(struct.pack('<I4s', len(blob), b'BIN\0')); f.write(blob)

def first(g, pre): return next(n for n in g['nodes'] if str(n.get('name', '')).startswith(pre))
def length(g):          # the x extent of the ship mesh, from the POSITION accessors' min and max (glTF requires them)
    root = next(n for n in g['nodes'] if n.get('name') == code); acc = [g['accessors'][pr['attributes']['POSITION']] for pr in g['meshes'][root['mesh']]['primitives']]
    return max(a['max'][0] for a in acc) - min(a['min'][0] for a in acc)
def qmul(a, b):         # glTF quaternions (x, y, z, w): a then b in the node's own frame
    ax, ay, az, aw = a; bx, by, bz, bw = b
    return [aw * bx + ax * bw + ay * bz - az * by, aw * by - ax * bz + ay * bw + az * bx, aw * bz + ax * by - ay * bx + az * bw, aw * bw - ax * bx - ay * by - az * bz]

def no_slot(g):
    for n in g['nodes']:
        if str(n.get('name', '')).startswith(f'hp_w{last}_'): n['name'] = 'x' + n['name']
def off_mesh(g):
    n = first(g, 'hp_w'); t = n['translation']; d = .05 * length(g); n['translation'] = [t[0], t[1] + d, t[2] + (d if t[2] > 0 else -d)]
def backward(g):
    n = first(g, 'hp_w'); n['rotation'] = [0, .7071068, 0, .7071068]   # a quarter turn about +Y: the node's -Z now points along -X (aft)
def wrong_side(g):
    n = next(n for n in g['nodes'] if re.fullmatch(r'hp_w\d+_.+_P_\d+', str(n.get('name', '')))); t = n['translation']; n['translation'] = [t[0], t[1], -t[2]]
def no_core(g): first(g, 'hp_core')['name'] = 'x_core'
def no_socket(g): first(g, 'hp_w')['extras'].pop('socket')
def no_engine(g):
    for n in g['nodes']:
        if str(n.get('name', '')).startswith('hp_eng_'): n['name'] = 'x' + n['name']
def no_rcs(g):
    for n in g['nodes']:
        if str(n.get('name', '')).startswith('hp_rcs_'): n['name'] = 'x' + n['name']
def no_board(g):
    for n in g['nodes']:
        if str(n.get('name', '')).startswith('hp_board_'): n['name'] = 'x' + n['name']
def breach_count(g):
    n = [n for n in g['nodes'] if str(n.get('name', '')).startswith('hp_breach_')][-1]; n['name'] = 'x' + n['name']
def breach_near(g): first(g, 'hp_breach_')['translation'] = list(first(g, 'hp_w')['translation'])
def breach_inward(g):
    n = first(g, 'hp_breach_'); n['rotation'] = qmul(n.get('rotation', [0, 0, 0, 1]), [1, 0, 0, 0])   # a half turn about its own X: +Y now points in
CASES = (('pass', None, 0, ''), ('no_slot', no_slot, 1, f'weapon slot {last} '), ('off_mesh', off_mesh, 1, 'off the mesh'),
         ('backward', backward, 1, 'aimed backward'), ('wrong_side', wrong_side, 1, 'a port mount must sit'), ('no_core', no_core, 1, 'hp_core'),
         ('no_socket', no_socket, 1, 'no extras.socket'), ('no_engine', no_engine, 1, 'hp_eng'),
         ('no_rcs', no_rcs, 1, 'hp_rcs'), ('no_board', no_board, 1, 'hp_board'),
         ('breach_count', breach_count, 1, 'hp_breach'), ('breach_near', breach_near, 1, 'from a part (at least'),
         ('breach_inward', breach_inward, 1, 'is not the outward normal'))
bad = 0; base = os.path.join(src, '_selftest')
for name, fn, want, why_must in CASES:
    d = os.path.join(base, name); os.makedirs(d, exist_ok=True)
    for f in os.listdir(src):
        if os.path.isfile(os.path.join(src, f)) and not f.endswith('.glb'): shutil.copyfile(os.path.join(src, f), os.path.join(d, f))
    g, blob = CE.read_glb(os.path.join(src, code + '.glb'))
    if fn: fn(g)
    write_glb(os.path.join(d, code + '.glb'), g, blob)
    mp = os.path.join(d, 'manifest_entry.json')
    if os.path.exists(mp):      # keep the manifest in step, so the only problem is the one this case broke
        c = {}
        for n in g['nodes']:
            ex = n.get('extras') or {}
            if ex.get('kind') and str(n.get('name', '')).startswith('hp_'): c[ex['kind']] = c.get(ex['kind'], 0) + 1
        m = json.load(open(mp)); m['hardpoints'] = c; m['breaches'] = c.get('breach', 0)
        json.dump(m, open(mp, 'w'), indent=1)
    r = subprocess.run([sys.executable, os.path.join(HERE, 'check_export.py'), shipj, d] + sys.argv[3:], capture_output=True, text=True)
    probs = [l[17:] for l in r.stdout.splitlines() if 'PROBLEM' in l]; why = [l for l in probs if why_must and why_must in l][:1]
    ok = (r.returncode == want) and (not want or bool(why)); bad += not ok
    print(('ok  ' if ok else 'WRONG'), f'{name}: the check ' + ('passed' if r.returncode == 0 else 'failed') + (' as it must' if ok else
          ', and it must not' if r.returncode != want else f', but not for the broken {name} (no "{why_must}" among its problems)'), '|', (why or probs or [''])[0])
print('PASS the export check fails when it should' if not bad else 'FAIL the export check let a broken export through (or refused a good one)')
sys.exit(1 if bad else 0)
