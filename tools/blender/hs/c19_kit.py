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
    (-.114, .068, -.088, .088, .058, .140),  # bridge tier (to -.114: the AI lump at the bridge front, Rey audit), its drums and roof tank (owner, Oct 21: soft and blobby near the bridge)
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
SHELL = os.environ.get('SHELL', '0') == '1'
if SHELL:
    # v12 (owner, Oct 22: "the ship underneath looks mangled and wavy", picked "rebuild as clean shell"): the AI hull body becomes only a shape
    # guide. Its measured sections (tools: secs/meas on the 250k LOD, Oct 22) define a clean lofted shell: a superstructure of true sloped
    # planes on a deck shelf, a vertical chine band and a lower hull falling to the keel. The shell replaces the whole AI hull aft of the bow.
    # columns: x, top z, top half-width, deck z, superstructure foot half-width, deck/chine half-width, half-width at z -.16, keel half-width, keel z
    ST = [(-.240, -.074, .080, -.085, .095, .122, .056, .046, -.188), (-.220, -.030, .040, -.085, .110, .150, .060, .045, -.188),
          (-.180, .016, .045, -.085, .135, .155, .072, .044, -.188), (-.140, .037, .046, -.085, .145, .162, .084, .045, -.200),
          (-.110, .056, .050, -.085, .150, .165, .094, .050, -.212), (-.060, .056, .050, -.085, .150, .165, .100, .055, -.214),
          (.000, .056, .052, -.085, .155, .165, .108, .080, -.207), (.060, .056, .052, -.080, .155, .165, .110, .080, -.210),
          (.080, .033, .065, -.076, .155, .165, .095, .060, -.218), (.110, .030, .076, -.075, .152, .160, .125, .058, -.222),
          (.165, .030, .076, -.075, .152, .160, .130, .058, -.218), (.190, .052, .066, -.075, .152, .160, .132, .060, -.214),
          (.280, .056, .064, -.075, .152, .160, .132, .060, -.212), (.300, .048, .052, -.078, .150, .158, .130, .060, -.214),
          (.345, -.064, .128, -.066, .134, .145, .118, .034, -.150), (.400, -.066, .110, -.068, .116, .122, .090, .030, -.130),
          (.460, -.064, .094, -.066, .097, .100, .072, .030, -.116), (.492, -.066, .080, -.068, .082, .084, .060, .028, -.112)]
    def shell_sec(r):
        x, zt, wt, zf, wf, wc, wl, wk, zk = r; wt = min(wt, wf - .002)
        half = [(wt, zt), (wf, zf), (wc, zf - .002), (wc, zf - .014), (wl, max(-.16, zk + .02)), (wk, zk)]
        return (x, [(0, zt + .002)] + half + [(0, zk)] + [(-y, z) for y, z in reversed(half)])
    shell = loft('shell', [shell_sec(r) for r in ST], bevel=.0015); hs_lib.PARTS.remove(shell)
    bpy.context.view_layer.objects.active = shell
    for m in list(shell.modifiers): shell.select_set(True); bpy.ops.object.modifier_apply(modifier=m.name)
    sd = shell.modifiers.new('sd', 'SUBSURF'); sd.subdivision_type = 'SIMPLE'; sd.levels = sd.render_levels = int(os.environ.get('SHELL_SUB', '4')); bpy.ops.object.modifier_apply(modifier='sd')  # dense enough to carry projected paint (same shape)
    UPPER, LOWER = (.36, .075, .05), (.045, .045, .05)
    a = shell.data.color_attributes.new('Col', 'FLOAT_COLOR', 'POINT')
    for v, d in zip(shell.data.vertices, a.data): c = UPPER if v.co.z > -.094 else LOWER; d.color = (c[0], c[1], c[2], 1)
    bmS = bmesh.new(); bmS.from_mesh(shell.data); BVH0 = BVHTree.FromBMesh(bmS); bmS.free()  # every measurement and snap now uses the shell
    print('shell faces', len(shell.data.polygons))
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
        y_ = face_y(x0 + .01, x1 - .01, z0 + .01, z1 - .01, s_, 35) if not SHELL else (face_y(x0 + .01, x1 - .01, z0 + .01, z1 - .01, s_, 100) or .16) + .026; SIDEF[(i, s_)] = y_; print('side block', i, s_, y_)
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
    TANK[s_] = (best[0] - .011, best[1]) if best else (.10, -.005)
    if SHELL:
        h = BVH0.ray_cast(Vector((.02, s_ * .5, .005)), Vector((0, -s_, 0)), 1.0); TANK[s_] = ((abs(h[0].y) if h[0] is not None else .09) + .008, .005)
    print('tank', s_, TANK[s_])
