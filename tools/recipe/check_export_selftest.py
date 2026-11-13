# Ship recipe, stage 7: prove the export check can fail. Takes a real written ship folder (one that passes), makes broken copies
# in a scratch folder next to it and runs check_export.py on each. Every broken copy must fail, and for its own reason (the check's
# problems must name what was broken), so a copy refused for something else does not count:
#   pass            the folder as written                                          must PASS
#   no_slot         every hard point of the last weapon slot renamed away          must FAIL (a weapon slot with no hard point)
#   off_mesh        the first weapon hard point moved 0.05 of the ship's length    must FAIL (a hard point off the mesh)
#                   above the ship mesh's top (issue 623: a point deep in a Chorus throat, moved 0.05 up and out,
#                   still lay on the head's skin)
#   backward        the first weapon hard point turned to aim aft                  must FAIL (a weapon resting aimed backward)
#   wrong_side      the first port weapon point mirrored to starboard (a ship       must FAIL (a port mount on the starboard side)
#                   with no port arc: its port boarding origin, issue 618)
#   no_core         hp_core renamed away                                           must FAIL (a required hard point missing)
#   no_socket       extras.socket taken off the first weapon point                 must FAIL (a weapon extra missing)
#   no_engine       every hp_eng renamed away                                      must FAIL (a required hard point missing)
#   no_rcs          every hp_rcs renamed away                                      must FAIL (a required hard point missing)
#   no_board        every hp_board renamed away                                    must FAIL (a required hard point missing)
#   breach_count    the last breach anchor renamed away                            must FAIL (the class and faction count is not met)
#   breach_near     the first breach anchor moved onto the first weapon's muzzle   must FAIL (closer than 0.03 to a part)
#   breach_inward   the first breach anchor turned so +Y points into the ship      must FAIL (+Y is not the outward normal)
#   turret_merged   (an export with turrets) the turret nodes removed and their      must FAIL (a marked turret merged into the mesh)
#                   muzzles moved onto the ship node, as the export did before 560
#   turret_no_mesh  (an export with turrets) the turning meshes renamed away          must FAIL (a turret with no turning mesh)
#   bell_radius     (an export with an open engine bell, issue 592) that engine's      must FAIL (not the centre of an open bell)
#                   extras.radius doubled
#   bell_plane      the same engine point moved half its radius down its exhaust       must FAIL (not the centre of an open bell)
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

def first(g, pre):      # the first such node on the ship node itself (a turret's muzzles are in their turret's frame)
    kids = set(next(n for n in g['nodes'] if n.get('name') == code).get('children', []))
    n = next((n for i, n in enumerate(g['nodes']) if str(n.get('name', '')).startswith(pre) and i in kids), None)
    if n is None:       # issue 633: a ship whose every gun is a turret (the A18 frigate's one autocannon) has its weapon points
        # only under its turret nodes; the case then breaks the first turret's muzzle, read through its turret as the game does
        under = {c for i in kids for c in g['nodes'][i].get('children', [])}
        n = next(n for i, n in enumerate(g['nodes']) if str(n.get('name', '')).startswith(pre) and i in under)
    return n
def length(g):          # the x extent of the ship mesh, from the POSITION accessors' min and max (glTF requires them)
    root = next(n for n in g['nodes'] if n.get('name') == code); acc = [g['accessors'][pr['attributes']['POSITION']] for pr in g['meshes'][root['mesh']]['primitives']]
    return max(a['max'][0] for a in acc) - min(a['min'][0] for a in acc)
def qmul(a, b):         # glTF quaternions (x, y, z, w): a then b in the node's own frame
    ax, ay, az, aw = a; bx, by, bz, bw = b
    return [aw * bx + ax * bw + ay * bz - az * by, aw * by - ax * bz + ay * bw + az * bx, aw * bz + ax * by - ay * bx + az * bw, aw * bw - ax * bx - ay * by - az * bz]

def no_slot(g):
    for n in g['nodes']:
        if str(n.get('name', '')).startswith(f'hp_w{last}_'): n['name'] = 'x' + n['name']
