# voidsworn_SF3: the Sunward Crusade fighter wing craft, the Spire Dart (data.js fighter: cls 'Squadron', guns T; hp 18, sp 6).
# Issue 769. Concept of record: contrib/muse/design/squadron_concepts_2026_11/sunward/round_2/SF3.jpg (Ryan, Nov 14 23:57 CST,
# R255: "Agree on sf3 and sb4"; design_notes_757.md section SF3). The notes' own ruling block names SF4 (23:51); R255, six
# minutes later, and the issue name SF3, so SF3 is built and the mismatch is reported to the Board.
# Designer of record: the Opus builder, the Board the final designer (R205, R207, R233, R236): SF3 is a base, not a trace.
# Ryan's words that bind (design_notes_757.md, R254): the round 1 craft "all look like they're aerial fighters, not space
# fighters": no canopy (an armoured sensor slit at most), no swept aero wings, no tail fins, no bombs hung under the hull;
# drives are nozzle clusters inside armoured blocks.
# Size: docs/playbooks/scale.md, Squadron row (binding; it wins over the notes' 3.2 units): every craft is CLS_LEN['Squadron']
# 1.6 long (godot/render/hull_table.gd), drawn x SHIP_K 1.6 x SQUADRON_K 1.5 = 3.84 on the board, fighter and bomber alike.
# Every station and size below is a share of LENGTH (the U() helper), so the Board can change the length in one line.
# +X bow, +Y port, +Z up. Bow tip x = +0.8, the drive cowls' aft faces x = -0.8.
import math

CODE = 'voidsworn_SF3'
NAME = 'Spire Dart fighter (Sunward Crusade fighter wing craft)'
FACTION = 'Sunward Crusade (voidsworn)'
CLASS = 'Squadron'
LENGTH = 1.6
GAME = "data.js fighter (cls 'Squadron', the Sunward wing: voidsworn sq 'fighter'); length from godot/render/hull_table.gd CLS_LEN['Squadron'] = 1.6 (drawn x SHIP_K 1.6 x SQUADRON_K 1.5 = 3.84 on the board, docs/playbooks/scale.md)"
BEAUTY = 'contrib/muse/design/squadron_concepts_2026_11/sunward/round_2/SF3.jpg'
KIT = 'voidsworn'
CONCEPT_SHEET = BEAUTY
# the concept is one three-quarter picture (no true views): the nine-cell sheet shows its craft in place of the top and side views
CONCEPT_VIEWS = dict(top=dict(box=(120, 170, 940, 590)), side=dict(box=(120, 170, 940, 590)))
CROPS = [('bow (the blade and the gun well)', (120, 170, 520, 470)), ('midships (the spire and the stern block)', (440, 230, 840, 530)),
         ('stern (the drives)', (600, 330, 960, 600))]
SHEET = dict(version=1, round='first sheet', date='2026-11-15', blend='opus769', px_per_unit=900, view_pad=0.12, label_scale=1.5, bar_units=0.5,
             blend_where='rendered in the issue 769 sandbox (Blender 5.3, Cycles CPU); not on the PC: `build.py voidsworn_SF3 <out> render` rebuilds it from this file',
             before='First full layout', before_note='The first complete layout, built with the Sunward kit\'s new craft parts and run through the fit check before any fix.',
             during='The table above is every finding, in the order the check made them. Beyond the fit check, the sheet\'s own looks sent back: '
                    'the first plating (small plates, many rivets) read as a shrunken capital ship, so the plates were made larger and the rivets smaller; the heat louvre\'s ember '
                    'back plate stood in front of its slats on so small a louvre (the kit now keeps it behind them).')


def U(v):
    """a share of the craft's length in world units"""
    return v * LENGTH


