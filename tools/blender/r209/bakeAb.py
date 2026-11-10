# Issue 209 round 2, the bake cell "Ab": B0's generated surface detail baked into normal and AO maps on the corrected A hull.
# The hull is A2's structure (the massing blocks joined into one mesh, UV unwrapped); the parts are A2's hand-built round 2 parts;
# the hand plating is left off so the hull surface detail comes only from the bake. Source: the whole-hull TRELLIS.2 generation
# (B0) at full resolution, yaw fixed. Cycles on the GPU, selected to active, cage pushed out and in so both B0 lumps above and
# hollows below the hand hull are caught. Where B0's shape departs from the hand hull by more than the ray distance, the map
# stays flat (that is part of what this cell shows).
# usage: blender -b -P bakeAb.py -- OUT_DIR B0_GLB [RES]
import os, sys, math, json, time
HERE = os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0, HERE)
import bpy
import common as C
import armA2 as A2

A = sys.argv[sys.argv.index('--') + 1:]
OUT, B0 = A[0], A[1]; RES = int(A[2]) if len(A) > 2 else 4096
AO_DIST = .025                  # AO reach in ship units (about 1 game unit on the 41.6 frame, a third of a hull height)
CAGE, RAY = .035, .070          # ship units (the hull is 1.0 long): rays start 0.035 outside the hand hull and reach 0.035 inside it
# (0.02 left rays starting inside B0 where B0 is fatter than the hand hull; they hit B0 from the inside and baked black AO)
INFO = {}

def gpu():
    sc = bpy.context.scene; sc.render.engine = 'CYCLES'
    prefs = bpy.context.preferences.addons['cycles'].preferences
    for t in ('OPTIX', 'CUDA'):
        try:
            prefs.compute_device_type = t; prefs.get_devices()
            gp = [d for d in prefs.devices if d.type == t]
            if not gp: continue
            for d in prefs.devices: d.use = True
            sc.cycles.device = 'GPU'; return t
        except Exception: pass
    return 'CPU'

def prepare(S):
    t0 = time.time()
    bpy.ops.object.select_all(action='DESELECT')
    for o in S: o.select_set(True)
    bpy.context.view_layer.objects.active = S[0]; bpy.ops.object.join(); hull = bpy.context.view_layer.objects.active
    hull.name = 'hull_baked'; hull['role'] = 'hull'
    bpy.ops.object.mode_set(mode='EDIT'); bpy.ops.mesh.select_all(action='SELECT')
    bpy.ops.uv.smart_project(angle_limit=math.radians(60), island_margin=.003); bpy.ops.object.mode_set(mode='OBJECT')
    src = C.import_glb(B0, 'b0_src'); C.ai_align(src, 22.0)
    sc0 = bpy.context.scene
    if sc0.world is None: sc0.world = bpy.data.worlds.new('w')
    sc0.world.light_settings.distance = AO_DIST
    src.data.calc_loop_triangles(); INFO['bake_source_triangles'] = len(src.data.loop_triangles)
    dev = gpu(); sc = bpy.context.scene; sc.cycles.samples = 64
    imgs = {}
    for kind in ('NORMAL', 'AO'):
        im = bpy.data.images.new(f'Ab_{kind.lower()}', RES, RES, alpha=False, float_buffer=False); im.colorspace_settings.name = 'Non-Color'
        im.generated_color = (.5, .5, 1, 1) if kind == 'NORMAL' else (1, 1, 1, 1); imgs[kind] = im
    bm = bpy.data.materials.new('bake_target'); bm.use_nodes = True; tex = bm.node_tree.nodes.new('ShaderNodeTexImage')
    hull.data.materials.clear(); hull.data.materials.append(bm)
    bpy.ops.object.select_all(action='DESELECT'); src.select_set(True); hull.select_set(True); bpy.context.view_layer.objects.active = hull
    rb = sc.render.bake; rb.use_selected_to_active = True; rb.cage_extrusion = CAGE; rb.max_ray_distance = RAY; rb.margin = 8
    for kind in ('NORMAL', 'AO'):
        tex.image = imgs[kind]; bm.node_tree.nodes.active = tex; t1 = time.time()
        for a in ('visible_diffuse', 'visible_glossy', 'visible_shadow', 'visible_transmission', 'visible_volume_scatter'):
            setattr(hull, a, kind != 'AO')   # the hand hull must not shade B0's own occlusion
        bpy.ops.object.bake(type=kind, normal_space='TANGENT' if kind == 'NORMAL' else 'OBJECT')
        INFO[f'bake_{kind.lower()}_seconds'] = round(time.time() - t1, 1)
        imgs[kind].filepath_raw = os.path.join(OUT, f'Ab_{kind.lower()}.png'); imgs[kind].file_format = 'PNG'; imgs[kind].save(); imgs[kind].pack()
    bpy.data.objects.remove(src); hull.data.materials.clear()
    for a in ('visible_diffuse', 'visible_glossy', 'visible_shadow', 'visible_transmission', 'visible_volume_scatter'): setattr(hull, a, True)
    INFO.update(bake_device=dev, bake_res=RES, cage=CAGE, ray=RAY, ao_distance=AO_DIST, bake_total_seconds=round(time.time() - t0, 1))
    return [hull]

def finish(S):
    """swap the hull's paint for copies that read the baked maps: normal map into the BSDF, AO multiplied into the base colour"""
    hull = S[0]; nimg = bpy.data.images['Ab_normal']; aimg = bpy.data.images['Ab_ao']
    for i, m in enumerate(list(hull.data.materials)):
        if m is None: continue
        mm = m.copy(); mm.name = m.name + '_Ab'; nt = mm.node_tree; bs = next(n for n in nt.nodes if n.type == 'BSDF_PRINCIPLED')
        uv = nt.nodes.new('ShaderNodeUVMap')
        tn = nt.nodes.new('ShaderNodeTexImage'); tn.image = nimg; nm = nt.nodes.new('ShaderNodeNormalMap'); nm.inputs['Strength'].default_value = 1.0
        nt.links.new(uv.outputs[0], tn.inputs[0]); nt.links.new(tn.outputs[0], nm.inputs['Color']); nt.links.new(nm.outputs[0], bs.inputs['Normal'])
        ta = nt.nodes.new('ShaderNodeTexImage'); ta.image = aimg; nt.links.new(uv.outputs[0], ta.inputs[0])
        lk = next((l for l in nt.links if l.to_socket == bs.inputs['Base Color']), None)
        if lk:
            mul = nt.nodes.new('ShaderNodeMixRGB'); mul.blend_type = 'MULTIPLY'; mul.inputs[0].default_value = 1
            nt.links.new(lk.from_socket, mul.inputs[1]); nt.links.new(ta.outputs[0], mul.inputs[2]); nt.links.new(mul.outputs[0], bs.inputs['Base Color'])
        hull.data.materials[i] = mm
    return dict(bake=INFO)

if __name__ == '__main__':
    os.makedirs(OUT, exist_ok=True)
    A2.build(OUT, 2, cell='Ab', hull_detail=False, before_paint=sys.modules[__name__])
