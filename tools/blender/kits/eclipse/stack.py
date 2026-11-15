# The Eclipse (`deathless`) paint stack for ships built from a build sheet (issue 642). Written once for the faction's kit and
# used by every Eclipse sheet ship (E11 the flagship, E12 the ring cruiser, and the next; R218; RULEBOOK 0.9, R225: one home per
# fact). The machinery is shared and has no look (tools/blender/kits/shared/paint_stack.py); everything that looks like the
# Eclipse is here. The worked example it follows is the Hullbreaker stack (tools/blender/kits/hullbreakers/stack.py, issue 601).
#
# The method (ships.md section 0 item 2, R96 Q1, binding): procedural layers driven by masks baked from the ship's own geometry
# (ambient occlusion, edges), a trim sheet and decals. Colours are SAMPLED from the accepted concepts; the concept picture is
# never projected onto the ship. No downloaded asset: the trim sheet and the decal atlas are drawn by this file (own work
# dedicated CC0, written into the job's textures folder with their licence lines, RULEBOOK 5.13).
#
# The faction (docs/playbooks/factions.md, Eclipse): "a black shade with a thin ring of green-white fire at its edge". Dark
# violet-black plates; the green is a thin, cold green-white line along the rim of every shade plate (the sheet's corona strips),
# plus the small bright core seen through gaps; never green pooled in hollows, ribs or sockets (reads as undead, Ryan Nov 10);
# never flame: engines are an eclipse ring of pale light. Machine bodies in a system they made dark: clean machined plate,
# ancient, dulled, never rust.
#
# THE BATTLE LIFT (R227). The game multiplies an Eclipse hull's albedo by its battle lift (godot/render/look.gd READ deathless
# lift, 2.2: Ryan, "a bit darker for eclipse") so the dark ships keep their outline on the darkest sky. The lift lives in the game
# and is not baked in here, but it is so large for this faction that a colour taken straight from the concept reads lavender or
# grey in the game (the first lift pass "turned the Eclipse lavender", look.gd's note). So every colour below is the tone the
# ship must SHOW under the game's light at the lift, and lin() divides it by the light gain and by the lift, read from look.gd
# (its one home), never copied here. Unpainted, E11 and E12 rendered glowing white in the game (bake none plus the lift).
#
# Where each colour zone sits on a ship is the build sheet's decision (its materials shade, shade2, violet, mauve, lilac, gunv,
# steel, iron, dark; glow zones corona, ecore, lens: tools/blender/build_sheets/kit.py MATS); this file says what each is made of.
import os, re, json, math
import numpy as np
import bpy

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.normpath(os.path.join(HERE, '..', '..', '..', '..'))
FACTION = 'deathless'


def battle_lift():
    """the game's Eclipse battle lift (godot/render/look.gd READ, the one home; R227)"""
    p = os.path.join(REPO, 'godot', 'render', 'look.gd')
    m = re.search(r'"%s":\s*\{[^}]*"lift":\s*([0-9.]+)' % FACTION, open(p, encoding='utf-8').read())
    if not m: raise SystemExit('eclipse stack: no %s lift in godot/render/look.gd READ' % FACTION)
    return float(m.group(1))


LIFT = battle_lift()