def cut_extra(c):
    for i, (x0, x1, z0, z1) in enumerate(SIDE):
        y_ = SIDEF[(i, 1 if c.y > 0 else -1)]
        if y_ is not None and x0 - .003 <= c.x <= x1 + .003 and z0 - .003 <= c.z <= z1 + .003 and abs(c.y) >= y_ - .03: return True
    if -.245 <= c.x <= -.11 and abs(c.y) < .072 and prof(c.x) - .015 <= c.z <= prof(c.x) + .06: return True  # slope skin and the stick debris above it
    if -.10 <= c.x <= .13 and c.z < -.191: return True  # loose barrels hanging under the hull
    if .285 <= c.x <= .36 and abs(c.y) < .062 and -.024 <= c.z <= .06: return True  # the open bay at the back of the superstructure
    if .295 <= c.x <= .46 and abs(c.y) < .045 and -.066 <= c.z <= (-.024 if c.x < .355 else .03): return True  # stern deckhouse (and the dark open box ahead of it)
    ty, tz = TANK[1 if c.y > 0 else -1]
    if -.035 <= c.x <= .075 and abs(c.y) > ty - .006 and math.hypot(abs(c.y) - ty, c.z - tz) < .016: return True
    if .20 <= c.x <= .32 and .105 <= abs(c.y) <= .175 and .012 <= c.z <= .10: return True  # the old AI aft long guns beside the new ones
    return False
kill = []
for f in ([] if SHELL else bm.faces):
    c = f.calc_center_median()
    if any(b[0] <= c.x <= b[1] and b[2] <= c.y <= b[3] and b[4] <= c.z <= b[5] for b in BOXES) or any(seg_d(c, a, b) < .022 and c.z > a.z + .010 or seg_d(c, a, b) < .015 and c.z > a.z - .004 for a, b in GUNS) or cut_extra(c):
        kill.append(f)
bmesh.ops.delete(bm, geom=kill, context='FACES'); bm.to_mesh(hull.data); print('cut faces', len(kill))
BVH = BVH0 if SHELL else BVHTree.FromBMesh(bm); bm.free()
# placement rules (owner, Oct 21): every bolt-on sits on the real surface on a visible mount, guns point out and away from the hull,
# and parts come in matched pairs at sensible hard points (Corsair excepted, which may stay junky)
def surf_down(x, y, z_from=.3):  # deck height under (x, y)
    h = BVH.ray_cast(Vector((x, y, z_from)), Vector((0, 0, -1)), 1.0); return (h[0], h[1]) if h[0] is not None else (None, None)
def surf_in(x, y_side, z):  # flank point at height z, cast inward from outside the hull on side sign(y_side)
    s_ = 1 if y_side > 0 else -1; h = BVH.ray_cast(Vector((x, s_ * .4, z)), Vector((0, -s_, 0)), 1.0); return (h[0], h[1]) if h[0] is not None else (None, None)
if SHELL:
    bpy.ops.object.select_all(action='DESELECT'); shell.select_set(True); bpy.context.view_layer.objects.active = shell
    try: bpy.ops.object.shade_smooth_by_angle(angle=math.radians(35), keep_sharp_edges=True)
    except Exception: pass
    try: shell.data.color_attributes.active_color_name = 'Col'
    except Exception: pass
    bpy.ops.export_scene.gltf(filepath=pre + '_shell.glb', export_format='GLB', use_selection=True, export_vertex_color='ACTIVE', export_all_vertex_colors=True)
    bpy.data.objects.remove(hull)  # the AI hull is not exported at all
else:
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
hz, _ = surf_down(.202, 0, .07); zc0 = (hz.z - .003) if hz is not None else .047; cyl('column', (.202, 0, (zc0 + .097) / 2), .028, .097 - zc0, seg=32, bevel=.002); cyl('collar', (.202, 0, .096), .032, .006, seg=32, bevel=.001)
for k in range(int((.090 - zc0) / .012)): cyl(f'colrib{k}', (.202, 0, zc0 + .010 + k * .012), .0295, .003, seg=32, bevel=0)
for xe in (.150, .284):  # braces from the column collar out under each end of the frame (Rey audit: one off-centre post read wrong)
    d_ = Vector((xe, 0, .098)) - Vector((.202 + (.030 if xe > .202 else -.030), 0, .090)); barrel(f'rackbrace{xe}', Vector((.202 + (.030 if xe > .202 else -.030), 0, .090)), d_.normalized(), d_.length, .003)
tag(STEEL)
cyl('domebase', (.202, 0, .135), .011, .03, seg=24, bevel=.001); tag(RED)
bm2 = bmesh.new(); bmesh.ops.create_uvsphere(bm2, u_segments=24, v_segments=10, radius=.011)
for v in bm2.verts: v.co.z = max(v.co.z, 0) * .9
bmesh.ops.translate(bm2, verts=bm2.verts, vec=(.202, 0, .150)); hs_lib._obj('dome', bm2, 0); tag(RED)
# funnels: a slim one and a stout one, red with dark bands and caps
for nm, x, y, r, z0, z1 in (('fun1', .062, 0, .0064, .040, .168), ('fun2', .085, 0, .0118, .034, .156)):  # on the centreline, slim forward, stout aft (side view)
    hz, _ = surf_down(x, y, .062)
    if hz is not None: z0 = hz.z - .003  # stands on the deck, slightly sunk
    cyl(nm + 'base', (x, y, z0 + .003), r * 1.35, .006, seg=24, bevel=.001); tag(STEEL)
    cyl(nm, (x, y, (z0 + z1) / 2), r, z1 - z0, seg=24, bevel=.0012); tag(RED)
    for k in range(int((z1 - z0) / .018)): cyl(f'{nm}band{k}', (x, y, z0 + .012 + k * .018), r * 1.06, .003, seg=24, bevel=0)
    if nm == 'fun2':  # the stout stack has a domed cap in the concept
        bmd = bmesh.new(); bmesh.ops.create_uvsphere(bmd, u_segments=24, v_segments=10, radius=r * 1.04)
        for v in bmd.verts: v.co.z = max(v.co.z, 0) * .6
        bmesh.ops.translate(bmd, verts=bmd.verts, vec=(x, y, z1)); hs_lib._obj(nm + 'dome', bmd, 0); tag(STEEL)
    else:
        cyl(nm + 'cap', (x, y, z1 + .002), r * 1.12, .005, seg=24, bevel=.001); cyl(nm + 'bore', (x, y, z1 + .0047), r * .8, .001, seg=24, bevel=0); tag(DARK)
