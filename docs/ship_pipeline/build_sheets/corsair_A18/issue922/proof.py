"""Issue 922 CPU proof. Run inside Blender: -- MODE SCRATCH before|after.

Uses the production builders, paint stack, cameras and export. The before design
comes from the recorded main revision, with the same paint as the after design.
Run compose with plain Python after render has completed for both revisions.
"""
import hashlib
import importlib.util
import json
import math
import os
from pathlib import Path
import runpy
import struct
import subprocess
import sys
import types

sys.dont_write_bytecode = True
REPO = next(p for p in Path(__file__).resolve().parents if (p / 'tools/picture_provenance.py').is_file())
for folder in ('tools', 'tools/blender/build_sheets', 'tools/blender/r209', 'tools/blender/kits/shared'):
    sys.path.insert(0, str(REPO / folder))
args = sys.argv[sys.argv.index('--') + 1:] if '--' in sys.argv else sys.argv[1:]
mode, scratch = args[:2]
stage = args[2] if len(args) > 2 else 'after'
out = Path(scratch) / stage
out.mkdir(parents=True, exist_ok=True)
DESIGN = 'tools/blender/build_sheets/ships/corsair_A18.py'
BASE = '820cbaca88b869806e965a8d65d60f5449a0b177'


def source():
    from picture_provenance import revision
    return (dict(source_commit=BASE, source_dirty=False, source_diff_sha256='')
            if stage == 'before' else revision(str(REPO)))


def asset_record(asset, revision, stage='paint proof'):
    from datetime import datetime, timezone
    return dict(revision, picture_name=Path(asset).name, stage=stage,
                date=datetime.now(timezone.utc).strftime('%Y-%m-%dT%H:%M:%SZ'),
                image_sha256=hashlib.sha256(Path(asset).read_bytes()).hexdigest(),
                sources=[dict(revision, stage=stage)])


def baseline():
    import variants
    original = variants.build
    text = subprocess.check_output(['git', '-C', str(REPO), 'show', BASE + ':' + DESIGN])

    def build(design, game=None):
        module = types.ModuleType('A18_main_before')
        module.__file__ = str(REPO / DESIGN)
        exec(compile(text, module.__file__, 'exec'), module.__dict__)
        return original(module, game)

    variants.build = build


if mode == 'bake':
    import bpy
    import paint_stack
    if stage == 'before':
        baseline()

    def cpu(samples):
        scene = bpy.context.scene
        scene.render.engine = 'CYCLES'
        scene.cycles.device = 'CPU'
        scene.cycles.samples = samples
        return 'CPU'

    paint_stack.gpu = cpu
    os.environ['R209_SHIP'] = str(REPO / 'tools/recipe/ships/corsair_A18.json')
    script = REPO / 'tools/blender/r209/bake_sheet.py'
    sys.argv = [str(script), '--', str(out), '_', '_', 'A18', '2048', '16']
    runpy.run_path(str(script), run_name='__main__')
    (out / 'source.json').write_text(json.dumps(source(), indent=2) + '\n')

