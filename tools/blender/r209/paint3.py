# Issue 209 round 3: paint matched to the concept, still the R96 route (procedural materials driven by masks from the ship's own
# geometry, baked to textures; no projected concept art). Ryan's round 2 ruling: the concept's rust-red forward hull and gunmetal
# aft, worn edges and grime. R103 and R105 still hold: broad areas, few tones, no busy speckle.
# Bands (by geometry and part kind, like round 6, but the concept's split):
#   rust    the forward hull (bow block, glacis, deck tiers, tower, casemate plates, fins): red-brown with broad lighter rust patches
#   gun     the sponsons, module blocks, aft body, stern, drums, bridge, guns, engines: gunmetal
#   rustdk  the flank cargo blocks: dark red-brown          belly  every downward face and the belly: near black
#   ochre   the drum bands and the tower band (the concept's faded yellow rings)            dark  bores and glass
# Masks, all from the ship's own geometry: ambient occlusion (grime in corners and under parts), a bevel-normal edge mask (worn
# bare metal on edges), vertical streaks on side faces; on the hull also the baked B0 cavity map (round 2's bake, trimmed source).
# The procedural graph is baked to an albedo map and an ORM map (occlusion, roughness, metal) per atlas (hull, parts); the render
# and the game export both use those textures, so what the sheets show is what Godot draws.
import bpy, math
import numpy as np
from mathutils import Vector

LIN = dict(rust=((.040, .0085, .0055), (.082, .019, .010)), gun=((.011, .0125, .0145), (.019, .021, .024)), rustdk=((.022, .010, .008), (.034, .015, .011)),
           belly=((.008, .0075, .007), (.013, .011, .009)), ochre=((.13, .085, .028), (.20, .13, .04)), dark=((.004, .004, .005), (.007, .007, .008)))
PATCH = (.14, .040, .015)       # the concept's brighter orange rust patches (rust band only, broad and few)
WORN = (.10, .095, .085)        # bare metal on worn edges
NOISE_SCALE = 3.2               # patches per ship length (broad)

def node(nt, t, **kw):
    n = nt.nodes.new(t)
    for k, v in kw.items(): setattr(n, k, v)
    return n

def math_(nt, op, a, b=None, clamp=False):
    n = node(nt, 'ShaderNodeMath', operation=op, use_clamp=clamp)
    for i, x in enumerate((a, b)):
        if x is None: continue
        if isinstance(x, (int, float)): n.inputs[i].default_value = x
        else: nt.links.new(x, n.inputs[i])
    return n.outputs[0]

def mixc(nt, a, b, f):
    n = node(nt, 'ShaderNodeMix', data_type='RGBA', blend_type='MIX')
    for sock, x in ((n.inputs[6], a), (n.inputs[7], b), (n.inputs[0], f)):
        if isinstance(x, (tuple, list)): sock.default_value = (*x, 1) if len(x) == 3 else x
        elif isinstance(x, (int, float)): sock.default_value = x
        else: nt.links.new(x, sock)
    return n.outputs[2]

def mulc(nt, a, f):
    n = node(nt, 'ShaderNodeMix', data_type='RGBA', blend_type='MULTIPLY'); n.inputs[0].default_value = 1
    nt.links.new(a, n.inputs[6])
    if isinstance(f, (int, float)): n.inputs[7].default_value = (f, f, f, 1)
    else: nt.links.new(f, n.inputs[7])
    return n.outputs[2]

def ramp(nt, x, a, b):
    """smooth step of x from a to b"""
    n = node(nt, 'ShaderNodeMapRange', interpolation_type='SMOOTHSTEP'); nt.links.new(x, n.inputs[0])
    n.inputs[1].default_value = a; n.inputs[2].default_value = b; return n.outputs[0]

