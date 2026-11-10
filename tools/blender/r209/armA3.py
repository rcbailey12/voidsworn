# Issue 209 round 3, Arm A rung 3 (Ab3 and the hybrid Hy3). Ryan's round 2 ruling (Nov 8 21:40 CST): Ab climbs one rung with the
# board's two fixes, softer layered plating so the hull reads less boxy against the concept, and paint matched to the concept.
# What changes from round 2's A2 structure (armA2.py, which stays as round 2 built it):
#   - rounded sections: the core hull's deck shoulders roll over (a bigger roll toward the bow), the chine and the belly corner are
#     chamfered, the nose is domed; every block (glacis, sponsons, modules, tiers, spine, stern) gets rounded outer corners;
#   - layered armour: big plates shaped to the hull (ray cast onto each block), lapped like scales with alternating standoff, real
#     thickness and chamfered edges, so the seams between them have depth. Plates never cross a break line.
#   - parts seat on the plated surface (ray cast), not on the round 2 tables.
# The hybrid (Hy3) swaps a few hand parts for AI-generated hero parts where round 2 showed they read best: the four gun
# casemates, the twin bow guns and the two sponson drum racks (TRELLIS.2 generations from round 1, reduced to a fixed budget).
# usage: imported by bakeAb3.py; standalone: blender -b -P armA3.py -- OUT_DIR [CELL]   (structure + parts, no bake, no paint)
import os, sys, math, json, time
HERE = os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0, HERE)
import common as C
import bpy, bmesh
import numpy as np
from mathutils import Vector, Matrix
import hs_lib
from hs_lib import loft, box, cyl
import armA2 as A2

BREAK = A2.BREAK
CORE = A2.CORE
at = A2.at
GUNS = []
PROXY_PREFIX = ('cplate', 'cring', 'cball', 'cgun', 'cbolt', 'clip', 'bowmount', 'bowgun', 'bowshroud', 'sdrum')
HERO_K = dict(casemate=6000, bowguns=8000, drumrack=8000)   # hybrid: triangles per generated hero part (B3r2 used 30k, 24k, 40k)

def clamp(v, a, b): return max(a, min(b, v))

# ------------------------------------------------------------------------------------------------ rounded sections
def rpoly(pts, radii, n=3):
    """closed polygon with each corner i replaced by a quadratic curve of n+1 points between the two points r_i along its edges
    (r_i = 0 keeps the corner). The point count depends only on which radii are non-zero, so lofted stations stay compatible."""
    out = []; m = len(pts)
    for i, (p, r) in enumerate(zip(pts, radii)):
        if r <= 0: out.append(p); continue
        a, b = Vector(pts[i - 1]), Vector(pts[(i + 1) % m]); P = Vector(p)
        la, lb = (a - P).length, (b - P).length; rr = min(r, la * .45, lb * .45)
        A = P + (a - P).normalized() * rr; B = P + (b - P).normalized() * rr
        for k in range(n + 1):
            t = k / n; q = A * (1 - t) ** 2 + P * 2 * t * (1 - t) + B * t * t; out.append((q.x, q.y))
    return out

def sec3(s):
    """core hull section: rounded deck shoulder (bigger toward the bow), chamfered chine and belly corner"""
    x, wd, zt, wc, zc, wb, zb = s
    bow = clamp((x - .28) / .22, 0, 1)
    r_sh = .012 + .020 * bow; r_ch = .010 + .010 * bow; r_bl = .008 + .010 * bow
    half = [(wd, zt), (wc, zt - .012), (wc, zc), (wb, zb)]
    loop = [(0, zt)] + half + [(0, zb)] + [(-y, z) for y, z in reversed(half)]
    radii = [0, r_sh * .6, r_sh, r_ch, r_bl, 0, r_bl, r_ch, r_sh, r_sh * .6]
    return (x, rpoly(loop, radii))

def nose(secs):
    """domed nose: two extra stations ahead of the bow, each a shrunken copy of the first section about its centre"""
    x0, pts = secs[-1]; zc = (max(p[1] for p in pts) + min(p[1] for p in pts)) / 2
    out = list(secs)
    for dx, k in ((.003, .90), (.006, .70), (.008, .40)):
        out.append((x0 + dx, [(y * k, zc + (z - zc) * k) for y, z in pts]))
    return out

