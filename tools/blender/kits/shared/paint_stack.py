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
#      world position and the face normal: base colour (two tones, one tone per plate island), soot, rust and run-off, grime,
#      edge wear to bare metal, the faction's TRIM SHEET (rivet rows near plate edges, scuffs, grilles, tread, stripes; sampled
#      by box projection at ship scale, so a gun and a hull plate carry the same rivet and scuff density, R224) and DECALS
#      (placed by the faction's rules on the ship's own surfaces by ray cast, never painted by hand);
#   4. bakes the atlases: albedo, ORM (occlusion, roughness, metal) for both; a detail normal for the hull (rivets, welds,
#      scuffs and seams from the same layers' height);
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


def bake_copy(objs, name, zone_by_kind=None):
    """one joined copy of these objects (same UVs and material slots, world space, no modifiers), so Cycles syncs the scene once
    per bake instead of once per object (round 6 lesson, bakeAb6.py); the originals are hidden from the render meanwhile"""
    cps = []
    for o in objs:
        c = o.copy(); c.data = o.data.copy(); bpy.context.scene.collection.objects.link(c)
        mw = o.matrix_world.copy(); c.parent = None; c.matrix_world = mw
        for md in list(c.modifiers): c.modifiers.remove(md)
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
    try:
        prefs = bpy.context.preferences.addons['cycles'].preferences
        for t in ('OPTIX', 'CUDA'):
            try:
                prefs.compute_device_type = t; prefs.get_devices()
                if not [d for d in prefs.devices if d.type == t]: continue
                for d in prefs.devices: d.use = True
                sc.cycles.device = 'GPU'; return t
            except Exception: pass
    except Exception: pass
    sc.cycles.device = 'CPU'; return 'CPU'


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
    """the inputs every layer reads, made once per material: masks, position, normal, per-plate random, edge bands"""
    def __init__(self, nt, masks, scale):
        self.nt = nt
        tc = node(nt, 'ShaderNodeTexCoord'); geo = node(nt, 'ShaderNodeNewGeometry'); self.tc, self.geo = tc, geo
        uv = node(nt, 'ShaderNodeUVMap')
        mk = node(nt, 'ShaderNodeTexImage'); mk.image = masks; mk.interpolation = 'Linear'; nt.links.new(uv.outputs[0], mk.inputs[0])
        sp = node(nt, 'ShaderNodeSeparateColor'); nt.links.new(mk.outputs[0], sp.inputs[0])
        self.ao, self.edge, self.aol = sp.outputs[0], sp.outputs[1], sp.outputs[2]
        self.pos = tc.outputs['Object']
        xyz = node(nt, 'ShaderNodeSeparateXYZ'); nt.links.new(self.pos, xyz.inputs[0]); self.x, self.y, self.z = xyz.outputs[0], xyz.outputs[1], xyz.outputs[2]
        nz = node(nt, 'ShaderNodeSeparateXYZ'); nt.links.new(geo.outputs['Normal'], nz.inputs[0]); self.nz = nz.outputs[2]
        self.up = math_(nt, 'MAXIMUM', self.nz, 0)
        self.down = math_(nt, 'MAXIMUM', math_(nt, 'MULTIPLY', self.nz, -1), 0)
        self.side = math_(nt, 'SUBTRACT', 1, math_(nt, 'ABSOLUTE', self.nz))
        self.isl = geo.outputs['Random Per Island'] if 'Random Per Island' in geo.outputs else None
        if self.isl is None:
            oi = node(nt, 'ShaderNodeObjectInfo'); self.isl = oi.outputs['Random']
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
        rel = node(nt, 'ShaderNodeVectorMath', operation='SUBTRACT'); nt.links.new(c.pos, rel.inputs[0]); rel.inputs[1].default_value = cpos
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


