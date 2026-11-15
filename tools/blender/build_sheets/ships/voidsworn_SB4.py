# voidsworn_SB4: the Sunward Crusade bomber wing craft, the Magazine Block (data.js bomber: cls 'Squadron', bombs T; hp 28, sp 5).
# Issue 769. Concept of record: contrib/muse/design/squadron_concepts_2026_11/sunward/round_2/SB4.jpg (Ryan, Nov 14 23:57 CST,
# R255: "Agree on sf3 and sb4"; design_notes_757.md section SB4: "the hull IS the magazine").
# Designer of record: the Opus builder, the Board the final designer (R205, R207, R233, R236): SB4 is a base, not a trace.
# Ryan's words that bind (design_notes_757.md, R254): no canopy, no swept aero wings, no tail fins, no bombs hung under the hull;
# drives are nozzle clusters inside armoured blocks; bombers chunkier and visibly built around what they carry.
# Size: docs/playbooks/scale.md, Squadron row (binding; it wins over the notes' 4.2 units): CLS_LEN['Squadron'] 1.6 long, drawn
# x SHIP_K 1.6 x SQUADRON_K 1.5 = 3.84 on the board, the same length as the fighter ("same wing frame as a fighter, only its load
# differs"). The bomber reads apart by its mass: about twice the fighter's beam and three times its depth.
# Every station and size below is a share of LENGTH (the U() helper). +X bow, +Y port, +Z up.
import math

CODE = 'voidsworn_SB4'
NAME = 'Magazine Block bomber (Sunward Crusade bomber wing craft)'
FACTION = 'Sunward Crusade (voidsworn)'
CLASS = 'Squadron'
LENGTH = 1.6
GAME = "data.js bomber (cls 'Squadron'); length from godot/render/hull_table.gd CLS_LEN['Squadron'] = 1.6 (drawn x SHIP_K 1.6 x SQUADRON_K 1.5 = 3.84 on the board, docs/playbooks/scale.md)"
BEAUTY = 'contrib/muse/design/squadron_concepts_2026_11/sunward/round_2/SB4.jpg'
KIT = 'voidsworn'
CONCEPT_SHEET = BEAUTY
CONCEPT_VIEWS = dict(top=dict(box=(100, 70, 1000, 650)), side=dict(box=(100, 70, 1000, 650)))
CROPS = [('bow (the bomb cassette)', (100, 230, 620, 650)), ('midships (the magazine ridges)', (300, 70, 820, 470)),
         ('stern (the drives)', (640, 70, 1010, 420))]
SHEET = dict(version=1, round='first sheet', date='2026-11-15', blend='opus769', px_per_unit=900, view_pad=0.12, label_scale=1.5, bar_units=0.5,
             blend_where='rendered in the issue 769 sandbox (Blender 5.3, Cycles CPU); not on the PC: `build.py voidsworn_SB4 <out> render` rebuilds it from this file',
             before='First full layout', before_note='The first complete layout, built with the Sunward kit\'s new craft parts and run through the fit check before any fix.',
             during='The fit check found nothing on the first layout. The sheet\'s own looks sent back: the cassette\'s front plate stood out past the housing\'s '
                    'chamfered corners (now clipped to them); the heat louvres\' ember back plate stood in front of their slats (the kit now keeps it behind); the first '
                    'plating read as a shrunken capital ship (larger plates, smaller rivets).')


def U(v):
    """a share of the craft's length in world units"""
    return v * LENGTH


# ---------------------------------------------------------------------------------------------------- the hull section
# The magazine block: a faceted eight-sided section (deck, chamfers, the vertical flank band, the lower chamfers, a flat belly),
# so the flanks are angled planes round a band, never a flat-walled box (R244). The bow face is set back for the bomb cassette.
# (n, hw: half-beam, zt: deck, zb: belly, ct: the deck chamfer, cb: the belly chamfer)
ST = [
    (0.400, 0.236, 0.122, -0.120, 0.060, 0.050),
    (0.370, 0.244, 0.130, -0.126, 0.064, 0.054),
    (0.300, 0.250, 0.134, -0.130, 0.068, 0.055),
    (-0.300, 0.250, 0.134, -0.130, 0.068, 0.055),
    (-0.400, 0.246, 0.131, -0.127, 0.070, 0.058),
    (-0.440, 0.232, 0.120, -0.116, 0.075, 0.064),
]
SHELL = U(0.006)
HULL = [(U(r[0]), U(r[1]), U(r[1]), U(r[3]), U(r[2]), 0.0, 0.0) for r in ST]


