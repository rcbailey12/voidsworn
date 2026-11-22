# The Hegemony Navy (`hegemony`) paint stack for ships built from a build sheet (issue 780). Written once for the faction's kit
# and used by every Hegemony sheet ship (H10 the Dominion dreadnought and IM5 the Iron Mandate first; R218; RULEBOOK 0.9, R225:
# one home per fact). The machinery is shared and has no look (tools/blender/kits/shared/paint_stack.py); everything that looks
# like the Hegemony is here. The worked examples it follows are the Hullbreaker stack (kits/hullbreakers/stack.py, issue 601),
# the Eclipse stack (kits/eclipse/stack.py, issue 642) and the Sunward stack (kits/voidsworn/stack.py, issue 756).
#
# The method (ships.md section 0 item 2, R96 Q1, binding): procedural layers driven by masks baked from the ship's own geometry
# (ambient occlusion, edges), a trim sheet and decals. Colours are SAMPLED from the accepted concept (H10); the concept picture
# is never projected onto the ship. No downloaded asset: the trim sheet and the decal atlas are drawn by this file (own work
# dedicated CC0, written into the job's textures folder with their licence lines, RULEBOOK 5.13).
#
# The direction is contrib/muse/design/paint_direction_2026_11/hegemony.md, approved by Ryan at the swatch review (Nov 14 2026)
# with his rulings (summary.md): the module band is structure, not ornament; the H10 sample holds with the #626d7d cap, no
# deliberate lightening. The faction (docs/playbooks/factions.md): "a pale wedge with a line of blue light"; machined, modular,
# horizontal; flush panels, straight seams, repeated modules; never rust, asymmetry, ornament or warm light.
#
# Where each colour zone sits on a ship is the build sheet's decision (the kit's materials hgrey, hgrey2, hpanel, htrim, hmetal
# and the shared dark; glow zones hblue, hlens, hnozzle, hlining, hwin: tools/blender/kits/hegemony/parts.py MATS); this file
# says what each is made of.
import os, sys, json, math
from functools import partial
import numpy as np
import bpy

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.normpath(os.path.join(HERE, '..', '..', '..', '..'))
SHARED = os.path.normpath(os.path.join(HERE, '..', 'shared'))
if SHARED not in sys.path: sys.path.insert(0, SHARED)
from paint_colors import LIGHT_GAIN, battle_lift, lin, lin_raw
FACTION = 'hegemony'


battle_lift = partial(battle_lift, FACTION)
LIFT = battle_lift()

# ------------------------------------------------------------------------------------------------------------ concept colours
# hegemony.md section 2: sampled from H10 (contrib/muse/design/concept_round7_2026_11/hegemony_H10_sheet.jpg) by the chair,
# k-means, 9 clusters, background excluded by corner colour; sample_concept() below repeats the method on the H10 beauty.
# (dark, light) sRGB show-tones: the tone the plate must SHOW in the game at the battle camera, face-on to the key light.
CONCEPT = dict(
    hull=((20, 28, 42), (72, 80, 94)),          # body modules, #141c2a / #48505e
    hull_shade=((11, 16, 28), (33, 43, 59)),    # recessed fields, #0b101c / #212b3b
    trim=((43, 57, 77), (98, 109, 125)),        # steel-blue strips at module edges and the rails, #2b394d / #626d7d
    nozzle=((33, 43, 59), (72, 80, 94)),        # rectangular nozzle housings, #212b3b / #48505e
    liner=((10, 14, 22), (21, 29, 43)),         # interior liner, dark with a faint cold tint
    # the builder's one plate-family step inside the hull band (R237: separation by value steps between plate families, never by
    # noise; plate_var .07, the lowest variation of any faction): a slightly darker cast of the same steel-blue grey
    hull_step=((18, 25, 38), (64, 72, 86)),
)
# hegemony.md 2, the value cap: no plate is ever brighter than #626d7d (the trim pair's light end). #888f9f is a light catch and
# a wear tone, never a plate tone; the wear and scuff layers mix toward the cap itself, so wear never lifts a plate past it.
CAP = (98, 109, 125)
# The implant blue of H10 (hegemony.md 2): the blue filter mean and hot decile, plate side. The light itself is the game's colour
# (faction_looks.json), read below; these two only colour the stencil read and the audit's blue test.
IMPLANT = ((87, 182, 229), (189, 241, 253))


# AgX and the warm key take colour out of dark tones (the Eclipse stack's finding): the first H10 sandbox bake read a grey with
# little blue in it (battle median blue over red 1.26 against the H10 concept's 1.46). So the albedo carries the steel-blue a
# little stronger than the tone it must show: its distance from its own grey is scaled by SAT (luminance kept). The value cap
# audit measures the result against #626d7d. SAT was 1.5 on the sampled tones (PR 796's first look, Board call 3); with the R262
# step below the plates are brighter and AgX greys them less, so at 1.5 the battle hue drifted bluer (blue over red 1.56 against
# 1.47 before the step and the concept's 1.46); at 1.3 it holds (1.50 on the 1024 check, PLATE_STEP .45)
SAT = 1.3


lin = partial(lin, lift=LIFT, saturation=SAT)


# R262 (Ryan, Nov 15 2026, "Fix engines, lighten a step"): the hull one step lighter for battle, the way S8 took its step (R258,
# PR 787). CONCEPT keeps the sampled tones; the step applies where the plate tones are painted. Each plate tone's brightest
# channel x (linear) goes to cap x (x / cap) ** PLATE_STEP, where cap is the #626d7d cap's brightest channel, and the other
# channels scale with it, so the hue holds, the family order holds, and nothing passes the cap (a tone at the cap stays there).
# The wear and scuff tone is the cap itself already (BARE), so it cannot rise with them: the worn edges stay the lightest tone.
# Glow colours, LIGHT_GAIN and the look.gd lift are unchanged. PLATE_STEP 1.0 is the sampled tones (PR 796's first look).
PLATE_STEP = .45
STEPPED = ('hull', 'hull_step', 'hull_shade', 'trim', 'nozzle')


def stepped(srgb):
    """a sampled plate tone (sRGB 0..255) one step toward the cap (R262), as sRGB 0..255 floats"""
    c = np.asarray(lin_raw(srgb)); m = float(c.max()); cm = max(lin_raw(CAP))
    if m <= 0 or m >= cm: return tuple(float(v) for v in srgb)
    c = c * (cm * (m / cm) ** PLATE_STEP / m)
    return tuple(float(v) for v in np.where(c <= .0031308, c * 12.92, 1.055 * np.clip(c, 0, 1) ** (1 / 2.4) - .055) * 255)


