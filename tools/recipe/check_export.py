# Ship recipe, stage 7: check a written ship folder (plain Python with numpy; no Blender). It reads the glb back the way the game
# will, and FAILS the export (exit code 1) when:
#   - a weapon slot of the ship's Godot weapon list has no hard point (hp_w<slot>_<weapon>_<arc>_<n>), or a weapon hard point
#     names a slot, weapon or arc the rules do not have;
#   - a hard point lies farther from the ship's mesh than TOL (tol, default 0.012, times the ship's length: the x extent of its
#     mesh box); hp_core must lie inside the hull's box. An engine point farther than TOL passes only as the centre of an
#     open bell (open_bell: the rim on its exit plane at extras.radius all round, a throat upstream, a clear exhaust path);
#   - a weapon rests aimed backward, a port mount sits on the starboard side or the other way round, a forward weapon does not
#     point forward, an engine exit does not point aft;
#   - a weapon hard point lacks one of the extras RECIPE.md lists (kind, size, arc, arc_deg, slot, weapon, radius, socket), or its
#     extras slot, weapon or arc disagree with its name;
#   - the breach contract (docs/ship_pipeline/HARDPOINTS.md; the count comes from tools/blender/kits/shared/hardpoints.py, never
#     from a constant) is not met: the number of hp_breach anchors is the class and faction count, they cover the sections
#     (prow, mid, eng: extras.section) the count needs, the port and starboard sides stay within one of even (extras.side P or S,
#     sitting on that side), each is at least BREACH_CLEAR (0.03, ship frame) from every part surface (the glb's surfaces other
#     than <code>_hull and root primitives whose own material marks hull_surface), and +Y is the outward normal (pointing out
#     of its own side: its z component along that side at least 0.5). Sharing a light map never exempts an unmarked part;
#   - the smallest required set of any class is not met: a weapon point per Godot weapon slot, hp_core, hp_eng, hp_rcs and
#     hp_board (two each, one port and one starboard), and hp_bay when Godot gives the ship a hangar;
#   - a hard point is not a child of the ship node (or, for a turret's muzzle, of its turret node), or a map the glb names is not
#     there.
#   - the authored interior/seams record or real room geometry is missing (a liner alone is not a room).
#   - turrets (issue 560, RULEBOOK 6.17; docs/ship_pipeline/HARDPOINTS.md "Turrets"): a turret the kit marks (a ship json part
#     whose part is 'turret', or the asset extras turrets_marked the export recorded from the blend) has no turret_<n> node of its
#     own (the export merged it into the ship mesh), or one of its muzzles hangs on the ship node instead of under its turret; a
#     turret node lacks its turning mesh, a muzzle, an extra (TURRET_EXTRAS), sits off the mesh, rests aimed backward or rests
#     outside its own arc.
# Every position and axis is read through the node tree (a turret's muzzle is in its turret's frame), as the game reads it.
# usage: python check_export.py SHIP_JSON EXPORT_DIR [tol=0.012] [unbaked=1]
import os, sys, json, struct, re
import numpy as np
HERE = os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0, HERE)
SHARED = os.path.normpath(os.path.join(HERE, '..', 'blender', 'kits', 'shared')); sys.path.insert(0, SHARED)
import gamedata, hardpoints as HP_CONTRACT
BREACH_CLEAR = .030; BREACH_SECTIONS = ('prow', 'mid', 'eng'); WEAPON_EXTRAS = ('kind', 'size', 'arc', 'arc_deg', 'slot', 'weapon', 'radius', 'socket')

from glb_io import read_glb  # noqa: E402 (one copy, shared with stage 7)

CT = {5120: np.int8, 5121: np.uint8, 5122: np.int16, 5123: np.uint16, 5125: np.uint32, 5126: np.float32}
NC = dict(SCALAR=1, VEC2=2, VEC3=3, VEC4=4)

