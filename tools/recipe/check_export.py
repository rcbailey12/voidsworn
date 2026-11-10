# Ship recipe, stage 7: check a written ship folder (plain Python with numpy; no Blender). It reads the glb back the way the game
# will, and FAILS the export (exit code 1) when:
#   - a weapon slot of the ship's data.js weapon list has no hard point (hp_w<slot>_<weapon>_<arc>_<n>), or a weapon hard point
#     names a slot, weapon or arc the rules do not have;
#   - a hard point lies farther from the ship's mesh than TOL (tol, default 0.012, times the ship's length: the x extent of its
#     mesh box); hp_core must lie inside the hull's box;
#   - a weapon rests aimed backward, a port mount sits on the starboard side or the other way round, a forward weapon does not
#     point forward, an engine exit does not point aft;
#   - a weapon hard point lacks one of the extras RECIPE.md lists (kind, size, arc, arc_deg, slot, weapon, radius, socket), or its
#     extras slot, weapon or arc disagree with its name;
#   - the breach contract (RECIPE.md hard point table; Muse condition 2 on PR 341) is not met: exactly six hp_breach anchors, two
#     per section (prow, mid, eng: extras.section), one port and one starboard (extras.side P or S, sitting on that side), each
#     at least BREACH_CLEAR (0.03, ship frame, the writer's export7.BREACH_CLEAR) from every part surface (the glb's surfaces other
#     than <code>_hull), and +Y the outward normal (pointing out of its own side: y component of +Y along that side at least 0.5);
#   - hp_eng or hp_core is missing, a hard point is not a child of the ship node, or a map the glb names is not there.
# usage: python check_export.py SHIP_JSON EXPORT_DIR [tol=0.012] [unbaked=1]
import os, sys, json, struct, re
import numpy as np
HERE = os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0, HERE)
import gamedata
BREACH_CLEAR = .030; BREACH_SECTIONS = ('prow', 'mid', 'eng'); WEAPON_EXTRAS = ('kind', 'size', 'arc', 'arc_deg', 'slot', 'weapon', 'radius', 'socket')

def read_glb(path):
    b = open(path, 'rb').read(); magic, ver, total = struct.unpack_from('<4sII', b, 0)
    if magic != b'glTF': raise ValueError('not a glb')
    off = 12; js = None; blob = b''
    while off < total:
        n, kind = struct.unpack_from('<I4s', b, off); data = b[off + 8:off + 8 + n]; off += 8 + n
        if kind == b'JSON': js = json.loads(data)
        elif kind == b'BIN\0': blob = data
    return js, blob

CT = {5120: np.int8, 5121: np.uint8, 5122: np.int16, 5123: np.uint16, 5125: np.uint32, 5126: np.float32}
NC = dict(SCALAR=1, VEC2=2, VEC3=3, VEC4=4)

def accessor(g, blob, i):
    a = g['accessors'][i]; bv = g['bufferViews'][a['bufferView']]; dt = np.dtype(CT[a['componentType']]); nc = NC[a['type']]
    o = bv.get('byteOffset', 0) + a.get('byteOffset', 0); stride = bv.get('byteStride') or dt.itemsize * nc
    if stride == dt.itemsize * nc: return np.frombuffer(blob, dt, a['count'] * nc, o).reshape(a['count'], nc)
    return np.stack([np.frombuffer(blob, dt, nc, o + k * stride) for k in range(a['count'])])

def quat_rot(q, v):
    x, y, z, w = q; u = np.array([x, y, z]); v = np.array(v, float)
    return v + 2 * np.cross(u, np.cross(u, v) + w * v)

def seg_dist(p, a, b):
    ab = b - a; t = np.einsum('ij,ij->i', p - a, ab) / np.maximum(np.einsum('ij,ij->i', ab, ab), 1e-20)
    return np.linalg.norm(p - (a + ab * np.clip(t, 0, 1)[:, None]), axis=1)

def tri_dist(p, A, B, C):
    """distance from point p to every triangle (A, B, C): the plane distance where p projects inside, else the nearest edge"""
    v0, v1, v2 = B - A, C - A, p - A
    d00 = np.einsum('ij,ij->i', v0, v0); d01 = np.einsum('ij,ij->i', v0, v1); d11 = np.einsum('ij,ij->i', v1, v1)
    d20 = np.einsum('ij,ij->i', v2, v0); d21 = np.einsum('ij,ij->i', v2, v1); den = d00 * d11 - d01 * d01
    ok = den > 1e-18; den = np.where(ok, den, 1)
    v = (d11 * d20 - d01 * d21) / den; w = (d00 * d21 - d01 * d20) / den; u = 1 - v - w
    n = np.cross(v0, v1); nl = np.linalg.norm(n, axis=1); plane = np.abs(np.einsum('ij,ij->i', v2, n)) / np.maximum(nl, 1e-20)
    inside = ok & (u >= 0) & (v >= 0) & (w >= 0)
    P = np.broadcast_to(p, A.shape); edge = np.minimum(np.minimum(seg_dist(P, A, B), seg_dist(P, B, C)), seg_dist(P, C, A))
    return np.where(inside, plane, edge)

