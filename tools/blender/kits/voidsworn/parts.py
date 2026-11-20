# Sunward Crusade (`voidsworn`) part shapes (issue 738, the Daybreak flagship build sheet voidsworn_S8; RULEBOOK 4.5: every
# faction its own kit, only the invisible plumbing in tools/blender/kits/shared/geom.py is shared).
# The faction sheet (docs/playbooks/factions.md, Sunward Crusade): "a black iron blade with burning spires"; forged, heavy,
# vertical; broadside gun decks in long straight rows; big engine bells, ember orange, deep-set; plate with rivet lines, never
# rust; black iron, frost-white markings, bright ember (windows, engines, and the spires, which glow because they shed the
# reactor's heat); the spires are radiators, never steeples (no crosses, no statues); never blue light. Lore (lore bible 2.5):
# "old manual gun decks", unaugmented crews, no AI. Ryan's part rules (R217, R218, R221) hold for every type: an engine reads as
# an engine, a gun has a base, a mount and a muzzle that say how it fires, every part carries the ship's detail level (R224).
#   gun          (R221) built from the weapon it carries (data.js W, FAC_WNAMES.voidsworn, godot/fx/fx_weapons.gd looks):
#                broadside (hbattery, the Heavy sear broadside, look 'macro'): a heavy short gun in a deep round armoured port
#                  on the flank, a ball mantlet set back in the port, a finned heat jacket, a flared muzzle with an ember-hot bore
#                sear turret (turret, the Sear turret, look 'las'): a forged faceted turret on a riveted barbette ring, one heavy
#                  focusing emitter in a block mantlet (stacked cooling rings, a lens collar, an ember lens deep in the bore),
#                  ember-slatted radiator fins on its bustle (a las weapon sheds heat like the ship's spires)
#                spark flak (flak, look 'flak'): a squat forged drum turret, two short barrels in slotted cooling sleeves with
#                  muzzle brakes, an ammunition drum on each cheek, elevating high for craft
#   engine_bell  a big riveted drum with banded plates and a heavy mount collar, a deep bell with stiffener rings and a rolled
#                lip, an ember lining, a hot throat and a glowing plug cone deep inside (S8: two big ember bells)
#   radiator     a radiator spire (never a steeple or a mast): a forged root socket, a column of iron posts round a dark core,
#                a stack of flat radiator fins out to each side glowing ember, rivet lines, a forged cap, gusset braces; four
#                profiles so no two neighbours match (pack.md: "not exactly the same shape for every ship")
#   hatch, hatchbox, vent, lamp, slit, thruster, plate_slab, forged_plates: the Sunward versions (forged round hatches with
#                studs, armoured deck housings, heat louvres, frost-white lamps, ember window slits, round thruster throats
#                with depth (R244), forged plates with rivet lines in ordered rows and sleek triangles on the flat fields (R243))
# Local frame of every part: +X forward (the aim, or the engine's thrust direction), +Y left, +Z up (the mount normal).
# Roles: 'mount' parts may sit into the hull; every other role must stay clear of it; 'turn' (turret guns, R219) turns.
# Materials: the Sunward rows are this kit's own (MATS below; the ship file merges them into the sheet kit's table before it
# builds, so the shared tools/blender/build_sheets/kit.py is untouched), plus the shared dark, glow, ember and steel.
import math
import os
import sys
from mathutils import Vector, Matrix

sys.path.insert(0, os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'shared')))
from geom import Part, P, D, frame, revolve, prism, octa, block, moved, ring_band, rod  # noqa: E402,F401
import geom  # noqa: E402

# R226: the part kinds that are machines (a machine never crosses a seam; it rides whole with one piece). Radiator spires are
# structure: they belong to the spire line, which snaps off as one piece along its own peel (factions.md "How it breaks").
MACHINES = ('gun', 'engine', 'thruster')

# The Sunward colour zones (factions.md: black iron, frost-white markings, bright ember; never rust, never blue light), in the
# sheet kit's format (rgb, emission strength). Schematic; the Sunward paint stack (paint_direction_2026_11/sunward.md) finishes
# them. METALLIC: the rows the sheet renders as worked metal.
MATS = {
    'siron': ((0.047, 0.045, 0.044), 0),     # black iron plate
    'siron2': ((0.026, 0.025, 0.025), 0),    # darker recessed iron (sockets, frames, the second plate family)
    'sworn': ((0.15, 0.147, 0.142), 0),      # worked bright iron: rivets, bands, rims, machinery
    'embar': ((1.0, 0.36, 0.07), 1.2),       # ember radiator fins and hot lenses (the spires shed the reactor's heat); 1.2 keeps it ember, not lemon
    'frost': ((0.9, 0.92, 0.92), 0.6),       # frost-white running points (paint direction 5), never blue over green
    'gallery': ((0.72, 0.36, 0.13), 0),      # inside: the gun crews' galleries, ember-lit (factions.md "Inside")
}
METALLIC = ('sworn',)

SUBPARTS = {
    'engine': ['housing', 'band', 'collar', 'bell', 'lining', 'throat', 'plug', 'bellring'],
    'gun': ['ring|port', 'mantlet', 'barrel', 'jacket', 'muzzle', 'bore'],
    'radiator': ['root', 'column', 'cap', 'fin', 'bar', 'brace'],
    'hatch': ['rim', 'door', 'seam', 'hinge'],
    'hatchbox': ['frame', 'lid', 'rib'],
    'vent': ['frame', 'slat'],
    'lamp': ['housing', 'lens'],
    'slit': ['frame', 'glass'],
    'thruster': ['block', 'nozzle'],
    'plate': ['slab', 'step', 'bevel', 'rivet'],
    'hull': ['facet', 'step', 'chamfer'],
    'belt': ['band', 'plate'],
    'tier': ['face', 'roof', 'opening'],
    'spine': ['block', 'step', 'slit'],
    'rib': ['rib'],
}


def detail_ok(kind, names):
    return geom.detail_ok(SUBPARTS, kind, names)


def _zrev(profile, n, phase=0.0, **kw):
    """a revolve about the local Z axis (a vertical solid of revolution): profile [(z, r)]"""
    return revolve(profile, n, axis='Z', phase=phase, **kw)


def _stud(c, nrm, r):
    """one rivet head: a low four-sided dome (a square base and an apex) at c on a face with normal nrm"""
    c = Vector(c); n = Vector(nrm).normalized()
    u = n.orthogonal().normalized() * r; w = n.cross(u).normalized() * r
    V = [c - u, c - w, c + u, c + w, c + n * r * 0.7]
    F = [(0, 1, 4), (1, 2, 4), (2, 3, 4), (3, 0, 4), (3, 2, 1, 0)]
    return [tuple(v) for v in V], F


def _join(parts):
    V, F = [], []
    for v, f in parts:
        o = len(V); V.extend(v); F.extend(tuple(x + o for x in q) for q in f)
    return V, F


def _ring_studs(z, r, n, rr, phase=0.0, out=True):
    """rivet studs round a vertical ring (local Z axis) at height z, radius r, facing out (or up when out is False)"""
    parts = []
    for i in range(n):
        a = 2 * math.pi * i / n + phase
        c = Vector((r * math.cos(a), r * math.sin(a), z))
        parts.append(_stud(c, Vector((math.cos(a), math.sin(a), 0)) if out else Vector((0, 0, 1)), rr))
    return _join(parts)


def _x_studs(x, r, n, rr, phase=0.0):
    """rivet studs round a ring about the local X axis at station x, radius r, facing out"""
    parts = []
    for i in range(n):
        a = 2 * math.pi * i / n + phase
        c = Vector((x, r * math.cos(a), r * math.sin(a)))
        parts.append(_stud(c, Vector((0, math.cos(a), math.sin(a))), rr))
    return _join(parts)


# ---------------------------------------------------------------------------------------------------- plate courses
PANEL = (0.36, 0.62)   # world units across and along: the hull's own forged plate size (the sheet lays the hull at about 0.5 by 0.9)


def panels(p, tag, role, mats, x0, x1, r, n, phase, skip=(), th=0.024, size=PANEL, seed=0, rivets=True):
    """forged plate courses on the flat faces of an n-sided revolve about X (radius r to its corners, phase as revolve's) from
    x0 to x1, laid at the hull's own plate size in world units (issue 618's rule for kit parts, R224), in ordered rows: each a
    chamfered slab with a gap round it, a rivet at each end of its long axis. One comp per material."""
    ap = r * math.cos(math.pi / n); fw = 2 * r * math.sin(math.pi / n)
    across = max(1, int(round(fw / size[0]))); along = max(1, int(round((x1 - x0) / size[1])))
    g = min(0.025, fw / across * 0.12, (x1 - x0) / along * 0.12)
    acc = {m: ([], []) for m in mats}; RV = []
    for k in range(n):
        if k in skip:
            continue
        a = 2 * math.pi * (k + 0.5) / n + phase
        nv = Vector((0, math.cos(a), math.sin(a))); tv = Vector((0, -math.sin(a), math.cos(a)))
        for i in range(along):
            xa = x0 + (x1 - x0) * i / along + g; xb = x0 + (x1 - x0) * (i + 1) / along - g
            for j in range(across):
                ta = -fw / 2 + fw * j / across + g; tb = -fw / 2 + fw * (j + 1) / across - g
                h = th * (0.8 + 0.4 * (((k * 7 + i * 13 + j * 5 + seed) * 2654435761) % 1000) / 1000.0)
                e = min(h * 0.8, (xb - xa) * 0.2, (tb - ta) * 0.2)
                base = [(xa, ta), (xb, ta), (xb, tb), (xa, tb)]
                top = [(xa + e, ta + e), (xb - e, ta + e), (xb - e, tb - e), (xa + e, tb - e)]
                V = [Vector((x, 0, 0)) + nv * (ap - 0.004) + tv * t for x, t in base] + [Vector((x, 0, 0)) + nv * (ap + h) + tv * t for x, t in top]
                F = [(3, 2, 1, 0), (4, 5, 6, 7), (0, 1, 5, 4), (1, 2, 6, 5), (2, 3, 7, 6), (3, 0, 4, 7)]
                m = mats[(i + j + k + seed) % len(mats)]
                VV, FF = acc[m]; o = len(VV); VV.extend(tuple(v) for v in V); FF.extend(tuple(q + o for q in f) for f in F)
                if rivets:
                    for xr in (xa + (xb - xa) * 0.18, xb - (xb - xa) * 0.18):
                        RV.append(_stud(Vector((xr, 0, 0)) + nv * (ap + h) + tv * (ta + tb) / 2, nv, 0.018))
    for m, (VV, FF) in acc.items():
        if FF:
            p.add('%s_plate_%s' % (tag, m), role, m, (VV, FF))
    if RV:
        p.add('%s_rivet' % tag, role, 'sworn', _join(RV))


