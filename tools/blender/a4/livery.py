# A4 hand livery (Nov 1 2026): ships whose concept projection smears get their livery painted from rules instead, in texture space,
# from each texel's 3D point and normal (concept.rasterise). Same frame as the ship npz: x along the length (+x bow), y up, z beam.
# The procedural bake still carries the small scale (panel lines, grain, hatches, wear) through concept.compose; this file only sets the
# large shapes: plate tones, the two-tone hull, stripes.
#
# H4_11 (Hegemony super-dreadnought). The projection put the concept's painted shading on the hull as diagonal red and blue smears (bow and
# middle, side) and grey blotches (deck), because the concept shows a stepped tower the faired hull no longer has (blob sweep, Nov 1:
# 4 of 9 cells). Read off docs/ship_pipeline/concepts/H4_11.webp and Ryan's Hegemony direction (clean futuristic, light grey and blue):
#   - light slate plating, plate to plate a few percent apart (the concept's tiled deck), never blotches;
#   - a darker slate lower hull: the underside facets and the bottom quarter of the side wall;
#   - a thin faction-blue line where the two tones meet;
#   - one red pinstripe along each deck edge, the full length; short red ticks down the side armour at even spacing (the concept's
#     red belt marks), matched port and starboard.
import numpy as np

W3 = np.array([.2126, .7152, .0722], np.float32)


def hexc(h): return np.array([int(h[i:i + 2], 16) / 255. for i in (1, 3, 5)], np.float32)


LIVERY = {
    'H4_11': dict(base='#a7b1bd', lower='#59677a', blue='#3f78c8', red='#c23b33', plate=(.040, .030, .026), plate_var=.035,
                  edge=(.80, .845), tick_dx=.085, tick_w=.006, tick_h=.32, low_frac=.25, blue_w=.007),
}


def has(code): return code in LIVERY


def _cell_noise(a, b, c, seed):
    """a value in -1..1 per integer cell (a, b, c), stable"""
    h = (a.astype(np.int64) * 73856093) ^ (b.astype(np.int64) * 19349663) ^ (c.astype(np.int64) * 83492791) ^ seed
    h = (h ^ (h >> 13)) * 1274126177; h = h ^ (h >> 16)
    return ((h & 0xffff).astype(np.float32) / 32767.5) - 1.0


def paint(code, P, N, nbins=200):
    """per-texel sRGB colour (n, 3) in 0..1 for texel points P and normals N"""
    L = LIVERY[code]; x, y, z = P[:, 0], P[:, 1], P[:, 2]; az = np.abs(z)
    # the hull's own profile along its length, from the outer deck only (so the command block and the gun sponsons do not bend the lines):
    # half-beam, main deck height and belly height per x bin, median-smoothed over about a tenth of the length
    x0, x1 = float(x.min()), float(x.max()); b = np.clip(((x - x0) / max(x1 - x0, 1e-6) * nbins).astype(int), 0, nbins - 1)
    up0 = N[:, 1] > .65
    beam = np.zeros(nbins, np.float32); bot = np.full(nbins, 9., np.float32); np.maximum.at(beam, b, az); np.minimum.at(bot, b, y)
    deck = np.full(nbins, np.nan, np.float32)
    for i in range(nbins):
        sel = up0 & (b == i) & (az > beam[i] * .6)
        if sel.sum() > 8: deck[i] = np.percentile(y[sel], 40)
    ok = ~np.isnan(deck); deck = np.interp(np.arange(nbins), np.nonzero(ok)[0], deck[ok]).astype(np.float32)
    def med(v, w=21):
        vp = np.pad(v, w // 2, mode='edge'); return np.array([np.median(vp[i:i + w]) for i in range(len(v))], np.float32)
    beam, deck, bot = med(beam), med(deck), med(bot)
    hb, yt, yb = beam[b], deck[b], bot[b]
    up, down, side = N[:, 1] > .65, N[:, 1] < -.3, np.abs(N[:, 2]) > .55
    base, lower, blue, red = (np.broadcast_to(hexc(L[c]), (len(P), 3)).copy() for c in ('base', 'lower', 'blue', 'red'))
    from concept import s2l, l2s
    col = s2l(base)
    # plates: box-projected cells (top faces by x and z, side faces by x and y), each a few percent lighter or darker
    px, py, pz = L['plate']
    cx = np.floor(x / px); cy = np.floor(y / py); cz = np.floor(z / pz)
    n_top = _cell_noise(cx, cz, np.zeros_like(cx), 11); n_side = _cell_noise(cx, cy, np.sign(z), 23)
    pv = np.where(up, n_top, np.where(side, n_side, _cell_noise(cx, cy, cz, 37))) * L['plate_var']
    col = col * (1 + pv[:, None])
    # two-tone hull: underside facets and the bottom of the side wall
    yl = yb + (yt - yb) * L['low_frac']
    low = down | (side & (y < yl))
    col = np.where(low[:, None], s2l(lower) * (1 + pv[:, None]), col)
    # the blue line where the tones meet on the side wall
    wall = (np.abs(N[:, 2]) > .8) & (az > hb * .85)  # the outer side wall, not the superstructure's sides
    bl = (np.abs(N[:, 2]) > .55) & (az > hb * .7) & (np.abs(y - yl) < L['blue_w'] * .5)
    col = np.where(bl[:, None], s2l(blue), col)
    # red pinstripe along each deck edge (top faces, a band of the local half-beam)
    e0, e1 = L['edge']; rel = az / np.maximum(hb, 1e-4)
    pin = up & (rel > e0) & (rel < e1) & (np.abs(y - yt) < (yt - yb) * .12)
    # red ticks down the side armour from the deck edge, evenly spaced, matched both sides
    ph = np.abs(((x - x0) / L['tick_dx']) % 1.0 - .5) * L['tick_dx']
    tick = wall & (ph < L['tick_w'] * .5) & (y < yt + .004) & (y > yt - (yt - yb) * L['tick_h']) & ~low & (x > x0 + .08 * (x1 - x0)) & (x < x1 - .1 * (x1 - x0))
    col = np.where((pin | tick)[:, None], s2l(red), col)
    return l2s(col)


def image(code, I, P, N, res):
    """the livery as a texture (res, res, 3) sRGB 0..1 and its mask"""
    out = np.zeros((res * res, 3), np.float32); out[I] = paint(code, P, N)
    mask = np.zeros(res * res, bool); mask[I] = True
    return out.reshape(res, res, 3), mask.reshape(res, res)
