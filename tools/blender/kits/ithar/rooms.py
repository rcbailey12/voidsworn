# Glasswright rooms (Ryan, Nov 23 2026: "why don't the glasswrights ships have actual interiors like other ships?"; his picks:
# a mix, real decks and rooms so the ship reads as a ship plus crystal machinery as the Glasswright touch; dim like every other
# faction; pearl and smoked glass with the leaf colours only on the lit crystals; GA1, GL1, GP1, GS1 and CD5, craft stay hollow).
#
# hull.insides() keeps what it builds (the layered glass decks, the open annealed frames, the braided light cores). This adds the
# rooms around them, as K.room boxes the shared Interior Kit V2 pass (build_sheets/interior_kit.py) furnishes like every other
# faction's rooms, in the Glasswright shapes (hexagonal crystal machinery, lit leaf-colour crystals) and the faction's role
# colours from godot/fx/faction_looks.json "interior". Three bands per compartment, every room inside one compartment (no room
# crosses a break, ships.md 5.17):
#   between the two decks   two rows of rooms, port and starboard, flanking the light-core trunk on the centreline (stores
#                           holds and stored-light machinery in turn)
#   above the top deck      one centreline row: the song bridge forward, crew galleries behind it
#   under the bottom deck   one centreline row: the crystal heart in the longest middle compartment, the drive resonators aft,
#                           the lens stores forward, the stored-light racks between
# half_w(x), half_h(x), x0, x1, breaks, decks, y0 and tag are hull.insides()'s own arguments, so the rooms sit where the decks do.
import math

GAP = 0.04          # of the ship's length either side of a break (hull.insides() keeps its decks off the break by the same)
EDGE = 0.012        # of the ship's length: the gap between neighbouring rooms along the hull
LONG = 0.2          # of the ship's length: a longer compartment row is split into two rooms


def _spans(K, x0, x1, breaks, gap=None):
    g = GAP * K.length if gap is None else gap
    edges = [x0] + [v for b in sorted(breaks) for v in (b - g, b + g)] + [x1]
    return [(edges[i], edges[i + 1]) for i in range(0, len(edges), 2) if edges[i + 1] - edges[i] > 0.05 * K.length]


def _cells(K, a, b):
    """one or two rooms along x inside the span, EDGE apart and off its ends"""
    e = EDGE * K.length
    a, b = a + e, b - e
    if b - a > LONG * K.length:
        m = (a + b) / 2
        return [(a, m - e / 2), (m + e / 2, b)]
    return [(a, b)]


def _least(f, a, b, n=7):
    return min(f(a + (b - a) * i / (n - 1)) for i in range(n))


def rooms(K, half_w, half_h, x0, x1, breaks, breach_x=(), decks=(-0.3, 0.2), y0=0.0, tag='', heart=True, gap=None, deck_z=None,
          bands=('mid', 'top', 'low')):
    """the Glasswright rooms for one hull (a twin hull calls it once per pod, with its y0 and tag); returns the room count.
    deck_z: the decks' own heights when a sheet builds them at fixed heights (CD5), instead of decks as fractions of half_h;
    gap: the sheet's own clearance either side of a break (CD5 0.22), instead of GAP of the length; bands: which of the three
    bands to fill (CD5 leaves out 'top', where its light reservoirs sit)"""
    spans = _spans(K, x0, x1, breaks, gap)
    if not spans:
        return 0
    zb, zt = min(decks), max(decks)
    th = 0.012 * K.length                                   # clear of the deck glass (its solidify is 0.015 of the length)
    longest = max(range(len(spans)), key=lambda i: spans[i][1] - spans[i][0])
    bow, stern = len(spans) - 1, 0                          # x runs stern (x0) to bow (x1)
    made = 0
    for si, (a, b) in enumerate(spans):
        for ci, (ra, rb) in enumerate(_cells(K, a, b)):
            hw = _least(half_w, ra, rb); hh = _least(half_h, ra, rb)
            if hw < 0.03 * K.length or hh < 0.03 * K.length:
                continue
            name = lambda base: '%s%s_%d%d' % (base, tag, si, ci)
            zlo, zhi = (min(deck_z), max(deck_z)) if deck_z else (zb * hh, zt * hh)
            # between the decks: port and starboard rows beside the light cores (which braid within 0.30 of the beam)
            z0, z1 = zlo + th, zhi - th
            yi, yo = 0.36 * hw, 0.70 * hw
            if 'mid' in bands and z1 - z0 > 0.04 * K.length:
                kind = 'hold' if (si + ci) % 2 == 0 else 'machinery'
                for s, side in ((1, 'p'), (-1, 's')):
                    lo, hi = sorted((y0 + s * yi, y0 + s * yo))
                    K.room(name('gw_' + kind + side), kind, ra, rb, lo, hi, z0, z1,
                           note='Glasswright %s beside the light-core trunk, in pearl and smoked glass' %
                                ('stores hold' if kind == 'hold' else 'stored-light machinery'))
                    made += 1
            # above the top deck: the song bridge in the bow compartment, galleries elsewhere
            z0, z1 = zhi + th, 0.58 * hh
            if 'top' in bands and z1 - z0 > 0.04 * K.length:
                fore = si == bow and ci == len(_cells(K, a, b)) - 1
                kind = 'bridge' if fore else 'crew'
                w = 0.42 * hw
                K.room(name('gw_' + kind), kind, ra, rb, y0 - w, y0 + w, z0, z1,
                       note='the song bridge: consoles of lit crystal under the crown' if fore else
                       'a crew gallery over the light cores, a lit crystal at every console')
                made += 1
            # under the bottom deck: the crystal heart, the drive resonators, the lens stores, the stored-light racks
            z0, z1 = -0.62 * hh, zlo - th
            if 'low' in bands and z1 - z0 > 0.04 * K.length:
                if heart and si == longest and ci == 0:
                    kind, note = 'core', 'the crystal heart: a lit hexagonal crystal column in collars, the ship\'s stored light'
                elif si == stern:
                    kind, note = 'engroom', 'the drive resonators: hexagonal crystal columns feeding the stern optics'
                elif si == bow:
                    kind, note = 'magazine', 'the lens stores: racked crystal lenses for the lances'
                else:
                    kind, note = 'machinery', 'stored-light racks with lit crystal caps'
                w = 0.40 * hw
                K.room(name('gw_' + kind), kind, ra, rb, y0 - w, y0 + w, z0, z1, note=note)
                made += 1
    K.inside.append(dict(kind='note', name='%srooms' % (tag.strip('_') + ' ' if tag else ''),
                         note='Glasswright rooms (Ryan, Nov 23): %d rooms in three bands per compartment, furnished by the shared '
                              'Interior Kit V2 in crystal shapes' % made))
    return made
