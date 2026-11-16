# corsair_KB1CC: the Ashfall Hullbreaker bomber wing craft, the Wide Glacis (data.js bomber: cls 'Squadron', bombs T; hp 28, sp 5).
# Issue 793; widened by R273 (Ryan, Nov 15 2026 18:46 CST: "Yes, I agree with your take on the bomber. Wider for sure."). His
# white-plates call widened into R274 (18:50 CST), a rule for every Hullbreaker ship in the paint stack (issue 726), not this sheet.
# Concept of record: contrib/muse/design/squadron_concepts_2026_11/hullbreakers/round_3/KB1CC.jpg (design_notes_785_round3.md;
# Ryan, Nov 15 2026, R259: KB1C-C "the best by far"; still a space bomber, never a boat, barge, platform or ground vehicle). The
# written sheet governs where the render drifts, except where Ryan ruled for the render: the sheet's terms (the mouths at the
# glacis's extreme corners in dark collars, the armoured lip) stand; its beam guard (60 to 65 percent) is lifted by R273, so the
# craft takes the render's width.
# Designer of record: the Opus builder, the Board the final designer (R205, R207, R233, R236): KB1C-C is a base, not a trace.
# Ryan's words that bind (R254, R259): no canopy, no swept aero wings, no tail fins, nothing hung under a hull; drives are nozzle
# clusters inside armoured blocks; bombers chunkier and visibly built around what they carry; each faction its own bomber (R253).
# Size: docs/playbooks/scale.md, Squadron row (binding): CLS_LEN['Squadron'] 1.6 long, drawn x SHIP_K 1.6 x SQUADRON_K 1.5 = 3.84.
# Every station and size below is a share of LENGTH (the U() helper). +X bow, +Y port, +Z up. Bow toe x = +0.8, the bells x = -0.8.
# The Hullbreaker kit (tools/blender/kits/hullbreakers/parts.py) builds the plating; the craft parts (the bomb tubes, the drives,
# the bays, the slit) are tools/blender/kits/hullbreakers/craft.py, added to the kit for this build by craft.install.
import math
import os
import importlib.util

CODE = 'corsair_KB1CC'
NAME = 'Wide Glacis bomber (Ashfall Hullbreaker bomber wing craft)'
FACTION = 'Ashfall Hullbreakers (corsair)'
CLASS = 'Squadron'
LENGTH = 1.6
GAME = "data.js bomber (cls 'Squadron', the Hullbreaker wing: corsair sq 'bomber'); length from godot/render/hull_table.gd CLS_LEN['Squadron'] = 1.6 (drawn x SHIP_K 1.6 x SQUADRON_K 1.5 = 3.84 on the board, docs/playbooks/scale.md)"
BEAUTY = 'contrib/muse/design/squadron_concepts_2026_11/hullbreakers/round_3/KB1CC.jpg'
KIT = 'hullbreakers'
CONCEPT_SHEET = BEAUTY
CONCEPT_VIEWS = dict(top=dict(box=(20, 120, 1070, 600)), side=dict(box=(20, 120, 1070, 600)))
CROPS = [('bow (the glacis and the two corner mouths)', (20, 200, 620, 600)), ('midships (the lid, the rails, the flank bays)', (250, 130, 900, 500)),
         ('stern (the thruster bank)', (520, 110, 1070, 420))]
SHEET = dict(version=1, round='first sheet', date='2026-11-15', blend='opus793', px_per_unit=900, view_pad=0.12, label_scale=1.5, bar_units=0.5,
             blend_where='rendered in the issue 793 sandbox (Blender 5.3, Cycles CPU); not on the PC: `build.py corsair_KB1CC <out> render` rebuilds it from this file',
             before='First full layout', before_note='The first complete layout, built with the Hullbreaker kit\'s plating and the new craft parts (craft.py), run through the fit check before any fix.',
             during='The table above is every finding, in the order the check made them.')


def U(v):
    """a share of the craft's length in world units"""
    return v * LENGTH