def rtrap(x, wb, wt, zb, zt, r=.010, rb=.003):
    """a mirrored block section with rounded top corners (r) and softened bottom corners (rb)"""
    loop = [(0, zt), (wt, zt), (wb, zb), (0, zb), (-wb, zb), (-wt, zt)]
    return (x, rpoly(loop, [0, r, rb, 0, rb, r]))

def rside(x, yi, yo, zb, zt, r=.014, s=1, ri=.003):
    """an off-centre block section on side s, outer corners rounded (r), inner corners softened (ri)"""
    pts = [(yi, zt), (yo, zt), (yo, zb), (yi, zb)]; rad = [ri, r, r, ri]
    pts = rpoly(pts, rad)
    pts = [(s * y, z) for y, z in pts]
    return (x, pts if s > 0 else list(reversed(pts)))

def hull_obj(o, kind):
    o['role'] = 'hull'; o['kind'] = kind; hs_lib.PARTS.remove(o); return o

def structure3():
    H = []
    o = loft('core', nose([sec3(s) for s in reversed(CORE)]), bevel=.004); H.append(hull_obj(o, 'core'))
    o = loft('glacis', [rtrap(.404, .058, .046, .020, .030, .006), rtrap(.386, .064, .056, .020, .052, .012), rtrap(.300, .071, .061, .021, .060, .012),
                        rtrap(.222, .078, .067, .022, .068, .012)], bevel=.002); H.append(hull_obj(o, 'glacis'))
    for s in (1, -1):
        o = loft(f'sponson{s}', [rside(.176, .10, .150, -.118, .032, .016, s), rside(.168, .10, .172, -.132, .042, .020, s),
                                 rside(.020, .10, .178, -.136, .044, .020, s), rside(.012, .10, .168, -.126, .034, .016, s)], bevel=.002)
        H.append(hull_obj(o, 'sponson'))
        o = loft(f'module{s}', [rside(.006, .10, .160, -.124, .004, .014, s), rside(.000, .10, .168, -.126, .010, .016, s),
                                rside(-.098, .10, .168, -.122, .010, .016, s), rside(-.106, .10, .156, -.112, .002, .014, s)], bevel=.002)
        H.append(hull_obj(o, 'module'))
        o = loft(f'rail{s}', [rside(-.092, .040, .080, -.070, -.064, .004, s), rside(-.110, .038, .084, -.122, -.064, .008, s),
                              rside(-.330, .038, .084, -.122, -.064, .008, s), rside(-.346, .040, .080, -.074, -.064, .004, s)], bevel=.002)
        H.append(hull_obj(o, 'rail'))
    o = loft('tier1', [rtrap(.176, .070, .060, .027, .040, .008), rtrap(.166, .088, .080, .027, .062, .012), rtrap(-.088, .084, .076, .027, .062, .012),
                       rtrap(-.098, .072, .064, .027, .050, .008)], bevel=.002); H.append(hull_obj(o, 'tier'))
    o = loft('tier2', [rtrap(.128, .052, .046, .060, .082, .008), rtrap(.118, .060, .054, .060, .094, .010), rtrap(.010, .060, .054, .060, .094, .010),
                       rtrap(.002, .054, .048, .060, .086, .008)], bevel=.002); H.append(hull_obj(o, 'tier'))
    o = loft('spine', [rtrap(-.136, .046, .036, .027, .040, .006), rtrap(-.146, .052, .046, .027, .050, .010), rtrap(-.330, .052, .046, .027, .050, .010),
                       rtrap(-.340, .046, .036, .027, .040, .006)], bevel=.002); H.append(hull_obj(o, 'spine'))
    o = loft('stern1', [rtrap(-.350, .074, .062, .027, .050, .008), rtrap(-.362, .086, .080, .027, .068, .014), rtrap(-.492, .086, .080, .027, .068, .014)],
             bevel=.002); H.append(hull_obj(o, 'stern'))
    o = loft('stern2', [rtrap(-.374, .046, .036, .066, .080, .006), rtrap(-.384, .054, .048, .066, .094, .010), rtrap(-.468, .054, .048, .066, .094, .010),
                        rtrap(-.474, .050, .044, .066, .090, .006)], bevel=.002); H.append(hull_obj(o, 'stern'))
    for o in H:
        bpy.context.view_layer.objects.active = o; o.select_set(True)
        for m in list(o.modifiers): bpy.ops.object.modifier_apply(modifier=m.name)
        o.select_set(False)
    return H

