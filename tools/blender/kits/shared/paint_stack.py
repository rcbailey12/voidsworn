# The paint stack for ships built from a build sheet (issue 601; ships.md section 0 item 2, R96 Q1; RULEBOOK 0.9, R225).
# Shared plumbing only, no look of its own: every colour, amount, trim row and decal rule comes from the faction's stack
# (tools/blender/kits/<faction>/stack.py), written once per faction kit and used by every sheet ship of that faction (R218).
#
# What it does, in order, on the scene the build contract made (role hull, parts, interior; one material per object, named by
# the sheet's colour zone: soot, rust, iron, blood, ...):
#   1. unwraps the hull and the parts into two atlases (hull, parts), every island at one texel density inside its atlas;
#   2. bakes MASKS from the ship's own geometry into each atlas: R ambient occlusion at a short reach (cavities, corners),
#      G edges (the bevel normal against the face normal: every plate edge, rim and step), B ambient occlusion at a long reach
#      (where grime gathers: under decks, between parts). Parts occlude the hull and the hull the parts, as on the real ship;
#   3. builds one procedural material per (zone, atlas) from the faction stack's layers, every layer driven by those masks, the
#      world position and the face normal: module family, surface duty and a small local step, soot, rust and run-off, grime,
#      edge wear to bare metal, the faction's TRIM SHEET (rivet rows near plate edges, scuffs, grilles, tread, stripes; sampled
#      by box projection at ship scale, so a gun and a hull plate carry the same rivet and scuff density, R224) and DECALS
#      (placed by the faction's rules on the ship's own surfaces by ray cast, never painted by hand);
#   4. bakes albedo, ORM (occlusion, roughness, metal) and a detail normal for both atlases (rivets, wear and seams);
#   5. puts the textured materials on the ship (the recipe's export, stage 7, reads them), keeps glowing zones as their own
#      emissive surfaces and leaves the insides with the sheet's own materials.
# The concept picture is never projected onto the ship: colours may be sampled from it (the faction stack says where).
# Blender 4.5 on Ryan's PC and 5.x in the sandbox: no 5.x-only API is used.
import os, sys, math, json, time
HERE = os.path.dirname(os.path.abspath(__file__))
R209 = os.path.normpath(os.path.join(HERE, '..', '..', 'r209'))
if R209 not in sys.path: sys.path.insert(0, R209)
import bpy, bmesh
import numpy as np
from mathutils import Vector
from mathutils.bvhtree import BVHTree
from paint3 import node, math_, mixc, mulc, ramp
from cycles_devices import configure_cycles_device

INFO = {}


def srgb_lin(c):
    """an sRGB colour in 0..255 to linear 0..1"""
    c = np.asarray(c, np.float64) / 255.0
    return tuple(float(x) for x in np.where(c <= .04045, c / 12.92, ((c + .055) / 1.055) ** 2.4))


# ------------------------------------------------------------------------------------------------------------ objects and UVs
def split(scene=None):
    """the ship's mesh objects by job: hull (role hull), parts (any other outside role), glow (an emissive zone), interior"""
    sc = scene or bpy.context.scene
    H, P, G, I = [], [], [], []
    for o in sc.objects:
        if o.type != 'MESH': continue
        r = o.get('role')
        if r == 'interior': I.append(o); continue
        z = o.data.materials[0].name if o.data.materials else ''
        if o.get('emissive_zone') or z in GLOW_ZONES: G.append(o)
        elif r == 'hull': H.append(o)
        else: P.append(o)
    return H, P, G, I


GLOW_ZONES = set()      # filled by use(stack): the zones the faction stack keeps as glowing surfaces


def glow_zone(o, fallback='glow'):
    """The sheet's explicit zone wins over a private or copied material name."""
    return o.get('emissive_zone') or (o.data.materials[0].name if o.data.materials else fallback)


def unwrap(objs, margin):
    """one atlas for these objects: smart projection, islands packed together at one texel density"""
    bpy.ops.object.select_all(action='DESELECT')
    for o in objs:
        o.hide_set(False); o.select_set(True)
        if not o.data.uv_layers: o.data.uv_layers.new(name='UVMap')
    bpy.context.view_layer.objects.active = objs[0]
    bpy.ops.object.mode_set(mode='EDIT'); bpy.ops.mesh.select_all(action='SELECT')
    bpy.ops.uv.smart_project(angle_limit=math.radians(60), island_margin=margin)
    # a sheet hull is thousands of small islands (plates, steps, rivet heads): a second, tighter pack takes the atlas from about
    # a third used to more than half (issue 601, sandbox: hull 0.34 to 0.58 of the atlas at a margin of 0.0003)
    bpy.ops.uv.select_all(action='SELECT'); bpy.ops.uv.pack_islands(margin=margin, rotate=True)
    bpy.ops.object.mode_set(mode='OBJECT')


def part_module_tones(S, objs):
    """Pick a finish once per authored assembly, including its mount and turning pieces."""
    by_group = {}
    for o in objs:
        kind = o.get('part_kind')
        if kind:
            by_group.setdefault(o.get('grp', o.name), kind)
    return {
        o.name: S.MODULE_TONES[S.PART_FAMILIES.get(by_group.get(o.get('grp', o.name)), 'body')]
        for o in objs
    }


def bake_copy(objs, name, zone_by_kind=None, module_tones=None, plate_mesh=None):
    """one joined copy of these objects (same UVs and material slots, world space, no modifiers), so Cycles syncs the scene once
    per bake instead of once per object (round 6 lesson, bakeAb6.py); the originals are hidden from the render meanwhile"""
    cps = []
    for o in objs:
        c = o.copy(); c.data = o.data.copy(); bpy.context.scene.collection.objects.link(c)
        mw = o.matrix_world.copy(); c.parent = None; c.matrix_world = mw
        for md in list(c.modifiers): c.modifiers.remove(md)
        if module_tones is not None:
            tone = c.data.attributes.new('ps_module_tone', 'FLOAT', 'POINT')
            tone.data.foreach_set('value', np.full(len(c.data.vertices), module_tones[o.name], np.float32))
        if plate_mesh is not None and plate_mesh(o):
            plates = c.data.attributes.new('ps_authored_panels', 'FLOAT', 'POINT')
            plates.data.foreach_set('value', np.ones(len(c.data.vertices), np.float32))
        z = (zone_by_kind or {}).get((o.get('part_kind'), o.data.materials[0].name if o.data.materials else ''))
        if z:      # the faction stack gives this part kind its own zone (a launch bay mouth's warning stripes)
            ph = bpy.data.materials.get(z) or bpy.data.materials.new(z)
            for i in range(len(c.data.materials)): c.data.materials[i] = ph
        cps.append(c)
    bpy.ops.object.select_all(action='DESELECT')
    for c in cps: c.select_set(True)
    bpy.context.view_layer.objects.active = cps[0]; bpy.ops.object.join()
    j = bpy.context.view_layer.objects.active; j.name = name
    for k in list(j.keys()): del j[k]
    return j


def gpu(samples):
    sc = bpy.context.scene; sc.render.engine = 'CYCLES'; sc.cycles.samples = samples
    return configure_cycles_device(sc)


def new_image(name, res, colour=True, fill=(0, 0, 0, 1), float_buffer=False):
    im = bpy.data.images.get(name)
    if im: bpy.data.images.remove(im)
    im = bpy.data.images.new(name, res, res, alpha=False, float_buffer=float_buffer)
    im.colorspace_settings.name = 'sRGB' if colour else 'Non-Color'; im.generated_color = fill
    return im


def save(im, out, name):
    im.filepath_raw = os.path.join(out, name + '.png'); im.file_format = 'PNG'; im.save(); im.pack()


def np_image(name, arr, colour=True):
    """a Blender image from a numpy array (H, W, 4) in 0..1, row 0 at the top"""
    h, w = arr.shape[:2]
    im = bpy.data.images.get(name)
    if im: bpy.data.images.remove(im)
    im = bpy.data.images.new(name, w, h, alpha=True)
    im.colorspace_settings.name = 'sRGB' if colour else 'Non-Color'
    im.pixels.foreach_set(np.ascontiguousarray(arr[::-1]).astype(np.float32).ravel()); im.pack()
    return im


# ------------------------------------------------------------------------------------------------------------ shared node blocks
class Ctx:
    """the inputs every layer reads, made once per material: masks, position, normal and edge bands"""
    def __init__(self, nt, masks, scale, mirror=False):
        self.nt = nt
        tc = node(nt, 'ShaderNodeTexCoord'); geo = node(nt, 'ShaderNodeNewGeometry'); self.tc, self.geo = tc, geo
        uv = node(nt, 'ShaderNodeUVMap')
        mk = node(nt, 'ShaderNodeTexImage'); mk.image = masks; mk.interpolation = 'Linear'; nt.links.new(uv.outputs[0], mk.inputs[0])
        sp = node(nt, 'ShaderNodeSeparateColor'); nt.links.new(mk.outputs[0], sp.inputs[0])
        self.ao, self.edge, self.aol = sp.outputs[0], sp.outputs[1], sp.outputs[2]
        # wpos: the true ship position (decals, which sit on one side); pos: what every pattern reads. A stack that asks for a
        # mirrored paint (LAYERS mirror, issue 783: the Eclipse, "the paint actually is even on each side") folds the starboard
        # half onto the port, (x, |y|, z), so every noise, panel lattice and trim tile repeats mirrored across the centre line.
        self.wpos = tc.outputs['Object']; self.pos = self.wpos
        if mirror:
            s = node(nt, 'ShaderNodeSeparateXYZ'); nt.links.new(self.wpos, s.inputs[0])
            f = node(nt, 'ShaderNodeCombineXYZ'); nt.links.new(s.outputs[0], f.inputs[0]); nt.links.new(s.outputs[2], f.inputs[2])
            nt.links.new(math_(nt, 'ABSOLUTE', s.outputs[1]), f.inputs[1]); self.pos = f.outputs[0]
        xyz = node(nt, 'ShaderNodeSeparateXYZ'); nt.links.new(self.pos, xyz.inputs[0]); self.x, self.y, self.z = xyz.outputs[0], xyz.outputs[1], xyz.outputs[2]
        nz = node(nt, 'ShaderNodeSeparateXYZ'); nt.links.new(geo.outputs['Normal'], nz.inputs[0]); self.nz = nz.outputs[2]
        self.up = math_(nt, 'MAXIMUM', self.nz, 0)
        self.down = math_(nt, 'MAXIMUM', math_(nt, 'MULTIPLY', self.nz, -1), 0)
        self.side = math_(nt, 'SUBTRACT', 1, math_(nt, 'ABSOLUTE', self.nz))
        self.scale = scale
        self._edge_band = None

    def noise(self, scale, detail=3, rough=.5, stretch=None, w=0.0):
        nt = self.nt; v = self.pos
        if stretch:
            mp = node(nt, 'ShaderNodeMapping'); mp.inputs['Scale'].default_value = stretch; nt.links.new(self.pos, mp.inputs['Vector']); v = mp.outputs[0]
        n = node(nt, 'ShaderNodeTexNoise'); n.inputs['Scale'].default_value = scale; n.inputs['Detail'].default_value = detail
        n.inputs['Roughness'].default_value = rough
        if w:
            n.noise_dimensions = '4D'; n.inputs['W'].default_value = w
        nt.links.new(v, n.inputs['Vector']); return n.outputs['Fac']

    def bevel_edge(self, radius, gain):
        nt = self.nt
        bv = node(nt, 'ShaderNodeBevel', samples=6); bv.inputs['Radius'].default_value = radius
        dot = node(nt, 'ShaderNodeVectorMath', operation='DOT_PRODUCT'); nt.links.new(self.geo.outputs['Normal'], dot.inputs[0]); nt.links.new(bv.outputs['Normal'], dot.inputs[1])
        return math_(nt, 'MULTIPLY', math_(nt, 'SUBTRACT', 1, dot.outputs['Value']), gain, clamp=True)

    def edge_band(self, near, far):
        """a strip set back from every edge (between near and far, ship units): where rivet rows run along a plate's border"""
        if self._edge_band is None:
            wide = self.bevel_edge(far, 30.0); narrow = self.bevel_edge(near, 30.0)
            self._edge_band = math_(self.nt, 'SUBTRACT', wide, narrow, clamp=True)
        return self._edge_band

    def tile(self, image, size, aspect=1.0):
        """a trim tile sampled by box projection at a world size (ship units across one tile): the same size on every surface"""
        nt = self.nt
        mp = node(nt, 'ShaderNodeMapping'); mp.inputs['Scale'].default_value = (1.0 / size, 1.0 / (size / aspect), 1.0 / size)
        nt.links.new(self.pos, mp.inputs['Vector'])
        ti = node(nt, 'ShaderNodeTexImage'); ti.image = image; ti.projection = 'BOX'; ti.projection_blend = .25; ti.interpolation = 'Linear'
        nt.links.new(mp.outputs[0], ti.inputs['Vector'])
        return ti.outputs['Color'], ti.outputs['Alpha']