# mast (v11, audits): tall main mast with two yards spanning sideways and ball caps, a ladder facing the bow, a second mast with its own
# crossbar, and an angled pipe from the main mast down to a junction box on the roof; every end lands on a part
cyl('mast', (.035, 0, .181), .0035, .158, seg=12, bevel=0); cyl('mastspike', (.035, 0, .266), .0030, .012, seg=12, r2=.0004, bevel=0)
for zy, w_ in ((.205, .090), (.238, .066)):
    box(f'yard{zy}', (.035, 0, zy), (.004, w_, .004), bevel=0)
    for s_ in (1, -1):
        bmy = bmesh.new(); bmesh.ops.create_uvsphere(bmy, u_segments=10, v_segments=6, radius=.003); bmesh.ops.translate(bmy, verts=bmy.verts, vec=(.035, s_ * w_ / 2, zy)); hs_lib._obj(f'yardcap{zy}{s_}', bmy, 0)
cyl('mast2', (.009, 0, .151), .0028, .098, seg=12, bevel=0); box('mast2bar', (.009, 0, .185), (.0035, .060, .0035), bevel=0); cyl('mast2stub', (.009, 0, .210), .0012, .020, seg=6, bevel=0)
for s_ in (1, -1): cyl(f'ladrail{s_}', (.0295, s_ * .006, .153), .0009, .094, seg=6, bevel=0)
for k in range(8): box(f'ladrung{k}', (.0295, 0, .112 + k * .012), (.0016, .012, .0016), bevel=0)
box('lantern', (.035, 0, .225), (.010, .009, .014), bevel=.001)
pa, pb = Vector((.0318, -.002, .170)), Vector((-.030, -.020, .121)); barrel('mastpipe', pa, (pb - pa).normalized(), (pb - pa).length, .0028)
tag(STEEL)
# long guns: tapered barrels on ball mounts, leaning outboard
for i, (a, b) in enumerate(GUNS):
    d = (b - a); L = d.length; p_, n_ = surf_in(a.x, a.y, a.z)
    if p_ is not None:
        n_ = Vector(n_).normalized()
        if n_.dot(Vector((0, 1 if a.y > 0 else -1, 0))) < 0: n_ = -n_  # outward
        a = p_ + n_ * .006; d = (d.normalized() + n_ * .5).normalized() * L  # never aimed back into the hull
        Rn = Vector((0, 0, 1)).rotation_difference(n_).to_matrix(); cyl(f'gunplate{i}', p_ + n_ * .0012, .018, .003, seg=24, rot=Rn, bevel=.0008)  # wide enough to cover the cut AI base
    cyl(f'gunball{i}', a, .0085, .010, seg=20, bevel=.002)
    barrel(f'gun{i}', a, d.normalized(), L, .0034)
tag(GUN)
# bridge tier: armoured block with a sloped front, window band with a row of lights, roof rail, shoulder drums on saddles, roof tank
x0, x1, zb, zt = -.088, .059, .056, .102
box('plinth', ((x0 + x1) / 2 - .002, 0, zb + .002), (x1 - x0 + .028, .170, .014), bevel=.002); tag(STEEL)  # a little longer at the front, under the front drums
frustum('tier', ((x0 + x1) / 2, 0, zb), ((x1 - x0) / 2, .056), ((x1 - x0) / 2 - .010, .050), zt - zb, shear=(.010, 0), bevel=.003); tag(RED)
box('roof', ((x0 + x1) / 2 + .010, 0, zt + .002), (x1 - x0 - .018, .098, .004), bevel=.001); tag(RED)  # red like the concept (steel read as a pale slab in game)
sl = math.atan2(.020, zt - zb)  # front face leans back by this much
def xface(z): return x0 + .020 * (z - zb) / (zt - zb)  # x of the tier's front face at height z
nf = Vector((-math.cos(sl), 0, math.sin(sl)))  # its outward normal
Rf = Vector((0, 0, 1)).rotation_difference(nf).to_matrix()
for y_ in (.030, .006):  # two drums side by side at the foot of the front face, ends to the bow (concept)
    cyl(f'fdrum{y_}', (xface(.0765) - .011, y_, .0765), .0125, .022, axis='X', seg=28, bevel=.0015)
tag(STEEL)
for y_ in (.030, .006):
    cyl(f'fdrumring{y_}', (xface(.0765) - .016, y_, .0765), .0132, .003, axis='X', seg=28, bevel=0)
