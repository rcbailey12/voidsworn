# Ship recipe: prove the hard point contract on the round 7 ship without Blender or the PC. It builds a small, valid ship glb
# from the real tools/recipe/ships/C15s_23.json and the real data.js weapon list, writes the manifest entry, and runs
# check_export.py on it: PASS with the full point set, then FAIL for each required point removed, each for its own reason. This
# is the "proved on the round 7 ship" half of issue 363 item 2; the real baked export is still checked on the PC by
# check_export_selftest.py inside stage 7.
# usage: python contract_selftest.py [SHIP_JSON]      (exit 0 when every case behaves)
import os, sys, json, struct, tempfile, shutil, subprocess
HERE = os.path.dirname(os.path.abspath(__file__)); REPO = os.path.normpath(os.path.join(HERE, '..', '..'))
sys.path.insert(0, HERE); sys.path.insert(0, os.path.join(REPO, 'tools', 'blender', 'kits', 'shared'))
import gamedata, hardpoints as H, check_export as CE

SHIPJ = sys.argv[1] if len(sys.argv) > 1 else os.path.join(HERE, 'ships', 'C15s_23.json')


def add(a, b): return [a[0] + b[0], a[1] + b[1], a[2] + b[2]]
def sub(a, b): return [a[0] - b[0], a[1] - b[1], a[2] - b[2]]
def mul(a, s): return [a[0] * s, a[1] * s, a[2] * s]
def dot(a, b): return a[0] * b[0] + a[1] * b[1] + a[2] * b[2]
def cross(a, b): return [a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0]]
def norm(a):
    n = dot(a, a) ** .5
    return [a[0] / n, a[1] / n, a[2] / n] if n else [0, 0, 1]


def quat(fwd, up):
    """the glTF quaternion whose node -Z is fwd and +Y is up (check_export.quat_rot uses x, y, z, w)"""
    z = mul(norm(fwd), -1.0)                         # local +Z
    y = sub(norm(up), mul(z, dot(norm(up), z)))
    if dot(y, y) < 1e-9: y = [0, 1, 0] if abs(z[1]) < .9 else [1, 0, 0]
    y = norm(y); x = norm(cross(y, z))
    m = [[x[0], y[0], z[0]], [x[1], y[1], z[1]], [x[2], y[2], z[2]]]
    tr = m[0][0] + m[1][1] + m[2][2]
    if tr > 0:
        s = (tr + 1.0) ** .5 * 2; w = .25 * s; qx = (m[2][1] - m[1][2]) / s; qy = (m[0][2] - m[2][0]) / s; qz = (m[1][0] - m[0][1]) / s
    elif m[0][0] > m[1][1] and m[0][0] > m[2][2]:
        s = (1.0 + m[0][0] - m[1][1] - m[2][2]) ** .5 * 2; w = (m[2][1] - m[1][2]) / s; qx = .25 * s; qy = (m[0][1] + m[1][0]) / s; qz = (m[0][2] + m[2][0]) / s
    elif m[1][1] > m[2][2]:
        s = (1.0 + m[1][1] - m[0][0] - m[2][2]) ** .5 * 2; w = (m[0][2] - m[2][0]) / s; qx = (m[0][1] + m[1][0]) / s; qy = .25 * s; qz = (m[1][2] + m[2][1]) / s
    else:
        s = (1.0 + m[2][2] - m[0][0] - m[1][1]) ** .5 * 2; w = (m[1][0] - m[0][1]) / s; qx = (m[0][2] + m[2][0]) / s; qy = (m[1][2] + m[2][1]) / s; qz = .25 * s
    q = [qx, qy, qz, w]; n = sum(v * v for v in q) ** .5
    return [v / n for v in q]


def box(x0, x1, y0, y1, z0, z1):
    v = [[x0, y0, z0], [x1, y0, z0], [x1, y1, z0], [x0, y1, z0], [x0, y0, z1], [x1, y0, z1], [x1, y1, z1], [x0, y1, z1]]
    f = [(0, 2, 1), (0, 3, 2), (4, 5, 6), (4, 6, 7), (0, 1, 5), (0, 5, 4), (2, 3, 7), (2, 7, 6), (1, 2, 6), (1, 6, 5), (0, 4, 7), (0, 7, 3)]
    return v, f