def decal_layer(c, col, height, rough, decals, atlas, cells, wear):
    """stamp every decal record onto this material: box projection on the record's own frame, clipped to its box, only on faces
    turned toward it; the paint wear eats into it (never fresh paint)"""
    nt = c.nt
    for d in decals:
        cpos, n, t, b, w, h, cell, a = d['pos'], d['n'], d['t'], d['b'], d['w'], d['h'], d['cell'], d.get('alpha', 1.0)
        rel = node(nt, 'ShaderNodeVectorMath', operation='SUBTRACT'); nt.links.new(c.wpos, rel.inputs[0]); rel.inputs[1].default_value = cpos
        def comp(axis, size):
            dp = node(nt, 'ShaderNodeVectorMath', operation='DOT_PRODUCT'); nt.links.new(rel.outputs[0], dp.inputs[0]); dp.inputs[1].default_value = axis
            return math_(nt, 'ADD', math_(nt, 'DIVIDE', dp.outputs['Value'], size), .5)
        u = comp(t, w); v = comp(b, h)
        dn = node(nt, 'ShaderNodeVectorMath', operation='DOT_PRODUCT'); nt.links.new(rel.outputs[0], dn.inputs[0]); dn.inputs[1].default_value = n
        depth = math_(nt, 'ABSOLUTE', dn.outputs['Value'])
        fn = node(nt, 'ShaderNodeVectorMath', operation='DOT_PRODUCT'); nt.links.new(c.geo.outputs['Normal'], fn.inputs[0]); fn.inputs[1].default_value = n
        inside = math_(nt, 'MULTIPLY', math_(nt, 'LESS_THAN', depth, d.get('depth', .02)), math_(nt, 'GREATER_THAN', fn.outputs['Value'], .55))
        for q in (u, v):
            inside = math_(nt, 'MULTIPLY', inside, math_(nt, 'MULTIPLY', math_(nt, 'GREATER_THAN', q, 0.0), math_(nt, 'LESS_THAN', q, 1.0)))
        cx, cy = cell % cells, cell // cells
        au = math_(nt, 'DIVIDE', math_(nt, 'ADD', math_(nt, 'MINIMUM', math_(nt, 'MAXIMUM', u, 0.0), 1.0), cx), cells)
        av = math_(nt, 'DIVIDE', math_(nt, 'ADD', math_(nt, 'MINIMUM', math_(nt, 'MAXIMUM', v, 0.0), 1.0), cells - 1 - cy), cells)
        cv = node(nt, 'ShaderNodeCombineXYZ'); nt.links.new(au, cv.inputs[0]); nt.links.new(av, cv.inputs[1])
        ti = node(nt, 'ShaderNodeTexImage'); ti.image = atlas; ti.extension = 'CLIP'; ti.interpolation = 'Linear'; nt.links.new(cv.outputs[0], ti.inputs['Vector'])
        m = math_(nt, 'MULTIPLY', math_(nt, 'MULTIPLY', inside, ti.outputs['Alpha']), a)
        m = math_(nt, 'MULTIPLY', m, math_(nt, 'SUBTRACT', 1, wear), clamp=True)
        col = mixc(nt, col, ti.outputs['Color'], m)
        rough = math_(nt, 'ADD', rough, math_(nt, 'MULTIPLY', m, -.08))
        height = math_(nt, 'ADD', height, math_(nt, 'MULTIPLY', m, .15))
    return col, height, rough


def _wn(nt, x, y, z):
    """white noise of three scalars (sockets or numbers): (value, r, g, b), each 0..1"""
    cv = node(nt, 'ShaderNodeCombineXYZ')
    for i, v in enumerate((x, y, z)):
        if isinstance(v, (int, float)): cv.inputs[i].default_value = v
        else: nt.links.new(v, cv.inputs[i])
    wn = node(nt, 'ShaderNodeTexWhiteNoise', noise_dimensions='3D'); nt.links.new(cv.outputs[0], wn.inputs['Vector'])
    sc = node(nt, 'ShaderNodeSeparateColor'); nt.links.new(wn.outputs['Color'], sc.inputs[0])
    return wn.outputs['Value'], sc.outputs[0], sc.outputs[1], sc.outputs[2]


def _warp(c, v, size, amp, seed):
    """a coordinate in cells whose cells are of uneven size: the cell count plus a slow 1D noise (amp small enough that it never
    turns back, so every cell is between about a third and three times the mean size)"""
    nt = c.nt; q = math_(nt, 'DIVIDE', v, size)
    n = node(nt, 'ShaderNodeTexNoise', noise_dimensions='1D'); n.inputs['Scale'].default_value = 1.0; n.inputs['Detail'].default_value = 0.0
    nt.links.new(math_(nt, 'ADD', math_(nt, 'MULTIPLY', q, .43), seed), n.inputs['W'])
    return math_(nt, 'ADD', q, math_(nt, 'MULTIPLY', math_(nt, 'SUBTRACT', n.outputs['Fac'], .5), 2 * amp))


def _grid_even(c, cell, seed, shift):
    """the even panel grid, for a stack that does not ask for the uneven one (no patch_warp in its LAYERS: Eclipse, and any clean,
    ordered faction, R243): rows (along z) each shifted along x and y by their own random amount, cells of the given size; returns
    (cell id vector, seam lines) in _grid's form. The node graph and its values are the pre-R240 grid's."""
    nt = c.nt; cx, cy, cz = cell
    off = node(nt, 'ShaderNodeVectorMath', operation='ADD'); nt.links.new(c.pos, off.inputs[0]); off.inputs[1].default_value = shift
    q = node(nt, 'ShaderNodeVectorMath', operation='DIVIDE'); nt.links.new(off.outputs[0], q.inputs[0]); q.inputs[1].default_value = (cx, cy, cz)
    sq = node(nt, 'ShaderNodeSeparateXYZ'); nt.links.new(q.outputs[0], sq.inputs[0])
    row = math_(nt, 'FLOOR', sq.outputs[2])
    rn = node(nt, 'ShaderNodeTexWhiteNoise', noise_dimensions='1D'); nt.links.new(math_(nt, 'ADD', row, seed), rn.inputs['W'])
    rc = node(nt, 'ShaderNodeSeparateColor'); nt.links.new(rn.outputs['Color'], rc.inputs[0])
    qx = math_(nt, 'ADD', sq.outputs[0], rc.outputs[0]); qy = math_(nt, 'ADD', sq.outputs[1], rc.outputs[1])
    cq = node(nt, 'ShaderNodeCombineXYZ'); nt.links.new(math_(nt, 'FLOOR', qx), cq.inputs[0]); nt.links.new(math_(nt, 'FLOOR', qy), cq.inputs[1])
    nt.links.new(math_(nt, 'ADD', row, seed), cq.inputs[2])
    lines = []
    for k, (qa, size) in enumerate(zip((qx, qy, sq.outputs[2]), cell)):
        f = math_(nt, 'FRACT', qa); lines.append((math_(nt, 'MULTIPLY', math_(nt, 'MINIMUM', f, math_(nt, 'SUBTRACT', 1, f)), size), k))
    return cq.outputs[0], lines


def _grid(c, cell, seed, shift, L):
    """one uneven panel grid in the ship frame (R240, RULEBOOK 0.5: patchwork never reads even or ordered). Every axis is warped
    (cells of uneven size, so no two rows or columns match); the z axis is cut into bands of a few rows whose edges step every
    few columns; the x columns shift per band and per strip of a few y cells; each x column shifts its y cells, and each (x, y)
    column its z rows, so no seam runs on across a face (a deck's cross seams break every strip, a flank's row seams at every
    column); a share of the cells is split
    once more at a random place along a random axis (two plates where one stood). Returns (cell id vector, seam lines), each seam
    line (distance to it in ship units, the axis it is measured along)."""
    if 'patch_warp' not in L:      # Board review of PR 682: the uneven grid is the Hullbreakers' opt-in, never every faction's
        return _grid_even(c, cell, seed, shift)
    nt = c.nt; cx, cy, cz = cell
    amp = L['patch_warp']; hb = L.get('patch_band', 2.3); share = L.get('patch_split', .55)
    off = node(nt, 'ShaderNodeVectorMath', operation='ADD'); nt.links.new(c.pos, off.inputs[0]); off.inputs[1].default_value = shift
    sq = node(nt, 'ShaderNodeSeparateXYZ'); nt.links.new(off.outputs[0], sq.inputs[0])
    wx = _warp(c, sq.outputs[0], cx, amp, seed + .1); wy = _warp(c, sq.outputs[1], cy, amp, seed + .2); wz = _warp(c, sq.outputs[2], cz, amp, seed + .3)
    # the bands step up and down every few columns (no flank seam runs the whole length); the x columns shift per band and per
    # strip of a few y cells (no deck cross seam runs the whole width)
    _, rb, _, _ = _wn(nt, math_(nt, 'FLOOR', math_(nt, 'DIVIDE', wx, 2.7)), seed, 3.0)
    bq = math_(nt, 'DIVIDE', math_(nt, 'ADD', wz, math_(nt, 'MULTIPLY', rb, hb)), hb); band = math_(nt, 'FLOOR', bq)
    _, r0, _, _ = _wn(nt, band, math_(nt, 'FLOOR', math_(nt, 'DIVIDE', wy, 1.9)), seed + 1.0)
    X = math_(nt, 'ADD', wx, r0); ix = math_(nt, 'FLOOR', X)
    _, _, g1, _ = _wn(nt, ix, band, seed + 2.0)
    Y = math_(nt, 'ADD', wy, g1); iy = math_(nt, 'FLOOR', Y)
    _, _, _, b2 = _wn(nt, ix, iy, math_(nt, 'ADD', band, seed * 3.0))
    Z = math_(nt, 'ADD', wz, b2); iz = math_(nt, 'FLOOR', Z)
    bx = math_(nt, 'ADD', ix, math_(nt, 'MULTIPLY', band, 17.13))
    v3, r3, g3, _ = _wn(nt, bx, iy, math_(nt, 'ADD', iz, seed + 5.0))
    on = math_(nt, 'LESS_THAN', v3, share); at = math_(nt, 'ADD', .28, math_(nt, 'MULTIPLY', g3, .44))
    ids, lines = [], []
    for k, (Q, size) in enumerate(((X, cx), (Y, cy), (Z, cz))):
        mk = math_(nt, 'MULTIPLY', on, math_(nt, 'MULTIPLY', math_(nt, 'GREATER_THAN', r3, k / 3.0 - 1e-4), math_(nt, 'LESS_THAN', r3, (k + 1) / 3.0)))
        f = math_(nt, 'FRACT', Q)
        ids.append(math_(nt, 'MULTIPLY', math_(nt, 'MULTIPLY', mk, math_(nt, 'GREATER_THAN', f, at)), .5))
        lines.append((math_(nt, 'MULTIPLY', math_(nt, 'MINIMUM', f, math_(nt, 'SUBTRACT', 1, f)), size), k))
        # the split line, only in a split cell (elsewhere pushed far away)
        d = math_(nt, 'MULTIPLY', math_(nt, 'ABSOLUTE', math_(nt, 'SUBTRACT', f, at)), size)
        lines.append((math_(nt, 'ADD', d, math_(nt, 'MULTIPLY', math_(nt, 'SUBTRACT', 1, mk), 10.0)), k))
    fb = math_(nt, 'FRACT', bq)
    lines.append((math_(nt, 'MULTIPLY', math_(nt, 'MINIMUM', fb, math_(nt, 'SUBTRACT', 1, fb)), cz * hb), 2))    # the band edges
    cq = node(nt, 'ShaderNodeCombineXYZ')
    nt.links.new(math_(nt, 'ADD', bx, ids[0]), cq.inputs[0]); nt.links.new(math_(nt, 'ADD', iy, ids[1]), cq.inputs[1])
    nt.links.new(math_(nt, 'ADD', math_(nt, 'ADD', iz, ids[2]), seed), cq.inputs[2])
    return cq.outputs[0], lines