tag(GUN)
box('fwindow', (xface(.086) - .0006, -.022, .086), (.003, .016, .011), rot=(0, sl, 0), bevel=.0006); tag(GUN)
box('fwinglass', (xface(.086) - .0022, -.022, .086), (.001, .012, .008), rot=(0, sl, 0), bevel=0); tag(DARK)
cyl('fport', Vector((xface(.080), -.041, .080)) + nf * .001, .0055, .003, seg=20, rot=Rf, bevel=.0005); tag(GUN)
cyl('fportglass', Vector((xface(.080), -.041, .080)) + nf * .0026, .0040, .001, seg=20, rot=Rf, bevel=0); tag(DARK)
# light visor on the roof's front edge (replaces the band that floated off the face): a dark plate pitched nose-down on two feet, five lamps
xr = (x0 + x1) / 2 + .010 - (x1 - x0 - .018) / 2; vz = zt + .009; vp = math.radians(-32)
box('visor', (xr + .004, 0, vz), (.020, .072, .0025), rot=(0, vp, 0), bevel=.0005); tag(DARK)
for s_ in (1, -1): box(f'visorfoot{s_}', (xr + .008, s_ * .028, zt + .0055), (.004, .004, .007), bevel=0)
tag(GUN)
nv = Vector((math.sin(vp), 0, math.cos(vp)))
for k in range(5): box(f'vlamp{k}', Vector((xr + .004, -.026 + k * .013, vz)) + nv * .0016, (.008, .007, .0012), rot=(0, vp, 0), bevel=0)
tag((1.0, .30, .04))
for s_ in (1, -1):
    box(f'rail{s_}', ((x0 + x1) / 2 + .010, s_ * .047, zt + .009), (x1 - x0 - .024, .0016, .0016), bevel=0)
    for k in range(6): box(f'post{s_}{k}', (x0 + .016 + k * .024, s_ * .047, zt + .0065), (.0016, .0016, .007), bevel=0)
tag(STEEL)
for s_ in (1, -1):  # netted drum lying against each side wall of the tier, held by two wall brackets (concept side view)
    yw = .056 - .006 * (.078 - zb) / (zt - zb)  # tier half width at the drum's height
    cyl(f'drum{s_}', (-.0075, s_ * (yw + .0115), .078), .0125, .053, axis='X', seg=28, bevel=.0015); tag(STEEL)
    for k in (-1, 1): cyl(f'drumring{s_}{k}', (-.0075 + k * .018, s_ * (yw + .0115), .078), .0132, .003, axis='X', seg=28, bevel=0)
    for k in (-1, 1): box(f'drumbracket{s_}{k}', (-.0075 + k * .016, s_ * (yw + .002), .078), (.005, .006, .010), bevel=0)
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
def deckz(x, y):  # bow deck top at (x, |y|), from bow_sec (the deck falls from the centreline toward the edge)
    sec = bow_sec(x); top = sorted([p for p in sec[:4]], key=lambda p: p[0]); ya = abs(y)
    for (y0_, z0_), (y1_, z1_) in zip(top, top[1:]):
        if ya <= y1_: return z0_ + (z1_ - z0_) * (ya - y0_) / max(1e-9, y1_ - y0_)
    return top[-1][1]
cyl('jackstaff', (XT + .032, 0, deckz(XT + .032, 0) + .025), .0035, .052, seg=12, bevel=0); cyl('jackspike', (XT + .032, 0, deckz(XT + .032, 0) + .056), .0042, .012, seg=12, r2=.0004, bevel=0); tag(STEEL)
cyl('chaserbase', (-.425, 0, zdk + .003), .016, .006, seg=24, bevel=.001); tag(STEEL)
box('chaserhouse', (-.425, 0, zdk + .012), (.026, .034, .012), bevel=.002); tag(RED)
for s_ in (1, -1): barrel(f'chaser{s_}', (-.436, s_ * .012, zdk + .013), (-1, 0, .04), .050, .0028)  # .012 apart from the centreline: clear of the jackstaff (Codex audit)
tag(GUN)
box('hatch1', (-.370, 0, zdk + .0015), (.030, .026, .003), bevel=.0008); cyl('hatch2', (-.335, .045, deckz(-.335, .045) + .001), .009, .003, seg=20, bevel=.0005); cyl('hatch3', (-.335, -.045, deckz(-.335, -.045) + .001), .009, .003, seg=20, bevel=.0005); tag(STEEL)
for x_ in (-.400, -.345, -.290):
    w_ = .124 * (1 - (1 - (x_ - XT) / (XS + .010 - XT)) ** 2.2)
    for s_ in (1, -1): cyl(f'bollard{x_}{s_}', (x_, s_ * (w_ - .012), deckz(x_, w_ - .012) + .0035), .0035, .008, seg=12, bevel=.0006)
