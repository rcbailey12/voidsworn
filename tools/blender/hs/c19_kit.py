# Pyre-Barge (C19_51) hybrid: the Pixal3D hull keeps its shape and paint; its small parts (rocket rack, funnels, mast, long guns),
# which the AI blurs together, are cut out and rebuilt as clean bevelled parts placed where the concept's side and front views put them.
# Frame: the Pixal3D GLB as Blender imports it for a side-first run: x aft (bow at -x), z up, y lateral; 1 unit = 931 px in the
# 1024 rig views (mvC2/C19_51_left.png and _front.png). Writes OUT_cut.glb (hull minus the cut parts) and OUT_kit.glb (vertex-coloured parts).
# usage: blender -b -P c19_kit.py -- hull.glb out_prefix
import sys, os, math, bpy, bmesh
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__))); from hs_lib import *
import hs_lib
from mathutils import Vector, Matrix
argv = sys.argv[sys.argv.index('--') + 1:] if '--' in sys.argv else sys.argv[1:]
src, pre = argv[0], argv[1]
bpy.ops.wm.read_factory_settings(use_empty=True); bpy.ops.import_scene.gltf(filepath=src)
hull = [o for o in bpy.context.scene.objects if o.type == 'MESH'][0]
XT, XS = -.490, -.245  # bow tip and the seam where the rebuilt bow meets the AI hull
GUNS = []  # (base, tip)
for x0, x1 in ((-.045, -.059), (.248, .250)):
    for s in (1, -1): GUNS.append((Vector((x0, s * .100, .006)), Vector((x1, s * .145, .080))))
BOXES = [  # (x0, x1, y0, y1, z0, z1): AI geometry to cut away (all above the deck or tower roof)
    (.130, .300, -.088, .088, .056, .170),   # rocket rack (its AI ends ran wider than the tubes) and the crumpled AI base under it
    (.176, .228, -.030, .030, .062, .170),   # rack column and dome
    (.054, .097, -.030, .030, .062, .172),   # funnels
    (-.012, .062, -.040, .040, .110, .250),  # mast
    (-.100, .068, -.088, .088, .058, .140),  # bridge tier, its drums and roof tank (owner, Oct 21: soft and blobby near the bridge)
    (.155, .310, .178, .4, -.165, -.088), (.155, .310, -.4, -.178, -.165, -.088),  # aft side casemates and long cannons (owner, Oct 21: big side guns blobby)
    (.310, .450, .035, .120, -.066, 0.), (.310, .450, -.120, -.035, -.066, 0.),     # stern deck guns and their lamp row
    (-.60, XS, -.4, .4, -.4, .4),             # the whole bow forward of the superstructure (owner, Oct 21: wavy and messy), rebuilt as a clean loft below
]
def seg_d(p, a, b):
    ab = b - a; t = max(0, min(1, (p - a).dot(ab) / ab.length_squared)); return (a + ab * t - p).length
bm = bmesh.new(); bm.from_mesh(hull.data)
from mathutils.bvhtree import BVHTree
import statistics
BVH0 = BVHTree.FromBMesh(bm)  # the uncut AI hull, for measuring what gets rebuilt
def face_y(x0, x1, z0, z1, s_, pct=50):  # outer face of the flank in a patch: a grid of inward rays, a percentile of the hit |y|
    ys = []
    for x in [x0 + (x1 - x0) * (i + .5) / 6 for i in range(6)]:
        for z in [z0 + (z1 - z0) * (j + .5) / 4 for j in range(4)]:
            h = BVH0.ray_cast(Vector((x, s_ * .5, z)), Vector((0, -s_, 0)), 1.0)
            if h[0] is not None: ys.append(abs(h[0].y))
    ys.sort(); return ys[min(len(ys) - 1, int(len(ys) * pct / 100))] if ys else None
def deck0(x, y, zf=.3):
    h = BVH0.ray_cast(Vector((x, y, zf)), Vector((0, 0, -1)), 1.0); return h[0].z if h[0] is not None else None
