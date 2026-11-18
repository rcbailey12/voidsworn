"""Polished blown glass, silver veins and stored light for the Glasswrights."""
import bpy
import numpy as np

from paint3 import math_, mixc, node, ramp


SCALE = 1.0
SOFT_RIM = False
LAYERS = dict(ao_short=.009, ao_long=.026, edge_radius=.0004, edge_gain=14,
              bump_distance=.00027, bump_strength=.26)

# Silver stays solid. The optical caps and vessel skin share the same PBR maps
# as their respective frames, with separate opacity on the actual glass.
GLASS = {
    'cd5_strand_glass': ((.53, .66, .73), (.82, .88, .91), .054, .86),
    'cd5_clear': ((.50, .67, .76), (.78, .88, .93), .047, .82),
    'cd5_body_clear': ((.50, .67, .76), (.78, .88, .93), .050, .84),
    'cd5_pearl': ((.49, .58, .65), (.75, .81, .85), .084, .86),
    'cd5_body_pearl': ((.56, .65, .71), (.81, .88, .91), .079, .86),
}
ZONES = {
    **GLASS,
    'cd5_silver': ((.55, .62, .68), (.77, .81, .86), .081, 1.0),
    'cd5_frame': ((.14, .22, .26), (.30, .38, .42), .12, .88),
}
FALLBACK = 'cd5_frame'
ZONE_OPACITY = dict.fromkeys(GLASS, .58)
ATLAS_OPACITY = {'H': ZONE_OPACITY['cd5_strand_glass']}
DECALS = ()

STORED_LIGHT = {
    'amber': ((1.0, .22, .008), 8.4),
    'violet': ((.40, .019, .91), 7.2),
    'green': ((.215, .61, .012), 5.5),
}
GLOW = {
    'cd5_white': ((.73, .86, 1.0), 13.0),
    'cd5_drive': ((.53, .51, .92), 8.0),
    'cd5_drive_core': ((.87, .90, 1.0), 19.0),
}
for colour, (rgb, power) in STORED_LIGHT.items():
    for zone, gain in ((colour, .72), (f'{colour}_deep', .22), (f'{colour}_hot', 1.32),
                       (f'pane_{colour}', .73), (f'sliver_{colour}', 1.0)):
        GLOW[f'cd5_{zone}'] = (rgb, power * gain)
GLOW_HULL = tuple(GLOW)


def surface_layers(c, zone, tiles):
    nt = c.nt
    low, high, roughness, metal = ZONES[zone]
    flow = c.noise(12, 2, .54, stretch=(.28, 1.28, 1.28))
    if zone == 'cd5_strand_glass':
        pearl = node(nt, 'ShaderNodeAttribute', attribute_name='pearl_flow')
        flow = math_(nt, 'ADD', math_(nt, 'MULTIPLY', pearl.outputs['Fac'], .73),
                     math_(nt, 'MULTIPLY', flow, .27))
    col = mixc(nt, low, high, ramp(nt, flow, .22, .76))
    rough = math_(nt, 'ADD', roughness, math_(nt, 'MULTIPLY', flow, .031))
    return col, flow, rough, metal


def trim_sheet():
    return {}


def decal_atlas():
    return np.zeros((2, 2, 4), dtype=np.float32)


def write_textures(folder, rows, decals):
    return []


def glow_material(zone, hull=False):
    rgb, power = GLOW[zone]
    material = bpy.data.materials.new(f'ithar_light_{zone}')
    material.use_nodes = True
    bsdf = material.node_tree.nodes.get('Principled BSDF')
    bsdf.inputs['Base Color'].default_value = tuple(v * .17 for v in rgb) + (1,)
    bsdf.inputs['Roughness'].default_value = .11
    bsdf.inputs['Emission Color'].default_value = (*rgb, 1)
    bsdf.inputs['Emission Strength'].default_value = power
    material['ps_glow'] = 1
    if hull:
        material['hull_surface'] = 1
    return material


def inside_material(zone):
    material = bpy.data.materials[zone].copy()
    material.name = f'ithar_inside_{zone}'
    bsdf = material.node_tree.nodes.get('Principled BSDF')
    rgb = bsdf.inputs['Base Color'].default_value
    bsdf.inputs['Base Color'].default_value = tuple(v * .20 for v in rgb[:3]) + (1,)
    bsdf.inputs['Emission Strength'].default_value *= .35
    bsdf.inputs['Transmission Weight'].default_value = 0.0
    material['ps_inside'] = 1
    return material