# ------------------------------------------------------------------------------------------------------------ concept colours
# Sampled from the accepted concepts contrib/muse/design/concept_round8c_2026_11/deathless_E11_beauty.jpg (box x 40 to 1900,
# y 40 to 1180) and deathless_E12_beauty.jpg (box x 180 to 1960, y 60 to 1000): k-means of the plate pixels (luminance 14 to 200,
# the green excluded), of the dark pixels (6 to 30) and of the green pixels (g over r above 1.4 and over b above 1.2); sample_concept()
# below repeats it. sRGB, as lit in the picture.
#   E12 plates (dark to light): (12,15,25) 29%, (25,24,38) 21%, (43,36,60) 17%, (61,51,82) 14%, (84,76,108) 9%, (115,107,137) 6%
#   E11 plates: (22,17,22) 24%, (42,32,40) 18%, (64,51,61) 13%, (93,76,87) 11%, (124,103,115) 12%, (154,136,143) 11%, (188,172,177) 9%
#   green rim (E12): (48,92,49), (84,136,82), (132,228,88); (E11): (54,92,65), (72,114,85), (101,152,115)
# The hue is the concepts' (violet: blue over red over green; E11's mauve plates a redder violet), the lightness is set by the
# faction sheet, not by the pictures' lighting: E11's lit plates at 124 to 188 are the lavender grey Ryan ruled out, so every
# tone here sits in the concepts' lower half (E12's 12 to 84, E11's 22 to 93), scaled to read dark violet-black under the lift.
# (low tone, lit tone): the tone the plate should SHOW in the game at the battle camera, face-on to the key light.
# Pass 2 (Ryan, Nov 13 2026 11:06 CST, on E11_paint_full.jpg: "Not a ton of details elsewhere, it looks like grainy paint almost.
# Everything kind of blends together"): separation by value steps between plates and plate families, not by noise. Near-black
# heat-shield plates, a deep violet, a lighter dusk violet, a few cool dark gunmetal plates (factions.md "Colours" lists only the
# violet-black plates, so no bronze: the gunmetal is the plates' own metal, kept cool and dark), and brighter worn edges.
CONCEPT = dict(
    shade=((7, 6, 11), (18, 15, 26)),           # near-black heat-shield plate (E12's darkest plates 12,15,25, held down)
    shade2=((10, 8, 16), (23, 17, 34)),        # deep violet plate (E12 25,24,38 to 43,36,60)
    violet=((16, 11, 26), (40, 29, 62)),        # dusk violet plate, the lighter step (E12 43,36,60 and 61,51,82)
    mauve=((16, 11, 19), (38, 28, 44)),         # dusty mauve plate (E11 42,32,40 and 64,51,61, darkened: E11's redder violet)
    lilac=((24, 20, 30), (58, 49, 68)),         # weathered pale plate (E11 64,51,61 and 93,76,87 held well down: never lavender)
    gunmetal=((16, 16, 21), (38, 38, 47)),      # a few cool dark gunmetal plates, the plates' own metal (small share)
    gunv=((14, 12, 18), (36, 32, 44)),          # violet gunmetal: frames, rails, collars, the machines
    steel=((18, 16, 22), (44, 40, 52)),         # machinery metal (the gun cores, the core cage hubs)
    iron=((11, 9, 14), (26, 22, 32)),           # the sheet's flush fasteners on the plates
    bare=((76, 68, 92), (124, 112, 144)),      # worn edges on rims and plate lips: the machined metal under the dark coat
    grime=((5, 4, 7), (10, 8, 12)),             # the dark of seams and deep recesses (the concepts' darkest 3,7,10 to 17,12,17)
)
# The game's light on a face at about 45 degrees to the key (godot/render/look.gd: key 2.0, ambient 0.25 x key): the factor
# between an albedo and the tone the face shows (the Hullbreaker stack's figure, checked again by this job's preview).
LIGHT_GAIN = 1.45
# The light (pass 2, Ryan: "that green looks so plain and stark, just like neon paint"): the corona is light, not paint, the faint
# green ring of a real eclipse. Cold green-white at its hottest (the hue of the concepts' brightest rim pixels, E12 132,228,88,
# whitened), a deeper green where it is dim (E12 48,92,49 and 84,136,82, brightened to read as light).
CORONA_HOT = (176, 255, 206)
CORONA_DIM = (40, 190, 96)
# the trapped light core (Board review of PR 643: the first core, near white at 1.9, flattened to a white blob): green-white at its
# centre grading to the concepts' core green at its edge (E12 66,203,23 to 132,228,88), never white all over
CORE_HOT = (220, 255, 204)
CORE_EDGE = (28, 255, 12)
CORONA_RGB = (128, 242, 164)     # the flat colour glow_material gives a corona surface the glow map does not hold (none on E11, E12)
CORE_RGB = (44, 255, 24)


# AgX and the warm key take colour out of dark tones: the first preview (sandbox, game light, lift 2.2) showed the shade plates
# as a neutral grey-violet (median hull pixel at the beauty camera saturation 0.22 against the E12 concept's 0.57). So the albedo
# carries the hue a little stronger than the tone it must show: its distance from its own grey is scaled by SAT.
SAT = 2.6


def lin(srgb):
    """the tone to show in the game (sRGB 0..255) to the albedo to paint: linear, over the light gain and the battle lift, with
    the hue held (SAT)"""
    c = np.asarray(srgb, np.float64) / 255.0
    c = np.where(c <= .04045, c / 12.92, ((c + .055) / 1.055) ** 2.4)
    y = float(c @ np.array((.2126, .7152, .0722))); c = np.clip(y + (c - y) * SAT, y * .15, None)
    return tuple(float(x) / (LIGHT_GAIN * LIFT) for x in c)


def lin_raw(srgb):
    c = np.asarray(srgb, np.float64) / 255.0
    return tuple(float(x) for x in np.where(c <= .04045, c / 12.92, ((c + .055) / 1.055) ** 2.4))


def pair(k):
    lo, hi = CONCEPT[k]; return lin(lo), lin(hi)


