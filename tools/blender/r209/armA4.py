# Issue 209 round 4: silhouette first (Ryan, Nov 9 07:08 CST, R145: "the actual ship itself doesn't look like the concept. It looks
# like a basic submarine instead"). Rounds 1 to 3 built a rounded tube (rolled shoulders, domed nose, a deck that sloped down to the
# nose) with one small tower and parts stuck on. Round 4 rebuilds the base blocks to the concept's outline and cross-section:
#   - a wide slab hull: a flat deck with a sharp edge running level to the bow, slab sides, a straight tuck in to an armoured belly;
#   - a raked, overhanging bow: the deck edge runs furthest forward, the side leans back below it, the tuck further back still;
#     the bow is round in plan (the concept's wide rounded front), blunt at the nose, never a boat stem;
#   - a stern block, and the shallower aft hull of rounds 2 and 3 (B0 and the concept agree on it);
#   - a stepped superstructure running most of the deck: the raised forward deck (glacis), the deckhouse tier, the tower tier, the
#     red hump behind the tower, the long dark aft body with its rounded top, the stern block;
#   - a tall antenna tower forward (a tapered pylon with sensor rings, dishes and whips: an antenna array, not a lattice mast);
#   - low, heavy side gun pods (bigger casemate plates and balls than round 3).
# Heights and stations are read off the concept through its fitted camera (silhouette4.py) and B0's sections (sil_dump.py), then
# tuned on the silhouette score. Round 3's plating (armour(), ray cast, lapped, chamfered) and paint (paint3.py) carry over unchanged.
# The hybrid (Hy4) keeps Hy3's generated casemates and drum racks; its bow guns are hand-built (Ryan's round 3 pick).
# usage: imported by bakeAb4.py; standalone: blender -b -P armA4.py -- OUT_DIR [CELL]   (structure + parts, no bake, no paint)
import os, sys, math, json, time
HERE = os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0, HERE)
import common as C
import bpy, bmesh
import numpy as np
from mathutils import Vector, Matrix
import hs_lib
from hs_lib import loft, box, cyl
import armA2 as A2
import armA3 as A3
from armA3 import rpoly, armour, Seat, drum, tag, plate_crossing

BREAK = A3.BREAK          # same break lines as rounds 2 and 3: bow | midship (split lengthwise at z -0.045) | aft body
GUNS = A3.GUNS            # drum() and casemate helpers record guns here; the audit reads it
HERO_K = A3.HERO_K
HERO_SLOTS = ('casemate', 'drumrack')    # Hy4: generated casemates and drum racks; the bow guns stay hand-built
PROXY = dict(casemate=('cplate', 'cring', 'cball', 'cgun', 'cbolt', 'clip'), drumrack=('sdrum',))

# ------------------------------------------------------------------------------------------------ the hull's shape numbers
# Ship frame: x to the bow, y to port, z up, length 1.0. Every number here is a design input, read off the concept (fitted camera) and
# B0's sections, then tuned on the silhouette score (silhouette4.py). The sweep in tune4.py moves only these.
P = dict(
    W=.124,          # deck half-width amidships (B0 .128 to .143 at deck height)
    xs=.255,         # full width from here aft; ahead of it the plan rounds in to the nose
    xn=.504,         # nose, at the deck edge (the overhang's front)
    nose_w=.020,     # blunt nose: half-width of the flat bow face at the deck
    pw=2.4,          # plan roundness (2 = ellipse; higher = fuller, blunter front)
    zd=.004,         # deck height amidships
    zd_nose=-.01,    # deck height at the nose (a slight sheer, still one flat plane)
    zc=-.104,        # chine: bottom of the slab side
    flare=.003,      # the slab side stands this far outside the deck edge at the chine
    over_c=.016,     # overhang: the chine line runs this far behind the deck edge at the bow
    over_b=.030,     # and the belly line this far behind
    wb=.094,         # belly half-width (B0 .09 to .10)
    zb=-.152,        # belly
    zb_nose=-.152,   # belly at its front end (a flat armoured belly; the silhouette tune left it level)
    x_aft=-.112,     # the forward hull's deep section ends here; the shallower aft hull behind it
    aft_zc=-.05, aft_zb=-.06, aft_wb=.086,
    # superstructure
    gl_x=(.408, .388, .130), gl_w=.076, gl_z=(.042, .046, .05),     # raised forward deck: front lip, front top, back
    t1_x=(.176, -.100), t1_w=.082, t1_z=.078,                        # deckhouse tier
    t2_x=(.128, .000), t2_w=.058, t2_z=.090,                         # tower tier
    hump_x=(-.030, -.165), hump_w=.064, hump_z=.073,                 # the red hump behind the tower
    ab_x=(-.110, -.442), ab_w=.072, ab_z=.05, ab_r=.024,            # long dark aft body, rounded top corners
    st_x=(-.436, -.500), st_w=.08, st_z=.062,                       # stern block
    sp_zb=-.120,     # sponson and module bottoms (round 3: -0.136; the concept's dark side block ends higher)
    rail_zb=-.11, cargo_z=(-.094, -.004),
)