# ------------------------------------------------------------------------------------------------ layered armour plates
def armour(name, T, mode, u, v, s=1, off=.0025, th=.0025, cw=.004, du=.010, dv=None, az=-.04, fb=None):
    """one armour plate shaped to a block. mode 'radial': u = (x0, x1), v = (a0, a1) degrees round the axis (y 0, z az) on side s;
    'side': v = (z0, z1), rays in from side s; 'top': v = (y0, y1), rays straight down. Outer face at off + th from the block,
    chamfered border (cw wide, dropping to a quarter of th), inner face at off, walls round the edge. fb: fallback BVH."""
    dv = dv or (4.0 if mode == 'radial' else .010)
    def axis(a, b, d, w):
        n = max(2, int(math.ceil((b - a - 2 * w) / d)))
        return [a] + list(np.linspace(a + w, b - w, n)) + [b]
    us = axis(u[0], u[1], du, cw)
    if mode == 'radial':
        w = math.degrees(cw / .12); vs = axis(v[0], v[1], dv, w)
    else: vs = axis(v[0], v[1], dv, cw)
    def ray(x, q):
        if mode == 'radial':
            a = math.radians(q); d = Vector((0, s * math.cos(a), math.sin(a))); P = Vector((x, 0, az)); o = P + d * .6; dr = -d
        elif mode == 'side': o = Vector((x, s * .6, q)); dr = Vector((0, -s, 0))
        else: o = Vector((x, q, .6)); dr = Vector((0, 0, -1))
        h = T.ray_cast(o, dr, 1.2)
        if h[0] is None:
            h = (fb or T).find_nearest(o + dr * .45)
        return Vector(h[0]), Vector(h[1]).normalized()
    nu, nv = len(us), len(vs); bm = bmesh.new(); O = []; I = []
    for i, x in enumerate(us):
        ro, ri = [], []
        for j, q in enumerate(vs):
            p, n = ray(x, q); border = i in (0, nu - 1) or j in (0, nv - 1)
            ro.append(bm.verts.new(p + n * (off + (th * .25 if border else th)))); ri.append(bm.verts.new(p + n * off))
        O.append(ro); I.append(ri)
    for i in range(nu - 1):
        for j in range(nv - 1):
            bm.faces.new((O[i][j], O[i + 1][j], O[i + 1][j + 1], O[i][j + 1])); bm.faces.new((I[i][j], I[i][j + 1], I[i + 1][j + 1], I[i + 1][j]))
    ring = [(i, 0) for i in range(nu)] + [(nu - 1, j) for j in range(1, nv)] + [(i, nv - 1) for i in range(nu - 2, -1, -1)] + [(0, j) for j in range(nv - 2, 0, -1)]
    for k in range(len(ring)):
        (a, b), (c, d) = ring[k], ring[(k + 1) % len(ring)]
        bm.faces.new((O[a][b], I[a][b], I[c][d], O[c][d]))
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    o = C.new_obj(name, bm); o['role'] = 'hull'; o['kind'] = 'plate'; return o

