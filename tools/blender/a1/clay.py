# Clay renders for the A1 silhouette pick: one grey material, four views (3/4 above, side, front, 3/4 below).
# usage: python3 clay.py out_prefix model1.obj [model2.obj ...]   (OBJ in the game frame: x length with the bow at -x, y up, z lateral)
#    or: imported from a builder that has already filled the scene: clay.render_views(prefix)
import sys, os, math, bpy
from mathutils import Vector

def setup_scene():
    sc = bpy.context.scene
    sc.render.engine = 'CYCLES'; sc.cycles.device = 'CPU'; sc.cycles.samples = 24
    sc.cycles.use_denoising = True
    sc.render.resolution_x, sc.render.resolution_y = 900, 520
    sc.render.film_transparent = False
    w = bpy.data.worlds.new('w'); sc.world = w; w.use_nodes = True
    bg = w.node_tree.nodes['Background']; bg.inputs[0].default_value = (0.11, 0.115, 0.13, 1); bg.inputs[1].default_value = 0.9
    sc.view_settings.view_transform = 'Standard'
    for name, rot, en in (('key', (50, 0, 35), 3.2), ('fill', (65, 0, -140), 1.0), ('rim', (-40, 0, 170), 1.6)):
        L = bpy.data.lights.new(name, 'SUN'); L.energy = en; L.angle = math.radians(8)
        o = bpy.data.objects.new(name, L); o.rotation_euler = [math.radians(a) for a in rot]; sc.collection.objects.link(o)

def clay_mat():
    m = bpy.data.materials.get('clay') or bpy.data.materials.new('clay'); m.use_nodes = True
    b = m.node_tree.nodes['Principled BSDF']; b.inputs['Base Color'].default_value = (0.62, 0.6, 0.57, 1); b.inputs['Roughness'].default_value = 0.65
    return m

def import_obj(p):
    bpy.ops.wm.obj_import(filepath=p)  # default axes: game x stays x (bow at -x), game y (up) -> blender z
    return bpy.context.selected_objects

def bounds():
    mn = Vector((1e9,) * 3); mx = Vector((-1e9,) * 3)
    for o in bpy.context.scene.objects:
        if o.type != 'MESH' or o.hide_render: continue
        for c in o.bound_box:
            w = o.matrix_world @ Vector(c); mn = Vector(map(min, mn, w)); mx = Vector(map(max, mx, w))
    return mn, mx

def render_views(prefix, views=('q', 'side', 'front', 'below'), mat=None):
    sc = bpy.context.scene; m = mat or clay_mat()
    for o in sc.objects:
        if o.type == 'MESH':
            o.data.materials.clear(); o.data.materials.append(m)
    bpy.context.view_layer.update(); mn, mx = bounds(); c = (mn + mx) / 2; L = max((mx - mn).x, (mx - mn).y, (mx - mn).z)
    cam = bpy.data.objects.get('cam')
    if not cam:
        cam = bpy.data.objects.new('cam', bpy.data.cameras.new('cam')); sc.collection.objects.link(cam)
    sc.camera = cam; outs = []
    # bow is at -x; the 3/4 views look from the bow quarter, port side
    V = {'q': (Vector((-0.9, -1.1, 0.75)), 'PERSP'), 'side': (Vector((0, -1, 0)), 'ORTHO'), 'front': (Vector((-1, 0, 0)), 'ORTHO'),
         'below': (Vector((-0.8, -1.1, -0.5)), 'PERSP'), 'qp': (Vector((-0.9, 1.1, 0.75)), 'PERSP'), 'belowp': (Vector((-0.6, 1.1, -0.6)), 'PERSP'), 'top': (Vector((0, 0, 1)), 'ORTHO')}
    for v in views:
        d, kind = V[v]; d = d.normalized(); cam.data.type = kind
        if kind == 'ORTHO':
            ext = mx - mn
            if v == 'front': cam.data.ortho_scale = max(ext.y * 1.25, ext.z * 1.25 * sc.render.resolution_x / sc.render.resolution_y)  # fit width and height
            else: cam.data.ortho_scale = L * 1.12
            cam.location = c + d * L * 3
        else:
            cam.data.lens = 50; cam.location = c + d * L * 2.05
        if v == 'top': cam.rotation_euler = (0, 0, 0)  # looking straight down: bow left, port up
        else: cam.rotation_euler = (c - cam.location).to_track_quat('-Z', 'Y').to_euler()  # camera local Y is screen up
        cam.data.clip_end = L * 20; cam.data.clip_start = L * 0.01
        f = f'{prefix}_{v}.png'; sc.render.filepath = f; bpy.ops.render.render(write_still=True); outs.append(f)
    return outs

if __name__ == '__main__':
    a = sys.argv[sys.argv.index('--') + 1:] if '--' in sys.argv else sys.argv[1:]
    bpy.ops.wm.read_factory_settings(use_empty=True); setup_scene()
    for p in a[1:]:
        for o in import_obj(p):
            if os.environ.get('FLIP') == '1': o.rotation_euler.z += math.pi  # game files store the bow at +x; turn it to -x like the options
    print(render_views(a[0], views=('q', 'side', 'front', 'below', 'top')))
