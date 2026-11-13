# The painted sheet ship beside its concept (issue 601): renders a stage 5 painted blend (tools/blender/r209/bake_sheet.py) at
# the build sheet's own beauty camera (ships/<sheet>_camera.json, fitted to the concept) and at the region windows of the
# sheet's side_by_side.jpg, under the GAME's light (godot/render/look.gd: key 2.0 from KEY_DIR, fill a quarter, cool ambient,
# AgX) with the faction's battle albedo lift (R227: Hullbreakers 1.25), then lays each beside the concept at the same camera.
# One picture per item, its code name on it, 1280 wide and no taller than 720 (RULEBOOK 1.2).
# usage: blender -b CELL.blend -P paint_sheet.py -- OUT_DIR SHEET CONCEPT_JPG [lift=1.25] [samples=32] [scale=0.5] [gpu=1] [sky_spec=0]
#        (python3 with the bpy module works the same: python3 paint_sheet.py CELL.blend OUT_DIR SHEET CONCEPT_JPG ...)
import os, sys, math, json
import bpy
from mathutils import Vector, Matrix

HERE = os.path.dirname(os.path.abspath(__file__))
if '--' in sys.argv:
    a = sys.argv[sys.argv.index('--') + 1:]
else:
    a = sys.argv[1:]; bpy.ops.wm.open_mainfile(filepath=a.pop(0))
OUT, SHEET, CONCEPT = a[0], a[1], a[2]
kw = dict(x.split('=', 1) for x in a[3:] if '=' in x)
LIFT = float(kw.get('lift', 1.25)); SAMP = int(kw.get('samples', 32)); SCALE = float(kw.get('scale', .5))
os.makedirs(OUT, exist_ok=True)
sc = bpy.context.scene
S = float(sc.get('r209_scale', 1.0))      # the build contract's scale: sheet world units to the recipe's length one

# the game's light (as tools/blender/r209/preview7.py light=game): Godot y up, the ship frame z up: (x, y, z)_godot -> (x, -z, y)
sc.render.engine = 'CYCLES'; sc.cycles.samples = SAMP; sc.cycles.use_denoising = True
if kw.get('gpu') == '1':
    try:
        prefs = bpy.context.preferences.addons['cycles'].preferences
        for t in ('OPTIX', 'CUDA'):
            try:
                prefs.compute_device_type = t; prefs.get_devices()
                if [d for d in prefs.devices if d.type == t]:
                    for d in prefs.devices: d.use = True
                    sc.cycles.device = 'GPU'; break
            except Exception: pass
    except Exception: pass
sc.view_settings.view_transform = 'AgX'; sc.view_settings.exposure = 0.0
w = bpy.data.worlds.new('game'); sc.world = w; w.use_nodes = True; bg = w.node_tree.nodes['Background']
bg.inputs['Color'].default_value = (.86 * .5, .9 * .5, 1.0 * .5, 1)
lp = w.node_tree.nodes.new('ShaderNodeLightPath'); mx = w.node_tree.nodes.new('ShaderNodeMixShader')
bk = w.node_tree.nodes.new('ShaderNodeBackground'); bk.inputs['Color'].default_value = (.004, .004, .005, 1)
out = w.node_tree.nodes['World Output']
w.node_tree.links.new(lp.outputs['Is Camera Ray'], mx.inputs[0]); w.node_tree.links.new(bg.outputs[0], mx.inputs[1])
w.node_tree.links.new(bk.outputs[0], mx.inputs[2]); w.node_tree.links.new(mx.outputs[0], out.inputs[0])
if kw.get('sky_spec') == '0':
    # issue 642: the battle reflects its dark sky (godot/scenes/battle/battle.gd: reflected light from the dead-star sky, near
    # black), so the ambient lights a hull's diffuse colour and not its specular. On a very dark albedo (the Eclipse under its 2.2
    # lift) the uniform world's grey specular sheen outweighed the colour in the preview; sky_spec=0 lets glossy rays see the dark
    # background instead, as the game does. Off by default: the pictures of the accepted ships stay as they were made.
    gl = w.node_tree.nodes.new('ShaderNodeMixShader'); w.node_tree.links.new(lp.outputs['Is Glossy Ray'], gl.inputs[0])
    w.node_tree.links.new(mx.outputs[0], gl.inputs[1]); w.node_tree.links.new(bk.outputs[0], gl.inputs[2]); w.node_tree.links.new(gl.outputs[0], out.inputs[0])
for o in [o for o in sc.objects if o.type == 'LIGHT']: bpy.data.objects.remove(o)
for nm, dg, col, e in (('key', (-.45, -.70, -.55), (1, .96, .90), 2.0), ('fill', (.6, -.2, .75), (.55, .65, .85), .5)):
    d = Vector((dg[0], -dg[2], dg[1])).normalized()
    L = bpy.data.lights.new(nm, 'SUN'); L.energy = e * math.pi; L.color = col; L.angle = math.radians(1.5)
    o = bpy.data.objects.new(nm, L); sc.collection.objects.link(o); o.rotation_euler = d.to_track_quat('-Z', 'Y').to_euler()
