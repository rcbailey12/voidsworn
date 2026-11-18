"""CPU renders of the actual proof GLBs, one labelled 1280x720 sheet per changed variant.

  blender -b -t 4 --python-exit-code 1 -P variant_review.py -- PROOF_DIR SHOTS_DIR

Run variant_selftest.py first. Images are geometry reviews of unbaked test exports.
"""
from pathlib import Path as _PicturePath
import sys
sys.dont_write_bytecode = True
sys.path.insert(0, str(next(p for p in _PicturePath(__file__).resolve().parents if (p / 'tools/picture_provenance.py').is_file()) / 'tools'))
from picture_provenance import Review, stamp_file
PICTURES = Review('sheet built')

import json
import math
import sys
from pathlib import Path

import bpy
from mathutils import Vector
from PIL import Image, ImageDraw, ImageFont


def bounds(objects):
    points = [o.matrix_world @ Vector(p) for o in objects if o.type == 'MESH' for p in o.bound_box]
    return [Vector([fn(p[i] for p in points) for i in range(3)]) for fn in (min, max)]


def load(path):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=str(path))
    bpy.context.view_layer.update()
    return list(bpy.context.scene.objects)


def render(path, destination, target, scale, below=False):
    load(path)
    scene = bpy.context.scene
    scene.render.engine = 'CYCLES'
    scene.cycles.device = 'CPU'
    scene.cycles.samples = 16
    scene.cycles.use_denoising = True
    scene.render.resolution_x, scene.render.resolution_y = 620, 550
    scene.render.resolution_percentage = 100
    scene.render.image_settings.file_format = 'PNG'
    scene.render.film_transparent = False
    scene.world = bpy.data.worlds.new('review_world')
    scene.world.use_nodes = True
    scene.world.node_tree.nodes['Background'].inputs[0].default_value = (0.12, 0.14, 0.17, 1)
    scene.world.node_tree.nodes['Background'].inputs[1].default_value = 0.4
    scene.view_settings.view_transform = 'AgX'
    for name, direction, power in [('key', (0.6, -0.7, 1), 3), ('fill', (-1, 0.5, -0.7), 1.5)]:
        data = bpy.data.lights.new(name, 'SUN'); data.energy = power; data.angle = math.radians(12)
        light = bpy.data.objects.new(name, data); scene.collection.objects.link(light)
        light.rotation_euler = (-Vector(direction)).to_track_quat('-Z', 'Y').to_euler()
    data = bpy.data.cameras.new('review_camera'); data.type = 'ORTHO'; data.ortho_scale = scale
    camera = bpy.data.objects.new('review_camera', data); scene.collection.objects.link(camera)
    direction = Vector((0.45, -1, -0.6 if below else 0.6)).normalized()
    camera.location = target + direction * 35
    camera.rotation_euler = (-direction).to_track_quat('-Z', 'Y').to_euler()
    scene.camera = camera
    scene.render.filepath = str(destination)
    bpy.ops.render.render(write_still=True); stamp_file(scene.render.filepath, 'sheet built', new_render=True)


def main():
    args = sys.argv[sys.argv.index('--') + 1:]
    proof, shots = map(Path, args)
    shots.mkdir(parents=True, exist_ok=True)
    report = json.loads((proof / 'variant_selftest.json').read_text())
    font_path = Path('C:/Windows/Fonts/segoeui.ttf')
    font = ImageFont.truetype(str(font_path), 22)
    small = ImageFont.truetype(str(font_path), 18)
    for code, game, change in [('deathless_E14', 'd_jackal_h', 'Added stern null spire; forward null lance retained'),
                               ('deathless_E13', 'd_scythe_s', 'Added belly null spire; dorsal null cannon retained'),
                               ('deathless_E12', 'd_harvester_t', 'Corona arc turns on fore saddle; aft cannon retained')]:
        base = Path(report['bases'][code]['glb'])
        variant = Path(report['variants'][game]['glb'])
        b0 = bounds(load(base)); b1 = bounds(load(variant))
        low = Vector([min(b0[0][i], b1[0][i]) for i in range(3)])
        high = Vector([max(b0[1][i], b1[1][i]) for i in range(3)])
        target = (low + high) / 2
        scale = max(high.x - low.x, high.y - low.y, high.z - low.z) * 1.28
        panels = []
        for label, path in [('base', base), ('variant', variant)]:
            image = proof / (code + '_' + label + '_review.png')
            render(path, image, target, scale, below=code.endswith('E13'))
            panels.append(PICTURES.open(image).convert('RGB'))
        sheet = Image.new('RGB', (1280, 720), (23, 27, 33))
        draw = ImageDraw.Draw(sheet)
        draw.text((20, 12), code.replace('deathless_', '') + ' / ' + game, font=font, fill='white')
        draw.text((20, 48), 'BASE / ' + base.stem, font=small, fill='#b6c0cb')
        draw.text((660, 48), 'VARIANT / ' + game, font=small, fill='#f4c374')
        for i, panel in enumerate(panels):
            sheet.paste(panel, (10 + i * 640, 78))
        draw.text((20, 641), change, font=font, fill='white')
        draw.text((20, 683), 'Actual exported GLBs / same scale and camera / unbaked geometry proof / CPU render', font=small, fill='#b6c0cb')
        PICTURES.save(sheet, shots / (code + '_variant.png'))
        print('WROTE', shots / (code + '_variant.png'), flush=True)


if __name__ == '__main__':
    main()
