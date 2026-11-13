# corsair_A20: Hullbreaker hulk-carrier, the Den (Ashfall Hullbreakers carrier, class Carrier, 16.5 world units; issue 633).
# Accepted picture: contrib/muse/design/class_family_corsair_2026_11/corsair_A20_beauty.jpg (v2s, accepted by Ryan Nov 12 2026,
# PR 625) and corsair_A20_sheet.jpg; designs.md is the design of record for the fittings. data.js c_hulk: turret T, turret T,
# ability launch, hangar 2. Ryan's ruling for the round: both hangar mouths are on the PORT flank (the sheet's side view is
# the layout of record; its front view's mouths either side of the intakes are a drift), and they must read as launch bays
# with depth (the Board's brief).
# Measured off the whole concept first (R229): a wide flat slab (the sheet's top view length to beam about 3.4, the beauty, the
# accepted picture, about 2.4: the build takes 2.7, the beauty's deepened hull),
# a narrower bow block carrying two big intake tubes in its face, a flat salvage deck with a spare engine bell and junk bolted
# down, a row of mismatched bells along the top of the stern, two big dark mouths low on the port flank with a fighter
# nosing out of one.
# The Board is the final designer (R233): the build keeps that mass and gives the carrier its own outline from above: the
# widest Hullbreaker for its length, a long rectangle with a narrow bow block, flat-sided, lopsided by its open port flank.
# It is never a small A16 (the barge's long body, gun rows and stern pods) or a stretched A17 (the cruiser's boxy head).
# +X bow, +Y port, +Z up. Grabber tips about x = +8.25, engine exits about x = -8.2. Flat belly z = -1.05, deck 1.0.
CODE = 'corsair_A20'
NAME = 'Hullbreaker hulk-carrier (the Den)'
FACTION = 'Ashfall Hullbreakers (corsair)'
CLASS = 'Carrier'
LENGTH = 16.5
GAME = "data.js c_hulk (cls 'Carrier'); length from godot/render/hull_table.gd CLS_LEN['Carrier'] = 16.5"
BEAUTY = 'contrib/muse/design/class_family_corsair_2026_11/corsair_A20_beauty.jpg'
CONCEPT_SHEET = 'contrib/muse/design/class_family_corsair_2026_11/corsair_A20_sheet.jpg'
CONCEPT_VIEWS = dict(top=dict(box=(180, 30, 1800, 520), largest=True, flip=False), side=dict(box=(120, 530, 1850, 830), largest=True, flip=False))
CROPS = [('bow (the bow block, intakes, port shoulder)', (40, 520, 980, 1240)), ('the port flank and the forward hangar mouth', (820, 560, 1440, 1060)),
         ('stern (the bell row and the aft deck)', (1060, 60, 1920, 620))]
SHEET = dict(version=1, round='first sheet (issue 633)', date='2026-11-12', blend='opus633\\corsair_A20',
             before='First full layout', before_note='The first complete A20 layout, built with the Hullbreaker kit and run through the check before any fix.',
             during='While designing, the check also caught (and the design fixed): see the fit report\'s fix column.')

import math, random

