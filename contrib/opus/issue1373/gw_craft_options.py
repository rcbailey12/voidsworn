# Issue 1373 (R362): three Glasswright strike craft options, built from the shared Glasswright kit (tools/blender/kits/ithar:
# pearl ribbons over a glowing stained-glass mosaic core, cut-lens drives), for Ryan to pick from pictures.
# Size: docs/playbooks/scale.md Squadron row: 1.6 long (drawn 3.84 on the board). +X bow, +Y port, +Z up.
# Ryan's craft rules that bind (R254, R259): space craft, not aircraft: no canopy, no swept aero wings, no tail fins, nothing
# hung under the hull. Glasswrights are a small elite fleet (Ryan, Nov 20): sleek, few, never a swarm.
#
#   V/bin/python contrib/opus/issue1373/gw_craft_options.py OUT [GF1,GF2,GF3] [--samples N]
import importlib.util
import math
import sys
from pathlib import Path

import bpy
from mathutils import Vector

ROOT = Path(__file__).resolve().parents[3]
LENGTH = 1.6
TAU = 2 * math.pi


def kitmod(name):
    key = 'ithar_' + name
    if key not in sys.modules:
        spec = importlib.util.spec_from_file_location(key, ROOT / 'tools/blender/kits/ithar' / (name + '.py'))
        mod = importlib.util.module_from_spec(spec)
        sys.modules[key] = mod
        spec.loader.exec_module(mod)
    return sys.modules[key]


P = kitmod('parts')
STACK = kitmod('stack')


class _Kit:
    MATS = {}


# ------------------------------------------------------------------------------------------------ the three designs
# Each design is a core surface core(x, a) (a: 0 port beam, pi/2 top), a list of ribbons, its lenses and its drive.

def spindle(hw, hh, x0, x1, bow_p=0.55, stern_p=0.45, flat=1.0):
    """a smooth spindle section function, widest between the ends"""
    def f(x, a):
        t = (x - x0) / (x1 - x0)          # 0 stern, 1 bow
        if t < 0.0 or t > 1.0:
            return (min(x1, max(x0, x)), 0.0, 0.0)   # outside the design's own length the core closes to its end point
        env = (math.sin(math.pi * t ** 0.9) ** (bow_p if t > 0.5 else stern_p))
        env = max(env, 0.10 if t < 0.5 else 0.0)  # a blunt stern face for the drive
        y = hw(t) * env * math.cos(a)
        s = math.sin(a)
        z = hh(t) * env * (s if s > 0 else s * flat)
        return (x, y, z)
    return f


