"""The Chorus finish: dry shell, weathered bone and wet living tissue."""

import bpy
import numpy as np

from paint3 import math_, mixc, node, ramp


SCALE = 1.0
AUTHORED_LOOK = True
EMISSIVE_ATLAS = True
RECESS_AMBER = (.46, .19, .028)  # linear RGB at unit strength, below the battle glow threshold (0.8)
LAYERS = dict(ao_short=0.013, ao_long=0.045, edge_radius=0.0008, edge_gain=16,
              bump_distance=0.002, bump_strength=0.78)   # R341 round 3 (Neon): the horn grain holds at 1024 and 4096

# Linear RGB light and dark endpoints, with the zone's base roughness.
ZONES = {
    # R341 (Ryan, Nov 19): warm brown hide between the plates, not dark olive; round 3 (Neon): deep wet maroon-umber, well under
    # the horn so the plates separate at camera 170
    'flesh': ((.050, .025, .015), (.016, .008, .004), .20),
    'flesh2': ((.056, .026, .015), (.014, .006, .003), .22),
    'hide': ((.058, .030, .017), (.018, .009, .005), .22),
    'scar': ((.125, .081, .037), (.063, .038, .017), .37),
    'chitin': ((.128, .093, .031), (.060, .040, .013), .63),
    'bone': ((.52, .43, .27), (.26, .19, .10), .61),
    'tissue': ((.152, .076, .038), (.058, .026, .015), .23),
    'maw': ((.029, .019, .007), (.008, .005, .002), .19),
    'pore': ((.018, .013, .005), (.006, .004, .002), .31),
    'pit': ((.014, .009, .005), (.004, .003, .002), .9),   # issue 1291: dark open holes, matte (a wet disc flared white in C13 run J)
    'vein': ((.060, .040, .016), (.024, .016, .007), .23),
    # issue 1373: the spore's gill valleys read as flat yellow bars at the game's Chorus lift (look.gd READ 1.9); a muted
    # blush a step above the chitin keeps R259's "matte, never a glow" (only the spore craft uses this zone)
    'amber': ((.13, .072, .022), (.07, .036, .010), .5),
    # the armour shell: pale weathered horn on the keels and lips down to charred horn at the tucked roots (round 3)
    'carapace': ((.17, .122, .074), (.022, .014, .007), .55),
    'carapace_joint': ((.043, .030, .015), (.018, .010, .005), .22),
}
FALLBACK = 'flesh'
DECALS = ()
GLOW = {
    # R341: the bile light kept to the sac windows and deep in the vents, yellower and lower so no flat lime disc reads
    'bile': ((.52, .78, .06), 2.2),   # round 3 (Neon): the bile slits under the sac caps read as the Chorus at 170
    'bilewet': ((.22, .24, .03), .30),
    # R341: the trailing veils are dark torn membrane with a faint warm glow through them, not flat lime
    'membrane': ((.16, .06, .02), .12),
    # round 3 (Neon): a restrained yellow-green glow at the veils' roots and main ribs, the torn tips stay dark
    'veilroot': ((.45, .68, .06), 1.0),
    'maw_amber': ((.99, .53, .11), 1.5),   # issue 1291: dimmer, so the throat's glow is not a flat orange sign
    'maw_amber_wet': ((.64, .25, .038), .51),
}
GLOW_HULL = ('bile', 'bilewet', 'membrane', 'veilroot')


