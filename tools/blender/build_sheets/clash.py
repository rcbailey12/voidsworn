# The fit check (issue 532 round 3; Ryan, Nov 11 2026, R217 and R218; RULEBOOK 5.15 and 5.16; ships.md 2c).
# Runs inside Blender on the built blockout (build.py calls run() after the build; `build.py <code> <out> fit` runs only this).
# Every part of every type gets the same tests:
#   1. CLASH    no part intersects another part; no non-mount piece of a part (barrel, bell, blade, lid) sits inside the hull.
#               Mount pieces (rings, collars, plates, saddles) may sit into the hull, never into another part.
#   2. MOUNT    every part touches the hull through a mount piece (or sits on another part where the sheet says so).
#   3. ARC      every gun, at every bearing of its data.js slot arc (core.js inArc: F 60 either side of the bow, P and S 30 to
#               150 off the bow, T all round), has a clear line at some elevation it can reach (deck and belly turrets 0 to 30
#               degrees off the mount plane, casemates -10 to +20), out to 60 percent of the ship's length. A hit inside the
#               gun's own reach means its barrels would strike that part when trained there.
#   3b. SWEEP  (R219: turret guns turn to face their target) every turret's turning pieces (housing, mantlet, breeches,
#               barrels; parented to its pivot at the ring centre) are turned through every bearing of its slot arc in
#               5 degree steps at their rest elevation and must not touch the hull, any part or any other turret's resting
#               pieces; and every pair of turrets, both turning through their arcs (10 degree steps), must never meet
#               (barrel against barrel, barrel against housing).
#   4. EXHAUST  nothing sits in an engine's (or thruster's) exhaust cone: 12 degrees half-angle, out to 2.5 bell diameters or
#               22 percent of the ship's length, whichever is longer (thrusters 20 degrees, 1.2 units).
#   5. EXIT     no launcher cell, tube mouth, dish beam, hatch, lamp, vent or slit is covered: rays out along its axis (launch
#               cells to 80 percent of the ship's length with a 4 degree spread) hit nothing.
#   6. LANE     (R221: parts must not look like they conflict) every launcher has a firing lane forward of its cells (4 degree
#               spread, to 80 percent of the ship's length) and a backblast aft of the rack (15 degree spread, 2.5 rack depths or
#               15 percent of the ship's length); no gun may sit in either, resting or turned through its slot arc, even when no
#               mesh touches.
#   Turret reach (the 560 lesson: deck dressing can pin a turret): each turret is turned from rest each way in 5 degree steps
#               until something stops it; the fit report lists the real reach and flags any under 60 degrees either way.
# Writes <out>/<code>_fit.json: every clash (check, parts, where), the arcs, cones and apertures for the fit view.
import json, math, os
import bpy
from mathutils import Vector
from mathutils.bvhtree import BVHTree

ARCS = {'F': (-60.0, 60.0), 'P': (30.0, 150.0), 'S': (-150.0, -30.0), 'T': (-180.0, 180.0), 'R': (120.0, 240.0)}


def _mesh(o, dg):
    e = o.evaluated_get(dg); me = e.to_mesh()
    mw = o.matrix_world
    V = [mw @ v.co for v in me.vertices]
    F = [tuple(p.vertices) for p in me.polygons]
    e.to_mesh_clear()
    return V, F