def design(code):
    L = LENGTH
    x0, x1 = -0.5 * L, 0.5 * L
    if code == 'GF1':
        # The Needle: a slim spindle (about 5 to 1) wrapped in six long ribbons that twist together to one point at the bow,
        # like a drawn flame. One amber optic stone on the spine, one violet cut-lens drive at the stern.
        core = spindle(lambda t: 0.095 * L * (1 + 0.15 * math.sin(math.pi * t)), lambda t: 0.070 * L, x0, x1 + 0.02, bow_p=0.75)
        tw = lambda x: 0.9 * (x - x0) / L + 0.25 * math.sin(3.0 * x / L)
        ribs = [P.Ribbon(x0 + 0.02 * L, x1, (lambda x, k=k: 0.4 + k * TAU / 6 + tw(x)), P.leaf(0.7, 0.55, 0.4, 0.05),
                         (lambda t, v: 0.006 * L + 0.004 * L * (1 - abs(v)) * math.sin(math.pi * t)), f'rib{k}') for k in range(6)]
        half = 0.29
        for r in ribs:
            r.half = (lambda t, f=r.half: half * f(t))
        lenses = [((0.12 * L, 0.0, 0.070 * L * 0.97), (0, 0, 1), 0.020 * L, 0.012 * L, 'gw_gem_amber')]
        drives = [((x0 + 0.03 * L, 0.035 * L * math.cos(a), 0.030 * L * math.sin(a)), 0.026 * L) for a in (0.5, 2.6, 4.7)]
    elif code == 'GF2':
        # The Twin Lance: a short teardrop core with two pearl lances running forward either side of the bow (the Ark's
        # lances in small), the ribbons sweeping back off the lance roots like folded silk. Two drives.
        core = spindle(lambda t: 0.13 * L, lambda t: 0.075 * L, x0, x1 - 0.18 * L, bow_p=0.9, stern_p=0.5)
        tw = lambda x: 0.35 * math.sin(2.2 * (x - x0) / L)
        ribs = []
        for k in range(8):
            base = 0.2 + k * TAU / 8
            ribs.append(P.Ribbon(x0 + 0.03 * L, x1 - 0.20 * L, (lambda x, b=base: b + tw(x) * (1 if math.cos(b) > 0 else -1)),
                                 (lambda t: 0.20 * P.leaf(0.8, 0.5, 0.55, 0.25)(t)),
                                 (lambda t, v: 0.006 * L + 0.006 * L * max(0.0, v) * t), f'rib{k}'))
        lenses = [((-0.05 * L, 0.0, 0.075 * L * 0.96), (0, 0, 1), 0.018 * L, 0.010 * L, 'gw_gem_violet'),
                  ((0.10 * L, 0.0, 0.075 * L * 0.9), (0, 0, 1), 0.014 * L, 0.008 * L, 'gw_gem_green')]
        drives = [((x0 + 0.010 * L, s * 0.045 * L, 0.0), 0.032 * L) for s in (-1, 1)]
        lances = [((x1 - 0.32 * L, s * 0.075 * L, 0.0), (x1 + 0.06 * L, s * 0.040 * L, 0.012 * L), 0.022 * L) for s in (-1, 1)]
    else:
        # The Bud: a short plump seed (about 2.6 to 1) closed by broad overlapping pearl petals that curl up and open a
        # little at the stern, the mosaic glowing between them; one large amber lens at the bow, a violet drive ring astern.
        core = spindle(lambda t: 0.19 * L, lambda t: 0.13 * L, x0 + 0.08 * L, x1 - 0.04 * L, bow_p=0.6, stern_p=0.6)
        ribs = []
        for k in range(7):
            base = 0.3 + k * TAU / 7
            ribs.append(P.Ribbon(x0 + 0.10 * L, x1 - 0.10 * L, (lambda x, b=base: b + 0.25 * (x - x0) / L),
                                 (lambda t: 0.36 * P.leaf(0.6, 0.6, 0.5, 0.1)(t)),
                                 (lambda t, v: 0.006 * L + 0.030 * L * (1 - t) ** 2 * (0.5 + 0.5 * v)), f'rib{k}'))
        lenses = [((x1 - 0.05 * L, 0.0, 0.0), (1, 0, 0), 0.050 * L, 0.025 * L, 'gw_gem_amber')]
        drives = [((x0 + 0.085 * L, 0.0, 0.0), 0.060 * L)]
    return core, ribs, lenses, drives, (lances if code == 'GF2' else [])


# ------------------------------------------------------------------------------------------------ building
def mesh_object(name, verts, faces, mat, attrs=None, colors=None, smooth=True):
    me = bpy.data.meshes.new(name)
    me.from_pydata([tuple(v) for v in verts], [], faces)
    me.update()
    for k, vals in (attrs or {}).items():
        at = me.attributes.new(k, 'FLOAT', 'POINT')
        at.data.foreach_set('value', vals)
    for k, vals in (colors or {}).items():
        at = me.color_attributes.new(k, 'FLOAT_COLOR', 'POINT')
        flat = []
        for c in vals:
            flat += [c[0], c[1], c[2], 1.0]
        at.data.foreach_set('color', flat)
    if smooth:
        for p in me.polygons:
            p.use_smooth = True
    ob = bpy.data.objects.new(name, me)
    ob.data.materials.append(bpy.data.materials[mat])
    bpy.context.scene.collection.objects.link(ob)
    return ob


