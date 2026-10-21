# Project the source pictures (concept painting + generated views) back onto a Pixal3D mesh and bake them into its albedo, so the
# paint is as sharp as the pictures wherever a picture sees the surface; elsewhere the mesh's own baked paint shows through.
# Cameras follow Pixal3D's orbit rig (z up, az 0 = front, 90 = left, fov 20, unit cube spanning 1/1.1 of the frame).
# usage: python3 project_paint.py in.glb out_albedo.png RES view.png:mask.png:az:el:weight [...]
import sys, math, numpy as np, bpy, bmesh, mathutils
from mathutils.bvhtree import BVHTree
argv = sys.argv[sys.argv.index('--') + 1:] if '--' in sys.argv else sys.argv[1:]  # works as `blender -b -P project_paint.py -- ...` or with the bpy module
src, outp, RES = argv[0], argv[1], int(argv[2]); views = []
for a in argv[3:]:
    p = a.split(':'); views.append((p[0], p[1], float(p[2]), float(p[3]), float(p[4])))
bpy.ops.wm.read_factory_settings(use_empty=True); bpy.ops.import_scene.gltf(filepath=src)
o = [x for x in bpy.context.scene.objects if x.type == 'MESH'][0]; me = o.data; sc = bpy.context.scene
bpy.context.view_layer.objects.active = o; o.select_set(True)
base_uv = me.uv_layers.active.name; mat = me.materials[0]; nt = mat.node_tree
base_img = next(n.image for n in nt.nodes if n.type == 'TEX_IMAGE' and n.outputs[0].links and n.outputs[0].links[0].to_socket.name == 'Base Color')
print('mesh', len(me.vertices), 'verts', len(me.polygons), 'tris, uv', base_uv, 'base', base_img.size[:])
sc.render.resolution_x = sc.render.resolution_y = 1024
FOV = math.radians(20); D = 1.1 * 0.5 / math.tan(FOV / 2)
V = np.array([v.co[:] for v in me.vertices]); NV = np.array([v.normal[:] for v in me.vertices])
bm = bmesh.new(); bm.from_mesh(me); bm.transform(o.matrix_world); bvh = BVHTree.FromBMesh(bm); bm.free()
mw = np.array(o.matrix_world); VW = V @ mw[:3, :3].T + mw[:3, 3]; NW = NV @ mw[:3, :3].T; NW /= np.maximum(np.linalg.norm(NW, axis=1, keepdims=True), 1e-9)
for k, (img, msk, az, el, wt) in enumerate(views):
    a, e = math.radians(az), math.radians(el); back = mathutils.Vector((math.sin(a) * math.cos(e), -math.cos(a) * math.cos(e), math.sin(e)))
    cam = bpy.data.objects.new(f'cam{k}', bpy.data.cameras.new(f'cam{k}')); sc.collection.objects.link(cam); cam.data.angle = FOV; cam.data.sensor_fit = 'HORIZONTAL'
    cam.location = back * D; cam.rotation_euler = (-back).to_track_quat('-Z', 'Y').to_euler()
    me.uv_layers.new(name=f'proj{k}'); me.uv_layers.active = me.uv_layers[f'proj{k}']
    m = o.modifiers.new(f'uvp{k}', 'UV_PROJECT'); m.uv_layer = f'proj{k}'; m.projector_count = 1; m.projectors[0].object = cam; m.aspect_x = m.aspect_y = 1
    bpy.ops.object.modifier_apply(modifier=m.name)
    # visibility (first hit from the camera is this vertex) and facing, per vertex
    cp = np.array(cam.location[:]); dvec = VW - cp; dist = np.linalg.norm(dvec, axis=1); dirs = dvec / dist[:, None]
    face = np.clip(-(NW * dirs).sum(1), 0, 1); vis = np.zeros(len(V), bool); cpl = mathutils.Vector(cp)
    for i in np.nonzero(face > 0.05)[0]:
        h = bvh.ray_cast(cpl, mathutils.Vector(dirs[i]), dist[i] + 0.02)
        vis[i] = h[0] is not None and h[3] > dist[i] - 0.012  # first surface hit is (near) this vertex
    w = vis * np.clip((face - 0.12) / 0.88, 0, 1) ** 1.5 * wt
    at = me.attributes.new(f'w{k}', 'FLOAT', 'POINT'); at.data.foreach_set('value', w.astype(np.float32))
    print('view', k, img.split('/')[-1], 'az', az, 'el', el, 'visible %.1f%%' % (100 * (w > 0).mean()))
