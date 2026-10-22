# Project the source pictures (concept painting + generated views) back onto a Pixal3D or kit mesh and bake them into its albedo,
# so the paint is as sharp as the pictures wherever a picture sees the surface; elsewhere the mesh's own paint shows through.
# Cameras follow Pixal3D's orbit rig (z up, az 0 = front, 90 = left, fov 20, unit cube spanning 1/1.1 of the frame).
# usage: python3 project_paint.py in.glb out_albedo.png RES view.png|mask.png|az|el|weight [...]
import sys, os, json, math, numpy as np, bpy, bmesh, mathutils
from mathutils.bvhtree import BVHTree

argv = sys.argv[sys.argv.index('--') + 1:] if '--' in sys.argv else sys.argv[1:]
src, outp, RES = argv[0], argv[1], int(argv[2])

def _parse_view_arg(a):
    if '|' in a:
        p = a.split('|')
        if p[2].startswith('@'):
            f = json.load(open(p[2][1:]))
            p[2], p[3] = f['az'], f['el']
        return (p[0], p[1], float(p[2]), float(p[3]), float(p[4]))
    # Auto-resolve bare image paths (fixes c19_4_kit_to_game.bat line 14)
    img_p = a
    stem, ext = os.path.splitext(img_p)
    cand_msk = stem + '_mask' + ext
    msk_p = cand_msk if os.path.exists(cand_msk) else img_p
    low = os.path.basename(stem).lower()
    if low.endswith('_left'):
        return (img_p, msk_p, 90.0, 0.0, 1.0)
    if low.endswith('_right'):
        return (img_p, msk_p, 270.0, 0.0, 1.0)
    if low.endswith('_front'):
        return (img_p, msk_p, 0.0, 0.0, 1.0)
    if low.endswith('_back'):
        return (img_p, msk_p, 180.0, 0.0, 1.0)
    if low.endswith('_top'):
        return (img_p, msk_p, 90.0, 88.0, 0.7)
    # Concept image: look for fitcam json in same or parent project folder
    fit_candidates = [
        os.path.join(os.path.dirname(outp), '..', 'proj', 'fitcam.json'),
        os.path.join(os.path.dirname(src), '..', 'proj', 'fitcam.json'),
    ]
    for fc in fit_candidates:
        if os.path.exists(fc):
            f = json.load(open(fc))
            return (img_p, msk_p, float(f['az']), float(f['el']), 2.0)
    return (img_p, msk_p, 146.0, 14.0, 2.0)

views = [_parse_view_arg(a) for a in argv[3:]]

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=src)
meshes = [x for x in bpy.context.scene.objects if x.type == 'MESH']

# If input GLB has multiple unjoined mesh objects (e.g. older kit GLBs), convert material Base Colors to vertex colors and join
if len(meshes) > 1 or (len(meshes) == 1 and not meshes[0].data.color_attributes and not meshes[0].data.uv_layers):
    for obj in meshes:
        me_part = obj.data
        if not me_part.color_attributes:
            rgb = (0.15, 0.15, 0.16)
            if me_part.materials and me_part.materials[0] and me_part.materials[0].use_nodes:
                bsdf = me_part.materials[0].node_tree.nodes.get('Principled BSDF')
                if bsdf:
                    bc = bsdf.inputs['Base Color'].default_value
                    rgb = (bc[0], bc[1], bc[2])
            ca = me_part.color_attributes.new(name='Col', type='FLOAT_COLOR', domain='CORNER')
            ca.data.foreach_set('color', [rgb[0], rgb[1], rgb[2], 1.0] * len(me_part.loops))
    if len(meshes) > 1:
        bpy.ops.object.select_all(action='DESELECT')
        for obj in meshes:
            obj.select_set(True)
        bpy.context.view_layer.objects.active = meshes[0]
        bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
        bpy.ops.object.join()

o = [x for x in bpy.context.scene.objects if x.type == 'MESH'][0]
me = o.data
sc = bpy.context.scene
bpy.context.view_layer.objects.active = o
o.select_set(True)

base_img = None
if me.uv_layers and me.materials and me.materials[0] and me.materials[0].use_nodes:
    nt = me.materials[0].node_tree
    base_img = next((n.image for n in nt.nodes if n.type == 'TEX_IMAGE' and n.outputs[0].links and n.outputs[0].links[0].to_socket.name == 'Base Color'), None)