# ---------------------------------------------------------------------------------------------------- the masses
# The central body (the sheet kit's octagon loft, shares of LENGTH): (n, half-beam, belly, top, top chamfer, belly chamfer). Its top
# is one continuous shallow glacis from the bow toe up to the armoured lip, the lid behind it, then a step up to the stern housing
# that holds the thruster bank.
BODY = [
    (0.500, 0.319, -0.036, -0.012, 0.004, 0.006),
    (0.465, 0.324, -0.046, 0.004, 0.006, 0.010),
    (0.300, 0.314, -0.048, 0.044, 0.010, 0.012),
    (0.120, 0.306, -0.050, 0.083, 0.014, 0.014),
    (0.080, 0.304, -0.050, 0.087, 0.016, 0.014),
    (-0.200, 0.293, -0.050, 0.091, 0.018, 0.014),
    (-0.380, 0.276, -0.049, 0.093, 0.018, 0.014),
    (-0.395, 0.271, -0.049, 0.102, 0.020, 0.014),
    (-0.460, 0.246, -0.046, 0.102, 0.022, 0.014),
]
# a shoulder either side (the side bodies behind the corner pods): its top slopes down and out from the body's wall to a thin
# outer edge, so the craft's section is a flattened six-sided wedge, never a box on two track-like sponsons. Port half points
# (y, z) of its section, shares of LENGTH, and the stations (n, scale of the slope's height). The starboard shoulder sits a touch
# lower and shorter: the Hullbreakers are lopsided (factions.md), never mirror-even.
# R273 (Ryan, Nov 15 2026: "Wider for sure"): the shoulders reach out to the render's width, the craft about a fifth wider than it is long
SHOULDER = [(0.270, 0.064), (0.499, 0.031), (0.585, 0.013), (0.600, 0.001), (0.600, -0.022), (0.546, -0.046), (0.270, -0.048)]
# (n, k: the slope's height as a share of its full height, w: the shoulder's reach out from the body as a share): in plan the
# craft tapers aft from the wide front (the two corner mouths) to the narrower stern housing, a wedge, never a rectangle
SHOULDER_X = {1: [(0.494, 0.55, 0.92), (0.455, 1.0, 1.0), (-0.230, 1.0, 1.0), (-0.370, 0.92, 0.74), (-0.440, 0.66, 0.6)],
              -1: [(0.494, 0.5, 0.92), (0.455, 0.93, 1.0), (-0.230, 0.93, 1.0), (-0.350, 0.86, 0.76), (-0.425, 0.62, 0.62)]}


def shoulder_ring(side, n, k, w):
    """the shoulder's section at station n: its heights scaled by k toward the belly line, its reach by w (the ends taper)"""
    zb = -0.048 if side > 0 else -0.05
    pts = []
    for (y, z) in SHOULDER:
        zz = zb + (z - zb) * k - (0.0 if side > 0 else 0.003)
        yy = SHOULDER[0][0] + (y - SHOULDER[0][0]) * w
        pts.append((U(n), U(side * yy), U(zz)))
    return pts


def shoulder_top(side, y, n=0.0):
    """the shoulder's sloped top at y (share, positive) for the full-height stations, world z"""
    (y0, z0), (y1, z1) = SHOULDER[0], SHOULDER[1]
    k = SHOULDER_X[side][1][1]; zb = -0.048 if side > 0 else -0.05
    z = z0 + (z1 - z0) * (y - y0) / (y1 - y0)
    return U(zb + (z - zb) * k - (0.0 if side > 0 else 0.003))


X_END = -0.46


def sec(tab, n):
    s = sorted(tab, key=lambda r: -r[0])
    if n >= s[0][0]:
        return list(s[0])
    if n <= s[-1][0]:
        return list(s[-1])
    for a, b in zip(s, s[1:]):
        if a[0] >= n >= b[0]:
            t = (a[0] - n) / (a[0] - b[0])
            return [a[i] + (b[i] - a[i]) * t for i in range(len(a))]


def top(n):
    """the central body's top at station n, world units"""
    return U(sec(BODY, n)[3])


HULL = [(U(r[0]), U(r[1]), U(r[1]), U(r[2]), U(r[3]), 0.0, 0.0) for r in BODY]