def pair(k):
    lo, hi = CONCEPT[k]
    if k in STEPPED: lo, hi = stepped(lo), stepped(hi)
    return lin(lo), lin(hi)


# the value cap as an albedo (no hue boost: the cap is the tone itself): every slice, the wear and the scuffs are held under it
CAP_LIN = tuple(c / (LIGHT_GAIN * LIFT) for c in lin_raw(CAP))


def slice_(k, at, var):
    """a narrow slice of a pair (the lowest variation of any faction): the tone at `at` of the pair's (dark, light) range, plus
    and minus var/2 of it, as (lo, hi) albedos. Every Hegemony zone and plate family is one of these, so no zone blotches"""
    lo, hi = pair(k); mid = [a + (b - a) * at for a, b in zip(lo, hi)]
    return tuple(min(m * (1 - var / 2), c) for m, c in zip(mid, CAP_LIN)), tuple(min(m * (1 + var / 2), c) for m, c in zip(mid, CAP_LIN))


# ------------------------------------------------------------------------------------------------------------ the layers
SCALE = 1.0          # every size below is in ship lengths (the recipe's frame: the ship is 1.0 long)
# where in each pair's (dark, light) range a plate sits: at its light end. R256 (Sunward read darker than its concept at the
# battle camera, Ryan asked a step lighter): the first H10 bake at .66 read 42,46,53 at the battle camera against the concept's
# 59,69,86; the light end is the sampled tone a face shows face-on to the key, and the #626d7d cap stays above it (no deliberate
# lightening past the sample, Ryan's swatch ruling)
TONE_AT = 1.0
LAYERS = dict(
    ao_short=.004, ao_long=.025, edge_radius=.0020, edge_gain=26.0,
    side_dark=.08, grain_scale=260.0, mottle_scale=40.0, grain=.38,
    rough=.34, metal=.48, wear=.45, grime=.30, ao_dark=.88, red_tone=0.0,
    parts_ao_dark=.76, recess_streaks=1.5,
    rough_floor=.25, bare_roughness=.19, rough_grain=.12, coat_roughness=.20,
    cavity_roughness=.22, scuff_roughness=.30, mottle_range=.07, plate_tone_range=.08,
    # hegemony.md 1: the two module sizes (patch_big on the body, patch_small on the small hull plates),
    # identical on every ship in ship lengths; over-plates (patch_over, a share of .05 of their cells) at the module joints only
    patch_big=(.070, .048, .038), patch_small=(.032, .021, .018), patch_over=(.085, .055, .045), patch_over_share=.05,
    patch_region=3.0, patch_seam=.0016, seam_dark=.94,
    # R243 (Ryan, Nov 13 2026: "Hegemony also pretty rigid and clean"; a hull's order follows its faction's lore): the EVEN GRID
    # IS THE DIRECTION. The Hegemony is the Registry's fleet, identical by doctrine, so its panels are flush rectangles on a
    # straight grid with no variation a sister ship would not share. patch_warp, patch_band and patch_split are 0 and stay 0: the
    # uneven warped grid is the Hullbreakers' opt-in only (R240, PR 682). Never "fix" this order into warp. The Hegemony panels
    # are drawn by panel_nodes below (the shared patchwork hands them over before it reads any of these three), so the shared
    # _grid never sees these zeros.
    patch_warp=0, patch_band=0, patch_split=0,
    # hegemony.md 1, the module band: where hull sections butt and the rails meet the hull, a double-width seam (about three times
    # patch_seam), a deeper seam_dark .96 and an AO-driven recess. As built (panel_nodes): the joint between the band's two trim
    # rings (the sheet's *_bandseam_*, 0.08 world wide: .0038 ship lengths on H10, .0026 on IM5) is seam all across, and a
    # one-sided seam band_seam / 2 = 1.5 patch_seam wide runs where each ring meets the plating (a full-width seam there covered
    # the whole 0.10 world ring on the second sandbox bake)
    band_seam=3.0, band_dark=.96, band_ao=.35, band_grime=.40,
    cavity_pow=1.6, wear_lo=.26, wear_hi=.52,
    scuff=.24, scuff_size=.050,                                           # hegemony.md 1: machining and handling marks
    colour_grain=.15, colour_grain_scale=180.0,                           # issue 1413: fine paint tone, kept modest (Board)
    parts_patchwork=1.0, parts_grid='small', panel_seam=1.0, seam_roughness=.35,         # issue 1413 round 4: big flat fittings carry the small plate grid
    rivets=0, rivet_pitch=.016, rivet_band=(.0012, .0040),               # hegemony.md 1: flush fasteners, no rivet lines
    trim_size=dict(), trim_aspect=dict(),
    streak_scale=4.0, streak_stretch=60.0, rust_blot=26.0,                # never rust (every zone's rust is 0)
    grime_z=(-.12, -.04), soot_x=(-.50, -.38), soot_aft=.24,              # soot toward the nozzle faces only
    wear_scale=50.0, wear_patch=3.0, bump_distance=.0010, bump_strength=.55, panel_relief=.75,
)
# hegemony.md 3 and 4: the paint stays cool and free of rust. Machinery
# housings and recesses are rougher than the plate and worked trim. Exposed
# edge metal takes a smoother finish through the shared convex wear mask.
# grid: the panel grid the zone carries on the hull ('big', 'small' or None: band treatment only, no grid seams of its own).
# grid_seam: the strength of the painted grid on unplated shell faces. The
# module_panels slabs carry their own gaps and the bands keep their own joints.
LEGACY_FINISH_ZONE = 'hgrey'  # Existing A4 atlas supplies its own paint colours and seams.
LEGACY_ALBEDO_BLEND = .45     # A4 already has painted shadows. Keep the second pass light enough for adjacent fittings.
_Z = dict(
    hgrey=dict(rust=0, grime=.32, patchwork=1.0, rough=.30, metal=.48, wear=1.05, grid='big', grid_seam=1.0),   # issue 1413 round 3: .35 to .70, the plating seams read (Ryan, Nov 21: no clay)
    hpanel=dict(rust=0, grime=.32, patchwork=1.0, rough=.48, metal=.48, wear=1.05, grid='small', grid_seam=1.0),
    hgrey2=dict(rust=0, grime=.52, patchwork=1.0, rough=.54, metal=.30, wear=.30, grid='small', grid_seam=.60),
    htrim=dict(rust=0, grime=.22, patchwork=1.0, rough=.25, metal=.62, wear=1.32, grid=None, handling_wear=.45),
    hmetal=dict(rust=0, grime=.20, patchwork=0, rough=.20, metal=.72, wear=1.23, handling_wear=.65),
    dark=dict(rust=0, grime=.20, patchwork=0, rough=.80, metal=.20, wear=.10, scuff=.03),
)
_BASE = dict(hgrey='hull', hpanel='hull', hgrey2='hull_shade', htrim='trim', hmetal='trim', dark='hull_shade')
_AT = dict(hgrey=TONE_AT, hpanel=TONE_AT, hgrey2=TONE_AT, htrim=TONE_AT, hmetal=.80, dark=.15)
ZONES = dict(_Z)
# the nozzle housings (hegemony.md 2 nozzle pair, 3 metal .48 and grime .30): every plate of an engine or a thruster takes the
# nozzle zone (ZONE_BY_KIND, read by the shared bake), so the stern's housings read as one machined family
ZONE_BY_KIND = {}
for _kind in ('engine', 'thruster'):
    for _zn in ('hgrey', 'hgrey2', 'hpanel', 'htrim', 'hmetal'):
        _nz = f'nozzle_{_zn}'
        _recess = _zn == 'hgrey2'
        ZONES[_nz] = dict(rust=0, grime=.52 if _recess else .32, patchwork=0,
                          rough=.56 if _recess else .32, metal=.34 if _recess else .60,
                          wear=.32 if _recess else 1.10, handling_wear=0 if _recess else .38)
        _BASE[_nz] = 'nozzle'; _AT[_nz] = .45 if _zn == 'hgrey2' else TONE_AT
        ZONE_BY_KIND[(_kind, _zn)] = _nz
