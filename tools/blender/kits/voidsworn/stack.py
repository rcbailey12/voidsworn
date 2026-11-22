# The Sunward Crusade (`voidsworn`) paint stack for ships built from a build sheet (issue 756). Written once for the faction's kit
# and used by every Sunward sheet ship (S8 the Daybreak flagship first; R218; RULEBOOK 0.9, R225: one home per fact). The
# machinery is shared and has no look (tools/blender/kits/shared/paint_stack.py); everything that looks like the Sunward is here.
# The worked examples it follows are the Hullbreaker stack (kits/hullbreakers/stack.py, issue 601) and the Eclipse stack
# (kits/eclipse/stack.py, issue 642).
#
# The method (ships.md section 0 item 2, R96 Q1, binding): procedural layers driven by masks baked from the ship's own geometry
# (ambient occlusion, edges), a trim sheet and decals. Colours are SAMPLED from the accepted concept (S8); the concept picture is
# never projected onto the ship. No downloaded asset: the trim sheet and the decal atlas are drawn by this file (own work
# dedicated CC0, written into the job's textures folder with their licence lines, RULEBOOK 5.13).
#
# The direction is contrib/muse/design/paint_direction_2026_11/sunward.md, approved by Ryan at the swatch review (Nov 14 2026)
# with his rulings (summary.md): frost-white running points on the blade's edge at about 0.72 of the glow threshold; frost
# markings as decals under a 6 percent cap. The faction (docs/playbooks/factions.md): "a black iron blade with burning spires";
# forged, heavy; plate with rivet lines, never rust; black iron, frost-white markings, bright ember; never blue light.
#
# Where each colour zone sits on a ship is the build sheet's decision (the kit's materials siron, siron2, sworn, dark; glow zones
# glow, ember, embar, frost: tools/blender/kits/voidsworn/parts.py MATS); this file says what each is made of.
import os, sys, json, math
from functools import partial
import numpy as np
import bpy

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.normpath(os.path.join(HERE, '..', '..', '..', '..'))
SHARED = os.path.normpath(os.path.join(HERE, '..', 'shared'))
if SHARED not in sys.path: sys.path.insert(0, SHARED)
from paint_colors import LIGHT_GAIN, battle_lift, lin, lin_raw
FACTION = 'voidsworn'


battle_lift = partial(battle_lift, FACTION)
LIFT = battle_lift()

# ------------------------------------------------------------------------------------------------------------ concept colours
# sunward.md section 2: sampled from S8 (contrib/codex/design/concept_round5_2026_11/voidsworn_S8_sheet.jpg) by the chair,
# k-means, 9 clusters, background excluded by corner colour; sample_concept() below repeats the method on the S8 beauty.
# (dark, light) sRGB show-tones: the tone the plate must SHOW in the game at the battle camera, face-on to the key light.
CONCEPT = dict(
    iron=((25, 22, 21), (82, 81, 81)),          # body plates, #191615 / #525151 (hull mid cluster #434242, 24.5 percent)
    iron_shade=((8, 8, 7), (59, 53, 50)),       # recessed fields, #080807 / #3b3532
    # the builder's two plate-family steps inside the iron band (R237: separation by value steps between plate families, never
    # by noise): a darker cast and a slightly brighter cast, both between the iron pair and the shade pair, never the wear tones
    iron_dark=((16, 14, 13), (64, 61, 60)),
    iron_cast=((30, 28, 27), (88, 87, 86)),
    # worked iron (rivets, bands, rims, machinery: the kit's zone sworn): the iron pair's upper half; it differs from the plate by
    # its finish (more metal, smoother), not by a pale colour (sunward.md 4: #656564 to #848382 are wear tones only)
    worked=((30, 28, 27), (88, 87, 86)),
    wear=((101, 101, 100), (132, 131, 130)),    # dulled bright iron at the edges, #656564 to #848382 (S8's lit-edge clusters)
    soot=((8, 8, 7), (20, 18, 17)),             # carbon soot: the iron_shade dark end, never rust streaks
    liner=((13, 11, 10), (26, 21, 18)),         # interior liner #0d0b0a / #1a1512, dark with a faint warm tint
    frost=((231, 244, 255), (231, 244, 255)),   # frost markings (paint, not light): #e7f4ff, the sRGB read of the game accent
)
# The ember colours of S8 (sunward.md 2): the spire bars' deep and hot ends. They colour light (the spires), never paint.
SPIRE_DEEP = (169, 73, 17)      # #a94911, the radiator bar at its root
SPIRE_MID = (218, 111, 21)      # #da6f15
SPIRE_HOT = (252, 171, 59)      # #fcab3b, the bar tip


# Black iron needs no hue boost; compensate only for this faction's battle lift.
lin = partial(lin, lift=LIFT)


# R256 (Ryan, Nov 15 2026, on the painted S8: "Lighten a step") and R258 (Ryan, Nov 15 2026: "the x1.85 column"; issue 781): the
# whole painted map about x1.85 lighter in linear, toward the concept's grey at the battle camera (the S8 already matched the
# concept's median at the fitted camera and read dark only at 34 degrees). Not the lift and not the light (LIFT and LIGHT_GAIN are
# unchanged). CONCEPT above keeps the tones as sampled (sunward.md section 2; the battle median audit reads its iron band); the
# steps below are applied where the tones are painted:
#   WEAR_STEP  the wear tones (edge wear, scuffs and the painted rivet heads all mix toward BARE, the wear pair's light end) times
#              WEAR_STEP in linear, so the bright edges rise with the plates and still read lighter than them (sunward.md 4)
#   IRON_STEP  the iron family (pair()): each tone's brightest channel x moves up as WEAR_FLOOR * (x / WEAR_FLOOR) ** IRON_STEP,
#              WEAR_FLOOR the stepped wear pair's dark end, and its other channels scale with it in linear, so its hue holds: the
#              dark ends rise most, the light ends less, the family order (shade, dark, iron, cast and worked) holds, and every
#              plate stays under the wear tones (sunward.md 4: wear tones only, never plate tones)
# Soot, liner and frost do not move. IRON_STEP 1.0 and WEAR_STEP 1.0 give the sampled tones back.
WEAR_STEP = 1.85
IRON_STEP = .60
IRON_STEP_KEYS = ('iron', 'iron_shade', 'iron_dark', 'iron_cast', 'worked')