def _grid(c, cell, seed, shift):
    """one panel grid in the ship frame: rows (along z) each shifted along x and y by their own random amount (never a regular
    stagger), cells of the given size; returns (cell id vector, the three in-cell coordinates)"""
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
    return cq.outputs[0], (qx, qy, sq.outputs[2])


def _seams(c, S, coords, cell):
    """the panel borders on the face's own plane (an axis along the face normal never draws a seam)"""
    nt = c.nt; L = S.LAYERS
    nrm = node(nt, 'ShaderNodeSeparateXYZ'); nt.links.new(c.geo.outputs['Normal'], nrm.inputs[0]); seam = None
    for qa, size, na in zip(coords, cell, nrm.outputs[:3]):
        f = math_(nt, 'FRACT', qa); d = math_(nt, 'MULTIPLY', math_(nt, 'MINIMUM', f, math_(nt, 'SUBTRACT', 1, f)), size)
        e = math_(nt, 'SUBTRACT', 1, ramp(nt, d, L['patch_seam'] * .4, L['patch_seam']))
        e = math_(nt, 'MULTIPLY', e, ramp(nt, math_(nt, 'SUBTRACT', 1, math_(nt, 'ABSOLUTE', na)), .35, .65))
        seam = e if seam is None else math_(nt, 'MAXIMUM', seam, e)
    return seam


def patchwork(c, S, col, amount, families=None, cells=None):
    """the plate patchwork (R228; RULEBOOK 0.5, tidy is a fault): two panel grids of different sizes, the region of each chosen by
    a broad noise, rows offset at random, plus a sparse layer of larger patch plates laid over them; each panel (and each modelled
    plate, by its UV island) picks one of the faction's plate families. Returns the colour and the seam mask."""
    nt = c.nt; L = S.LAYERS; families = families or S.PATCH_FAMILIES
    big, small, patch = cells or (L['patch_big'], L['patch_small'], L['patch_over'])
    region = ramp(nt, c.noise(L['patch_region'], 2), .42, .58)          # 0: big plates, 1: small plates
    ids = []; seam = None
    for k, (cell, seed, sh) in enumerate(((big, 11.0, (0, 0, 0)), (small, 37.0, (.013, .007, .005)))):
        cid, co = _grid(c, cell, seed, sh); sm = _seams(c, S, co, cell)
        w = region if k else math_(nt, 'SUBTRACT', 1, region)
        ids.append((cid, w)); sm = math_(nt, 'MULTIPLY', sm, w)
        seam = sm if seam is None else math_(nt, 'ADD', seam, sm)
    def pick(cid, w, col, small=False):
        wn = node(nt, 'ShaderNodeTexWhiteNoise', noise_dimensions='3D'); nt.links.new(cid, wn.inputs['Vector'])
        r = math_(nt, 'FRACT', math_(nt, 'ADD', wn.outputs['Value'], math_(nt, 'MULTIPLY', c.isl, .618)))
        sp2 = node(nt, 'ShaderNodeSeparateColor'); nt.links.new(wn.outputs['Color'], sp2.inputs[0]); tone = sp2.outputs[1]
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
    pid, pco = _grid(c, patch, 71.0, (.021, .011, .009))
    pw = node(nt, 'ShaderNodeTexWhiteNoise', noise_dimensions='3D'); nt.links.new(pid, pw.inputs['Vector'])
    on = math_(nt, 'LESS_THAN', pw.outputs['Value'], L['patch_over_share'])
    col = pick(pid, on, col)
    seam = math_(nt, 'MAXIMUM', math_(nt, 'MULTIPLY', seam, math_(nt, 'SUBTRACT', 1, on)), math_(nt, 'MULTIPLY', _seams(c, S, pco, patch), on))
    return col, math_(nt, 'MULTIPLY', seam, amount, clamp=True)


