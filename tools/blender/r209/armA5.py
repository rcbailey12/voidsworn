# Issue 209 round 5: the hand hull traced from B0's own shape (Ryan, Nov 9 09:47 CST, R147: round 4 "too tall and chunky", a blunt
# bow, no tall tower; "you can see some of that waviness issues with the ai hulls too, even some of the parts look wavy or
# oversharpened"). B0 (TRELLIS.2's whole-hull generation, yaw fixed) scores 88 percent at the concept camera and is the closest shape.
# B0 is a shape reference only, never shipped geometry:
#   - the core hull is a loft of clean faceted sections (flat deck, sharp deck edge, a chamfered shoulder, a slab side, a two-facet
#     tuck to a flat belly), one knot per B0 station read by fitting that section to B0's slice (b0trace.py), then smoothed and tuned
#     on the concept outline (tune5.py) inside ranges that keep B0's proportions;
#   - the superstructure (raised forward deck, deckhouse tier, tower tier, hump, aft body, stern block) and the side blocks (sponsons,
#     modules, cargo blocks) are flat-sided lofts sized from B0's top envelope and its outboard blocks;
#   - the tall antenna tower forward and the aft sensor mast are space parts (a tapered truss pylon with sensor rings and an antenna
#     array; a three-leg sensor mast with a housing and dish), sized to the concept's outline, no crossbars or rigging;
#   - the casemates and drum racks are hand rebuilt at the proportions of Hy4's generated parts (p_casemate, p_drumrack, read as
#     references only): octagonal plate, riveted ring, turret drum with a ribbed band and a tapered nose, twin barrels; three drums
#     on saddles over a base frame. Crisp bevels, no noise. Bow guns hand built. Every part in matched pairs.
# Round 3 and 4's plating (armour(), lapped, chamfered) and paint (paint3.py), break lines, internal decks and bulkheads carry over.
# usage: imported by bakeAb5.py, sil_dump.py (build armA5 Ab5), tune5.py; standalone: blender -b -P armA5.py -- OUT_DIR [A5s|Ab5]
import os, sys, math, json, time
HERE = os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0, HERE)
import common as C
import bpy, bmesh
import numpy as np
from mathutils import Vector, Matrix
import hs_lib
from hs_lib import loft, box, cyl
import armA3 as A3
from armA3 import armour, Seat, drum, tag, plate_crossing

BREAK = A3.BREAK          # same break lines as rounds 2 to 4: bow | midship (split lengthwise at z -0.045) | aft body
GUNS = A3.GUNS
HERO_SLOTS = ()           # Ab5 is all hand built; the generated parts are references only

# ------------------------------------------------------------------------------------------------ the core hull, traced from B0
# Ship frame: x to the bow, y to port, z up, length 1.0. One knot per traced station:
#   x, deck z (zt), deck-edge half-width (Wd), side half-width (Ws), top and bottom of the slab side (zs1, zs2),
#   tuck point (Wt, zt2), belly corner (Wb, zb). Half-section: (0,zt) (Wd,zt) (Ws,zs1) (Ws,zs2) (Wt,zt2) (Wb,zb) (0,zb).
KEYS = ('zt', 'Wd', 'Ws', 'zs1', 'zs2', 'Wt', 'zt2', 'Wb', 'zb')
HK = [
    (-.475, .028, .066, .072, .016, -.020, .058, -.032, .036, -.042),
    (-.440, .030, .068, .078, .018, -.024, .066, -.038, .042, -.050),
    (-.400, .030, .072, .086, .016, -.030, .080, -.046, .056, -.058),
    (-.340, .030, .078, .092, .012, -.046, .086, -.066, .068, -.082),
    (-.260, .028, .088, .110, .004, -.060, .104, -.082, .084, -.094),
    (-.180, .030, .104, .124, .004, -.066, .118, -.096, .086, -.110),
    (-.140, .028, .112, .140, .000, -.078, .128, -.112, .092, -.128),
    (-.110, .026, .120, .150, .000, -.086, .124, -.126, .086, -.150),
    (-.070, .026, .130, .153, .006, -.094, .112, -.134, .074, -.168),
    (0.000, .026, .136, .154, .006, -.094, .110, -.132, .086, -.164),
    (0.070, .027, .142, .152, .002, -.072, .104, -.114, .060, -.150),
    (0.140, .027, .142, .153, .008, -.086, .100, -.126, .066, -.160),
    (0.180, .024, .120, .146, .000, -.086, .103, -.125, .060, -.162),
    (0.210, .018, .108, .146, -.018, -.086, .108, -.126, .054, -.163),
    (0.300, .018, .106, .146, -.019, -.086, .110, -.126, .055, -.164),
    (0.380, .017, .096, .148, -.021, -.088, .105, -.132, .050, -.168),
    (0.420, .008, .094, .132, -.016, -.098, .095, -.136, .056, -.166),
    (0.450, .000, .086, .114, -.030, -.090, .098, -.120, .062, -.148),
    (0.480, -.006, .074, .094, -.022, -.090, .074, -.114, .044, -.132),
    (0.497, -.010, .050, .064, -.028, -.084, .050, -.104, .030, -.118),
]