def _seams(c, S, lines):
    """the panel borders on the face's own plane (a line measured along the face normal never draws a seam)"""
    nt = c.nt; L = S.LAYERS
    nrm = node(nt, 'ShaderNodeSeparateXYZ'); nt.links.new(c.geo.outputs['Normal'], nrm.inputs[0]); seam = None
    for d, k in lines:
        e = math_(nt, 'SUBTRACT', 1, ramp(nt, d, L['patch_seam'] * .4, L['patch_seam']))
        e = math_(nt, 'MULTIPLY', e, ramp(nt, math_(nt, 'SUBTRACT', 1, math_(nt, 'ABSOLUTE', nrm.outputs[k])), .35, .65))
        seam = e if seam is None else math_(nt, 'MAXIMUM', seam, e)
    return seam


def repair_cluster(c, cell_id):
    """Neighbouring salvage cells share a repair register within the authored shell section."""
    nt = c.nt
    ids = node(nt, 'ShaderNodeSeparateXYZ')
    nt.links.new(cell_id, ids.inputs[0])
    xyz = [math_(nt, 'FLOOR', math_(nt, 'DIVIDE', axis, 2)) for axis in ids.outputs]
    return _wn(nt, xyz[0], xyz[1], math_(nt, 'ADD', xyz[2], math_(nt, 'MULTIPLY', c.shell_module, 41.0)))


def patchwork(c, S, col, amount, families=None, cells=None):
    """the plate patchwork (R228, R240; RULEBOOK 0.5, tidy is a fault): two uneven panel grids of different sizes (_grid: no even
    row, no repeated cell, no row running on across a face), the region of each chosen by a broad noise, plus a sparse layer of
    larger patch plates laid over them. Hullbreaker colours follow those same seam cells and their repair clusters.
    Returns the colour and the seam mask."""
    if hasattr(S, 'panel_nodes'):
        return S.panel_nodes(c, col, amount, families, cells)
    nt = c.nt; L = S.LAYERS; families = families or S.PATCH_FAMILIES
    big, small, patch = cells or (L['patch_big'], L['patch_small'], L['patch_over'])
    region = ramp(nt, c.noise(L['patch_region'], 2), .42, .58)          # 0: big plates, 1: small plates
    ids = []; seam = None
    for k, (cell, seed, sh) in enumerate(((big, 11.0, (0, 0, 0)), (small, 37.0, (.013, .007, .005)))):
        cid, co = _grid(c, cell, seed, sh, L); sm = _seams(c, S, co)
        w = region if k else math_(nt, 'SUBTRACT', 1, region)
        ids.append((cid, w)); sm = math_(nt, 'MULTIPLY', sm, w)
        seam = sm if seam is None else math_(nt, 'ADD', seam, sm)
    def pick(cid, w, col, small=False):
        wn = node(nt, 'ShaderNodeTexWhiteNoise', noise_dimensions='3D'); nt.links.new(cid, wn.inputs['Vector'])
        cluster, _, _, _ = repair_cluster(c, cid)
        sp2 = node(nt, 'ShaderNodeSeparateColor'); nt.links.new(wn.outputs['Color'], sp2.inputs[0]); tone = sp2.outputs[1]
        grouped = math_(nt, 'LESS_THAN', sp2.outputs[2], .55)
        r = math_(nt, 'ADD', wn.outputs['Value'], math_(nt, 'MULTIPLY', grouped, math_(nt, 'SUBTRACT', cluster, wn.outputs['Value'])))
        lo = 0.0
        for fam_ in families:
            share, (flo, fhi) = fam_[0], fam_[1]
            hi = lo + share
            if len(fam_) > 2 and fam_[2] == 'small' and not small: lo = hi; continue
            m = math_(nt, 'MULTIPLY', math_(nt, 'GREATER_THAN', r, lo - 1e-4), math_(nt, 'LESS_THAN', r, hi))
            fam = mixc(nt, flo, fhi, math_(nt, 'ADD', math_(nt, 'MULTIPLY', tone, .75), math_(nt, 'MULTIPLY', c.noise(L['patch_scale'] * 3, 2), .25)))
            col = mixc(nt, col, fam, math_(nt, 'MULTIPLY', math_(nt, 'MULTIPLY', m, w), amount))
            lo = hi
        return col
    for k, (cid, w) in enumerate(ids): col = pick(cid, w, col, small=k == 1)
    # the overlaid patch plates: a sparse few larger plates, bolted over whatever is under them, with their own seam
    pid, pco = _grid(c, patch, 71.0, (.021, .011, .009), L)
    pw = node(nt, 'ShaderNodeTexWhiteNoise', noise_dimensions='3D'); nt.links.new(pid, pw.inputs['Vector'])
    on = math_(nt, 'LESS_THAN', pw.outputs['Value'], L['patch_over_share'])
    col = pick(pid, on, col)
    seam = math_(nt, 'MAXIMUM', math_(nt, 'MULTIPLY', seam, math_(nt, 'SUBTRACT', 1, on)), math_(nt, 'MULTIPLY', _seams(c, S, pco), on))
    return col, math_(nt, 'MULTIPLY', seam, amount, clamp=True)


def seam_limit(c, x, path):
    """Read the sheet's kinked plan seam as an x boundary at the current beam position."""
    if not path:
        return x
    nt = c.nt
    path = sorted(path, key=lambda point: point[1])
    low_y, high_y = path[0][1], path[-1][1]
    if high_y <= low_y:
        return x
    low_x = min(p[0] for p in path)
    span_x = max(p[0] for p in path) - low_x
    if span_x < 1e-6:
        return low_x
    along = math_(nt, 'DIVIDE', math_(nt, 'SUBTRACT', c.y, low_y), high_y - low_y)
    profile = node(nt, 'ShaderNodeValToRGB')
    nt.links.new(along, profile.inputs['Fac'])
    elements = profile.color_ramp.elements
    stops = [elements[0], elements[1]]
    for px, element in zip((path[0][0], path[-1][0]), stops):
        value = (px - low_x) / span_x
        element.color = (value, value, value, 1)
    for px, py in path[1:-1]:
        element = elements.new((py - low_y) / (high_y - low_y))
        value = (px - low_x) / span_x
        element.color = (value, value, value, 1)
    return math_(nt, 'ADD', low_x, math_(nt, 'MULTIPLY', profile.outputs['Color'], span_x))


def module_finish(c, S, zone, group, joints):
    """R318: choose a module family, then an authored finish for its surface duty."""
    nt = c.nt
    c.shell_module = 0.0
    tone = S.MODULE_TONES[S.HULL_FAMILIES[0]]
    for i, (joint, path) in enumerate(joints, 1):
        after = math_(nt, 'GREATER_THAN', c.x, seam_limit(c, joint, path))
        c.shell_module = math_(nt, 'ADD', c.shell_module, after)
        if group == 'H':
            families = S.HULL_FAMILIES
            step = S.MODULE_TONES[families[i % len(families)]] - S.MODULE_TONES[families[(i - 1) % len(families)]]
            if step:
                tone = math_(nt, 'ADD', tone, math_(nt, 'MULTIPLY', after, step))
    if group == 'P':
        attr = node(nt, 'ShaderNodeAttribute', attribute_type='GEOMETRY', attribute_name='ps_module_tone')
        tone = attr.outputs['Fac']
    z = S.ZONES[zone]
    duty = S.SURFACE_DUTIES[zone]
    base = getattr(S, 'PART_DUTY_TONES', {}).get(duty) if group == 'P' else None
    if base is None:
        base = tuple((a + b) / 2 for a, b in zip(z['lo'], z['hi']))
    rgb = node(nt, 'ShaderNodeRGB')
    rgb.outputs[0].default_value = (*base, 1.0)
    return mulc(nt, rgb.outputs[0], tone)