# side armour blocks (owner, Oct 21: the big dark side blocks are wavy): measured off the AI hull, rebuilt as clean boxes
SIDE = [(-.235, -.120, -.150, -.060), (-.045, .085, -.185, -.085), (.135, .265, -.185, -.085)]
SIDEF = {}
for i, (x0, x1, z0, z1) in enumerate(SIDE):
    for s_ in (1, -1):
        y_ = face_y(x0 + .01, x1 - .01, z0 + .01, z1 - .01, s_, 35); SIDEF[(i, s_)] = y_; print('side block', i, s_, y_)
# front armour plates: the forward slope under the bridge, its centreline profile measured
PX = [-.245 + k * .010 for k in range(14)]
PZ = []
for x in PX:
    zs = [z for z in (deck0(x, -.05), deck0(x, 0), deck0(x, .05)) if z is not None]; PZ.append(statistics.median(zs) if zs else -.07)
def prof(x):
    if x <= PX[0]: return PZ[0]
    for (xa, za), (xb, zb) in zip(zip(PX, PZ), zip(PX[1:], PZ[1:])):
        if x <= xb: return za + (zb - za) * (x - xa) / (xb - xa)
    return PZ[-1]
print('front slope', [round(z, 3) for z in PZ])
# midship side tanks: the AI's own tank axis, from the outermost hits in the patch
TANK = {}
for s_ in (1, -1):
    best = None
    for z in [-.025 + k * .005 for k in range(10)]:
        for x in (.0, .02, .04):
            h = BVH0.ray_cast(Vector((x, s_ * .5, z)), Vector((0, -s_, 0)), 1.0)
            if h[0] is not None and (best is None or abs(h[0].y) > best[0]): best = (abs(h[0].y), z)
    TANK[s_] = (best[0] - .011, best[1]) if best else (.10, -.005); print('tank', s_, TANK[s_])
def cut_extra(c):
    for i, (x0, x1, z0, z1) in enumerate(SIDE):
        y_ = SIDEF[(i, 1 if c.y > 0 else -1)]
        if y_ is not None and x0 - .003 <= c.x <= x1 + .003 and z0 - .003 <= c.z <= z1 + .003 and abs(c.y) >= y_ - .03: return True
    if -.245 <= c.x <= -.115 and abs(c.y) < .072 and prof(c.x) - .015 <= c.z <= prof(c.x) + .03: return True
    if -.10 <= c.x <= .13 and c.z < -.191: return True  # loose barrels hanging under the hull
    if .285 <= c.x <= .36 and abs(c.y) < .062 and -.024 <= c.z <= .06: return True  # the open bay at the back of the superstructure
    if .295 <= c.x <= .46 and abs(c.y) < .045 and -.066 <= c.z <= (-.024 if c.x < .355 else .03): return True  # stern deckhouse (and the dark open box ahead of it)
    ty, tz = TANK[1 if c.y > 0 else -1]
    if -.035 <= c.x <= .075 and abs(c.y) > ty - .006 and math.hypot(abs(c.y) - ty, c.z - tz) < .016: return True
    if .20 <= c.x <= .32 and .105 <= abs(c.y) <= .175 and .012 <= c.z <= .10: return True  # the old AI aft long guns beside the new ones
    return False
kill = []
for f in bm.faces:
    c = f.calc_center_median()
    if any(b[0] <= c.x <= b[1] and b[2] <= c.y <= b[3] and b[4] <= c.z <= b[5] for b in BOXES) or any(seg_d(c, a, b) < .022 and c.z > a.z + .010 for a, b in GUNS) or cut_extra(c):
        kill.append(f)
bmesh.ops.delete(bm, geom=kill, context='FACES'); bm.to_mesh(hull.data); print('cut faces', len(kill))
BVH = BVHTree.FromBMesh(bm); bm.free()
# placement rules (owner, Oct 21): every bolt-on sits on the real surface on a visible mount, guns point out and away from the hull,
# and parts come in matched pairs at sensible hard points (Corsair excepted, which may stay junky)
def surf_down(x, y, z_from=.3):  # deck height under (x, y)
    h = BVH.ray_cast(Vector((x, y, z_from)), Vector((0, 0, -1)), 1.0); return (h[0], h[1]) if h[0] is not None else (None, None)