def knot(x):
    """the hull's numbers at station x (linear between knots)"""
    xs = [k[0] for k in HK]
    if x <= xs[0]: return dict(zip(KEYS, HK[0][1:]))
    if x >= xs[-1]: return dict(zip(KEYS, HK[-1][1:]))
    for a, b in zip(HK, HK[1:]):
        if a[0] <= x <= b[0]:
            t = (x - a[0]) / (b[0] - a[0]); return {k: a[i + 1] + (b[i + 1] - a[i + 1]) * t for i, k in enumerate(KEYS)}

def half(k):
    zt, Wd, Ws = k['zt'], k['Wd'], max(k['Ws'], k['Wd'])
    zs1 = min(k['zs1'], zt - .002); zs2 = min(k['zs2'], zs1 - .004); zt2 = min(k['zt2'], zs2 - .004); zb = min(k['zb'], zt2 - .004)
    Wt = min(k['Wt'], Ws); Wb = min(k['Wb'], Wt)
    return [(Wd, zt), (Ws, zs1), (Ws, zs2), (Wt, zt2), (Wb, zb)]

def section(x):
    h = half(knot(x)); zt, zb = h[0][1], h[-1][1]
    return (x, [(0, zt)] + h + [(0, zb)] + [(-y, z) for y, z in reversed(h)])

def stations():
    xs = set(round(k[0], 4) for k in HK)
    xs |= set(round(x, 4) for x in np.arange(-.46, .49, .02))
    return sorted(xs)

def deck_z(x): return knot(x)['zt']
def deck_w(x): return knot(x)['Wd']

# ------------------------------------------------------------------------------------------------ superstructure and side blocks
# All block numbers in one table; tune5.py moves some of them (each held to a range that keeps the design).
P = dict(
    gl_x=(.408, .394, .212), gl_wb=.080, gl_wt=.064, gl_z=(.046, .056, .064),   # raised forward deck: front lip, front top, back
    t1_x=(.176, -.100), t1_w=.082, t1_z=.074,                                     # deckhouse tier
    t2_x=(.128, .000), t2_w=.058, t2_z=.088,                                      # tower tier
    hump_x=(-.030, -.165), hump_w=.064, hump_z=.070,                              # the red hump behind the tower
    ab_x=(-.110, -.430), ab_w=.066, ab_z=.054, ab_r=.022,                        # long dark aft body, rounded top corners
    st_x=(-.424, -.478), st_w=.066, st_z=.062,                                    # stern block
    sp_x=(.172, .020), sp_out=.182, sp_z=(-.096, .022),                          # sponsons (the concept's dark side block)
    md_x=(.012, -.104), md_out=.176, md_z=(-.104, .016),                         # modules behind them
    cg_x=(-.150, -.296), cg_out=.172, cg_z=(-.096, -.012),                       # cargo blocks on the aft hull
    bg_dz=0.0, bg_x=0.0, fd_r=.016,                                               # bow guns: lift and shift; fore drum radius
    fin_dx=0.0, fin_dz=0.0, fin_fwd=0.0, fin_root=0.0,                                       # ventral pylons: shift, extra depth, foot forward
)

def flatsec(x, w, zb, zt, r=.0035, rb=.002):
    return A3.rtrap(x, w, w, zb, zt, r, rb)

def rbox(x, wi, wo, zb, zt, s, r=.004):
    return A3.rside(x, wi, wo, zb, zt, r, s, .002)

def hull_obj(o, kind):
    o['role'] = 'hull'; o['kind'] = kind; hs_lib.PARTS.remove(o); return o

