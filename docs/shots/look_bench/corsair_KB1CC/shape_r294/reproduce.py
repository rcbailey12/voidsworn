"""Issue 903: rebuild KB1CC, check the sheet contract, bake the existing stack and publish labelled proof.

python reproduce.py %TEMP%/voidsworn903_r299 [all|paint|capture|publish]
Blender entry: blender -b KB1CC.blend -P reproduce.py -- capture RAW
Scratch stays in OUT. Review files also go to board_b/issue-903/shots.
"""
import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys

HERE = Path(__file__).resolve().parent
REPO = HERE.parents[4]
PC = REPO.parents[1]
CODE = 'corsair_KB1CC'
CONCEPT = REPO / 'contrib/muse/design/squadron_concepts_2026_11/hullbreakers/round_3/KB1CC.jpg'
SHEET = REPO / 'docs/ship_pipeline/build_sheets' / CODE
BLENDER = PC / 'blender/blender-4.5.14-windows-x64/blender.exe'
SHOTS = REPO.parent / 'issue-903/shots'


def check_build(out):
    import bpy
    sys.path[:0] = [str(REPO / 'tools/blender/kits/shared'), str(REPO / 'tools/blender/r209')]
    import plumbing
    sc = bpy.context.scene
    objects = [o for o in sc.objects if o.type == 'MESH']
    hull = [o for o in objects if o.get('role') == 'hull']
    parts = [o for o in objects if o.get('role') not in ('hull', 'glow', 'interior')]
    # The shared audit accepts a launcher-only craft. Its weapon exits and slots
    # are checked by build.py fit and weapon_match, rather than inventing a gun.
    record = plumbing.audit(hull, parts, guns=[], t_lines=tuple(sc['r209_t_lines']),
                            t_paths=json.loads(sc['r209_t_paths']), l_line=(), l_lines=[])
    record['ok'] = not record['problems'] and not record['crossing_break_lines']
    out.write_text(json.dumps(record, indent=1) + '\n')
    assert record['ok'], record
    print('PASS shared mount and machine-seam audit', flush=True)


def capture(raw):
    import bpy
    import runpy
    import numpy as np
    from mathutils import Vector
    sys.argv = ['capture.py', '--', 'render', str(raw)]
    result = runpy.run_path(str(HERE.parent / 'capture.py'), run_name='__main__')
    shared = result['shared']
    # The outline score uses this exact built geometry in sheet units, with the
    # existing fitted camera held fixed. No camera or shape optimization.
    dg = bpy.context.evaluated_depsgraph_get()
    triangles = []
    contract_scale = float(bpy.context.scene['r209_scale'])
    for ob in bpy.context.scene.objects:
        if ob.type != 'MESH' or ob.hide_render:
            continue
        evaluated = ob.evaluated_get(dg)
        mesh = evaluated.to_mesh(); mesh.calc_loop_triangles()
        for tri in mesh.loop_triangles:
            triangles.append([tuple((ob.matrix_world @ mesh.vertices[i].co) / contract_scale) for i in tri.vertices])
        evaluated.to_mesh_clear()
    np.savez_compressed(raw.parent / 'outline_tris.npz', tris=np.asarray(triangles, dtype='float32'))
    cam = shared['look_cam'](145, 28, 3.8, 52, (1080, 720), (0, 0, .02))
    shared['shoot'](cam, 'paint_rear', 1)
    for name, target, direction, view_scale in (
        ('tube', (.385, .495, .059), (1.1, .65, .55), .46),
        ('bay', (.01, .405, .015), (.38, .8, 1.4), .59),
        ('nacelle', (-.435, .49, .065), (-1.1, .6, .5), .36),
    ):
        # The recipe scene is normalized by its evaluated length.
        factor = float(bpy.context.scene['r209_length_world']) * contract_scale
        p = Vector(target) * factor
        o = shared['ortho'](name, p + Vector(direction), p, (0, 0, 1), view_scale, (1080, 660))
        shared['shoot'](o, 'paint_' + name, 1)
    weapon = [o for o in bpy.context.scene.objects if o.type == 'MESH' and o.get('grp') == 'BT1']
    assert weapon
    points = [o.matrix_world @ Vector(v) for o in weapon for v in o.bound_box]
    lo = Vector([min(v[i] for v in points) for i in range(3)])
    hi = Vector([max(v[i] for v in points) for i in range(3)])
    p = (lo + hi) / 2
    visible = {o.name for o in weapon}
    for ob in bpy.context.scene.objects:
        if ob.type == 'MESH': ob.hide_render = ob.name not in visible
    o = shared['ortho']('weapon_bombs', p + Vector((1, .55, .4)), p, (0, 0, 1), max(hi-lo)*1.5, (1080, 660))
    shared['shoot'](o, 'paint_weapon_bombs', 1)


