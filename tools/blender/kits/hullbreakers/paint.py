# The Ashfall Hullbreakers paint (issue 209 round 6; Ryan, Nov 9 14:52 CST, R151: "weapons and paint first. Let's ensure it
# actually looks good"). Same route as round 3 (R96: procedural materials driven by masks from the ship's own geometry, baked to
# an albedo and an ORM atlas; no projected concept art), retuned to the concept, region by region (colours read off the concept
# image, docs/shots/ship_pipeline/route209/round6/README.md, section 2):
#   rust     the forward hull: dark oxide red, broad bright orange rust blooms (strongest on up-facing faces and the upper sides)
#   gun      the aft body, sponsons, modules, stern: dark gunmetal with rust-brown run-off streaks down the sides, lighter tops
#   belly    downward faces and the lowest hull: near black            grime   every band darkens toward the keel line (z), the
#            concept's dark olive lower hull, and in corners and under parts (ambient occlusion), and in the B0 cavity map
#   copper   barrels, mantlets: dark copper, bright worn edges         sleeve  the quilted mantlet sleeves: mid steel
#   ochre    drum bands and tower band (faded yellow, worn)            rack    the welded drum cradles: red oxide
#   hazard   yellow and black stripes (ventral pylon feet, marked parts) white  stencil markings          dark  bores, glass
#   borrowed a clean blue-grey from another navy's yard, barely weathered (the salvaged turret)
# Every band: worn bare steel on edges (broken up, not a clean line), vertical streaks on side faces, AO grime.
# The bake, the textured material and the band switch reuse paint3.py (same node labels, so bakeAb and export3 are unchanged).
import os, sys
HERE = os.path.dirname(os.path.abspath(__file__))
R209 = os.path.normpath(os.path.join(HERE, '..', '..', 'r209'))
if R209 not in sys.path: sys.path.insert(0, R209)
import bpy, math
import numpy as np
from mathutils import Vector
import paint3 as P3
from paint3 import node, math_, mixc, mulc, ramp, flat, bake_group, textured

# linear albedo pairs (low, high) per band; see the README for the concept samples they were fitted to
LIN = dict(rust=((.036, .0034, .0020), (.062, .0058, .0030)), gun=((.012, .013, .0145), (.021, .022, .024)),
           drum=((.007, .0075, .008), (.013, .0135, .015)),
           belly=((.0050, .0048, .0044), (.0085, .0078, .0068)), copper=((.090, .030, .016), (.150, .052, .026)),
           sleeve=((.030, .031, .034), (.050, .052, .058)), ochre=((.20, .12, .025), (.30, .19, .040)), rack=((.060, .011, .006), (.095, .018, .010)),
           hazard=((.36, .22, .015), (.44, .28, .02)), yellow=((.30, .19, .015), (.40, .26, .02)), white=((.36, .35, .32), (.46, .45, .41)), dark=((.004, .004, .005), (.007, .007, .008)),
           borrowed=((.040, .050, .062), (.050, .062, .076)), rustdk=((.022, .010, .008), (.034, .015, .011)))
DUST = dict(rust=((.34, .19, .16), 1.0), rack=((.12, .05, .035), .4), gun=((.075, .072, .072), .55), drum=((.04, .04, .04), .3), sleeve=((.08, .08, .082), .4))
PATCH = (.40, .072, .012)       # the concept's bright orange rust blooms
PATCH2 = (.075, .011, .004)      # their darker rim
STREAK = (.050, .020, .010)     # rust run-off on gunmetal
WORN = (.16, .15, .135)         # bare steel on worn edges
GRIME_LOW = (.030, .023, .014)  # the concept's dark olive lower hull
Z_GRIME = (-.135, -.050)        # grime ramps in from z0 (full) to z1 (none)