def plate_slab(bot, nrm, t, bevel=0.3, rivets=True, lift=0.0, rr=0.03, sink=0.02, inmax=0.07):
    """one forged plate on a hull face: bot = three or four corners on the surface (world), nrm = outward normal. A slab of
    thickness t with a chamfer on its top edges (bevel, a share of t) and a rivet line along its long edge (two studs on a
    triangle, three on a quad). Returns ((verts, faces) of the slab, (verts, faces) of the rivets)."""
    bot = [Vector(q) for q in bot]; nrm = Vector(nrm); k = len(bot)
    mid = sum(bot, Vector()) / k
    top = []
    for i, q in enumerate(bot):
        sh = (mid - q).normalized() * min(t * (1 + bevel * 2), (mid - q).length * 0.3)
        top.append(q + nrm * (t + (lift if i == 2 else 0.0)) + sh)
    base = [q - nrm * sink for q in bot]
    V = [tuple(q) for q in base + top]
    F = [tuple(range(k))[::-1], tuple(range(k, 2 * k))] + [(i, (i + 1) % k, k + (i + 1) % k, k + i) for i in range(k)]
    RV = []
    if rivets:
        # the rivet line runs along the plate's longest edge, set in from it
        ei = max(range(k), key=lambda i: (top[(i + 1) % k] - top[i]).length)
        a, b = top[ei], top[(ei + 1) % k]
        inward = (mid + nrm * t - (a + b) / 2)
        inward = inward.normalized() * min(inmax, inward.length * 0.35)
        for f in ((0.2, 0.8) if k == 3 else (0.15, 0.5, 0.85)):
            RV.append(_stud(a.lerp(b, f) + inward, nrm, rr))
    return (V, F), _join(RV) if RV else ([], [])


def forged_plates(rings, faces, size, thick, mats, seed=1, keep=None, tri=False, offset=True, step_every=5, rr=0.026, closed=True, unit=1.0):
    """Sunward plating over the quad strips of a loft (rings: lists of world points, the same count each, in order along the
    mass; faces: the ring edge indices to plate). Forged, never scavenged (paint_direction sunward.md: patch_warp 0): every face
    is laid in ordered rows at the plate size in world units both ways, rows offset by half a plate on alternate courses (a
    forged bond, never random), every step_every-th plate carries a narrower reinforcing strip (the thickness step), rivet
    lines along each plate's long edge. tri=True lays the face in sleek triangles instead (R243, Ryan: "Sunward could have more
    triangle sleek panels"): each cell an arrow plate pointing forward with two infill triangles beside it. keep(p, r) returns
    True where a mount claims the surface (no plate there). unit (issue 769, the squadron craft) scales the fixed sizes in world
    units (the smallest face plated, the gaps, the sink under the surface) for a hull far smaller than a capital ship; 1.0 is the
    capital ships' plating, unchanged. Returns ({mat: (V, F)}, (rivet V, F), plates laid)."""
    import random
    rnd = random.Random(seed)
    lo, hi = size
    tlo, thi = thick
    names = list(mats); wts = [mats[k_] for k_ in names]
    n = len(rings[0])
    acc = {k_: ([], []) for k_ in names}
    RV = []
    laid = 0
    cen = [sum((Vector(q) for q in r), Vector()) / n for r in rings]
    count = 0
    for i in range(len(rings) - 1):
        for j in faces:
            if not closed and j >= n - 1:
                continue
            A, B = Vector(rings[i][j]), Vector(rings[i][(j + 1) % n])
            Dq, C = Vector(rings[i + 1][j]), Vector(rings[i + 1][(j + 1) % n])
            flen = ((Dq - A).length + (C - B).length) / 2; fw = ((B - A).length + (C - Dq).length) / 2
            if flen < 0.25 * unit or fw < 0.18 * unit:
                continue
            nrm = (B - A).cross(Dq - A)
            if nrm.length < 1e-7:
                nrm = (C - B).cross(Dq - B)
            if nrm.length < 1e-7:
                continue
            nrm.normalize()
            if nrm.dot((A + C) / 2 - (cen[i] + cen[i + 1]) / 2) < 0:
                nrm = -nrm

            def Pq(u, v):
                return A.lerp(Dq, u).lerp(B.lerp(C, u), v)
            nv = max(1, int(round(fw / lo)))
            nu = max(1, int(round(flen / hi)))
            g = 0.035 * unit
            for b in range(nv):
                v0, v1 = b / nv + g / fw, (b + 1) / nv - g / fw
                sh = (0.5 / nu) if (offset and b % 2) else 0.0
                us = [0.0] + [min(1.0, max(0.0, (a + sh) / nu)) for a in range(1, nu + 1)]
                if sh:
                    us = [0.0] + [(a - 0.5) / nu for a in range(1, nu + 1)] + [1.0]
                for a0, a1 in zip(us, us[1:]):
                    u0, u1 = a0 + g / flen, a1 - g / flen
                    if u1 - u0 < 0.08 * unit / flen or v1 <= v0:
                        continue
                    pc = Pq((u0 + u1) / 2, (v0 + v1) / 2); hd = 0.5 * ((u1 - u0) * flen + (v1 - v0) * fw)
                    if keep and keep(pc, hd):
                        continue
                    count += 1
                    t = tlo + (thi - tlo) * (((count * 2654435761 + seed * 97) % 1000) / 1000.0)
                    k_ = names[(i * 3 + j * 5 + b + int(a0 * 7)) % len(names)] if len(names) > 1 and rnd.random() < 0.85 else rnd.choices(names, wts)[0]
                    if tri and (u1 - u0) * flen > 0.3 * unit:
                        # two sleek triangles per cell, split on the one diagonal so the rows run straight (point forward)
                        gu, gv = 0.03 * unit / flen, 0.03 * unit / fw
                        cells = [([Pq(u0 + gu, v0), Pq(u1, v0), Pq(u1, v1 - gv)], k_),
                                 ([Pq(u0, v0 + gv), Pq(u1 - gu, v1), Pq(u0, v1)], names[(count + 1) % len(names)])]
                        for bot, mk in cells:
                            (V, F), (rv, rf) = plate_slab(bot, nrm, t, rivets=True, rr=rr, sink=0.02 * unit, inmax=0.07 * unit)
                            bv, bf = acc[mk]; o = len(bv); bv.extend(V); bf.extend(tuple(x + o for x in f) for f in F)
                            if rv:
                                RV.append((rv, rf))
                            laid += 1
                    else:
                        bot = [Pq(u0, v0), Pq(u1, v0), Pq(u1, v1), Pq(u0, v1)]
                        (V, F), (rv, rf) = plate_slab(bot, nrm, t, rivets=True, rr=rr, sink=0.02 * unit, inmax=0.07 * unit)
                        bv, bf = acc[k_]; o = len(bv); bv.extend(V); bf.extend(tuple(x + o for x in f) for f in F)
                        if rv:
                            RV.append((rv, rf))
                        laid += 1
                        if step_every and count % step_every == 0:
                            # the thickness step: a narrower reinforcing strip along the plate's middle
                            cv = (v0 + v1) / 2; hv = (v1 - v0) * 0.22
                            b2 = [Pq(u0 + (u1 - u0) * 0.12, cv - hv) + nrm * t, Pq(u1 - (u1 - u0) * 0.12, cv - hv) + nrm * t,
                                  Pq(u1 - (u1 - u0) * 0.12, cv + hv) + nrm * t, Pq(u0 + (u1 - u0) * 0.12, cv + hv) + nrm * t]
                            (V, F), _ = plate_slab(b2, nrm, t * 0.7, rivets=False, sink=0.02 * unit)
                            o = len(bv); bv.extend(V); bf.extend(tuple(x + o for x in f) for f in F)
    return acc, _join(RV) if RV else ([], []), laid


# ---------------------------------------------------------------------------------------------------- engine
def engine_bell(r_exit, body_len, bell_len=None, body_r=None, throat=0.55, rings=3, struts=8, nose='flat', seg=28, craft=False):
    """the Sunward engine (S8: big riveted drums behind deep bells); exhaust leaves along -X; origin at the centre of the bell's
    exit plane. bell: deep, a thick rolled lip, stiffener rings on its back laid at the hull's plate pitch (R224); inside it an
    ember lining, a hot throat and a glowing plug cone (Hullbreaker R228 lesson, held here: the plug glows hottest, never black;
    the paint stack varies the glow later). housing: a 16-sided drum of forged plates in ordered courses, riveted bands round
    it and a heavy mount collar at its front (deep-set: the collar and drum sit in the stern armour). craft=True (issue 769):
    a squadron craft's drive instead, craft_drive below (the sheet kit's K.engine passes it through kw)."""
    if craft:
        return craft_drive(r_exit, body_len, bell_len=bell_len, cowl_r=body_r, throat=throat)
    p = Part('engine')
    bl = bell_len or r_exit * 1.05
    br = body_r or r_exit * 0.92
    t = max(0.04, r_exit * 0.075)
    rt = r_exit * throat
    k = 8
    outer = [(bl - bl * i / k, rt + (r_exit - rt) * (i / k) ** 1.5) for i in range(k + 1)]
    lip = [(-t * 0.6, r_exit + t * 1.2), (-t * 0.6, r_exit - t * 0.5)]
    inner = [(x, max(rt * 0.8, r - t * 1.3)) for (x, r) in reversed(outer)]
    p.add('bell', 'body', 'siron', revolve(outer + lip + inner[1:], seg, closed=True, phase=math.pi / seg))
    p.add('lining', 'body', 'ember', revolve([(x - 0.004, max(rt * 0.78, r - t * 1.35)) for (x, r) in outer[::-1][:-1]], seg, phase=math.pi / seg))
    nr = max(2, int(round(bl / 0.14)))
    for i in range(nr):
        u = (i + 0.7) / (nr + 0.4); x = bl * (1 - u); rr = rt + (r_exit - rt) * (1 - x / bl) ** 1.5
        p.add('bellring%d' % i, 'body', 'sworn', revolve([(x + 0.035, rr - 0.005), (x + 0.035, rr + t * 0.75), (x - 0.035, rr + t * 0.75), (x - 0.035, rr - 0.005)],
                                                          seg, closed=True, phase=math.pi / seg))
    p.add('throat', 'body', 'glow', revolve([(bl * 0.92, rt * 0.82), (bl * 0.98, 0.001)], seg, cap0=False))
    p.add('plug', 'body', 'glow', revolve([(bl * 0.9, rt * 0.62), (bl * 0.55, rt * 0.42), (bl * 0.18, 0.001)], seg, cap0=True))
    # the drum housing: 16 flats, forged plate courses, riveted bands, a mount collar
    xf = bl + body_len
    ph = math.pi / 16
    house = [(bl - t, rt * 1.05), (bl + r_exit * 0.12, br * 0.86), (bl + r_exit * 0.2, br), (xf - br * 0.12, br), (xf, br * 0.82), (xf, 0.001)]
    p.add('housing', 'mount', 'siron2', revolve(house, 16, cap0=False, phase=ph))
    panels(p, 'housing', 'mount', ('siron', 'siron2'), bl + r_exit * 0.24, xf - br * 0.42, br, 16, ph, seed=5, th=0.03)
    nb = max(2, int(body_len / 0.7))
    for i in range(nb):
        x = bl + r_exit * 0.22 + (body_len - r_exit * 0.22 - br * 0.45) * i / max(1, nb - 1)
        p.add('band%d' % i, 'mount', 'sworn', revolve([(x - 0.06, br * 0.99), (x - 0.06, br * 1.06), (x + 0.06, br * 1.06), (x + 0.06, br * 0.99)],
                                                      16, closed=True, phase=ph))
        p.add('bandstud%d' % i, 'mount', 'sworn', _x_studs(x, br * 1.06, 32, 0.026, phase=ph))
    p.add('collar', 'mount', 'siron', revolve([(xf - br * 0.42, br * 0.98), (xf - br * 0.42, br * 1.14), (xf - br * 0.1, br * 1.14),
                                               (xf - br * 0.1, br * 0.98)], 16, closed=True, phase=ph))
    p.add('collarstud', 'mount', 'sworn', _x_studs(xf - br * 0.26, br * 1.14, 32, 0.028, phase=ph))
    # rivet rows round the lip of the bell (the forged bell is riveted to its lip ring)
    p.add('lipstud', 'body', 'sworn', _x_studs(t * 1.4, r_exit + t * 1.05, 40, 0.024))
    for i in range(struts):
        a = 2 * math.pi * (i + 0.5) / struts
        c, s = math.cos(a), math.sin(a)
        r1 = rt + (r_exit - rt) * 0.55 ** 1.5 + t
        p.add('strut%d' % i, 'mount', 'sworn', rod((bl + r_exit * 0.25, br * 0.97 * c, br * 0.97 * s), (bl * 0.45, r1 * c, r1 * s), 0.045, 6))
    p.fit = dict(exit=P((0, 0, 0)), axis=D((-1, 0, 0)), radius=r_exit + t * 1.2, front=P((xf, 0, 0)), body_r=br)
    return p