def write_glb(path, nodes, materials, prims, asset_extra):
    """one mesh with one primitive per material, positions float32 and indices uint16"""
    blob = b''; views = []; accs = []
    for pi, pr in enumerate(prims):
        pos, idx = pr['pos'], pr['idx']
        pb = b''.join(struct.pack('<3f', *p) for p in pos); pb += b'\0' * (-len(pb) % 4)
        ib = b''.join(struct.pack('<H', i) for i in idx); ib += b'\0' * (-len(ib) % 4)
        po = len(blob); blob += pb; io = len(blob); blob += ib
        views.append(dict(buffer=0, byteOffset=po, byteLength=len(pb), target=34962))
        views.append(dict(buffer=0, byteOffset=io, byteLength=len(ib), target=34963))
        mn = [min(p[k] for p in pos) for k in range(3)]; mx = [max(p[k] for p in pos) for k in range(3)]
        accs.append(dict(bufferView=len(views) - 2, componentType=5126, count=len(pos), type='VEC3', min=mn, max=mx))
        accs.append(dict(bufferView=len(views) - 1, componentType=5123, count=len(idx), type='SCALAR'))
    g = dict(asset=dict(version='2.0', generator='issue 363 contract selftest', extras=asset_extra),
             scene=0, scenes=[dict(nodes=[0])], nodes=nodes,
             meshes=[dict(primitives=[dict(attributes=dict(POSITION=2 * i), indices=2 * i + 1, material=i) for i in range(len(prims))])],
             materials=materials, buffers=[dict(byteLength=len(blob))], bufferViews=views, accessors=accs)
    js = json.dumps(g, separators=(',', ':')).encode(); js += b' ' * (-len(js) % 4)
    with open(path, 'wb') as f:
        f.write(struct.pack('<4sII', b'glTF', 2, 12 + 8 + len(js) + 8 + len(blob)))
        f.write(struct.pack('<I4s', len(js), b'JSON')); f.write(js); f.write(struct.pack('<I4s', len(blob), b'BIN\0')); f.write(blob)