def accessor(g, blob, i):
    a = g['accessors'][i]; bv = g['bufferViews'][a['bufferView']]; dt = np.dtype(CT[a['componentType']]); nc = NC[a['type']]
    o = bv.get('byteOffset', 0) + a.get('byteOffset', 0); stride = bv.get('byteStride') or dt.itemsize * nc
    if stride == dt.itemsize * nc: return np.frombuffer(blob, dt, a['count'] * nc, o).reshape(a['count'], nc)
    return np.stack([np.frombuffer(blob, dt, nc, o + k * stride) for k in range(a['count'])])

def node_matrix(n):
    """a glTF node's local 4x4 matrix (matrix, or translation, rotation, scale)"""
    if 'matrix' in n: return np.array(n['matrix'], float).reshape(4, 4).T
    x, y, z, w = n.get('rotation', (0, 0, 0, 1)); t = n.get('translation', (0, 0, 0)); sc = n.get('scale', (1, 1, 1))
    R = np.array([[1 - 2 * (y * y + z * z), 2 * (x * y - z * w), 2 * (x * z + y * w)],
                  [2 * (x * y + z * w), 1 - 2 * (x * x + z * z), 2 * (y * z - x * w)],
                  [2 * (x * z - y * w), 2 * (y * z + x * w), 1 - 2 * (x * x + y * y)]])
    M = np.eye(4); M[:3, :3] = R * np.array(sc, float)[None, :]; M[:3, 3] = t
    return M

def world_matrices(g):
    """every node's matrix in the scene frame, and its parent index"""
    nodes = g['nodes']; parent = {}
    for i, n in enumerate(nodes):
        for c in n.get('children', []): parent[c] = i
    W = {}
    def w(i):
        if i not in W: W[i] = (w(parent[i]) if i in parent else np.eye(4)) @ node_matrix(nodes[i])
        return W[i]
    for i in range(len(nodes)): w(i)
    return W, parent

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

def open_bell(p, fwd, R, V, tol, *, require_clear_mouth=False):
    """Check the centre of a round engine or bomb-tube exit of radius R along fwd (RECIPE.md stage 7).
    rim:    mesh vertices on the exit plane (within min(tol, 0.25 R) along the axis) at the recorded radius (0.7 R to 1.15 R off the axis)
            in at least 10 of 12 sectors round the axis: the bell is there, at that size, facing that way;
    throat: mesh inside 0.9 R of the axis upstream of the plane (within 2 R): the bell has a throat behind its mouth;
    clear:  no mesh inside 0.6 R of the axis downstream of the plane (tol to 2 R): nothing plugs the exhaust."""
    if R <= 0: return dict(ok=False, why='no extras.radius')
    f = np.asarray(fwd, float); f = f / np.linalg.norm(f); q = V - p; ax = q @ f; rad = np.linalg.norm(q - np.outer(ax, f), axis=1)
    u = np.cross(f, [0, 1, 0] if abs(f[1]) < .9 else [1, 0, 0]); u /= np.linalg.norm(u); w = np.cross(f, u)
    # Issue 967: the whole-ship mesh tolerance can exceed half a small bell's radius (IM5).
    # Keep the mouth's plane local to the bell, so moving the point down the exhaust cannot reuse its old rim.
    plane_tol = min(tol, .25 * R)
    rim = (np.abs(ax) <= plane_tol) & (rad >= .7 * R) & (rad <= 1.15 * R)
    sectors = len(set((np.floor((np.arctan2(q[rim] @ w, q[rim] @ u) + np.pi) / (2 * np.pi) * 12).astype(int) % 12).tolist()))
    throat = int(((ax < -tol * .25) & (ax > -2 * R) & (rad < .9 * R)).sum())
    plug = int(((ax > tol) & (ax < 2 * R) & (rad < .6 * R)).sum())
    out = dict(radius=round(R, 4), plane_tolerance=round(plane_tol, 6), rim_sectors=sectors, throat_vertices=throat, exhaust_vertices=plug)
    why = [] if sectors >= 10 else [f'its rim at radius {R:.4f} on the exit plane covers {sectors} of 12 sectors']
    if not throat: why.append('no throat upstream of the exit')
    if plug: why.append(f'{plug} mesh points in the exhaust path')
    if require_clear_mouth:
        # Check a thin slice at the mouth. A recessed load is outside this slice, while a smaller
        # inner rim gives away a falsely enlarged radius even if surrounding armour forms a ring.
        mouth = int(((np.abs(ax) <= plane_tol * .25) & (rad < .7 * R)).sum())
        if mouth: why.append(f'{mouth} mesh points inside the claimed opening on the exit plane')
    out.update(ok=not why, why='; '.join(why)); return out