def structure5():
    p = P; H = []
    o = loft('core', [section(x) for x in stations()], bevel=.0022); H.append(hull_obj(o, 'core'))
    (gx0, gx1, gx2), (gz0, gz1, gz2) = p['gl_x'], p['gl_z']
    zb0 = lambda x: deck_z(x) - .006
    o = loft('glacis', [A3.rtrap(gx0, p['gl_wb'] - .012, p['gl_wt'] - .012, zb0(gx0), gz0, .003, .002),
                        A3.rtrap(gx1, p['gl_wb'], p['gl_wt'], zb0(gx1), gz1, .003, .002),
                        A3.rtrap(gx2, p['gl_wb'], p['gl_wt'], zb0(gx2), gz2, .003, .002)], bevel=.002); H.append(hull_obj(o, 'glacis'))
    for s in (1, -1):
        (a, b), (zl, zh), wo = p['sp_x'], p['sp_z'], p['sp_out']; wi = .110
        o = loft(f'sponson{s}', [rbox(a, wi, wo - .022, zl + .016, zh - .010, s), rbox(a - .008, wi, wo, zl + .004, zh, s),
                                 rbox(b + .008, wi, wo, zl, zh, s), rbox(b, wi, wo - .010, zl + .010, zh - .008, s)], bevel=.002)
        H.append(hull_obj(o, 'sponson'))
        (a, b), (zl, zh), wo = p['md_x'], p['md_z'], p['md_out']
        o = loft(f'module{s}', [rbox(a, wi, wo - .008, zl + .010, zh - .006, s), rbox(a - .006, wi, wo, zl, zh, s),
                                rbox(b + .008, wi, wo, zl, zh, s), rbox(b, wi, wo - .012, zl + .012, zh - .008, s)], bevel=.002)
        H.append(hull_obj(o, 'module'))
    (a, b), w, z = p['t1_x'], p['t1_w'], p['t1_z']; z0 = .020
    o = loft('tier1', [flatsec(a, w - .010, z0, z - .010), flatsec(a - .010, w, z0, z), flatsec(b + .010, w, z0, z), flatsec(b, w - .010, z0, z - .010)],
             bevel=.002); H.append(hull_obj(o, 'tier'))
    (a, b), w, z = p['t2_x'], p['t2_w'], p['t2_z']; z1 = p['t1_z'] - .004
    o = loft('tier2', [flatsec(a, w - .006, z1, z - .008), flatsec(a - .008, w, z1, z), flatsec(b + .008, w, z1, z), flatsec(b, w - .006, z1, z - .008)],
             bevel=.002); H.append(hull_obj(o, 'tier'))
    (a, b), w, z = p['hump_x'], p['hump_w'], p['hump_z']
    o = loft('hump', [A3.rtrap(a, w - .016, w - .020, z0, z - .016, .018, .002), A3.rtrap(a - .018, w, w - .004, z0, z, .026, .002),
                      A3.rtrap(b + .016, w, w - .004, z0, z, .026, .002), A3.rtrap(b, w - .012, w - .016, z0, z - .014, .018, .002)], bevel=.002)
    H.append(hull_obj(o, 'tier'))
    (a, b), w, z, r = p['ab_x'], p['ab_w'], p['ab_z'], p['ab_r']
    o = loft('aftbody', [A3.rtrap(a, w - .012, w - .014, z0, z - .010, r * .8, .002), A3.rtrap(a - .012, w, w, z0, z, r, .002),
                         A3.rtrap(b + .004, w, w, z0, z, r, .002), A3.rtrap(b, w - .004, w - .004, z0, z - .002, r, .002)], bevel=.002)
    H.append(hull_obj(o, 'spine'))
    (a, b), w, z = p['st_x'], p['st_w'], p['st_z']; zsb = knot(b)['zb'] + .006
    o = loft('sternblock', [flatsec(a, w - .010, zsb, z - .010), flatsec(a - .010, w, zsb, z), flatsec(b, w, zsb, z)], bevel=.002)
    H.append(hull_obj(o, 'stern'))
    for o in H:
        bpy.context.view_layer.objects.active = o; o.select_set(True)
        for m in list(o.modifiers): bpy.ops.object.modifier_apply(modifier=m.name)
        o.select_set(False)
    return H

