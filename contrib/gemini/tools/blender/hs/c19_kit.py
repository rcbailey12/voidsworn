# Pyre-Barge (C19_51) hybrid: the Pixal3D hull keeps its shape and paint; its small parts (rocket rack, funnels, mast, guns, bridge top)
# which the AI blurs together, are cut out and rebuilt as clean bevelled parts placed where the concept's side and front views specify.
# Frame: the Pixal3D GLB as Blender imports it for a side-first run: x aft (bow at -x), z up, y lateral; 1 unit = 1m.
# 1024 rig views (mvC2/C19_51_left.png and _front.png). Writes OUT_cut.glb (hull minus the cut parts) and OUT_kit.glb (rebuilt kit parts).
# usage: blender -b -P c19_kit.py -- hull.glb out_prefix
import sys, os, math, statistics, bpy, bmesh
import numpy as _np
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from hs_lib import *
import hs_lib
from mathutils import Vector, Matrix
from mathutils.bvhtree import BVHTree

argv = sys.argv[sys.argv.index('--') + 1:] if '--' in sys.argv else sys.argv[1:]
src, pre = argv[0], argv[1]
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=src)
hull = [o for o in bpy.context.scene.objects if o.type == 'MESH'][0]

XT, XS = -.490, -.245  # bow tip and the seam where the rebuilt bow meets the AI hull
GUNS = []  # (base, tip): lowered aft z1 from .080 to .028 so deck guns aim outboard rather than straight up
for x0, x1, z1 in ((-.045, -.059, .032), (.248, .240, .028)):
    for s in (1, -1):
        GUNS.append((Vector((x0, s * .100, .006)), Vector((x1, s * .148, z1))))

BOXES = [  # (x0, x1, y0, y1, z0, z1): AI geometry to cut away (all above the deck or tower roof)
    (.130, .300, -.088, .088, .056, .170),    # rocket rack and crumpled aft bridge block
    (.176, .228, -.030, .030, .062, .170),    # rack column and dome
    (.054, .097, -.030, .030, .062, .172),    # funnels
    (-.012, .062, -.040, .040, .110, .250),   # mast
    (-.100, .068, -.088, .088, .058, .140),   # bridge tier, its drums and roof tank
    (.155, .310, .178, .4, -.165, -.088), (.155, .310, -.4, -.178, -.165, -.088),  # aft side casemates and long guns
    (.310, .450, .035, .120, -.066, 0.), (.310, .450, -.120, -.035, -.066, 0.),      # stern deck guns and their platform
    (-.60, XS, -.4, .4, -.4, .4),             # the whole bow forward of the superstructure
]

def seg_d(p, a, b):
    ab = b - a
    t = max(0., min(1., (p - a).dot(ab) / ab.length_squared))
    return (a + ab * t - p).length

bm = bmesh.new()
bm.from_mesh(hull.data)
BVH0 = BVHTree.FromBMesh(bm)  # uncut AI hull for measuring what gets rebuilt

def face_y(x0, x1, z0, z1, s_, pct=50):
    ys = []
    for x in [x0 + (x1 - x0) * (i + .5) / 6 for i in range(6)]:
        for z in [z0 + (z1 - z0) * (j + .5) / 4 for j in range(4)]:
            h = BVH0.ray_cast(Vector((x, s_ * .5, z)), Vector((0, -s_, 0)), 1.0)
            if h[0] is not None:
                ys.append(abs(h[0].y))
    ys.sort()
    return ys[min(len(ys) - 1, int(len(ys) * pct / 100))] if ys else None

def deck0(x, y, zf=.3):
    h = BVH0.ray_cast(Vector((x, y, zf)), Vector((0, 0, -1)), 1.0)
    return h[0].z if h[0] is not None else None

# side armour blocks measured off the AI hull
SIDE = [(-.235, -.120, -.150, -.060), (-.045, .085, -.185, -.085), (.135, .265, -.185, -.085)]
SIDEF = {}
for i, (x0, x1, z0, z1) in enumerate(SIDE):
    for s_ in (1, -1):
        y_ = face_y(x0 + .01, x1 - .01, z0 + .01, z0 + (z1 - z0) - .01, s_, 35)
        SIDEF[(i, s_)] = y_
        print('side block', i, s_, y_)

