"""Run 3 control from dfe0baba, kept for compiler and OSL experiments.

This proposal still overflows A20 in SVM. It is not the retained repair.
"""
import bpy
import time


def bake(obj, kind, margin):
    sc = bpy.context.scene; rb = sc.render.bake
    rb.use_selected_to_active = False; rb.margin = margin; rb.target = 'IMAGE_TEXTURES'
    bpy.ops.object.select_all(action='DESELECT'); obj.select_set(True); bpy.context.view_layer.objects.active = obj
    t0 = time.time()
    if kind == 'NORMAL':
        # Cycles compiles the entire surface even for a normal bake. Large
        # trophy graphs exceed SVM's stack when their unused colour, roughness
        # and metal branches stay attached. Keep exactly the same normal input
        # on a temporary simple surface, then restore every original link.
        restore = []
        materials = {slot.material for slot in obj.material_slots if slot.material}
        try:
            for mat in materials:
                nt = mat.node_tree
                bs = next(n for n in nt.nodes if n.type == 'BSDF_PRINCIPLED')
                out = next(n for n in nt.nodes if n.type == 'OUTPUT_MATERIAL')
                surface = out.inputs['Surface']
                sources = [link.from_socket for link in surface.links]
                proxy = nt.nodes.new('ShaderNodeBsdfDiffuse')
                restore.append((nt, surface, sources, proxy))
                for link in bs.inputs['Normal'].links:
                    nt.links.new(link.from_socket, proxy.inputs['Normal'])
                nt.links.new(proxy.outputs[0], surface)
            bpy.ops.object.bake(type='NORMAL', normal_space='TANGENT')
        finally:
            for nt, surface, sources, proxy in restore:
                nt.nodes.remove(proxy)
                for source in sources: nt.links.new(source, surface)
    else: bpy.ops.object.bake(type=kind)
    return round(time.time() - t0, 1)
