"""GS1, the Glasswright sliver (data.js i_wisp, Frigate). Issue 1415, Ryan's Nov 16 pick R2a
(contrib/muse/design/glasswright_family_2026_11/frigate.md): two ribbons twisting round each other, fused at the bow and the
stern, pressed together along most of the length, with a short glowing cleft amidships.

Built in the R337 finish on the shared Glasswright kit (tools/blender/kits/ithar: parts.py, stack.py, hull.py): opaque
reflective pearl ribbons with silver edges over glowing amber, violet and green mosaic; the cleft holds seafoam stored light.
Nothing is see-through. Replaces the Nov 1 hull I14_23 (R368).
  python THIS_FILE review TEMP_OUT            (or blender -b -P THIS_FILE -- review TEMP_OUT)
  python THIS_FILE layout TEMP_OUT docs/ship_pipeline/build_sheets/ithar_GS1
"""
import math
from pathlib import Path
import sys

sys.dont_write_bytecode = True
ROOT = Path(__file__).resolve().parents[4]
CODE = 'ithar_GS1'
SHORT = 'GS1 Sliver'
NAME = 'Glasswright sliver GS1'
PICK = 'R2a'
FACTION = 'The Glasswrights (ithar)'
CLASS = 'Frigate'
LENGTH = 6.5
GAME_SHIP = 'i_wisp'
GAME = 'data.js i_wisp (Frigate); CLS_LEN Frigate = 6.5, SHIP_K 1.6 = 10.4 on the board'
BEAUTY = 'contrib/muse/design/glasswright_family_2026_11/img/frigate_sliver_r2a.webp'
SHEET = dict(version=1, round='R337 / issue 1415', date='2026-11-20', stage='blockout + paint preview')
CAMERA = dict(az=300.0, el=40.0, roll=12.0, scale=31.0)
CLOSE = dict(daz=10, del_=8, scale=0.55, target=(0.05, 0, 0.02))
COMPARE_NOTE = ['Two pearl ribbons twist round each other, fused at bow and stern; a short seafoam cleft amidships.',
                'Opaque: the sketch\'s clear glass is now pearl over glowing panels (R337). Three shard needles at the bow.']
SIDE_NOTE = 'One long axis, about 4.6 to 1; the two lobes twist about 150 degrees bow to stern.'
INSIDE_NOTE = 'Two shaped glass decks, open annealed frames and three braided light cores, cut at the break line.'

XS, XB = -2.95, 2.85          # the fused stern and bow of the twisted body
W = 0.70                      # half beam at the widest
CLEFT = (-1.25, 1.15)         # the short cleft amidships


def hk(name):
    import importlib.util
    key = 'ithar_' + name
    if key not in sys.modules:
        spec = importlib.util.spec_from_file_location(key, ROOT / 'tools/blender/kits/ithar' / (name + '.py'))
        mod = importlib.util.module_from_spec(spec); sys.modules[key] = mod; spec.loader.exec_module(mod)
    return sys.modules[key]


def t_of(x):
    return min(1.0, max(0.0, (x - XS) / (XB - XS)))


def env(x):
    t = t_of(x)
    # fused at both ends; the stern stays round enough to carry its drive optic, the bow draws to a point for the shards
    return max(0.0, math.sin(math.pi * t)) ** 0.55 * (1.0 - 0.18 * t) + 0.10 * math.exp(-((x - XS - 0.25) / 0.35) ** 2)


def theta(x):
    """the direction of the two lobes: horizontal amidships, turned about 50 degrees each way toward bow and stern"""
    return 1.35 * math.sin(math.pi * (t_of(x) - 0.5))


def cleft(x):
    a, b = CLEFT
    if x <= a or x >= b:
        return 0.0
    return math.sin(math.pi * (x - a) / (b - a)) ** 1.5


def skin(x, a, inset=0.0):
    """two round lobes along theta(x), pressed together (a shallow groove top and bottom) except in the cleft, where they part
    over a small core of stored light. A soft union (p = 8) keeps the groove smooth, never a crease."""
    e = env(x)
    rho = 0.43 * W / 0.70 * e
    d = (0.25 + 0.30 * cleft(x)) * W / 0.70 * e
    core = (0.30 - 0.10 * cleft(x)) * W / 0.70 * e
    u = a - theta(x)
    rr = []
    for c in (math.cos(u), -math.cos(u)):
        s2 = 1 - c * c
        disc = rho * rho - d * d * s2
        rr.append(max(0.0, d * c + math.sqrt(disc)) if disc > 0 else 0.0)
    r = (rr[0] ** 8 + rr[1] ** 8 + core ** 8) ** 0.125
    r = max(0.012, r - inset)
    return (x, r * math.cos(a), r * math.sin(a))


def half_w(x):
    return 0.62 * W * env(x)


