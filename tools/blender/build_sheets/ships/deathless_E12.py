# deathless_E12: Eclipse zenith, the ring cruiser (class Cruiser, 14.5 world units). Issue 532, Eclipse build sheets.
# Accepted picture: contrib/muse/design/concept_round8c_2026_11/deathless_E12_beauty.jpg and _sheet.jpg (R206).
# data.js d_harvester: gauss T, gauss T, doom F, gsentry T; ability reclaim; no hangar.
# Designer of record: Opus (R205, R207). R207: "Where there are gaps like eclipse rings not all having structural
# connections ... you should build differently": every arc gets its own truss struts.
# Measured off the 8c sheet's plan (1259 px = 14.5 units): the ring an oval about 13 long and 8.1 wide, widest at 43 to
# 50 percent, broken at the bow (the emitter fires through the gap) and at the stern (the engine block); the arcs about 1.4
# deep; the core caged at the ring's centre; the stern block about 2.8 wide; hull length to beam 1.9; the whole ship low
# (the ring flat, the spine thin), the stern block and the core the tallest masses.
# +X bow, +Y port, +Z up. Bow (the fore arcs' tips) x = +7.25, engine exits x = -7.25.
import math

CODE = 'deathless_E12'
NAME = 'Eclipse zenith (the ring cruiser)'
FACTION = 'Eclipse (deathless)'
CLASS = 'Cruiser'
LENGTH = 14.5
GAME = "data.js d_harvester (cls 'Cruiser'); length from godot/render/hull_table.gd CLS_LEN['Cruiser'] = 14.5 (drawn x SHIP_K 1.6 = 23.2 on the board)"
BEAUTY = 'contrib/muse/design/concept_round8c_2026_11/deathless_E12_beauty.jpg'
KIT = 'eclipse'
CONCEPT_SHEET = 'contrib/muse/design/concept_round8c_2026_11/deathless_E12_sheet.jpg'
CONCEPT_VIEWS = dict(top=dict(box=(116, 40, 1376, 770), largest=False, flip=True), side=dict(box=(100, 850, 1395, 1080), largest=False, flip=True))
CROPS = [('bow (fore arcs, emitter, fore battery)', (1150, 40, 2000, 1000)), ('midships (core and centre arcs)', (620, 40, 1300, 1000)),
         ('stern (engine block, aft arcs)', (150, 200, 780, 900))]
SHEET = dict(version=3, round='third sheet (R221 weapons)', date='2026-11-12', blend='opus532e\\w\\w1',
             alt_cameras=dict(fwd='best ring overlap (forward of the starboard beam, high): the ring layout lines up, the bells cannot show'),
             before='First full layout', before_note='The first complete E12 layout, built with the Eclipse kit and run through the check before any fix.',
             during='While designing, the check also caught (and the design fixed): the sentry twin sweeping through the block roof thrusters (moved forward), a roof hatch on a '
                    'thruster, the block\'s green lights inside the stern arcs (raised), and the heat panels touching the outer engine housings (moved forward).')

XC, AR, BR, WR = 0.97, 6.5, 4.07, 1.4    # the ring: centre x, outer semi-axes (along, across), radial depth
ZR, HR = -0.1, 0.42                      # the ring plane and its depth
ZS = 0.15                                # the spine axis
ARCS_T = [('fore', 15.0, 62.0), ('centre', 66.0, 104.0), ('aft', 108.0, 146.0), ('stern', 150.0, 168.0)]   # parametric angle, from the bow to port
# the stern spine and block, one loft (x, half-beam port, starboard, bottom, top, top chamfer, bottom chamfer): the hull
HULL = [
    (0.2, 0.18, 0.18, ZS - 0.16, ZS + 0.16, 0, 0),
    (-2.6, 0.2, 0.2, ZS - 0.17, ZS + 0.17, 0, 0),
    (-3.3, 0.85, 0.85, -0.36, 0.56, 0, 0),
    (-4.0, 1.38, 1.38, -0.6, 0.76, 0, 0),
    (-5.95, 1.48, 1.48, -0.62, 0.78, 0, 0),
    (-6.3, 1.38, 1.38, -0.55, 0.7, 0, 0),
]
PEXP = (3.0, 3.0)   # the block's section: a rounded box (the concept's block is round-shouldered, never a slab)
PL = dict(keep3d=True, size=(0.2, 0.45), thick=(0.04, 0.1), skip=0.06, stack=0.5, mats={'shade2': 5, 'violet': 3, 'shade': 3, 'mauve': 1})


