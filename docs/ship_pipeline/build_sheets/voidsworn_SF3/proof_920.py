"""Issue 920 evidence, CPU only. Run from the repo root.

Blender: blender -b BEFORE_OR_AFTER.blend -P THIS_FILE -- battle OUT.png
Blender: blender -b -P THIS_FILE -- measure BEFORE.blend AFTER.blend OUT.json
Python:  python THIS_FILE publish TEMP_ROOT SHEET_DIR
Python:  python THIS_FILE sheet TEMP_ROOT

TEMP_ROOT contains build.py render directories before/ and after-final/, and
before_battle.png / after_battle.png from the battle command. Rebuild before/
with the unmodified main design before editing it; never stamp an old image
as a new render. All review pictures are 1280 x 720 with source sidecars.
"""
import json
import math
import sys
from pathlib import Path

sys.dont_write_bytecode = True
REPO = next(p for p in Path(__file__).resolve().parents if (p / 'tools/picture_provenance.py').is_file())
sys.path.insert(0, str(REPO / 'tools'))
from picture_provenance import Review, stamp_file, verify

CODE = 'voidsworn_SF3'
CONCEPT = REPO / 'contrib/muse/design/squadron_concepts_2026_11/sunward/round_2/SF3.jpg'
args = sys.argv[sys.argv.index('--') + 1:] if '--' in sys.argv else sys.argv[1:]


def measure(paths, output):
    import bpy
    import hashlib
    rows = []
    for path in paths:
        bpy.ops.wm.open_mainfile(filepath=str(path))
        dg = bpy.context.evaluated_depsgraph_get()
        row = dict(triangles_outside=0, triangles_inside=0, materials_outside=set(), objects={}, radiator_z=[], hull_roof_z=-1e9)
        for ob in bpy.context.scene.objects:
            if ob.type != 'MESH':
                continue
            e = ob.evaluated_get(dg); mesh = e.to_mesh(); mesh.calc_loop_triangles()
            inside = bool(ob.get('inside')) or ob.get('role') == 'interior'
            row['triangles_inside' if inside else 'triangles_outside'] += len(mesh.loop_triangles)
            if not inside:
                row['materials_outside'].update(m.name for m in mesh.materials if m)
            vertices = [tuple(ob.matrix_world @ v.co) for v in mesh.vertices]
            if ob.get('grp') == 'hull' and not inside:
                row['hull_roof_z'] = max(row['hull_roof_z'], max(v[2] for v in vertices))
            if ob.name == CODE + '_hull':
                row['bare_hull_roof_z'] = max(v[2] for v in vertices)
            if ob.get('grp') == 'R1':
                row['radiator_z'].extend(v[2] for v in vertices)
            else:
                payload = dict(vertices=vertices, faces=[tuple(p.vertices) for p in mesh.polygons],
                               materials=[m.name for m in mesh.materials if m])
                row['objects'][ob.name] = hashlib.sha256(json.dumps(payload, sort_keys=True).encode()).hexdigest()
            e.to_mesh_clear()
        row['materials_outside'] = sorted(row['materials_outside'])
        row['surfaces_outside'] = row['draw_calls_joined_by_material'] = len(row['materials_outside'])
        row['radiator_z'] = [min(row['radiator_z']), max(row['radiator_z'])]
        row['radiator_total_height'] = row['radiator_z'][1] - row['radiator_z'][0]
        rows.append(row)
    names = set(rows[0]['objects']) | set(rows[1]['objects'])
    changes = sorted(n for n in names if rows[0]['objects'].get(n) != rows[1]['objects'].get(n))
    result = dict(before=rows[0], after=rows[1], changed_objects_outside_R1=changes,
                  unchanged_objects_outside_R1=len(names) - len(changes),
                  fin_below_hull_roof=rows[1]['radiator_z'][1] < rows[1]['bare_hull_roof_z'],
                  fin_height_above_roof=rows[1]['radiator_z'][1] - rows[1]['bare_hull_roof_z'],
                  old_tower_height_above_roof=rows[0]['radiator_z'][1] - rows[0]['bare_hull_roof_z'],
                  height_reduction_percent=100 * (1 - rows[1]['radiator_total_height'] / rows[0]['radiator_total_height']))
    result['exposed_height_reduction_percent'] = 100 * (1 - result['fin_height_above_roof'] / result['old_tower_height_above_roof'])
    Path(output).write_text(json.dumps(result, indent=2) + '\n', encoding='utf-8')
    print(json.dumps({k: v for k, v in result.items() if k not in ('before', 'after')}))
    if changes:
        raise RuntimeError('Geometry changed outside R1: ' + ', '.join(changes))
    if not 0 < result['fin_height_above_roof'] < result['old_tower_height_above_roof'] / 3:
        raise RuntimeError('R1 must be visibly raised and under a third of the old tower height')