def make(band, group, b0ao=None):
    """the procedural material for one band; group 'H' (hull atlas), 'P' (parts atlas) or 'G' (generated parts, parts atlas). Returns the material; its node tree keeps
    sockets for colour, roughness, metal and AO under the names used by the bake."""
    m = bpy.data.materials.new(f'p3_{band}_{group}'); m.use_nodes = True; nt = m.node_tree; nt.nodes.clear()
    out = node(nt, 'ShaderNodeOutputMaterial'); bs = node(nt, 'ShaderNodeBsdfPrincipled'); nt.links.new(bs.outputs[0], out.inputs[0])
    tc = node(nt, 'ShaderNodeTexCoord'); geo = node(nt, 'ShaderNodeNewGeometry')
    lo, hi = LIN[band]
    n1 = node(nt, 'ShaderNodeTexNoise'); n1.inputs['Scale'].default_value = NOISE_SCALE; n1.inputs['Detail'].default_value = 3; n1.inputs['Roughness'].default_value = .5
    nt.links.new(tc.outputs['Object'], n1.inputs['Vector'])
    n2 = node(nt, 'ShaderNodeTexNoise'); n2.inputs['Scale'].default_value = 40; n2.inputs['Detail'].default_value = 5
    nt.links.new(tc.outputs['Object'], n2.inputs['Vector'])
    mp = node(nt, 'ShaderNodeMapping'); mp.inputs['Scale'].default_value = (26, 26, 2.2); nt.links.new(tc.outputs['Object'], mp.inputs['Vector'])
    n3 = node(nt, 'ShaderNodeTexNoise'); n3.inputs['Scale'].default_value = 3; n3.inputs['Detail'].default_value = 2; nt.links.new(mp.outputs[0], n3.inputs['Vector'])
    ao = node(nt, 'ShaderNodeAmbientOcclusion', samples=16, only_local=False); ao.inputs['Distance'].default_value = .012
    bv = node(nt, 'ShaderNodeBevel', samples=6); bv.inputs['Radius'].default_value = .0011
    dot = node(nt, 'ShaderNodeVectorMath', operation='DOT_PRODUCT'); nt.links.new(geo.outputs['Normal'], dot.inputs[0]); nt.links.new(bv.outputs['Normal'], dot.inputs[1])
    edge = math_(nt, 'MULTIPLY', math_(nt, 'SUBTRACT', 1, dot.outputs['Value']), 16)
    edge = math_(nt, 'MULTIPLY', edge, ramp(nt, n2.outputs['Fac'], .38, .62), clamp=True)          # broken-up wear, not a clean line
    soft = group == 'G'   # generated hero parts: their lumpy surface reads as edges and cavities everywhere, so wear and grime are toned down
    if soft: edge = math_(nt, 'MULTIPLY', edge, .2)
    # base: two tones in broad patches
    col = mixc(nt, lo, hi, ramp(nt, n1.outputs['Fac'], .40, .64))
    if band == 'rust':
        n4 = node(nt, 'ShaderNodeTexNoise'); n4.inputs['Scale'].default_value = 7; n4.inputs['Detail'].default_value = 4
        nt.links.new(tc.outputs['Object'], n4.inputs['Vector'])
        col = mixc(nt, col, PATCH, math_(nt, 'MULTIPLY', ramp(nt, n4.outputs['Fac'], .60, .70), .55))
    # grime: cavities and corners (AO), then vertical streaks on side faces
    nz = node(nt, 'ShaderNodeSeparateXYZ'); nt.links.new(geo.outputs['Normal'], nz.inputs[0])
    side = math_(nt, 'SUBTRACT', 1, math_(nt, 'ABSOLUTE', nz.outputs['Z']))
    grime = math_(nt, 'ADD', .70 if soft else .42, math_(nt, 'MULTIPLY', ramp(nt, ao.outputs['AO'], .15, 1.0), .30 if soft else .58))
    col = mulc(nt, col, grime)
    streak = math_(nt, 'MULTIPLY', math_(nt, 'MULTIPLY', ramp(nt, n3.outputs['Fac'], .50, .72), side), .30)
    col = mulc(nt, col, math_(nt, 'SUBTRACT', 1, streak))
    if b0ao is not None:   # the hull's baked B0 cavity map (surface detail grime)
        uv = node(nt, 'ShaderNodeUVMap'); ti = node(nt, 'ShaderNodeTexImage'); ti.image = b0ao; nt.links.new(uv.outputs[0], ti.inputs[0])
        col = mulc(nt, col, math_(nt, 'ADD', .55, math_(nt, 'MULTIPLY', ti.outputs['Color'], .45)))
    if band not in ('dark',):
        col = mixc(nt, col, WORN, math_(nt, 'MULTIPLY', edge, .85))
    rough = math_(nt, 'ADD', math_(nt, 'SUBTRACT', .74, math_(nt, 'MULTIPLY', edge, .30)), math_(nt, 'MULTIPLY', n2.outputs['Fac'], .10))
    metal = math_(nt, 'ADD', .18, math_(nt, 'MULTIPLY', edge, .60), clamp=True)
    nt.links.new(col, bs.inputs['Base Color']); nt.links.new(rough, bs.inputs['Roughness']); nt.links.new(metal, bs.inputs['Metallic'])
    orm = node(nt, 'ShaderNodeCombineColor'); orm.label = 'ORM'
    nt.links.new(ao.outputs['AO'], orm.inputs[0]); nt.links.new(rough, orm.inputs[1]); nt.links.new(metal, orm.inputs[2])
    alb = node(nt, 'ShaderNodeMix', data_type='RGBA'); alb.label = 'ALBEDO'; alb.inputs[0].default_value = 0; nt.links.new(col, alb.inputs[6])
    m['p3_band'] = band; m['p3_group'] = group
    return m

