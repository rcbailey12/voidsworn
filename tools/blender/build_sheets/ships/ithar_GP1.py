"""GP1, the Glasswright prism (data.js i_song, Cruiser). Issue 1415, Ryan's Nov 16 pick Step 3
(contrib/muse/design/glasswright_family_2026_11/cruiser.md): two parallel pane hulls side by side, joined by curved glass
bridges, stored light glowing in the cleft between them; one lens point at each bow (the two pulsars), a lens blister on top
amidships (the turret), a white bloom at each stern. Ryan likes the parallel read: the hulls are never merged.

Built in the R337 finish on the shared Glasswright kit (tools/blender/kits/ithar: parts.py, stack.py, hull.py). This hull is
the pane-heavy one of the family: narrow pearl ribbons over a mostly mosaic skin, as the pick's thick lens panes.
Nothing is see-through. Replaces the Nov 1 hull I15_11 (R368).
  python THIS_FILE review TEMP_OUT
  python THIS_FILE layout TEMP_OUT docs/ship_pipeline/build_sheets/ithar_GP1
"""
import math
from pathlib import Path
import sys

sys.dont_write_bytecode = True
ROOT = Path(__file__).resolve().parents[4]
CODE = 'ithar_GP1'
SHORT = 'GP1 Prism'
NAME = 'Glasswright prism GP1'
PICK = 'Step 3'
FACTION = 'The Glasswrights (ithar)'
CLASS = 'Cruiser'
LENGTH = 14.5
GAME_SHIP = 'i_song'
GAME = 'data.js i_song (Cruiser); CLS_LEN Cruiser = 14.5, SHIP_K 1.6 = 23.2 on the board'
BEAUTY = 'contrib/muse/design/glasswright_family_2026_11/img/cruiser_prism_s3.webp'
SHEET = dict(version=1, round='R337 / issue 1415', date='2026-11-20', stage='blockout + paint preview')
CAMERA = dict(az=58.0, el=42.0, roll=-8.0, scale=33.0)
CLOSE = dict(daz=-12, del_=6, scale=0.45, target=(0.0, 0, 0.03))
COMPARE_NOTE = ['Two parallel pane hulls joined by two arched bridges; seafoam stored light on the inner flanks.',
                'Opaque (R337): mostly glowing panes with narrow pearl ribbons. Lens points at both bows, blister on top.']
SIDE_NOTE = 'Two hulls, each about 6.5 to 1, side by side; the bridges arch above the cleft.'
INSIDE_NOTE = 'Each hull: two shaped glass decks, open annealed frames and three braided light cores, cut at both break lines.'

XS, XB = -6.55, 6.15          # each pod's stern and bow
YP = 1.72                     # pod centre line, port (+) and starboard (-)
R = 1.30                      # pod radius at the widest
S = (LENGTH / 26.0) ** 0.7
BRIDGES = (-2.7, 2.2)


def hk(name):
    import importlib.util
    key = 'ithar_' + name
    if key not in sys.modules:
        spec = importlib.util.spec_from_file_location(key, ROOT / 'tools/blender/kits/ithar' / (name + '.py'))
        mod = importlib.util.module_from_spec(spec); sys.modules[key] = mod; spec.loader.exec_module(mod)
    return sys.modules[key]


def radius(x):
    t = min(1.0, max(0.0, (x - XS) / (XB - XS)))
    body = max(0.0, math.sin(math.pi * min(1.0, t * 0.78 + 0.11))) ** 0.45      # long, full, rounded at the stern
    nose = 1.0 - 0.80 * max(0.0, (t - 0.80) / 0.20) ** 1.6                        # drawn to the bow lens collar
    stern = 1.0 - 0.32 * max(0.0, (0.06 - t) / 0.06) ** 1.4
    return max(0.04, R * body * nose * stern)


def pod(side):
    def skin(x, a, inset=0.0):
        r = max(0.02, radius(x) - inset)
        return (x, side * YP + r * math.cos(a), 0.86 * r * math.sin(a))
    return skin


TWIST = lambda x: 0.035 * x + 0.10 * math.sin(0.30 * x)


def field(side):
    hl = hk('hull')
    return hl.RibbonField(10, lambda x: side * TWIST(x), sway=0.0, leaf_f=2.6, start=0.15)


