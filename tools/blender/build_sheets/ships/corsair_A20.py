# corsair_A20: Hullbreaker hulk-carrier, the Den (Ashfall Hullbreakers carrier, class Carrier, 16.5 world units; issue 633).
# Accepted picture: contrib/muse/design/class_family_corsair_2026_11/corsair_A20_beauty.jpg (v2s, accepted by Ryan Nov 12 2026,
# PR 625) and corsair_A20_sheet.jpg; designs.md is the design of record for the fittings. data.js c_hulk: turret T, turret T,
# ability launch, hangar 2. Issue 633 put both hangar mouths on the PORT flank (the concept README's sheet note: the sheet's
# side view as the layout of record). Issue 651 (the Board as designer, R233, R236, after the first in-game run, Nov 13): the
# Den read as a long narrow box from above and its port-flank mouths did not read from the battle three-quarter camera, so
# the beam is broadened toward the accepted beauty and the two mouths open on the bow face either side of the bow block, as
# the beauty and the sheet's bow-on view draw them; they must read as launch bays with depth.
# Measured off the whole concept first (R229): a wide flat slab (the sheet's top view length to beam about 3.4, the beauty, the
# accepted picture, about 2.4: issue 651 takes 2.39 over the hull, the beauty's broad slab), a bow block as tall as the slab carrying two
# huge intake tubes side by side in its face, two big dark hangar mouths in the bow face beside it with a fighter nosing out
# of one, a flat salvage deck with a spare engine bell and junk bolted down, a row of mismatched bells along the top of the stern.
# The Board is the final designer (R233): the build keeps that mass and gives the carrier its own outline from above: the
# widest Hullbreaker for its length, a broad heavy slab with the bow block standing out ahead of it between the two mouths,
# flat-sided, lopsided by its uneven mouths and the armour bricks on its starboard wall only.
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
CROPS = [('bow (the bow block, intakes, port shoulder)', (40, 520, 980, 1240)), ('the bow face and the port hangar mouth', (820, 560, 1440, 1060)),
         ('stern (the bell row and the aft deck)', (1060, 60, 1920, 620))]
SHEET = dict(version=2, round='issue 651: the broad slab and the bow mouths', date='2026-11-13', blend='opus651\\corsair_A20',
             before='First full layout', before_note='The first complete A20 layout, built with the Hullbreaker kit and run through the check before any fix.',
             during='While designing, the check also caught (and the design fixed): see the fit report\'s fix column.')

import math, random

HB = 3.45           # the body's half-beam (issue 651: was 2.75; the slab is 6.9 wide over its hull)
DECK, BELLY = 1.0, -1.05
# the two hangar mouths in the bow face (issue 651), one either side of the bow block: each a recess from the face X_MF back
# to its back wall at X_MB, between the core (half-beam HC, wider than the bow block) and an outer cheek CHEEK thick
HC = 1.85            # the core's half-beam between the mouths (the bow block is 1.62: the mouth rims need the step)
X_MF, X_MB = 5.7, 2.7  # the mouths' face and back wall: 3.0 deep, 2.7 to the inner blast door
LINER = 0.3          # the dark liner slab on the back wall
MZ0, MZ1 = -0.86, 0.72                                  # mouth floor and ceiling: three quarters of the face's height (the beauty)
CHEEK = {1: 0.22, -1: 0.3}                              # the outer wall of each mouth (port thin, starboard under its bricks)
MOUTHS = [('H1', 1), ('H2', -1)]                        # (id, side): H1 the port mouth (the fighter noses out), H2 starboard
def mouth_y(side):
    # (inner y, outer y, centre y, width) of a mouth: port 1.85 to 3.23 (1.38 wide), starboard 1.85 to 3.15 (1.3)
    yi, yo = side * HC, side * (HB - CHEEK[side])
    return yi, yo, (yi + yo) / 2, abs(yo - yi)