def top(g):             # the y top of the ship mesh, from the same accessors
    root = next(n for n in g['nodes'] if n.get('name') == code)
    return max(g['accessors'][pr['attributes']['POSITION']]['max'][1] for pr in g['meshes'][root['mesh']]['primitives'])
def off_mesh(g):
    n = first(g, 'hp_w'); t = n['translation']; d = .05 * length(g); n['translation'] = [t[0], max(t[1], top(g)) + d, t[2] + (d if t[2] > 0 else -d)]
def in_turret(g, n):    # issue 633: the point is a turret's muzzle (its frame is the turret's, not the ship node's)
    root = next(i for i, m in enumerate(g['nodes']) if m.get('name') == code)
    return g['nodes'].index(n) not in set(g['nodes'][root].get('children', []))
def mat_quat(R):        # a rotation matrix as a glTF quaternion (x, y, z, w)
    import numpy as np
    w = np.sqrt(max(0.0, 1 + R[0, 0] + R[1, 1] + R[2, 2])) / 2; x = np.sqrt(max(0.0, 1 + R[0, 0] - R[1, 1] - R[2, 2])) / 2
    y = np.sqrt(max(0.0, 1 - R[0, 0] + R[1, 1] - R[2, 2])) / 2; z = np.sqrt(max(0.0, 1 - R[0, 0] - R[1, 1] + R[2, 2])) / 2
    x = np.copysign(x, R[2, 1] - R[1, 2]); y = np.copysign(y, R[0, 2] - R[2, 0]); z = np.copysign(z, R[1, 0] - R[0, 1])
    return [float(x), float(y), float(z), float(w)]
def backward(g):
    n = first(g, 'hp_w'); n['rotation'] = [0, .7071068, 0, .7071068]   # a quarter turn about +Y: the node's -Z now points along -X (aft)
    if in_turret(g, n):     # a turret's muzzle: turned so it aims aft in the ship's frame, read through its turret
        import numpy as np
        W, par = CE.world_matrices(g); i = g['nodes'].index(n); Rp = W[par[i]][:3, :3]; Rp = Rp / np.linalg.norm(Rp, axis=0)[None, :]
        Raft = np.array(((0.0, 0, 1), (0, 1, 0), (-1, 0, 0)))          # the quarter turn about +Y: -Z to -X
        n['rotation'] = mat_quat(Rp.T @ Raft)
def port_point(g):      # the first port weapon point; a ship with no port arc (issue 618: Eclipse fires T and F) mirrors its port boarding origin
    n = next((n for n in g['nodes'] if re.fullmatch(r'hp_w\d+_.+_P_\d+', str(n.get('name', '')))), None)
    return n or next(n for n in g['nodes'] if str(n.get('name', '')).startswith('hp_board_') and (n.get('extras') or {}).get('side') == 'P')
def wrong_side(g):
    n = port_point(g); t = n['translation']; n['translation'] = [t[0], t[1], -t[2]]
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
def breach_near(g):
    m = first(g, 'hp_w'); b = first(g, 'hp_breach_'); b['translation'] = list(m['translation'])
    if in_turret(g, m):     # a turret's muzzle: its place in the ship node's frame
        import numpy as np
        W, par = CE.world_matrices(g); root = next(i for i, n in enumerate(g['nodes']) if n.get('name') == code)
        b['translation'] = [float(v) for v in (np.linalg.inv(W[root]) @ W[g['nodes'].index(m)])[:3, 3]]
def breach_inward(g):
    n = first(g, 'hp_breach_'); n['rotation'] = qmul(n.get('rotation', [0, 0, 0, 1]), [1, 0, 0, 0])   # a half turn about its own X: +Y now points in

def no_interior(g):
    root = next(n for n in g['nodes'] if n.get('name') == code)
    mats = root['extras']['voidsworn_destruct']['interior_materials']
    g['meshes'][root['mesh']]['primitives'] = [p for p in g['meshes'][root['mesh']]['primitives'] if g['materials'][p['material']]['name'] not in mats]

def no_seams(g):
    next(n for n in g['nodes'] if n.get('name') == code)['extras']['voidsworn_destruct']['seams'] = []