tag(GUN)
for s_ in (1, -1):
    for k in (0, 1): cyl(f'deckdrum{s_}{k}', (-.278 + k * .024, s_ * .072, deckz(-.278 + k * .024, .072) + .0088), .0095, .028, axis='Y', seg=24, bevel=.001)
    tag(STEEL)
    for k in (0, 1):
        for e in (1, -1): cyl(f'deckdrumring{s_}{k}{e}', (-.278 + k * .024, s_ * .072 + e * .009, deckz(-.278 + k * .024, .072) + .0088), .0101, .002, axis='Y', seg=24, bevel=0)
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
    a_ = Vector((.150, s_ * (yf + .018), -.133)); barrel(f'casegun{s_}', a_, (-1, s_ * .12, -.01), .095, .0055); tag(GUN)  # forward and outboard (owner, Oct 22: no ship fires backward)
    y2 = (SIDEF[(2, s_)] or .165) + .0085
    cyl(f'longgun{s_}', (.240, s_ * y2, -.098), .0065, .175, axis='X', seg=20, bevel=.0008); cyl(f'longgunm{s_}', (.147, s_ * y2, -.098), .0085, .012, axis='X', seg=20, bevel=.0008)  # muzzle forward
    for k in range(4): cyl(f'longgunring{s_}{k}', (.175 + k * .045, s_ * y2, -.098), .0074, .004, axis='X', seg=20, bevel=0)
    tag(GUN)
    for xb in (.185, .290): box(f'longgunbracket{s_}{xb}', (xb, s_ * (y2 - .008), -.098), (.010, .012, .008), bevel=.001)
    tag(STEEL)
    # stern deck gun: housing on a pedestal, a heavy lower barrel and a lighter upper one, both aimed aft
    hz, _ = surf_down(.365, s_ * .070, .0); zdk_ = hz.z if hz is not None else -.068
    box(f'sternped{s_}', (.365, s_ * .070, (zdk_ + -.056) / 2), (.030, .022, max(.004, -.056 - zdk_ + .004)), bevel=.001); tag(STEEL)
    # turned to fire outboard (broadside), not aft (owner, Oct 22)
    cyl(f'sternhouse{s_}', (.365, s_ * .072, -.044), .0125, .040, axis='Y', seg=28, bevel=.0015); cyl(f'sterncap{s_}', (.365, s_ * .0515, -.044), .0105, .004, axis='Y', seg=28, bevel=.001); tag(STEEL)
    barrel(f'sternbig{s_}', (.371, s_ * .092, -.044), (0, s_, .06), .050, .0060); barrel(f'sternsmall{s_}', (.357, s_ * .085, -.030), (0, s_, .10), .070, .0040); tag(GUN)
    box(f'sternstrut{s_}', (.360, s_ * .080, -.034), (.005, .008, .012), bevel=0); tag(GUN)
    cyl(f'sternlamp{s_}', (.379, s_ * .080, -.041), .0055, .003, axis='X', seg=20, bevel=0); tag(LAMP)
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
        if SHELL and i > 0:  # gun sponson (concept side view): dark housing under a sloped red hood, an opening with a stacked drum magazine,
            # three glowing thruster nozzles underneath; it reaches back into the hull so it is one piece with it
            xc = (x0 + x1) / 2; wy = y_ - .135
            box(f'spon{i}{s_}', (xc, s_ * (y_ - wy / 2), (z0 + z1) / 2), (x1 - x0, wy, z1 - z0), bevel=.003); tag((.07, .07, .075))
            ha = math.radians(28); box(f'sponhood{i}{s_}', (xc, s_ * (y_ - .012), z1 + .006), (x1 - x0 + .008, .040, .006), rot=(-s_ * ha, 0, 0), bevel=.0015); tag(RED)
            for k in range(6): box(f'sponhoodrib{i}{s_}{k}', (x0 + .012 + k * (x1 - x0 - .024) / 5, s_ * (y_ - .010), z1 + .0095), (.003, .036, .002), rot=(-s_ * ha, 0, 0), bevel=0)
            tag(DARK)
            box(f'sponopen{i}{s_}', (xc + .006, s_ * (y_ + .0006), (z0 + z1) / 2 + .004), (x1 - x0 - .040, .002, (z1 - z0) * .55), bevel=0); tag(DARK)
            for zz in (-.006, .010):
                cyl(f'spondrum{i}{s_}{zz}', (xc + .006, s_ * (y_ - .002), (z0 + z1) / 2 + .004 + zz), .0075, x1 - x0 - .048, axis='X', seg=24, bevel=.001)
            tag((.11, .08, .06))
            for k in (-1, 0, 1):
                nx_ = xc + k * .024; ny_ = s_ * (y_ - .016)
                cyl(f'sponthr{i}{s_}{k}', (nx_, ny_, z0 - .008), .0065, .016, seg=20, bevel=.0008); cyl(f'sponbell{i}{s_}{k}', (nx_, ny_, z0 - .020), .0065, .008, r2=.0090, seg=20, bevel=0); tag(STEEL)
                cyl(f'sponglow{i}{s_}{k}', (nx_, ny_, z0 - .0242), .0082, .0012, seg=20, bevel=0); tag(LAMP)
            continue
        box(f'sideblock{i}{s_}', ((x0 + x1) / 2, s_ * (y_ - .015), (z0 + z1) / 2), (x1 - x0, .030, z1 - z0), bevel=.004); tag(STEEL)
        box(f'sidepanel{i}{s_}', ((x0 + x1) / 2, s_ * (y_ + .001), (z0 + z1) / 2 + .006), (x1 - x0 - .022, .003, (z1 - z0) * .45), bevel=.001); tag(GUN)
        if i != 2:
            for k in range(6): box(f'sidevent{i}{s_}{k}', (x0 + .016 + k * .007, s_ * (y_ + .0012), z0 + .016), (.0035, .002, .014), bevel=0)
            tag(DARK)