# (x, half-beam port, half-beam starboard, bottom, top, top chamfer, bottom chamfer): the body; forward of the mouths' back
# wall it is the core between the mouths, the sill, the lintel and the cheeks (masses below) close each mouth round
HULL = [
    (5.75, HC - 0.1, HC - 0.1, BELLY + 0.15, DECK - 0.1, 0.12, 0.25),
    (5.5, HC, HC, BELLY, DECK, 0.12, 0.28),
    (X_MB + 0.02, HC, HC, BELLY, DECK, 0.12, 0.28),
    (X_MB - 0.02, HB, HB, BELLY, DECK, 0.3, 0.28),
    (-7.2, HB, HB, BELLY, DECK, 0.3, 0.28),
    (-7.45, HB - 0.2, HB - 0.2, BELLY + 0.1, DECK - 0.08, 0.26, 0.24),
]
PL = dict(keep3d=True, courses=True, size=(0.4, 0.9), thick=(0.035, 0.08), step=0.045, gap=0.03, over=0.22, skip=0.05, stack=0.22, rivets_share=0.3, mats={'soot': 4, 'iron': 3, 'pale': 3, 'rust': 2, 'soot2': 2, 'violet': 2, 'steel': 2})
ENG = [('E1', -2.1, 0.46, 0.38, ''), ('E2', -1.06, 0.42, 0.33, ''), ('E3', 0.02, 0.44, 0.47, 'the largest'),
       ('E4', 1.1, 0.4, 0.35, 'in a violet Eclipse trophy housing'), ('E5', 2.12, 0.48, 0.4, '')]   # (id, y, z, r, note)
THR = [(6.6, 1.61, -0.6), (6.6, -1.61, -0.6), (-6.55, HB, -0.1), (-6.55, -HB, -0.1)]
LAMPS = [(5.2, HB, -0.45, 1), (-6.15, HB, -0.6, 1), (7.0, 1.595, 0.3, 1), (4.6, -HB - 0.14, -0.4, -1),
         (1.4, -HB - 0.14, -0.55, -1), (-2.75, -HB - 0.14, -0.35, -1), (-5.2, -HB - 0.14, -0.55, -1), (7.0, -1.595, 0.3, -1)]   # (x, y, z, side)
DECK_TIERS = [('D1 fore deck tier', 5.35, 2.05, -1.95, 0.9, 0.34), ('D2 mid deck tier', 1.35, -2.75, -3.2, -0.3, 0.4),
              ('D3 aft deck tier', -3.25, -6.95, -2.6, 2.7, 0.36)]                  # (name, x fore, x aft, y stbd, y port, height)