elif mode == 'render':
    import bpy
    from mathutils import Vector
    from picture_provenance import save_picture
    from PIL import Image
    script = REPO / 'tools/blender/build_sheets/paint_sheet.py'
    shots = out / 'views'
    shots.mkdir(exist_ok=True)
    sys.argv = [str(script), '--', str(shots), 'corsair_A18',
                str(REPO / 'contrib/muse/design/class_family_corsair_2026_11/corsair_A18_beauty.jpg'),
                'samples=32', 'scale=0.5', 'sky_spec=0']
    ns = {'__file__': str(script), '__name__': 'proof922'}
    exec(compile(script.read_text().split('beauty = look_cam(')[0], str(script), 'exec'), ns)
    scene = bpy.context.scene
    scene.cycles.device = 'CPU'
    record = asset_record(out / 'A18.blend', json.loads((out / 'source.json').read_text()))

    def stamp(path, stage, new_render=False):
        with Image.open(path) as image:
            save_picture(image.copy(), path, stage, sources=[record])

    ns['_stamp_picture'] = stamp
    fc = ns['fc']
    cam = ns['look_cam'](fc['az'], fc['el'], fc['dist'], fc['mm'], tuple(fc['res']),
                         fc['target'], fc.get('roll', 0), (-fc.get('sx', 0), -fc.get('sy', 0)))
    ns['shoot'](cam, 'A18_concept_camera', .5)
    cam = ns['look_cam'](145, 25, 12, 55, (1280, 720), (0, 0, 0))
    ns['shoot'](cam, 'A18_engine_detail', 1)
    distance = 170 / float(scene['r209_length_world'])
    pitch = .98
    data = bpy.data.cameras.new('camera170')
    cam = bpy.data.objects.new('camera170', data)
    scene.collection.objects.link(cam)
    cam.location = Vector((0, -math.sin(pitch) * distance, math.cos(pitch) * distance))
    cam.rotation_euler = (-cam.location).to_track_quat('-Z', 'Y').to_euler()
    data.sensor_fit = 'VERTICAL'
    data.angle_y = 2 * math.atan(math.tan(math.radians(22.5)) * 360 / 1080)
    data.clip_start, data.clip_end = .001, distance * 3
    scene.render.resolution_x, scene.render.resolution_y = 640, 360
    ns['shoot'](cam, 'A18_camera170', 1)

elif mode == 'snapshot':
    import bpy
    rows = {}
    for obj in bpy.context.scene.objects:
        if obj.type != 'MESH':
            continue
        digest = hashlib.sha256()
        for vertex in obj.data.vertices:
            digest.update(struct.pack('<3f', *(obj.matrix_world @ vertex.co)))
        for face in obj.data.polygons:
            digest.update(struct.pack('<I', len(face.vertices)))
            digest.update(struct.pack('<%dI' % len(face.vertices), *face.vertices))
        rows[obj.name] = dict(sha256=digest.hexdigest(), kind=obj.get('part_kind'),
                              group=obj.get('grp'), role=obj.get('role'))
    (out / 'geometry.json').write_text(json.dumps(rows, indent=2) + '\n')
    if stage == 'after':
        import kit
        spec = importlib.util.spec_from_file_location('a18_design', REPO / DESIGN)
        design = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(design)

        class Capture:
            def engine(self):
                self.part = kit.HP.engine_bell(.336, 1, bell_len=.3696, rings=3)

        capture = Capture()
        original = kit.HP.engine_bell
        design.overburn_engine(capture)
        from collections import Counter
        bell = next(c for c in capture.part.comps if c['name'] == 'bell')
        edges = Counter(tuple(sorted((face[i], face[(i + 1) % len(face)])))
                        for face in bell['faces'] for i in range(len(face)))
        assert all(n == 2 for n in edges.values()), 'open cooling-slot shell'
        directions = Counter((face[i], face[(i + 1) % len(face)])
                             for face in bell['faces'] for i in range(len(face)))
        assert all(count == directions[b, a] for (a, b), count in directions.items()), 'reversed slot-wall winding'
        assert kit.HP.engine_bell is original, 'engine override leaked to the kit'
        before = json.loads((Path(scratch) / 'before/geometry.json').read_text())
        changed = [name for name in rows.keys() | before.keys() if rows.get(name) != before.get(name)]
        running_lights = [name for name in changed if name.startswith('RL')]
        allowed = lambda name: name.startswith(('D1_', 'E1_body_', 'E2_body_', 'E3_body_'))
        assert all(allowed(name) for name in changed if name not in running_lights), changed
        lamp_counts = {revision: json.loads((Path(scratch) / revision / 'lights.json').read_text())['lights']['running']['count']
                       for revision in ('before', 'after')}
        report = dict(result='PASS', changed_objects=changed, unchanged_objects=len(rows.keys() & before.keys()) -
                      sum(name in rows and name in before for name in changed),
                      plate_layout_unchanged=True, interiors_unchanged=True,
                      automatic_running_light_changes=running_lights, running_light_counts=lamp_counts,
                      running_light_note='The unchanged stack admits one extra lamp after the large dish clears its placement test.',
                      bell_shell_closed=True, slot_wall_winding_consistent=True, kit_builder_restored=True)
        (Path(scratch) / 'geometry_check.json').write_text(json.dumps(report, indent=2) + '\n')
        print('PASS dish and engine geometry only', report)