def _to_srgb255(c):
    c = np.clip(np.asarray(c, np.float64), 0, 1)
    return tuple(float(v) * 255.0 for v in np.where(c <= .0031308, c * 12.92, 1.055 * c ** (1 / 2.4) - .055))


def wear_tone(srgb):
    """a wear tone (sRGB show-tone) after the R258 wear step, as sRGB floats"""
    return _to_srgb255(np.asarray(lin_raw(srgb)) * WEAR_STEP)


WEAR_FLOOR = float(min(wear_tone(CONCEPT['wear'][0])))


def stepped(srgb):
    """an iron tone (sRGB show-tone) after the R256 and R258 iron step, as sRGB floats"""
    x = float(max(srgb))
    if x <= 0 or x >= WEAR_FLOOR: return tuple(float(c) for c in srgb)
    k = lin_raw((WEAR_FLOOR * (x / WEAR_FLOOR) ** IRON_STEP,))[0] / lin_raw((x,))[0]
    return _to_srgb255(np.asarray(lin_raw(srgb)) * k)


def pair(k):
    lo, hi = CONCEPT[k]
    if k in IRON_STEP_KEYS: lo, hi = stepped(lo), stepped(hi)
    return lin(lo), lin(hi)


# ------------------------------------------------------------------------------------------------------------ the layers
SCALE = 1.0          # every size below is in ship lengths (the recipe's frame: the ship is 1.0 long)
LAYERS = dict(
    ao_short=.004, ao_long=.025, edge_radius=.0018, edge_gain=24.0,
    # Sunward iron stays free of visible grain. The shared satin coat varies in roughness.
    side_dark=.25, grain_scale=260.0, mottle_scale=40.0, grain=0.0,
    rough=.33, metal=.48, wear=1.0, grime=.55, ao_dark=.90, red_tone=0.0,
    rough_floor=.28, bare_roughness=.21, rough_grain=.12, coat_roughness=.18,
    cavity_roughness=.22, scuff_roughness=.30, recess_streaks=1.0, plate_tone_range=.08,
    # sunward.md 1: triangles on the flat fields (patch_big), rectangles on the curves and the triangular infill (patch_small),
    # over-plates at deck edges and spire roots only (patch_over, a share of .08 of their cells)
    patch_big=(.070, .038, .028), patch_small=(.030, .018, .014), patch_over=(.060, .036, .026), patch_over_share=.08,
    patch_region=3.0, patch_seam=.0014, seam_dark=.90,
    # R243 (Ryan, Nov 13 2026: "Sunward could have more triangle sleek panels"; a hull's order follows its faction's lore): the
    # Sunward plates are FORGED, not scavenged, so their order is deliberate and stays exact. patch_warp, patch_band and
    # patch_split are 0 and stay 0: the uneven warped grid is the Hullbreakers' opt-in only (R240, PR 682), never "fix" this order
    # into warp. panel_nodes follows modeled plate islands and draws the Sunward pattern on exposed shell fields, so the
    # shared _grid never sees these zeros.
    patch_warp=0, patch_band=0, patch_split=0,
    cavity_pow=1.6, wear_lo=.22, wear_hi=.46,
    scuff=.35, scuff_size=.050,
    rivets=1, rivet_pitch=.011, rivet_band=(.0012, .0040),               # sunward.md 4: rivet lines are the trim, pitch .011
    rivet_set=.0016, rivet_head=.0026,                                    # the painted rivet rows along the plates' long edges
    trim_size=dict(), trim_aspect=dict(),
    streak_scale=4.0, streak_stretch=60.0, rust_blot=26.0,                # never rust (every zone's rust is 0)
    grime_z=(-.12, -.04), soot_x=(-.50, -.30), soot_aft=.30,              # soot gathers low and toward the ember bells
    wear_scale=50.0, wear_patch=3.0, bump_distance=.0008, bump_strength=.50, panel_relief=.90,
)
# Grime is carbon soot (GRIME below), with rust 0 everywhere. Recesses keep a rougher coat than exposed iron.
_Z = dict(
    siron=dict(rust=0, grime=.55, patchwork=1.0, rough=.33, metal=.48, wear=1.08),
    siron2=dict(rust=0, grime=.70, patchwork=.8, rough=.52, metal=.35, wear=.48),
    sworn=dict(rust=0, grime=.45, patchwork=1.0, rough=.26, metal=.62, wear=1.32, handling_wear=.50),
    dark=dict(rust=0, grime=.2, wear=.10, scuff=.05, rivets=0, metal=.1, rough=.92),
)
_BASE = dict(siron='iron', siron2='iron_shade', sworn='worked', dark='soot')
# sunward.md 3 grime by place: gun decks .60, spire roots .20 (heat burns them cleaner), bells .30. A part kind's plates take
# their own zone (ZONE_BY_KIND, read by the shared bake): the guns' ports and mantlets, the radiator spires' sockets and posts,
# the engine bells' drums and housings.
_BY_KIND = dict(gun=.60, radiator=.20, engine=.30)
ZONES = dict(_Z)
ZONE_BY_KIND = {}
for _kind, _g in _BY_KIND.items():
    for _zn in ('siron', 'siron2', 'sworn'):
        _nz = f'{_zn}_{_kind}'; ZONES[_nz] = dict(_Z[_zn], grime=_g); _BASE[_nz] = _BASE[_zn]
        ZONE_BY_KIND[(_kind, _zn)] = _nz
for _k, _z in ZONES.items():
    _z['lo'], _z['hi'] = pair(_BASE[_k])
FALLBACK = 'siron'
MODULE_TONES = dict(body=1.0, dark_cast=.94, worked=1.02)
HULL_FAMILIES = ('body', 'dark_cast')
PART_FAMILIES = dict(gun='worked', engine='worked', radiator='worked')
SURFACE_DUTIES = dict(siron='panel', siron2='recess', sworn='band', dark='recess')
for (_kind, _zone), _part_zone in ZONE_BY_KIND.items():
    SURFACE_DUTIES[_part_zone] = dict(siron='machinery', siron2='recess', sworn='edge')[_zone]
