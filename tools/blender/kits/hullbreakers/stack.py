# The Ashfall Hullbreakers paint stack for ships built from a build sheet (issue 601). Written once for the faction's kit and
# used by every Hullbreaker sheet ship (R218; RULEBOOK 0.9, R225: one home per fact). The machinery is shared and has no look
# (tools/blender/kits/shared/paint_stack.py); everything that looks like the Hullbreakers is here.
#
# The method (ships.md section 0 item 2, R96 Q1, binding): procedural layers driven by masks baked from the ship's own geometry
# (ambient occlusion, edges), a trim sheet and decals. Colours are SAMPLED from the accepted concept; the concept picture is never
# projected onto the ship. No downloaded asset: the trim sheet and the decal atlas are drawn by this file (own work dedicated CC0,
# written into the job's textures folder with their licence lines, RULEBOOK 5.13).
#
# The faction (docs/playbooks/factions.md): soot black, rust, dried-blood red, patches of trophy colour (pale Hegemony grey,
# violet Eclipse plate), dim red running lights. Never clean symmetry, bright light or fresh paint. Lore round 8: the
# Hullbreakers run dark. The game lifts this faction's albedo by 1.25 at the battle camera (R227, godot/render/look.gd): the
# lift lives in the game, not here, so these colours are the concept's own read under the game's light without it.
#
# Where each colour zone sits on a ship is the build sheet's decision (its materials soot, rust, iron, blood, pale, violet, ...);
# this file says what each zone is made of.
import os, json, math
import numpy as np
import bpy

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.normpath(os.path.join(HERE, '..', '..', '..', '..'))

# ------------------------------------------------------------------------------------------------------------ concept colours
# Sampled from contrib/muse/design/concept_round8_2026_11/corsair_A16_beauty.jpg (the accepted A16 concept; corsair_A.jpg is
# the same palette): k-means of the hull pixels in the box x 90 to 1650, y 60 to 1000 (the escort excluded), separately for all
# mid-tone pixels, the reddish pixels (r over g above 1.35), the violet pixels and the dark pixels (luminance 8 to 35). sRGB, as
# lit in the picture: (shadow or low tone, lit tone). sample_concept() below repeats it.
CONCEPT = dict(
    soot=((18, 20, 23), (41, 39, 43)),          # the dark cool plate that is most of the hull (dark clusters 48 and 27 percent)
    soot2=((10, 12, 15), (29, 29, 32)),         # the darker soot plate
    iron=((24, 25, 29), (58, 55, 60)),          # iron plate and belts: dark gunmetal (the dark and low mid-tone clusters)
    rust=((44, 20, 16), (98, 44, 31)),          # the rust plate: dark brick red (the red clusters, blue held under green: never pink)
    blood=((58, 20, 18), (100, 28, 24)),        # dried-blood red plate and bands
    pale=((98, 88, 88), (149, 136, 130)),       # pale Hegemony grey trophy plate
    violet=((57, 29, 53), (110, 78, 140)),      # violet Eclipse trophy plate (violet clusters)
    steel=((20, 21, 24), (52, 50, 56)),         # gun metal, machinery: dark, its bare edges carry the light
    rust_streak=((34, 15, 11), (84, 40, 26)),   # rust run-off and blooms: the deep red-brown dark cluster, brick, not pink
    bare=((120, 110, 111), (170, 157, 151)),    # worn bare metal on edges (the lit grey clusters)
    grime=((10, 9, 9), (20, 17, 16)),           # soot and grime
    red_plate=((60, 22, 17), (108, 42, 28)),    # the brick and blood red plates scattered among the dark ones (red clusters)
    gunmetal=((34, 35, 40), (72, 70, 76)),      # the grey gun-metal plates of the patchwork (mid-tone clusters 52, 52, 59 and 72, 67, 77)
    scrape=((112, 106, 102), (165, 156, 150)),  # bare steel scrape plates (the lit grey clusters)
)
# The game's light on a face at about 45 degrees to the key (godot/render/look.gd: key 2.0, ambient 0.25 x key), the factor
# between an albedo and the lit tone the concept shows; checked by the sandbox preview under the game's light (issue 601).
LIGHT_GAIN = 1.45