me.uv_layers.active = me.uv_layers[base_uv]
# bake material: weighted average of the projected pictures (masked), with the mesh's own paint as a weak fallback
bm_ = bpy.data.materials.new('proj'); bm_.use_nodes = True; T = bm_.node_tree; T.nodes.clear(); L = T.links
out = T.nodes.new('ShaderNodeOutputMaterial'); em = T.nodes.new('ShaderNodeEmission'); L.new(em.outputs[0], out.inputs[0])
uvb = T.nodes.new('ShaderNodeUVMap'); uvb.uv_map = base_uv; tb = T.nodes.new('ShaderNodeTexImage'); tb.image = base_img; L.new(uvb.outputs[0], tb.inputs[0])
def math_(op, a, b):
    n = T.nodes.new('ShaderNodeMath'); n.operation = op
    for i, x in enumerate((a, b)):
        (L.new(x, n.inputs[i]) if not isinstance(x, (int, float)) else n.inputs[i].__setattr__('default_value', x))
    return n.outputs[0]
def vmath(op, a, b=None, s=None):
    n = T.nodes.new('ShaderNodeVectorMath'); n.operation = op; L.new(a, n.inputs[0])
    if b is not None: L.new(b, n.inputs[1])
    if s is not None: L.new(s, n.inputs[3]) if not isinstance(s, (int, float)) else n.inputs[3].__setattr__('default_value', s)
    return n.outputs[0]
wb = 0.06; sumc = vmath('SCALE', tb.outputs[0], s=wb); sumw = None
for k, (img, msk, az, el, wt) in enumerate(views):
    uv = T.nodes.new('ShaderNodeUVMap'); uv.uv_map = f'proj{k}'
    ti = T.nodes.new('ShaderNodeTexImage'); ti.image = bpy.data.images.load(img); ti.extension = 'CLIP'; L.new(uv.outputs[0], ti.inputs[0])
    tm = T.nodes.new('ShaderNodeTexImage'); tm.image = bpy.data.images.load(msk); tm.image.colorspace_settings.name = 'Non-Color'; tm.extension = 'CLIP'; L.new(uv.outputs[0], tm.inputs[0])
    atn = T.nodes.new('ShaderNodeAttribute'); atn.attribute_name = f'w{k}'
    mk = math_('MULTIPLY', atn.outputs['Fac'], math_('GREATER_THAN', tm.outputs[0], 0.5))
    sumc = vmath('ADD', sumc, vmath('SCALE', ti.outputs[0], s=mk)); sumw = mk if sumw is None else math_('ADD', sumw, mk)
sumw = math_('ADD', sumw, wb); L.new(vmath('SCALE', sumc, s=math_('DIVIDE', 1.0, sumw)), em.inputs[0])
me.materials.clear(); me.materials.append(bm_)
tgt = bpy.data.images.new('albedo', RES, RES, alpha=False); tt = T.nodes.new('ShaderNodeTexImage'); tt.image = tgt; T.nodes.active = tt
sc.render.engine = 'CYCLES'
try:
    pr = bpy.context.preferences.addons['cycles'].preferences
    for t_ in ('OPTIX', 'CUDA'):
        try:
            pr.compute_device_type = t_; pr.get_devices()
            if any(d.type == t_ for d in pr.devices):
                for d in pr.devices: d.use = d.type == t_
                sc.cycles.device = 'GPU'; print('device', t_); break
        except Exception: pass
except Exception: pass
sc.cycles.samples = 4; sc.render.bake.margin = 8; sc.render.bake.use_selected_to_active = False
bpy.ops.object.bake(type='EMIT'); tgt.filepath_raw = outp; tgt.file_format = 'PNG'; tgt.save(); print('baked', outp)
