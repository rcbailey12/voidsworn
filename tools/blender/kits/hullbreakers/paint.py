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
# Round 7 (Ryan, Nov 9 18:16 CST, R156: "Now it's a texture and paint pass"; the board: the hull sides read as one noisy red, the
# concept has plate lines, panel breaks, a rust gradient and a dark olive lower hull):
#   panels   the hull (not the bolt-on parts) is cut into painted plates at the concept's scale: long plates on the sides, smaller
#            ones on the decks, big ones on the lower hull; a dark seam line between them, every plate its own tone, some rustier
#   rust     a gradient, not even specks: on the sides it is strongest under the deck edge, runs down in long streaks and gathers
#            under each plate seam (run-off), and fades out toward the lower hull; on the decks it sits in soft plate-shaped patches
#   lower    the lower hull (the tuck under the slab side and the belly) is dark olive, not black
#   bow      dusty light decks, darker and redder sides; drums darker and cooler
# Round 8 (Board brief, Nov 10; outside audit pass 2 finding 3 and R160: paint from the concept in layers, judged in the GAME's light):
#   layer 1  region colours SAMPLED FROM THE CONCEPT (docs/shots/ship_pipeline/route209/round8/README.md, step 3), set so they keep
#            their read under the game's own light (godot/render/look.gd: key energy 2 from above, AgX), not only in Blender:
#            the up-facing hull of the red front is a deck red (REGION_DECK), the bow deck brighter than the midship tops, and
#            the pale dust that went salmon pink in the game is cut to a thin dusting of the deck red itself
#   layer 2  rust in the concept's big orange blotches (BLOTCH: about 0.03 to 0.06 of the ship's length, on the decks and the
#            upper sides), not thin streaks
#   layer 3  wear and grime from the ship's own shape, as before (plates, seams, edge wear, AO, run-off)
#   not yet  CC0 material textures under the colour; NOT ALLOWED without Ryan's ruling: the concept projected onto the ship (R96 Q1); a light map, big
#            far-reading markings (finding 3 items 1, 2, 4, 5): see the round 8 README, "not done"
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
LIN = dict(rust=((.070, .0068, .0040), (.120, .0115, .0062)), gun=((.012, .013, .0145), (.021, .022, .024)),
           drum=((.0050, .0054, .0060), (.0090, .0095, .0105)),
           belly=((.066, .055, .030), (.090, .076, .041)), copper=((.090, .030, .016), (.150, .052, .026)),
           sleeve=((.030, .031, .034), (.050, .052, .058)), ochre=((.15, .090, .020), (.22, .14, .030)), rack=((.060, .011, .006), (.095, .018, .010)),
           hazard=((.36, .22, .015), (.44, .28, .02)), yellow=((.30, .19, .015), (.40, .26, .02)), white=((.36, .35, .32), (.46, .45, .41)), dark=((.004, .004, .005), (.007, .007, .008)),
           borrowed=((.040, .050, .062), (.050, .062, .076)), rustdk=((.022, .010, .008), (.034, .015, .011)))
