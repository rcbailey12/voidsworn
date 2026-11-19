# The Glasswright (`ithar`) paint stack (issue 1183, R337; R333: one home, every Glasswright sheet ship uses it).
#
# What it must show (Ryan, Nov 18 2026: "glass like, so almost reflective", no wear; R337 Nov 19: the approved CD5 concept):
#   pearl   opaque, pearly white to warm champagne ribbons, highly reflective with a soft iridescent sheen, fine silk lines
#           along the ribbon; NO transmission, NO wear, NO grime
#   silver  fine bright silver lines along every ribbon edge
#   mosaic  leaf panels of small faceted cells, saturated amber, violet and green, glowing from inside, dark leading between
#           cells and a few sparkles; the main colour of the ship
#   gem     the round optics and stern lenses: faceted, glowing stones (violet for the drives)
#   tip     the forward lance tips: hot orange points
# Never see-through: every intact-hull material here has Transmission 0, so no interior can show (R337, the drift of 1058
# runs 2 to 6 was reading "glass" as clear glass).
#
# Colours SAMPLED from the approved concept docs/ship_pipeline/build_sheets/ithar_CD5/concept.jpg (k-means, pixels brighter
# than 40, sample_concept() below repeats it), sRGB as lit in the picture:
#   pearl  (250,239,238) 36%, (220,201,207) 21%, (186,166,170) 21%, (151,130,132) 22%   (low saturation, mean above 120)
#   amber  (226,155,88), (173,105,55), (122,60,19)      28% of the lit pixels: the dominant panel colour
#   violet (210,138,222), (155,71,151), (104,29,85)      8%
#   green  (172,200,92), (109,137,51), (66,90,17)       4%
# Panel weights follow those shares, with violet and green lifted so they still read at battle size (amber 55, violet 27,
# green 18). The concept is never projected: colours are numbers here, where each sits is the ship's geometry.
#
# This file builds the Cycles review materials the sheet renders with, and records the same values (LOOK) for the bake and
# the game material (look.gd authored_look, R329: Godot must not override them with older caps).
import math

def srgb(c):
    c = c / 255.0
    return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4


def lin(rgb):
    return tuple(srgb(c) for c in rgb)


CONCEPT = dict(
    pearl=[(250, 239, 238), (220, 201, 207), (186, 166, 170)],
    amber=[(226, 155, 88), (173, 105, 55), (122, 60, 19)],
    violet=[(210, 138, 222), (155, 71, 151), (104, 29, 85)],
    green=[(172, 200, 92), (109, 137, 51), (66, 90, 17)],
)
PALETTE = ('amber', 'violet', 'green')
WEIGHTS = (55, 27, 18)

# The glowing panel colour: the concept's bright tone pushed to full saturation (the panel glows, so it carries its own light).
GLOW = dict(amber=(0.88, 0.13, 0.0), violet=(0.42, 0.02, 0.95), green=(0.22, 0.75, 0.0))
# The bake marks its materials authored_look (shared paint_stack.py), so godot/render/look.gd keeps these values instead of
# applying the faction's older read caps (R329). No soft-rim mark: the pearl's own shine is the look.
AUTHORED_LOOK = True
SOFT_RIM = False
# The game and the bake read these (one home for the numbers, RULEBOOK 0.9).
LOOK = dict(
    pearl=dict(base=lin((240, 230, 226)), metallic=0.45, roughness=0.09, coat=1.0, coat_roughness=0.05,
               thin_film_nm=420.0, transmission=0.0, wear=0.0),
    silver=dict(base=(0.92, 0.91, 0.90), metallic=1.0, roughness=0.10, transmission=0.0),
    mosaic=dict(emission=1.1, roughness=0.06, coat=1.0, cell_scale=7.0, lead=0.05, sparkle=0.06, facet_tilt=0.8, transmission=0.0),
    gem=dict(emission=3.0, roughness=0.06, transmission=0.0),
    tip=dict(base=(1.0, 0.33, 0.05), emission=9.0),
)


