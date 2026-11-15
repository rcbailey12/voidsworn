# Issue 726 sandbox previews of a painted Hullbreaker sheet ship (not a standing check). Sets the game light and the battle lift
# exactly as tools/blender/build_sheets/paint_sheet.py does (its own code, run up to its first shot), then renders only:
#   beauty  the sheet's fitted beauty camera (ships/<sheet>_camera.json), with a transparent film so the ship's mask is exact
#   deck    the deck close, from above the port quarter (the trophy patches at a judgeable size: uneven, no rows)
#   flank   the port flank close
# usage: python run_cpu.py preview.py PAINTED.blend -- OUT_DIR SHEET CONCEPT [samples=16] [scale=0.5] [only=beauty,deck,flank]
import os, sys
import bpy
from mathutils import Vector

REPO = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..', '..', '..'))
a = sys.argv[sys.argv.index('--') + 1:]
OUT, SHEET, CONCEPT = a[0], a[1], a[2]; kw = dict(x.split('=', 1) for x in a[3:] if '=' in x)
SAMP = kw.get('samples', '16'); SCALE = float(kw.get('scale', '0.5'))
want = set(kw.get('only', 'beauty,deck,flank').split(','))
sys.argv = ['x', '--', OUT, SHEET, CONCEPT, 'lift=1.25', f'samples={SAMP}', f'scale={SCALE}']
PS = os.path.join(REPO, 'tools', 'blender', 'build_sheets', 'paint_sheet.py')
src = open(PS).read().split("beauty = look_cam(")[0]       # the light, the lift and the camera helpers only
G = {'__file__': PS, '__name__': 'ps'}
exec(compile(src, PS, 'exec'), G)
sc = bpy.context.scene; shoot, look_cam, fc = G['shoot'], G['look_cam'], G['fc']
if 'beauty' in want:
    sc.render.film_transparent = True
    o = look_cam(fc['az'], fc['el'], fc['dist'], fc['mm'], tuple(fc['res']), fc['target'], fc.get('roll', 0), (-fc.get('sx', 0), -fc.get('sy', 0)))
    shoot(o, 'paint_beauty', SCALE); sc.render.film_transparent = False
H = [o for o in sc.objects if o.type == 'MESH' and o.get('role') == 'hull' and not o.hide_render] or \
    [o for o in sc.objects if o.type == 'MESH' and o.get('role') != 'interior' and not o.hide_render]
P = [o.matrix_world @ Vector(v) for o in H for v in o.bound_box]
lo = Vector((min(p.x for p in P), min(p.y for p in P), min(p.z for p in P))); hi = Vector((max(p.x for p in P), max(p.y for p in P), max(p.z for p in P)))


def cam(name, target, offset, lens, res):
    c = bpy.data.cameras.new(name); o = bpy.data.objects.new(name, c); sc.collection.objects.link(o)
    o.location = target + offset; o.rotation_euler = (target - o.location).to_track_quat('-Z', 'Y').to_euler()
    c.lens = lens; c.clip_start = .0005; c.clip_end = 20; sc.render.resolution_x, sc.render.resolution_y = res
    return o


if 'deck' in want:
    t = Vector((lo.x + .45 * (hi.x - lo.x), 0, hi.z - .15 * (hi.z - lo.z)))
    shoot(cam('deck', t, Vector((-.35, .55, 1.0)).normalized() * .80, 50, (1280, 720)), 'paint_deck', SCALE * 2)
if 'flank' in want:
    t = Vector((lo.x + .55 * (hi.x - lo.x), hi.y, (lo.z + hi.z) / 2))
    shoot(cam('flank', t, Vector((.10, 1.0, .30)).normalized() * .75, 50, (1280, 720)), 'paint_flank', SCALE * 2)
print('[726] preview done', flush=True)
