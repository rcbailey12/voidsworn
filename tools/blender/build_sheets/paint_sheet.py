# The painted sheet ship beside its concept (issue 601): renders a stage 5 painted blend (tools/blender/r209/bake_sheet.py) at
# the build sheet's own beauty camera (ships/<sheet>_camera.json, fitted to the concept) and at the region windows of the
# sheet's side_by_side.jpg, under the GAME's light (godot/render/look.gd: key 2.0 from KEY_DIR, fill a quarter, cool ambient,
# AgX) with the faction's battle albedo lift (R227: Hullbreakers 1.25), then lays each beside the concept at the same camera.
# One picture per item, its code name on it, 1280 wide and no taller than 720 (RULEBOOK 1.2).
# usage: blender -b CELL.blend -P paint_sheet.py -- OUT_DIR SHEET CONCEPT_JPG [lift=1.25] [samples=32] [scale=0.5] [gpu=1]
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
json.dump(dict(shots=shots, lift=LIFT, samples=SAMP, camera=SHEET + '_camera.json'), open(os.path.join(OUT, 'paint_shots.json'), 'w'), indent=1)
