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
CONCEPT = dict(
    shade=((13, 11, 19), (30, 25, 42)),         # violet-black shade plate, most of the ship (E12 12,15,25 and 25,24,38; the hue of 43,36,60)
    shade2=((16, 12, 24), (36, 28, 52)),        # deep violet plate (E12 25,24,38 to 43,36,60)
    violet=((19, 13, 30), (52, 38, 78)),        # Eclipse violet plate (E12 43,36,60 and 61,51,82, darkened)
    mauve=((22, 15, 25), (58, 43, 62)),         # dusty mauve plate (E11 42,32,40 and 64,51,61, darkened: E11's redder violet)
    lilac=((26, 21, 30), (64, 54, 72)),         # weathered pale plate (E11 64,51,61 and 93,76,87 held well down: never lavender)
    gunv=((12, 10, 16), (30, 26, 38)),          # violet gunmetal: frames, rails, collars, the barrels of machines
    steel=((16, 14, 20), (38, 34, 46)),         # machinery metal (the gun cores, the core cage hubs)
    iron=((11, 9, 14), (26, 22, 32)),           # the sheet's flush fasteners on the plates
    bare=((70, 63, 84), (112, 102, 130)),         # worn edges: the machined metal under the dark coat, cool and dulled, a little violet
    grime=((6, 5, 8), (12, 10, 14)),            # the dark of seams and deep recesses (the concepts' darkest 3,7,10 to 17,12,17)
    seam=((8, 6, 11), (16, 12, 20)),
)
# The game's light on a face at about 45 degrees to the key (godot/render/look.gd: key 2.0, ambient 0.25 x key): the factor
# between an albedo and the tone the face shows (the Hullbreaker stack's figure, checked again by this job's preview).
LIGHT_GAIN = 1.45
# the green-white corona: the hue of the concepts' brightest rim pixels (E12 132,228,88; E11 101,152,115), whitened toward a cold
# white (factions.md: "a thin, cold green-white line"; the concepts' saturated green reads as a toxic or undead glow)
CORONA_RGB = (128, 242, 164)
CORE_RGB = (186, 255, 204)       # the trapped light core: the same light, hotter, nearly white at its heart


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
    ao_short=.004, ao_long=.025, edge_radius=.0010, edge_gain=14.0,      # the masks
    patch_scale=4.0, plate_var=.30, side_dark=.22, grain_scale=260.0, mottle_scale=40.0, mottle=.03, grain=.003,   # no salt and pepper
    rough=.66, metal=.50, wear=1.0, grime=.55, ao_dark=.90, red_tone=0.0,
    rough_floor=.60,     # the roughness floor (ships.md section 0 item 2, pass 5): no white specular glare at the game's key light
    # the plate patchwork in mixed sizes, rows offset at random, a few larger plates laid over (RULEBOOK 0.5: never a grid); the
    # sheet's modelled plates each take their own tone by UV island on top of it
    patch_big=(.046, .030, .026), patch_small=(.017, .012, .010), patch_over=(.060, .036, .030), patch_over_share=.08,
    patch_region=6.0, patch_parts=((.018, .014, .012), (.010, .008, .007), (.022, .016, .014)), patch_seam=.0010, seam_dark=.88,
    cavity_pow=2.2, wear_lo=.28, wear_hi=.50,
    scuff=.22, scuff_size=.050,                                           # fine machining scratches, never chips
    rivets=1, rivet_pitch=.012, rivet_band=(.0012, .0040),               # flush fasteners in a band in from each plate edge
    trim_size=dict(), trim_aspect=dict(),
    streak_scale=4.0, streak_stretch=60.0, rust_blot=26.0,                # no rust on the Eclipse (every zone's rust is 0)
    grime_z=(-.12, -.04), soot_x=(-.50, -.30), soot_aft=.10,              # a little grime low and toward the engines; no soot (no flame)
    wear_scale=70.0, wear_patch=5.0, bump_distance=.0008, bump_strength=.50,
)
ZONES = dict(
    shade=dict(rust=0, grime=.55, patchwork=1.0, patchwork_parts=.8),
    shade2=dict(rust=0, grime=.60, patchwork=1.0, patchwork_parts=.8),
    violet=dict(rust=0, grime=.55, patchwork=.9, patchwork_parts=.7),
    mauve=dict(rust=0, grime=.55, patchwork=.7, patchwork_parts=.6),
    lilac=dict(rust=0, grime=.70, patchwork=.6, plate_var=.25),
    gunv=dict(rust=0, metal=.50, rough=.62, wear=1.0, patchwork_parts=.6),
    steel=dict(rust=0, metal=.55, rough=.60, wear=.9, patchwork_parts=.6),
    iron=dict(rust=0, metal=.45, rough=.66, rivets=0, scuff=.1),
    dark=dict(rust=0, grime=.2, wear=.10, scuff=.05, rivets=0, metal=.1, rough=.92, plate_var=.08),
    bell=dict(base='gunv', rust=0, metal=.30, rough=.82, wear=.5, grime=.8),     # engine bells and housings: matte, never mirror black
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
# the patchwork families: (share of panels, colour pair[, 'small']). Shares by eye from the concepts' plate clusters: the dark
# shade most, then deep violet, the redder mauve, a few weathered pale plates, small only (never whole big pale plates)
PATCH_FAMILIES = [(.30, pair('shade')), (.22, pair('shade2')), (.16, pair('violet')), (.10, pair('mauve')), (.03, pair('lilac'), 'small')]
PATCH_FAMILIES_PARTS = [(.28, pair('gunv')), (.22, pair('shade')), (.16, pair('violet')), (.10, pair('mauve')), (.03, pair('lilac'), 'small')]

# ------------------------------------------------------------------------------------------------------------ the light
# glowing zones keep their own emissive surface. The corona line and the core are the faction's green-white (factions.md; their
# colour is the sheet's zone, whitened here as above); the engine ring is the game's Eclipse engine colour (godot/fx/
# faction_looks.json deathless engine, the colour the game's engine plume is drawn in), paled toward white, with a touch of its
# accent (the white-gold corona the game puts round each engine core). Brightness: the corona line just over the game's 0.8 glow
# threshold, so a thin line gets a faint edge of fire and never a fat halo; the core brighter, it is the one bright point.
GLOW = ('corona', 'ecore', 'lens')
GLOW_STRENGTH = dict(corona=1.05, ecore=1.9, lens=1.6)
CLOSE = dict(corona='rim', ecore='core')       # paint_sheet.py renders a close view of each of these (the rim line, the core)


def faction_look():
    p = os.path.join(REPO, 'godot', 'fx', 'faction_looks.json')
    d = json.load(open(p, encoding='utf-8'))
    return d.get(FACTION) or d.get('factions', {}).get(FACTION)


def glow_material(zone):
    m = bpy.data.materials.new(f'p3_{zone}'); m.use_nodes = True
    b = m.node_tree.nodes['Principled BSDF']
    col = lin_raw(CORE_RGB if zone in ('ecore', 'lens') else CORONA_RGB)
    b.inputs['Base Color'].default_value = (col[0] * .05, col[1] * .05, col[2] * .05, 1); b.inputs['Roughness'].default_value = .6
    b.inputs['Emission Color'].default_value = (*col, 1); b.inputs['Emission Strength'].default_value = GLOW_STRENGTH.get(zone, 1.0)
    m['ps_glow'] = 1; m['rim_soft'] = 1
    if zone in CLOSE: m['ps_close'] = CLOSE[zone]
    return m


# The engine (Ryan, Nov 12, on the Hullbreaker engines: "more variation to the engine glow so it's not so uniform, just disc
# color"; factions.md: no flaming bells, an eclipse ring of pale light). The sheet's engine is a bell with a thin corona ring just
# inside the lip round a black shade disc set back (tools/blender/kits/eclipse/parts.py engine_bell): an eclipse seen end on. The
# stack gives the ring its own emission map (shared/paint_stack.bake_engine_glow with this stack's engine_glow_nodes): bright
# round most of the ring, brighter on its inner edge (the light leaking round the disc), uneven hot spots and dim gaps round the
# circle (each engine its own pattern), each engine its own brightness and its own tint (paler, or warmer toward the accent).
# The disc stays the dark zone: the ring is the light, the middle is black. The game's moving plume sits on top; no flame.
ENGINE_GLOW = dict(zones=('corona',), kind='engine', disc=('corona',), plug=(),
                   pale=.25, accent=(0.0, .35), bright=(.45, 1.15), hotspot_scale=7.0, hotspot=(.40, .72), hotspot_gain=.90,
                   gaps=(.30, .55), gap_dark=.90, inner_gain=.35, norm=.50, strength=1.0, base=(.008, .006, .012))


def engine_glow_nodes(nt, r, e, d, a, tc, H):
    """the ring's emission colour (H: the shared node helpers node, math_, ramp, mixc, noise)"""
    E = ENGINE_GLOW; f = faction_look()
    eng = [float(c) for c in f['engine']]; acc = [float(c) for c in (f.get('accent') or f['engine'])]
    pale = [c + (1 - c) * E['pale'] for c in eng]
    math_, ramp, mixc, node = H['math_'], H['ramp'], H['mixc'], H['node']
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
    # the inner edge of the ring is brighter (the light round the disc); r is the distance from the axis over the ring's outer radius
    heat = math_(nt, 'MULTIPLY', heat, math_(nt, 'ADD', 1.0, math_(nt, 'MULTIPLY', ramp(nt, r, .97, .90), E['inner_gain'])))
    heat = math_(nt, 'MULTIPLY', heat, math_(nt, 'ADD', E['bright'][0], math_(nt, 'MULTIPLY', e, E['bright'][1] - E['bright'][0])))
    return H['mulc'](nt, col, math_(nt, 'MULTIPLY', heat, E['norm'], clamp=True))     # the map holds 0..1; strength sets the light


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