# front armour slope profile: measure both centreline and lateral shoulders so chevron slabs wrap the hull camber
PX = [-.245 + k * .010 for k in range(14)]
PZ_C, PZ_S = [], []
for x in PX:
    zc = deck0(x, 0)
    zs = [z for z in (deck0(x, -.055), deck0(x, .055)) if z is not None]
    zc_val = zc if zc is not None else (statistics.median(zs) if zs else -.05)
    zs_val = statistics.median(zs) if zs else (zc_val - .011)
    PZ_C.append(zc_val)
    PZ_S.append(min(zc_val - .006, zs_val))

def _interp_profile(x, arr):
    if x <= PX[0]:
        return arr[0]
    for (xa, za), (xb, zb) in zip(zip(PX, arr), zip(PX[1:], arr[1:])):
        if x <= xb:
            return za + (zb - za) * (x - xa) / (xb - xa)
    return arr[-1]

def prof(x):
    return _interp_profile(x, PZ_C)

def prof_side(x):
    return _interp_profile(x, PZ_S)

print('front slope centre', [round(z, 3) for z in PZ_C])
print('front slope side  ', [round(z, 3) for z in PZ_S])

# midship side tanks: measured off the AI hull
TANK = {}
for s_ in (1, -1):
    best = None
    for z in [-.025 + k * .005 for k in range(10)]:
        for x in (.0, .02, .04):
            h = BVH0.ray_cast(Vector((x, s_ * .5, z)), Vector((0, -s_, 0)), 1.0)
            if h[0] is not None and (best is None or abs(h[0].y) > best[0]):
                best = (abs(h[0].y), z)
    TANK[s_] = (best[0] - .011, best[1]) if best else (.10, -.005)
    print('tank', s_, TANK[s_])

def cut_extra(c):
    for i, (x0, x1, z0, z1) in enumerate(SIDE):
        y_ = SIDEF[(i, 1 if c.y > 0 else -1)]
        if y_ is not None and x0 - .003 <= c.x <= x1 + .003 and z0 - .003 <= c.z <= z1 + .003 and abs(c.y) >= y_ - .006:
            return True
    if -.245 <= c.x <= -.11 and abs(c.y) < .072 and prof_side(c.x) - .015 <= c.z <= prof(c.x) + .06:
        return True  # slope
    if -.10 <= c.x <= .13 and c.z < -.191:
        return True  # loose barrels hanging under the hull
    if .285 <= c.x <= .36 and abs(c.y) < .062 and -.024 <= c.z <= .06:
        return True  # aft deck bay (rebuilt below as aftbay)
    if .295 <= c.x <= .46 and abs(c.y) < .045 and -.066 <= c.z <= (-.024 if c.x < .355 else .03):
        return True  # stern deck
    ty, tz = TANK[1 if c.y > 0 else -1]
    if -.035 <= c.x <= .075 and abs(c.y) > ty - .006 and math.hypot(abs(c.y) - ty, c.z - tz) < .016:
        return True  # side tanks (rebuilt below as sidetank)
    if .20 <= c.x <= .32 and .105 <= abs(c.y) <= .175 and .012 <= c.z <= .10:
        return True  # old AI aft long guns
    return False

kill = []
for f in bm.faces:
    c = f.calc_center_median()
    if any(b[0] <= c.x <= b[1] and b[2] <= c.y <= b[3] and b[4] <= c.z <= b[5] for b in BOXES) or any(seg_d(c, a, b) < .022 for a, b in GUNS) or cut_extra(c):
        kill.append(f)
bmesh.ops.delete(bm, geom=kill, context='FACES')
bm.to_mesh(hull.data)
print('cut faces', len(kill))
BVH = BVHTree.FromBMesh(bm)
bm.free()

def surf_down(x, y, z_from=.3):
    h = BVH.ray_cast(Vector((x, y, z_from)), Vector((0, 0, -1)), 1.0)
    return (h[0], h[1]) if h[0] is not None else (Vector((x, y, .02)), Vector((0, 0, 1)))

def surf_in(x, y_side, z):
    s_ = 1 if y_side > 0 else -1
    h = BVH.ray_cast(Vector((x, s_ * .4, z)), Vector((0, -s_, 0)), 1.0)
    return (h[0], h[1]) if h[0] is not None else (Vector((x, y_side, z)), Vector((0, s_, 0)))

