"""CPU review picture of the actual exported GLBs. No paint or mesh changes.
blender -b -t 4 -P variant_preview.py -- BASE_GLB VARIANT_GLB OUT_DIR
python variant_preview.py --layout OUT_DIR
"""
import os
import sys
import json
import struct


def layout(out):
    from PIL import Image, ImageDraw, ImageFont
    im = Image.new('RGB', (1280, 720), (24, 25, 30))
    d = ImageDraw.Draw(im)
    font = ImageFont.truetype('C:/Windows/Fonts/arial.ttf', 26)
    small = ImageFont.truetype('C:/Windows/Fonts/arial.ttf', 20)
    meta = json.load(open(os.path.join(out, 'preview.json')))
    code = meta['code']
    d.text((24, 20), code + ' | Named-variant parts | Actual stage 7 GLBs', font=font, fill='#e8e0d4')
    for i, (key, title) in enumerate([('base', code + ' base | ' + meta['base']), ('variant', code + ' variant | ' + meta['variant'])]):
        im.paste(Image.open(os.path.join(out, key + '.png')).convert('RGB'), (640 * i, 100))
        d.text((24 + 640 * i, 76), title, font=small, fill='#c7b4db')
    descriptions = {'E14': ('One fixed null lance', 'Same lance plus a turning null spire'),
                    'E13': ('One roof null cannon | view from below', 'Same cannon plus a belly null spire'),
                    'E12': ('Two null cannons and a fixed corona arc', 'One null cannon and a turning corona arc')}
    for i, text in enumerate(descriptions[code]):
        d.text((24 + 640 * i, 628), text, font=small, fill='#e8e0d4')
    d.text((24, 682), 'Unpainted geometry proof | CPU render | Base E11 to E14 triangle coordinates unchanged', font=small, fill='#b6b6be')
    im.save(os.path.join(out, code + '_variant_review.jpg'), quality=92)


def render(base, variant, out):
    import math
    import bpy
    from mathutils import Vector
    os.makedirs(out, exist_ok=True)
    def extras(path):
        b = open(path, 'rb').read()
        return json.loads(b[20:20 + struct.unpack_from('<I', b, 12)[0]])['asset']['extras']
    meta = dict(code=extras(base)['ship'].split('_')[-1], base=extras(base)['game_ship'], variant=extras(variant)['game_ship'])
    json.dump(meta, open(os.path.join(out, 'preview.json'), 'w'), indent=1)
    for key, path in [('base', base), ('variant', variant)]:
        bpy.ops.wm.read_factory_settings(use_empty=True)
        bpy.ops.import_scene.gltf(filepath=os.path.abspath(path))
        sc = bpy.context.scene
        sc.world = bpy.data.worlds.new('world')
        sc.world.use_nodes = True
        sc.world.node_tree.nodes['Background'].inputs[0].default_value = (0.14, 0.15, 0.18, 1)
        sc.world.node_tree.nodes['Background'].inputs[1].default_value = 0.6
        up = -1 if meta['code'] == 'E13' else 1
        for name, loc, energy in [('key', (-1, -2, 3 * up), 3.0), ('fill', (1, 1, up), 1.2)]:
            light = bpy.data.lights.new(name, 'SUN')
            light.energy = energy
            light.angle = math.radians(20)
            ob = bpy.data.objects.new(name, light)
            sc.collection.objects.link(ob)
            ob.rotation_euler = Vector(loc).to_track_quat('Z', 'Y').to_euler()
        cam = bpy.data.objects.new('camera', bpy.data.cameras.new('camera'))
        sc.collection.objects.link(cam)
        target = Vector((0.0, 0, 0))
        cam.location = (-0.9, -1.8, -1.0 if meta['code'] == 'E13' else 1.0)
        cam.rotation_euler = (target - cam.location).to_track_quat('-Z', 'Y').to_euler()
        cam.data.type = 'ORTHO'
        cam.data.ortho_scale = 1.25
        sc.camera = cam
        sc.render.engine = 'CYCLES'
        sc.cycles.device = 'CPU'
        sc.cycles.samples = 24
        sc.cycles.use_denoising = True
        sc.render.resolution_x = 640
        sc.render.resolution_y = 500
        sc.render.resolution_percentage = 100
        sc.render.image_settings.file_format = 'PNG'
        sc.render.filepath = os.path.join(out, key + '.png')
        sc.view_settings.view_transform = 'AgX'
        bpy.ops.render.render(write_still=True)


if __name__ == '__main__':
    if '--layout' in sys.argv:
        layout(sys.argv[-1])
    else:
        render(*sys.argv[sys.argv.index('--') + 1:])
