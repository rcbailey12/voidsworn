# Glasswright rooms (Ryan, Nov 23 2026: "why don't the glasswrights ships have actual interiors like other ships?"; his picks:
# a mix, real decks and rooms so the ship reads as a ship plus crystal machinery as the Glasswright touch; dim like every other
# faction; pearl and smoked glass with the leaf colours only on the lit crystals; GA1, GL1, GP1, GS1 and CD5, craft stay hollow).
#
# hull.insides() keeps what it builds (the layered glass decks, the open annealed frames, the braided light cores). This adds the
# rooms around them, as K.room boxes the shared Interior Kit V2 pass (build_sheets/interior_kit.py) furnishes like every other
# faction's rooms, in the Glasswright shapes (hexagonal crystal machinery, lit leaf-colour crystals) and the faction's role
# colours from godot/fx/faction_looks.json "interior". Every room sits in one compartment (no room crosses a break, ships.md
# 5.17) and in one bay between two of the annealed frames, so the glass rings read as the bulkheads between rooms. Three bands:
#   between the two decks   two rows, port and starboard, flanking the light-core trunk on the centreline (stores holds and
#                           stored-light machinery in turn)
#   above the top deck      one centreline row: the song bridge forward, crew galleries behind it
#   under the bottom deck   one centreline row: the crystal heart in the longest compartment, the drive resonators aft, the
#                           lens stores forward, stored-light racks between
# half_w(x), half_h(x), x0, x1, breaks, breach_x, decks, frames, y0 and tag are hull.insides()'s own arguments, so the rooms sit
# where its decks and frames do; the rooms fill out to ENV of that envelope (inside the hull's inner glass, which the Interior
# Kit and surface_check.py hold the furniture and the room boxes off).
import math

GAP = 0.04          # of the ship's length either side of a break: hull.insides() keeps its decks off the break by the same
TH = 0.004          # of the ship's length: the clearance off the deck glass and the frame rings
MINH = 0.010        # of the ship's length: the lowest or narrowest room worth placing (GP1's pods are 2.6 high on a 14.5 hull)
MINL = 0.03         # of the ship's length: the shortest bay worth a room
ENV = 1.12          # the rooms' envelope, of hull.insides()'s half beam and height (its frame rings stand at 0.8 of them)


def frame_xs(K, x0, x1, breaks, breach_x, frames):
    """where hull.insides() stands its annealed frames (the same walk, so a room never crosses a ring)"""
    clear_b, clear_r = 0.1 * K.length, 0.14 * K.length
    out = []
    for i in range(frames):
        x = x0 + (x1 - x0) * (i + 0.5) / frames
        for _ in range(4):
            near = [b for b in breaks if abs(x - b) < clear_b] + [b for b in breach_x if abs(x - b) < clear_r]
            if not near:
                break
            lim = clear_b if near[0] in breaks else clear_r
            x = near[0] + (lim + 0.01) * (1 if x >= near[0] else -1)
        if not (x0 < x < x1) or any(abs(x - b) < clear_b for b in breaks) or any(abs(x - b) < clear_r for b in breach_x):
            continue
        out.append(x)
    return sorted(out)


def _spans(K, x0, x1, breaks, gap=None):
    g = GAP * K.length if gap is None else gap
    edges = [x0] + [v for b in sorted(breaks) for v in (b - g, b + g)] + [x1]
    return [(edges[i], edges[i + 1]) for i in range(0, len(edges), 2) if edges[i + 1] - edges[i] > MINL * K.length]


def _bays(K, a, b, rings, ring_r):
    """the bays of one compartment between its frame rings, each clear of a ring by its tube radius and TH"""
    c = ring_r + TH * K.length
    cuts = [x for x in rings if a + c < x < b - c]
    edges = [a] + cuts + [b]
    bays = []
    for i in range(len(edges) - 1):
        lo = edges[i] + (c if i > 0 else TH * K.length); hi = edges[i + 1] - (c if i < len(edges) - 2 else TH * K.length)
        if hi - lo > MINL * K.length:
            bays.append((lo, hi))
    return bays


def _least(f, a, b, n=7):
    return min(f(a + (b - a) * i / (n - 1)) for i in range(n))


def _most(f, a, b, n=7):
    return max(f(a + (b - a) * i / (n - 1)) for i in range(n))