def build(code):
    core, ribs, lenses, drives, lances = design(code)
    L = LENGTH
    # the core: the glowing mosaic, tinted per vertex by which ribbon gap it sits in
    nu, nv = 140, 72
    xs = (-0.5 * L, 0.5 * L)
    verts, faces = P.Ribbon(xs[0], xs[1], lambda x: 0.0, lambda t: math.pi, lambda t, v: 0.0).mesh(
        lambda x, a: core(x, a), nu, nv)[:2]
    # mesh() above lays a full wrap (v -1..1 -> a -pi..pi); weld the seam by closing faces
    tints, glows = [], []
    nrib = len(ribs)

    def gaps(x, a):
        cs = sorted(((r.centre(x) % TAU), r) for r in ribs)
        a0 = a % TAU
        for i in range(nrib):
            c0 = cs[i][0]
            c1 = cs[(i + 1) % nrib][0] + (TAU if i == nrib - 1 else 0)
            aa = a0 if a0 >= c0 else a0 + TAU
            if c0 <= aa <= c1:
                return i, 3.0 * (x / L + 0.5) + 0.3 * i, (aa - c0) / max(1e-6, c1 - c0)
        return 0, 0.0, 0.5
    for i in range(nu + 1):
        x = xs[0] + (xs[1] - xs[0]) * i / nu
        for j in range(nv + 1):
            a = -math.pi + 2 * math.pi * j / nv
            rgb, g = P.mosaic_tint(x, a, gaps, STACK.PALETTE, STACK.WEIGHTS, seed=sum(map(ord, code)) % 7, tones=STACK.TONES)
            tints.append(rgb)
            glows.append(g)
    mesh_object(code + '_core', verts, faces, 'gw_mosaic', attrs=dict(gw_glow=glows), colors=dict(gw_tint=tints))
    for r in ribs:
        v, f, at = r.mesh(core, 120, 10)
        ob = mesh_object(code + '_' + r.name, v, f, 'gw_pearl', attrs=at)
        mod = ob.modifiers.new('thick', 'SOLIDIFY')
        mod.thickness = 0.006 * L
        mod.offset = 1.0
        for side in (-1, 1):
            e = r.edge(core, side, 120, 0.004 * L)
            tv, tf = tube(e, 0.0016 * L)
            mesh_object(f'{code}_{r.name}_edge{side}', tv, tf, 'gw_silver')
    for c, ax, rad, dep, mat in lenses:
        v, f = P.cut_lens(c, ax, rad, dep, 12)
        mesh_object(code + '_lens', v, f, mat, smooth=False)
    for root, tipp, rad in lances:
        a, b = Vector(root), Vector(tipp)
        pts = [a.lerp(b, i / 24) for i in range(25)]
        radii = [rad * (1 - i / 24) ** 0.8 + 0.0008 for i in range(25)]
        vv, ff = [], []
        for i, (p, r) in enumerate(zip(pts, radii)):
            for j in range(10):
                an = j * TAU / 10
                vv.append(p + Vector((0, r * math.cos(an), r * math.sin(an))))
        for i in range(24):
            for j in range(10):
                q0, q1 = i * 10 + j, i * 10 + (j + 1) % 10
                ff.append((q0, q1, q1 + 10, q0 + 10))
        mesh_object(code + '_lance', vv, ff, 'gw_lance')
        v, f = P.cut_lens(b, (1, 0, 0), 0.006 * LENGTH, 0.006 * LENGTH, 8)
        mesh_object(code + '_lance_tip', v, f, 'gw_tip', smooth=False)
    for c, rad in drives:
        v, f = P.cut_lens(c, (-1, 0, 0), rad, 0.4 * rad, 14)
        mesh_object(code + '_drive', v, f, 'gw_drive', smooth=False)
        v, f = P.cut_lens(Vector(c) + Vector((-0.002, 0, 0)), (-1, 0, 0), rad * 0.45, 0.6 * rad, 10)
        mesh_object(code + '_drive_core', v, f, 'gw_drive_core', smooth=False)


def tube(points, r, n=6):
    vv, ff = [], []
    pts = [Vector(p) for p in points]
    for i, p in enumerate(pts):
        d = (pts[min(i + 1, len(pts) - 1)] - pts[max(0, i - 1)])
        d = d.normalized() if d.length > 1e-9 else Vector((1, 0, 0))
        q = d.cross(Vector((0, 0, 1)))
        q = q.normalized() if q.length > 0.1 else d.cross(Vector((0, 1, 0))).normalized()
        w = d.cross(q).normalized()
        for j in range(n):
            a = j * TAU / n
            vv.append(p + r * (q * math.cos(a) + w * math.sin(a)))
    for i in range(len(pts) - 1):
        for j in range(n):
            a, b = i * n + j, i * n + (j + 1) % n
            ff.append((a, b, b + n, a + n))
    return vv, ff


