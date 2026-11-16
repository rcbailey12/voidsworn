# Side to side check (issue 783; Ryan, Nov 15 2026, R256: "let's make sure that the paint actually is even on each side"): a top
# view of a ship blend (a sheet blockout, a stage 4 build or a stage 5 painted blend) under a light that is the same on both sides
# (a sun straight down, a sun from the bow, a grey ambient), bow up, port left, the centre line between the two middle columns;
# then the port half mirrored onto the starboard half and the difference measured:
#   mean_diff               the mean of each ship pixel's largest channel difference from its mirror twin, 0 to 255
#   share_over_24           the share of ship pixels that differ from their twin by more than 24 of 255
#   green_unmatched_share   the share of corona light pixels (green over red and blue) with no twin within 1 px
# A painted blend gets the faction's battle lift (lift=, as paint_sheet.py and the game apply it). Interiors are hidden.
#   python3 mirror_check.py BLEND OUT_DIR [px=720] [samples=16] [lift=1.0]       (the bpy module; or blender -b -P ... -- the same)
# Writes OUT_DIR/mirror_top.png and OUT_DIR/mirror_check.json. The thresholds are viewing values, not a pass bar (RULEBOOK 0.4).
import os, sys, json, math
import numpy as np
import bpy
from mathutils import Vector, Matrix

a = sys.argv[sys.argv.index('--') + 1:] if '--' in sys.argv else sys.argv[1:]
if '--' not in sys.argv:
    bpy.ops.wm.open_mainfile(filepath=a.pop(0))
OUT = a[0]; kw = dict(x.split('=', 1) for x in a[1:] if '=' in x)
PX = int(kw.get('px', 720)); SAMP = int(kw.get('samples', 16)); LIFT = float(kw.get('lift', 1.0))
os.makedirs(OUT, exist_ok=True)
sc = bpy.context.scene
for o in [o for o in sc.objects if o.type in ('LIGHT', 'CAMERA')]: bpy.data.objects.remove(o)
for o in sc.objects:
    if o.type == 'MESH' and o.get('role') == 'interior': o.hide_render = True
for m in bpy.data.materials:
    if LIFT == 1.0 or not m.get('p3_textured') or not m.use_nodes: continue
    nt = m.node_tree; bs = nt.nodes.get('Principled BSDF')
    if bs is None or not bs.inputs['Base Color'].links: continue
    src = bs.inputs['Base Color'].links[0].from_socket
    mul = nt.nodes.new('ShaderNodeMix'); mul.data_type = 'RGBA'; mul.blend_type = 'MULTIPLY'; mul.inputs[0].default_value = 1
    nt.links.new(src, mul.inputs[6]); mul.inputs[7].default_value = (LIFT, LIFT, LIFT, 1); nt.links.new(mul.outputs[2], bs.inputs['Base Color'])
ms = [o for o in sc.objects if o.type == 'MESH' and not o.hide_render]
P = [o.matrix_world @ Vector(b) for o in ms for b in o.bound_box]
x0 = min(p.x for p in P); x1 = max(p.x for p in P); zt = max(p.z for p in P)
cam = bpy.data.cameras.new('mirror_top'); cam.type = 'ORTHO'; cam.ortho_scale = (x1 - x0) * 1.04
co = bpy.data.objects.new('mirror_top', cam); sc.collection.objects.link(co); sc.camera = co
co.location = ((x0 + x1) / 2, 0.0, zt + 10.0); cam.clip_end = zt + 20.0 - min(p.z for p in P)
co.rotation_euler = Matrix(((0, 1, 0), (-1, 0, 0), (0, 0, 1))).to_euler()      # looking down; image up is the bow, right is starboard
sc.render.resolution_x = sc.render.resolution_y = PX; sc.render.resolution_percentage = 100
sc.render.engine = 'CYCLES'; sc.cycles.samples = SAMP; sc.cycles.use_denoising = True
sc.render.film_transparent = True; sc.view_settings.view_transform = 'AgX'
w = bpy.data.worlds.new('mirror_check'); sc.world = w; w.use_nodes = True; w.node_tree.nodes['Background'].inputs['Color'].default_value = (.12, .12, .13, 1)
for nm, d, e in (('top', (0, 0, -1), 2.2), ('bow', (-1, 0, -.6), 1.0)):
    l = bpy.data.lights.new(nm, 'SUN'); l.energy = e; l.angle = math.radians(2)
    o = bpy.data.objects.new(nm, l); sc.collection.objects.link(o); o.rotation_euler = Vector(d).normalized().to_track_quat('-Z', 'Y').to_euler()
png = os.path.join(OUT, 'mirror_top.png')
sc.render.filepath = png; sc.render.image_settings.file_format = 'PNG'; sc.render.image_settings.color_mode = 'RGBA'
bpy.ops.render.render(write_still=True)

im = bpy.data.images.load(png); A = np.asarray(im.pixels[:], np.float32).reshape(im.size[1], im.size[0], 4)[::-1] * 255
h = PX // 2; port = A[:, :h]; stbd = A[:, PX - h:][:, ::-1]
ship = (port[..., 3] > 128) | (stbd[..., 3] > 128)
diff = np.abs(port[..., :3] - stbd[..., :3]).max(-1)


def green(x):
    r, g, b = x[..., 0], x[..., 1], x[..., 2]
    return (g > 1.25 * r) & (g > 1.08 * b) & (g > 80) & (x[..., 3] > 128)


def grow(m):
    o = m.copy(); o[1:] |= m[:-1]; o[:-1] |= m[1:]; o[:, 1:] |= m[:, :-1]; o[:, :-1] |= m[:, 1:]; return o


gp, gs = green(port), green(stbd); miss = (gp & ~grow(gs)) | (gs & ~grow(gp))
res = dict(blend=bpy.data.filepath, px=PX, samples=SAMP, lift=LIFT, ship_px=int(ship.sum()), mean_diff=round(float(diff[ship].mean()), 2),
           share_over_24=round(float((diff[ship] > 24).mean()), 4), green_px=int(gp.sum() + gs.sum()), green_unmatched_px=int(miss.sum()),
           green_unmatched_share=round(float(miss.sum() / max(1, gp.sum() + gs.sum())), 4))
json.dump(res, open(os.path.join(OUT, 'mirror_check.json'), 'w'), indent=1)
print('[mirror_check]', json.dumps(res))
