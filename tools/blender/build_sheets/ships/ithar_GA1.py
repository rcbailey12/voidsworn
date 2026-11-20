"""GA1, the Glasswright aperture (data.js i_carrier, Carrier). Issue 1415, Ryan's Nov 16 pick V1
(contrib/muse/design/glasswright_family_2026_11/carrier.md): the CD5 leaf scaled up to carrier size, one dominant axis, the
hangar carried as two lens bays grown into the flanks with Starlings visible inside, a bow lance on the centreline (the
pulsar), a lens blister on top amidships (the turret), a soft white bloom at the stern optic.

Built in the R337 finish on the shared Glasswright kit (tools/blender/kits/ithar: parts.py, stack.py, hull.py): opaque
reflective pearl ribbons with silver edges over glowing amber, violet and green mosaic. Nothing is see-through: each hangar
lens is a shallow well in the mosaic core with a floor of seafoam stored light. Replaces the Nov 1 hull I16_11 (R368).
  python THIS_FILE review TEMP_OUT
  python THIS_FILE layout TEMP_OUT docs/ship_pipeline/build_sheets/ithar_GA1
"""
import math
from pathlib import Path
import sys

sys.dont_write_bytecode = True
ROOT = Path(__file__).resolve().parents[4]
CODE = 'ithar_GA1'
SHORT = 'GA1 Aperture'
NAME = 'Glasswright aperture GA1'
PICK = 'V1'
FACTION = 'The Glasswrights (ithar)'
CLASS = 'Carrier'
LENGTH = 16.5
GAME_SHIP = 'i_carrier'
GAME = 'data.js i_carrier (Carrier); CLS_LEN Carrier = 16.5, SHIP_K 1.6 = 26.4 on the board'
BEAUTY = 'contrib/muse/design/glasswright_family_2026_11/img/carrier_aperture_v1.webp'
SHEET = dict(version=1, round='R337 / issue 1415', date='2026-11-20', stage='blockout + paint preview')
CAMERA = dict(az=64.0, el=36.0, roll=-10.0, scale=32.0)
CLOSE = dict(daz=-8, del_=4, scale=0.42, target=(-0.06, 0.12, 0.0))
COMPARE_NOTE = ['The CD5 leaf at carrier size: pearl ribbons over glowing panels, a hangar lens in each flank.',
                'Opaque (R337): each hangar lens is a shallow well floored with stored light, Starlings parked on it.']
SIDE_NOTE = 'One broad leaf, about 3.2 to 1; the hangar lens sits mid-flank, the turret blister on the crown.'
INSIDE_NOTE = 'Two shaped glass decks, open annealed frames and three braided light cores, cut at all three break lines.'

XS, XB = -7.75, 6.95
W = 2.55
S = (LENGTH / 26.0) ** 0.7
BAY = dict(x=-0.6, len=5.6, hgt=1.55, depth=0.40)
TURRET_X = -2.6
LANCE_X = XB - 0.75


def hk(name):
    import importlib.util
    key = 'ithar_' + name
    if key not in sys.modules:
        spec = importlib.util.spec_from_file_location(key, ROOT / 'tools/blender/kits/ithar' / (name + '.py'))
        mod = importlib.util.module_from_spec(spec); sys.modules[key] = mod; spec.loader.exec_module(mod)
    return sys.modules[key]


def width(x):
    t = min(1.0, max(0.0, (x - XS) / (XB - XS)))
    leaf = max(0.0, math.sin(math.pi * t ** 1.12)) ** 0.62
    stern = 1.20 * math.exp(-((x - XS - 1.05) / 1.05) ** 2)      # the broad stern shoulders round the big stern optic
    return 0.06 + W * leaf + stern


def height(x):
    return 0.50 * width(x) + 0.25


def flow_phase(x):
    return 0.16 * x + 0.42 * math.sin(x * 0.35)


def base_skin(x, a, inset=0.0):
    w = max(0.03, width(x) - inset)
    h = max(0.03, height(x) - inset)
    folded = math.atan2(math.sin(a), abs(math.cos(a)))
    ridge = 4 * (folded - flow_phase(x))
    flow = 1.0 + 0.12 * math.cos(ridge) + 0.03 * math.cos(2 * ridge)
    return (x, w * math.cos(a), h * math.sin(a)), flow


def bay_q(x, a):
    """the hangar lens ellipse in (x, height): 0 at its middle, 1 at its rim; and the side (+1 port, -1 starboard)"""
    side = 1 if math.cos(a) >= 0 else -1
    z = height(x) * math.sin(a)
    q = ((x - BAY['x']) / (BAY['len'] / 2)) ** 2 + (z / (BAY['hgt'] / 2)) ** 2
    return q, side