def plates(S):
    """the plate layout (port; starboard mirrored). Rows overlap like scales: neighbours alternate standoff (0.0025 / 0.0045), so one
    plate's edge laps over the next and the uncovered seams sit as grooves. Every plate stays inside one break piece."""
    by = {}
    for o in S: by.setdefault(o['kind'], []).append(o)
    B = {k: C.bvh(v) for k, v in by.items()}; Ball = C.bvh(S); P = []
    lo, hi = .0025, .0045
    for s in (1, -1):
        t = 'p' if s > 0 else 's'
        # bow block, three belts: shoulder and upper flank, lower flank, chine and belly corner (x from 0.19, ahead of the break line)
        for k, (x0, x1) in enumerate(((.190, .272), (.264, .352), (.344, .432), (.424, .484))):
            P.append(armour(f'plA{t}{k}', B['core'], 'radial', (x0, x1), (-3, 33), s, off=hi if k % 2 else lo))
        for k, (x0, x1) in enumerate(((.190, .302), (.294, .404), (.396, .476))):
            P.append(armour(f'plB{t}{k}', B['core'], 'radial', (x0, x1), (-30, -1), s, off=lo if k % 2 else hi))
        for k, (x0, x1) in enumerate(((.190, .332), (.324, .462))):
            P.append(armour(f'plC{t}{k}', B['core'], 'radial', (x0, x1), (-57, -28), s, off=hi if k % 2 else lo))
        # bow deck strips beside the glacis
        for k, (x0, x1) in enumerate(((.192, .300), (.292, .392))):
            P.append(armour(f'pld{t}{k}', B['core'], 'top', (x0, x1), tuple(sorted((s * .070, s * .108))), s, off=lo if k % 2 else hi))
        # glacis top, split down the centreline
        P.append(armour(f'plg{t}', B['glacis'], 'top', (.226, .372), tuple(sorted((s * .003, s * .058))), s, off=lo))
        # sponsons: upper and lower belts split at the longitudinal break line (z -0.045), staggered along x
        for k, (x0, x1) in enumerate(((.024, .100), (.092, .168))):
            P.append(armour(f'plsu{t}{k}', B['sponson'], 'radial', (x0, x1), (1.5, 40), s, az=-.045, off=hi if k % 2 else lo))
        for k, (x0, x1) in enumerate(((.024, .124), (.116, .168))):
            P.append(armour(f'plsl{t}{k}', B['sponson'], 'radial', (x0, x1), (-37, -1.5), s, az=-.045, off=lo if k % 2 else hi))
        # module blocks
        P.append(armour(f'plmu{t}', B['module'], 'side', (-.094, -.006), (-.041, .004), s, off=lo))
        for k, (x0, x1) in enumerate(((-.094, -.046), (-.052, -.006))):
            P.append(armour(f'plml{t}{k}', B['module'], 'side', (x0, x1), (-.116, -.049), s, off=hi if k % 2 else lo))
        # deckhouse tier sides and the stern block sides
        for k, (x0, x1) in enumerate(((-.082, .044), (.036, .158))):
            P.append(armour(f'plt{t}{k}', B['tier'], 'side', (x0, x1), (.031, .058), s, off=lo if k % 2 else hi))
        for k, (x0, x1) in enumerate(((-.486, -.418), (-.426, -.368))):
            P.append(armour(f'plst{t}{k}', B['stern'], 'side', (x0, x1), (.031, .064), s, off=lo if k % 2 else hi))
    return P

# ------------------------------------------------------------------------------------------------ parts, seated by ray cast
def tag(r, since, kind=None):
    for o in hs_lib.PARTS[since:]:
        o['role'] = r
        if kind: o['kind'] = kind

def gun(name, base, d, L, r):
    d = Vector(d).normalized(); GUNS.append((name, d)); hs_lib.barrel(name, base, d, L, r)

class Seat:
    def __init__(self, hull): self.T = C.bvh(hull)
    def flank(self, x, z, s):
        h = self.T.ray_cast(Vector((x, s * .6, z)), Vector((0, -s, 0)), .6); return abs(h[0].y) if h[0] is not None else at(x)[3]
    def top(self, x, y, L=0.0):
        zs = []
        for xx in (x - L / 2, x, x + L / 2):
            h = self.T.ray_cast(Vector((xx, y, .6)), Vector((0, 0, -1)), 1.2)
            if h[0] is not None: zs.append(h[0].z)
        return max(zs) if zs else A2.top_z(x, y)