def run(K, out, code, length, verbose=True):
    dg = bpy.context.evaluated_depsgraph_get()
    objs = [o for o in K.coll.objects if o.type == 'MESH']
    rec = []
    allV, allF, owner = [], [], []
    for i, o in enumerate(objs):
        V, F = _mesh(o, dg)
        if not V or not F:
            continue
        lo = Vector((min(v.x for v in V), min(v.y for v in V), min(v.z for v in V)))
        hi = Vector((max(v.x for v in V), max(v.y for v in V), max(v.z for v in V)))
        r = dict(name=o.name, grp=o.get('grp', 'hull'), role=o.get('role', 'hull'), V=V, F=F, lo=lo, hi=hi,
                 bvh=BVHTree.FromPolygons(V, F, epsilon=0.0))
        rec.append(r)
        o0 = len(allV); allV.extend(V)
        for f in F:
            allF.append(tuple(x + o0 for x in f)); owner.append(len(rec) - 1)
    ALL = BVHTree.FromPolygons(allV, allF, epsilon=0.0)
    allow = {frozenset((a, b)): why for a, b, why in K.allow}
    clashes = []
    seen = set()

    def add(check, a, b, where, detail, bearing=None):
        # one entry per (check, part, other part); ARC entries collect their blocked bearings into sectors
        key = (check, a, b)
        for c in clashes:
            if c['_key'] == key:
                if bearing is not None:
                    c['bearings'].append(bearing)
                c['n'] += 1
                return
        clashes.append(dict(_key=key, check=check, part=a, other=b, where=[round(c, 2) for c in where], detail=detail, n=1,
                            bearings=[bearing] if bearing is not None else []))

    # ---- 1. clash: object pairs from different groups whose meshes intersect
    n_pairs = 0
    for i in range(len(rec)):
        a = rec[i]
        for j in range(i + 1, len(rec)):
            b = rec[j]
            if a['grp'] == b['grp']:
                continue
            if a['grp'] == 'hull' and b['grp'] == 'hull':
                continue
            if any(a['lo'][k] > b['hi'][k] + 1e-4 or b['lo'][k] > a['hi'][k] + 1e-4 for k in range(3)):
                continue
            n_pairs += 1
            hull_pair = 'hull' in (a['grp'], b['grp'])
            part = b if a['grp'] == 'hull' else a
            if hull_pair and part['role'] == 'mount':
                continue
            if frozenset((a['grp'], b['grp'])) in allow:
                continue
            ov = a['bvh'].overlap(b['bvh'])
            if ov:
                p = sum((sum((a['V'][v] for v in a['F'][ov[0][0]]), Vector()) / len(a['F'][ov[0][0]]),), Vector())
                if hull_pair:
                    hob = a if part is b else b
                    add('CLASH', part['grp'], 'hull', p, '%s piece inside the hull or a hull mass (%s in %s)' % (part['role'], part['name'], hob['name']))
                else:
                    add('CLASH', a['grp'], b['grp'], p, 'parts intersect: %s and %s' % (a['name'], b['name']))

    # ---- 2. mount: every part group touches the hull with a mount piece
    groups = sorted({r['grp'] for r in rec if r['grp'] != 'hull'})
    hulls = [r for r in rec if r['grp'] == 'hull']
    for g in groups:
        mounts = [r for r in rec if r['grp'] == g and r['role'] == 'mount']
        ok = False
        for m in mounts:
            for h in hulls:
                if any(m['lo'][k] > h['hi'][k] + 0.05 or h['lo'][k] > m['hi'][k] + 0.05 for k in range(3)):
                    continue
                if m['bvh'].overlap(h['bvh']):
                    ok = True; break
                step = max(1, len(m['V']) // 400)
                for v in m['V'][::step]:
                    hit = h['bvh'].find_nearest(v)
                    if hit[0] is not None and hit[3] < 0.05:
                        ok = True; break
                if ok:
                    break
            if ok:
                break
        if not ok and not any(g in pr for pr in allow):
            c = mounts[0] if mounts else [r for r in rec if r['grp'] == g][0]
            add('MOUNT', g, 'hull', (c['lo'] + c['hi']) / 2, 'no mount piece touches the hull' if mounts else 'part has no mount piece')

    def cast(o, d, L, own):
        """first hit along a ray that is not the part itself: (distance, group, object name) or None"""
        o = Vector(o); d = Vector(d).normalized(); t0 = 0.0
        for _ in range(64):
            loc, nrm, idx, dist = ALL.ray_cast(o + d * t0, d, L - t0)
            if loc is None:
                return None
            r = rec[owner[idx]]
            if r['grp'] != own:
                return (t0 + dist, r['grp'], r['name'], loc)
            t0 += dist + 1e-4
            if t0 >= L:
                return None
        return None

    # ---- 3. arcs
    arcs = []
    env = 0.6 * length
    n_rays = 0
    for f in K.fitdata:
        if f['kind'] != 'gun':
            continue
        lo_, hi_ = ARCS.get(f['slot'] or 'T', (-180, 180))
        up = Vector(f['up']); piv = Vector(f['pivot'])
        bearings = []
        b = lo_
        while b <= hi_ + 1e-6:
            br = math.radians(b); hz = Vector((math.cos(br), math.sin(br), 0))
            clear_el = None; first = None
            for e in f['band']:
                er = math.radians(e)
                if f['mount'] in ('casemate', 'spinal'):
                    d = hz * math.cos(er) + Vector((0, 0, 1)) * math.sin(er)
                else:
                    d = hz * math.cos(er) + up * math.sin(er)
                n_rays += 1
                h = cast(piv, d, env, f['id'])
                if os.environ.get('CLASH_DEBUG') == '%s:%d' % (f['id'], b):
                    print('DEBUG', f['id'], b, e, h and (round(h[0], 2), h[2], tuple(round(c, 2) for c in h[3])))
                if h is None:
                    clear_el = e; break
                if first is None:
                    first = h
            bearings.append([round(b, 1), clear_el])
            if clear_el is None:
                what = 'barrels would strike %s' % first[1] if first[0] < f['reach'] else 'fire blocked by %s' % first[1]
                add('ARC', f['id'], first[1], first[3], '%s (slot %s): %s' % (what, f['slot'] or 'T', first[2]), bearing=b)
            b += 5.0
        arcs.append(dict(id=f['id'], pivot=list(piv), up=list(up), slot=f['slot'], mount=f['mount'], reach=f['reach'], bearings=bearings))

    # ---- 3b. turret sweeps (R219)
    from mathutils import Matrix
    sweeps = []
    turrets = [f for f in K.fitdata if f['kind'] == 'gun' and f['mount'] not in ('casemate', 'spinal')]  # fixed guns do not turn
    for f in turrets:
        movers = [r for r in rec if r['grp'] == f['id'] and r['role'] == 'turn']
        if not movers:
            add('SWEEP', f['id'], f['id'], f['pivot'], 'turret has no turning pieces'); continue
        V0, F0 = [], []
        for r in movers:
            o = len(V0); V0 += r['V']; F0 += [tuple(x + o for x in fc) for fc in r['F']]
        up = Vector(f['up']).normalized(); ring = Vector(f['ring'])
        ry = math.radians(f['rest_yaw']); rest = Vector((math.cos(ry), math.sin(ry), 0))
        lo_, hi_ = ARCS.get(f['slot'] or 'T', (-180, 180))
        n_ok = 0; b = lo_
        while b <= hi_ + 1e-6:
            br = math.radians(b); bd = Vector((math.cos(br), math.sin(br), 0))
            phi = math.atan2(rest.cross(bd).dot(up), rest.dot(bd))
            R = Matrix.Rotation(phi, 3, up)
            Vb = [ring + R @ (v - ring) for v in V0]
            lo = Vector((min(v.x for v in Vb), min(v.y for v in Vb), min(v.z for v in Vb)))
            hi = Vector((max(v.x for v in Vb), max(v.y for v in Vb), max(v.z for v in Vb)))
            tb = BVHTree.FromPolygons(Vb, F0, epsilon=0.0)
            hit = None
            for r in rec:
                if r['grp'] == f['id'] or any(lo[k] > r['hi'][k] or r['lo'][k] > hi[k] for k in range(3)):
                    continue
                ov = tb.overlap(r['bvh'])
                if ov:
                    hit = r; break
            if hit:
                add('SWEEP', f['id'], hit['grp'], (hit['lo'] + hit['hi']) / 2, 'turning through its arc hits %s' % hit['name'], bearing=b)
            else:
                n_ok += 1
            b += 5.0
        reach = []
        for sgn in (1, -1):
            got = 0
            for k_ in range(1, 37):
                R = Matrix.Rotation(math.radians(5.0 * k_ * sgn), 3, up)
                Vb = [ring + R @ (v - ring) for v in V0]
                lo = Vector((min(v.x for v in Vb), min(v.y for v in Vb), min(v.z for v in Vb)))
                hi = Vector((max(v.x for v in Vb), max(v.y for v in Vb), max(v.z for v in Vb)))
                tb = BVHTree.FromPolygons(Vb, F0, epsilon=0.0)
                stop = None
                for r in rec:
                    if r['grp'] == f['id'] or any(lo[k] > r['hi'][k] or r['lo'][k] > hi[k] for k in range(3)):
                        continue
                    if tb.overlap(r['bvh']):
                        stop = r['name']; break
                if stop:
                    reach.append(dict(deg=got, stop=stop)); break
                got = 5 * k_
            else:
                reach.append(dict(deg=180, stop=None))
        sweeps.append(dict(id=f['id'], slot=f['slot'], arc=[lo_, hi_], clear_steps=n_ok, rest_yaw=f['rest_yaw'],
                           reach_port=reach[0], reach_stbd=reach[1]))

    def seg_dist(p1, q1, p2, q2):
        d1 = q1 - p1; d2 = q2 - p2; r = p1 - p2
        a = d1.dot(d1); e = d2.dot(d2); f_ = d2.dot(r)
        if a < 1e-9 and e < 1e-9:
            return (p1 - p2).length
        if a < 1e-9:
            s_ = 0.0; t_ = min(1, max(0, f_ / e))
        else:
            c = d1.dot(r)
            if e < 1e-9:
                t_ = 0.0; s_ = min(1, max(0, -c / a))
            else:
                b_ = d1.dot(d2); den = a * e - b_ * b_
                s_ = min(1, max(0, (b_ * f_ - c * e) / den)) if den > 1e-9 else 0.0
                t_ = (b_ * s_ + f_) / e
                if t_ < 0:
                    t_ = 0.0; s_ = min(1, max(0, -c / a))
                elif t_ > 1:
                    t_ = 1.0; s_ = min(1, max(0, (b_ - c) / a))
        return ((p1 + d1 * s_) - (p2 + d2 * t_)).length

    def barrels_at(f, b):
        up = Vector(f['up']).normalized(); ring = Vector(f['ring'])
        ry = math.radians(f['rest_yaw']); rest = Vector((math.cos(ry), math.sin(ry), 0))
        br = math.radians(b); bd = Vector((math.cos(br), math.sin(br), 0))
        R = Matrix.Rotation(math.atan2(rest.cross(bd).dot(up), rest.dot(bd)), 3, up)
        piv = Vector(f['pivot'])
        return [(ring + R @ (piv - ring), ring + R @ (Vector(m) - ring)) for m in f['muzzles']]

    def bearings(f, step=10.0):
        lo_, hi_ = ARCS.get(f['slot'] or 'T', (-180, 180)); out = []; b = lo_
        while b <= hi_ + 1e-6:
            out.append(b); b += step
        return out
    for i, A in enumerate(turrets):
        for B in turrets[i + 1:]:
            if (Vector(A['pivot']) - Vector(B['pivot'])).length > A['reach'] + B['reach'] + A['hous_r'] + B['hous_r']:
                continue
            met = None
            for X, Y in ((A, B), (B, A)):
                axis0 = Vector(Y['ring']); axis1 = Vector(Y['pivot']) + Vector(Y['up']) * Y['hous_r'] * 0.5
                for bx in bearings(X):
                    for p0, p1 in barrels_at(X, bx):
                        if seg_dist(p0 + (p1 - p0) * 0.25, p1, axis0, axis1) < Y['hous_r'] * 0.85 + X['cal']:
                            met = '%s barrels at bearing %d reach %s\'s housing' % (X['id'], bx, Y['id']); break
                    if met:
                        break
                if met:
                    break
            if not met:
                for ba in bearings(A):
                    for bb in bearings(B):
                        for a0, a1 in barrels_at(A, ba):
                            for b0, b1 in barrels_at(B, bb):
                                if seg_dist(a0 + (a1 - a0) * 0.3, a1, b0 + (b1 - b0) * 0.3, b1) < A['cal'] + B['cal']:
                                    met = 'barrels meet with %s at %d and %s at %d' % (A['id'], ba, B['id'], bb); break
                            if met:
                                break
                        if met:
                            break
                    if met:
                        break
            if met:
                add('SWEEP', A['id'], B['id'], (Vector(A['pivot']) + Vector(B['pivot'])) / 2, met)

    # ---- 4. exhaust cones (rays and every vertex of every other part)
    import numpy as np
    VA = np.array([tuple(v) for v in allV], dtype=float)
    vown = np.zeros(len(allV), dtype=int)
    k = 0
    for i, r in enumerate(rec):
        vown[k:k + len(r['V'])] = i; k += len(r['V'])
    grp_of = np.array([r['grp'] for r in rec])
    cones = []
    for f in K.fitdata:
        for c in f.get('cones', []):
            apex = Vector(c['apex']); d = Vector(c['dir']).normalized(); L = c['length']; ta = math.tan(math.radians(c['half']))
            u = d.orthogonal().normalized(); w = d.cross(u)
            rays = [(apex, d)]
            for i in range(12):
                a = 2 * math.pi * i / 12; e = u * math.cos(a) + w * math.sin(a)
                rays.append((apex + e * c['r0'] * 0.92, (d + e * ta).normalized()))
            for o, dd in rays:
                n_rays += 1
                h = cast(o, dd, L, f['id'])
                if h:
                    add('EXHAUST', f['id'], h[1], h[3], 'exhaust cone hits %s at %.1f behind the exit' % (h[2], h[0]))
            rel = VA - np.array(tuple(apex))
            ax = rel @ np.array(tuple(d))
            rad = np.linalg.norm(rel - np.outer(ax, np.array(tuple(d))), axis=1)
            inside = (ax > 0.02) & (ax < L) & (rad < c['r0'] + ax * ta) & (grp_of[vown] != f['id'])
            if inside.any():
                idx = np.where(inside)[0]
                gs = sorted(set(grp_of[vown[idx]]))
                for g in gs:
                    j = idx[grp_of[vown[idx]] == g][0]
                    add('EXHAUST', f['id'], str(g), Vector(VA[j]), 'part inside the exhaust cone: %s' % rec[vown[j]]['name'])
            cones.append(dict(id=f['id'], apex=list(apex), dir=list(d), r0=c['r0'], half=c['half'], length=L))

    # ---- 5. exits and apertures
    aps = []
    for f in K.fitdata:
        for a in f.get('apertures', []):
            o = Vector(a['pos']); d = Vector(a['dir']).normalized(); L = a['length']
            rays = [(o, d)]
            if a.get('cone'):
                u = d.orthogonal().normalized(); w = d.cross(u); ta = math.tan(math.radians(a['cone']))
                for e in (u, -u, w, -w):
                    rays.append((o + e * a.get('r', 0.0), (d + e * ta).normalized()))
            blocked = None
            for oo, dd in rays:
                n_rays += 1
                h = cast(oo, dd, L, f['id'])
                if h:
                    blocked = h; break
            if blocked:
                add('EXIT', f['id'], blocked[1], blocked[3], '%s covered by %s at %.1f' % (a['what'], blocked[2], blocked[0]))
            aps.append(dict(id=f['id'], kind=f['kind'], pos=list(o), dir=list(d), length=L, blocked=bool(blocked)))

    # ---- 6. firing lanes and backblast (R221)
    lanes = []
    guns = [f for f in K.fitdata if f['kind'] == 'gun']

    def in_lane(ln, p):
        rel = Vector(p) - Vector(ln['apex']); a_ = rel.dot(Vector(ln['dir']))
        if a_ <= 0 or a_ >= ln['length']:
            return False
        t_ = math.tan(math.radians(ln['half']))
        return abs(rel.dot(Vector(ln['u']))) < ln['hu'] + a_ * t_ and abs(rel.dot(Vector(ln['w']))) < ln['hw'] + a_ * t_
    for f in K.fitdata:
        for ln in f.get('lanes', []):
            lanes.append(dict(id=f['id'], **ln))
            for g in guns:
                if g['id'] == f['id']:
                    continue
                hit = None
                for r in rec:
                    if r['grp'] != g['id']:
                        continue
                    for v in r['V']:
                        if in_lane(ln, v):
                            hit = ('resting', v); break
                    if hit:
                        break
                if not hit and g['mount'] != 'casemate':
                    for bx in bearings(g, 5.0):
                        for p0, p1 in barrels_at(g, bx):
                            for t_ in (0.25, 0.5, 0.75, 1.0):
                                q = p0 + (p1 - p0) * t_
                                if in_lane(ln, q):
                                    hit = ('turned to bearing %d' % bx, q); break
                            if hit:
                                break
                        if hit:
                            break
                if hit:
                    add('LANE', g['id'], f['id'], hit[1], 'gun %s sits in %s\'s %s (%s)' % (g['id'], f['id'], ln['what'], hit[0]))

    for c in clashes:
        del c['_key']
        if c['bearings']:
            bs = sorted(c['bearings']); sec = [[bs[0], bs[0]]]
            for b_ in bs[1:]:
                if b_ - sec[-1][1] <= 5.01:
                    sec[-1][1] = b_
                else:
                    sec.append([b_, b_])
            c['detail'] += '; blocked bearings ' + ', '.join('%d to %d' % (a_, b_) if a_ != b_ else '%d' % a_ for a_, b_ in sec)
    res = dict(code=code, clashes=clashes, counts={c: sum(1 for x in clashes if x['check'] == c) for c in ('CLASH', 'MOUNT', 'ARC', 'SWEEP', 'EXHAUST', 'EXIT', 'LANE')},
               tested=dict(objects=len(rec), parts=len(groups), close_pairs=n_pairs, rays=n_rays, guns=len(arcs), turrets_swept=len(sweeps), cones=len(cones), apertures=len(aps), lanes=len(lanes)),
               arcs=arcs, sweeps=sweeps, cones=cones, apertures=aps, lanes=lanes, fixes=[list(x) for x in K.fixes], allowed=[list(x) for x in K.allow])
    json.dump(res, open(os.path.join(out, code + '_fit.json'), 'w'), indent=1, default=lambda v: list(v) if hasattr(v, '__iter__') else str(v))
    if verbose:
        print('FIT', code, res['counts'], res['tested'])
        for c in clashes:
            print('  %-8s %-10s %-12s x%-3d %s' % (c['check'], c['part'], c['other'], c['n'], c['detail']))
    return res