for _k, _z in ZONES.items():
    _z['lo'], _z['hi'] = slice_(_BASE[_k], _AT[_k], .07)
FALLBACK = 'hgrey'
MODULE_TONES = dict(body=1.0, steel=.95, machinery=.97)
HULL_FAMILIES = ('body', 'steel')
PART_FAMILIES = dict(engine='machinery', thruster='machinery', gun='machinery', spinal='machinery')
SURFACE_DUTIES = dict(hgrey='panel', hpanel='panel', hgrey2='recess', htrim='band', hmetal='edge', dark='recess')
for _nozzle_zone in ZONE_BY_KIND.values():
    SURFACE_DUTIES[_nozzle_zone] = 'recess' if _nozzle_zone.endswith('_hgrey2') else 'machinery'
# Exposed housings, mounts and bands are all casts of the same steel blue.
# Recesses and machinery carry the darker steps of the same blue-grey family.
_STEEL = pair('hull')[1]
PART_DUTY_TONES = {
    duty: tuple(min(channel * step, cap) for channel, cap in zip(_STEEL, CAP_LIN))
    for duty, step in dict(panel=1.0, band=1.14, edge=1.16, machinery=.90, recess=.66).items()
}
BARE = CAP_LIN                                 # the wear tone: dulled pale edges at the value cap, never past it
GRIME = lin(CONCEPT['hull_shade'][0])          # grime and the nozzles' light soot: the deep shadow tone
RUST = RUST_DARK = GRIME                       # read by the shared rust layer only where a zone has rust, and no Hegemony zone has


def _zone_of(nt):
    """the zone of the material this node tree belongs to (the shared stack names it ps_<zone>_<group>)"""
    for m in bpy.data.materials:
        if m.node_tree is not None and m.node_tree == nt:
            return m.name[3:].rsplit('_', 1)[0] if m.name.startswith('ps_') else m.name
    return ''


def authored_panel_mesh(obj):
    """The sheet builder's module_panels slabs are disconnected mesh islands."""
    return '_panels_' in obj.name


_BANDS = None


def module_bands():
    """the module bands of the ship in the scene (hegemony.md 1: the joints where the ship genuinely comes apart), read from the
    sheet's own band geometry: each hull object named *_bandseam_* is one joint, and the *_band_* trim rings beside it widen it to
    the whole band. Returns [(x0, x1, y0, y1, z0, z1, xs0, xs1)] in ship lengths: the band's box and its seam's x range. A
    Hegemony sheet with no band is a fault of the sheet (the direction puts a band at every module joint), so it stops here"""
    global _BANDS
    if _BANDS is not None: return _BANDS
    from mathutils import Vector

    def box(o):
        P = [o.matrix_world @ Vector(b) for b in o.bound_box]
        return [min(p.x for p in P), max(p.x for p in P), min(p.y for p in P), max(p.y for p in P), min(p.z for p in P), max(p.z for p in P)]
    hull = [o for o in bpy.data.objects if o.type == 'MESH' and o.get('role') == 'hull']
    seams = [box(o) for o in hull if '_bandseam_' in o.name]
    rings = [box(o) for o in hull if '_band_' in o.name]
    if not seams:
        raise SystemExit('hegemony stack: no module band (*_bandseam_*) on this sheet; hegemony.md 1 puts one at every module joint')
    out = []
    for s in seams:
        xc = (s[0] + s[1]) / 2; b = list(s)
        for r in rings:
            near = abs((r[0] + r[1]) / 2 - xc) < .012
            over = r[2] < s[3] and r[3] > s[2] and r[4] < s[5] and r[5] > s[4]
            if near and over: b = [min(b[0], r[0]), max(b[1], r[1]), min(b[2], r[2]), max(b[3], r[3]), min(b[4], r[4]), max(b[5], r[5])]
        out.append(tuple(b) + (s[0], s[1]))
    _BANDS = out
    return out


def paint_joints():
    global _BANDS
    _BANDS = None
    return [(band[6] + band[7]) / 2 for band in module_bands()]