def skin(x, a, inset=0.0):
    """the CD5 leaf at carrier scale (broad poured ridges, a flatter section), with a shallow oval well in each flank for the
    hangar lens: smooth walls, a flat floor"""
    p, flow = base_skin(x, a, inset)
    q, side = bay_q(x, a)
    dent = 0.0
    if q < 1.0 and abs(math.cos(a)) > 0.3:
        k = min(1.0, (1.0 - q) / 0.25)
        dent = BAY['depth'] * k * k * (3 - 2 * k)
        flow = 1.0 + (flow - 1.0) * (1 - k)
    r = math.hypot(p[1] / max(1e-6, width(x) - inset), p[2] / max(1e-6, height(x) - inset))
    y = p[1] * flow - side * dent * abs(math.cos(a))
    return (x, y, p[2] * flow)


TWIST_A = lambda x: 0.11 * x + 0.30 * math.sin(0.33 * x)
TWIST_B = lambda x: 0.08 * x + 0.22 * math.sin(0.38 * x + 1.1)
LEAVES = [(-7.0, 1.2, 1.30, 0.17), (-5.2, 5.6, 2.25, 0.16), (-3.2, 5.8, 0.75, 0.16)]


def bay_clear(x, a):
    """push a ribbon's angle off the hangar lens: inside the lens window, ribbons near the flank slide above or below it"""
    q, side = bay_q(x, a)
    span = 1.0 - ((x - BAY['x']) / (BAY['len'] / 2 + 0.9)) ** 2
    if span <= 0:
        return a
    flank = 0.0 if side > 0 else math.pi
    d = math.atan2(math.sin(a - flank), math.cos(a - flank))
    lim = 0.62
    if abs(d) >= lim:
        return a
    s = span ** 0.5
    target = lim if d >= 0 else -lim
    return a + (target - d) * s


def field():
    hl = hk('hull')
    g = hl.bow_gather(1.5, 7.0, (0.55, math.pi - 0.55, -math.pi / 2), 0.85)
    return hl.RibbonField(13, TWIST_A, sway=0.12, leaf_f=1.25, start=0.2, gather=lambda x, a: bay_clear(x, g(x, a)))


def light(x, a):
    q, side = bay_q(x, a)
    if abs(math.cos(a)) < 0.3:
        return 0.0
    return max(0.0, min(1.0, (1.0 - q) / 0.35))