def sample_concept(path):
    """repeat the k-means sampling above (needs numpy and PIL); prints the clusters"""
    import numpy as np
    from PIL import Image
    px = np.asarray(Image.open(path).convert('RGB')).astype(float).reshape(-1, 3)
    px = px[px.mean(1) > 40]
    r, g, b = px.T
    sat = px.max(1) - px.min(1)
    sel = dict(pearl=(sat < 45) & (px.mean(1) > 120), amber=(r > g * 1.25) & (g > b * 1.3) & (sat > 60),
               violet=(b > g * 1.3) & (r > g * 1.1) & (sat > 50), green=(g > r * 1.05) & (g > b * 1.4))
    out = {}
    for name, s in sel.items():
        pts = px[s]
        c = pts[np.random.default_rng(0).choice(len(pts), 3)]
        for _ in range(20):
            a = ((pts[:, None] - c[None]) ** 2).sum(2).argmin(1)
            c = np.array([pts[a == i].mean(0) if (a == i).any() else c[i] for i in range(3)])
        out[name] = dict(share=float(len(pts) / len(px)), clusters=[tuple(int(v) for v in cc) for cc in c])
    return out


# ------------------------------------------------------------------------------------------------ Cycles review materials
def _facets(nt, cells_colour, tilt):
    """each cell tilts its own way: the geometry normal plus the cell's random colour, so cells catch the light one by one
    like cut stones (flat facets, never noise grain)"""
    N, Ln = nt.nodes, nt.links
    geo = N.new('ShaderNodeNewGeometry')
    off = N.new('ShaderNodeVectorMath'); off.operation = 'SUBTRACT'; off.inputs[1].default_value = (0.5, 0.5, 0.5)
    Ln.new(cells_colour, off.inputs[0])
    sc = N.new('ShaderNodeVectorMath'); sc.operation = 'SCALE'; sc.inputs['Scale'].default_value = tilt
    Ln.new(off.outputs[0], sc.inputs[0])
    add = N.new('ShaderNodeVectorMath'); add.operation = 'ADD'
    Ln.new(geo.outputs['Normal'], add.inputs[0]); Ln.new(sc.outputs[0], add.inputs[1])
    nm = N.new('ShaderNodeVectorMath'); nm.operation = 'NORMALIZE'
    Ln.new(add.outputs[0], nm.inputs[0])
    return nm.outputs[0]


def _principled(m):
    nt = m.node_tree
    b = nt.nodes.get('Principled BSDF')
    if b is None:
        b = nt.nodes.new('ShaderNodeBsdfPrincipled')
        nt.links.new(b.outputs[0], nt.nodes.get('Material Output').inputs['Surface'])
    for k in ('Transmission Weight',):
        b.inputs[k].default_value = 0.0
    return b


def _new(name):
    import bpy
    m = bpy.data.materials.get(name) or bpy.data.materials.new(name)
    m.use_nodes = True
    return m


def pearl(name='gw_pearl', tint=None):
    """opaque reflective pearl ribbon with silk lines along it (attributes gw_along, gw_across from parts.Ribbon)"""
    L = LOOK['pearl']
    m = _new(name); nt = m.node_tree; N, Ln = nt.nodes, nt.links
    b = _principled(m)
    base = tint or L['base']
    b.inputs['Metallic'].default_value = L['metallic']
    b.inputs['Roughness'].default_value = L['roughness']
    b.inputs['Coat Weight'].default_value = L['coat']
    b.inputs['Coat Roughness'].default_value = L['coat_roughness']
    if 'Thin Film Thickness' in b.inputs:
        b.inputs['Thin Film Thickness'].default_value = L['thin_film_nm']
        b.inputs['Thin Film IOR'].default_value = 1.45
    b.inputs['Sheen Weight'].default_value = 0.35
    b.inputs['Sheen Tint'].default_value = (1.0, 0.86, 0.80, 1)
    # Silk lines: a soft wave across the ribbon, drifting along it, as a value and a faint bump (no noise grain).
    across = N.new('ShaderNodeAttribute'); across.attribute_name = 'gw_across'
    along = N.new('ShaderNodeAttribute'); along.attribute_name = 'gw_along'
    m1 = N.new('ShaderNodeMath'); m1.operation = 'MULTIPLY'; m1.inputs[1].default_value = 9.0
    m2 = N.new('ShaderNodeMath'); m2.operation = 'MULTIPLY'; m2.inputs[1].default_value = 7.0
    add = N.new('ShaderNodeMath'); add.operation = 'ADD'
    sin = N.new('ShaderNodeMath'); sin.operation = 'SINE'
    Ln.new(across.outputs['Fac'], m1.inputs[0]); Ln.new(along.outputs['Fac'], m2.inputs[0])
    Ln.new(m1.outputs[0], add.inputs[0]); Ln.new(m2.outputs[0], add.inputs[1]); Ln.new(add.outputs[0], sin.inputs[0])
    ramp = N.new('ShaderNodeValToRGB')
    ramp.color_ramp.elements[0].position = 0.0
    ramp.color_ramp.elements[0].color = tuple(c * 0.80 for c in base) + (1,)
    ramp.color_ramp.elements[1].color = tuple(min(1, c * 1.06) for c in base) + (1,)
    rescale = N.new('ShaderNodeMapRange'); rescale.inputs['From Min'].default_value = -1.0
    Ln.new(sin.outputs[0], rescale.inputs['Value']); Ln.new(rescale.outputs['Result'], ramp.inputs['Fac'])
    Ln.new(ramp.outputs['Color'], b.inputs['Base Color'])
    bump = N.new('ShaderNodeBump'); bump.inputs['Strength'].default_value = 0.12; bump.inputs['Distance'].default_value = 0.02
    Ln.new(rescale.outputs['Result'], bump.inputs['Height']); Ln.new(bump.outputs['Normal'], b.inputs['Normal'])
    m.diffuse_color = tuple(base) + (1,)
    return m