def build(ship, out):
    code = ship['game_code']; game = ship['game_ship']
    weapons = gamedata.weapons(game); cls = gamedata.ship_attr(game, 'cls'); fac = gamedata.ship_attr(game, 'fac')
    hangar = int(gamedata.ship_attr(game, 'hangar', default=0) or 0)
    hv, hf = box(-.5, .5, -.08, .08, -.25, .25)
    pv, pf = box(-.10, .10, .14, .16, -.08, .08)                   # a part surface, clear of the breach anchors
    nodes = [dict(name=code, mesh=0, children=[])]; extras = []

    def node(name, p, fwd, up, ex):
        nodes[0]['children'].append(len(nodes)); nodes.append(dict(name=name, translation=p, rotation=quat(fwd, up), extras=ex))

    # two barrels per weapon slot, on the hull surface
    for slot, (wk, arc) in enumerate(weapons):
        for k in range(2):
            if arc in ('P', 'S'):
                sg = -1 if arc == 'P' else 1
                node(f'hp_w{slot}_{wk}_{arc}_{k}', [.30 - .10 * k, .02, sg * .25], [0, 0, sg], [0, 1, 0],
                     dict(kind='gun', size='M', arc=arc, arc_deg={'F': 30, 'T': 135, 'P': 60, 'S': 60}[arc], slot=slot, weapon=wk, radius=.02, socket=f's{slot}'))
            elif arc == 'F':
                node(f'hp_w{slot}_{wk}_{arc}_{k}', [.5, .02, -.08 + .08 * k], [1, 0, 0], [0, 1, 0],
                     dict(kind='gun', size='M', arc=arc, arc_deg=30, slot=slot, weapon=wk, radius=.02, socket=f's{slot}'))
            else:
                node(f'hp_w{slot}_{wk}_{arc}_{k}', [-.10 - .10 * k, .08, 0], [1, 0, 0], [0, 0, 1],
                     dict(kind='gun', size='S', arc=arc, arc_deg=135, slot=slot, weapon=wk, radius=.02, socket=f's{slot}'))
    for k in range(3):
        node(f'hp_eng_{k}', [-.5, .02, -.10 + .10 * k], [-1, 0, 0], [0, 0, 1], dict(kind='engine', radius=.05, engine=f'e{k}'))
    if hangar:
        node('hp_bay_0', [.2, .08, 0], [1, 0, 0], [0, 1, 0], dict(kind='bay', hangar=hangar))
    for k, (sec, side) in enumerate(H.breach_layout(H.expected_breach(cls, fac))):
        x = {'prow': .35, 'mid': .03, 'eng': -.30}[sec]; sg = -1 if side == 'P' else 1
        node(f'hp_breach_{k}', [x, .02, sg * .25], [1, 0, 0], [0, 0, sg], dict(kind='breach', section=sec, side=side, clear=.12))
    node('hp_core', [0, 0, 0], [0, 1, 0], [0, 0, 1], dict(kind='core'))
    if cls not in ('Squadron', 'beacon', 'station'):
        for k, sg in enumerate((-1, 1)):
            node(f'hp_rcs_{k}', [.30, .02, sg * .25], [1, 0, 0], [0, 0, 1], dict(kind='rcs', side='P' if sg < 0 else 'S'))
            node(f'hp_board_{k}', [0, .02, sg * .25], [0, 0, sg], [0, 0, 1], dict(kind='board', side='P' if sg < 0 else 'S'))
    write_glb(os.path.join(out, code + '.glb'), nodes,
              [dict(name=code + '_hull'), dict(name=code + '_parts')],
              [dict(pos=hv, idx=[i for f in hf for i in f]), dict(pos=pv, idx=[i for f in pf for i in f])],
              dict(recipe='contract_selftest', ship=ship['ship'], unbaked=True))
    counts = {}
    for n in nodes[1:]:
        k = n['extras']['kind']; counts[k] = counts.get(k, 0) + 1
    json.dump(dict(name=ship.get('name') or code, faction=ship.get('faction'), cls=cls, band=H.band(cls),
                   length_world=ship.get('length_world', 0), hardpoints=counts, breaches=counts.get('breach', 0), files={}),
              open(os.path.join(out, 'manifest_entry.json'), 'w'), indent=1)
    return code


def run_check(shipj, out):
    r = subprocess.run([sys.executable, os.path.join(HERE, 'check_export.py'), shipj, out, 'unbaked=1'], capture_output=True, text=True)
    return r.returncode, r.stdout + r.stderr