# ------------------------------------------------------------------------------------------------------------ the layers
SCALE = 1.0          # every size below is in ship lengths (the recipe's frame: the ship is 1.0 long)
LAYERS = dict(
    ao_short=.004, ao_long=.025, edge_radius=.0014, edge_gain=18.0,      # the masks (a wider edge than the Hullbreakers': the machined bevels read)
    # pass 2: no fine mottle, no grain, almost none of the per-island tone (the sheet's thousands of tiny plate islands each took
    # their own tone, which read as grainy paint); the plate families and their seams carry the variety, in big calm panels
    patch_scale=4.0, plate_var=.10, island_tone=.15, side_dark=.30, grain_scale=260.0, mottle_scale=40.0, mottle=0.0, grain=0.0,
    rough=.66, metal=.40, wear=1.0, grime=.50, ao_dark=.92, red_tone=0.0,
    rough_floor=.50,     # the roughness floor (ships.md section 0 item 2, pass 5): no white specular glare at the game's key light
    # R243: mechanically aligned panels with recessed seams and shallow relief, all in one ship coordinate frame.
    patch_big=(.090, .060, .050), patch_small=(.040, .026, .022), patch_over=(.110, .070, .060), patch_over_share=.06,
    patch_region=3.0, patch_parts=((.035, .025, .020), (.018, .014, .012), (.045, .030, .025)), patch_seam=.0020, seam_dark=.95,
    cavity_pow=1.6, wear_lo=.16, wear_hi=.38,
    scuff=.08, scuff_size=.050,                                           # a few machining scratches, never chips
    rivets=0, rivet_pitch=.016, rivet_band=(.0015, .0045),               # flush fasteners only on the body plates (zone violet)
    trim_size=dict(), trim_aspect=dict(),
    streak_scale=4.0, streak_stretch=60.0, rust_blot=26.0,                # no rust on the Eclipse (every zone's rust is 0)
    grime_z=(-.12, -.04), soot_x=(-.50, -.30), soot_aft=.10,              # a little grime low and toward the engines; no soot (no flame)
    wear_scale=40.0, wear_patch=3.0, bump_distance=.0008, bump_strength=.50, panel_relief=.95,
)
# pass 2: the shade plates, the body behind them and the machinery differ in finish, not only colour: the shades a matte heat
# shield, the body a satin metal, the machines (guns, engines, saddles, rails) a brighter worked metal
ZONES = dict(
    shade=dict(rust=0, grime=.50, patchwork=1.0, patchwork_parts=.8, rough=.80, metal=.15),
    shade2=dict(rust=0, grime=.55, patchwork=1.0, patchwork_parts=.8, rough=.74, metal=.20),
    violet=dict(rust=0, grime=.50, patchwork=.9, patchwork_parts=.7, rough=.58, metal=.50, rivets=1),
    mauve=dict(rust=0, grime=.50, patchwork=.7, patchwork_parts=.6, rough=.60, metal=.45),
    lilac=dict(rust=0, grime=.60, patchwork=.6, rough=.66, metal=.35),
    gunv=dict(rust=0, metal=.78, rough=.50, wear=1.2, patchwork_parts=.6),
    steel=dict(rust=0, metal=.80, rough=.48, wear=1.1, patchwork_parts=.6),
    iron=dict(rust=0, metal=.60, rough=.55, rivets=0, scuff=.05),
    dark=dict(rust=0, grime=.2, wear=.10, scuff=.05, rivets=0, metal=.1, rough=.92, plate_var=.05),
    bell=dict(base='gunv', rust=0, metal=.35, rough=.80, wear=.6, grime=.7),     # engine bells and housings: matte, never mirror black
)
_BASE = dict(shade='shade', shade2='shade2', violet='violet', mauve='mauve', lilac='lilac', gunv='gunv', steel='steel', iron='iron',
             dark='grime', bell='gunv')
for _k, _z in ZONES.items():
    _z['lo'], _z['hi'] = pair(_BASE[_k])
FALLBACK = 'shade'
ZONE_BY_KIND = {('engine', 'gunv'): 'bell', ('engine', 'shade'): 'bell', ('engine', 'shade2'): 'bell'}
BARE = lin(CONCEPT['bare'][1])
GRIME = lin(CONCEPT['grime'][0])
RUST = RUST_DARK = GRIME          # read by the shared rust layer only where a zone has rust, and no Eclipse zone has
RED_PLATE = pair('shade')         # read only where a zone has a red_share, and no Eclipse zone has
# the patchwork families: (share of panels, colour pair[, 'small']). Clear value steps (pass 2): near-black shade plates most, then
# deep violet, the lighter dusk violet, a few mauve and cool gunmetal plates, rare weathered pale plates on small plates only
PATCH_FAMILIES = [(.32, pair('shade')), (.22, pair('shade2')), (.14, pair('violet')), (.08, pair('mauve')), (.05, pair('gunmetal')),
                  (.03, pair('lilac'), 'small')]
PATCH_FAMILIES_PARTS = [(.30, pair('gunv')), (.18, pair('shade')), (.14, pair('violet')), (.06, pair('gunmetal')), (.03, pair('lilac'), 'small')]


def panel_nodes(c, col, amount, families=None, cells=None):
    """R243: one aligned panel lattice across the hull and crescent, with shallow recessed joints.
    The accepted colour pairs and shares stay unchanged. Panel tone varies by cell, never by mesh island; neither row
    offsets, noise-chosen grid sizes nor overlaid patches may break the alignment. Small panels occupy every fourth column.
    The shared stack bakes the joints' relief into the hull normal map as well as its albedo and roughness."""
    from paint_stack import node, math_, mixc, _seams
    from types import SimpleNamespace
    nt = c.nt; cell = cells[0] if cells else LAYERS['patch_big']
    q = node(nt, 'ShaderNodeVectorMath', operation='DIVIDE'); nt.links.new(c.pos, q.inputs[0]); q.inputs[1].default_value = cell
    xyz = node(nt, 'ShaderNodeSeparateXYZ'); nt.links.new(q.outputs[0], xyz.inputs[0])
    column = math_(nt, 'FLOOR', xyz.outputs[0])
    small = math_(nt, 'LESS_THAN', math_(nt, 'PINGPONG', column, 2.0), .5)
    cid = node(nt, 'ShaderNodeCombineXYZ'); lines = []
    for k, (axis, size) in enumerate(zip(xyz.outputs, cell)):
        # A fixed half pitch inside periodic columns. Every joint remains on the same half-cell lattice.
        div = math_(nt, 'ADD', 1.0, small)
        v = math_(nt, 'MULTIPLY', axis, div)
        nt.links.new(math_(nt, 'FLOOR', v), cid.inputs[k])
        f = math_(nt, 'FRACT', v)
        lines.append((math_(nt, 'DIVIDE', math_(nt, 'MULTIPLY', math_(nt, 'MINIMUM', f, math_(nt, 'SUBTRACT', 1, f)), size), div), k))
    wn = node(nt, 'ShaderNodeTexWhiteNoise', noise_dimensions='3D'); nt.links.new(cid.outputs[0], wn.inputs['Vector'])
    tones = node(nt, 'ShaderNodeSeparateColor'); nt.links.new(wn.outputs['Color'], tones.inputs[0])
    lo = 0.0
    for family in families or PATCH_FAMILIES:
        share, (flo, fhi) = family[:2]; hi = lo + share
        on = math_(nt, 'MULTIPLY', math_(nt, 'GREATER_THAN', wn.outputs['Value'], lo - 1e-4), math_(nt, 'LESS_THAN', wn.outputs['Value'], hi))
        if len(family) > 2: on = math_(nt, 'MULTIPLY', on, small)
        col = mixc(nt, col, mixc(nt, flo, fhi, tones.outputs[1]), math_(nt, 'MULTIPLY', on, amount))
        lo = hi
    return col, math_(nt, 'MULTIPLY', _seams(c, SimpleNamespace(LAYERS=LAYERS), lines), amount, clamp=True)