def surf_in(x, y_side, z):  # flank point at height z, cast inward from outside the hull on side sign(y_side)
    s_ = 1 if y_side > 0 else -1; h = BVH.ray_cast(Vector((x, s_ * .4, z)), Vector((0, -s_, 0)), 1.0); return (h[0], h[1]) if h[0] is not None else (None, None)
bpy.ops.object.select_all(action='DESELECT'); hull.select_set(True); bpy.context.view_layer.objects.active = hull
bpy.ops.export_scene.gltf(filepath=pre + '_cut.glb', export_format='GLB', use_selection=True, export_image_format='JPEG', export_jpeg_quality=95)
# ---------- clean parts ----------
COL = {}
def tag(rgb):  # colour every part made since the last tag
    for o in hs_lib.PARTS:
        if o.name not in COL: COL[o.name] = rgb
GUN = (.085, .085, .09); STEEL = (.17, .17, .18); RED = (.36, .075, .05); DARK = (.02, .02, .022)  # linear colours, sampled by eye from the concept
# rocket rack: two rows of seven launch tubes across the ship, on a column with a domed cap. Painted by hand, not by projection
# (owner, Oct 21: the projected rack came out a grey blob, like an unpainted tabletop model): gunmetal tubes, steel rims, dark bores, red frame.
TUBE = (.05, .05, .055); RIM = (.14, .13, .12)
for row, z in enumerate((.113, .091)):
    for k in range(7):
        x = .217 + (k - 3) * .0202
        cyl(f'tube{row}{k}', (x, 0, z), .0090, .085, axis='Y', seg=20, bevel=.0008); tag(TUBE)
        for s in (1, -1): cyl(f'rim{row}{k}{s}', (x, s * .0405, z), .0100, .005, axis='Y', seg=20, bevel=.0006)
        cyl(f'rimc{row}{k}', (x, 0, z), .0097, .004, axis='Y', seg=20, bevel=0); tag(RIM)
        for s in (1, -1): cyl(f'bore{row}{k}{s}', (x, s * .0431, z), .0072, .002, axis='Y', seg=20, bevel=0)
tag(DARK)
box('rackframe', (.217, 0, .102), (.150, .07, .006), bevel=.0015); box('rackcheek1', (.144, 0, .102), (.006, .088, .04), bevel=.0015); box('rackcheek2', (.290, 0, .102), (.006, .088, .04), bevel=.0015); tag(RED)
for s in (1, -1): box(f'rackstrap{s}', (.217, s * .028, .124), (.150, .004, .003), bevel=.0006)
tag(STEEL)
hz, _ = surf_down(.202, 0, .07); zc0 = (hz.z - .003) if hz is not None else .047; cyl('column', (.202, 0, (zc0 + .097) / 2), .021, .097 - zc0, seg=32, bevel=.002); cyl('collar', (.202, 0, .096), .025, .006, seg=32, bevel=.001); tag(STEEL)
cyl('domebase', (.202, 0, .135), .011, .03, seg=24, bevel=.001); tag(RED)
bm2 = bmesh.new(); bmesh.ops.create_uvsphere(bm2, u_segments=24, v_segments=10, radius=.011)
for v in bm2.verts: v.co.z = max(v.co.z, 0) * .9
bmesh.ops.translate(bm2, verts=bm2.verts, vec=(.202, 0, .150)); hs_lib._obj('dome', bm2, 0); tag(RED)
# funnels: a slim one and a stout one, red with dark bands and caps
for nm, x, y, r, z0, z1 in (('fun1', .0666, .010, .0064, .040, .163), ('fun2', .0827, -.012, .0118, .034, .156)):
    hz, _ = surf_down(x, y, .062)
    if hz is not None: z0 = hz.z - .003  # stands on the deck, slightly sunk
    cyl(nm + 'base', (x, y, z0 + .003), r * 1.35, .006, seg=24, bevel=.001); tag(STEEL)
    cyl(nm, (x, y, (z0 + z1) / 2), r, z1 - z0, seg=24, bevel=.0012); tag(RED)
    for k in range(int((z1 - z0) / .018)): cyl(f'{nm}band{k}', (x, y, z0 + .012 + k * .018), r * 1.06, .003, seg=24, bevel=0)
    cyl(nm + 'cap', (x, y, z1 + .002), r * 1.12, .005, seg=24, bevel=.001); cyl(nm + 'bore', (x, y, z1 + .0047), r * .8, .001, seg=24, bevel=0); tag(DARK)