def panel_nodes(c, col, amount, families=None, cells=None):
    """hegemony.md 1 and R243: the even grid. Flush rectangles on one straight grid anchored to the ship (x along the hull, the
    beam measured out from the centreline so port and starboard are mirror images, z up), no stagger, no warp, no split: the same
    module on every sister ship. Two module sizes: patch_big on the body modules (zone hgrey), patch_small on the small module
    plates and recessed fields (hpanel, hgrey2). The module bands (module_bands()) carry the joint: the band's own
    seam dark all across and a one-sided seam where each ring meets the plating, darker (band_dark), an AO-driven recess and a little more grime; over-plates
    (patch_over, share .05) sit only beside the bands. Returns the colour and the seam mask (the shared stack darkens the seams by
    seam_dark and bakes their relief into the hull normal)."""
    from paint_stack import node, math_, mixc, mulc, ramp
    nt = c.nt; L = LAYERS
    zone = _zone_of(nt); z = ZONES.get(zone, ZONES[FALLBACK])
    nx = node(nt, 'ShaderNodeSeparateXYZ'); nt.links.new(c.geo.outputs['Normal'], nx.inputs[0])
    nrm = [math_(nt, 'ABSOLUTE', nx.outputs[k]) for k in range(3)]
    ay = math_(nt, 'ABSOLUTE', c.y)          # the beam from the centreline: the grid mirrors port to starboard

    def line(d, width):
        """a seam of the given width at distance d (ship lengths) from its line"""
        return math_(nt, 'SUBTRACT', 1, ramp(nt, d, width * .4, width))

    def on_face(k):
        """a line measured along axis k shows only on faces whose normal is not along k (never a seam across a face's depth)"""
        return ramp(nt, math_(nt, 'SUBTRACT', 1, nrm[k]), .35, .65)

    def grid(size, seed):
        """the plain even grid: cell id vector and seam mask"""
        q = [math_(nt, 'DIVIDE', v, s) for v, s in zip((c.x, ay, c.z), size)]
        cid = node(nt, 'ShaderNodeCombineXYZ')
        for k in range(3): nt.links.new(math_(nt, 'ADD', math_(nt, 'FLOOR', q[k]), seed * (k + 1)), cid.inputs[k])
        seam = None
        for k in range(3):
            f = math_(nt, 'FRACT', q[k]); d = math_(nt, 'MULTIPLY', math_(nt, 'MINIMUM', f, math_(nt, 'SUBTRACT', 1, f)), size[k])
            e = math_(nt, 'MULTIPLY', line(d, L['patch_seam']), on_face(k))
            seam = e if seam is None else math_(nt, 'MAXIMUM', seam, e)
        return cid.outputs[0], seam

    kind = z.get('grid', 'small')
    if kind is not None and any(m.node_tree == nt and m.name.endswith('_P') for m in bpy.data.materials):
        kind = L.get('parts_grid', kind)   # issue 1413 round 4: fittings are small, so their plates are the small module
    seam = None
    panels = node(nt, 'ShaderNodeAttribute', attribute_type='GEOMETRY', attribute_name='ps_authored_panels').outputs['Fac']
    unplated = math_(nt, 'SUBTRACT', 1, panels)
    if kind is not None:
        size = L['patch_big'] if kind == 'big' else L['patch_small']
        _, gseam = grid(size, 11.0 if kind == 'big' else 37.0)
        # issue 1413 round 4 (Ryan, Nov 21: "so they don't look like clay"): the authored panel slabs carry the same straight
        # grid's seams (panel_seam of the plating's strength), so a slab bigger than one module reads as plates (R243's order)
        cover = math_(nt, 'ADD', unplated, math_(nt, 'MULTIPLY', panels, L.get('panel_seam', 0.0)))
        seam = math_(nt, 'MULTIPLY', gseam, math_(nt, 'MULTIPLY', cover, z.get('grid_seam', 1.0)))
        island = c.geo.outputs['Random Per Island']
        shade = math_(nt, 'MULTIPLY', math_(nt, 'SUBTRACT', 1, island), L['plate_tone_range'])
        col = mulc(nt, col, math_(nt, 'SUBTRACT', 1, math_(nt, 'MULTIPLY', shade, panels)))
    # the module bands: the box of each band (a little wider, so the joint reaches the plating on both sides of the rings), the
    # seams at its edges and at its own seam, and a wider neighbourhood where the over-plates may sit
    pad, near = .003, .022
    B = W = bseam = None
    for (x0, x1, y0, y1, z0, z1, xs0, xs1) in module_bands():
        def inside(e, ey=None):
            ey = e if ey is None else ey; m = None
            for v, a, b_, ee in ((c.x, x0, x1, e), (c.y, y0, y1, ey), (c.z, z0, z1, ey)):
                t = math_(nt, 'MULTIPLY', math_(nt, 'GREATER_THAN', v, a - ee), math_(nt, 'LESS_THAN', v, b_ + ee))
                m = t if m is None else math_(nt, 'MULTIPLY', m, t)
            return m
        bi = inside(pad, .004); wi = inside(near, .004)
        B = bi if B is None else math_(nt, 'MAXIMUM', B, bi)
        W = wi if W is None else math_(nt, 'MAXIMUM', W, wi)
        # the joint itself (the band's own seam, between its two trim rings) is seam all across, and where the rings meet the
        # plating a seam band_seam / 2 patch_seam wide runs on the plating side only, so the rings stay clean machined trim
        hw = L['patch_seam'] * L['band_seam'] / 2
        e = math_(nt, 'MULTIPLY', math_(nt, 'GREATER_THAN', c.x, xs0), math_(nt, 'LESS_THAN', c.x, xs1))
        for xe, sgn in ((x0, -1.0), (x1, 1.0)):
            d = math_(nt, 'MULTIPLY', math_(nt, 'SUBTRACT', c.x, xe), sgn)          # the distance out onto the plating
            out_ = math_(nt, 'MULTIPLY', line(d, hw), math_(nt, 'GREATER_THAN', d, -1e-5))
            e = math_(nt, 'MAXIMUM', e, math_(nt, 'MULTIPLY', out_, on_face(0)))
        e = math_(nt, 'MULTIPLY', e, inside(hw * 2, .004))
        bseam = e if bseam is None else math_(nt, 'MAXIMUM', bseam, e)
    # over-plates at the joints only (plate zones), on their own grid, with their own seam
    if kind is not None and zone in ('hgrey', 'hpanel'):
        oid, oseam = grid(L['patch_over'], 71.0)
        ow = node(nt, 'ShaderNodeTexWhiteNoise', noise_dimensions='3D'); nt.links.new(oid, ow.inputs['Vector'])
        on = math_(nt, 'MULTIPLY', math_(nt, 'LESS_THAN', ow.outputs['Value'], L['patch_over_share']), math_(nt, 'MULTIPLY', W, math_(nt, 'SUBTRACT', 1, B)))
        on = math_(nt, 'MULTIPLY', on, unplated)
        seam = math_(nt, 'MAXIMUM', math_(nt, 'MULTIPLY', seam, math_(nt, 'SUBTRACT', 1, on)), math_(nt, 'MULTIPLY', oseam, on))
    # inside a band: the grid's own seams give way to the band's (the band is one machined ring), the recess darkens with the
    # short occlusion, a little more grime gathers in it, and the band seam reaches band_dark (the shared stack darkens every seam
    # by seam_dark; the extra third here takes .94 to .96 where the band seam is full)
    if seam is not None:
        seam = math_(nt, 'MULTIPLY', seam, math_(nt, 'SUBTRACT', 1, B))
    seam = bseam if seam is None else math_(nt, 'MAXIMUM', seam, bseam)
    k = 1 - (1 - L['band_dark']) / (1 - L['seam_dark'])
    col = mixc(nt, col, (0, 0, 0), math_(nt, 'MULTIPLY', bseam, k))
    col = mixc(nt, col, (0, 0, 0), math_(nt, 'MULTIPLY', math_(nt, 'MULTIPLY', B, math_(nt, 'SUBTRACT', 1, c.ao)), L['band_ao']))
    g = math_(nt, 'MULTIPLY', math_(nt, 'MULTIPLY', B, math_(nt, 'SUBTRACT', 1, c.aol)), 1.4, clamp=True)
    col = mixc(nt, col, GRIME, math_(nt, 'MULTIPLY', g, max(0.0, L['band_grime'] - z.get('grime', L['grime'])) * .8))
    return col, math_(nt, 'MULTIPLY', seam, amount, clamp=True)