HB = 2.75           # the body's half-beam
DECK, BELLY = 1.0, -1.05
# the hangar block on the port flank: two mouths in a recess DEPTH deep; the core's port side is the back wall
DEPTH = 1.9
MZ0, MZ1 = -0.82, 0.55                                  # mouth floor and ceiling (low on the flank, the sheet's side view)
MOUTHS = [('H1', 1.5, 3.4, 1), ('H2', -2.4, 2.8, -1)]  # (id, centre x, length, doors slid +1 forward / -1 aft)
X_FORE, X_AFT = 3.2, -3.8                               # the hangar block's ends (mouth 1 front, mouth 2 back)
# (x, half-beam port, half-beam starboard, bottom, top, top chamfer, bottom chamfer): the body, its port side stepped in
# to the back wall of the hangar block between X_FORE and X_AFT
HULL = [
    (5.75, HB - 0.25, HB - 0.25, BELLY + 0.15, DECK - 0.1, 0.3, 0.25),
    (5.5, HB, HB, BELLY, DECK, 0.3, 0.28),
    (X_FORE + 0.02, HB, HB, BELLY, DECK, 0.3, 0.28),
    (X_FORE - 0.02, HB - DEPTH, HB, BELLY, DECK, 0.12, 0.28),
    (X_AFT + 0.02, HB - DEPTH, HB, BELLY, DECK, 0.12, 0.28),
    (X_AFT - 0.02, HB, HB, BELLY, DECK, 0.3, 0.28),
    (-7.2, HB, HB, BELLY, DECK, 0.3, 0.28),
    (-7.45, HB - 0.2, HB - 0.2, BELLY + 0.1, DECK - 0.08, 0.26, 0.24),
]
PL = dict(keep3d=True, size=(0.42, 1.05), thick=(0.05, 0.15), skip=0.08, stack=0.5, mats={'soot': 5, 'iron': 3, 'pale': 3, 'rust': 2, 'soot2': 2, 'violet': 2})
ENG = [('E1', -2.1, 0.46, 0.38, ''), ('E2', -1.06, 0.42, 0.33, ''), ('E3', 0.02, 0.44, 0.47, 'the largest'),
       ('E4', 1.1, 0.4, 0.35, 'in a violet Eclipse trophy housing'), ('E5', 2.12, 0.48, 0.4, '')]   # (id, y, z, r, note)
THR = [(6.4, 1.16, -0.25), (6.4, -1.16, -0.25), (-6.55, HB, -0.1), (-6.55, -HB, -0.1)]
LAMPS = [(5.5, HB, -0.4, 1), (-6.15, HB, -0.6, 1), (7.0, 1.22, 0.3, 1), (4.6, -HB - 0.14, -0.4, -1),
         (1.4, -HB - 0.14, -0.55, -1), (-2.75, -HB - 0.14, -0.35, -1), (-5.2, -HB - 0.14, -0.55, -1), (7.0, -1.22, 0.3, -1)]   # (x, y, z, side)
DECK_TIERS = [('D1 fore deck tier', 5.35, 2.05, -2.4, 0.7, 0.34), ('D2 mid deck tier', 1.35, -2.75, -2.5, -0.3, 0.4),
              ('D3 aft deck tier', -3.25, -6.95, -2.0, 2.1, 0.36)]                  # (name, x fore, x aft, y stbd, y port, height)