def zone_material(S, zone, group, masks, tiles, decals, decal_atlas, joints, *, base_image=None, normal_image=None):
    """the procedural material of one zone in one atlas (group 'H' hull, 'P' parts), from the faction stack S"""
    z = S.ZONES[zone]
    if base_image is not None:
        z = {**z, **getattr(S, 'LEGACY_COAT', {})}
    m = bpy.data.materials.new(f'ps_{zone}_{group}'); m.use_nodes = True; nt = m.node_tree; nt.nodes.clear()
    out = node(nt, 'ShaderNodeOutputMaterial'); bs = node(nt, 'ShaderNodeBsdfPrincipled'); nt.links.new(bs.outputs[0], out.inputs[0])
    c = Ctx(nt, masks, S.SCALE, mirror=S.LAYERS.get('mirror', False))
    L = S.LAYERS
    if base_image is None and hasattr(S, 'surface_layers'):
        # a stack that builds its own surface (PR 1083's hook; no module finish, no wear). Issue 1183: a fifth value, when the
        # stack gives one, is the zone's emission colour, baked to the hull's emission atlas (EMISSIVE_ATLAS)
        layers = S.surface_layers(c, zone, tiles)
        col, height, rough, metal = layers[:4]
        _emit_output(nt, layers[4] if len(layers) > 4 else None)
        return _zone_outputs(m, bs, c, S, zone, group, col, height, rough, metal)
    bare_roughness = L.get('bare_roughness')
    if base_image is None:
        col = module_finish(c, S, zone, group, joints)
    else:
        # A legacy atlas already carries its livery and the seams of its fitted pieces.
        # Keep that paint beneath the same satin coat, grime and exposed edge layers.
        col = atlas_colour(nt, base_image)
        legacy_panel_colour = getattr(S, 'legacy_panel_colour', None)
        if legacy_panel_colour is not None:
            col = legacy_panel_colour(c, col)
    seam = None
    # The ship-frame lattice belongs to the shell. A fitting already has
    # its own joints, edges and clearances in the built geometry.
    if base_image is None and group == 'H' and z.get('patchwork', 0) > 0:
        col, seam = patchwork(c, S, col, z['patchwork'])
    mottle = c.noise(L['mottle_scale'], 2)
    tone_range = z.get('mottle_range', L.get('mottle_range', .03))
    col = mulc(nt, col, math_(nt, 'ADD', 1 - tone_range / 2, math_(nt, 'MULTIPLY', mottle, tone_range)))
    col = mulc(nt, col, math_(nt, 'ADD', 1 - L['side_dark'], math_(nt, 'MULTIPLY', c.up, L['side_dark'])))
    grain = c.noise(L['grain_scale'], 2 if bare_roughness is not None else 4, .6)
    height = math_(nt, 'MULTIPLY', grain, L.get('grain', .05))
    rough_grain = grain if bare_roughness is not None else c.noise(L['grain_scale'], 2)
    rough = math_(nt, 'ADD', z.get('rough', L['rough']), math_(nt, 'MULTIPLY', rough_grain, L.get('rough_grain', .08)))
    if L.get('coat_roughness'):
        coat = ramp(nt, mottle, .34, .66)
        rough = math_(nt, 'ADD', rough, math_(nt, 'MULTIPLY', coat, L['coat_roughness']))
    metal = z.get('metal', L['metal'])
    wear_amt = z.get('wear', L['wear'])
    # 2. the trim sheet: scuffs everywhere, rivet rows set back from plate edges, the zone's own rows (grille, tread, stripes)
    sc_c, sc_a = c.tile(tiles['scuffs'], L['scuff_size'])
    scuff = math_(nt, 'MULTIPLY', sc_a, z.get('scuff', L['scuff']))
    col = mixc(nt, col, S.BARE, math_(nt, 'MULTIPLY', scuff, .55))
    height = math_(nt, 'ADD', height, math_(nt, 'MULTIPLY', scuff, -.25))
    if L.get('scuff_roughness'):
        rough = math_(nt, 'ADD', rough, math_(nt, 'MULTIPLY', scuff, L['scuff_roughness']))
    if z.get('rivets', L['rivets']):
        rv_c, rv_a = c.tile(tiles['rivets'], L['rivet_pitch'])
        band = c.edge_band(L['rivet_band'][0], L['rivet_band'][1])
        rv = math_(nt, 'MULTIPLY', rv_a, band, clamp=True)
        col = mixc(nt, col, mulc(nt, col, .45), math_(nt, 'MULTIPLY', rv, .6))
        height = math_(nt, 'ADD', height, math_(nt, 'MULTIPLY', rv, .9))
    for row in z.get('trim', ()):
        tc_, ta_ = c.tile(tiles[row], L['trim_size'].get(row, .02), aspect=L['trim_aspect'].get(row, 1.0))
        k = z.get('trim_amount', .9)
        col = mixc(nt, col, tc_, math_(nt, 'MULTIPLY', ta_, k))
        height = math_(nt, 'ADD', height, math_(nt, 'MULTIPLY', ta_, .5))
    # 3. rust: in the cavities, gathering under edges and running down the sides, in broad patches; never on a borrowed clean plate
    if z.get('rust', 0) > 0:
        streak = ramp(nt, c.noise(L['streak_scale'], 3, .55, stretch=(L['streak_stretch'], L['streak_stretch'], 1.0)), .50, .72)
        cav = math_(nt, 'SUBTRACT', 1, c.ao)
        r = math_(nt, 'ADD', math_(nt, 'MULTIPLY', cav, 1.6), math_(nt, 'MULTIPLY', math_(nt, 'MULTIPLY', streak, c.side), .9))
        # rust creeps out from under the plate edges and rivets (the edge band) and blooms in a few places, never in round spots
        bloom = ramp(nt, math_(nt, 'MULTIPLY', c.noise(L['rust_blot'], 5, .7), ramp(nt, c.noise(L['rust_blot'] * .25, 2), .45, .65)), .38, .55)
        r = math_(nt, 'ADD', r, math_(nt, 'MULTIPLY', math_(nt, 'MAXIMUM', bloom, math_(nt, 'MULTIPLY', c.edge_band(L['rivet_band'][0], L['rivet_band'][1]), .7)), .8))
        r = math_(nt, 'MULTIPLY', r, z['rust'], clamp=True)
        rcol = mixc(nt, S.RUST_DARK, S.RUST, ramp(nt, c.noise(L['rust_blot'] * 3, 3), .35, .7))
        col = mixc(nt, col, rcol, math_(nt, 'MULTIPLY', r, .85))
        rough = math_(nt, 'ADD', rough, math_(nt, 'MULTIPLY', r, .10))
        metal = math_(nt, 'MULTIPLY', math_(nt, 'SUBTRACT', 1, r), metal)
        height = math_(nt, 'ADD', height, math_(nt, 'MULTIPLY', r, .06))
    # 4. grime and soot: long-reach occlusion, the lower hull, downward faces, soot toward the engines (the faction runs dark)
    g = math_(nt, 'ADD', math_(nt, 'MULTIPLY', math_(nt, 'SUBTRACT', 1, c.aol), 1.4), math_(nt, 'MULTIPLY', c.down, .35))
    g = math_(nt, 'ADD', g, math_(nt, 'MULTIPLY', ramp(nt, c.z, L['grime_z'][1], L['grime_z'][0]), .35))
    g = math_(nt, 'ADD', g, math_(nt, 'MULTIPLY', ramp(nt, c.x, L['soot_x'][1], L['soot_x'][0]), L['soot_aft']))
    g = math_(nt, 'MULTIPLY', g, z.get('grime', L['grime']), clamp=True)
    col = mixc(nt, col, S.GRIME, math_(nt, 'MULTIPLY', g, .8))
    streaks = c.noise(L['streak_scale'] * .7, 2, .5, stretch=(30, 30, 1.6))
    run = math_(nt, 'MULTIPLY', math_(nt, 'MULTIPLY', ramp(nt, streaks, .55, .74), c.side), z.get('grime', L['grime']) * .5)
    if L.get('recess_streaks'):
        # Vertical tracks show strongly below overhangs and around vents.
        shelter = ramp(nt, c.aol, .97, .58)
        residue = math_(nt, 'MULTIPLY', run, shelter)
        run = math_(nt, 'ADD', run, math_(nt, 'MULTIPLY', residue, L['recess_streaks']))
        rough = math_(nt, 'ADD', rough, math_(nt, 'MULTIPLY', run, .30))
    col = mulc(nt, col, math_(nt, 'SUBTRACT', 1, run))
    cav = math_(nt, 'POWER', c.ao, L.get('cavity_pow', 1.0))
    ao_dark = L.get('parts_ao_dark', L['ao_dark']) if group == 'P' else L['ao_dark']
    col = mulc(nt, col, math_(nt, 'ADD', 1 - ao_dark, math_(nt, 'MULTIPLY', cav, ao_dark)))
    if L.get('cavity_roughness'):
        sheltered = math_(nt, 'SUBTRACT', 1, cav)
        rough = math_(nt, 'ADD', rough, math_(nt, 'MULTIPLY', sheltered, L['cavity_roughness']))
    if seam is not None:       # black seams between the panels
        seam_dark = L.get('seam_dark', .8)
        col = mulc(nt, col, math_(nt, 'SUBTRACT', 1, math_(nt, 'MULTIPLY', seam, seam_dark)))
        panel_height = math_(nt, 'MULTIPLY', seam, L.get('panel_relief', .5))
        panel_height.node.label = 'NORMAL_PATCHWORK_HEIGHT'
        height = math_(nt, 'SUBTRACT', height, panel_height)
        rough = math_(nt, 'ADD', rough, math_(nt, 'MULTIPLY', seam, .1))
    # 5. decals (hull atlas): before the wear, so the wear eats into them
    wear = math_(nt, 'MULTIPLY', math_(nt, 'MULTIPLY', c.edge, ramp(nt, c.noise(L['wear_scale'], 6, .6), L.get('wear_lo', .38), L.get('wear_hi', .62))), wear_amt)
    wear = math_(nt, 'MULTIPLY', wear, ramp(nt, c.noise(L['wear_patch'], 2), .30, .66), clamp=True)
    if bare_roughness is not None:
        wear = math_(nt, 'MULTIPLY', wear, cav)
    if z.get('handling_wear'):
        # The trim's scratches also polish exposed fittings such as collars
        # and rims. Short occlusion keeps them out of sheltered corners.
        handling = math_(nt, 'MULTIPLY', scuff, math_(nt, 'MULTIPLY', cav, z['handling_wear']))
        wear = math_(nt, 'MAXIMUM', wear, handling)
    if decals and decal_atlas is not None:
        col, height, rough = decal_layer(c, col, height, rough, decals, decal_atlas, S.DECAL_CELLS, math_(nt, 'ADD', math_(nt, 'MULTIPLY', scuff, .7), wear))
    # 6. edge wear to bare metal: broken up, only in some areas
    col = mixc(nt, col, S.BARE, wear)
    if bare_roughness is None:
        rough = math_(nt, 'SUBTRACT', rough, math_(nt, 'MULTIPLY', wear, .30))
    rough = math_(nt, 'MAXIMUM', math_(nt, 'MINIMUM', rough, 1.0), L.get('rough_floor', .05))
    if bare_roughness is not None:
        # Coat and exposed metal have separate finishes. The paint's
        # roughness floor still applies across broad panel faces.
        rough = math_(nt, 'ADD', rough, math_(nt, 'MULTIPLY', wear, math_(nt, 'SUBTRACT', bare_roughness, rough)))
    metal_gain = math_(nt, 'SUBTRACT', 1, metal) if bare_roughness is not None else .6
    metal = math_(nt, 'ADD', metal, math_(nt, 'MULTIPLY', wear, metal_gain), clamp=True)
    height = math_(nt, 'SUBTRACT', height, math_(nt, 'MULTIPLY', wear, .1))
    nt.links.new(col, bs.inputs['Base Color']); nt.links.new(rough, bs.inputs['Roughness'])
    if isinstance(metal, float): bs.inputs['Metallic'].default_value = metal
    else: nt.links.new(metal, bs.inputs['Metallic'])
    return _zone_outputs(m, bs, c, S, zone, group, col, height, rough, metal, normal_image)


def _emit_output(nt, colour):
    """issue 1183: the zone's emission, labelled EMIT for the emission atlas bake; black when the zone does not glow"""
    em = node(nt, 'ShaderNodeMix', data_type='RGBA'); em.label = 'EMIT'; em.inputs[0].default_value = 0
    em.inputs[6].default_value = (0, 0, 0, 1)
    if colour is not None:
        nt.links.new(colour, em.inputs[6])
    return em


def _zone_outputs(m, bs, c, S, zone, group, col, height, rough, metal, normal_image=None):
    nt = c.nt
    L = S.LAYERS
    if isinstance(col, tuple): col = mixc(nt, col, col, 0.0)
    nt.links.new(col, bs.inputs['Base Color'])
    if isinstance(rough, float): bs.inputs['Roughness'].default_value = rough
    else: nt.links.new(rough, bs.inputs['Roughness'])
    if isinstance(metal, float): bs.inputs['Metallic'].default_value = metal
    else: nt.links.new(metal, bs.inputs['Metallic'])
    # the detail normal: the layers' height through a bump at the trim's own scale
    bp = node(nt, 'ShaderNodeBump'); bp.inputs['Distance'].default_value = L['bump_distance']; bp.inputs['Strength'].default_value = L['bump_strength']
    if normal_image is not None:
        original_normal = node(nt, 'ShaderNodeNormalMap')
        original_normal.inputs['Strength'].default_value = getattr(S, 'LEGACY_COAT', {}).get(
            'normal_strength', S.ZONES[zone].get('normal_strength', 1.0))
        nt.links.new(atlas_colour(nt, normal_image), original_normal.inputs['Color'])
        nt.links.new(original_normal.outputs['Normal'], bp.inputs['Normal'])
    nt.links.new(height, bp.inputs['Height']); nt.links.new(bp.outputs['Normal'], bs.inputs['Normal'])
    # the bake's labelled outputs (paint3's names, so the same emit switch bakes them)
    orm = node(nt, 'ShaderNodeCombineColor'); orm.label = 'ORM'
    occ = math_(nt, 'MULTIPLY', c.ao, math_(nt, 'ADD', .5, math_(nt, 'MULTIPLY', c.aol, .5)))
    nt.links.new(occ, orm.inputs[0])
    if isinstance(rough, float): orm.inputs[1].default_value = rough
    else: nt.links.new(rough, orm.inputs[1])
    if isinstance(metal, float): orm.inputs[2].default_value = metal
    else: nt.links.new(metal, orm.inputs[2])
    alb = node(nt, 'ShaderNodeMix', data_type='RGBA'); alb.label = 'ALBEDO'; alb.inputs[0].default_value = 0; nt.links.new(col, alb.inputs[6])
    m['ps_zone'] = zone; m['ps_group'] = group
    # Only the trophy layer needs this repair. Other factions retain their
    # original bake path even if a later ship adds more nodes or decals.
    m['ps_height_bake'] = bool((getattr(S, 'TROPHY', None) or {}).get('share'))
    return m


def atlas_colour(nt, image):
    tex = node(nt, 'ShaderNodeTexImage'); tex.image = image
    nt.links.new(node(nt, 'ShaderNodeUVMap').outputs[0], tex.inputs[0])
    return tex.outputs['Color']


def mask_material(name, S):
    """the mask bake's shader: R short ambient occlusion, G edges, B long ambient occlusion, out through an emission"""
    L = S.LAYERS
    m = bpy.data.materials.new(name); m.use_nodes = True; nt = m.node_tree; nt.nodes.clear()
    out = node(nt, 'ShaderNodeOutputMaterial'); em = node(nt, 'ShaderNodeEmission'); nt.links.new(em.outputs[0], out.inputs[0])
    geo = node(nt, 'ShaderNodeNewGeometry')
    a1 = node(nt, 'ShaderNodeAmbientOcclusion', samples=16, only_local=False); a1.inputs['Distance'].default_value = L['ao_short']
    a2 = node(nt, 'ShaderNodeAmbientOcclusion', samples=16, only_local=False); a2.inputs['Distance'].default_value = L['ao_long']
    bv = node(nt, 'ShaderNodeBevel', samples=8); bv.inputs['Radius'].default_value = L['edge_radius']
    dot = node(nt, 'ShaderNodeVectorMath', operation='DOT_PRODUCT'); nt.links.new(geo.outputs['Normal'], dot.inputs[0]); nt.links.new(bv.outputs['Normal'], dot.inputs[1])
    e = math_(nt, 'MULTIPLY', math_(nt, 'SUBTRACT', 1, dot.outputs['Value']), L['edge_gain'], clamp=True)
    e = math_(nt, 'MULTIPLY', e, ramp(nt, a1.outputs['AO'], .45, .85))     # convex edges only: a concave corner is occluded
    cc = node(nt, 'ShaderNodeCombineColor'); nt.links.new(a1.outputs['AO'], cc.inputs[0]); nt.links.new(e, cc.inputs[1]); nt.links.new(a2.outputs['AO'], cc.inputs[2])
    nt.links.new(cc.outputs[0], em.inputs['Color']); em.inputs['Strength'].default_value = 1
    return m