def silver(name='gw_silver'):
    L = LOOK['silver']
    m = _new(name); b = _principled(m)
    b.inputs['Base Color'].default_value = tuple(L['base']) + (1,)
    b.inputs['Metallic'].default_value = L['metallic']
    b.inputs['Roughness'].default_value = L['roughness']
    m.diffuse_color = tuple(L['base']) + (1,)
    return m


def mosaic(name='gw_mosaic'):
    """glowing stained-glass cells: tint and glow from the core's gw_tint / gw_glow attributes; dark leading between cells;
    each cell its own brightness and facet tilt; rare sparkles. Opaque."""
    L = LOOK['mosaic']
    m = _new(name); nt = m.node_tree; N, Ln = nt.nodes, nt.links
    b = _principled(m)
    b.inputs['Roughness'].default_value = L['roughness']
    b.inputs['Coat Weight'].default_value = L['coat']
    b.inputs['Coat Roughness'].default_value = 0.03
    b.inputs['Metallic'].default_value = 0.0
    tint = N.new('ShaderNodeAttribute'); tint.attribute_name = 'gw_tint'
    glow = N.new('ShaderNodeAttribute'); glow.attribute_name = 'gw_glow'
    tc = N.new('ShaderNodeTexCoord')
    cells = N.new('ShaderNodeTexVoronoi'); cells.voronoi_dimensions = '3D'; cells.inputs['Scale'].default_value = L['cell_scale']
    edges = N.new('ShaderNodeTexVoronoi'); edges.voronoi_dimensions = '3D'; edges.feature = 'DISTANCE_TO_EDGE'
    edges.inputs['Scale'].default_value = L['cell_scale']
    Ln.new(tc.outputs['Object'], cells.inputs['Vector']); Ln.new(tc.outputs['Object'], edges.inputs['Vector'])
    # per-cell brightness 0.55..1.35
    cr = N.new('ShaderNodeMapRange'); cr.inputs['To Min'].default_value = 0.25; cr.inputs['To Max'].default_value = 1.45
    sep = N.new('ShaderNodeSeparateColor')
    Ln.new(cells.outputs['Color'], sep.inputs['Color']); Ln.new(sep.outputs['Red'], cr.inputs['Value'])
    lead = N.new('ShaderNodeMapRange'); lead.inputs['From Min'].default_value = L['lead'] * 0.5
    lead.inputs['From Max'].default_value = L['lead']
    Ln.new(edges.outputs['Distance'], lead.inputs['Value'])  # 0 on the leading, 1 inside a cell
    k = N.new('ShaderNodeMath'); k.operation = 'MULTIPLY'
    Ln.new(cr.outputs['Result'], k.inputs[0]); Ln.new(lead.outputs['Result'], k.inputs[1])
    k2 = N.new('ShaderNodeMath'); k2.operation = 'MULTIPLY'
    Ln.new(k.outputs[0], k2.inputs[0]); Ln.new(glow.outputs['Fac'], k2.inputs[1])
    col = N.new('ShaderNodeMix'); col.data_type = 'RGBA'; col.blend_type = 'MULTIPLY'; col.inputs['Factor'].default_value = 1.0
    Ln.new(tint.outputs['Color'], col.inputs['A'])
    # base colour: the tint, darkened on the leading
    dark = N.new('ShaderNodeMix'); dark.data_type = 'RGBA'
    dark.inputs['B'].default_value = (0.22, 0.15, 0.08, 1)  # dark bronze leading between the cells (metal, so it glints)
    inv = N.new('ShaderNodeMath'); inv.operation = 'SUBTRACT'; inv.inputs[0].default_value = 1.0
    Ln.new(lead.outputs['Result'], inv.inputs[1])
    Ln.new(inv.outputs[0], dark.inputs['Factor'])
    Ln.new(inv.outputs[0], b.inputs['Metallic'])  # the leading is metal
    deep = N.new('ShaderNodeMix'); deep.data_type = 'RGBA'; deep.blend_type = 'MULTIPLY'; deep.inputs['Factor'].default_value = 1.0
    deep.inputs['B'].default_value = (0.18, 0.18, 0.18, 1)  # a deep body colour: the glow, not the lit surface, carries the hue
    Ln.new(tint.outputs['Color'], deep.inputs['A']); Ln.new(deep.outputs['Result'], dark.inputs['A'])
    Ln.new(dark.outputs['Result'], b.inputs['Base Color'])
    Ln.new(tint.outputs['Color'], b.inputs['Emission Color'])
    # sparkle: a few small cells far brighter
    sp = N.new('ShaderNodeTexVoronoi'); sp.voronoi_dimensions = '3D'; sp.inputs['Scale'].default_value = L['cell_scale'] * 3.1
    Ln.new(tc.outputs['Object'], sp.inputs['Vector'])
    sps = N.new('ShaderNodeSeparateColor'); Ln.new(sp.outputs['Color'], sps.inputs['Color'])
    spr = N.new('ShaderNodeMapRange'); spr.inputs['From Min'].default_value = 1 - L['sparkle']; spr.inputs['To Max'].default_value = 6.0
    spr.clamp = True
    Ln.new(sps.outputs['Green'], spr.inputs['Value'])
    tot = N.new('ShaderNodeMath'); tot.operation = 'ADD'
    Ln.new(k2.outputs[0], tot.inputs[0]); Ln.new(spr.outputs['Result'], tot.inputs[1])
    st = N.new('ShaderNodeMath'); st.operation = 'MULTIPLY'; st.inputs[1].default_value = L['emission']
    Ln.new(tot.outputs[0], st.inputs[0]); Ln.new(st.outputs[0], b.inputs['Emission Strength'])
    # facets: each cell tilts a little, so the cells catch the light separately
    Ln.new(_facets(nt, cells.outputs['Color'], L['facet_tilt']), b.inputs['Normal'])
    m.diffuse_color = (0.9, 0.45, 0.1, 1)
    return m