bpy.ops.object.select_all(action='DESELECT')
hull.select_set(True)
bpy.context.view_layer.objects.active = hull
bpy.ops.export_scene.gltf(filepath=pre + '_cut.glb', export_format='GLB', use_selection=True, export_image_format='JPEG')

# ---------- clean parts ----------
COL = {}
def tag(rgb):
    for o in hs_lib.PARTS:
        if o.name not in COL:
            COL[o.name] = rgb

GUN = (.095, .095, .091)
STEEL = (.17, .17, .19)
RED = (.26, .075, .051)
DARK = (.02, .02, .022)
IRON = (.075, .058, .050)  # warm charcoal-iron matched to concept glacis plates
LAMP = (1.0, .30, .04)

# 1. Rocket rack: armored housing box with 2x7 launch tubes on a stepped turret neck and domed cap
TUBE = (.05, .05, .055)
RIM = (.14, .13, .12)
for row, z in enumerate((.113, .091)):
    for k in range(7):
        x = .217 + (k - 3) * .0202
        cyl(f'tube{row}{k}', (x, 0, z), .0090, .085, axis='Y', seg=20, bevel=.0008)
        tag(TUBE)
        for s in (1, -1):
            cyl(f'rim{row}{k}{s}', (x, s * .0405, z), .0100, .005, axis='Y', seg=20, bevel=.0006)
        cyl(f'rimc{row}{k}', (x, 0, z), .0097, .004, axis='Y', seg=20, bevel=0)
        tag(RIM)
        for s in (1, -1):
            cyl(f'bore{row}{k}{s}', (x, s * .0431, z), .0072, .002, axis='Y', seg=20, bevel=0)
tag(DARK)
box('rackframe', (.217, 0, .102), (.152, .072, .008), bevel=.0015)
box('rackhood', (.217, 0, .125), (.154, .078, .005), bevel=.0012)
for xk in (.144, .290):
    box(f'rackcheek{xk}', (xk, 0, .103), (.007, .084, .042), bevel=.001)
for s in (1, -1):
    box(f'rackstrap{s}', (.217, s * .028, .124), (.150, .004, .003), bevel=.0006)
tag(STEEL)
hz, _ = surf_down(.202, 0, .07)
zc0 = (hz.z - .003) if hz is not None else .047
cyl('colbase', (.202, 0, zc0 + .006), .024, .012, seg=24, bevel=.0015)
cyl('column', (.202, 0, (zc0 + .135) / 2), .016, .135 - zc0, seg=24, bevel=.0015)
tag(STEEL)
cyl('domebase', (.202, 0, .135), .012, .03, seg=24, bevel=.001)
tag(RED)
bm2 = bmesh.new()
bmesh.ops.create_uvsphere(bm2, u_segments=24, v_segments=10, radius=.012)
for v in bm2.verts:
    v.co.z = max(v.co.z, 0) * .9
bmesh.ops.translate(bm2, verts=bm2.verts, vec=(.202, 0, .150))
hs_lib._obj('dome', bm2, 0)
tag(RED)

# 2. Funnels: centered on ship spine y = 0.0 (fixing off-center stagger)
for nm, x, y, r, z0, z1 in (('fun1', .065, .0, .0068, .040, .163), ('fun2', .084, .0, .0118, .034, .156)):
    hz, _ = surf_down(x, y, .062)
    if hz is not None:
        z0 = hz.z - .003
    cyl(nm + 'base', (x, y, z0 + .003), r * 1.35, .006, seg=24, bevel=.001)
    tag(STEEL)
    cyl(nm, (x, y, (z0 + z1) / 2), r, z1 - z0, seg=24, bevel=.0012)
    tag(RED)
    for k in range(int((z1 - z0) / .018)):
        cyl(f'{nm}band{k}', (x, y, z0 + .012 + k * .018), r * 1.06, .003, seg=24, bevel=0)
    tag(DARK)
    cyl(nm + 'cap', (x, y, z1 + .002), r * 1.12, .005, seg=24, bevel=.001)
    tag(STEEL)
    cyl(nm + 'bore', (x, y, z1 + .0047), r * .82, .001, seg=24, bevel=0)
    tag(DARK)