# ---------------------------------------------------------------------------------------------------- the hull section
# One loft from the point to the stern face. Its section (port half, shares of LENGTH): a raised centre (a low spine strip
# forward that grows into the armoured stern block aft), the block's chamfer and flank, the deck, the upper facet sloping out
# to the knife edge (thin, never a wing: the blade is one solid body with no aerofoil and no sweep), the lower facet, a flat belly.
# (n, hw: half-beam at the knife edge, zt: deck, zb: belly, sw: the raised centre's half-width, ztop: its top, c: its chamfer)
ST = [
    (0.500, 0.003, 0.0035, -0.003, 0.0006, 0.0040, 0.0),
    (0.460, 0.016, 0.0090, -0.007, 0.0030, 0.0100, 0.0),
    (0.380, 0.040, 0.0160, -0.013, 0.0060, 0.0170, 0.0),
    (0.260, 0.068, 0.0220, -0.019, 0.0080, 0.0225, 0.0),
    (0.150, 0.087, 0.0250, -0.022, 0.0090, 0.0255, 0.0),
    (0.090, 0.095, 0.0265, -0.023, 0.0120, 0.0300, 0.001),
    (-0.020, 0.106, 0.0280, -0.025, 0.0200, 0.0350, 0.003),
    (-0.095, 0.110, 0.0280, -0.025, 0.0300, 0.0380, 0.005),
    (-0.175, 0.114, 0.0280, -0.026, 0.0740, 0.0880, 0.020),
    (-0.300, 0.116, 0.0270, -0.025, 0.0780, 0.0910, 0.022),
    (-0.420, 0.114, 0.0260, -0.024, 0.0790, 0.0910, 0.022),
    (-0.445, 0.110, 0.0250, -0.023, 0.0770, 0.0870, 0.024),
]
DWF = 0.42        # the deck's half-width share of hw
BWF = 0.38        # the belly's half-width share of hw
EDGE = 0.004      # the knife edge's half thickness (share of LENGTH)
SHELL = U(0.0035)  # hull thickness (the solidify shell)
# the sheet tools' loft format (x, half-beam port, half-beam starboard, belly, deck, -, -), for layout.py (the prow overhang)
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
    """the port half of the section at n (shares of LENGTH), top centre to belly centre, inset inward by about inset"""
    _, hw, zt, zb, sw, ztop, c = st_at(n)
    hw -= inset; zt -= inset; zb += inset; ztop -= inset; sw = max(0.0004, sw - inset)
    et = min(EDGE, max(0.0005, 0.45 * (zt - zb)))
    dw = max(sw + 0.001, hw * DWF); bw = max(0.001, hw * BWF)
    c = min(c, sw * 0.6, max(0.0, ztop - zt) * 0.6)
    return [(0.0, ztop), (sw - c, ztop), (sw, ztop - c), (sw, zt), (dw, zt), (hw, et), (hw, -et), (bw, zb), (0.0, zb)]


def ring(n, inset=0.0):
    h = half_ring(n, inset)
    full = h + [(-y, z) for (y, z) in reversed(h[1:-1])]
    return [(U(n), U(y), U(z)) for (y, z) in full]


def top_z(n, y=0.0):
    """the hull's top at station n and offset y (both shares of LENGTH), in world units"""
    h = half_ring(n)
    y = abs(y)
    for (y0, z0), (y1, z1) in zip(h, h[1:5]):
        if min(y0, y1) - 1e-9 <= y <= max(y0, y1) + 1e-9 and abs(y1 - y0) > 1e-9:
            return U(z0 + (z1 - z0) * (y - y0) / (y1 - y0))
    return U(h[3][1])


