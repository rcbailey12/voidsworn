"""Test route B on the saved A20 graph; compare to the CPU OSL control."""
import json
from pathlib import Path
import sys

import bpy
import numpy as np

repo, output, reference = map(Path, sys.argv[sys.argv.index('--') + 1:])
sys.path.insert(0, str(repo / 'tools/blender/kits/shared'))
import paint_stack as ps

output.mkdir(parents=True, exist_ok=True)
obj = bpy.data.objects['A20_H_bake']
image = obj.material_slots[0].material.node_tree.nodes.active.image
image.scale(4096, 4096)
# Run 3's saved graph predates the new label. Find its existing seam-depth
# multiply, not a new height term. Current recipe builds write the label.
for material in {slot.material for slot in obj.material_slots}:
    material['ps_height_bake'] = True
    for node in material.node_tree.nodes:
        if node.type != 'MATH' or node.operation != 'SUBTRACT' or not node.inputs[1].is_linked:
            continue
        source = node.inputs[1].links[0].from_node
        if source.type == 'MATH' and source.operation == 'MULTIPLY' and not source.inputs[1].is_linked and source.inputs[1].default_value == .5:
            source.label = 'NORMAL_PATCHWORK_HEIGHT'
ps.gpu(1)
elapsed = ps.bake(obj, 'NORMAL', 8)
ps.save(image, str(output), 'A20_height_normal')
control = bpy.data.images.load(str(reference))
a, b = (np.empty(len(image.pixels), np.float32) for _ in range(2))
image.pixels.foreach_get(a); control.pixels.foreach_get(b)
delta = np.abs(a - b).reshape(-1, 4)[:, :3]
report = dict(seconds=elapsed, height_maps=ps.INFO['normal_height_maps'],
              max_8bit=float(delta.max() * 255), rms_8bit=float(np.sqrt(np.mean(delta ** 2)) * 255),
              channels_over_one=int(np.count_nonzero(delta > 1.01 / 255)),
              channels=int(delta.size), finite=bool(np.isfinite(a).all()))
(output / 'height_probe.json').write_text(json.dumps(report, indent=2))
print('HEIGHT PROBE', json.dumps(report), flush=True)