# the faction's albedo lift, as the game applies it (linear multiply of the base colour)
for m in bpy.data.materials:
    if not m.get('p3_textured') or not m.use_nodes: continue
    nt = m.node_tree; bs = nt.nodes.get('Principled BSDF')
    if bs is None or not bs.inputs['Base Color'].links: continue
    src = bs.inputs['Base Color'].links[0].from_socket
    mul = nt.nodes.new('ShaderNodeMix'); mul.data_type = 'RGBA'; mul.blend_type = 'MULTIPLY'; mul.inputs[0].default_value = 1
    nt.links.new(src, mul.inputs[6]); mul.inputs[7].default_value = (LIFT, LIFT, LIFT, 1); nt.links.new(mul.outputs[2], bs.inputs['Base Color'])
for o in sc.objects:
    if o.type == 'MESH' and o.get('role') == 'interior': o.hide_render = True

fc = json.load(open(os.path.join(HERE, 'ships', SHEET + '_camera.json')))


def look_cam(az, el, dist, mm, res, target, roll=0.0, shift=(0, 0)):
    """the build sheet's beauty camera (build.py look_cam), in the recipe frame"""
    a_, e = math.radians(az), math.radians(el)
    d = Vector((math.cos(e) * math.cos(a_), math.cos(e) * math.sin(a_), math.sin(e)))
    loc = Vector(target) * S + d * dist * S; f = -d
    right = f.cross(Vector((0, 0, 1))).normalized(); up = right.cross(f).normalized(); rr = math.radians(roll)
    right, up = right * math.cos(rr) + up * math.sin(rr), up * math.cos(rr) - right * math.sin(rr)
    c = bpy.data.cameras.new('beauty'); o = bpy.data.objects.new('beauty', c); sc.collection.objects.link(o)
    r = right.normalized(); u = up.normalized(); b = r.cross(u)
    o.matrix_world = Matrix(((r.x, u.x, b.x, loc[0]), (r.y, u.y, b.y, loc[1]), (r.z, u.z, b.z, loc[2]), (0, 0, 0, 1)))
    c.lens = mm; c.sensor_width = 36; c.sensor_fit = 'HORIZONTAL'; c.clip_start = .001; c.clip_end = 20
    c.shift_x, c.shift_y = shift
    sc.render.resolution_x, sc.render.resolution_y = res
    return o


def ortho(name, loc, look, up, scale, res):
    c = bpy.data.cameras.new(name); o = bpy.data.objects.new(name, c); sc.collection.objects.link(o)
    f = (Vector(look) - Vector(loc)).normalized(); r = f.cross(Vector(up)).normalized(); u = r.cross(f)
    b = -f
    o.matrix_world = Matrix(((r.x, u.x, b.x, loc[0]), (r.y, u.y, b.y, loc[1]), (r.z, u.z, b.z, loc[2]), (0, 0, 0, 1)))
    c.type = 'ORTHO'; c.ortho_scale = scale; c.clip_start = .001; c.clip_end = 20
    sc.render.resolution_x, sc.render.resolution_y = res
    return o


def shoot(o, name, pct):
    sc.camera = o; sc.render.resolution_percentage = int(pct * 100)
    p = os.path.join(OUT, name + '.png'); sc.render.filepath = p; bpy.ops.render.render(write_still=True); print('[601] shot', name, flush=True)
    return p


