"""GL1, the Glasswright lancet (data.js i_blade, Destroyer). Issue 1415, Ryan's Nov 16 pick Step 1
(contrib/muse/design/glasswright_family_2026_11/destroyer.md): one slender leaf of flowing blown glass, the closest of the set
to CD5; the shards grown into the bow optic; a star torpedo carried on the keel in a glass cradle; a white bloom at the stern.

Built in the R337 finish on the shared Glasswright kit (tools/blender/kits/ithar: parts.py, stack.py, hull.py): opaque
reflective pearl ribbons with silver edges over glowing amber, violet and green mosaic. Nothing is see-through.
Replaces the Nov 1 hull I11_37 (R368).
  python THIS_FILE review TEMP_OUT
  python THIS_FILE layout TEMP_OUT docs/ship_pipeline/build_sheets/ithar_GL1
"""
import math
from pathlib import Path
import sys

sys.dont_write_bytecode = True
ROOT = Path(__file__).resolve().parents[4]
CODE = 'ithar_GL1'
SHORT = 'GL1 Lancet'
NAME = 'Glasswright lancet GL1'
PICK = 'Step 1'
FACTION = 'The Glasswrights (ithar)'
CLASS = 'Destroyer'
LENGTH = 9.5
GAME_SHIP = 'i_blade'
GAME = 'data.js i_blade (Destroyer); CLS_LEN Destroyer = 9.5, SHIP_K 1.6 = 15.2 on the board'
BEAUTY = 'contrib/muse/design/glasswright_family_2026_11/img/destroyer_lancet_s1.webp'
SHEET = dict(version=1, round='R337 / issue 1415', date='2026-11-20', stage='blockout + paint preview')
CAMERA = dict(az=62.0, el=30.0, roll=-14.0, scale=30.0)
CLOSE = dict(daz=-10, del_=8, scale=0.50, target=(0.05, 0, 0.0))
COMPARE_NOTE = ['One slender leaf: pearl ribbons sweep stern to bow over glowing panels; shards in the bow optic.',
                'Opaque (R337). The star torpedo rides the keel in a grown pearl cradle, carried, not docked.']
SIDE_NOTE = 'One long axis, about 4.5 to 1; the torpedo hangs on the keel under the forward body.'
INSIDE_NOTE = 'Two shaped glass decks, open annealed frames and three braided light cores, cut at both break lines.'

XS, XB = -4.45, 3.70
W = 1.02
S = (LENGTH / 26.0) ** 0.7
TORP = dict(x=0.35, len=2.7, r=0.31)


def hk(name):
    import importlib.util
    key = 'ithar_' + name
    if key not in sys.modules:
        spec = importlib.util.spec_from_file_location(key, ROOT / 'tools/blender/kits/ithar' / (name + '.py'))
        mod = importlib.util.module_from_spec(spec); sys.modules[key] = mod; spec.loader.exec_module(mod)
    return sys.modules[key]


def width(x):
    t = min(1.0, max(0.0, (x - XS) / (XB - XS)))
    leaf = max(0.0, math.sin(math.pi * t ** 1.30)) ** 0.85
    neck = 1.0 - 0.38 * math.exp(-((t - 0.12) / 0.07) ** 2)         # a waist before the stern bulb
    bulb = 0.42 * math.exp(-((x - XS - 0.40) / 0.42) ** 2)           # the stern bulb that carries the drive optic
    return 0.03 + W * leaf * neck + bulb


def height(x):
    return 0.74 * width(x)


def flow_phase(x):
    return 0.30 * x + 0.40 * math.sin(x * 0.6)


def skin(x, a, inset=0.0):
    """an oval leaf with broad poured ridges flowing along it (CD5 language), slightly flatter on the belly"""
    w = max(0.02, width(x) - inset)
    h = max(0.02, height(x) - inset)
    folded = math.atan2(math.sin(a), abs(math.cos(a)))
    ridge = 4 * (folded - flow_phase(x))
    flow = 1.0 + 0.10 * math.cos(ridge) + 0.025 * math.cos(2 * ridge)
    belly = 0.88 if math.sin(a) < 0 else 1.0
    return (x, w * math.cos(a) * flow, h * math.sin(a) * flow * belly)


W8 = 1.0   # R431 round 3: i8_shell ribbon width, set by the kit gate (MOSAIC_MAX)


def field():
    hl = hk('hull')
    # R431 round 3 (Ryan Nov 23, the white "more detailed and wrapping" like I8_37): the Ark's spiralling field from the kit
    return hl.i8_field(XB - XS, start=0.2, gather=hl.bow_gather(1.6, 4.0, (0.25, math.pi - 0.25, -math.pi / 2), 0.85))