def drum(nm, x, y, r, L, seat, lift=.003):
    zt = seat.top(x, y, L); z = zt + r + lift
    n0 = len(hs_lib.PARTS); cyl(nm, (x, y, z), r, L, axis='X', seg=28, bevel=.0015); hs_lib.PARTS[n0]['kind'] = 'drum'
    for k, xx in enumerate((x - L * .3, x + L * .3)): cyl(f'{nm}band{k}', (xx, y, z), r * 1.04, L * .06, axis='X', seg=28, bevel=0)
    tag('trim', n0 + 1, 'band')
    n1 = len(hs_lib.PARTS); cyl(f'{nm}bore', (x + L / 2 + .0005, y, z), r * .72, .002, axis='X', seg=24, bevel=0); tag('dark', n1)
    n2 = len(hs_lib.PARTS)
    cyl(f'{nm}nose', (x + L / 2 - .002, y, z), r * 1.06, .004, axis='X', seg=28, bevel=.0005)
    cyl(f'{nm}tail', (x - L / 2 - .002, y, z), r * .55, .006, axis='X', seg=20, bevel=.0008)
    for xx in (x - L * .15, x + L * .15): box(f'{nm}lug{xx:.3f}', (xx, y, z + r), (.006, .004, .004), bevel=.0006)
    for k, xx in enumerate((x - L * .3, x + L * .3)):
        zs = seat.top(xx, y); box(f'{nm}saddle{k}', (xx, y, (z - r * .6 + zs) / 2 - .001), (L * .10, r * 1.6, max(.004, z - r * .6 - zs + .006)), bevel=.001)
    for o in hs_lib.PARTS[n2:]: o['kind'] = 'drum'

def casemate(i, x, s, seat):
    z = -.046; y = s * (seat.flank(x, z, s) + .001)
    n0 = len(hs_lib.PARTS); cyl(f'cplate{i}{s}', (x, y, z), .036, .008, axis='Y', seg=8, bevel=.0015); tag('part', n0, 'casemate_plate')
    n0 = len(hs_lib.PARTS)
    cyl(f'cring{i}{s}', (x, y + s * .006, z), .024, .006, axis='Y', seg=24, bevel=.001)
    cyl(f'cball{i}{s}', (x, y + s * .013, z), .017, .015, axis='Y', seg=24, bevel=.004)
    d = Vector((.55, s * .83, .05))
    for k in (-1, 1): gun(f'cgun{i}{s}{k}', Vector((x, y + s * .015, z + k * .007)), d, .060, .0046)
    for a in range(8):
        t = (a + .5) * math.pi / 4; box(f'cbolt{i}{s}{a}', (x + .031 * math.cos(t), y + s * .005, z + .031 * math.sin(t)), (.004, .003, .004), bevel=.0005)
    box(f'clip{i}{s}', (x, y + s * .010, z + .024), (.040, .010, .004), bevel=.0008)
    tag('part', n0, 'gun')