if base_img is None:  # hand-built parts: vertex colours, give them a clean UV atlas first
    while me.uv_layers:
        me.uv_layers.remove(me.uv_layers[0])
    me.uv_layers.new(name='UVMap')
    bpy.ops.object.mode_set(mode='EDIT')
    bpy.ops.mesh.select_all(action='SELECT')
    bpy.ops.uv.smart_project(angle_limit=math.radians(55), island_margin=0.006)
    bpy.ops.object.mode_set(mode='OBJECT')

base_uv = me.uv_layers.active.name
print('mesh', len(me.vertices), 'verts', len(me.polygons), 'tris, uv', base_uv, 'base', base_img.size[:] if base_img else 'vertex colours')

occ = None
if os.environ.get('OCC'):
    before = set(sc.objects)
    bpy.ops.import_scene.gltf(filepath=os.environ['OCC'])
    occ = [x for x in set(sc.objects) - before if x.type == 'MESH']
    bpy.ops.object.select_all(action='DESELECT')
    bpy.context.view_layer.objects.active = o
    o.select_set(True)

sc.render.resolution_x = sc.render.resolution_y = 1024
FOV = math.radians(20)
D = 1.1 * 0.5 / math.tan(FOV / 2)
V = np.array([v.co[:] for v in me.vertices])
NV = np.array([v.normal[:] for v in me.vertices])
bm = bmesh.new()
bm.from_mesh(me)
bm.transform(o.matrix_world)
for x in occ or []:
    t = bmesh.new()
    t.from_mesh(x.data)
    t.transform(x.matrix_world)
    tm = bpy.data.meshes.new('occtmp')
    t.to_mesh(tm)
    bm.from_mesh(tm)
bvh = BVHTree.FromBMesh(bm)
bm.free()
for x in occ or []:
    bpy.data.objects.remove(x)

mw = np.array(o.matrix_world)
VW = V @ mw[:3, :3].T + mw[:3, 3]
NW = NV @ mw[:3, :3].T
NW /= np.maximum(np.linalg.norm(NW, axis=1, keepdims=True), 1e-9)

KEEP = None
if os.environ.get('KEEP'):
    KEEP = np.zeros(len(V), bool)
    for b_ in os.environ['KEEP'].split(';'):
        x0, x1, y0, y1, z0, z1 = map(float, b_.split(','))
        KEEP |= (VW[:, 0] >= x0) & (VW[:, 0] <= x1) & (VW[:, 1] >= y0) & (VW[:, 1] <= y1) & (VW[:, 2] >= z0) & (VW[:, 2] <= z1)
    print('keep own paint', int(KEEP.sum()), 'verts')

for k, (img, msk, az, el, wt) in enumerate(views):
    a, e = math.radians(az), math.radians(el)
    back = mathutils.Vector((math.sin(a) * math.cos(e), -math.cos(a) * math.cos(e), math.sin(e)))
    cam = bpy.data.objects.new(f'cam{k}', bpy.data.cameras.new(f'cam{k}'))
    sc.collection.objects.link(cam)
    cam.data.angle = FOV
    cam.data.sensor_fit = 'HORIZONTAL'
    cam.location = back * D
    cam.rotation_euler = mathutils.Euler((math.pi / 2 - e, 0, a))
    m = o.modifiers.new(name=f'proj{k}', type='UV_PROJECT')
    m.uv_layer = f'proj{k}'
    m.projector_count = 1
    m.projectors[0].object = cam
    m.aspect_x = m.aspect_y = 1
    me.uv_layers.new(name=f'proj{k}')
    me.uv_layers.active = me.uv_layers[f'proj{k}']
    bpy.ops.object.modifier_apply(modifier=m.name)

    cp = np.array(cam.location[:])
    dvec = VW - cp
    dist = np.linalg.norm(dvec, axis=1)
    dirs = dvec / dist[:, None]
    face = np.clip(-(NW * dirs).sum(1), 0, 1)
    vis = np.zeros(len(V), bool)
    cpl = mathutils.Vector(cp)
    for i in np.nonzero(face > 0.05)[0]:
        h = bvh.ray_cast(cpl, mathutils.Vector(dirs[i]), dist[i] + 0.02)
        vis[i] = h[0] is not None and h[3] > dist[i] - 0.012
    w = vis * np.clip((face - 0.12) / 0.88, 0, 1) ** 1.5 * wt
    if KEEP is not None:
        w[KEEP] = 0
    at = me.attributes.new(f'w{k}', 'FLOAT', 'POINT')
    at.data.foreach_set('value', w.astype(np.float32))
    print('view', k, os.path.basename(img), 'az', az, 'el', el, 'visible %.1f%%' % (100 * (w > 0).mean()))

me.uv_layers.active = me.uv_layers[base_uv]

