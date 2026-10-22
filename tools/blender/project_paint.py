# Project the source pictures (concept painting + generated views) back onto a Pixal3D mesh and bake them into its albedo, so the
# paint is as sharp as the pictures wherever a picture sees the surface; elsewhere the mesh's own baked paint shows through.
# Cameras follow Pixal3D's orbit rig (z up, az 0 = front, 90 = left, fov 20, unit cube spanning 1/1.1 of the frame).
# usage: python3 project_paint.py in.glb out_albedo.png RES view.png|mask.png|az|el|weight [...]
import sys, math, numpy as np, bpy, bmesh, mathutils
from mathutils.bvhtree import BVHTree
argv = sys.argv[sys.argv.index('--') + 1:] if '--' in sys.argv else sys.argv[1:]  # works as `blender -b -P project_paint.py -- ...` or with the bpy module
src, outp, RES = argv[0], argv[1], int(argv[2]); views = []
for a in argv[3:]:
    p = a.split('|')
    if p[2].startswith('@'):  # az/el from a fitcam_rig.py result
        import json as _j; f = _j.load(open(p[2][1:])); p[2], p[3] = f['az'], f['el']
    views.append((p[0], p[1], float(p[2]), float(p[3]), float(p[4])))
import os
PROC = os.environ.get('PAINT') == 'proc'  # v12: weathered paint made from the parts' own colours, no picture projection (pictures carry
# the AI's old part layout, which ghosts onto the clean shell)
if PROC: views = []
bpy.ops.wm.read_factory_settings(use_empty=True); bpy.ops.import_scene.gltf(filepath=src)
o = [x for x in bpy.context.scene.objects if x.type == 'MESH'][0]; me = o.data; sc = bpy.context.scene
bpy.context.view_layer.objects.active = o; o.select_set(True)
base_img = None
if me.uv_layers and me.materials and me.materials[0] and me.materials[0].use_nodes:
    nt = me.materials[0].node_tree; base_img = next((n.image for n in nt.nodes if n.type == 'TEX_IMAGE' and n.outputs[0].links and n.outputs[0].links[0].to_socket.name == 'Base Color'), None)
if base_img is None:  # hand-built parts: vertex colours, no UVs yet; give them a UV atlas first
    while me.uv_layers: me.uv_layers.remove(me.uv_layers[0])
    me.uv_layers.new(name='UVMap'); bpy.ops.object.mode_set(mode='EDIT'); bpy.ops.mesh.select_all(action='SELECT')
    bpy.ops.uv.smart_project(angle_limit=math.radians(55), island_margin=0.0005)
    try: bpy.ops.uv.pack_islands(rotate=True, margin_method='FRACTION', margin=0.0006, shape_method='AABB')  # v13: the old pack left the kit at 1.7% of the atlas (parts read black in game); this fills ~60%
    except Exception as e: print('uv pack failed', e)
    bpy.ops.object.mode_set(mode='OBJECT')
base_uv = me.uv_layers.active.name
print('mesh', len(me.vertices), 'verts', len(me.polygons), 'tris, uv', base_uv, 'base', base_img.size[:] if base_img else 'vertex colours')
occ = None
if os.environ.get('OCC'):  # other geometry that can hide this mesh from a camera (the hull, for the hand-built parts)
    before = set(sc.objects); bpy.ops.import_scene.gltf(filepath=os.environ['OCC']); occ = [x for x in set(sc.objects) - before if x.type == 'MESH']
    bpy.ops.object.select_all(action='DESELECT'); bpy.context.view_layer.objects.active = o; o.select_set(True)
sc.render.resolution_x = sc.render.resolution_y = 1024
FOV = math.radians(20); D = 1.1 * 0.5 / math.tan(FOV / 2)
V = np.array([v.co[:] for v in me.vertices]); NV = np.array([v.normal[:] for v in me.vertices])
bm = bmesh.new(); bm.from_mesh(me); bm.transform(o.matrix_world)
for x in occ or []:
    t = bmesh.new(); t.from_mesh(x.data); t.transform(x.matrix_world); tm = bpy.data.meshes.new('occtmp'); t.to_mesh(tm); t.free(); bm.from_mesh(tm)