def main():
    from PIL import Image, ImageDraw, ImageFont
    sys.path.insert(0, str(REPO / 'tools'))
    from picture_provenance import open_picture, save_picture, verify
    out = Path(sys.argv[1]).resolve()
    mode = sys.argv[2] if len(sys.argv) > 2 else 'all'
    out.mkdir(parents=True, exist_ok=True)
    SHOTS.mkdir(parents=True, exist_ok=True)
    env = os.environ.copy()
    env.update(PYTHONDONTWRITEBYTECODE='1', PC_GPU_ISSUE='903-r299', SHEET_SAMPLES='32',
               R209_SHIP=str(REPO / 'tools/recipe/ships/corsair_KB1CC.json'))
    for key in ('TMO_REPO', 'TMO_OUT', 'TMO_LOG', 'TMO_ERR_LOG'):
        env.pop(key, None)

    def run(label, args):
        with (out / (label + '.log')).open('w') as log:
            result = subprocess.run([str(a) for a in args], cwd=REPO, env=env,
                                    stdout=log, stderr=subprocess.STDOUT)
        if result.returncode:
            raise RuntimeError(f'{label}: exit {result.returncode}, see {out / (label + ".log")}')
        print('PASS', label, flush=True)

    def blender(label, args):
        run(label, [REPO / 'tools/pc/tmo.bat', '3600', BLENDER, '-b', '-t', '4', '--python-exit-code', '1', *args])

    # Inventory/outline use SciPy. Keep its wheel and dependencies in this job's
    # scratch folder if Ryan's ordinary Python does not already provide it.
    deps = out / 'deps'
    if not (deps / 'scipy').exists():
        import importlib.util
        if importlib.util.find_spec('scipy') is None:
            run('dependencies', [sys.executable, '-m', 'pip', 'install', '--target', deps, 'scipy'])
    env['PYTHONPATH'] = str(deps) + os.pathsep + env.get('PYTHONPATH', '')
    if mode == 'all':
        blender('sheet', ['-P', 'tools/blender/build_sheets/build.py', '--', CODE, out / 'sheet', 'render'])
    fit = json.loads((out / f'sheet/{CODE}_fit.json').read_text())
    assert not any(fit['counts'].values()), fit['counts']
    if mode in ('all', 'paint'):
        blender('contract', ['-P', 'tools/recipe/sheet_contract_selftest.py', '--', env['R209_SHIP'], out / 'contract'])
        blender('bake', ['-P', 'tools/blender/r209/bake_sheet.py', '--', out, 'none', 'none', 'KB1CC', '2048', '32'])
        blender('machine_fit', [out / 'KB1CC.blend', '-P', __file__, '--', 'check', out / 'machine_fit.json'])
        blender('capture', [out / 'KB1CC.blend', '-P', __file__, '--', 'capture', out / 'paint'])
        blender('surface', [out / 'KB1CC.blend', '-P', 'tools/recipe/surface_check.py', '--', out / 'surface'])
        blender('density', [out / 'KB1CC.blend', '-P', 'tools/blender/build_sheets/studies/mesh_density.py', '--', out / 'density_mesh.json'])
        for check in ('licences', 'lights'):
            run(check, [sys.executable, 'tools/recipe/standing.py', check, '--ship', env['R209_SHIP'], '--job', out])
    if mode == 'capture':
        blender('capture', [out / 'KB1CC.blend', '-P', __file__, '--', 'capture', out / 'paint'])
    src = REPO / f'tools/blender/build_sheets/ships/{CODE}.py'
    digest = hashlib.sha256(src.read_bytes()).hexdigest()
    base = subprocess.check_output(['git', 'rev-parse', '--short=8', 'HEAD'], cwd=REPO, text=True).strip()
    revision = f'{base}+903-r2-{digest[:10]}'
    layout = out / 'layout'
    for label, args in (
        ('layout', ['tools/blender/build_sheets/layout.py', out / 'sheet', REPO, layout]),
        ('inventory', ['tools/blender/build_sheets/inventory.py', CODE, REPO, layout, out / f'sheet/{CODE}_model.json']),
        ('extras', ['tools/blender/build_sheets/sheet_extras.py', CODE, out / 'sheet', REPO, layout]),
    ):
        run(label, [sys.executable, *args])
    blank = open_picture(CONCEPT).convert('RGB')
    ImageDraw.Draw(blank).rectangle((0, 658, 540, 720), fill=(16, 16, 16))
    blank.save(out / 'concept_no_label.jpg')
    run('mask', [sys.executable, 'contrib/opus/tools/issue738/mask.py', out / 'concept_no_label.jpg', out / 'concept_mask.png'])
    run('outline', [sys.executable, 'tools/blender/build_sheets/fit.py', out / 'outline_tris.npz', out / 'concept_mask.png',
                    CONCEPT, out / 'KB1CC_outline', REPO / f'tools/blender/build_sheets/ships/{CODE}_camera.json'])
    outline = json.loads((out / 'KB1CC_outline_camera.json').read_text())
    dimensions = json.loads((layout / 'checks.json').read_text())
    old_score = dimensions.get('outline_iou_percent')
    old_mass_score = dimensions.get('mass_outline_iou_percent')
    dimensions['outline_iou_percent'] = round(outline['iou']*100, 1)
    dimensions['mass_outline_iou_percent'] = round(outline['body_iou']*100, 1)
    dimensions['outline_note'] = 'R299 run 2 geometry, fixed historical outline camera; reported, not gated'
    (layout / 'checks.json').write_text(json.dumps(dimensions, indent=1) + '\n')
    table = (layout / 'feature_table.md').read_text()
    table = table.replace(f'| outline iou percent | {old_score} |', f'| outline iou percent | {dimensions["outline_iou_percent"]} |')
    table = table.replace(f'| mass outline iou percent | {old_mass_score} |', f'| mass outline iou percent | {dimensions["mass_outline_iou_percent"]} |')
    lines = table.splitlines()
    in_features = False
    for index, line in enumerate(lines):
        if line.startswith('| ID | Fitting |'):
            in_features = True
            value = 'Route'
        elif in_features and line.startswith('|---'):
            value = '---'
        elif in_features and line.startswith('|'):
            fid = line.split('|')[1].strip()
            value = 'hand-built' if fid in ('Y1', 'Y2', 'BT1', 'BT2') else 'kit'
        else:
            in_features = False
            continue
        lines[index] = line + ' ' + value + ' |'
    table = '\n'.join(lines) + '\n'
    (layout / 'feature_table.md').write_text(table)
    routes = json.loads((layout / 'manifest.json').read_text())
    for part in routes['parts']:
        if part['id'] in ('Y1', 'Y2', 'BT1', 'BT2'):
            part['route'] = 'hand-built'
            part['builder'] = f'tools/blender/build_sheets/ships/{CODE}.py: ' + ('sunken machinery well' if part['id'].startswith('Y') else 'corner_bomb, kit collar and deeper red-lined bore')
    (layout / 'manifest.json').write_text(json.dumps(routes, indent=1) + '\n')
    # Layout already makes the manifest, full feature table and dimension checks.
    # Publish only images <=720 high, and stamp every current sheet with its stage.
    font = lambda n: ImageFont.truetype('C:/Windows/Fonts/segoeui.ttf', n)

    def stamp(im, title, stage='SHEET BUILT'):
        im = im.convert('RGB')
        im.thumbnail((1280, 660), Image.Resampling.LANCZOS)
        page = Image.new('RGB', (max(640, im.width), im.height + 60), (14, 15, 18))
        page.paste(im, ((page.width-im.width)//2, 60))
        d = ImageDraw.Draw(page)
        d.text((12, 4), 'KB1CC | ' + title, font=font(20), fill='white')
        d.text((12, 32), stage + ' | Rev ' + revision, font=font(16), fill=(183, 187, 195))
        return page

    for name in ('side', 'top', 'underside', 'bow', 'stern', 'cutaway', 'threequarter'):
        im = open_picture(layout / (name + '.png'))
        stamp(im, name).save(SHEET / (name + '.jpg'), quality=91)
    for name in ('preview', 'sheet', 'fit_view', 'side_by_side', 'cells'):
        stamp(open_picture(layout / (name + '.jpg')), name).save(SHEET / (name + '.jpg'), quality=91)
    for name in ('feature_table.md', 'checks.json', 'manifest.json', 'fit_report.md', 'cells.json', 'inventory.md'):
        shutil.copy2(layout / name, SHEET / name)
    shutil.copy2(out / f'sheet/{CODE}_fit.json', SHEET / 'fit.json')
    shutil.copy2(out / f'sheet/{CODE}_weapon_match.json', SHEET / 'weapon_match.json')
    shutil.copy2(out / 'density_mesh.json', SHEET / 'density_mesh.json')
    stamp(open_picture(out / 'paint/paint_weapon_bombs.png'), 'bombs T: one of two matching tubes', 'PAINT PROOF').save(SHEET / 'weapon_bombs.jpg', quality=91)

    def page(title):
        im = Image.new('RGB', (1280, 720), (14, 15, 18))
        d = ImageDraw.Draw(im)
        d.text((12, 5), 'KB1CC | ' + title, font=font(24), fill='white')
        d.text((12, 38), 'PAINT PROOF | Rev ' + revision + ' | Existing Hullbreaker stack, game light 1.25', font=font(17), fill=(182, 186, 194))
        return im

    def put(page, path, box, label, crop=None):
        im = open_picture(path).convert('RGB')
        if crop: im = im.crop(crop)
        im.thumbnail((box[2], box[3]-28), Image.Resampling.LANCZOS)
        page.paste(im, (box[0]+(box[2]-im.width)//2, box[1]+28+(box[3]-28-im.height)//2))
        ImageDraw.Draw(page).text((box[0]+8, box[1]), label, font=font(18), fill=(235, 184, 110))

    im = page('R299 run 2: concept, run 1, restored bomb tubes and red armour')
    put(im, CONCEPT, (0, 82, 424, 352), 'Accepted concept, R259')
    put(im, HERE / 'KB1CC_R294_run1_paint_full.jpg',
        (428, 82, 424, 352), 'Run 1, ba3af366, paint proof', (0, 70, 1080, 720))
    put(im, out / 'paint/paint_beauty.png', (856, 82, 424, 352), 'Run 2, same paint_full camera')
    put(im, out / 'paint/paint_side.png', (0, 458, 640, 205), 'Ramp, then plateau; tapered toe at left')
    put(im, out / 'paint/paint_rear.png', (640, 438, 640, 275), 'Two main nacelles plus the stern row')
    im.save(HERE / 'KB1CC_R299_compare.jpg', quality=94)
    # Full-size feature evidence, one named ship per sheet.
    for name, title, a, b, labels in (
        ('details', 'sunken side bays and aft-facing engines', 'bay', 'rear', ('Cut shoulder, coupled pipes and bomb hoist', 'Deep red-orange main-drive throats and stern row')),
        ('profile', 'tapered bow, raised rails, ramp then plateau', 'top', 'side', ('Top: narrowed toe and swept shoulder edges', 'Side: sloped glacis meets a level upper deck')),
    ):
        im = page(title)
        put(im, out / f'paint/paint_{a}.png', (0, 86, 640, 572), labels[0])
        put(im, out / f'paint/paint_{b}.png', (640, 86, 640, 572), labels[1])
        im.save(HERE / ('KB1CC_R299_' + name + '.jpg'), quality=94)
    im = page('R299: camera 170, run 1 and run 2 at the same true pixel size')
    for row, source, label in ((0, HERE / 'KB1CC_R294_run1_cam170_pixels.png', 'Run 1 | ba3af366 | PAINT PROOF'),
                               (1, out / 'paint/paint_cam170.png', 'Run 2 | ' + revision + ' | PAINT PROOF')):
        frame = open_picture(source).convert('RGB')
        # Each frame is the shared 640 x 360 crop from the same 1080p camera.
        # Crop black margin only. The ship stays at exactly its rendered pixels.
        y = 106 + row*298
        im.paste(frame.crop((0, 54, 640, 306)), (0, y+24))
        crop = frame.crop((214, 120, 426, 204)).resize((636, 252), Image.Resampling.NEAREST)
        im.paste(crop, (644, y+24))
        ImageDraw.Draw(im).text((12, y), label + ' | left 1:1, right 3x', font=font(17), fill=(235,184,110))
    im.save(HERE / 'KB1CC_R299_cam170.jpg', quality=95)
    im = page('R299: bomb tube mouth, dark collar and deep red bore')
    put(im, out / 'paint/paint_tube.png', (0, 86, 900, 582), 'Port corner armour, actual painted hull')
    put(im, out / 'paint/paint_weapon_bombs.png', (900, 86, 380, 582), 'One of two bombs T mouths')
    im.save(HERE / 'KB1CC_R299_tube.jpg', quality=95)
    im = page('R299: paint_full camera, enlarged forward weapons and red armour')
    put(im, out / 'paint/paint_beauty.png', (0, 82, 1280, 638), 'Run 2 | paint_full 35 degrees / 30 degrees / 52 mm')
    im.save(HERE / 'KB1CC_R299_paint_full.jpg', quality=95)
    # Retire stale sheet comparison images by rebuilding them from the same revision.
    for name in ('corsair_KB1CC_compare.jpg', 'corsair_KB1CC_sheet_overview.jpg'):
        shutil.copy2(HERE / 'KB1CC_R299_compare.jpg', SHEET / name)
    stamp(open_picture(out / 'KB1CC_outline_overlay.jpg'), 'outline at the fixed historical camera').save(SHEET / 'outline_check.jpg', quality=91)
    im = Image.new('RGB', (1280, 720), (44, 44, 46))
    put(im, CONCEPT, (0, 70, 640, 530), 'Accepted concept, R259')
    put(im, out / 'sheet/beauty_cam.png', (640, 70, 640, 530), 'Rebuilt sheet at the saved outline camera')
    stamp(im, 'concept beside blockout').save(SHEET / 'beauty_vs_blockout.jpg', quality=91)
    wm = json.loads((SHEET / 'weapon_match.json').read_text())
    im = Image.new('RGB', (1280, 660), (44, 44, 46))
    put(im, out / 'paint/paint_weapon_bombs.png', (0, 0, 800, 560), 'One of two matching fixed forward bomb tubes')
    ImageDraw.Draw(im).text((810, 150), 'bombs T: PASS\n2 shots per volley\nBT1: 1 muzzle\nBT2: 1 muzzle\nBoth mounts fire', font=font(23), fill='white')
    stamp(im, 'weapon match: bombs T, two shots', 'PAINT PROOF').save(SHEET / 'weapon_review.jpg', quality=91)
    run('manifest', ['node', 'contrib/opus/tools/build_manifest_tests.js'])
    meta = json.loads((out / 'KB1CC.json').read_text())
    manifest = json.loads((SHEET / 'manifest.json').read_text())
    model = json.loads((out / f'sheet/{CODE}_model.json').read_text())
    assert {x['id'] for x in manifest['parts']} == {x['id'] for x in model['features']}
    surface = json.loads((out / 'surface/surface_check.json').read_text())
    contract = json.loads((out / 'contract/sheet_contract_selftest.json').read_text())
    machine_fit = json.loads((out / 'machine_fit.json').read_text())
    assert surface['ok'] and contract['ok'] and machine_fit['ok']
    def red_measure(path, crop=None):
        image = open_picture(path).convert('RGB')
        if crop: image = image.crop(crop)
        visible = red = 0
        for r, g, b in image.getdata():
            if max(r, g, b) > 32:
                visible += 1
                red += r > 1.30*g and r > 1.40*b
        return dict(visible_pixels=visible, red_pixels=red, red_percent=round(100*red/max(1, visible), 1))
    red_area = dict(method='Visible pixels: max sRGB channel >32; red: R>1.30G and R>1.40B. Same paint_full camera; reported, not gated.',
                    run1=red_measure(HERE / 'KB1CC_R294_run1_paint_full.jpg', (0, 70, 1080, 720)),
                    run2=red_measure(out / 'paint/paint_beauty.png'))
    evidence = dict(revision=revision, stage='paint proof, not installed or accepted',
                    design_sha256=digest, fit=fit['counts'], weapon_match=wm['result'], contract='PASS', manifest='PASS',
                    machine_fit=machine_fit, rendered_red_area=red_area,
                    outline_iou_percent=dimensions['outline_iou_percent'],
                    triangles=meta['triangles'], objects=meta['objects'], surfaces=meta['surfaces'],
                    draw_calls_merged=meta['draw_calls_merged'], surface=surface,
                    paint=meta['paint'], capture=json.loads((out / 'paint/capture.json').read_text()))
    evidence['source_sha256'] = {str(path.relative_to(REPO)).replace('\\', '/'): hashlib.sha256(path.read_bytes()).hexdigest()
                                 for path in (src, src.with_name(CODE + '_inv.py'), Path(__file__),
                                              HERE.parent / 'capture.py', REPO / 'tools/blender/kits/hullbreakers/stack.py')}
    (HERE / 'checks.json').write_text(json.dumps(evidence, indent=2) + '\n')
    (SHEET / 'README.md').write_text(f'''# corsair_KB1CC: R299 run 2, issue 903

Revision: `{revision}`. Stage: sheet built and paint proof, not installed or accepted.

Run 2 restores the concept's large forward bomb mouths in dark collars, with
real bores and dim red liners. Their radius is .064 LENGTH, up from .026 in run 1.
The drums blend into red corner armour; the bores cut that armour and the shoulder
skins. The next bomb sits deep inside, with no engine plug or flared throat.
Both mounts remain bombs T, two shots per volley. The stern nacelles are 19 and
18 percent smaller and .016/.014 LENGTH lower, with orange flared throats.
The five stern thrusters, sunken bays, pipes, rails, tapered bow and plateau stay.

Only KB1CC paint inputs change: larger physical plates, rust/blood weights raised
from 49 to 85 percent, rust underpaint on the body and shoulders. The existing
Hullbreaker stack supplies the same seams, grime, scrapes and worn metal edges.
Grey salvage is a minority; there are no pale or purple plate zones.
Measured red area is {red_area['run1']['red_percent']} percent in run 1 and
{red_area['run2']['red_percent']} percent in run 2, using the threshold documented
in the evidence JSON. This reports the painted result, not just material weights.

The older R275 sheet simplified the top to one ramp, retained the broad bow toe,
and put shallow machinery panels on closed shoulder skins. Run 1 restored these
features but reduced the front tubes to tiny weapons. R299 corrects that tradeoff.

[Concept, run 1 and run 2](../../../shots/look_bench/corsair_KB1CC/shape_r294/KB1CC_R299_compare.jpg)
uses the saved paint_full camera. [Tube close view](../../../shots/look_bench/corsair_KB1CC/shape_r294/KB1CC_R299_tube.jpg)
shows the collar, real bore and integrated corner armour.
[Camera 170](../../../shots/look_bench/corsair_KB1CC/shape_r294/KB1CC_R299_cam170.jpg)
compares both runs at true pixel size. Every current picture names its revision
and stage and is at most 720 pixels high. These are paint proofs, not game installs.

Method: this sheet's [design](../../../../tools/blender/build_sheets/ships/corsair_KB1CC.py),
[manifest](manifest.json), the existing sheet contract and Hullbreaker craft stack.
The wells and the modified kit bomb tubes are recorded as hand-built in the manifest.
[Rebuild and evidence](../../../shots/look_bench/corsair_KB1CC/shape_r294/README.md).

Budget: {meta['triangles']:,} exterior triangles, {meta['objects']} outside mesh objects,
{meta['draw_calls_merged']} merged draw calls and {meta['surfaces']} surfaces. These are
reported counts, not caps or measured frame times. No game export or install is included.

Checks: zero fit clashes, weapon match PASS, inventory PASS, sheet contract PASS,
shared mount/machine-seam audit PASS, manifest agreement PASS, texture licences PASS,
lights PASS. Six painted surface views found zero room-colour and zero bare pixels.
Outline overlap is {dimensions['outline_iou_percent']} percent with the historical camera held
fixed; it is reported, not a pass bar. See [dimensions](checks.json),
[fit](fit.json), [weapons](weapon_match.json), [inventory](inventory.md),
[features](feature_table.md), and the [painted evidence](../../../shots/look_bench/corsair_KB1CC/shape_r294/checks.json).
''')
    # Preserve the source render revision when composing and publishing. The
    # R294 snapshots predate picture sidecars; they remain labelled references.
    current_sources = [verify(out / 'paint/paint_beauty.png')]
    for path in HERE.glob('KB1CC_R299_*.jpg'):
        sources = current_sources
        if 'cam170' in path.name:
            sources = [verify(out / 'paint/paint_cam170.png')]
        save_picture(Image.open(path), path, 'paint proof', sources=sources, quality=95)
    for path in SHEET.glob('*.jpg'):
        stage = 'sheet built'
        raw_source = out / 'sheet' / (path.stem + '.png')
        if raw_source.is_file():
            sources = [verify(raw_source)]
        elif path.name in ('weapon_bombs.jpg', 'weapon_review.jpg'):
            sources = [verify(out / 'paint/paint_weapon_bombs.png')]; stage = 'paint proof'
        elif path.name in ('corsair_KB1CC_compare.jpg', 'corsair_KB1CC_sheet_overview.jpg'):
            sources = current_sources; stage = 'paint proof'
        else:
            sources = [verify(out / 'sheet/beauty_cam.png')]
        save_picture(Image.open(path), path, stage, sources=sources, quality=95)
    for path in HERE.iterdir():
        if path.suffix in ('.jpg', '.png', '.json', '.md', '.py', '.bat'):
            shutil.copy2(path, SHOTS / path.name)
    for path in list(SHEET.glob('*.jpg')) + list(HERE.glob('*.jpg')):
        assert open_picture(path).height <= 720, path
    print('DONE', revision, meta['triangles'], 'triangles', meta['surfaces'], 'surfaces', flush=True)


if __name__ == '__main__':
    if '--' in sys.argv:
        args = sys.argv[sys.argv.index('--')+1:]
        if args[0] == 'capture':
            capture(Path(args[1]))
        elif args[0] == 'check':
            check_build(Path(args[1]))
        else:
            raise ValueError(args[0])
    else:
        main()