def lin(srgb):
    c = np.asarray(srgb, np.float64) / 255.0
    return tuple(float(x) / LIGHT_GAIN for x in np.where(c <= .04045, c / 12.92, ((c + .055) / 1.055) ** 2.4))


def pair(k):
    lo, hi = CONCEPT[k]; return lin(lo), lin(hi)


# ------------------------------------------------------------------------------------------------------------ the layers
SCALE = 1.0          # every size below is in ship lengths (the recipe's frame: the ship is 1.0 long)
LAYERS = dict(
    ao_short=.004, ao_long=.025, edge_radius=.0010, edge_gain=14.0,      # the masks (about 10 cm, 65 cm, 2.6 cm on the 26 unit barge)
    patch_scale=4.0, plate_var=.40, side_dark=.25, grain_scale=260.0, mottle_scale=90.0, mottle=.10, grain=.02,    # base: broad two-tone patches, one tone per plate island
    rough=.70, metal=.40, wear=1.0, grime=.75, ao_dark=.88, red_tone=.75,
    # the plate patchwork (issue 601 Board review: the concept's hull is a quilt of small plates, each its own tone): a grid of
    # panels at the concept's plate size, staggered, each panel and each modelled plate picks a family; black seams between them
    patch_cell=(.034, .022, .019), patch_seam=.0011, seam_dark=.85,
    cavity_pow=2.0, wear_lo=.30, wear_hi=.52,
    scuff=.85, scuff_size=.045,                                           # the trim sheet's scuff tile, 1.2 m across on the barge
    rivets=1, rivet_pitch=.011, rivet_band=(.0012, .0045),               # a rivet every 29 cm, in a band 3 to 12 cm in from each edge
    trim_size=dict(stripes=.03, tread=.02, weld=.03), trim_aspect=dict(stripes=1.0, tread=1.0, weld=4.0),
    streak_scale=4.0, streak_stretch=60.0, rust_blot=26.0,                # rust: long vertical streaks, blotches about 4 percent across
    grime_z=(-.12, -.04), soot_x=(-.50, -.25), soot_aft=.35,              # grime gathers low and soot toward the engines
    wear_scale=70.0, wear_patch=5.0, bump_distance=.0008, bump_strength=.55,
)
# zone: base pair, then what the layers do to it. rust 0 keeps a trophy plate's own paint clean of new rust (it came off a
# ship that kept it painted); scuff and wear still mark it.
ZONES = dict(
    soot=dict(rust=.45, grime=.75, red_share=.20, patchwork=1.0),
    soot2=dict(rust=.40, grime=.85, plate_var=.35, red_share=.15, patchwork=1.0),
    iron=dict(rust=.55, metal=.55, rough=.58, wear=1.0, red_share=.12, patchwork=1.0),
    rust=dict(rust=.90, rough=.88, metal=.20, patchwork=.6),
    blood=dict(rust=.40, rough=.86, metal=.15, patchwork=.4),
    pale=dict(rust=.15, rough=.70, metal=.25, plate_var=.25),
    violet=dict(rust=.10, rough=.62, metal=.20, plate_var=.20),
    steel=dict(rust=.25, metal=.65, rough=.50, wear=1.0, rivets=0),
    dark=dict(rust=0, grime=.2, wear=.15, scuff=.1, rivets=0, metal=.1, rough=.9, plate_var=.1),
    dish=dict(rust=.30, metal=.40, rough=.55, plate_var=.1, scuff=1.0),
    warhead=dict(rust=.35, metal=.30, rough=.65, rivets=0),
    brass=dict(rust=.20, metal=.60, rough=.50, rivets=0),
    iron_bay=dict(base='iron', rust=.4, metal=.45, rough=.72, trim=('stripes',), trim_amount=.75),
)
_BASE = dict(soot='soot', soot2='soot2', iron='iron', rust='rust', blood='blood', pale='pale', violet='violet', steel='steel',
             dark='grime', dish='bare', warhead='rust', brass='bare', iron_bay='iron')
