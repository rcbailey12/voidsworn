# A2 max-detail ships: review renders in the manner of tools/blender/a1/clay.py (studio light, Cycles), in the Blender frame used by the
# a2detail scripts (bow +x, port -y, up +z). Two sets per ship:
#   views: side, three-quarter top, three-quarter below, close-up  (clay and painted)
#   sweep: the 9-cell blob sweep, bow / mid / stern each from the top, the side and below (orthographic crops)
import os, math
import bpy
from mathutils import Vector

FONT = '/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf'


def studio(sc, samples=24, res=(900, 520)):
    sc.render.engine = 'CYCLES'; sc.cycles.samples = samples; sc.cycles.use_denoising = True
    for k, v in (('max_bounces', 4), ('diffuse_bounces', 2), ('glossy_bounces', 2), ('transmission_bounces', 0), ('transparent_max_bounces', 2)):
        try: setattr(sc.cycles, k, v)
        except Exception: pass
    try: sc.cycles.denoiser = 'OPENIMAGEDENOISE'
    except Exception: pass
    sc.render.resolution_x, sc.render.resolution_y = res; sc.render.resolution_percentage = 100; sc.render.film_transparent = False
    w = bpy.data.worlds.new('w'); sc.world = w; w.use_nodes = True
    bg = w.node_tree.nodes['Background']; bg.inputs[0].default_value = (0.11, 0.115, 0.13, 1); bg.inputs[1].default_value = 0.9
    sc.view_settings.view_transform = 'Standard'
    try: sc.view_settings.look = 'None'
    except Exception: pass
    # the a1 rig, turned so the key light comes from the bow quarter above (bow is +x here, -x in clay.py)
    for name, rot, en in (('key', (50, 0, 215), 3.2), ('fill', (65, 0, 40), 1.0), ('rim', (-40, 0, -10), 1.6)):
        L = bpy.data.lights.new(name, 'SUN'); L.energy = en; L.angle = math.radians(8)
        o = bpy.data.objects.new(name, L); o.rotation_euler = [math.radians(a) for a in rot]; sc.collection.objects.link(o)


def clay_mat():
    m = bpy.data.materials.get('clay') or bpy.data.materials.new('clay'); m.use_nodes = True
    b = m.node_tree.nodes['Principled BSDF']; b.inputs['Base Color'].default_value = (0.62, 0.6, 0.57, 1); b.inputs['Roughness'].default_value = 0.65
    return m


def painted_mat(maps, uv='UV0', emit_gain=6.0):
    """maps: dict base, orm, normal, emissive -> image path"""
    m = bpy.data.materials.new('painted'); m.use_nodes = True; T = m.node_tree; L = T.links; b = T.nodes['Principled BSDF']
    uvn = T.nodes.new('ShaderNodeUVMap'); uvn.uv_map = uv
    def tex(p, data):
        t = T.nodes.new('ShaderNodeTexImage'); t.image = bpy.data.images.load(p, check_existing=True)
        if data: t.image.colorspace_settings.name = 'Non-Color'
        L.new(uvn.outputs[0], t.inputs[0]); return t
    if maps.get('base'): L.new(tex(maps['base'], False).outputs[0], b.inputs['Base Color'])
    if maps.get('orm'):
        s = T.nodes.new('ShaderNodeSeparateColor'); L.new(tex(maps['orm'], True).outputs[0], s.inputs[0])
        L.new(s.outputs[1], b.inputs['Roughness']); L.new(s.outputs[2], b.inputs['Metallic'])
        if maps.get('base'):  # studio stand-in for the engines' occlusion term
            mx = T.nodes.new('ShaderNodeMix'); mx.data_type = 'RGBA'; mx.blend_type = 'MULTIPLY'; mx.inputs['Factor'].default_value = .5  # occlusion only dims ambient in the engines
            L.new(b.inputs['Base Color'].links[0].from_socket, mx.inputs[6]); L.new(s.outputs[0], mx.inputs[7]); L.new(mx.outputs[2], b.inputs['Base Color'])
    if maps.get('normal'):
        nm = T.nodes.new('ShaderNodeNormalMap'); nm.uv_map = uv; L.new(tex(maps['normal'], True).outputs[0], nm.inputs['Color']); L.new(nm.outputs[0], b.inputs['Normal'])
    if maps.get('emissive'):
        L.new(tex(maps['emissive'], False).outputs[0], b.inputs['Emission Color']); b.inputs['Emission Strength'].default_value = emit_gain
    return m