def st_at(n):
    s = sorted(ST, key=lambda r: -r[0])
    if n >= s[0][0]:
        return list(s[0])
    if n <= s[-1][0]:
        return list(s[-1])
    for a, b in zip(s, s[1:]):
        if a[0] >= n >= b[0]:
            t = (a[0] - n) / (a[0] - b[0])
            return [a[i] + (b[i] - a[i]) * t for i in range(len(a))]


def half_ring(n, inset=0.0):
    """port half, deck centre to belly centre (shares of LENGTH)"""
    _, hw, zt, zb, ct, cb = st_at(n)
    hw -= inset; zt -= inset; zb += inset
    return [(0.0, zt), (hw - ct, zt), (hw, zt - ct), (hw, zb + cb), (hw - cb, zb), (0.0, zb)]


def ring(n, inset=0.0):
    h = half_ring(n, inset)
    full = h + [(-y, z) for (y, z) in reversed(h[1:-1])]
    return [(U(n), U(y), U(z)) for (y, z) in full]


def half_w(n, z, inset=0.0):
    h = half_ring(n, inset)
    best = 0.0
    for (y0, z0), (y1, z1) in zip(h, h[1:]):
        if min(z0, z1) - 1e-9 <= z <= max(z0, z1) + 1e-9:
            best = max(best, y0, y1) if abs(z1 - z0) < 1e-9 else max(best, y0 + (y1 - y0) * (z - z0) / (z1 - z0))
    return best


# the two magazine ridges on the deck: (y centre, half-width, height over the deck, fore, aft), shares of LENGTH
RIDGE = (0.105, 0.046, 0.032, 0.30, -0.38)