# ---------------------------------------------------------------------------------------------------- guns
# R221 (Ryan, Nov 12: weapons "more unique per factions and fit the actual weapons they use per lore Bible and faction rules").
# Every Sunward weapon is built from what it is: data.js W and FAC_WNAMES.voidsworn (the Sear weapons carry the las trait,
# FAC_WTRAIT), the battle look in godot/fx/fx_weapons.gd (hbattery 'macro', turret 'las', flak 'flak'), the lore bible 2.5 ("Heavy
# broadside decks ... old manual gun decks") and the faction sheet (forged, heavy, vertical; plate with rivet lines). The design
# line per weapon is in WEAPONS below and in tools/blender/kits/voidsworn/README.md.
WEAPONS = {
    'hbattery': dict(
        name='Heavy sear broadside', rules='data.js hbattery: 5 shots, 7 damage, range 5 (k battery); FAC_WTRAIT las: +4 aim, half the long-range falloff',
        lore='Lore 2.5 and 2.7: heavy broadside decks, old manual gun decks; broadsides hit 40% harder after moving. Battle look: macro shells.',
        design=('A heavy short gun in an old manual gun deck: a deep round armoured port standing out of the flank (a forged '
                'collar with a rolled lip and a ring of rivets on its square surround), a ball mantlet set back in the port, a '
                'finned heat jacket (the sear rounds leave the bore white hot), a flared muzzle with a dark bore glowing ember '
                'deep inside. One gun per port; the crews work it from the gallery behind (the INSIDE).')),
    'turret': dict(
        name='Sear turret', rules='data.js turret: 2 shots, 8 damage, range 5 (k battery); FAC_WTRAIT las',
        lore='Lore 2.11: the Sear turret. Battle look: las (a beam).',
        design=('A low faceted forged dome on a flush riveted ring (S8\'s low round turrets, never a battleship\'s box turret on a '
                'tall barbette): a twelve-sided drum with a banded, riveted skirt stepping in to a faceted crown and a hatch, one '
                'short heavy focusing emitter out of a block mantlet (a jacket with cooling rings, a lens collar, an ember lens deep '
                'in the bore), and a radiator bustle with ember fins behind: a las weapon sheds its heat like the ship\'s spires.')),
    'flak': dict(
        name='Spark flak', rules='data.js flak: 3 shots, 3 damage, range 2, point defence (vs squadrons x3)',
        lore='Lore 2.11: Spark flak. Battle look: flak (a spread of airbursts).',
        design=('A squat forged drum turret, two short barrels in slotted cooling sleeves ending in squared muzzle brakes, an '
                'ammunition drum on each cheek (the spark shells), elevating high (to 60) for craft. Twin: two barrels.')),
    'autocannon': dict(
        name='Sear repeater', rules='data.js autocannon: 3 shots, 5 damage, range 4 (k battery); FAC_WTRAIT las: +4 aim',
        lore='Lore 2.5: unaugmented crews work their guns by hand; the frigate is built round its bow gun. Battle look: battery.',
        design=('A compact forged casemate at the spearhead\'s root, fixed forward (arc F): a riveted footing, an armoured '
                'housing with cheek plates and a sloped glacis, a round port collar with a ball mantlet, a rotary cluster of '
                'three barrels round a spindle (a heat jacket over the roots, clamp bands, a muzzle ring), dark bores with an '
                'ember lens. All three barrels fire each volley (issue 1156, the Warden).')),
}


def _barrel(p, tag, x0, L, cal, E, seg=14, jacket=0.5, fins=None, lens=True, brake=False):
    """one Sunward barrel along +X from x0 under the elevation frame E: a thick heat jacket with cooling fins (rings at the hull's
    plate pitch), a slimmer tube with bands, a flared focusing muzzle (or a squared brake), a dark bore with an ember glow deep in
    it (the sear rounds leave the bore hot). Returns the muzzle point in the part frame."""
    xj = x0 + L * jacket
    p.add('%sjacket' % tag, 'body', 'siron2', moved(revolve([(x0, cal * 1.55), (xj, cal * 1.55), (xj + cal * 0.5, cal * 1.05), (xj + cal * 0.5, 0.001)],
                                                             seg, cap0=True, phase=math.pi / seg), E))
    nf = fins if fins is not None else 3
    for i in range(nf):
        x = x0 + cal * 0.6 + (xj - x0 - cal * 1.2) * (i + 0.5) / nf
        p.add('%sfin%d' % (tag, i), 'body', 'sworn', moved(ring_band(x, cal * 1.55, cal * 0.6, cal * 0.22, seg), E))
    xe = x0 + L
    p.add('%sbarrel' % tag, 'body', 'siron', moved(revolve([(xj, cal * 1.0), (xe - cal * 1.2, cal * 0.92)], seg, phase=math.pi / seg), E))
    for i, f in enumerate((0.25, 0.6)):
        x = xj + (xe - cal * 1.2 - xj) * f
        p.add('%sbband%d' % (tag, i), 'body', 'sworn', moved(ring_band(x, cal * 0.95, cal * 0.4, cal * 0.18, seg), E))
    if brake:
        p.add('%smuzzle' % tag, 'body', 'siron2', moved(block(xe - cal * 1.4, xe, cal * 1.12, cal * 1.05, cal * 0.3), E))
        for s in (1, -1):
            p.add('%sslot%d' % (tag, s > 0), 'body', 'dark', moved(block(xe - cal * 1.1, xe - cal * 0.4, cal * 0.1, cal * 0.7, 0, yo=s * cal * 1.1), E))
    else:
        p.add('%smuzzle' % tag, 'body', 'sworn', moved(revolve([(xe - cal * 1.2, cal * 0.92), (xe - cal * 0.9, cal * 1.35), (xe, cal * 1.45),
                                                                (xe, cal * 0.62), (xe - cal * 2.0, cal * 0.62)], seg, phase=math.pi / seg), E))
    p.add('%sbore' % tag, 'body', 'dark', moved(revolve([(xe - cal * 2.0, 0.001), (xe - cal * 2.0, cal * 0.63)], seg), E))
    if lens:
        p.add('%slens' % tag, 'body', 'embar', moved(revolve([(xe - cal * 1.9, cal * 0.5), (xe - cal * 1.85, 0.001)], seg, cap0=True), E))
    return Vector((xe, 0, 0))


def _broadside(p, barrels, cal, blen, s, pitch, variant):
    """the heavy sear broadside (data.js hbattery): a casemate. Local +Z out of the flank, +X toward the bow; pitch is the
    train out from the hull axis (90 = straight out), so the barrel elevates about the ball's centre."""
    R = 0.4 * s
    # the square forged surround on the flank, chamfered, with rivets round it
    sq = 1.22 * R; ch = 0.3 * R
    pts = [(sq, sq - ch), (sq - ch, sq), (-sq + ch, sq), (-sq, sq - ch), (-sq, -sq + ch), (-sq + ch, -sq), (sq - ch, -sq), (sq, -sq + ch)]
    sur = prism([(-0.12 * s, [(y, x) for (x, y) in pts]), (0.07 * s, [(y * 0.94, x * 0.94) for (x, y) in pts])])
    sur = ([(v[1], v[2], v[0]) for v in sur[0]], sur[1])   # the prism runs along X: turn it to stand on the flank (+Z out)
    p.add('surround', 'mount', 'siron2', sur)
    st = []
    for i in range(12):
        a = 2 * math.pi * (i + 0.5) / 12
        st.append(_stud((sq * 0.82 * math.cos(a) * 1.12, sq * 0.82 * math.sin(a) * 1.12, 0.07 * s), (0, 0, 1), 0.028 * s))
    p.add('surroundstud', 'mount', 'sworn', _join(st))
    # the port: a deep round collar standing out of the flank with a rolled lip, its dark throat behind the ball
    zt = 0.42 * s
    p.add('port', 'mount', 'siron', _zrev([(-0.1 * s, R), (zt - 0.06 * s, R), (zt, R * 1.08), (zt + 0.04 * s, R * 1.08), (zt + 0.04 * s, R * 0.8),
                                          (0.04 * s, R * 0.8)], 20, closed=True, phase=math.pi / 20))
    p.add('portband', 'mount', 'sworn', _zrev([(zt * 0.45, R * 0.99), (zt * 0.45, R * 1.05), (zt * 0.6, R * 1.05), (zt * 0.6, R * 0.99)], 20, closed=True))
    p.add('portstud', 'mount', 'sworn', _ring_studs(zt * 0.25, R * 1.0, 10, 0.026 * s))
    p.add('throat', 'mount', 'dark', _zrev([(0.05 * s, R * 0.8), (0.05 * s, 0.001)], 20))
    mr = 0.27 * s
    trunnion = Vector((0, 0, 0.05 * s + mr + 0.04 * s))
    E = Matrix.Translation(trunnion) @ Matrix.Rotation(-math.radians(pitch), 4, 'Y')
    ball = []
    k = 10
    for i in range(k + 1):
        a = -math.pi / 2 + math.pi * i / k
        ball.append((mr * math.sin(a), max(0.001, mr * math.cos(a))))
    p.add('mantlet', 'body', 'siron2', moved(revolve(ball, 18), E))
    p.add('mantletcollar', 'body', 'sworn', moved(ring_band(mr * 0.55, mr * 0.84, mr * 0.3, mr * 0.12, 18), E))
    muzzles = []
    for i in range(barrels):
        off = (i - (barrels - 1) / 2) * cal * 3.4
        T = E @ Matrix.Translation((0, off, 0))
        mz = _barrel(p, 'b%d_' % i, mr * 0.6, blen, cal, T, jacket=0.48)
        muzzles.append(P(T @ mz))
    reach = mr * 0.6 + blen
    return trunnion, muzzles, reach, R * 1.1, E