# ------------------------------------------------------------------------------------------------ layered armour on the traced hull
def plates5(S):
    """big plates in staggered belts, lapped (alternating standoff); none crosses a break line (x .178, x -.125, z -.045 between them)"""
    by = {}
    for o in S: by.setdefault(o['kind'], []).append(o)
    B = {k: C.bvh(v) for k, v in by.items()}; Pl = []; lo, hi = .0025, .0045
    p = P
    for s in (1, -1):
        t = 'p' if s > 0 else 's'
        # bow block: the shoulder (deck edge down to the slab side), the slab side, the upper tuck
        for k, (x0, x1) in enumerate(((.190, .272), (.264, .346), (.338, .414))):
            Pl.append(armour(f'plU{t}{k}', B['core'], 'side', (x0, x1), (-.014, .012), s, off=hi if k % 2 else lo))
        for k, (x0, x1) in enumerate(((.190, .300), (.292, .404), (.396, .446))):
            Pl.append(armour(f'plS{t}{k}', B['core'], 'side', (x0, x1), (-.082, -.024), s, off=lo if k % 2 else hi))
        for k, (x0, x1) in enumerate(((.190, .296), (.288, .392))):
            Pl.append(armour(f'plT{t}{k}', B['core'], 'side', (x0, x1), (-.120, -.092), s, off=hi if k % 2 else lo))
        # bow deck strips beside the raised deck, and the deck ahead of it
        for k, (x0, x1) in enumerate(((.190, .292), (.284, .384))):
            Pl.append(armour(f'pld{t}{k}', B['core'], 'top', (x0, x1), tuple(sorted((s * (p['gl_wb'] + .006), s * .098))), s, off=lo if k % 2 else hi))
        Pl.append(armour(f'pldn{t}', B['core'], 'top', (.418, .468), tuple(sorted((s * .004, s * .062))), s, off=lo))
        # raised deck top, split down the centreline
        Pl.append(armour(f'plg{t}', B['glacis'], 'top', (.222, .384), tuple(sorted((s * .004, s * (p['gl_wt'] - .008)))), s, off=lo))
        # sponsons: upper and lower belts split at the longitudinal break line, staggered
        for k, (x0, x1) in enumerate(((.026, .100), (.092, .162))):
            Pl.append(armour(f'plsu{t}{k}', B['sponson'], 'side', (x0, x1), (-.040, p['sp_z'][1] - .008), s, off=hi if k % 2 else lo))
        for k, (x0, x1) in enumerate(((.026, .124), (.116, .162))):
            Pl.append(armour(f'plsl{t}{k}', B['sponson'], 'side', (x0, x1), (p['sp_z'][0] + .010, -.050), s, off=lo if k % 2 else hi))
        Pl.append(armour(f'plmu{t}', B['module'], 'side', (-.094, -.004), (-.040, p['md_z'][1] - .008), s, off=lo))
        for k, (x0, x1) in enumerate(((-.094, -.046), (-.052, -.004))):
            Pl.append(armour(f'plml{t}{k}', B['module'], 'side', (x0, x1), (p['md_z'][0] + .012, -.050), s, off=hi if k % 2 else lo))
        # deckhouse tier, aft body and stern block sides
        for k, (x0, x1) in enumerate(((-.090, .040), (.032, .160))):
            Pl.append(armour(f'plt{t}{k}', B['tier'], 'side', (x0, x1), (.026, p['t1_z'] - .006), s, off=lo if k % 2 else hi))
        for k, (x0, x1) in enumerate(((-.418, -.350), (-.358, -.272), (-.280, -.196), (-.204, -.132))):
            Pl.append(armour(f'pla{t}{k}', B['spine'], 'side', (x0, x1), (.026, p['ab_z'] - .016), s, off=hi if k % 2 else lo))
        Pl.append(armour(f'plst{t}', B['stern'], 'side', (-.470, -.432), (-.020, p['st_z'] - .006), s, off=lo))
        # aft hull side behind the cargo blocks
        for k, (x0, x1) in enumerate(((-.420, -.360), (-.366, -.304))):
            Pl.append(armour(f'plh{t}{k}', B['core'], 'side', (x0, x1), (-.030, .018), s, off=lo if k % 2 else hi))
    return Pl

# ------------------------------------------------------------------------------------------------ parts, seated by ray cast
def octo(name, c, w, h, th, ch, axis_s):
    """an octagonal armour plate (w along x, h along z, chamfer ch) standing th proud along +y (axis_s = side)"""
    pts = [(-w / 2 + ch, h / 2), (w / 2 - ch, h / 2), (w / 2, h / 2 - ch), (w / 2, -h / 2 + ch), (w / 2 - ch, -h / 2), (-w / 2 + ch, -h / 2),
           (-w / 2, -h / 2 + ch), (-w / 2, h / 2 - ch)]
    bm = bmesh.new(); x0, y0, z0 = c
    vs = [[bm.verts.new((x0 + u, y0 + axis_s * d, z0 + v)) for u, v in pts] for d in (0, th)]
    bm.faces.new(vs[0][::-1] if axis_s > 0 else vs[0]); bm.faces.new(vs[1] if axis_s > 0 else vs[1][::-1])
    for i in range(8): bm.faces.new((vs[0][i], vs[0][(i + 1) % 8], vs[1][(i + 1) % 8], vs[1][i]))
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces); return hs_lib._obj(name, bm, .0012)

CASEMATE_X = (.346, .232); CASEMATE_Z = -.054; CAS_FWD = .26   # turret axis: out to the side, a little forward

def casemate5(i, x, s, seat, z=CASEMATE_Z):
    """hand rebuild of the generated casemate at its proportions (p_casemate read as a reference, scaled to the 0.088 slot):
    octagonal plate 0.088 x 0.090, 0.016 proud; riveted ring r 0.024 on its face; turret drum r 0.014, a ribbed band r 0.015,
    a tapered nose to r 0.011; twin barrels aimed out to the side and a little forward"""
    y = s * (seat.flank(x, z, s) + .0005)
    n0 = len(hs_lib.PARTS); octo(f'cplate{i}{s}', (x, y, z), .088, .090, .016, .020, s); tag('part', n0, 'casemate_plate')
    n0 = len(hs_lib.PARTS); yf = y + s * .016
    cyl(f'cring{i}{s}', (x, yf + s * .0015, z), .025, .003, axis='Y', seg=32, bevel=.0006)
    for a in range(12):
        t = (a + .5) * math.pi / 6; cyl(f'crivet{i}{s}{a}', (x + .022 * math.cos(t), yf + s * .0035, z + .022 * math.sin(t)), .0018, .002, axis='Y', seg=8, bevel=0)
    for a in range(4):
        t = (a + .5) * math.pi / 2; cyl(f'cbolt{i}{s}{a}', (x + .036 * math.cos(t), yf + s * .001, z + .037 * math.sin(t)), .0024, .002, axis='Y', seg=8, bevel=0)
    tag('part', n0, 'casemate_plate')
    n0 = len(hs_lib.PARTS); d = Vector((CAS_FWD, s * .966, 0)).normalized()
    R = d.to_track_quat('X', 'Z').to_matrix(); base = Vector((x, yf + s * .003, z))
    cyl(f'cdrum{i}{s}', base + d * .005, .0145, .010, axis='X', seg=32, rot=R, bevel=.0008)
    cyl(f'cband{i}{s}', base + d * .019, .0155, .018, axis='X', seg=32, rot=R, bevel=.0008)
    for k in range(5): cyl(f'crib{i}{s}{k}', base + d * (.012 + k * .0035), .0162, .0012, axis='X', seg=32, rot=R, bevel=0)
    cyl(f'cnose{i}{s}', base + d * .0315, .0145, .007, axis='X', seg=32, r2=.0112, rot=R, bevel=.0006)
    for k in (-1, 1):
        off = Vector((-d.y, d.x, 0)).normalized() * (k * .0065)
        A3.gun(f'cgun{i}{s}{k}', base + d * .034 + off, d, .016, .0034)
    tag('part', n0, 'gun')

