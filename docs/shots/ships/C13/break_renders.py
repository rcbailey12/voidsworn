import bpy, bmesh, sys, math, json
from mathutils import Vector
blend, out = sys.argv[1], sys.argv[2]
bpy.ops.wm.open_mainfile(filepath=blend)
sc = bpy.context.scene
tl = list(sc['r209_t_lines'])
paths = json.loads(sc['r209_t_paths'])
names = {0: 'B-2', 1: 'B-1'} if tl[0] < tl[1] else {0: 'B-1', 1: 'B-2'}
src = [o for o in bpy.data.objects if o.type == 'MESH']
def cut(keep_fore, x):
    made = []
    for o in src:
        me = o.data.copy(); me.transform(o.matrix_world)
        bm = bmesh.new(); bm.from_mesh(me)
        geom = bm.verts[:] + bm.edges[:] + bm.faces[:]
        r = bmesh.ops.bisect_plane(bm, geom=geom, plane_co=(x, 0, 0), plane_no=(1, 0, 0) if keep_fore else (-1, 0, 0), clear_inner=True)
        if not bm.verts: bm.free(); continue
        bm.to_mesh(me); bm.free()
        n = bpy.data.objects.new(o.name + '_cut', me); sc.collection.objects.link(n); made.append(n)
        if o.data.materials:
            for m in o.data.materials: pass
    return made
for o in src: o.hide_render = True
sc.render.engine = 'CYCLES'; sc.cycles.device = 'CPU'; sc.cycles.samples = 24; sc.cycles.use_denoising = True
sc.view_settings.view_transform = 'Standard'
for o in [o for o in bpy.data.objects if o.type == 'LIGHT']: bpy.data.objects.remove(o)
def sun(nm, d, e):
    l = bpy.data.objects.new(nm, bpy.data.lights.new(nm, 'SUN')); l.data.energy = e; sc.collection.objects.link(l)
    l.rotation_euler = Vector(d).to_track_quat('Z', 'Y').to_euler()
sun('key', (0.5, 0.5, 0.7), 4.0); sun('fill', (-0.6, -0.6, 0.3), 1.5); sun('cutl', (1, 0, 0.2), 1.2); sun('cutl2', (-1, 0, 0.2), 1.2)
w = bpy.data.worlds.new('w'); sc.world = w; w.use_nodes = True; w.node_tree.nodes['Background'].inputs[0].default_value = (0.05, 0.05, 0.06, 1); w.node_tree.nodes['Background'].inputs[1].default_value = 1.0
sc.render.resolution_x, sc.render.resolution_y = 1080, 720
cam = bpy.data.objects.new('cam', bpy.data.cameras.new('cam')); sc.collection.objects.link(cam); sc.camera = cam
cam.data.lens = 50
res = []
for i, x in enumerate(tl):
    for keep_fore in (True, False):
        made = cut(keep_fore, x)
        for el in (30, 60):
            d = 1.35
            az = math.radians(180 + 35) if keep_fore else math.radians(35)  # look at the cut face
            e = math.radians(el)
            c = Vector((x, 0, 0)); p = c + Vector((math.cos(az) * math.cos(e), math.sin(az) * math.cos(e), math.sin(e))) * d
            cam.location = p; cam.rotation_euler = (c - p).to_track_quat('-Z', 'Y').to_euler()
            fn = '%s/C13_break_%s_%s_el%d.png' % (out, names[i].replace('-', ''), 'fore_piece_cut_face' if keep_fore else 'aft_piece_cut_face', el)
            sc.render.filepath = fn; bpy.ops.render.render(write_still=True); res.append(fn)
        for n in made: bpy.data.objects.remove(n, do_unlink=True)
print('\n'.join(res))