def liner_only(g):
    root = next(n for n in g['nodes'] if n.get('name') == code)
    mats = root['extras']['voidsworn_destruct']['interior_materials']
    g['meshes'][root['mesh']]['primitives'] = [p for p in g['meshes'][root['mesh']]['primitives'] if g['materials'][p['material']]['name'] not in mats or g['materials'][p['material']]['name'] == code + '_inside_skin']
    root['extras']['voidsworn_destruct']['interior_materials'] = [code + '_inside_skin']
def turret_merged(g):   # issue 560: the turrets folded back into the ship mesh (turret nodes gone, their muzzles on the ship node)
    W, par = CE.world_matrices(g); root = next(i for i, n in enumerate(g['nodes']) if n.get('name') == code)
    for i, n in enumerate(g['nodes']):
        if re.fullmatch(r'turret_\d+', str(n.get('name', ''))):
            for c in list(n.get('children', [])):
                if str(g['nodes'][c].get('name', '')).startswith('hp_w'):
                    g['nodes'][c]['translation'] = [float(v) for v in W[c][:3, 3]]; g['nodes'][c]['rotation'] = n.get('rotation', [0, 0, 0, 1])
                    n['children'].remove(c); g['nodes'][root]['children'].append(c)
            g['nodes'][root]['children'].remove(i); n['name'] = 'x' + n['name']; n.pop('extras', None)
def turret_no_mesh(g):
    for n in g['nodes']:
        if re.fullmatch(r'turret_\d+_turn', str(n.get('name', ''))): n['name'] += 'x'
_g0, _ = CE.read_glb(os.path.join(src, code + '.glb'))
WRONG_SIDE = 'a port mount must sit' if str(port_point(_g0).get('name', '')).startswith('hp_w') else 'a port boarding origin sits on the other side'
CASES = (('pass', None, 0, ''), ('no_slot', no_slot, 1, f'weapon slot {last} '), ('off_mesh', off_mesh, 1, 'off the mesh'),
         ('backward', backward, 1, 'aimed backward'), ('wrong_side', wrong_side, 1, WRONG_SIDE), ('no_core', no_core, 1, 'hp_core'),
         ('no_socket', no_socket, 1, 'no extras.socket'), ('no_engine', no_engine, 1, 'hp_eng'),
         ('no_rcs', no_rcs, 1, 'hp_rcs'), ('no_board', no_board, 1, 'hp_board'),
         ('breach_count', breach_count, 1, 'hp_breach'), ('breach_near', breach_near, 1, 'from a part (at least'),
         ('breach_inward', breach_inward, 1, 'is not the outward normal'),
         ('no_interior', no_interior, 1, 'no authored interior geometry'), ('no_seams', no_seams, 1, 'no authored break seams'),
         ('liner_only', liner_only, 1, 'no authored interior rooms'))
if any(re.fullmatch(r'turret_\d+', str(n.get('name', ''))) for n in _g0['nodes']):     # issue 560: only an export that has turrets
    CASES += (('turret_merged', turret_merged, 1, 'merged it into the ship mesh'), ('turret_no_mesh', turret_no_mesh, 1, 'no turning mesh'))
def open_bells():       # the engines the check passed as open bells (its own record of the export as written)
    cj = os.path.join(src, code + '_check.json')
    if not os.path.exists(cj): subprocess.run([sys.executable, os.path.join(HERE, 'check_export.py'), shipj, src] + sys.argv[3:], capture_output=True)
    if not os.path.exists(cj): return []
    return [r['name'] for r in json.load(open(cj)).get('rows', []) if (r.get('bell') or {}).get('ok')]
BELLS = open_bells()
def bell_node(g): return next(n for n in g['nodes'] if n.get('name') == BELLS[0])
def bell_radius(g): n = bell_node(g); n['extras']['radius'] = 2 * float(n['extras']['radius'])
def bell_plane(g):
    n = bell_node(g); fwd = CE.quat_rot(n.get('rotation', [0, 0, 0, 1]), (0, 0, -1.0)); r = float(n['extras']['radius'])
    n['translation'] = [float(t + .5 * r * f) for t, f in zip(n['translation'], fwd)]
if BELLS:
    CASES += (('bell_radius', bell_radius, 1, 'not the centre of an open engine bell'), ('bell_plane', bell_plane, 1, 'not the centre of an open engine bell'))
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