# mast: main pole, a second pole, a yard arm, a brace and a lantern box
cyl('mast', (.035, 0, .170), .0035, .136, seg=12, bevel=0); cyl('mast2', (.009, 0, .146), .0028, .088, seg=12, bevel=0)
box('yard', (.008, 0, .176), (.026, .003, .003), bevel=0); box('yard2', (.040, 0, .214), (.016, .0025, .0025), bevel=0)
barrel('brace', (-.032, 0, .123), (.98, 0, .30), .06, .0018)
box('lantern', (.036, 0, .225), (.010, .009, .014), bevel=.001)
for k in range(4): box(f'rung{k}', (.038, 0, .115 + k * .022), (.010, .004, .0016), bevel=0)
tag(STEEL)
# long guns: tapered barrels on ball mounts, leaning outboard
for i, (a, b) in enumerate(GUNS):
    d = (b - a); L = d.length; p_, n_ = surf_in(a.x, a.y, a.z)
    if p_ is not None:
        n_ = Vector(n_).normalized()
        if n_.dot(Vector((0, 1 if a.y > 0 else -1, 0))) < 0: n_ = -n_  # outward
        a = p_ + n_ * .006; d = (d.normalized() + n_ * .5).normalized() * L  # never aimed back into the hull
        Rn = Vector((0, 0, 1)).rotation_difference(n_).to_matrix(); cyl(f'gunplate{i}', p_ + n_ * .0012, .011, .003, seg=20, rot=Rn, bevel=.0008)
    cyl(f'gunball{i}', a, .0085, .010, seg=20, bevel=.002)
    barrel(f'gun{i}', a, d.normalized(), L, .0034)
tag(GUN)
# bridge tier: armoured block with a sloped front, window band with a row of lights, roof rail, shoulder drums on saddles, roof tank
x0, x1, zb, zt = -.088, .059, .056, .102
box('plinth', ((x0 + x1) / 2 + .004, 0, zb + .002), (x1 - x0 + .016, .170, .014), bevel=.002); tag(STEEL)
frustum('tier', ((x0 + x1) / 2, 0, zb), ((x1 - x0) / 2, .056), ((x1 - x0) / 2 - .010, .050), zt - zb, shear=(.010, 0), bevel=.003); tag(RED)
box('roof', ((x0 + x1) / 2 + .010, 0, zt + .002), (x1 - x0 - .018, .098, .004), bevel=.001); tag(RED)  # red like the concept (steel read as a pale slab in game)
sl = math.atan2(.020, zt - zb)  # front slope
box('winband', (x0 + .006, 0, zt - .010), (.004, .094, .012), rot=(0, -sl, 0), bevel=.001); tag(DARK)
for k in range(8): box(f'light{k}', (x0 + .0035, -.040 + k * .0114, zt - .010), (.002, .006, .004), rot=(0, -sl, 0), bevel=0)
tag((1.0, .30, .04))
for s_ in (1, -1):
    box(f'rail{s_}', ((x0 + x1) / 2 + .010, s_ * .047, zt + .009), (x1 - x0 - .024, .0016, .0016), bevel=0)
    for k in range(6): box(f'post{s_}{k}', (x0 + .016 + k * .024, s_ * .047, zt + .0065), (.0016, .0016, .007), bevel=0)