def flat(name, rgb, emit=None):
    m = bpy.data.materials.new(name); m.use_nodes = True; b = m.node_tree.nodes['Principled BSDF']
    b.inputs['Base Color'].default_value = (*rgb, 1); b.inputs['Roughness'].default_value = .8
    if emit: b.inputs['Emission Color'].default_value = (*emit, 1); b.inputs['Emission Strength'].default_value = 2.2
    return m

# ------------------------------------------------------------------------------------------------ band assignment
FWD = -.100     # the concept's red ends where the aft body starts (behind the deckhouse tier)

def hull_band(c, n):
    if n.z < -.5 or c.z < -.128: return 'belly'
    ay = abs(c.y)
    if -.110 < c.x < .180 and ay > .099 and c.z < .050: return 'gun'          # sponsons and module blocks: the concept's dark side block
    if c.x > FWD: return 'rust'
    return 'gun'

PART_BAND = dict(casemate_plate='rust', tower='rust', fin='rust', cargo='rustdk', drum='gun', gun='gun', bridge='gun', antenna='gun',
                 radiator='gun', engine='gun', detail=None, gen_casemate=None, gen_bowguns='gun', gen_drumrack='gun')

def assign(objs, hull_objs, b0ao=None):
    """materials by band; hull objects get the H set (with the B0 cavity map), parts and break structure the P set"""
    import common as C
    T = C.bvh(hull_objs); mats = {}
    def M(band, g):
        k = (band, g)
        if k not in mats: mats[k] = make(band, g, b0ao if g == 'H' else None)
        return mats[k]
    glow = flat('p3_glow', (.05, .02, .01), (1.5, .06, .006)); inter = flat('p3_interior', (.020, .016, .014))
    for o in objs:
        r = o.get('role', 'part'); kind = o.get('kind'); me = o.data
        if r == 'interior': me.materials.clear(); me.materials.append(inter); continue
        if r == 'glow': me.materials.clear(); me.materials.append(glow); continue
        g = 'H' if r == 'hull' else ('G' if str(kind).startswith('gen_') else 'P')
        if r == 'dark': me.materials.clear(); me.materials.append(M('dark', g)); continue
        if r == 'trim' and kind == 'band': me.materials.clear(); me.materials.append(M('ochre', g)); continue
        mw = o.matrix_world; nm = mw.to_3x3().inverted_safe().transposed(); ids = []
        fixed = PART_BAND.get(kind) if r != 'hull' else None
        for p in me.polygons:
            c = mw @ p.center; nn = (nm @ p.normal).normalized()
            if r == 'hull': b = hull_band(c, nn)
            else:
                h = T.find_nearest(c); b = hull_band(Vector(h[0]), Vector(h[1])) if h[0] is not None else 'gun'
                if fixed: b = fixed
                if r == 'trim': b = 'gun'                # rim bands at break lines: steel, not red stripes (the concept has none)
                if nn.z < -.6 and b != 'gun': b = 'belly'
            ids.append(b)
        order = sorted(set(ids)); loc = {b: k for k, b in enumerate(order)}; me.materials.clear()
        for b in order: me.materials.append(M(b, g))
        me.polygons.foreach_set('material_index', np.array([loc[b] for b in ids], np.int32))
    return mats

