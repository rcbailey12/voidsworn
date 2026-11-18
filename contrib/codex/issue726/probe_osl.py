"""Try CPU OSL on run 3's actual A20 normal input. TEMP output only."""
import json
from pathlib import Path
import sys
import time

import bpy

repo, output = map(Path, sys.argv[sys.argv.index('--') + 1:sys.argv.index('--') + 3])
resolution = int(sys.argv[-1])
sys.path.insert(0, str(repo / 'tools/blender/kits/shared'))
import paint_stack as ps

# Run 3's normal-only function is the route A control, independent of the
# retained height fallback in the working tree.
sys.path.insert(0, str(Path(__file__).parent))
from run3_normal_only import bake as normal_only

output.mkdir(parents=True, exist_ok=True)
obj = bpy.data.objects['A20_H_bake']
image = obj.material_slots[0].material.node_tree.nodes.active.image
image.scale(resolution, resolution)
scene = bpy.context.scene
scene.cycles.device = 'CPU'
scene.cycles.shading_system = True
scene.cycles.samples = 1
started = time.monotonic()
try:
    elapsed = normal_only(obj, 'NORMAL', 8)
    ps.save(image, str(output), 'A20_osl_normal')
    result = dict(ok=True, seconds=elapsed, resolution=resolution)
except Exception as error:
    result = dict(ok=False, seconds=time.monotonic() - started, error=str(error), resolution=resolution)
    raise
finally:
    (output / 'osl_probe.json').write_text(json.dumps(result, indent=2))
    print('OSL PROBE', json.dumps(result), flush=True)
