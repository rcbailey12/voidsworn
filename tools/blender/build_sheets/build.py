# Build sheet driver (issue 532). Usage, inside Blender or with the bpy module:
#   blender -b -P tools/blender/build_sheets/build.py -- <code> <outdir> [render|mesh|blend] [--quick]
# render: builds the blockout, saves <outdir>/<code>_blockout.blend, renders every view (side, top, underside, bow, stern,
#         the standard three-quarter, the fitted beauty camera, the side cutaway) and writes <code>_model.json.
# mesh:   builds and writes <code>_tris.npz (exterior triangles) for the outline fit, no renders.
# fit:    builds, runs the fit check (clash.py) and writes <code>_fit.json and <code>_model.json, no renders.
# render runs the fit check too (round 3, R217).
import sys, os, json, math, importlib.util
import bpy
from mathutils import Vector, Matrix

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import kit  # noqa: E402

argv = sys.argv[sys.argv.index('--') + 1:] if '--' in sys.argv else sys.argv[1:]
CODE, OUT = argv[0], argv[1]
MODE = argv[2] if len(argv) > 2 else 'render'
QUICK = '--quick' in argv
os.makedirs(OUT, exist_ok=True)

spec = importlib.util.spec_from_file_location(CODE, os.environ.get('SHIP_FILE') or os.path.join(HERE, 'ships', CODE + '.py'))
ship = importlib.util.module_from_spec(spec); spec.loader.exec_module(ship)

bpy.ops.wm.read_factory_settings(use_empty=True)
sc = bpy.context.scene
K = kit.Kit(CODE, ship.LENGTH)
ship.build(K)
K.finish()
bpy.context.view_layer.update()
import clash  # noqa: E402


def ext_objects():
    return [o for o in K.coll.objects if o.type == 'MESH']


def bbox(objs):
    lo = Vector((1e9, 1e9, 1e9)); hi = Vector((-1e9, -1e9, -1e9))
    dg = bpy.context.evaluated_depsgraph_get()
    for o in objs:
        e = o.evaluated_get(dg)
        for v in e.data.vertices:
            w = o.matrix_world @ v.co
            lo = Vector(map(min, lo, w)); hi = Vector(map(max, hi, w))
    return lo, hi


LO, HI = bbox(ext_objects())
MODEL_LEN = HI.x - LO.x
XTIP = HI.x
print('model extents', tuple(LO), tuple(HI), 'length', MODEL_LEN)


def tris(objs):
    dg = bpy.context.evaluated_depsgraph_get(); out = []
    for o in objs:
        e = o.evaluated_get(dg); me = e.to_mesh(); me.calc_loop_triangles()
        mw = o.matrix_world
        for t in me.loop_triangles:
            out.append([tuple(mw @ me.vertices[i].co) for i in t.vertices])
        e.to_mesh_clear()
    return out


def r3(v):
    return [round(float(c), 3) for c in v]


def write_model():
    model = dict(code=CODE, name=ship.NAME, faction=ship.FACTION, cls=ship.CLASS, length=ship.LENGTH, game=ship.GAME,
                 beauty=ship.BEAUTY, model_length=round(MODEL_LEN, 3), x_tip=round(XTIP, 3), lo=r3(LO), hi=r3(HI), views=views,
                 features=[], masses=[], inside=K.inside, points=[], changes=K.changes, tbd=K.tbd)
    for f in K.features:
        g = dict(f)
        for k in ('pos', 'end', 'tip', 'exit'):
            if g.get(k) is not None:
                g[k] = r3(g[k])
        if 'muzzle' in g:
            g['muzzle'] = [r3(m) for m in g['muzzle']]
        g['station'] = round((XTIP - f['pos'][0]) / MODEL_LEN * 100, 1)
        model['features'].append(g)
    for m in K.masses:
        ob = bpy.data.objects[m['obj']]
        lo, hi = bbox([ob])
        model['masses'].append(dict(m, st=(round((XTIP - hi.x) / MODEL_LEN * 100, 1), round((XTIP - lo.x) / MODEL_LEN * 100, 1)),
                                    y=(round(lo.y, 2), round(hi.y, 2)), z=(round(lo.z, 2), round(hi.z, 2))))
    for p in K.points:
        model['points'].append(dict(p, pos=r3(p['pos']), station=round((XTIP - p['pos'][0]) / MODEL_LEN * 100, 1)))
    model['parts'] = K.built
    model['fit_counts'] = FIT['counts']
    json.dump(model, open(os.path.join(OUT, CODE + '_model.json'), 'w'), indent=1)


