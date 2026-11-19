"""The Chorus finish: dry shell, weathered bone and wet living tissue."""

import bpy
import numpy as np

from paint3 import math_, mixc, node, ramp


SCALE = 1.0
AUTHORED_LOOK = True
LAYERS = dict(ao_short=0.013, ao_long=0.045, edge_radius=0.0008, edge_gain=16,
              bump_distance=0.002, bump_strength=0.48)

# Linear RGB light and dark endpoints, with the zone's base roughness.
ZONES = {
    'flesh': ((.075, .067, .031), (.033, .027, .011), .26),
    'flesh2': ((.073, .053, .024), (.021, .013, .006), .28),
    'hide': ((.093, .078, .032), (.043, .034, .013), .28),
    'scar': ((.125, .091, .037), (.063, .044, .017), .37),
    'chitin': ((.128, .093, .031), (.060, .040, .013), .63),
    'bone': ((.52, .43, .27), (.26, .19, .10), .61),
    'tissue': ((.152, .086, .038), (.058, .029, .015), .23),
    'maw': ((.029, .019, .007), (.008, .005, .002), .19),
    'pore': ((.018, .013, .005), (.006, .004, .002), .31),
    'vein': ((.045, .067, .018), (.024, .029, .008), .23),
    'amber': ((.29, .15, .025), (.15, .066, .011), .55),
    'carapace': ((.135, .107, .047), (.063, .045, .018), .68),
    'carapace_joint': ((.043, .030, .015), (.018, .010, .005), .22),
}
FALLBACK = 'flesh'
DECALS = ()
GLOW = {
    'bile': ((.47, .84, .036), 2.7),
    'bilewet': ((.27, .52, .026), .51),
    'membrane': ((.25, .34, .033), .38),
    'maw_amber': ((.99, .53, .11), 2.7),
    'maw_amber_wet': ((.64, .25, .038), .51),
}
GLOW_HULL = ('bile', 'bilewet', 'membrane')


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
        tone = math_(nt, 'ADD', tone, math_(nt, 'MULTIPLY', plate_tone, .32))
        # Scatter fine growth marks near the free edge. The plate face has no repeating wave.
        margin = ramp(nt, progress, .65, .92)
        fine_marks = math_(nt, 'MULTIPLY', fine_marks, margin)
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