def _sear_turret(p, barrels, cal, blen, s, pitch, variant):
    """the sear turret (data.js turret): a low faceted forged dome on a flush riveted ring (S8's low round turrets, never a
    battleship's box turret on a tall barbette, R185 (5)), one short heavy focusing emitter out of a block mantlet, ember-slatted
    radiator fins on its bustle"""
    rr = 0.5 * s
    p.add('ring', 'mount', 'siron2', _zrev([(-0.3 * s, rr * 1.06), (0.08 * s, rr * 1.06), (0.08 * s, rr * 0.95), (0.11 * s, rr * 0.92),
                                           (0.11 * s, 0.001)], 16, cap0=True, phase=math.pi / 16))
    p.add('ringband', 'mount', 'sworn', _zrev([(-0.04 * s, rr * 1.05), (-0.04 * s, rr * 1.11), (0.05 * s, rr * 1.11), (0.05 * s, rr * 1.05)], 16, closed=True,
                                             phase=math.pi / 16))
    p.add('ringstud', 'mount', 'sworn', _ring_studs(0.08 * s, rr * 1.0, 16, 0.026 * s, out=False))
    z0 = 0.11 * s
    R = 0.46 * s
    # the dome: a twelve-sided forged drum stepping in to a faceted crown (two plate courses), a flat hatch on top
    p.add('housing', 'body', 'siron', _zrev([(z0, R), (z0 + 0.13 * s, R), (z0 + 0.15 * s, R * 0.96), (z0 + 0.27 * s, R * 0.8), (z0 + 0.36 * s, R * 0.5),
                                            (z0 + 0.38 * s, 0.001)], 12, phase=math.pi / 12))
    p.add('housingband', 'body', 'siron2', _zrev([(z0 + 0.04 * s, R * 0.995), (z0 + 0.04 * s, R * 1.035), (z0 + 0.1 * s, R * 1.035), (z0 + 0.1 * s, R * 0.995)],
                                                12, closed=True, phase=math.pi / 12))
    p.add('housingstud', 'body', 'sworn', _ring_studs(z0 + 0.07 * s, R * 1.035, 12, 0.022 * s, phase=math.pi / 12))
    p.add('roof', 'body', 'siron2', _zrev([(z0 + 0.36 * s, R * 0.36), (z0 + 0.42 * s, R * 0.34), (z0 + 0.42 * s, 0.001)], 8, phase=math.pi / 8))
    p.add('sight', 'body', 'dark', block(R * 0.05, R * 0.28, R * 0.18, 0.018 * s, 0, zo=z0 + 0.33 * s))
    # the bustle: a radiator block behind the dome, vertical fins with ember slats between (a las weapon sheds its heat)
    p.add('bustle', 'body', 'siron2', block(-R * 1.35, -R * 0.7, R * 0.42, 0.11 * s, 0.03 * s, zo=z0 + 0.12 * s))
    for j in range(5):
        x = -R * 1.3 + j * R * 0.13
        p.add('fin%d' % j, 'body', 'sworn', block(x - 0.012 * s, x + 0.012 * s, R * 0.42, 0.09 * s, 0, zo=z0 + 0.3 * s))
        if j < 4:
            p.add('finglow%d' % j, 'body', 'embar', block(x + 0.016 * s, x + R * 0.13 - 0.016 * s, R * 0.36, 0.07 * s, 0, zo=z0 + 0.3 * s))
    trunnion = Vector((R * 0.78, 0, z0 + 0.17 * s))
    E = Matrix.Translation(trunnion) @ Matrix.Rotation(-math.radians(pitch), 4, 'Y')
    mw = R * 0.9 + 0.1 * s * (barrels - 1)
    p.add('mantlet', 'body', 'siron2', moved(block(-0.12 * s, 0.13 * s, mw / 2, 0.12 * s, 0.04 * s), E))
    for sgn in (1, -1):
        p.add('trunnion%d' % (sgn > 0), 'body', 'sworn', moved(rod((0, sgn * mw / 2, 0), (0, sgn * (mw / 2 + 0.04 * s), 0), 0.07 * s, 10), E))
    muzzles = []
    for i in range(barrels):
        off = (i - (barrels - 1) / 2) * cal * 3.6
        T = E @ Matrix.Translation((0, off, 0))
        mz = _barrel(p, 'b%d_' % i, 0.12 * s, blen, cal, T, jacket=0.42)
        p.add('b%d_collar' % i, 'body', 'siron2', moved(ring_band(0.12 * s + blen * 0.8, cal * 0.95, cal * 0.6, cal * 0.38, 14), T))
        muzzles.append(P(T @ mz))
    return trunnion, muzzles, 0.12 * s + blen + trunnion.x, max(rr * 1.11, R * 1.35), E


def _spark_flak(p, barrels, cal, blen, s, pitch, variant):
    """the spark flak (data.js flak): a squat forged drum turret, short twin barrels in slotted sleeves, drums on the cheeks"""
    rr = 0.4 * s
    p.add('ring', 'mount', 'siron2', _zrev([(-0.25 * s, rr * 1.08), (0.1 * s, rr * 1.08), (0.1 * s, rr * 0.95), (0.14 * s, rr * 0.9),
                                           (0.14 * s, 0.001)], 16, cap0=True, phase=math.pi / 16))
    p.add('ringstud', 'mount', 'sworn', _ring_studs(0.1 * s, rr * 1.0, 12, 0.026 * s, out=False))
    z0 = 0.14 * s
    p.add('housing', 'body', 'siron', _zrev([(z0, rr * 0.92), (z0 + 0.22 * s, rr * 0.92), (z0 + 0.3 * s, rr * 0.74), (z0 + 0.3 * s, 0.001)], 8, phase=math.pi / 8))
    p.add('housingband', 'body', 'sworn', _zrev([(z0 + 0.08 * s, rr * 0.91), (z0 + 0.08 * s, rr * 0.97), (z0 + 0.13 * s, rr * 0.97), (z0 + 0.13 * s, rr * 0.91)],
                                               8, closed=True, phase=math.pi / 8))
    zc = z0 + 0.2 * s
    trunnion = Vector((0.06 * s, 0, zc))
    E = Matrix.Translation(trunnion) @ Matrix.Rotation(-math.radians(pitch), 4, 'Y')
    # the cradle (mantlet) and the ammunition drums on both cheeks
    gap = cal * 3.2 * max(1, barrels - 1)
    p.add('mantlet', 'body', 'siron2', moved(block(-0.16 * s, 0.1 * s, gap / 2 + cal * 1.2, 0.09 * s, 0.03 * s), E))
    for sgn in (1, -1):
        y = sgn * (gap / 2 + cal * 1.2 + 0.07 * s)
        p.add('drum%d' % (sgn > 0), 'body', 'siron', moved(rod((-0.1 * s, y, 0), (-0.1 * s, y + sgn * 0.11 * s, 0), 0.13 * s, 12), E))
        p.add('drumband%d' % (sgn > 0), 'body', 'sworn', moved(rod((-0.1 * s, y + sgn * 0.045 * s, 0), (-0.1 * s, y + sgn * 0.065 * s, 0), 0.138 * s, 12), E))
    muzzles = []
    for i in range(barrels):
        off = (i - (barrels - 1) / 2) * cal * 3.2
        T = E @ Matrix.Translation((0, off, 0))
        mz = _barrel(p, 'b%d_' % i, 0.08 * s, blen, cal, T, jacket=0.55, fins=2, lens=False, brake=True)
        muzzles.append(P(T @ mz))
    return trunnion, muzzles, 0.08 * s + blen + trunnion.x, rr * 1.08, E


