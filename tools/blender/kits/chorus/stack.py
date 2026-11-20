"""The Chorus finish: dry shell, weathered bone and wet living tissue."""

import bpy
import numpy as np

from paint3 import math_, mixc, node, ramp


SCALE = 1.0
AUTHORED_LOOK = True
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
    'vein': ((.060, .040, .016), (.024, .016, .007), .23),
    'amber': ((.29, .15, .025), (.15, .066, .011), .55),
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
    'maw_amber': ((.99, .53, .11), 2.7),
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


def surface_layers(c, zone, _tiles):
    nt = c.nt
    base, shade, roughness = ZONES[zone]
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
    return mixc(nt, base, shade, dark), height, rough, 0.0


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
    bsdf.inputs['Emission Color'].default_value = (*colour, 1)
    bsdf.inputs['Emission Strength'].default_value = power
    material['ps_glow'] = 1
    material['authored_look'] = 1
    if hull:
        material['hull_surface'] = 1
    return material


def inside_material(zone):
    material = bpy.data.materials[zone].copy()
    material.name = f'chorus_inside_{zone}'
    bsdf = material.node_tree.nodes.get('Principled BSDF')
    colour = bsdf.inputs['Base Color'].default_value
    bsdf.inputs['Base Color'].default_value = tuple(v * .54 for v in colour[:3]) + (1,)
    bsdf.inputs['Roughness'].default_value = .34
    material['ps_inside'] = 1
    material['authored_look'] = 1
    return material
