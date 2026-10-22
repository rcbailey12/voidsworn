# One load, several textured views. usage: python3 render_multi.py in.glb out_prefix "az el;az el;..."  (env DIST, RES)
import sys, os, math, bpy, mathutils
argv = sys.argv[sys.argv.index('--') + 1:] if '--' in sys.argv else sys.argv[1:]
src, pre, angs = argv[0], argv[1], [tuple(map(float, a.split())) for a in argv[2].split(';')]
bpy.ops.wm.read_factory_settings(use_empty=True); bpy.ops.import_scene.gltf(filepath=src)
if os.environ.get('EXTRA'):  # a second GLB in the same frame (the hand-built parts), shown with its vertex colours
    before = set(bpy.context.scene.objects); bpy.ops.import_scene.gltf(filepath=os.environ['EXTRA'])
    km = bpy.data.materials.new('kit'); km.use_nodes = True; kn = km.node_tree; kb = kn.nodes['Principled BSDF']; at = kn.nodes.new('ShaderNodeVertexColor')
    kn.links.new(at.outputs[0], kb.inputs['Base Color']); kb.inputs['Metallic'].default_value = .45; kb.inputs['Roughness'].default_value = .42
    for o in set(bpy.context.scene.objects) - before:
        if o.type == 'MESH' and not (o.data.materials and o.data.materials[0] and any(n.type == 'TEX_IMAGE' for n in o.data.materials[0].node_tree.nodes)): o.data.materials.clear(); o.data.materials.append(km)
ms = [o for o in bpy.context.scene.objects if o.type == 'MESH']
for o in ms:  # an untextured main mesh (the clean shell before painting) shows its vertex colours
    if o.data.color_attributes and not (o.data.materials and o.data.materials[0] and o.data.materials[0].use_nodes and any(n.type == 'TEX_IMAGE' for n in o.data.materials[0].node_tree.nodes)):
        vm = bpy.data.materials.new('vcol'); vm.use_nodes = True; vb = vm.node_tree.nodes['Principled BSDF']; vc = vm.node_tree.nodes.new('ShaderNodeVertexColor')
        vm.node_tree.links.new(vc.outputs[0], vb.inputs['Base Color']); vb.inputs['Roughness'].default_value = .5; o.data.materials.clear(); o.data.materials.append(vm)
mn = mathutils.Vector((1e9,)*3); mx = mathutils.Vector((-1e9,)*3)
if os.environ.get('ALB'):  # swap in a replacement albedo
    im = bpy.data.images.load(os.environ['ALB'])
    for o in ms:
        for m in o.data.materials:
            for n in m.node_tree.nodes:
                if n.type == 'TEX_IMAGE' and n.outputs[0].links and n.outputs[0].links[0].to_socket.name == 'Base Color': n.image = im
for o in ms:
    for c in o.bound_box:
        w = o.matrix_world @ mathutils.Vector(c); mn = mathutils.Vector(map(min, mn, w)); mx = mathutils.Vector(map(max, mx, w))
ctr = (mn + mx) / 2; R = (mx - mn).length / 2; print('size', [round(x, 3) for x in (mx - mn)], 'faces', sum(len(o.data.polygons) for o in ms))
sc = bpy.context.scene; sc.render.engine = 'CYCLES'
try:
    pr = bpy.context.preferences.addons['cycles'].preferences
    for t_ in ('OPTIX', 'CUDA'):
        try:
            pr.compute_device_type = t_; pr.get_devices()
            if any(d.type == t_ for d in pr.devices):
                for d in pr.devices: d.use = d.type == t_
                sc.cycles.device = 'GPU'; break
        except Exception: pass
except Exception: pass
sc.cycles.samples = 24; sc.cycles.use_denoising = True; r = int(os.environ.get('RES', '900')); sc.render.resolution_x = r; sc.render.resolution_y = r * 2 // 3
sc.world = bpy.data.worlds.new('w'); sc.world.use_nodes = True; sc.world.node_tree.nodes['Background'].inputs[0].default_value = (.06, .065, .08, 1); sc.world.node_tree.nodes['Background'].inputs[1].default_value = .7
cam = bpy.data.objects.new('cam', bpy.data.cameras.new('cam')); sc.collection.objects.link(cam); sc.camera = cam; cam.data.lens = 50
for (en, rot) in ((8.0, (math.radians(50), 0, math.radians(30))), (1.5, (math.radians(70), 0, math.radians(200)))):
    l = bpy.data.objects.new('sun', bpy.data.lights.new('sun', 'SUN')); l.data.energy = en; l.rotation_euler = rot; sc.collection.objects.link(l)
d = R * float(os.environ.get('DIST', '2.3'))
for k, (az, el) in enumerate(angs):
    a, e = math.radians(az), math.radians(el)
    cam.location = ctr + mathutils.Vector((math.cos(a) * math.cos(e), -math.sin(a) * math.cos(e), math.sin(e))) * d
    cam.rotation_euler = (ctr - cam.location).to_track_quat('-Z', 'Y').to_euler()
    sc.render.filepath = f'{pre}{k}.png'; bpy.ops.render.render(write_still=True)