# ------------------------------------------------------------------------------------------------------------ the light
# hegemony.md 5. Nothing on the intact ship crosses the game's 0.8 glow threshold (godot/render/look.gd): the values below are the
# brightest linear channel of each light's emission colour times its strength, read as absolute values against 0.8, the way
# the Hullbreaker lamps are written (0.77). Colours are the game's (godot/fx/faction_looks.json hegemony engine and weapon);
# never warm light on the intact ship (no Hegemony emissive has red over blue: the stack checks it, emissive_audit()). The white-
# gold damage glow is the game's, inside damage only, and never here.
THRESHOLD = 0.8
STRIP_PEAK = .74       # the blue line's implant strips at rest (hegemony.md 5: about 0.74; the game pulses them to about 0.79)
NOZZLE_PEAK = .76      # the flat row of nozzle faces (hegemony.md 5: about 0.76)
LENS_PEAK = .65        # the sensor fin's tip lens (hegemony.md 5: about 0.65), and every weapon lens and bore with it
WINDOW_PEAK = .60      # the blue-white window slits (the builder's call: under the strips, never a second line)
LINING_PEAK = .50      # a retro thruster's inner walls (the builder's call: dim, so the dark lip reads)
# The nozzle throats and linings of the engines share one emission map (shared/paint_stack.bake_engine_glow: the shared throat
# drawing in the game's Hegemony engine colour, its top held to NOZZLE_PEAK). The ion emitter and blue strips share that map.
GLOW = ('hblue', 'hlens', 'hnozzle', 'hlining', 'hwin')
# The blue line's strips that the sheet puts on the hull itself are hull trim, not parts (issue 642, the Eclipse corona line):
# their own material, marked hull_surface, so the export check measures breach clearance from the parts and not from them.
GLOW_HULL = ('hblue',)


def faction_look():
    p = os.path.join(REPO, 'godot', 'fx', 'faction_looks.json')
    d = json.load(open(p, encoding='utf-8'))
    return d.get(FACTION) or d.get('factions', {}).get(FACTION)


def _peak(col, peak):
    """a light colour scaled so its brightest channel is peak"""
    m = max(col) or 1.0; return tuple(float(c) * peak / m for c in col)


def engine_rgb():
    """the blue line and the nozzles: the game's Hegemony engine colour (0.45, 0.72, 1.0 today), read, never copied. The strips take
    it rather than the paler weapon colour: under the game's tone map the weapon colour read white on the first sandbox bake"""
    return tuple(float(c) for c in faction_look()['engine'])


def weapon_rgb():
    """the implant blue of the strips and lenses: the game's Hegemony weapon colour (0.55, 0.82, 1.0 today), read, never copied"""
    return tuple(float(c) for c in faction_look()['weapon'])


def window_rgb():
    """blue-white: the weapon colour taken a little toward white"""
    return tuple(c + (1.0 - c) * .45 for c in weapon_rgb())


GLOW_FLAT = dict(       # the flat lights (no map): name, colour, peak
    hblue=('p3_hblue', lambda: _peak(engine_rgb(), STRIP_PEAK)),
    hlens=('p3_hlens', lambda: _peak(weapon_rgb(), LENS_PEAK)),
    hwin=('p3_hwin', lambda: _peak(window_rgb(), WINDOW_PEAK)),
    hlining=('p3_hlining', lambda: _peak(engine_rgb(), LINING_PEAK)),
    hnozzle=('p3_hnozzle', lambda: _peak(engine_rgb(), NOZZLE_PEAK)),
)


def glow_material(zone, hull=False):
    """a flat light (no map): the blue line's strips (hblue), lenses and bores (hlens), window slits (hwin), a retro thruster's
    walls and throat (hlining, hnozzle). Never named p3_glow (export7 names the first p3_glow material the ship's glow surface:
    the map's). A strip on the hull itself is hull trim: its own material, marked hull_surface (GLOW_HULL)"""
    name, f = GLOW_FLAT.get(zone, ('p3_' + zone, lambda: _peak(weapon_rgb(), LENS_PEAK)))
    m = bpy.data.materials.new(name + ('_hull' if hull else '')); m.use_nodes = True
    b = m.node_tree.nodes['Principled BSDF']; col = f()
    b.inputs['Base Color'].default_value = (col[0] * .04, col[1] * .04, col[2] * .04, 1); b.inputs['Roughness'].default_value = .6
    b.inputs['Emission Color'].default_value = (*col, 1); b.inputs['Emission Strength'].default_value = 1.0
    m['ps_glow'] = 1; m['rim_soft'] = 1; m['ps_peak'] = max(col)
    if hull: m['hull_surface'] = 1
    return m


def _ramp_to(col, peak, stops):
    """a throat ramp in the game's engine colour, its top at peak: (position, fraction of the top). The dim end falls off red
    first and blue last, so a cooling throat goes deeper blue, never warm (hegemony.md 5)"""
    top = _peak(col, peak)
    return [(p, tuple(c * k ** g for c, g in zip(top, (2.4, 1.6, 1.0)))) for p, k in stops]