# 3. Bridge tier + Upper Conning Tower (tier2) + Sponsons + Roof Vents + Braced Tripod Mast
x0, x1, zb, zt = -.088, .059, .056, .102
box('plinth', ((x0 + x1) / 2 + .004, 0, zb + .002), (x1 - x0 + .016, .170, .014), bevel=.002)
tag(STEEL)
frustum('tier', ((x0 + x1) / 2, 0, zb), ((x1 - x0) / 2, .056), ((x1 - x0) / 2 - .010, .050), zt - zb, shear=(.010, 0), bevel=.002)
tag(RED)
box('roof', ((x0 + x1) / 2 + .010, 0, zt + .002), (x1 - x0 - .018, .098, .004), bevel=.001)
tag(RED)
sl = math.atan2(.020, zt - zb)
box('winband', (x0 + .006, 0, zt - .010), (.004, .094, .012), rot=(0, -sl, 0), bevel=.001)
tag(DARK)
for k in range(8):
    box(f'light{k}', (x0 + .0035, -.040 + k * .0114, zt - .010), (.002, .006, .004), rot=(0, -sl, 0), bevel=0)
tag(LAMP)

# Upper conning deckhouse (tier2) with armored red brow visor and 4 upper slit lamps
zt2 = .126
frustum('tier2', (-.012, 0, zt + .003), (.044, .034), (.036, .028), zt2 - (zt + .003), shear=(.005, 0), bevel=.0018)
tag(STEEL)
box('tier2roof', (-.010, 0, zt2 + .0015), (.074, .058, .003), bevel=.0008)
box('tier2visor', (-.048, 0, zt2 - .003), (.012, .062, .005), rot=(0, -.18, 0), bevel=.0008)
tag(RED)
box('tier2win', (-.046, 0, zt2 - .007), (.004, .052, .006), bevel=.0005)
tag(DARK)
for k in range(4):
    box(f'tier2light{k}', (-.0485, -.018 + k * .012, zt2 - .007), (.002, .005, .003), bevel=0)
tag(LAMP)

# Wing rangefinder sponsons on bridge shoulders + aft roof louver vents
for s_ in (1, -1):
    box(f'wingsponson{s_}', (-.008, s_ * .042, zt + .010), (.034, .018, .010), bevel=.0012)
    cyl(f'wingopt{s_}', (-.012, s_ * .046, zt + .018), .0055, .016, axis='Y', seg=18, bevel=.0008)
    box(f'rail{s_}', ((x0 + x1) / 2 + .010, s_ * .047, zt + .009), (x1 - x0 - .024, .0016, .0016), bevel=0)
    for k in range(6):
        box(f'post{s_}{k}', (x0 + .016 + k * .024, s_ * .047, zt + .0065), (.0016, .0016, .007), bevel=0)
vents('brvents', (.036, 0, zt + .005), 5, .042, .004, .0055)
tag(STEEL)

# Braced tripod mast anchored into mast collar on tier2roof and aft roof corners
Rake = Matrix.Rotation(math.radians(6), 3, 'Y')
cyl('mastcollar', (.014, 0, zt2 + .008), .0085, .014, seg=20, bevel=.001)
cyl('mast', (.018, 0, .182), .0038, .116, seg=14, bevel=0, rot=Rake)
cyl('mast2', (-.004, 0, .162), .0030, .076, seg=14, bevel=0, rot=Rake)
for s_ in (1, -1):
    # Tripod legs anchored from mast hound (.018, 0, .178) down to real roof (.044, s_*.024, zt+.004)
    p_top = Vector((.018, 0, .178))
    p_bot = Vector((.044, s_ * .024, zt + .004))
    d_leg = p_top - p_bot
    barrel(f'tripod{s_}', p_bot, d_leg.normalized(), d_leg.length, .0022)
    # Whip aerials on tier2 corners
    barrel(f'whip{s_}', (-.028, s_ * .024, zt2 + .002), (.12, s_ * .06, .99), .055, .0013)
box('yard', (-.004, 0, .182), (.0035, .068, .0035), bevel=.0005)
box('yard2', (.020, 0, .216), (.0030, .046, .0030), bevel=.0005)
for s_ in (1, -1):
    cyl(f'yarddrum{s_}', (-.004, s_ * .034, .182), .0042, .012, axis='X', seg=16, bevel=.0006)
box('lantern', (.021, 0, .230), (.010, .009, .014), bevel=.001)
for k in range(4):
    box(f'rung{k}', (.016, 0, .136 + k * .018), (.003, .012, .0016), bevel=0)
tag(STEEL)
cyl('mastbeacon', (.021, 0, .239), .0035, .004, seg=14, bevel=0)
tag(LAMP)