def _emit_switch(m, which):
    nt = m.node_tree; out = next(n for n in nt.nodes if n.type == 'OUTPUT_MATERIAL')
    em = next((n for n in nt.nodes if n.type == 'EMISSION'), None) or nt.nodes.new('ShaderNodeEmission')
    bs = next(n for n in nt.nodes if n.type == 'BSDF_PRINCIPLED')
    for l in list(out.inputs[0].links): nt.links.remove(l)
    if which is None: nt.links.new(bs.outputs[0], out.inputs[0]); return
    src = next((n for n in nt.nodes if n.label == which), None)
    if src is None and which == 'EMIT':      # issue 1183: a zone with no emission bakes black into the emission atlas
        for l in list(em.inputs['Color'].links): nt.links.remove(l)
        em.inputs['Color'].default_value = (0, 0, 0, 1)
    else:
        nt.links.new(src.outputs[2] if which in ('ALBEDO', 'EMIT') else src.outputs[0], em.inputs['Color'])
    em.inputs['Strength'].default_value = 1
    nt.links.new(em.outputs[0], out.inputs[0])


def _target(mats, im):
    for m in mats:
        nt = m.node_tree; tn = next((n for n in nt.nodes if n.label == 'BAKE_TARGET'), None)
        if tn is None: tn = nt.nodes.new('ShaderNodeTexImage'); tn.label = 'BAKE_TARGET'
        tn.image = im; nt.nodes.active = tn


def bake(obj, kind, margin):
    sc = bpy.context.scene; rb = sc.render.bake
    rb.use_selected_to_active = False; rb.margin = margin; rb.target = 'IMAGE_TEXTURES'
    bpy.ops.object.select_all(action='DESELECT'); obj.select_set(True); bpy.context.view_layer.objects.active = obj
    t0 = time.time()
    if kind == 'NORMAL':
        # Compile only the existing normal. Large patchwork inputs are cut at
        # their labelled height term, baked per material to 16-bit PNG, then
        # sampled by a small UV graph. Rivets, wear and decals stay procedural.
        restore, temporary_nodes, temporary_images, height_links = [], [], [], []
        materials = {slot.material for slot in obj.material_slots if slot.material}
        old_clear = rb.use_clear
        try:
            for mat in sorted(materials, key=lambda m: m.name):
                nt = mat.node_tree
                bs = next(n for n in nt.nodes if n.type == 'BSDF_PRINCIPLED')
                out = next(n for n in nt.nodes if n.type == 'OUTPUT_MATERIAL')
                surface = out.inputs['Surface']; sources = [link.from_socket for link in surface.links]
                normal = [link.from_socket for link in bs.inputs['Normal'].links]
                pending = [socket.node for socket in normal]; ancestors = set(pending)
                while pending:
                    for socket in pending.pop().inputs:
                        for link in socket.links:
                            if link.from_node not in ancestors:
                                ancestors.add(link.from_node); pending.append(link.from_node)
                target = nt.nodes.active
                restore.append((mat, surface, sources, None, target, target.image, len(ancestors)))
            # 800 is a conservative routing budget measured against A20, not
            # a test of SVM validity. Simpler materials retain their old path.
            heavy = [item for item in restore if item[0].get('ps_height_bake', False) and item[-1] > 800]
            if heavy:
                # Leave every smaller ship's bake entirely on its original
                # surface, including Eclipse. Only a large input needs proxies.
                for index, item in enumerate(restore):
                    mat, surface, sources, _, target, atlas, count = item
                    nt = mat.node_tree
                    proxy = nt.nodes.new('ShaderNodeBsdfDiffuse'); temporary_nodes.append((nt, proxy))
                    bs = next(n for n in nt.nodes if n.type == 'BSDF_PRINCIPLED')
                    for link in bs.inputs['Normal'].links: nt.links.new(link.from_socket, proxy.inputs['Normal'])
                    nt.links.new(proxy.outputs[0], surface)
                    restore[index] = (mat, surface, sources, proxy, target, atlas, count)
                heavy = [item for item in restore if item[0].get('ps_height_bake', False) and item[-1] > 800]
                import tempfile
                from pathlib import Path
                directory = Path(tempfile.mkdtemp(prefix='voidsworn_normal_height_'))
                dummy = bpy.data.images.new('ps_height_inactive', 1, 1, alpha=False)
                temporary_images.append(dummy)
                emissions = {}
                for mat, surface, _, _, _, _, _ in restore:
                    emission = mat.node_tree.nodes.new('ShaderNodeEmission')
                    emissions[mat] = emission; temporary_nodes.append((mat.node_tree, emission))
                # Raw avoids display transforms. PNG is genuinely 16-bit and
                # is reloaded before the normal pass, so its precision is tested.
                writer = bpy.data.scenes.new('ps_height_writer')
                try:
                    writer.view_settings.view_transform = 'Raw'
                    settings = writer.render.image_settings
                    settings.file_format = 'PNG'; settings.color_mode = 'BW'; settings.color_depth = '16'
                    rows = []
                    for active in heavy:
                        mat, _, _, _, _, atlas, count = active
                        nt = mat.node_tree
                        cut = next((n for n in nt.nodes if n.label == 'NORMAL_PATCHWORK_HEIGHT'), None)
                        if cut is None: raise ValueError(mat.name + ': large normal input has no patchwork height cut')
                        source = cut.outputs[0]
                        destinations = [link.to_socket for link in source.links]
                        height = bpy.data.images.new('ps_patchwork_height', *atlas.size, alpha=False, float_buffer=True)
                        height.colorspace_settings.name = 'Non-Color'; temporary_images.append(height)
                        for other, surface, _, _, target, _, _ in restore:
                            emission = emissions[other]; tree = other.node_tree
                            for link in list(emission.inputs['Color'].links): tree.links.remove(link)
                            emission.inputs['Color'].default_value = (0, 0, 0, 1)
                            if other == mat: tree.links.new(source, emission.inputs['Color'])
                            target.image = height if other == mat else dummy
                            tree.links.new(emission.outputs[0], surface)
                        rb.use_clear = True
                        started = time.time(); bpy.ops.object.bake(type='EMIT')
                        path = directory / (mat.name + '_height16.png')
                        height.save_render(str(path), scene=writer)
                        with open(path, 'rb') as encoded:
                            if encoded.read(25)[24] != 16: raise ValueError('Patchwork height was not saved at 16 bits')
                        loaded = bpy.data.images.load(str(path), check_existing=False)
                        loaded.colorspace_settings.name = 'Non-Color'; temporary_images.append(loaded)
                        uv = nt.nodes.new('ShaderNodeUVMap'); temporary_nodes.append((nt, uv))
                        texture = nt.nodes.new('ShaderNodeTexImage'); temporary_nodes.append((nt, texture))
                        texture.image = loaded; texture.interpolation = 'Linear'; texture.extension = 'EXTEND'
                        nt.links.new(uv.outputs[0], texture.inputs['Vector'])
                        for destination in destinations:
                            height_links.append((nt, source, destination))
                            nt.links.new(texture.outputs['Color'], destination)
                        row = dict(material=mat.name, input_nodes=count, path=str(path), bits=16,
                                   seconds=round(time.time() - started, 1))
                        rows.append(row); print('NORMAL HEIGHT', row, flush=True)
                    INFO['normal_height_maps'] = rows
                finally:
                    bpy.data.scenes.remove(writer)
                for mat, surface, _, proxy, target, atlas, _ in restore:
                    target.image = atlas; mat.node_tree.links.new(proxy.outputs[0], surface)
            rb.use_clear = old_clear
            bpy.ops.object.bake(type='NORMAL', normal_space='TANGENT')
        finally:
            rb.use_clear = old_clear
            for nt, source, destination in height_links: nt.links.new(source, destination)
            for mat, surface, sources, _, target, atlas, _ in restore:
                target.image = atlas
                for link in list(surface.links): mat.node_tree.links.remove(link)
                for source in sources: mat.node_tree.links.new(source, surface)
            for nt, temporary in reversed(temporary_nodes): nt.nodes.remove(temporary)
            for temporary in temporary_images: bpy.data.images.remove(temporary)
    else: bpy.ops.object.bake(type=kind)
    return round(time.time() - t0, 1)


def textured(name, albedo, orm, normal=None):
    """the final atlas material (paint3.textured's layout, which the recipe's export reads): albedo, ORM, an optional normal"""
    from paint3 import textured as _t
    return _t(name, albedo, orm, normal)


def add_emission(m, image, strength=1.0):
    """issue 1183: the baked emission atlas on the final material, so the glTF export writes it as the emissiveTexture"""
    nt = m.node_tree; bs = nt.nodes['Principled BSDF']
    uv = next((n for n in nt.nodes if n.type == 'UVMAP'), None) or nt.nodes.new('ShaderNodeUVMap')
    te = nt.nodes.new('ShaderNodeTexImage'); te.image = image; nt.links.new(uv.outputs[0], te.inputs[0])
    nt.links.new(te.outputs[0], bs.inputs['Emission Color']); bs.inputs['Emission Strength'].default_value = strength
    m['ps_emission'] = 1


# ------------------------------------------------------------------------------------------------------------ decal placement
def place_decals(S, hull, others):
    """every decal rule of the faction stack placed on this ship's own surfaces: a ray from outside at the rule's station hits
    the hull (not a part) on a face turned the rule's way, with room for the decal; the rule's height band is searched for the
    flattest such spot. Returns the records the decal layer stamps, and a report."""
    dg = bpy.context.evaluated_depsgraph_get()
    def tree(objs):
        bm = bmesh.new()
        for o in objs:
            e = o.evaluated_get(dg); me = e.to_mesh(); t = bmesh.new(); t.from_mesh(me); t.transform(o.matrix_world)
            tm = bpy.data.meshes.new('_t'); t.to_mesh(tm); t.free(); bm.from_mesh(tm); bpy.data.meshes.remove(tm); e.to_mesh_clear()
        T = BVHTree.FromBMesh(bm); bm.free(); return T
    TH = tree(hull); TA = tree(hull + others)
    xs = [v for o in hull for v in (o.matrix_world @ Vector(b) for b in o.bound_box)]
    x0 = min(v.x for v in xs); x1 = max(v.x for v in xs); zt = max(v.z for v in xs); zb = min(v.z for v in xs)
    recs, rep = [], []
    for rule in S.DECALS:
        sides = rule.get('sides', ('port', 'stbd')) if rule['face'] == 'side' else ('top',)
        mirror = S.LAYERS.get('mirror', False); placed = {}
        for sd in sides:
            best = None
            if mirror and sd == 'stbd' and placed.get('port'):
                # issue 783: a mirrored paint puts the starboard mark where the port one went, mirrored, when the hull is there
                _, p_, n_ = placed['port']; p_ = Vector((p_.x, -p_.y, p_.z)); n_ = Vector((n_.x, -n_.y, n_.z))
                hit = TA.ray_cast(p_ + n_ * .05, -n_); hh = TH.ray_cast(p_ + n_ * .05, -n_)
                if hit[0] is not None and hh[0] is not None and (hit[0] - hh[0]).length < 1e-5 and (hh[0] - p_).length < .002:
                    best = (_room(TA, hh[0], n_, rule['w'], rule['h']), hh[0], n_)
            for fx in (() if best is not None else rule['x']):
                x = x1 - fx * (x1 - x0)
                if rule['face'] == 'side':
                    sy = 1 if sd == 'port' else -1
                    for fz in np.linspace(rule['z'][0], rule['z'][1], 9):
                        z = zb + fz * (zt - zb); o = Vector((x, sy * 2.0, z)); d = Vector((0, -sy, 0))
                        hit = TA.ray_cast(o, d); hh = TH.ray_cast(o, d)
                        if hit[0] is None or hh[0] is None or (hit[0] - hh[0]).length > 1e-5: continue
                        n = hh[1].normalized()
                        if n.y * sy < rule.get('min_facing', .8): continue
                        sc = _room(TA, hh[0], n, rule['w'], rule['h'])
                        if best is None or sc > best[0]: best = (sc, hh[0], n)
                else:
                    for fy in (rule.get('y', (0.0,))[:1] if mirror else rule.get('y', (0.0,))):     # mirrored: the centre line only
                        o = Vector((x, fy, zt + 1.0)); d = Vector((0, 0, -1))
                        hit = TA.ray_cast(o, d); hh = TH.ray_cast(o, d)
                        if hit[0] is None or hh[0] is None or (hit[0] - hh[0]).length > 1e-5: continue
                        n = hh[1].normalized()
                        if n.z < rule.get('min_facing', .85): continue
                        sc = _room(TA, hh[0], n, rule['w'], rule['h'])
                        if best is None or sc > best[0]: best = (sc, hh[0], n)
            if best is None or best[0] < rule.get('min_room', .7):
                rep.append(dict(rule=rule['name'], side=sd, placed=False, room=None if best is None else round(best[0], 2))); continue
            _, p, n = best; placed[sd] = best
            b = Vector((0, 0, 1)) if abs(n.z) < .7 else Vector((1, 0, 0))
            b = (b - n * b.dot(n)).normalized(); t = (-n).cross(b).normalized()      # text reads left to right to a viewer facing it
            recs.append(dict(name=rule['name'], pos=tuple(p), n=tuple(n), t=tuple(t), b=tuple(b), w=rule['w'], h=rule['h'], cell=rule['cell'],
                             alpha=rule.get('alpha', 1.0), depth=rule.get('depth', .02)))
            rep.append(dict(rule=rule['name'], side=sd, placed=True, pos=[round(v, 4) for v in p], room=round(best[0], 2)))
    return recs, rep


