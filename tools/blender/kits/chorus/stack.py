"""No-wear finishes for the Chorus sheet kit, using its existing organic zones."""
import os

import bpy
import numpy as np

from paint3 import math_, mixc, node, ramp


FINISH = os.environ.get('CHORUS_FINISH', 'chitin')
if FINISH not in ('flesh', 'chitin'):
    raise ValueError('CHORUS_FINISH must be flesh or chitin')

SCALE = 1.0
AUTHORED_LOOK = True
LAYERS = dict(ao_short=.013, ao_long=.045, edge_radius=.0008, edge_gain=16,
              bump_distance=.006 if FINISH == 'chitin' else .0005,
              bump_strength=.78 if FINISH == 'chitin' else .34)

# Authored linear RGB. Keep the actual joints, throats and
# organ seams soft in both takes. Callus and armour zones carry the harder shell.
ZONES = {
    'flesh': ((.075, .067, .031), (.033, .027, .011), .26),
    'flesh2': ((.073, .053, .024), (.021, .013, .006), .28),
    'hide': ((.136, .124, .053), (.052, .039, .014), .25),
    'scar': ((.125, .091, .037), (.063, .044, .017), .37),
    'chitin': ((.26, .16, .048), (.12, .072, .023), .39),
    'bone': ((.49, .36, .18), (.24, .16, .07), .47),
    'tissue': ((.152, .086, .038), (.058, .029, .015), .23),
    'maw': ((.029, .019, .007), (.008, .005, .002), .19),
    'pore': ((.018, .013, .005), (.006, .004, .002), .31),
    'vein': ((.045, .067, .018), (.024, .029, .008), .23),
    'amber': ((.29, .15, .025), (.15, .066, .011), .55),
}
HARD_SHELL = {
    'hide': ((.093, .078, .032), (.043, .034, .013), .28),
    'chitin': ((.128, .093, .031), (.060, .040, .013), .63),
    'bone': ((.49, .36, .18), (.24, .16, .07), .63),
    'carapace': ((.129, .102, .037), (.048, .034, .011), .64),
    'carapace_joint': ((.041, .026, .012), (.016, .010, .005), .24),
}
if FINISH == 'chitin':
    ZONES.update(HARD_SHELL)
else:
    ZONES.update(carapace=ZONES['hide'], carapace_joint=ZONES['flesh2'])

FALLBACK = 'flesh'
DECALS = ()
GLOW = {
    'bile': ((.47, .84, .036), 2.7),
    'bilewet': ((.27, .52, .026), .51),
    'membrane': ((.25, .34, .033), .38),
}
GLOW_HULL = tuple(GLOW)


def growth_ridges(c, progress):
    """Curved growth fronts in the recipe's length-one ship coordinates."""
    nt = c.nt
    bend = math_(nt, 'ADD', math_(nt, 'MULTIPLY', c.y, c.y), math_(nt, 'MULTIPLY', c.z, c.z))
    wander = c.noise(7.0, 2, .54, stretch=(.62, .94, 1.25))
    front = math_(nt, 'ADD', c.x, math_(nt, 'MULTIPLY', bend, 3.2)) if progress is None else progress
    front = math_(nt, 'ADD', front, math_(nt, 'MULTIPLY', wander, .13))
    broad = math_(nt, 'SINE', math_(nt, 'MULTIPLY', front, 53.5))
    faint = math_(nt, 'SINE', math_(nt, 'MULTIPLY', front, 226.0))
    broken = ramp(nt, c.noise(18.0, 2, .64, stretch=(.59, 1.2, 1.2)), .24, .70)
    crest = math_(nt, 'MULTIPLY', ramp(nt, broad, -.22, .88), broken)
    groove = math_(nt, 'MULTIPLY', ramp(nt, broad, .06, -.91), broken)
    line = math_(nt, 'MULTIPLY', ramp(nt, faint, .48, .96), broken)
    return crest, groove, line