bm_ = bpy.data.materials.new('proj')
bm_.use_nodes = True
T = bm_.node_tree
T.nodes.clear()
L = T.links
out = T.nodes.new('ShaderNodeOutputMaterial')
em = T.nodes.new('ShaderNodeEmission')
L.new(em.outputs[0], out.inputs[0])

if base_img is not None:
    uvb = T.nodes.new('ShaderNodeUVMap')
    uvb.uv_map = base_uv
    tb = T.nodes.new('ShaderNodeTexImage')
    tb.image = base_img
    L.new(uvb.outputs[0], tb.inputs[0])
else:
    vc = T.nodes.new('ShaderNodeVertexColor')
    if me.color_attributes:
        vc.layer_name = me.color_attributes[0].name
    nz = T.nodes.new('ShaderNodeTexNoise')
    nz.inputs['Scale'].default_value = 160
    nz.inputs['Detail'].default_value = 8
    tco = T.nodes.new('ShaderNodeTexCoord')
    L.new(tco.outputs['Object'], nz.inputs['Vector'])
    gm = T.nodes.new('ShaderNodeMapRange')
    L.new(nz.outputs['Fac'], gm.inputs['Value'])
    gm.inputs['From Min'].default_value = .3
    gm.inputs['From Max'].default_value = .7
    gm.inputs['To Min'].default_value = .78
    gm.inputs['To Max'].default_value = 1.16
    tb = T.nodes.new('ShaderNodeVectorMath')
    tb.operation = 'SCALE'
    L.new(vc.outputs[0], tb.inputs[0])
    L.new(gm.outputs[0], tb.inputs[3])

def math_(op, a, b):
    n = T.nodes.new('ShaderNodeMath')
    n.operation = op
    for i, x in enumerate((a, b)):
        (L.new(x, n.inputs[i]) if not isinstance(x, (int, float)) else n.inputs[i].__setattr__('default_value', x))
    return n.outputs[0]

def vmath(op, a, b=None, s=None):
    n = T.nodes.new('ShaderNodeVectorMath')
    n.operation = op
    L.new(a, n.inputs[0])
    if b is not None:
        L.new(b, n.inputs[1])
    if s is not None:
        L.new(s, n.inputs[3]) if not isinstance(s, (int, float)) else n.inputs[3].__setattr__('default_value', s)
    return n.outputs[0]

wb = 0.06
sumc = vmath('SCALE', tb.outputs[0], s=wb)
sumw = None
for k, (img, msk, az, el, wt) in enumerate(views):
    uv = T.nodes.new('ShaderNodeUVMap')
    uv.uv_map = f'proj{k}'
    ti = T.nodes.new('ShaderNodeTexImage')
    ti.image = bpy.data.images.load(img)
    ti.extension = 'CLIP'
    L.new(uv.outputs[0], ti.inputs[0])
    tm = T.nodes.new('ShaderNodeTexImage')
    tm.image = bpy.data.images.load(msk)
    tm.image.colorspace_settings.name = 'Non-Color'
    tm.extension = 'CLIP'
    L.new(uv.outputs[0], tm.inputs[0])
    atn = T.nodes.new('ShaderNodeAttribute')
    atn.attribute_name = f'w{k}'
    # Support both grayscale mask images and RGBA alpha masks
    msk_soc = tm.outputs['Alpha'] if (msk == img and tm.image.channels == 4) else tm.outputs['Color']
    mk = math_('MULTIPLY', atn.outputs['Fac'], math_('GREATER_THAN', msk_soc, 0.5))
    sumc = vmath('ADD', sumc, vmath('SCALE', ti.outputs[0], s=mk))
    sumw = mk if sumw is None else math_('ADD', sumw, mk)

sumw = math_('ADD', sumw, wb)
col_ = vmath('SCALE', sumc, s=math_('DIVIDE', 1.0, sumw))