def zone_material(S, zone, group, masks, tiles, decals, decal_atlas):
    """the procedural material of one zone in one atlas (group 'H' hull, 'P' parts), from the faction stack S"""
    z = S.ZONES[zone]
    m = bpy.data.materials.new(f'ps_{zone}_{group}'); m.use_nodes = True; nt = m.node_tree; nt.nodes.clear()
    out = node(nt, 'ShaderNodeOutputMaterial'); bs = node(nt, 'ShaderNodeBsdfPrincipled'); nt.links.new(bs.outputs[0], out.inputs[0])
    c = Ctx(nt, masks, S.SCALE)
    L = S.LAYERS
    lo, hi = z['lo'], z['hi']
    # 1. base: two tones in broad patches, one tone per plate island (a scavenged hull: no two plates alike)
    # the plate's own tone first (its island), a soft broad patch over it, a fine mottle: a hull of salvaged plates, no camouflage
    tone = math_(nt, 'ADD', math_(nt, 'MULTIPLY', c.isl, .75), math_(nt, 'MULTIPLY', ramp(nt, c.noise(L['patch_scale'], 3), .3, .7), .25))
    col = mixc(nt, lo, hi, tone)
    col = mulc(nt, col, math_(nt, 'ADD', 1 - z.get('plate_var', L['plate_var']) / 2, math_(nt, 'MULTIPLY', c.isl, z.get('plate_var', L['plate_var']))))
    mo = L.get('mottle', .2); col = mulc(nt, col, math_(nt, 'ADD', 1 - mo / 2, math_(nt, 'MULTIPLY', c.noise(L['mottle_scale'], 5, .65), mo)))
    seam = None
    if group == 'H' and z.get('red_share', 0) > 0:      # a share of the zone's hull plates (by island) carry the red over-paint, worn
        pick = math_(nt, 'GREATER_THAN', math_(nt, 'FRACT', math_(nt, 'MULTIPLY', c.isl, 7.31)), 1 - z['red_share'])
        rlo, rhi = S.RED_PLATE
        red = mixc(nt, rlo, rhi, ramp(nt, c.noise(L['patch_scale'] * 3, 3), .3, .7))
        thin = ramp(nt, c.noise(L['mottle_scale'] * .5, 4, .6), .32, .58)          # the paint is thin and patchy
        col = mixc(nt, col, red, math_(nt, 'MULTIPLY', math_(nt, 'MULTIPLY', pick, thin), L.get('red_tone', .75)))
    if group == 'H' and z.get('patchwork', 0) > 0 and getattr(S, 'PATCH_FAMILIES', None):
        col, seam = patchwork(c, S, col, z['patchwork'])
    elif group == 'P' and z.get('patchwork_parts', 0) > 0 and getattr(S, 'PATCH_FAMILIES_PARTS', None):
        # R224 in paint: big part faces (a rack box, a turret top) carry the hull's plate and seam detail at a smaller plate size
        col, seam = patchwork(c, S, col, z['patchwork_parts'], S.PATCH_FAMILIES_PARTS, S.LAYERS['patch_parts'])
    col = mulc(nt, col, math_(nt, 'ADD', 1 - L['side_dark'], math_(nt, 'MULTIPLY', c.up, L['side_dark'])))
    height = math_(nt, 'MULTIPLY', c.noise(L['grain_scale'], 4, .6), L.get('grain', .05))
    rough = math_(nt, 'ADD', z.get('rough', L['rough']), math_(nt, 'MULTIPLY', c.noise(L['grain_scale'], 2), .08))
    metal = z.get('metal', L['metal'])
    wear_amt = z.get('wear', L['wear'])
    # 2. the trim sheet: scuffs everywhere, rivet rows set back from plate edges, the zone's own rows (grille, tread, stripes)
    sc_c, sc_a = c.tile(tiles['scuffs'], L['scuff_size'])
    scuff = math_(nt, 'MULTIPLY', sc_a, z.get('scuff', L['scuff']))
    col = mixc(nt, col, S.BARE, math_(nt, 'MULTIPLY', scuff, .55))
    height = math_(nt, 'ADD', height, math_(nt, 'MULTIPLY', scuff, -.25))
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
    run = math_(nt, 'MULTIPLY', math_(nt, 'MULTIPLY', ramp(nt, c.noise(L['streak_scale'] * .7, 2, .5, stretch=(30, 30, 1.6)), .55, .74), c.side), z.get('grime', L['grime']) * .5)
    col = mulc(nt, col, math_(nt, 'SUBTRACT', 1, run))
    cav = math_(nt, 'POWER', c.ao, L.get('cavity_pow', 1.0))
    col = mulc(nt, col, math_(nt, 'ADD', 1 - L['ao_dark'], math_(nt, 'MULTIPLY', cav, L['ao_dark'])))
    if seam is not None:       # black seams between the panels
        col = mulc(nt, col, math_(nt, 'SUBTRACT', 1, math_(nt, 'MULTIPLY', seam, L.get('seam_dark', .8))))
        height = math_(nt, 'SUBTRACT', height, math_(nt, 'MULTIPLY', seam, .5))
        rough = math_(nt, 'ADD', rough, math_(nt, 'MULTIPLY', seam, .1))
    # 5. decals (hull atlas): before the wear, so the wear eats into them
    wear = math_(nt, 'MULTIPLY', math_(nt, 'MULTIPLY', c.edge, ramp(nt, c.noise(L['wear_scale'], 6, .6), L.get('wear_lo', .38), L.get('wear_hi', .62))), wear_amt)
    wear = math_(nt, 'MULTIPLY', wear, ramp(nt, c.noise(L['wear_patch'], 2), .30, .66), clamp=True)
    if decals and decal_atlas is not None:
        col, height, rough = decal_layer(c, col, height, rough, decals, decal_atlas, S.DECAL_CELLS, math_(nt, 'ADD', math_(nt, 'MULTIPLY', scuff, .7), wear))
    # 6. edge wear to bare metal: broken up, only in some areas
    col = mixc(nt, col, S.BARE, wear)
    rough = math_(nt, 'SUBTRACT', rough, math_(nt, 'MULTIPLY', wear, .30))
    metal = math_(nt, 'ADD', metal, math_(nt, 'MULTIPLY', wear, .6), clamp=True)
    height = math_(nt, 'SUBTRACT', height, math_(nt, 'MULTIPLY', wear, .1))
    rough = math_(nt, 'MAXIMUM', math_(nt, 'MINIMUM', rough, 1.0), L.get('rough_floor', .05))
    nt.links.new(col, bs.inputs['Base Color']); nt.links.new(rough, bs.inputs['Roughness'])
    if isinstance(metal, float): bs.inputs['Metallic'].default_value = metal
    else: nt.links.new(metal, bs.inputs['Metallic'])
    # the detail normal: the layers' height through a bump at the trim's own scale
    bp = node(nt, 'ShaderNodeBump'); bp.inputs['Distance'].default_value = L['bump_distance']; bp.inputs['Strength'].default_value = L['bump_strength']
    nt.links.new(height, bp.inputs['Height']); nt.links.new(bp.outputs['Normal'], bs.inputs['Normal'])
    # the bake's labelled outputs (paint3's names, so the same emit switch bakes them)
    orm = node(nt, 'ShaderNodeCombineColor'); orm.label = 'ORM'
    occ = math_(nt, 'MULTIPLY', c.ao, math_(nt, 'ADD', .5, math_(nt, 'MULTIPLY', c.aol, .5)))
    nt.links.new(occ, orm.inputs[0]); nt.links.new(rough, orm.inputs[1])
    if isinstance(metal, float): orm.inputs[2].default_value = metal
    else: nt.links.new(metal, orm.inputs[2])
    alb = node(nt, 'ShaderNodeMix', data_type='RGBA'); alb.label = 'ALBEDO'; alb.inputs[0].default_value = 0; nt.links.new(col, alb.inputs[6])
    m['ps_zone'] = zone; m['ps_group'] = group
    return m


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
    src = next(n for n in nt.nodes if n.label == which)
    nt.links.new(src.outputs[2] if which == 'ALBEDO' else src.outputs[0], em.inputs['Color']); em.inputs['Strength'].default_value = 1
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
    if kind == 'NORMAL': bpy.ops.object.bake(type='NORMAL', normal_space='TANGENT')
    else: bpy.ops.object.bake(type=kind)
    return round(time.time() - t0, 1)