def _sear_repeater(p, barrels, cal, blen, s, pitch, variant):
    """the Sear repeater (data.js autocannon, issue 1156, the Warden frigate's bow gun): a compact forged casemate at the
    spearhead's root, fixed forward (arc F: the frigate turns to bring it to bear). Local +X the aim, +Z up, origin on the deck.
    A riveted footing, an armoured housing whose front face slopes back over a round port collar, a ball mantlet in the port,
    a rotary cluster of `barrels` barrels round a spindle (a heat jacket over their roots, clamp bands, a muzzle ring), each
    barrel with a dark bore and an ember lens (las: the sear rounds leave the bore hot). Every barrel fires each volley."""
    # the footing: a low riveted plinth sunk into the deck (the casemate's ground)
    p.add('footing', 'mount', 'siron2', block(-0.72 * s, 0.42 * s, 0.44 * s, 0.07 * s, 0.025 * s, zo=0.0))
    st = []
    for i in range(6):
        x = -0.66 * s + i * 0.2 * s
        for sg in (1, -1):
            st.append(_stud((x, sg * 0.44 * s, 0.035 * s), (0, sg, 0), 0.02 * s))
    p.add('footingstud', 'mount', 'sworn', _join(st))
    # the housing: an armoured block, its front end narrower and lower (the sloped glacis over the port), a stepped roof plate
    p.add('housing', 'mount', 'siron', block(-0.64 * s, 0.32 * s, 0.38 * s, 0.25 * s, 0.09 * s, zo=0.3 * s, taper=0.74, ztaper=0.62))
    p.add('housingband', 'mount', 'sworn', block(-0.4 * s, -0.34 * s, 0.395 * s, 0.24 * s, 0.085 * s, zo=0.3 * s))
    p.add('roof', 'mount', 'siron2', block(-0.52 * s, 0.1 * s, 0.29 * s, 0.035 * s, 0.015 * s, zo=0.56 * s))
    p.add('roofstep', 'mount', 'siron', block(-0.44 * s, -0.06 * s, 0.2 * s, 0.03 * s, 0.01 * s, zo=0.61 * s))
    for sg in (1, -1):
        # the cheek plates: a second forged layer on each flank of the housing, rivets along their top edge
        p.add('cheek%d' % (sg > 0), 'mount', 'siron2', block(-0.58 * s, 0.16 * s, 0.025 * s, 0.17 * s, 0.01 * s, yo=sg * 0.385 * s, zo=0.27 * s))
        rv = [_stud((-0.52 * s + k * 0.13 * s, sg * 0.412 * s, 0.4 * s), (0, sg, 0), 0.018 * s) for k in range(6)]
        p.add('cheekstud%d' % (sg > 0), 'mount', 'sworn', _join(rv))
    # the gunner's sight: a narrow ember slit high in the glacis, under a brow
    p.add('sight', 'mount', 'glow', block(0.205 * s, 0.235 * s, 0.11 * s, 0.018 * s, 0, zo=0.47 * s))
    p.add('sightbrow', 'mount', 'sworn', block(0.17 * s, 0.26 * s, 0.14 * s, 0.012 * s, 0, zo=0.5 * s))
    # the port: a round forged collar standing out of the glacis, a rolled lip, a dark throat round the ball
    zc = 0.27 * s
    C = Matrix.Translation((0, 0, zc))
    R = 0.19 * s
    p.add('port', 'mount', 'siron2', moved(revolve([(0.16 * s, R), (0.36 * s, R), (0.4 * s, R * 1.1), (0.43 * s, R * 1.1), (0.43 * s, R * 0.8),
                                                     (0.2 * s, R * 0.8)], 20, closed=True, phase=math.pi / 20), C))
    p.add('portstud', 'mount', 'sworn', moved(_x_studs(0.3 * s, R, 10, 0.02 * s), C))
    p.add('throat', 'mount', 'dark', moved(revolve([(0.22 * s, R * 0.8), (0.22 * s, 0.001)], 20), C))
    trunnion = Vector((0.33 * s, 0, zc))
    E = Matrix.Translation(trunnion) @ Matrix.Rotation(-math.radians(pitch), 4, 'Y')
    mr = 0.14 * s
    ball = [(mr * math.sin(-math.pi / 2 + math.pi * i / 10), max(0.001, mr * math.cos(-math.pi / 2 + math.pi * i / 10))) for i in range(11)]
    p.add('mantlet', 'body', 'siron2', moved(revolve(ball, 18), E))
    p.add('mantletcollar', 'body', 'sworn', moved(ring_band(mr * 0.6, mr * 0.82, mr * 0.3, mr * 0.12, 18), E))
    # the rotary cluster: a spindle, a heat jacket over the barrel roots, clamp bands, barrels round the spindle, a muzzle ring
    rc = cal * 1.7                      # the barrels' circle round the spindle
    x0 = mr * 0.7; xe = x0 + blen
    p.add('spindle', 'body', 'siron2', moved(revolve([(x0, cal * 0.8), (xe - cal * 0.6, cal * 0.8)], 10, cap1=True), E))
    p.add('jacket', 'body', 'siron', moved(revolve([(x0, rc + cal * 1.35), (x0 + blen * 0.34, rc + cal * 1.35), (x0 + blen * 0.34 + cal, rc + cal * 0.9),
                                                    (x0 + blen * 0.34 + cal, 0.001)], 16, cap0=True, phase=math.pi / 16), E))
    for i, f in enumerate((0.08, 0.2)):
        p.add('jacketfin%d' % i, 'body', 'sworn', moved(ring_band(x0 + blen * f, rc + cal * 1.35, cal * 0.7, cal * 0.25, 16), E))
    for i, f in enumerate((0.58, 0.82)):
        p.add('clamp%d' % i, 'body', 'siron2', moved(ring_band(x0 + blen * f, rc + cal * 0.95, cal * 1.1, cal * 0.3, 16), E))
    p.add('muzzlering', 'body', 'sworn', moved(revolve([(xe - cal * 1.6, rc + cal * 1.15), (xe - cal * 0.3, rc + cal * 1.15), (xe - cal * 0.3, rc + cal * 0.7),
                                                       (xe - cal * 1.6, rc + cal * 0.7)], 16, closed=True), E))
    muzzles = []
    for i in range(barrels):
        a = math.pi / 2 + 2 * math.pi * i / barrels
        T = E @ Matrix.Translation((0, rc * math.cos(a), rc * math.sin(a)))
        p.add('b%d_barrel' % i, 'body', 'siron', moved(revolve([(x0 + blen * 0.3, cal), (xe - cal * 0.8, cal * 0.95)], 10, phase=math.pi / 10), T))
        p.add('b%d_muzzle' % i, 'body', 'sworn', moved(revolve([(xe - cal * 0.8, cal * 0.95), (xe - cal * 0.4, cal * 1.25), (xe, cal * 1.3), (xe, cal * 0.6),
                                                                (xe - cal * 1.6, cal * 0.6)], 10, phase=math.pi / 10), T))
        p.add('b%d_bore' % i, 'body', 'dark', moved(revolve([(xe - cal * 1.6, 0.001), (xe - cal * 1.6, cal * 0.61)], 10), T))
        p.add('b%d_lens' % i, 'body', 'embar', moved(revolve([(xe - cal * 1.5, cal * 0.5), (xe - cal * 1.45, 0.001)], 10, cap0=True), T))
        muzzles.append(P(T @ Vector((xe, 0, 0))))
    return trunnion, muzzles, xe + trunnion.x, 0.44 * s, E


GUN_BUILDERS = {'hbattery': _broadside, 'turret': _sear_turret, 'flak': _spark_flak, 'autocannon': _sear_repeater}


def gun(barrels=1, cal=0.12, blen=1.6, size=1.0, mount='turret', pitch=0.0, variant=0, seg=14, weapon='turret'):
    """a Sunward weapon mount, built from the weapon it carries (data.js id hbattery, turret or flak; WEAPONS says how each
    works). Origin on the hull surface at the mount centre, local +Z the mount normal, +X the rest aim (a turret) or the bow (a
    casemate, whose pitch is its train out from the hull axis). Fixed pieces are 'mount'; a turret's turning pieces are 'turn'
    (R219); a casemate's ball and barrel stay 'body' (fixed on the ship node)."""
    fn = GUN_BUILDERS[weapon]
    if weapon in ('hbattery', 'autocannon'):
        assert mount == 'casemate', 'the heavy sear broadside and the Sear repeater sit in casemates'
    else:
        assert mount == 'turret', 'the sear turret and the spark flak are turrets'
    p = Part('gun')
    trunnion, muzzles, reach, radius, E = fn(p, barrels, cal, blen, size, pitch, variant)
    if mount == 'turret':
        for c in p.comps:
            if c['role'] == 'body':
                c['role'] = 'turn'
    p.fit = dict(pivot=P((0, 0, trunnion.z)), trunnion=P(trunnion), muzzles=muzzles, reach=reach,
                 aim=D(E.to_3x3() @ Vector((1, 0, 0))), up=D((0, 0, 1)), mount=mount, radius=radius)
    return p