def gem(name, colour, strength=None, metallic=0.0, cut=False):
    """a faceted glowing stone: the optics and the stern lenses. Opaque; facets from coarse cells."""
    L = LOOK['gem']
    m = _new(name); nt = m.node_tree; N, Ln = nt.nodes, nt.links
    b = _principled(m)
    b.inputs['Base Color'].default_value = tuple(colour) + (1,)
    b.inputs['Emission Color'].default_value = tuple(colour) + (1,)
    b.inputs['Emission Strength'].default_value = strength or L['emission']
    b.inputs['Roughness'].default_value = L['roughness']
    b.inputs['Metallic'].default_value = metallic
    b.inputs['Coat Weight'].default_value = 1.0
    tc = N.new('ShaderNodeTexCoord')
    v = N.new('ShaderNodeTexVoronoi'); v.voronoi_dimensions = '3D'; v.inputs['Scale'].default_value = 7.0
    Ln.new(tc.outputs['Object'], v.inputs['Vector'])
    if cut:
        # a cut stone: each flat facet faces its own way, so each glows its own strength (light from inside the stone)
        lw = N.new('ShaderNodeLayerWeight'); lw.inputs['Blend'].default_value = 0.5
        # (Facing is 0 face-on, 1 at grazing: tilted facets glow brightest, the table facet stays a deep window)
        pw = N.new('ShaderNodeMath'); pw.operation = 'POWER'; pw.inputs[1].default_value = 0.7
        Ln.new(lw.outputs['Facing'], pw.inputs[0])
        ms = N.new('ShaderNodeMapRange'); ms.inputs['To Min'].default_value = strength or L['emission']
        ms.inputs['To Max'].default_value = 2.6
        Ln.new(pw.outputs[0], ms.inputs['Value']); Ln.new(ms.outputs['Result'], b.inputs['Emission Strength'])
    else:
        Ln.new(_facets(nt, v.outputs['Color'], 0.9), b.inputs['Normal'])
    m.diffuse_color = tuple(colour) + (1,)
    return m