beauty = look_cam(fc['az'], fc['el'], fc['dist'], fc['mm'], tuple(fc['res']), fc['target'], fc.get('roll', 0), (-fc.get('sx', 0), -fc.get('sy', 0)))
shots = {'beauty': shoot(beauty, 'paint_beauty', SCALE)}
side = ortho('side', (0, 3, -.0), (0, 0, 0), (0, 0, 1), 1.12, (2400, 1000)); shots['side'] = shoot(side, 'paint_side', SCALE * .55)
side_s = ortho('side_s', (0, -3, 0), (0, 0, 0), (0, 0, 1), 1.12, (2400, 1000)); shots['side_s'] = shoot(side_s, 'paint_side_s', SCALE * .55)
top = ortho('top', (0, 0, 3), (0, 0, 0), (0, -1, 0), 1.12, (2400, 1000)); shots['top'] = shoot(top, 'paint_top', SCALE * .55)
below = ortho('below', (0, 0, -3), (0, 0, 0), (0, 1, 0), 1.12, (2400, 1000)); shots['below'] = shoot(below, 'paint_below', SCALE * .55)
bow = ortho('bow', (3, 0, 0), (0, 0, 0), (0, 0, 1), .62, (1200, 1000)); shots['bow'] = shoot(bow, 'paint_bow', SCALE * .55)
stern = ortho('stern', (-3, 0, 0), (0, 0, 0), (0, 0, 1), .62, (1200, 1000)); shots['stern'] = shoot(stern, 'paint_stern', SCALE * .55)
# the region windows for the compare (bow, midships, stern thirds of the ship's length), measured on this render's own camera:
# each third's outside meshes projected through the beauty camera, so the stern window holds the engines on every ship
from bpy_extras.object_utils import world_to_camera_view
import numpy as np
sc.camera = beauty; sc.render.resolution_percentage = 100; sc.render.resolution_x, sc.render.resolution_y = tuple(fc['res'])
pts = []
dg = bpy.context.evaluated_depsgraph_get()
for o in sc.objects:
    if o.type != 'MESH' or o.get('role') == 'interior' or o.hide_render: continue
    M = o.matrix_world; vs = o.data.vertices
    step = max(1, len(vs) // 400)
    for i in range(0, len(vs), step): pts.append(M @ vs[i].co)
X = np.array([p.x for p in pts]); x0, x1 = X.min(), X.max(); third = (x1 - x0) / 3
windows = {}
for name, lo, hi in (('bow', x1 - third, x1), ('midships', x0 + third, x1 - third), ('stern', x0, x0 + third)):
    uv = [world_to_camera_view(sc, beauty, p) for p in pts if lo - 1e-6 <= p.x <= hi + 1e-6]
    us = [c.x for c in uv if c.z > 0]; vv = [1 - c.y for c in uv if c.z > 0]
    if not us: continue
    pad = .04
    u0, u1 = max(0, min(us) - pad), min(1, max(us) + pad); v0, v1 = max(0, min(vv) - pad), min(1, max(vv) + pad)
    windows[name] = [round(u0, 4), round(v0, 4), round(u1, 4), round(v1, 4)]
# the engines up close (Board, pass 5: judge the glow on a zoomed stern-on view and one bell at the close camera)
hp = json.loads(sc.get('r209_hp', '{}')).get('engines', [])
if hp:
    E = np.array([e['pos'] for e in hp]); R = max(e['radius'] for e in hp)
    cy, cz = E[:, 1].mean(), E[:, 2].mean(); span = max(np.ptp(E[:, 1]), np.ptp(E[:, 2])) + 4 * R
    z = ortho('stern_zoom', (-3, cy, cz), (0, cy, cz), (0, 0, 1), span * 1.15, (1200, 1000)); shots['stern_zoom'] = shoot(z, 'paint_stern_zoom', SCALE * .6)
    big = max(hp, key=lambda e: e['radius']); bp = Vector(big['pos']); r = big['radius']
    c = bpy.data.cameras.new('bell'); o = bpy.data.objects.new('bell', c); sc.collection.objects.link(o)
    loc = bp + Vector((-7.0 * r, 2.2 * r * (1 if bp.y >= 0 else -1), 2.0 * r)); o.location = loc
    o.rotation_euler = (bp + Vector((r * .6, 0, 0)) - loc).to_track_quat('-Z', 'Y').to_euler(); c.lens = 50; c.clip_start = .0005
    sc.render.resolution_x, sc.render.resolution_y = 1200, 1000; shots['bell'] = shoot(o, 'paint_bell', SCALE * .6)
# close views of the glow a faction stack asks for (issue 642: the Eclipse corona line on a shade rim, and the core seen through its
# port): a material with ps_close names the view; the camera sits just outside the surface, looking in at it
close = {}
for o in sc.objects:
    if o.type != 'MESH' or o.hide_render or o.get('role') == 'interior' or not o.data.materials or o.data.materials[0] is None: continue
    tag = o.data.materials[0].get('ps_close')
    if tag: close.setdefault(str(tag), []).append(o)
for tag, objs in sorted(close.items()):
    if tag == 'rim':      # the longest corona line, at its point farthest out from the ship's axis
        span = lambda o: max((o.matrix_world @ v.co - o.matrix_world @ o.data.vertices[0].co).length for v in o.data.vertices)   # noqa: E731
        o = max(objs, key=lambda o: (o.get('role') == 'hull', span(o))); vs = [o.matrix_world @ v.co for v in o.data.vertices]
        p = max(vs, key=lambda v: abs(v.y)); out_ = Vector((0.15, 1.0 if p.y >= 0 else -1.0, 0.9)).normalized(); dist = .09
    else:                 # the core: the middle of its glowing surfaces, seen from above and a little forward
        vs = [o.matrix_world @ v.co for o in objs for v in o.data.vertices]; p = sum(vs, Vector()) / len(vs)
        span = max(max(v[i] for v in vs) - min(v[i] for v in vs) for i in range(3)); out_ = Vector((0.45, 0.35, 1.0)).normalized(); dist = max(.05, span * 3.5)
    c = bpy.data.cameras.new('close_' + tag); o2 = bpy.data.objects.new('close_' + tag, c); sc.collection.objects.link(o2)
    o2.location = p + out_ * dist; o2.rotation_euler = (p - o2.location).to_track_quat('-Z', 'Y').to_euler(); c.lens = 50; c.clip_start = .0005
    sc.render.resolution_x, sc.render.resolution_y = 1200, 1000; shots['close_' + tag] = shoot(o2, 'paint_close_' + tag, SCALE * .6)
json.dump(dict(shots=shots, windows=windows, lift=LIFT, samples=SAMP, camera=SHEET + '_camera.json'), open(os.path.join(OUT, 'paint_shots.json'), 'w'), indent=1)