# ------------------------------------------------------------------------------------------------------------ the light
# Every light shares one emission map (shared/paint_stack.bake_engine_glow, the export's
# CODE_glow surface and CODE_glow_emission.jpg): the engine rings, the corona line on every shade rim, the corona strip lights,
# the gun shades' rims, the core and the arc emitter's lens. A flat emissive colour read as neon paint (Ryan, Nov 13 11:06 CST:
# "that green looks so plain and stark, just like neon paint"), so each kind of light is drawn on the map:
#   the corona line (round 3, R243): the faint green ring of a real eclipse. Thin at rest: brightest along the middle of the strip and
#     falling softly to its edges and sides (into the plate edge, never a hard band), and the bright core of it widens only in the
#     brighter arcs. Its brightness varies along its length (brighter arcs, dimmer stretches, a few short breaks where plates
#     overlap); cold green-white at its hottest, deeper green where dim. R243: the broader soft profile and extra brightness
#     keep the same thin strip readable at camera 170; brighter arcs cross the game's glow threshold.
#   the core and the lens: green-white at the centre grading to the concepts' core green at the edge, the brightest light on the
#     ship, never a white blob (Board review of PR 643).
#   the engine ring: as below.
# Only the hull's corona trim material is marked hull_surface (GLOW_HULL). Engine rings, core and lens use an unmarked
# material sharing the map, so every part surface still participates in breach clearance.
GLOW = ('corona', 'ecore', 'lens')
GLOW_STRENGTH = dict(corona=1.05, ecore=1.35, lens=1.25)     # only for a glow surface the map does not hold (none on E11, E12)
GLOW_HULL = ('corona',)
CORONA = dict(base=1.0, arc=1.1, arc_scale=9.0, arc_band=(.48, .78), breaks_scale=26.0, breaks=(.20, .25), rest_width=.75,
              arc_width=.50, hot=1.25)
CORE = dict(edge=1.0, falloff=2.0, hot_radius=.18)


def faction_look():
    p = os.path.join(REPO, 'godot', 'fx', 'faction_looks.json')
    d = json.load(open(p, encoding='utf-8'))
    return d.get(FACTION) or d.get('factions', {}).get(FACTION)


def glow_material(zone, hull=False):
    m = bpy.data.materials.new(f'p3_{zone}_hull' if hull else f'p3_{zone}'); m.use_nodes = True
    b = m.node_tree.nodes['Principled BSDF']
    col = lin_raw(CORE_RGB if zone in ('ecore', 'lens') else CORONA_RGB)
    b.inputs['Base Color'].default_value = (col[0] * .05, col[1] * .05, col[2] * .05, 1); b.inputs['Roughness'].default_value = .6
    b.inputs['Emission Color'].default_value = (*col, 1); b.inputs['Emission Strength'].default_value = GLOW_STRENGTH.get(zone, 1.0)
    m['ps_glow'] = 1; m['rim_soft'] = 1
    if hull: m['hull_surface'] = 1
    return m