BARE = lin(wear_tone(CONCEPT['wear'][1]))   # the wear tone, dulled bright iron (the shared wear and scuff layers and the
#                                              rivet heads mix toward it), after the R258 wear step
GRIME = lin(CONCEPT['soot'][0])       # carbon soot
RUST = RUST_DARK = GRIME              # read by the shared rust layer only where a zone has rust, and no Sunward zone has

# The A4 sheets already carry livery, panel seams and rivets in a single atlas.
LEGACY_FINISH_ZONE = 'siron'
LEGACY_ALBEDO_BLEND = .64
LEGACY_COAT = dict(rough=.24, metal=.48, wear=1.32, handling_wear=.40, rivets=0, normal_strength=.85)


def legacy_paint_mesh(obj):
    """Keep hidden damage skins that share the exterior UVs out of the bake."""
    return obj.get('kind') not in ('breach_skin', 'ram_skin')


def legacy_panel_colour(c, colour):
    """Step the iron values by connected piece while keeping the installed livery."""
    from paint_stack import math_, mulc, node, ramp

    nt = c.nt
    luma = node(nt, 'ShaderNodeRGBToBW')
    nt.links.new(colour, luma.inputs[0])
    value = luma.outputs[0]
    iron = math_(nt, 'MULTIPLY', ramp(nt, value, .007, .019), ramp(nt, value, .24, .10))
    step = math_(nt, 'MULTIPLY', c.geo.outputs['Random Per Island'], LAYERS['plate_tone_range'])
    return mulc(nt, colour, math_(nt, 'ADD', 1, math_(nt, 'MULTIPLY', iron, step)))


def authored_panel_mesh(obj):
    """The sheet's forged plates are disconnected mesh islands."""
    return '_plates_' in obj.name


def _zone_of(nt):
    """the zone of the material this node tree belongs to (the shared stack names it ps_<zone>_<group>)"""
    for m in bpy.data.materials:
        if m.node_tree is not None and m.node_tree == nt:
            return m.name[3:].rsplit('_', 1)[0] if m.name.startswith('ps_') else m.name
    return ''


def panel_nodes(c, col, amount, families=None, cells=None):
    """sunward.md 1 and R243: two regions, one forged order. On the hull (cells None), the flat fields carry sleek triangular
    plates: long edge on the hull axis, point forward, nested point to base, the rows running straight along the decks (on a
    deck the rows run along y, on a flank along z); two rows meet as an arrowhead. Curved shell faces carry small rectangles.
    Painted over-plates sit at deck edges, and painted rivet rows follow the triangles' long edges. Modeled plates use
    their actual rims and rivets and take one quiet tone per connected plate. Returns the colour and the seam mask."""
    from paint_stack import node, math_, mixc, mulc, ramp, _grid_even, _seams
    from types import SimpleNamespace
    nt = c.nt; L = LAYERS; S_ = SimpleNamespace(LAYERS=LAYERS)
    hull = cells is None
    zone = _zone_of(nt)
    base_col = col

    # the rectangles: the even grid (shared _grid_even, the pre-R240 grid), at the small size
    small = (cells[0] if cells else L['patch_small'])
    _, rlines = _grid_even(c, small, 37.0, (.013, .007, .005))
    rseam = _seams(c, S_, rlines)
    if hull:
        nx = node(nt, 'ShaderNodeSeparateXYZ'); nt.links.new(c.geo.outputs['Normal'], nx.inputs[0])
        ax, ay, az = (math_(nt, 'ABSOLUTE', nx.outputs[k]) for k in range(3))
        tri = math_(nt, 'SUBTRACT', 1, ramp(nt, ax, .50, .62))                    # 1 on the flat fields, 0 on faces turned fore or aft
        deck = math_(nt, 'GREATER_THAN', az, ay)                                  # 1 on a deck (rows along y), 0 on a flank (rows along z)
        Lx, Ly, Lz = L['patch_big']
        u = math_(nt, 'DIVIDE', c.x, Lx)
        vd = math_(nt, 'DIVIDE', c.y, Ly); vf = math_(nt, 'DIVIDE', c.z, Lz)
        v = math_(nt, 'ADD', vf, math_(nt, 'MULTIPLY', deck, math_(nt, 'SUBTRACT', vd, vf)))
        H = math_(nt, 'ADD', Lz, math_(nt, 'MULTIPLY', deck, Ly - Lz))           # the row height in ship lengths on this face
        row = math_(nt, 'FLOOR', v); fv = math_(nt, 'FRACT', v)
        pair_ = math_(nt, 'FLOOR', math_(nt, 'MULTIPLY', row, .5))
        odd = math_(nt, 'SUBTRACT', row, math_(nt, 'MULTIPLY', pair_, 2.0))     # 0 the lower row of a pair, 1 the upper
        uu = math_(nt, 'ADD', u, math_(nt, 'MULTIPLY', math_(nt, 'FRACT', math_(nt, 'MULTIPLY', pair_, .5)), 1.0))   # every second pair half a plate along
        fu = math_(nt, 'FRACT', uu)
        # the lower row's forward plate has its long edge on the row's TOP line, the upper row's on its BOTTOM line, so the pair's
        # forward plates share one long edge (the arrowhead); g is the distance up from that shared line, 0..1 across the row
        g = math_(nt, 'ADD', math_(nt, 'MULTIPLY', odd, fv), math_(nt, 'MULTIPLY', math_(nt, 'SUBTRACT', 1, odd), math_(nt, 'SUBTRACT', 1, fv)))
        # seams: the row lines, the plate bases (across the row) and the diagonal; distances in ship lengths
        d_row = math_(nt, 'MULTIPLY', math_(nt, 'MINIMUM', fv, math_(nt, 'SUBTRACT', 1, fv)), H)
        d_col = math_(nt, 'MULTIPLY', math_(nt, 'MINIMUM', fu, math_(nt, 'SUBTRACT', 1, fu)), Lx)
        k = math_(nt, 'DIVIDE', 1.0, math_(nt, 'SQRT', math_(nt, 'ADD', 1.0 / (Lx * Lx), math_(nt, 'DIVIDE', 1.0, math_(nt, 'MULTIPLY', H, H)))))
        d_dia = math_(nt, 'MULTIPLY', math_(nt, 'ABSOLUTE', math_(nt, 'SUBTRACT', math_(nt, 'ADD', fu, g), 1.0)), k)
        d = math_(nt, 'MINIMUM', d_row, math_(nt, 'MINIMUM', d_col, d_dia))
        tseam = math_(nt, 'SUBTRACT', 1, ramp(nt, d, L['patch_seam'] * .4, L['patch_seam']))
        seam = math_(nt, 'ADD', math_(nt, 'MULTIPLY', tseam, tri), math_(nt, 'MULTIPLY', rseam, math_(nt, 'SUBTRACT', 1, tri)))
        # rivet rows along the long edges (the row lines), set in from each line, at the rivet pitch along the hull axis
        p = L['rivet_pitch']
        dx = math_(nt, 'MULTIPLY', math_(nt, 'SUBTRACT', math_(nt, 'FRACT', math_(nt, 'DIVIDE', c.x, p)), .5), p)
        dv = math_(nt, 'SUBTRACT', d_row, L['rivet_set'])
        rr = math_(nt, 'SQRT', math_(nt, 'ADD', math_(nt, 'MULTIPLY', dx, dx), math_(nt, 'MULTIPLY', dv, dv)))
        hr = L['rivet_head'] / 2
        head = math_(nt, 'MULTIPLY', math_(nt, 'SUBTRACT', 1, ramp(nt, rr, hr * .55, hr)), tri)
        ring = math_(nt, 'MULTIPLY', math_(nt, 'MULTIPLY', ramp(nt, rr, hr * .55, hr), math_(nt, 'SUBTRACT', 1, ramp(nt, rr, hr, hr * 1.35))), tri)
        col = mixc(nt, col, BARE, math_(nt, 'MULTIPLY', head, .30))
        seam = math_(nt, 'MAXIMUM', seam, math_(nt, 'MULTIPLY', ring, .5))
        # over-plates at the deck edges: up-facing faces near a convex edge
        near = ramp(nt, c.bevel_edge(.025, 30.0), .05, .25)
        over_w = math_(nt, 'MULTIPLY', math_(nt, 'GREATER_THAN', az, .7), near)
    else:
        seam = rseam
        over_w = 1.0 if zone.endswith('_radiator') else 0.0                        # the spire roots' sockets and posts
    if not isinstance(over_w, float) or over_w > 0:
        oid, olines = _grid_even(c, L['patch_over'], 71.0, (.021, .011, .009))
        ow = node(nt, 'ShaderNodeTexWhiteNoise', noise_dimensions='3D'); nt.links.new(oid, ow.inputs['Vector'])
        on = math_(nt, 'MULTIPLY', math_(nt, 'LESS_THAN', ow.outputs['Value'], L['patch_over_share']), over_w)
        seam = math_(nt, 'MAXIMUM', math_(nt, 'MULTIPLY', seam, math_(nt, 'SUBTRACT', 1, on)), math_(nt, 'MULTIPLY', _seams(c, S_, olines), on))
    if hull:
        plates = node(nt, 'ShaderNodeAttribute', attribute_type='GEOMETRY', attribute_name='ps_authored_panels').outputs['Fac']
        island = c.geo.outputs['Random Per Island']
        shade = math_(nt, 'MULTIPLY', math_(nt, 'SUBTRACT', 1, island), L['plate_tone_range'])
        plate_col = mulc(nt, base_col, math_(nt, 'SUBTRACT', 1, shade))
        col = mixc(nt, col, plate_col, plates)
        seam = math_(nt, 'MULTIPLY', seam, math_(nt, 'SUBTRACT', 1, plates))
    return col, math_(nt, 'MULTIPLY', seam, amount, clamp=True)