def parts3(seat, hero=()):
    """A2's round 2 hand parts on the plated rung 3 hull. hero: which slots the hybrid fills with generated parts instead."""
    P = hs_lib.PARTS
    if 'bowguns' not in hero:
        for s in (1, -1):
            n0 = len(P)
            box(f'bowmount{s}', (.384, s * .030, .060), (.024, .022, .018), bevel=.002)
            gun(f'bowgun{s}', (.392, s * .030, .062), (1, 0, 0), .075, .0062)
            cyl(f'bowshroud{s}', (.405, s * .030, .062), .0105, .022, axis='X', seg=20, bevel=.001); tag('part', n0, 'gun')
    if 'casemate' not in hero:
        for i, x in enumerate((.368, .248)):
            for s in (1, -1): casemate(i, x, s, seat)
    n0 = len(P); cyl('tower', (.058, 0, .094 + .030), .034, .060, seg=32, bevel=.003); tag('part', n0, 'tower')
    n0 = len(P); cyl('towerband', (.058, 0, .094 + .046), .0355, .007, seg=32, bevel=0); tag('trim', n0, 'band')
    n0 = len(P); box('bridge', (.068, 0, .094 + .068), (.058, .070, .022), bevel=.003); tag('part', n0, 'bridge')
    n0 = len(P); box('bridgeglass', (.098, 0, .094 + .070), (.004, .056, .007), bevel=.0005); tag('dark', n0)
    import barge_shapes as B
    n0 = len(P); B.antenna_array(.058, 0, .094 + .079, h=.080); tag('part', n0, 'antenna')
    for s in (1, -1): drum(f'fdrum{s}', .146, s * .040, .016, .040, seat)
    for s in (1, -1):
        if 'drumrack' not in hero:
            for k, yy in enumerate((.124, .156)): drum(f'sdrum{s}{k}', .092, s * yy, .0145, .085, seat)
        drum(f'mdrum{s}', -.050, s * .134, .018, .080, seat)
    for s in (1, -1): drum(f'adrum{s}', -.290, s * .070, .014, .060, seat)
    n0 = len(P); B.radiator_pair(-.426, 0, .094, n=2, L=.070, H=.046); tag('part', n0, 'radiator')
    for nm, (y, z, r) in (('main', (0, -.013, .030)), ('portb', (.056, -.012, .020)), ('stbdb', (-.056, -.012, .020)),
                          ('upp', (.040, .047, .012)), ('ups', (-.040, .047, .012))):
        n0 = len(P); B.engine_bell((-.492 if z < .03 else -.488, y, z), r, .040 if r > .015 else .026, axis_dir=Vector((-1, 0, 0))); tag('part', n0, 'engine')
        n0 = len(P); cyl(f'glow{nm}', (-.522 if z < .03 else -.512, y, z), r * .9, .002, axis='X', seg=28, bevel=0); tag('glow', n0)
    for s in (1, -1):
        n0 = len(P); loft(f'cargo{s}', [rside(-.146, .100, .150, -.092, -.016, .008, s), rside(-.154, .100, .158, -.108, -.010, .010, s),
                                         rside(-.292, .100, .158, -.108, -.010, .010, s), rside(-.300, .100, .150, -.092, -.016, .008, s)], bevel=.002)
        for xx in (-.170, -.275): box(f'cargoarm{s}{xx}', (xx, s * .104, -.004), (.016, .012, .016), bevel=.001)
        for k in range(7): box(f'cargorib{s}{k}', (-.160 - k * .012, s * .159, -.059), (.005, .004, .090), bevel=0)
        for k in range(5): box(f'cargorib2{s}{k}', (-.244 - k * .010, s * .159, -.059), (.004, .004, .090), bevel=0)
        box(f'cargohatch{s}', (-.236, s * .159, -.054), (.020, .003, .060), bevel=.0006)
        tag('part', n0, 'cargo')
    for s in (1, -1):
        n0 = len(P); R = Matrix.Rotation(math.radians(s * -18), 3, 'X')
        bm = bmesh.new(); prof = [(.402, -.150), (.288, -.160), (.300, -.232), (.360, -.236)]
        vs = [[bm.verts.new(Vector((x, s * .040, 0)) + R @ Vector((0, k * .005, z + .150)) + Vector((0, 0, -.150))) for x, z in prof] for k in (-1, 1)]
        bm.faces.new(vs[0][::-1]); bm.faces.new(vs[1])
        for i in range(4): bm.faces.new((vs[0][i], vs[0][(i + 1) % 4], vs[1][(i + 1) % 4], vs[1][i]))
        bmesh.ops.recalc_face_normals(bm, faces=bm.faces); hs_lib._obj(f'vfin{s}', bm, .0015)
        tip = Vector((.330, s * .040, 0)) + R @ Vector((0, 0, -.084)) + Vector((0, 0, -.150))
        cyl(f'vpod{s}', tip, .009, .060, axis='X', seg=16, r2=.007, bevel=.001)
        tag('part', n0, 'fin')
    for s in (1, -1):
        n0 = len(P)
        cyl(f'vthr{s}', (-.300, s * .060, -.132), .012, .050, axis='X', seg=20, bevel=.002)
        box(f'vthrpylon{s}', (-.300, s * .060, -.124), (.030, .008, .008), bevel=.001); tag('part', n0, 'engine')
    # round 2 rung detail that is not plating: sponson vents, module hatches, rail plates, spine pipes, bow hatches
    import detail_lib as D
    n0 = len(P)
    for s_ in (1, -1):
        hs_lib.vents(f'spvent{s_}', (.120, s_ * (seat.flank(.120, .010, s_) + .001), .010), 6, .003, .010, .008)
        for xx in (-.020, -.070): box(f'mhatch{s_}{xx}', (xx, s_ * (seat.flank(xx, -.078, s_) + .0005), -.078), (.026, .002, .030), bevel=.0006)
        for xx in (-.200, -.260): box(f'railplate{s_}{xx}', (xx, s_ * .060, -.1225), (.040, .040, .002), bevel=.0005)
    for yy in (-.030, .030): D.tube(f'spinepipe{yy}', Vector((-.150, yy, .052)), Vector((-.325, yy, .052)), .0028)
    tag('part', n0, 'detail')