def glow_vertex(o):
    """the per-vertex inputs of a light that is not an engine ring (shared bake_engine_glow calls this): colour attribute ps_glow
    R the place across a corona strip (0 and 1 its two edges, 0.5 its middle), G the light's own random, B the distance from a
    core's centre over its radius; float attribute ps_kind 1 a corona line, 2 the core or the lens. The sheet's rim strips
    (kit.strip) are four vertices per station: the base edges and the top edges, left, right, right, left."""
    me = o.data; z = me.materials[0].name if me.materials else ''
    # Both attributes are made first and only then looked up again by name and written in one call each. Adding an attribute
    # reallocates the mesh's attribute storage, so a handle taken before it (the first fix of pass 2 wrote ps_glow through one)
    # points at freed memory: Blender 5.3 survived it, Blender 4.5 on Ryan's PC crashed later in the bake
    # (EXCEPTION_ACCESS_VIOLATION in tbbmalloc or ucrtbase, issue 642, E11_E12_PAINT_642 and 642b).
    if me.color_attributes.get('ps_glow') is None: me.color_attributes.new('ps_glow', 'FLOAT_COLOR', 'POINT')
    if me.attributes.get('ps_kind') is None: me.attributes.new('ps_kind', 'FLOAT', 'POINT')
    rnd = (sum(ord(c) for c in o.name) * 0.61803) % 1.0
    W = [o.matrix_world @ v.co for v in me.vertices]
    n = len(W); col = np.zeros((n, 4), np.float32); col[:, 1] = rnd
    if z == 'corona':
        strip = o.get('role') == 'hull' and n % 4 == 0 and n >= 8
        col[:, 0] = np.tile(np.array((0.0, 1.0, 1.0, 0.0), np.float32), n // 4 + 1)[:n] if strip else 0.5
        kind = 1.0
        if o.get('role') == 'hull': o['ps_close'] = 'rim'
    else:
        c = sum(W, W[0] * 0) / n; ext = [max(v[k] for v in W) - min(v[k] for v in W) for k in range(3)]
        thin = ext.index(min(ext)) if max(ext) > 2.5 * min(ext) else 2       # a flat port: across its face; a sphere: round its top
        R = max(math.hypot(*[(v - c)[k] for k in range(3) if k != thin]) for v in W) or 1.0
        col[:, 0] = 0.5
        col[:, 2] = [min(1.0, math.hypot(*[(v - c)[k] for k in range(3) if k != thin]) / R) for v in W]
        kind = 2.0
        if z == 'ecore': o['ps_close'] = 'core'
    me.color_attributes['ps_glow'].data.foreach_set('color', col.ravel())
    me.attributes['ps_kind'].data.foreach_set('value', np.full(n, kind, np.float32))


# The engine (Ryan, Nov 12, on the Hullbreaker engines: "more variation to the engine glow so it's not so uniform, just disc
# color"; factions.md: no flaming bells, an eclipse ring of pale light). The sheet's engine is a bell with a thin corona ring just
# inside the lip round a black shade disc set back (tools/blender/kits/eclipse/parts.py engine_bell): an eclipse seen end on. The
# ring is bright round most of its circle, brighter on its inner edge (the light leaking round the disc), with uneven hot spots
# and dim gaps (each engine its own pattern), each engine its own brightness and its own tint (paler, or warmer toward the
# accent), in the game's Eclipse engine colour. The disc stays the dark zone. The game's moving plume sits on top; no flame.
ENGINE_GLOW = dict(zones=('corona',), kind='engine', disc=('corona',), plug=(), extra_zones=('corona', 'ecore', 'lens'), res_frac=.5,
                   pale=.25, accent=(0.0, .35), bright=(.45, 1.15), hotspot_scale=7.0, hotspot=(.40, .72), hotspot_gain=.90,
                   gaps=(.30, .55), gap_dark=.90, inner_gain=.35, norm=.32, strength=1.6, base=(.008, .006, .012))


def engine_glow_nodes(nt, r, e, d, a, tc, H):
    """the emission colour of every light on the map (H: the shared node helpers, and kind: 0 engine ring, 1 corona line, 2 core)"""
    E = ENGINE_GLOW; f = faction_look()
    eng = [float(c) for c in f['engine']]; acc = [float(c) for c in (f.get('accent') or f['engine'])]
    pale = [c + (1 - c) * E['pale'] for c in eng]
    math_, ramp, mixc, node, mulc = H['math_'], H['ramp'], H['mixc'], H['node'], H['mulc']
    e2 = math_(nt, 'FRACT', math_(nt, 'MULTIPLY', e, 7.31))
    col = mixc(nt, tuple(pale), tuple(acc), math_(nt, 'ADD', E['accent'][0], math_(nt, 'MULTIPLY', e2, E['accent'][1] - E['accent'][0])))
    # round the ring: hot spots and dim gaps by the angle, each engine its own pattern (W = the engine's random)
    av = node(nt, 'ShaderNodeCombineXYZ'); nt.links.new(math_(nt, 'COSINE', math_(nt, 'MULTIPLY', a, 2 * math.pi)), av.inputs[0])
    nt.links.new(math_(nt, 'SINE', math_(nt, 'MULTIPLY', a, 2 * math.pi)), av.inputs[1]); nt.links.new(math_(nt, 'MULTIPLY', e, 23.0), av.inputs[2])
    hn = node(nt, 'ShaderNodeTexNoise'); hn.noise_dimensions = '4D'; hn.inputs['Scale'].default_value = E['hotspot_scale']
    hn.inputs['Detail'].default_value = 3; hn.inputs['Roughness'].default_value = .55
    nt.links.new(av.outputs[0], hn.inputs['Vector']); nt.links.new(math_(nt, 'MULTIPLY', e, 11.0), hn.inputs['W'])
    heat = math_(nt, 'ADD', .75, math_(nt, 'MULTIPLY', ramp(nt, hn.outputs['Fac'], E['hotspot'][0], E['hotspot'][1]), E['hotspot_gain']))
    gn = node(nt, 'ShaderNodeTexNoise'); gn.noise_dimensions = '4D'; gn.inputs['Scale'].default_value = E['hotspot_scale'] * .6
    gn.inputs['Detail'].default_value = 2
    nt.links.new(av.outputs[0], gn.inputs['Vector']); nt.links.new(math_(nt, 'ADD', math_(nt, 'MULTIPLY', e, 5.0), 3.3), gn.inputs['W'])
    heat = math_(nt, 'MULTIPLY', heat, math_(nt, 'SUBTRACT', 1, math_(nt, 'MULTIPLY', ramp(nt, gn.outputs['Fac'], E['gaps'][1], E['gaps'][0]), E['gap_dark'])))
    heat = math_(nt, 'MULTIPLY', heat, math_(nt, 'ADD', 1.0, math_(nt, 'MULTIPLY', ramp(nt, r, .97, .90), E['inner_gain'])))
    heat = math_(nt, 'MULTIPLY', heat, math_(nt, 'ADD', E['bright'][0], math_(nt, 'MULTIPLY', e, E['bright'][1] - E['bright'][0])))
    ring = mulc(nt, col, math_(nt, 'MULTIPLY', heat, E['norm'], clamp=True))
    # the corona line: brighter arcs and dimmer stretches along it (noise on the ship's own position), a few short breaks, a soft
    # falloff from the middle of the strip to its edges; the bright middle widens only where the arc is bright
    C = CORONA; pos = tc.outputs['Object']
    an = node(nt, 'ShaderNodeTexNoise'); an.inputs['Scale'].default_value = C['arc_scale']; an.inputs['Detail'].default_value = 2
    an.inputs['Roughness'].default_value = .5; nt.links.new(pos, an.inputs['Vector'])
    arc = ramp(nt, an.outputs['Fac'], C['arc_band'][0], C['arc_band'][1])
    bn = node(nt, 'ShaderNodeTexNoise'); bn.inputs['Scale'].default_value = C['breaks_scale']; bn.inputs['Detail'].default_value = 1
    nt.links.new(pos, bn.inputs['Vector'])
    brk = ramp(nt, bn.outputs['Fac'], C['breaks'][0], C['breaks'][1])          # 0 in a short break, 1 elsewhere
    across = math_(nt, 'SUBTRACT', 1, math_(nt, 'POWER', math_(nt, 'ABSOLUTE', math_(nt, 'MULTIPLY', math_(nt, 'SUBTRACT', r, .5), 2.0)), 2.0))
    width = math_(nt, 'ADD', C['rest_width'], math_(nt, 'MULTIPLY', arc, C['arc_width'] - C['rest_width']))
    prof = math_(nt, 'POWER', math_(nt, 'MAXIMUM', across, 0.0), width)
    lh = math_(nt, 'MULTIPLY', math_(nt, 'MULTIPLY', math_(nt, 'ADD', C['base'], math_(nt, 'MULTIPLY', arc, C['arc'])), prof), brk)
    line = mulc(nt, mixc(nt, lin_raw(CORONA_DIM), lin_raw(CORONA_HOT), math_(nt, 'POWER', lh, .8)), math_(nt, 'MULTIPLY', lh, C['hot']))
    # the core: green-white in the middle grading to green at the edge (B = distance from the centre over the radius)
    k = math_(nt, 'POWER', ramp(nt, d, CORE['hot_radius'], 0.0), CORE['falloff'])
    core = mulc(nt, mixc(nt, lin_raw(CORE_EDGE), lin_raw(CORE_HOT), k), math_(nt, 'ADD', CORE['edge'], math_(nt, 'MULTIPLY', k, 1 - CORE['edge'])))
    kd = H['kind']
    out = mixc(nt, ring, line, math_(nt, 'GREATER_THAN', kd, .5))
    return mixc(nt, out, core, math_(nt, 'GREATER_THAN', kd, 1.5))


# ------------------------------------------------------------------------------------------------------------ insides
# An inside seen from outside reads as the dark inner liner (R99 Q1), never a room colour from outside: the Eclipse liner is a
# dark violet-black (their dark decks), a faint tint per room so a broken ship's spaces are not all one; the core keeps its light.
INSIDE_BASE = (.010, .008, .014)
INSIDE_TINT = .20


def inside_material(room):
    src = bpy.data.materials.get(room); m = bpy.data.materials.new(f'ps_inside_{room}'); m.use_nodes = True
    b = m.node_tree.nodes['Principled BSDF']; rgb = (1, 1, 1)
    if src is not None and src.use_nodes and src.node_tree.nodes.get('Principled BSDF'):
        sb = src.node_tree.nodes['Principled BSDF']; rgb = tuple(sb.inputs['Base Color'].default_value)[:3]
        em = sb.inputs['Emission Strength'].default_value
        if em > 0:      # the core: its own light stays (the bright bite when the ship breaks), in the corona's green-white
            col = lin_raw(CORE_RGB)
            b.inputs['Emission Color'].default_value = (*col, 1); b.inputs['Emission Strength'].default_value = em
    mx = max(rgb) or 1
    b.inputs['Base Color'].default_value = tuple(INSIDE_BASE[i] * (1 - INSIDE_TINT + INSIDE_TINT * rgb[i] / mx) for i in range(3)) + (1,)
    b.inputs['Roughness'].default_value = .9; b.inputs['Metallic'].default_value = .2
    m['ps_inside'] = 1
    return m


# ------------------------------------------------------------------------------------------------------------ running lights
# The builder's call (issue 642; R207, R233: the Board reviews it): the Eclipse carry NO added running lamps. The red lamps are a
# Hullbreaker rule (R228 item 4); a row of coloured points along the flanks reads as a navy's or a pirate's ship, and the Eclipse
# are machines in a system they made dark (lore 7.1): their only lights are the corona (the thin green-white line on every shade
# rim, which already marks the outline and the heading at the battle camera), the core seen through its port, the pale engine
# rings, and the sheet's own corona strip lights over the belts (the kit's lamp, a short strip of the same corona light, never a
# point). So RUNNING_LIGHTS is None: the shared stack adds no lamps and writes no lights.json; the standing light check has no
# painted window or trim light to hold (it passes with none) and the corona strips are the sheet's geometry.
RUNNING_LIGHTS = None


# ------------------------------------------------------------------------------------------------------------ decals
# Placed by rule on each ship's own surfaces (shared/paint_stack.place_decals): x is the station from the bow (0) to the stern (1),
# z the height band on the side, a top decal searches the deck at y. Eclipse marks are machine-cut and faint, a slightly paler
# violet than the plate, never a bright colour: the eclipse sigil (a black disc in a thin ring, the faction's one mark), a line of
# archive glyphs (the ship's index in the archive, its own from the game code) and band ticks on the shade bands. The concepts
# show none at their scale: the builder's design, written on each sheet.
DECAL_CELLS = 2      # 2 x 2: 0 the eclipse sigil, 1 archive glyphs, 2 band ticks, 3 unused
DECALS = [
    dict(name='eclipse sigil', cell=0, face='top', x=(.52, .56, .60, .48, .64), y=(0.0, .02, -.02), w=.040, h=.040, alpha=.85, min_facing=.9),
    dict(name='archive glyphs', cell=1, face='side', x=(.40, .45, .50, .55, .35), z=(.40, .70), w=.060, h=.014, alpha=.80),
    dict(name='band ticks', cell=2, face='side', x=(.70, .66, .74, .62), z=(.35, .65), w=.030, h=.016, alpha=.75),
]
DECAL_RGB = (74, 64, 92)      # the mark's tone in the game: a paler violet than the plate, dulled (lin() as every colour)


def ship_code():
    p = os.environ.get('R209_SHIP', '')
    code = (json.load(open(p)).get('game_code') if p and os.path.exists(p) else '') or 'D00'
    return code.split('_')[0]


def _srgb(lin_rgb):
    c = np.clip(np.asarray(lin_rgb, np.float64), 0, 1)
    return np.where(c <= .0031308, c * 12.92, 1.055 * c ** (1 / 2.4) - .055)


def decal_atlas(res=1024, code=None):
    """the decal atlas, RGBA in 0..1 (sRGB colour, the albedo it paints), row 0 at the top; drawn here (own work). The glyph
    line is the ship's own (seeded by its game code), so no two ships of the faction carry the same index"""
    code = code or ship_code()
    c = res // 2; A = np.zeros((res, res, 4), np.float32)
    rng = np.random.default_rng(sum(ord(ch) * (k + 5) for k, ch in enumerate(code)) + 642)
    mark = _srgb(lin(DECAL_RGB)); ink = _srgb(lin(CONCEPT['grime'][0]))
    y, x = np.mgrid[0:c, 0:c]; u = x / c; v = y / c

    def put(cell, mask, col):
        cx, cy = cell % 2, cell // 2; sl = (slice(cy * c, cy * c + c), slice(cx * c, cx * c + c))
        a = A[sl]; m = mask.astype(np.float32) * (0.8 + 0.2 * rng.random(mask.shape))
        a[..., :3] = np.where(m[..., None] > 0, col, a[..., :3]); a[..., 3] = np.maximum(a[..., 3], m)
    # 0 the eclipse sigil: a black disc inside a thin ring, the ring broken at one point (the light escaping)
    r = np.hypot(u - .5, v - .5); ang = np.arctan2(v - .5, u - .5)
    ring = (r > .36) & (r < .41) & ~((ang > -1.75) & (ang < -1.39))
    put(0, ring, mark); put(0, r < .30, ink)
    # 1 archive glyphs: a line of small ring and bar glyphs, the ship's own sequence
    g = np.zeros((c, c), bool); n = 9; cw = .9 / n
    for k in range(n):
        x0 = .05 + k * cw; cxk = x0 + cw * .45; kind = int(rng.integers(0, 4))
        rr = np.hypot((u - cxk) / (cw * .40), (v - .5) / .30)
        if kind == 0: g |= (rr > .70) & (rr < 1.0)
        elif kind == 1: g |= (np.abs(u - cxk) < cw * .08) & (np.abs(v - .5) < .30)
        elif kind == 2: g |= ((rr > .70) & (rr < 1.0) & (v < .5)) | ((np.abs(v - .5) < .04) & (np.abs(u - cxk) < cw * .40))
        else: g |= (rr < .45)
    put(1, g, mark)
    # 2 band ticks: thin parallel ticks, the shade band's index
    t = np.zeros((c, c), bool); nt_ = int(rng.integers(3, 6))
    for k in range(nt_): t |= (np.abs(u - (.15 + k * .16)) < .03) & (np.abs(v - .5) < .34)
    put(2, t, mark)
    # wear: the marks are old; patches gone
    holes = np.kron(rng.random((res // 16, res // 16)) < .14, np.ones((16, 16))) > 0
    A[..., 3] *= np.where(holes, .3, 1.0)
    return A


# ------------------------------------------------------------------------------------------------------------ the trim sheet
def _tile_noise(n, k, rng):
    g = rng.random((k, k)); up = np.kron(g, np.ones((n // k, n // k)))
    for _ in range(3): up = (up + np.roll(up, 1, 0) + np.roll(up, -1, 0) + np.roll(up, 1, 1) + np.roll(up, -1, 1)) / 5
    return (up - up.min()) / (up.max() - up.min() + 1e-9)


def trim_sheet():
    """the faction's trim tiles, each RGBA in 0..1 (alpha is the tile's mask and height): drawn here (own work). The Eclipse plate
    is machine-cut: flush round fasteners (a thin dark ring, never a domed rivet) and fine straight machining scratches."""
    rng = np.random.default_rng(642)
    T = {}
    n = 128; y, x = np.mgrid[0:n, 0:n]; r = np.hypot(x - n / 2, y - n / 2) / (n * .14)
    ring = np.clip(1 - np.abs(r - 1.0) * 4, 0, 1); cap = np.clip(1 - r, 0, 1) > 0
    a = np.clip(ring * .9 + cap * .25, 0, 1); col = np.stack([.30 + .2 * cap] * 3, -1) * (1 - ring[..., None] * .7)
    T['rivets'] = np.dstack([col, a])
    n = 512; m = np.zeros((n, n), np.float32)
    for _ in range(160):
        L = rng.uniform(20, 180); th = rng.normal(0, .08) + (math.pi / 2 if rng.random() < .3 else 0)
        x0, y0 = rng.uniform(0, n, 2); s = rng.uniform(.25, .7)
        for t in np.linspace(0, 1, int(L)):
            xi = int(x0 + math.cos(th) * L * t) % n; yi = int(y0 + math.sin(th) * L * t) % n
            m[yi, xi] = max(m[yi, xi], s)
    m = np.maximum(m, (_tile_noise(n, 32, rng) > .93) * .35)
    T['scuffs'] = np.dstack([np.stack([np.full((n, n), .6)] * 3, -1), m])
    return T


def _sheet_image(rows, width=512):
    out = []
    for k, a in rows.items():
        h, w = a.shape[:2]; reps = int(math.ceil(width / w)); out.append(np.tile(a, (1, reps, 1))[:, :width])
    return np.concatenate(out, 0)


def write_textures(folder, rows, decals):
    """the trim sheet and decal atlas into the job's textures folder, with their licence lines (standing.py licences)"""
    import struct, zlib

    def png(path, a):
        a = (np.clip(a, 0, 1) * 255).astype(np.uint8); h, w = a.shape[:2]
        raw = b''.join(b'\x00' + a[i].tobytes() for i in range(h))
        def chunk(t, d): return struct.pack('>I', len(d)) + t + d + struct.pack('>I', zlib.crc32(t + d) & 0xffffffff)
        open(path, 'wb').write(b'\x89PNG\r\n\x1a\n' + chunk(b'IHDR', struct.pack('>IIBBBBB', w, h, 8, 6, 0, 0, 0)) + chunk(b'IDAT', zlib.compress(raw, 6)) + chunk(b'IEND', b''))
    png(os.path.join(folder, 'eclipse_trim.png'), _sheet_image(rows))
    png(os.path.join(folder, 'eclipse_decals.png'), decals)
    src = 'own work, drawn by tools/blender/kits/eclipse/stack.py and dedicated CC0 (no downloaded asset)'
    lines = [dict(file='eclipse_trim.png', source=src, licence='CC0', used='trim sheet: flush fasteners, machining scratches (rows: ' + ', '.join(rows) + ')'),
             dict(file='eclipse_decals.png', source=src, licence='CC0', used='decal atlas: eclipse sigil, archive glyphs, band ticks')]
    lp = os.path.join(os.path.dirname(folder.rstrip('/\\')), 'licences.json')
    old = json.load(open(lp, encoding='utf-8')).get('textures', []) if os.path.exists(lp) else []
    keep = [r for r in old if r.get('file') not in {l['file'] for l in lines}]
    json.dump(dict(textures=keep + lines), open(lp, 'w', encoding='utf-8'), indent=1)
    return lines


def sample_concept():
    """repeat the colour sampling above (needs Pillow): the cluster centres per concept, plates, dark and green"""
    from PIL import Image
    out = {}
    for ship, (x0, y0, x1, y1) in (('E11', (40, 40, 1900, 1180)), ('E12', (180, 60, 1960, 1000))):
        p = os.path.join(REPO, 'contrib', 'muse', 'design', 'concept_round8c_2026_11', f'deathless_{ship}_beauty.jpg')
        im = np.asarray(Image.open(p).convert('RGB')).astype(np.float32)[y0:y1, x0:x1].reshape(-1, 3); L = im.mean(1)
        rng = np.random.default_rng(1)

        def km(X, k):
            X = X[rng.choice(len(X), min(40000, len(X)), replace=False)]; C = X[rng.choice(len(X), k, replace=False)]
            for _ in range(40):
                a = ((X[:, None] - C[None]) ** 2).sum(2).argmin(1); C = np.array([X[a == j].mean(0) if (a == j).any() else C[j] for j in range(k)])
            return [(tuple(int(v) for v in C[j]), round(float((a == j).mean()), 3)) for j in np.argsort(C.mean(1))]
        green = (im[:, 1] > im[:, 0] * 1.4) & (im[:, 1] > im[:, 2] * 1.2) & (L > 50)
        out[ship] = dict(green=km(im[green], 4), plate=km(im[~green & (L > 14) & (L < 200)], 8), dark=km(im[(L > 6) & (L < 30) & ~green], 4))
    return out
