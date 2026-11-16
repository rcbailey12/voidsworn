"""Issue 853 pictures, using the recipe's painted blend and shared paint camera.

Render: blender -b KB1CC.blend -P capture.py -- render RAW_DIR
Compose: python capture.py compose RAW_DIR OUT_DIR [BEFORE_RAW_DIR]
Raw images stay outside git. This script changes the preview scene only.
"""
import json
import math
from pathlib import Path
import runpy
import sys

HERE = Path(__file__).resolve().parent
REPO = HERE.parents[3]
SHEETS = REPO / 'tools/blender/build_sheets'
CODE = 'corsair_KB1CC'
CONCEPT = REPO / 'contrib/muse/design/squadron_concepts_2026_11/hullbreakers/round_3/KB1CC.jpg'
args = sys.argv[sys.argv.index('--') + 1:] if '--' in sys.argv else sys.argv[1:]
mode, raw = args[0], Path(args[1])

if mode == 'render':
    import bpy
    from mathutils import Vector

    sc = bpy.context.scene
    sheet_length = float(sc['r209_length_world'])
    assert math.isclose(sheet_length, 1.6), sheet_length
    # paint_sheet's cam170 reads the drawn length. Craft draw at 1.6 * 1.6 * 1.5.
    # The baked blend and its design length are never saved or changed on disk.
    drawn_length = sheet_length * 1.6 * 1.5
    sc['r209_length_world'] = drawn_length
    sys.argv = ['paint_sheet.py', '--', str(raw), CODE, str(CONCEPT),
                'scale=1', 'samples=64', 'gpu=1', 'cam170=1']
    shared = runpy.run_path(str(SHEETS / 'paint_sheet.py'), run_name='__main__')
    sc['r209_length_world'] = sheet_length
    # This craft is wider than long. Fit the flat views to its evaluated bounds;
    # paint_sheet's capital-ship flat framing crops a wide craft vertically.
    dg = bpy.context.evaluated_depsgraph_get()
    pts = [o.evaluated_get(dg).matrix_world @ Vector(v)
           for o in sc.objects if o.type == 'MESH' and not o.hide_render
           for v in o.evaluated_get(dg).bound_box]
    lo = Vector(tuple(min(p[i] for p in pts) for i in range(3)))
    hi = Vector(tuple(max(p[i] for p in pts) for i in range(3)))
    mid = (lo + hi) / 2
    span = hi - lo
    views = [('top', (0, 0, 3), (0, -1, 0), (span.x, span.y)),
             ('below', (0, 0, -3), (0, 1, 0), (span.x, span.y)),
             ('side', (0, 3, 0), (0, 0, 1), (span.x, span.z)),
             ('side_s', (0, -3, 0), (0, 0, 1), (span.x, span.z)),
             ('bow', (3, 0, 0), (0, 0, 1), (span.y, span.z)),
             ('stern', (-3, 0, 0), (0, 0, 1), (span.y, span.z))]
    for name, loc, up, (width, height) in views:
        cam = shared['ortho'](name + '_wide', mid + Vector(loc), mid, up,
                              max(width, height * 1280 / 660) * 1.12, (1280, 660))
        shared['shoot'](cam, 'paint_' + name, 1.0)
    cam = shared['look_cam'](35, 30, 4.8, 52, (1280, 660), (0, 0, 0))
    shared['shoot'](cam, 'paint_glacis', 1.0)
    evidence = dict(sheet_length=sheet_length, drawn_length=drawn_length,
                    battle_radius=170, vertical_fov=45, pitch_from_up=0.98,
                    full_frame=[1920, 1080], unscaled_crop=[640, 360],
                    beauty_clip=[shared['beauty'].data.clip_start,
                                 shared['beauty'].data.clip_end],
                    source_blend=bpy.data.filepath,
                    note='Painted preview only; no stage 7 export or game install.')
    (raw / 'capture.json').write_text(json.dumps(evidence, indent=1) + '\n')
elif mode == 'compose':
    from PIL import Image, ImageDraw

    out = Path(args[2])
    out.mkdir(parents=True, exist_ok=True)
    sys.argv = ['paint_compare.py', str(raw), str(CONCEPT), '-', CODE, str(out),
                'name=' + CODE, 'stack=Hullbreaker', 'issue=853']
    shared = runpy.run_path(str(SHEETS / 'paint_compare.py'), run_name='__main__')
    shared['pair'](Image.open(CONCEPT).convert('RGB'),
                   Image.open(raw / 'paint_glacis.png').convert('RGB'),
                   CODE + ': accepted concept (left), painted glacis view (right)',
                   'Extra three-quarter view to show the slope; fitted concept camera is on the paint_full sheet.',
                   str(out / (CODE + '_paint_glacis.jpg')))
    battle = out / (CODE + '_paint_cam170.jpg')
    img = Image.open(battle).convert('RGB')
    ImageDraw.Draw(img).rectangle((0, 0, 1279, 59), fill=shared['BG'])
    shared['head'](img, CODE + ': battle camera 170, drawn length 3.84',
                   'Painted preview: left at 1:1 pixels on a 1080p screen; right enlarged 2x. FOV 45, pitch 0.98 rad.')
    img.save(battle, quality=95)
    if len(args) > 3:
        before = Path(args[3])
        shared['pair'](Image.open(before / 'paint_beauty.png').convert('RGB'),
                       Image.open(raw / 'paint_beauty.png').convert('RGB'),
                       CODE + ': capital pattern (left), craft size setting (right)',
                       'Same fitted camera and game light; larger patches and marks, less bare wear on grey trophy plates.',
                       str(out / (CODE + '_paint_size_compare.jpg')))
    for path in out.glob('*.jpg'):
        with Image.open(path) as im:
            assert im.height <= 720, (path, im.size)
            print(path.name, im.size)
else:
    raise SystemExit('Expected render or compose')