def plan(x):
    """deck-edge half-width at station x (the concept's wide rounded bow in plan)"""
    p = P
    if x <= p['xs']:
        if x >= 0: return p['W']
        if x > p['x_aft']: return p['W'] - .004 * (x / p['x_aft'])
        return p['W'] - .004 - (p['W'] - .004 - .096) * min(1, (x - p['x_aft']) / (-.5 - p['x_aft']))
    t = min(1.0, (x - p['xs']) / (p['xn'] - p['xs']))
    return p['nose_w'] + (p['W'] - p['nose_w']) * max(0.0, 1 - t ** p['pw']) ** .5

def zdeck(x):
    p = P; t = max(0.0, (x - .20) / (p['xn'] - .20)); return p['zd'] + (p['zd_nose'] - p['zd']) * t

def section(x):
    """the hull section: flat deck to a sharp edge, slab side, straight tuck to the belly; fore and aft hulls differ in depth"""
    p = P; wd = plan(x); zt = zdeck(x)
    if x > p['x_aft']:
        wc = max(.012, plan(x + p['over_c']) if x + p['over_c'] < p['xn'] else p['nose_w'] * .6) + p['flare']
        wbx = plan(x + p['over_b']) * .74 if x + p['over_b'] < p['xn'] else p['nose_w'] * .3
        wb = max(.010, min(p['wb'], wbx)); tb = max(0.0, (x - .30) / (p['xn'] - .30)); zb = p['zb'] + (p['zb_nose'] - p['zb']) * tb ** 1.6
        zc = p['zc']
    else:
        wc = wd + p['flare']; zc = p['aft_zc']; wb = p['aft_wb'] - (.004 if x < -.35 else 0); zb = p['aft_zb']
    half = [(wd, zt), (wc, zc), (wb, zb)]
    return (x, [(0, zt)] + half + [(0, zb)] + [(-y, z) for y, z in reversed(half)])

def stations():
    p = P; xs = [-.500, -.470, -.400, -.300, -.200, -.130, p['x_aft'] - .004, p['x_aft'] + .004, -.090, .000, .100, .200, p['xs']]
    xs += list(np.linspace(p['xs'], p['xn'], 16)[1:])
    return sorted(set(round(x, 5) for x in xs))

def flatsec(x, w, zb, zt, r=.0035, rb=.002):
    """a centred superstructure section: vertical sides, sharp (lightly broken) corners"""
    return A3.rtrap(x, w, w, zb, zt, r, rb)

def rbox(x, wi, wo, zb, zt, s, r=.004):
    return A3.rside(x, wi, wo, zb, zt, r, s, .002)

def hull_obj(o, kind):
    o['role'] = 'hull'; o['kind'] = kind; hs_lib.PARTS.remove(o); return o