def bounds(objs):
    mn = Vector((1e9,) * 3); mx = Vector((-1e9,) * 3)
    for o in objs:
        for c in o.bound_box:
            w = o.matrix_world @ Vector(c); mn = Vector(map(min, mn, w)); mx = Vector(map(max, mx, w))
    return mn, mx


def _cam(sc):
    cam = bpy.data.objects.get('cam')
    if not cam:
        cam = bpy.data.objects.new('cam', bpy.data.cameras.new('cam')); sc.collection.objects.link(cam)
    sc.camera = cam; return cam


def _shoot(sc, cam, loc, target, ortho=None, lens=50, path=None, rot=None):
    cam.location = loc; d = (target - loc)
    if ortho: cam.data.type = 'ORTHO'; cam.data.ortho_scale = ortho
    else: cam.data.type = 'PERSP'; cam.data.lens = lens
    cam.rotation_euler = rot if rot is not None else d.to_track_quat('-Z', 'Y').to_euler()
    cam.data.clip_start = .001; cam.data.clip_end = 100
    sc.render.filepath = path; bpy.ops.render.render(write_still=True); return path


def render_views(objs, prefix, mat=None, res=(760, 440)):
    sc = bpy.context.scene; sc.render.resolution_x, sc.render.resolution_y = res
    if mat is not None:
        for o in objs: o.data.materials.clear(); o.data.materials.append(mat)
    bpy.context.view_layer.update(); mn, mx = bounds(objs); c = (mn + mx) / 2; ext = mx - mn; Lm = max(ext)
    cam = _cam(sc); outs = {}
    asp = res[0] / res[1]
    outs['side'] = _shoot(sc, cam, c + Vector((0, -3 * Lm, 0)), c, ortho=max(ext.x * 1.08, ext.z * 1.15 * asp), path=f'{prefix}_side.png')
    outs['q'] = _shoot(sc, cam, c + Vector((0.9, -1.1, 0.75)).normalized() * Lm * 2.05, c, lens=50, path=f'{prefix}_q.png')
    outs['below'] = _shoot(sc, cam, c + Vector((0.8, -1.1, -0.5)).normalized() * Lm * 2.05, c, lens=50, path=f'{prefix}_below.png')
    tgt = Vector((c.x + ext.x * .18, c.y, c.z + ext.z * .12))  # close-up: forward half, upper flank
    outs['close'] = _shoot(sc, cam, tgt + Vector((0.55, -1.0, 0.45)).normalized() * Lm * .85, tgt, lens=50, path=f'{prefix}_close.png')
    return outs


def render_sweep(objs, prefix, mat=None, res=(512, 320)):
    sc = bpy.context.scene; sc.render.resolution_x, sc.render.resolution_y = res
    if mat is not None:
        for o in objs: o.data.materials.clear(); o.data.materials.append(mat)
    bpy.context.view_layer.update(); mn, mx = bounds(objs); ext = mx - mn; Lm = max(ext); cam = _cam(sc); outs = {}; asp = res[0] / res[1]
    for k, reg in enumerate(('stern', 'mid', 'bow')):  # x grows toward the bow
        x0 = mn.x + ext.x * k / 3; x1 = x0 + ext.x / 3; cx = (x0 + x1) / 2; seg = ext.x / 3 * 1.25
        # every view has the bow to the right: top (port up), side from port, below (port down)
        for v, d, rot in (('top', Vector((0, 0, 1)), (0, 0, 0)), ('side', Vector((0, -1, 0)), (math.pi / 2, 0, 0)), ('below', Vector((0, 0, -1)), (math.pi, 0, 0))):
            c = Vector((cx, (mn.y + mx.y) / 2, (mn.z + mx.z) / 2))
            span = ext.y if v != 'side' else ext.z
            outs[(reg, v)] = _shoot(sc, cam, c + d * Lm * 3, c, ortho=max(seg, span * 1.1 * asp), path=f'{prefix}_{reg}_{v}.png', rot=rot)
    return outs