views = {}
FIT = clash.run(K, OUT, CODE, ship.LENGTH) if MODE in ('fit', 'render') else dict(counts={})
if MODE == 'fit':
    write_model()
    sys.exit(0)

if MODE == 'mesh':
    import numpy as np
    np.savez_compressed(os.path.join(OUT, CODE + '_tris.npz'), tris=np.array(tris(ext_objects()), dtype='float32'))
    json.dump([dict(id=f['id'], pos=list(f['pos']), tip=list(f.get('muzzle', [f.get('tip') or f['pos']])[0])) for f in K.features],
              open(os.path.join(OUT, CODE + '_marks.json'), 'w'))
    sys.exit(0)

# ---------------- scene: one key light, one fill, flat grey ground added in the layout ----------------
world = bpy.data.worlds.new('w'); sc.world = world; world.use_nodes = True
world.node_tree.nodes['Background'].inputs[0].default_value = (0.2, 0.2, 0.2, 1)
world.node_tree.nodes['Background'].inputs[1].default_value = 0.7


def sun(name, toward, strength, angle=4.0):
    l = bpy.data.lights.new(name, 'SUN'); l.energy = strength; l.angle = math.radians(angle)
    o = bpy.data.objects.new(name, l); sc.collection.objects.link(o)
    d = Vector(toward).normalized()  # direction the light comes FROM
    o.rotation_euler = d.to_track_quat('Z', 'Y').to_euler()
    return o


# key: from forward, port and above (45 up, 45 to port of the bow); fill: a fifth of the key from aft-starboard
sun('key', (math.cos(math.radians(45)) * math.cos(math.radians(45)), math.cos(math.radians(45)) * math.sin(math.radians(45)),
            math.sin(math.radians(45))), 4.0)
sun('fill', (-0.66, -0.66, -0.35), 0.8, angle=20)

sc.render.engine = 'CYCLES'
sc.cycles.device = 'GPU' if os.name == 'nt' else 'CPU'
if os.name == 'nt':
    try:
        prefs = bpy.context.preferences.addons['cycles'].preferences
        prefs.compute_device_type = 'OPTIX'; prefs.get_devices()
        for d in prefs.devices:
            d.use = True
    except Exception as ex:
        print('gpu setup', ex)
sc.cycles.samples = int(os.environ.get('SHEET_SAMPLES', 8 if QUICK else 48))
sc.cycles.use_denoising = True
sc.render.film_transparent = True
sc.view_settings.view_transform = 'Standard'
sc.render.image_settings.file_format = 'PNG'
sc.render.image_settings.color_mode = 'RGBA'

PX_PER_UNIT = 40 if QUICK else 80  # one scale for every orthographic view


def cam(name, loc, right, up, ortho=None, persp_mm=None, res=(1000, 1000), clip=(0.1, 500), shift=(0, 0)):
    c = bpy.data.cameras.new(name)
    o = bpy.data.objects.new(name, c); sc.collection.objects.link(o)
    r = Vector(right).normalized(); u = Vector(up).normalized(); b = r.cross(u)
    o.matrix_world = Matrix((
        (r.x, u.x, b.x, loc[0]), (r.y, u.y, b.y, loc[1]), (r.z, u.z, b.z, loc[2]), (0, 0, 0, 1)))
    if ortho:
        c.type = 'ORTHO'; c.ortho_scale = ortho
    else:
        c.lens = persp_mm; c.sensor_width = 36; c.sensor_fit = 'HORIZONTAL'
    c.clip_start, c.clip_end = clip
    c.shift_x, c.shift_y = shift
    sc.render.resolution_x, sc.render.resolution_y = res
    return o


def render(o, res, path, inside=False, outside=True):
    sc.camera = o
    sc.render.resolution_x, sc.render.resolution_y = res
    sc.render.resolution_percentage = 100
    for ob in K.cin.objects:
        ob.hide_render = not inside
    for ob in K.coll.objects:
        ob.hide_render = not outside
    sc.render.filepath = path
    bpy.ops.render.render(write_still=True)


# ortho views: window centred on the model, one px-per-unit for all
cx, cy, cz = (LO.x + HI.x) / 2, (LO.y + HI.y) / 2, (LO.z + HI.z) / 2
pad = 1.0
Lx, Ly, Lz = HI.x - LO.x + 2 * pad, HI.y - LO.y + 2 * pad, HI.z - LO.z + 2 * pad
views = {}