def hard_layers(c, zone, base, shade, roughness):
    nt = c.nt
    variation = ramp(nt, c.noise(9, 2, .57), .21, .78)
    contact = ramp(nt, c.ao, .98, .67)
    tone = math_(nt, 'ADD', math_(nt, 'MULTIPLY', variation, .30),
                 math_(nt, 'MULTIPLY', contact, .74))
    pits = ramp(nt, c.noise(290, 2, .53), .30, .16)
    height = math_(nt, 'MULTIPLY', pits, -.15)
    fine_marks = c.noise(198, 2, .52, stretch=(1.55, .51, .61))
    fine_marks = ramp(nt, fine_marks, .62, .86)
    if zone == 'carapace':
        progress = node(nt, 'ShaderNodeAttribute', attribute_name='scute_progress').outputs['Fac']
        plate_tone = node(nt, 'ShaderNodeAttribute', attribute_name='scute_tone').outputs['Fac']
        tone = math_(nt, 'ADD', tone, math_(nt, 'MULTIPLY', plate_tone, .26))
        # Scatter fine growth marks near the free edge.
        margin = ramp(nt, progress, .65, .92)
        fine_marks = math_(nt, 'MULTIPLY', fine_marks, margin)
        # R341, the keratin texture: grooves running the length of each scute (a pangolin's striations), growth lines parallel
        # to the free lip, the root dark where it slides under the scute ahead, the lip worn paler
        # (round 2, the Board: coarse and strong enough to read at camera 26; round 3, Neon: the keel crests and lips worn pale,
        # the grooves and roots dark and chalky, the crests waxy)
        crest = node(nt, 'ShaderNodeAttribute', attribute_name='scute_ridge').outputs['Fac']
        grain = ramp(nt, c.noise(50, 2, .4, stretch=(.12, 1.0, 1.0)), .46, .6)
        lines = ramp(nt, math_(nt, 'SINE', math_(nt, 'MULTIPLY', progress, 19.0)), .7, .97)
        lines = math_(nt, 'MULTIPLY', lines, ramp(nt, progress, .2, .55))
        pitted = ramp(nt, c.noise(64, 2, .55), .63, .72)
        root = math_(nt, 'SUBTRACT', 1.0, ramp(nt, progress, .04, .4))
        lip = ramp(nt, progress, .86, .99)
        worn = math_(nt, 'MAXIMUM', ramp(nt, crest, .55, .95), lip)
        tone = math_(nt, 'ADD', tone, math_(nt, 'MULTIPLY', grain, .4))
        tone = math_(nt, 'ADD', tone, math_(nt, 'MULTIPLY', lines, .25))
        tone = math_(nt, 'ADD', tone, math_(nt, 'MULTIPLY', pitted, .4))
        tone = math_(nt, 'ADD', tone, math_(nt, 'MULTIPLY', root, .7))
        tone = math_(nt, 'SUBTRACT', tone, math_(nt, 'MULTIPLY', worn, .75))
        height = math_(nt, 'ADD', height, math_(nt, 'MULTIPLY', grain, -.32))
        height = math_(nt, 'ADD', height, math_(nt, 'MULTIPLY', lines, -.14))
        height = math_(nt, 'ADD', height, math_(nt, 'MULTIPLY', pitted, -.25))
        # waxy 0.32 on the worn crests and lips, chalky 0.75 in the grooves and at the roots
        chalk = math_(nt, 'MAXIMUM', math_(nt, 'MAXIMUM', grain, root), pitted)
        roughness = math_(nt, 'ADD', .32, math_(nt, 'MULTIPLY', math_(nt, 'SUBTRACT', 1.0, worn), math_(nt, 'ADD', .18, math_(nt, 'MULTIPLY', chalk, .25))))
    tone = math_(nt, 'ADD', tone, math_(nt, 'MULTIPLY', fine_marks, .07), clamp=True)
    height = math_(nt, 'ADD', height, math_(nt, 'MULTIPLY', fine_marks, .10))
    rough = math_(nt, 'ADD', roughness, math_(nt, 'MULTIPLY', variation, .075))
    return mixc(nt, base, shade, tone), height, rough, 0.0


# ---------------------------------------------------------------------------------------------------- the grown look
# Issue 1291 (Ryan, Nov 20, on C13 in game: "the flesh just looks like red clay", "none of [the armour] looks right"; he agreed
# the colour: muddy olive-brown hide, dark red veins, bone-to-horn chitin, the yellow-green glow kept). Ryan accepted it in game
# on C13 round G (Nov 20, R349, PR 1308), so it is the family's default: every Chorus ship gets it unless its recipe json says
# "chorus_look": "r341" (C12's first round G trial, opus1291c12a, missed it because the grown look was still opt-in; Ryan
# caught the old skin on its sheet). Linear RGB.
def _look():
    import json, os
    try:
        with open(os.environ.get('R209_SHIP', ''), encoding='utf-8') as f:
            return json.load(f).get('chorus_look', 'grown')
    except (OSError, ValueError):
        return 'grown'


LOOK = _look()
if LOOK == 'grown':
    # issue 1291: the bile light lower, so the sacs' slits and the glands' depths read as a glow, not white streaks in game
    GLOW['bile'] = ((.52, .78, .06), 1.1)
    # the veils: tan leathery membrane with the warm light faint through it (the concept), not glossy maroon
    GLOW['membrane'] = ((.14, .055, .02), .06)   # round D: the warm light faint, so the veil reads as dark wet skin
    # deeper relief: the hide's creases must read in the light at camera 26, not only in the colour
    LAYERS.update(bump_distance=0.004, bump_strength=1.0)