for _k, _z in ZONES.items():
    _lo, _hi = pair(_BASE[_k])
    if _k == 'dish': _lo, _hi = lin((70, 66, 64)), lin((120, 112, 108))
    if _k == 'brass': _lo, _hi = lin((70, 52, 26)), lin((120, 92, 46))
    if _k == 'warhead': _lo, _hi = lin((60, 22, 16)), lin((104, 40, 26))
    _z['lo'], _z['hi'] = _lo, _hi
FALLBACK = 'soot'
ZONE_BY_KIND = {('bay', 'iron'): 'iron_bay'}      # (part kind, sheet zone): the launch bay mouth carries the warning stripes
BARE = lin(CONCEPT['bare'][1])
RUST = lin(CONCEPT['rust_streak'][1]); RUST_DARK = lin(CONCEPT['rust_streak'][0])
GRIME = lin(CONCEPT['grime'][0])
RED_PLATE = pair('red_plate')    # a zone's red_share of its plates carry this worn red over-paint (the concept's scattered red plates)
# the patchwork families (a hull zone with patchwork > 0): (share of panels, colour pair). The rest keep the zone's own tones.
# Shares read off the concept's hull pixels (the k-means above): dark soot most, then gun-metal grey, brick red, a few scrapes.
PATCH_FAMILIES = [(.30, pair('soot2')), (.24, pair('gunmetal')), (.20, pair('red_plate')), (.06, pair('scrape'))]

# glowing zones keep their own emissive surface: engine throat and bell lining in the faction's engine colour, running lights
# in its accent (godot/fx/faction_looks.json corsair, the game's one home for them); dim, never bright (factions.md)
GLOW = ('glow', 'ember', 'light')
GLOW_STRENGTH = dict(glow=6.0, ember=1.4, light=1.0)


def faction_look():
    p = os.path.join(REPO, 'godot', 'fx', 'faction_looks.json')
    d = json.load(open(p, encoding='utf-8'))
    return d.get('corsair') or d.get('factions', {}).get('corsair')


def glow_material(zone):
    f = faction_look(); col = f['accent'] if zone == 'light' else f['engine']
    # the engine throat is the ship's glow surface (export7 names the first p3_glow material CODE_glow); the bell lining and the
    # running lights are their own emissive surfaces
    m = bpy.data.materials.new('p3_glow' if zone == 'glow' else f'p3_{zone}'); m.use_nodes = True
    b = m.node_tree.nodes['Principled BSDF']
    b.inputs['Base Color'].default_value = (col[0] * .08, col[1] * .08, col[2] * .08, 1); b.inputs['Roughness'].default_value = .6
    if zone == 'light': col = [c * LIGHT_EMIT for c in col]
    b.inputs['Emission Color'].default_value = (*col, 1); b.inputs['Emission Strength'].default_value = GLOW_STRENGTH.get(zone, 2.0)
    return m


# ------------------------------------------------------------------------------------------------------------ running lights
# The Board, Nov 12 2026 (PR 610 review, R207: the concept guides): the concept shows clear red lights along the flanks and the deck
# edges, so they are made to read at the battle camera: every running light is at least the light size rule across (RULEBOOK
# standing check `lights`: light_min_px, 2.0 px on a 70 px ship) with a small margin, red, small, never a bloom halo (the
# emission stays under the game's glow threshold, 0.8, godot/render/look.gd). Placed by rule on each ship's own hull, as the
# decals: a row along each flank at the height of the sheet's own lamps (the sheet decides where the light row runs; mid-flank
# when it has none) and a few points on the deck edges. A light is a flush lens in a thin iron frame (surface fittings like the
# decals, on hull faces only, clear of every part and of the breach, braking and boarding points).
RUNNING_LIGHTS = dict(px=2.2, aspect=1.5, proud=.0015, frame=.25, max_step=.012,
                      flank=dict(x=(.06, .82), step=.068, z_band=(.40, .62)),
                      deck=dict(x=(.16, .30, .44, .58, .72), inset=.010),
                      clear_points=.045, clear_decals=.035)
LIGHT_EMIT = .75      # emission colour = accent x this, strength 1: under the game's 0.8 glow threshold, so no halo