def open_rectangular_exhaust(p, fwd, up, aperture, vertices, tol):
    """Check the open rim, recessed throat and downstream clearance of a kit's drive slit."""
    try:
        half = np.asarray(aperture, dtype=float) * .5
    except (TypeError, ValueError):
        half = np.empty(0)
    if half.shape != (2,) or not np.isfinite(half).all() or not (half > 0).all():
        return dict(ok=False, why='invalid rectangular exhaust width or height')

    offset = vertices - p
    side = np.cross(fwd, up)
    span = np.column_stack((offset @ side, offset @ up)) / half
    axis = offset @ fwd
    extent = np.max(np.abs(span), axis=1)
    height = min(half)
    plane = min(tol, .25 * height)
    corners = (np.abs(axis) <= plane) & (extent <= 1.15) & (np.min(np.abs(span), axis=1) >= .85)
    quadrants = len(set(map(tuple, span[corners] > 0)))
    throat = int(((axis < -plane) & (axis > -2 * height) & (extent < .9)).sum())
    plug = int(((axis > plane) & (axis < 2 * height) & (extent < .8)).sum())
    why = []
    if quadrants != 4:
        why.append(f'its rectangular rim covers {quadrants} of 4 corners on the exit plane')
    if not throat:
        why.append('no throat upstream of the exit')
    if plug:
        why.append(f'{plug} mesh points in the exhaust path')
    return dict(ok=not why, why='; '.join(why), aperture=list(aperture), rim_corners=quadrants,
                plane_tolerance=round(plane, 6), throat_vertices=throat, exhaust_vertices=plug)

def image_size(path):
    """(width, height) read from a PNG or JPEG header, without decoding; None for anything else"""
    with open(path, 'rb') as f:
        head = f.read(26)
        if head[:8] == b'\x89PNG\r\n\x1a\n': return struct.unpack('>II', head[16:24])
        if head[:2] != b'\xff\xd8': return None
        f.seek(2)
        while True:
            m = f.read(4)
            if len(m) < 4 or m[0] != 0xFF: return None
            ln = struct.unpack('>H', m[2:4])[0]
            if m[1] in (0xC0, 0xC1, 0xC2, 0xC3, 0xC5, 0xC6, 0xC7, 0xC9, 0xCA, 0xCB, 0xCD, 0xCE, 0xCF):
                h, w = struct.unpack('>xHH', f.read(5)); return (w, h)
            f.seek(ln - 2, 1)