# ------------------------------------------------------------------------------------------------------------ the light
# sunward.md 5. Nothing on the intact ship crosses the game's 0.8 glow threshold (godot/render/look.gd): the values below are the
# brightest linear channel of each light's emission colour times its strength, read as absolute values against 0.8, the way
# the Hullbreaker lamps are written (0.77). Colours are the game's (godot/fx/faction_looks.json voidsworn engine and accent) and
# S8's ember samples; never blue light (no Sunward emissive has blue over green: the stack checks it, emissive_audit()).
THRESHOLD = 0.8
BELL_PEAK = .75        # the bell throats, deep-set so the bloom stays contained (sunward.md 5: about 0.75)
SPIRE_PEAK = .78       # the spire bar tips, just under the threshold (sunward.md 5: about 0.78)
FROST_PEAK = .72       # the frost running points on the blade's edge (Ryan at the swatch review: about 0.72)
WINDOW_PEAK = .62      # the ember window slits of the command deck (the builder's call: under the spires, never a second line)
VENT_PEAK = .45        # the heat louvres' ember recess (dim)
BORE_PEAK = .66        # the gun bores, turret lenses and turret radiator fins (ember deep in the bore)
# Every light but the frost points and the slits and louvres shares one emission map (shared/paint_stack.bake_engine_glow): the
# bell throat and lining (kind 0, the shared throat drawing in the game's engine colour), the spire fins (kind 1: deep at the
# root to hot at the tip, each spire its own) and the gun bores and lenses (kind 2). The map is baked at final brightness and
# the surface carries strength 1.0, so the map's brightest pixel is the light's brightest channel.
GLOW = ('glow', 'ember', 'embar', 'frost')
GLOW_HULL = ()


def faction_look():
    p = os.path.join(REPO, 'godot', 'fx', 'faction_looks.json')
    d = json.load(open(p, encoding='utf-8'))
    return d.get(FACTION) or d.get('factions', {}).get(FACTION)


def _peak(col, peak):
    """a light colour scaled so its brightest channel is peak"""
    m = max(col) or 1.0; return tuple(float(c) * peak / m for c in col)


def frost_rgb():
    """the frost running point's colour: the game's voidsworn accent (0.8, 0.9, 1.0) with its blue held to its green, because
    the faction never shows blue light (factions.md; sunward.md 5 asks the builder to verify no blue over green; the kit's own
    frost row does the same). The point reads cool white, the ship's only cool light"""
    a = [float(c) for c in faction_look()['accent']]
    return (a[0], a[1], min(a[2], a[1]))