GROWN = {
    # hide: muddy olive-brown, light and dark ends, base roughness (matte)
    'flesh': ((.112, .085, .046), (.024, .016, .009), .72),
    'flesh2': ((.098, .072, .039), (.020, .013, .007), .68),
    'hide': ((.106, .081, .044), (.022, .015, .008), .72),
    'scar': ((.13, .10, .06), (.05, .036, .02), .55),
    'tissue': ((.105, .052, .030), (.030, .013, .008), .38),   # raw transition tissue round the vents and spine roots: redder, wetter
    'vein': ((.050, .009, .007), (.016, .003, .002), .40),     # dark red blood vessels, never maroon flesh
    'pore': ((.062, .045, .026), (.030, .020, .012), .45),     # round D: a pit in the hide's own colour, never a black rivet
    'maw': ((.030, .012, .007), (.008, .003, .002), .22),
    'pit': ((.016, .007, .005), (.004, .002, .001), .9),
    # chitin grown out of the hide: pale bone on the worn crests and lips to dark horn at the roots
    'carapace': ((.056, .044, .026), (.013, .009, .005), .62),   # round D: darker, nearer the hide, rough
    'chitin': ((.20, .155, .085), (.04, .028, .013), .55),
}
VEIN_RED = (.045, .007, .006)
FOLD_RED = (.040, .010, .007)   # round D: the wet dark red deep in the folds (the concept's warm shadows)
PAD = (.15, .135, .09)   # the dusty crowns of the hide's pads
BONE = (.22, .18, .115)   # worn chitin at a lip (round D: duller)
MOTTLE = ((.072, .066, .034), (.068, .042, .024), (.036, .028, .018))   # greener, browner, darker patches of the hide


def _voronoi(c, scale, feature='F1', out='Distance'):
    nt = c.nt
    v = node(nt, 'ShaderNodeTexVoronoi', feature=feature)
    v.inputs['Scale'].default_value = scale
    if 'Randomness' in v.inputs:
        v.inputs['Randomness'].default_value = .9
    nt.links.new(c.pos, v.inputs['Vector'])
    return v.outputs[out]


def _ridge(c, scale, detail, stretch, w, lo, hi):
    """thin lines where a noise crosses its middle (wrinkles, veins)"""
    nt = c.nt
    n = c.noise(scale, detail, .55, stretch=stretch, w=w)
    band = math_(nt, 'SUBTRACT', 1.0, math_(nt, 'MULTIPLY', math_(nt, 'ABSOLUTE', math_(nt, 'SUBTRACT', n, .5)), 2.0))
    return ramp(nt, band, lo, hi)


def _recess_glow(c, zone, layers, detail):
    # R411: even the strongest vein or pore pattern needs short-range occlusion to glow.
    if zone in ('vein', 'pore'):
        detail = 1.0
    elif zone not in ('flesh', 'flesh2', 'hide'):
        return layers
    cavity = ramp(c.nt, c.ao, .90, .35)
    glow = math_(c.nt, 'MULTIPLY', cavity, detail)
    return (*layers, mixc(c.nt, (0.0, 0.0, 0.0), RECESS_AMBER, glow))