# ------------------------------------------------------------------------------------------------ the review renders
def scene(samples):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    sc = bpy.context.scene
    sc.render.engine = 'CYCLES'
    sc.cycles.device = 'CPU'
    sc.cycles.samples = samples
    sc.cycles.use_denoising = True
    sc.view_settings.view_transform = 'AgX'
    sc.render.film_transparent = False
    w = bpy.data.worlds.new('w'); sc.world = w
    w.use_nodes = True
    # the camera sees the game's near-black sky; reflections see a soft studio sky, so the pearl reads as pearl
    nt = w.node_tree
    bg = nt.nodes['Background']
    bg.inputs[0].default_value = (0.06, 0.065, 0.085, 1)
    dark = nt.nodes.new('ShaderNodeBackground'); dark.inputs[0].default_value = (0.008, 0.009, 0.014, 1)
    lp = nt.nodes.new('ShaderNodeLightPath'); mix = nt.nodes.new('ShaderNodeMixShader')
    nt.links.new(lp.outputs['Is Camera Ray'], mix.inputs[0])
    nt.links.new(bg.outputs[0], mix.inputs[1]); nt.links.new(dark.outputs[0], mix.inputs[2])
    nt.links.new(mix.outputs[0], nt.nodes['World Output'].inputs[0])
    ad = bpy.data.lights.new('soft', 'AREA'); ad.energy = 25.0; ad.size = 3.0; ad.color = (0.95, 0.95, 1.0)
    ao = bpy.data.objects.new('soft', ad); sc.collection.objects.link(ao); ao.location = (0.3, 0.8, 2.2)
    ao.rotation_euler = (Vector((0, 0, 0)) - ao.location).to_track_quat('-Z', 'Y').to_euler()
    # the game's key and fill directions (godot/render/look.gd KEY_DIR, FILL_DIR), in Blender axes (Godot -Z = Blender +Y)
    for name, d, e, col in (('key', (-0.45, 0.55, -0.70), 2.0, (1.0, 0.96, 0.90)), ('fill', (0.6, -0.75, -0.2), 0.6, (0.55, 0.65, 0.85))):
        lt = bpy.data.lights.new(name, 'SUN'); lt.energy = e; lt.color = col
        ob = bpy.data.objects.new(name, lt); sc.collection.objects.link(ob)
        ob.rotation_euler = Vector(d).to_track_quat('-Z', 'Y').to_euler()
    STACK.setup(_Kit)
    # the kit's cells are sized for a 26-unit Ark (4.2 per unit); a 1.6-unit craft needs finer cells to keep the same read
    for n in bpy.data.materials['gw_mosaic'].node_tree.nodes:
        if n.bl_idname == 'ShaderNodeTexVoronoi':
            n.inputs['Scale'].default_value *= CELL_K
    return sc


CELL_K = 6.0


def camera(sc, loc, look, lens=50.0, ortho=None):
    cd = bpy.data.cameras.new('cam')
    if ortho:
        cd.type = 'ORTHO'; cd.ortho_scale = ortho
    else:
        cd.lens = lens
    ob = bpy.data.objects.new('cam', cd); sc.collection.objects.link(ob)
    ob.location = loc
    ob.rotation_euler = (Vector(look) - Vector(loc)).to_track_quat('-Z', 'Y').to_euler()
    sc.camera = ob
    return ob


def render(sc, path, w, h):
    sc.render.resolution_x, sc.render.resolution_y = w, h
    sc.render.filepath = str(path)
    bpy.ops.render.render(write_still=True)


def main():
    argv = sys.argv[sys.argv.index('--') + 1:] if '--' in sys.argv else sys.argv[1:]
    out = Path(argv[0]); out.mkdir(parents=True, exist_ok=True)
    codes = [a for a in argv[1:] if not a.startswith('--')] or ['GF1', 'GF2', 'GF3']
    samples = int(next((a.split('=')[1] for a in argv if a.startswith('--samples=')), 24))
    for code in codes:
        sc = scene(samples)
        build(code)
        L = LENGTH
        cam = camera(sc, (-0.95 * L, 1.15 * L, 0.75 * L), (0.02 * L, 0, -0.02 * L), lens=50)
        render(sc, out / f'{code}_threequarter.png', 1200, 800)
        cam.location = (0.0, 0.0, 3.0 * L)
        cam.rotation_euler = (0, 0, math.pi)
        cam.data.type = 'ORTHO'; cam.data.ortho_scale = 1.25 * L
        render(sc, out / f'{code}_top.png', 1000, 560)
        cam.location = (0.0, 3.0 * L, 0.0)
        cam.rotation_euler = (math.pi / 2, 0, math.pi)
        render(sc, out / f'{code}_side.png', 1000, 400)
        bpy.ops.wm.save_as_mainfile(filepath=str(out / f'{code}.blend'))


main()