def make(band, group, b0ao=None):
    m = bpy.data.materials.new(f'p3_{band}_{group}'); m.use_nodes = True; nt = m.node_tree; nt.nodes.clear()
    out = node(nt, 'ShaderNodeOutputMaterial'); bs = node(nt, 'ShaderNodeBsdfPrincipled'); nt.links.new(bs.outputs[0], out.inputs[0])
    tc = node(nt, 'ShaderNodeTexCoord'); geo = node(nt, 'ShaderNodeNewGeometry')
    lo, hi = LIN[band]
    xyz = node(nt, 'ShaderNodeSeparateXYZ'); nt.links.new(tc.outputs['Object'], xyz.inputs[0])
    nz = node(nt, 'ShaderNodeSeparateXYZ'); nt.links.new(geo.outputs['Normal'], nz.inputs[0])
    def noise(scale, detail=3, rough=.5, vec=None):
        n = node(nt, 'ShaderNodeTexNoise'); n.inputs['Scale'].default_value = scale; n.inputs['Detail'].default_value = detail
        n.inputs['Roughness'].default_value = rough; nt.links.new(vec or tc.outputs['Object'], n.inputs['Vector']); return n.outputs['Fac']
    def stretched(sx, sy, sz, scale, detail=2):
        mp = node(nt, 'ShaderNodeMapping'); mp.inputs['Scale'].default_value = (sx, sy, sz); nt.links.new(tc.outputs['Object'], mp.inputs['Vector'])
        return noise(scale, detail, .5, mp.outputs[0])
    up = math_(nt, 'MAXIMUM', nz.outputs['Z'], 0)                                   # 1 on decks, 0 on sides and below
    side = math_(nt, 'SUBTRACT', 1, math_(nt, 'ABSOLUTE', nz.outputs['Z']))
    ao = node(nt, 'ShaderNodeAmbientOcclusion', samples=16, only_local=False); ao.inputs['Distance'].default_value = .014
    bv = node(nt, 'ShaderNodeBevel', samples=6); bv.inputs['Radius'].default_value = .0009
    dot = node(nt, 'ShaderNodeVectorMath', operation='DOT_PRODUCT'); nt.links.new(geo.outputs['Normal'], dot.inputs[0]); nt.links.new(bv.outputs['Normal'], dot.inputs[1])
    fine = noise(46, 6, .6)
    edge = math_(nt, 'MULTIPLY', math_(nt, 'SUBTRACT', 1, dot.outputs['Value']), 18)
    edge = math_(nt, 'MULTIPLY', edge, ramp(nt, fine, .40, .60), clamp=True)          # broken-up wear
    edge = math_(nt, 'MULTIPLY', edge, ramp(nt, noise(4, 2), .35, .65))                # and only in some areas (handled, scraped)
    clean = band in ('borrowed', 'dark', 'white', 'hazard', 'yellow')
    if band == 'borrowed': edge = math_(nt, 'MULTIPLY', edge, .25)
    if band == 'drum': edge = math_(nt, 'MULTIPLY', edge, .35)                        # strapped drums: wear on the rims, not every strap
    # base: two tones in broad patches, a finer mottle on top
    col = mixc(nt, lo, hi, ramp(nt, noise(3.0, 3), .38, .66))
    col = mulc(nt, col, math_(nt, 'ADD', .82, math_(nt, 'MULTIPLY', noise(18, 4), .36)))
    col = mulc(nt, col, math_(nt, 'ADD', .62, math_(nt, 'MULTIPLY', up, .38)))      # sides darker than decks (the concept's read)
    if band in DUST:          # dust and bleach on up-facing faces (the concept's light pink-grey bow deck, grey aft deck)
        dc, dk = DUST[band]
        col = mixc(nt, col, dc, math_(nt, 'MULTIPLY', math_(nt, 'MULTIPLY', math_(nt, 'POWER', up, 4.0), dk), ramp(nt, noise(5, 3), .05, .55)))
    if band in ('rust', 'rack'):
        # round 6 paint pass: smaller, sparser, more saturated blooms (the concept's orange specks and spots, not camouflage blotches),
        # gated by a broad mask so some panels stay plain dark red
        bloom = math_(nt, 'ADD', ramp(nt, noise(20, 4, .6), .52, .62), math_(nt, 'MULTIPLY', ramp(nt, noise(48, 6, .65), .55, .62), .9))
        bloom = math_(nt, 'MULTIPLY', bloom, ramp(nt, noise(2.5, 2), .28, .52))
        reach = math_(nt, 'ADD', .40, math_(nt, 'MULTIPLY', up, .60))                  # blooms sit mostly on decks and upper sides
        bm = math_(nt, 'MULTIPLY', math_(nt, 'MULTIPLY', bloom, reach), ramp(nt, xyz.outputs['Z'], -.14, -.07), clamp=True)
        col = mixc(nt, col, PATCH2, math_(nt, 'MULTIPLY', ramp(nt, bm, .05, .30), .55))
        col = mixc(nt, col, PATCH, math_(nt, 'MULTIPLY', ramp(nt, bm, .30, .70), .85))
    if band in ('gun', 'sleeve', 'rustdk', 'drum'):
        run = math_(nt, 'MULTIPLY', ramp(nt, stretched(30, 30, 1.6, 4, 3), .55, .72), side)
        col = mixc(nt, col, STREAK, math_(nt, 'MULTIPLY', run, .55))
        col = mulc(nt, col, math_(nt, 'ADD', 1, math_(nt, 'MULTIPLY', up, .45)))      # dusty lighter tops (the concept's grey aft deck)
    if band == 'hazard':      # yellow and black stripes at 45 degrees, worn
        wv = node(nt, 'ShaderNodeTexWave', wave_type='BANDS', bands_direction='DIAGONAL'); wv.inputs['Scale'].default_value = 60
        nt.links.new(tc.outputs['Object'], wv.inputs['Vector']); s = ramp(nt, wv.outputs['Fac'], .48, .52)
        col = mixc(nt, LIN['dark'][1], col, s)
    # grime: toward the keel line, corners and under parts, vertical streaks on the sides, the B0 cavity map
    if not clean:
        g = ramp(nt, xyz.outputs['Z'], Z_GRIME[0], Z_GRIME[1])
        col = mixc(nt, GRIME_LOW, col, math_(nt, 'ADD', .28, math_(nt, 'MULTIPLY', g, .72)))
    grime = math_(nt, 'ADD', .62 if clean else .36, math_(nt, 'MULTIPLY', ramp(nt, ao.outputs['AO'], .10, 1.0), .38 if clean else .64))
    col = mulc(nt, col, grime)
    streak = math_(nt, 'MULTIPLY', math_(nt, 'MULTIPLY', ramp(nt, stretched(26, 26, 2.2, 3, 2), .48, .72), side), .10 if clean else .34)
    col = mulc(nt, col, math_(nt, 'SUBTRACT', 1, streak))
    if b0ao is not None:
        uv = node(nt, 'ShaderNodeUVMap'); ti = node(nt, 'ShaderNodeTexImage'); ti.image = b0ao; nt.links.new(uv.outputs[0], ti.inputs[0])
        col = mulc(nt, col, math_(nt, 'ADD', .50, math_(nt, 'MULTIPLY', ti.outputs['Color'], .50)))
    if band != 'dark':
        wc = (.30, .14, .07) if band == 'copper' else WORN
        col = mixc(nt, col, wc, math_(nt, 'MULTIPLY', edge, .75))
    rough = math_(nt, 'ADD', math_(nt, 'SUBTRACT', .86 if band != 'borrowed' else .55, math_(nt, 'MULTIPLY', edge, .32)), math_(nt, 'MULTIPLY', fine, .10))
    # rust and rack: some metalness so the sheen takes the paint's own red instead of greying it (white sheen on a dark red read mauve)
    metal = math_(nt, 'ADD', .45 if band in ('copper', 'borrowed') else (.38 if band in ('rust', 'rack') else .15), math_(nt, 'MULTIPLY', edge, .65), clamp=True)
    nt.links.new(col, bs.inputs['Base Color']); nt.links.new(rough, bs.inputs['Roughness']); nt.links.new(metal, bs.inputs['Metallic'])
    orm = node(nt, 'ShaderNodeCombineColor'); orm.label = 'ORM'
    nt.links.new(ao.outputs['AO'], orm.inputs[0]); nt.links.new(rough, orm.inputs[1]); nt.links.new(metal, orm.inputs[2])
    alb = node(nt, 'ShaderNodeMix', data_type='RGBA'); alb.label = 'ALBEDO'; alb.inputs[0].default_value = 0; nt.links.new(col, alb.inputs[6])
    m['p3_band'] = band; m['p3_group'] = group
    return m