def grown_flesh(c, zone, base, shade, roughness):
    """the hide (issue 1291): elephant-skin creases and a crack network that read at camera 26, pores and fine grain for the
    close-up, dark red veins, broad olive and brown mottling; matte, wet only in the folds and cavities. The relief goes to
    the normal map (height) and the roughness as well as the colour, so the light shows it."""
    nt = c.nt
    folds = ramp(nt, c.noise(38, 3, .64, stretch=(.31, 1.42, 1.42), w=.19), .37, .62)
    recess = ramp(nt, c.ao, .9, .32)
    # wrinkles: two families of long creases (round the body and along it), each strong where a broad noise says so
    turn = ramp(nt, c.noise(5, 2, .5, w=4.2), .4, .6)
    wr_a = _ridge(c, 16.0, 3, (1.0, .32, .32), .37, .62, .93)
    wr_b = _ridge(c, 19.0, 3, (.3, 1.0, 1.0), 1.13, .62, .93)
    wr_c = _ridge(c, 42.0, 2, (1.0, .5, .5), 3.7, .76, .96)
    wr = math_(nt, 'MAXIMUM', math_(nt, 'MULTIPLY', wr_a, turn), math_(nt, 'MULTIPLY', wr_b, math_(nt, 'SUBTRACT', 1.0, turn)))
    wr = math_(nt, 'MAXIMUM', wr, math_(nt, 'MULTIPLY', wr_c, .7))
    fine = _ridge(c, 95.0, 2, (1.0, .45, .45), 2.9, .8, .97)
    # the crack network between the skin's raised pads (an elephant's hide), patchy
    edge = _voronoi(c, 62.0, 'DISTANCE_TO_EDGE')
    cracks = math_(nt, 'SUBTRACT', 1.0, ramp(nt, edge, .0, .07))
    cracks = math_(nt, 'MULTIPLY', cracks, math_(nt, 'MULTIPLY', ramp(nt, c.noise(7, 2, .5, w=1.7), .45, .65), .7))
    veins = _ridge(c, 11.0, 4, (.7, 1.0, 1.0), 2.3, .89, .985)   # round D: wider, so they read in game
    veins = math_(nt, 'MULTIPLY', veins, ramp(nt, c.noise(3, 2, .5, w=5.1), .42, .62))
    pores = math_(nt, 'SUBTRACT', 1.0, ramp(nt, _voronoi(c, 240.0), .04, .16))
    pores = math_(nt, 'MULTIPLY', pores, ramp(nt, c.noise(9, 2, .5, w=2.3), .45, .62))
    grain = c.noise(320, 2, .55)
    cavity = math_(nt, 'MAXIMUM', math_(nt, 'MULTIPLY', folds, .7), math_(nt, 'MULTIPLY', recess, .9))
    dark = math_(nt, 'MAXIMUM', cavity, math_(nt, 'MAXIMUM', math_(nt, 'MULTIPLY', wr, 1.0), math_(nt, 'MULTIPLY', cracks, .45)))
    dark = math_(nt, 'MAXIMUM', dark, math_(nt, 'MULTIPLY', fine, .55))
    # the raised pads between the creases catch the light paler (dust on the crowns)
    pads = math_(nt, 'MULTIPLY', ramp(nt, edge, .05, .2), math_(nt, 'SUBTRACT', 1.0, wr))
    col = mixc(nt, base, shade, dark)
    for k, mc in enumerate(MOTTLE):
        m = ramp(nt, c.noise(3.2 + 1.3 * k, 3, .55, w=.7 + 1.1 * k), .52, .7)
        col = mixc(nt, col, mc, math_(nt, 'MULTIPLY', m, .45))
    col = mixc(nt, col, VEIN_RED, math_(nt, 'MULTIPLY', veins, .95))
    deep = math_(nt, 'MULTIPLY', ramp(nt, folds, .65, .95), ramp(nt, c.ao, .7, .35))
    col = mixc(nt, col, FOLD_RED, math_(nt, 'MULTIPLY', deep, .45))
    col = mixc(nt, col, PAD, math_(nt, 'MULTIPLY', pads, .3))
    col = mixc(nt, col, shade, math_(nt, 'MULTIPLY', pores, .75))
    height = math_(nt, 'MULTIPLY', folds, -.12)
    height = math_(nt, 'ADD', height, math_(nt, 'MULTIPLY', wr, -.5))
    height = math_(nt, 'ADD', height, math_(nt, 'MULTIPLY', cracks, -.12))
    height = math_(nt, 'ADD', height, math_(nt, 'MULTIPLY', fine, -.08))
    height = math_(nt, 'ADD', height, math_(nt, 'MULTIPLY', veins, .22))
    height = math_(nt, 'ADD', height, math_(nt, 'MULTIPLY', pores, -.18))
    height = math_(nt, 'ADD', height, math_(nt, 'MULTIPLY', grain, .04))
    # wet only deep in the folds and the cavities (the concept's skin is matte; a wet sheen all over read as glossy clay)
    wet = math_(nt, 'MAXIMUM', math_(nt, 'MULTIPLY', folds, .6), ramp(nt, c.ao, .55, .2))
    wet = math_(nt, 'MAXIMUM', wet, math_(nt, 'MULTIPLY', deep, .8))
    rough = math_(nt, 'SUBTRACT', roughness, math_(nt, 'MULTIPLY', wet, max(0.0, roughness - .12)))
    rough = math_(nt, 'ADD', rough, math_(nt, 'MULTIPLY', c.noise(9, 2, .5), .08), clamp=True)
    slits_and_pores = math_(nt, 'MAXIMUM', wr, pores)
    return _recess_glow(c, zone, (col, height, rough, 0.0), slits_and_pores)