# ------------------------------------------------------------------------------------------------------------ decals
# Placed by rule on each ship's own surfaces (shared/paint_stack.place_decals): x is the station from the bow (0) to the stern
# (1), searched in that order; z the height band on the side (0 the keel, 1 the top); a top decal searches the deck at y.
# Hullbreaker marks are crude, painted by hand in the field and half worn off. The kill tallies and the clan mark are the
# builder's design (the concept shows none at its scale): see the build sheet's "Changed from the picture".
DECAL_CELLS = 2      # the atlas is 2 x 2 cells: 0 clan mark, 1 hull code, 2 kill tallies, 3 warning chevrons
DECALS = [
    dict(name='hull code', cell=1, face='side', x=(.22, .26, .30, .34), z=(.45, .70), w=.050, h=.025, alpha=.85),
    dict(name='clan mark', cell=0, face='top', x=(.30, .34, .38, .42), y=(0.0, .03, -.03), w=.050, h=.050, alpha=.80, min_facing=.9),
    dict(name='kill tallies', cell=2, face='side', x=(.62, .58, .66, .54), z=(.50, .78), w=.040, h=.020, alpha=.80),
    dict(name='warning chevrons', cell=3, face='side', x=(.08, .11, .14), z=(.35, .65), w=.030, h=.015, alpha=.70),
]


def _disc(h, w, cx, cy, r):
    y, x = np.mgrid[0:h, 0:w]; return np.hypot(x - cx, y - cy) <= r