def ortho_view(name, loc, right, up, w_units, h_units, cen, clip=(0.1, 500)):
    res = (int(round(w_units * PX_PER_UNIT)), int(round(h_units * PX_PER_UNIT)))
    scale = max(w_units, h_units)
    o = cam(name, loc, right, up, ortho=scale, res=res, clip=clip)
    views[name] = dict(cam=name, res=res, px_per_unit=PX_PER_UNIT, right=tuple(right), up=tuple(up), centre=tuple(cen),
                       w_units=w_units, h_units=h_units)
    return o, res


D = 100.0
# side: on the port beam, bow left (camera at +Y looking -Y: screen right = -X)
o, res = ortho_view('side', (cx, cy + D, cz), (-1, 0, 0), (0, 0, 1), Lx, Lz, (cx, cy, cz))
render(o, res, os.path.join(OUT, 'side.png'))
# cutaway: the same camera, clipped at the centreline (y = 0): the near (port) half removed
o, res = ortho_view('cutaway', (cx, D, cz), (-1, 0, 0), (0, 0, 1), Lx, Lz, (cx, 0, cz), clip=(D, 500))
for ob in list(K.coll.objects) + list(K.cin.objects):
    ob.visible_shadow = False  # the cut-open hull must not shade its own insides
render(o, res, os.path.join(OUT, 'cutaway.png'), inside=True, outside=True)
for ob in list(K.coll.objects) + list(K.cin.objects):
    ob.visible_shadow = True
# top: overhead, bow up the page, port on the left (camera at +Z looking -Z, screen right = -Y, up = +X)
o, res = ortho_view('top', (cx, cy, cz + D), (0, -1, 0), (1, 0, 0), Ly, Lx, (cx, cy, cz))
render(o, res, os.path.join(OUT, 'top.png'))
# underside: from below, bow up the page, port on the right (as seen looking up)
o, res = ortho_view('underside', (cx, cy, cz - D), (0, 1, 0), (1, 0, 0), Ly, Lx, (cx, cy, cz))
render(o, res, os.path.join(OUT, 'underside.png'))
# bow-on: camera ahead looking aft, port on the right
o, res = ortho_view('bow', (cx + D, cy, cz), (0, 1, 0), (0, 0, 1), Ly, Lz, (cx, cy, cz))
render(o, res, os.path.join(OUT, 'bow.png'))
# engine end: camera astern looking forward, port on the left
o, res = ortho_view('stern', (cx - D, cy, cz), (0, -1, 0), (0, 0, 1), Ly, Lz, (cx, cy, cz))
render(o, res, os.path.join(OUT, 'stern.png'))


def look_cam(name, az, el, dist, mm, res, target, roll=0.0, shift=(0, 0)):
    """az from the bow toward port, el above the deck plane"""
    a, e = math.radians(az), math.radians(el)
    d = Vector((math.cos(e) * math.cos(a), math.cos(e) * math.sin(a), math.sin(e)))
    loc = Vector(target) + d * dist
    f = -d
    right = f.cross(Vector((0, 0, 1))).normalized(); up = right.cross(f).normalized()
    rr = math.radians(roll)
    right, up = right * math.cos(rr) + up * math.sin(rr), up * math.cos(rr) - right * math.sin(rr)
    return cam(name, loc, right, up, persp_mm=mm, res=res, shift=shift)


# standard three-quarter: 45 degrees off the bow toward port, 30 above, bow left
o = look_cam('threequarter', 45, 30, 120, 50 * 120 / (1.5 * ship.LENGTH) * 0.9, (1600, 1000), (cx, cy, cz))
render(o, (int(1600 * (0.5 if QUICK else 1)), int(1000 * (0.5 if QUICK else 1))), os.path.join(OUT, 'threequarter.png'))
# the fitted beauty camera (written by fit.py), for the outline check
fitp = os.path.join(HERE, 'ships', CODE + '_camera.json')
if os.path.exists(fitp):
    fc = json.load(open(fitp))
    o = look_cam('beauty_cam', fc['az'], fc['el'], fc['dist'], fc['mm'], tuple(fc['res']), fc['target'], fc.get('roll', 0),
                 (-fc.get('sx', 0), -fc.get('sy', 0)))  # fit.py moves the picture, Blender's shift moves the frame
    render(o, tuple(fc['res']), os.path.join(OUT, 'beauty_cam.png'))


write_model()
blend = os.path.join(OUT, CODE + '_blockout.blend')
bpy.ops.wm.save_as_mainfile(filepath=blend)
print('WROTE', blend)
