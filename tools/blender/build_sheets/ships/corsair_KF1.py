"""corsair_KF1: the Hullbreaker fighter, the Narrow Glacis (data.js fighter: cls 'Squadron', guns T; hp 20, sp 7).

Issue 1373 (R362: anything solid near a ship is built from the ship part kits and takes the hull finish). The Hullbreakers fly
fighters only in the adaptive enemy wings (rules.gd adaptWings: "launched a fighter wing to hunt your craft"), and the game drew
a code-built box for them. KF1 is the fighter of Ryan's accepted bomber KB1CC (R259, R273): the same glacis ramp, rails,
armoured lip and patchwork plating, without the wide shoulders and bomb barrels, so it reads as the light craft of the same
family. A salvaged twin gun sits off to port on the ramp, the vision slit off to starboard (lopsided, factions.md). Nothing hung
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
    PL = dict(size=(U(0.08), U(0.19)), thick=(U(0.002), U(0.0045)), gap=U(0.0016), skip=0.06, turn=12.0, hard=0.35, stack=0.45,
              rivets_share=0.07, rivet_r=U(0.0018),
              # Ryan, Nov 21 2026: "it's ALL red compared to the patchy colors of the rest": the capitals' plate mix (A18, A19):
              # red plate, grey salvaged trophy plates and a few violet ones over a dark steel body. The faction register paints soot and
              # iron red (R306), so the grey and violet come from steel, pale and violet here.
              mats={'rust': 3, 'blood': 3, 'steel': 2, 'pale': 4, 'violet': 2})
    PATCH = []
    ns = sorted({r[0] for r in BODY} | {round(0.46 - 0.04 * i, 3) for i in range(24) if 0.46 - 0.04 * i > X_END}, reverse=True)
    bsecs = [(U(r[0]), U(r[1]), U(r[1]), U(r[2]), U(r[3]), U(r[4]), U(r[5])) for r in [sec(BODY, n) for n in ns]]
    body = K.loft(CODE + '_body', bsecs, 'steel', shell=U(0.004))
    PATCH.append((CODE + '_body', [[(s_[0], y, z) for (y, z) in _k._octa(*s_[1:7])] for s_ in bsecs],
                  dict(PL, seed=17, faces=[1, 3, 7, 5], inv=['glacis_plates', 'belly_plates'])))
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

    # ---------------- the gun: a salvaged twin mount on the ramp, off to port, fixed forward ----------------
    K.gun('G1', (U(GX), U(GY), top(GX)), 0.0, 3.0, barrels=2, cal=U(0.0035), blen=U(0.075), size=U(0.034), slot='T', weapon='guns', inv='guns',
          variant=1, band=(0, 10, 20, 30, 45), note='the fighter\'s guns (data.js guns T): a salvaged twin mount from the Hullbreaker kit, off to port on the deck above the ramp, firing forward; the craft turns onto its target')

    # ---------------- the drives: the bomber's thruster bank, three bells under a hood ----------------
    BANK = [(0.062, 0.088, 0.019), (-0.004, 0.094, 0.025), (-0.066, 0.086, 0.017)]
    XB = X_END - 0.036
    for i, (y, z, r) in enumerate(BANK):
        K.engine('E%d' % (i + 1), (U(XB), U(y), U(z)), U(r), U(0.07), bell=1.0, kw=dict(craft=True, craft_len=U(0.034), seed=i + 3), inv='drives',
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
    K.change('A salvaged twin gun off to port on the deck above the ramp, the vision slit off to starboard, three drive bells', 'Hullbreakers are lopsided, never mirror-even (factions.md); guns T (data.js fighter)')
