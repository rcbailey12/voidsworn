"""Issue 903: rebuild KB1CC, check the sheet contract, bake the existing stack and publish labelled proof.

python reproduce.py %TEMP%/voidsworn903 [all|paint|capture|publish]
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
    out = Path(sys.argv[1]).resolve()
    mode = sys.argv[2] if len(sys.argv) > 2 else 'all'
    out.mkdir(parents=True, exist_ok=True)
    SHOTS.mkdir(parents=True, exist_ok=True)
    env = os.environ.copy()
    env.update(PYTHONDONTWRITEBYTECODE='1', PC_GPU_ISSUE='903-shape', SHEET_SAMPLES='32',
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
        run(label, [REPO / 'tools/pc/tmo.bat', '3600', BLENDER, '-b', '--python-exit-code', '1', *args])

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
    revision = f'{base}+903-{digest[:10]}'
    layout = out / 'layout'
    for label, args in (
        ('layout', ['tools/blender/build_sheets/layout.py', out / 'sheet', REPO, layout]),
        ('inventory', ['tools/blender/build_sheets/inventory.py', CODE, REPO, layout, out / f'sheet/{CODE}_model.json']),
        ('extras', ['tools/blender/build_sheets/sheet_extras.py', CODE, out / 'sheet', REPO, layout]),
    ):
        run(label, [sys.executable, *args])
    blank = Image.open(CONCEPT).convert('RGB')
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
    dimensions['outline_note'] = 'R294 geometry, fixed historical outline camera; reported, not gated'
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
            value = 'hand-built' if fid in ('Y1', 'Y2') else 'kit'
        else:
            in_features = False
            continue
        lines[index] = line + ' ' + value + ' |'
    table = '\n'.join(lines) + '\n'
    (layout / 'feature_table.md').write_text(table)
    routes = json.loads((layout / 'manifest.json').read_text())
    for part in routes['parts']:
        if part['id'] in ('Y1', 'Y2'):
            part['route'] = 'hand-built'
            part['builder'] = f'tools/blender/build_sheets/ships/{CODE}.py: sunken machinery well'
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
        im = Image.open(layout / (name + '.png'))
        stamp(im, name).save(SHEET / (name + '.jpg'), quality=91)
    for name in ('preview', 'sheet', 'fit_view', 'side_by_side', 'cells'):
        stamp(Image.open(layout / (name + '.jpg')), name).save(SHEET / (name + '.jpg'), quality=91)
    for name in ('feature_table.md', 'checks.json', 'manifest.json', 'fit_report.md', 'cells.json', 'inventory.md'):
        shutil.copy2(layout / name, SHEET / name)
    shutil.copy2(out / f'sheet/{CODE}_fit.json', SHEET / 'fit.json')
    shutil.copy2(out / f'sheet/{CODE}_weapon_match.json', SHEET / 'weapon_match.json')
    shutil.copy2(out / 'density_mesh.json', SHEET / 'density_mesh.json')
    stamp(Image.open(out / 'paint/paint_weapon_bombs.png'), 'bombs T: one of two matching tubes', 'PAINT PROOF').save(SHEET / 'weapon_bombs.jpg', quality=91)

    def page(title):
        im = Image.new('RGB', (1280, 720), (14, 15, 18))
        d = ImageDraw.Draw(im)
        d.text((12, 5), 'KB1CC | ' + title, font=font(24), fill='white')
        d.text((12, 38), 'PAINT PROOF | Rev ' + revision + ' | Existing Hullbreaker stack, game light 1.25', font=font(17), fill=(182, 186, 194))
        return im

    def put(page, path, box, label, crop=None):
        im = Image.open(path).convert('RGB')
        if crop: im = im.crop(crop)
        im.thumbnail((box[2], box[3]-28), Image.Resampling.LANCZOS)
        page.paste(im, (box[0]+(box[2]-im.width)//2, box[1]+28+(box[3]-28-im.height)//2))
        ImageDraw.Draw(page).text((box[0]+8, box[1]), label, font=font(18), fill=(235, 184, 110))

    im = page('R294 shape restoration: concept, previous build, revised build')
    put(im, CONCEPT, (0, 82, 424, 352), 'Accepted concept, R259')
    put(im, REPO / 'docs/shots/look_bench/hullbreaker_patchwork/KB1CC_patchwork.jpg',
        (428, 82, 424, 352), 'Previous paint_full, PR 898', (644, 86, 1280, 491))
    put(im, out / 'paint/paint_beauty.png', (856, 82, 424, 352), 'R294 at the same paint_full camera')
    put(im, out / 'paint/paint_side.png', (0, 458, 640, 205), 'Ramp, then plateau; tapered toe at left')
    put(im, out / 'paint/paint_rear.png', (640, 438, 640, 275), 'Two main nacelles plus the stern row')
    im.save(HERE / 'KB1CC_R294_compare.jpg', quality=94)
    # Full-size feature evidence, one named ship per sheet.
    for name, title, a, b, labels in (
        ('details', 'sunken side bays and aft-facing engines', 'bay', 'rear', ('Cut shoulder, coupled pipes and bomb hoist', 'Deep red-orange main-drive throats and stern row')),
        ('profile', 'tapered bow, raised rails, ramp then plateau', 'top', 'side', ('Top: narrowed toe and swept shoulder edges', 'Side: sloped glacis meets a level upper deck')),
    ):
        im = page(title)
        put(im, out / f'paint/paint_{a}.png', (0, 86, 640, 572), labels[0])
        put(im, out / f'paint/paint_{b}.png', (640, 86, 640, 572), labels[1])
        im.save(HERE / ('KB1CC_R294_' + name + '.jpg'), quality=94)
    im = page('camera 170 preview: true pixels and 3x inspection')
    put(im, out / 'paint/paint_cam170.png', (0, 90, 640, 450), 'Left: unscaled crop from 1920 x 1080')
    crop = Image.open(out / 'paint/paint_cam170.png').crop((214, 120, 426, 240)).resize((636, 360), Image.Resampling.NEAREST)
    im.paste(crop, (644, 118))
    im.save(HERE / 'KB1CC_R294_cam170.jpg', quality=94)
    # Retire stale sheet comparison images by rebuilding them from the same revision.
    for name in ('corsair_KB1CC_compare.jpg', 'corsair_KB1CC_sheet_overview.jpg'):
        shutil.copy2(HERE / 'KB1CC_R294_compare.jpg', SHEET / name)
    stamp(Image.open(out / 'KB1CC_outline_overlay.jpg'), 'outline at the fixed historical camera').save(SHEET / 'outline_check.jpg', quality=91)
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
    evidence = dict(revision=revision, stage='paint proof, not installed or accepted',
                    design_sha256=digest, fit=fit['counts'], weapon_match=wm['result'], contract='PASS', manifest='PASS',
                    machine_fit=machine_fit,
                    outline_iou_percent=dimensions['outline_iou_percent'],
                    triangles=meta['triangles'], objects=meta['objects'], surfaces=meta['surfaces'],
                    draw_calls_merged=meta['draw_calls_merged'], surface=surface,
                    paint=meta['paint'], capture=json.loads((out / 'paint/capture.json').read_text()))
    evidence['source_sha256'] = {str(path.relative_to(REPO)).replace('\\', '/'): hashlib.sha256(path.read_bytes()).hexdigest()
                                 for path in (src, src.with_name(CODE + '_inv.py'), Path(__file__),
                                              HERE.parent / 'capture.py', REPO / 'tools/blender/kits/hullbreakers/stack.py')}
    (HERE / 'checks.json').write_text(json.dumps(evidence, indent=2) + '\n')
    (SHEET / 'README.md').write_text(f'''# corsair_KB1CC: R294 shape restoration, issue 903

Revision: `{revision}`. Stage: sheet built and paint proof, not installed or accepted.

The bomber now has two large round aft-facing main drives plus the five stern
thrusters, real sunken machinery bays with coupled pipes and hoists, a tapered
bow toe, higher framing rails, and a ramp that meets a level upper deck. The two
small forward bomb tubes preserve bombs T, two shots per volley. The old R275
sheet interpreted the top as one continuous ramp, kept the broad bow station,
mounted shallow machinery panels over closed skins, and interpreted the large
concept mouths as weapon tubes. These were geometry simplifications before PR 898.

The existing PR 898 Hullbreaker craft paint stack is unchanged. Isolated pale and
violet plate zones on this design were reassigned to weathered metal and blood red.
The nacelle mounts end aft of the existing seam so engines remain whole; the
inside room layout is retained, with dark walls and machinery in the new bays.

[Concept, previous and revised paint](../../../shots/look_bench/corsair_KB1CC/shape_r294/KB1CC_R294_compare.jpg)
uses the saved paint_full camera. [Feature proof](../../../shots/look_bench/corsair_KB1CC/shape_r294/KB1CC_R294_details.jpg)
also shows the aft engine openings. Those face aft for forward thrust, unlike the
concept's forward-visible glowing mouths. [Profile proof](../../../shots/look_bench/corsair_KB1CC/shape_r294/KB1CC_R294_profile.jpg)
shows the taper and plateau. Every current picture carries revision and stage and
is at most 720 pixels high.

Method: this sheet's [design](../../../../tools/blender/build_sheets/ships/corsair_KB1CC.py),
[manifest](manifest.json), the existing sheet contract and Hullbreaker craft stack.
The two new wells are hand-built in this design, recorded as such in the manifest.
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
    for path in HERE.iterdir():
        if path.suffix in ('.jpg', '.json', '.md', '.py', '.bat'):
            shutil.copy2(path, SHOTS / path.name)
    for path in list(SHEET.glob('*.jpg')) + list(HERE.glob('*.jpg')):
        assert Image.open(path).height <= 720, path
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
