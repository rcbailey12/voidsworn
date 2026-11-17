"""Compile A20's saved normal graph using the proposal or an isolated copy.

TEMP only. Usage after opening A20_normal_input.blend: REPO OUTPUT plain|isolate
"""
from pathlib import Path
import sys

import bpy

repo, output = map(Path, sys.argv[sys.argv.index('--') + 1:sys.argv.index('--') + 3])
mode = sys.argv[-1]
sys.path.insert(0, str(repo / 'tools/blender/kits/shared'))
import paint_stack as ps

output.mkdir(parents=True, exist_ok=True)
obj = bpy.data.objects['A20_H_bake']
image = obj.material_slots[0].material.node_tree.nodes.active.image
image.scale(64, 64)
ps.gpu(1)
if mode == 'plain':
    sys.path.insert(0, str(Path(__file__).parent))
    from run3_normal_only import bake as normal_only
    normal_only(obj, 'NORMAL', 8)
else:
    originals = [slot.material for slot in obj.material_slots]
    copies = {}
    try:
        for original in set(originals):
            material = original.copy()
            copies[original] = material
            nt = material.node_tree
            bs = next(n for n in nt.nodes if n.type == 'BSDF_PRINCIPLED')
            out = next(n for n in nt.nodes if n.type == 'OUTPUT_MATERIAL')
            target = nt.nodes.active
            proxy = nt.nodes.new('ShaderNodeBsdfDiffuse')
            for link in bs.inputs['Normal'].links:
                nt.links.new(link.from_socket, proxy.inputs['Normal'])
            nt.links.new(proxy.outputs[0], out.inputs['Surface'])
            keep = {out, target}
            pending = [out]
            while pending:
                current = pending.pop()
                for socket in current.inputs:
                    for link in socket.links:
                        if link.from_node not in keep:
                            keep.add(link.from_node)
                            pending.append(link.from_node)
            old_count = len(nt.nodes)
            for n in list(nt.nodes):
                if n not in keep:
                    nt.nodes.remove(n)
            nt.nodes.active = target
            print('NORMAL GRAPH', original.name, old_count, len(nt.nodes), flush=True)
        for slot in obj.material_slots:
            slot.material = copies[slot.material]
        bpy.ops.object.select_all(action='DESELECT')
        obj.select_set(True)
        bpy.context.view_layer.objects.active = obj
        bpy.context.scene.render.bake.margin = 8
        bpy.ops.object.bake(type='NORMAL', normal_space='TANGENT')
    finally:
        for slot, original in zip(obj.material_slots, originals):
            slot.material = original
        for material in copies.values():
            bpy.data.materials.remove(material)
ps.save(image, str(output), mode + '_normal')
print('DONE normal compile probe', mode, flush=True)