# Bridge shoulder drums on saddles
for s_ in (1, -1):
    cyl(f'drum{s_}', (-.0075, s_ * .0625, .078), .0125, .053, axis='X', seg=28, bevel=.0015)
    tag(STEEL)
    for k in (-1, 1):
        cyl(f'drumring{s_}{k}', (-.0075 + k * .018, s_ * .0625, .078), .0132, .003, axis='X', seg=28, bevel=0)
    tag(GUN)
    for k in (-1, 1):
        hz, _ = surf_down(-.0075 + k * .016, s_ * .0625, .07)
        ztop = .066
        zbot = min(ztop - .004, hz.z if hz is not None else .058)
        box(f'saddle{s_}{k}', (-.0075 + k * .016, s_ * .0625, (ztop + zbot) / 2), (.008, .020, ztop - zbot), bevel=.0006)
    tag(GUN)

# 4. Midship side tanks (previously cut out of hull by TANK and never built)
for s_ in (1, -1):
    ty, tz = TANK[s_]
    cyl(f'sidetank{s_}', (.020, s_ * ty, tz), .0135, .092, axis='X', seg=24, bevel=.0012)
    tag(STEEL)
    for e_ in (-1, 1):
        cyl(f'sidetankcap{s_}{e_}', (.020 + e_ * .046, s_ * ty, tz), .0120, .006, axis='X', seg=24, bevel=.002)
    tag(RED)
    for k, xk in enumerate((-.010, .050)):
        box(f'tanksaddle{s_}{k}', (xk, s_ * (ty - .006), tz), (.010, .018, .028), bevel=.001)
        cyl(f'tankband{s_}{k}', (xk, s_ * ty, tz), .0145, .004, axis='X', seg=24, bevel=0)
    tag(GUN)

# 5. Long deck guns: fixed gunplate rot=Rn and outboard elevation
for i, (a, b) in enumerate(GUNS):
    d = (b - a)
    L = d.length
    p_, n_ = surf_in(a.x, a.y, a.z)
    if p_ is not None:
        n_ = Vector(n_).normalized()
        if n_.dot(Vector((0, 1 if a.y > 0 else -1, 0))) < 0:
            n_ = -n_
        a = p_ + n_ * .006
        d = (d.normalized() + n_ * .5).normalized() * L
        Rn = Vector((0, 0, 1)).rotation_difference(n_).to_matrix()
        cyl(f'gunplate{i}', p_ + n_ * .0012, .011, .003, axis='Z', seg=20, bevel=.0006, rot=Rn)
        cyl(f'gunball{i}', a, .0085, .010, axis='Z', seg=20, bevel=.002, rot=Rn)
        barrel(f'gun{i}', a, d.normalized(), L, .0034)
tag(GUN)

# 6. Bow loft and symmetric deck dressing
def bow_sec(x):
    s_ = max(0., min(1., (x - XT) / (XS + .010 - XT)))
    wd = max(.006, .124 * (1 - (1 - s_) ** 2.2))
    wh = max(.004, min(wd - .008, .095 * s_ ** .9))
    wk = max(.003, wd * .3)
    zd, t = -.085, .007
    zk = -.102 - .098 * min(1., max(0., (s_ - .04) / .27))
    zk += .014 * min(1., max(0., (x + .300) / .012))
    zh = zd - t - .003
    zc = zk + min(.012, (zh - zk) * .5)
    half = [(wd * .45, zd + .002), (wd * .97, zd), (wd, zd - t), (wh, zh), (min(wh, wk + .008), zc), (wk, zk)]
    return [(0, zd + .003)] + half + [(0, zk)] + [(-y, z) for y, z in reversed(half)]

loft('bow', [[float(x), bow_sec(float(x))] for x in _np.concatenate([_np.linspace(XT, XT + .03, 4), _np.linspace(XT + .03, XS + .012, 14)[1:]])])
tag(RED)

zdk = -.082
cyl('jackbase', (XT + .032, 0, zdk + .002), .007, .004, seg=16, bevel=.0008)
cyl('jackstaff', (XT + .032, 0, zdk + .026), .0035, .052, seg=12, bevel=0)
cyl('jackspike', (XT + .032, 0, zdk + .052 + .009), .0016, .018, seg=12, bevel=0)
cyl('chaserbase', (-.425, 0, zdk + .003), .016, .006, seg=24, bevel=.001)
tag(STEEL)
box('chaserhouse', (-.425, 0, zdk + .012), (.026, .020, .012), bevel=.002)
tag(RED)
for s_ in (1, -1):
    barrel(f'chaser{s_}', (-.436, s_ * .005, zdk + .013), (-1, 0, .04), .052, .0028)