def build(K):
    import kit as _k
    from mathutils import Vector, Matrix
    HP = _k.HP
    sy = lambda x, side: _k.sec_at(HULL, x)[1 if side > 0 else 2] * side  # noqa: E731
    # the mouths' inner walls are the core's flanks: no hull plate there (the dark liner covers them; issue 651)
    for side in (1, -1):
        for k in range(7):
            for z_ in (-0.45, 0.35):
                K.keepouts.append((Vector((X_MB + 0.25 + k * 0.45, side * (HC + 0.3), z_)), 0.45))
    K.mass('Base hull (the slab, its core between the two bow mouths)', K.hull(HULL, 'soot', shell=0.14, plates=dict(PL, seed=20, inv=['hull_plates', 'belly_plates'])),
           'soot and patched plate', note='the broad flat slab; forward of the mouths\' back wall it is the core between the two mouths')
    K.mark('hull_form', 'hull', ['bevel', 'step', 'overhang'])
    # the bow block: narrower than the body, a little lower, the two intake tubes in its face
    K.mass('Bow block', K.loft('A20_bowblock', [(8.0, 1.5, 1.5, -1.0, 0.8, 0.22, 0.2), (7.8, 1.58, 1.58, -1.05, 0.86, 0.26, 0.22),
                                                 (5.3, 1.62, 1.62, -1.05, 0.9, 0.26, 0.22)], 'soot2', plates=dict(PL, seed=21, inv='bow_plates')),
           'dark soot', note='the bow block in front of the body, as tall as the slab and about half its beam: a housing for the two huge intake tubes (the beauty)')
    K.mark('bow_block', 'tier', ['face', 'roof', 'opening'])
    # the two hangar blocks either side of the core (issue 651): per mouth the sill under it, the lintel over it and the outer
    # cheek, from the bow face back into the full-beam body; the core's flank is each mouth's inner wall
    for (hid, side) in MOUTHS:
        yi, yo, yc, W = mouth_y(side)
        sd = 'port' if side > 0 else 'starboard'
        # a loft section takes (port half-beam, starboard half-beam): the block spans from just inside the core to the hull side
        span = (HB, -(HC - 0.05)) if side > 0 else (-(HC - 0.05), HB)
        fs = (lambda pf, sf: pf if side > 0 else sf)
        K.mass('Hangar sill, %s' % sd, K.loft('A20_sill_%s' % hid, [(X_MF, span[0], span[1], BELLY + 0.06, MZ0, 0.0, 0.22), (X_MF - 0.1, span[0], span[1], BELLY, MZ0, 0.0, 0.28),
                                                                  (X_MB - 0.05, span[0], span[1], BELLY, MZ0, 0.0, 0.28)],
                                         'soot', plates=dict(PL, seed=22 + (side < 0) * 10, faces=fs([5, 6, 7], [3, 4, 5]), inv='hangar_plates')),
               'soot', note='the floor of the %s mouth, the belly under it' % sd)
        K.mass('Hangar lintel, %s' % sd, K.loft('A20_lintel_%s' % hid, [(X_MF, span[0], span[1], MZ1, DECK - 0.06, 0.24, 0.0), (X_MF - 0.1, span[0], span[1], MZ1, DECK, 0.3, 0.0),
                                                                      (X_MB - 0.05, span[0], span[1], MZ1, DECK, 0.3, 0.0)],
                                           'soot2', plates=dict(PL, seed=23 + (side < 0) * 10, faces=fs([0, 1, 7], [1, 2, 3]), inv='hangar_plates')),
               'dark soot', note='the roof of the %s mouth, the deck over it' % sd)
        ch = (HB, -(HB - CHEEK[side])) if side > 0 else (-(HB - CHEEK[side]), HB)
        K.mass('Hangar cheek, %s' % sd, K.loft('A20_cheek_%s' % hid, [(X_MF, ch[0], ch[1], MZ0 - 0.02, MZ1 + 0.02, 0.0, 0.0),
                                                                    (X_MB - 0.05, ch[0], ch[1], MZ0 - 0.02, MZ1 + 0.02, 0.0, 0.0)],
                                         'iron', plates=dict(PL, seed=24 + (side < 0) * 10, faces=fs([7], [3]), inv='hangar_plates', size=(0.25, 0.5))),
               'bare iron, patched', note='the outer wall of the %s mouth' % sd)
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
    for p_ in ((5.2, 2.55, DECK), (5.2, -2.5, DECK)):
        K.keepouts.append((Vector(p_), 0.5))
    K.keepouts.append((Vector((1.45, 1.15, DECK)), 0.95))           # the spare bell
    for (x, y, z, n) in LAMPS:
        K.keepouts.append((Vector((x, y, z)), 0.15))
    for side in (1, -1):                                             # the bow grabbers' shoulders and the grapples under the belly
        K.keepouts.append((Vector((6.8, 0.68 * side, -1.05)), 0.45))
        for x in (-6.85, -6.0, -5.2):
            K.keepouts.append((Vector((x, 2.6 * side, BELLY)), 0.55))
    K.finish()

    # ---------------- the hangar mouths: the dressing that makes each recess read as a launch bay with depth ----------------
    # issue 651: both mouths open forward in the bow face, either side of the bow block (the beauty, the sheet's bow-on view)
    D_ = X_MF - X_MB
    for (hid, side) in MOUTHS:
        yi, yo, yc, W = mouth_y(side)
        y0_, y1_ = min(yi, yo), max(yi, yo)
        # the dark liner of the recess (issue 633 round 2: the mouths must read as big, deep, dark openings): soot-black floor,
        # ceiling, back wall and side walls, so the key light that falls into a mouth finds no grey plate, only the rails, ribs,
        # lamps and the fighter. The back liner is a 0.3 slab on the body's plated front face, so the mouth is 2.7 deep to its
        # blast door
        K.box('A20_%s_liner_back' % hid, X_MB, X_MB + LINER, y0_, y1_, MZ0, MZ1, 'dark')
        K.box('A20_%s_liner_roof' % hid, X_MB + LINER, X_MF - 0.03, y0_, y1_, MZ1 - 0.025, MZ1 + 0.005, 'dark')
        K.box('A20_%s_liner_floor' % hid, X_MB + LINER, X_MF - 0.03, y0_, y1_, MZ0 - 0.005, MZ0 + 0.012, 'dark')
        for ye, d_ in ((y0_, 1), (y1_, -1)):
            K.box('A20_%s_liner_wall%d' % (hid, d_ > 0), X_MB + LINER, X_MF - 0.03, min(ye, ye + d_ * 0.025), max(ye, ye + d_ * 0.025), MZ0, MZ1, 'dark')
        # the kit's mouth part in its own frame (+X along the mouth, +Y out of the face): turned so +Y is the bow (+X); no
        # door leaves, there is no face beside a bow mouth for them to slide onto
        part = HP.hangar_mouth(W, MZ1 - MZ0, D_ - LINER, slide=1, seed=7 if side > 0 else 11, doors=False)
        K.emit(hid, part, Matrix.Translation((X_MF, yc, (MZ0 + MZ1) / 2)) @ Matrix.Rotation(-math.pi / 2, 4, 'Z'), 'hangars', keep=False)
        K.features.append(dict(id=hid, kind='hangar', what='open hangar mouth %.2f wide, %.2f high, %.1f deep, in the bow face' % (W, MZ1 - MZ0, D_),
                               count=1, pos=(X_MF, yc, (MZ0 + MZ1) / 2), aim=(0.0, 0.0), src='picture',
                               note='%s mouth in the bow face beside the bow block: torn plate rim, launch rails, ceiling beams, a dim red lamp, an inner blast door' % ('port' if side > 0 else 'starboard'),
                               inv=['hangars']))
    # the craft: a fighter nosing out of the port mouth, a second parked deeper in the starboard one (the game's squadron, 1.6);
    # each set off the mouth's centre toward its shorter wing so both wings clear the wall ribs
    for (cid, side, x, var) in (('C1', 1, X_MF - 0.5, 0), ('C2', -1, X_MB + LINER + 1.05, 1)):
        yi, yo, yc, W = mouth_y(side)
        part = HP.craft(1.6, variant=var)
        K.emit(cid, part, HP.frame((x, yc - 0.05, MZ0), (1, 0, 0), (0, 0, 1)), 'craft', keep=False)
        K.features.append(dict(id=cid, kind='craft', what='cobbled fighter, 1.6 long', count=1, pos=(x, yc - 0.05, MZ0), aim=(0.0, 0.0), src='picture',
                               note='nosing out of the port mouth' if var == 0 else 'parked deeper in the starboard mouth, half refitted', inv=['craft']))
    # ---------------- the bow: two big intake tubes in the bow block's face, a chin scoop, a pair of grabbers ----------------
    for i, (y, r) in enumerate(((0.73, 0.56), (-0.73, 0.54))):
        K.tube('I%d' % (i + 1), (8.13, y, -0.12), r, 2.25, hood=0.18, bands=3, inv='intakes', what='intake tube',
               note='%s intake: the family\'s face (designs.md "two low intake tubes")' % ('port' if y > 0 else 'starboard'))
        # a soot-black liner down the bore, so each mouth reads as a deep dark hole from the beauty camera (round 2)
        K.cyl('A20_I%d_liner' % (i + 1), (8.07, y, -0.12), (6.05, y, -0.12), r * 0.985, 'dark', cap=False)
    # the bow face round the tubes: torn plates bolted over the block's face, not one smooth plane (round 2)
    for k, (y, z, w, h, m) in enumerate(((0.0, 0.66, 1.9, 0.22, 'iron'), (1.42, 0.3, 0.22, 0.62, 'soot2'), (-1.42, 0.25, 0.22, 0.7, 'rust'),
                                          (0.95, -0.95, 0.75, 0.16, 'soot2'), (-0.9, -0.95, 0.7, 0.16, 'iron'), (0.0, 0.42, 0.24, 0.3, 'pale'))):
        K.patch('FP%d' % k, (8.0, y, z), (1, 0, 0), w, h, ang=0.02 * (k - 2), lift=0.02, t=0.05, m=m, inv='bow_plates')
    K.tube('I3', (8.1, 0.0, -0.86), 0.1, 0.42, grille=True, bands=2, inv='scoop', what='wake-sniffer scoop with a grille', note='chin scoop (designs.md)')
    for side, fi in ((1, 'J1'), (-1, 'J2')):
        K.claw_arm(fi, (6.8, 0.68 * side, -1.42), [(7.3, 0.74 * side, -1.56), (7.64, 0.78 * side, -1.5)], w=0.34, hook=-1.0, fork=0.32,
                   inv='grabbers', housing=(6.4, 7.1, 0.68 * side - 0.22, 0.68 * side + 0.22, -1.5, -0.95),
                   note='%s grabber under the bow block' % ('port' if side > 0 else 'starboard'))
    # the heavy grapple arms, folded flat under the stern quarters, for dragging prizes alongside (designs.md)
    for side, fi in ((1, 'J3'), (-1, 'J4')):
        K.claw_arm(fi, (-6.85, 2.52 * side, -1.48), [(-5.85, 2.66 * side, -1.58), (-5.1, 2.62 * side, -1.54)], w=0.46, hook=1.0, fork=0.3,
                   inv='grapples', housing=(-7.35, -6.5, 2.52 * side - 0.3, 2.52 * side + 0.3, -1.58, -0.95),
                   note='%s grapple arm, folded flat under the stern quarter' % ('port' if side > 0 else 'starboard'))
    # ---------------- the dishes on the body's front shoulders, uneven ----------------
    K.dish('D1', (5.2, 2.55, DECK), 0.6, yaw=30, pitch=18, post=0.95, inv='dishes', note='the larger dish on the port shoulder, over the port mouth')
    K.dish('D2', (5.2, -2.5, DECK), 0.42, yaw=-35, pitch=15, post=1.0, inv='dishes', note='the smaller dish on the starboard shoulder, over the starboard mouth')
    # ---------------- the spare engine bell, bolted down flat on the deck (field repairs) ----------------
    sp = HP.spare_bell(0.5, 0.75, bell_len=0.55, body_r=0.44, rings=3, nose='flat')     # cold: its throat and lining dark (kit)
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
    K.colour('bare iron', X_MF, X_MB, 'the outer walls of the two bow mouths')

    # ---------- INSIDE: two hangar deck levels behind the mouths, kennels, loot holds in the bow, machinery aft ----------
    # each deck in two lengths, the core between the mouths and the full-beam body behind them (a deck loft samples three
    # stations, so one deck across the step at the back wall would reach into the mouths)
    K.deck('lower', -0.12, -6.9, X_MB - 0.1, inset=0.3, t=0.08)
    K.deck('upper', 0.42, -6.9, X_MB - 0.1, inset=0.35, t=0.08)
    K.deck('lower_fore', -0.12, X_MB + 0.1, 5.4, inset=0.3, t=0.08)
    K.deck('upper_fore', 0.42, X_MB + 0.1, 5.4, inset=0.35, t=0.08)
    for i, x in enumerate((5.3, 3.3, 0.55, -1.75, -4.35, -6.2)):
        K.bulkhead('F%d' % i, x, inset=0.2, t=0.08)
    for (hid, side) in MOUTHS:
        y0_, y1_ = sorted((side * 0.25, side * (HB - 0.4)))
        K.room('%s_hangar_lower' % hid, 'hangar', 0.7, 2.05, y0_, y1_, -0.75, -0.2, note='lower hangar deck behind the %s mouth: half-built fighters on scavenged frames' % hid)
        K.room('%s_hangar_upper' % hid, 'hangar', 0.7, 2.05, y0_, y1_, -0.04, 0.4, note='upper hangar deck behind the %s mouth: bombers and spares' % hid)
    K.room('loot_hold_fore', 'hold', 5.45, 7.6, -0.8, 0.8, -0.6, 0.0, note='loot hold in the bow block (designs.md)')
    K.room('loot_hold_body', 'hold', 3.45, 5.2, -(HC - 0.35), HC - 0.35, -0.75, -0.2, note='loot hold in the core between the mouths')
    K.room('kennel_deck', 'crew', 3.45, 5.2, -(HC - 0.35), HC - 0.35, -0.04, 0.6, note='kennel deck for the boarding crews, in the core between the mouths')
    K.room('turret_magazine_fore', 'magazine', 2.95, 4.25, -(HC - 0.35), -0.1, 0.55, 0.82, note='under the fore turret')
    K.room('core', 'core', -1.5, 0.4, -2.2, 0.6, -0.75, -0.2, note='reactor core (hp_core), between the hangar decks')
    K.room('crew_decks', 'crew', -1.5, 0.4, -2.2, 0.6, -0.04, 0.6, note='crew decks over the core')
    K.room('turret_magazine_aft', 'magazine', -5.6, -4.65, -0.6, 0.8, 0.55, 0.82, note='under the aft turret')
    K.room('machinery', 'machinery', -5.9, -4.65, -2.9, 2.9, -0.75, 0.3, note='machinery aft')
    K.room('engine_room', 'engroom', -7.05, -6.35, -2.9, 2.9, -0.75, 0.6, note='engine room and the bell feeds')
    K.armour('bow block', 0.25, 'the intake face')
    K.armour('starboard wall', 0.22, 'the closed wall and its bricks')
    K.armour('hangar blocks', 0.12, 'thin round the two bow mouths: the bay frames tear open first (designs.md)')
    K.armour('deck', 0.12, 'the salvage tiers over it')
    K.armour('engine end', 0.15, '')
    # R226 (RULEBOOK 5.17): every seam kinks round the machines near it. B-1 (fore weld, issue 651: moved aft to the mouths'
    # back wall) runs between the spare bell and the fore turret T1, so the bow, both mouths and their craft go as one piece;
    # B-2 parts the body behind the hangar decks, through the core; B-3 (aft weld) runs between the aft turret T2 and the
    # stern machines
    K.break_line('B-1', 2.27, 'the fore weld behind the mouths: the bow block and both hangar mouths tear away with the dishes, the grabbers and the craft, opening the loot holds and the hangar decks',
                 path=[(2.3, 4.2), (2.3, 3.0), (2.2, 2.0), (2.35, 1.0), (2.18, 0.2), (2.32, -0.6), (2.2, -1.5), (2.36, -2.3), (2.25, -3.0), (2.25, -4.2)])
    K.break_line('B-2', -0.55, 'the body parts behind the hangar decks, through the core: the bay side tears first and the hangar decks spill (designs.md)',
                 path=[(-0.5, 4.2), (-0.5, 3.0), (-0.65, 2.0), (-0.45, 1.0), (-0.7, 0.2), (-0.48, -0.6), (-0.68, -1.5), (-0.5, -2.3), (-0.62, -3.0), (-0.62, -4.2)])
    K.break_line('B-3', -4.0, 'the aft weld: the stern, the bell row and the aft turret tear away, opening the machinery and the engine room',
                 path=[(-3.9, 4.2), (-3.9, 3.0), (-4.05, 2.0), (-3.88, 1.1), (-4.08, 0.3), (-3.9, -0.5), (-4.1, -1.4), (-3.92, -2.3), (-4.05, -3.0), (-4.05, -4.2)])
    # issue 633 recipe (as C10 and C11, issue 623): each seam path runs straight on past the flanks to 4.2 off the axis; a path
    # that stopped at 3.0, inside the widest parts (3.1), tore the starboard rooms apart from their plating in the death check
    K.inside.append(dict(kind='note', name='insides', note='Full interiors through the hull (R215), hidden until a piece breaks. The bay side tears open first, then the hull parts at the fore and aft welds: bow, hangar sections and stern, never halves (designs.md, R186).'))
    K.point('core', 'hp_core', (-0.55, -0.7, -0.45))
    for i, (x, y, z, sec, side) in enumerate([(4.3, HB, 0.2, 'prow', 'port'), (3.9, -HB, 0.3, 'prow', 'stbd'), (-0.65, HB, -0.06, 'mid', 'port'),
                                              (1.0, -HB, -0.25, 'mid', 'stbd'), (-3.2, -HB, -0.05, 'mid', 'stbd'), (-6.4, HB, 0.35, 'eng', 'port'),
                                              (-7.0, -HB, -0.45, 'eng', 'stbd')]):
        K.point('breach', 'hp_breach_%d' % i, (x, y, z), side=side, section=sec)
    K.point('rcs', 'hp_rcs_0', (6.6, 1.61, -0.6), side='port')
    K.point('rcs', 'hp_rcs_1', (6.6, -1.61, -0.6), side='stbd')
    K.point('board', 'hp_board_0', (-0.65, HB, -0.4), side='port')
    K.point('board', 'hp_board_1', (-0.9, -HB, -0.3), side='stbd')
    for i, (hid, side) in enumerate(MOUTHS):
        yi, yo, yc, W = mouth_y(side)
        K.point('bay', 'hp_bay_%d' % i, (X_MF - 0.2, yc, MZ0 + 0.012), side='port' if side > 0 else 'stbd',
                note='launch forward out of the %s mouth, on its floor at the lip (the recipe: a hard point sits on the mesh, the mouth itself is open air)' % hid, dir=(1, 0, 0))

    # ---------- changed from the picture (designer's decisions, R207, R233) ----------
    K.change('Issue 651: the beam broadened from 5.5 to 6.9 over the hull (6.19 to 7.55 overall, across the stern thrusters; length to beam on the top view 3.0 to 2.39 over the hull, 2.67 to 2.19 overall), the length kept at the class length 16.5, the height kept',
             'the Board as designer (R233, R236), after the first in-game run (Nov 13, C16s_23 at the top and three-quarter cameras): from above the Den read as a long narrow box, while its accepted beauty is a broad flat slab (about 2.4 long for its width). The sheet\'s top view (3.4) is the narrower drawing; the beauty is the accepted picture')
    K.change('Issue 651: both hangar mouths open forward in the bow face, one either side of the bow block (port 1.38 wide, starboard 1.3; 1.58 high, three quarters of the face; 3.0 deep to the back wall, 2.7 to the blast door), framed by a sill, a lintel and an outer cheek each; the port flank is closed plate now',
             'the Board as designer (R233, R236): the beauty and the sheet\'s bow-on view draw the two mouths in the bow face beside the twin tubes with a craft visible inside, and from the battle three-quarter camera the port-flank mouths of issue 633 did not read (the in-game shot shows the tubes, not the mouths). '
             'This reverses issue 633\'s layout, which took the sheet\'s side view as the layout of record (the concept README\'s note, recorded there as Ryan\'s ruling); data.js c_hulk (launch, hangar 2) is met either way, and a carrier that faces its target launches straight at it')
    K.change('Each mouth is a real recess with a torn plate rim, launch rails on the floor, ceiling beams, a dim red lamp, frame ribs and an inner blast door on the back wall; no door leaves (issue 651)',
             'the Board\'s brief: they must read as launch bays with depth; in the bow face there is no face beside a mouth for designs.md\'s slid doors (the bow block stands there), so the kit part leaves them out (hangar_mouth doors=False)')
    K.change('The mouths are lined dark (floor, ceiling, back wall and ends): only the rails, ribs, red lamps and the fighters catch the light',
             'the Board on round 1 (Nov 13): the mouths must be big, deep, dark openings that show from the beauty camera with the fighter in them; round 1\'s were 1.37 high and lit grey inside, so they read as shallow grilles')
    K.change('The bow block is as tall as the slab and about half its beam (3.2 across, 1.9 tall, 2.7 long); its face carries two huge intake tubes side by side, each 1.1 across (three quarters of the face\'s height), reaching 2.3 back into the block',
             'the Board on round 1 (Nov 13): the build had no twin tubes (two 0.8 tubes in a narrow block); the README\'s bow intakes and the beauty\'s two huge tubes. The concept sheet\'s plan draws the block about 0.4 of the beam; it is widened so the tubes fit side by side')
    K.change('Bow thrusters and the bow lamps on the bow block\'s flanks, the chin scoop under the web between the tubes', 'the wider block and its tubes fill the old places')
    K.change('The two shoulder dishes stand on the lintels over the mouths', 'designs.md puts the dishes on the shoulders; the mouths took the shoulders\' faces (issue 651)')
    K.change('The slab is 6.9 wide over its hull, 7.55 overall across the stern thrusters (length to beam 2.39 over the hull on the top view) and 2.05 deep', 'the accepted beauty (v2s, "hull deepened") draws it about 2.4 long for its width, the sheet\'s top view 3.4; issue 651 takes the beauty\'s broad slab (R229: the whole concept; R233, R236)')
    K.change('Two dorsal turrets, one on the fore deck tier and one on the aft', 'data.js c_hulk: turret T twice (R221); designs.md\'s bow casemates, starboard flank guns and rocket rack have no slot, so they are not built')
    K.change('Five mismatched bells in a row along the top of the stern, one in a violet Eclipse trophy housing', 'designs.md; the picture\'s eight become five')
    K.change('A fighter nosing out of the port mouth and a second parked deeper in the starboard one, both 1.6 long', 'designs.md and the beauty (the fighter in the near mouth); the game\'s squadron length gives the scale')
    K.change('The spare engine bell lies across the deck in a cradle, cold', 'the picture\'s bell on the deck; designs.md: bolted down flat (field repairs)')
    K.change('The salvage deck is three low tiers of stacked plate with lockers bolted down, not loose junk', 'Ryan R185: nothing hangs off the ship; stacked and bolted scrap brick (R196, R197)')
    K.change('One pair of grabbers under the bow block and two heavy grapple arms folded flat under the stern quarters', 'designs.md (four bow arms become two, so the jaw is not A17\'s; the grapples drag prizes alongside)')
    K.change('Four attitude thrusters', 'a ship in space needs them to turn')
    K.change('The fore weld B-1 moved aft to x 2.3, behind the mouths\' back wall (issue 651; was 4.75)', 'with the mouths in the bow face a weld at 4.75 would cut through both mouths and the port fighter; the bow, both mouths and their craft now tear away as one piece (designs.md: the bay side tears first)')
    K.change('Every face is plated in courses at the hull\'s plate size (0.4 to 0.9), each course jointed on its own (a brick bond), patches laid over joints and offset patches over plates; upward faces stepped in terraces of one to three plate thicknesses',
             'the Board on round 1 (Nov 13): the faces read as big smooth grey planes with a few greebles; the concept is scrap brick, plates over plates on every face (R196, R197). Kit: the sheet kit\'s courses plating (kit.py, opt-in, issue 633)')

    K.change('Insides: two hangar deck levels behind each mouth, loot holds in the bow and in the core between the mouths, a kennel deck, the core between the hangar decks, machinery and the engine room aft',
             'designs.md; R209, R215')
    K.open_item('Belly detail between the bow grabbers and the stern grapples is designed here; the picture does not show the underside')