def _room(T, p, n, w, h):
    """the share of a decal's box that lies on one flat face: rays from just outside its corners and edge midpoints land within
    a small distance of the centre's plane"""
    b = Vector((0, 0, 1)) if abs(n.z) < .7 else Vector((1, 0, 0)); b = (b - n * b.dot(n)).normalized(); t = n.cross(b).normalized()
    ok = tot = 0
    for su in (-.5, 0, .5):
        for sv in (-.5, 0, .5):
            q = p + t * (su * w) + b * (sv * h); hit = T.ray_cast(q + n * .02, -n)
            tot += 1
            if hit[0] is not None and abs((hit[0] - p).dot(n)) < .004 and hit[1].dot(n) > .9: ok += 1
    return ok / tot


# ------------------------------------------------------------------------------------------------------------ running lights
def _box(name, centre, t, b, n, w, h, d, mat, role, grp, back=.0003):
    """a flat box on a surface frame (t across, b up, n out): its front d out from centre, its back `back` behind it"""
    bm = bmesh.new(); vs = []
    for k in (0, 1):
        for sv in (-1, 1):
            for su in (-1, 1):
                vs.append(bm.verts.new(centre + t * (su * w / 2) + b * (sv * h / 2) + n * (d if k else -back)))
    for f in ((0, 1, 3, 2), (4, 6, 7, 5), (0, 4, 5, 1), (2, 3, 7, 6), (0, 2, 6, 4), (1, 5, 7, 3)):
        bm.faces.new([vs[i] for i in f])
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    me = bpy.data.meshes.new(name); bm.to_mesh(me); bm.free()
    m = bpy.data.materials.get(mat) or bpy.data.materials.new(mat); me.materials.append(m)
    o = bpy.data.objects.new(name, me); bpy.context.scene.collection.objects.link(o)
    o['role'] = role; o['grp'] = grp; o['part_kind'] = 'lamp'; o['machine'] = 0; o['inside'] = False
    return o


def _disc(name, centre, t, b, n, r, d, mat, role, grp, back=.0003, sides=12):
    """a short round lamp on a surface frame: front face d out from centre, back `back` behind it"""
    bm = bmesh.new(); rings = []
    for off in (-back, d):
        rings.append([bm.verts.new(centre + n * off + (t * math.cos(2 * math.pi * k / sides) + b * math.sin(2 * math.pi * k / sides)) * r)
                      for k in range(sides)])
    bm.faces.new(rings[1]); bm.faces.new(list(reversed(rings[0])))
    for k in range(sides):
        k2 = (k + 1) % sides; bm.faces.new((rings[0][k], rings[0][k2], rings[1][k2], rings[1][k]))
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    me = bpy.data.meshes.new(name); bm.to_mesh(me); bm.free()
    m = bpy.data.materials.get(mat) or bpy.data.materials.new(mat); me.materials.append(m)
    o = bpy.data.objects.new(name, me); bpy.context.scene.collection.objects.link(o)
    o['role'] = role; o['grp'] = grp; o['part_kind'] = 'lamp'; o['machine'] = 0; o['inside'] = False
    return o