def build(K):
    import bpy
    import kit as _k
    from mathutils import Vector
    HP = _k.HP
    for k_, v_ in getattr(HP, 'MATS', {}).items():
        _k.MATS.setdefault(k_, v_)
    K.hull_sections = [(U(r[0]), U(r[1]), U(r[1]), U(r[3]), U(r[2]), 0.0, 0.0) for r in ST]
    K.hull_rounded = False
    ns = sorted({r[0] for r in ST} | {0.3 - i * 0.05 for i in range(13)}, reverse=True)
    rings = [ring(n) for n in ns]
    hull = K.loft_rings(CODE + '_hull', rings, 'siron')
    md = hull.modifiers.new('shell', 'SOLIDIFY'); md.thickness = SHELL; md.offset = -1; md.use_rim = True
    K.mass('Hull: the magazine block', hull, 'black iron plate',
           note='one massive faceted block built round the bomb magazine: deck, chamfers, the flank band, lower chamfers, a flat belly')
    K.mark('block', 'hull', ['facet', 'step', 'chamfer'])
    PL = dict(thick=(U(0.002), U(0.0032)), unit=U(0.07), rr=U(0.0013))
    # ring edge indices: 0 deck (port half), 1 deck chamfer, 2 flank band, 3 belly chamfer, 4 belly, 5 belly', 6 chamfer', 7 band',
    # 8 chamfer', 9 deck'
    plate_jobs = [('deck', rings, dict(PL, faces=[0, 9], size=(U(0.065), U(0.15)), mats={'siron': 3, 'siron2': 2}, seed=21, inv='block_plates')),
                  ('chamfer', rings, dict(PL, faces=[1, 8], size=(U(0.06), U(0.14)), tri=True, mats={'siron': 3, 'siron2': 2}, seed=22, inv='block_plates')),
                  ('band', rings, dict(PL, faces=[2, 7], size=(U(0.06), U(0.15)), mats={'siron2': 3, 'siron': 2}, seed=23, inv='block_plates')),
                  ('lower', rings, dict(PL, faces=[3, 6], size=(U(0.06), U(0.15)), mats={'siron2': 3, 'siron': 2}, seed=24, inv='block_plates')),
                  ('belly', rings, dict(PL, faces=[4, 5], size=(U(0.07), U(0.16)), mats={'siron2': 3, 'siron': 2}, seed=25, inv='block_plates'))]

    # ---------------- the two magazine ridges: armour over the two bomb rows, one row feeding each tube ----------------
    yc, rw, rh, f0, f1 = RIDGE
    for side, nm in ((1, 'port'), (-1, 'starboard')):
        rs = []
        for n, k in ((f0, 0.0), (f0 - 0.03, 1.0), (f1 + 0.03, 1.0), (f1, 0.0)):
            zt = st_at(n)[2]
            w = rw * (0.7 + 0.3 * k); h = rh * (0.35 + 0.65 * k); c = min(w, h) * 0.45
            y0 = side * yc
            pts = [(y0 - w, zt - 0.006), (y0 - w, zt + h - c), (y0 - w + c, zt + h), (y0 + w - c, zt + h), (y0 + w, zt + h - c), (y0 + w, zt - 0.006)]
            rs.append([(U(n), U(y), U(z)) for (y, z) in pts])
        ob = K.loft_rings('SB4_ridge_%s' % nm[0], rs, 'siron2')
        K.mass('Magazine ridge, %s' % nm, ob, 'darker iron', note='the armoured roof over one bomb row; the row feeds the %s tube' % nm)
        K.mark('ridges', 'spine', ['block', 'step', 'slit'], fid='SB4_ridge_%s' % nm[0])
        plate_jobs.append(('ridge%s' % nm[0], rs, dict(PL, faces=[1, 2, 3], size=(U(0.045), U(0.13)), mats={'siron': 2, 'siron2': 1}, seed=30 + side,
                                                       inv='ridge_plates', closed=False)))
    # ---------------- the magazine belts: a second forged layer over each flank band, over the magazine ----------------
    for side, nm in ((1, 'port'), (-1, 'starboard')):
        rs = []
        for n, k in ((0.27, 0.0), (0.24, 1.0), (-0.28, 1.0), (-0.31, 0.0)):
            _, hw, zt, zb, ct, cb = st_at(n)
            o = 0.012 * k
            pts = [(hw - 0.004, zt - ct - 0.004), (hw + o, zt - ct - 0.008), (hw + o, zb + cb + 0.008), (hw - 0.004, zb + cb + 0.004)]
            rs.append([(U(n), U(side * y), U(z)) for (y, z) in (pts if side > 0 else pts[::-1])])
        ob = K.loft_rings('SB4_belt_%s' % nm[0], rs, 'siron2')
        K.mass('Magazine belt, %s' % nm, ob, 'darker iron', note='a second forged layer over the flank band where the bomb rows lie; its ends are angled')
        K.mark('belts', 'belt', ['band', 'plate'], fid='SB4_belt_%s' % nm[0])
        plate_jobs.append(('belt%s' % nm[0], rs, dict(PL, faces=[1], size=(U(0.05), U(0.12)), mats={'siron': 2, 'siron2': 1}, seed=40 + side,
                                                      inv='belt_plates', closed=False)))

    # ---------------- the bomb cassette: the bow face, two big tube mouths and the bombardier's sight ----------------
    CELL = 0.22
    r_ = CELL * 0.3
    XF = 0.5 - r_ * 0.42 - 0.0021  # the cassette's front face; its rims' studs reach 0.5
    K.launcher('BT', (U(XF), 0.0, U(-0.004)), 1, 2, cell=U(CELL), depth=U(0.135), yaw=0.0, pitch=0.0, slot='T', weapon='bombs', inv='bomb_cassette',
               note='the bomb payload (data.js bombs T, 2 shots): two tube mouths in the armoured bow cassette, one bomb from each every volley')
    K.features[-1]['what'] = 'bomb cassette, two tube mouths %.2f across' % (2 * U(r_))

    # ---------------- the drives: two pairs of deep bells sunk in armoured cowls in the stern face ----------------
    R_EX = 0.034
    XE = -0.5 + 0.35 * R_EX + 0.0018
    for i, (y, z) in enumerate(((0.115, 0.056), (0.115, -0.056), (-0.115, 0.056), (-0.115, -0.056))):
        K.engine('E%d' % (i + 1), (U(XE), U(y), U(z)), U(R_EX), U(0.09), bell=1.0, body_r=U(0.0493), rings=1, kw=dict(craft=True), inv='drives',
                 note='%s %s drive: a deep bell sunk in an eight-sided armoured cowl, ember lining and plug, dim like banked coals' % (
                     'port' if y > 0 else 'starboard', 'upper' if z > 0 else 'lower'))

    # ---------------- the drive heat louvres on the ridges aft ----------------
    for side in (1, -1):
        n = -0.29
        K._surface_part('V1' + ('p' if side > 0 else 's'), HP.vent(U(0.05), U(0.11), slats=6, depth=U(0.008), fr=U(0.012)),
                        (U(n), side * U(yc), U(st_at(n)[2] + rh) + U(0.0005)), (0, 0, 1), (1, 0, 0), 'louvres', 'heat louvre %.3f x %.3f' % (U(0.05), U(0.11)), 'vent',
                        'picture', 'the drive room\'s heat louvre on the ridge\'s aft end: slanted slats over an ember-lit recess (the concept\'s glowing roof slits)',
                        aperture=U(0.15))

    # ---------------- colour zones ----------------
    K.colour('black iron plate, one frost-white oath band across one shoulder (paint stage)', U(0.5), U(-0.5), 'whole hull')
    K.colour('ember glow (the drive throats, the louvres, the sight slit)', U(0.5), U(-0.5), 'the bells, the louvres, the sight')
    K.colour('no rust anywhere, no blue light, no canopy glass, no bombs outside the hull', U(0.5), U(-0.5), 'factions.md Never; Ryan R254')

    # ---------------- INSIDE: the magazine (the bomber's whole story), kept small ----------------
    IN = SHELL / LENGTH + 0.003

    def room(name, kind, n0, n1, y0, y1, z0, z1, note=''):
        K.room(name, kind, U(min(n0, n1)), U(max(n0, n1)), U(y0), U(y1), U(z0), U(z1), note=note)
    room('magazine_p', 'magazine', 0.30, -0.17, 0.035, 0.19, -0.095, 0.1, note='the port bomb row: bombs racked nose forward, fed to the port tube')
    room('magazine_s', 'magazine', 0.30, -0.17, -0.19, -0.035, -0.095, 0.1, note='the starboard bomb row, fed to the starboard tube')
    room('bombardier', 'crew', 0.30, 0.18, -0.03, 0.03, -0.02, 0.07, note='the bombardier and pilot between the rows, behind the sight slit (no AI, lore 2.5)')
    room('reactor', 'core', -0.20, -0.30, -0.12, 0.12, -0.08, 0.09, note='the drive reactor')
    room('drive_room', 'engroom', -0.31, -0.37, -0.19, 0.19, -0.09, 0.1, note='the drive room and the four drives\' feeds')
    # the bombs on their racks: two rows of four, each a short fat iron round (the payload the hull is built round)
    BV, BF = [], []
    for y in (0.112, -0.112):
        for i in range(4):
            x0 = 0.26 - i * 0.105
            V_, F_ = HP.revolve([(U(x0), 0.0001), (U(x0 - 0.02), U(0.034)), (U(x0 - 0.075), U(0.034)), (U(x0 - 0.09), U(0.02)), (U(x0 - 0.09), 0.0001)], 12)
            o = len(BV); BV += [(v[0], v[1] + U(y), v[2] + U(0.0)) for v in V_]; BF += [tuple(q + o for q in f) for f in F_]
    K._obj('in_bombs', BV, BF, 'magazine', inside=True)
    K.inside.append(dict(kind='space', name='bombs', mat='magazine', x=(U(-0.09), U(0.26)), y=(U(-0.146), U(0.146)), z=(U(-0.034), U(0.034)),
                         note='eight bombs racked in two rows of four (the magazine the hull is built round)'))
    K.inside.append(dict(kind='note', name='insides', note='A craft: the game shows its death as a spark and hides it (godot/fx/fx_death.gd _wing_death); nothing breaks open. The magazine rooms are here because the build contract needs an inside (tools/blender/build_sheets/contract.py) and because the magazine is the bomber\'s story; they cost few triangles.'))
    K.armour('block', U(0.006), 'the magazine block\'s plate')
    K.armour('bow cassette', U(0.02), 'the heaviest armour, round the tubes')
    reach = 0.4
    K.break_line('B-1', U(-0.185), 'the magazine tears from the reactor section (only for the recipe\'s records: the game never breaks a craft)',
                 path=[(U(-0.185), U(reach)), (U(-0.185), U(0.2)), (U(-0.178), U(0.08)), (U(-0.192), U(-0.03)), (U(-0.181), U(-0.14)), (U(-0.185), U(-reach))])
    K.point('core', 'hp_core', (U(-0.25), 0.0, 0.0))

    # ---------- changed from the picture (designer's decisions, R207, R233, R236) ----------
    K.change('Length 1.6 (CLS_LEN Squadron; drawn 3.84 on the board), the same as the fighter, not the notes\' 4.2 units',
             'docs/playbooks/scale.md, Squadron rows, binding (it wins over the design notes); the bomber reads apart by its mass: about twice the fighter\'s beam and three times its depth')
    K.change('The two tube mouths sit in a deep armoured cassette that is the bow face: dark bores 0.22 deep with the next bomb\'s nose seated in each, heavy twelve-sided rims with forged lugs',
             'R244: a round opening is a real recess with depth and detail, never a disc; the notes: ordnance internal, the hull IS the magazine')
    K.change('The tubes are fixed forward, not on a traverse cassette',
             'a craft turns onto its target on a strafing run; a turning cassette in the bow face would need the hull round it cut free. The weapon-match table allows bombs (arc T) on a fixed bomb-tube launcher (weapon_match.py FITS, the Board\'s reading of rule 11 for craft)')
    K.change('The rims are worked iron (lighter) round the dark mouths', 'the concept\'s worn grey rims; a light ring round a dark mouth is what reads at the close cameras')
    K.change('The bombardier\'s sight slit between the mouths belongs to the cassette', 'it aims the tubes (the concept\'s recessed sensor slit at the centre of the bow face)')
    K.change('Four drives: two pairs of deep bells sunk in eight-sided armoured cowls in the stern face, not the concept\'s side pods with rows of small glowing nozzles',
             'the owner\'s rule for craft: drives are nozzle clusters inside armoured blocks; four bold bells read at the battle camera where a row of small nozzles would not')
    K.change('The concept\'s many flank panels and boxes become one forged belt a side over the flank band; the small grilles and boxes are not modelled',
             'fine greeble reads as a shrunken capital ship at this size (both design legs, production notes); R244: the flanks are angled chamfers round a band with a raised belt, never a flat wall')
    K.change('The two dorsal blocks are the magazine ridges, one over each bomb row; their aft ends carry the drive room\'s heat louvres (the concept\'s ember roof slits)',
             'every part has a job (R221): each ridge roofs the row that feeds one tube')
    K.change('No hatches, lamps or attitude thrusters', 'below what the battle camera shows on a 3.84 unit craft; the drives turn the craft; bold and simple')
    K.change('A small inside: two magazine rows with eight bombs, the bombardier\'s cell, the reactor, the drive room; one seam (B-1)',
             'the game shows a craft\'s death as a spark and hides it (fx_death.gd _wing_death), so nothing breaks open; the build contract needs an inside and a seam, and the magazine is the bomber\'s story')
    K.open_item('The frost-white oath band across one shoulder and the ember trim are paint: the Sunward stack (issue 756) applies later')
    K.open_item('How a sheet craft reaches the game: the game builds every craft in code today (godot/render/squadron_craft.gd), so no stage 7 export or install here')
    K.open_item('At the battle camera the bomber reads by its block and its four ember drives; the two bow mouths read at the close cameras (voidsworn_SF3_SB4_battle_cam.jpg)')

    for m_ in getattr(HP, 'METALLIC', ()):
        if m_ in bpy.data.materials:
            bpy.data.materials[m_].node_tree.nodes['Principled BSDF'].inputs['Metallic'].default_value = 0.3

    def keep(pc, hd):
        return any((pc - c_).length < r__ + hd * 0.6 for c_, r__ in K.keepouts)
    for nm_, rs_, spec in plate_jobs:
        acc, (RV, RF), laid = HP.forged_plates(rs_, spec['faces'], spec['size'], spec['thick'], spec['mats'], seed=spec['seed'], keep=keep,
                                               tri=spec.get('tri', False), rr=spec['rr'], unit=spec['unit'], closed=spec.get('closed', True))
        for m_, (V_, F_) in acc.items():
            if V_:
                K._obj('SB4_%s_plates_%s' % (nm_, m_), V_, F_, m_, grp='hull')
        if RV:
            K._obj('SB4_%s_rivets' % nm_, RV, RF, 'sworn', grp='hull')
        K.built.append(dict(id='SB4_%s_plates' % nm_, kind='plate', type='plate', inv=[spec['inv']], shaped=True, detailed=laid > 0,
                            subs=['slab', 'step', 'bevel', 'rivet']))