def ring_pt(t_deg, r):
    """a point on the ring at parametric angle t (0 = bow, + to port), r = 0 the outer edge, 1 the inner edge: (x, y)"""
    t = math.radians(t_deg)
    a = AR - WR * r; b = BR - WR * r
    return XC + a * math.cos(t), b * math.sin(t)


def build(K):
    import kit as _k
    from mathutils import Vector

    hull = K.hull(HULL, 'shade', shell=0.12, plates=dict(PL, seed=51, inv='spine_plates'), rounded=True, pexp=PEXP)
    K.mass('Hull: the stern block and the aft spine', hull, 'deep violet plate', note='a round-shouldered block tapering forward into the spine')
    K.mass('Block roof step', K.loft('E12_roofstep', [(-4.2, 0.75, 0.75, 0.55, 0.86, 0.1, 0.0), (-4.45, 0.85, 0.85, 0.55, 0.9, 0.12, 0.0), (-5.7, 0.85, 0.85, 0.55, 0.9, 0.12, 0.0),
                                                     (-5.9, 0.75, 0.75, 0.55, 0.85, 0.1, 0.0)], 'violet', plates=dict(PL, seed=53, faces=[0, 1, 2, 3], size=(0.2, 0.4))),
           'violet plate', note='a raised plate step on the block roof, the sentry on it')
    K.mass('Block flank cheeks', K.loft('E12_cheeks', [(-4.3, 1.5, 1.5, -0.3, 0.42, 0.08, 0.08), (-5.75, 1.56, 1.56, -0.3, 0.42, 0.08, 0.08)], 'violet',
                                        plates=dict(PL, seed=54, faces=[6, 7, 0, 2, 3, 4], size=(0.2, 0.4))), 'violet plate', note='armour cheeks on the block flanks, the lights in them')
    K.mark('stern_block', 'tier', ['face', 'roof', 'opening'])
    fore = K.loft('E12_spine_fore', [(5.35, 0.17, 0.17, ZS - 0.15, ZS + 0.15, 0.05, 0.05), (4.9, 0.18, 0.18, ZS - 0.16, ZS + 0.16, 0.05, 0.05),
                                     (1.75, 0.18, 0.18, ZS - 0.16, ZS + 0.16, 0.05, 0.05)], 'shade2', plates=dict(PL, seed=52, inv='spine_plates'))
    K.mass('Spine, fore', fore, 'deep violet plate', note='the plated beam from the core to the emitter')
    # spine collars where fittings meet it (the steps)
    for i, x in enumerate((5.0, 2.25, -0.75, -1.95)):
        K.loft('E12_collar%d' % i, [(x + 0.1, 0.25, 0.25, ZS - 0.22, ZS + 0.22, 0.07, 0.07), (x - 0.1, 0.25, 0.25, ZS - 0.22, ZS + 0.22, 0.07, 0.07)], 'violet')
    K.mark('spine', 'hull', ['bevel', 'step', 'overhang'])
    K.mark('spine_plates', 'plate', ['slab', 'step', 'bevel', 'fastener'])

    # ---------------- the broken shade ring: eight box-section arcs, open on the inside ----------------
    tp, tw = 0.07, 0.1
    zb, zt = ZR - HR / 2, ZR + HR / 2
    narc = 0
    for side in (1, -1):
        for nm, t0, t1 in ARCS_T:
            n = max(4, int((t1 - t0) / 4.5))
            ts = [side * (t0 + (t1 - t0) * i / n) for i in range(n + 1)]
            rings = []
            for t in ts:
                sec = [(0.0, zb), (1.0, zb), (1.0, zb + tp), (tw, zb + tp), (tw, zt - tp), (0.58, zt - tp), (0.58, zt), (0.0, zt)]
                pts = []
                for r, z in sec:
                    x, y = ring_pt(t, r); pts.append((x, y, z))
                rings.append(pts if side > 0 else pts[::-1])
            ob = K.loft_rings('E12_arc_%s_%s' % (nm, 'p' if side > 0 else 's'), rings, 'shade',
                              plates=dict(PL, seed=60 + narc, faces=[6, 7, 0] if side > 0 else [0, 7, 6], size=(0.25, 0.5), inv='arc_plates'))
            K.mass('Arc, %s %s' % (nm, 'port' if side > 0 else 'starboard'), ob, 'deep violet plate', note='box-section shade arc, the inner bay open')
            # the corona line along the outer rim
            K.strip('E12_corona_%s_%s' % (nm, 'p' if side > 0 else 's'), [(*ring_pt(t, 0.02), zt + 0.002) for t in ts], w=0.034, t=0.022)
            # frames across the open bay and the machinery running along it
            nf = max(2, int((t1 - t0) / 7))
            for j in range(nf + 1):
                t = side * (t0 + (t1 - t0) * (j + 0.5) / (nf + 1))
                fr = []
                for r, z in ((tw, zb + tp), (0.98, zb + tp), (0.98, zb + tp + 0.08), (0.58, zt - tp), (tw, zt - tp)):
                    x, y = ring_pt(t, r); fr.append(Vector((x, y, z)))
                tang = (Vector((*ring_pt(t + 0.5, 0.5), 0)) - Vector((*ring_pt(t - 0.5, 0.5), 0))).normalized()
                K.loft_rings('E12_frame_%s_%s_%d' % (nm, 'p' if side > 0 else 's', j), [[q - tang * 0.03 for q in fr], [q + tang * 0.03 for q in fr]], 'gunv')
            for k_, (r, z, rad, m) in enumerate(((0.35, zb + tp + 0.09, 0.07, 'gunv'), (0.62, zb + tp + 0.07, 0.05, 'mauve'), (0.8, zb + tp + 0.05, 0.035, 'gunv'))):
                pts = [Vector((*ring_pt(side * (t0 + (t1 - t0) * (i + 0.15) / n * 0.9 + 0.5), r), z)) for i in range(n + 1)]
                for i, (a, b) in enumerate(zip(pts, pts[1:])):
                    K.cyl('E12_mach_%s_%s_%d_%d' % (nm, 'p' if side > 0 else 's', k_, i), a, b, rad, m, n=8)
            # tanks between some frames
            for j in range(nf):
                t = side * (t0 + (t1 - t0) * (j + 1.0) / (nf + 1))
                x, y = ring_pt(t, 0.45)
                tang = (Vector((*ring_pt(t + 0.5, 0.45), 0)) - Vector((*ring_pt(t - 0.5, 0.45), 0))).normalized()
                c = Vector((x, y, zb + tp + 0.1))
                K.cyl('E12_tank_%s_%s_%d' % (nm, 'p' if side > 0 else 's', j), c - tang * 0.18, c + tang * 0.18, 0.09, 'lilac', n=10)
            K.built.append(dict(id='arc_%s_%s' % (nm, 'p' if side > 0 else 's'), kind='arc', inv=['arcs'], shaped=True, detailed=True,
                                subs=['channel', 'corona', 'frame', 'machinery', 'plate']))
            narc += 1
    K.mark('arc_plates', 'plate', ['slab', 'step', 'bevel', 'fastener'])

    # ---------------- the struts: every arc on its own truss (R207) ----------------
    def spine_y(x):
        if x > 1.8:
            return 0.18
        return abs(K.surf(x, 1, ZS))
    struts = [('fore', 48.0, 48.0), ('centre', 77.0, 77.0), ('centre', 103.0, 103.0), ('aft', 130.0, 130.0)]
    for side in (1, -1):
        for i, (nm, t, _) in enumerate(struts):
            x, y = ring_pt(side * t, 0.96)
            xs = x
            a = (xs, side * (spine_y(xs) - 0.02), ZS - 0.02)
            b = (x, y * 1.0, zt - 0.05)
            K.strut('S%d%s' % (i + 1, 'p' if side > 0 else 's'), a, b, w=0.2, r=0.03, up=(0, 0, 1), src='picture' if nm in ('fore', 'aft') else 'designed',
                    inv='struts', note='truss from the spine to the %s %s arc' % (nm, 'port' if side > 0 else 'starboard'))

    # ---------------- the core, caged at the ring's centre ----------------
    K.core('C1', (XC, 0.0, ZS), 0.75, inv='core', note='the trapped light core in gimbal rings; the spine enters its hubs')

    # ---------------- weapons, by data.js slot ----------------
    for i, (x, nm) in enumerate(((3.2, 'fore'), (-1.35, 'aft'))):
        sad = K.loft('E12_saddle%d' % (i + 1), [(x + 0.75, 0.22, 0.22, ZS + 0.06, ZS + 0.3, 0.06, 0.0), (x + 0.5, 0.42, 0.42, ZS - 0.02, ZS + 0.42, 0.12, 0.0),
                                                 (x - 0.5, 0.42, 0.42, ZS - 0.02, ZS + 0.42, 0.12, 0.0), (x - 0.75, 0.22, 0.22, ZS + 0.06, ZS + 0.3, 0.06, 0.0)],
                     'violet', plates=dict(PL, seed=80 + i, faces=[0, 1, 2, 3], size=(0.2, 0.35)))
        K.mass('Saddle, %s battery' % nm, sad, 'violet plate', note='the oval saddle the turret stands on')
        K.gun('T%d' % (i + 1), (x, 0.0, ZS + 0.42), 0, 4, barrels=2, cal=0.07, blen=1.15, size=0.72, slot='T', weapon='gauss', inv='main_guns',
              variant=i, note='%s null cannon: twin rail pairs through a crescent shade, on its saddle' % nm)
    K.mark('saddles', 'pylon', ['web', 'plate'])
    K.spinal('A1', (5.3, 0.0, ZS), 1.05, r=0.24, collar_r=0.4, collar_len=0.45, block_len=0.36, block_r=0.33, slot='F', weapon='doom', inv='emitter',
             note='the corona arc emitter on the spine head (a crown of electrode horns round a black shade disc), firing through the ring\'s bow gap')
    import bpy as _bpy
    for nm_, ob_, col_ in (('Emitter collars', 'A1_mount_mauve', 'mauve and violet'), ('Emitter shaft', 'A1_body_violet', 'violet and mauve'), ('Emitter block', 'A1_body_mauve', 'mauve')):
        K.mass(nm_, _bpy.data.objects[ob_], col_, note='a part of the kit projector, counted as its own mass')
    K.gun('G1', (-5.25, 0.0, 0.9), 0, 6, barrels=2, cal=0.05, blen=0.75, size=0.55, slot='T', weapon='gsentry', inv='sentry', variant=2,
          note='the null spire: a tall turning spire on the block roof, green sight slits, two needle rails through a shade fin at its head')

    # ---------------- engines: three side by side ----------------
    for i, y in enumerate((1.02, 0.0, -1.02)):
        K.engine('E%d' % (i + 1), (-7.25, y, 0.08), 0.39, 0.9, bell=1.18, body_r=0.44, rings=2, nose='flat', inv='engines',
                 src='picture', note=('port', 'centre', 'starboard')[i] + ' engine')

    # ---------------- block fittings ----------------
    for side in (1, -1):
        sn = 'p' if side > 0 else 's'
        for j, x in enumerate((-4.45, -4.75, -5.05)):
            K.lamp('L%d%s' % (j, sn), (x, side * 1.56, 0.3), (0, side, 0), inv='block_lights', note='green light panel on the block flank', up=(0, 0, 1))
        K.vent('V1' + sn, (-5.45, side * 1.565, 0.06), (0, side, 0), 0.4, 0.3, slats=4, inv='block_vents', note='heat slot panel on the block flank')
        K.hatch('H1' + sn, (-5.65, side * 0.5, 0.9), (0, 0, 1), 0.26, inv='block_hatches', note='hatch on the block roof')
        K.thruster('Q1' + sn, (-4.0, side * 1.0, K.deck_z(-4.0, 1.0) - 0.02), (0, side * 0.6, 0.8), r=0.2, inv='thrusters', note='block roof edge, firing up and out over the ring')
        K.thruster('Q2' + sn, (-4.0, side * 1.0, 0.16 - (K.deck_z(-4.0, 1.0) - 0.08) - 0.02), (0, side * 0.6, -0.8), r=0.2, inv='thrusters', note='block belly edge, firing down and out')

    # ---------------- colour zones ----------------
    K.colour('deep violet plate, violet-black shade (paint stage)', 7.25, -7.25, 'whole ship')
    K.colour('green-white corona line', 7.2, -5.6, 'every arc\'s outer rim')
    K.colour('core light', 1.8, 0.2, 'the caged core')
    K.colour('emitter green', 6.4, 6.2, 'the bow lens')

    # ---------- INSIDE ----------
    for nm_, z_ in (('block_lower', -0.3), ('block_upper', 0.38)):
        secs = []
        for x in (-4.0, -5.0, -5.95):
            hw = abs(K.surf(x, 1, z_)) - 0.25
            secs.append((x, hw, hw, z_ - 0.04, z_ + 0.04, 0, 0))
        K.loft('in_deck_' + nm_, secs, 'darkdeck', inside=True)
        K.inside.append(dict(kind='deck', name=nm_, z=z_, x=(-5.95, -4.0)))
    for i, x in enumerate((-3.4, -4.4, -5.3, -6.0)):
        s_ = _k.sec_at(HULL, x)
        K.loft('in_bh_F%d' % i, [(x + 0.05, s_[1] - 0.22, s_[2] - 0.22, s_[3] + 0.22, s_[4] - 0.22, 0, 0), (x - 0.05, s_[1] - 0.22, s_[2] - 0.22, s_[3] + 0.22, s_[4] - 0.22, 0, 0)],
               'frame', inside=True, rounded=True, pexp=PEXP)
        K.inside.append(dict(kind='bulkhead', name='F%d' % i, x=x))
    K.room('conduit_aft', 'machinery', -3.2, 0.1, -0.1, 0.1, ZS - 0.09, ZS + 0.09, note='the spine\'s power conduits from the core to the drives')
    K.room('conduit_fore', 'machinery', 1.9, 5.2, -0.1, 0.1, ZS - 0.09, ZS + 0.09, note='conduits to the emitter and the fore battery')
    K.room('archive_vault', 'archive', -4.0, -3.4, -0.5, 0.5, -0.3, 0.4, note='the archive vault in the block\'s forward taper')
    K.room('dark_decks', 'darkdeck', -4.8, -4.05, -0.9, 0.9, 0.4, 0.6, note='dark decks: machine crew stations')
    K.room('sentry_magazine', 'magazine', -5.8, -4.85, -0.6, 0.6, 0.4, 0.6, note='under the null spire')
    K.room('engine_room', 'engroom', -6.0, -4.4, -0.9, 0.9, -0.55, 0.3, note='engine room and the three drives\' feeds')
    K.room('battery_feeds', 'magazine', 3.0, 3.4, -0.12, 0.12, ZS + 0.18, ZS + 0.38, note='the fore battery\'s feed under its saddle')
    K.inside.append(dict(kind='space', name='core', mat='ecore', x=(XC - 0.55, XC + 0.55), y=(-0.55, 0.55), z=(ZS - 0.55, ZS + 0.55),
                         note='the core of trapped light, caged in the open (hp_core)'))
    K.armour('ring arcs (outer walls and top plates)', 0.14, 'the shade: thickest on the outer wall')
    K.armour('stern block', 0.3, '')
    K.armour('spine', 0.12, 'thin; the ring shades it')
    K.break_line('B-1', XC, 'the spine parts at the core: the cage bursts, the fore spine and the bow arcs tear away (a ragged bite where the core goes)',
                 path=[(XC + 0.4, 0.95), (XC - 0.2, 0.5), (XC + 0.3, 0.0), (XC - 0.3, -0.45)])
    K.break_line('B-2', -3.6, 'the block tears from the spine at its taper, opening the archive vault and the engine room',
                 path=[(-3.4, 0.8), (-3.85, 0.3), (-3.45, -0.15), (-3.9, -0.6)])
    K.inside.append(dict(kind='note', name='insides', note='Eclipse breaks in layers (factions.md): the ring arcs peel away first, band by band, as their struts snap, their open bays spilling frames and machinery; then the bare spine parts at the core and the block tears away. Full interiors throughout (R215), hidden until a piece breaks.'))
    K.point('core', 'hp_core', (XC, 0, ZS))
    # four breach anchors on the shade arcs (Cruiser base 4, Eclipse +0): prow 1, mid 2, engine 1, alternating sides
    for i, (t, sec, side) in enumerate(((40.0, 'prow', 'port'), (-85.0, 'mid', 'stbd'), (95.0, 'mid', 'port'), (-135.0, 'eng', 'stbd'))):
        x, y = ring_pt(t, 0.3)
        K.point('breach', 'hp_breach_%d' % i, (x, y, zt + 0.01), side=side, section=sec, note='on a shade arc')
    for i, (x, y, z) in enumerate(((-4.0, 1.0, K.deck_z(-4.0, 1.0)), (-4.0, -1.0, K.deck_z(-4.0, 1.0)), (-4.0, 1.0, 0.16 - K.deck_z(-4.0, 1.0)), (-4.0, -1.0, 0.16 - K.deck_z(-4.0, 1.0)))):
        K.point('rcs', 'hp_rcs_%d' % i, (x, y, z), side='port' if y > 0 else 'stbd')

    # ---------- changed from the picture (designer's decisions, R207) ----------
    K.change('Every arc has its own truss struts (eight)', 'R207: the picture leaves four of seven arcs floating; the centre arcs get two struts each, clear of the core cage, the stern arcs sit into the block')
    K.change('Eight arcs, the stern pair matched', 'the picture has one stern arc on the starboard side only; matched pairs (factions.md) unless a break is drawn on purpose')
    K.change('The spine slimmed to a rod (0.36 across); the block made compact and low (1.4 tall), its aft face filled by three 0.92 bells standing out 0.95 behind it', 'the Board on the first sheet: the concept\'s spine is a thin rod carrying the fittings, and its three large dark bells are the stern\'s most prominent feature')
    K.change('Three engines side by side in one row', 'the plan and the beauty show three across; the side view stacks them, which the plan cannot; one row keeps the block broad and low')
    K.change('Engines are eclipse rings, not flame', 'factions.md: "no flaming bells. An eclipse ring of pale light"')
    K.change('Arcs are real box sections, 0.42 deep', 'the side view draws the ring as a line; the beauty shows thick box sections with open bays, which carry frames and machinery')
    K.change('Weapons built from the lore, not the picture\'s generic turrets (R221)', 'Ryan: "their turrets look the same as hullbreakers"; the picture draws box turrets with round twin barrels. The null cannons are rail guns firing through the slot of a crescent shade, the null spire a tall sentry spire with needle rails, the emitter a crown of electrode horns round the crest\'s black disc (tools/blender/kits/eclipse/README.md)')
    K.change('Weapons by data.js slot', 'd_harvester: gauss T twice on the spine saddles, doom F the bow emitter, gsentry T the null spire on the block roof (the picture\'s small green-lit turret)')
    K.change('Thrusters, hatches and heat panels added', 'a ship in space needs thrusters; the picture shows no underside')
    K.open_item('The underside of the block and the ring is designed here; the picture shows no underside')
    # ---------- the fit report's fix column: every finding on the first full layout ----------
    K.fix('E1, E2, E3 bells inside the stern block', 'the block\'s aft face moved forward to 6.65 aft of the bow datum, so the bells stand clear of it')
    K.fix('S1p and S1s (fore struts) into the emitter\'s breech collar', 'the fore struts meet the arcs at 48 degrees and run straight across, clear of the collar')
    K.fix('S3p and S3s (aft centre struts) touching the core\'s hub collars', 'the struts moved to 103 degrees and the spine collar there moved aft, so the lugs clear the hubs')
    K.fix('A1 (emitter) collar against the spine-head thrusters Q2p and Q2s', 'the spine-head thrusters removed; all four thrusters sit on the block\'s roof and belly edges')
    K.fix('Q1 and Q2 exhaust cones on the aft and fore arcs and on the fore struts', 'the thrusters fire up and out, and down and out, from the block edges, clear of every arc')