# the nozzle throat (factions.md: a flat row of rectangular blue-white nozzles): the shared throat drawing (shared/paint_stack.
# _throat_glow: a hot core on the axis, the lining dark toward the lip) in the game's Hegemony engine colour, its top held to
# NOZZLE_PEAK. Identical by doctrine: no hue shift and almost no brightness spread between the nozzles, faint hot spots, light soot.
# The lining glows almost evenly from the throat to the lip (lining_falloff .5, lining_gain .85), the throat plate at the top: the
# pod's trim bands are open rings since R262 (kits/hegemony/parts.py engine_bell), so the camera sees the throat, the vanes and
# the lit lining round them, the whole nozzle face blue (PR 796's first bake saw only the lining, behind solid bands)
ENGINE_GLOW = dict(kind='engine', zones=('hnozzle', 'hlining'), disc=('hnozzle',), plug=(), extra_zones=('hblue', 'hlining'), res_frac=.5,
                   core_reach=(.55, .65), lining_gain=.85, lining_falloff=.5, hotspot_scale=700.0, hotspot=(.60, .72),
                   hotspot_gain=.08, streaks=14.0, soot=(.55, .70), soot_gain=.15, bright=(.97, 1.0), hue_shift=0.0, strength=4.0,
                   base=(.006, .010, .020),
                   ramp=_ramp_to(engine_rgb(), NOZZLE_PEAK, [(0.0, .02), (.25, .30), (.50, .62), (.75, .86), (1.0, 1.0)]))


def glow_vertex(o):
    """Issue 930: lens coordinates and light identity, preserved through the shared map's bake copy. No new geometry."""
    from paint_stack import glow_zone
    zone = glow_zone(o)
    ion = o.get('grp') == 'I1' and o.get('part_kind') == 'spinal'
    kind = (1 if zone == 'hblue' else 2) if ion else (3 if zone == 'hblue' else 4)
    me = o.data
    at = me.attributes.get('ps_kind') or me.attributes.new('ps_kind', 'FLOAT', 'POINT')
    at.data.foreach_set('value', np.full(len(me.vertices), kind, np.float32))
    ca = me.color_attributes.get('ps_ion') or me.color_attributes.new('ps_ion', 'FLOAT_COLOR', 'POINT')
    coords = np.array([tuple(o.matrix_world @ v.co) for v in me.vertices])
    lo, hi = coords.min(0), coords.max(0)
    coords = (coords - lo) / np.maximum(hi - lo, 1e-6)
    for i, xyz in enumerate(coords): ca.data[i].color = (*xyz, 1)


def engine_glow_nodes(nt, r, e, d, a, tc, H):
    """One exportable map: original engine/strip light, graded ion lens and dimmer blue field contacts (R304)."""
    from paint_stack import _throat_glow
    node, math_, ramp, mixc, mulc = (H[k] for k in ('node', 'math_', 'ramp', 'mixc', 'mulc'))
    original = _throat_glow(nt, ENGINE_GLOW, r, e, d, a, tc, H['noise'])
    attr = node(nt, 'ShaderNodeAttribute'); attr.attribute_name = 'ps_ion'
    sep = node(nt, 'ShaderNodeSeparateXYZ'); nt.links.new(attr.outputs['Color'], sep.inputs[0])
    # The recessed front and open-roof top both show a core grading out toward their own edges.
    xyz = [math_(nt, 'SUBTRACT', math_(nt, 'MULTIPLY', v, 2), 1) for v in sep.outputs]
    normal = node(nt, 'ShaderNodeNewGeometry')
    ns = node(nt, 'ShaderNodeSeparateXYZ'); nt.links.new(normal.outputs['Normal'], ns.inputs[0])
    along = math_(nt, 'GREATER_THAN', math_(nt, 'ABSOLUTE', ns.outputs[0]), .5)
    u = xyz[1]
    v = math_(nt, 'ADD', math_(nt, 'MULTIPLY', xyz[2], along),
              math_(nt, 'MULTIPLY', xyz[0], math_(nt, 'SUBTRACT', 1, along)))
    radius = math_(nt, 'SQRT', math_(nt, 'ADD', math_(nt, 'MULTIPLY', u, u), math_(nt, 'MULTIPLY', v, v)))
    heat = math_(nt, 'SUBTRACT', 1, ramp(nt, radius, .08, 1.1))
    # Dark frame lines split the optic into segments. Metal coils and the worn muzzle keep the normal parts atlas.
    lines = math_(nt, 'MULTIPLY', ramp(nt, math_(nt, 'ABSOLUTE', u), .016, .035),
                  ramp(nt, math_(nt, 'ABSOLUTE', v), .016, .035))
    lens = mixc(nt, (.0005, .008, .12), (.008, .30, 1.0), heat)
    lens = mulc(nt, lens, math_(nt, 'ADD', .025, math_(nt, 'MULTIPLY', lines, .975)))
    field = mixc(nt, (.001, .014, .20), (.002, .07, .375), H['noise'](attr.outputs['Color'], 5, 2))
    col = mulc(nt, original, 1 / ENGINE_GLOW['strength'])
    for kind, value in ((1, lens), (2, field),
                        (3, tuple(c / 4 for c in GLOW_FLAT['hblue'][1]())),
                        (4, tuple(c / 4 for c in GLOW_FLAT['hlining'][1]()))):
        col = mixc(nt, col, value, math_(nt, 'COMPARE', H['kind'], kind))
    return col


def emissive_audit(job_dir, cell):
    """No warm light. The shared map includes PR 911's ion lens (peak 4), the explicit R304 exception to resting trim."""
    from PIL import Image
    out = dict(threshold=THRESHOLD, lights={})
    p = os.path.join(job_dir, f'{cell}_engine_emission.png')
    if os.path.exists(p):
        a = np.asarray(Image.open(p).convert('RGB')).astype(np.float64) / 255.0
        a = np.where(a <= .04045, a / 12.92, ((a + .055) / 1.055) ** 2.4) * ENGINE_GLOW['strength']
        lit = a.max(2) > .02
        out['lights']['map'] = dict(max=round(float(a.max()), 4), limit=ENGINE_GLOW['strength'],
                                   warm_px=int(((a[..., 0] > a[..., 2] + 1e-3) & lit).sum()))
    for z, (name, f) in GLOW_FLAT.items():
        c = f(); out['lights'][name] = dict(max=round(max(c), 4), warm=bool(c[0] > c[2] + 1e-6))
    out['pass'] = all(v['max'] <= v['limit'] if 'limit' in v else v['max'] < THRESHOLD for v in out['lights'].values()) and \
        not any(v.get('warm') or v.get('warm_px') for v in out['lights'].values())
    return out


