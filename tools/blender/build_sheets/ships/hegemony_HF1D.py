# hegemony_HF1D: the Hegemony Navy fighter wing craft, the Spined Shield (data.js fighter: cls 'Squadron', guns T; hp 18, sp 6).
# Issue 793. Concept of record: contrib/muse/design/squadron_concepts_2026_11/hegemony/round_3/HF1D.jpg, the slimmed render
# (design_notes_785_round3.md; Ryan, Nov 15 2026, R259: "HF1D with the slimmed prow is good to go": HF1C's sleek body with HF1B's
# bow detail, the front slimmed so the whole reads more of a wedge). The written sheet governs where the render drifts (the
# render lights the sensor slot blue and sits flatter than HF1C; the notes keep the slit dark and HF1C's depth).
# Designer of record: the Opus builder, the Board the final designer (R205, R207, R233, R236): HF1D is a base, not a trace.
# Ryan's words that bind (R254, R259): no canopy, no swept aero wings, no tail fins, nothing hung under a hull; drives are nozzle
# clusters inside armoured blocks; each faction its own fighter (R253).
# Size: docs/playbooks/scale.md, Squadron row (binding): CLS_LEN['Squadron'] 1.6 long, drawn x SHIP_K 1.6 x SQUADRON_K 1.5 = 3.84 on
# the board, the same as every craft. Every station and size below is a share of LENGTH (the U() helper).
# +X bow, +Y port, +Z up. Prow tip x = +0.8, the drive pod's lip x = -0.8.
import math

CODE = 'hegemony_HF1D'
NAME = 'Spined Shield fighter (Hegemony Navy fighter wing craft)'
FACTION = 'Hegemony Navy (hegemony)'
CLASS = 'Squadron'
LENGTH = 1.6
GAME = "data.js fighter (cls 'Squadron', the Hegemony wing: hegemony sq 'fighter'); length from godot/render/hull_table.gd CLS_LEN['Squadron'] = 1.6 (drawn x SHIP_K 1.6 x SQUADRON_K 1.5 = 3.84 on the board, docs/playbooks/scale.md)"
BEAUTY = 'contrib/muse/design/squadron_concepts_2026_11/hegemony/round_3/HF1D.jpg'
KIT = 'hegemony'
CONCEPT_SHEET = BEAUTY
# the concept is one three-quarter picture (no true views): the nine-cell sheet shows its craft in place of the top and side views
CONCEPT_VIEWS = dict(top=dict(box=(40, 60, 1060, 660)), side=dict(box=(40, 60, 1060, 660)))
CROPS = [('bow (the slim prow, the framed recess, the cassette)', (40, 380, 520, 660)), ('midships (the ridge and the stepped edging)', (300, 130, 840, 520)),
         ('stern (the stern block and the drive slit)', (640, 50, 1060, 330))]
SHEET = dict(version=1, round='first sheet', date='2026-11-15', blend='opus793', px_per_unit=900, view_pad=0.12, label_scale=1.5, bar_units=0.5,
             blend_where='rendered in the issue 793 sandbox (Blender 5.3, Cycles CPU); not on the PC: `build.py hegemony_HF1D <out> render` rebuilds it from this file',
             before='First full layout', before_note='The first complete layout, built with the Hegemony kit\'s new craft parts and run through the fit check before any fix.',
             during='The table above is every finding, in the order the check made them.')


def U(v):
    """a share of the craft's length in world units"""
    return v * LENGTH