# ------------------------------------------------------------------------------------------------ bake the paint to textures
def _emit_switch(m, which):
    """route ALBEDO or ORM into an emission output for an EMIT bake (and back to the BSDF with which=None)"""
    nt = m.node_tree; out = next(n for n in nt.nodes if n.type == 'OUTPUT_MATERIAL')
    em = next((n for n in nt.nodes if n.type == 'EMISSION'), None) or nt.nodes.new('ShaderNodeEmission')
    bs = next(n for n in nt.nodes if n.type == 'BSDF_PRINCIPLED')
    for l in list(out.inputs[0].links): nt.links.remove(l)
    if which is None: nt.links.new(bs.outputs[0], out.inputs[0]); return
    src = next(n for n in nt.nodes if n.label == which)
    nt.links.new(src.outputs[2] if which == 'ALBEDO' else src.outputs[0], em.inputs['Color']); em.inputs['Strength'].default_value = 1
    nt.links.new(em.outputs[0], out.inputs[0])

def bake_group(objs, mats, prefix, res, out_dir, margin=6, imgs=None):
    """bake every material of these objects (which share one UV atlas) to <prefix>_albedo and <prefix>_orm"""
    import os
    if imgs is None:
        imgs = {}
        for kind, cs in (('albedo', 'sRGB'), ('orm', 'Non-Color')):
            im = bpy.data.images.new(f'{prefix}_{kind}', res, res, alpha=False); im.colorspace_settings.name = cs; imgs[kind] = im
    sc = bpy.context.scene; sc.render.bake.use_selected_to_active = False; sc.render.bake.margin = margin; sc.render.bake.target = 'IMAGE_TEXTURES'
    bpy.ops.object.select_all(action='DESELECT')
    for o in objs: o.select_set(True)
    bpy.context.view_layer.objects.active = objs[0]
    t = {}
    import time
    for kind in ('albedo', 'orm'):
        for m in mats:
            nt = m.node_tree; tn = next((n for n in nt.nodes if n.label == 'BAKE_TARGET'), None)
            if tn is None: tn = nt.nodes.new('ShaderNodeTexImage'); tn.label = 'BAKE_TARGET'
            tn.image = imgs[kind]; nt.nodes.active = tn; _emit_switch(m, 'ALBEDO' if kind == 'albedo' else 'ORM')
        t0 = time.time(); bpy.ops.object.bake(type='EMIT'); t[kind] = round(time.time() - t0, 1)
        imgs[kind].filepath_raw = os.path.join(out_dir, f'{prefix}_{kind}.png'); imgs[kind].file_format = 'PNG'; imgs[kind].save(); imgs[kind].pack()
    for m in mats: _emit_switch(m, None)
    return imgs, t

def textured(name, albedo, orm, normal=None, nstrength=1.0):
    """the final material for an atlas: albedo, ORM (roughness G, metal B; occlusion R goes to the glTF occlusion slot), normal"""
    m = bpy.data.materials.new(name); m.use_nodes = True; nt = m.node_tree; bs = nt.nodes['Principled BSDF']
    uv = nt.nodes.new('ShaderNodeUVMap')
    ta = nt.nodes.new('ShaderNodeTexImage'); ta.image = albedo; nt.links.new(uv.outputs[0], ta.inputs[0]); nt.links.new(ta.outputs[0], bs.inputs['Base Color'])
    to = nt.nodes.new('ShaderNodeTexImage'); to.image = orm; nt.links.new(uv.outputs[0], to.inputs[0])
    sp = nt.nodes.new('ShaderNodeSeparateColor'); nt.links.new(to.outputs[0], sp.inputs[0])
    nt.links.new(sp.outputs[1], bs.inputs['Roughness']); nt.links.new(sp.outputs[2], bs.inputs['Metallic'])
    if normal is not None:
        tn = nt.nodes.new('ShaderNodeTexImage'); tn.image = normal; nt.links.new(uv.outputs[0], tn.inputs[0])
        nm = nt.nodes.new('ShaderNodeNormalMap'); nm.inputs['Strength'].default_value = nstrength
        nt.links.new(tn.outputs[0], nm.inputs['Color']); nt.links.new(nm.outputs[0], bs.inputs['Normal'])
    m['p3_textured'] = 1
    return m