tag(GUN)
box('hatch1', (-.370, 0, zdk + .0015), (.030, .026, .003), bevel=.0008)
for s_ in (1, -1):  # mirrored hatch2 on both port and starboard
    cyl(f'hatch2_{s_}', (-.335, s_ * .045, zdk + .0015), .011, .003, seg=16, bevel=.0006)
for x_ in (-.400, -.345, -.290):
    w_ = .124 * (1 - (1 - (x_ - XT) / (XS + .010 - XT)) ** 2.2)
    for s_ in (1, -1):
        cyl(f'bollard{x_}{s_}', (x_, s_ * (w_ - .012), zdk + .004), .0035, .008, seg=12, bevel=.0006)
tag(GUN)
for s_ in (1, -1):
    for k in (0, 1):
        cyl(f'deckdrum{s_}{k}', (-.278 + k * .024, s_ * .072, zdk + .010), .0095, .028, axis='Y', seg=20, bevel=.001)
    tag(STEEL)
    for k in (0, 1):
        for e in (1, -1):
            cyl(f'deckdrumring{s_}{k}{e}', (-.278 + k * .024, s_ * .072 + e * .009, zdk + .010), .010, .002, axis='Y', seg=20, bevel=0)
    tag(GUN)

# 7. Aft deck bay cap (covers the .285..0.36 cutout so no hole remains in the hull)
box('aftbaycoam', (.322, 0, -.018), (.076, .118, .016), bevel=.002)
tag(STEEL)
box('aftbaylid', (.322, 0, -.009), (.064, .102, .006), bevel=.0015)
tag(DARK)
for s_ in (1, -1):
    cyl(f'aftbaydrum{s_}', (.322, s_ * .030, -.002), .008, .048, axis='X', seg=20, bevel=.001)
tag(RED)

# 8. Aft side casemates (tapered frustum blisters, guns aimed forward -X & outboard) and yawed long guns
for s_ in (1, -1):
    yf = SIDEF[(2, s_)] or .165
    # Tapered armoured blister faired into the flank
    frustum(f'casemate{s_}', (.192, s_ * (yf + .004), -.156), (.052, .020), (.042, .016), .052, bevel=.004)
    tag(STEEL)
    box(f'casematelid{s_}', (.196, s_ * (yf + .021), -.122), (.070, .004, .022), bevel=.002)
    tag(GUN)
    for k in range(5):
        box(f'casemateband{s_}{k}', (.170 + k * .011, s_ * (yf + .023), -.137), (.004, .002, .014), bevel=0)
    tag(DARK)
    # Forward-facing casemate barrel (-X is bow, angled 14 deg outboard) on visible ball mount
    a_ = Vector((.152, s_ * (yf + .014), -.133))
    cyl(f'caseball{s_}', a_, .0095, .012, axis='X', seg=20, bevel=.002)
    barrel(f'casegun{s_}', a_, (-1, s_ * .25, -.02), .095, .0055)
    tag(GUN)

    # Long cannon above casemate yawed 8 deg outboard so muzzle clears forward hull flare
    y2 = (SIDEF[(2, s_)] or .165) + .012
    yaw_ang = s_ * math.radians(-8)
    Ryaw = Matrix.Rotation(yaw_ang, 3, 'Z')
    gun_c = Vector((.240, s_ * y2, -.098))
    gun_dir = Vector((-math.cos(yaw_ang), -math.sin(yaw_ang), 0))
    cyl(f'longgun{s_}', gun_c, .0065, .175, axis='X', seg=20, bevel=.0008, rot=Ryaw)
    cyl(f'longgunm{s_}', gun_c + gun_dir * .082, .0085, .012, axis='X', seg=20, bevel=.001, rot=Ryaw)
    for k in range(4):
        cyl(f'longgunring{s_}{k}', gun_c + gun_dir * (.065 - k * .045), .0074, .004, axis='X', seg=20, bevel=0, rot=Ryaw)
    tag(GUN)
    for xb in (.185, .290):
        box(f'longgunbracket{s_}{xb}', (xb, s_ * (y2 - .010), -.098), (.012, .022, .010), rot=(0, 0, yaw_ang), bevel=.001)
    tag(STEEL)

    # Stern deck gun: housing on a pedestal, twin barrels aimed aft (+X)
    hz, _ = surf_down(.365, s_ * .070, .0)
    zdk_ = hz.z if hz is not None else -.068
    box(f'sternped{s_}', (.365, s_ * .070, (zdk_ + -.056) / 2), (.030, .022, max(.004, -.056 - zdk_ + .004)), bevel=.0012)
    tag(STEEL)
    cyl(f'sternhouse{s_}', (.368, s_ * .070, -.044), .0125, .075, axis='X', seg=28, bevel=.0015)
    cyl(f'sterncap{s_}', (.330, s_ * .070, -.044), .0132, .004, axis='X', seg=28, bevel=0)
    barrel(f'sternbig{s_}', (.404, s_ * .070, -.044), (1, 0, 0), .055, .0060)
    barrel(f'sternsmall{s_}', (.345, s_ * .070, -.034), (1, 0, 0), .088, .0034)
    box(f'sternstrut{s_}', (.372, s_ * .070, -.034), (.008, .005, .012), bevel=0)
    tag(GUN)
    cyl(f'sternlamp{s_}', (.381, s_ * (.070 + .0125), -.041), .0055, .003, axis='Y', seg=20, bevel=0)
    tag(LAMP)
    for k in range(5):
        hz, _ = surf_down(.330 + k * .022, s_ * .100, .0)
        zl = hz.z if hz is not None else -.068
        cyl(f'decklamp{s_}{k}', (.330 + k * .022, s_ * .100, zl + .002), .0045, .004, seg=16, bevel=0)
        bm4 = bmesh.new()
        bmesh.ops.create_uvsphere(bm4, u_segments=16, v_segments=8, radius=.0042)
        for v in bm4.verts:
            v.co.z = max(v.co.z, 0) * .8
        bmesh.ops.translate(bm4, verts=bm4.verts, vec=(.330 + k * .022, s_ * .100, zl + .004))
        hs_lib._obj(f'decklampdome{s_}{k}', bm4, 0)
    tag(LAMP)