def structure4():
    p = P; H = []
    o = loft('core', [section(x) for x in stations()], bevel=.0025); H.append(hull_obj(o, 'core'))
    (gx0, gx1, gx2), (gz0, gz1, gz2), gw = p['gl_x'], p['gl_z'], p['gl_w']
    o = loft('glacis', [flatsec(gx0, gw - .010, p['zd'] - .006, gz0), flatsec(gx1, gw, p['zd'] - .006, gz1), flatsec(gx2, gw, p['zd'] - .006, gz2)],
             bevel=.002); H.append(hull_obj(o, 'glacis'))
    for s in (1, -1):
        zs = P['sp_zb']
        o = loft(f'sponson{s}', [rbox(.178, .10, .150, zs + .014, .032, s), rbox(.170, .10, .174, zs + .004, .044, s),
                                 rbox(.020, .10, .178, zs, .046, s), rbox(.012, .10, .168, zs + .010, .036, s)], bevel=.002)
        H.append(hull_obj(o, 'sponson'))
        o = loft(f'module{s}', [rbox(.006, .10, .160, zs + .012, .004, s), rbox(.000, .10, .168, zs + .010, .010, s),
                                rbox(-.098, .10, .168, zs + .014, .010, s), rbox(-.106, .10, .156, zs + .024, .002, s)], bevel=.002)
        H.append(hull_obj(o, 'module'))
        o = loft(f'rail{s}', [rbox(-.100, .040, .080, p['rail_zb'] + .010, p['aft_zb'] + .006, s), rbox(-.114, .038, .084, p['rail_zb'], p['aft_zb'] + .006, s),
                              rbox(-.330, .038, .084, p['rail_zb'], p['aft_zb'] + .006, s), rbox(-.346, .040, .080, p['rail_zb'] + .010, p['aft_zb'] + .006, s)],
                 bevel=.002)
        H.append(hull_obj(o, 'rail'))
    (a, b), w, z = p['t1_x'], p['t1_w'], p['t1_z']
    o = loft('tier1', [flatsec(a, w - .010, .026, z - .010), flatsec(a - .010, w, .026, z), flatsec(b + .010, w, .026, z), flatsec(b, w - .010, .026, z - .010)],
             bevel=.002); H.append(hull_obj(o, 'tier'))
    (a, b), w, z = p['t2_x'], p['t2_w'], p['t2_z']
    o = loft('tier2', [flatsec(a, w - .006, p['t1_z'] - .004, z - .008), flatsec(a - .008, w, p['t1_z'] - .004, z), flatsec(b + .008, w, p['t1_z'] - .004, z),
                       flatsec(b, w - .006, p['t1_z'] - .004, z - .008)], bevel=.002); H.append(hull_obj(o, 'tier'))
    (a, b), w, z = p['hump_x'], p['hump_w'], p['hump_z']
    o = loft('hump', [A3.rtrap(a, w - .016, w - .020, .026, z - .016, .018, .002), A3.rtrap(a - .018, w, w - .004, .026, z, .028, .002),
                      A3.rtrap(b + .016, w, w - .004, .026, z, .028, .002), A3.rtrap(b, w - .012, w - .016, .026, z - .014, .018, .002)], bevel=.002)
    H.append(hull_obj(o, 'tier'))
    (a, b), w, z, r = p['ab_x'], p['ab_w'], p['ab_z'], p['ab_r']
    o = loft('aftbody', [A3.rtrap(a, w - .012, w - .014, .026, z - .010, r * .8, .002), A3.rtrap(a - .012, w, w, .026, z, r, .002),
                         A3.rtrap(b + .004, w, w, .026, z, r, .002), A3.rtrap(b, w - .004, w - .004, .026, z - .002, r, .002)], bevel=.002)
    H.append(hull_obj(o, 'spine'))
    (a, b), w, z = p['st_x'], p['st_w'], p['st_z']
    o = loft('sternblock', [flatsec(a, w - .010, p['aft_zb'] + .004, z - .010), flatsec(a - .010, w, p['aft_zb'] + .004, z),
                            flatsec(b, w, p['aft_zb'] + .004, z)], bevel=.002); H.append(hull_obj(o, 'stern'))
    for o in H:
        bpy.context.view_layer.objects.active = o; o.select_set(True)
        for m in list(o.modifiers): bpy.ops.object.modifier_apply(modifier=m.name)
        o.select_set(False)
    return H