def drum_rack(nm, x, y, seat, L=.085, r=.0108, gap=.0225):
    """hand rebuild of the generated drum rack at its proportions (p_drumrack read as a reference): three drums side by side on
    saddles over a base frame, each drum with end rims and two bands"""
    zt = seat.top(x, y, L); n0 = len(hs_lib.PARTS)
    box(f'{nm}frame', (x, y, zt + .002), (L * .96, gap * 2 + r * 2.2, .004), bevel=.0008)
    for k in (-1, 1): box(f'{nm}rail{k}', (x, y + k * (gap + r * 1.1), zt + .005), (L * .96, .003, .003), bevel=.0004)
    for k in (-1, 0, 1):
        yy = y + k * gap; zc = zt + .004 + .003 + r
        for e in (-.3, .3): box(f'{nm}saddle{k}{e}', (x + e * L, yy, zt + .004 + .003), (.006, r * 1.5, .006), bevel=.0006)
        cyl(f'{nm}drum{k}', (x, yy, zc), r, L * .9, axis='X', seg=32, bevel=.0012)
    tag('part', n0, 'drum')
    n1 = len(hs_lib.PARTS)
    for k in (-1, 0, 1):
        yy = y + k * gap; zc = zt + .004 + .003 + r
        for e in (-.45, .45): cyl(f'{nm}rim{k}{e}', (x + e * L * .98, yy, zc), r * 1.07, .0025, axis='X', seg=32, bevel=0)
        for e in (-.18, .18): cyl(f'{nm}band{k}{e}', (x + e * L, yy, zc), r * 1.035, .003, axis='X', seg=32, bevel=0)
    tag('trim', n1, 'band')
    n2 = len(hs_lib.PARTS)
    for k in (-1, 0, 1):
        yy = y + k * gap; zc = zt + .004 + .003 + r; cyl(f'{nm}cap{k}', (x + L * .455, yy, zc), r * .7, .002, axis='X', seg=24, bevel=0)
    tag('dark', n2)

# Tower and mast heights are read off the concept through its fitted camera (a ruler up the tower axis, silhouette4.project), not
# tuned: the outline score alone would shorten any thin structure, and the concept's tower is tall.
TOWER = dict(x=.074, drum_top=.150, truss_top=.218, w0=.028, w1=.013)     # red drum to 0.15, lattice to 0.218, head 0.237, whips 0.25
ADRUM = (-.250, .052, .012)                                                 # aft drum pair: x, y, radius
MAST = dict(x=-.398, top=.132, dx=.055, dy=.020)                           # aft A-frame: apex 0.13, legs fore and aft

