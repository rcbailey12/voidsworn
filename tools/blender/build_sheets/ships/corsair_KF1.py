"""corsair_KF1: the Hullbreaker fighter, the Narrow Glacis (data.js fighter: cls 'Squadron', guns T; hp 20, sp 7).

Issue 1373 (R362: anything solid near a ship is built from the ship part kits and takes the hull finish). The Hullbreakers fly
fighters only in the adaptive enemy wings (rules.gd adaptWings: "launched a fighter wing to hunt your craft"), and the game drew
a code-built box for them. KF1 is the fighter of Ryan's accepted bomber KB1CC (R259, R273): the same glacis ramp, rails,
armoured lip and patchwork plating, without the wide shoulders and bomb barrels, so it reads as the light craft of the same
family. Two cannon booms reach past the bow (port longer), one twin turret sits centred on the ramp, the vision slit off to starboard (lopsided, factions.md). Nothing hung
under the hull, no canopy, no wings (R254). Size 1.6 (scale.md Squadron row), +X bow.
  blender -b -P tools/blender/build_sheets/build.py -- corsair_KF1 OUT render
"""
import importlib.util
import os
from pathlib import Path

_spec = importlib.util.spec_from_file_location('corsair_KB1CC_for_KF1', Path(__file__).with_name('corsair_KB1CC.py'))
F = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(F)

CODE = 'corsair_KF1'
NAME = 'Narrow Glacis fighter (Ashfall Hullbreaker fighter wing craft, the KB1CC family)'
FACTION = F.FACTION
CLASS = F.CLASS
LENGTH = 1.6   # a plain number: stage 6 reads it without running the sheet (ship.py sheet_length); the same as F.LENGTH
GAME = "data.js fighter (cls 'Squadron', the Hullbreaker adaptive fighter wing); length from godot/render/hull_table.gd CLS_LEN['Squadron'] = 1.6 (drawn x SHIP_K 1.6 x SQUADRON_K 1.5 = 3.84 on the board, docs/playbooks/scale.md)"
BEAUTY = F.BEAUTY
KIT = 'hullbreakers'
CONCEPT_SHEET = F.CONCEPT_SHEET
SHEET = dict(F.SHEET, version=1, round='first sheet (issue 1373, the KB1CC family\'s fighter)', date='2026-11-20', blend='opus1373',
             blend_where='built in the issue 1373 cloud thread (Blender 4.5 bpy wheel, Cycles CPU); `build.py corsair_KF1 <out> render` rebuilds it from this file',
             before='KB1CC', before_note='The accepted Hullbreaker bomber\'s glacis body, narrowed to a fighter, with a salvaged twin gun in place of the bomb barrels.')
U = F.U
sec = F.sec

# the fighter's body: the bomber's glacis loft at about two thirds of its beam and a touch lower (n, half-beam, belly, top, chamfers)
BODY = [(n, hw * 0.62, zb * 0.9, zt * 0.85, ct, cb) for (n, hw, zb, zt, ct, cb) in F.BODY]
X_END = F.X_END
GX, GY = -0.14, 0.045      # the gun's station: on the level deck above the ramp, off to port
SLIT_Y = -0.03             # the vision slit, off to starboard


def top(n):
    return U(sec(BODY, n)[3])