def battle(output):
    import bpy
    from mathutils import Matrix, Vector
    sc = bpy.context.scene
    coll = bpy.data.collections[CODE]
    for collection in (coll, bpy.data.collections[CODE + '_inside']):
        sc.view_layers[0].layer_collection.children[collection.name].exclude = True
    # Same formation and scale as squadron_wing.gd and issue769/game_view.py.
    for i, offset in enumerate(((0, 0, 0), (-0.95, -0.95, 0.12), (-0.95, 1.02, -0.09), (-1.9, -1.9, 0.12))):
        ob = bpy.data.objects.new('SF3_proof_%d' % i, None)
        ob.instance_type = 'COLLECTION'; ob.instance_collection = coll
        sc.collection.objects.link(ob)
        ob.matrix_world = Matrix.Translation(Vector(offset) * 3.84) @ Matrix.Scale(2.4, 4)
    for name, direction, energy in (('key', (0.45, -0.55, 0.70), 4), ('fill', (-0.45, 0.55, 0.3), 0.8)):
        ob = bpy.data.objects[name]; ob.data.energy = energy
        ob.rotation_euler = Vector(direction).normalized().to_track_quat('Z', 'Y').to_euler()
    sc.world.node_tree.nodes['Background'].inputs[0].default_value = (0.012, 0.012, 0.016, 1)
    sc.world.node_tree.nodes['Background'].inputs[1].default_value = 1
    camera = bpy.data.cameras.new('proof_camera170'); camera.sensor_fit = 'VERTICAL'
    camera.lens = 50; camera.angle_y = math.radians(45); camera.clip_end = 2000
    ob = bpy.data.objects.new(camera.name, camera); sc.collection.objects.link(ob)
    elevation = math.pi / 2 - 0.98
    ob.location = (0, -170 * math.cos(elevation), 170 * math.sin(elevation))
    ob.rotation_euler = (-ob.location).to_track_quat('-Z', 'Y').to_euler(); sc.camera = ob
    sc.cycles.device = 'CPU'; sc.cycles.samples = 24; sc.cycles.use_denoising = False
    sc.render.resolution_x = 1920; sc.render.resolution_y = 1080
    sc.render.resolution_percentage = 100; sc.render.film_transparent = False
    sc.render.use_border = True; sc.render.use_crop_to_border = True
    sc.render.border_min_x = sc.render.border_min_y = 1 / 3
    sc.render.border_max_x = sc.render.border_max_y = 2 / 3
    sc.render.filepath = str(output); bpy.ops.render.render(write_still=True)
    # The loaded blend's renders identify its source, even if this script runs after an edit.
    from picture_provenance import save_picture
    from PIL import Image
    source = Path(bpy.data.filepath).parent / 'beauty_cam.png'
    save_picture(Image.open(output).copy(), output, 'sheet built', sources=[verify(source)])