def add_running_lights(S, hull, others, decals):
    """the faction's running lights, by its rule (S.RUNNING_LIGHTS), on this ship's own hull: each lens at least the light size
    rule across (px on a 70 px ship, the ship one unit long), a flank row at the sheet's lamp height and a few deck-edge points,
    each on a hull face with room, clear of every part, of the decals and of the breach, braking and boarding points. Returns the
    report (count, size in px, where)."""
    R = S.RUNNING_LIGHTS
    Lw = float(bpy.context.scene.get('r209_length_world', 0) or 0)
    if 'length_frac' in R: h = w = R['length_frac']              # a lamp sized to the ship (the ship is one unit long here)
    elif 'world' in R and Lw > 0: h = w = R['world'] / Lw
    elif 'px' in R: h = R['px'] / 70.0; w = h * R.get('aspect', 1.0)
    else: raise ValueError('RUNNING_LIGHTS needs length_frac, world (with the ship length) or px')     # Muse NOTE 7 on PR 610
    dg = bpy.context.evaluated_depsgraph_get()
    def tree(objs):
        bm = bmesh.new()
        for o in objs:
            e = o.evaluated_get(dg); me = e.to_mesh(); t = bmesh.new(); t.from_mesh(me); t.transform(o.matrix_world)
            tm = bpy.data.meshes.new('_t'); t.to_mesh(tm); t.free(); bm.from_mesh(tm); bpy.data.meshes.remove(tm); e.to_mesh_clear()
        T = BVHTree.FromBMesh(bm); bm.free(); return T
    TH = tree(hull); TA = tree(hull + others)
    mach = [o for o in others if o.get('machine')]
    TM = tree(mach) if mach else None
    xs = [v for o in hull for v in (o.matrix_world @ Vector(b) for b in o.bound_box)]
    x0 = min(v.x for v in xs); x1 = max(v.x for v in xs); zt = max(v.z for v in xs); zb = min(v.z for v in xs)
    keep = [Vector(p['pos']) for p in json.loads(bpy.context.scene.get('r209_points', '[]')) if p['kind'] in ('breach', 'rcs', 'board')]
    keep_d = [Vector(d['pos']) for d in decals]
    lamps = [o for o in others if o.get('part_kind') == 'lamp']
    def clear(p):
        if TM is not None and R.get('clear_machines'):     # never on a machine or the hull right under one (a turret's barbette)
            q = TM.find_nearest(p)
            if q[0] is not None and q[3] < R['clear_machines'] + w / 2: return False
        return all((p - k).length > R['clear_points'] for k in keep) and all((p - k).length > R['clear_decals'] for k in keep_d)
    made = []; rep = []
    def seat(p, n):
        """a light bridges the plate steps under it: every ray over its frame must land on the hull (not a part) on a face
        turned out; the frame's back reaches the deepest of them, its front sits proud of the highest (never floating)"""
        b = Vector((0, 0, 1)) if abs(n.z) < .7 else Vector((1, 0, 0)); b = (b - n * b.dot(n)).normalized(); t = n.cross(b).normalized()
        fr = 1 + R['frame']; ds = []
        for su in (-.5, 0, .5):
            for sv in (-.5, 0, .5):
                q = p + t * (su * w * fr) + b * (sv * h * fr) + n * .05
                a_ = TA.ray_cast(q, -n); h_ = TH.ray_cast(q, -n)
                if a_[0] is None or h_[0] is None or (a_[0] - h_[0]).length > 1e-5 or h_[1].dot(n) < .6: return None
                ds.append((h_[0] - p).dot(n))
        if max(ds) - min(ds) > R.get('max_step', .010): return None
        return t, b, max(ds), max(ds) - min(ds)
    def place(p, n, tag):
        st = seat(p, n)
        if st is None: return False
        t, b, top, spread = st; c = p + n * top
        g = f'RL{len(made) // 2}'; fr = 1 + R['frame']
        if R.get('round'):
            made.append(_disc(g + '_mount_iron', c, t, b, n, w * fr / 2, R['proud'] * .6, 'iron', 'mount', g, back=spread + .0006))
            made.append(_disc(g + '_body_light', c, t, b, n, w / 2, R['proud'], 'light', 'body', g))
        else:
            made.append(_box(g + '_mount_iron', c, t, b, n, w * fr, h * fr, R['proud'] * .6, 'iron', 'mount', g, back=spread + .0006))
            made.append(_box(g + '_body_light', c, t, b, n, w, h, R['proud'], 'light', 'body', g))
        rep.append(dict(at=tag, pos=[round(v, 4) for v in c], bridge=round(spread, 4))); return True
    for sy in (1, -1):
        cy = lambda o: sum((o.matrix_world @ Vector(c)).y for c in o.bound_box) / 8      # noqa: E731 (the contract bakes transforms in)
        mine = [o for o in lamps if (cy(o) > 0) == (sy > 0)]
        zs = [sum((o.matrix_world @ Vector(c)).z for c in o.bound_box) / 8 for o in mine]
        zrow = sorted(zs)[len(zs) // 2] if zs else None
        fx = R['flank']['x'][0]
        while fx <= R['flank']['x'][1] + 1e-9:
            x = x1 - fx * (x1 - x0)
            cands = [zrow + dz * h for dz in (0, 1.3, -1.3, 2.6, -2.6, 3.9, -3.9, 5.2)] if zrow is not None else \
                [zb + f * (zt - zb) for f in np.linspace(R['flank']['z_band'][0], R['flank']['z_band'][1], 5)]
            placed = False
            for z, dx in [(z, dx) for dx in (0, .25, -.25, .45, -.45) for z in cands]:
                if placed: break
                o = Vector((x + dx * R['flank']['step'], sy * 2.0, z)); d = Vector((0, -sy, 0))
                hit = TA.ray_cast(o, d); hh = TH.ray_cast(o, d)
                if hit[0] is None or hh[0] is None or (hit[0] - hh[0]).length > 1e-5: continue
                n = hh[1].normalized()
                if n.y * sy < .75 or not clear(hh[0]): continue
                placed = place(hh[0], n, 'port flank' if sy > 0 else 'starboard flank')
            fx += R['flank']['step']
        for fx in R['deck']['x']:
            x = x1 - fx * (x1 - x0)
            # the deck edge: the outermost up-facing hull deck at this station, then step in from it until a light seats
            edge = None; zdeck = None
            for y in np.linspace(.01, .25, 49):    # walk out across the top deck; its edge is where the deck level drops away
                hh = TH.ray_cast(Vector((x, sy * y, zt + 1.0)), Vector((0, 0, -1)))
                if hh[0] is None: break
                if hh[1].z <= .85: continue
                if zdeck is None: zdeck = hh[0].z
                if abs(hh[0].z - zdeck) > .008: break
                edge = sy * y
            ys = [] if edge is None else [edge - sy * R['deck']['inset'] * k for k in np.linspace(1, 6, 11)]
            for y in ys:
                o = Vector((x, y, zt + 1.0)); hit = TA.ray_cast(o, Vector((0, 0, -1))); hh = TH.ray_cast(o, Vector((0, 0, -1)))
                if hit[0] is None or hh[0] is None or (hit[0] - hh[0]).length > 1e-5: continue
                n = hh[1].normalized()
                if n.z < .85 or not clear(hh[0]): continue
                if place(hh[0], n, 'port deck edge' if sy > 0 else 'starboard deck edge'): break
    return made, dict(count=len(made) // 2, px=round(min(w, h) * 70.0, 2), lens=[round(w, 4), round(h, 4)], lens_world=round(min(w, h) * Lw, 3),
                      rule=R, where=rep)


# ------------------------------------------------------------------------------------------------------------ engine glow
def bake_engine_glow(S, objs, out, cell, res, samples):
    """the engine throat glow (Ryan, Nov 12 19:16 CST: "more variation to the engine glow so it's not so uniform, just disc
    color"): each engine's throat disc and bell lining get an emission map, a hot core grading out to deeper red and orange,
    uneven hot spots and soot streaks across the throat, the lining dark toward the lip. R308: engines on one ship share
    colour, strength, core reach and a pattern scaled to their own radius. The game's moving plume sits on top; this paints no flame. Per vertex the stack
    writes, in the colour attribute ps_glow: R the distance from the engine's axis over the throat radius, G the engine's own
    shared random, B the depth into the bell (1 at the throat, 0 at the lip), A the angle round the axis.
    ps_glow_pos stores normalized bell coordinates, so translated and larger bells get the same hot spots."""
    E = S.ENGINE_GLOW; groups = {}; ek = E.get('kind'); extra = []
    for o in objs:
        if ek is not None and o.get('part_kind') != ek and o.get('emissive_zone') != 'plug':
            extra.append(o); continue        # issue 642: a stack's other lights (the Eclipse rim lines and core) share the map
        groups.setdefault(o.get('grp') or o.name.split('_')[0], []).append(o)
    for o in extra: S.glow_vertex(o)
    rnd = float(np.random.default_rng(601).random())
    for gname, members in sorted(groups.items()):
        W = [o.matrix_world @ v.co for o in members for v in o.data.vertices]
        disc = [o for o in members if glow_zone(o) in E.get('disc', ('glow',))]
        core = disc + [o for o in members if o.get('emissive_zone') == 'plug']      # the throat disc and the plug: the core's surfaces
        Dv = [o.matrix_world @ v.co for o in (disc or members) for v in o.data.vertices]
        cy = (min(v.y for v in Dv) + max(v.y for v in Dv)) / 2
        cz = (min(v.z for v in Dv) + max(v.z for v in Dv)) / 2
        rmax = max(math.hypot(v.y - cy, v.z - cz) for v in Dv) or 1.0
        x0 = min(v.x for v in W); x1 = max(v.x for v in W)
        for o in members:
            me = o.data; ca = me.color_attributes.get('ps_glow') or me.color_attributes.new('ps_glow', 'FLOAT_COLOR', 'POINT')
            pos = me.color_attributes.get('ps_glow_pos') or me.color_attributes.new('ps_glow_pos', 'FLOAT_COLOR', 'POINT')
            is_disc = o in core
            for i, v in enumerate(me.vertices):
                w = o.matrix_world @ v.co
                r = min(1.0, math.hypot(w.y - cy, w.z - cz) / rmax) if is_disc else 1.0
                d = 1.0 if is_disc else (w.x - x0) / max(x1 - x0, 1e-6)
                dy, dz = w.y - cy, w.z - cz
                ang = 0.0 if math.hypot(dy, dz) < rmax * 1e-7 else (math.atan2(dz, dy) / (2 * math.pi)) % 1.0
                ca.data[i].color = (r, rnd, d, ang)
                pos.data[i].color = ((w.y - cy) / rmax * .025, (w.z - cz) / rmax * .025, d * .025, 1.0)
    for o in objs: o.hide_render = False
    unwrap(objs, .004)
    J = bake_copy(objs, f'{cell}_E_bake'); hid = {o.name: o.hide_render for o in objs}
    for o in objs: o.hide_render = True
    m = bpy.data.materials.new('ps_engine_glow_bake'); m.use_nodes = True; nt = m.node_tree; nt.nodes.clear()
    outn = node(nt, 'ShaderNodeOutputMaterial'); em = node(nt, 'ShaderNodeEmission'); nt.links.new(em.outputs[0], outn.inputs[0])
    at = node(nt, 'ShaderNodeAttribute'); at.attribute_type = 'GEOMETRY'; at.attribute_name = 'ps_glow'
    sp = node(nt, 'ShaderNodeSeparateColor'); nt.links.new(at.outputs['Color'], sp.inputs[0])
    r, e, d, a = sp.outputs[0], sp.outputs[1], sp.outputs[2], at.outputs['Alpha']
    tc = node(nt, 'ShaderNodeTexCoord')
    def noise(vec, scale, detail=3, rough=.6):
        n = node(nt, 'ShaderNodeTexNoise'); n.inputs['Scale'].default_value = scale; n.inputs['Detail'].default_value = detail
        n.inputs['Roughness'].default_value = rough; nt.links.new(vec, n.inputs['Vector']); return n.outputs['Fac']
    if hasattr(S, 'engine_glow_nodes'):     # issue 642: a faction whose engine is not a hot throat (the Eclipse ring) draws its own
        kn = node(nt, 'ShaderNodeAttribute'); kn.attribute_type = 'GEOMETRY'; kn.attribute_name = 'ps_kind'
        col = S.engine_glow_nodes(nt, r, e, d, a, tc, dict(node=node, math_=math_, ramp=ramp, mixc=mixc, mulc=mulc, noise=noise, kind=kn.outputs['Fac']))
    else:
        col = _throat_glow(nt, E, r, e, d, a, tc, noise)
    nt.links.new(col, em.inputs['Color']); em.inputs['Strength'].default_value = 1
    for i in range(len(J.material_slots)): J.material_slots[i].material = m
    im = new_image(f'{cell}_engine_emission', res, colour=True); _target([m], im)
    INFO['bake_engine_glow_s'] = bake(J, 'EMIT', 4); save(im, out, im.name)
    for o in objs: o.hide_render = hid[o.name]
    bpy.data.objects.remove(J)
    g = bpy.data.materials.new('p3_glow'); g.use_nodes = True; gt = g.node_tree; b = gt.nodes['Principled BSDF']
    uv = gt.nodes.new('ShaderNodeUVMap'); ti = gt.nodes.new('ShaderNodeTexImage'); ti.image = im; gt.links.new(uv.outputs[0], ti.inputs[0])
    gt.links.new(ti.outputs[0], b.inputs['Emission Color']); b.inputs['Emission Strength'].default_value = E['strength']
    b.inputs['Base Color'].default_value = (*E.get('base', (.03, .012, .006)), 1); b.inputs['Roughness'].default_value = .85
    INFO['engine_glow'] = dict(engines=len(groups), map=im.name + '.png', res=res)
    return g


def _throat_glow(nt, E, r, e, d, a, tc, noise):
    """the Hullbreaker throat (issue 601): a hot core on the axis grading out to deep red, hot spots, soot streaks, the lining
    dark toward the lip; returns the emission colour socket"""
    # heat: the core (hot at the axis) on the throat disc, the lining by its depth (dark at the lip, R228 item 5)
    # the core: hottest on the axis, falling off toward the wall with the ship's shared core reach
    e2 = math_(nt, 'FRACT', math_(nt, 'MULTIPLY', e, 7.31))
    reach = math_(nt, 'ADD', E['core_reach'][0], math_(nt, 'MULTIPLY', e2, E['core_reach'][1] - E['core_reach'][0]))
    corev = math_(nt, 'POWER', math_(nt, 'SUBTRACT', 1, ramp(nt, r, 0.0, 1.0)), reach)
    lining = math_(nt, 'MULTIPLY', ramp(nt, r, .98, 1.0), math_(nt, 'MULTIPLY', math_(nt, 'POWER', d, E['lining_falloff']), E['lining_gain']))
    heat = math_(nt, 'ADD', math_(nt, 'MULTIPLY', corev, math_(nt, 'SUBTRACT', 1, ramp(nt, r, .98, 1.0))), lining)
    # Uneven hot spots in normalized bell coordinates, with the same pattern on every engine.
    hn = node(nt, 'ShaderNodeTexNoise'); hn.noise_dimensions = '4D'; hn.inputs['Scale'].default_value = E['hotspot_scale']
    hn.inputs['Detail'].default_value = 4; hn.inputs['Roughness'].default_value = .6
    local = node(nt, 'ShaderNodeAttribute'); local.attribute_type = 'GEOMETRY'; local.attribute_name = 'ps_glow_pos'
    nt.links.new(local.outputs['Color'], hn.inputs['Vector']); nt.links.new(math_(nt, 'MULTIPLY', e, 13.0), hn.inputs['W'])
    hs = ramp(nt, hn.outputs['Fac'], E['hotspot'][0], E['hotspot'][1])
    heat = math_(nt, 'ADD', heat, math_(nt, 'MULTIPLY', math_(nt, 'MULTIPLY', hs, d), E['hotspot_gain']))
    av = node(nt, 'ShaderNodeCombineXYZ'); nt.links.new(math_(nt, 'MULTIPLY', a, E['streaks']), av.inputs[0]); nt.links.new(math_(nt, 'MULTIPLY', e, 31.0), av.inputs[1])
    nt.links.new(math_(nt, 'MULTIPLY', r, 1.5), av.inputs[2])
    soot = ramp(nt, noise(av.outputs[0], 1.0, 2, .5), E['soot'][0], E['soot'][1])
    heat = math_(nt, 'MULTIPLY', heat, math_(nt, 'SUBTRACT', 1, math_(nt, 'MULTIPLY', soot, E['soot_gain'])), clamp=True)
    # One brightness and hue for every engine, driven by the shared ship random.
    heat = math_(nt, 'MULTIPLY', heat, math_(nt, 'ADD', E['bright'][0], math_(nt, 'MULTIPLY', e, E['bright'][1] - E['bright'][0])))
    cr = node(nt, 'ShaderNodeValToRGB')
    for i_, (pos, col) in enumerate(E['ramp']):
        el = cr.color_ramp.elements[i_] if i_ < 2 else cr.color_ramp.elements.new(pos)
        el.position = pos; el.color = (*col, 1)
    hue = math_(nt, 'ADD', heat, math_(nt, 'MULTIPLY', math_(nt, 'SUBTRACT', e, .5), E['hue_shift']))
    nt.links.new(math_(nt, 'MINIMUM', math_(nt, 'MAXIMUM', hue, 0.0), 1.0), cr.inputs[0])
    return mixc(nt, (0, 0, 0), cr.outputs[0], ramp(nt, heat, 0.0, .25))


# ------------------------------------------------------------------------------------------------------------ the whole stack
def use(S):
    GLOW_ZONES.clear(); GLOW_ZONES.update(S.GLOW)


def run(S, out, cell, res, parts_res, samples, textures_dir=None):
    """paint the ship in the current scene with the faction stack S; returns the report dict"""
    t0 = time.time(); use(S)
    H, P, G, I = split()
    INFO.update(hull_objects=len(H), part_objects=len(P), glow_objects=len(G), interior_objects=len(I), device=gpu(samples), samples=samples)
    for o in H + P + G: o.hide_render = False
    # the trim sheet and decal atlas: the faction's own art, written into the job's textures folder with its licence line
    trim_rows, decal_arr = S.trim_sheet(), S.decal_atlas()
    tiles = {k: np_image(f'{cell}_trim_{k}', v, colour=True) for k, v in trim_rows.items()}
    datlas = np_image(f'{cell}_decals', decal_arr, colour=True)
    if textures_dir:
        os.makedirs(textures_dir, exist_ok=True)
        lic = S.write_textures(textures_dir, trim_rows, decal_arr)
        INFO['textures'] = lic
    decals, drep = place_decals(S, H, P); INFO['decals'] = drep
    if getattr(S, 'RUNNING_LIGHTS', None):       # the faction's running lights, by its rule (before the atlases: their frames are parts)
        made, lrep = add_running_lights(S, H, P, decals); INFO['running_lights'] = lrep
        json.dump(dict(lights={'running': dict(px=lrep['px'], count=lrep['count'], point=True, world=lrep['lens_world'],
                                               source='measured: the lens size the stack built, on a 70 px ship; point lights (R228 item 4): brightness, not size, carries the read')}),
                  open(os.path.join(out, 'lights.json'), 'w'), indent=1)
        H, P, G, I = split()
    if hasattr(S, 'ENGINE_GLOW'):    # the engine's plug cone glows with the throat (it sits where the core is): out of the parts atlas
        # issue 651: only a lit engine's plug glows (its group has a throat or lining, glow or ember); a cold spare bell keeps its dark
        lit = {o.get('grp') for o in G if o.get('part_kind') == 'engine'}
        plug = [o for o in P if o.get('part_kind') == 'engine' and o.get('grp') in lit and o.data.materials and o.data.materials[0].name in S.ENGINE_GLOW.get('plug', ())]
        for o in plug: o['emissive_zone'] = 'plug'
        P = [o for o in P if o not in plug]; G = G + plug
    unwrap(H, .0003); unwrap(P, .0004)
    scene = bpy.context.scene
    if hasattr(S, 'paint_joints'):
        joints = [(x, None) for x in sorted(S.paint_joints())]
    else:
        cuts = scene.get('r209_t_lines', ())
        paths = json.loads(scene.get('r209_t_paths', 'null')) or [None] * len(cuts)
        joints = list(zip(cuts, paths))
    maps = {}
    for group, objs, R in (('H', H, res), ('P', P, parts_res)):
        tones = part_module_tones(S, objs) if group == 'P' and not hasattr(S, 'surface_layers') else None
        plate_mesh = getattr(S, 'authored_panel_mesh', None) if group == 'H' else None
        J = bake_copy(objs, f'{cell}_{group}_bake', getattr(S, 'ZONE_BY_KIND', None), tones, plate_mesh)
        hid = {o.name: o.hide_render for o in objs}
        for o in objs: o.hide_render = True
        for o in I: o.hide_render = True
        mm = mask_material(f'ps_mask_{group}', S)
        zones = [s.material.name if s.material else 'soot' for s in J.material_slots]
        for i in range(len(J.material_slots)): J.material_slots[i].material = mm
        masks = new_image(f'{cell}_{group}_masks', R, colour=False, fill=(1, 0, 1, 1))
        _target([mm], masks); INFO[f'bake_{group}_masks_s'] = bake(J, 'EMIT', 8); save(masks, out, f'{cell}_{"hull" if group == "H" else "parts"}_masks')
        mats = {}
        for i, z in enumerate(zones):
            zz = z if z in S.ZONES else S.FALLBACK
            if zz not in mats: mats[zz] = zone_material(S, zz, group, masks, tiles, decals if group == 'H' else (), datlas, joints)
            J.material_slots[i].material = mats[zz]
        ml = list(mats.values()); imgs = {}
        kinds = [('albedo', True), ('orm', False)]
        if group == 'H' and getattr(S, 'EMISSIVE_ATLAS', False):
            kinds.append(('emission', True))      # issue 1183: the hull's own glow (the Glasswright mosaic), opt-in
        for kind, cs in kinds:
            im = new_image(f'{cell}_{"hull" if group == "H" else "parts"}_{kind}', R, colour=cs)
            _target(ml, im)
            for m in ml: _emit_switch(m, {'albedo': 'ALBEDO', 'orm': 'ORM', 'emission': 'EMIT'}[kind])
            INFO[f'bake_{group}_{kind}_s'] = bake(J, 'EMIT', 8); save(im, out, im.name); imgs[kind] = im
        for m in ml: _emit_switch(m, None)
        atlas = 'hull' if group == 'H' else 'parts'
        im = new_image(f'{cell}_{atlas}_normal', R, colour=False, fill=(.5, .5, 1, 1))
        _target(ml, im); INFO[f'bake_{group}_normal_s'] = bake(J, 'NORMAL', 8); save(im, out, im.name); imgs['normal'] = im
        maps[group] = imgs
        for o in objs: o.hide_render = hid[o.name]
        bpy.data.objects.remove(J)
        INFO[f'zones_{group}'] = sorted(mats)
    HM = textured(f'{cell}_hull_mat', maps['H']['albedo'], maps['H']['orm'], maps['H']['normal'])
    PM = textured(f'{cell}_parts_mat', maps['P']['albedo'], maps['P']['orm'], maps['P']['normal'])
    if 'emission' in maps['H']:
        add_emission(HM, maps['H']['emission'], getattr(S, 'EMISSIVE_STRENGTH', 1.0))
    if getattr(S, 'AUTHORED_LOOK', False):
        for material in (HM, PM):
            material['authored_look'] = 1
    # issue 601: these surfaces carry the stack's own roughness; the game gives them the soft rim light (godot/render/look.gd RIM
    # soft), not the full specular that flared white on them at the close cameras. glTF writes it as the material's extras.
    if getattr(S, 'SOFT_RIM', True):
        for M_ in (HM, PM): M_['rim_soft'] = 1
    for objs, M in ((H, HM), (P, PM)):
        for o in objs:
            o.data.materials.clear(); o.data.materials.append(M); o.data.polygons.foreach_set('material_index', np.zeros(len(o.data.polygons), np.int32))
    glow = {}
    # the engine glow's surfaces: the zones the stack names (default the throat and lining, glow and ember), only on the part kind
    # it names when it names one (issue 642: the Eclipse engine ring is the corona zone, which is also every shade rim's line)
    ez = S.ENGINE_GLOW.get('zones', ('glow', 'ember')) if hasattr(S, 'ENGINE_GLOW') else (); ek = S.ENGINE_GLOW.get('kind') if hasattr(S, 'ENGINE_GLOW') else None
    ex = S.ENGINE_GLOW.get('extra_zones', ()) if hasattr(S, 'ENGINE_GLOW') else ()      # issue 642: lights of any part kind on the same map
    eng = [o for o in G if (glow_zone(o) in ez and (ek is None or o.get('part_kind') == ek))
           or glow_zone(o) in ex or o.get('emissive_zone') == 'plug'] if hasattr(S, 'ENGINE_GLOW') else []
    if eng:      # the engine throats and linings: one surface, its own emission map (graded, hot spots, soot, each engine its own)
        glow['engine'] = bake_engine_glow(S, eng, out, cell, max(256, int(res * S.ENGINE_GLOW.get('res_frac', .25))), samples); glow['engine']['rim_soft'] = 1
        hull_glow = getattr(S, 'GLOW_HULL', ())
        if hull_glow:
            # One emission image, separate materials: only the hull's own listed trim is exempt from breach clearance.
            # The engine rings, core and lens keep the unmarked material even when they use that same image.
            trim = [o for o in eng if o.get('role') == 'hull' and glow_zone(o) in hull_glow]
            if trim:
                glow['engine_hull'] = glow['engine'].copy(); glow['engine_hull'].name = 'p3_glow_hull'
                glow['engine_hull']['hull_surface'] = 1
        else:
            trim = []
        for o in eng:
            o.data.materials.clear(); o.data.materials.append(glow['engine_hull'] if o in trim else glow['engine'])
    for o in G:
        if o in eng: continue
        z = glow_zone(o)
        # issue 642: a glow zone the stack lists in GLOW_HULL that the sheet puts on the hull itself (the Eclipse corona line on a
        # shade rim) is hull trim, not a part: its own material, marked hull_surface, so the export check measures breach
        # clearance from the parts and not from the hull's own rim line
        k = (z, 'hull') if o.get('role') == 'hull' and z in getattr(S, 'GLOW_HULL', ()) else z
        if k not in glow: glow[k] = S.glow_material(z, hull=True) if isinstance(k, tuple) else S.glow_material(z)
        o.data.materials.clear(); o.data.materials.append(glow[k])
    for o in I: o.hide_render = False
    INFO['glow_materials'] = sorted(m.name for m in glow.values())
    # the insides: an inside seen from outside (an opening, a gap) reads as the dark inner liner, never a sheet room colour (R99 Q1;
    # Ryan, Nov 12 16:32 CST: "a white square near the back and another white square underneath")
    if hasattr(S, 'inside_material'):
        inside = {}
        for o in I:
            for i, sl in enumerate(o.material_slots):
                z = sl.material.name if sl.material else 'room'
                if z not in inside: inside[z] = S.inside_material(z)
                o.material_slots[i].material = inside[z]
        INFO['inside_materials'] = sorted(m.name for m in inside.values())
    INFO['texel_density'] = texel_density(H, P, res, parts_res)
    INFO['stack_seconds'] = round(time.time() - t0, 1)
    return INFO


def bake_existing_atlas(S, source, out, samples):
    """Bake finish onto the installed A4 UVs, keeping their paint and relief as inputs."""
    code = source.stem
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=str(source), merge_vertices=True)
    scene = bpy.context.scene
    geometry = [obj for obj in scene.objects if obj.type == 'MESH']
    expected = {f'{code}_hull'}
    if not geometry or any(not obj.data.uv_layers or {m.name for m in obj.data.materials if m} != expected
                           for obj in geometry):
        raise ValueError(f'{code}: expected the single textured A4 exterior atlas')
    paint_mesh = getattr(S, 'legacy_paint_mesh', None)
    exterior = geometry if paint_mesh is None else [obj for obj in geometry if paint_mesh(obj)]
    if not exterior:
        raise ValueError(f'{code}: no intact exterior meshes to paint')
    device = gpu(samples)
    print(f'[paint] {code}: {device}, {samples} samples', flush=True)
    images = {}
    for kind in ('base', 'orm', 'normal'):
        image = bpy.data.images.load(str(source.with_name(f'{code}_{kind}.jpg')))
        if kind != 'base':
            image.colorspace_settings.name = 'Non-Color'
        if image.size[0] < 1 or image.size[0] != image.size[1]:
            raise ValueError(f'{code}: invalid {kind} atlas size {tuple(image.size)}')
        images[kind] = image

    atlas = bake_copy(exterior, code + '_finish')
    for obj in geometry:
        obj.hide_render = True
    mask = mask_material('ps_existing_mask', S)
    atlas.data.materials[0] = mask
    resolution = max(im.size[0] for im in images.values())
    masks = new_image(code + '_mask', resolution, colour=False, fill=(1, 0, 1, 1))
    _target([mask], masks)
    scene.render.bake.use_clear = True
    bake(atlas, 'EMIT', 8)

    tiles = {name: np_image(code + '_trim_' + name, pixels) for name, pixels in S.trim_sheet().items()}
    material = zone_material(S, S.LEGACY_FINISH_ZONE, 'H', masks, tiles, (), None, (),
                             base_image=images['base'], normal_image=images['normal'])
    atlas.data.materials[0] = material
    scene.render.bake.use_clear = False
    out.mkdir(parents=True, exist_ok=True)
    for kind, label in (('base', 'ALBEDO'), ('orm', 'ORM'), ('normal', None)):
        original = images[kind]
        image = new_image(code + '_coated_' + kind, original.size[0], colour=kind == 'base')
        # Damage meshes can sample UVs outside the intact mesh's islands. Keep
        # the old texels there, including the padding around those islands.
        pixels = np.empty(len(original.pixels), dtype=np.float32)
        original.pixels.foreach_get(pixels)
        image.pixels.foreach_set(pixels)
        _target([material], image)
        _emit_switch(material, label)
        seconds = bake(atlas, 'EMIT' if label else 'NORMAL', 8)
        if kind == 'base':
            coated = np.empty_like(pixels)
            image.pixels.foreach_get(coated)
            coated -= pixels
            coated *= S.LEGACY_ALBEDO_BLEND
            coated += pixels
            image.pixels.foreach_set(coated)
            print(f'[paint] {code} legacy albedo blend {S.LEGACY_ALBEDO_BLEND}', flush=True)
        save(image, str(out), f'{code}_{kind}')
        print(f'[paint] {code} {kind} {image.size[0]}px: {seconds:.1f}s', flush=True)


