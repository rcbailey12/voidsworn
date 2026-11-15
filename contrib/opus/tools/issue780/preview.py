# Issue 780 sandbox previews of a painted Hegemony sheet ship (sandbox only, not a standing check). Runs the repo's paint_sheet.py
# (the game light, the Hegemony battle lift read from look.gd, the sheet's fitted beauty camera, the flat views, the stern zoom
# and one nozzle close, and cam170: the game's battle camera at 34 degrees above the board and its true pixel size, fixed in
# PR 777), then adds what this job's pictures need:
#   battle  the battle camera as the build sheet frames it (ships/<sheet>_camera_battle.json: 34 degrees above the board, port
#           beam, range 170, a long lens so the ship fills the frame)
#   band    a module band close, from above the port bow quarter: the even grid, the double seam, the latch row
#   flank   the port flank close: the blue line, its break at a band, the hull number
#   nozzle  one nozzle from astern, off its axis (as paint_sheet.py's bell camera)
#   mark    a decal close (only with mark=x,y,z, a position from the job's decal report)
# usage: python run_cpu.py preview.py PAINTED.blend -- OUT_DIR SHEET CONCEPT_JPG [samples=16] [scale=0.5] [only=battle,band,flank,nozzle,mark] [mark=x,y,z]
import os, sys, math, json, re, runpy
import bpy
from mathutils import Vector

REPO = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..', '..', '..'))
a = sys.argv[sys.argv.index('--') + 1:]
OUT, SHEET, CONCEPT = a[0], a[1], a[2]; kw = dict(x.split('=', 1) for x in a[3:] if '=' in x)
SAMP = kw.get('samples', '16'); SCALE = kw.get('scale', '0.5')
LIFT = float(re.search(r'"hegemony":\s*\{[^}]*"lift":\s*([0-9.]+)', open(os.path.join(REPO, 'godot', 'render', 'look.gd')).read()).group(1))
only = kw.get('only')
args = ['x', '--', OUT, SHEET, CONCEPT, f'lift={LIFT}', f'samples={SAMP}', f'scale={SCALE}', 'sky_spec=0']
ps = os.path.join(REPO, 'tools', 'blender', 'build_sheets', 'paint_sheet.py')
if only:      # extra views only: the same game light and lift, without paint_sheet's standard views
    sys.argv = args
    src = open(ps).read().split("beauty = look_cam(")[0]
    G = {'__file__': ps, '__name__': 'ps'}; exec(compile(src, ps, 'exec'), G)
else:
    sys.argv = args + ['cam170=1']; G = runpy.run_path(ps)
want = set((only or 'battle,band,flank').split(','))
sc = bpy.context.scene; shoot, look_cam = G['shoot'], G['look_cam']
bc = json.load(open(os.path.join(REPO, 'tools', 'blender', 'build_sheets', 'ships', SHEET + '_camera_battle.json')))
if 'battle' in want:
    o = look_cam(bc['az'], bc['el'], bc['dist'], bc['mm'], tuple(bc['res']), bc['target'], 0, (0, 0))
    o.data.clip_end = 400; shoot(o, 'paint_battle', 1.0)


def cam(name, target, offset, lens, res):
    c = bpy.data.cameras.new(name); o = bpy.data.objects.new(name, c); sc.collection.objects.link(o)
    o.location = target + offset; o.rotation_euler = (target - o.location).to_track_quat('-Z', 'Y').to_euler()
    c.lens = lens; c.clip_start = .0005; c.clip_end = 20; sc.render.resolution_x, sc.render.resolution_y = res
    return o


def box(o):
    P = [o.matrix_world @ Vector(b) for b in o.bound_box]
    return Vector((min(p.x for p in P), min(p.y for p in P), min(p.z for p in P))), Vector((max(p.x for p in P), max(p.y for p in P), max(p.z for p in P)))


seams = [box(o) for o in sc.objects if o.type == 'MESH' and '_bandseam_' in o.name]
if 'band' in want and seams:      # the most forward band that crosses the deck's centreline (a wedge band), at its port deck edge
    wedge = [b for b in seams if b[0].y < 0 < b[1].y] or seams
    lo, hi = max(wedge, key=lambda b: b[1].x)
    t = Vector(((lo.x + hi.x) / 2, hi.y * .55, hi.z))
    o = cam('band', t, Vector((0.45, 0.55, 1.0)).normalized() * .30, 50, (1280, 720)); shoot(o, 'paint_band', float(SCALE) * 2)
if 'flank' in want:
    blue = [box(o) for o in sc.objects if o.type == 'MESH' and o.get('role') == 'hull' and o.data.materials and
            o.data.materials[0] and o.data.materials[0].name.startswith('p3_hblue') and box(o)[0].y > 0]
    if blue:
        lo, hi = max(blue, key=lambda b: (b[1].x - b[0].x) * (1 if b[1].z > -.02 else .5))
        t = Vector((hi.x - .02, hi.y, (lo.z + hi.z) / 2))
    else:
        t = Vector((.25, .15, 0))
    o = cam('flank', t, Vector((0.25, 1.0, 0.30)).normalized() * .34, 50, (1280, 720)); shoot(o, 'paint_flank', float(SCALE) * 2)
if 'nozzle' in want:     # one nozzle from astern and a little off its axis (paint_sheet.py's bell camera, for the only= mode)
    hp = json.loads(sc.get('r209_hp', '{}')).get('engines', [])
    if hp:
        big = max(hp, key=lambda e: e['radius']); bp = Vector(big['pos']); r = big['radius']
        o = cam('nozzle', bp + Vector((r * .6, 0, 0)), Vector((-7.0 * r, 2.2 * r * (1 if bp.y >= 0 else -1), 2.0 * r)) - Vector((r * .6, 0, 0)), 50, (1200, 1000))
        shoot(o, 'paint_nozzle', float(SCALE) * .6)
if 'mark' in want and kw.get('mark'):      # a decal close (mark=x,y,z from the job's decal report): the stencil read at close range
    t = Vector(tuple(float(v) for v in kw['mark'].split(',')))
    o = cam('mark', t, Vector((0.15, 1.0 if t.y >= 0 else -1.0, 0.35)).normalized() * .12, 50, (1280, 720)); shoot(o, 'paint_mark', float(SCALE) * 2)
print('[780] preview done', flush=True)