def antenna_tower(x, z0, zt, w0, w1):
    """the tall antenna tower forward: a tapered four-leg truss pylon from z0 to zt (open, ring frames and diagonals, no yards), a
    sensor ring with pods, a platform with dishes, a sensor head and an antenna array with whips on top"""
    import detail_lib as D
    n0 = len(hs_lib.PARTS); H = zt - z0
    for sx in (1, -1):
        for sy in (1, -1):
            D.tube(f'tleg{sx}{sy}', Vector((x + sx * w0, sy * w0, z0)), Vector((x + sx * w1, sy * w1, zt)), .0024, seg=8)
    fs = (.0, .30, .56, .80, 1.0)
    for k, f in enumerate(fs):
        w = w0 + (w1 - w0) * f; zz = z0 + H * f
        box(f'tframe{k}', (x, 0, zz), (2 * w + .004, 2 * w + .004, .003), bevel=.0004)
        if k < len(fs) - 1:
            g = fs[k + 1]; w2 = w0 + (w1 - w0) * g; zz2 = z0 + H * g
            for sx, sy in ((1, 1), (-1, -1)):
                D.tube(f'tdiag{k}{sx}', Vector((x + sx * w, -sy * w, zz)), Vector((x + sx * w2, sy * w2, zz2)), .0012, seg=6)
                D.tube(f'tdiagb{k}{sx}', Vector((x - sx * w, sx * w, zz)), Vector((x + sx * w2, sx * w2, zz2)), .0012, seg=6)
    cyl('tcore', (x, 0, z0 + H * .5), .006, H, seg=12, bevel=0)
    zr = z0 + H * .56
    cyl('tsring', (x, 0, zr), .026, .004, seg=32, bevel=.0008)
    for j, a in enumerate((30, 150, 270)):
        t = math.radians(a); box(f'tspod{j}', (x + .024 * math.cos(t), .024 * math.sin(t), zr + .006), (.007, .007, .009), bevel=.001)
    cyl('tplat', (x, 0, zt + .003), .030, .005, seg=32, bevel=.001)
    for j, dy in enumerate((.030, -.030)):
        R = Matrix.Rotation(math.radians(-60 if dy > 0 else 60), 3, 'X')
        cyl(f'tdish{j}', (x - .004, dy, zt + .010), .011, .004, seg=24, r2=.004, rot=R, bevel=.0008)
        box(f'tdishstrut{j}', (x - .004, dy * .5, zt + .010), (.004, abs(dy), .004), bevel=0)
    box('thead', (x, 0, zt + .013), (.020, .018, .016), bevel=.0015)
    box('tarray', (x, 0, zt + .023), (.008, .100, .004), bevel=.0006)      # antenna array: a flat boom carrying whips (not a yard)
    for k, (yy, hh) in enumerate(((-.046, .012), (-.024, .020), (0, .028), (.024, .020), (.046, .012))):
        cyl(f'twhip{k}', (x, yy, zt + .025 + hh / 2), .0014, hh, seg=8, bevel=0)
    tag('part', n0, 'antenna')

def aft_mast(x, z0, top, dx, dy):
    """the aft sensor mast (the concept's A-frame): four tapered legs, splayed fore and aft, to a sensor housing with a dish and an
    antenna array on top; braced by two ring frames; no rigging"""
    import detail_lib as D
    n0 = len(hs_lib.PARTS); H = top - z0; apex = Vector((x, 0, top))
    F = [(sx * dx, sy * dy) for sx in (1, -1) for sy in (1, -1)]
    for k, (ex, ey) in enumerate(F):
        D.tube(f'mleg{k}', Vector((x + ex, ey, z0)), apex + Vector((ex * .12, ey * .3, -.004)), .0030, seg=10)
        box(f'mfoot{k}', (x + ex, ey, z0 + .002), (.010, .010, .004), bevel=.0006)
    for k, f in enumerate((.35, .65)):
        q = [Vector((x + ex * (1 - f * .88), ey * (1 - f * .7), z0 + H * f)) for ex, ey in F]
        for i, j in ((0, 1), (1, 3), (3, 2), (2, 0)): D.tube(f'mring{k}{i}{j}', q[i], q[j], .0013, seg=6)
    box('mhouse', apex + Vector((0, 0, .002)), (.018, .016, .014), bevel=.0015)
    R = Matrix.Rotation(math.radians(-90), 3, 'Y')
    cyl('mdish', apex + Vector((.0105, 0, .004)), .011, .004, seg=24, r2=.004, rot=R, bevel=.0008)
    box('marray', apex + Vector((0, 0, .0105)), (.008, .040, .004), bevel=.0005)
    for k, (yy, hh) in enumerate(((-.016, .016), (0, .024), (.016, .016))):
        cyl(f'mwhip{k}', apex + Vector((0, yy, .0125 + hh / 2)), .0013, hh, seg=8, bevel=0)
    tag('part', n0, 'antenna')