def textured(name, albedo, orm, normal=None):
    """the final atlas material (paint3.textured's layout, which the recipe's export reads): albedo, ORM, an optional normal"""
    from paint3 import textured as _t
    return _t(name, albedo, orm, normal)


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
        for sd in sides:
            best = None
            for fx in rule['x']:
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
                    for fy in rule.get('y', (0.0,)):
                        o = Vector((x, fy, zt + 1.0)); d = Vector((0, 0, -1))
                        hit = TA.ray_cast(o, d); hh = TH.ray_cast(o, d)
                        if hit[0] is None or hh[0] is None or (hit[0] - hh[0]).length > 1e-5: continue
                        n = hh[1].normalized()
                        if n.z < rule.get('min_facing', .85): continue
                        sc = _room(TA, hh[0], n, rule['w'], rule['h'])
                        if best is None or sc > best[0]: best = (sc, hh[0], n)
            if best is None or best[0] < rule.get('min_room', .7):
                rep.append(dict(rule=rule['name'], side=sd, placed=False, room=None if best is None else round(best[0], 2))); continue
            _, p, n = best
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
    uneven hot spots and soot streaks across the throat, the lining dark toward the lip, and each engine a little dimmer, more
    orange or more red than its neighbours. The game's moving plume sits on top; this paints no flame. Per vertex the stack
    writes, in the colour attribute ps_glow: R the distance from the engine's axis over the throat radius, G the engine's own
    random, B the depth into the bell (1 at the throat, 0 at the lip), A the angle round the axis."""
    E = S.ENGINE_GLOW; groups = {}
    for o in objs: groups.setdefault(o.get('grp') or o.name.split('_')[0], []).append(o)
    rng = np.random.default_rng(601)
    for gname, members in sorted(groups.items()):
        rnd = float(rng.random())
        W = [o.matrix_world @ v.co for o in members for v in o.data.vertices]
        disc = [o for o in members if o.data.materials and o.data.materials[0].name == 'glow']
        core = disc + [o for o in members if o.get('emissive_zone') == 'plug']      # the throat disc and the plug: the core's surfaces
        Dv = [o.matrix_world @ v.co for o in (disc or members) for v in o.data.vertices]
        cy = sum(v.y for v in Dv) / len(Dv); cz = sum(v.z for v in Dv) / len(Dv)
        rmax = max(math.hypot(v.y - cy, v.z - cz) for v in Dv) or 1.0
        x0 = min(v.x for v in W); x1 = max(v.x for v in W)
        for o in members:
            me = o.data; ca = me.color_attributes.get('ps_glow') or me.color_attributes.new('ps_glow', 'FLOAT_COLOR', 'POINT')
            is_disc = o in core
            for i, v in enumerate(me.vertices):
                w = o.matrix_world @ v.co
                r = min(1.0, math.hypot(w.y - cy, w.z - cz) / rmax) if is_disc else 1.0
                d = 1.0 if is_disc else (w.x - x0) / max(x1 - x0, 1e-6)
                ang = (math.atan2(w.z - cz, w.y - cy) / (2 * math.pi)) % 1.0
                ca.data[i].color = (r, rnd, d, ang)
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
    # heat: the core (hot at the axis) on the throat disc, the lining by its depth (dark at the lip, R228 item 5)
    # the core: hottest on the axis (the plug's tip, the throat's centre), falling off toward the wall, each engine its own reach
    e2 = math_(nt, 'FRACT', math_(nt, 'MULTIPLY', e, 7.31))
    reach = math_(nt, 'ADD', E['core_reach'][0], math_(nt, 'MULTIPLY', e2, E['core_reach'][1] - E['core_reach'][0]))
    corev = math_(nt, 'POWER', math_(nt, 'SUBTRACT', 1, ramp(nt, r, 0.0, 1.0)), reach)
    lining = math_(nt, 'MULTIPLY', ramp(nt, r, .98, 1.0), math_(nt, 'MULTIPLY', math_(nt, 'POWER', d, E['lining_falloff']), E['lining_gain']))
    heat = math_(nt, 'ADD', math_(nt, 'MULTIPLY', corev, math_(nt, 'SUBTRACT', 1, ramp(nt, r, .98, 1.0))), lining)
    # uneven hot spots (each engine's own pattern), and soot streaks running out from the axis
    hn = node(nt, 'ShaderNodeTexNoise'); hn.noise_dimensions = '4D'; hn.inputs['Scale'].default_value = E['hotspot_scale']
    hn.inputs['Detail'].default_value = 4; hn.inputs['Roughness'].default_value = .6
    nt.links.new(tc.outputs['Object'], hn.inputs['Vector']); nt.links.new(math_(nt, 'MULTIPLY', e, 13.0), hn.inputs['W'])
    hs = ramp(nt, hn.outputs['Fac'], E['hotspot'][0], E['hotspot'][1])
    heat = math_(nt, 'ADD', heat, math_(nt, 'MULTIPLY', math_(nt, 'MULTIPLY', hs, d), E['hotspot_gain']))
    av = node(nt, 'ShaderNodeCombineXYZ'); nt.links.new(math_(nt, 'MULTIPLY', a, E['streaks']), av.inputs[0]); nt.links.new(math_(nt, 'MULTIPLY', e, 31.0), av.inputs[1])
    nt.links.new(math_(nt, 'MULTIPLY', r, 1.5), av.inputs[2])
    soot = ramp(nt, noise(av.outputs[0], 1.0, 2, .5), E['soot'][0], E['soot'][1])
    heat = math_(nt, 'MULTIPLY', heat, math_(nt, 'SUBTRACT', 1, math_(nt, 'MULTIPLY', soot, E['soot_gain'])), clamp=True)
    # each engine its own: brightness and hue (more orange or more red)
    heat = math_(nt, 'MULTIPLY', heat, math_(nt, 'ADD', E['bright'][0], math_(nt, 'MULTIPLY', e, E['bright'][1] - E['bright'][0])))
    cr = node(nt, 'ShaderNodeValToRGB')
    for i_, (pos, col) in enumerate(E['ramp']):
        el = cr.color_ramp.elements[i_] if i_ < 2 else cr.color_ramp.elements.new(pos)
        el.position = pos; el.color = (*col, 1)
    hue = math_(nt, 'ADD', heat, math_(nt, 'MULTIPLY', math_(nt, 'SUBTRACT', e, .5), E['hue_shift']))
    nt.links.new(math_(nt, 'MINIMUM', math_(nt, 'MAXIMUM', hue, 0.0), 1.0), cr.inputs[0])
    col = mixc(nt, (0, 0, 0), cr.outputs[0], ramp(nt, heat, 0.0, .25))
    nt.links.new(col, em.inputs['Color']); em.inputs['Strength'].default_value = 1
    for i in range(len(J.material_slots)): J.material_slots[i].material = m
    im = new_image(f'{cell}_engine_emission', res, colour=True); _target([m], im)
    INFO['bake_engine_glow_s'] = bake(J, 'EMIT', 4); save(im, out, im.name)
    for o in objs: o.hide_render = hid[o.name]
    bpy.data.objects.remove(J)
    g = bpy.data.materials.new('p3_glow'); g.use_nodes = True; gt = g.node_tree; b = gt.nodes['Principled BSDF']
    uv = gt.nodes.new('ShaderNodeUVMap'); ti = gt.nodes.new('ShaderNodeTexImage'); ti.image = im; gt.links.new(uv.outputs[0], ti.inputs[0])
    gt.links.new(ti.outputs[0], b.inputs['Emission Color']); b.inputs['Emission Strength'].default_value = E['strength']
    b.inputs['Base Color'].default_value = (.03, .012, .006, 1); b.inputs['Roughness'].default_value = .85
    INFO['engine_glow'] = dict(engines=len(groups), map=im.name + '.png', res=res)
    return g


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
        plug = [o for o in P if o.get('part_kind') == 'engine' and o.data.materials and o.data.materials[0].name in S.ENGINE_GLOW.get('plug', ())]
        for o in plug: o['emissive_zone'] = 'plug'
        P = [o for o in P if o not in plug]; G = G + plug
    unwrap(H, .0003); unwrap(P, .0004)
    maps = {}
    for group, objs, R in (('H', H, res), ('P', P, parts_res)):
        J = bake_copy(objs, f'{cell}_{group}_bake', getattr(S, 'ZONE_BY_KIND', None)); hid = {o.name: o.hide_render for o in objs}
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
            if zz not in mats: mats[zz] = zone_material(S, zz, group, masks, tiles, decals if group == 'H' else (), datlas)
            J.material_slots[i].material = mats[zz]
        ml = list(mats.values()); imgs = {}
        for kind, cs in (('albedo', True), ('orm', False)):
            im = new_image(f'{cell}_{"hull" if group == "H" else "parts"}_{kind}', R, colour=cs)
            _target(ml, im)
            for m in ml: _emit_switch(m, 'ALBEDO' if kind == 'albedo' else 'ORM')
            INFO[f'bake_{group}_{kind}_s'] = bake(J, 'EMIT', 8); save(im, out, im.name); imgs[kind] = im
        for m in ml: _emit_switch(m, None)
        if group == 'H':
            im = new_image(f'{cell}_hull_normal', R, colour=False, fill=(.5, .5, 1, 1))
            _target(ml, im); INFO['bake_H_normal_s'] = bake(J, 'NORMAL', 8); save(im, out, im.name); imgs['normal'] = im
        maps[group] = imgs
        for o in objs: o.hide_render = hid[o.name]
        bpy.data.objects.remove(J)
        INFO[f'zones_{group}'] = sorted(mats)
    HM = textured(f'{cell}_hull_mat', maps['H']['albedo'], maps['H']['orm'], maps['H']['normal'])
    PM = textured(f'{cell}_parts_mat', maps['P']['albedo'], maps['P']['orm'])
    # issue 601: these surfaces carry the stack's own roughness; the game gives them the soft rim light (godot/render/look.gd RIM
    # soft), not the full specular that flared white on them at the close cameras. glTF writes it as the material's extras.
    for M_ in (HM, PM): M_['rim_soft'] = 1
    for objs, M in ((H, HM), (P, PM)):
        for o in objs:
            o.data.materials.clear(); o.data.materials.append(M); o.data.polygons.foreach_set('material_index', np.zeros(len(o.data.polygons), np.int32))
    glow = {}
    eng = [o for o in G if (o.data.materials[0].name if o.data.materials else '') in ('glow', 'ember') or o.get('emissive_zone') == 'plug'] \
        if hasattr(S, 'ENGINE_GLOW') else []
    if eng:      # the engine throats and linings: one surface, its own emission map (graded, hot spots, soot, each engine its own)
        glow['engine'] = bake_engine_glow(S, eng, out, cell, max(256, res // 4), samples); glow['engine']['rim_soft'] = 1
        for o in eng:
            o.data.materials.clear(); o.data.materials.append(glow['engine'])
    for o in G:
        if o in eng: continue
        z = o.data.materials[0].name if o.data.materials else 'glow'
        if z not in glow: glow[z] = S.glow_material(z)
        o.data.materials.clear(); o.data.materials.append(glow[z])
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
