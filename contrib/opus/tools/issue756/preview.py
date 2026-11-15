# Issue 756 sandbox previews of the painted S8 (sandbox only, not a standing check). Runs the repo's paint_sheet.py (game light,
# battle lift, the sheet's fitted beauty camera and the flat views), then adds what this job's pictures need:
#   battle  the battle camera as the build sheet frames it (ships/voidsworn_S8_camera_battle.json: 34 degrees above the board,
#           port beam, range 170, a long lens so the ship fills the frame)
#   b170    the same angle at the game's true pixel size (godot/render/camera_rig.gd: b 0.98 rad from straight up, so 34 degrees
#           above the board; fov 45 vertical; the middle 640 x 360 of a 1920 x 1080 screen). paint_sheet.py's own cam170 places
#           its camera at 56 degrees (sin and cos swapped), so it is not used here
#   spires  the radiator spires close, from above the port quarter
#   broad   the port broadside: the gun deck, the spire line over it, the frost points on the blade's edge
#   deck    the forward deck close (triangle plates, rivet rows, the crest, the spine line); flank the port flank close
# usage: python run_cpu.py preview.py PAINTED.blend -- OUT_DIR [samples=16] [scale=0.5] [only=battle,b170,spires,broad,deck,flank]
import os, sys, math, json, runpy
import bpy
from mathutils import Vector

REPO = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..', '..', '..'))
a = sys.argv[sys.argv.index('--') + 1:]
OUT = a[0]; kw = dict(x.split('=', 1) for x in a[1:] if '=' in x)
SAMP = kw.get('samples', '16'); SCALE = kw.get('scale', '0.5')
import re
LIFT = float(re.search(r'"voidsworn":\s*\{[^}]*"lift":\s*([0-9.]+)', open(os.path.join(REPO, 'godot', 'render', 'look.gd')).read()).group(1))
only = kw.get('only')
if only:      # extra views only: set the game light and lift the same way, without paint_sheet's standard views
    sys.argv = ['x', '--', OUT, 'voidsworn_S8', os.path.join(REPO, 'contrib/codex/design/concept_round5_2026_11/voidsworn_S8_beauty.jpg'),
                f'lift={LIFT}', f'samples={SAMP}', f'scale={SCALE}', 'sky_spec=0']
    src = open(os.path.join(REPO, 'tools', 'blender', 'build_sheets', 'paint_sheet.py')).read()
    src = src.split("beauty = look_cam(")[0]       # the light, the lift and the camera helpers only
    G = {'__file__': os.path.join(REPO, 'tools', 'blender', 'build_sheets', 'paint_sheet.py'), '__name__': 'ps'}
    exec(compile(src, G['__file__'], 'exec'), G)
else:
    sys.argv = ['x', '--', OUT, 'voidsworn_S8', os.path.join(REPO, 'contrib/codex/design/concept_round5_2026_11/voidsworn_S8_beauty.jpg'),
                f'lift={LIFT}', f'samples={SAMP}', f'scale={SCALE}', 'sky_spec=0']
    G = runpy.run_path(os.path.join(REPO, 'tools', 'blender', 'build_sheets', 'paint_sheet.py'))
want = set((only or 'battle,b170,spires,broad,deck,flank').split(','))
sc = bpy.context.scene; shoot, look_cam = G['shoot'], G['look_cam']
S = float(sc.get('r209_scale', 1.0)); Lw = float(sc.get('r209_length_world', 27.0) or 27.0)
bc = json.load(open(os.path.join(REPO, 'tools', 'blender', 'build_sheets', 'ships', 'voidsworn_S8_camera_battle.json')))
if 'battle' in want:
    o = look_cam(bc['az'], bc['el'], bc['dist'], bc['mm'], tuple(bc['res']), bc['target'], 0, (0, 0))
    o.data.clip_end = 400; shoot(o, 'paint_battle', 1.0)
if 'b170' in want:
    b = 0.98; d = 170.0 / Lw          # the game's camera: up = cos(b), out = sin(b) (camera_rig.gd line 195), the ship one long
    c = bpy.data.cameras.new('b170'); o = bpy.data.objects.new('b170', c); sc.collection.objects.link(o)
    o.location = Vector((0, math.sin(b) * d, math.cos(b) * d)); o.rotation_euler = (-o.location).to_track_quat('-Z', 'Y').to_euler()
    c.sensor_fit = 'VERTICAL'; c.angle_y = 2 * math.atan(math.tan(math.radians(22.5)) * 360 / 1080); c.clip_start = .01; c.clip_end = d * 3
    sc.render.resolution_x, sc.render.resolution_y = 640, 360; shoot(o, 'paint_b170', 1.0)
rad = [o for o in sc.objects if o.type == 'MESH' and o.get('part_kind') == 'radiator' and not o.hide_render]
P = [o.matrix_world @ Vector(v) for o in rad for v in o.bound_box]
lo = Vector((min(p.x for p in P), min(p.y for p in P), min(p.z for p in P))); hi = Vector((max(p.x for p in P), max(p.y for p in P), max(p.z for p in P)))
mid = (lo + hi) / 2


def cam(name, target, offset, lens, res):
    c = bpy.data.cameras.new(name); o = bpy.data.objects.new(name, c); sc.collection.objects.link(o)
    o.location = target + offset; o.rotation_euler = (target - o.location).to_track_quat('-Z', 'Y').to_euler()
    c.lens = lens; c.clip_start = .0005; c.clip_end = 20; sc.render.resolution_x, sc.render.resolution_y = res
    return o


if 'spires' in want:
    span = (hi - lo).x
    o = cam('spires', mid + Vector((0, 0, -0.1 * (hi - lo).z)), Vector((-.35, 1.0, .75)).normalized() * span * 1.95, 50, (1280, 720))
    shoot(o, 'paint_spires', float(SCALE) * 2)
if 'broad' in want:
    o = cam('broad', Vector((-0.04, 0, -0.01)), Vector((0.10, 1.0, .22)).normalized() * 1.32, 50, (1280, 720))
    shoot(o, 'paint_broad', float(SCALE) * 2)
if 'deck' in want:      # the forward deck close: the triangle plates, rivet rows, the crest and the spine line
    o = cam('deck', Vector((0.25, 0, 0.035)), Vector((-0.30, 0.45, 1.0)).normalized() * .36, 50, (1280, 720))
    shoot(o, 'paint_deck', float(SCALE) * 2)
if 'flank' in want:     # the port flank close: the broadside band's plates, a deck number, the frost points
    o = cam('flank', Vector((0.15, 0.07, -0.02)), Vector((0.05, 1.0, 0.25)).normalized() * .30, 50, (1280, 720))
    shoot(o, 'paint_flank', float(SCALE) * 2)
print('[756] preview done', flush=True)
