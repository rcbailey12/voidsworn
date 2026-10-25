# Studio renders for the dressed barge: full views in colour and clay, plus the 9-cell blob sweep (CLAUDE.md): bow, middle and stern,
# each seen from the top, the side and below, close enough to judge every part.
# usage: python3 render_v15.py ship.blend out_prefix
import sys, os, math
HERE = os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0, HERE); sys.path.insert(0, os.path.join(HERE, '..', 'hs'))
import bpy
from mathutils import Vector
a = sys.argv[sys.argv.index('--') + 1:] if '--' in sys.argv else sys.argv[1:]
bpy.ops.wm.open_mainfile(filepath=a[0]); pre = a[1]
import clay, barge_v15
for o in list(bpy.context.scene.objects):
    if o.type in ('LIGHT', 'CAMERA'): bpy.data.objects.remove(o)
clay.setup_scene(); sc = bpy.context.scene; sc.cycles.samples = 48
vm = barge_v15.color_material()
outs = clay.render_views(pre, views=('q', 'qp', 'side', 'below', 'belowp', 'front', 'top'), mat=vm)
outs += clay.render_views(pre + '_clay', views=('q', 'side', 'below'))
for o in sc.objects:
    if o.type == 'MESH': o.data.materials.clear(); o.data.materials.append(vm)
cam = bpy.data.objects['cam']; sc.render.resolution_x, sc.render.resolution_y = 760, 560
cells = {'bow': (-.50, -.18), 'mid': (-.20, .14), 'stern': (.12, .53)}
views = {'top': (Vector((0, 0, 1)), 'Y'), 'side': (Vector((0, -1, 0)), 'Z'), 'port': (Vector((0, 1, 0)), 'Z'), 'below': (Vector((0, 0, -1)), 'Y')}
for cn, (x0, x1) in cells.items():
    for vn, (d, up) in views.items():
        c = Vector(((x0 + x1) / 2, 0, -.07)); cam.data.type = 'ORTHO'; cam.data.ortho_scale = (x1 - x0) * 1.05
        if vn in ('top', 'below'): cam.data.ortho_scale = max(x1 - x0, .56 * 760 / 560) * 1.02
        cam.location = c + d * 3; cam.data.clip_end = 10
        if vn == 'top': cam.rotation_euler = (0, 0, 0)
        elif vn == 'below': cam.rotation_euler = (math.pi, 0, 0)
        else: cam.rotation_euler = (c - cam.location).to_track_quat('-Z', 'Y').to_euler()
        f = f'{pre}_cell_{cn}_{vn}.png'; sc.render.filepath = f; bpy.ops.render.render(write_still=True); outs.append(f)
print(outs)