# ---------------------------------------------------------------------------------------------------- the hull section
# One machined wedge from the prow point to the stern. Its section (port half, shares of LENGTH): a flat deck, a small deck
# chamfer, then the flank in three stepped layers, each a step further out going down (HF1B's stepped plate edging, kept flush and
# shallow so it never reads as a wing or a ledge), a belly chamfer and a flat belly. In plan a long sleek point that widens to
# the stern third; the stern corners are cut.
# (n, hw: the lowest layer's half-beam, zt: deck, zb: belly)
ST = [
    (0.500, 0.003, 0.004, -0.003),
    (0.470, 0.013, 0.010, -0.008),
    (0.420, 0.030, 0.017, -0.014),
    (0.340, 0.054, 0.024, -0.020),
    (0.250, 0.078, 0.029, -0.025),
    (0.150, 0.103, 0.033, -0.029),
    (0.000, 0.138, 0.037, -0.032),
    (-0.200, 0.178, 0.040, -0.035),
    (-0.360, 0.200, 0.041, -0.036),
    (-0.420, 0.204, 0.041, -0.036),
    (-0.440, 0.192, 0.040, -0.035),
    (-0.455, 0.172, 0.039, -0.034),
]
X_END = -0.455    # the hull's stern face (the drive pod stands proud of it to -0.5)
STEP = 0.0095     # one edging step (share of LENGTH)
SHELL = U(0.0035)
HULL = [(U(r[0]), U(r[1]), U(r[1]), U(r[3]), U(r[2]), 0.0, 0.0) for r in ST]
# the ridge: (half-width, height over the deck, fore end, full height from, aft end), shares of LENGTH
RIDGE = (0.044, 0.023, 0.195, 0.155, -0.375)
# the stern block: (half-width, height over the deck, fore toe, full height from)
BLOCK = (0.13, 0.029, -0.335, -0.375)


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
    """the port half of the section at n (shares of LENGTH), deck centre to belly centre, inset inward by about inset"""
    _, hw, zt, zb = st_at(n)
    hw -= inset; zt -= inset; zb += inset
    s = min(STEP, hw * 0.1)
    z1 = zt - (zt - zb) * 0.34; z2 = zt - (zt - zb) * 0.66
    c = min(0.006, hw * 0.12, (zt - z1) * 0.45); cb = min(0.008, hw * 0.15, (z2 - zb) * 0.45)
    return [(0.0, zt), (hw - 2 * s - c, zt), (hw - 2 * s, zt - c), (hw - 2 * s, z1), (hw - s, z1), (hw - s, z2), (hw, z2), (hw, zb + cb),
            (hw - cb, zb), (0.0, zb)]


def ring(n, inset=0.0):
    h = half_ring(n, inset)
    full = h + [(-y, z) for (y, z) in reversed(h[1:-1])]
    return [(U(n), U(y), U(z)) for (y, z) in full]


def deck(n):
    """the deck's height at station n, world units"""
    return U(st_at(n)[2])


def half_w(n, z, inset=0.0):
    h = half_ring(n, inset)
    best = 0.0
    for (y0, z0), (y1, z1) in zip(h, h[1:]):
        if min(z0, z1) - 1e-9 <= z <= max(z0, z1) + 1e-9:
            best = max(best, y0, y1) if abs(z1 - z0) < 1e-9 else max(best, y0 + (y1 - y0) * (z - z0) / (z1 - z0))
    return best