def build(K):
    import bpy
    import kit as _k
    from mathutils import Vector
    HP = _k.HP
    for k_, v_ in getattr(HP, 'MATS', {}).items():   # the Sunward colour zones live in the faction kit (tools/blender/kits/voidsworn)
        _k.MATS.setdefault(k_, v_)
    K.hull_sections = [(U(r[0]), U(r[1]), U(r[1]), U(r[3]), U(r[2]), 0.0, 0.0) for r in ST]
    K.hull_rounded = False
    ns = sorted({r[0] for r in ST} | {0.5 - i * 0.025 for i in range(38)}, reverse=True)
    ns = [n for n in ns if n >= -0.445]
    rings = [ring(n) for n in ns]
    hull = K.loft_rings(CODE + '_hull', rings, 'siron')
    md = hull.modifiers.new('shell', 'SOLIDIFY'); md.thickness = SHELL; md.offset = -1; md.use_rim = True
    K.mass('Hull: the forged blade', hull, 'black iron plate',
           note='one narrow forged blade: a low spine strip, the deck, upper facets out to a thin knife edge, lower facets, a flat belly; thickened at the stern into the armoured block')
    K.mark('blade', 'hull', ['facet', 'step', 'chamfer'])
    K.mark('stern_block', 'hull', ['facet', 'step', 'chamfer'])
    PL = dict(thick=(U(0.0016), U(0.0026)), unit=U(0.06), rr=U(0.0012))
    fwd = [r for n, r in zip(ns, rings) if n >= -0.1]
    aft = [r for n, r in zip(ns, rings) if n <= -0.1]
    plate_jobs = [('deck', rings, dict(PL, faces=[3, 12], size=(U(0.04), U(0.12)), mats={'siron': 3, 'siron2': 2}, seed=11, inv='blade_plates')),
                  ('facet', fwd, dict(PL, faces=[4, 11], size=(U(0.04), U(0.11)), tri=True, mats={'siron': 3, 'siron2': 2}, seed=12, inv='blade_plates')),
                  ('facet_aft', aft, dict(PL, faces=[4, 11], size=(U(0.04), U(0.11)), mats={'siron': 3, 'siron2': 2}, seed=13, inv='blade_plates')),
                  ('lower', rings, dict(PL, faces=[6, 9], size=(U(0.045), U(0.13)), mats={'siron2': 3, 'siron': 2}, seed=14, inv='blade_plates')),
                  ('belly', rings, dict(PL, faces=[7, 8], size=(U(0.05), U(0.14)), mats={'siron2': 3, 'siron': 2}, seed=15, inv='blade_plates')),
                  ('block', aft, dict(PL, faces=[0, 15, 2, 13], size=(U(0.045), U(0.1)), mats={'siron': 3, 'siron2': 2}, seed=16, inv='block_plates'))]

    # ---------------- the gun well: the interceptor guns on a shallow traverse ring, sunk in the blade's back near the bow ----------------
    GX = 0.21
    K.gun('G1', (U(GX), 0.0, top_z(GX)), 0.0, 5.0, barrels=3, cal=U(0.003), blen=U(0.06), size=U(0.03), slot='T', weapon='guns', inv='guns',
          band=(0, 10, 20, 30, 45),
          note='the interceptor guns (data.js guns T, 3 shots): three barrels in one emitter cluster on a traverse ring in an armoured well; every volley fires all three')

    # ---------------- the spire: one radiator spire on the stern block, the flagship's spire line reduced to one ----------------
    SX = -0.25
    part = HP.craft_spire(U(0.115), U(0.075), U(0.012), U(0.04), fins=4)
    K.organ('R1', part, (U(SX), 0.0, top_z(SX)), (0, 0, 1), fwd=(1, 0, 0), inv='spire', what='radiator spire, %.2f tall, four ember fins a side' % U(0.115),
            kind='radiator', note='sheds the drive reactor\'s heat: a square-topped column of iron posts round a dark core, ember fins reaching out to each side')
    K.mass('Radiator spire R1', bpy.data.objects['R1_body_embar'], 'ember fins on iron', note='the fighter\'s one spire (SF3)')

    # ---------------- the pilot's sensor slit in the stern block's sloping face (no canopy) ----------------
    n0, n1 = -0.095, -0.175
    a = Vector((U(n0), 0, U(st_at(n0)[5]))); b = Vector((U(n1), 0, U(st_at(n1)[5])))
    t = 0.55
    p = a.lerp(b, t); nrm = Vector(((b - a).z, 0, -(b - a).x)).normalized()
    if nrm.z < 0:
        nrm = -nrm
    K._surface_part('W1', HP.slit(U(0.034), U(0.008), depth=U(0.006), fr=U(0.004)), tuple(p + nrm * U(0.0005)), tuple(nrm), (0, 0, 1), 'sensor_slit',
                    'armoured sensor slit %.3f x %.3f' % (U(0.034), U(0.008)), 'slit', 'picture',
                    'the pilot looks out through an ember-lit armoured slit in the stern block\'s sloping face: no canopy, no glass bubble', aperture=U(0.2))

    # ---------------- the drives: two deep bells sunk in armoured cowls in the stern face ----------------
    R_EX = 0.024
    XE = -0.5 + 0.35 * R_EX + 0.0012   # the cowl's face studs end at the stern, -0.5
    for side in (1, -1):
        K.engine('E%d' % (1 if side > 0 else 2), (U(XE), side * U(0.04), U(0.024)), U(R_EX), U(0.075), bell=1.0, body_r=U(0.0348), rings=1,
                 kw=dict(craft=True), inv='drives',
                 note='%s drive: a deep bell sunk in an eight-sided armoured cowl, ember lining and plug, dim like banked coals' % ('port' if side > 0 else 'starboard'))

    # ---------------- the drive heat louvres on the stern block's flanks ----------------
    for side in (1, -1):
        n = -0.33
        sw = st_at(n)[4]
        K._surface_part('V1' + ('p' if side > 0 else 's'), HP.vent(U(0.09), U(0.032), slats=4, depth=U(0.006), fr=U(0.006)),
                        (U(n), side * (U(sw) + U(0.0005)), U(0.048)), (0, side, 0), (0, 0, 1), 'louvres', 'heat louvre %.3f x %.3f' % (U(0.09), U(0.032)), 'vent',
                        'picture', 'the drive room\'s heat louvre: slanted slats over an ember-lit recess (the concept\'s glowing flank slats)', aperture=U(0.15))

    # ---------------- colour zones ----------------
    K.colour('black iron plate, frost-white oath stripe along the blade edge (paint stage)', U(0.5), U(-0.5), 'whole hull')
    K.colour('ember glow (the spire\'s fins, the drive throats, the sensor slit, the louvres)', U(-0.1), U(-0.5), 'the spire, the bells, the slit')
    K.colour('no rust anywhere, no blue light, no canopy glass', U(0.5), U(-0.5), 'factions.md Never; Ryan R254')

    # ---------------- INSIDE: kept small; the build contract needs one, the death effect does not ----------------
    IN = SHELL / LENGTH + 0.002

    def room(name, kind, n0_, n1_, z0, z1, y=None, note=''):
        hw = min(half_w(n_, z_, IN) for n_ in (n0_, n1_, (n0_ + n1_) / 2) for z_ in (z0, z1)) - 0.002
        if y is not None:
            hw = min(hw, y)
        K.room(name, kind, U(min(n0_, n1_)), U(max(n0_, n1_)), -U(hw), U(hw), U(z0), U(z1), note=note)

    def half_w(n_, z_, inset):
        h = half_ring(n_, inset)
        best = 0.0
        for (y0, z0_), (y1, z1_) in zip(h, h[1:]):
            if min(z0_, z1_) - 1e-9 <= z_ <= max(z0_, z1_) + 1e-9:
                best = max(best, y0, y1) if abs(z1_ - z0_) < 1e-9 else max(best, y0 + (y1 - y0) * (z_ - z0_) / (z1_ - z0_))
        return best
    room('gun_feed', 'magazine', 0.16, 0.06, -0.012, 0.014, y=0.03, note='the interceptor guns\' ammunition drum and feed, behind the gun well')
    room('pilot', 'crew', -0.16, -0.225, 0.032, 0.062, y=0.03, note='the pilot\'s cell: a prone couch under the sensor slit (one unaugmented pilot, no AI, lore 2.5)')
    room('reactor', 'core', -0.235, -0.3, 0.032, 0.075, y=0.045, note='the drive reactor under the spire: its heat goes up into the spire')
    room('drive_room', 'engroom', -0.31, -0.405, -0.015, 0.075, y=0.06, note='the drive room and the two drives\' feeds')
    K.inside.append(dict(kind='note', name='insides', note='A craft: the game shows its death as a spark and hides it (godot/fx/fx_death.gd _wing_death); nothing breaks open. These few rooms are here because the build contract needs an inside (tools/blender/build_sheets/contract.py); they cost few triangles.'))
    K.armour('stern block', U(0.0035), 'over the pilot, the reactor and the drives')
    K.armour('blade', U(0.0035), '')
    reach = 0.2
    K.break_line('B-1', U(-0.1), 'the stern block tears from the blade at the block\'s toe (only for the recipe\'s records: the game never breaks a craft)',
                 path=[(U(-0.1), U(reach)), (U(-0.1), U(0.06)), (U(-0.093), U(0.02)), (U(-0.104), U(-0.02)), (U(-0.098), U(-0.06)), (U(-0.1), U(-reach))])
    K.point('core', 'hp_core', (U(-0.26), 0.0, U(0.05)))

    # ---------- changed from the picture (designer's decisions, R207, R233, R236) ----------
    K.change('Length 1.6 (CLS_LEN Squadron; drawn 3.84 on the board), the same as the bomber, not the notes\' 3.2 units',
             'docs/playbooks/scale.md, Squadron rows, binding (it wins over the design notes): "same wing frame as a fighter, only its load differs"; the fighter reads apart by its slim outline, not its length')
    K.change('The spire is an upright, square-topped radiator with four ember fins reaching out to each side, standing on the stern block, not the concept\'s raked fin',
             'Ryan (R254): no tail fins; the council flagged spires drifting into stabiliser reads (design_notes_757.md); factions.md: the spires are radiators. A raked blade on the stern reads as a tail fin; fins out to the sides read as a radiator from the battle camera and from above')
    K.change('The two drives are deep bells sunk in eight-sided armoured cowls in the stern face, smaller (0.077 across) and dim, not two big protruding drums with bright bells',
             'the production notes: SF3\'s bells render oversized and brighter than banked coals, the sheet dims and shrinks them (R55); the owner\'s rule for craft: drives are nozzle clusters inside armoured blocks')
    K.change('The interceptor guns turn on a shallow traverse ring in an armoured well on the blade\'s back near the bow (the concept\'s dorsal bow recess), three barrels in one emitter cluster',
             'data.js guns fires all round (arc T): the fit check sweeps the guns through every bearing, which a gun in the nose face cannot do; the notes let the sheet pick the dorsal recess or the nose face, and DeepSeek\'s traverse ring is in the callout (R241, ships.md rule 11)')
    K.change('The guns elevate to 45 degrees (the fit check\'s band 0 to 45)',
             'interceptor guns engage craft above and below the wing; dead astern the line clears the spire from 30 degrees up (the ARC test)')
    K.change('An armoured sensor slit for the pilot in the stern block\'s sloping face',
             'Ryan (R254): no canopy, an armoured slit at most; one unaugmented pilot, no AI (lore 2.5), so the pilot needs a view out')
    K.change('The concept\'s glowing flank slats are the drive room\'s heat louvres; its glyph decals and small panels are not modelled',
             'every part has a job (R221); the decals are generator noise (production notes); fine greeble reads as a shrunken capital ship at this size (both design legs)')
    K.change('No hatches, lamps or attitude thrusters', 'below what the battle camera shows on a 3.84 unit craft (about 30 px long); the drives turn the craft; bold and simple (production notes)')
    K.change('A small inside: the gun feed, the pilot\'s cell, the reactor under the spire, the drive room; one seam (B-1)',
             'the game shows a craft\'s death as a spark and hides it (fx_death.gd _wing_death), so nothing breaks open; the build contract needs an inside and a seam (tools/blender/build_sheets/contract.py)')
    K.fix('G1: a turning piece (the mantlet) inside the blade, and the cluster striking the deck when turned aft (SWEEP, every bearing)',
          'the trunnion raised from 0.3 to 0.4 of the ring\'s radius, the mantlet set inside the housing\'s height, the guns resting 5 degrees up (the deck rises toward the stern block)')
    K.open_item('The frost-white oath stripe along the blade edge, the trim and the ember lines are paint: the Sunward stack (issue 756) applies later')
    K.open_item('How a sheet craft reaches the game: the game builds every craft in code today (godot/render/squadron_craft.gd), so no stage 7 export or install here')

    for m_ in getattr(HP, 'METALLIC', ()):   # worked metal, as the sheet kit renders its own metal rows
        if m_ in bpy.data.materials:
            bpy.data.materials[m_].node_tree.nodes['Principled BSDF'].inputs['Metallic'].default_value = 0.3

    # ---------- the forged plating, laid last so every mount has claimed its ground (keep-outs) ----------
    def keep(pc, hd):
        return any((pc - c_).length < r_ + hd * 0.6 for c_, r_ in K.keepouts)
    for nm_, rs_, spec in plate_jobs:
        acc, (RV, RF), laid = HP.forged_plates(rs_, spec['faces'], spec['size'], spec['thick'], spec['mats'], seed=spec['seed'], keep=keep,
                                               tri=spec.get('tri', False), rr=spec['rr'], unit=spec['unit'])
        for m_, (V_, F_) in acc.items():
            if V_:
                K._obj('SF3_%s_plates_%s' % (nm_, m_), V_, F_, m_, grp='hull')
        if RV:
            K._obj('SF3_%s_rivets' % nm_, RV, RF, 'sworn', grp='hull')
        K.built.append(dict(id='SF3_%s_plates' % nm_, kind='plate', type='plate', inv=[spec['inv']], shaped=True, detailed=laid > 0,
                            subs=['slab', 'step', 'bevel', 'rivet']))
