# Issue 1889 (blind builder pair 2, Opus leg): the five comparison views of a painted sheet ship, the same five as the Picket
# comparison (board/review_1123/1725): three quarter, side, top, underside and the battle camera at 170. Same light and albedo
# lift as tools/blender/build_sheets/paint_sheet.py (the game's key and fill, AgX, the faction lift), a slate backdrop so the dark
# Sunward iron reads, and fixed cameras that do not depend on any one build's fitted concept camera, so every Warden build
# (Astra S9A, Opus S9O, the accepted S9) can be shot alike from its stage 5 blend.
# usage: python render_views.py CELL.blend OUT_DIR NAME [lift=1.45] [samples=48] [res=1280x720]
#        (or blender -b CELL.blend -P render_views.py -- OUT_DIR NAME ...)
import math
import os
import sys

import bpy
from mathutils import Matrix, Vector

if '--' in sys.argv:
    a = sys.argv[sys.argv.index('--') + 1:]
else:
    a = sys.argv[1:]
    bpy.ops.wm.open_mainfile(filepath=a.pop(0))
OUT, NAME = a[0], a[1]
kw = dict(x.split('=', 1) for x in a[2:] if '=' in x)
LIFT = float(kw.get('lift', 1.45))
SAMP = int(kw.get('samples', 48))
RW, RH = (int(v) for v in kw.get('res', '1280x720').split('x'))
os.makedirs(OUT, exist_ok=True)
sc = bpy.context.scene
sc.render.engine = 'CYCLES'
sc.cycles.samples = SAMP
sc.cycles.use_denoising = True
sc.view_settings.view_transform = 'AgX'
sc.view_settings.exposure = 0.0
sc.render.film_transparent = False

# the game's light (paint_sheet.py): a uniform cool ambient for lighting rays, a slate backdrop for camera rays
w = bpy.data.worlds.new('views'); sc.world = w; w.use_nodes = True
nt = w.node_tree
amb = nt.nodes['Background']; amb.inputs['Color'].default_value = (.86 * .5, .9 * .5, 1.0 * .5, 1)
lp = nt.nodes.new('ShaderNodeLightPath'); mx = nt.nodes.new('ShaderNodeMixShader')
bk = nt.nodes.new('ShaderNodeBackground'); bk.inputs['Color'].default_value = (.026, .036, .05, 1)
nt.links.new(lp.outputs['Is Camera Ray'], mx.inputs[0]); nt.links.new(amb.outputs[0], mx.inputs[1])
nt.links.new(bk.outputs[0], mx.inputs[2]); nt.links.new(mx.outputs[0], nt.nodes['World Output'].inputs[0])
for o in [o for o in sc.objects if o.type == 'LIGHT']:
    bpy.data.objects.remove(o)
for nm, dg, col, e in (('key', (-.45, -.70, -.55), (1, .96, .90), 2.0), ('fill', (.6, -.2, .75), (.55, .65, .85), .5)):
    d = Vector((dg[0], -dg[2], dg[1])).normalized()
    L = bpy.data.lights.new(nm, 'SUN'); L.energy = e * math.pi; L.color = col; L.angle = math.radians(1.5)
    o = bpy.data.objects.new(nm, L); sc.collection.objects.link(o); o.rotation_euler = d.to_track_quat('-Z', 'Y').to_euler()
for m in bpy.data.materials:          # the faction's albedo lift, as the game applies it
    if not m.get('p3_textured') or not m.use_nodes:
        continue
    bs = m.node_tree.nodes.get('Principled BSDF')
    if bs is None or not bs.inputs['Base Color'].links:
        continue
    src = bs.inputs['Base Color'].links[0].from_socket
    mul = m.node_tree.nodes.new('ShaderNodeMix'); mul.data_type = 'RGBA'; mul.blend_type = 'MULTIPLY'; mul.inputs[0].default_value = 1
    m.node_tree.links.new(src, mul.inputs[6]); mul.inputs[7].default_value = (LIFT, LIFT, LIFT, 1); m.node_tree.links.new(mul.outputs[2], bs.inputs['Base Color'])
vis = [o for o in sc.objects if o.type == 'MESH' and not o.hide_render]
for o in vis:
    if o.get('role') == 'interior':
        o.hide_render = True
vis = [o for o in vis if not o.hide_render]
pts = [o.matrix_world @ Vector(c) for o in vis for c in o.bound_box]
lo = Vector([min(p[i] for p in pts) for i in range(3)]); hi = Vector([max(p[i] for p in pts) for i in range(3)])
C = (lo + hi) / 2
L = hi.x - lo.x


def cam(name, d, up=(0, 0, 1), ortho=None, lens=50.0, dist=None):
    c = bpy.data.cameras.new(name); o = bpy.data.objects.new(name, c); sc.collection.objects.link(o)
    d = Vector(d).normalized()
    loc = C + d * (dist or L * 4)
    f = -d; r = f.cross(Vector(up)).normalized(); u = r.cross(f)
    o.matrix_world = Matrix(((r.x, u.x, -f.x, loc.x), (r.y, u.y, -f.y, loc.y), (r.z, u.z, -f.z, loc.z), (0, 0, 0, 1)))
    c.clip_start = L * 0.01; c.clip_end = L * 20
    if ortho:
        c.type = 'ORTHO'; c.ortho_scale = ortho
    else:
        c.lens = lens; c.sensor_width = 36; c.sensor_fit = 'HORIZONTAL'
    return o


def shoot(o, fname, res=(RW, RH)):
    sc.camera = o; sc.render.resolution_x, sc.render.resolution_y = res; sc.render.resolution_percentage = 100
    sc.render.filepath = os.path.join(OUT, '%s_%s.png' % (NAME, fname)); bpy.ops.render.render(write_still=True)
    print('[1889] shot', fname, flush=True)


# bow to the left in the flat views (as the concept sheet draws it); the three quarter from ahead, port and above
shoot(cam('three_quarter', (0.5, 0.78, 0.5), lens=50, dist=L * 1.7), 'three_quarter')
shoot(cam('side', (0, 1, 0), ortho=L * 1.08), 'side')
shoot(cam('top', (0, 0, 1), up=(0, -1, 0), ortho=L * 1.08), 'top')
shoot(cam('underside', (0, 0, -1), up=(0, 1, 0), ortho=L * 1.08), 'underside')
# the battle camera: godot/render/camera_rig.gd fov 45 vertical, distance 170, pitch 34 degrees above the board, bow to screen right,
# the middle 640 x 360 of a 1920 x 1080 screen at true pixel size (paint_sheet.py cam170)
Lw = float(sc.get('r209_length_world', 0) or 0) or 1.0
dist = 170.0 / Lw; b_ = 0.98
c = bpy.data.cameras.new('cam170'); o = bpy.data.objects.new('cam170', c); sc.collection.objects.link(o)
o.location = C + Vector((0, -math.sin(b_) * dist, math.cos(b_) * dist)); o.rotation_euler = (C - o.location).to_track_quat('-Z', 'Y').to_euler()
c.sensor_fit = 'VERTICAL'; c.angle_y = 2 * math.atan(math.tan(math.radians(22.5)) * 360 / 1080); c.clip_start = .01; c.clip_end = dist * 3
shoot(o, 'battle_170', (640, 360))