def build(K):
    import bpy
    import kit as _k
    from mathutils import Vector
    HP = _k.HP
    for k_, v_ in getattr(HP, 'MATS', {}).items():   # the Hegemony colour zones live in the faction kit (tools/blender/kits/hegemony)
        _k.MATS.setdefault(k_, v_)
    K.hull_sections = [(U(r[0]), U(r[1]), U(r[1]), U(r[3]), U(r[2]), 0.0, 0.0) for r in ST]
    K.hull_rounded = False
    PV = 0.03   # the module grid's pitch along the craft (share of LENGTH): rings at an even pitch so seams line up (R243)
    ns = sorted({0.5, 0.47, 0.44} | {round(0.42 - i * PV, 4) for i in range(30) if 0.42 - i * PV > X_END + 0.004} | {X_END, -0.44, -0.42}, reverse=True)
    rings = [ring(n) for n in ns]
    hull = K.loft_rings(CODE + '_hull', rings, 'hgrey')
    md = hull.modifiers.new('shell', 'SOLIDIFY'); md.thickness = SHELL; md.offset = -1; md.use_rim = True
    K.mass('Hull: the machined wedge', hull, 'pale grey module plate',
           note='one sleek machined wedge: a flat deck, the flank in three stepped layers (the stepped plate edging), a flat belly; the prow slimmed to a point, the stern corners cut')
    K.mark('wedge', 'hull', ['facet', 'step', 'chamfer'])
    K.mark('edging', 'rail', ['facet', 'step', 'strip'])
    # ring edge indices (port half 0 to 8, starboard 9 to 17): 0 deck, 1 chamfer, 2 upper flank, 3 step, 4 middle flank, 5 step,
    # 6 lower flank, 7 belly chamfer, 8 belly; mirrored 17 deck, 16, 15 upper flank, 14, 13 middle flank, 12, 11 lower flank, 10, 9 belly
    grid = [r for n, r in zip(ns, rings) if n <= 0.44]
    plate_jobs = [('deck', grid, dict(faces=[0, 17], inv='wedge_panels')), ('flank', grid, dict(faces=[2, 4, 6, 11, 13, 15], inv='wedge_panels')),
                  ('belly', grid, dict(faces=[8, 9], inv='belly_panels'))]

    # ---------------- the ridge: the low broad flat-topped armoured ridge, bow block to stern block ----------------
    rw, rh, f0, f1, a0 = RIDGE
    xs = [f0, f1] + [round(f1 - PV * i, 4) for i in range(1, 30) if f1 - PV * i > a0] + [a0]

    def ridge_ring(n, k):
        zd = st_at(n)[2]; h = rh * k; c = min(0.006, h * 0.4) if h > 0.002 else 0.0
        pts = [(-rw, zd - 0.004), (-rw, zd + h - c), (-rw + c, zd + h), (rw - c, zd + h), (rw, zd + h - c), (rw, zd - 0.004)]
        return [(U(n), U(y), U(z)) for (y, z) in pts]
    rrings = [ridge_ring(n, 0.05 if n == f0 else 1.0) for n in xs]
    ob = K.loft_rings(CODE + '_ridge', rrings, 'hgrey')
    K.mass('The spine ridge', ob, 'pale grey module plate', note='the low broad flat-topped ridge, squared in section, from the bow block\'s top aft to the stern block; its sloped front face is the bow block\'s single-stage bevel')
    K.mark('ridge', 'spine', ['facet', 'step', 'strip'])
    plate_jobs.append(('ridge', rrings[1:], dict(faces=[1, 2, 3], inv='ridge_panels', closed=False)))

    # ---------------- the stern block: the armoured block that holds the reactor and the drive ----------------
    bw, bh, b0, b1 = BLOCK

    def block_ring(n, k):
        zd = st_at(n)[2]; h = bh * k; c = min(0.008, h * 0.4) if h > 0.002 else 0.0
        hw_ = min(bw, half_w(n, zd) - 0.004)
        pts = [(-hw_, zd - 0.004), (-hw_, zd + h - c), (-hw_ + c, zd + h), (hw_ - c, zd + h), (hw_, zd + h - c), (hw_, zd - 0.004)]
        return [(U(n), U(y), U(z)) for (y, z) in pts]
    bx = [b0, b1] + [round(b1 - 0.02 * i, 4) for i in range(1, 8) if b1 - 0.02 * i > X_END] + [X_END]
    brings = [block_ring(n, 0.05 if n == b0 else 1.0) for n in bx]
    ob = K.loft_rings(CODE + '_sternblock', brings, 'hgrey')
    K.mass('The stern block', ob, 'pale grey module plate', note='a raised armoured block across the stern, as tall as the ridge plus a step, a sloped front; the drive pod stands out of its aft face')
    K.mark('stern_block', 'tier', ['face', 'roof', 'opening'])
    plate_jobs.append(('block', brings[1:], dict(faces=[1, 2, 3], inv='block_panels', closed=False)))

    # ---------------- module bands: the joints where the craft gives way (factions.md "How it breaks": in modules) ----------------
    def band(tag, n, w=0.006, t=0.0028):
        h = half_ring(n)
        out = []
        for (y, z) in h[1:-1]:
            out.append((y, z))
        pts = []
        for (y, z) in [h[0]] + out + [h[-1]]:
            pts.append((y, z))
        V, F = [], []
        loop = pts + [(-y, z) for (y, z) in reversed(pts[1:-1])]
        cy = 0.0; cz = (h[0][1] + h[-1][1]) / 2
        nn = len(loop)
        for x in (n + w / 2, n - w / 2):
            for (y, z) in loop:
                dy, dz = y - cy, z - cz; L_ = math.hypot(dy, dz) or 1.0
                V.append((U(x), U(y + dy / L_ * t), U(z + dz / L_ * t)))
            for (y, z) in loop:
                V.append((U(x), U(y), U(z)))
        for i in range(nn):
            j = (i + 1) % nn
            F.append((i, j, 2 * nn + j, 2 * nn + i))
            F.append((nn + j, nn + i, 3 * nn + i, 3 * nn + j))
            F.append((j, i, nn + i, nn + j))
            F.append((2 * nn + i, 2 * nn + j, 3 * nn + j, 3 * nn + i))
        K._obj('HF1D_bandseam_%s' % tag, V, F, 'htrim', grp='hull')
    for tag, n in (('bow', 0.2), ('mid', -0.1), ('stern', -0.33)):
        band(tag, n)
    K.mark('module_bands', 'band', ['band', 'seam', 'strip'])

    # ---------------- the blue line: implant-blue strips along the upper edging step and the ridge's foot ----------------
    def blue_run(tag, pts, nrm):
        K.strip('HF1D_blue_%s' % tag, [tuple(U(c) for c in p) for p in pts], w=U(0.0022), t=U(0.0009), normals=[nrm] * len(pts), m='hblue', grp='hull')
    for side in (1, -1):
        sg = 'p' if side > 0 else 's'
        xs_ = [0.36 - 0.02 * i for i in range(43) if 0.36 - 0.02 * i > -0.43]
        blue_run('edge' + sg, [(n, side * (half_ring(n)[4][0] - 0.0015), half_ring(n)[4][1] + 0.0002) for n in xs_], (0, 0, 1))
        blue_run('ridge' + sg, [(n, side * (rw + 0.0012), st_at(n)[2] + 0.0035) for n in [f1 - 0.02 * i for i in range(27) if f1 - 0.02 * i > b1]], (0, side, 0))
    K.mark('blue_line', 'band', ['band', 'seam', 'strip'], fid='HF1D_blue')

    # ---------------- the gun cassette: on a flush ring sunk in the framed recess at the prow ----------------
    GX = 0.305
    K.gun('G1', (U(GX), 0.0, deck(GX)), 0.0, 3.0, barrels=3, cal=U(0.0025), blen=U(0.052), size=U(0.025), slot='T', weapon='guns', inv='guns',
          band=(0, 10, 20, 30, 45),
          note='the interceptor guns (data.js guns T, 3 shots): three barrels grouped tight in one cassette on a flush ring in the framed recess at the prow; every volley fires all three')

    # ---------------- the sensor slit: in its own slot in the ridge's sloped front face, above the recess ----------------
    n0, n1 = f0, f1
    a = Vector((U(n0), 0, U(st_at(n0)[2] + rh * 0.05))); b = Vector((U(n1), 0, U(st_at(n1)[2] + rh)))
    p = a.lerp(b, 0.55); nrm = Vector((-(b - a).z, 0, (b - a).x)).normalized()
    if nrm.x < 0:
        nrm = -nrm
    K._surface_part('W1', HP.slit(U(0.034), U(0.0055), depth=U(0.004), fr=U(0.0022), back=U(0.001), pane=U(0.0004)), tuple(p + nrm * U(0.0003)), tuple(nrm),
                    (0, 0, 1), 'sensor_slit', 'sensor slit %.3f x %.3f' % (U(0.034), U(0.0055)), 'slit', 'picture',
                    'the pilot\'s sensor slit in its own slot in the ridge\'s sloped front face, above the recess: dark glass, no canopy', aperture=U(0.2))
    for o_ in K.coll.objects:   # the round 3 notes keep the slit dark: its pane is dark glass, not the kit's lit window
        if o_.get('grp') == 'W1' and o_.type == 'MESH' and o_.data.materials and o_.data.materials[0].name == 'hwin':
            o_.data.materials[0] = _k.mat('dark')

    # ---------------- the drive: one recessed rectangular slit split into a row of three cells, in an armoured pod ----------------
    WD, HD = 0.165, 0.032
    zc = 0.016   # the pod centred on the stern face (belly -0.034 to the block's top 0.068)
    K.engine('E1', (U(-0.5 + 0.003), 0.0, U(zc)), U(HD / 2), U(0.1), bell=1.0, body_r=U(0.05), kw=dict(craft=True, w=U(WD), h=U(HD), cells=3), inv='drive',
             note='the drive: one recessed ion-blue slit across the stern block\'s aft face, three cells behind upright guide vanes (the faction\'s flat row of rectangular nozzles), in an armoured pod')
    K.features[-1]['what'] = 'drive, rectangular slit %.2f x %.2f, three cells' % (U(WD), U(HD))

    # ---------------- colour zones ----------------
    K.colour('pale grey module plate, steel-blue trim on the bands, the edging and the frame (paint stage)', U(0.5), U(-0.5), 'whole hull')
    K.colour('implant-blue light: the edging line, the ridge\'s foot, the drive slit', U(0.4), U(-0.5), 'the blue line')
    K.colour('no warm light, no rust, no canopy glass; the sensor slit stays dark', U(0.5), U(-0.5), 'factions.md Never; Ryan R254; the round 3 notes')

    # ---------------- INSIDE: kept small; the build contract needs one, the death effect does not ----------------
    IN = SHELL / LENGTH + 0.002

    def room(name, kind, n0_, n1_, z0, z1, y=None, note=''):
        hw = min(half_w(n_, z_, IN) for n_ in (n0_, n1_, (n0_ + n1_) / 2) for z_ in (z0, z1)) - 0.002
        if y is not None:
            hw = min(hw, y)
        K.room(name, kind, U(min(n0_, n1_)), U(max(n0_, n1_)), -U(hw), U(hw), U(z0), U(z1), note=note)
    room('gun_feed', 'magazine', 0.27, 0.2, -0.017, 0.02, y=0.03, note='the cassette\'s charge cells and feed, under the framed recess')
    room('pilot', 'crew', 0.14, 0.02, -0.02, 0.05, y=0.026, note='the pilot\'s cell under the ridge, behind the sensor slit (a linked crew of one, lore 3)')
    room('reactor', 'core', -0.15, -0.3, -0.022, 0.05, y=0.06, note='the drive reactor, white-lit, under the ridge\'s aft end')
    room('drive_room', 'engroom', -0.34, -0.43, -0.022, 0.06, y=0.09, note='the drive room and the slit\'s feed, inside the stern block')
    K.armour('wedge', SHELL, 'machined plate over the whole hull')
    K.armour('stern block', U(0.006), 'over the reactor and the drive')
    reach = 0.32
    K.break_line('B-1', U(-0.1), 'the craft parts at its mid module band (Hegemony: in modules; only for the recipe\'s records: the game never breaks a craft)',
                 path=[(U(-0.1), U(reach)), (U(-0.1), U(0.1)), (U(-0.094), U(0.04)), (U(-0.106), U(-0.02)), (U(-0.097), U(-0.09)), (U(-0.1), U(-reach))])
    K.inside.append(dict(kind='note', name='insides', note='A craft: the game shows its death as a spark and hides it (godot/fx/fx_death.gd _wing_death); nothing breaks open. These few rooms are here because the build contract needs an inside (tools/blender/build_sheets/contract.py); they cost few triangles.'))
    K.point('core', 'hp_core', (U(-0.22), 0.0, U(0.01)))

    # ---------- changed from the picture (designer's decisions, R207, R233, R236) ----------
    K.change('Length 1.6 (CLS_LEN Squadron; drawn 3.84 on the board), the same as every craft',
             'docs/playbooks/scale.md, Squadron rows, binding; the fighter reads apart from the bomber by its outline, not its length')
    K.change('The gun cassette turns: it sits on a flush ring inside the framed recess, a low flat housing round a cassette of three tightly grouped barrels; at rest it faces forward out of its frame',
             'data.js guns fires all round (arc T), so the guns are a turret (ships.md rule 11 for craft, weapon_match.py FITS guns: turret); the recess frame, the grouping and the place at the prow are the concept\'s')
    K.change('The recess is a flat framed well in the prow deck, not a vertical bow face',
             'the round 3 notes put the cassette in a face recess, the slim render on the sloped deck near the tip; a turret needs a deck under it, and the slim prow is too thin for a face recess. The render stands as the silhouette, the sheet keeps the frame and the place')
    K.change('The ridge starts behind the gun recess (its sloped front face holds the sensor slit) and runs to the stern block, no taller than it',
             'a turning cassette needs the deck clear behind it: the barrels clear the ridge front by 0.06 when turned aft (the fit check sweeps every bearing); the notes put the slit in its own slot above the recess')
    K.change('The sensor slit is dark glass with a machined frame, not lit blue', 'the round 3 notes: the render lights the slot blue; the sheet keeps it dark, ion glow only at the stern')
    K.change('The hull keeps HF1C\'s depth: about 0.075 of the length at the stern, more with the ridge and the stern block',
             'the round 3 notes: the slim render reads very flat from above; the hull keeps HF1C\'s depth so it reads as a machined wedge, never a flat wing')
    K.change('The stepped edging is three stepped flank layers, each a 0.015 step out going down, with the implant-blue line along the upper step',
             'HF1B\'s edging kept flush and shallow (DeepSeek): steps, never ledges or wings; factions.md: a pale wedge with a line of blue light')
    K.change('The drive slit is one recessed rectangular mouth split by two upright guide vanes into three cells, in an armoured pod that stands 0.07 out of the stern face',
             'factions.md: a flat row of rectangular blue-white nozzles; the owner\'s rule for craft: nozzle clusters inside armoured blocks')
    K.change('Three module bands cross the hull (at the bow block, midships and the stern block); the craft gives way at the midships band (B-1)',
             'factions.md: the Hegemony breaks in modules, at the bands; the paint stack keys its module band on every *_bandseam_* joint')
    K.change('No hatches, lamps, thrusters, drone bays or antennas', 'below what the battle camera shows on a 3.84 unit craft (about 30 px long); the drive turns the craft; bold and simple')
    K.change('A small inside: the gun feed, the pilot\'s cell, the reactor, the drive room; one seam (B-1)',
             'the game shows a craft\'s death as a spark and hides it (fx_death.gd _wing_death), so nothing breaks open; the build contract needs an inside and a seam (tools/blender/build_sheets/contract.py)')
    K.open_item('Pale grey, steel-blue trim and the blue line are schematic colour zones: the Hegemony paint stack (issue 780) applies later')
    K.open_item('How a sheet craft reaches the game: the game builds every craft in code today (godot/render/squadron_craft.gd), so no stage 7 export or install here')

    for m_ in getattr(HP, 'METALLIC', ()):
        if m_ in bpy.data.materials:
            bpy.data.materials[m_].node_tree.nodes['Principled BSDF'].inputs['Metallic'].default_value = 0.35

    # ---------- the flush panel grid, laid last so every mount has claimed its ground (keep-outs) ----------
    def keep(pc, hd):
        if abs(pc.y) < U(rw + 0.004) and U(a0) - 0.01 < pc.x < U(f0) + 0.01 and deck(pc.x / LENGTH) - 0.01 < pc.z < deck(pc.x / LENGTH) + U(0.004):
            return True   # the deck under the ridge
        if abs(pc.y) < U(bw + 0.004) and pc.x < U(b0) + 0.01 and pc.z > deck(pc.x / LENGTH) - 0.01 and pc.z < deck(pc.x / LENGTH) + U(0.004):
            return True   # the deck under the stern block
        return any((pc - c_).length < r_ + hd * 0.6 for c_, r_ in K.keepouts)
    for nm_, rs_, spec in plate_jobs:
        acc, laid = HP.module_panels(rs_, spec['faces'], pv=U(0.045), t_big=U(0.0019), t_small=U(0.0013), keep=keep, closed=spec.get('closed', True),
                                     gap=U(0.0016), unit=U(0.05))
        for m_, (V_, F_) in acc.items():
            if V_:
                K._obj('HF1D_%s_panels_%s' % (nm_, m_), V_, F_, m_, grp='hull')
        K.built.append(dict(id='HF1D_%s_panels' % nm_, kind='plate', type='plate', inv=[spec['inv']], shaped=True, detailed=laid > 0,
                            subs=['panel', 'seam', 'module']))