def ember_rgb():
    return tuple(float(c) for c in faction_look()['engine'])


GLOW_FLAT = dict(       # the flat lights (no map): name, colour, peak
    glow=('p3_window', lambda: _peak(ember_rgb(), WINDOW_PEAK)),
    ember=('p3_vent', lambda: _peak(ember_rgb(), VENT_PEAK)),
    embar=('p3_bore', lambda: _peak(lin_raw(SPIRE_MID), BORE_PEAK)),
    frost=('p3_frost', lambda: _peak(frost_rgb(), FROST_PEAK)),
)


def glow_material(zone, hull=False):
    """a flat light (no map): the ember window slits (glow on a slit), the heat louvres (ember on a vent), the frost running
    points (frost). Never named p3_glow (export7 names the first p3_glow material the ship's glow surface: the map's)"""
    name, f = GLOW_FLAT.get(zone, ('p3_' + zone, lambda: _peak(ember_rgb(), VENT_PEAK)))
    m = bpy.data.materials.new(name); m.use_nodes = True
    b = m.node_tree.nodes['Principled BSDF']; col = f()
    base = (.03, .03, .03) if zone == 'frost' else (col[0] * .04, col[1] * .04, col[2] * .04)
    b.inputs['Base Color'].default_value = (*base, 1); b.inputs['Roughness'].default_value = .6
    b.inputs['Emission Color'].default_value = (*col, 1); b.inputs['Emission Strength'].default_value = 1.0
    m['ps_glow'] = 1; m['rim_soft'] = 1; m['ps_peak'] = max(col)
    if zone == 'frost': m['ps_close'] = 'frost'
    return m


def glow_vertex(o):
    """the per-vertex inputs of a light on the map that is not an engine bell (shared bake_engine_glow calls this): colour
    attribute ps_glow R the height up a spire (0 its root, 1 its tip), G the light's own random, B the place out along a fin (0
    at the spire's column, 1 at the fin's edge); float attribute ps_kind 1 a
    radiator spire's fins, 2 a gun bore, turret lens or turret radiator fin"""
    me = o.data
    # every attribute is made first and only then looked up again by name and written in one call each (adding an attribute
    # moves the mesh's attribute storage; a handle taken before it crashed Blender 4.5 on Ryan's PC, issue 642)
    if me.color_attributes.get('ps_glow') is None: me.color_attributes.new('ps_glow', 'FLOAT_COLOR', 'POINT')
    if me.attributes.get('ps_kind') is None: me.attributes.new('ps_kind', 'FLOAT', 'POINT')
    rnd = (sum(ord(c) for c in o.name) * 0.61803) % 1.0
    n = len(me.vertices); col = np.zeros((n, 4), np.float32); col[:, 1] = rnd
    spire = o.get('part_kind') == 'radiator'
    if spire:
        W = np.array([tuple(o.matrix_world @ v.co) for v in me.vertices], np.float32)
        col[:, 0] = (W[:, 2] - W[:, 2].min()) / max(float(W[:, 2].max() - W[:, 2].min()), 1e-6)
        cy = (W[:, 1].max() + W[:, 1].min()) / 2; ry = max(float(np.abs(W[:, 1] - cy).max()), 1e-6)
        col[:, 2] = np.abs(W[:, 1] - cy) / ry          # B: out along the fin from the spire's column (0) to the fin's edge (1)
        if o.get('ps_close') is None: o['ps_close'] = 'spire'
    else:
        col[:, 0] = .5
    me.color_attributes['ps_glow'].data.foreach_set('color', col.ravel())
    me.attributes['ps_kind'].data.foreach_set('value', np.full(n, 1.0 if spire else 2.0, np.float32))


def _ramp_to(col, peak, stops):
    """a throat ramp in the game's engine colour, its top at peak: (position, fraction of the top)"""
    top = _peak(col, peak)
    return [(p, tuple(c * k ** g for c, g in zip(top, (1.0, 1.6, 2.4)))) for p, k in stops]


# the bell throat (factions.md: big bells, ember orange, deep-set): the shared throat drawing (shared/paint_stack._throat_glow,
# the Hullbreakers' hot core on the axis, the plug hottest, hot spots, soot streaks, the lining dark toward the lip, each engine
# its own), in the game's Sunward engine colour, its top held to BELL_PEAK
ENGINE_GLOW = dict(kind='engine', zones=('glow', 'ember'), disc=('glow',), plug=(), extra_zones=('embar',), res_frac=.5,
                   core_reach=(.70, 1.6), lining_gain=.60, lining_falloff=2.0, hotspot_scale=700.0, hotspot=(.56, .70),
                   hotspot_gain=.30, streaks=14.0, soot=(.52, .70), soot_gain=.45, bright=(.70, 1.10), hue_shift=.20, strength=1.0,
                   base=(.02, .012, .008))
# Ryan, Nov 20 2026 on the Warden ("fix ember glow"): the light is the spire's heat core, lit the full height under the iron ribs
# (parts.radiator glow='slats'), so the root keeps .45 of the tip and the old fore-and-aft bar stripes are only a faint
# unevenness, never dark gaps across the core.
# Ryan, Nov 20 2026 13:43 UTC, on the Board card of S8 today beside a brighter mock-up: "A bit brighter". The tip stays at
# SPIRE_PEAK (under the 0.8 glow threshold, no halo); the rest of the core comes up toward it: the root .70 of the tip (was
# .45), the fins cool less toward their edges (.50, was .80), less fin-to-fin flicker (.15, was .30) and less striping (.06,
# was .12). The mean lit level of a spire rises about 1.5 times (.49 to .73 of the peak). Every Sunward spire takes it.
SPIRE = dict(curve=.9, edge=.50, bright=(.94, 1.0), flicker_scale=90.0, flicker=.15, root=.70, bar_pitch=.0045, bar_gap=(.55, .80),
             gap_dark=.06)


def node_sep(nt, vec, H):
    """the x (fore and aft) of a position socket"""
    n = H['node'](nt, 'ShaderNodeSeparateXYZ'); nt.links.new(vec, n.inputs[0]); return n.outputs[0]