tag(STEEL)
for s_ in (1, -1):  # drums ride on saddles that sit on the tier shoulders
    cyl(f'drum{s_}', (-.0075, s_ * .0625, .078), .0125, .053, axis='X', seg=28, bevel=.0015); tag(STEEL)
    for k in (-1, 1): cyl(f'drumring{s_}{k}', (-.0075 + k * .018, s_ * .0625, .078), .0132, .003, axis='X', seg=28, bevel=0)
    tag(GUN)
    for k in (-1, 1):
        hz, _ = surf_down(-.0075 + k * .016, s_ * .0625, .07); ztop = .066; zbot = min(ztop - .004, hz.z if hz is not None else ztop - .01)
        box(f'saddle{s_}{k}', (-.0075 + k * .016, s_ * .0625, (ztop + zbot) / 2), (.008, .020, ztop - zbot), bevel=.0008)
    tag(GUN)
cyl('rooftank', (-.020, 0, zt + .015), .010, .022, seg=24, bevel=.0012); tag(RED)
bm3 = bmesh.new(); bmesh.ops.create_uvsphere(bm3, u_segments=24, v_segments=10, radius=.010)
for v in bm3.verts: v.co.z = max(v.co.z, 0) * .8
bmesh.ops.translate(bm3, verts=bm3.verts, vec=(-.020, 0, zt + .026)); hs_lib._obj('rooftankcap', bm3, 0); tag(RED)
# bow: the AI bow was wavy and crumpled, so it is rebuilt as a faired loft that follows the AI hull's own sections (measured off the mesh:
# a flat deck plate overhanging a V hull, raked stem, a step in the keel), symmetric about the centreline, overlapping 1 cm into the hull at the seam
def bow_sec(x):
    s_ = max(0., min(1., (x - XT) / (XS + .010 - XT)))
    wd = max(.006, .124 * (1 - (1 - s_) ** 2.2)); wh = max(.004, min(wd - .008, .095 * s_ ** .9)); wk = max(.003, min(wh - .002, .05 * s_ * s_ + .006))
    zd, t = -.085, .007
    zk = -.102 - .098 * min(1., max(0., (s_ - .04) / .27)); zk += .014 * min(1., max(0., (x + .300) / .012))  # stem rake, then the keel step up
    zh = zd - t - .003; zc = zk + min(.012, (zh - zk) * .5)
    half = [(wd * .45, zd + .002), (wd * .97, zd), (wd, zd - .003), (wd, zd - t), (wh, zh), (min(wh, wk + .008), zc), (wk, zk)]
    return [(0, zd + .003)] + half + [(0, zk)] + [(-y, z) for y, z in reversed(half)]
import numpy as _np
loft('bow', [(float(x), bow_sec(float(x))) for x in _np.concatenate([_np.linspace(XT, XT + .03, 4), _np.linspace(XT + .04, XS + .010, 22)])], bevel=.0015); tag(RED)
# deck dressing from the concept: jackstaff with a spike at the tip, a forward-facing bow chaser (owner: bow guns may face forward),
# hatches, bollards along the deck edges and a pair of drums on each side at the foot of the superstructure
zdk = -.082
cyl('jackstaff', (XT + .032, 0, zdk + .026), .0035, .052, seg=12, bevel=0); cyl('jackspike', (XT + .032, 0, zdk + .057), .0042, .012, seg=12, r2=.0004, bevel=0); tag(STEEL)
cyl('chaserbase', (-.425, 0, zdk + .003), .016, .006, seg=24, bevel=.001); tag(STEEL)
box('chaserhouse', (-.425, 0, zdk + .012), (.026, .020, .012), bevel=.002); tag(RED)
for s_ in (1, -1): barrel(f'chaser{s_}', (-.436, s_ * .005, zdk + .013), (-1, 0, .04), .052, .0028)
tag(GUN)
box('hatch1', (-.370, 0, zdk + .0015), (.030, .026, .003), bevel=.0008); cyl('hatch2', (-.335, .045, zdk + .0015), .009, .003, seg=20, bevel=.0005); cyl('hatch3', (-.335, -.045, zdk + .0015), .009, .003, seg=20, bevel=.0005); tag(STEEL)
for x_ in (-.400, -.345, -.290):
    w_ = .124 * (1 - (1 - (x_ - XT) / (XS + .010 - XT)) ** 2.2)
    for s_ in (1, -1): cyl(f'bollard{x_}{s_}', (x_, s_ * (w_ - .012), zdk + .004), .0035, .008, seg=12, bevel=.0006)