# 9. Side armour blocks
for i, (x0, x1, z0, z1) in enumerate(SIDE):
    for s_ in (1, -1):
        y_ = SIDEF[(i, s_)]
        if y_ is None:
            continue
        box(f'sideblock{i}{s_}', ((x0 + x1) / 2, s_ * (y_ - .015), (z0 + z1) / 2), (x1 - x0, .030, z1 - z0), bevel=.002)
        tag(STEEL)
        box(f'sidepanel{i}{s_}', ((x0 + x1) / 2, s_ * (y_ + .001), (z0 + z1) / 2 + .006), (x1 - x0 - .022, .003, (z1 - z0) * .55), bevel=.0008)
        tag(DARK)
        if i != 2:
            for k in range(6):
                box(f'sidevent{i}{s_}{k}', (x0 + .016 + k * .007, s_ * (y_ + .0012), z0 + .016), (.003, .002, .018), bevel=0)
    tag(DARK)

# 10. Front armour (cambered chevron lofts wrapping the lateral slope, shingled overlap, framing cheek rails + central spine)
xs_ = [-.242, -.208, -.175, -.143, -.112]
for k in range(4):
    xa, xb = xs_[k] - .002, xs_[k + 1] + .002  # 4 mm shingle overlap
    hw_a = (.130 - .006 * k) * .5
    hw_b = (.130 - .006 * (k + 1)) * .5
    t_bot, t_top = .015, .007  # shingled wedge: thick lower brow, thinner upper edge tucked under next slab
    secs = []
    for x_st, hw, thk in ((xa, hw_a, t_bot), ((xa + xb) * .5, (hw_a + hw_b) * .5, (t_bot + t_top) * .5), (xb, hw_b, t_top)):
        zc = prof(x_st)
        zs = prof_side(x_st)
        zb_sk = zs - .006  # skirt tucks into hull slope so outer corners never float
        pts = [
            (0.0, zc + thk + .002),
            (hw * .55, (zc + zs) * .5 + thk),
            (hw, zs + thk * .75),
            (hw, zb_sk),
            (0.0, zc - .004),
            (-hw, zb_sk),
            (-hw, zs + thk * .75),
            (-hw * .55, (zc + zs) * .5 + thk),
        ]
        secs.append((float(x_st), pts))
    loft(f'frontslab{k}', secs, bevel=.002)
    tag(IRON)
    # Stepped lower brow lip following the chevron camber
    za_c, za_s = prof(xa), prof_side(xa)
    lip_secs = []
    for x_st in (xa - .002, xa + .004):
        pts_l = [
            (0.0, za_c + t_bot + .004),
            (hw_a + .002, za_s + t_bot * .8 + .002),
            (hw_a + .002, za_s - .004),
            (0.0, za_c - .002),
            (-(hw_a + .002), za_s - .004),
            (-(hw_a + .002), za_s + t_bot * .8 + .002),
        ]
        lip_secs.append((float(x_st), pts_l))
    loft(f'frontrim{k}', lip_secs, bevel=.0008)
    tag(DARK)