# ---------------------------------------------------------------------------------------------------- the radiator spires
def radiator(h, L, spread=0.36, profile=0, fins=None, pitch=0.17, t=0.2, seed=0, lean=None, bars=None, glow='fins', scale=1.0):
    """a radiator spire, standing on the spine block: origin at the root's foot on the spine top, +X forward, +Z up. It sheds
    the reactor's heat (factions.md: the spires glow because they shed the reactor's heat), so it is all radiator: a tapering
    forged column whose two faces are a glowing heat core (the bar) behind a stack of horizontal iron heat fins standing out
    to each side (a heat sink, never a window or an organ pipe), iron posts fore and aft framing the core, a forged cap, gusset
    braces at the root. Never a steeple, a cross, a statue or a mast. profile 0 blade (the cap swept back), 1 stepped (a
    narrower upper tier on a shoulder), 2 twin (two columns sharing one fin stack), 3 raked (the leading edge raked back).
    h: height over the root foot, L: length along the spine at the root, spread: how far the lowest fins reach out each side.
    glow: 'fins' (the first S8 build: fins packed 0.17 apart, so the glowing stack reads as one whole lit tower) or 'slats'
    (R331, Nov 19 2026: the ember in the fin slats, the one Sunward spire treatment, R333; Ryan, Nov 20 on the Warden: "fix
    ember glow", like the concept: the heat core glows ember the full height of the column and the fins are dark iron ribs
    over it, 0.15 apart and reaching 45 percent as far out, so the glow shows in the slats between the ribs, never on fin
    tips or as a whole lit tower; call it with glow='slats' and no other setting).
    scale (issue 1156, the Warden frigate): build the spire at h / scale and shrink the whole part by scale, so a small hull's
    spire keeps the flagship's proportions of root, fins and cap (their sizes below are flagship world sizes) instead of a tall
    root under a few fins; h, L and spread stay world sizes."""
    assert glow in ('fins', 'slats')
    if scale != 1.0:
        part = radiator(h / scale, L / scale, spread / scale, profile, fins, pitch, t, seed, lean, bars, glow=glow)
        return part.transform(Matrix.Scale(scale, 4))
    if glow == 'slats':
        pitch = 0.15
        spread *= 0.45
    core_mat, fin_mat = ('embar', 'siron2') if glow == 'slats' else ('siron2', 'embar')
    p = Part('radiator')
    p.type = 'radiator'
    zr = 0.26
    p.add('root', 'mount', 'siron2', block(-L / 2 - 0.04, L / 2 + 0.04, t * 1.9, 0.16, 0.06, zo=0.1))
    p.add('rootstep', 'mount', 'siron', block(-L / 2 + 0.03, L / 2 - 0.03, t * 1.35, 0.05, 0.02, zo=0.29))
    st = []
    for x in (-L / 2 + 0.03, L / 2 - 0.03):
        for sg in (1, -1):
            st.append(_stud((x, sg * t * 1.9, 0.15), (0, sg, 0), 0.025))
    p.add('rootstud', 'mount', 'sworn', _join(st))
    shoulder = 0.62

    def span(z):
        """the column's fore and aft edges and its half-thickness at height z"""
        f = (z - zr) / max(0.01, h - zr)
        top = 0.72 if profile != 1 else (0.88 if f < shoulder else 0.6)
        k = 1 - (1 - top) * (f if profile != 1 else (f / shoulder * 0.25 if f < shoulder else 1.0))
        xa, xb = -L / 2 * k, L / 2 * k
        if profile == 3:
            xb -= L * 0.35 * f          # the raked leading edge
        return xa, xb, t / 2 * (1 - 0.2 * f)

    def cap_z(x, xa, xb):
        if profile == 0:
            return h - 0.28 * (x - xa) / max(0.01, xb - xa)      # swept back: highest aft
        if profile == 3:
            return h - 0.12 * (x - xa) / max(0.01, xb - xa)
        return h
    cols = [(0, 1)] if profile != 2 else [(-1, 0), (1, 0)]
    nz = 8
    zs = [zr + (h - zr) * i / nz for i in range(nz + 1)]
    for ci, (cx, _) in enumerate(cols):
        def edge(z, i, _cx=cx):
            xa, xb, th = span(z)
            if profile == 2:
                w = (xb - xa) * 0.4; c = (xa + xb) / 2 + _cx * (xb - xa) * 0.3
                xa, xb = c - w / 2, c + w / 2
                th *= 0.85
            return xa, xb, th
        # the heat core: a glowing slab through the column (the bars), then the iron posts fore and aft and the fin stack over it
        secs_core, post_a, post_b = [], [], []
        for z in zs:
            xa, xb, th = edge(z, 0)
            secs_core.append([(xa + 0.06, -th, z), (xb - 0.06, -th, z), (xb - 0.06, th, z), (xa + 0.06, th, z)])
            post_a.append([(xa, -th - 0.02, z), (xa + 0.1, -th - 0.02, z), (xa + 0.1, th + 0.02, z), (xa, th + 0.02, z)])
            post_b.append([(xb - 0.1, -th - 0.02, z), (xb, -th - 0.02, z), (xb, th + 0.02, z), (xb - 0.1, th + 0.02, z)])

        def stack(rs):
            V, F = [], []
            for r in rs:
                V.extend(r)
            for i in range(len(rs) - 1):
                for j in range(4):
                    a, b = i * 4 + j, i * 4 + (j + 1) % 4
                    F.append((a, b, b + 4, a + 4))
            F.append((3, 2, 1, 0)); o = (len(rs) - 1) * 4; F.append((o, o + 1, o + 2, o + 3))
            return V, F
        p.add('bar%d' % ci, 'body', core_mat, stack(secs_core))
        p.add('column%d' % ci, 'body', 'siron', _join([stack(post_a), stack(post_b)]))
        xa, xb, th = edge(h, 0)
        zc = [cap_z(x, xa, xb) for x in (xa, xb)]
        capv = [(xa - 0.04, -th - 0.06, zc[0] - 0.14), (xb + 0.04, -th - 0.06, zc[1] - 0.14), (xb + 0.04, th + 0.06, zc[1] - 0.14), (xa - 0.04, th + 0.06, zc[0] - 0.14),
                (xa - 0.01, -th * 0.5, zc[0] + 0.04), (xb + 0.01, -th * 0.5, zc[1] + 0.04), (xb + 0.01, th * 0.5, zc[1] + 0.04), (xa - 0.01, th * 0.5, zc[0] + 0.04)]
        p.add('cap%d' % ci, 'body', 'sworn', (capv, [(3, 2, 1, 0), (4, 5, 6, 7), (0, 1, 5, 4), (1, 2, 6, 5), (2, 3, 7, 6), (3, 0, 4, 7)]))
        # rivet lines down both posts on both faces, at the hull's rivet pitch (R224: the spire carries the hull's detail)
        rv = []
        for z in [zr + 0.12 + k * 0.13 for k in range(int((h - zr - 0.3) / 0.13))]:
            xa_, xb_, th_ = edge(z, 0)
            for xx in (xa_ + 0.05, xb_ - 0.05):
                for sg in (1, -1):
                    rv.append(_stud((xx, sg * (th_ + 0.02), z + 0.06), (0, sg, 0), 0.02))
        p.add('rivet%d' % ci, 'body', 'sworn', _join(rv))
        if profile == 1:
            zsh = zr + (h - zr) * shoulder
            xa2, xb2, th2 = span(zsh - 0.01)
            p.add('shoulder%d' % ci, 'body', 'siron2', block(xa2 - 0.03, xb2 + 0.03, th2 + 0.08, 0.05, 0.02, zo=zsh - 0.02))
    # the fin stack: horizontal iron fins across the column, reaching out each side, shorter toward the top
    n = fins or (max(3, int((h - zr - 0.3) / pitch) + 1) if glow == 'slats' else max(5, int((h - zr - 0.3) / pitch)))
    fv = []
    for i in range(n):
        z = zr + 0.2 + i * (h - zr - 0.42) / max(1, n - 1)
        if profile == 1 and abs((z - zr) / (h - zr) - shoulder) < 0.04:
            continue
        xa, xb, th = span(z)
        f = (z - zr) / (h - zr)
        reach = th + 0.04 + spread * (1 - 0.25 * f)
        e = 0.05
        for sg in (1, -1):
            # one fin each side of the core, chamfered on its top edge (they run out from the core face)
            y0, y1 = sg * (th - 0.01), sg * reach
            V = [(xa + e, y0, z - 0.018), (xb - e, y0, z - 0.018), (xb - e, y1, z - 0.018), (xa + e, y1, z - 0.018),
                 (xa + e + 0.025, y0, z + 0.018), (xb - e - 0.025, y0, z + 0.018), (xb - e - 0.025, y1 - sg * 0.025, z + 0.018), (xa + e + 0.025, y1 - sg * 0.025, z + 0.018)]
            fv.append((V, [(3, 2, 1, 0), (4, 5, 6, 7), (0, 1, 5, 4), (1, 2, 6, 5), (2, 3, 7, 6), (3, 0, 4, 7)]))
    p.add('fin', 'body', fin_mat, _join(fv))
    # gusset braces at the root, fore and aft on both faces (they carry the column's weight into the root socket)
    gz = []
    for sg in (1, -1):
        for x in (-L / 2 + 0.12, L / 2 - 0.12 - (L * 0.1 if profile == 3 else 0.0)):
            gz.append(([(x - 0.025, sg * t * 0.5, zr), (x + 0.025, sg * t * 0.5, zr), (x + 0.025, sg * (t * 1.75), zr), (x - 0.025, sg * (t * 1.75), zr),
                        (x - 0.025, sg * t * 0.5, zr + 0.42), (x + 0.025, sg * t * 0.5, zr + 0.42)],
                       [(0, 1, 2, 3), (0, 4, 5, 1), (1, 5, 2), (3, 2, 5, 4), (0, 3, 4)]))
    p.add('brace', 'body', 'siron2', _join(gz))
    return p


# ---------------------------------------------------------------------------------------------------- small parts
def hatch(w, h, round_=True, wheel=False):
    """a forged round hatch (local +Z out): a raised rim with studs, a door set proud with a seam, a hinge pair"""
    p = Part('hatch')
    r = w / 2
    p.add('rim', 'mount', 'siron2', _zrev([(-0.03, r * 1.22), (0.06, r * 1.22), (0.06, r * 1.02), (-0.03, r * 1.02)], 16, closed=True))
    p.add('rimstud', 'mount', 'sworn', _ring_studs(0.06, r * 1.12, 8, 0.022, out=False))
    p.add('seam', 'body', 'dark', _zrev([(0.0, r * 1.02), (0.0, r * 0.97)], 16))
    p.add('door', 'body', 'siron', _zrev([(0.01, r * 0.96), (0.05, r * 0.96), (0.075, r * 0.78), (0.075, 0.001)], 16))
    p.add('doorbar', 'body', 'sworn', block(-r * 0.7, r * 0.7, r * 0.1, 0.012, 0.0, zo=0.088))
    for s in (1, -1):
        p.add('hinge%d' % (s > 0), 'body', 'sworn', rod((-r * 0.95, s * r * 0.45, 0.06), (-r * 0.95, s * r * 0.15, 0.06), 0.04, 6))
    return p


def hatchbox(w, l, h, fins=0):
    """an armoured deck housing (a lift head or a heat exchanger cover): a chamfered frame block, an inset lid with a stacked
    plate, side ribs; origin on the deck, +X forward"""
    p = Part('hatchbox')
    p.add('frame', 'mount', 'siron2', block(-l / 2, l / 2, w / 2, h / 2, h * 0.3, zo=h / 2 - 0.05, taper=0.9, ztaper=0.9))
    p.add('lid', 'body', 'siron', block(-l * 0.38, l * 0.32, w * 0.36, 0.035, 0.03, zo=h * 0.93))
    p.add('lid2', 'body', 'siron2', block(-l * 0.26, l * 0.18, w * 0.24, 0.03, 0.02, zo=h * 0.99))
    p.add('lidseam', 'body', 'dark', block(-l * 0.4, l * 0.34, w * 0.38, 0.015, 0.02, zo=h * 0.9))
    for i in range(3):
        x = -l * 0.32 + l * 0.32 * i
        for s in (1, -1):
            p.add('rib%d%d' % (i, s > 0), 'body', 'sworn', block(x - 0.035, x + 0.035, 0.03, h * 0.32, 0.0, yo=s * (w / 2 + 0.0), zo=h * 0.48))
    return p


def vent(w, h, slats=5, depth=0.1, fr=0.05):
    """a heat louvre (local +Z out): a forged frame and slanted slats over a recess lit dull ember from inside"""
    p = Part('vent')
    p.add('back', 'mount', 'ember', block(-0.03, min(0.01, depth * 0.1), w / 2, h / 2, 0))   # behind the slats on a small louvre too (issue 769)
    for (yo, zo, hw, hh) in ((0, h / 2 - fr / 2, w / 2, fr / 2), (0, -h / 2 + fr / 2, w / 2, fr / 2), (w / 2 - fr / 2, 0, fr / 2, h / 2), (-w / 2 + fr / 2, 0, fr / 2, h / 2)):
        p.add('frame', 'mount', 'siron2', block(-0.02, depth, hw, hh, 0, yo=yo, zo=zo))
    for i in range(slats):
        z = -h / 2 + fr + (h - 2 * fr) * (i + 0.5) / slats
        dz = (h - 2 * fr) / slats * 0.3
        st_ = min(0.016, fr * 0.32)   # the slat's half thickness (fr: the frame width; 0.016 on the capital ships)
        p.add('slat%d' % i, 'body', 'siron', prism([(depth * 0.2, [(w / 2 - fr, z - st_), (-w / 2 + fr, z - st_), (-w / 2 + fr, z + st_), (w / 2 - fr, z + st_)]),
                                                    (depth * 0.8, [(w / 2 - fr, z + dz - st_), (-w / 2 + fr, z + dz - st_), (-w / 2 + fr, z + dz + st_),
                                                                   (w / 2 - fr, z + dz + st_)])]))
    for c in p.comps:
        c['verts'] = [Vector((-v.z, v.y, v.x)) for v in c['verts']]
    return p


def lamp(r=0.08, hood=True):
    """a frost-white running point (local +Z out; paint direction sunward.md 5: small frost points on the blade's edge): a
    low forged housing with a hood and a small round lens"""
    p = Part('lamp')
    p.add('housing', 'mount', 'siron2', block(-r * 1.6, r * 1.6, r * 1.2, r * 0.35, r * 0.15, zo=r * 0.2))
    p.add('lens', 'body', 'frost', _zrev([(r * 0.5, r * 0.55), (r * 0.75, r * 0.45), (r * 0.82, 0.001)], 10))
    if hood:
        p.add('hood', 'body', 'sworn', block(r * 0.4, r * 1.0, r * 1.0, r * 0.05, 0, zo=r * 0.95))
    return p


def slit(w, h, depth=0.08, fr=0.045):
    """an armoured ember window slit (local +Z out; factions.md: ember windows): a forged frame round a recessed glowing pane,
    never a round porthole"""
    p = Part('slit')
    for (yo, zo, hw, hh) in ((0, h / 2 + fr / 2, w / 2 + fr, fr / 2), (0, -h / 2 - fr / 2, w / 2 + fr, fr / 2), (w / 2 + fr / 2, 0, fr / 2, h / 2), (-w / 2 - fr / 2, 0, fr / 2, h / 2)):
        p.add('frame', 'mount', 'siron2', block(-0.02, depth, hw, hh, 0, yo=yo, zo=zo))
    p.add('glass', 'body', 'glow', block(min(0.006, depth * 0.075), depth * 0.3, w / 2, h / 2, 0))   # recessed on a small slit too (issue 769)
    p.add('brow', 'body', 'sworn', block(depth * 0.6, depth * 1.2, w / 2 + fr, min(0.012, fr * 0.27), 0, zo=h / 2 + fr))
    for c in p.comps:
        c['verts'] = [Vector((-v.z, v.y, v.x)) for v in c['verts']]
    return p


