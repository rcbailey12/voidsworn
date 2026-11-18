"""No-wear finishes for the Chorus sheet kit, using its existing organic zones."""
import os

import bpy
import numpy as np

from paint3 import math_, mixc, ramp


FINISH = os.environ.get('CHORUS_FINISH', 'flesh')
if FINISH not in ('flesh', 'chitin'):
    raise ValueError('CHORUS_FINISH must be flesh or chitin')

SCALE = 1.0
LAYERS = dict(ao_short=.013, ao_long=.045, edge_radius=.0008, edge_gain=16,
              bump_distance=.0005, bump_strength=.34)

# Linear RGB under the Chorus battle lift. Keep the actual joints, throats and
# organ seams soft in both takes. Callus and armour zones carry the harder shell.
ZONES = {
    'flesh': ((.105, .095, .042), (.044, .031, .012), .26),
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
    'flesh': ((.162, .139, .052), (.067, .058, .022), .38),
    'hide': ((.32, .22, .076), (.15, .112, .038), .42),
    'chitin': ((.44, .29, .088), (.21, .127, .041), .39),
    'bone': ((.50, .39, .21), (.28, .20, .102), .45),
}
if FINISH == 'chitin':
    ZONES.update(HARD_SHELL)

FALLBACK = 'flesh'
DECALS = ()
GLOW = {
    'bile': ((.47, .84, .036), 2.7),
    'bilewet': ((.27, .52, .026), .51),
    'membrane': ((.25, .34, .033), .38),
}
GLOW_HULL = tuple(GLOW)


def surface_layers(c, zone, tiles):
    nt = c.nt
    base, shade, roughness = ZONES[zone]
    shell = FINISH == 'chitin' and zone in HARD_SHELL
    # Draw lengthwise, wandering bundles rather than a lattice. A broad signal
    # under the bundles keeps the colour variation visible at battle distance.
    broad = c.noise(11, 3, .61, stretch=(.74, 1.25, 1.25))
    flow = c.noise(46 if shell else 38, 3, .64, stretch=(.31, 1.42, 1.42), w=.19)
    folds = ramp(nt, flow, .37, .62)
    recess = ramp(nt, c.ao, .86, .34)
    dark = math_(nt, 'MULTIPLY', folds, .44 if shell else .75)
    dark = math_(nt, 'MAXIMUM', dark, math_(nt, 'MULTIPLY', recess, .70))
    col = mixc(nt, base, shade, dark)
    col = mixc(nt, col, shade, math_(nt, 'MULTIPLY', ramp(nt, broad, .63, .36), .24))
    pores = c.noise(240, 2, .55)
    height = math_(nt, 'ADD', math_(nt, 'MULTIPLY', folds, -.19 if shell else -.32),
                   math_(nt, 'MULTIPLY', pores, .12 if shell else .055))
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
    return material