def build(K):
    import kit as _k
    from mathutils import Vector, Matrix
    HP = _k.HP
    sy = lambda x, side: _k.sec_at(HULL, x)[1 if side > 0 else 2] * side  # noqa: E731
    K.mass('Base hull (the slab, its port side stepped in at the hangar block)', K.hull(HULL, 'soot', shell=0.14, plates=dict(PL, seed=20, inv=['hull_plates', 'belly_plates'])),
           'soot and patched plate', note='the wide flat slab; between the hangar block\'s ends its port side is the back wall of the two mouths')
    K.mark('hull_form', 'hull', ['bevel', 'step', 'overhang'])
    # the bow block: narrower than the body, a little lower, the two intake tubes in its face
    K.mass('Bow block', K.loft('A20_bowblock', [(8.0, 1.0, 1.0, -0.7, 0.52, 0.18, 0.16), (7.75, 1.18, 1.18, -0.84, 0.66, 0.22, 0.2),
                                                 (5.6, 1.22, 1.22, -0.88, 0.7, 0.22, 0.2)], 'soot2', plates=dict(PL, seed=21, inv='bow_plates')),
           'dark soot', note='the narrow bow block in front of the body (the sheet\'s plan)')
    K.mark('bow_block', 'tier', ['face', 'roof', 'opening'])
    # the hangar block on the port flank: the sill under the mouths, the lintel over them, the plate between them
    x_gap0 = MOUTHS[0][1] - MOUTHS[0][2] / 2; x_gap1 = MOUTHS[1][1] + MOUTHS[1][2] / 2
    K.mass('Hangar sill', K.loft('A20_sill', [(X_FORE, HB, -(HB - DEPTH - 0.05), BELLY, MZ0, 0.0, 0.28), (X_AFT, HB, -(HB - DEPTH - 0.05), BELLY, MZ0, 0.0, 0.28)],
                                 'soot', plates=dict(PL, seed=22, faces=[5, 6, 7], inv='hangar_plates')), 'soot', note='the floor of both mouths, the belly under them')
    K.mass('Hangar lintel', K.loft('A20_lintel', [(X_FORE, HB, -(HB - DEPTH - 0.05), MZ1, DECK, 0.3, 0.0), (X_AFT, HB, -(HB - DEPTH - 0.05), MZ1, DECK, 0.3, 0.0)],
                                   'soot2', plates=dict(PL, seed=23, faces=[0, 1, 7], inv='hangar_plates')), 'dark soot', note='the roof of both mouths, the deck over them')
    K.mass('Plate between the mouths', K.loft('A20_between', [(x_gap0, HB, -(HB - DEPTH - 0.05), MZ0 - 0.02, MZ1 + 0.02, 0.0, 0.0),
                                                              (x_gap1, HB, -(HB - DEPTH - 0.05), MZ0 - 0.02, MZ1 + 0.02, 0.0, 0.0)],
                                              'iron', plates=dict(PL, seed=24, faces=[7], inv='hangar_plates', size=(0.25, 0.5))),
           'bare iron, patched', note='the plate between the two mouths (it tears first, designs.md)')
    K.mark('hangar_block', 'tier', ['face', 'roof', 'opening'])
    # the closed starboard wall: big bolted bricks, a patchwork
    for i, (x0, x1, z0, z1) in enumerate(((5.1, 3.2, -0.55, 0.45), (2.6, 0.2, -0.7, 0.3), (-0.4, -2.9, -0.5, 0.55), (-3.5, -6.6, -0.7, 0.35))):
        hw = HB
        ob = K.loft('A20_brick_%d' % i, [(x0, -(hw - 0.3), hw + 0.14, z0, z1, 0.08, 0.08), (x1, -(hw - 0.3), hw + 0.14, z0, z1, 0.08, 0.08)],
                    ('soot', 'iron', 'soot2', 'iron')[i], plates=dict(PL, seed=340 + i, faces=[2, 3, 4], size=(0.3, 0.7)))
        K.mass('Starboard brick %d' % (i + 1), ob, 'patched plate', note='armour brick on the closed starboard wall')
    K.mark('wall_bricks', 'tier', ['face', 'roof', 'opening'])
    # the salvage deck: low tiers of plate stacked on the deck, uneven
    for (nm, x0, x1, y0, y1, h) in DECK_TIERS:
        K.mass(nm, K.loft('A20_' + nm.split()[0], [(x0, y1, -y0, DECK - 0.04, DECK + h, 0.06, 0.0), (x0 - 0.15, y1, -y0, DECK - 0.04, DECK + h, 0.06, 0.0),
                                                   (x1, y1, -y0, DECK - 0.04, DECK + h, 0.06, 0.0)],
                          ('soot', 'iron', 'soot2')[DECK_TIERS.index((nm, x0, x1, y0, y1, h))], plates=dict(PL, seed=360 + int(h * 100), faces=[0, 1, 2, 3, 7], size=(0.35, 0.8))),
               'patched deck plate', note='a low tier of salvage plate on the deck, %.2f high' % h)
    K.mark('deck_tiers', 'tier', ['face', 'roof', 'opening'])
    K.mass('Stern frame', K.loft('A20_sternframe', [(-6.95, HB - 0.05, HB - 0.05, DECK - 0.4, DECK + 0.06, 0.06, 0.0), (-7.5, HB - 0.2, HB - 0.2, DECK - 0.45, DECK + 0.02, 0.06, 0.0)],
                                 'iron', plates=dict(PL, seed=380, faces=[0, 1, 2], size=(0.3, 0.6))), 'iron', note='the frame along the top of the stern the bell row hangs from')
    K.mark('stern_frame', 'pylon', ['web', 'plate'])
    # the violet Eclipse trophy housing round one bell's housing
    e4 = [e for e in ENG if e[0] == 'E4'][0]
    K.mass('Violet bell housing', K.box('A20_violet_housing', -7.75, -6.9, e4[1] - 0.42, e4[1] + 0.42, e4[2] - 0.42, e4[2] + 0.42, 'violet', ch=0.1,
                                        plates=dict(PL, seed=381, size=(0.2, 0.4), mats={'violet': 4, 'lilac': 1})),
           'violet Eclipse plate', note='a trophy housing torn from an Eclipse hull, round one bell (designs.md)')
    # flat trophies and patches on the deck and the walls
    K.patch('TP1', (-1.4, -HB - 0.141, -0.1), (0, -1, 0), 2.2, 0.62, ang=0.03, lift=0.05, t=0.06, m='pale', inv='trophy')
    K.patch('TP2', (4.1, -0.3, DECK + 0.345), (0, 0, 1), 1.0, 0.7, ang=0.2, lift=0.04, t=0.05, m='violet', inv='trophy')
    K.patch('TP3', (-5.2, 0.4, DECK + 0.365), (0, 0, 1), 1.2, 0.8, ang=-0.15, lift=0.04, t=0.05, m='pale', inv='trophy')
    K.patch('TP4', (-1.65, 1.35, DECK + 0.005), (0, 0, 1), 1.1, 0.75, ang=0.1, lift=0.04, t=0.05, m='blood', inv='trophy')
    K.patch('TP5', (6.2, 0.0, 0.705), (0, 0, 1), 0.8, 0.6, ang=0.05, lift=0.03, t=0.05, m='pale', inv='trophy')
    K.patch('TP6', (-5.4, HB + 0.005, 0.3), (0, 1, 0), 1.0, 0.45, ang=-0.04, lift=0.04, t=0.05, m='violet', inv='trophy')
    for i, (x, y, z, w, l, h) in enumerate([(4.6, -1.3, DECK + 0.34, 0.5, 0.6, 0.18), (2.7, 0.0, DECK + 0.34, 0.45, 0.5, 0.15), (-1.0, -1.15, DECK + 0.4, 0.55, 0.7, 0.2),
                                            (-2.2, -0.75, DECK + 0.4, 0.4, 0.45, 0.16), (-3.9, 1.1, DECK + 0.36, 0.5, 0.55, 0.18), (-6.3, -0.9, DECK + 0.36, 0.45, 0.6, 0.16)]):
        K.hatchbox('HB%d' % (i + 1), (x, y, z), w, l, h, inv='salvage', note='salvage locker bolted down on the deck')
    K.hatch('HS1', (5.95, -1.4, DECK - 0.03), (0, 0, 1), 0.5, 0.5, round_=True, inv='deck_hatches', note='round deck hatch at the bow end of the deck')
    K.hatch('HS2', (0.1, 1.55, DECK + 0.002), (0, 0, 1), 0.55, 0.55, inv='deck_hatches', note='square deck hatch over the hangar decks')
    for i, x in enumerate((-4.6, -5.8)):
        K.vent('VS%d' % i, (x, -HB - 0.141, 0.0) if i == 0 else (x, -HB - 0.141, -0.15), (0, -1, 0), 0.6, 0.4, slats=5, inv='vents', note='engine room louvre in the starboard wall')
    K.antenna('AN1', (-6.6, 1.5, DECK + 0.36), 1.3, whips=3, inv='antenna', note='comms array on the aft deck: calls the squadrons home')

    # the plates go on now, before the machines claim their mounts (issue 633: the kit's default keep-outs would strip the deck)
    for (x, y, z) in THR:
        K.keepouts.append((Vector((x, y, z)), 0.3))
    for p_ in ((3.6, -0.7, DECK + 0.34), (-4.9, 0.1, DECK + 0.36)):
        K.keepouts.append((Vector(p_), 0.85))
    for p_ in ((5.4, 2.1, DECK), (5.4, -2.05, DECK)):
        K.keepouts.append((Vector(p_), 0.5))
    K.keepouts.append((Vector((1.45, 1.15, DECK)), 0.95))           # the spare bell
    for (hid, xc, L, slide) in MOUTHS:                               # the back walls of the mouths stay clean round the blast door
        for k in range(3):
            K.keepouts.append((Vector((xc + L * (k - 1) / 3, HB - DEPTH, (MZ0 + MZ1) / 2)), 0.75))
    for (x, y, z, n) in LAMPS:
        K.keepouts.append((Vector((x, y, z)), 0.15))
    for side in (1, -1):                                             # the bow grabbers' shoulders and the grapples under the belly
        K.keepouts.append((Vector((6.8, 0.68 * side, -0.88)), 0.5))
        for x in (-6.85, -6.0, -5.2):
            K.keepouts.append((Vector((x, 2.1 * side, BELLY)), 0.55))
    K.finish()

    # ---------------- the hangar mouths: the dressing that makes each recess read as a launch bay with depth ----------------
    for (hid, xc, L, slide) in MOUTHS:
        part = HP.hangar_mouth(L, MZ1 - MZ0, DEPTH, slide=slide, seed=7 if slide > 0 else 11)
        K.emit(hid, part, Matrix.Translation((xc, HB, (MZ0 + MZ1) / 2)), 'hangars', keep=False)
        K.features.append(dict(id=hid, kind='hangar', what='open hangar mouth %.1f long, %.1f high, %.1f deep, doors slid %s' % (L, MZ1 - MZ0, DEPTH, 'forward' if slide > 0 else 'aft'),
                               count=1, pos=(xc, HB, (MZ0 + MZ1) / 2), aim=(90.0, 0.0), src='picture',
                               note='%s mouth on the port flank: torn plate rim, armoured doors slid clear, launch rails, a dim red lamp' % ('forward' if slide > 0 else 'aft'),
                               inv=['hangars']))
    # the craft: a fighter nosing out of the forward mouth, a second parked deeper in the aft one (the game's squadron, 1.6)
    for (cid, xc, y, var, fwd) in (('C1', 1.5, HB - 0.75, 0, (0, 1, 0)), ('C2', -2.3, HB - 0.8, 1, (-0.3, 0.954, 0))):
        part = HP.craft(1.6, variant=var)
        K.emit(cid, part, HP.frame((xc, y, MZ0), fwd, (0, 0, 1)), 'craft', keep=False)
        K.features.append(dict(id=cid, kind='craft', what='cobbled fighter, 1.6 long', count=1, pos=(xc, y, MZ0), aim=(90.0, 0.0), src='picture',
                               note='nosing out of the forward mouth' if var == 0 else 'parked deeper in the aft mouth, half refitted', inv=['craft']))
    # ---------------- the bow: two big intake tubes in the bow block's face, a chin scoop, a pair of grabbers ----------------
    for i, (y, r) in enumerate(((0.55, 0.41), (-0.55, 0.39))):
        K.tube('I%d' % (i + 1), (8.06, y, -0.06), r, 1.6, hood=0.2, bands=3, inv='intakes', what='intake tube',
               note='%s intake: the family\'s face (designs.md "two low intake tubes")' % ('port' if y > 0 else 'starboard'))
    K.tube('I3', (7.86, 0.0, -0.98), 0.11, 0.42, grille=True, bands=2, inv='scoop', what='wake-sniffer scoop with a grille', note='chin scoop (designs.md)')
    for side, fi in ((1, 'J1'), (-1, 'J2')):
        K.claw_arm(fi, (6.8, 0.68 * side, -1.3), [(7.3, 0.74 * side, -1.44), (7.64, 0.78 * side, -1.38)], w=0.34, hook=-1.0, fork=0.32,
                   inv='grabbers', housing=(6.4, 7.1, 0.68 * side - 0.22, 0.68 * side + 0.22, -1.38, -0.8),
                   note='%s grabber under the bow block' % ('port' if side > 0 else 'starboard'))
    # the heavy grapple arms, folded flat under the stern quarters, for dragging prizes alongside (designs.md)
    for side, fi in ((1, 'J3'), (-1, 'J4')):
        K.claw_arm(fi, (-6.85, 2.02 * side, -1.48), [(-5.85, 2.16 * side, -1.58), (-5.1, 2.12 * side, -1.54)], w=0.46, hook=1.0, fork=0.3,
                   inv='grapples', housing=(-7.35, -6.5, 2.02 * side - 0.3, 2.02 * side + 0.3, -1.58, -0.95),
                   note='%s grapple arm, folded flat under the stern quarter' % ('port' if side > 0 else 'starboard'))
    # ---------------- the dishes on the body's front shoulders, uneven ----------------
    K.dish('D1', (5.4, 2.1, DECK), 0.6, yaw=30, pitch=18, post=0.95, inv='dishes', note='the larger dish on the port shoulder')
    K.dish('D2', (5.4, -2.05, DECK), 0.42, yaw=-35, pitch=15, post=1.0, inv='dishes', note='the smaller dish on the starboard shoulder')
    # ---------------- the spare engine bell, bolted down flat on the deck (field repairs) ----------------
    sp = HP.engine_bell(0.5, 0.75, bell_len=0.55, body_r=0.44, rings=3, nose='flat')
    for c in sp.comps:
        if c['mat'] in ('glow', 'ember'):
            c['mat'] = 'dark'     # a spare: cold
    K.box('A20_bell_cradle', 1.1, 1.8, 1.2, 1.8, DECK - 0.02, DECK + 0.1, 'iron', ch=0.03)
    K.emit('SB1', sp, HP.frame((1.45, 0.55, DECK + 0.1 + 0.44), (0, 1, 0), (0, 0, 1)), 'spare_bell', keep=False)
    K.features.append(dict(id='SB1', kind='spare', what='spare engine bell, 1.0 across, lying across the deck in a cradle', count=1, pos=(1.45, 0.55, DECK + 0.54),
                           aim=None, src='picture', note='bolted down flat for field repairs (designs.md); cold, no glow', inv=['spare_bell']))
    # ---------------- the two dorsal turrets: data.js turret T, twice ----------------
    K.gun('T1', (3.6, -0.7, DECK + 0.34), 0, 6, barrels=2, cal=0.1, blen=1.35, size=1.0, slot='T', weapon='turret', inv='turrets',
          note='fore dorsal turret on the fore deck tier, all round')
    K.gun('T2', (-4.9, 0.1, DECK + 0.36), 0, 6, barrels=2, cal=0.095, blen=1.3, size=0.95, slot='T', weapon='turret', inv='turrets', variant=1,
          note='aft dorsal turret on the aft deck tier, all round (designs.md\'s deck gun aft)')
    # ---------------- engines: five mismatched bells in a row along the top of the stern ----------------
    for (fid, y, z, r, note) in ENG:
        K.engine(fid, (-8.23, y, z), r, 0.75, bell=1.1, rings=3 if r > 0.33 else 2, body_r=r * 1.08, nose='flat', inv='engines', src='picture',
                 note=('stern bell, ' + note) if note else 'stern bell')
    for i, (x, y, z) in enumerate(THR):
        K.thruster('Q%d' % (i + 1), (x, y, z), (0, 1 if y > 0 else -1, 0), r=0.28, inv='thrusters', note='bow' if x > 0 else 'stern')
    for i, (x, y, z, n) in enumerate(LAMPS):
        K.lamp('L%d' % i, (x, y + 0.01 * n, z), (0, n, 0), inv='lamps')

    # ---- colour zones ----
    K.colour('soot and weathered plate', 8.25, -8.25, 'whole hull')
    K.colour('pale Hegemony trophy plates', -0.3, -2.5, 'starboard wall and the aft deck')
    K.colour('violet Eclipse plate', 4.6, 3.6, 'fore deck; the violet bell housing at the stern')
    K.colour('dried-blood red patch', 0.0, -1.2, 'deck over the hangars')
    K.colour('bare iron', X_FORE, X_AFT, 'the plate between the mouths')

    # ---------- INSIDE: two hangar deck levels behind the mouths, kennels, loot holds in the bow, machinery aft ----------
    K.deck('lower', -0.12, -6.9, 5.4, inset=0.3, t=0.08)
    K.deck('upper', 0.42, -6.9, 5.4, inset=0.35, t=0.08)
    for i, x in enumerate((5.3, 3.3, 0.55, -1.75, -4.35, -6.2)):
        K.bulkhead('F%d' % i, x, inset=0.2, t=0.08)
    for (hid, xc, L, slide) in MOUTHS:
        x0, x1 = xc - L / 2 + 0.1, xc + L / 2 - 0.1
        K.room('%s_hangar_lower' % hid, 'hangar', x0, x1, -1.9, HB - DEPTH - 0.2, -0.75, -0.2, note='lower hangar deck behind the %s mouth: half-built fighters on scavenged frames' % hid)
        K.room('%s_hangar_upper' % hid, 'hangar', x0, x1, -1.9, HB - DEPTH - 0.2, -0.04, 0.4, note='upper hangar deck behind the %s mouth: bombers and spares' % hid)
    K.room('loot_hold_fore', 'hold', 5.45, 7.6, -0.8, 0.8, -0.6, 0.0, note='loot hold in the bow block (designs.md)')
    K.room('loot_hold_body', 'hold', 3.45, 5.2, -2.3, 2.3, -0.75, -0.2, note='loot hold at the front of the body')
    K.room('kennel_deck', 'crew', 3.45, 5.2, -2.3, 2.3, -0.04, 0.6, note='kennel deck for the boarding crews')
    K.room('turret_magazine_fore', 'magazine', 2.95, 4.25, -1.8, -0.1, 0.55, 0.82, note='under the fore turret')
    K.room('core', 'core', -1.5, 0.4, -2.2, 0.6, -0.75, -0.2, note='reactor core (hp_core), between the hangar decks')
    K.room('crew_decks', 'crew', -1.5, 0.4, -2.2, 0.6, -0.04, 0.6, note='crew decks over the core')
    K.room('turret_magazine_aft', 'magazine', -5.6, -4.65, -0.6, 0.8, 0.55, 0.82, note='under the aft turret')
    K.room('machinery', 'machinery', -5.9, -4.65, -2.3, 2.3, -0.75, 0.3, note='machinery aft')
    K.room('engine_room', 'engroom', -7.05, -6.35, -2.3, 2.3, -0.75, 0.6, note='engine room and the bell feeds')
    K.armour('bow block', 0.25, 'the intake face')
    K.armour('starboard wall', 0.22, 'the closed wall and its bricks')
    K.armour('hangar block', 0.12, 'thin round the mouths: the bay side tears open first (designs.md)')
    K.armour('deck', 0.12, 'the salvage tiers over it')
    K.armour('engine end', 0.15, '')
    # R226 (RULEBOOK 5.17): every seam kinks round the machines near it. B-1 (fore weld) runs between the fore turret T1 and the
    # bow's dishes, thrusters and grabbers; B-2 tears the hangar block between the mouths (the plate between them goes); B-3 (aft
    # weld) runs between mouth 2 and the aft turret T2 and the stern machines
    K.break_line('B-1', 4.75, 'the fore weld: the bow block and the front of the body tear away with the dishes and the grabbers, opening the loot holds',
                 path=[(4.85, 3.0), (4.6, 1.9), (4.8, 0.9), (4.55, 0.1), (4.75, -0.7), (4.62, -1.6), (4.82, -2.3), (4.65, -3.0)])
    K.break_line('B-2', -0.55, 'the hangar block parts between the mouths: the plate between them tears first and the craft spill (designs.md)',
                 path=[(-0.5, 3.0), (-0.65, 2.0), (-0.45, 1.0), (-0.7, 0.2), (-0.48, -0.6), (-0.68, -1.5), (-0.5, -2.3), (-0.62, -3.0)])
    K.break_line('B-3', -4.0, 'the aft weld: the stern, the bell row and the aft turret tear away, opening the machinery and the engine room',
                 path=[(-3.9, 3.0), (-4.05, 2.0), (-3.88, 1.1), (-4.08, 0.3), (-3.9, -0.5), (-4.1, -1.4), (-3.92, -2.3), (-4.05, -3.0)])
    K.inside.append(dict(kind='note', name='insides', note='Full interiors through the hull (R215), hidden until a piece breaks. The bay side tears open first, then the hull parts at the fore and aft welds: bow, hangar sections and stern, never halves (designs.md, R186).'))
    K.point('core', 'hp_core', (-0.55, -0.7, -0.45))
    for i, (x, y, z, sec, side) in enumerate([(5.2, HB, 0.25, 'prow', 'port'), (3.9, -HB, 0.3, 'prow', 'stbd'), (-0.55, HB, -0.06, 'mid', 'port'),
                                              (1.0, -HB, -0.25, 'mid', 'stbd'), (-3.2, -HB, -0.05, 'mid', 'stbd'), (-6.4, HB, 0.35, 'eng', 'port'),
                                              (-7.0, -HB, -0.45, 'eng', 'stbd')]):
        K.point('breach', 'hp_breach_%d' % i, (x, y, z), side=side, section=sec)
    K.point('rcs', 'hp_rcs_0', (6.4, 1.22, 0.0), side='port')
    K.point('rcs', 'hp_rcs_1', (6.4, -1.22, 0.0), side='stbd')
    K.point('board', 'hp_board_0', (-0.55, HB, -0.4), side='port')
    K.point('board', 'hp_board_1', (-0.9, -HB, -0.3), side='stbd')
    for i, (hid, xc, L, slide) in enumerate(MOUTHS):
        K.point('bay', 'hp_bay_%d' % i, (xc, HB - 0.3, (MZ0 + MZ1) / 2), side='port', note='launch out of the %s mouth' % hid, dir=(0, 1, 0))

    # ---------- changed from the picture (designer's decisions, R207, R233) ----------
    K.change('Both hangar mouths on the PORT flank, low, the forward one 3.4 long and the aft one 2.8, 1.37 high and 1.9 deep',
             'Ryan\'s ruling for the round (the sheet\'s side view is the layout of record; the front view\'s mouths either side of the intakes are a drift); '
             'sized between the sheet\'s side view and the beauty so a 1.6 fighter fits and they read as launch bays with depth')
    K.change('Each mouth is a real recess with a torn plate rim, armoured doors slid clear on rails, launch rails on the floor, ceiling beams, a dim red lamp, '
             'frame ribs and an inner blast door on the back wall', 'the Board\'s brief: they must read as launch bays with depth; designs.md\'s armoured doors slid open and red lamps')
    K.change('The bow block\'s front corners are closed plate, carrying the two shoulder dishes', 'the beauty\'s front openings beside the intake block are the drift Ryan ruled out; designs.md puts the dishes on the shoulders')
    K.change('The slab is 5.5 wide over its hull, about 6 over the starboard bricks (hull length to beam 2.7 on the top view) and 2.05 deep', 'the accepted beauty (v2s, "hull deepened") draws it about 2.4 long for its width, the sheet\'s top view 3.4; the build sits between, nearer the beauty (R229: the whole concept; as A17\'s head followed its beauty)')
    K.change('Two dorsal turrets, one on the fore deck tier and one on the aft', 'data.js c_hulk: turret T twice (R221); designs.md\'s bow casemates, starboard flank guns and rocket rack have no slot, so they are not built')
    K.change('Five mismatched bells in a row along the top of the stern, one in a violet Eclipse trophy housing', 'designs.md; the picture\'s eight become five')
    K.change('A fighter nosing out of the forward mouth and a second parked deeper in the aft one, both 1.6 long', 'designs.md (the forward mouth); the game\'s squadron length gives the scale')
    K.change('The spare engine bell lies across the deck in a cradle, cold', 'the picture\'s bell on the deck; designs.md: bolted down flat (field repairs)')
    K.change('The salvage deck is three low tiers of stacked plate with lockers bolted down, not loose junk', 'Ryan R185: nothing hangs off the ship; stacked and bolted scrap brick (R196, R197)')
    K.change('One pair of grabbers under the bow block and two heavy grapple arms folded flat under the stern quarters', 'designs.md (four bow arms become two, so the jaw is not A17\'s; the grapples drag prizes alongside)')
    K.change('Four attitude thrusters', 'a ship in space needs them to turn')
    K.change('Insides: two hangar deck levels behind each mouth, loot holds in the bow, a kennel deck, the core between the hangar decks, machinery and the engine room aft',
             'designs.md; R209, R215')
    K.open_item('Belly detail between the bow grabbers and the stern grapples is designed here; the picture does not show the underside')