def decal_atlas(res=1024):
    """the decal atlas, RGBA in 0..1, row 0 at the top; drawn here (own work)"""
    c = res // 2; A = np.zeros((res, res, 4), np.float32)
    rng = np.random.default_rng(601)
    blood = np.array(CONCEPT['blood'][1]) / 255 * 1.1; bone = np.array((176, 166, 150)) / 255; soot = np.array((18, 16, 15)) / 255
    y, x = np.mgrid[0:c, 0:c]; u = x / c; v = y / c
    def put(cell, mask, col):
        cx, cy = cell % 2, cell // 2; sl = (slice(cy * c, cy * c + c), slice(cx * c, cx * c + c))
        a = A[sl]; m = mask.astype(np.float32) * (0.75 + 0.25 * rng.random(mask.shape))
        a[..., :3] = np.where(m[..., None] > 0, col, a[..., :3]); a[..., 3] = np.maximum(a[..., 3], m)
    # 0 the clan mark: a broken ring (the hull they took) torn by three claw slashes
    r = np.hypot(u - .5, v - .5); ang = np.arctan2(v - .5, u - .5)
    ring = (r > .30) & (r < .40) & ~((ang > .35) & (ang < .95))
    slash = np.zeros_like(ring)
    for k in (-1, 0, 1):
        d = np.abs((u - .5 - k * .13) * .94 + (v - .5) * .34)
        slash |= (d < .028 + .02 * (1 - np.abs(v - .5) * 2)) & (np.abs(v - .5) < .44)
    put(0, ring | slash, blood)
    # 1 the hull code: stencil glyphs C 1 9 (the ship's game code, C19), with stencil bridges
    g = np.zeros((c, c), bool)
    def bar(x0, y0, x1, y1): g[int(y0 * c):int(y1 * c), int(x0 * c):int(x1 * c)] = True
    bar(.06, .25, .12, .75); bar(.06, .25, .27, .33); bar(.06, .67, .27, .75)                       # C
    bar(.40, .25, .47, .75); bar(.35, .25, .40, .33)                                                 # 1
    bar(.60, .25, .86, .33); bar(.60, .25, .67, .52); bar(.60, .46, .86, .53); bar(.79, .25, .86, .75); bar(.60, .67, .86, .75)  # 9
    g[int(.47 * c):int(.50 * c), :] = False                                                           # the stencil bridge
    put(1, g, bone)
    # 2 kill tallies: rows of four strokes and a slash, scratched in by hand
    t = np.zeros((c, c), bool)
    for row in range(2):
        for grp in range(4):
            x0 = .06 + grp * .23; y0 = .18 + row * .40
            for s in range(4):
                xs = x0 + s * .04 + rng.uniform(-.006, .006); t |= (np.abs(u - xs) < .011) & (v > y0) & (v < y0 + .28)
            t |= (np.abs((u - x0 - .08) * .8 - (v - y0 - .14) * .55) < .012) & (u > x0 - .02) & (u < x0 + .18) & (v > y0) & (v < y0 + .28)
    put(2, t, bone)
    # 3 warning chevrons: soot and bone, faded (a Hullbreaker warning, not a navy's yellow)
    ch = ((np.mod((u * 4 + np.abs(v - .5) * 4), 1.0) < .5) & (np.abs(v - .5) < .42) & (u > .04) & (u < .96))
    put(3, ch, bone * .8)
    put(3, ~ch & (np.abs(v - .5) < .42) & (u > .04) & (u < .96), soot)
    # wear: every mark has bare patches where the paint came off
    holes = np.kron(rng.random((res // 16, res // 16)) < .18, np.ones((16, 16))) > 0
    A[..., 3] *= np.where(holes, .25, 1.0)
    return A


# ------------------------------------------------------------------------------------------------------------ the trim sheet
def _tile_noise(n, k, rng):
    """smooth tileable noise, n px, k cells"""
    g = rng.random((k, k)); up = np.kron(g, np.ones((n // k, n // k)))
    for _ in range(3): up = (up + np.roll(up, 1, 0) + np.roll(up, -1, 0) + np.roll(up, 1, 1) + np.roll(up, -1, 1)) / 5
    return (up - up.min()) / (up.max() - up.min() + 1e-9)


def trim_sheet():
    """the faction's trim tiles, each RGBA in 0..1 (alpha is the tile's mask and height): drawn here (own work). Written to the job
    as one trim sheet image, rows top to bottom in this order."""
    rng = np.random.default_rng(209)
    T = {}
    # rivets: one domed rivet head per tile, a dark ring of grime round it
    n = 128; y, x = np.mgrid[0:n, 0:n]; r = np.hypot(x - n / 2, y - n / 2) / (n * .16)
    dome = np.clip(1 - r * r, 0, 1); ring = np.clip(1 - np.abs(r - 1.15) * 3, 0, 1)
    a = np.clip(dome + ring * .5, 0, 1); col = np.stack([.25 + .35 * dome] * 3, -1) * (1 - ring[..., None] * .6)
    T['rivets'] = np.dstack([col, a])
    # scuffs: scratches wiped mostly along the ship, chips, tileable
    n = 512; m = np.zeros((n, n), np.float32)
    for _ in range(260):
        L = rng.uniform(10, 140); th = rng.normal(0, .35) + (math.pi / 2 if rng.random() < .2 else 0)
        x0, y0 = rng.uniform(0, n, 2); w = rng.uniform(.6, 1.8); s = rng.uniform(.3, 1.0)
        for t in np.linspace(0, 1, int(L)):
            xi = int(x0 + math.cos(th) * L * t) % n; yi = int(y0 + math.sin(th) * L * t) % n
            for dx in range(-int(w), int(w) + 1):
                m[yi, (xi + dx) % n] = max(m[yi, (xi + dx) % n], s * (1 - abs(dx) / (w + 1)))
    chips = _tile_noise(n, 64, rng) > .86
    m = np.maximum(m, chips * .7)
    T['scuffs'] = np.dstack([np.stack([np.full((n, n), .6)] * 3, -1), m])
    # stripes: faded bone and soot at 45 degrees (warning marks on a launch bay mouth)
    n = 128; y, x = np.mgrid[0:n, 0:n]; s = (np.mod(x + y, n / 2) < n / 4)
    col = np.where(s[..., None], np.array((150, 140, 124)) / 255, np.array((16, 14, 13)) / 255)
    fade = _tile_noise(n, 8, rng)
    T['stripes'] = np.dstack([col, (.55 + .45 * fade) * (fade > .25)])
    # tread: raised diamonds of deck plate
    n = 128; y, x = np.mgrid[0:n, 0:n]; d = np.abs(np.mod(x + y, 32) - 16) + np.abs(np.mod(x - y, 32) - 16)
    dia = (d < 9).astype(np.float32); T['tread'] = np.dstack([np.stack([.3 + .3 * dia] * 3, -1), dia * .8])
    # weld: a rippled bead along the tile
    n = 128; y, x = np.mgrid[0:n // 4, 0:n]; b = np.clip(1 - np.abs(y - n / 8) / (n / 14), 0, 1) * (.75 + .25 * np.cos(x / n * 2 * math.pi * 12))
    T['weld'] = np.dstack([np.stack([.35 + .3 * b] * 3, -1), b])
    return T


def _sheet_image(rows, width=512):
    """the rows stacked into one trim sheet (each row resized to the sheet's width by repetition)"""
    out = []
    for k, a in rows.items():
        h, w = a.shape[:2]; reps = int(math.ceil(width / w)); r = np.tile(a, (1, reps, 1))[:, :width]
        out.append(r)
    return np.concatenate(out, 0)


def write_textures(folder, rows, decals):
    """the trim sheet and decal atlas into the job's textures folder, with their licence lines (standing.py licences)"""
    import struct, zlib
    def png(path, a):
        a = (np.clip(a, 0, 1) * 255).astype(np.uint8); h, w = a.shape[:2]
        raw = b''.join(b'\x00' + a[i].tobytes() for i in range(h))
        def chunk(t, d): return struct.pack('>I', len(d)) + t + d + struct.pack('>I', zlib.crc32(t + d) & 0xffffffff)
        open(path, 'wb').write(b'\x89PNG\r\n\x1a\n' + chunk(b'IHDR', struct.pack('>IIBBBBB', w, h, 8, 6, 0, 0, 0)) + chunk(b'IDAT', zlib.compress(raw, 6)) + chunk(b'IEND', b''))
    png(os.path.join(folder, 'hullbreakers_trim.png'), _sheet_image(rows))
    png(os.path.join(folder, 'hullbreakers_decals.png'), decals)
    src = 'own work, drawn by tools/blender/kits/hullbreakers/stack.py and dedicated CC0 (no downloaded asset)'
    lines = [dict(file='hullbreakers_trim.png', source=src, licence='CC0', used='trim sheet: rivet rows, scuffs, warning stripes, tread, weld (rows: ' + ', '.join(rows) + ')'),
             dict(file='hullbreakers_decals.png', source=src, licence='CC0', used='decal atlas: clan mark, hull code, kill tallies, warning chevrons')]
    lp = os.path.join(os.path.dirname(folder.rstrip('/\\')), 'licences.json')
    old = json.load(open(lp, encoding='utf-8')).get('textures', []) if os.path.exists(lp) else []
    keep = [r for r in old if r.get('file') not in {l['file'] for l in lines}]
    json.dump(dict(textures=keep + lines), open(lp, 'w', encoding='utf-8'), indent=1)
    return lines


def sample_concept(path=None):
    """repeat the colour sampling above (needs Pillow; Blender's python has it after env.bat): prints the cluster centres"""
    from PIL import Image
    path = path or os.path.join(REPO, 'contrib', 'muse', 'design', 'concept_round8_2026_11', 'corsair_A16_beauty.jpg')
    im = np.asarray(Image.open(path).convert('RGB')).astype(np.float32)[60:1000, 90:1650].reshape(-1, 3)
    rng = np.random.default_rng(1); L = im.mean(1)
    def km(X, k):
        X = X[rng.choice(len(X), min(40000, len(X)), replace=False)]; C = X[rng.choice(len(X), k, replace=False)]
        for _ in range(40):
            a = ((X[:, None] - C[None]) ** 2).sum(2).argmin(1); C = np.array([X[a == j].mean(0) if (a == j).any() else C[j] for j in range(k)])
        return [(tuple(int(v) for v in C[j]), round(float((a == j).mean()), 3)) for j in np.argsort(C.mean(1))]
    return dict(mid=km(im[(L > 35) & (L < 200)], 10), red=km(im[(im[:, 0] > im[:, 1] * 1.35) & (L > 25) & (L < 200)], 6),
                violet=km(im[(im[:, 2] > im[:, 1] * 1.4) & (im[:, 0] > im[:, 1] * 1.1) & (L > 30)], 3), dark=km(im[(L > 8) & (L < 35)], 4))