def main():
    a = sys.argv[1:]; shipj, out = a[0], a[1]; kw = dict(x.split('=', 1) for x in a[2:] if '=' in x)
    TOL_FRAC = float(kw.get('tol', .012)); UNBAKED = kw.get('unbaked') == '1'
    ship = json.load(open(shipj)); code = ship.get('game_code') or ship['ship']; probs = []; notes = []
    weapons = gamedata.weapons(ship['game_ship'])
    cls = gamedata.ship_attr(ship['game_ship'], 'cls', default='Cruiser')
    fac = gamedata.ship_attr(ship['game_ship'], 'fac', default=ship.get('faction'))
    wing = cls == 'Squadron'
    hangar = int(gamedata.ship_attr(ship['game_ship'], 'hangar', default=0) or 0)
    req = HP_CONTRACT.required_points(weapons, cls, fac, hangar)
    expected_breach = req['breach']
    g, blob = read_glb(os.path.join(out, code + '.glb')); nodes = g['nodes']
    root = next((i for i, n in enumerate(nodes) if n.get('name') == code), None)
    if root is None or 'mesh' not in nodes[root]: probs.append(f'no ship node named {code} with a mesh'); return finish(out, code, probs, notes, {})
    for k in ('translation', 'rotation', 'scale', 'matrix'):
        if k in nodes[root]: probs.append(f'the ship node has a {k}: its mesh and hard points must be in the ship frame as written')
    extras = nodes[root].get('extras', {})
    contract = extras.get('voidsworn_destruct', {})
    interiors = contract.get('interior_materials', [])
    seams = contract.get('seams', [])
    if wing:
        if 'voidsworn_destruct' in extras: probs.append('wing carries an authored destruction contract')
    else:
        if contract.get('version') != 1: probs.append('no authored interior/seams contract version 1')
        if not seams: probs.append('no authored break seams')
    signatures = set()
    for seam in seams:
        try:
            p, n = np.array(seam['p'], float), np.array(seam['n'], float)
            if p.shape != (3,) or n.shape != (3,) or not np.isfinite([p, n]).all() or abs(np.linalg.norm(n) - 1) > .001: raise ValueError()
            if 'span' in seam and (len(seam['span']) != 2 or not np.isfinite(seam['span']).all() or seam['span'][0] >= seam['span'][1]): raise ValueError()
            if not np.allclose(n, [0, 1, 0] if 'span' in seam else [1, 0, 0], atol=.001): raise ValueError()
            signature = (tuple(np.round(p, 7)), tuple(n), tuple(seam.get('span', [])))
            if signature in signatures: raise ValueError()
            signatures.add(signature)
        except (KeyError, TypeError, ValueError): probs.append('invalid authored break seam')
    if seams and not any('span' not in s for s in seams): probs.append('no authored transverse break seam')
    T = []; PT = []; IT = []; rooms = []; interior_seen = set(); hull_seen = False
    WM, parent = world_matrices(g)
    turret_ids = [i for i, n in enumerate(nodes) if re.fullmatch(HP_CONTRACT.TURRET_PATTERN, str(n.get('name', ''))) or (n.get('extras') or {}).get('kind') == 'turret']
    turn_meshes = [(i, nodes[i]) for i, n in enumerate(nodes) if 'mesh' in n and parent.get(i) in turret_ids]
    prims = [(pr, None) for pr in g['meshes'][nodes[root]['mesh']]['primitives']]
    # issue 1543: a door lobe's mesh hangs under its hinge node (HARDPOINTS.md "Doors"); shut, it is part of the ship's surface
    lobe_ids = {i for i, n in enumerate(nodes) if re.fullmatch(r'door_\d+_lobe_\d+', str(n.get('name', '')))}
    turn_meshes += [(i, nodes[i]) for i, n in enumerate(nodes) if 'mesh' in n and parent.get(i) in lobe_ids]
    for i, n in turn_meshes: prims += [(pr, WM[i]) for pr in g['meshes'][n['mesh']]['primitives']]
    for pr, M in prims:
        pos = accessor(g, blob, pr['attributes']['POSITION']).astype(np.float64)
        if M is not None: pos = pos @ M[:3, :3].T + M[:3, 3]
        idx = accessor(g, blob, pr['indices']).reshape(-1, 3).astype(np.int64) if 'indices' in pr else np.arange(len(pos)).reshape(-1, 3)
        mat = g['materials'][pr['material']].get('name', '') if 'material' in pr else ''
        if wing and mat.startswith(code + '_inside_'):
            probs.append(f'wing carries interior surface {mat}')
        if mat in interiors:
            IT.append(pos[idx]); interior_seen.add(mat)
            if mat != code + '_inside_skin': rooms.append(pos[idx])
            continue
        T.append(pos[idx])
        trim = 'material' in pr and (g['materials'][pr['material']].get('extras') or {}).get('hull_surface')
        if mat == code + '_hull' and M is None: hull_seen = True
        elif trim and M is None: pass                 # issue 642: the hull's own glowing trim (the Eclipse rim line), marked by the paint stack
        else: PT.append(pos[idx])                     # every surface but the hull is a part surface (parts, glow, turrets)
    if not hull_seen: probs.append(f'no {code}_hull surface: the hull cannot be told from the parts, so breach clearance cannot be measured')
    T = np.concatenate(T); A, B, C = T[:, 0], T[:, 1], T[:, 2]; lo, hi = T.reshape(-1, 3).min(0), T.reshape(-1, 3).max(0)
    PT = np.concatenate(PT) if PT else np.zeros((0, 3, 3))
    LEN = float(hi[0] - lo[0]); TOL = TOL_FRAC * LEN; VERTS = np.unique(T.reshape(-1, 3).round(6), axis=0)
    if not wing:
        if not IT: probs.append('no authored interior geometry')
        else:
            inside = np.concatenate(IT)
            area = np.linalg.norm(np.cross(inside[:, 1] - inside[:, 0], inside[:, 2] - inside[:, 0]), axis=1).sum() * .5
            if not np.isfinite(inside).all() or area <= 1e-10: probs.append('no usable authored interior geometry')
            notes.append(f'authored interiors: {len(inside)} triangles, {len(IT)} surfaces; authored seams: {len(seams)}')
        if not rooms: probs.append('no authored interior rooms: an inner liner alone is not comprehensive insides')
        else:
            room_geo = np.concatenate(rooms)
            if np.linalg.norm(np.cross(room_geo[:, 1] - room_geo[:, 0], room_geo[:, 2] - room_geo[:, 0]), axis=1).sum() <= 1e-10:
                probs.append('no authored interior rooms: room geometry has no area')
    if set(interiors) != interior_seen: probs.append('authored interior material list does not match its nonempty surfaces')
    for seam in seams:
        if len(seam.get('p', [])) != 3: continue
        p = np.array(seam['p'], float); n = np.array(seam.get('n', [0, 0, 0]), float)
        if n.shape != (3,): continue
        distances = (T.reshape(-1, 3) - p) @ n
        if distances.min() >= 0 or distances.max() <= 0: probs.append('authored break seam does not cross the hull')
    notes.append(f'{len(T)} triangles ({len(PT)} on part surfaces), box x {lo[0]:.3f} to {hi[0]:.3f}, y {lo[1]:.3f} to {hi[1]:.3f}, z {lo[2]:.3f} to {hi[2]:.3f}')
    notes.append(f'ship length {LEN:.4f}: off-mesh limit {TOL_FRAC} of it, {TOL:.4f}; breach clearance at least {BREACH_CLEAR}')
    kids = set(nodes[root].get('children', [])); hps = [(i, n) for i, n in enumerate(nodes) if str(n.get('name', '')).startswith('hp_')]
    by_slot = {}; count = {}; rows = []
    origin_sides = {'rcs': set(), 'board': set()}
    for i, n in hps:
        before = len(probs)
        nm = n['name']; M = WM[i]; p = M[:3, 3].copy()
        par = parent.get(i); under = par if par in turret_ids and parent.get(par) == root else None
        if i not in kids and under is None: probs.append(f'{nm} is not a child of the ship node')
        if under is not None and not nm.startswith('hp_w'): probs.append(f'{nm} hangs under a turret: only weapon muzzles turn with a turret')
        R3 = M[:3, :3] / np.linalg.norm(M[:3, :3], axis=0)[None, :]
        fwd = R3 @ np.array((0, 0, -1.0)); up = R3 @ np.array((0, 1.0, 0)); row = dict(name=nm, p=[round(v, 4) for v in p], fwd=[round(v, 3) for v in fwd])
        if under is not None: row['turret'] = nodes[under]['name']
        if nm == 'hp_core':
            count['core'] = count.get('core', 0) + 1
            if not (np.all(p >= lo) and np.all(p <= hi)): probs.append('hp_core is outside the hull')
            rows.append(row); continue
        d = float(tri_dist(p, A, B, C).min()); row['off_mesh'] = round(d, 4)
        extras = n.get('extras') or {}
        m = re.fullmatch(r'hp_w(\d+)_([A-Za-z0-9_]+)_([FTPS])_(\d+)', nm)
        aperture = extras.get('aperture') if nm.startswith('hp_eng_') else None
        if aperture is not None:
            exhaust = open_rectangular_exhaust(p, fwd, up, aperture, VERTS, TOL)
            row['exhaust'] = exhaust
            if not exhaust['ok']:
                probs.append(f'{nm} is not the centre of an open rectangular exhaust: {exhaust["why"]}')
        elif d > TOL and nm.startswith('hp_eng_'):
            # issue 592: an engine point is the centre of its bell's exit, and an open bell has no mesh at its centre. It passes
            # when the authored bell is there: its rim on the exit plane at the recorded radius, all round, its throat upstream
            # and its exhaust path clear (open_bell); the 0.012 limit is not loosened for any point
            bell = open_bell(p, fwd, float(extras.get('radius') or 0), VERTS, TOL)
            row['bell'] = bell
            if not bell.get('ok'): probs.append(f'{nm} is {d:.4f} off the mesh (limit {TOL:.4f}) and is not the centre of an open engine bell: {bell["why"]}')
        elif d > TOL and wing and m and m.group(2) == 'bombs':
            # A bomb launches from the open centre of its authored tube. Prove the rim, bore and clear exit.
            tube = open_bell(p, fwd, float(extras.get('radius') or 0), VERTS, TOL, require_clear_mouth=True)
            row['bomb_tube'] = tube
            if not tube['ok']:
                probs.append(f'{nm} is {d:.4f} off the mesh (limit {TOL:.4f}) and is not the centre of an open bomb tube: {tube["why"]}')
        elif d > TOL: probs.append(f'{nm} is {d:.4f} off the mesh (limit {TOL:.4f})')
        if m:
            slot, wk, arc = int(m.group(1)), m.group(2), m.group(3); count['gun'] = count.get('gun', 0) + 1
            if slot >= len(weapons) or weapons[slot] != (wk, arc):
                probs.append(f'{nm}: Godot has ' + (f'{weapons[slot][0]} {weapons[slot][1]}' if slot < len(weapons) else 'no weapon') + f' in slot {slot}')
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
            sec, side = ex.get('section'), ex.get('side')
            if sec not in BREACH_SECTIONS: probs.append(f'{nm}: extras.section is {sec!r}, not one of {", ".join(BREACH_SECTIONS)}')
            if side not in ('P', 'S'): probs.append(f'{nm}: extras.side is {side!r}, not P or S')
            else:
                sg = -1 if side == 'P' else 1                 # port is -Z in the game frame
                if p[2] * sg <= 0: probs.append(f'{nm}: a {"port" if side == "P" else "starboard"} breach anchor sits on the other side (z {p[2]:+.3f})')
                if up[2] * sg < .5: probs.append(f'{nm}: +Y is not the outward normal (it points z {up[2]:+.2f} on the {"port" if side == "P" else "starboard"} side)')
            if len(PT):
                cl = float(tri_dist(p, PT[:, 0], PT[:, 1], PT[:, 2]).min()); row['clear'] = round(cl, 4)
                if cl < BREACH_CLEAR - 1e-5: probs.append(f'{nm} is {cl:.4f} from a part (at least {BREACH_CLEAR})')   # 1e-5: float32 rounding only
        elif nm.startswith('hp_bay_'):
            count['bay'] = count.get('bay', 0) + 1
            if 'hangar' not in n.get('extras', {}): probs.append(f'{nm} has no extras.hangar')
        elif nm.startswith('hp_rcs_'):
            count['rcs'] = count.get('rcs', 0) + 1; ex = n.get('extras', {})
            side = ex.get('side')
            if side not in ('P', 'S'): probs.append(f'{nm}: extras.side is {side!r}, not P or S')
            elif not p[2] * (-1 if side == 'P' else 1) > 0: probs.append(f'{nm}: a {"port" if side == "P" else "starboard"} braking origin sits on the other side (z {p[2]:+.3f})')
            if not fwd[0] >= .5: probs.append(f'{nm}: a braking origin must point forward (+X, thrust against the motion)')
            if len(probs) == before: origin_sides['rcs'].add(side)
        elif nm.startswith('hp_board_'):
            count['board'] = count.get('board', 0) + 1; ex = n.get('extras', {})
            side = ex.get('side')
            if side not in ('P', 'S'): probs.append(f'{nm}: extras.side is {side!r}, not P or S')
            else:
                sg = -1 if side == 'P' else 1
                if not p[2] * sg > 0: probs.append(f'{nm}: a {"port" if side == "P" else "starboard"} boarding origin sits on the other side (z {p[2]:+.3f})')
                if not fwd[2] * sg >= .5: probs.append(f'{nm}: a boarding origin must point out of its own side')
            if len(probs) == before: origin_sides['board'].add(side)
        else: probs.append(f'{nm}: not a hard point name the contract defines')
        rows.append(row)
    # turrets (issue 560): every turret the kit marks reaches the glb as its own node with its turning mesh and its muzzles
    trows = []; tinfo = []
    for t in turret_ids:
        n = nodes[t]; nm = str(n.get('name', '')); ex = n.get('extras') or {}; M = WM[t]; p = M[:3, 3]
        R3 = M[:3, :3] / np.linalg.norm(M[:3, :3], axis=0)[None, :]; fwd = R3 @ np.array((0, 0, -1.0)); ax = R3 @ np.array((0, 1.0, 0))
        if parent.get(t) != root: probs.append(f'{nm} is not a child of the ship node')
        ch = n.get('children', [])
        mz = [c for c in ch if str(nodes[c].get('name', '')).startswith('hp_w')]
        has_mesh = any('mesh' in nodes[c] and nodes[c].get('name') == nm + '_turn' for c in ch)
        trows.append(dict(name=nm, extras=ex, has_mesh=has_mesh, muzzles=len(mz)))
        d = float(tri_dist(p, A, B, C).min())
        if d > TOL: probs.append(f'{nm}: its pivot is {d:.4f} off the mesh (limit {TOL:.4f}): the turret must turn about its own ring')
        if fwd[0] < -.05: probs.append(f'{nm} rests aimed backward (x {fwd[0]:+.2f}): no gun faces backward (RULEBOOK 4.2)')
        k = re.fullmatch(HP_CONTRACT.TURRET_PATTERN, nm)
        for c in mz:
            if k and (nodes[c].get('extras') or {}).get('turret') != int(k.group(1)):
                probs.append(f'{nodes[c]["name"]}: extras.turret is {(nodes[c].get("extras") or {}).get("turret")!r}, its turret is {nm}')
        tinfo.append(dict(name=nm, id=ex.get('id'), socket=ex.get('socket'), p=[round(v, 4) for v in p], fwd=[round(v, 3) for v in fwd],
                          axis=[round(v, 3) for v in ax], arc=[ex.get('arc_lo'), ex.get('arc_hi')], muzzles=[nodes[c]['name'] for c in mz], off_mesh=round(d, 4)))
    probs += HP_CONTRACT.turret_problems(trows)
    marked = set(g.get('asset', {}).get('extras', {}).get('turrets_marked') or [])
    for e in ship.get('parts', []):
        if e.get('part') == 'turret':
            marked.add(e['name'])
            if e.get('pair'): marked.add(e['name'] + '_s')
    have = {str(nodes[t].get('extras', {}).get('id')) for t in turret_ids} | {str(nodes[t].get('extras', {}).get('socket')) for t in turret_ids}
    for tid in sorted(marked):
        if tid not in have: probs.append(f'turret {tid} is marked by the kit but the export merged it into the ship mesh (no turret node of its own)')
    for i, n in hps:
        sock = (n.get('extras') or {}).get('socket')
        if sock in marked and parent.get(i) == root:
            probs.append(f'{n["name"]}: a muzzle of turret {sock} hangs on the ship node, so it would not turn with its barrels (merged turret)')
    notes.append(f'turrets: {len(turret_ids)} written ({", ".join(t["name"] + " " + str(t["id"]) for t in tinfo) or "none"}); marked by the kit: {sorted(marked) or "none"}')
    for slot, (wk, arc) in enumerate(weapons):
        if slot not in by_slot: probs.append(f'weapon slot {slot} ({wk} {arc}) has no hard point')
    if count.get('core', 0) > 1: probs.append('more than one hp_core')
    for prob in HP_CONTRACT.missing_required(count, weapons, cls, fac, hangar): probs.append(prob)
    probs.extend(HP_CONTRACT.missing_sides(req, origin_sides))
    breach_ex = [n.get('extras', {}) for i, n in hps if str(n.get('name', '')).startswith('hp_breach_')]
    for prob in HP_CONTRACT.check_breach_layout([(ex.get('section'), ex.get('side')) for ex in breach_ex]):
        probs.append(prob)
    unb = bool(g.get('asset', {}).get('extras', {}).get('unbaked'))
    if unb and not UNBAKED: probs.append('this is an unbaked test export (no maps): not a game ship folder')
    imgs = [im.get('uri') for im in g.get('images', [])]
    if not unb and not imgs: probs.append('the glb names no maps')
    for u in imgs:
        if not u or not os.path.exists(os.path.join(out, u)): probs.append(f'map {u} is named by the glb but is not in the folder')
    # Artoo on PR 1724: the hull and parts maps are measured as written, against the R411 band target (stage 7's own report
    # target when it ran with maps=); a smaller older bake is never upscaled, so it fails here until stage 5 rebakes it
    if not unb and not wing:
        rep = os.path.join(out, code + '_export.json')
        target = json.load(open(rep)).get('maps_target') if os.path.exists(rep) else None
        target = target or HP_CONTRACT.map_size(cls, ship.get('length_world'))
        sizes = {}
        for u in imgs:
            if u and os.path.exists(os.path.join(out, u)) and re.fullmatch(re.escape(code) + r'(_parts)?_(base|orm|normal|emission)\.\w+', u):
                wh = image_size(os.path.join(out, u))
                if wh: sizes[u] = max(wh)
        under = sorted(u for u, v in sizes.items() if v < target)
        notes.append(f'maps measured: {", ".join(f"{u} {v}" for u, v in sorted(sizes.items())) or "none"} (target {target})')
        if under: probs.append(f'maps under the {target} target (a smaller source bake; rebake at stage 5): ' + ', '.join(f'{u} {sizes[u]}' for u in under))
    mp = os.path.join(out, 'manifest_entry.json')
    if not os.path.exists(mp):
        probs.append('no manifest_entry.json: the export must write the point counts into the ship\'s manifest entry')
    else:
        entry = json.load(open(mp, encoding='utf-8'))
        if entry.get('hardpoints') != count:
            probs.append(f'manifest_entry.json hardpoints {entry.get("hardpoints")} do not match the written points {count}')
        if entry.get('breaches') != count.get('breach', 0):
            probs.append(f'manifest_entry.json breaches {entry.get("breaches")} do not match the written {count.get("breach", 0)}')
        if entry.get('cls') != cls:
            probs.append(f'manifest_entry.json cls {entry.get("cls")!r} is not {cls!r} (Godot)')
        if wing:
            wanted_role = None if unb else ship['game_ship']
            if entry.get('wing_role') != wanted_role or entry.get('faction') != HP_CONTRACT.faction_key(fac):
                probs.append('manifest_entry.json wing faction or role differs from the recipe')
    info = dict(cls=cls, faction=HP_CONTRACT.faction_key(fac), expected_breach=expected_breach,
                required=req, weapons=[dict(slot=s, weapon=wk, arc=arc, hard_points=sorted(by_slot.get(s, []))) for s, (wk, arc) in enumerate(weapons)],
                hardpoints=count, maps=imgs, tolerance=TOL, tolerance_of_length=TOL_FRAC, ship_length=LEN, breach_clearance=BREACH_CLEAR, rows=rows, turrets=tinfo)
    return finish(out, code, probs, notes, info)

def finish(out, code, probs, notes, info):
    ok = not probs; json.dump(dict(ok=ok, problems=probs, notes=notes, **info), open(os.path.join(out, code + '_check.json'), 'w'), indent=1)
    for n in notes: print('[check]', n)
    for w in info.get('weapons', []): print(f"[check] slot {w['slot']} {w['weapon']} {w['arc']}: {len(w['hard_points'])} hard points")
    print('[check] hard points:', json.dumps(info.get('hardpoints', {})))
    for p in probs: print('[check] PROBLEM:', p)
    print('PASS' if ok else 'FAIL', f'{code} game export:', 'every required point is there and every hard point passes the mesh checks' if ok else f'{len(probs)} problems')
    sys.exit(0 if ok else 1)

if __name__ == '__main__':
    main()