bvh = BVHTree.FromBMesh(bm); bm.free()
for x in occ or []: bpy.data.objects.remove(x)
mw = np.array(o.matrix_world); VW = V @ mw[:3, :3].T + mw[:3, 3]; NW = NV @ mw[:3, :3].T; NW /= np.maximum(np.linalg.norm(NW, axis=1, keepdims=True), 1e-9)
KEEP = None
if os.environ.get('KEEP'):  # boxes "x0,x1,y0,y1,z0,z1;..." in this mesh's frame: vertices inside keep their vertex colours, unprojected
    KEEP = np.zeros(len(V), bool)
    for b_ in os.environ['KEEP'].split(';'):
        x0, x1, y0, y1, z0, z1 = map(float, b_.split(',')); KEEP |= (VW[:, 0] >= x0) & (VW[:, 0] <= x1) & (VW[:, 1] >= y0) & (VW[:, 1] <= y1) & (VW[:, 2] >= z0) & (VW[:, 2] <= z1)
    print('keep own paint', int(KEEP.sum()), 'verts')
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
    if KEEP is not None: w[KEEP] = 0  # parts that keep their own (vertex) paint
    at = me.attributes.new(f'w{k}', 'FLOAT', 'POINT'); at.data.foreach_set('value', w.astype(np.float32))
    print('view', k, img.split('/')[-1], 'az', az, 'el', el, 'visible %.1f%%' % (100 * (w > 0).mean()))
me.uv_layers.active = me.uv_layers[base_uv]
# bake material: weighted average of the projected pictures (masked), with the mesh's own paint as a weak fallback
bm_ = bpy.data.materials.new('proj'); bm_.use_nodes = True; T = bm_.node_tree; T.nodes.clear(); L = T.links
out = T.nodes.new('ShaderNodeOutputMaterial'); em = T.nodes.new('ShaderNodeEmission'); L.new(em.outputs[0], out.inputs[0])
if base_img is not None:
    uvb = T.nodes.new('ShaderNodeUVMap'); uvb.uv_map = base_uv; tb = T.nodes.new('ShaderNodeTexImage'); tb.image = base_img; L.new(uvb.outputs[0], tb.inputs[0])