def light(side):
    """seafoam stored light on the pod's inner flank, facing the cleft, between the bridges"""
    def f(x, a):
        inner = max(0.0, -side * math.cos(a) - 0.55) / 0.45
        span = max(0.0, min(1.0, (x - (BRIDGES[0] - 1.2)) / 1.0, ((BRIDGES[1] + 1.2) - x) / 1.0))
        return inner ** 1.2 * span
    return f


def bridge(K, hl, x, name):
    """an arched glass bridge from pod to pod: a flattened oval tube rising over the cleft, pearl over a mosaic underside,
    a silver line along each edge"""
    pts, rads = [], []
    for i in range(41):
        u = -1 + 2 * i / 40
        y = u * YP
        z = 0.25 + 0.72 * (1 - u * u) ** 0.8
        pts.append((x, y, z))
    sec = lambda xx, a, i: None
    vv, ff = [], []
    n, m = len(pts), 28
    for i, p in enumerate(pts):
        u = -1 + 2 * i / 40
        wx = 0.55 + 0.25 * u * u            # flares where it grows into each pod
        tz = 0.20 + 0.10 * u * u
        for j in range(m):
            a = j * hl.TAU / m
            vv.append((p[0] + wx * math.cos(a), p[1], p[2] + tz * math.sin(a)))
    for i in range(n - 1):
        for j in range(m):
            a_, b_ = i * m + j, i * m + (j + 1) % m
            ff.append((a_, b_, b_ + m, a_ + m))
    ob = K._obj(name, vv, ff, 'gw_pearl', smooth=True)
    ob.data.attributes.new('gw_across', 'FLOAT', 'POINT'); ob.data.attributes.new('gw_along', 'FLOAT', 'POINT')
    ob.data.attributes['gw_across'].data.foreach_set('value', [math.cos(j * hl.TAU / m) for i in range(n) for j in range(m)])
    ob.data.attributes['gw_along'].data.foreach_set('value', [i / (n - 1) for i in range(n) for j in range(m)])
    for sgn in (-1, 1):
        edge = [(p[0] + sgn * (0.56 + 0.25 * (-1 + 2 * i / 40) ** 2), p[1], p[2] + 0.02) for i, p in enumerate(pts)]
        K._obj(name + ('_silver_f' if sgn > 0 else '_silver_a'), *hl.tube_mesh(edge, [0.030 * S] * n, 6), 'gw_silver', smooth=True)
    # a row of seafoam panes under the arch, the stored light the bridge carries between the hulls
    under = [(p[0], p[1], p[2] - (0.20 + 0.10 * (-1 + 2 * i / 40) ** 2) * 0.92) for i, p in enumerate(pts)][4:-4]
    K._obj(name + '_light', *hl.tube_mesh(under, [0.09] * len(under), 10), 'gw_light', smooth=True)
    return ob