def main():
    a = sys.argv[1:]; shipj, out = a[0], a[1]; kw = dict(x.split('=', 1) for x in a[2:] if '=' in x)
    TOL_FRAC = float(kw.get('tol', .012)); UNBAKED = kw.get('unbaked') == '1'
    ship = json.load(open(shipj)); code = ship.get('game_code') or ship['ship']; probs = []; notes = []
    weapons = gamedata.weapons(ship['game_ship'])
    g, blob = read_glb(os.path.join(out, code + '.glb')); nodes = g['nodes']
    root = next((i for i, n in enumerate(nodes) if n.get('name') == code), None)
    if root is None or 'mesh' not in nodes[root]: probs.append(f'no ship node named {code} with a mesh'); return finish(out, code, probs, notes, {})
    for k in ('translation', 'rotation', 'scale', 'matrix'):
        if k in nodes[root]: probs.append(f'the ship node has a {k}: its mesh and hard points must be in the ship frame as written')
    T = []; PT = []; hull_seen = False
    for pr in g['meshes'][nodes[root]['mesh']]['primitives']:
        pos = accessor(g, blob, pr['attributes']['POSITION']).astype(np.float64)
        idx = accessor(g, blob, pr['indices']).reshape(-1, 3).astype(np.int64) if 'indices' in pr else np.arange(len(pos)).reshape(-1, 3)
        T.append(pos[idx]); mat = g['materials'][pr['material']].get('name', '') if 'material' in pr else ''
        if mat == code + '_hull': hull_seen = True
        else: PT.append(pos[idx])                     # every surface but the hull is a part surface (parts and glow)
    if not hull_seen: probs.append(f'no {code}_hull surface: the hull cannot be told from the parts, so breach clearance cannot be measured')
    T = np.concatenate(T); A, B, C = T[:, 0], T[:, 1], T[:, 2]; lo, hi = T.reshape(-1, 3).min(0), T.reshape(-1, 3).max(0)
    PT = np.concatenate(PT) if PT else np.zeros((0, 3, 3))
    LEN = float(hi[0] - lo[0]); TOL = TOL_FRAC * LEN
    notes.append(f'{len(T)} triangles ({len(PT)} on part surfaces), box x {lo[0]:.3f} to {hi[0]:.3f}, y {lo[1]:.3f} to {hi[1]:.3f}, z {lo[2]:.3f} to {hi[2]:.3f}')
    notes.append(f'ship length {LEN:.4f}: off-mesh limit {TOL_FRAC} of it, {TOL:.4f}; breach clearance at least {BREACH_CLEAR}')
    breach = {}
    kids = set(nodes[root].get('children', [])); hps = [(i, n) for i, n in enumerate(nodes) if str(n.get('name', '')).startswith('hp_')]
    by_slot = {}; count = {}; rows = []
    for i, n in hps:
        nm = n['name']; p = np.array(n.get('translation', (0, 0, 0)), float); q = n.get('rotation', (0, 0, 0, 1))
        if i not in kids: probs.append(f'{nm} is not a child of the ship node')
        fwd = quat_rot(q, (0, 0, -1)); up = quat_rot(q, (0, 1, 0)); row = dict(name=nm, p=[round(v, 4) for v in p], fwd=[round(v, 3) for v in fwd])
        if nm == 'hp_core':
            count['core'] = count.get('core', 0) + 1
            if not (np.all(p >= lo) and np.all(p <= hi)): probs.append('hp_core is outside the hull')
            rows.append(row); continue
        d = float(tri_dist(p, A, B, C).min()); row['off_mesh'] = round(d, 4)
        if d > TOL: probs.append(f'{nm} is {d:.4f} off the mesh (limit {TOL:.4f})')
        m = re.fullmatch(r'hp_w(\d+)_([A-Za-z0-9_]+)_([FTPS])_(\d+)', nm)
        if m:
            slot, wk, arc = int(m.group(1)), m.group(2), m.group(3); count['gun'] = count.get('gun', 0) + 1
            if slot >= len(weapons) or weapons[slot] != (wk, arc):
                probs.append(f'{nm}: data.js has ' + (f'{weapons[slot][0]} {weapons[slot][1]}' if slot < len(weapons) else 'no weapon') + f' in slot {slot}')
            else: by_slot.setdefault(slot, []).append(nm)
            if fwd[0] < -.05: probs.append(f'{nm} rests aimed backward (x {fwd[0]:+.2f})')
            if arc == 'P' and (p[2] > 0 or fwd[2] > .05): probs.append(f'{nm}: a port mount must sit and aim to port (z below 0)')
            if arc == 'S' and (p[2] < 0 or fwd[2] < -.05): probs.append(f'{nm}: a starboard mount must sit and aim to starboard (z above 0)')
            if arc == 'F' and fwd[0] < .5: probs.append(f'{nm}: a forward weapon must point forward')
            ex = n.get('extras', {})
            for k in WEAPON_EXTRAS:
                if k not in ex: probs.append(f'{nm} has no extras.{k}')
            for k, v in (('slot', slot), ('weapon', wk), ('arc', arc)):
                if k in ex and ex[k] != v: probs.append(f'{nm}: extras.{k} is {ex[k]!r}, its name says {v!r}')
        elif nm.startswith('hp_eng_'):
            count['engine'] = count.get('engine', 0) + 1
            if fwd[0] > -.7: probs.append(f'{nm}: an engine exit must point aft')
            if not n.get('extras', {}).get('radius'): probs.append(f'{nm} has no extras.radius')
        elif nm.startswith('hp_breach_'):
            count['breach'] = count.get('breach', 0) + 1; row['normal'] = [round(v, 3) for v in up]; ex = n.get('extras', {})
            sec, side = ex.get('section'), ex.get('side'); breach.setdefault(sec, []).append(side)
            if sec not in BREACH_SECTIONS: probs.append(f'{nm}: extras.section is {sec!r}, not one of {", ".join(BREACH_SECTIONS)}')
            if side not in ('P', 'S'): probs.append(f'{nm}: extras.side is {side!r}, not P or S')
            else:
                sg = -1 if side == 'P' else 1                 # port is -Z in the game frame
                if p[2] * sg <= 0: probs.append(f'{nm}: a {"port" if side == "P" else "starboard"} breach anchor sits on the other side (z {p[2]:+.3f})')
                if up[2] * sg < .5: probs.append(f'{nm}: +Y is not the outward normal (it points z {up[2]:+.2f} on the {"port" if side == "P" else "starboard"} side)')
            if len(PT):
                cl = float(tri_dist(p, PT[:, 0], PT[:, 1], PT[:, 2]).min()); row['clear'] = round(cl, 4)
                if cl < BREACH_CLEAR - 1e-5: probs.append(f'{nm} is {cl:.4f} from a part (at least {BREACH_CLEAR})')   # 1e-5: float32 rounding only
        elif nm.startswith('hp_bay_'): count['bay'] = count.get('bay', 0) + 1
        else: probs.append(f'{nm}: not a hard point name the format defines')
        rows.append(row)
    for slot, (wk, arc) in enumerate(weapons):
        if slot not in by_slot: probs.append(f'weapon slot {slot} ({wk} {arc}) has no hard point')
    for k in ('engine', 'breach', 'core'):
        if not count.get(k): probs.append(f'no hp_{ {"engine": "eng", "breach": "breach", "core": "core"}[k] } hard point')
    if count.get('core', 0) > 1: probs.append('more than one hp_core')
    if count.get('breach', 0) and count['breach'] != 6: probs.append(f'{count["breach"]} hp_breach anchors: the contract is six, two per section')
    for sec in BREACH_SECTIONS:
        if count.get('breach') and sorted(breach.get(sec, [])) != ['P', 'S']:
            probs.append(f'the {sec} section has breach anchors {sorted(breach.get(sec, []))}: the contract is one port (P) and one starboard (S)')
    unb = bool(g.get('asset', {}).get('extras', {}).get('unbaked'))
    if unb and not UNBAKED: probs.append('this is an unbaked test export (no maps): not a game ship folder')
    imgs = [im.get('uri') for im in g.get('images', [])]
    if not unb and not imgs: probs.append('the glb names no maps')
    for u in imgs:
        if not u or not os.path.exists(os.path.join(out, u)): probs.append(f'map {u} is named by the glb but is not in the folder')
    info = dict(weapons=[dict(slot=s, weapon=wk, arc=arc, hard_points=sorted(by_slot.get(s, []))) for s, (wk, arc) in enumerate(weapons)],
                hardpoints=count, maps=imgs, tolerance=TOL, tolerance_of_length=TOL_FRAC, ship_length=LEN, breach_clearance=BREACH_CLEAR, rows=rows)
    return finish(out, code, probs, notes, info)

def finish(out, code, probs, notes, info):
    ok = not probs; json.dump(dict(ok=ok, problems=probs, notes=notes, **info), open(os.path.join(out, code + '_check.json'), 'w'), indent=1)
    for n in notes: print('[check]', n)
    for w in info.get('weapons', []): print(f"[check] slot {w['slot']} {w['weapon']} {w['arc']}: {len(w['hard_points'])} hard points")
    print('[check] hard points:', json.dumps(info.get('hardpoints', {})))
    for p in probs: print('[check] PROBLEM:', p)
    print('PASS' if ok else 'FAIL', f'{code} game export:', 'every weapon slot has its hard points and every hard point is on the mesh' if ok else f'{len(probs)} problems')
    sys.exit(0 if ok else 1)

if __name__ == '__main__':
    main()