def tip(name='gw_tip'):
    L = LOOK['tip']
    m = _new(name); b = _principled(m)
    b.inputs['Base Color'].default_value = tuple(L['base']) + (1,)
    b.inputs['Emission Color'].default_value = tuple(L['base']) + (1,)
    b.inputs['Emission Strength'].default_value = L['emission']
    m.diffuse_color = tuple(L['base']) + (1,)
    return m


def lance_pearl(name='gw_lance'):
    """the lances: pearl at the root shading to violet toward the tip (object x 0..10 in the lance's own frame)"""
    m = pearl(name)
    nt = m.node_tree; N, Ln = nt.nodes, nt.links
    b = nt.nodes.get('Principled BSDF')
    ramp_in = [l for l in nt.links if l.to_socket == b.inputs['Base Color']][0].from_node
    tc = N.new('ShaderNodeTexCoord'); sep = N.new('ShaderNodeSeparateXYZ')
    Ln.new(tc.outputs['Object'], sep.inputs['Vector'])
    mr = N.new('ShaderNodeMapRange'); mr.inputs['From Min'].default_value = 2.0; mr.inputs['From Max'].default_value = 9.5
    Ln.new(sep.outputs['X'], mr.inputs['Value'])
    mix = N.new('ShaderNodeMix'); mix.data_type = 'RGBA'
    mix.inputs['B'].default_value = tuple(GLOW['violet']) + (1,)
    Ln.new(mr.outputs['Result'], mix.inputs['Factor']); Ln.new(ramp_in.outputs['Color'], mix.inputs['A'])
    Ln.new(mix.outputs['Result'], b.inputs['Base Color'])
    em = N.new('ShaderNodeMath'); em.operation = 'MULTIPLY'; em.inputs[1].default_value = 1.2
    Ln.new(mr.outputs['Result'], em.inputs[0]); Ln.new(em.outputs[0], b.inputs['Emission Strength'])
    b.inputs['Emission Color'].default_value = tuple(GLOW['violet']) + (1,)
    return m


def setup(kit):
    """register every Glasswright material with the sheet kit (kit.MATS / kit.mat) and build their node trees"""
    made = {
        'gw_pearl': pearl(), 'gw_silver': silver(), 'gw_mosaic': mosaic(), 'gw_tip': tip(), 'gw_lance': lance_pearl(),
        'gw_gem_amber': gem('gw_gem_amber', GLOW['amber']), 'gw_gem_violet': gem('gw_gem_violet', GLOW['violet']),
        'gw_gem_green': gem('gw_gem_green', GLOW['green']),
        # the grown optic's root: the same stone, dimmer, so the lens reads as the bright point on it
        'gw_root_amber': gem('gw_root_amber', GLOW['amber'], 0.7), 'gw_root_violet': gem('gw_root_violet', GLOW['violet'], 0.7),
        'gw_root_green': gem('gw_root_green', GLOW['green'], 0.7),
        'gw_drive': gem('gw_drive', (0.62, 0.42, 1.0), 0.45),
        'gw_drive_cut': gem('gw_drive_cut', (0.78, 0.62, 1.0), 0.25, metallic=0.4, cut=True),
        'gw_drive_core': gem('gw_drive_core', (0.88, 0.80, 1.0), 1.6),
    }
    for name, m in made.items():
        kit.MATS[name] = (tuple(m.diffuse_color[:3]), 0)
    return made
