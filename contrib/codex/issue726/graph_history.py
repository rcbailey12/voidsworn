"""Count the same capital zone's normal dependencies across paint revisions.

CPU graph construction only, no bakes, installs or source edits. Decals are
omitted equally from every case to isolate the patchwork and trophy changes.
Usage in Blender: -- REPO TEMP_OUTPUT
"""
import json
from pathlib import Path
import subprocess
import sys
import types

import bpy

repo, output = map(Path, sys.argv[sys.argv.index('--') + 1:])
output.mkdir(parents=True, exist_ok=True)
for path in ('tools/blender/r209', 'tools/blender/kits/shared'):
    sys.path.insert(0, str(repo / path))


def module(name, revision, relative):
    path = repo / relative
    source = subprocess.check_output(['git', '-C', str(repo), 'show', revision + ':' + relative])
    result = types.ModuleType(name)
    result.__file__ = str(path)
    sys.modules[name] = result
    exec(compile(source, str(path), 'exec'), result.__dict__)
    return result


rows = []
for revision, label in [('737c8cf0', 'R240, hb682'),
                        ('ac3453bf', 'R252 trophies'),
                        ('19464d19', 'R274 dark grey'),
                        ('225b10ae', 'PR 898 craft path'),
                        ('0e9c791d', 'run 4 main')]:
    # Hold the shared machinery fixed, isolating each faction-stack change.
    ps = module('paint_stack', '0e9c791d', 'tools/blender/kits/shared/paint_stack.py')
    stack = module('history_stack', revision, 'tools/blender/kits/hullbreakers/stack.py')
    if hasattr(stack, 'configure_size'): stack.configure_size(19.0)
    masks = bpy.data.images.new('history_masks', 16, 16)
    masks.colorspace_settings.name = 'Non-Color'
    tiles = {key: ps.np_image('history_' + key, value) for key, value in stack.trim_sheet().items()}
    material = ps.zone_material(stack, 'soot', 'H', masks, tiles, [], None)
    normal = next(n for n in material.node_tree.nodes if n.type == 'BSDF_PRINCIPLED').inputs['Normal']
    pending = [link.from_node for link in normal.links]
    keep = set(pending)
    while pending:
        for socket in pending.pop().inputs:
            for link in socket.links:
                if link.from_node not in keep:
                    keep.add(link.from_node); pending.append(link.from_node)
    row = dict(revision=revision, label=label, normal_input_nodes=len(keep), total_nodes=len(material.node_tree.nodes))
    rows.append(row)
    print('GRAPH HISTORY', json.dumps(row), flush=True)
(output / 'graph_history.json').write_text(json.dumps(dict(zone='soot', group='H', shared_revision='0e9c791d',
                                                         decals='omitted equally', cases=rows), indent=2))