# ------------------------------------------------------------------------------------------------ layered armour on the slab hull
def plates4(S):
    """big plates in staggered belts, lapped (alternating standoff); none crosses a break line (x .178, x -.125, z -.045 between them)"""
    by = {}
    for o in S: by.setdefault(o['kind'], []).append(o)
    B = {k: C.bvh(v) for k, v in by.items()}; Pl = []; lo, hi = .0025, .0045
    p = P; zt = p['zd'] - .006
    for s in (1, -1):
        t = 'p' if s > 0 else 's'
        # bow slab side, two belts, staggered
        for k, (x0, x1) in enumerate(((.190, .262), (.254, .330), (.322, .398), (.390, .452))):
            Pl.append(armour(f'plU{t}{k}', B['core'], 'side', (x0, x1), (-.032, zt), s, off=hi if k % 2 else lo))
        for k, (x0, x1) in enumerate(((.190, .292), (.284, .372), (.364, .436))):
            Pl.append(armour(f'plL{t}{k}', B['core'], 'side', (x0, x1), (p['zc'] + .006, -.026), s, off=lo if k % 2 else hi))
        # bow tuck (the belly corner), rays from the hull's axis
        for k, (x0, x1) in enumerate(((.190, .292), (.284, .380))):
            Pl.append(armour(f'plT{t}{k}', B['core'], 'radial', (x0, x1), (-40, -3), s, az=-.105, off=hi if k % 2 else lo))
        # bow deck strips beside the raised deck, and the deck ahead of it
        for k, (x0, x1) in enumerate(((.190, .292), (.284, .384))):
            Pl.append(armour(f'pld{t}{k}', B['core'], 'top', (x0, x1), tuple(sorted((s * (p['gl_w'] + .006), s * (p['W'] - .010)))), s, off=lo if k % 2 else hi))
        Pl.append(armour(f'pldn{t}', B['core'], 'top', (.414, .470), tuple(sorted((s * .004, s * .070))), s, off=lo))
        # raised deck top, split down the centreline
        Pl.append(armour(f'plg{t}', B['glacis'], 'top', (.186, .380), tuple(sorted((s * .004, s * (p['gl_w'] - .008)))), s, off=lo))
        # sponsons: upper and lower belts split at the longitudinal break line, staggered
        for k, (x0, x1) in enumerate(((.024, .100), (.092, .168))):
            Pl.append(armour(f'plsu{t}{k}', B['sponson'], 'side', (x0, x1), (-.040, .038), s, off=hi if k % 2 else lo))
        for k, (x0, x1) in enumerate(((.024, .124), (.116, .168))):
            Pl.append(armour(f'plsl{t}{k}', B['sponson'], 'side', (x0, x1), (p['sp_zb'] + .008, -.050), s, off=lo if k % 2 else hi))
        Pl.append(armour(f'plmu{t}', B['module'], 'side', (-.094, -.006), (-.041, .004), s, off=lo))
        for k, (x0, x1) in enumerate(((-.094, -.046), (-.052, -.006))):
            Pl.append(armour(f'plml{t}{k}', B['module'], 'side', (x0, x1), (p['sp_zb'] + .016, -.049), s, off=hi if k % 2 else lo))
        # deckhouse tier, aft body and stern block sides
        for k, (x0, x1) in enumerate(((-.090, .040), (.032, .160))):
            Pl.append(armour(f'plt{t}{k}', B['tier'], 'side', (x0, x1), (.032, p['t1_z'] - .006), s, off=lo if k % 2 else hi))
        for k, (x0, x1) in enumerate(((-.430, -.350), (-.358, -.272), (-.280, -.196), (-.204, -.132))):
            Pl.append(armour(f'pla{t}{k}', B['spine'], 'side', (x0, x1), (.032, p['ab_z'] - .016), s, off=hi if k % 2 else lo))
        Pl.append(armour(f'plst{t}', B['stern'], 'side', (-.494, -.448), (-.064, p['st_z'] - .006), s, off=lo))
        # aft hull side behind the cargo blocks
        for k, (x0, x1) in enumerate(((-.432, -.360), (-.366, -.304))):
            Pl.append(armour(f'plh{t}{k}', B['core'], 'side', (x0, x1), (p['aft_zc'] + .006, .020), s, off=lo if k % 2 else hi))
    return Pl