def build(K):
    hl = hk('hull')
    gw = hk('parts')
    hl.material_setup(CODE, LENGTH)
    f = field()
    core = hl.mosaic_core(K, CODE + '_mosaic_core', skin, XS, XB, f.gap_of, nu=180, nv=120, thick=0.025, seed=1)
    K.mass('Mosaic leaf core', core, 'opaque glowing stained-glass mosaic',
           note='One slender leaf; amber, violet and green panels between the ribbons; never see-through.')
    K.mark('flowing_hull', 'hull', ['bevel', 'step', 'overhang'])
    # R431 round 3: the I8_37 shell from the kit (twelve fine pillowed ribbons spiralling, crossing leaves curling up)
    hl.i8_shell(K, skin, f, XS + 0.10, XB - 0.05, 'gl1', scale=S, leaves=8, seed=1, width=W8)
    hl.shard_cluster(K, 'S1', (XB - 0.35, 0.0, 0.0), 1.35, 0.12, spread=0.09,
                     note='The Prism shards grown into the bow optic: three drawn needles on the centreline; fixed forward, F arc.')
    belly = -height(TORP['x']) * 0.88
    zt = belly - TORP['r'] * 1.12
    hl.star_torpedo(K, 'T1', (TORP['x'], 0.0, zt), TORP['len'], TORP['r'], cradle_up=belly - zt + 0.10)
    hl.stern_drive(K, 'E1', (XS + 0.28, 0.0, 0.0), 0.40)
    breaks = (-2.05, 2.30)
    breach_x = (2.95, -3.05)
    hl.insides(K, lambda x: 0.70 * width(x), lambda x: 0.66 * height(x), XS + 0.6, XB - 0.7, breaks, breach_x,
               decks=(-0.35, 0.25), frames=8)
    hk('rooms').rooms(K, lambda x: 0.70 * width(x), lambda x: 0.66 * height(x), XS + 0.6, XB - 0.7, breaks, breach_x,
                      decks=(-0.35, 0.25))      # the rooms (Ryan, Nov 23): kits/ithar/rooms.py
    K.armour('annealed outer glass', 0.025, 'actual shell thickness; layered blown glass, no armour plates')
    hl.ragged_break(K, 'B1', breaks[0], 2.6, 'ragged shatter path aft of the waist; the stern optic stays whole')
    hl.ragged_break(K, 'B2', breaks[1], 2.6, 'ragged shatter path forward of the torpedo cradle; the shard optic stays whole on the bow piece')
    K.point('core', 'hp_core', (-0.4, 0, 0.0))
    K.point('breach', 'hp_breach_0', skin(breach_x[0], 0.30), side='port', section='prow')
    K.point('breach', 'hp_breach_1', skin(breach_x[1], math.pi - 0.30), side='stbd', section='eng')
    for i, (x, a, side) in enumerate(((-2.9, 0.0, 'port'), (2.2, math.pi, 'stbd'))):
        K.point('rcs', 'hp_rcs_%d' % i, skin(x, a), side=side)
        K.point('board', 'hp_board_%d' % i, skin(x - 0.5, a), side=side)
    K.colour('opaque pearl ribbons, silver edges', XB, XS, 'seven narrow ribbons and four low crest leaves sweep stern to bow')
    K.colour('amber, violet, green mosaic panels', XB, XS, 'the core between the ribbons; glows from within')
    K.colour('soft white bloom', XS + 0.3, XS - 0.3, 'stern drive optic, no flame')
    K.change('Opaque pearl ribbons over a glowing mosaic core instead of the sketch\'s clear glass',
             'R337 (Ryan, Nov 19): the Glasswright finish is opaque reflective pearl with glowing stained-glass panels; nothing see-through.')
    K.change('The bow optic is three short drawn needles on the centreline, not an open glass tube',
             'data.js shard F fires three shots, one per needle; the sketch habit of tube optics is written against (README).')
    K.change('The star torpedo hangs under the forward body in a pearl cradle of two hoops and four arms grown into the belly',
             'destroyer.md: the cradle must read as carried, not docked. The sketch\'s pod becomes the weapon itself: a glowing '
             'capsule in a pointed pearl sheath open down each flank, swept fins fore and aft (Ryan Nov 21: richer torpedo).')
    K.change('A waist before a round stern bulb; one stern optic with a white bloom and a rose-cut face',
             'The sketch\'s bottle-neck stern; family drive language from CD5; no flame.')


if __name__ == '__main__':
    hk('hull').main(sys.modules[__name__])