def engine_glow_nodes(nt, r, e, d, a, tc, H):
    """the emission colour of every light on the map (kind 0 a bell throat and lining, 1 a spire's fins, 2 a bore or lens)"""
    import paint_stack as PS
    math_, ramp, mixc, mulc = H['math_'], H['ramp'], H['mixc'], H['mulc']
    E = dict(ENGINE_GLOW, ramp=_ramp_to(ember_rgb(), BELL_PEAK, [(0.0, .02), (.25, .25), (.50, .55), (.75, .82), (1.0, 1.0)]))
    throat = PS._throat_glow(nt, E, r, e, d, a, tc, H['noise'])
    # the spire: deep ember at the root to hot at the tip (sunward.md 5: #a94911 to #fcab3b), each spire its own brightness
    # (never above the tip's peak) and a slow unevenness up the stack; the root never dark (the root .30 of the tip)
    # sunward.md 2: the bar centres hot (spire_hot), the bar sides the deeper spire pair: each fin hottest at the column and
    # cooling out to its edge (d, out along the fin), so the fins read as radiator bars, never flat painted planks (R237)
    S_ = SPIRE; h = math_(nt, 'POWER', r, S_['curve'])
    h = math_(nt, 'MULTIPLY', h, math_(nt, 'SUBTRACT', 1, math_(nt, 'MULTIPLY', ramp(nt, d, .15, 1.0), S_['edge'])))
    deep = _peak(lin_raw(SPIRE_DEEP), SPIRE_PEAK); hot = _peak(lin_raw(SPIRE_HOT), SPIRE_PEAK)
    scol = mixc(nt, deep, hot, h)
    lvl = math_(nt, 'ADD', S_['root'], math_(nt, 'MULTIPLY', h, 1 - S_['root']))
    lvl = math_(nt, 'MULTIPLY', lvl, math_(nt, 'ADD', S_['bright'][0], math_(nt, 'MULTIPLY', e, S_['bright'][1] - S_['bright'][0])))
    # the fins are cast as upright ember bars with dark iron gaps between them, fore and aft (S8's radiator bars): the bar
    # centres hottest, the gaps dark, so the fins never read as flat painted planks (R237: "neon paint")
    sx = node_sep(nt, tc.outputs['Object'], H)
    q = math_(nt, 'MULTIPLY', math_(nt, 'ABSOLUTE', math_(nt, 'SUBTRACT', math_(nt, 'FRACT', math_(nt, 'DIVIDE', sx, S_['bar_pitch'])), .5)), 2.0)
    lvl = math_(nt, 'MULTIPLY', lvl, math_(nt, 'SUBTRACT', 1, math_(nt, 'MULTIPLY', ramp(nt, q, S_['bar_gap'][0], S_['bar_gap'][1]), S_['gap_dark'])))
    fl = H['noise'](tc.outputs['Object'], S_['flicker_scale'], 0, .5)      # fin by fin
    lvl = math_(nt, 'MULTIPLY', lvl, math_(nt, 'SUBTRACT', 1, math_(nt, 'MULTIPLY', ramp(nt, fl, .35, .70), S_['flicker'])), clamp=True)
    spire = mulc(nt, scol, lvl)
    # the bores and lenses: the ember mid tone at its peak, a little uneven per gun
    bore = mulc(nt, mixc(nt, _peak(lin_raw(SPIRE_MID), BORE_PEAK), _peak(lin_raw(SPIRE_MID), BORE_PEAK * .8), e), 1.0)
    kd = H['kind']
    out = mixc(nt, throat, spire, math_(nt, 'GREATER_THAN', kd, .5))
    return mixc(nt, out, bore, math_(nt, 'GREATER_THAN', kd, 1.5))


def emissive_audit(job_dir, cell):
    """sunward.md 5 and 6: nothing on the intact ship over the glow threshold, no blue over green. Reads the baked emission map
    (its brightest pixel times its strength) and every flat light's colour times strength"""
    from PIL import Image
    out = dict(threshold=THRESHOLD, lights={})
    p = os.path.join(job_dir, f'{cell}_engine_emission.png')
    if os.path.exists(p):
        a = np.asarray(Image.open(p).convert('RGB')).astype(np.float64) / 255.0
        a = np.where(a <= .04045, a / 12.92, ((a + .055) / 1.055) ** 2.4) * ENGINE_GLOW['strength']
        lit = a.max(2) > .02
        out['lights']['map'] = dict(max=round(float(a.max()), 4), blue_over_green_px=int(((a[..., 2] > a[..., 1] + 1e-3) & lit).sum()))
    for z, (name, f) in GLOW_FLAT.items():
        c = f(); out['lights'][name] = dict(max=round(max(c), 4), blue_over_green=bool(c[2] > c[1] + 1e-6))
    out['pass'] = all(v['max'] < THRESHOLD for v in out['lights'].values()) and \
        not any(v.get('blue_over_green') or v.get('blue_over_green_px') for v in out['lights'].values())
    return out


# ------------------------------------------------------------------------------------------------------------ insides
# An inside seen from outside reads as the dark inner liner (R99 Q1): sunward.md's liner, dark with a faint warm tint, a faint
# tint per room so a broken ship's spaces are not all one; the reactor core keeps its ember light.
INSIDE_BASE = lin(CONCEPT['liner'][1])
INSIDE_TINT = .55      # issue 1743 (R416): lifted from .18 so a broken ship's rooms read apart
# Interior Kit V2 (issue 1743, R416 Layer 3): the shared trim maps (tools/blender/kits/shared/interior_trim.py) in this
# faction's look: black iron corridors, ember-lit (factions.md, Sunward: inside iron corridors, ember-lit; never blue light,
# never rust). INSIDE_LIFT lifts the room colour the maps carry (R416 root cause 2: crushed, unlit insides).
INSIDE_LIFT = 2.6
INSIDE_TRIM = None      # made on first use (it reads the faction's light colours)