# ------------------------------------------------------------------------------------------------ parts, seated by ray cast
def casemate4(i, x, s, seat, z=-.040):
    """a low, heavy side gun pod: octagonal armour plate, ring, big ball, twin barrels aimed forward and out"""
    y = s * (seat.flank(x, z, s) + .001)
    n0 = len(hs_lib.PARTS); cyl(f'cplate{i}{s}', (x, y, z), .043, .009, axis='Y', seg=8, bevel=.0018); tag('part', n0, 'casemate_plate')
    n0 = len(hs_lib.PARTS)
    cyl(f'cring{i}{s}', (x, y + s * .007, z), .030, .007, axis='Y', seg=24, bevel=.001)
    cyl(f'cball{i}{s}', (x, y + s * .016, z), .022, .018, axis='Y', seg=24, bevel=.005)
    d = Vector((.55, s * .83, .05))
    for k in (-1, 1): A3.gun(f'cgun{i}{s}{k}', Vector((x, y + s * .020, z + k * .008)), d, .066, .0055)
    for a in range(8):
        t = (a + .5) * math.pi / 4; box(f'cbolt{i}{s}{a}', (x + .037 * math.cos(t), y + s * .006, z + .037 * math.sin(t)), (.005, .003, .005), bevel=.0005)
    box(f'clip{i}{s}', (x, y + s * .012, z + .029), (.048, .012, .005), bevel=.0008)
    tag('part', n0, 'gun')

CASEMATE_X = (.356, .246)

def antenna_tower(x, z0):
    """the tall antenna tower forward: tapered octagonal pylon, two sensor rings with dishes and pods, sensor head and whips on top
    (the concept's lattice mast as an antenna array; no crossbars, no yards)"""
    import barge_shapes as B
    n0 = len(hs_lib.PARTS)
    cyl('pylon', (x, 0, z0 + .032), .016, .064, seg=8, r2=.010, bevel=.0012)
    for k, (zz, r) in enumerate(((z0 + .022, .030), (z0 + .058, .024))):
        cyl(f'sring{k}', (x, 0, zz), r, .005, seg=24, bevel=.0008)
        for j, a in enumerate((50, 170, 290)):
            t = math.radians(a + 40 * k); px, py = x + r * .85 * math.cos(t), r * .85 * math.sin(t)
            box(f'spod{k}{j}', (px, py, zz + .007), (.008, .008, .010), bevel=.001)
    for j, (dy, dz, rr) in enumerate(((.034, .030, .016), (-.030, .052, .013))):
        R = Matrix.Rotation(math.radians(-55 if dy > 0 else 55), 3, 'X')
        cyl(f'tdish{j}', (x + .006, dy, z0 + dz), rr, .005, seg=24, r2=rr * .35, rot=R, bevel=.001)
        box(f'tdishstrut{j}', (x + .006, dy * .55, z0 + dz), (.004, abs(dy) * .8, .004), bevel=0)
    B.antenna_array(x, 0, z0 + .062, h=.034)
    tag('part', n0, 'antenna')