tag(GUN)
for s_ in (1, -1):
    for k in (0, 1): cyl(f'deckdrum{s_}{k}', (-.278 + k * .024, s_ * .072, zdk + .010), .0095, .028, axis='Y', seg=24, bevel=.001)
    tag(STEEL)
    for k in (0, 1):
        for e in (1, -1): cyl(f'deckdrumring{s_}{k}{e}', (-.278 + k * .024, s_ * .072 + e * .009, zdk + .010), .0101, .002, axis='Y', seg=24, bevel=0)
    tag(GUN)
# aft side guns, one matched set per side (concept side view): an oval casemate on the flank with a long barrel aimed aft along the side,
# a long cannon on brackets above it, and on the stern deck a gun housing with twin barrels aimed aft, an orange lamp, and a row of deck lamps
def ellipsoid(name, c, r):
    b_ = bmesh.new(); bmesh.ops.create_uvsphere(b_, u_segments=32, v_segments=16, radius=1)
    for v in b_.verts: v.co = Vector((v.co.x * r[0], v.co.y * r[1], v.co.z * r[2]))
    bmesh.ops.translate(b_, verts=b_.verts, vec=c); return hs_lib._obj(name, b_, 0)
LAMP = (1.0, .30, .04)
for s_ in (1, -1):
    yf = SIDEF[(2, s_)] or .165
    box(f'casemate{s_}', (.192, s_ * (yf + .006), -.130), (.096, .034, .054), bevel=.011); tag(STEEL)  # armoured casemate, heavily rounded
    box(f'casematelid{s_}', (.196, s_ * (yf + .0235), -.122), (.070, .004, .022), bevel=.002); tag(GUN)
    for k in range(5): box(f'casemateband{s_}{k}', (.170 + k * .011, s_ * (yf + .0258), -.137), (.004, .002, .014), bevel=0)
    tag(DARK)
    a_ = Vector((.226, s_ * (yf + .018), -.133)); barrel(f'casegun{s_}', a_, (1, s_ * .05, -.01), .095, .0055); tag(GUN)
    y2 = (SIDEF[(2, s_)] or .165) + .0085
    cyl(f'longgun{s_}', (.240, s_ * y2, -.098), .0065, .175, axis='X', seg=20, bevel=.0008); cyl(f'longgunm{s_}', (.333, s_ * y2, -.098), .0085, .012, axis='X', seg=20, bevel=.0008)
    for k in range(4): cyl(f'longgunring{s_}{k}', (.175 + k * .045, s_ * y2, -.098), .0074, .004, axis='X', seg=20, bevel=0)
    tag(GUN)
    for xb in (.185, .290): box(f'longgunbracket{s_}{xb}', (xb, s_ * (y2 - .008), -.098), (.010, .012, .008), bevel=.001)
    tag(STEEL)
    # stern deck gun: housing on a pedestal, a heavy lower barrel and a lighter upper one, both aimed aft
    hz, _ = surf_down(.365, s_ * .070, .0); zdk_ = hz.z if hz is not None else -.068
    box(f'sternped{s_}', (.365, s_ * .070, (zdk_ + -.056) / 2), (.030, .022, max(.004, -.056 - zdk_ + .004)), bevel=.001); tag(STEEL)
    cyl(f'sternhouse{s_}', (.368, s_ * .070, -.044), .0125, .075, axis='X', seg=28, bevel=.0015); cyl(f'sterncap{s_}', (.331, s_ * .070, -.044), .0105, .004, axis='X', seg=28, bevel=.001); tag(STEEL)
    barrel(f'sternbig{s_}', (.404, s_ * .070, -.044), (1, 0, 0), .055, .0060); barrel(f'sternsmall{s_}', (.345, s_ * .070, -.027), (1, 0, 0), .100, .0040); tag(GUN)
    box(f'sternstrut{s_}', (.372, s_ * .070, -.034), (.008, .005, .012), bevel=0); tag(GUN)
    cyl(f'sternlamp{s_}', (.381, s_ * (.070 + .0125), -.041), .0055, .003, axis='Y', seg=20, bevel=0); tag(LAMP)
    for k in range(5):
        hz, _ = surf_down(.330 + k * .022, s_ * .100, .0); zl = hz.z if hz is not None else -.068
        cyl(f'decklamp{s_}{k}', (.330 + k * .022, s_ * .100, zl + .002), .0045, .004, seg=16, bevel=0)
        bm4 = bmesh.new(); bmesh.ops.create_uvsphere(bm4, u_segments=16, v_segments=8, radius=.0042)
        for v in bm4.verts: v.co.z = max(v.co.z, 0) * .8
        bmesh.ops.translate(bm4, verts=bm4.verts, vec=(.330 + k * .022, s_ * .100, zl + .004)); hs_lib._obj(f'decklampdome{s_}{k}', bm4, 0)
    tag(LAMP)