def _uv_world_area(objs):
    uv = world = 0.0
    for o in objs:
        me = o.data; me.calc_loop_triangles(); M = o.matrix_world; ul = me.uv_layers.active.data
        for t in me.loop_triangles:
            a, b, c = (M @ me.vertices[i].co for i in t.vertices)
            world += (b - a).cross(c - a).length / 2
            p, q, r = (ul[l].uv for l in t.loops)
            uv += abs((q.x - p.x) * (r.y - p.y) - (r.x - p.x) * (q.y - p.y)) / 2
    return uv, world


def texel_density(H, P, res, parts_res):
    """texels per square ship unit in each atlas (the paint's resolution on the ship); the stack keeps parts at or above the hull"""
    out = {}
    for k, objs, R in (('hull', H, res), ('parts', P, parts_res)):
        uv, world = _uv_world_area(objs)
        out[k] = dict(uv_share=round(uv, 4), area=round(world, 5), texels_per_unit2=round(uv * R * R / max(world, 1e-9), 1))
    return out


if __name__ == '__main__':
    import argparse
    import importlib.util
    from pathlib import Path

    parser = argparse.ArgumentParser(description='Bake finish onto an existing A4 ship atlas.')
    parser.add_argument('stack', type=Path)
    parser.add_argument('source', type=Path, help='installed GLB with its original maps alongside it')
    parser.add_argument('output', type=Path)
    parser.add_argument('--samples', type=int, default=64)
    args = parser.parse_args(sys.argv[sys.argv.index('--') + 1:])
    spec = importlib.util.spec_from_file_location('faction_stack', args.stack)
    stack = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(stack)
    bake_existing_atlas(stack, args.source, args.output, args.samples)