def parts4(seat, hero=()):
    """round 3's hand parts, re-seated on the round 4 blocks, plus the antenna tower, bigger gun pods and a few deck fittings"""
    Pp = hs_lib.PARTS; p = P
    # twin bow guns on the raised deck's front, aimed straight ahead (the concept's muzzles sit at about x 0.42)
    gz = p['gl_z'][1]
    for s in (1, -1):
        n0 = len(Pp)
        box(f'bowmount{s}', (.346, s * .032, gz + .009), (.026, .024, .018), bevel=.002)
        A3.gun(f'bowgun{s}', (.354, s * .032, gz + .011), (1, 0, 0), .050, .0064)
        cyl(f'bowshroud{s}', (.366, s * .032, gz + .011), .011, .022, axis='X', seg=20, bevel=.001); tag('part', n0, 'gun')
    for i, x in enumerate(CASEMATE_X):
        for s in (1, -1): casemate4(i, x, s, seat)
    # tower tier: the red tower drum, the bridge, then the antenna tower
    tx, z2 = .068, p['t2_z']
    n0 = len(Pp); cyl('tower', (tx, 0, z2 + .028), .040, .056, seg=32, bevel=.003); tag('part', n0, 'tower')
    n0 = len(Pp); cyl('towerband', (tx, 0, z2 + .046), .0415, .007, seg=32, bevel=0); tag('trim', n0, 'band')
    n0 = len(Pp); box('bridge', (tx + .008, 0, z2 + .067), (.062, .074, .022), bevel=.003); tag('part', n0, 'bridge')
    n0 = len(Pp); box('bridgeglass', (tx + .040, 0, z2 + .069), (.004, .060, .007), bevel=.0005); tag('dark', n0)
    antenna_tower(tx - .004, z2 + .078)
    # drums: fore pair on the raised deck, the sponson racks, the mid pair, the aft pair on the aft body
    for s in (1, -1): drum(f'fdrum{s}', .214, s * .048, .017, .066, seat)
    for s in (1, -1):
        if 'drumrack' not in hero or True:   # hand racks always built; in the hybrid they become hidden proxies (far LODs)
            for k, yy in enumerate((.124, .156)): drum(f'sdrum{s}{k}', .092, s * yy, .0145, .085, seat)
        drum(f'mdrum{s}', -.052, s * .134, .018, .080, seat)
    for s in (1, -1): drum(f'adrum{s}', -.290, s * .058, .015, .064, seat)
    import barge_shapes as B
    n0 = len(Pp); B.radiator_pair(-.396, 0, p['ab_z'], n=2, L=.074, H=.064); tag('part', n0, 'radiator')
    for nm, (y, z, r) in (('main', (0, -.013, .030)), ('portb', (.058, -.010, .020)), ('stbdb', (-.058, -.010, .020)),
                          ('upp', (.044, .050, .013)), ('ups', (-.044, .050, .013))):
        n0 = len(Pp); B.engine_bell((-.492 if z < .03 else -.490, y, z), r, .040 if r > .015 else .026, axis_dir=Vector((-1, 0, 0))); tag('part', n0, 'engine')
        n0 = len(Pp); cyl(f'glow{nm}', (-.522 if z < .03 else -.514, y, z), r * .9, .002, axis='X', seg=28, bevel=0); tag('glow', n0)
    za, zb_ = p['cargo_z']
    for s in (1, -1):
        n0 = len(Pp); loft(f'cargo{s}', [rbox(-.146, .100, .150, za + .012, zb_ - .006, s), rbox(-.154, .100, .158, za, zb_, s),
                                          rbox(-.292, .100, .158, za, zb_, s), rbox(-.300, .100, .150, za + .012, zb_ - .006, s)], bevel=.002)
        for xx in (-.170, -.275): box(f'cargoarm{s}{xx}', (xx, s * .104, zb_ + .004), (.016, .012, .016), bevel=.001)
        hz = zb_ - za - .006; cz = (za + zb_) / 2
        for k in range(7): box(f'cargorib{s}{k}', (-.160 - k * .012, s * .159, cz), (.005, .004, hz), bevel=0)
        for k in range(5): box(f'cargorib2{s}{k}', (-.244 - k * .010, s * .159, cz), (.004, .004, hz), bevel=0)
        box(f'cargohatch{s}', (-.236, s * .159, cz + .004), (.020, .003, hz * .66), bevel=.0006)
        tag('part', n0, 'cargo')
    # twin ventral fins with sensor pods under the bow (round 1's space version of the concept's chin fin), a little further forward
    for s in (1, -1):
        n0 = len(Pp); R = Matrix.Rotation(math.radians(s * -18), 3, 'X')
        bm = bmesh.new(); prof = [(.416, -.150), (.300, -.160), (.312, -.236), (.376, -.240)]
        vs = [[bm.verts.new(Vector((x, s * .040, 0)) + R @ Vector((0, k * .005, z + .150)) + Vector((0, 0, -.150))) for x, z in prof] for k in (-1, 1)]
        bm.faces.new(vs[0][::-1]); bm.faces.new(vs[1])
        for i in range(4): bm.faces.new((vs[0][i], vs[0][(i + 1) % 4], vs[1][(i + 1) % 4], vs[1][i]))
        bmesh.ops.recalc_face_normals(bm, faces=bm.faces); hs_lib._obj(f'vfin{s}', bm, .0015)
        tip = Vector((.344, s * .040, 0)) + R @ Vector((0, 0, -.086)) + Vector((0, 0, -.150))
        cyl(f'vpod{s}', tip, .009, .060, axis='X', seg=16, r2=.007, bevel=.001)
        tag('part', n0, 'fin')
    for s in (1, -1):
        n0 = len(Pp); zt = p['rail_zb'] - .010
        cyl(f'vthr{s}', (-.300, s * .060, zt), .012, .050, axis='X', seg=20, bevel=.002)
        box(f'vthrpylon{s}', (-.300, s * .060, zt + .008), (.030, .008, .008), bevel=.001); tag('part', n0, 'engine')
    # detail that is not plating: sponson vents, module hatches, rail plates, aft body pipes, and the deck fittings round 3 lacked
    import detail_lib as D
    n0 = len(Pp)
    for s_ in (1, -1):
        hs_lib.vents(f'spvent{s_}', (.120, s_ * (seat.flank(.120, .010, s_) + .001), .010), 6, .003, .010, .008)
        for xx in (-.020, -.070): box(f'mhatch{s_}{xx}', (xx, s_ * (seat.flank(xx, -.078, s_) + .0005), -.078), (.026, .002, .030), bevel=.0006)
        for xx in (-.200, -.260): box(f'railplate{s_}{xx}', (xx, s_ * .060, p['rail_zb'] - .0005), (.040, .040, .002), bevel=.0005)
        # bow deck: an armoured hatch block and a vent box each side of the raised deck (the concept's hatches beside it)
        zt = seat.top(.300, s_ * .112)
        box(f'dhatch{s_}', (.300, s_ * .112, zt + .005), (.040, .022, .010), bevel=.0012)
        for k in range(4): box(f'dhslat{s_}{k}', (.288 + k * .008, s_ * .112, zt + .0105), (.004, .018, .0015), bevel=0)
        zt = seat.top(.440, s_ * .050)
        box(f'dvent{s_}', (.440, s_ * .050, zt + .003), (.024, .016, .006), bevel=.0008)
        # aft body: a raised deck grating platform near the stern (the concept's) and pipes along the top
        zt = seat.top(-.250, s_ * .040)
        box(f'agrate{s_}', (-.250, s_ * .040, zt + .002), (.060, .030, .004), bevel=.0006)
    for yy in (-.064, .064): D.tube(f'aftpipe{yy}', Vector((-.140, yy, P['ab_z'] - .012)), Vector((-.420, yy, P['ab_z'] - .012)), .0032)
    # the raised deck's front hatch (the concept's dark hatch block on the forward deck, port of centre)
    zt = seat.top(.260, .050)
    box('ghatch', (.260, .050, zt + .006), (.050, .034, .012), bevel=.0015)
    for k in range(3): box(f'ghslat{k}', (.246 + k * .014, .050, zt + .0125), (.010, .028, .002), bevel=0)
    tag('part', n0, 'detail')