# side armour blocks: clean boxes on the measured faces, an inset panel and a vent row on each
for i, (x0, x1, z0, z1) in enumerate(SIDE):
    for s_ in (1, -1):
        y_ = SIDEF[(i, s_)]
        if y_ is None: continue
        box(f'sideblock{i}{s_}', ((x0 + x1) / 2, s_ * (y_ - .015), (z0 + z1) / 2), (x1 - x0, .030, z1 - z0), bevel=.004); tag(STEEL)
        box(f'sidepanel{i}{s_}', ((x0 + x1) / 2, s_ * (y_ + .001), (z0 + z1) / 2 + .006), (x1 - x0 - .022, .003, (z1 - z0) * .45), bevel=.001); tag(GUN)
        if i != 2:
            for k in range(6): box(f'sidevent{i}{s_}{k}', (x0 + .016 + k * .007, s_ * (y_ + .0012), z0 + .016), (.0035, .002, .014), bevel=0)
            tag(DARK)
# front armour plates: three shingled slabs down the slope under the bridge, with view slits on the top one
xs_ = [-.245, -.200, -.158, -.115]
for k in range(3):
    xa, xb = xs_[k], xs_[k + 1]; za, zb = prof(xa) + .006, prof(xb) + .006; a_ = math.atan2(zb - za, xb - xa); L_ = math.hypot(xb - xa, zb - za)
    nx, nz = -math.sin(a_), math.cos(a_); off = .002 * k
    box(f'frontplate{k}', ((xa + xb) / 2 + nx * off, 0, (za + zb) / 2 + nz * off), (L_ + .008, .150 - .012 * k, .012), rot=(0, -a_, 0), bevel=.002); tag(STEEL)
    box(f'frontlip{k}', (xa + nx * (off + .004), 0, za + nz * (off + .004)), (.006, .152 - .012 * k, .006), rot=(0, -a_, 0), bevel=.001); tag(GUN)
    if k == 2:
        for j in (-1, 0, 1): box(f'viewslit{j}', ((xa + xb) / 2 + nx * (off + .0065), j * .036, (za + zb) / 2 + nz * (off + .0065)), (.010, .024, .002), rot=(0, -a_, 0), bevel=0)
        tag(DARK)
# ventral thrusters (concept: three glowing nozzles under the midship), on a keel plate
for k, x_ in enumerate((-.015, .017, .049)):
    h = BVH.ray_cast(Vector((x_, 0, -.5)), Vector((0, 0, 1)), 1.0); zb_ = h[0].z if h[0] is not None else -.19
    box(f'thrplate{k}', (x_, 0, zb_ - .001), (.028, .030, .004), bevel=.0008); tag(GUN)
    cyl(f'thr{k}', (x_, 0, zb_ - .013), .0095, .022, seg=24, bevel=.001); cyl(f'thrbell{k}', (x_, 0, zb_ - .028), .0095, .010, r2=.0125, seg=24, bevel=0); tag(STEEL)
    cyl(f'thrglow{k}', (x_, 0, zb_ - .0325), .0088, .0015, seg=24, bevel=0); tag(LAMP)
