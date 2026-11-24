"""Opt-in hull methods from Astra's Picket. Distances are in the sheet's units."""

from bisect import bisect_right
from math import dist, isfinite


def _lerp(a, b, t):
    return tuple(x + (y - x) * t for x, y in zip(a, b))


class FlatSoleLoft:
    """A symmetric faceted hull through aft-to-bow (x, half beam, deck z) stations.

    The three fractions scale the deck, chine and sole widths from each half beam.
    Flank heights and the sole are fixed z datums. Chine height is above the sole.
    """

    def __init__(self, stations, *, sole, flank, chine_height, widths):
        self.stations = tuple(tuple(station) for station in stations)
        self.xs = tuple(x for x, _, _ in self.stations)
        self.sole = sole
        self.flank = tuple(flank)
        self.chine = sole + chine_height
        self.widths = tuple(widths)
        deck_width, chine_width, sole_width = self.widths
        lower, upper = self.flank
        if (len(self.xs) < 2 or not all(isfinite(x) for x in self.xs)
                or any(a >= b for a, b in zip(self.xs, self.xs[1:]))):
            raise ValueError('the loft needs at least two stations in increasing X order')
        if (not 0 < sole_width < chine_width < 1 or not 0 < deck_width < 1
                or not sole < self.chine < lower < upper
                or any(not (isfinite(beam) and beam > 0 and isfinite(deck) and deck > upper)
                       for _, beam, deck in self.stations)):
            raise ValueError('the loft needs positive widths and ordered heights from sole to deck')

    def ring(self, x):
        """An interpolated ring, clockwise looking from the bow, starting at the starboard deck edge."""
        i = bisect_right(self.xs, x)
        if x < self.xs[0] or x > self.xs[-1]:
            raise ValueError('station is outside the loft')
        if i == len(self.xs):
            _, beam, deck = self.stations[-1]
        else:
            a, b = self.stations[i - 1], self.stations[i]
            beam, deck = _lerp(a[1:], b[1:], (x - a[0]) / (b[0] - a[0]))
        d, c, s = (beam * fraction for fraction in self.widths)
        lower, upper = self.flank
        return [(x, y, z) for y, z in ((-d, deck), (d, deck), (beam, upper), (beam, lower),
                                      (c, self.chine), (s, self.sole), (-s, self.sole),
                                      (-c, self.chine), (-beam, lower), (-beam, upper))]

    def rings(self, start=None, end=None):
        """Rings for Kit.loft_rings, retaining all authored stations within a module span."""
        start = self.xs[0] if start is None else start
        end = self.xs[-1] if end is None else end
        if not self.xs[0] <= start < end <= self.xs[-1]:
            raise ValueError('module span must be inside the loft and run aft to bow')
        return [self.ring(x) for x in (start, *(x for x in self.xs if start < x < end), end)]


def in_plate_keepout(centre, radius, keepouts):
    """Test selected mount footprints with 30 percent of the panel radius as clearance."""
    return any(dist(centre, origin) < reach + radius * .3 for origin, reach in keepouts)


_BOX_FACES = ((3, 2, 1, 0), (4, 5, 6, 7), (0, 1, 5, 4),
              (1, 2, 6, 5), (2, 3, 7, 6), (3, 0, 4, 7))


def _box(name, role, material, x, y, z):
    x0, x1 = x
    y0, y1 = y
    verts = [(a, b, c) for c in z for a, b in ((x0, y0), (x1, y0), (x1, y1), (x0, y1))]
    return name, role, material, (verts, _BOX_FACES)


def _rim(x, y, rim, z, material):
    opening = (-x + rim, x - rim)
    return [_box('frame_aft', 'mount', material, (-x, opening[0]), (-y, y), z),
            _box('frame_fore', 'mount', material, (opening[1], x), (-y, y), z),
            _box('frame_port', 'mount', material, opening, (y - rim, y), z),
            _box('frame_starboard', 'mount', material, opening, (-y, -y + rim), z)]


def slatted_cassette(*, length, width, depth, rim, seat, slats, slat_width, materials):
    """Cooling cassette components in local +Z-out, +X-length coordinates.

    Materials are (back, frame, slat). The dark back and frame seat in the hull;
    the spaced slats sit below the rim. Mount the result as a vent.
    """
    if (not 0 < 2 * rim < min(length, width) or depth <= 0 or seat <= 0
            or not isinstance(slats, int) or slats < 1 or not 0 < slat_width < (length - 2 * rim) / slats):
        raise ValueError('cassette needs a rim and clear space between its slats')
    back, trim, fin = materials
    x, y = length / 2, width / 2
    opening = (-(x - rim), x - rim)
    result = [_box('back', 'mount', back, (-x, x), (-y, y), (-seat, 0))]
    result.extend(_rim(x, y, rim, (0, depth), trim))
    for i in range(slats):
        centre = opening[0] + (i + .5) * (length - 2 * rim) / slats
        result.append(_box(f'slat{i}', 'body', fin, (centre - slat_width / 2, centre + slat_width / 2),
                           (-y + rim, y - rim), (depth * .15, depth * .8)))
    return result


def belly_cover(*, length, width, depth, rim, seat, gap, materials):
    """A seated flange and its separate removable lid, using (flange, lid) materials.

    Local axes match slatted_cassette. Gap is the clearance around the lid, which
    stays a separate mesh for editing or showing the service trunk open.
    """
    if not 0 < 2 * rim < 2 * (rim + gap) < min(length, width) or depth <= 0 or seat <= 0:
        raise ValueError('cover needs positive depth, seat, flange width and lid clearance')
    flange, lid = materials
    x, y = length / 2, width / 2
    inset = rim + gap
    shelf = inset + min(gap, (min(x, y) - inset) / 2)
    base = depth / 3
    return [*_rim(x, y, shelf, (-seat, base), flange), *_rim(x, y, rim, (base, depth), flange),
            _box('lid', 'body', lid, (-x + inset, x - inset), (-y + inset, y - inset), (base, depth))]


def stripe_runs(stations, doors, *, clearance):
    """Split increasing stripe X stations around door (min X, max X) intervals.

    Returns point stations for each remaining run, including exact cut ends.
    Use the same result for the trim race and its inlay; sample the hull at each X.
    """
    stations = tuple(stations)
    doors = tuple(doors)
    if (len(stations) < 2 or any(a >= b for a, b in zip(stations, stations[1:]))
            or clearance < 0 or any(a >= b for a, b in doors)):
        raise ValueError('stripe stations must increase, doors must have width, and clearance cannot be negative')
    runs = []
    start, end = stations[0], stations[-1]
    for low, high in sorted(doors):
        low, high = max(start, low - clearance), min(end, high + clearance)
        if low >= high:
            continue
        if start < low:
            runs.append((start, low))
        start = high
    if start < end:
        runs.append((start, end))
    return [[a, *(x for x in stations if a < x < b), b] for a, b in runs]
