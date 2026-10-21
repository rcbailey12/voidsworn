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
GUNS = []  # (base, tip)
for x0, x1 in ((-.045, -.059), (.248, .250)):
    for s in (1, -1): GUNS.append((Vector((x0, s * .100, .006)), Vector((x1, s * .145, .080))))
BOXES = [  # (x0, x1, y0, y1, z0, z1): AI geometry to cut away (all above the deck or tower roof)
    (.130, .300, -.065, .065, .076, .170),   # rocket rack
    (.176, .228, -.030, .030, .062, .170),   # rack column and dome
    (.054, .097, -.030, .030, .062, .172),   # funnels
    (-.012, .062, -.040, .040, .110, .250),  # mast
    (-.100, .068, -.088, .088, .058, .140),  # bridge tier, its drums and roof tank (owner, Oct 21: soft and blobby near the bridge)
]
def seg_d(p, a, b):
    ab = b - a; t = max(0, min(1, (p - a).dot(ab) / ab.length_squared)); return (a + ab * t - p).length
bm = bmesh.new(); bm.from_mesh(hull.data); kill = []
for f in bm.faces:
    c = f.calc_center_median()
    if any(b[0] <= c.x <= b[1] and b[2] <= c.y <= b[3] and b[4] <= c.z <= b[5] for b in BOXES) or any(seg_d(c, a, b) < .012 and c.z > a.z + .012 for a, b in GUNS):
        kill.append(f)
bmesh.ops.delete(bm, geom=kill, context='FACES'); bm.to_mesh(hull.data); print('cut faces', len(kill))
from mathutils.bvhtree import BVHTree
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
# rocket rack: two rows of seven launch tubes across the ship, on a column with a domed cap
R = Matrix.Rotation(math.pi / 2, 3, 'Z')  # tubes() runs its tubes along its local X; turn them to run across the ship (y)
for row, z in enumerate((.113, .091)):
    for k in range(7):
        x = .217 + (k - 3) * .0202
        cyl(f'tube{row}{k}', (x, 0, z), .0094, .085, axis='Y', seg=20, bevel=.0012)
        for s in (1, -1): cyl(f'bore{row}{k}{s}', (x, s * .0428, z), .0068, .002, axis='Y', seg=20, bevel=0)
tag(GUN)
box('rackframe', (.217, 0, .102), (.150, .07, .006), bevel=.0015); box('rackcheek1', (.144, 0, .102), (.006, .088, .04), bevel=.0015); box('rackcheek2', (.290, 0, .102), (.006, .088, .04), bevel=.0015); tag(STEEL)
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
box('roof', ((x0 + x1) / 2 + .010, 0, zt + .002), (x1 - x0 - .018, .098, .004), bevel=.001); tag(STEEL)
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
for o in hs_lib.PARTS:  # each part carries its colour as a vertex attribute, which survives the bevels and the join
    c = DARK if o.name.startswith('bore') or 'band' in o.name else COL.get(o.name, STEEL); a = o.data.color_attributes.new('Col', 'FLOAT_COLOR', 'POINT')
    for d in a.data: d.color = (c[0], c[1], c[2], 1)
kit = finish('C19_kit'); print('kit faces', len(kit.data.polygons))
try: kit.data.color_attributes.active_color_name = 'Col'
except Exception: kit.data.color_attributes.active_color = kit.data.color_attributes['Col']
bpy.ops.object.select_all(action='DESELECT'); kit.select_set(True); bpy.context.view_layer.objects.active = kit
bpy.ops.export_scene.gltf(filepath=pre + '_kit.glb', export_format='GLB', use_selection=True, export_vertex_color='ACTIVE', export_all_vertex_colors=True)