if not SHELL:
    # front armour (v11, Rey audit + concept close-up): a stack of book-like steps climbing the front slope. Each step's tread tilts at half
    # the slope, its downhill face stands near vertical, widths shrink hard as they climb; steps 1 and 3 carry a raised rim with engraved
    # grooves, 2 and 4 are plain with one seam, step 5 is a laminate of three thin plates. Page-layer grooves on every front face.
    STEPS = [(-.242, .042, .152, .032), (-.205, .038, .140, .028), (-.172, .034, .126, .024), (-.143, .030, .108, .020)]
    SCOL = [(.055, .055, .060), (.030, .032, .040), (.060, .060, .065), (.045, .045, .050), (.065, .065, .070)]
    def slope_ang(x): return math.atan2(prof(x + .01) - prof(x - .01), .02)
    def step_frame(xf, ln):
        b_ = slope_ang(xf + ln / 2) / 2; F = Vector((xf, 0, prof(xf) - .002)); u = Vector((math.cos(b_), 0, math.sin(b_))); v = Vector((-math.sin(b_), 0, math.cos(b_)))
        return b_, F, u, v
    for k, (xf, ln, w_, h_) in enumerate(STEPS):
        b_, F, u, v = step_frame(xf, ln)
        box(f'step{k}', F + u * ln / 2 + v * h_ / 2, (ln + .005, w_, h_), rot=(0, -b_, 0), bevel=.0015); tag(SCOL[k])
        for s_ in (1, -1): box(f'stepcheek{k}{s_}', F + u * ln / 2 + v * (h_ / 2 - .004) + Vector((0, s_ * (w_ / 2 - .004), 0)), (ln + .004, .008, h_ + .008), rot=(0, -b_, 0), bevel=.001)
        tag(SCOL[k])
        for f_ in (1 / 3, 2 / 3): box(f'steppage{k}{f_:.2f}', F - u * .0004 + v * h_ * f_, (.0012, w_ - .004, .0015), rot=(0, -b_, 0), bevel=0)
        tag(DARK)
        T_ = F + v * (h_ + .00125)
        if k in (0, 2):  # raised perimeter rim, engraved grooves inside
            for s_ in (1, -1): box(f'steprim{k}{s_}', T_ + u * ln / 2 + Vector((0, s_ * (w_ / 2 - .005), 0)), (ln, .010, .0025), rot=(0, -b_, 0), bevel=.0004)
            for e_ in (.005, ln - .005): box(f'steprimx{k}{e_:.3f}', T_ + u * e_, (.010, w_, .0025), rot=(0, -b_, 0), bevel=.0004)
            tag(SCOL[k])
            for f_ in (.35, .5, .65): box(f'stepgroove{k}{f_}', F + v * (h_ + .0004) + u * ln * f_, (.0015, w_ * .55, .0008), rot=(0, -b_, 0), bevel=0)
            for g_ in range(4): box(f'stepblock{k}{g_}', F + v * (h_ + .0004) + u * ln * .5 + Vector((0, -.012 + g_ * .008, 0)), (.006, .0015, .0008), rot=(0, -b_, 0), bevel=0)
            tag(DARK)
        else:
            box(f'stepseam{k}', F + v * (h_ + .0003) + u * ln * .5, (.0015, w_ - .01, .0007), rot=(0, -b_, 0), bevel=0); tag(DARK)
    b_, F, u, v = step_frame(-.118, .024)
    for q, (wq, xo) in enumerate(((.088, 0), (.082, .002), (.076, .004))):  # step 5: a laminate of three thin plates
        box(f'lam{q}', F + u * (.012 + xo) + v * (.002 + .004 * q + .002), (.024 - xo, wq, .004), rot=(0, -b_, 0), bevel=.0008)
    tag(SCOL[4])