def half_h(x):
    return 0.30 * W * env(x)


S = (LENGTH / 26.0) ** 0.7     # ribbon and line scale against CD5
# R431 round 3 (Ryan Nov 23 2026: every Glasswright reads as I8_37, the white "more detailed and wrapping"): the two
# twisting lobes stay in the body; the shell over them is the kit's I8_37 one, the Ark's spiralling ribbons with crossing
# leaves, and the glass shows only in their leaf seams. The old crest stripes (RIBS, gap_of) are gone.
def field():
    hl = hk('hull')
    return hl.i8_field(XB - XS, start=0.2, gather=hl.bow_gather(2.2, 2.85, (0.0, math.pi), 0.9))


def light(x, a):
    """seafoam stored light in the grooves, strongest and widest in the cleft"""
    u = a - theta(x)
    s_ = abs(math.sin(u))
    groove = max(0.0, s_ - 0.93) / 0.07
    wide = max(0.0, s_ - 0.55) / 0.30
    return max(0.7 * groove, min(1.0, wide) * cleft(x) ** 0.6)


def build(K):
    hl = hk('hull')
    gw = hk('parts')
    hl.material_setup(CODE, LENGTH)
    f = field()
    core = hl.mosaic_core(K, CODE + '_mosaic_core', skin, XS, XB, f.gap_of, nu=160, nv=128, thick=0.02, seed=3, light=light)
    K.mass('Twisted mosaic core', core, 'opaque glowing stained-glass mosaic',
           note='Two lobes twisting round each other, fused at both ends; seafoam stored light in the cleft. Never see-through.')
    K.mark('flowing_hull', 'hull', ['bevel', 'step', 'overhang'])
    hl.i8_shell(K, skin, f, XS + 0.08, XB - 0.10, 'gs1', scale=S, leaves=8, seed=4, width=1.0)
    hl.shard_cluster(K, 'S1', (2.50, 0.0, 0.0), 0.75, 0.085, spread=0.075)
    hl.stern_drive(K, 'E1', (XS + 0.22, 0.0, 0.0), 0.27)
    breaks = (-0.95,)
    breach_x = (0.35,)
    hl.insides(K, half_w, half_h, XS + 0.45, XB - 0.55, breaks, breach_x, decks=(-0.35, 0.3), frames=6)
    hk('rooms').rooms(K, half_w, half_h, XS + 0.45, XB - 0.55, breaks, breach_x, decks=(-0.35, 0.3), frames=6)   # rooms (Ryan, Nov 23)
    K.armour('annealed outer glass', 0.02, 'actual shell thickness; layered blown glass, no armour plates')
    hl.ragged_break(K, 'B1', breaks[0], 1.6, 'ragged shatter path aft of the cleft; the shard needles and the stern optic stay whole')
    K.point('core', 'hp_core', (-0.3, 0, 0.0))
    K.point('breach', 'hp_breach_0', skin(breach_x[0], theta(breach_x[0]) + 0.40), side='port', section='mid')
    for i, (x, a, side) in enumerate(((-1.9, 0.0, 'port'), (1.5, math.pi, 'stbd'))):
        K.point('rcs', 'hp_rcs_%d' % i, skin(x, a), side=side)
        K.point('board', 'hp_board_%d' % i, skin(x - 0.3, a), side=side)
    K.colour('opaque pearl ribbons, silver edges', XB, XS, 'eight long ribbons over the twisted core, two bracketing each lobe\'s crest')
    K.colour('amber, violet, green mosaic panels', XB, XS, 'the core between the ribbons; glows from within')
    K.colour('seafoam stored light', CLEFT[1], CLEFT[0], 'the cleft amidships and the grooves')
    K.colour('soft white bloom', XS + 0.2, XS - 0.2, 'stern drive optic, no flame')
    K.change('Opaque pearl ribbons over a glowing mosaic core instead of the sketch\'s clear glass',
             'R337 (Ryan, Nov 19): the Glasswright finish is opaque reflective pearl with glowing stained-glass panels; nothing see-through.')
    K.change('The cleft is a short deep groove over a core of seafoam stored light, not an opening through the ship',
             'Nothing see-through; the pick asks for a short glowing cleft with the ribbons pressed together elsewhere.')
    K.change('The lobes stay level amidships and turn about 77 degrees each way toward bow and stern',
             'Keeps one clear long axis and a leaf outline from above at the battle camera (the small-hull habit, frigate.md).')
    K.change('Shard F is three short drawn needles grown from the bow on the centreline',
             'The sketch\'s bow spikes; data.js shard fires three shots, one per needle; grown, never a tube or a crystal.')
    K.change('One stern drive optic with a white bloom and a rose-cut face', 'Family language (CD5); no flame.')


if __name__ == '__main__':
    hk('hull').main(sys.modules[__name__])