def thruster(r=0.3, nozzles=2):
    """an attitude thruster (local +Z out): a forged block with round nozzle throats that have depth (R244: a round opening is
    never a flat disc): a rolled lip, a dark bore"""
    p = Part('thruster')
    p.add('block', 'mount', 'siron2', block(-r, r, r * 0.7, r * 0.36, r * 0.14, zo=r * 0.2))
    for i in range(nozzles):
        y = (i - (nozzles - 1) / 2) * r * 0.75
        p.add('nozzle%d' % i, 'body', 'sworn', moved(_zrev([(0.0, r * 0.3), (r * 0.42, r * 0.3), (r * 0.5, r * 0.34), (r * 0.5, r * 0.22), (r * 0.12, r * 0.2)],
                                                          12, closed=True), Matrix.Translation((0, y, r * 0.5))))
        p.add('nozzlebore%d' % i, 'body', 'dark', moved(_zrev([(r * 0.14, r * 0.21), (r * 0.14, 0.001)], 12), Matrix.Translation((0, y, r * 0.5))))
    for c in p.comps:
        c['verts'] = [Vector((v.y, v.x, v.z)) for v in c['verts']]
    p.fit = dict(out=D((0, 0, 1)))
    return p


# ---------------------------------------------------------------------------------------------------- squadron craft (issue 769)
# The Sunward fighter (SF3, data.js fighter: guns T) and bomber (SB4, data.js bomber: bombs T), R253 and R255. A craft is about
# a twelfth of the flagship's length on the board, so these parts take every size from their own arguments (no fixed world
# sizes, which suit a 27 unit hull and would swamp a 1.6 unit craft), and they stay bold and simple: fine greeble at this size
# reads as a shrunken capital ship (design_notes_757.md, production notes). Ryan's words that bind (R254, round 1 craft "look
# like they're aerial fighters, not space fighters"): no canopy, no swept aero wings, no tail fins, no bombs hung under the hull;
# drives are nozzle clusters inside armoured blocks; ordnance is internal.
WEAPONS.update({
    'guns': dict(
        name='Interceptor guns', rules='data.js guns: 3 shots, 4 damage, range 1 (k sq), 82 aim, x2.2 against squadrons, x0.5 against capitals',
        lore='The wing\'s only weapon (lore 2.5: unaugmented crews, no AI: a pilot aims it). Battle look: guns (craft on a strafing run).',
        design=('Three short barrels in one tight emitter cluster on a shallow traverse ring, sunk in an armoured well on the '
                'blade\'s back near the bow: a low faceted housing, a block mantlet, the three muzzles flared with dark bores. It '
                'turns (data.js arc T, the fit check sweeps it all round) and sits low, so nothing on the fighter reads as a turret '
                'on a jet.')),
    'bombs': dict(
        name='Bomb payload', rules='data.js bombs: 2 shots, 9 damage, range 1 (k sq), 78 aim, pierce 0.6, crit 10, x0.2 against squadrons',
        lore='The wing\'s only weapon: the bomber is built round its magazine. Battle look: bombs.',
        design=('Two big tube mouths in a deep armoured cassette that is the bomber\'s bow face: heavy twelve-sided rims with '
                'forged lugs, dark bores with the next bomb\'s nose seated deep inside, the bombardier\'s sight slit between them. '
                'Fixed forward: the bomber turns to bring them to bear. Ordnance is internal, never hung under the hull.')),
})


def _vslab(x0, x1, hy, z0, z1, k_top=1.0, yo=0.0):
    """an upright slab from z0 to z1, x0 to x1 at the foot, its fore and aft edges drawn in toward the middle by k_top at the top"""
    xm = (x0 + x1) / 2; a0, a1 = xm + (x0 - xm) * k_top, xm + (x1 - xm) * k_top
    V = [(x0, yo - hy, z0), (x1, yo - hy, z0), (x1, yo + hy, z0), (x0, yo + hy, z0),
         (a0, yo - hy, z1), (a1, yo - hy, z1), (a1, yo + hy, z1), (a0, yo + hy, z1)]
    return V, [(3, 2, 1, 0), (4, 5, 6, 7), (0, 1, 5, 4), (1, 2, 6, 5), (2, 3, 7, 6), (3, 0, 4, 7)]


def _interceptor(p, barrels, cal, blen, s, pitch, variant):
    """the interceptor guns (data.js guns): s is the traverse ring's radius, cal a barrel's radius, blen the cluster's reach from
    the trunnion. Local +Z out of the deck, +X the rest aim."""
    ph = math.pi / 16
    p.add('ring', 'mount', 'siron2', _zrev([(-0.6 * s, s), (0.1 * s, s), (0.1 * s, s * 0.9), (0.14 * s, s * 0.86), (0.14 * s, 0.001)], 16, cap0=True, phase=ph))
    # the armoured well's rim round the ring (the "armoured recess" of the concept), riveted
    p.add('well', 'mount', 'sworn', _zrev([(-0.05 * s, s * 1.0), (-0.05 * s, s * 1.2), (0.12 * s, s * 1.2), (0.18 * s, s * 1.1), (0.18 * s, s * 1.0)], 16, closed=True, phase=ph))
    p.add('wellstud', 'mount', 'sworn', _ring_studs(0.18 * s, s * 1.1, 10, 0.035 * s, out=False))
    R = 0.8 * s
    p.add('housing', 'body', 'siron', _zrev([(0.14 * s, R), (0.3 * s, R), (0.42 * s, R * 0.74), (0.46 * s, 0.001)], 8, phase=math.pi / 8))
    p.add('housingband', 'body', 'siron2', _zrev([(0.17 * s, R * 0.99), (0.17 * s, R * 1.05), (0.24 * s, R * 1.05), (0.24 * s, R * 0.99)], 8, closed=True, phase=math.pi / 8))
    p.add('sight', 'body', 'dark', block(-R * 0.55, -R * 0.15, R * 0.22, 0.025 * s, 0, zo=0.44 * s))
    trunnion = Vector((0.35 * s, 0, 0.4 * s))
    E = Matrix.Translation(trunnion) @ Matrix.Rotation(-math.radians(pitch), 4, 'Y')
    d = cal * 2.0
    offs = [(0.0, d * 1.0), (-d * 0.87, -d * 0.5), (d * 0.87, -d * 0.5)][:max(1, barrels)]
    cw = d * 0.87 + cal * 1.7
    p.add('mantlet', 'body', 'siron2', moved(block(-0.25 * s, 0.1 * s, cw * 1.1, d * 0.75 + cal * 1.7, cal * 0.8, zo=d * 0.25), E))
    # the emitter cluster: one forged jacket round all three barrels, chamfered, two cooling bands
    xj = blen * 0.55
    p.add('cluster_jacket', 'body', 'siron2', moved(block(0.05 * s, xj, cw, d * 0.75 + cal * 1.6, cal * 1.2, zo=d * 0.25), E))
    for i, f in enumerate((0.35, 0.75)):
        x = 0.05 * s + (xj - 0.05 * s) * f
        p.add('cluster_band%d' % i, 'body', 'sworn', moved(block(x - cal * 0.5, x + cal * 0.5, cw * 1.08, d * 0.75 + cal * 1.75, cal * 1.2, zo=d * 0.25), E))
    muzzles = []
    for i, (oy, oz) in enumerate(offs):
        T = E @ Matrix.Translation((0, oy, oz))
        xe = blen
        p.add('b%d_barrel' % i, 'body', 'siron', moved(revolve([(xj - cal, cal), (xe - cal * 1.1, cal * 0.92)], 12, phase=math.pi / 12), T))
        p.add('b%d_muzzle' % i, 'body', 'sworn', moved(revolve([(xe - cal * 1.1, cal * 0.92), (xe - cal * 0.5, cal * 1.3), (xe, cal * 1.35), (xe, cal * 0.62),
                                                                (xe - cal * 1.6, cal * 0.62)], 12, phase=math.pi / 12), T))
        p.add('b%d_bore' % i, 'body', 'dark', moved(revolve([(xe - cal * 1.6, 0.0001), (xe - cal * 1.6, cal * 0.63)], 12), T))
        muzzles.append(P(T @ Vector((xe, 0, 0))))
    return trunnion, muzzles, trunnion.x + blen, s * 1.2, E


GUN_BUILDERS['guns'] = _interceptor