def main():
    ship = json.load(open(SHIPJ)); tmp = tempfile.mkdtemp(prefix='hardpoint-contract-selftest-')
    bad = 0
    try:
        # the one table, spot checks against docs/playbooks/factions.md
        table = [('Frigate', 'corsair', 3), ('Frigate', 'ithar', 1), ('Destroyer', 'corsair', 4), ('Cruiser', 'corsair', 5),
                 ('Cruiser', 'ithar', 3), ('Carrier', 'chorus', 7), ('Battleship', 'hegemony', 6), ('Dreadnought', 'corsair', 9),
                 ('Frigate', 'chorus', 2), ('Squadron', 'chorus', 0)]
        for cls, fac, want in table:
            got = H.expected_breach(cls, fac)
            ok = got == want; bad += not ok
            print(('ok  ' if ok else 'WRONG'), f'breach {cls} {fac}: {got}, expected {want}')
        cls = gamedata.ship_attr(ship['game_ship'], 'cls'); fac = gamedata.ship_attr(ship['game_ship'], 'fac')
        want = H.expected_breach(cls, fac)
        print(f'[contract] round 7 ship {ship["ship"]} ({ship["game_ship"]}): {cls} of {H.faction_key(fac)}, expected breach anchors {want} (the shipped round 7 export has 6; a PC re-export is needed for the table)')
        d = os.path.join(tmp, 'good'); os.makedirs(d)
        code = build(ship, d)
        rc, txt = run_check(SHIPJ, d)
        ok = rc == 0 and 'PASS' in txt; bad += not ok
        print(('ok  ' if ok else 'WRONG'), 'the full point set on the round 7 ship: the check', 'passed' if rc == 0 else 'failed')
        if not ok: print(txt)
        # every required type removed once, each must fail for its own reason. The manifest entry is rewritten to match the
        # broken point set, so the only problem the check can name is the one this case broke.
        def put(b, g, blob):
            js = json.dumps(g, separators=(',', ':')).encode(); js += b' ' * (-len(js) % 4)
            with open(os.path.join(b, code + '.glb'), 'wb') as f:
                f.write(struct.pack('<4sII', b'glTF', 2, 12 + 8 + len(js) + 8 + len(blob)))
                f.write(struct.pack('<I4s', len(js), b'JSON')); f.write(js); f.write(struct.pack('<I4s', len(blob), b'BIN\0')); f.write(blob)
            c = {}
            for n in g['nodes']:
                ex = n.get('extras') or {}
                if ex.get('kind') and str(n.get('name', '')).startswith('hp_'): c[ex['kind']] = c.get(ex['kind'], 0) + 1
            m = json.load(open(os.path.join(b, 'manifest_entry.json')))
            m['hardpoints'] = c; m['breaches'] = c.get('breach', 0)
            json.dump(m, open(os.path.join(b, 'manifest_entry.json'), 'w'), indent=1)
        cases = [('gun', 'hp_w', 'weapon slot'), ('engine', 'hp_eng_', 'hp_eng'), ('breach', 'hp_breach_', 'hp_breach'),
                 ('core', 'hp_core', 'hp_core'), ('rcs', 'hp_rcs_', 'hp_rcs'), ('board', 'hp_board_', 'hp_board')]
        for name, prefix, why in cases:
            b = os.path.join(tmp, name); shutil.copytree(d, b)
            g, blob = CE.read_glb(os.path.join(b, code + '.glb'))
            for n in g['nodes']:
                if str(n.get('name', '')).startswith(prefix): n['name'] = 'x' + n['name']
            put(b, g, blob)
            rc, txt = run_check(SHIPJ, b)
            ok = rc != 0 and why in txt; bad += not ok
            print(('ok  ' if ok else 'WRONG'), f'no {name}: the check', 'refused it' if ok else 'did not name the missing ' + why)
        # one anchor fewer is the wrong class and faction count
        b = os.path.join(tmp, 'breach_count'); shutil.copytree(d, b)
        g, blob = CE.read_glb(os.path.join(b, code + '.glb'))
        [n for n in g['nodes'] if str(n.get('name', '')).startswith('hp_breach_')][-1]['name'] = 'x_breach'
        put(b, g, blob)
        rc, txt = run_check(SHIPJ, b)
        ok = rc != 0 and 'hp_breach' in txt and '4 written' in txt; bad += not ok
        print(('ok  ' if ok else 'WRONG'), 'one breach anchor short: the check', 'refused it for the class and faction count' if ok else 'let it through')
        # the round 7 ship ships six anchors; the same folder must be refused for the count the table gives it
        b = os.path.join(tmp, 'six_anchors'); shutil.copytree(d, b)
        g, blob = CE.read_glb(os.path.join(b, code + '.glb'))
        secs = [('prow', 'P'), ('prow', 'S'), ('mid', 'P'), ('mid', 'S'), ('eng', 'P'), ('eng', 'S')]
        for k in range(5, 6):
            sec, side = secs[k]; sg = -1 if side == 'P' else 1
            g['nodes'].append(dict(name=f'hp_breach_{k}', translation=[-.30, .02, sg * .25], rotation=quat([1, 0, 0], [0, 0, sg]),
                                   extras=dict(kind='breach', section=sec, side=side, clear=.12)))
            g['nodes'][0]['children'].append(len(g['nodes']) - 1)
        put(b, g, blob)
        rc, txt = run_check(SHIPJ, b)
        ok = rc != 0 and '6 written' in txt; bad += not ok
        print(('ok  ' if ok else 'WRONG'), 'the round 7 six-anchor export: the check', 'refused it (the table counts 5)' if ok else 'let it through')
        print('PASS the hard point contract is proved on the round 7 ship' if not bad else f'FAIL {bad} case(s) did not behave')
        return 0 if not bad else 1
    finally:
        shutil.rmtree(tmp, ignore_errors=True)


if __name__ == '__main__':
    sys.exit(main())