def build(K):
    import kit as _k
    from mathutils import Vector
    HP = _k.HP
    sp = importlib.util.spec_from_file_location('hb_craft', os.path.join(_k._KITS, 'hullbreakers', 'craft.py'))
    CR = importlib.util.module_from_spec(sp); sp.loader.exec_module(CR)
    CR.install(HP)
    K.hull_sections = [(U(r[0]), U(r[1]), U(r[1]), U(r[2]), U(r[3]), U(r[4]), U(r[5])) for r in BODY]
    PL = dict(size=(U(0.08), U(0.19)), thick=(U(0.002), U(0.0045)), gap=U(0.0016), skip=0.0, turn=12.0, hard=0.35, stack=0.45,
              rivets_share=0.07, rivet_r=U(0.0018),
              # Ryan, Nov 21 2026: "it's ALL red compared to the patchy colors of the rest": the capitals' plate mix (A18, A19):
              # red plate, grey salvaged trophy plates and a few violet ones over a dark steel body. The faction register paints soot and
              # iron red (R306), so the grey and violet come from steel, pale and violet here.
              mats={'rust': 3, 'blood': 3, 'steel': 2, 'pale': 4, 'violet': 2})
    PATCH = []
    ns = sorted({r[0] for r in BODY} | {round(0.46 - 0.04 * i, 3) for i in range(24) if 0.46 - 0.04 * i > X_END}, reverse=True)
    bsecs = [(U(r[0]), U(r[1]), U(r[1]), U(r[2]), U(r[3]), U(r[4]), U(r[5])) for r in [sec(BODY, n) for n in ns]]
    body = K.loft(CODE + '_body', bsecs, 'steel', shell=U(0.004))
    brings = [[(s_[0], y, z) for (y, z) in _k._octa(*s_[1:7])] for s_ in bsecs]
    PATCH.append((CODE + '_body', brings, dict(PL, seed=17, faces=[5], inv=['belly_plates'])))
    # the deck around the guns and lockers: plates small enough to fit between them
    PATCH.append((CODE + '_deck', brings, dict(PL, seed=19, faces=[1], size=(U(0.05), U(0.12)), inv=['glacis_plates'])))
    # the flanks and chamfers are low, so the deck's plate size left few cells and wide bare gaps (Ryan, Nov 21: "it looks
    # unfinished with the lack of plates"): smaller plates there, so the whole flank is covered
    PATCH.append((CODE + '_flank', brings, dict(PL, seed=29, faces=[0, 2, 3, 7], size=(U(0.045), U(0.1)), inv=[])))
    K.mass('Hull: the glacis body (the bomber\'s ramp and stern housing, narrowed)', body, 'soot and patched plate',
           note='the KB1CC body at about two thirds of its beam: a tapered bow toe, the rising glacis, a level upper deck, the stern bank housing')
    K.mark('body', 'hull', ['bevel', 'step', 'overhang'])

    # ---------------- the glacis rails ----------------
    RW, RH = 0.011, 0.020
    for side in (1, -1):
        nm = 'p' if side > 0 else 's'
        rs = []
        for n in [0.49 - 0.04 * i for i in range(23) if 0.49 - 0.04 * i > -0.39] + [-0.388]:
            hw = sec(BODY, n)[1] - 0.005 - sec(BODY, n)[4] * 0.6
            zt = sec(BODY, n)[3] - 0.003
            y0, y1 = side * (hw - 2 * RW), side * hw
            ya, yb = min(y0, y1), max(y0, y1)
            c = RW * 0.35
            rs.append([(U(n), U(y), U(z)) for (y, z) in ((ya, zt), (ya, zt + RH - c), (ya + c, zt + RH), (yb - c, zt + RH), (yb, zt + RH - c), (yb, zt))])
        K.loft_rings('KF1_rail_%s' % nm, rs, 'iron')
    K.mark('rails', 'rib', ['rib'])

    # ---------------- the armoured lip at the top of the ramp, the vision slit off to starboard ----------------
    LX0, LX1, LTOP = -0.330, -0.372, 0.148
    secs = []
    for n, zt_ in ((LX0, top(LX0) / LENGTH + 0.002), (LX0 - 0.014, LTOP - 0.002), (LX1, LTOP)):
        hw = sec(BODY, n)[1] - 0.005 - sec(BODY, n)[4] * 0.6 - 2 * RW - 0.002
        secs.append((U(n), U(hw), U(hw), U(sec(BODY, n)[3] - 0.006), U(zt_), U(0.004), 0.0))
    lip = K.loft('KF1_lip', secs, 'soot2')
    PATCH.append(('KF1_lip', [[(s_[0], y, z) for (y, z) in _k._octa(*s_[1:7])] for s_ in secs], dict(PL, seed=23, faces=[1], size=(U(0.045), U(0.1)), inv=[])))
    K.mass('The armoured lip', lip, 'dark soot plate', note='the lip across the top of the ramp, the pilot under it, as on the bomber')
    K.mark('lip', 'tier', ['face', 'roof', 'opening'])
    z0_, z1_ = top(LX0) / LENGTH + 0.002, LTOP - 0.002
    sn = Vector((z1_ - z0_, 0, 0.014)).normalized()
    K._surface_part('W1', CR.slit(U(0.05), U(0.0040), U(0.0022), U(0.0022)), (U(LX0 - 0.007), U(SLIT_Y), U((z0_ + z1_) / 2)), tuple(sn), (0, 0, 1),
                    'vision_slit', 'vision slit %.2f x %.3f' % (U(0.05), U(0.004)), 'slit', 'designed',
                    'the pilot\'s vision slit in the lip\'s face, off to starboard, looking forward down the ramp', aperture=U(0.2))

    # ---------------- the gun: one salvaged twin turret, centred on the ramp ----------------
    # Ryan, Nov 21 2026: the two uneven turrets looked odd ("make sure all the detail makes sense"). The booms below are the
    # fighter's main cannons, fixed forward; this one turret, centred, covers its flanks. Seated at the ramp's height just
    # ahead of it so no edge floats (an upright mount on the 14 degree ramp).
    K.gun('G1', (U(0.16), 0.0, top(0.16 + 0.022)), 0.0, 3.0, barrels=2, cal=U(0.0055), blen=U(0.11), size=U(0.058), slot='T', weapon='guns', inv='guns',
          variant=1, band=(0, 10, 20, 30, 45),
          note='the fighter\'s guns (data.js guns T): a salvaged twin turret from the Hullbreaker kit, centred on the bow ramp, firing forward over the booms')

    # ---------------- the fighter's own shape: long cannon booms past the bow, on armoured sponsons ----------------
    # Ryan, Nov 21 2026: "a bit more dramatic ... so it feels a bit more like the bomber and is clearly a fighting ship", "keep it
    # distinct from the bomber but use that type of detailed approach". The bomber has fat bomb barrels at its corners; the
    # fighter gets two slim banded cannon booms reaching well past the bow, lopsided (port longer and higher), each on a
    # sponson with exposed machinery (the ammunition feed and recoil gear for the boom cannon).
    def octo(x, r, yc, zc):
        c = r * 0.58
        return (U(x), U(r), U(r), U(zc - r), U(zc + r), U(c), U(c), U(yc))
    for side, (yc, zc, xa, xb, r) in (('p', (0.212, 0.004, -0.17, 0.66, 0.026)), ('s', (-0.206, -0.004, -0.12, 0.59, 0.023))):
        secs = [octo(xb, r * 0.9, yc, zc), octo(xb - 0.02, r, yc, zc), octo(xa + 0.03, r, yc, zc), octo(xa, r * 0.8, yc, zc)]
        K.loft('KF1_boom_%s' % side, secs, 'iron', grp='hull')
        # the muzzle brake: a short wider block with a dark bore face
        K.loft('KF1_brake_%s' % side, [octo(xb + 0.035, r * 1.35, yc, zc), octo(xb - 0.005, r * 1.35, yc, zc)], 'steel', grp='hull')
        K.loft('KF1_bore_%s' % side, [octo(xb + 0.037, r * 0.6, yc, zc), octo(xb + 0.030, r * 0.6, yc, zc)], 'dark', grp='hull')
        # barrel bands, uneven spacing (salvaged and patched)
        for i, bx in enumerate([xb - 0.07, xb - 0.19, xb - 0.27, xb - 0.42, xa + 0.10][: 5 if side == 'p' else 4]):
            K.loft('KF1_band_%s%d' % (side, i), [octo(bx + 0.008, r * 1.22, yc, zc), octo(bx - 0.008, r * 1.22, yc, zc)], 'rust', grp='hull')
        # the sponson: an armoured block from the flank out to the boom, slatted machinery on top
        sgn = 1 if side == 'p' else -1
        y_in, y_out = sgn * 0.150, yc
        ya, yb = min(y_in, y_out), max(y_in, y_out)
        K.box('KF1_sponson_%s' % side, U(xa + 0.01), U(0.22 if side == 'p' else 0.17), U(ya), U(yb), U(zc - r * 1.3), U(zc + r * 1.5), 'soot2',
              ch=U(0.006), taper=U(0.012), grp='hull')
        for i in range(5):
            x0 = xa + 0.06 + 0.032 * i
            K.box('KF1_spslat_%s%d' % (side, i), U(x0), U(x0 + 0.012), U(ya + 0.012), U(yb - 0.004), U(zc + r * 1.5 - 0.002), U(zc + r * 1.5 + 0.007),
                  'iron', grp='hull')
        PATCH.append(('KF1_sponson_%s' % side, [[(U(x_), y, z) for (y, z) in _k._octa(U((yb - ya) / 2), U((yb - ya) / 2), U(zc - r * 1.3), U(zc + r * 1.5), U(0.006), U(0.003), U((ya + yb) / 2))]
                                                for x_ in ((0.22 if side == 'p' else 0.17), xa + 0.01)],
                      dict(PL, seed=37 + sgn, faces=[3 if side == 's' else 7, 5], size=(U(0.035), U(0.08)), inv=[])))
    K.mark('booms', 'pylon', ['web', 'plate'])

    # ---------------- deck detail: an ammunition locker and a vent box on the level deck, off centre ----------------
    zd = top(-0.12) / LENGTH
    K.box('KF1_ammo', U(-0.17), U(-0.06), U(0.012), U(0.085), U(zd - 0.002), U(zd + 0.018), 'iron', ch=U(0.003), grp='hull')
    K.box('KF1_ammo_lid', U(-0.16), U(-0.07), U(0.020), U(0.077), U(zd + 0.018), U(zd + 0.022), 'steel', ch=U(0.0015), grp='hull')
    K.box('KF1_vent', U(-0.26), U(-0.19), U(-0.095), U(-0.03), U(zd - 0.002), U(zd + 0.012), 'soot2', ch=U(0.002), grp='hull')
    for i in range(4):
        x0 = -0.198 - 0.016 * i
        K.box('KF1_vent_slat%d' % i, U(x0 - 0.006), U(x0), U(-0.09), U(-0.035), U(zd + 0.012), U(zd + 0.016), 'iron', ch=0.0, grp='hull')
    K.mark('deck_detail', 'tier', ['face', 'roof'])

    # ---------------- the drives: the bomber's thruster bank, three bells under a hood ----------------
    # Ryan, Nov 21 2026: "make the engines a bit more prominent too? So it's not just a floating wedge": bigger bells on longer
    # drums, hung out behind the stern past the hood (they were tucked inside it)
    BANK = [(0.096, 0.090, 0.036), (-0.002, 0.096, 0.044), (-0.098, 0.088, 0.033)]
    XB = X_END - 0.085
    for i, (y, z, r) in enumerate(BANK):
        K.engine('E%d' % (i + 1), (U(XB), U(y), U(z)), U(r), U(0.11), bell=1.0, kw=dict(craft=True, craft_len=U(0.05), seed=i + 3), inv='drives',
                 note='%s drive: a salvaged bell with a red-orange glow on a short drum%s' % (('port', 'centre', 'starboard')[i], ', the big one' if r > 0.02 else ''))
    zb_, zt_ = sec(BODY, X_END)[2], sec(BODY, X_END)[3]
    hw_ = sec(BODY, X_END)[1]
    HZ = 0.123
    K.box('KF1_bankhood', U(X_END - 0.03), U(X_END + 0.004), U(-hw_ + 0.005), U(hw_ - 0.005), U(HZ), U(zt_ - 0.004), 'soot2', ch=U(0.004), grp='hull')
    K.box('KF1_banksill', U(X_END - 0.03), U(X_END + 0.004), U(-hw_ + 0.005), U(hw_ - 0.005), U(zb_ + 0.006), U(0.055), 'soot2', ch=U(0.003), grp='hull')
    K.mark('bank_recess', 'pylon', ['web', 'plate'])

    K.colour('a patchwork of rust and dried-blood plate, dark iron, grey salvaged trophy plates and a few violet ones', U(0.5), U(-0.5), 'whole hull, the capitals\' mix (Ryan, Nov 21)')
    K.colour('red-orange stern drives, dark gun mount', U(-0.46), U(-0.5), 'factions.md: runs dark')

    def room(name, kind, n0, n1, y0, y1, z0, z1, note=''):
        K.room(name, kind, U(min(n0, n1)), U(max(n0, n1)), U(y0), U(y1), U(z0), U(z1), note=note)
    room('magazine', 'magazine', 0.18, 0.02, 0.0, 0.09, -0.03, 0.04, note='the gun\'s ammunition, under the mount')
    room('crew', 'crew', -0.258, -0.35, -0.05, 0.05, -0.02, 0.10, note='the pilot under the lip at the top of the ramp, behind the vision slit')
    room('reactor', 'core', -0.04, -0.19, -0.07, 0.07, -0.03, 0.05, note='the drive reactor, under the ramp')
    room('drive_room', 'engroom', -0.37, -0.44, -0.09, 0.09, -0.03, 0.11, note='the drive room and the bank\'s feeds, in the stern housing')
    K.armour('glacis', U(0.007), 'the heaviest plate, over the pilot and the bow')
    K.armour('body', U(0.004), 'patched plate')
    reach = 0.25
    K.break_line('B-1', U(-0.237), 'the pilot and stern block tears from the body at a weld (only for the recipe\'s records: the game never breaks a craft)',
                 path=[(U(-0.237), U(reach)), (U(-0.229), U(0.08)), (U(-0.245), U(0.0)), (U(-0.23), U(-0.08)), (U(-0.237), U(-reach))])
    K.inside.append(dict(kind='note', name='insides', note='A craft: the game shows its death as a spark and hides it (godot/fx/fx_death.gd _wing_death); nothing breaks open. The rooms are here because the build contract needs an inside.'))
    K.point('core', 'hp_core', (U(-0.115), 0.0, U(0.01)))

    for nm_, rings_, spec_ in PATCH:
        F.patchwork(K, HP, nm_, rings_, spec_)
    K.change('Built on the accepted KB1CC bomber: the same glacis ramp, rails, lip and patchwork at about two thirds of the beam, no shoulders or bomb barrels',
             'issue 1373: the Hullbreaker adaptive fighter wing drew a code-built box; one family per faction, the fighter reads as the light craft (R259, R362)')
    K.change('The plate mix of the capitals (red, dark iron, grey trophy and violet plates), not the bomber\'s all-red craft mix; drawn at 0.7 of the unit length in game (squadron_wing.gd CRAFT_K)',
             'Ryan, Nov 21 2026: "it\'s ALL red compared to the patchy colors of the rest" and "they look like 2x as big as other fighters"')
    K.change('The vision slit off to starboard, three drive bells', 'Hullbreakers are lopsided, never mirror-even (factions.md); guns T (data.js fighter)')
    K.change('Three drive bells about twice the size on longer drums, hung out behind the stern; deeper craft bump in the Hullbreaker stack (normal relief 5.65 against the 3.5 floor)',
             'Ryan, Nov 21 2026: "make the engines a bit more prominent too? So it\'s not just a floating wedge"; issue 1517 detail floor')
    K.change('Two slim banded cannon booms past the bow (port longer and higher), the main guns, with muzzle brakes and armoured sponsons carrying their feed machinery; one centred twin turret on the ramp in place of the two uneven ones; no ram',
             'Ryan, Nov 21 2026: "a bit more dramatic ... clearly a fighting ship", "keep it distinct from the bomber but use that type of detailed approach"')
    K.change('An ammunition locker and a vent box on the deck, and smaller plates on the deck, flanks and chamfers so no bare hull shows',
             'Ryan, Nov 21 2026: "it looks unfinished with the lack of plates" and "can we make the weapon more prominent? right now it just looks like a slab shape"')