# ------------------------------------------------------------------------------------------------ band assignment
FWD = -.100     # the concept's red ends where the aft body starts (behind the deckhouse tier)

def hull_band(c, n):
    if n.z < -.5 or c.z < -.150: return 'belly'
    ay = abs(c.y)
    if -.110 < c.x < .180 and ay > .099 and c.z < .050: return 'gun'          # sponsons and module blocks: the concept's dark side block
    if c.x > FWD: return 'rust'
    return 'gun'

PART_BAND = dict(casemate_plate='rust', tower='rust', fin='rust', cargo='rustdk', drum='drum', gun='sleeve', gun_dark='gun', bridge='gun',
                 antenna='gun', radiator='gun', engine='gun', detail=None, copper='copper', copper_dark='copper', hood='rust', rack='rack',
                 turret_ring='rack', borrowed='borrowed', hazard='hazard', white='white', yellow='yellow', rust_plain='rust')

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
        g = 'H' if r == 'hull' else 'P'
        if r == 'dark': me.materials.clear(); me.materials.append(M('dark', g)); continue
        if r == 'trim' and kind == 'band': me.materials.clear(); me.materials.append(M('ochre', g)); continue
        if r == 'decal': me.materials.clear(); me.materials.append(M(PART_BAND.get(kind, 'white'), g)); continue   # worn, not clean (below)
        mw = o.matrix_world; nm = mw.to_3x3().inverted_safe().transposed(); ids = []
        fixed = PART_BAND.get(kind) if r != 'hull' else None
        for p in me.polygons:
            c = mw @ p.center; nn = (nm @ p.normal).normalized()
            if r == 'hull': b = hull_band(c, nn)
            else:
                h = T.find_nearest(c); b = hull_band(Vector(h[0]), Vector(h[1])) if h[0] is not None else 'gun'
                if fixed: b = fixed
                if r == 'trim': b = 'gun'
                if kind == 'fin' and c.z < -.236 and o.name.startswith('vpod'): b = 'hazard'                     # the concept's yellow-striped pylon feet
                if nn.z < -.6 and b not in ('gun', 'copper', 'sleeve', 'hazard', 'borrowed'): b = 'belly'
            ids.append(b)
        order = sorted(set(ids)); loc = {b: k for k, b in enumerate(order)}; me.materials.clear()
        for b in order: me.materials.append(M(b, g))
        me.polygons.foreach_set('material_index', np.array([loc[b] for b in ids], np.int32))
    return mats