def hard_layers(c, zone, base, shade, roughness):
    nt = c.nt
    progress = None
    if zone == 'carapace':
        progress = node(nt, 'ShaderNodeAttribute', attribute_name='scute_progress').outputs['Fac']
    crest, groove, line = growth_ridges(c, progress)
    # The sheet's own overlapping shell and seams drive this shadow. The growth
    # ridges ride across the curved faces, with their finer lines inside each front.
    seam = ramp(nt, c.ao, .98, .62)
    cavity = ramp(nt, c.aol, .95, .51)
    depth = math_(nt, 'MAXIMUM', seam, math_(nt, 'MULTIPLY', cavity, .64))
    colour_flow = ramp(nt, c.noise(8.0, 3, .62, stretch=(.67, 1.28, 1.28)), .25, .75)
    tone = math_(nt, 'ADD', math_(nt, 'MULTIPLY', colour_flow, .59),
                 math_(nt, 'MULTIPLY', groove, .78), clamp=True)
    tone = math_(nt, 'MAXIMUM', tone, math_(nt, 'MULTIPLY', depth, .97))
    if progress is not None:
        variation = node(nt, 'ShaderNodeAttribute', attribute_name='scute_tone').outputs['Fac']
        tone = math_(nt, 'ADD', tone, math_(nt, 'MULTIPLY', variation, .39), clamp=True)
    col = mixc(nt, base, shade, tone)
    ridge_colour = tuple(v * gain for v, gain in zip(base, (1.62, 1.37, 1.08)))
    col = mixc(nt, col, ridge_colour, math_(nt, 'MULTIPLY', crest, .68))
    grain = c.noise(172, 3, .58, stretch=(.70, 1.50, 1.50), w=.19)
    height = math_(nt, 'ADD', math_(nt, 'MULTIPLY', crest, .55), math_(nt, 'MULTIPLY', groove, -.36))
    height = math_(nt, 'ADD', height, math_(nt, 'MULTIPLY', line, .17))
    height = math_(nt, 'ADD', height, math_(nt, 'MULTIPLY', grain, .19))
    height = math_(nt, 'SUBTRACT', height, math_(nt, 'MULTIPLY', depth, .28))
    rough = math_(nt, 'ADD', roughness, math_(nt, 'MULTIPLY', colour_flow, .15))
    rough = math_(nt, 'SUBTRACT', rough, math_(nt, 'MULTIPLY', crest, .16))
    rough = math_(nt, 'ADD', rough, math_(nt, 'MULTIPLY', depth, .24))
    rough = math_(nt, 'ADD', rough, math_(nt, 'MULTIPLY', grain, .07), clamp=True)
    if progress is not None:
        root = ramp(nt, progress, .32, .015)
        col = mixc(nt, col, (.025, .018, .007), math_(nt, 'MULTIPLY', root, .88))
        striations = ramp(nt, c.noise(180, 2, .57, stretch=(1.85, .54, .67)), .39, .68)
        pits = ramp(nt, c.noise(255, 2, .56), .33, .19)
        height = math_(nt, 'ADD', height, math_(nt, 'MULTIPLY', striations, .11))
        height = math_(nt, 'SUBTRACT', height, math_(nt, 'MULTIPLY', pits, .16))
        rough = math_(nt, 'ADD', rough, math_(nt, 'MULTIPLY', pits, .08))
        rough = math_(nt, 'MINIMUM', math_(nt, 'MAXIMUM', rough, .60), .80)
    return col, height, rough, 0.0


def surface_layers(c, zone, tiles):
    nt = c.nt
    base, shade, roughness = ZONES[zone]
    if FINISH == 'chitin' and zone in ('chitin', 'bone', 'carapace'):
        return hard_layers(c, zone, base, shade, roughness)
    broad = c.noise(11, 3, .61, stretch=(.74, 1.25, 1.25))
    flow = c.noise(38, 3, .64, stretch=(.31, 1.42, 1.42), w=.19)
    folds = ramp(nt, flow, .37, .62)
    recess = ramp(nt, c.ao, .86, .34)
    dark = math_(nt, 'MULTIPLY', folds, .75)
    dark = math_(nt, 'MAXIMUM', dark, math_(nt, 'MULTIPLY', recess, .70))
    col = mixc(nt, base, shade, dark)
    col = mixc(nt, col, shade, math_(nt, 'MULTIPLY', ramp(nt, broad, .63, .36), .24))
    pores = c.noise(240, 2, .55)
    height = math_(nt, 'ADD', math_(nt, 'MULTIPLY', folds, -.32), math_(nt, 'MULTIPLY', pores, .055))
    if FINISH == 'chitin':
        # The wet tissue still bends softly with the larger shell bump scale.
        height = math_(nt, 'MULTIPLY', height, .24)
    rough = math_(nt, 'ADD', roughness, math_(nt, 'MULTIPLY', folds, .05))
    return col, height, rough, 0.0


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
    source = bpy.data.materials[zone]
    material = source.copy()
    material.name = f'chorus_inside_{zone}'
    bsdf = material.node_tree.nodes.get('Principled BSDF')
    colour = bsdf.inputs['Base Color'].default_value
    bsdf.inputs['Base Color'].default_value = tuple(v * .54 for v in colour[:3]) + (1,)
    bsdf.inputs['Roughness'].default_value = .34
    material['ps_inside'] = 1
    material['authored_look'] = 1
    return material