else:
    # front armour (v12, owner Oct 22 + concept close-up): four thick dark slabs lying along the front slope like books on a ramp, near
    # constant width, each starting just above the one below so its thick front edge shows; slabs 1 and 3 carry a raised rim around a recessed
    # engraved plaque, slab 2 is plain with two seams, the top one is small with a lip. Oval intakes either side, a hatch box at the foot.
    SL = [(-.246, .042, .104), (-.202, .034, .100), (-.166, .034, .096), (-.130, .026, .086)]
    for k, (xa, ln, w_) in enumerate(SL):
        xb = xa + ln; za, zb = prof(xa), prof(xb); a_ = math.atan2(zb - za, xb - xa); L_ = math.hypot(xb - xa, zb - za)
        u = Vector((math.cos(a_), 0, math.sin(a_))); v = Vector((-math.sin(a_), 0, math.cos(a_))); t_ = .017 - .002 * k
        F = Vector((xa, 0, za)); cen = F + u * L_ / 2 + v * (t_ / 2 - .002)
        box(f'fslab{k}', cen, (L_, w_, t_), rot=(0, -a_, 0), bevel=.0018); tag((.055, .055, .060))
        for f_ in (.35, .7): box(f'fslabpage{k}{f_}', F + v * (t_ * f_ - .002) - u * .0004, (.0012, w_ - .006, .0012), rot=(0, -a_, 0), bevel=0)
        tag(DARK)
        T_ = F + v * (t_ - .002)
        if k in (0, 2):
            for s_ in (1, -1): box(f'fslabrim{k}{s_}', T_ + u * L_ / 2 + v * .0011 + Vector((0, s_ * (w_ / 2 - .006), 0)), (L_ - .004, .008, .0022), rot=(0, -a_, 0), bevel=.0004)
            for e_ in (.006, L_ - .006): box(f'fslabrimx{k}{e_:.3f}', T_ + u * e_ + v * .0011, (.008, w_ - .004, .0022), rot=(0, -a_, 0), bevel=.0004)
            tag((.075, .072, .070))
            for g_ in range(5): box(f'fslabeng{k}{g_}', T_ + u * L_ * (.32 + g_ * .09) + v * .0003, (.0016, w_ * .45, .0007), rot=(0, -a_, 0), bevel=0)
            tag(DARK)
        elif k == 1:
            for f_ in (.33, .66): box(f'fslabseam{k}{f_}', T_ + u * L_ * f_ + v * .0003, (.0016, w_ - .01, .0007), rot=(0, -a_, 0), bevel=0)
            tag(DARK)
        else:
            box('fslablip', F + u * .003 + v * (t_ + .0005), (.006, w_ + .004, .004), rot=(0, -a_, 0), bevel=.0008); tag((.075, .072, .070))
    for s_ in (1, -1):  # oval intake on each side of the front slope, and a hatch box at the foot of the column
        p_, n_ = BVH.ray_cast(Vector((-.170, s_ * .5, -.020)), Vector((0, -s_, 0)), 1.0)[:2]
        if p_ is not None:
            n_ = Vector(n_).normalized(); n_ = n_ if n_.y * s_ > 0 else -n_; Rn = Vector((0, 0, 1)).rotation_difference(n_).to_matrix() @ Matrix.Diagonal((1.8, 1, 1))
            cyl(f'intake{s_}', Vector(p_) + n_ * .003, .0065, .008, seg=24, rot=Rn, bevel=.001); tag(STEEL)
            cyl(f'intakehole{s_}', Vector(p_) + n_ * .0072, .0050, .001, seg=24, rot=Rn, bevel=0); tag(DARK)
        hb = deckz(-.258, .040) if 'deckz' in globals() else -.085
        box(f'hatchbox{s_}', (-.262, s_ * .040, hb + .007), (.020, .022, .014), bevel=.0012); tag(STEEL)
        box(f'hatchboxlid{s_}', (-.266, s_ * .040, hb + .0146), (.012, .018, .0012), bevel=0); tag(DARK)
# ventral thrusters (concept: three glowing nozzles under the midship), on a keel plate
for k, x_ in enumerate(() if SHELL else (-.015, .017, .049)):
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
# bridge top (v11, Rey audit + concept): the density is vertical. One base plate on the roof's rear half carries the mast cluster (built
# above); the front half of the roof stays clean red behind the light visor. Two whips on the plate's rear corners, roof vents, a hatch,
# and the junction box the mast pipe lands on. No radar dish, searchlights or rangefinder: the concept has none.
ZR = zt + .004
box('mastplate', (.012, 0, ZR + .002), (.090, .090, .004), bevel=.0008); tag(STEEL)
ring('crowsnest', (.035, 0, .186), .014, .004); ring('crowrail', (.035, 0, .193), .014, .002)
cyl('crowfloor', (.035, 0, .1845), .014, .0015, seg=24, bevel=0)
for k in range(6): cyl(f'crowpost{k}', (.035 + .0135 * math.cos(k * math.pi / 3), .0135 * math.sin(k * math.pi / 3), .1895), .0007, .007, seg=6, bevel=0)
tag(STEEL)
box('junction', (-.030, -.020, ZR + .009), (.012, .012, .010), bevel=.0008); cyl('valve', (-.030, -.0138, ZR + .010), .006, .002, axis='Y', seg=16, bevel=0); tag(GUN)
for s_ in (1, -1): cyl(f'whip{s_}', (.050, s_ * .040, ZR + .004 + .025), .0011, .050, seg=6, bevel=0); cyl(f'whipbase{s_}', (.050, s_ * .040, ZR + .005), .003, .002, seg=12, bevel=0)
tag(STEEL)
for s_ in (1, -1):
    box(f'roofvent{s_}', (.016, s_ * .030, ZR + .008), (.018, .012, .008), bevel=.0008); tag(STEEL)
    for k in range(4): box(f'roofslat{s_}{k}', (.009 + k * .0047, s_ * .030, ZR + .0123), (.002, .010, .0008), bevel=0)
    tag(DARK)