# ------------------------------------------------------------------------------------------------------------ insides
# An inside seen from outside reads as the dark inner liner (R99 Q1): hegemony.md's liner, dark with a faint cold tint, a faint
# tint per room so a broken ship's spaces are not all one; the core and the blue emergency strips keep their light, in blue.
INSIDE_BASE = lin(CONCEPT['liner'][1])
INSIDE_TINT = .18
# Interior Kit V2 (issue 1743, R416 Layer 3) under R420 (Ryan, Nov 22; contrib/opus/plans/global_cohesion_standard.md 3):
# cool brushed clinical steel-slate, cleaner, cooler and a little lighter than Sunward and the Hullbreakers, never chalk-white
# clay (the 0.175 matte corridors are retired); crisp cold-blue emergency strips carry the sterile look (factions.md,
# Directorate: racks of identical equipment, blue emergency light; never rust, never warm light). Each zone takes its role's
# colour here, inside the shared budgets of tools/blender/kits/shared/interior_trim.py; the values match the 1741 breach
# interior (faction_looks.json wound).
FAC_KEY = 'hegemony'
INSIDE_ROLES = dict(wall=dict(rgb=(.08, .085, .095)), deck=dict(rgb=(.07, .075, .083)), frame=dict(rgb=(.065, .07, .078), light=False),
                    machinery=dict(rgb=(.085, .088, .096)), core=dict(rgb=(.07, .075, .083)))
_TRIMS = None


def inside_trims():
    global _TRIMS
    if _TRIMS is None:
        _TRIMS = dict(main=dict(style='panels', seed=1744, panel=8, split=0.0, var=0.10, grime=0.10, grille=0.25, conduit_rows=2, metal=0.45,
                    rough=(0.3, 0.5), relief=5.0, tones=((1.0, 1.0, 1.0), (0.93, 0.95, 0.98)),
                    strip=dict(rgb=tuple(min(1.0, c) for c in engine_rgb()), every=3, strength=2.2)))
    return _TRIMS


def CORE_LIGHT():
    return (tuple(engine_rgb()), 4.0)


def inside_material(room, trim=False):
    """trim: the insides carry the Interior Kit V2 UVs, so the zone takes its role's colour and trim from INSIDE_ROLES (R420; the
    kit's zone colour and light are never read, only the core keeps its light)"""
    if trim:
        import interior_trim
        return interior_trim.role_material(f'ps_inside_{room}', FAC_KEY, room, INSIDE_ROLES, inside_trims(), core=CORE_LIGHT())
    src = bpy.data.materials.get(room); m = bpy.data.materials.new(f'ps_inside_{room}'); m.use_nodes = True
    b = m.node_tree.nodes['Principled BSDF']; rgb = (1, 1, 1)
    if src is not None and src.use_nodes and src.node_tree.nodes.get('Principled BSDF'):
        sb = src.node_tree.nodes['Principled BSDF']; rgb = tuple(sb.inputs['Base Color'].default_value)[:3]
        em = sb.inputs['Emission Strength'].default_value
        if em > 0:      # the core and the emergency strips: their own light stays (the bright bite when the ship breaks), in blue
            b.inputs['Emission Color'].default_value = (*engine_rgb(), 1); b.inputs['Emission Strength'].default_value = em
    mx = max(rgb) or 1
    b.inputs['Base Color'].default_value = tuple(INSIDE_BASE[i] * (1 - INSIDE_TINT + INSIDE_TINT * rgb[i] / mx) for i in range(3)) + (1,)
    b.inputs['Roughness'].default_value = .9; b.inputs['Metallic'].default_value = .2
    m['ps_inside'] = 1
    return m


# ------------------------------------------------------------------------------------------------------------ running lights
# hegemony.md 5: the strips are the running lights; there are no separate navigation points. The stack adds no lamps of its own
# and writes no lights.json: the red lamps are a Hullbreaker rule (R228 item 4).
RUNNING_LIGHTS = None


# ------------------------------------------------------------------------------------------------------------ decals
# hegemony.md 4: the stencil marks, identical small marks at module corners (H10 carries "HD-14" as the picture's example),
# symmetric, low contrast: the hull number on each flank, corner ticks and module index bars at the module corners, a registry
# plate on the deck's centreline. Never ornament (no crest). Edge wear runs last, over the decals (the shared stack's order).
# Symmetry (hegemony.md 3, a build rule): every side decal is placed on port and starboard at the same station and height (the
# shared placement does both sides); every deck decal off the centreline is written as a plus and minus y pair. Placed by rule
# on each ship's own surfaces (shared/paint_stack.place_decals): x the station from the bow (0) to the stern (1), z the height
# band on the side, a top decal searches the deck at y. On a top decal the cell's up (its top row) points to the bow.
DECAL_CELLS = 2      # 2 x 2: 0 the hull number, 1 a module corner tick, 2 module index bars, 3 the registry plate
_CORNER_Y = (.050, .060, .070, .080, .040)
DECALS = [
    dict(name='hull number', cell=0, face='side', x=(.14, .18, .22, .26, .10), z=(.35, .80), w=.044, h=.012, alpha=.70, min_room=.6),
    dict(name='module index bars', cell=2, face='side', x=(.46, .50, .54, .42, .58), z=(.35, .80), w=.018, h=.007, alpha=.65,
         min_room=.6),
    dict(name='corner tick port', cell=1, face='top', x=(.24, .28, .32, .20), y=_CORNER_Y, w=.010, h=.010, alpha=.65,
         min_facing=.85, min_room=.6),
    dict(name='corner tick starboard', cell=1, face='top', x=(.24, .28, .32, .20), y=tuple(-v for v in _CORNER_Y), w=.010, h=.010,
         alpha=.65, min_facing=.85, min_room=.6),
    dict(name='registry plate', cell=3, face='top', x=(.36, .40, .32, .44, .28), y=(0.0,), w=.016, h=.026, alpha=.65,
         min_facing=.85, min_room=.6),
]


def ship_code():
    """the ship's sheet cell (H10, IM5), the hull number's text"""
    p = os.environ.get('R209_SHIP', '')
    d = json.load(open(p)) if p and os.path.exists(p) else {}
    return str(d.get('cell') or (d.get('game_code') or 'H00').split('_')[0])


def _srgb(lin_rgb):
    c = np.clip(np.asarray(lin_rgb, np.float64), 0, 1)
    return np.where(c <= .0031308, c * 12.92, 1.055 * c ** (1 / 2.4) - .055)


# a 3 x 5 stencil font for the hull number (own work): each glyph five rows of three cells, '#' painted
_FONT = {
    '0': ('###', '#.#', '#.#', '#.#', '###'), '1': ('.#.', '##.', '.#.', '.#.', '###'), '2': ('###', '..#', '###', '#..', '###'),
    '3': ('###', '..#', '.##', '..#', '###'), '4': ('#.#', '#.#', '###', '..#', '..#'), '5': ('###', '#..', '###', '..#', '###'),
    '6': ('###', '#..', '###', '#.#', '###'), '7': ('###', '..#', '..#', '.#.', '.#.'), '8': ('###', '#.#', '###', '#.#', '###'),
    '9': ('###', '#.#', '###', '..#', '###'), 'H': ('#.#', '#.#', '###', '#.#', '#.#'), 'I': ('###', '.#.', '.#.', '.#.', '###'),
    'M': ('#.#', '###', '###', '#.#', '#.#'), 'D': ('##.', '#.#', '#.#', '#.#', '##.'), '-': ('...', '...', '###', '...', '...'),
}