def hero_parts4(G, seat, notes, slots):
    """Hy4: Hy3's generated casemates and drum racks (TRELLIS.2, round 1), fitted to the round 4 slots at Hy3's budgets"""
    import armB as AB
    Pg = lambda nm: os.path.join(G, f'p_{nm}.glb'); made = []
    if 'casemate' in slots:
        for i, x in enumerate(CASEMATE_X):
            for s in (1, -1):
                wc = seat.flank(x, -.040, s)
                o = AB.gen(Pg('casemate'), f'hcasemate_{i}{"p" if s > 0 else "s"}', HERO_K['casemate'], (x - .044, wc - .004, -.084), (x + .044, wc + .064, .004), 'part', notes)
                if s < 0: AB.mirror_y(o)
                o['kind'] = 'gen_casemate'; made.append(o)
    if 'drumrack' in slots:
        for nm, y in (('hdrums_sp', .139), ('hdrums_ss', -.139)):
            zt = seat.top(.092, y, .085)
            o = AB.gen(Pg('drumrack'), nm, HERO_K['drumrack'], (.092 - .0425, y - .033, zt - .003), (.092 + .0425, y + .033, zt + .030), 'part', notes)
            o['kind'] = 'gen_drumrack'; made.append(o)
    return made

def build_geometry(hero=(), G=None):
    """structure, plates, parts (and hero parts). Returns (blocks, plates, hard parts, generated parts, notes, proxies)"""
    bpy.ops.wm.read_factory_settings(use_empty=True); hs_lib.PARTS.clear(); GUNS.clear(); C.set_break(**BREAK)
    S = structure4(); Pl = plates4(S); seat = Seat(S + Pl); notes = []
    parts4(seat, ())
    pref = tuple(q for h in hero for q in PROXY[h])
    if hero:   # the hand parts in the hero slots stay as hidden proxies: the hybrid's far LODs use them instead of the generated parts
        for o in hs_lib.PARTS:
            if o.name.startswith(pref): o['proxy'] = 1; o.hide_render = True
        GUNS[:] = [g for g in GUNS if not g[0].startswith(pref)]
    gen = hero_parts4(G, seat, notes, hero) if hero else []
    for o in hs_lib.PARTS:
        if 'role' not in o: o['role'] = 'part'
        if o.get('proxy'): o.hide_render = True
        for m in list(o.modifiers):
            bpy.context.view_layer.objects.active = o; o.select_set(True); bpy.ops.object.modifier_apply(modifier=m.name); o.select_set(False)
    return S, Pl, [o for o in hs_lib.PARTS if not o.get('proxy')], gen, notes, [o for o in hs_lib.PARTS if o.get('proxy')]

if __name__ == '__main__':
    a = sys.argv[sys.argv.index('--') + 1:] if '--' in sys.argv else sys.argv[1:]
    out = a[0]; cell = a[1] if len(a) > 1 else 'A4s'; t0 = time.time()
    S, Pl, hard, gen, notes, prox = build_geometry()
    if cell == 'A4s':
        for o in hard: bpy.data.objects.remove(o)
    rep = C.report(S + Pl + ([] if cell == 'A4s' else hard))
    os.makedirs(out, exist_ok=True); bpy.ops.wm.save_as_mainfile(filepath=os.path.join(out, f'{cell}.blend'))
    meta = dict(cell=cell, plates=len(Pl), plate_crossing=plate_crossing(Pl), plate_triangles=sum(C.tris(o) for o in Pl),
                block_triangles=sum(C.tris(o) for o in S), seconds=round(time.time() - t0, 1), **rep)
    print('[209]', json.dumps(meta), flush=True)