def rooms(K, half_w, half_h, x0, x1, breaks, breach_x=(), decks=(-0.3, 0.2), frames=8, y0=0.0, tag='', heart=True, gap=None,
          deck_z=None, deck_t=None, rings=None, ring_r=None, bands=('mid', 'top', 'low')):
    """the Glasswright rooms for one hull (a twin hull calls it once per pod, with its y0 and tag); returns the room count.
    deck_z, deck_t: the decks' own heights and thickness when a sheet builds them itself (CD5), instead of decks as fractions
    of half_h and hull.insides()' 0.015 of the length;
    rings / ring_r: the sheet's own frame positions and tube radius when it stands its own frames (CD5); gap: the sheet's own
    clearance either side of a break (CD5 0.22); bands: which bands to fill (CD5 leaves out 'top' for its light reservoirs)"""
    L = K.length
    spans = _spans(K, x0, x1, breaks, gap)
    if not spans:
        return 0
    if rings is None:
        rings = frame_xs(K, x0, x1, breaks, breach_x, frames)
    if ring_r is None:
        ring_r = 0.012 * L
    zb, zt = min(decks), max(decks)
    th = TH * L; minh = MINH * L
    dk = 0.0075 * L if deck_t is None else deck_t / 2      # half the deck glass (hull.insides(): a 0.015 of the length solidify)
    spans_b = [(a, b, _bays(K, a, b, rings, ring_r)) for a, b in spans]
    spans_b = [s for s in spans_b if s[2]]
    if not spans_b:
        return 0
    longest = max(range(len(spans_b)), key=lambda i: spans_b[i][1] - spans_b[i][0])
    bow, stern = len(spans_b) - 1, 0                        # x runs stern (x0) to bow (x1)
    made = 0
    for si, (a, b, bays) in enumerate(spans_b):
        mid_bay = len(bays) // 2
        for ci, (ra, rb) in enumerate(bays):
            hw = _least(half_w, ra, rb); hh = _least(half_h, ra, rb); hx = _most(half_h, ra, rb)
            ew, eh = ENV * hw, ENV * hh                     # the rooms' ellipse in this bay
            name = lambda base: '%s%s_%d%d' % (base, tag, si, ci)
            if deck_z:
                zlo = zlo_x = min(deck_z); zhi = zhi_x = max(deck_z)
            else:
                zlo, zhi, zlo_x, zhi_x = zb * hh, zt * hh, zb * hx, zt * hx

            def width_at(z, frac=0.92):
                return ew * math.sqrt(max(0.0, 1 - (z / eh) ** 2)) * frac if abs(z) < eh else 0.0
            # between the decks: port and starboard rows beside the light cores (which braid within 0.30 of the beam)
            z0, z1 = zlo + dk + th, zhi - dk - th
            yi = 0.36 * hw; yo = width_at(max(abs(z0), abs(z1)))
            if 'mid' in bands and z1 - z0 > minh and yo - yi > minh:
                kind = 'hold' if (si + ci) % 2 == 0 else 'machinery'
                for s, side in ((1, 'p'), (-1, 's')):
                    lo, hi = sorted((y0 + s * yi, y0 + s * yo))
                    K.room(name('gw_' + kind + side), kind, ra, rb, lo, hi, z0, z1,
                           note='Glasswright %s beside the light-core trunk, in pearl and smoked glass' %
                                ('stores hold' if kind == 'hold' else 'stored-light machinery'))
                    made += 1
            # above the top deck: the song bridge in the bow compartment, crew galleries elsewhere
            z0 = zhi_x + dk + th
            w = 0.45 * ew; z1 = eh * math.sqrt(max(0.0, 1 - (w / ew) ** 2)) * 0.92
            if 'top' in bands and z1 - z0 > minh:
                fore = si == bow and ci == len(bays) - 1
                kind = 'bridge' if fore else 'crew'
                K.room(name('gw_' + kind), kind, ra, rb, y0 - w, y0 + w, z0, z1,
                       note='the song bridge: consoles of lit crystal under the crown' if fore else
                       'a crew gallery over the light cores, a lit crystal at every console')
                made += 1
            # under the bottom deck: the crystal heart, the drive resonators, the lens stores, the stored-light racks
            z1 = zlo_x - dk - th
            w = 0.45 * ew; z0 = -eh * math.sqrt(max(0.0, 1 - (w / ew) ** 2)) * 0.92
            if 'low' in bands and z1 - z0 > minh:
                if heart and si == longest and ci == mid_bay:
                    kind, note = 'core', 'the crystal heart: a lit hexagonal crystal column in collars, the ship\'s stored light'
                elif si == stern and len(spans_b) > 1:
                    kind, note = 'engroom', 'the drive resonators: hexagonal crystal columns feeding the stern optics'
                elif si == bow and len(spans_b) > 1:
                    kind, note = 'magazine', 'the lens stores: racked crystal lenses for the lances'
                else:
                    kind, note = 'machinery', 'stored-light racks with lit crystal caps'
                K.room(name('gw_' + kind), kind, ra, rb, y0 - w, y0 + w, z0, z1, note=note)
                made += 1
    K.inside.append(dict(kind='note', name='%srooms' % (tag.strip('_') + ' ' if tag else ''),
                         note='Glasswright rooms (Ryan, Nov 23): %d rooms in three bands, one per bay between the glass '
                              'frames, furnished by the shared Interior Kit V2 in crystal shapes' % made))
    print('[gw_rooms] %s: %d rooms' % (tag or 'hull', made), flush=True)
    return made