def decal_atlas(res=1024, code=None):
    """the decal atlas, RGBA in 0..1 (sRGB colour, the albedo it paints), row 0 at the top; drawn here (own work). Low-contrast
    stencils in the trim pair's light end (the value cap), crisp and machined, a little worn; identical on every ship but for the
    hull number"""
    code = (code or ship_code()).upper()
    c = res // 2; A = np.zeros((res, res, 4), np.float32)
    rng = np.random.default_rng(780)
    ink = _srgb(lin(CAP))
    y, x = np.mgrid[0:c, 0:c]; u = x / c; v = y / c

    def put(cell, mask, col):
        cx, cy = cell % 2, cell // 2; sl = (slice(cy * c, cy * c + c), slice(cx * c, cx * c + c))
        a = A[sl]; m = mask.astype(np.float32) * (0.88 + 0.12 * rng.random(mask.shape))
        a[..., :3] = np.where(m[..., None] > 0, col, a[..., :3]); a[..., 3] = np.maximum(a[..., 3], m)
    # 0 the hull number: the sheet cell in the stencil font, centred, with the stencil's breaks (a gap between cells)
    text = [ch for ch in code if ch in _FONT]
    g = np.zeros((c, c), bool)
    if text:
        gw = 4 * len(text) - 1; px = .86 / gw; ph = .62 / 5; x0 = .5 - gw * px / 2; y0 = .19
        for i, ch in enumerate(text):
            for r, row in enumerate(_FONT[ch]):
                for k, s in enumerate(row):
                    if s != '#': continue
                    ux = x0 + (4 * i + k) * px; vy = y0 + r * ph
                    g |= (u > ux + px * .08) & (u < ux + px * .92) & (v > vy + ph * .08) & (v < vy + ph * .92)
    put(0, g, ink)
    # 1 a module corner tick: an L at the corner and a small square inside it
    t = ((u > .14) & (u < .26) & (v > .14) & (v < .86)) | ((u > .14) & (u < .86) & (v > .74) & (v < .86))
    t |= (u > .40) & (u < .56) & (v > .44) & (v < .60)
    put(1, t, ink)
    # 2 module index bars: three short equal bars between two end ticks
    b = ((np.abs(u - .06) < .03) | (np.abs(u - .94) < .03)) & (np.abs(v - .5) < .34)
    for k in range(3): b |= (np.abs(u - (.28 + k * .22)) < .07) & (np.abs(v - .5) < .20)
    put(2, b, ink)
    # 3 the registry plate: a plain frame with two bars inside (the Registry's mark, plain, never a crest)
    fr = ((u > .14) & (u < .86) & (v > .08) & (v < .92)) & ~((u > .22) & (u < .78) & (v > .14) & (v < .86))
    fr |= (u > .30) & (u < .70) & (np.abs(v - .36) < .05)
    fr |= (u > .30) & (u < .70) & (np.abs(v - .60) < .05)
    put(3, fr, ink)
    # a well-kept fleet: only small wear in the marks (edge wear eats them further, on the ship)
    holes = np.kron(rng.random((res // 16, res // 16)) < .05, np.ones((16, 16))) > 0
    A[..., 3] *= np.where(holes, .55, 1.0)
    return A


# ------------------------------------------------------------------------------------------------------------ the trim sheet
def trim_sheet():
    """the faction's trim tiles, each RGBA in 0..1 (alpha is the tile's mask and height): drawn here (own work). Machining and
    handling marks: short straight strokes along the hull axis, few and light (hegemony.md 4: scuff .08); no rivets (flush)"""
    rng = np.random.default_rng(780)
    T = {}
    n = 512; m = np.zeros((n, n), np.float32)
    for _ in range(90):
        L = rng.uniform(10, 70); th = rng.normal(0, .04) + (math.pi / 2 if rng.random() < .25 else 0)
        x0, y0 = rng.uniform(0, n, 2); s = rng.uniform(.25, .7)
        for t in np.linspace(0, 1, int(L)):
            xi = int(x0 + math.cos(th) * L * t) % n; yi = int(y0 + math.sin(th) * L * t) % n
            m[yi, xi] = max(m[yi, xi], s)
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
    png(os.path.join(folder, 'hegemony_trim.png'), _sheet_image(rows))
    png(os.path.join(folder, 'hegemony_decals.png'), decals)
    src = 'own work, drawn by tools/blender/kits/hegemony/stack.py and dedicated CC0 (no downloaded asset)'
    lines = [dict(file='hegemony_trim.png', source=src, licence='CC0', used='trim sheet: machining and handling marks (rows: ' + ', '.join(rows) + ')'),
             dict(file='hegemony_decals.png', source=src, licence='CC0', used='decal atlas: hull number, module corner tick, module index bars, registry plate')]
    lp = os.path.join(os.path.dirname(folder.rstrip('/\\')), 'licences.json')
    old = json.load(open(lp, encoding='utf-8')).get('textures', []) if os.path.exists(lp) else []
    keep = [r for r in old if r.get('file') not in {l['file'] for l in lines}]
    json.dump(dict(textures=keep + lines), open(lp, 'w', encoding='utf-8'), indent=1)
    return lines


def sample_concept():
    """repeat the colour sampling of hegemony.md section 2 on the H10 beauty (needs Pillow): k-means, 9 clusters, the background
    (pixels near the corner colour) left out; returns the cluster centres and shares, dark to light"""
    from PIL import Image
    p = os.path.join(REPO, 'contrib', 'muse', 'design', 'concept_round7_2026_11', 'hegemony_H10_beauty.jpg')
    im = np.asarray(Image.open(p).convert('RGB')).astype(np.float32); bg = im[:8, :8].reshape(-1, 3).mean(0)
    X = im.reshape(-1, 3); X = X[np.abs(X - bg).sum(1) > 24]
    rng = np.random.default_rng(1); X = X[rng.choice(len(X), min(60000, len(X)), replace=False)]; C = X[rng.choice(len(X), 9, replace=False)]
    for _ in range(40):
        a = ((X[:, None] - C[None]) ** 2).sum(2).argmin(1); C = np.array([X[a == j].mean(0) if (a == j).any() else C[j] for j in range(9)])
    return [(tuple(int(v) for v in C[j]), round(float((a == j).mean()), 3)) for j in np.argsort(C.mean(1))]