else:  # vertex colours, broken up with grime so hand-painted parts don't read as flat plastic
    vc = T.nodes.new('ShaderNodeVertexColor'); nz = T.nodes.new('ShaderNodeTexNoise'); nz.inputs['Scale'].default_value = 160; nz.inputs['Detail'].default_value = 8
    tco = T.nodes.new('ShaderNodeTexCoord'); L.new(tco.outputs['Object'], nz.inputs['Vector'])
    gm = T.nodes.new('ShaderNodeMapRange'); L.new(nz.outputs['Fac'], gm.inputs['Value']); gm.inputs['From Min'].default_value = .3; gm.inputs['From Max'].default_value = .7; gm.inputs['To Min'].default_value = .62; gm.inputs['To Max'].default_value = 1.18
    tb = T.nodes.new('ShaderNodeVectorMath'); tb.operation = 'SCALE'; L.new(vc.outputs[0], tb.inputs[0]); L.new(gm.outputs[0], tb.inputs[3])
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
if sumw is None: col_ = tb.outputs[0]
else: sumw = math_('ADD', sumw, wb); col_ = vmath('SCALE', sumc, s=math_('DIVIDE', 1.0, sumw))
if PROC and base_img is None:
    # weathered metal (owner, Oct 22: "less like shiny clay and more like rusted metal"): the part's own paint colour, mottled, with rust
    # patches and vertical streaks, grime in the cavities, paint worn back to steel on the edges. All in ship space, same scale on every part.
    vcol = T.nodes.new('ShaderNodeVertexColor'); tco = T.nodes.new('ShaderNodeTexCoord'); oc = tco.outputs['Object']
    def noise(scale, detail, vec=None, rough=.55):
        n = T.nodes.new('ShaderNodeTexNoise'); n.inputs['Scale'].default_value = scale; n.inputs['Detail'].default_value = detail; n.inputs['Roughness'].default_value = rough; L.new(vec or oc, n.inputs['Vector']); return n.outputs['Fac']
    def rng(x, a, b, c, d):
        m = T.nodes.new('ShaderNodeMapRange'); L.new(x, m.inputs['Value']); m.inputs['From Min'].default_value = a; m.inputs['From Max'].default_value = b; m.inputs['To Min'].default_value = c; m.inputs['To Max'].default_value = d; return m.outputs[0]
    def mix(fac, a, b):  # vector lerp a->b by fac
        mx = T.nodes.new('ShaderNodeMix'); mx.data_type = 'RGBA'; L.new(fac, mx.inputs['Factor'])
        for sock, v in ((mx.inputs[6], a), (mx.inputs[7], b)):
            if isinstance(v, tuple): sock.default_value = (*v, 1)
            else: L.new(v, sock)
        return mx.outputs[2]
    base = vmath('SCALE', vcol.outputs[0], s=rng(noise(32, 7), .25, .75, .62, 1.18))                     # mottled, faded paint
    base = vmath('SCALE', base, s=rng(noise(9, 6, rough=.6), .40, .70, .50, 1.0))                         # big dirt patches
    st = T.nodes.new('ShaderNodeVectorMath'); st.operation = 'MULTIPLY'; L.new(oc, st.inputs[0]); st.inputs[1].default_value = (90, 90, 5)
    streak = rng(noise(1, 6, st.outputs[0]), .40, .72, 0, 1)                                             # vertical run-off streaks
    base = vmath('SCALE', base, s=rng(streak, 0, 1, 1.0, .55))
    vo = T.nodes.new('ShaderNodeTexVoronoi'); vo.inputs['Scale'].default_value = 26; L.new(oc, vo.inputs['Vector'])  # plate-to-plate repaint tone
    base = vmath('SCALE', base, s=rng(vo.outputs['Distance'] if False else vo.outputs[1], 0, 1, .78, 1.15))
    scorch = rng(noise(4, 4, rough=.5), .70, .80, 0, 1)                                                   # scorch marks from hits
    base = vmath('SCALE', base, s=rng(scorch, 0, 1, 1.0, .22))
    rust = rng(noise(20, 10, rough=.7), .52, .64, 0, 1)                                                   # rust patches
    base = mix(math_('MULTIPLY', rust, .85), base, (.13, .045, .018))
    pits = rng(noise(140, 4), .62, .72, 0, 1)                                                             # small rust pits
    base = mix(math_('MULTIPLY', pits, .7), base, (.09, .035, .015))
    bv = T.nodes.new('ShaderNodeBevel'); bv.inputs['Radius'].default_value = .0025; geo = T.nodes.new('ShaderNodeNewGeometry')
    dp = T.nodes.new('ShaderNodeVectorMath'); dp.operation = 'DOT_PRODUCT'; L.new(bv.outputs[0], dp.inputs[0]); L.new(geo.outputs['Normal'], dp.inputs[1])
    edge = math_('MULTIPLY', rng(dp.outputs['Value'], .985, .80, 0, 1), rng(noise(70, 3), .3, .6, .25, 1))  # worn edges, broken up
    base = mix(edge, base, (.26, .24, .22))
    ao = T.nodes.new('ShaderNodeAmbientOcclusion'); ao.inputs['Distance'].default_value = .03; ao.samples = 16
    base = vmath('SCALE', base, s=rng(ao.outputs['AO'], 0, 1, .30, 1.0))                                  # grime in the cavities
    col_ = vmath('SCALE', base, s=rng(noise(500, 2), .3, .7, .85, 1.08))                                  # fine grit
    sc.cycles.samples = 16