cyl('roofhatch', (-.008, .028, ZR + .007), .007, .006, seg=20, bevel=.0005); tag(STEEL)
box('greeble', (.020, 0, ZR + .008), (.010, .008, .008), bevel=.0008); tag(GUN)
if SHELL:
    # designed hull detail on the clean shell (concept side view): a rub rail along the deck shelf, two belt ledges on the superstructure
    # slope, a row of dark ports under the upper ledge, inset hatch panels and vent grilles between the guns, and plate seams. All flush to
    # the shell (snapped with rays, oriented to its surface normal), all in matched pairs.
    def flank(x, z, s_):
        h = BVH.ray_cast(Vector((x, s_ * .5, z)), Vector((0, -s_, 0)), 1.0)
        if h[0] is None: return None, None
        n = Vector(h[1]).normalized(); n = n if n.y * s_ > 0 else -n; return Vector(h[0]), n
    def plate(name, x, z, s_, size, lift=.0008):  # a thin box lying on the shell at (x, z), size = (length along x, height up the slope, thickness)
        p_, n = flank(x, z, s_)
        if p_ is None: return False
        up = Vector((0, 0, 1)) - n * n.z; up.normalize(); fx = Vector((1, 0, 0)) - n * n.x; fx.normalize(); up = n.cross(fx) * (1 if n.cross(fx).z > 0 else -1)
        M = Matrix((fx, up, n)).transposed(); bm_ = bmesh.new(); bmesh.ops.create_cube(bm_, size=1); bmesh.ops.scale(bm_, vec=size, verts=bm_.verts)
        bmesh.ops.transform(bm_, matrix=M.to_4x4(), verts=bm_.verts); bmesh.ops.translate(bm_, verts=bm_.verts, vec=p_ + n * (size[2] / 2 - lift)); hs_lib._obj(name, bm_, .0006); return True
    for s_ in (1, -1):
        for i in range(0, len(ST) - 1):  # rub rail along the deck shelf edge, segment by segment
            a_, b_ = ST[i], ST[i + 1]; pa = Vector((a_[0], s_ * (a_[5] + .002), a_[3] - .004)); pb = Vector((b_[0], s_ * (b_[5] + .002), b_[3] - .004))
            if (pb - pa).length > .001: barrel(f'rubrail{s_}{i}', pa, (pb - pa).normalized(), (pb - pa).length, .0035)
        tag(UPPER)
        for zl in (-.050, -.005):  # belt ledges on the superstructure slope
            for k in range(30):
                x = -.105 + k * .0135
                if x > .295: break
                plate(f'ledge{s_}{zl}{k}', x, zl, s_, (.0145, .004, .004))
        tag(UPPER)
        for k in range(44):  # row of dark round-ish holes under the upper ledge (concept)
            x = -.100 + k * .009
            if x > .29 or .065 < x < .17: continue
            plate(f'port{s_}{k}', x, -.020, s_, (.0042, .0042, .0014))
        tag(DARK)
        for k in range(60):  # rivet line along the top edge of the superstructure side
            x = -.105 + k * .0068
            if x > .295: break
            plate(f'rivet{s_}{k}', x, .030 if not (.065 < x < .17) else .012, s_, (.0022, .0022, .0018))
        tag((.20, .07, .05))
        plate(f'nameplate{s_}', -.165, -.050, s_, (.070, .030, .0030)); tag((.13, .13, .135))  # big riveted name plate (concept)
        for k in range(12): plate(f'nprivet{s_}{k}', -.198 + k * .006, -.0375, s_, (.0018, .0018, .0040)); plate(f'nprivetb{s_}{k}', -.198 + k * .006, -.0625, s_, (.0018, .0018, .0040))
        for k in range(3): plate(f'npline{s_}{k}', -.165, -.056 + k * .0055, s_, (.052, .0016, .0036))
        tag(DARK)
        p_, n_ = BVH.ray_cast(Vector((-.205, s_ * .5, -.030)), Vector((0, -s_, 0)), 1.0)[:2]  # round porthole near the front
        if p_ is not None:
            n_ = Vector(n_).normalized(); n_ = n_ if n_.y * s_ > 0 else -n_; Rn = Vector((0, 0, 1)).rotation_difference(n_).to_matrix()
            cyl(f'porthole{s_}', Vector(p_) + n_ * .0008, .0065, .0025, seg=24, rot=Rn, bevel=.0004); tag(STEEL)
            cyl(f'portglass{s_}', Vector(p_) + n_ * .0022, .0046, .001, seg=24, rot=Rn, bevel=0); tag(DARK)
        plate(f'bayframe{s_}', .118, -.040, s_, (.060, .040, .0050)); tag(RED)  # framed bay in the middle dip (concept side view)
        plate(f'bayopen{s_}', .118, -.042, s_, (.046, .026, .0062)); tag(DARK)
        plate(f'baybox{s_}', .118, -.044, s_, (.020, .012, .0090)); tag(STEEL)
        for x in (-.085, .115, .235):  # inset hatch panels with a dark frame
            plate(f'hatchf{s_}{x}', x, -.072, s_, (.034, .024, .0012)); tag(DARK)
            plate(f'hatch{s_}{x}', x, -.072, s_, (.030, .020, .0024)); tag(STEEL)
        for x in (.025, .175):  # vent grilles
            for k in range(6): plate(f'grille{s_}{x}{k}', x - .0125 + k * .005, -.075, s_, (.0025, .016, .002))
            tag(DARK)
        for x in (-.03, .05, .14, .21, .27):  # vertical plate seams on the slope
            for k in range(7): plate(f'seam{s_}{x}{k}', x, -.085 + k * .011, s_, (.0012, .0115, .0008), lift=.0004)
        tag(DARK)
for o in hs_lib.PARTS:  # each part carries its colour as a vertex attribute, which survives the bevels and the join
    c = DARK if o.name.startswith('bore') or 'band' in o.name else COL.get(o.name, STEEL); a = o.data.color_attributes.new('Col', 'FLOAT_COLOR', 'POINT')
    for d in a.data: d.color = (c[0], c[1], c[2], 1)
kit = finish('C19_kit'); print('kit faces', len(kit.data.polygons))
try: kit.data.color_attributes.active_color_name = 'Col'
except Exception: kit.data.color_attributes.active_color = kit.data.color_attributes['Col']
bpy.ops.object.select_all(action='DESELECT'); kit.select_set(True); bpy.context.view_layer.objects.active = kit
bpy.ops.export_scene.gltf(filepath=pre + '_kit.glb', export_format='GLB', use_selection=True, export_vertex_color='ACTIVE', export_all_vertex_colors=True)
