"""Issue 875 close views using paint_sheet's game light and camera helpers.

Blender -b PAINTED.blend -P render_patchwork_close.py -- OUT SHEET CONCEPT
"""
from pathlib import Path
import sys
import bpy
from mathutils import Vector

REPO = Path(__file__).resolve().parents[4]
args = sys.argv[sys.argv.index('--') + 1:]
out, sheet, concept = args[:3]
shared_path = REPO / 'tools/blender/build_sheets/paint_sheet.py'
sys.argv = ['paint_sheet.py', '--', out, sheet, concept, 'samples=32', 'scale=1', 'gpu=1']
if sheet == 'corsair_KB1CC':
    sys.argv += ['sky_spec=0']
source = shared_path.read_text().split('beauty = look_cam(')[0]
shared = {'__file__': str(shared_path), '__name__': 'patchwork_close'}
exec(compile(source, str(shared_path), 'exec'), shared)
sc = bpy.context.scene
hull = [o for o in sc.objects if o.type == 'MESH' and o.get('role') == 'hull' and not o.hide_render]
points = [o.matrix_world @ Vector(v) for o in hull for v in o.bound_box]
lo = Vector(tuple(min(p[i] for p in points) for i in range(3)))
hi = Vector(tuple(max(p[i] for p in points) for i in range(3)))


def close(name, target, direction, distance):
    cam = bpy.data.cameras.new(name)
    obj = bpy.data.objects.new(name, cam); sc.collection.objects.link(obj)
    obj.location = target + Vector(direction).normalized() * distance
    obj.rotation_euler = (target - obj.location).to_track_quat('-Z', 'Y').to_euler()
    cam.lens = 50; cam.clip_start = .0005
    sc.render.resolution_x, sc.render.resolution_y = 1280, 720
    shared['shoot'](obj, 'paint_' + name, 1)


close('deck', Vector((lo.x + .45 * (hi.x - lo.x), 0, hi.z - .15 * (hi.z - lo.z))),
      (-.35, .55, 1), .80)
close('flank', Vector((lo.x + .55 * (hi.x - lo.x), hi.y, (lo.z + hi.z) / 2)),
      (.10, 1, .30), .75)