def parts5(seat):
    Pp = hs_lib.PARTS; p = P
    # twin bow guns on the raised deck's front, aimed straight ahead
    gz = p['gl_z'][1] + p['bg_dz']; bx = .360 + p['bg_x']
    for s in (1, -1):
        n0 = len(Pp); zm = seat.top(bx, s * .030, .026)
        box(f'bowmount{s}', (bx, s * .030, (zm + gz + .018) / 2 - .001), (.026, .024, max(.010, gz + .018 - zm + .002)), bevel=.002)
        A3.gun(f'bowgun{s}', (bx + .008, s * .030, gz + .011), (1, 0, 0), .044, .0064)
        cyl(f'bowshroud{s}', (bx + .020, s * .030, gz + .011), .011, .022, axis='X', seg=24, bevel=.001); tag('part', n0, 'gun')
    for i, x in enumerate(CASEMATE_X):
        for s in (1, -1): casemate5(i, x, s, seat)
    # tower tier: the tall red tower drum (to the concept's 0.15), a railed platform ring on it, then the tall antenna tower
    tx, z2 = TOWER['x'], p['t2_z']; dt = max(.040, TOWER['drum_top'] - z2)
    n0 = len(Pp); cyl('tower', (tx, 0, z2 + dt / 2 - .002), .036, dt + .004, seg=40, bevel=.003); tag('part', n0, 'tower')
    n0 = len(Pp); cyl('towerband', (tx, 0, z2 + dt * .62), .0375, .006, seg=40, bevel=0); tag('trim', n0, 'band')
    n0 = len(Pp); cyl('bridge', (tx, 0, z2 + dt + .003), .042, .006, seg=40, bevel=.0015); tag('part', n0, 'bridge')
    n0 = len(Pp)
    for k in range(10):
        t = k * math.pi / 5; cyl(f'brail{k}', (tx + .040 * math.cos(t), .040 * math.sin(t), z2 + dt + .011), .0012, .010, seg=6, bevel=0)
    for k in range(4):
        t = k * math.pi / 2 + .3; box(f'bwin{k}', (tx + .0365 * math.cos(t), .0365 * math.sin(t), z2 + dt * .8), (.008, .008, .006), rot=(0, 0, t), bevel=.0005)
    tag('dark', n0)
    antenna_tower(tx, z2 + dt + .006, TOWER['truss_top'], TOWER['w0'], TOWER['w1'])
    # drums: fore pair on the raised deck, the drum racks on the sponsons, the mid pair, the aft pair
    for s in (1, -1): drum(f'fdrum{s}', .226, s * .044, p['fd_r'], .066, seat)
    for s in (1, -1): drum_rack(f'srack{s}', .094, s * .140, seat)
    for s in (1, -1): drum(f'mdrum{s}', -.052, s * .134, .017, .078, seat)
    for s in (1, -1): drum(f'adrum{s}', ADRUM[0], s * ADRUM[1], ADRUM[2], .062, seat)
    aft_mast(MAST['x'], seat.top(MAST['x'], 0), MAST['top'], MAST['dx'], MAST['dy'])
    xs = p['st_x'][1]
    for nm, (y, z, r) in (('main', (0, -.004, .026)), ('portb', (.044, -.004, .016)), ('stbdb', (-.044, -.004, .016))):
        n0 = len(Pp); B_engine((xs + .002, y, z), r, .036 if r > .02 else .026); tag('part', n0, 'engine')
        n0 = len(Pp); cyl(f'glow{nm}', (xs - .036 if r > .02 else xs - .027, y, z), r * .9, .002, axis='X', seg=32, bevel=0); tag('glow', n0)
    (xa, xb), (za, zb_), wo = p['cg_x'], p['cg_z'], p['cg_out']
    for s in (1, -1):
        n0 = len(Pp); wi = .090
        loft(f'cargo{s}', [rbox(xa, wi, wo - .008, za + .010, zb_ - .006, s), rbox(xa - .008, wi, wo, za, zb_, s),
                           rbox(xb + .008, wi, wo, za, zb_, s), rbox(xb, wi, wo - .008, za + .010, zb_ - .006, s)], bevel=.002)
        for xx in (xa - .024, xb + .024): box(f'cargoarm{s}{xx}', (xx, s * (wi + .004), zb_ + .004), (.016, .012, .010), bevel=.001)
        hz = zb_ - za - .008; cz = (za + zb_) / 2
        for k in range(7): box(f'cargorib{s}{k}', (xa - .012 - k * .012, s * (wo + .001), cz), (.005, .004, hz), bevel=0)
        for k in range(5): box(f'cargorib2{s}{k}', (xb + .060 - k * .010, s * (wo + .001), cz), (.004, .004, hz), bevel=0)
        box(f'cargohatch{s}', ((xa + xb) / 2 - .004, s * (wo + .001), cz + .003), (.020, .003, hz * .66), bevel=.0006)
        tag('part', n0, 'cargo')
    # twin ventral sensor pylons under the bow (B0 has two struts here; the concept's chin fin), each with a sensor pod at its foot
    for s in (1, -1):
        n0 = len(Pp); R = Matrix.Rotation(math.radians(s * -8), 3, 'X'); zr = knot(.35 + p['fin_dx'])['zb'] + .004
        bm = bmesh.new(); fx, fz = p['fin_dx'], p['fin_dz']; ff = p['fin_fwd']; fr = p['fin_root']; prof = [(.420 + fx - fr, zr), (.288 + fx - fr * .5, zr), (.304 + fx + ff * .5, -.238 - fz), (.416 + fx + ff, -.244 - fz)]
        vs = [[bm.verts.new(Vector((x, s * .026, zr)) + R @ Vector((0, k * .0045, z - zr))) for x, z in prof] for k in (-1, 1)]
        bm.faces.new(vs[0][::-1]); bm.faces.new(vs[1])
        for i in range(4): bm.faces.new((vs[0][i], vs[0][(i + 1) % 4], vs[1][(i + 1) % 4], vs[1][i]))
        bmesh.ops.recalc_face_normals(bm, faces=bm.faces); hs_lib._obj(f'vfin{s}', bm, .0015)
        tip = Vector((.366 + fx, s * .026, zr)) + R @ Vector((0, 0, -.248 - fz - zr))
        cyl(f'vpod{s}', tip + Vector((ff * .7, 0, 0)), .010, .110 + ff * .6, axis='X', seg=24, r2=.007, bevel=.001)
        tag('part', n0, 'fin')
    for s in (1, -1):
        n0 = len(Pp); xv = -.300; zt = knot(xv)['zb']
        cyl(f'vthr{s}', (xv, s * .050, zt - .012), .011, .046, axis='X', seg=24, bevel=.002)
        box(f'vthrpylon{s}', (xv, s * .050, zt - .003), (.030, .008, .008), bevel=.001); tag('part', n0, 'engine')
    # detail that is not plating: sponson vents, module hatches, deck hatches and vents, aft grating, pipes along the aft body
    import detail_lib as D
    n0 = len(Pp)
    for s_ in (1, -1):
        hs_lib.vents(f'spvent{s_}', (.120, s_ * (seat.flank(.120, .004, s_) + .001), .004), 6, .003, .010, .008)
        for xx in (-.020, -.070): box(f'mhatch{s_}{xx}', (xx, s_ * (seat.flank(xx, -.074, s_) + .0005), -.074), (.026, .002, .030), bevel=.0006)
        zt = seat.top(.300, s_ * .092)
        box(f'dhatch{s_}', (.300, s_ * .092, zt + .005), (.040, .012, .010), bevel=.0012)
        for k in range(4): box(f'dhslat{s_}{k}', (.288 + k * .008, s_ * .092, zt + .0105), (.004, .010, .0015), bevel=0)
        zt = seat.top(.440, s_ * .044)
        box(f'dvent{s_}', (.440, s_ * .044, zt + .003), (.024, .016, .006), bevel=.0008)
        zt = seat.top(-.320, s_ * .036)
        box(f'agrate{s_}', (-.320, s_ * .036, zt + .002), (.050, .026, .004), bevel=.0006)
    for yy in (-.058, .058): D.tube(f'aftpipe{yy}', Vector((-.140, yy, P['ab_z'] - .012)), Vector((-.410, yy, P['ab_z'] - .012)), .0032)
    zt = seat.top(.268, .046)
    box('ghatch', (.268, .046, zt + .006), (.050, .030, .012), bevel=.0015)
    for k in range(3): box(f'ghslat{k}', (.254 + k * .014, .046, zt + .0125), (.010, .024, .002), bevel=0)
    tag('part', n0, 'detail')