def inside_trim():
    global INSIDE_TRIM
    if INSIDE_TRIM is None:
        INSIDE_TRIM = dict(style='panels', seed=1743, panel=8, split=0.4, var=0.12, grime=0.25, grille=0.2, conduit_rows=2, metal=0.3,
                   rough=(0.4, 0.75), relief=6.0, tones=((1.0, 1.0, 1.0), (0.82, 0.82, 0.86), (1.12, 1.08, 1.02)),
                   strip=dict(rgb=tuple(min(1.0, c) for c in ember_rgb()), every=4, strength=2.0))
    return INSIDE_TRIM


def inside_material(room, trim=False):
    """trim: the insides carry the Interior Kit V2 UVs, so the room takes the faction's shared trim maps (issue 1743)"""
    src = bpy.data.materials.get(room); m = bpy.data.materials.new(f'ps_inside_{room}'); m.use_nodes = True
    b = m.node_tree.nodes['Principled BSDF']; rgb = (1, 1, 1)
    if src is not None and src.use_nodes and src.node_tree.nodes.get('Principled BSDF'):
        sb = src.node_tree.nodes['Principled BSDF']; rgb = tuple(sb.inputs['Base Color'].default_value)[:3]
        em = sb.inputs['Emission Strength'].default_value
        if em > 0:      # the reactor core: its own light stays (the bright bite when the ship breaks), in the faction's ember
            b.inputs['Emission Color'].default_value = (*ember_rgb(), 1); b.inputs['Emission Strength'].default_value = em
    mx = max(rgb) or 1
    b.inputs['Base Color'].default_value = tuple(INSIDE_BASE[i] * (1 - INSIDE_TINT + INSIDE_TINT * rgb[i] / mx) for i in range(3)) + (1,)
    b.inputs['Roughness'].default_value = .9; b.inputs['Metallic'].default_value = .2
    if trim:
        import interior_trim
        return interior_trim.upgrade(m, 'voidsworn', inside_trim(), INSIDE_LIFT)
    m['ps_inside'] = 1
    return m


# ------------------------------------------------------------------------------------------------------------ running lights
# The Sunward running points are the sheet's own frost lamps (the kit's lamp: an iron housing and a frost lens, placed on the
# blade's edge by the sheet), painted here as the frost light (FROST_PEAK). The stack adds no lamps of its own and writes no
# lights.json: the red lamps are a Hullbreaker rule (R228 item 4).
RUNNING_LIGHTS = None


# ------------------------------------------------------------------------------------------------------------ decals
# sunward.md 4: frost-white markings are decals only, never a plate family: a spine line, broadside deck row numbers, heat-shed
# marks at the spire roots, plus the half-sun crest (the sheet's "Designed here": the crest is paint). Cap: at most 6 percent of
# any visible face (the stack's frost coverage audit measures it on the flat views). Edge wear runs last, over the decals (the
# shared stack's order). Placed by rule on each ship's own surfaces (shared/paint_stack.place_decals): x the station from the bow
# (0) to the stern (1), z the height band on the side, a top decal searches the deck at y. On a top decal the cell's up (its
# top row) points to the bow and w runs across the beam, h along the hull; on a side decal the cell's up is up.
DECAL_CELLS = 2      # 2 x 2: 0 the half-sun crest, 1 the spine line, 2 deck row numbers, 3 heat-shed marks
DECALS = [
    dict(name='half-sun crest', cell=0, face='top', x=(.30, .27, .33, .24, .36, .40), y=(0.0, .012, -.012, .03, -.03), w=.040, h=.026,
         alpha=.85, min_facing=.85, min_room=.6),
    dict(name='spine line', cell=1, face='top', x=(.10, .13, .16, .19, .22, .25, .08, .82, .86), y=(0.0, .004, -.004, .010, -.010), w=.005,
         h=.060, alpha=.80, min_facing=.85, min_room=.5),
    dict(name='deck row numbers', cell=2, face='side', x=(.44, .40, .48, .36, .52, .56), z=(.30, .75), w=.030, h=.011, alpha=.85,
         min_room=.6),
    dict(name='heat-shed marks port', cell=3, face='top', x=(.62, .58, .66, .70, .55), y=(.07, .06, .08, .05, .09, .10), w=.024, h=.016,
         alpha=.80, min_facing=.80, min_room=.6),
    dict(name='heat-shed marks starboard', cell=3, face='top', x=(.62, .58, .66, .70, .55), y=(-.07, -.06, -.08, -.05, -.09, -.10), w=.024,
         h=.016, alpha=.80, min_facing=.80, min_room=.6),
]
FROST_CAP = .06


def ship_code():
    p = os.environ.get('R209_SHIP', '')
    code = (json.load(open(p)).get('game_code') if p and os.path.exists(p) else '') or 'V00'
    return code.split('_')[0]


def _srgb(lin_rgb):
    c = np.clip(np.asarray(lin_rgb, np.float64), 0, 1)
    return np.where(c <= .0031308, c * 12.92, 1.055 * c ** (1 / 2.4) - .055)


