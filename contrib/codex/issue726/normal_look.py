"""Render the same painted A20 with the OSL control and the height fallback.

Opens an already painted blend via Blender -b. Writes only to TEMP.
Usage: -- REPO OUTPUT CONTROL_NORMAL HEIGHT_NORMAL
"""
import json
from pathlib import Path
import sys

import bpy
import numpy as np
from PIL import Image, ImageDraw, ImageFont, ImageOps

repo, output, control, candidate = map(Path, sys.argv[sys.argv.index('--') + 1:])
output.mkdir(parents=True, exist_ok=True)
script = repo / 'tools/blender/build_sheets/paint_sheet.py'
concept = repo / json.loads((repo / 'tools/recipe/ships/corsair_A20.json').read_text())['concept']
sys.argv = ['normal_look', '--', str(output), 'corsair_A20', str(concept),
            'lift=1.25', 'samples=64', 'scale=0.6', 'gpu=1', 'sky_spec=0']
namespace = {'__file__': str(script), '__name__': 'normal_look_setup'}
exec(compile(script.read_text().split("shots = {'beauty'")[0], str(script), 'exec'), namespace)
targets = [n.inputs['Color'].links[0].from_node for mat in bpy.data.materials if mat.use_nodes
           for n in mat.node_tree.nodes if n.type == 'NORMAL_MAP' and n.inputs['Color'].is_linked]
assert targets, 'No textured hull normal found'
paths = []
for name, source in [('osl_control', control), ('height_fallback', candidate)]:
    image = bpy.data.images.load(str(source), check_existing=False)
    image.colorspace_settings.name = 'Non-Color'
    for node in targets: node.image = image
    paths.append(namespace['shoot'](namespace['beauty'], name, .6))
left, right = [Image.open(path).convert('RGB') for path in paths]
delta = np.abs(np.asarray(left, dtype=np.float32) - np.asarray(right, dtype=np.float32))
report = dict(rms_8bit=float(np.sqrt(np.mean(delta ** 2))), max_8bit=float(delta.max()),
              mean_8bit=float(delta.mean()), pixels=list(left.size), samples=64)
(output / 'normal_look.json').write_text(json.dumps(report, indent=2))
canvas = Image.new('RGB', (1280, 720), (14, 15, 18))
draw = ImageDraw.Draw(canvas)
font = lambda size: ImageFont.truetype('C:/Windows/Fonts/arial.ttf', size)
draw.text((12, 10), 'A20 | normal-method comparison | 0e9c791d+normal726-run4', fill='white', font=font(22))
draw.text((12, 42), 'Stage 5 diagnostic: same painted mesh, camera, light and 64 samples; only the normal map changes', fill=(180, 185, 190), font=font(16))
for image, x, label in [(left, 0, 'CPU OSL control'), (right, 640, '16-bit patchwork height fallback')]:
    draw.text((x + 12, 82), label, fill='white', font=font(18))
    fitted = ImageOps.contain(image, (636, 588), Image.Resampling.LANCZOS)
    canvas.paste(fitted, (x + (640 - fitted.width) // 2, 116 + (588 - fitted.height) // 2))
canvas.save(output / 'A20_normal_routes.jpg', quality=95)
print('NORMAL LOOK', json.dumps(report), flush=True)