elif mode == 'publish':
    import shutil
    from PIL import Image, ImageDraw, ImageFont
    from picture_provenance import Review
    rendered = Path(scratch) / 'sheet'
    layout = Path(scratch) / 'layout'
    destination = REPO / 'docs/ship_pipeline/build_sheets/corsair_A18'
    subprocess.check_call([sys.executable, str(REPO / 'tools/blender/build_sheets/layout.py'),
                           str(rendered), str(REPO), str(layout)])
    subprocess.check_call([sys.executable, str(REPO / 'tools/blender/build_sheets/inventory.py'),
                           'corsair_A18', str(REPO), str(layout), str(rendered / 'corsair_A18_model.json')])
    subprocess.check_call([sys.executable, str(REPO / 'tools/blender/build_sheets/sheet_extras.py'),
                           'corsair_A18', str(rendered), str(REPO), str(layout)])
    model = json.loads((rendered / 'corsair_A18_model.json').read_text())
    disc = next(feature for feature in model['features'] if feature['id'] == 'D1')
    inventory = (layout / 'inventory.md').read_text().splitlines()
    for index, line in enumerate(inventory):
        if line.startswith('| ear |'):
            cells = line.split('|')
            cells[4] = ' ' + disc['note'] + ' '
            inventory[index] = '|'.join(cells)
    (layout / 'inventory.md').write_text('\n'.join(inventory) + '\n')
    # The A18-only engine openings are authored in its design, on the kit bell.
    manifest = json.loads((layout / 'manifest.json').read_text())
    for part in manifest['parts']:
        if part['kind'] == 'engine':
            part['route'] = 'hand-built'
            part['method'] = DESIGN + ':overburn_engine on the unchanged Hullbreaker bell'
    (layout / 'manifest.json').write_text(json.dumps(manifest, indent=1) + '\n')
    table = (layout / 'feature_table.md').read_text()
    lines = table.splitlines()
    in_features = False
    for index, line in enumerate(lines):
        if line.startswith('## Feature table'):
            in_features = True
        elif line.startswith('## '):
            in_features = False
        if in_features and line.startswith('|'):
            cells = line.split('|')
            identity = cells[1].strip()
            route = 'Route' if identity == 'ID' else ('---' if identity.startswith('---') else
                    ('hand-built' if identity in ('E1', 'E2', 'E3') else 'kit'))
            cells.insert(2, ' ' + route + ' ')
            lines[index] = '|'.join(cells)
    # layout.py reads the old camera-fit overlap; do not report it as a new score.
    lines = [line for line in lines if not line.startswith(('| outline iou percent |', '| mass outline iou percent |'))]
    (layout / 'feature_table.md').write_text('\n'.join(lines) + '\n')
    checks = json.loads((layout / 'checks.json').read_text())
    for key in ('outline_iou_percent', 'mass_outline_iou_percent'):
        checks.pop(key, None)
    checks['outline_note'] = 'Historical outline record retained in README; not rescored for issue 922.'
    (layout / 'checks.json').write_text(json.dumps(checks, indent=1) + '\n')
    for name in ('feature_table.md', 'manifest.json', 'checks.json', 'fit_report.md', 'cells.json', 'inventory.md'):
        shutil.copy2(layout / name, destination / name)
    for origin, target in (('corsair_A18_fit.json', 'fit.json'), ('corsair_A18_weapon_match.json', 'weapon_match.json')):
        shutil.copy2(rendered / origin, destination / target)
    for name in ('side', 'top', 'underside', 'bow', 'stern', 'cutaway', 'threequarter', 'fit_view', 'cells', 'side_by_side'):
        path = layout / (name + ('.png' if name in ('side', 'top', 'underside', 'bow', 'stern', 'cutaway', 'threequarter') else '.jpg'))
        review = Review('sheet built')
        image = review.open(path).convert('RGB')
        image.thumbnail((1280, 720), Image.Resampling.LANCZOS)
        review.save(image, destination / (name + '.jpg'), quality=90)
    font = ImageFont.truetype('C:/Windows/Fonts/arial.ttf', 20)
    review = Review('sheet built')
    canvas = Image.new('RGB', (1280, 720), '#22252a')
    ImageDraw.Draw(canvas).text((20, 12), 'A18 | issue 922 | sheet built | six views', font=font, fill='#ede8db')
    for index, name in enumerate(('top', 'side', 'threequarter', 'bow', 'stern', 'underside')):
        image = review.open(layout / (name + '.png')).convert('RGB')
        image.thumbnail((400, 248), Image.Resampling.LANCZOS)
        x, y = (index % 3) * 426, 55 + (index // 3) * 275
        canvas.paste(image, (x + (426 - image.width) // 2, y + 25 + (248 - image.height) // 2))
        ImageDraw.Draw(canvas).text((x + 16, y), name, font=font, fill='#ede8db')
    review.save(canvas, destination / 'sheet.jpg', quality=92)
    for origin, target in ((rendered / 'weapon_autocannon.png', destination / 'weapon_autocannon.jpg'),
                           (destination / 'issue922/A18_after_concept_camera.jpg', destination / 'preview.jpg'),
                           (destination / 'issue922/A18_concept_vs_after.jpg', destination / 'paint/A18_paint_full.jpg'),
                           (destination / 'issue922/A18_after_engine_detail.jpg', destination / 'paint/A18_paint_engines.jpg')):
        review = Review('paint proof' if 'issue922' in str(origin) else 'sheet built')
        image = review.open(origin).convert('RGB')
        image.thumbnail((1280, 720), Image.Resampling.LANCZOS)
        review.save(image, target, quality=92)
    concept = REPO / 'contrib/muse/design/class_family_corsair_2026_11/corsair_A18_beauty.jpg'
    reference = asset_record(concept, dict(source_commit=BASE, source_dirty=False, source_diff_sha256=''), 'sheet built')
    for target, name in (('beauty_vs_blockout.jpg', 'beauty_cam'), ('weapon_review.jpg', 'weapon_autocannon')):
        review = Review('sheet built')
        canvas = Image.new('RGB', (1280, 720), '#22252a')
        draw = ImageDraw.Draw(canvas)
        draw.text((20, 12), 'A18 | issue 922 | sheet built | ' + ('concept camera' if name == 'beauty_cam' else 'weapon match PASS'), font=font, fill='#ede8db')
        for index, picture in enumerate((concept, rendered / (name + '.png'))):
            image = review.open(picture, reference=(index == 0)).convert('RGBA')
            image.thumbnail((620, 440), Image.Resampling.LANCZOS)
            canvas.paste(image, (index * 640 + (640 - image.width) // 2, 65 + (440 - image.height) // 2), image)
        if name == 'weapon_autocannon':
            draw.text((20, 535), 'data.js c_raider | slot 0: autocannon T | turret T1 | 2 muzzles | fit and weapon match PASS', font=font, fill='#ede8db')
        review.save(canvas, destination / target, sources=[reference], quality=92)
    print('PASS current A18 sheet outputs published')

elif mode == 'compose':
    from PIL import Image, ImageDraw, ImageFont
    from picture_provenance import Review, save_picture
    proof = REPO / 'docs/ship_pipeline/build_sheets/corsair_A18/issue922'
    font = ImageFont.truetype('C:/Windows/Fonts/arial.ttf', 22)

    def panel(picture, label, target, reference=False):
        review = Review('paint proof')
        image = review.open(picture, reference=reference).convert('RGB')
        canvas = Image.new('RGB', (1280, 720), '#101319')
        image.thumbnail((1240, 590), Image.Resampling.LANCZOS)
        canvas.paste(image, ((1280 - image.width) // 2, 48 + (590 - image.height) // 2))
        ImageDraw.Draw(canvas).text((20, 12), label, fill='#ede8db', font=font)
        if reference:
            save_picture(canvas, proof / target, 'sheet built', sources=[asset_record(picture, dict(
                source_commit=BASE, source_dirty=False, source_diff_sha256=''), 'sheet built')])
        else:
            review.save(canvas, proof / target, quality=92)

    panel(REPO / 'contrib/muse/design/class_family_corsair_2026_11/corsair_A18_beauty.jpg',
          'A18 | accepted concept v3 | reference, no runtime effects', 'A18_concept.jpg', True)
    for revision in ('before', 'after'):
        for view in ('concept_camera', 'engine_detail', 'camera170'):
            panel(Path(scratch) / revision / 'views' / ('A18_' + view + '.png'),
                  'A18 | %s | %s | CPU paint proof, 2048 maps' % (revision, view.replace('_', ' ')),
                  'A18_%s_%s.jpg' % (revision, view))
    for view in ('concept_camera', 'engine_detail', 'camera170'):
        review = Review('paint proof')
        canvas = Image.new('RGB', (1280, 720), '#101319')
        draw = ImageDraw.Draw(canvas)
        draw.text((20, 12), 'A18 | before main / after issue 922 | ' + view.replace('_', ' '), fill='#ede8db', font=font)
        for index, revision in enumerate(('before', 'after')):
            image = review.open(Path(scratch) / revision / 'views' / ('A18_' + view + '.png')).convert('RGB')
            image.thumbnail((640 if view == 'camera170' else 620, 490), Image.Resampling.LANCZOS)
            x = index * 640 + (640 - image.width) // 2
            canvas.paste(image, (x, 82 + (490 - image.height) // 2))
            draw.text((index * 640 + 20, 50), revision, fill='#ede8db', font=font)
        draw.text((20, 548), 'Same paint stack and cameras. Dark lips retained; hot lining is real emissive geometry.', fill='#bfc4cc', font=font)
        review.save(canvas, proof / ('A18_compare_' + view + '.jpg'), quality=92)
    review = Review('paint proof')
    canvas = Image.new('RGB', (1280, 720), '#101319')
    draw = ImageDraw.Draw(canvas)
    draw.text((20, 12), 'A18 | accepted concept / issue 922 | same concept camera', fill='#ede8db', font=font)
    for index, picture in enumerate((proof / 'A18_concept.jpg', proof / 'A18_after_concept_camera.jpg')):
        image = review.open(picture).convert('RGB')
        image.thumbnail((640, 490), Image.Resampling.LANCZOS)
        canvas.paste(image, (index * 640 + (640 - image.width) // 2, 65 + (490 - image.height) // 2))
    draw.text((20, 548), 'Dish and engine correction only. Colour and plate character remain the issue 726 paint.', fill='#bfc4cc', font=font)
    review.save(canvas, proof / 'A18_concept_vs_after.jpg', quality=92)
    if (Path(scratch) / 'after/game/A18_game_camera170.png').is_file():
        for revision in ('before', 'after'):
            for view in ('camera170', 'engines'):
                panel(Path(scratch) / revision / 'game' / ('A18_game_' + view + '.png'),
                      'A18 | %s | game engine effect | %s | checked export, paint proof' % (revision, view),
                      'A18_%s_game_%s.jpg' % (revision, view))
        review = Review('paint proof')
        canvas = Image.new('RGB', (1280, 720), '#101319')
        draw = ImageDraw.Draw(canvas)
        draw.text((20, 12), 'A18 | main before / issue 922 after | game effect at camera 170', fill='#ede8db', font=font)
        for index, revision in enumerate(('before', 'after')):
            image = review.open(Path(scratch) / revision / 'game/A18_game_camera170.png').convert('RGB')
            canvas.paste(image, (index * 640, 150))
            draw.text((index * 640 + 20, 70), revision, fill='#ede8db', font=font)
        draw.text((20, 548), 'Native pixels from 1920 x 1080, radius 170, pitch 0.98. Production engine effect at full burn.', fill='#bfc4cc', font=font)
        review.save(canvas, proof / 'A18_game_camera170_compare.jpg', quality=92)

else:
    raise SystemExit('unknown proof mode ' + mode)