def decal_atlas(res=1024, code=None):
    """the decal atlas, RGBA in 0..1 (sRGB colour, the albedo it paints), row 0 at the top; drawn here (own work). Frost white,
    stencilled and worn: never fresh paint. The deck numbers and the wear are seeded by the ship's game code"""
    code = code or ship_code()
    c = res // 2; A = np.zeros((res, res, 4), np.float32)
    rng = np.random.default_rng(sum(ord(ch) * (k + 3) for k, ch in enumerate(code)) + 756)
    frost = _srgb(lin(CONCEPT['frost'][1]))
    y, x = np.mgrid[0:c, 0:c]; u = x / c; v = y / c

    def put(cell, mask, col):
        cx, cy = cell % 2, cell // 2; sl = (slice(cy * c, cy * c + c), slice(cx * c, cx * c + c))
        a = A[sl]; m = mask.astype(np.float32) * (0.82 + 0.18 * rng.random(mask.shape))
        a[..., :3] = np.where(m[..., None] > 0, col, a[..., :3]); a[..., 3] = np.maximum(a[..., 3], m)
    # 0 the half-sun crest: a half disc on a horizon bar with seven rays (the Sunward's sun at the horizon), rising to the bow
    r = np.hypot(u - .5, v - .66); ang = np.arctan2(.66 - v, u - .5)
    disc = (r < .20) & (v <= .66)
    rays = np.zeros_like(disc)
    for k in range(7):
        t = math.pi * (k + .5) / 7; rays |= (np.abs(ang - t) < .07) & (r > .25) & (r < .42) & (v < .64)
    bar = (np.abs(v - .70) < .022) & (np.abs(u - .5) < .42)
    put(0, disc | rays | bar, frost)
    # 1 the spine line: a long stencilled band along the hull broken into dashes, an arrowhead at the forward end (the top row)
    band = (np.abs(u - .5) < .16) & (v > .16) & (v < .98) & (np.mod(v * 9, 1.0) < .82)
    head = (v > .02) & (v <= .14) & (np.abs(u - .5) < (v - .02) * 2.6)
    put(1, band | head, frost)
    # 2 deck row numbers: the deck's index in Roman strokes between two bracket ticks (I to V, seeded per ship)
    g = np.zeros((c, c), bool); n = int(rng.integers(2, 5))
    g |= (np.abs(u - .08) < .025) & (np.abs(v - .5) < .30); g |= (np.abs(u - .92) < .025) & (np.abs(v - .5) < .30)
    for k in range(n):
        xc = .5 + (k - (n - 1) / 2) * .16; g |= (np.abs(u - xc) < .035) & (np.abs(v - .5) < .26)
    put(2, g, frost)
    # 3 heat-shed marks: three chevrons pointing aft (the bottom rows; the heat leaves the spire roots astern), thin
    h = np.zeros((c, c), bool)
    for k in range(3):
        x0 = .22 + k * .26; h |= (np.abs(np.abs(u - x0) * 1.1 - (.70 - v)) < .045) & (v > .28) & (v < .72) & (np.abs(u - x0) < .17)
    put(3, h, frost)
    # wear: the marks are old; patches gone (edge wear eats them further, on the ship)
    holes = np.kron(rng.random((res // 16, res // 16)) < .12, np.ones((16, 16))) > 0
    A[..., 3] *= np.where(holes, .35, 1.0)
    return A


# ------------------------------------------------------------------------------------------------------------ the trim sheet
def _tile_noise(n, k, rng):
    g = rng.random((k, k)); up = np.kron(g, np.ones((n // k, n // k)))
    for _ in range(3): up = (up + np.roll(up, 1, 0) + np.roll(up, -1, 0) + np.roll(up, 1, 1) + np.roll(up, -1, 1)) / 5
    return (up - up.min()) / (up.max() - up.min() + 1e-9)


def trim_sheet():
    """the faction's trim tiles, each RGBA in 0..1 (alpha is the tile's mask and height): drawn here (own work). Forged domed
    rivets (a round head, a thin dark ring), and scuffs wiped along the ship: few, short, never chips of colour"""
    rng = np.random.default_rng(756)
    T = {}
    n = 128; y, x = np.mgrid[0:n, 0:n]; r = np.hypot(x - n / 2, y - n / 2) / (n * .15)
    dome = np.clip(1 - r * r, 0, 1); ring = np.clip(1 - np.abs(r - 1.12) * 3.5, 0, 1)
    a = np.clip(dome + ring * .45, 0, 1); col = np.stack([.28 + .32 * dome] * 3, -1) * (1 - ring[..., None] * .6)
    T['rivets'] = np.dstack([col, a])
    n = 512; m = np.zeros((n, n), np.float32)
    for _ in range(140):
        L = rng.uniform(12, 110); th = rng.normal(0, .18) + (math.pi / 2 if rng.random() < .15 else 0)
        x0, y0 = rng.uniform(0, n, 2); s = rng.uniform(.3, .85)
        for t in np.linspace(0, 1, int(L)):
            xi = int(x0 + math.cos(th) * L * t) % n; yi = int(y0 + math.sin(th) * L * t) % n
            m[yi, xi] = max(m[yi, xi], s); m[yi, (xi + 1) % n] = max(m[yi, (xi + 1) % n], s * .5)
    m = np.maximum(m, (_tile_noise(n, 64, rng) > .93) * .35)
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
    png(os.path.join(folder, 'sunward_trim.png'), _sheet_image(rows))
    png(os.path.join(folder, 'sunward_decals.png'), decals)
    src = 'own work, drawn by tools/blender/kits/voidsworn/stack.py and dedicated CC0 (no downloaded asset)'
    lines = [dict(file='sunward_trim.png', source=src, licence='CC0', used='trim sheet: forged rivets, scuffs (rows: ' + ', '.join(rows) + ')'),
             dict(file='sunward_decals.png', source=src, licence='CC0', used='decal atlas: half-sun crest, spine line, deck row numbers, heat-shed marks')]
    lp = os.path.join(os.path.dirname(folder.rstrip('/\\')), 'licences.json')
    old = json.load(open(lp, encoding='utf-8')).get('textures', []) if os.path.exists(lp) else []
    keep = [r for r in old if r.get('file') not in {l['file'] for l in lines}]
    json.dump(dict(textures=keep + lines), open(lp, 'w', encoding='utf-8'), indent=1)
    return lines


def sample_concept():
    """repeat the colour sampling of sunward.md section 2 on the S8 beauty (needs Pillow): k-means, 9 clusters, the background
    (pixels near the corner colour) left out; returns the cluster centres and shares, dark to light"""
    from PIL import Image
    p = os.path.join(REPO, 'contrib', 'codex', 'design', 'concept_round5_2026_11', 'voidsworn_S8_beauty.jpg')
    im = np.asarray(Image.open(p).convert('RGB')).astype(np.float32); bg = im[:8, :8].reshape(-1, 3).mean(0)
    X = im.reshape(-1, 3); X = X[np.abs(X - bg).sum(1) > 24]
    rng = np.random.default_rng(1); X = X[rng.choice(len(X), min(60000, len(X)), replace=False)]; C = X[rng.choice(len(X), 9, replace=False)]
    for _ in range(40):
        a = ((X[:, None] - C[None]) ** 2).sum(2).argmin(1); C = np.array([X[a == j].mean(0) if (a == j).any() else C[j] for j in range(9)])
    return [(tuple(int(v) for v in C[j]), round(float((a == j).mean()), 3)) for j in np.argsort(C.mean(1))]