# Continuous side cheek rails and centreline spine rib tying the 4 glacis plates into the deck
xa_all, xb_all = xs_[0], xs_[-1]
a_glacis = math.atan2(prof(xb_all) - prof(xa_all), xb_all - xa_all)
L_glacis = math.hypot(xb_all - xa_all, prof(xb_all) - prof(xa_all))
cx_g = (xa_all + xb_all) * .5
cz_g_c = (prof(xa_all) + prof(xb_all)) * .5 + .011
cz_g_s = (prof_side(xa_all) + prof_side(xb_all)) * .5 + .006
box('frontspine', (cx_g, 0, cz_g_c), (L_glacis, .008, .008), rot=(0, -a_glacis, 0), bevel=.001)
for s_ in (1, -1):
    box(f'frontcheek{s_}', (cx_g, s_ * .060, cz_g_s), (L_glacis + .006, .007, .012), rot=(0, -a_glacis, 0), bevel=.0012)
tag(STEEL)

# 11. Ventral thrusters
for k, x_ in enumerate((-.015, .017, .049)):
    h = BVH.ray_cast(Vector((x_, 0, -.5)), Vector((0, 0, 1)), 1.0)
    zb_ = h[0].z if h[0] is not None else -.19
    box(f'thrplate{k}', (x_, 0, zb_ - .001), (.028, .030, .004), bevel=.0008)
    tag(GUN)
    cyl(f'thr{k}', (x_, 0, zb_ - .013), .0095, .022, seg=24, bevel=.001)
    cyl(f'thrbell{k}', (x_, 0, zb_ - .028), .0125, .008, seg=24, bevel=.001)
    tag(GUN)
    cyl(f'thrglow{k}', (x_, 0, zb_ - .0325), .0088, .0015, seg=24, bevel=0)
    tag(LAMP)

# 12. Write vertex colors ('Col') onto every part and join into one clean kit mesh via hs_lib.finish('kit')
for o in hs_lib.PARTS:
    rgb = COL.get(o.name, (0.1, 0.1, 0.1))
    me = o.data
    if 'Col' not in me.color_attributes:
        ca = me.color_attributes.new(name='Col', type='FLOAT_COLOR', domain='CORNER')
    else:
        ca = me.color_attributes['Col']
    n_loops = len(me.loops)
    ca.data.foreach_set('color', [rgb[0], rgb[1], rgb[2], 1.0] * n_loops)

n_parts = len(hs_lib.PARTS)
hs_lib.finish('kit')
kit_obj = bpy.context.view_layer.objects.active
kit_obj.data.color_attributes.active_color = kit_obj.data.color_attributes['Col']

mat = bpy.data.materials.new(name='m_kit')
mat.use_nodes = True
nt = mat.node_tree
vc_node = nt.nodes.new('ShaderNodeVertexColor')
vc_node.layer_name = 'Col'
bsdf = nt.nodes.get('Principled BSDF')
if bsdf:
    nt.links.new(vc_node.outputs['Color'], bsdf.inputs['Base Color'])
    bsdf.inputs['Roughness'].default_value = 0.4
kit_obj.data.materials.clear()
kit_obj.data.materials.append(mat)

bpy.ops.object.select_all(action='DESELECT')
kit_obj.select_set(True)
bpy.context.view_layer.objects.active = kit_obj
bpy.ops.export_scene.gltf(filepath=pre + '_kit.glb', export_format='GLB', use_selection=True)
print('wrote joined kit GLB with', n_parts, 'parts and vertex color layer Col')