def publish(root, output):
    from PIL import Image, ImageDraw, ImageFont
    root, output = Path(root), Path(output)
    output.mkdir(parents=True, exist_ok=True)
    rendered = {'before': root / 'before', 'after': root / 'after-final'}
    font = lambda n: ImageFont.truetype('C:/Windows/Fonts/arial.ttf', n)
    bg, ink, dim, accent = '#242426', '#f0e8da', '#c5c1b7', '#f0aa50'

    def canvas(title, note):
        im = Image.new('RGB', (1280, 720), bg); draw = ImageDraw.Draw(im)
        draw.text((18, 10), 'SF3 | ' + title, font=font(27), fill=ink)
        draw.text((18, 46), note, font=font(17), fill=dim)
        return im

    def paste(im, source, box, alpha=False, ortho=False):
        source = source.convert('RGBA')
        if alpha:
            source = source.crop(source.getchannel('A').getbbox())
        if ortho:
            # Every raw orthographic view uses 900 pixels per world unit.
            # One half scale on all three views preserves that shared scale.
            source = source.resize((round(source.width / 2), round(source.height / 2)), Image.Resampling.LANCZOS)
        else:
            source.thumbnail((box[2], box[3]), Image.Resampling.LANCZOS)
        im.paste(source, (box[0] + (box[2] - source.width) // 2, box[1] + (box[3] - source.height) // 2), source)

    # Each revision gets a full-size picture at the same locked concept camera.
    for state in ('before', 'after'):
        review = Review('sheet built')
        im = canvas(('Main before R302' if state == 'before' else 'R302 run 2: visible low swept radiator'),
                    'Sheet built, unpainted | original concept camera, lens and framing unchanged')
        paste(im, review.open(rendered[state] / 'beauty_cam.png'), (40, 72, 1200, 500))
        review.save(im, output / ('SF3_R302_%s_concept.jpg' % state), quality=93)

    review = Review('sheet built')
    # The accepted concept is a reference from main, not a newly generated picture.
    review.open(root / 'before/beauty_cam.png')
    im = canvas('Accepted concept (R255)', 'Concept reference at the baseline main revision | source below')
    paste(im, review.open(CONCEPT, reference=True), (30, 76, 1220, 490))
    ImageDraw.Draw(im).text((18, 574), str(CONCEPT.relative_to(REPO)).replace('\\', '/'), font=font(17), fill=dim)
    review.save(im, output / 'SF3_R302_concept.jpg', quality=93)

    review = Review('sheet built')
    im = canvas('Concept / main before / R302 after', 'Same concept camera | sheet built, unpainted | only radiator R1 changes')
    for i, (label, path) in enumerate((('Accepted concept', CONCEPT), ('Main before', root / 'before/beauty_cam.png'),
                                       ('R302 after', rendered['after'] / 'beauty_cam.png'))):
        ImageDraw.Draw(im).text((i * 426 + 15, 88), label, font=font(22), fill=accent)
        paste(im, review.open(path, reference=(i == 0)), (i * 426 + 5, 122, 416, 350))
    ImageDraw.Draw(im).text((18, 510), 'Small raised swept fin with orange side slats. No tower or zigzag; the reactor socket stays put.', font=font(21), fill=ink)
    review.save(im, output / 'voidsworn_SF3_compare_SF3.jpg', quality=93)

    review = Review('sheet built')
    im = canvas('Side profile before and after | run 2', 'Same scale and aligned bow | only radiator R1 changes')
    for state, y in (('before', 90), ('after', 365)):
        ImageDraw.Draw(im).text((20, y), state.upper(), font=font(21), fill=accent)
        source = review.open(rendered[state] / 'side.png').convert('RGBA')
        source = source.crop(source.getchannel('A').getbbox())
        source = source.resize((1100, round(source.height * 1100 / source.width)), Image.Resampling.LANCZOS)
        im.paste(source, (100, y), source)
    review.save(im, output / 'SF3_R302_side.jpg', quality=93)

    review = Review('sheet built')
    im = canvas('Camera 170 before and after', 'FOV 45, radius 170, elevation 33.85 deg | wing of four at 3.84 board units per craft')
    for state, x in (('before', 0), ('after', 640)):
        raw = review.open(root / (state + '_battle.png')).convert('RGB')
        im.paste(raw, (x, 90))
        draw = ImageDraw.Draw(im); draw.text((x + 18, 70), state.upper() + ' | native 1080p pixels, 1:1', font=font(17), fill=accent)
        zoom = raw.crop((300, 170, 342, 186)).resize((336, 128), Image.Resampling.NEAREST)
        im.paste(zoom, (x + 152, 460))
        draw.text((x + 20, 448), 'Same centre craft crop x8 (nearest pixels)', font=font(17), fill=dim)
    review.save(im, output / 'SF3_R302_camera170.jpg', quality=95)

    review = Review('sheet built')
    im = canvas('R302 run 2 sheet overview | page 1 of 2', 'One rebuilt SF3 sheet | unpainted | CPU render | visible low dorsal radiator, no zigzag')
    for name, box in (('side', (15, 92, 810, 170)), ('top', (15, 280, 810, 170)),
                      ('cutaway', (15, 470, 810, 130)), ('threequarter', (850, 95, 415, 345))):
        source = review.open(rendered['after'] / (name + '.png'))
        if name == 'top':
            source = source.rotate(90, expand=True)
        paste(im, source, box, alpha=True, ortho=(name != 'threequarter'))
        ImageDraw.Draw(im).text((box[0], box[1] - 20), name.upper(), font=font(18), fill=accent)
    metrics = json.loads((root / 'geometry.json').read_text())
    ImageDraw.Draw(im).text((850, 460), 'Fin rise: %.4f above roof\n%.1f%% lower than old tower\nSame hull, guns, drives, insides\nLength 1.6; board length 3.84' % (metrics['fin_height_above_roof'], metrics['exposed_height_reduction_percent']), font=font(19), fill=ink, spacing=12)
    draw = ImageDraw.Draw(im)
    draw.line((30, 610, 255, 610), fill=ink, width=3)
    draw.text((270, 596), '0.5 world units | orthographic views at one scale', font=font(18), fill=ink)
    # The overview is the front page, not a thumbnail of the tall working sheet.
    sources = review.take_sources()
    review.save(im, output / 'sheet.jpg', sources=sources, quality=93)
    review.save(im, output / 'voidsworn_SF3_sheet_overview.jpg', sources=sources, quality=93)
    review.save(im, output / 'preview.jpg', sources=sources, quality=93)

    review = Review('sheet built')
    im = canvas('R302 run 2 sheet details | page 2 of 2', 'Enlarged true end views, underside and insides | full feature table and fit report beside these pages')
    for name, box in (('bow', (25, 105, 590, 200)), ('stern', (660, 105, 590, 200)),
                      ('underside', (25, 365, 785, 195))):
        source = review.open(rendered['after'] / (name + '.png'))
        if name == 'underside':
            source = source.rotate(90, expand=True)
        paste(im, source, box, alpha=True)
        ImageDraw.Draw(im).text((box[0], box[1] - 25), name.upper(), font=font(20), fill=accent)
    draw = ImageDraw.Draw(im)
    draw.text((850, 365), 'INSIDE: unchanged\nGun feed, pilot, reactor, drives\nOne break seam: B-1\nThree gun muzzles, two drives\nSeven material surfaces', font=font(19), fill=ink, spacing=13)
    review.save(im, output / 'sheet_02.jpg', quality=93)


def sheet(root):
    """Use the shared compositors with current measured scores, never change the fitted camera."""
    import shutil
    import subprocess
    from PIL import Image
    root = Path(root).resolve()
    rendered, layout, inputs = root / 'after-final', root / 'layout', root / 'sheet-inputs'
    ships = inputs / 'tools/blender/build_sheets/ships'
    ships.mkdir(parents=True, exist_ok=True)
    source_ships = REPO / 'tools/blender/build_sheets/ships'
    shutil.copyfile(source_ships / (CODE + '.py'), ships / (CODE + '.py'))
    kit_input = inputs / 'tools/blender/kits/voidsworn/parts.py'
    kit_input.parent.mkdir(parents=True, exist_ok=True)
    shutil.copyfile(REPO / 'tools/blender/kits/voidsworn/parts.py', kit_input)
    # fit.py scored the new mesh using the original camera, with no --fit.
    shutil.copyfile(root / 'outline_camera.json', ships / (CODE + '_camera.json'))
    concept = inputs / CONCEPT.relative_to(REPO)
    concept.parent.mkdir(parents=True, exist_ok=True); shutil.copyfile(CONCEPT, concept)
    model = json.loads((rendered / (CODE + '_model.json')).read_text())
    radiator = next(f for f in model['features'] if f['id'] == 'R1')
    inventory = (source_ships / (CODE + '_inv.py')).read_text()
    inventory = inventory.replace('one short radiator spire on the stern block, square-topped, four ember fins a side', radiator['what'])
    inventory = inventory.replace('a forged root socket with an ember glow at its foot, a column (iron posts round a dark core), the ember fins, a forged cap, gusset braces',
                                  'a forged root socket, one swept ember panel per side, dark channels, a thin cap and root braces (R302)')
    (ships / (CODE + '_inv.py')).write_text(inventory, encoding='utf-8')
    scripts = REPO / 'tools/blender/build_sheets'
    for script, arguments in (
        ('inventory.py', [CODE, inputs, layout, rendered / (CODE + '_model.json')]),
        ('layout.py', [rendered, inputs, layout]),
        ('sheet_extras.py', [CODE, rendered, inputs, layout, root / 'before' / (CODE + '_fit.json')]),
        ('publish.py', [CODE, rendered, layout, root / 'outline_overlay.jpg', REPO]),
    ):
        subprocess.run([sys.executable, str(scripts / script), *map(str, arguments)], check=True)
    output = Path(__file__).resolve().parent
    # The shared sheet's older table assumes all fittings are kit parts. R1 is now bespoke.
    manifest = json.loads((output / 'manifest.json').read_text())
    routes = {p['id']: p['route'] for p in manifest['parts']}
    table = output / 'feature_table.md'
    lines = []
    for line in table.read_text().splitlines():
        if line.startswith('| ID | Fitting |'):
            line += ' Route |'
        elif line.startswith('|---|---|---:|---:|---:|---:|---|---|---|---|'):
            line += '---|'
        elif line.startswith('| ') and line.split('|')[1].strip() in routes:
            line += ' ' + routes[line.split('|')[1].strip()] + ' |'
        lines.append(line)
    table.write_text('\n'.join(lines) + '\n', encoding='utf-8')
    inventory_path = output / 'inventory.md'
    inventory_text = inventory_path.read_text().replace(
        '`tools/blender/build_sheets/ships/voidsworn_SF3_inv.py`.',
        '`tools/blender/build_sheets/ships/voidsworn_SF3_inv.py`; R302 updates R1 from the current model written by `voidsworn_SF3.py`.')
    inventory_path.write_text(inventory_text, encoding='utf-8')
    for source, name in ((root / 'geometry.json', 'geometry_920.json'),
                         (root / 'contract/sheet_contract_selftest.json', 'contract_920.json'),
                         (rendered / (CODE + '_model.json'), 'model.json')):
        shutil.copyfile(source, output / name)
    # Shared layout pages are large working sheets. Deliver owner pictures at <=720 high.
    for path in output.iterdir():
        if path.suffix.lower() not in ('.jpg', '.png') or not Path(str(path) + '.provenance.json').exists():
            continue
        with Image.open(path) as image:
            large = image.height > 720 or image.width > 1280
        if large:
            review = Review('sheet built'); image = review.open(path)
            image.thumbnail((1280, 720), Image.Resampling.LANCZOS)
            review.save(image, path, quality=92)
    publish(root, output)


if args[0] == 'battle':
    battle(Path(args[1]))
elif args[0] == 'measure':
    measure(args[1:3], args[3])
elif args[0] == 'publish':
    publish(args[1], args[2])
elif args[0] == 'sheet':
    sheet(args[1])
elif args[0] == 'density':
    import runpy
    script = REPO / 'contrib/opus/tools/issue738/density_mesh.py'
    sys.argv = [str(script), args[1], args[2]]
    runpy.run_path(str(script), run_name='__main__')
else:
    raise SystemExit('Choose battle, measure, publish, sheet or density')