def grown_chitin(c, zone, base, shade, roughness):
    """the grown shell (issue 1291): dark horn at the root where it grows out of the hide, paling to bone on the ridges and the
    worn lip, fine growth lines across it and a fibrous grain along it; no blotches (a mottle read as camouflage paint)"""
    nt = c.nt
    progress = node(nt, 'ShaderNodeAttribute', attribute_name='scute_progress').outputs['Fac']
    crest = node(nt, 'ShaderNodeAttribute', attribute_name='scute_ridge').outputs['Fac']
    plate_tone = node(nt, 'ShaderNodeAttribute', attribute_name='scute_tone').outputs['Fac']
    root = math_(nt, 'SUBTRACT', 1.0, ramp(nt, progress, .05, .55))
    pale = math_(nt, 'MAXIMUM', ramp(nt, crest, .45, .9), ramp(nt, progress, .85, .99))
    # round D: the growth lines wander (a noise added to the progress), so they read as grown, not machined
    warp = math_(nt, 'MULTIPLY', c.noise(14, 2, .5), .08)
    lines = ramp(nt, math_(nt, 'SINE', math_(nt, 'MULTIPLY', math_(nt, 'ADD', progress, warp), 41.0)), .62, .97)
    grain = ramp(nt, c.noise(60, 3, .45, stretch=(.15, 1.0, 1.0)), .4, .65)
    pits = math_(nt, 'SUBTRACT', 1.0, ramp(nt, _voronoi(c, 180.0), .03, .12))
    contact = ramp(nt, c.ao, .95, .5)
    dark = math_(nt, 'ADD', math_(nt, 'MULTIPLY', root, .75), math_(nt, 'MULTIPLY', contact, .5))
    dark = math_(nt, 'ADD', dark, math_(nt, 'MULTIPLY', lines, .12))
    dark = math_(nt, 'ADD', dark, math_(nt, 'MULTIPLY', grain, .22))
    dark = math_(nt, 'ADD', dark, math_(nt, 'MULTIPLY', plate_tone, .15))
    mott = ramp(nt, c.noise(4.5, 3, .55, w=2.9), .4, .7)
    dark = math_(nt, 'ADD', dark, math_(nt, 'MULTIPLY', mott, .25))
    dark = math_(nt, 'SUBTRACT', dark, math_(nt, 'MULTIPLY', pale, .15), clamp=True)
    col = mixc(nt, base, shade, dark)
    col = mixc(nt, col, BONE, math_(nt, 'MULTIPLY', ramp(nt, progress, .9, 1.0), .3))   # the worn lip pales toward bone
    height = math_(nt, 'ADD', math_(nt, 'MULTIPLY', lines, -.2), math_(nt, 'MULTIPLY', grain, -.18))
    height = math_(nt, 'ADD', height, math_(nt, 'MULTIPLY', pits, -.15))
    rough = math_(nt, 'ADD', .5, math_(nt, 'MULTIPLY', math_(nt, 'SUBTRACT', 1.0, pale), math_(nt, 'ADD', .12, math_(nt, 'MULTIPLY', grain, .2))))
    return col, height, rough, 0.0


def surface_layers(c, zone, _tiles):
    nt = c.nt
    base, shade, roughness = ZONES[zone]
    if LOOK == 'grown' and zone in GROWN:
        base, shade, roughness = GROWN[zone]
        if zone == 'carapace':
            return grown_chitin(c, zone, base, shade, roughness)
        if zone not in ('chitin', 'bone', 'maw', 'pore', 'pit'):
            return grown_flesh(c, zone, base, shade, roughness)
    if zone in ('chitin', 'bone', 'carapace'):
        return hard_layers(c, zone, base, shade, roughness)
    folds = ramp(nt, c.noise(38, 3, .64, stretch=(.31, 1.42, 1.42), w=.19), .37, .62)
    recess = ramp(nt, c.ao, .86, .34)
    dark = math_(nt, 'MAXIMUM', math_(nt, 'MULTIPLY', folds, .75),
                 math_(nt, 'MULTIPLY', recess, .70))
    pores = c.noise(240, 2, .55)
    height = math_(nt, 'ADD', math_(nt, 'MULTIPLY', folds, -.10),
                   math_(nt, 'MULTIPLY', pores, .025))
    rough = math_(nt, 'ADD', roughness, math_(nt, 'MULTIPLY', folds, .05))
    layers = mixc(nt, base, shade, dark), height, rough, 0.0
    return _recess_glow(c, zone, layers, ramp(nt, folds, .65, .95))