# stern deckhouse: a clean low house with a door, vents and a roof hatch on the centreline
hz, _ = surf_down(.400, 0, .02); zsd = hz.z if hz is not None else -.068
box('sternhouse', (.373, 0, (zsd + -.022) / 2), (.135, .070, -.022 - zsd), bevel=.003); tag(RED)
box('sternroof', (.373, 0, -.020), (.127, .062, .004), bevel=.001); cyl('sternhatch', (.412, 0, -.017), .010, .003, seg=20, bevel=.0005); tag(STEEL)
box('sterndoor', (.4405, 0, (zsd + -.030) / 2), (.002, .022, -.030 - zsd - .006), bevel=0)
for k in range(8): box(f'sternvent{k}', (.325 + k * .012, .0355, -.034), (.006, .002, .010), bevel=0)
for k in range(8): box(f'sternventb{k}', (.325 + k * .012, -.0355, -.034), (.006, .002, .010), bevel=0)
tag(DARK)
# rear bulkhead closing the bay at the back of the superstructure: a sloped plate from the deckhouse roof up to the rack base, with a door
hz, _ = surf_down(.280, 0, .2); ztop = min(hz.z, .06) if hz is not None else .045
xa, za, xb, zb = .358, -.024, .282, ztop; a_ = math.atan2(zb - za, xb - xa); L_ = math.hypot(xb - xa, zb - za)
box('bulkhead', ((xa + xb) / 2, 0, (za + zb) / 2), (L_ + .006, .128, .010), rot=(0, -a_, 0), bevel=.002); tag(RED)
nx, nz = -math.sin(a_), math.cos(a_)
if nz < 0: nx, nz = -nx, -nz
box('bulkdoor', ((xa + xb) / 2 + nx * .0055 * (1 if nx > 0 else -1), 0, (za + zb) / 2 + abs(nz) * .0055), (L_ * .45, .030, .002), rot=(0, -a_, 0), bevel=0); tag(DARK)
for s_ in (1, -1): box(f'bulkrib{s_}', ((xa + xb) / 2, s_ * .052, (za + zb) / 2 + .004), (L_, .006, .010), rot=(0, -a_, 0), bevel=.001)
tag(STEEL)
# midship side tanks: clean capsules on the AI tank's axis, with two straps each
for s_ in (1, -1):
    ty, tz = TANK[s_]
    cyl(f'tank{s_}', (.020, s_ * ty, tz), .0125, .086, axis='X', seg=28, bevel=.0015); tag(STEEL)
    for e in (1, -1):
        b5 = bmesh.new(); bmesh.ops.create_uvsphere(b5, u_segments=28, v_segments=10, radius=.0125)
        for v in b5.verts: v.co.x = max(e * v.co.x, 0) * .6 * e
        bmesh.ops.translate(b5, verts=b5.verts, vec=(.020 + e * .043, s_ * ty, tz)); hs_lib._obj(f'tankend{s_}{e}', b5, 0)
    tag(STEEL)
    for e in (-1, 1): cyl(f'tankstrap{s_}{e}', (.020 + e * .024, s_ * ty, tz), .0133, .004, axis='X', seg=28, bevel=0)
    tag(GUN)
for o in hs_lib.PARTS:  # each part carries its colour as a vertex attribute, which survives the bevels and the join
    c = DARK if o.name.startswith('bore') or 'band' in o.name else COL.get(o.name, STEEL); a = o.data.color_attributes.new('Col', 'FLOAT_COLOR', 'POINT')
    for d in a.data: d.color = (c[0], c[1], c[2], 1)
kit = finish('C19_kit'); print('kit faces', len(kit.data.polygons))
try: kit.data.color_attributes.active_color_name = 'Col'
except Exception: kit.data.color_attributes.active_color = kit.data.color_attributes['Col']
bpy.ops.object.select_all(action='DESELECT'); kit.select_set(True); bpy.context.view_layer.objects.active = kit
bpy.ops.export_scene.gltf(filepath=pre + '_kit.glb', export_format='GLB', use_selection=True, export_vertex_color='ACTIVE', export_all_vertex_colors=True)