def hero_parts(G, hull, seat, notes):
    """the hybrid's generated hero parts, in the same slots B3r2 used, at the HERO_K budgets"""
    import armB as AB
    P = lambda nm: os.path.join(G, f'p_{nm}.glb'); made = []
    for i, x in enumerate((.368, .248)):
        for s in (1, -1):
            wc = seat.flank(x, -.046, s)
            o = AB.gen(P('casemate'), f'hcasemate_{i}{"p" if s > 0 else "s"}', HERO_K['casemate'], (x - .040, wc - .004, -.086), (x + .040, wc + .060, -.006), 'part', notes)
            if s < 0: AB.mirror_y(o)
            o['kind'] = 'gen_casemate'; made.append(o)
    o = AB.gen(P('bowguns'), 'hbowguns', HERO_K['bowguns'], (.336, -.050, .052), (.452, .050, .088), 'part', notes); o['kind'] = 'gen_bowguns'; made.append(o)
    for nm, y in (('hdrums_sp', .139), ('hdrums_ss', -.139)):
        zt = seat.top(.092, y, .085)
        o = AB.gen(P('drumrack'), nm, HERO_K['drumrack'], (.092 - .0425, y - .033, zt - .003), (.092 + .0425, y + .033, zt + .030), 'part', notes)
        o['kind'] = 'gen_drumrack'; made.append(o)
    return made

def plate_crossing(P):
    bad = []
    for o in P:
        w = [o.matrix_world @ Vector(b) for b in o.bound_box]; lo = Vector([min(v[i] for v in w) for i in range(3)]); hi = Vector([max(v[i] for v in w) for i in range(3)])
        for x in BREAK['t_lines']:
            if lo.x < x - .001 and hi.x > x + .001: bad.append(o.name)
        z, x0, x1 = BREAK['l_line']
        if lo.x < x1 and hi.x > x0 and lo.z < z - .001 and hi.z > z + .001: bad.append(o.name)
    return sorted(set(bad))

def build_geometry(hero=(), G=None):
    """structure, plates, parts (and hero parts). Returns (blocks, plates, hard parts, generated parts, notes)"""
    bpy.ops.wm.read_factory_settings(use_empty=True); hs_lib.PARTS.clear(); GUNS.clear(); C.set_break(**BREAK)
    S = structure3(); Pl = plates(S); seat = Seat(S + Pl); notes = []
    parts3(seat, ())
    if hero:   # the hand parts in the hero slots stay as hidden proxies: the hybrid's far LODs use them instead of the generated parts
        for o in hs_lib.PARTS:
            if o.name.startswith(PROXY_PREFIX): o['proxy'] = 1; o.hide_render = True
        GUNS[:] = [g for g in GUNS if not g[0].startswith(PROXY_PREFIX)]
    gen = hero_parts(G, S + Pl, seat, notes) if hero else []
    for o in hs_lib.PARTS:
        if 'role' not in o: o['role'] = 'part'
        if o.get('proxy'): o.hide_render = True
        for m in list(o.modifiers):
            bpy.context.view_layer.objects.active = o; o.select_set(True); bpy.ops.object.modifier_apply(modifier=m.name); o.select_set(False)
    return S, Pl, [o for o in hs_lib.PARTS if not o.get('proxy')], gen, notes, [o for o in hs_lib.PARTS if o.get('proxy')]

if __name__ == '__main__':
    a = sys.argv[sys.argv.index('--') + 1:] if '--' in sys.argv else sys.argv[1:]
    out = a[0]; cell = a[1] if len(a) > 1 else 'A3s'; t0 = time.time()
    S, Pl, hard, gen, notes, prox = build_geometry()
    if cell == 'A3s':  # structure compare: blocks and plates only, parts as envelopes are not needed for the flat views
        for o in hard: bpy.data.objects.remove(o)
    rep = C.report(S + Pl + ([] if cell == 'A3s' else hard))
    os.makedirs(out, exist_ok=True); bpy.ops.wm.save_as_mainfile(filepath=os.path.join(out, f'{cell}.blend'))
    meta = dict(cell=cell, plates=len(Pl), plate_crossing=plate_crossing(Pl), plate_triangles=sum(C.tris(o) for o in Pl),
                block_triangles=sum(C.tris(o) for o in S), seconds=round(time.time() - t0, 1), **rep)
    print('[209]', json.dumps(meta), flush=True)