def rocket_rack(rows, cols, cell, depth, variant=0):
    """the Sunward bomb cassette (data.js bombs). The sheet kit's K.launcher asks every faction kit for rocket_rack(rows, cols,
    cell, depth); the Sunward answer is no rack of rockets but a deep armoured cassette of bomb tubes that forms the bomber's bow
    face. Local +X the firing direction, +Z up, origin at the centre of the cassette's front face; cell is the tube pitch, depth
    how far the bores run back. Every piece is mount: the cassette stands on the hull's bow and the bores run back into it."""
    p = Part('launcher')
    p.type = 'bomb_tube'
    r = cell * 0.3
    hw, hh = cols * cell / 2, rows * cell / 2
    tf = r * 0.25
    ch = cell * 0.12
    n = 16
    ctr = [((i - (cols - 1) / 2) * cell, (j - (rows - 1) / 2) * cell) for j in range(rows) for i in range(cols)]
    # the front plate: each cell a square with a round hole, quads from the hole to the square (front at x 0, back at -tf)
    FV, FF = [], []
    for (cy, cz) in ctr:
        for x, flip in ((0.0, False), (-tf, True)):
            o = len(FV)
            for k in range(n):
                a = 2 * math.pi * k / n
                c, s_ = math.cos(a), math.sin(a)
                m = max(abs(c), abs(s_))
                FV.append((x, cy + r * 1.02 * c, cz + r * 1.02 * s_))
                oy, oz = cy + cell / 2 * c / m, cz + cell / 2 * s_ / m
                ex = abs(oy) + abs(oz) - (hw + hh - ch)   # past the housing's chamfered corner: pulled in along the ray
                if ex > 0:
                    k_ = ex / max(1e-9, abs(oy - cy) * (1 if oy * (oy - cy) > 0 else -1) + abs(oz - cz) * (1 if oz * (oz - cz) > 0 else -1))
                    oy, oz = oy - (oy - cy) * min(1.0, k_), oz - (oz - cz) * min(1.0, k_)
                FV.append((x, oy, oz))
            for k in range(n):
                a, b = o + 2 * k, o + 2 * ((k + 1) % n)
                q = (a, b, b + 1, a + 1)
                FF.append(q[::-1] if flip else q)
    p.add('face', 'mount', 'siron2', (FV, FF))
    # the housing round the bores: the cassette's top, bottom and side walls, chamfered, and its back block in the hull
    w = cell * 0.12
    p.add('housing', 'mount', 'siron', block(-depth * 1.15, -tf * 0.3, hw, hh, ch))
    for k_, (cy, cz) in enumerate(ctr):
        p.add('bore%d' % k_, 'mount', 'siron2', moved(revolve([(0.0, r * 1.02), (-depth, r * 1.02)], n), Matrix.Translation((0, cy, cz))))
        p.add('back%d' % k_, 'mount', 'dark', moved(revolve([(-depth * 0.99, r * 1.03), (-depth * 0.99, 0.0001)], n), Matrix.Translation((0, cy, cz))))
        # the next bomb seated deep in the bore: a dark iron nose with a worked band (ordnance internal, never underslung)
        p.add('warhead%d' % k_, 'mount', 'siron', moved(revolve([(-depth * 0.97, r * 0.82), (-depth * 0.72, r * 0.8), (-depth * 0.55, r * 0.45), (-depth * 0.5, 0.0001)], n),
                                                        Matrix.Translation((0, cy, cz))))
        p.add('warheadband%d' % k_, 'mount', 'sworn', moved(ring_band(-depth * 0.78, r * 0.8, r * 0.1, r * 0.05, n), Matrix.Translation((0, cy, cz))))
        # the heavy shaped rim: a twelve-sided collar of worked iron standing proud of the face, stepped, with forged lugs round it
        # (worked iron, as the concept's worn grey rims: a light ring round a dark mouth is what reads at the battle camera)
        p.add('rim%d' % k_, 'mount', 'sworn', moved(revolve([(-tf * 0.5, r * 1.02), (-tf * 0.5, r * 1.4), (r * 0.3, r * 1.4), (r * 0.42, r * 1.27), (r * 0.42, r * 1.02)],
                                                            12, closed=True, phase=math.pi / 12), Matrix.Translation((0, cy, cz))))
        lugs = []
        for a in (60, 120, 240, 300):
            ar = math.radians(a)
            u = Vector((0, math.cos(ar), math.sin(ar))); v = Vector((0, -math.sin(ar), math.cos(ar)))
            c0 = Vector((0, cy, cz)) + u * r * 1.47
            V_ = []
            for x in (-tf * 0.5, r * 0.34):
                for du, dv in ((-1, -1), (1, -1), (1, 1), (-1, 1)):
                    V_.append(tuple(c0 + Vector((x, 0, 0)) + u * du * r * 0.13 + v * dv * r * 0.18))
            lugs.append((V_, [(3, 2, 1, 0), (4, 5, 6, 7), (0, 1, 5, 4), (1, 2, 6, 5), (2, 3, 7, 6), (3, 0, 4, 7)]))
        p.add('lug%d' % k_, 'mount', 'siron2', _join(lugs))
        st = []
        for i in range(12):
            a = 2 * math.pi * (i + 0.5) / 12
            st.append(_stud((r * 0.42, cy + r * 1.15 * math.cos(a), cz + r * 1.15 * math.sin(a)), (1, 0, 0), r * 0.045))
        p.add('studs%d' % k_, 'mount', 'sworn', _join(st))
    if cols == 2 and rows == 1:
        # the bombardier's sight slit between the two mouths (the concept's recessed sensor slit at the centre): a forged frame
        # round a recessed ember pane; it aims the tubes, so it belongs to the cassette
        sw, sh = cell * 0.05, cell * 0.17
        p.add('sightframe', 'mount', 'siron2', block(-tf * 0.5, r * 0.12, sw + r * 0.06, sh + r * 0.06, r * 0.03))
        p.add('sight', 'mount', 'glow', block(r * 0.06, r * 0.125, sw, sh, 0))
    p.fit = dict(exits=[dict(pos=P((r * 0.42, cy, cz)), axis=D((1, 0, 0)), radius=r) for (cy, cz) in ctr])
    return p


def craft_drive(r_exit, body_len, bell_len=None, cowl_r=None, throat=0.55, recess=0.35):
    """a craft's drive (the owner's rule for craft: thrusters are nozzle clusters inside armoured blocks): a deep bell sunk in an
    eight-sided armoured cowl, the cowl's aft face standing proud of the bell's lip by recess (a share of r_exit), so the bell
    sits in a recess; ember lining, a hot throat and a glowing plug cone deep inside (dim, banked coals, R55). Origin at the
    centre of the bell's exit plane, exhaust along -X; the cowl runs forward body_len into the stern armour."""
    p = Part('engine')
    r = r_exit
    bl = bell_len or r * 1.05
    t = r * 0.12
    rt = r * throat
    k = 6
    outer = [(bl - bl * i / k, rt + (r - rt) * (i / k) ** 1.5) for i in range(k + 1)]
    lip = [(-t * 0.5, r + t * 1.1), (-t * 0.5, r - t * 0.5)]
    inner = [(x, max(rt * 0.8, rr - t * 1.3)) for (x, rr) in reversed(outer)]
    seg = 20
    p.add('bell', 'body', 'siron', revolve(outer + lip + inner[1:], seg, closed=True, phase=math.pi / seg))
    p.add('lining', 'body', 'ember', revolve([(x - r * 0.01, max(rt * 0.78, rr - t * 1.35)) for (x, rr) in outer[::-1][:-1]], seg, phase=math.pi / seg))
    xr = bl * 0.45; rr_ = rt + (r - rt) * (1 - xr / bl) ** 1.5
    p.add('bellring0', 'body', 'sworn', revolve([(xr + t * 0.6, rr_ - t * 0.1), (xr + t * 0.6, rr_ + t * 0.7), (xr - t * 0.6, rr_ + t * 0.7), (xr - t * 0.6, rr_ - t * 0.1)],
                                               seg, closed=True, phase=math.pi / seg))
    p.add('throat', 'body', 'glow', revolve([(bl * 0.92, rt * 0.82), (bl * 0.98, 0.0001)], seg, cap0=False))
    p.add('plug', 'body', 'glow', revolve([(bl * 0.9, rt * 0.62), (bl * 0.55, rt * 0.42), (bl * 0.2, 0.0001)], seg, cap0=True))
    cr = cowl_r or r * 1.5
    rb = r + t * 1.6
    xa = -r * recess
    ph = math.pi / 8
    p.add('housing', 'mount', 'siron2', revolve([(xa, rb), (xa, cr), (body_len, cr), (body_len, rb)], 8, closed=True, phase=ph))
    p.add('housingback', 'mount', 'dark', revolve([(bl * 1.04, rb), (bl * 1.04, 0.0001)], 8, phase=ph))
    p.add('band', 'mount', 'sworn', revolve([(xa + r * 0.08, cr * 0.98), (xa + r * 0.08, cr * 1.07), (xa + r * 0.3, cr * 1.07), (xa + r * 0.3, cr * 0.98)], 8, closed=True, phase=ph))
    p.add('collar', 'mount', 'siron', revolve([(body_len * 0.5, cr * 0.98), (body_len * 0.5, cr * 1.1), (body_len * 0.7, cr * 1.1), (body_len * 0.7, cr * 0.98)], 8, closed=True, phase=ph))
    st = []
    for i in range(8):
        a = 2 * math.pi * (i + 0.5) / 8 + ph
        st.append(_stud((xa, (rb + cr) / 2 * math.cos(a), (rb + cr) / 2 * math.sin(a)), (-1, 0, 0), r * 0.06))
    p.add('facestud', 'mount', 'sworn', _join(st))
    p.fit = dict(exit=P((0, 0, 0)), axis=D((-1, 0, 0)), radius=r + t * 1.1, front=P((body_len, 0, 0)), body_r=cr)
    return p


def craft_spire(h, L, t, spread, fins=4):
    """the fighter's one radiator spire (SF3: "a single short radiator spire stands on the spine, ember glow at its root": the
    flagship's spire row reduced to one). Origin at the root's foot, +X forward, +Z up. Upright and square-topped with its ember
    fins reaching out to each side, so it reads as a radiator, never a tail fin (no sweep, no rake, no rudder edge)."""
    p = Part('radiator')
    p.type = 'radiator'
    p.add('root', 'mount', 'siron2', block(-L * 0.62, L * 0.62, t * 1.6, h * 0.1, h * 0.03))
    p.add('rootstep', 'mount', 'siron', block(-L * 0.5, L * 0.5, t * 1.2, h * 0.03, 0.0, zo=h * 0.12))
    p.add('rootglow', 'body', 'embar', block(-L * 0.42, L * 0.42, t * 1.22, h * 0.012, 0.0, zo=h * 0.155))
    p.add('bar', 'body', 'siron2', _vslab(-L * 0.36, L * 0.36, t * 0.42, h * 0.14, h * 0.9, 0.85))
    p.add('column', 'body', 'siron', _join([_vslab(-L * 0.5, -L * 0.32, t * 0.55, h * 0.14, h * 0.9, 1.0), _vslab(L * 0.32, L * 0.5, t * 0.55, h * 0.14, h * 0.9, 1.0)]))
    p.add('cap', 'body', 'sworn', block(-L * 0.55, L * 0.55, t * 0.85, h * 0.045, h * 0.02, zo=h * 0.93))
    fv = []
    for i in range(fins):
        z = h * (0.28 + 0.56 * i / max(1, fins - 1))
        f = (z / h - 0.28) / 0.56
        reach = t * 0.5 + spread * (1 - 0.3 * f)
        th = h * 0.022
        for sg in (1, -1):
            y0, y1 = sg * t * 0.4, sg * reach
            V = [(-L * 0.3, y0, z - th), (L * 0.3, y0, z - th), (L * 0.3, y1, z - th), (-L * 0.3, y1, z - th),
                 (-L * 0.26, y0, z + th), (L * 0.26, y0, z + th), (L * 0.26, y1 - sg * th, z + th), (-L * 0.26, y1 - sg * th, z + th)]
            fv.append((V, [(3, 2, 1, 0), (4, 5, 6, 7), (0, 1, 5, 4), (1, 2, 6, 5), (2, 3, 7, 6), (3, 0, 4, 7)]))
    p.add('fin', 'body', 'embar', _join(fv))
    gz = []
    for sg in (1, -1):
        for x in (-L * 0.35, L * 0.35):
            gz.append(([(x - L * 0.05, sg * t * 0.5, h * 0.14), (x + L * 0.05, sg * t * 0.5, h * 0.14), (x + L * 0.05, sg * t * 1.15, h * 0.14),
                        (x - L * 0.05, sg * t * 1.15, h * 0.14), (x - L * 0.05, sg * t * 0.5, h * 0.36), (x + L * 0.05, sg * t * 0.5, h * 0.36)],
                       [(0, 1, 2, 3), (0, 4, 5, 1), (1, 5, 2), (3, 2, 5, 4), (0, 3, 4)]))
    p.add('brace', 'body', 'siron2', _join(gz))
    return p


MACHINES = MACHINES + ('launcher',)   # issue 769: the bomb cassette is a machine (it rides whole with one piece)
SUBPARTS['bomb_tube'] = ['face', 'housing', 'bore', 'rim', 'warhead', 'back']
