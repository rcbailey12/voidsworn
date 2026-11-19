"""No-wear neutral glass and ice-blue light for the Glasswrights."""
import bpy
import numpy as np

from paint3 import math_, mixc, node, ramp


SCALE = 1.0
SOFT_RIM = False
LAYERS = dict(ao_short=.009, ao_long=.026, edge_radius=.0004, edge_gain=14,
              bump_distance=.00035, bump_strength=.22)

# Neutral fallback and optical-depth mask. The review shader reads the red channel.
GLASS = {
    'cd5_strand_glass': (0.58, 0.16, 0.068),
    'cd5_clear': (0.52, 0.27, 0.052),
    'cd5_body_clear': (0.51, 0.19, 0.057),
}
SMOKE_GREY = 0.16
ZONES = {**GLASS, 'cd5_frame': (SMOKE_GREY, SMOKE_GREY, 0.46)}
FALLBACK = 'cd5_frame'
ZONE_OPACITY = dict.fromkeys(GLASS, 0.21)
ATLAS_OPACITY = {'H': ZONE_OPACITY['cd5_strand_glass']}
DECALS = ()

GLOW = {'cd5_white': ((0.94, 0.94, 0.94), 2.2)}


def surface_layers(c, zone, tiles):
    nt = c.nt
    low, high, roughness = ZONES[zone]
    height = math_(nt, 'ADD', 0.0, 0.0)
    rough = math_(nt, 'ADD', roughness, 0.0)
    flow = c.noise(12, 2, .54, stretch=(.28, 1.28, 1.28))
    if zone == 'cd5_strand_glass':
        pearl = node(nt, 'ShaderNodeAttribute', attribute_name='pearl_flow')
        flow = pearl.outputs['Fac']
    col = mixc(nt, (low,) * 3, (high,) * 3, ramp(nt, flow, .22, .76))
    return col, height, rough, 0.0


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
    bsdf.inputs['Base Color'].default_value = (*(v * 0.17 for v in rgb), 1)
    bsdf.inputs['Roughness'].default_value = 0.16
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
    bsdf.inputs['Base Color'].default_value = (SMOKE_GREY, SMOKE_GREY, SMOKE_GREY, 1)
    bsdf.inputs['Coat Weight'].default_value = 0.0
    material['ps_inside'] = 1
    return material