def build(K):
    import bpy
    import kit as _k
    from mathutils import Vector
    HP = _k.HP
    sp = importlib.util.spec_from_file_location('hb_craft', os.path.join(_k._KITS, 'hullbreakers', 'craft.py'))
    CR = importlib.util.module_from_spec(sp); sp.loader.exec_module(CR)
    CR.install(HP)
    K.hull_sections = [(U(r[0]), U(r[1]), U(r[1]), U(r[2]), U(r[3]), U(r[4]), U(r[5])) for r in BODY]
    # scrap brick in courses at the craft's own plate size (world units), big trophy patches among them (R252), rust and dried
    # blood the main tones (the concept's red), soot and bare iron between
    PL = dict(keep3d=True, courses=True, size=(U(0.034), U(0.08)), thick=(U(0.0018), U(0.0042)), step=U(0.0016), gap=U(0.0012), over=0.22, skip=0.015,
              stack=0.2, rivets_share=0.22, rivet_r=U(0.0018), terrace=1.5,
              mats={'rust': 5, 'soot': 4, 'blood': 3, 'iron': 2, 'soot2': 2, 'pale': 0.6, 'violet': 0.4})
    ns = sorted({r[0] for r in BODY} | {round(0.46 - 0.04 * i, 3) for i in range(24) if 0.46 - 0.04 * i > X_END}, reverse=True)
    body = K.loft(CODE + '_body', [(U(r[0]), U(r[1]), U(r[1]), U(r[2]), U(r[3]), U(r[4]), U(r[5])) for r in [sec(BODY, n) for n in ns]], 'soot',
                  shell=U(0.004), plates=dict(PL, seed=31, faces=[0, 1, 7, 2, 6, 3, 4, 5], inv=['glacis_plates', 'belly_plates']))
    K.mass('Hull: the central body (the glacis, the lid, the stern housing)', body, 'soot and patched plate',
           note='one wide low body: its top a continuous shallow glacis from the bow toe up to the armoured lip, the flat lid behind, a step up to the stern housing; flat belly with chines')
    K.mark('body', 'hull', ['bevel', 'step', 'overhang'])
    for side in (1, -1):
        nm = 'port' if side > 0 else 'starboard'
        rs = [shoulder_ring(side, n, k, w) for (n, k, w) in SHOULDER_X[side]]
        ob = K.loft_rings('KB1CC_shoulder_%s' % nm[0], rs, 'soot2', plates=dict(PL, seed=40 + side, faces=[0, 1, 2, 3, 4, 5], inv='shoulder_plates'))
        md = ob.modifiers.new('shell', 'SOLIDIFY'); md.thickness = U(0.004); md.offset = -1; md.use_rim = True
        K.mass('Shoulder, %s' % nm, ob, 'dark soot and patched plate', note='the %s side body behind the corner pod, its top sloping down and out to a thin edge: the bomb row\'s magazine and the hoist bay%s' % (
            nm, '' if side > 0 else '; a touch lower and shorter than the port one (lopsided)'))
    K.mark('shoulders', 'tier', ['face', 'roof', 'opening'])

    # ---------------- the glacis rails: armoured edge frames up the glacis and along the lid ----------------
    RW, RH = 0.011, 0.012
    for side in (1, -1):
        nm = 'p' if side > 0 else 's'
        rs = []
        for n in [0.49 - 0.04 * i for i in range(23) if 0.49 - 0.04 * i > -0.39] + [-0.388]:
            hw = sec(BODY, n)[1] - 0.006 - sec(BODY, n)[4] * 0.6
            zt = sec(BODY, n)[3] - 0.003
            y0, y1 = side * (hw - 2 * RW), side * hw
            ya, yb = min(y0, y1), max(y0, y1)
            c = RW * 0.35
            rs.append([(U(n), U(y), U(z)) for (y, z) in ((ya, zt), (ya, zt + RH - c), (ya + c, zt + RH), (yb - c, zt + RH), (yb, zt + RH - c), (yb, zt))])
        K.loft_rings('KB1CC_rail_%s' % nm, rs, 'iron')
        # clamp brackets bolted along the rail every few plates
        for n in (0.42, 0.3, 0.18, 0.02, -0.14, -0.3):
            hw = sec(BODY, n)[1] - 0.006 - sec(BODY, n)[4] * 0.6; zt = sec(BODY, n)[3]
            K.box('KB1CC_railclamp_%s%d' % (nm, int(n * 100)), U(n - 0.012), U(n + 0.012), U(side * (hw - 2 * RW) - 0.004) if side > 0 else U(-hw - 0.004),
                  U(hw + 0.004) if side > 0 else U(-(hw - 2 * RW) + 0.004), U(zt), U(zt + RH + 0.004), 'steel', ch=U(0.002), grp='hull')
    K.mark('rails', 'rib', ['rib'])

    # ---------------- the armoured lip at the glacis and lid junction, and the crew's vision slit in its face ----------------
    LX0, LX1 = 0.085, 0.045
    secs = []
    for n, k in ((LX0 + 0.012, 0.15), (LX0, 1.0), (LX1, 1.0)):
        hw = sec(BODY, n)[1] - 0.006 - sec(BODY, n)[4] * 0.6 - 2 * RW - 0.002
        zt = sec(BODY, n)[3]
        secs.append((U(n), U(hw), U(hw), U(zt - 0.006), U(zt + 0.016 * k), U(0.005 * k), 0.0))
    lip = K.loft('KB1CC_lip', secs[::-1][::-1], 'soot2')
    K.mass('The armoured lip', lip, 'dark soot plate', note='a shallow armoured lip across the glacis\'s top edge: it ends the slope, so the glacis reads as armour on a hull, never a ramp')
    K.mark('lip', 'tier', ['face', 'roof', 'opening'])
    sn = Vector((0.016 / 0.012, 0, 1)).normalized()
    ax, az = U(LX0 + 0.006), U(sec(BODY, LX0 + 0.006)[3] + 0.0085)
    K._surface_part('W1', CR.slit(U(0.07), U(0.0042), U(0.0022), U(0.0022)), (ax, U(0.02), az), tuple(sn), (0, 0, 1), 'vision_slit',
                    'vision slit %.2f x %.3f' % (U(0.07), U(0.0042)), 'slit', 'designed',
                    'the crew\'s vision slit in the lip\'s face, a little to port (the bombardier aims the craft at its target)', aperture=U(0.2))

    # ---------------- the two bomb tubes: one in each front corner pod, at the glacis's extreme corners ----------------
    R_M = 0.04
    for side, fid in ((1, 'BT1'), (-1, 'BT2')):
        y = side * 0.535
        K.launcher(fid, (U(0.5 - 0.004), U(y), U(0.019 if side > 0 else 0.017)), 1, 1, cell=U(R_M / 0.3), depth=U(0.215), yaw=0.0, pitch=0.0,
                   slot='T', weapon='bombs', inv='bomb_tubes', variant='bomb%d' % (1 if side > 0 else 2),
                   note='the bomb payload (data.js bombs T, 2 shots): the %s bomb tube in its corner pod, a dark armoured collar round the mouth; one bomb from each tube every volley' % (
                       'port' if side > 0 else 'starboard'))
        K.features[-1]['what'] = 'bomb tube in a corner pod, mouth %.2f across' % (2 * U(R_M))
        c_, r_ = K.keepouts[-1]
        K.keepouts[-1] = (c_, U(0.07))   # the pod's own plate keep-out (the kit's default reaches its whole drum)

    # ---------------- the hoist bays: the bomb hoists, behind armoured doors, in the shoulders' sloped tops ----------------
    (y0_, z0_), (y1_, z1_) = SHOULDER[0], SHOULDER[1]
    for side, fid in ((1, 'Y1'), (-1, 'Y2')):
        n0, n1 = -0.0, -0.215
        nc = (n0 + n1) / 2
        yc = 0.39
        nrm = Vector((0.0, side * (z0_ - z1_), (y1_ - y0_))).normalized()
        wid = (Vector((y1_ - y0_, z1_ - z0_)).length) * 0.62
        K._surface_part(fid, CR.machbay(U(n0 - n1), U(wid), U(0.004), door=0.42 if side > 0 else 0.5, seed=1 if side > 0 else 2),
                        (U(nc), side * U(yc), shoulder_top(side, yc) + U(0.0005)), tuple(nrm), (1, 0, 0), 'hoist_bays',
                        'hoist bay %.2f x %.2f, armoured door' % (U(n0 - n1), U(wid)), 'bay', 'picture',
                        'the %s bomb hoist: the machinery that walks the next bomb from the shoulder\'s magazine row into its tube, behind an armoured door (the concept\'s recessed side bay)' % (
                            'port' if side > 0 else 'starboard'))
        c_, r_ = K.keepouts.pop()   # the bay is long and narrow: three small keep-outs along it instead of one circle round it all
        for f_ in (-0.32, 0.0, 0.32):
            K.keepouts.append((c_ + Vector((U((n0 - n1) * f_), 0, 0)), U(0.05)))

    # ---------------- the thruster bank: five mismatched drives in a recess in the stern housing ----------------
    BANK = [(0.104, 0.027, 0.017), (0.057, 0.031, 0.021), (-0.003, 0.025, 0.028), (-0.062, 0.03, 0.02), (-0.107, 0.022, 0.016)]   # (y, z, bell radius)
    XB = X_END - 0.036
    for i, (y, z, r) in enumerate(BANK):
        K.engine('E%d' % (i + 1), (U(XB), U(y), U(z)), U(r), U(0.07), bell=1.0, kw=dict(craft=True, craft_len=U(0.034), seed=i), inv='drives',
                 note='%s drive: a salvaged bell with a red-orange glow on a short drum%s' % (('first', 'second', 'centre', 'fourth', 'fifth')[i],
                                                                                              ', the big one' if r > 0.025 else ''))
    # the recess round the bank: a hood over it, cheeks at its sides, a sill under it, all welded to the stern housing
    zb_, zt_ = sec(BODY, X_END)[2], sec(BODY, X_END)[3]
    hw_ = sec(BODY, X_END)[1]
    K.box('KB1CC_bankhood', U(X_END - 0.03), U(X_END + 0.004), U(-hw_ + 0.006), U(hw_ - 0.006), U(0.074), U(zt_ - 0.004), 'soot2', ch=U(0.004), grp='hull',
          plates=dict(PL, seed=55, faces=[0, 1, 2]))
    for side in (1, -1):
        K.box('KB1CC_bankcheek_%s' % ('p' if side > 0 else 's'), U(X_END - 0.03), U(X_END + 0.004), U(0.136) if side > 0 else U(-hw_ + 0.006),
              U(hw_ - 0.006) if side > 0 else U(-0.142), U(zb_ + 0.006), U(0.074), 'iron', ch=U(0.003), grp='hull')
    K.box('KB1CC_banksill', U(X_END - 0.03), U(X_END + 0.004), U(-0.142), U(0.136), U(zb_ + 0.006), U(-0.018), 'soot2', ch=U(0.003), grp='hull')
    K.mark('bank_recess', 'pylon', ['web', 'plate'])
    K.fix('The corner pods hung below the belly (the collars\' bottoms at -0.07 against a belly of -0.04): side-on they read as front rollers (seen on the sheet\'s side view, not the fit check)',
          'the mouths a step smaller (0.08 across) and raised to mid-height on the corners, the collars\' bottoms on the belly line, the bow\'s belly a touch deeper; nothing hangs under the hull')
    K.fix('E2, E3 and E4: neighbouring bells touching at their lips, each in the next one\'s exhaust cone (CLASH 2, EXHAUST 3)',
          'the bells shrunk a step (the centre one 0.045 across, still the largest) and spread so each lip clears the next by 0.008')

    # ---------------- colour zones ----------------
    K.colour('rust and dried-blood plate in uneven courses, soot and bare iron between', U(0.5), U(-0.5), 'whole hull')
    K.colour('trophy patches: pale Hegemony grey, violet Eclipse plate', U(0.5), U(-0.5), 'scattered, big (R252; R274: the Hullbreaker paint stack turns the pale ones dark grey metal, issue 726)')
    K.colour('red-orange glow only in the five bells; the mouths dark; no bright light', U(-0.46), U(-0.5), 'the thruster bank; factions.md: runs dark')

    # ---------------- INSIDE: the magazine rows (the bomber's story), kept small ----------------
    def room(name, kind, n0, n1, y0, y1, z0, z1, note=''):
        K.room(name, kind, U(min(n0, n1)), U(max(n0, n1)), U(y0), U(y1), U(z0), U(z1), note=note)
    for side in (1, -1):
        y = side * 0.42
        room('magazine_%s' % ('p' if side > 0 else 's'), 'magazine', 0.26, -0.1, y - 0.04, y + 0.04, -0.036, 0.014,
             note='the %s bomb row in the shoulder: salvaged bombs racked nose forward, fed by the hoist to the tube' % ('port' if side > 0 else 'starboard'))
    room('crew', 'crew', 0.07, -0.05, -0.06, 0.06, -0.02, 0.07, note='the pilot and the bombardier under the lip, behind the vision slit')
    room('reactor', 'core', -0.12, -0.24, -0.09, 0.09, -0.035, 0.07, note='the drive reactor')
    room('drive_room', 'engroom', -0.3, -0.4, -0.13, 0.13, -0.035, 0.08, note='the drive room and the bank\'s feeds')
    K.armour('glacis', U(0.008), 'the heaviest plate, over the crew and the bow')
    K.armour('body and shoulders', U(0.004), 'patched plate')
    reach = 0.4
    K.break_line('B-1', U(-0.27), 'the stern housing tears from the body at a weld (Hullbreakers: at the seams; only for the recipe\'s records: the game never breaks a craft)',
                 path=[(U(-0.27), U(reach)), (U(-0.27), U(0.2)), (U(-0.258), U(0.12)), (U(-0.279), U(0.04)), (U(-0.262), U(-0.05)), (U(-0.281), U(-0.14)),
                       (U(-0.27), U(-0.2)), (U(-0.27), U(-reach))])
    K.inside.append(dict(kind='note', name='insides', note='A craft: the game shows its death as a spark and hides it (godot/fx/fx_death.gd _wing_death); nothing breaks open. The magazine rows are here because the build contract needs an inside (tools/blender/build_sheets/contract.py) and because the magazine is the bomber\'s story; they cost few triangles.'))
    K.point('core', 'hp_core', (U(-0.18), 0.0, U(0.01)))

    # ---------- changed from the picture (designer's decisions, R207, R233, R236) ----------
    K.change('Length 1.6 (CLS_LEN Squadron; drawn 3.84 on the board), the same as every craft; beam about 1.2 of the length, the render\'s width',
             'docs/playbooks/scale.md, Squadron rows, binding; R273, Ryan, Nov 15: "Wider for sure": the round 3 beam guard (60 to 65 percent) is lifted for this craft. The first sheet held it at 0.61 and read far narrower than the render')
    K.change('The two round mouths at the front corners are bomb tubes: dark armoured collars round dark bores with the next bomb\'s nose seated deep inside, no glow',
             'the round 3 sheet: the mouths at the glacis\'s extreme corners, each in a dark armoured collar; the render lights them red like engines, which would read as drives facing forward; the glow belongs to the bank aft')
    K.change('The tubes are fixed forward in their pods, not on a turning mount',
             'a craft turns onto its target on a strafing run; weapon_match.py FITS bombs: a bomb tube on a launcher (the Board\'s reading of rule 11 for craft); two tubes for the 2 shots, both fire every volley')
    K.change('A shallow armoured lip across the top of the glacis, with the crew\'s vision slit in its face; the glacis and the lid are framed by armoured edge rails with bolted clamps',
             'the round 3 sheet (DeepSeek): the lip at the lid and glacis junction against the ramp read; no canopy (R254), so the crew looks out through a slit; the rails are the concept\'s raised glacis edges')
    K.change('The flank bays are the bomb hoists, one a side in the shoulder\'s sloped top: a heavy frame, a dark back, pipes and the hoist block inside, an armoured door in a second tone over the fore part',
             'every part has a job (R221): the hoist walks the next bomb from the shoulder\'s magazine row into its tube; on the slope they face the battle camera; the doors carry a two-tone value shift so they survive 32 px (Qwen)')
    K.change('The stern thruster bank is five mismatched salvaged bells, the centre one the largest, in a recess (a hood, cheeks and a sill) in the stern housing',
             'the concept\'s row of stern thrusters; factions.md: mismatched bells with a red-orange glow, one often larger than the rest; the owner\'s rule for craft: nozzle clusters inside armoured blocks')
    K.change('The starboard shoulder sits a touch lower and shorter than the port one; the plating is uneven courses of rust, dried blood, soot and iron with big trophy patches',
             'factions.md: lopsided, bolted, patched, plates torn from every other faction; R240: the patchwork never reads even; R252: big trophy patches (R274: the pale ones become dark grey metal in the Hullbreaker paint stack for every ship, issue 726; the sheet keeps the pale zone)')
    K.change('No dishes, claws, antennas, lamps or hangar', 'below what the battle camera shows on a 3.84 unit craft, and nothing hangs off (factions.md); bold and simple')
    K.change('A small inside: two magazine rows in the shoulders, the crew cell, the reactor, the drive room; one seam (B-1)',
             'the game shows a craft\'s death as a spark and hides it (fx_death.gd _wing_death), so nothing breaks open; the build contract needs an inside and a seam')
    K.open_item('The rust, soot, trophy colours and the red running lights are the Hullbreaker paint stack (tools/blender/kits/hullbreakers/stack.py), applied later')
    K.open_item('How a sheet craft reaches the game: the game builds every craft in code today (godot/render/squadron_craft.gd), so no stage 7 export or install here')