DUST = dict(rust=((.50, .29, .25), 1.0), rack=((.12, .05, .035), .4), gun=((.075, .072, .072), .55), drum=((.03, .031, .033), .05), sleeve=((.08, .08, .082), .4))
PATCH = (.46, .074, .017)       # the concept's bright orange rust blooms (round 8: sampled from the concept's blotches, sRGB about 190, 82, 42)
PATCH2 = (.075, .011, .004)      # their darker rim
STREAK = (.050, .020, .010)     # rust run-off on gunmetal
WORN = (.16, .15, .135)         # bare steel on worn edges
GRIME_LOW = (.100, .078, .042)  # the concept's dark olive lower hull
Z_GRIME = (-.114, -.094)        # grime ramps in from z0 (full) to z1 (none): the slab side stays red, the tuck under it goes olive
# round 7: painted plates on the hull. (length, height) of a plate in ship lengths: side faces, decks, the lower hull
PANEL = dict(side=(.088, .043), deck=(.054, .047), belly=(.120, .064))
SEAM = .0012                    # seam line width
RUST_Z = (-.100, .004)          # side rust ramps in from the lower hull (none) to the deck edge (full)
PANEL_BANDS = ('rust', 'gun', 'belly', 'rustdk')
GRIT = ('rust', 'gun', 'belly', 'rustdk', 'rack', 'sleeve')
ROUGH = dict(borrowed=.55, rust=.93, rack=.93, drum=.93, belly=.92)   # base roughness per band (default .86)
# round 8, layer 1: deck reds from the concept (linear albedo before grime; sampled bow deck about sRGB 124, 85, 79 lit, the hump
# 144, 84, 75, the tier tops 49, 33, 31). Bow deck forward of the bow break line, the midship tops behind it. Under the game's key
# light (energy 2 from above) a deck reads about twice as bright as its albedo, so these sit well under the concept's lit values.
REGION_DECK = dict(bow=(.110, .036, .028), mid=(.070, .021, .016))
DECK_X = .178                   # the bow break line: the bow deck forward of it, the midship tops aft
DECK_DUST = ((.30, .13, .10), .32)    # a thin dusting of a pale deck red (round 7's .50, .29, .25 at full cover went salmon pink in the game)
# round 8, layer 2: the concept's big rust blotches (noise scale in ship lengths, coverage thresholds), decks and upper sides
BLOTCH = dict(scale=20.0, lo=.52, hi=.61, side=.85)

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
    # round 7: painted plates (hull only). Two brick layouts in the ship frame: side faces by (run along the side, z), decks and the
    # lower hull by (x, y). The run along the side is x minus a share of |y|, so the plates wrap round the bow instead of smearing,
    # and port and starboard get different layouts (nothing on a Hullbreaker ship matches).
    panels = group == 'H' and band in PANEL_BANDS
    seam = pv = runoff = None; dustf = 0.0; bm = 0.0
    if panels:
        def brick(vec, L, H, mortar=SEAM / 2, smooth=.1):
            b = node(nt, 'ShaderNodeTexBrick', offset=.5, offset_frequency=2); nt.links.new(vec, b.inputs['Vector'])
            b.inputs['Color1'].default_value = (0, 0, 0, 1); b.inputs['Color2'].default_value = (1, 1, 1, 1); b.inputs['Mortar'].default_value = (.5, .5, .5, 1)
            b.inputs['Scale'].default_value = 1; b.inputs['Mortar Size'].default_value = mortar; b.inputs['Mortar Smooth'].default_value = smooth
            b.inputs['Bias'].default_value = 0; b.inputs['Brick Width'].default_value = L; b.inputs['Row Height'].default_value = H
            return b.outputs['Fac'], b.outputs['Color']
        ay = math_(nt, 'ABSOLUTE', xyz.outputs['Y'])
        run = math_(nt, 'ADD', math_(nt, 'SUBTRACT', xyz.outputs['X'], math_(nt, 'MULTIPLY', ay, .6)), math_(nt, 'MULTIPLY', math_(nt, 'SIGN', xyz.outputs['Y']), .0137))
        vs = node(nt, 'ShaderNodeCombineXYZ'); nt.links.new(run, vs.inputs[0]); nt.links.new(xyz.outputs['Z'], vs.inputs[1])
        vd = node(nt, 'ShaderNodeCombineXYZ'); nt.links.new(xyz.outputs['X'], vd.inputs[0]); nt.links.new(xyz.outputs['Y'], vd.inputs[1])
        Ls, Hs = PANEL['belly' if band == 'belly' else 'side']; Ld, Hd = PANEL['belly' if band == 'belly' else 'deck']
        fs, cs = brick(vs.outputs[0], Ls, Hs); fd, cd = brick(vd.outputs[0], Ld, Hd)
        hs, _ = brick(vs.outputs[0], Ls, Hs, SEAM * 5, 1.0); hd, _ = brick(vd.outputs[0], Ld, Hd, SEAM * 5, 1.0)   # a soft band round each seam
        flatsel = ramp(nt, math_(nt, 'ABSOLUTE', nz.outputs['Z']), .45, .55)           # 1 on decks and the belly, 0 on side faces
        mx = node(nt, 'ShaderNodeMix', data_type='RGBA'); nt.links.new(flatsel, mx.inputs[0]); nt.links.new(cs, mx.inputs[6]); nt.links.new(cd, mx.inputs[7])
        sp = node(nt, 'ShaderNodeSeparateColor'); nt.links.new(mx.outputs[2], sp.inputs[0]); pv = sp.outputs[0]   # every plate its own 0..1
        seam = math_(nt, 'ADD', math_(nt, 'MULTIPLY', fs, math_(nt, 'SUBTRACT', 1, flatsel)), math_(nt, 'MULTIPLY', fd, flatsel), clamp=True)
        halo = math_(nt, 'ADD', math_(nt, 'MULTIPLY', hs, math_(nt, 'SUBTRACT', 1, flatsel)), math_(nt, 'MULTIPLY', hd, flatsel), clamp=True)
        rowf = math_(nt, 'FRACT', math_(nt, 'DIVIDE', xyz.outputs['Z'], Hs))            # 0 at a plate's bottom seam, 1 under its top seam
        runoff = math_(nt, 'MULTIPLY', ramp(nt, rowf, .25, 1.0), side)                  # run-off gathers under each horizontal seam
    ao = node(nt, 'ShaderNodeAmbientOcclusion', samples=16, only_local=False); ao.inputs['Distance'].default_value = .014
    bv = node(nt, 'ShaderNodeBevel', samples=6); bv.inputs['Radius'].default_value = .0009
    dot = node(nt, 'ShaderNodeVectorMath', operation='DOT_PRODUCT'); nt.links.new(geo.outputs['Normal'], dot.inputs[0]); nt.links.new(bv.outputs['Normal'], dot.inputs[1])
    fine = noise(46, 6, .6)
    edge = math_(nt, 'MULTIPLY', math_(nt, 'SUBTRACT', 1, dot.outputs['Value']), 18)
    edge = math_(nt, 'MULTIPLY', edge, ramp(nt, fine, .40, .60), clamp=True)          # broken-up wear
    edge = math_(nt, 'MULTIPLY', edge, ramp(nt, noise(4, 2), .35, .65))                # and only in some areas (handled, scraped)
    clean = band in ('borrowed', 'dark', 'white', 'hazard', 'yellow')
    if band == 'borrowed': edge = math_(nt, 'MULTIPLY', edge, .25)
    if band == 'drum': edge = math_(nt, 'MULTIPLY', edge, .08)                        # strapped drums: wear on the rims, not every strap
    # base: two tones in broad patches, a finer mottle on top
    col = mixc(nt, lo, hi, ramp(nt, noise(3.0, 3), .38, .66))
    col = mulc(nt, col, math_(nt, 'ADD', .82, math_(nt, 'MULTIPLY', noise(18, 4), .36)))
    sd = .80 if band in ('rust', 'rack') else .54                                    # round 7: darker, redder bow sides
    col = mulc(nt, col, math_(nt, 'ADD', sd, math_(nt, 'MULTIPLY', up, 1 - sd)))     # sides darker than decks (the concept's read)
    if panels: col = mulc(nt, col, math_(nt, 'ADD', .80, math_(nt, 'MULTIPLY', pv, .40)))   # every plate its own tone
    if band in GRIT:          # round 7: surface grit (fine mottle), broad stains, sparse dark chips: the concept's paint is never one flat tone
        col = mulc(nt, col, math_(nt, 'ADD', .86, math_(nt, 'MULTIPLY', noise(170, 3, .6), .28)))
        col = mulc(nt, col, math_(nt, 'ADD', .74, math_(nt, 'MULTIPLY', ramp(nt, noise(7, 4, .6), .30, .62), .30)))
        col = mulc(nt, col, math_(nt, 'SUBTRACT', 1, math_(nt, 'MULTIPLY', ramp(nt, noise(95, 2, .5), .66, .70), .45)))
    if panels and band != 'belly':   # each side plate a little darker toward its lower edge (stain gathers there)
        col = mulc(nt, col, math_(nt, 'SUBTRACT', 1, math_(nt, 'MULTIPLY', math_(nt, 'MULTIPLY', math_(nt, 'SUBTRACT', 1, ramp(nt, rowf, .0, .45)), side), .20)))
    if band == 'rust':        # round 8, layer 1: the deck red by region (bow deck, midship tops), on up-facing faces
        bowsel = ramp(nt, xyz.outputs['X'], DECK_X - .01, DECK_X + .01)
        dcol = mixc(nt, REGION_DECK['mid'], REGION_DECK['bow'], bowsel)
        dcol = mulc(nt, dcol, math_(nt, 'ADD', .80, math_(nt, 'MULTIPLY', noise(3.0, 3), .40)))
        if panels: dcol = mulc(nt, dcol, math_(nt, 'ADD', .82, math_(nt, 'MULTIPLY', pv, .36)))
        col = mixc(nt, col, dcol, ramp(nt, up, .55, .85))
    if band in DUST:          # dust and bleach on up-facing faces (the concept's light pink-grey bow deck, grey aft deck)
        dc, dk = DECK_DUST if band == 'rust' else DUST[band]      # round 8: the rust decks get a thin dusting only
        dustf = math_(nt, 'MULTIPLY', math_(nt, 'MULTIPLY', math_(nt, 'POWER', up, 4.0), dk), math_(nt, 'ADD', .45, math_(nt, 'MULTIPLY', ramp(nt, noise(5, 3), .10, .55), .55)), clamp=True)
        col = mixc(nt, col, dc, dustf)
    if band in ('rust', 'rack'):
        # round 7: a gradient with streaks and run-off, not even specks. Decks: soft plate-shaped patches under a broad mask.
        # Sides: strongest under the deck edge, long thin streaks running down, heavier under each plate seam, gone by the lower hull.
        blot = ramp(nt, noise(BLOTCH['scale'], 3, .55), BLOTCH['lo'], BLOTCH['hi'])        # round 8: the concept's big blotches
        speck = ramp(nt, noise(48, 6, .65), .57, .63)
        broad = ramp(nt, noise(2.5, 2), .28, .52)
        if panels: blot = math_(nt, 'MULTIPLY', blot, math_(nt, 'ADD', .70, math_(nt, 'MULTIPLY', pv, .30)))
        deck_r = math_(nt, 'MULTIPLY', math_(nt, 'MULTIPLY', up, math_(nt, 'ADD', .55, math_(nt, 'MULTIPLY', broad, .45))), math_(nt, 'ADD', blot, math_(nt, 'MULTIPLY', speck, .15)))
        zg = ramp(nt, xyz.outputs['Z'], RUST_Z[0], RUST_Z[1])
        strk = ramp(nt, stretched(55, 55, 1.0, 4, 3), .54, .72)
        side_r = math_(nt, 'ADD', math_(nt, 'MULTIPLY', strk, .40 if panels else .30), math_(nt, 'MULTIPLY', math_(nt, 'MULTIPLY', blot, zg), BLOTCH['side']))
        if panels: side_r = math_(nt, 'MULTIPLY', side_r, math_(nt, 'ADD', .55, math_(nt, 'MULTIPLY', runoff, .90)))
        side_r = math_(nt, 'MULTIPLY', math_(nt, 'MULTIPLY', side_r, zg), side)
        creep = 0.0
        if panels:      # rust creeping out of the seams, in broken stretches (not every seam, not all the way along)
            creep = math_(nt, 'MULTIPLY', math_(nt, 'MULTIPLY', halo, ramp(nt, noise(9, 3, .55), .46, .62)), math_(nt, 'ADD', .35, math_(nt, 'MULTIPLY', zg, .65)))
            creep = math_(nt, 'MULTIPLY', creep, .60)
        bm = math_(nt, 'MULTIPLY', math_(nt, 'ADD', math_(nt, 'ADD', deck_r, side_r), creep), ramp(nt, xyz.outputs['Z'], -.14, -.07), clamp=True)
        col = mixc(nt, col, PATCH2, math_(nt, 'MULTIPLY', ramp(nt, bm, .05, .30), .55))
        col = mixc(nt, col, PATCH, math_(nt, 'MULTIPLY', ramp(nt, bm, .38, .85), .85))
    if band in ('gun', 'sleeve', 'rustdk', 'drum'):
        run = math_(nt, 'MULTIPLY', ramp(nt, stretched(30, 30, 1.6, 4, 3), .55, .72), side)
        if panels: run = math_(nt, 'MULTIPLY', run, math_(nt, 'ADD', .45, math_(nt, 'MULTIPLY', runoff, 1.1)), clamp=True)
        col = mixc(nt, col, STREAK, math_(nt, 'MULTIPLY', run, .55 if band != 'drum' else .18))
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
    if panels:
        col = mulc(nt, col, math_(nt, 'SUBTRACT', 1, math_(nt, 'MULTIPLY', seam, .70)))                    # the seam line
        if band != 'belly':       # a dark stain bleeding down from each horizontal seam (side faces)
            col = mulc(nt, col, math_(nt, 'SUBTRACT', 1, math_(nt, 'MULTIPLY', math_(nt, 'MULTIPLY', ramp(nt, rowf, .80, 1.0), side), .22)))
    if band != 'dark':
        wc = (.30, .14, .07) if band == 'copper' else WORN
        col = mixc(nt, col, wc, math_(nt, 'MULTIPLY', edge, .75))
    rough = math_(nt, 'ADD', math_(nt, 'SUBTRACT', ROUGH.get(band, .86), math_(nt, 'MULTIPLY', edge, .32)), math_(nt, 'MULTIPLY', fine, .10))
    if panels: rough = math_(nt, 'ADD', rough, math_(nt, 'MULTIPLY', math_(nt, 'SUBTRACT', pv, .5), .12), clamp=True)   # plates differ in sheen
    # rust and rack: metalness so the sheen takes the paint's own red instead of greying it (white sheen on a dark red read mauve;
    # round 7 raises it from .38 to .70 with a brighter base, because the bow sides still read pink under the key light)
    m0 = .45 if band in ('copper', 'borrowed') else (.70 if band in ('rust', 'rack') else .15)
    if band == 'rust': m0 = math_(nt, 'SUBTRACT', .70, math_(nt, 'MULTIPLY', ramp(nt, up, .55, .85), .45))   # round 8: decks .25, sides .70
    if band in ('rust', 'rack'):      # dust and rust blooms are not metallic: they keep their own light colour
        m0 = math_(nt, 'MULTIPLY', m0, math_(nt, 'SUBTRACT', 1, math_(nt, 'MAXIMUM', math_(nt, 'MULTIPLY', dustf, .9), ramp(nt, bm, .30, .70)), clamp=True))
    metal = math_(nt, 'ADD', m0, math_(nt, 'MULTIPLY', edge, .65), clamp=True)
    nt.links.new(col, bs.inputs['Base Color']); nt.links.new(rough, bs.inputs['Roughness']); nt.links.new(metal, bs.inputs['Metallic'])
    orm = node(nt, 'ShaderNodeCombineColor'); orm.label = 'ORM'
    occ = ao.outputs['AO']
    if panels:
        occ = math_(nt, 'MULTIPLY', occ, math_(nt, 'SUBTRACT', 1, math_(nt, 'MULTIPLY', seam, .6)))
    nt.links.new(occ, orm.inputs[0]); nt.links.new(rough, orm.inputs[1]); nt.links.new(metal, orm.inputs[2])
    alb = node(nt, 'ShaderNodeMix', data_type='RGBA'); alb.label = 'ALBEDO'; alb.inputs[0].default_value = 0; nt.links.new(col, alb.inputs[6])
    m['p3_band'] = band; m['p3_group'] = group
    return m

# ------------------------------------------------------------------------------------------------ band assignment
FWD = -.100     # the concept's red ends where the aft body starts (behind the deckhouse tier)

def hull_band(c, n):
    # round 8: a downward face high on the ship (a deck plate's or the deck lip's underside) is not lower hull. The hull is one
    # joined mesh unwrapped by smart_project, and a thin plate becomes one island whose top and underside land on the same texels;
    # painting the underside as belly turned the bow deck plates olive (rounds 7 and 8's first bake). They take their region's band.
    if (n.z < -.5 and c.z < -.06) or c.z < -.150 or (c.z < -.106 and n.z < -.12): return 'belly'   # round 7: the tuck under the slab side is lower hull too
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