if base_img is None and os.environ.get('DETAIL', '1') == '1':
    # Energy-neutral surface detail: centered at mean = 1.00 so kit brightness never drifts from hull brightness
    tc = T.nodes.new('ShaderNodeTexCoord')
    br = T.nodes.new('ShaderNodeTexBrick')
    br.inputs['Scale'].default_value = 38
    br.inputs['Mortar Size'].default_value = .012
    br.inputs['Color1'].default_value = (1.03, 1.03, 1.03, 1)
    br.inputs['Color2'].default_value = (.98, .98, .98, 1)
    br.inputs['Mortar'].default_value = (.52, .52, .52, 1)
    br.offset = .5
    L.new(tc.outputs['Object'], br.inputs['Vector'])

    gr = T.nodes.new('ShaderNodeTexNoise')
    gr.inputs['Scale'].default_value = 900
    gr.inputs['Detail'].default_value = 4
    L.new(tc.outputs['Object'], gr.inputs['Vector'])
    gm2 = T.nodes.new('ShaderNodeMapRange')
    L.new(gr.outputs['Fac'], gm2.inputs['Value'])
    gm2.inputs['To Min'].default_value = .88
    gm2.inputs['To Max'].default_value = 1.12

    bv = T.nodes.new('ShaderNodeBevel')
    bv.inputs['Radius'].default_value = .0015
    geo = T.nodes.new('ShaderNodeNewGeometry')
    dp = T.nodes.new('ShaderNodeVectorMath')
    dp.operation = 'DOT_PRODUCT'
    L.new(bv.outputs[0], dp.inputs[0])
    L.new(geo.outputs['Normal'], dp.inputs[1])
    ed = T.nodes.new('ShaderNodeMapRange')
    L.new(dp.outputs['Value'], ed.inputs['Value'])
    ed.inputs['From Min'].default_value = .80
    ed.inputs['From Max'].default_value = .99
    ed.inputs['To Min'].default_value = 1.28
    ed.inputs['To Max'].default_value = .98

    bw = T.nodes.new('ShaderNodeRGBToBW')
    L.new(br.outputs['Color'], bw.inputs[0])
    f_ = math_('MULTIPLY', math_('MULTIPLY', bw.outputs[0], gm2.outputs[0]), ed.outputs[0])
    col_ = vmath('SCALE', col_, s=f_)

L.new(col_, em.inputs[0])
me.materials.clear()
me.materials.append(bm_)

# Use Standard view transform so Blender 4.5 AgX does not compress highlights during EMIT bake
sc.view_settings.view_transform = 'Standard'
sc.view_settings.look = 'None'

tgt = bpy.data.images.new('albedo', RES, RES, alpha=False)
tt = T.nodes.new('ShaderNodeTexImage')
tt.image = tgt
T.nodes.active = tt
sc.render.engine = 'CYCLES'
try:
    pr = bpy.context.preferences.addons['cycles'].preferences
    for t_ in ('OPTIX', 'CUDA'):
        try:
            pr.compute_device_type = t_
            pr.get_devices()
            if any(d.type == t_ for d in pr.devices):
                for d in pr.devices:
                    d.use = d.type == t_
                sc.cycles.device = 'GPU'
                print('device', t_)
                break
        except Exception:
            pass
except Exception:
    pass

sc.cycles.samples = 4
sc.render.bake.margin = 8
sc.render.bake.use_selected_to_active = False
bpy.ops.object.bake(type='EMIT')
tgt.filepath_raw = outp
tgt.file_format = 'PNG'
tgt.save()
print('baked', outp)

# Optional unified linear gain (pass GAIN=<hull_gain> so kit and hull share the exact same scalar gain)
if os.environ.get('GAIN'):
    from PIL import Image
    g = float(os.environ['GAIN'])
    im = Image.open(outp).convert('RGB')
    a = np.array(im, dtype=np.float64) / 255.0
    m = a.sum(2) > 6.0 / 255.0
    lin = a ** 2.2
    o_lin = np.where(lin * g < .6, lin * g, .6 + (1.0 - .6) * (1.0 - np.exp(-(lin * g - .6) / .4)))
    out_srgb = np.clip(o_lin ** (1.0 / 2.2), 0.0, 1.0)
    out_srgb[~m] = a[~m]
    Image.fromarray((out_srgb * 255.0 + 0.5).astype(np.uint8)).save(outp)
    print('applied unified linear gain', g, 'to', outp)

if os.environ.get('EXPORT'):
    for k in range(len(views)):
        me.uv_layers.remove(me.uv_layers[f'proj{k}'])
    em_ = bpy.data.materials.new('painted')
    em_.use_nodes = True
    ti_ = em_.node_tree.nodes.new('ShaderNodeTexImage')
    ti_.image = bpy.data.images.load(outp)
    em_.node_tree.links.new(ti_.outputs[0], em_.node_tree.nodes['Principled BSDF'].inputs['Base Color'])
    me.materials.clear()
    me.materials.append(em_)
    bpy.ops.object.select_all(action='DESELECT')
    o.select_set(True)
    bpy.context.view_layer.objects.active = o
    bpy.ops.export_scene.gltf(filepath=os.environ['EXPORT'], export_format='GLB', use_selection=True)
    print('exported', os.environ['EXPORT'])