if base_img is None and os.environ.get('DETAIL', '0') == '1':  # v55: off by default; the shared in-game detail layer (HullFx DET) covers hull and parts alike
    # hand-built parts get the AI hull's level of surface detail (owner, Oct 21: "the level of texture and details seem to vary wildly"):
    # panel seams at a fixed ship-space scale, fine grit, and worn edges from the bevel normal, on top of whatever paint they carry
    tc = T.nodes.new('ShaderNodeTexCoord')
    br = T.nodes.new('ShaderNodeTexBrick'); br.inputs['Scale'].default_value = 38; br.inputs['Mortar Size'].default_value = .012; br.inputs['Color1'].default_value = (1, 1, 1, 1); br.inputs['Color2'].default_value = (.93, .93, .93, 1); br.inputs['Mortar'].default_value = (.45, .45, .45, 1); br.offset = .5
    L.new(tc.outputs['Object'], br.inputs['Vector'])
    gr = T.nodes.new('ShaderNodeTexNoise'); gr.inputs['Scale'].default_value = 900; gr.inputs['Detail'].default_value = 4; L.new(tc.outputs['Object'], gr.inputs['Vector'])
    gm2 = T.nodes.new('ShaderNodeMapRange'); L.new(gr.outputs['Fac'], gm2.inputs['Value']); gm2.inputs['To Min'].default_value = .82; gm2.inputs['To Max'].default_value = 1.12
    bv = T.nodes.new('ShaderNodeBevel'); bv.inputs['Radius'].default_value = .0015; geo = T.nodes.new('ShaderNodeNewGeometry')
    dp = T.nodes.new('ShaderNodeVectorMath'); dp.operation = 'DOT_PRODUCT'; L.new(bv.outputs[0], dp.inputs[0]); L.new(geo.outputs['Normal'], dp.inputs[1])
    ed = T.nodes.new('ShaderNodeMapRange'); L.new(dp.outputs['Value'], ed.inputs['Value']); ed.inputs['From Min'].default_value = .80; ed.inputs['From Max'].default_value = .99; ed.inputs['To Min'].default_value = 1.6; ed.inputs['To Max'].default_value = 1.0
    bw = T.nodes.new('ShaderNodeRGBToBW'); L.new(br.outputs['Color'], bw.inputs[0])
    f_ = math_('MULTIPLY', math_('MULTIPLY', bw.outputs[0], gm2.outputs[0]), ed.outputs[0])
    col_ = vmath('SCALE', col_, s=f_)
L.new(col_, em.inputs[0])
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
sc.cycles.samples = 16 if PROC else 4; sc.render.bake.margin = 3; sc.render.bake.use_selected_to_active = False
bpy.ops.object.bake(type='EMIT'); tgt.filepath_raw = outp; tgt.file_format = 'PNG'; tgt.save(); print('baked', outp)
if os.environ.get('EXPORT'):  # write the mesh back out with the baked paint as its texture (hand-built parts)
    for k in range(len(views)): me.uv_layers.remove(me.uv_layers[f'proj{k}'])
    em_ = bpy.data.materials.new('painted'); em_.use_nodes = True; ti_ = em_.node_tree.nodes.new('ShaderNodeTexImage'); ti_.image = bpy.data.images.load(outp)
    em_.node_tree.links.new(ti_.outputs[0], em_.node_tree.nodes['Principled BSDF'].inputs['Base Color']); me.materials.clear(); me.materials.append(em_)
    bpy.ops.object.select_all(action='DESELECT'); o.select_set(True); bpy.context.view_layer.objects.active = o
    bpy.ops.export_scene.gltf(filepath=os.environ['EXPORT'], export_format='GLB', use_selection=True); print('exported', os.environ['EXPORT'])