def trim_sheet():
    return {}


def decal_atlas():
    return np.zeros((2, 2, 4), dtype=np.float32)


def write_textures(folder, rows, decals):
    return []


def glow_material(zone, hull=False):
    colour, power = GLOW[zone]
    material = bpy.data.materials.new(f'chorus_light_{zone}')
    material.use_nodes = True
    bsdf = material.node_tree.nodes.get('Principled BSDF')
    bsdf.inputs['Base Color'].default_value = (*[v * .14 for v in colour], 1)
    bsdf.inputs['Roughness'].default_value = .25
    if LOOK == 'grown' and zone == 'membrane':
        # issue 1291 round D: the veils as dark wet skin in the hide's colour, not pale paper. The glow materials export as
        # plain glTF factors (no baked map), so a node pattern here would export white: colour and roughness only.
        bsdf.inputs['Base Color'].default_value = (.040, .029, .017, 1)
        # run E: .34 caught the rim light as hot white spots at the veil tips (runs D2 and D3). A glTF factor cannot vary along
        # the veil, so the whole veil goes satin: still a sheen, no pinpoint highlight.
        bsdf.inputs['Roughness'].default_value = .6
    bsdf.inputs['Emission Color'].default_value = (*colour, 1)
    bsdf.inputs['Emission Strength'].default_value = power
    material['ps_glow'] = 1
    # issue 1291 run D2: the wet veils caught LookRim's full specular as hot white spots at the tips. Like the Eclipse and
    # Hegemony glow materials, they take the soft rim (godot/render/look.gd) that the baked hull and parts already get.
    material['rim_soft'] = 1
    material['authored_look'] = 1
    if hull:
        material['hull_surface'] = 1
    return material


# Interior Kit V2 (issue 1743, R416 Layer 3): the shared trim maps (tools/blender/kits/shared/interior_trim.py) as wet flesh:
# cells, raised dark red veins, pores, a little bile yellow-green light in some veins; no metal, never magenta or maroon
# (factions.md, the Chorus: inside flesh and bone, wet and lit from within).
INSIDE_TRIM = dict(style='flesh', seed=1747, cells=170, vein_w=7.0, warp=0.05, relief=5.0, rough=(0.26, 0.5), flesh_tone=(1.0, 0.95, 0.7),
                   vein_tone=(0.55, 0.12, 0.08), glow=dict(rgb=(0.55, 0.85, 0.08), share=0.2, strength=0.6))


def inside_material(zone, trim=False):
    """trim: the insides carry the Interior Kit V2 UVs, so the zone takes the Chorus trim maps (issue 1743)"""
    if trim:
        import os, sys
        sh_ = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'shared')
        if sh_ not in sys.path: sys.path.insert(0, sh_)
        import interior_trim
        sb = bpy.data.materials[zone].node_tree.nodes.get('Principled BSDF')
        col = tuple(sb.inputs['Base Color'].default_value)[:3]; em = sb.inputs['Emission Strength'].default_value
        m = interior_trim.trim_material(f'chorus_inside_{zone}', 'chorus', INSIDE_TRIM, tuple(min(.5, v * .54) for v in col),
                                        emission=(tuple(sb.inputs['Emission Color'].default_value)[:3], em) if em > 0 else None)
        m['authored_look'] = 1
        return m
    material = bpy.data.materials[zone].copy()
    material.name = f'chorus_inside_{zone}'
    bsdf = material.node_tree.nodes.get('Principled BSDF')
    colour = bsdf.inputs['Base Color'].default_value
    bsdf.inputs['Base Color'].default_value = tuple(v * .54 for v in colour[:3]) + (1,)
    bsdf.inputs['Roughness'].default_value = .34
    material['ps_inside'] = 1
    material['authored_look'] = 1
    return material
