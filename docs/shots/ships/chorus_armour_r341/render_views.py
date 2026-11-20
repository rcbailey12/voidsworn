# R341 (the Chorus armour shell): the views for Ryan's before and after sheets, from a stage 5 painted blend
# (tools/blender/r209/bake_sheet.py, cloud CPU). The game's light and the Chorus albedo lift as paint_sheet.py sets them; the
# battle camera's pitch (0.98 rad from straight down, bow to screen right) at distance 170 and 26, at the game's 1080p pixel
# scale (fov 45 vertical over 1080 rows), each the middle 640 x 360 of the screen; and one close-up of the shell's texture.
# usage: python3 render_views.py CELL.blend OUT_DIR PREFIX [samples=24] [lift=1.25]
import os, sys, math
import bpy
from mathutils import Vector

a = sys.argv[1:]
bpy.ops.wm.open_mainfile(filepath=a[0])
OUT, PRE = a[1], a[2]
kw = dict(x.split('=', 1) for x in a[3:] if '=' in x)
SAMP = int(kw.get('samples', 24)); LIFT = float(kw.get('lift', 1.25))
os.makedirs(OUT, exist_ok=True)
sc = bpy.context.scene
sc.render.engine = 'CYCLES'; sc.cycles.device = 'CPU'; sc.cycles.samples = SAMP; sc.cycles.use_denoising = True
sc.view_settings.view_transform = 'AgX'; sc.view_settings.exposure = 0.0
w = bpy.data.worlds.new('game'); sc.world = w; w.use_nodes = True; bg = w.node_tree.nodes['Background']
bg.inputs['Color'].default_value = (.43, .45, .5, 1)
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
for m in bpy.data.materials:
    if not m.get('p3_textured') or not m.use_nodes: continue
    nt = m.node_tree; bs = nt.nodes.get('Principled BSDF')
    if bs is None or not bs.inputs['Base Color'].links: continue
    src = bs.inputs['Base Color'].links[0].from_socket
    mul = nt.nodes.new('ShaderNodeMix'); mul.data_type = 'RGBA'; mul.blend_type = 'MULTIPLY'; mul.inputs[0].default_value = 1
    nt.links.new(src, mul.inputs[6]); mul.inputs[7].default_value = (LIFT, LIFT, LIFT, 1); nt.links.new(mul.outputs[2], bs.inputs['Base Color'])
for o in sc.objects:
    if o.type == 'MESH' and o.get('role') == 'interior': o.hide_render = True
Lw = float(sc.get('r209_length_world', 0) or 0) or 1.0


def cam(name, loc, look, vfov_rows=360, lens=None):
    c = bpy.data.cameras.new(name); o = bpy.data.objects.new(name, c); sc.collection.objects.link(o)
    o.location = loc; o.rotation_euler = (Vector(look) - Vector(loc)).to_track_quat('-Z', 'Y').to_euler()
    c.clip_start = .0005; c.clip_end = 100
    if lens:
        c.lens = lens
    else:
        c.sensor_fit = 'VERTICAL'; c.angle_y = 2 * math.atan(math.tan(math.radians(22.5)) * vfov_rows / 1080)
    return o


def shoot(o, name, res):
    sc.camera = o; sc.render.resolution_x, sc.render.resolution_y = res; sc.render.resolution_percentage = 100
    sc.render.filepath = os.path.join(OUT, '%s_%s.png' % (PRE, name)); bpy.ops.render.render(write_still=True)
    print('[r341] shot', sc.render.filepath, flush=True)


b_ = 0.98
for dist in (170, 26):
    d = dist / Lw
    shoot(cam('r%d' % dist, Vector((0, -math.sin(b_) * d, math.cos(b_) * d)), (0, 0, 0)), 'R%d' % dist, (640, 360))
# the close-up: the skin's own texture on the starboard flank a little forward of the middle, seen from above and aft
# (the bake merges every part into a few surfaces, so the spot is found by a ray at the flank, not by object name)
dg = bpy.context.evaluated_depsgraph_get()
hit, p, *_ = sc.ray_cast(dg, Vector((0.05, -2.0, 0.035)), Vector((0, 1, 0)))
if not hit:
    p = Vector((0.05, -0.15, 0.03))
loc = p + Vector((-0.06, -0.12, 0.09))
shoot(cam('close', loc, p, lens=50), 'close', (640, 360))
if kw.get('hero'):
    # a working view for the builder (not on Ryan's sheet): the whole ship filling a 1280 x 720 frame from the battle pitch
    d = float(kw.get('hero')) / Lw
    shoot(cam('hero', Vector((0, -math.sin(b_) * d, math.cos(b_) * d)), (0, 0, 0), vfov_rows=1080), 'hero', (1280, 720))
if kw.get('herop'):
    # the same, from above the port bow (the PC paint proof's hero angle)
    d = float(kw.get('herop')) / Lw
    shoot(cam('herop', Vector((0.55, 0.6, 0.58)).normalized() * d, (0, 0, 0), vfov_rows=1080), 'herop', (1280, 720))