def build(K):
    hl = hk('hull')
    gw = hk('parts')
    hl.material_setup(CODE, LENGTH)
    for side, tag in ((1, 'port'), (-1, 'stbd')):
        skin = pod(side)
        f = field(side)
        core = hl.mosaic_core(K, '%s_%s_pane_hull' % (CODE, tag), skin, XS, XB, f.gap_of, nu=180, nv=120, thick=0.04,
                              seed=5 if side > 0 else 8, light=light(side), even=0.7)
        K.mass('%s pane hull' % tag.capitalize(), core, 'opaque glowing stained-glass panes',
               note='One of the two parallel hulls; thick amber, violet and green panes under narrow pearl ribbons.')
        ribbons = []
        for k in range(f.n):
            ribbons.append(gw.Ribbon(
                XS + 0.15 + 0.10 * math.sin(2.3 * k), XB - 0.35 - 0.10 * (k % 3), f.centre(k),
                lambda t, k=k: (0.085 + 0.012 * math.sin(1.7 * k)) * gw.leaf(0.35, 0.65, 0.5, tip=0.35)(t),
                lambda t, v: S * (0.04 + 0.08 * (1 - v * v) ** 0.5),
                name='%s_ribbon_%d' % (tag, k)))
        hl.lay_ribbons(K, ribbons, skin, 0.035 * S, 0.030 * S, nu=160, nv=6)
        hl.lance(K, 'L%d' % (1 if side > 0 else 2), (XB - 0.50, side * YP, 0.0), 1.30, 0.40,
                 note='One pulsar lance per hull: a grown lens point at the bow on the hull\'s own axis; fixed forward, F arc.',
                 what='grown lens point at the %s bow / pulsar' % tag)
        hl.stern_drive(K, 'E%d' % (1 if side > 0 else 2), (XS + 0.38, side * YP, 0.0), 0.62)
    K.mark('flowing_hull', 'hull', ['bevel', 'step', 'overhang'])
    for i, x in enumerate(BRIDGES):
        b = bridge(K, hl, x, '%s_bridge_%s' % (CODE, 'aft' if i == 0 else 'fwd'))
        K.mass('Arched bridge %s' % ('aft' if i == 0 else 'fwd'), b, 'pearl glass bridge between the hulls',
               note='Grows out of both hulls; carries a row of stored light under its arch.')
    # the turret: a lens blister grown on the crown of the forward bridge, on the centreline
    hl.turret_optic(K, 'O1', (BRIDGES[1], 0.0, 0.25 + 0.72 + 0.20 + 0.19), 'turret', 'violet', s=1.15,
                    note='The Needle beam: a violet lens blister grown on the crown of the forward bridge, 360 degrees.')
    breaks = (-4.35, 4.05)
    breach_x = (4.9, 0.3, -5.1)
    for side, tag in ((1, 'port'), (-1, 'stbd')):
        hl.insides(K, lambda x: 0.70 * radius(x), lambda x: 0.60 * radius(x), XS + 0.9, XB - 0.9, breaks, breach_x,
                   decks=(-0.35, 0.25), frames=9, y0=side * YP, tag='_' + tag)
    K.armour('annealed outer glass', 0.04, 'actual shell thickness; layered blown glass, no armour plates')
    hl.ragged_break(K, 'B1', breaks[0], 2 * (YP + R) + 0.6, 'ragged shatter path through both hulls aft of the aft bridge; the stern optics stay whole')
    hl.ragged_break(K, 'B2', breaks[1], 2 * (YP + R) + 0.6, 'ragged shatter path through both hulls forward of the forward bridge; the bow lances stay whole')
    K.point('core', 'hp_core', (0.0, YP, 0.0))
    for i, (x, side, sec) in enumerate(((breach_x[0], 1, 'prow'), (breach_x[1], -1, 'mid'), (breach_x[2], 1, 'eng'))):
        K.point('breach', 'hp_breach_%d' % i, pod(side)(x, 0.35 if side > 0 else math.pi - 0.35), side='port' if side > 0 else 'stbd', section=sec)
    for i, (x, side) in enumerate(((-3.2, 1), (3.0, -1))):
        a = 0.0 if side > 0 else math.pi
        K.point('rcs', 'hp_rcs_%d' % i, pod(side)(x, a), side='port' if side > 0 else 'stbd')
        K.point('board', 'hp_board_%d' % i, pod(side)(x - 1.0, a), side='port' if side > 0 else 'stbd')
    K.colour('amber, violet, green panes', XB, XS, 'most of each hull; glows from within')
    K.colour('opaque pearl ribbons, silver edges', XB, XS, 'nine narrow ribbons on each hull, the bridges')
    K.colour('seafoam stored light', BRIDGES[1] + 1.2, BRIDGES[0] - 1.2, 'the inner flanks facing the cleft and under each bridge')
    K.colour('soft white bloom', XS + 0.4, XS - 0.4, 'one stern drive optic per hull, no flame')
    K.change('Opaque panes and pearl instead of the sketch\'s clear glass', 'R337 (Ryan, Nov 19): nothing see-through.')
    K.change('Two arched bridges, the turret blister on the crown of the forward one',
             'The sketch\'s curved bridges; a blister on the bridge crown clears both hulls through a full turn (turret T, 360).')
    K.change('Stored light on the hulls\' inner flanks and under the bridges, not a pool in open space',
             'The cleft is open space between two hulls; the glow sits on the glass that faces it.')
    K.change('Each bow lens point is a short drawn-glass lance with a glowing tip on the hull\'s axis',
             'cruiser.md: keep them points, never tubes; one pulsar per hull.')


if __name__ == '__main__':
    hk('hull').main(sys.modules[__name__])