def build(K):
    hl = hk('hull')
    gw = hk('parts')
    hl.material_setup(CODE, LENGTH)
    f = field()
    turret_z = max(skin(TURRET_X + 0.3 * i / 6, math.pi / 2 + 0.2 * j / 6)[2] for i in range(-6, 7) for j in range(-6, 7))
    clamp = hl.optic_clamp([(TURRET_X, 0.0, 1.5)])
    core = hl.mosaic_core(K, CODE + '_mosaic_core', skin, XS, XB, f.gap_of, nu=240, nv=160, thick=0.05, seed=2, light=light)
    K.mass('Mosaic leaf core', core, 'opaque glowing stained-glass mosaic',
           note='The CD5 leaf at carrier size; two shallow hangar wells floored with stored light; never see-through.')
    K.mark('flowing_hull', 'hull', ['bevel', 'step', 'overhang'])
    ribbons = []
    for k in range(f.n):
        ribbons.append(gw.Ribbon(
            XS + 0.25 + 0.15 * math.sin(2.3 * k), XB - 0.15 - 0.25 * (k % 3), f.centre(k),
            lambda t, k=k: (0.135 + 0.025 * math.sin(1.7 * k)) * gw.leaf(0.55, 0.40, 0.40 + 0.05 * math.sin(k), tip=0.0)(t),
            lambda t, v: S * (0.05 + 0.14 * (1 - v * v) ** 0.5 * (0.5 + 0.5 * math.sin(math.pi * t) ** 0.5)),
            name='long_ribbon_%d' % k, clamp=clamp))
    for k, (x0, x1, base, wd) in enumerate(LEAVES):
        top = max(0.0, math.sin(base)) ** 2
        ribbons.append(gw.Ribbon(
            x0, x1, lambda x, base=base: bay_clear(x, base + TWIST_B(x)),
            lambda t, wd=wd: wd * gw.leaf(0.7, 0.0, 0.38)(t),
            lambda t, v, top=top: S * (0.22 + 0.14 * (1 - v * v) ** 0.5 + 0.75 * top * ((v + 1) / 2) ** 2 * math.sin(math.pi * t) ** 1.5),
            name='leaf_ribbon_%d' % k, clamp=clamp))
    hl.lay_ribbons(K, ribbons, skin, 0.035 * S, 0.024 * S, nu=170, nv=8)
    hl.lance(K, 'L1', (LANCE_X, 0.0, 0.0), 2.05, 0.48,
             note='The bow lance: a drawn-glass waveguide grown from the bow optic on the centreline; fixed forward, F arc.',
             what='drawn-glass bow lance on the centreline / pulsar', collar=0.62)
    hl.turret_optic(K, 'O1', (TURRET_X, 0.0, turret_z + 0.30), 'turret', 'violet', s=1.35,
                    note='The Needle beam: a violet lens blister grown on the crown, 360 degrees.')
    # the hangar lenses: a pearl lip round each well, Starlings parked on its stored-light floor
    for i, side in enumerate((1, -1)):
        a_mid = 0.0 if side > 0 else math.pi
        rim = []
        for j in range(72):
            v = hl.TAU * j / 72
            x = BAY['x'] + 0.5 * BAY['len'] * math.cos(v)
            zt = 0.5 * BAY['hgt'] * math.sin(v)
            a = math.asin(max(-0.95, min(0.95, zt / height(x))))
            a = a if side > 0 else math.pi - a
            rim.append(base_skin(x, a)[0])
        floor = lambda u, w, side=side: (lambda x, zt: (x, side * (width(x) - BAY['depth']) * math.cos(math.asin(max(-0.9, min(0.9, zt / height(x))))), zt))(
            BAY['x'] + 0.45 * BAY['len'] * u, 0.45 * BAY['hgt'] * w)
        hl.lens_bay(K, 'H%d' % (i + 1), rim, floor, side, craft=3, s=1.5, hangar_index=i)
    hl.stern_drive(K, 'E1', (XS + 0.70, 0.0, 0.0), 1.38)
    breaks = (-5.45, -4.15, 3.05)
    breach_x = (4.6, 3.6, 1.6, -2.2, -6.0)
    hl.insides(K, lambda x: 0.66 * width(x), lambda x: 0.66 * height(x), XS + 1.0, XB - 0.9, breaks, breach_x,
               decks=(-0.35, 0.25), frames=10)
    K.armour('annealed outer glass', 0.05, 'actual shell thickness; layered blown glass, no armour plates')
    hl.ragged_break(K, 'B1', breaks[0], 2 * W + 2, 'ragged shatter path forward of the stern optic; the drive stays whole')
    hl.ragged_break(K, 'B2', breaks[1], 2 * W + 2, 'ragged shatter path aft of the hangar lenses, forward of the turret blister')
    hl.ragged_break(K, 'B3', breaks[2], 2 * W + 2, 'ragged shatter path forward of the hangar lenses; the bow lance stays whole')
    K.point('core', 'hp_core', (0.6, 0, 0.0))
    for i, (x, side, sec) in enumerate(((breach_x[0], 1, 'prow'), (breach_x[1], -1, 'prow'), (breach_x[2], 1, 'mid'),
                                        (breach_x[3], -1, 'mid'), (breach_x[4], 1, 'eng'))):
        K.point('breach', 'hp_breach_%d' % i, skin(x, 0.95 if side > 0 else math.pi - 0.95), side='port' if side > 0 else 'stbd', section=sec)
    for i, (x, side) in enumerate(((-5.0, 1), (4.0, -1))):
        a = 0.0 if side > 0 else math.pi
        K.point('rcs', 'hp_rcs_%d' % i, skin(x, a), side='port' if side > 0 else 'stbd')
        K.point('board', 'hp_board_%d' % i, skin(x + 0.8, a), side='port' if side > 0 else 'stbd')
    K.colour('opaque pearl ribbons, silver edges', XB, XS, 'thirteen long ribbons and three crest leaves sweep stern to bow')
    K.colour('amber, violet, green mosaic panels', XB, XS, 'the core between the ribbons; glows from within')
    K.colour('seafoam stored light', BAY['x'] + BAY['len'] / 2, BAY['x'] - BAY['len'] / 2, 'the floor of each hangar lens')
    K.colour('soft white bloom', XS + 0.6, XS - 0.6, 'the big stern drive optic, no flame')
    K.change('Opaque pearl ribbons over a glowing mosaic core instead of the sketch\'s clear glass',
             'R337 (Ryan, Nov 19): the Glasswright finish is opaque reflective pearl with glowing stained-glass panels; nothing see-through.')
    K.change('Each hangar lens is a shallow well in the mosaic skin with a pearl lip and a stored-light floor, three Starlings parked on it',
             'carrier.md: lenses grown into the skin, not cut openings or pods; Starlings visible; opaque, so the floor is light, not a window.')
    K.change('The sketch\'s extra stern and flank lens rings are left out; one large stern optic carries the bloom',
             'Weapon match (R241): only data.js weapons show as lenses (one pulsar F, one turret T); the rings read as more guns.')
    K.change('Ribbons slide above and below each hangar lens', 'So the lens stays clear and reads as grown into the skin.')


if __name__ == '__main__':
    hk('hull').main(sys.modules[__name__])
