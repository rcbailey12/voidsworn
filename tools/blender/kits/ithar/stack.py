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

# The glowing panel colour (PANEL; GLOW below is the bake's list of glowing stone zones): the concept's bright tone pushed to
# full saturation (the panel glows, so it carries its own light). Round 5: emerald, not lime.
PANEL = dict(amber=(0.88, 0.13, 0.0), violet=(0.42, 0.02, 0.95), green=(0.03, 0.55, 0.10))
# Round 5 (outside read, Nov 19: "flat orange, purple and lime gravel"): each panel is lit from behind, so its colour runs
# from a DEEP tone at the lead border to a HOT tone in the middle (parts.mosaic_tint writes the graded colour per vertex).
# Stored light, the seafoam of the faction's data glow #9fffd2 (issue 1415: the fleet hulls' cleft, star torpedo, hangar floor).
LIGHT = (0.35, 1.0, 0.64)
TONES = dict(amber=((0.40, 0.035, 0.0), (1.0, 0.40, 0.015)),
             violet=((0.13, 0.0, 0.36), (0.62, 0.10, 1.0)),
             green=((0.0, 0.18, 0.03), (0.20, 0.78, 0.04)))
# The bake marks its materials authored_look (shared paint_stack.py), so godot/render/look.gd keeps these values instead of
# applying the faction's older read caps (R329). No soft-rim mark: the pearl's own shine is the look.
AUTHORED_LOOK = True
SOFT_RIM = False
# The game and the bake read these (one home for the numbers, RULEBOOK 0.9).
LOOK = dict(
    # Round 5: each ribbon is a bundle of fine strands (STRANDS across it), each strand its own pearl tone with a bright
    # silver line between strands, and a facing colour shift (the iridescence) that the review shows and the game's rim
    # approximates. Tones sampled from the concept's pearl clusters.
    pearl=dict(base=lin((246, 236, 228)), tones=(lin((252, 238, 226)), lin((240, 212, 214)), lin((240, 222, 190)),
                                                 lin((228, 214, 232))),
               iris=(lin((255, 214, 150)), lin((240, 170, 205)), lin((175, 170, 245)), lin((160, 225, 225))),
               iris_weight=0.60, strands=7.0, line=0.07, metallic=0.55, roughness=0.08, coat=1.0, coat_roughness=0.04,
               thin_film_nm=520.0, transmission=0.0, wear=0.0),
    silver=dict(base=(0.92, 0.91, 0.90), metallic=1.0, roughness=0.10, transmission=0.0),
    mosaic=dict(emission=2.6, roughness=0.10, coat=0.35, cell_scale=4.2, lead=0.045, sparkle=0.006, facet_tilt=0.45,
                body=0.08, cell_lo=0.55, cell_hi=1.2, lead_rgb=(0.035, 0.026, 0.018), transmission=0.0),
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


def _m(nt, op, a, b=0.0):
    """one math node; a and b are sockets or numbers"""
    n = nt.nodes.new('ShaderNodeMath'); n.operation = op
    for k, v in enumerate((a, b)):
        if isinstance(v, (int, float)):
            n.inputs[k].default_value = v
        else:
            nt.links.new(v, n.inputs[k])
    return n.outputs[0]


def _mix(nt, a, b, f):
    """colour mix; a, b sockets or rgb tuples, f socket or number"""
    n = nt.nodes.new('ShaderNodeMix'); n.data_type = 'RGBA'
    for sock, v in ((n.inputs['A'], a), (n.inputs['B'], b), (n.inputs['Factor'], f)):
        if isinstance(v, (int, float)):
            sock.default_value = v
        elif isinstance(v, tuple):
            sock.default_value = tuple(v[:3]) + (1,)
        else:
            nt.links.new(v, sock)
    return n.outputs['Result']


def strands(nt, across, along):
    """the fine strands of a pearl ribbon: (strand colour, height 0..1, silver line mask 0..1). A strand wanders a little
    along the ribbon; neighbours take different pearl tones; a bright silver line runs between every two strands."""
    L = LOOK['pearl']
    n = L['strands']
    wander = _m(nt, 'MULTIPLY', _m(nt, 'SINE', _m(nt, 'ADD', _m(nt, 'MULTIPLY', along, 19.0), _m(nt, 'MULTIPLY', across, 2.3))), 0.28)
    s = _m(nt, 'ADD', _m(nt, 'MULTIPLY', _m(nt, 'ADD', across, 1.0), n * 0.5), wander)
    fr = _m(nt, 'FRACT', s)
    idx = _m(nt, 'FLOOR', s)
    h = _m(nt, 'FRACT', _m(nt, 'MULTIPLY', _m(nt, 'SINE', _m(nt, 'MULTIPLY', idx, 12.9898)), 43758.5453))
    t = L['tones']
    col = _mix(nt, _mix(nt, t[0], t[1], _m(nt, 'GREATER_THAN', h, 0.55)), _mix(nt, t[2], t[3], _m(nt, 'GREATER_THAN', h, 0.30)),
               _m(nt, 'LESS_THAN', h, 0.45))
    height = _m(nt, 'POWER', _m(nt, 'MAXIMUM', _m(nt, 'SINE', _m(nt, 'MULTIPLY', fr, math.pi)), 0.0), 0.5)
    edge = _m(nt, 'MINIMUM', fr, _m(nt, 'SUBTRACT', 1.0, fr))
    line = _m(nt, 'SUBTRACT', 1.0, _m(nt, 'MINIMUM', _m(nt, 'DIVIDE', edge, L['line']), 1.0))
    return col, height, line


def pearl(name='gw_pearl', tint=None):
    """opaque reflective pearl ribbon made of fine strands with silver lines (attributes gw_along, gw_across from
    parts.Ribbon) and a facing colour shift (iridescence)"""
    L = LOOK['pearl']
    m = _new(name); nt = m.node_tree; N, Ln = nt.nodes, nt.links
    b = _principled(m)
    base = tint or L['base']
    b.inputs['Coat Weight'].default_value = L['coat']
    b.inputs['Coat Roughness'].default_value = L['coat_roughness']
    if 'Thin Film Thickness' in b.inputs:
        b.inputs['Thin Film Thickness'].default_value = L['thin_film_nm']
        b.inputs['Thin Film IOR'].default_value = 1.8
    across = N.new('ShaderNodeAttribute'); across.attribute_name = 'gw_across'
    along = N.new('ShaderNodeAttribute'); along.attribute_name = 'gw_along'
    col, height, line = strands(nt, across.outputs['Fac'], along.outputs['Fac'])
    # iridescence: the colour shifts gold -> rose -> lilac -> aqua as the surface turns from the eye
    lw = N.new('ShaderNodeLayerWeight'); lw.inputs['Blend'].default_value = 0.45
    ramp = N.new('ShaderNodeValToRGB'); cr = ramp.color_ramp
    iris = L['iris']
    cr.elements[0].position = 0.15; cr.elements[0].color = tuple(iris[0]) + (1,)
    cr.elements[1].position = 0.85; cr.elements[1].color = tuple(iris[3]) + (1,)
    for pos, c in ((0.38, iris[1]), (0.62, iris[2])):
        e = cr.elements.new(pos); e.color = tuple(c) + (1,)
    # the strand phase shifts the colour band too, so neighbouring strands shimmer differently
    ph = _m(nt, 'FRACT', _m(nt, 'ADD', lw.outputs['Facing'], _m(nt, 'MULTIPLY', height, 0.18)))
    Ln.new(ph, ramp.inputs['Fac'])
    irisw = _m(nt, 'MULTIPLY', _m(nt, 'POWER', lw.outputs['Facing'], 0.8), L['iris_weight'])
    col = _mix(nt, col, ramp.outputs['Color'], irisw)
    col = _mix(nt, col, (0.97, 0.96, 0.95), line)
    Ln.new(col, b.inputs['Base Color'])
    Ln.new(_m(nt, 'ADD', L['metallic'], _m(nt, 'MULTIPLY', line, 1 - L['metallic'])), b.inputs['Metallic'])
    Ln.new(_m(nt, 'SUBTRACT', L['roughness'], _m(nt, 'MULTIPLY', line, 0.04)), b.inputs['Roughness'])
    bump = N.new('ShaderNodeBump'); bump.inputs['Strength'].default_value = 0.35; bump.inputs['Distance'].default_value = 0.02
    Ln.new(_m(nt, 'SUBTRACT', height, _m(nt, 'MULTIPLY', line, 0.4)), bump.inputs['Height'])
    Ln.new(bump.outputs['Normal'], b.inputs['Normal'])
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
    # per-cell brightness (round 5: a narrower spread, so the panel reads as one lit leaf, not gravel)
    cr = N.new('ShaderNodeMapRange'); cr.inputs['To Min'].default_value = L['cell_lo']; cr.inputs['To Max'].default_value = L['cell_hi']
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
    dark.inputs['B'].default_value = tuple(L['lead_rgb']) + (1,)  # dark leading between the cells (metal, so it glints)
    inv = N.new('ShaderNodeMath'); inv.operation = 'SUBTRACT'; inv.inputs[0].default_value = 1.0
    Ln.new(lead.outputs['Result'], inv.inputs[1])
    Ln.new(inv.outputs[0], dark.inputs['Factor'])
    Ln.new(inv.outputs[0], b.inputs['Metallic'])  # the leading is metal
    deep = N.new('ShaderNodeMix'); deep.data_type = 'RGBA'; deep.blend_type = 'MULTIPLY'; deep.inputs['Factor'].default_value = 1.0
    deep.inputs['B'].default_value = (L['body'],) * 3 + (1,)  # a deep body colour: the glow, not the lit surface, carries the hue
    Ln.new(tint.outputs['Color'], deep.inputs['A']); Ln.new(deep.outputs['Result'], dark.inputs['A'])
    Ln.new(dark.outputs['Result'], b.inputs['Base Color'])
    Ln.new(tint.outputs['Color'], b.inputs['Emission Color'])
    # sparkle: a few small cells far brighter
    sp = N.new('ShaderNodeTexVoronoi'); sp.voronoi_dimensions = '3D'; sp.inputs['Scale'].default_value = L['cell_scale'] * 3.1
    Ln.new(tc.outputs['Object'], sp.inputs['Vector'])
    sps = N.new('ShaderNodeSeparateColor'); Ln.new(sp.outputs['Color'], sps.inputs['Color'])
    spr = N.new('ShaderNodeMapRange'); spr.inputs['From Min'].default_value = 1 - L['sparkle']; spr.inputs['To Max'].default_value = 2.5
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
    ramp_in = [l for l in nt.links if l.to_socket == b.inputs['Base Color']][0].from_socket
    tc = N.new('ShaderNodeTexCoord'); sep = N.new('ShaderNodeSeparateXYZ')
    Ln.new(tc.outputs['Object'], sep.inputs['Vector'])
    mr = N.new('ShaderNodeMapRange'); mr.inputs['From Min'].default_value = 2.0; mr.inputs['From Max'].default_value = 9.5
    Ln.new(sep.outputs['X'], mr.inputs['Value'])
    mix = N.new('ShaderNodeMix'); mix.data_type = 'RGBA'
    mix.inputs['B'].default_value = tuple(PANEL['violet']) + (1,)
    Ln.new(mr.outputs['Result'], mix.inputs['Factor']); Ln.new(ramp_in, mix.inputs['A'])
    Ln.new(mix.outputs['Result'], b.inputs['Base Color'])
    em = N.new('ShaderNodeMath'); em.operation = 'MULTIPLY'; em.inputs[1].default_value = 1.2
    Ln.new(mr.outputs['Result'], em.inputs[0]); Ln.new(em.outputs[0], b.inputs['Emission Strength'])
    b.inputs['Emission Color'].default_value = tuple(PANEL['violet']) + (1,)
    return m


def setup(kit):
    """register every Glasswright material with the sheet kit (kit.MATS / kit.mat) and build their node trees"""
    made = {
        'gw_pearl': pearl(), 'gw_silver': silver(), 'gw_mosaic': mosaic(), 'gw_tip': tip(), 'gw_lance': lance_pearl(),
        'gw_gem_amber': gem('gw_gem_amber', PANEL['amber']), 'gw_gem_violet': gem('gw_gem_violet', PANEL['violet']),
        'gw_gem_green': gem('gw_gem_green', PANEL['green']),
        # the grown optic's root: the same stone, dimmer, so the lens reads as the bright point on it
        'gw_root_amber': gem('gw_root_amber', PANEL['amber'], 0.7), 'gw_root_violet': gem('gw_root_violet', PANEL['violet'], 0.7),
        'gw_root_green': gem('gw_root_green', PANEL['green'], 0.7),
        'gw_drive': gem('gw_drive', (0.62, 0.42, 1.0), 0.45),
        'gw_drive_cut': gem('gw_drive_cut', (0.78, 0.62, 1.0), 0.25, metallic=0.4, cut=True),
        'gw_drive_core': gem('gw_drive_core', (0.88, 0.80, 1.0), 1.6),
        # stored light (the data glow #9fffd2): a star torpedo's body, a hangar lens floor (issue 1415)
        'gw_light': gem('gw_light', LIGHT, 1.4),
    }
    for name, m in made.items():
        kit.MATS[name] = (tuple(m.diffuse_color[:3]), 0)
    return made


# ------------------------------------------------------------------------------------------- the bake (recipe stage 5, stack)
# The shared machinery (tools/blender/kits/shared/paint_stack.py) bakes albedo, ORM and a detail normal for the hull and parts
# atlases from surface_layers(), and with EMISSIVE_ATLAS the hull's emission atlas too (issue 1183: the mosaic glows in the
# game). The glowing stones are their own emissive surfaces (GLOW, glow_material). No wear, no grime, no trim sheet, no decals.
# The bake runs on the contract's scene, scaled to length one, so pattern sizes are per ship length here.
SCALE = 1.0
EMISSIVE_ATLAS = True
EMISSIVE_STRENGTH = 1.6          # the atlas holds emission / this (8-bit maps clip at 1); the material multiplies it back
CELLS_PER_LENGTH = 109.0         # LOOK mosaic cell_scale (4.2 per world unit) on a 26-unit Ark, as in the review
LAYERS = dict(ao_short=.009, ao_long=.026, edge_radius=.0004, edge_gain=14, bump_distance=.0004, bump_strength=.30)
ZONES = {z: {} for z in ('gw_pearl', 'gw_silver', 'gw_mosaic', 'gw_lance')}
ZONES.update({z: {} for z in ('cd5_frame', 'cd5_amber', 'cd5_violet', 'cd5_green', 'cd5_clear', 'cd5_silver')})
FALLBACK = 'gw_pearl'
DECALS = ()
GLOW = {
    'gw_gem_amber': (PANEL['amber'], LOOK['gem']['emission']), 'gw_gem_violet': (PANEL['violet'], LOOK['gem']['emission']),
    'gw_gem_green': (PANEL['green'], LOOK['gem']['emission']),
    'gw_drive': ((0.62, 0.42, 1.0), 0.45), 'gw_drive_cut': ((0.78, 0.62, 1.0), 1.2), 'gw_drive_core': ((0.88, 0.80, 1.0), 1.6),
    'gw_tip': (LOOK['tip']['base'], 4.0),
    'gw_light': (LIGHT, 1.4),
}


def _attr(nt, name):
    from paint3 import node
    return node(nt, 'ShaderNodeAttribute', attribute_name=name)


def surface_layers(c, zone, tiles):
    """(colour, height, roughness, metal[, emission]) node sockets for one zone, read by paint_stack.zone_material"""
    from paint3 import math_, mixc, mulc, node
    nt = c.nt
    zero = math_(nt, 'ADD', 0.0, 0.0)
    if zone in ('gw_pearl', 'gw_lance'):
        L = LOOK['pearl']
        across, along = _attr(nt, 'gw_across').outputs['Fac'], _attr(nt, 'gw_along').outputs['Fac']
        col, height, line = strands(nt, across, along)    # the same strands and silver lines as the review material
        col = _mix(nt, col, (0.97, 0.96, 0.95), line)
        if zone == 'gw_lance':      # pearl at the root shading to violet toward the tip (x, length one: 0.19 to 0.48)
            t = node(nt, 'ShaderNodeMapRange', clamp=True); nt.links.new(c.x, t.inputs[0])
            t.inputs[1].default_value = 0.19; t.inputs[2].default_value = 0.48
            col = mixc(nt, col, PANEL['violet'], t.outputs[0])
        metal = _m(nt, 'ADD', L['metallic'], _m(nt, 'MULTIPLY', line, 1 - L['metallic']))
        rough = _m(nt, 'SUBTRACT', L['roughness'], _m(nt, 'MULTIPLY', line, 0.04))
        return col, _m(nt, 'MULTIPLY', _m(nt, 'SUBTRACT', height, _m(nt, 'MULTIPLY', line, 0.4)), 0.3), rough, metal
    if zone in ('gw_silver', 'cd5_silver'):
        L = LOOK['silver']
        return mixc(nt, L['base'], L['base'], 0.0), zero, math_(nt, 'ADD', L['roughness'], 0.0), L['metallic']
    if zone == 'gw_mosaic':
        L = LOOK['mosaic']
        tint = node(nt, 'ShaderNodeAttribute', attribute_name='gw_tint', attribute_type='GEOMETRY').outputs['Color']
        glow = _attr(nt, 'gw_glow').outputs['Fac']
        cells = node(nt, 'ShaderNodeTexVoronoi', voronoi_dimensions='3D'); cells.inputs['Scale'].default_value = CELLS_PER_LENGTH
        edges = node(nt, 'ShaderNodeTexVoronoi', voronoi_dimensions='3D', feature='DISTANCE_TO_EDGE')
        edges.inputs['Scale'].default_value = CELLS_PER_LENGTH
        nt.links.new(c.pos, cells.inputs['Vector']); nt.links.new(c.pos, edges.inputs['Vector'])
        sep = node(nt, 'ShaderNodeSeparateColor'); nt.links.new(cells.outputs['Color'], sep.inputs[0])
        bright = node(nt, 'ShaderNodeMapRange'); nt.links.new(sep.outputs[0], bright.inputs[0])
        bright.inputs[3].default_value = L['cell_lo']; bright.inputs[4].default_value = L['cell_hi']
        lead = node(nt, 'ShaderNodeMapRange', clamp=True); nt.links.new(edges.outputs['Distance'], lead.inputs[0])
        lead.inputs[1].default_value = L['lead'] * 0.5; lead.inputs[2].default_value = L['lead']
        inner = math_(nt, 'MULTIPLY', math_(nt, 'MULTIPLY', bright.outputs[0], lead.outputs[0]), glow)
        sp = node(nt, 'ShaderNodeTexVoronoi', voronoi_dimensions='3D'); sp.inputs['Scale'].default_value = CELLS_PER_LENGTH * 3.1
        nt.links.new(c.pos, sp.inputs['Vector'])
        sps = node(nt, 'ShaderNodeSeparateColor'); nt.links.new(sp.outputs['Color'], sps.inputs[0])
        spark = node(nt, 'ShaderNodeMapRange', clamp=True); nt.links.new(sps.outputs[1], spark.inputs[0])
        spark.inputs[1].default_value = 1 - L['sparkle']; spark.inputs[4].default_value = 2.5
        energy = math_(nt, 'MULTIPLY', math_(nt, 'ADD', inner, spark.outputs[0]), L['emission'] / EMISSIVE_STRENGTH)
        emission = mulc(nt, tint, energy)
        body = mulc(nt, tint, L['body'])
        col = mixc(nt, L['lead_rgb'], body, lead.outputs[0])      # dark leading between the cells
        metal = math_(nt, 'SUBTRACT', 1.0, lead.outputs[0])
        return col, math_(nt, 'MULTIPLY', sep.outputs[1], 0.6), math_(nt, 'ADD', L['roughness'], 0.0), metal, emission
    # inside zones (break-up only) and anything unlisted: a dim pearl-grey glass
    return mixc(nt, (0.35, 0.36, 0.40), (0.35, 0.36, 0.40), 0.0), zero, math_(nt, 'ADD', 0.3, 0.0), 0.2


def trim_sheet():
    return {}


def decal_atlas():
    import numpy as np
    return np.zeros((2, 2, 4), dtype=np.float32)


def write_textures(folder, rows, decals):
    return []


def glow_material(zone, hull=False):
    import bpy
    rgb, power = GLOW[zone]
    m = bpy.data.materials.new(f'ithar_glow_{zone}'); m.use_nodes = True
    b = m.node_tree.nodes.get('Principled BSDF')
    b.inputs['Base Color'].default_value = (*(v * 0.3 for v in rgb), 1)
    b.inputs['Roughness'].default_value = 0.08
    b.inputs['Emission Color'].default_value = (*rgb, 1); b.inputs['Emission Strength'].default_value = power
    m['ps_glow'] = 1; m['authored_look'] = 1
    if hull:
        m['hull_surface'] = 1
    return m


def inside_material(zone):
    """the interior, seen only in the break-up: layered glass and light, opaque"""
    import bpy
    src = bpy.data.materials.get(zone)
    m = src.copy() if src else bpy.data.materials.new(zone)
    m.name = f'ithar_inside_{zone}'; m.use_nodes = True
    b = m.node_tree.nodes.get('Principled BSDF')
    if b is not None:
        b.inputs['Transmission Weight'].default_value = 0.0
    m['ps_inside'] = 1; m['authored_look'] = 1
    return m