def B_engine(c, r, L):
    import barge_shapes as B
    B.engine_bell(c, r, L, axis_dir=Vector((-1, 0, 0)))

def build_geometry(hero=(), G=None):
    """structure, plates, parts. Returns (blocks, plates, hard parts, generated parts (none), notes, proxies (none))"""
    bpy.ops.wm.read_factory_settings(use_empty=True); hs_lib.PARTS.clear(); GUNS.clear(); C.set_break(**BREAK)
    S = structure5(); Pl = plates5(S); seat = Seat(S + Pl); notes = []
    parts5(seat)
    for o in hs_lib.PARTS:
        if 'role' not in o: o['role'] = 'part'
        for m in list(o.modifiers):
            bpy.context.view_layer.objects.active = o; o.select_set(True); bpy.ops.object.modifier_apply(modifier=m.name); o.select_set(False)
    return S, Pl, list(hs_lib.PARTS), [], notes, []

def load_tuned(path=os.path.join(HERE, 'tune5_P.json')):
    """the tuned numbers (tune5.py writes them; kept beside the script so every build reads the same shape)"""
    if not os.path.exists(path): return False
    d = json.load(open(path)); global HK
    HK = [tuple(k) for k in d['HK']]
    for k, v in d['P'].items(): P[k] = tuple(v) if isinstance(v, list) else v
    return True

TUNED = False if os.environ.get('R209_NO_TUNED') else load_tuned()

if __name__ == '__main__':
    a = sys.argv[sys.argv.index('--') + 1:] if '--' in sys.argv else sys.argv[1:]
    out = a[0]; cell = a[1] if len(a) > 1 else 'A5s'; t0 = time.time()
    S, Pl, hard, gen, notes, prox = build_geometry()
    if cell == 'A5s':
        for o in hard: bpy.data.objects.remove(o)
    rep = C.report(S + Pl + ([] if cell == 'A5s' else hard))
    os.makedirs(out, exist_ok=True); bpy.ops.wm.save_as_mainfile(filepath=os.path.join(out, f'{cell}.blend'))
    meta = dict(cell=cell, tuned=TUNED, plates=len(Pl), plate_crossing=plate_crossing(Pl), plate_triangles=sum(C.tris(o) for o in Pl),
                block_triangles=sum(C.tris(o) for o in S), seconds=round(time.time() - t0, 1), **rep)
    print('[209]', json.dumps(meta), flush=True)
