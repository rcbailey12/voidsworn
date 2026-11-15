# deathless_E13: the Eclipse mote, the fan frigate (class Frigate, 6.5 world units). Issue 739, Eclipse build sheets.
# Accepted picture: contrib/muse/design/class_family_deathless_2026_11/deathless_E13_mote.jpg and _sheet.jpg (Ryan, Nov 12
# 2026, issue 627: the round 1 Fan direction, "Fan is definitely good", R172). data.js d_scythe: gauss T; ability phase,
# regen 2, reanimate; speed 4, evasion 14 (the family's skirmisher); no hangar.
# Designer of record: Opus (R205, R207); the Board is the final designer (R233, R236): the concept is a base.
# Read off the whole concept (R229): the plan (the sheet's left view, 600 px = 6.5 units) is a leaf widest at about 25 percent
# from the bow (the outer plates' tips hook out level with the nose's flanks), envelope length to beam 1.87 and to height 9.6
# (inventory.py's measure); the plates gather at the stern by the engine and fan FORWARD, their tips stepping back from the
# nose outward; the side view is low and flat, the gun housing the only thing above the plates.
# +X bow, +Y port, +Z up. Nose tip x = +3.25, engine exit x = -3.25.
import math

CODE = 'deathless_E13'
NAME = 'Eclipse mote (the fan frigate)'
FACTION = 'Eclipse (deathless)'
CLASS = 'Frigate'
LENGTH = 6.5
GAME = "data.js d_scythe (cls 'Frigate'); length from godot/render/hull_table.gd CLS_LEN['Frigate'] = 6.5 (drawn x SHIP_K 1.6 = 10.4 on the board)"
BEAUTY = 'contrib/muse/design/class_family_deathless_2026_11/deathless_E13_mote.jpg'
KIT = 'eclipse'
CONCEPT_SHEET = 'contrib/muse/design/class_family_deathless_2026_11/deathless_E13_mote_sheet.jpg'
# the sheet's true views (x0, y0, x1, y1): the plan on the left and the side view in the middle, both BOW ON THE LEFT
CONCEPT_VIEWS = dict(top=dict(box=(28, 420, 650, 870), largest=True, flip=False), side=dict(box=(700, 560, 1365, 725), largest=True, flip=False))
CROPS = [('bow (the plate tips and the nose)', (120, 560, 1020, 1160)), ('midships (the core gap and the crest plate)', (520, 300, 1260, 1000)),
         ('stern (the plates\' roots, the gun and the engine ring)', (900, 120, 1500, 940))]
SHEET = dict(version=1, round='first sheet (issue 739)', date='2026-11-15', blend='sandbox w739run (Blender 5.3 bpy, Cycles CPU)',
             before='First full layout', before_note='The first complete E13 layout, built with the Eclipse kit and run through the check before any fix.',
             during='While designing, the check caught (and the design fixed): the core\'s gimbal ring inside the dart and the stern block (both now end in its hub '
                    'collars, clear of the gimbal), the belly hatches inside the root collar (moved aft of it), and, once the plates were widened to the concept\'s leaf, '
                    'the crest plate over the core\'s gimbal ring (the crest raised over the core).')

# ---------------- the dart (the hull loft): (x, half-beam port, starboard, bottom, top, top chamfer, bottom chamfer), nose first
HULL = [
    (3.25, 0.03, 0.03, -0.04, 0.02, 0.0, 0.0),
    (2.95, 0.15, 0.15, -0.1, 0.08, 0.05, 0.04),
    (2.6, 0.24, 0.24, -0.15, 0.12, 0.07, 0.06),
    (2.0, 0.32, 0.32, -0.2, 0.17, 0.09, 0.07),
    (1.2, 0.38, 0.38, -0.24, 0.21, 0.11, 0.09),
    (0.3, 0.4, 0.4, -0.26, 0.23, 0.12, 0.1),
    (-0.3, 0.33, 0.33, -0.22, 0.19, 0.1, 0.08),
    (-0.615, 0.15, 0.15, -0.13, 0.13, 0.04, 0.04),   # seated in the core's fore hub collar, clear of its gimbal
]
XCORE, ZCORE, RCORE = -0.95, 0.0, 0.32
# the stern block: from the core's aft hub to the engine's housing
BLOCK = [
    (-1.285, 0.15, 0.15, -0.13, 0.13, 0.04, 0.04),
    (-1.5, 0.3, 0.3, -0.27, 0.3, 0.1, 0.08),
    (-1.7, 0.4, 0.4, -0.33, 0.38, 0.13, 0.11),
    (-2.25, 0.42, 0.42, -0.34, 0.4, 0.13, 0.11),
    (-2.4, 0.38, 0.38, -0.3, 0.36, 0.11, 0.1),
]
PANEL = (0.26, 0.4)   # the even panel size (R243), across and along, world units (E11 and E12 plate 0.2 to 0.32 by 0.45 to 0.75)
# the five plates (port side; the side plates are mirrored): inner edge and outer edge in plan as polylines (x, y) from the
# root to a shared tip (straight machined edges with a kink at the broadest point, the concept's chevron blades), the height
# of the inner and outer edge's top along x as (x, z) rows, and the thickness. The crest's "inner edge" is its half-width.
BLADES = {
    'crest': ([(-1.52, 0.11), (-0.9, 0.2), (0.6, 0.25), (2.82, 0.0)], None,
              [(-1.6, 0.38), (-0.95, 0.44), (-0.3, 0.38), (0.4, 0.3), (1.6, 0.26), (2.4, 0.19), (2.9, 0.12)], None, 0.08),
    'inner': ([(-1.76, 0.36), (-0.9, 0.38), (0.6, 0.4), (1.8, 0.52), (2.72, 0.82)], [(-1.84, 0.55), (-0.6, 0.9), (0.9, 1.1), (2.0, 1.2), (2.72, 0.82)],
              [(-1.9, 0.3), (-0.95, 0.34), (0.3, 0.22), (1.6, 0.17), (2.8, 0.1)], [(-1.9, 0.25), (0.3, 0.08), (1.6, 0.04), (2.8, 0.04)], 0.075),
    'outer': ([(-1.96, 0.42), (-0.6, 0.72), (0.9, 1.0), (2.32, 1.6)], [(-2.04, 0.55), (-0.6, 1.15), (0.7, 1.55), (1.7, 1.82), (2.32, 1.6)],
              [(-2.1, 0.1), (-0.9, 0.12), (0.3, 0.04), (1.4, -0.02), (2.4, -0.05)], [(-2.1, 0.05), (0.3, -0.16), (1.4, -0.16), (2.4, -0.1)], 0.07),
}
N_BLADE = 28


def lerp_tab(tab, x):
    if x <= tab[0][0]:
        return tab[0][1]
    for (xa, za), (xb, zb) in zip(tab, tab[1:]):
        if xa <= x <= xb:
            return za + (zb - za) * (x - xa) / (xb - xa)
    return tab[-1][1]


def blade_rings(nm, side):
    """the plate's section rings from root to tip, its outer-rim points and (the crest) its other rim: port side = +y.
    Side plates: [inner bottom, outer bottom, outer top, inner top]; the crest: a low ridge, six points."""
    from mathutils import Vector
    ie, oe, zi, zo, th = BLADES[nm]
    rings, rims, irims = [], [], []
    for i in range(N_BLADE + 1):
        t = i / N_BLADE
        xa = ie[0][0] + (ie[-1][0] - ie[0][0]) * t
        a = Vector((xa, lerp_tab(ie, xa), 0.0))
        if nm == 'crest':
            x = a.x; hw = max(0.012, abs(a.y)); z = lerp_tab(zi, x)
            ring = [(x, hw, z - th), (x, -hw, z - th), (x, -hw, z), (x, -hw * 0.35, z + 0.035), (x, hw * 0.35, z + 0.035), (x, hw, z)]
            rings.append(ring); rims.append((x, hw, z + 0.004)); irims.append((x, -hw, z + 0.004))
            continue
        xb = oe[0][0] + (oe[-1][0] - oe[0][0]) * t
        b = Vector((xb, lerp_tab(oe, xb), 0.0))
        if (b - a).length < 0.02:
            mid = (a + b) / 2; d = Vector((-(b - a).y, (b - a).x, 0)).normalized() if (b - a).length > 1e-6 else Vector((0, 1, 0))
            a, b = mid - d * 0.01, mid + d * 0.01
        za, zb_ = lerp_tab(zi, a.x), lerp_tab(zo, b.x)
        ib, ob = (a.x, side * a.y, za - th), (b.x, side * b.y, zb_ - th)
        it, ot = (a.x, side * a.y, za), (b.x, side * b.y, zb_)
        rings.append([ib, ob, ot, it] if side > 0 else [ob, ib, it, ot])
        rims.append((b.x, side * b.y, zb_ + 0.004)); irims.append((a.x, side * a.y, za + 0.004))
    return rings, rims, irims


def dense(sections, step=0.4):
    """the loft sections resampled every `step` along x (bow first), so the even panels of neighbouring rows line up"""
    import kit as _k
    out = []
    for a, b in zip(sections, sections[1:]):
        n = max(1, int(round((a[0] - b[0]) / step)))
        for i in range(n):
            x = a[0] + (b[0] - a[0]) * i / n
            out.append(tuple(_k.sec_at(sections, x)))
    out.append(tuple(sections[-1]))
    return out


def bez(p0, p1, p2, t):
    return tuple((1 - t) ** 2 * a + 2 * (1 - t) * t * b + t * t * c for a, b, c in zip(p0, p1, p2))


def build(K):
    import kit as _k
    from mathutils import Vector
    EP = _k.HP   # the Eclipse kit (KIT above): its even panels (R243)
    panel_jobs = []

    def rings_of(secs):
        return [[(s[0], y, z) for (y, z) in _k._octa(s[1], s[2], s[3], s[4], s[5], s[6])] for s in secs]

    # ---------------- the dart and the stern block ----------------
    hd = dense(HULL)
    hull = K.hull(hd, 'shade2', shell=0.06)
    K.mass('Hull: the dart', hull, 'deep violet plate', note='the short dart under the fan: a chamfered octagon section, the nose ahead of the plate tips')
    panel_jobs.append(('E13_dart', rings_of(hd), list(range(8)), 'body_plates', ('shade2', 'violet')))
    K.mark('body', 'hull', ['bevel', 'step', 'overhang'])
    bd = dense(BLOCK, 0.2)
    blk = K.loft('E13_block', bd, 'violet')
    K.mass('Stern block', blk, 'violet plate', note='a chamfered block from the core\'s aft hub to the engine, the gun on its roof')
    panel_jobs.append(('E13_block', rings_of(bd), [0, 2, 3, 4, 5, 6, 7], 'body_plates', ('violet', 'shade2')))
    # the root collar: a stepped band round the block's front where the five plates gather
    col = K.loft('E13_rootcollar', [(-1.45, 0.33, 0.33, -0.29, 0.33, 0.11, 0.09), (-1.55, 0.45, 0.45, -0.37, 0.39, 0.14, 0.12),
                                    (-1.98, 0.47, 0.47, -0.38, 0.4, 0.15, 0.12), (-2.06, 0.44, 0.44, -0.36, 0.37, 0.13, 0.11)], 'mauve')
    K.mass('Root collar', col, 'mauve plate', note='the stepped band where the plates\' roots gather on the block')
    K.mark('root_collar', 'pylon', ['web', 'plate'])
    K.loft('E13_roofstep', [(-1.72, 0.26, 0.26, 0.36, 0.44, 0.05, 0.0), (-1.8, 0.3, 0.3, 0.36, 0.47, 0.07, 0.0), (-2.2, 0.3, 0.3, 0.36, 0.47, 0.07, 0.0),
                            (-2.28, 0.26, 0.26, 0.36, 0.44, 0.05, 0.0)], 'mauve')
    K.mark('stern_block', 'tier', ['face', 'roof', 'opening'])

    # ---------------- the fan: five shade plates gathered at the stern, fanning forward ----------------
    # each plate (port side; the starboard twin is its mirror): its inner and outer edges in plan, two quadratic curves from
    # the root to a shared tip; the height of each edge along the length (x, z) and a thickness. The crest plate rides the
    # spine with a low ridge; each side plate sits under the edge of the one inside it, banked down outward, so the front of
    # the fan reads as a layered stack. Plan of record (measured off the concept sheet, inventory.py): the leaf widest at about 25 percent, envelope length to beam about 1.8.
    for nm, (ie, oe, zi, zo, th) in BLADES.items():
        for side in ((1,) if nm == 'crest' else (1, -1)):
            sn = '' if nm == 'crest' else ('_p' if side > 0 else '_s')
            rings, rims, irims = blade_rings(nm, side)
            ob = K.loft_rings('E13_blade_%s%s' % (nm, sn), rings, 'shade')
            K.mass('Shade plate, %s%s' % (nm, {'': '', '_p': ' port', '_s': ' starboard'}[sn]), ob, 'violet-black shade',
                   note='a layered slab gathered at the root collar, its tip forward')
            step = max(1, int(round(PANEL[1] / max(1e-6, abs(rings[1][0][0] - rings[0][0][0])))))   # one panel row per ring pair
            pr = rings[::step] + ([rings[-1]] if (len(rings) - 1) % step else [])
            panel_jobs.append(('E13_blade_%s%s' % (nm, sn), pr, [2, 3, 4] if nm == 'crest' else [2], 'fan_plates', ('shade', 'shade2')))
            # the stepped second layer on the root half: a narrower slab on the plate's top, set in from both edges
            lay = []
            for r in rings[:int(N_BLADE * 0.55)]:
                if nm == 'crest':
                    lo, hi = Vector(r[5]), Vector(r[2])
                else:
                    lo, hi = (Vector(r[3]), Vector(r[2])) if side > 0 else (Vector(r[2]), Vector(r[3]))
                mid = (lo + hi) / 2; half = (hi - lo) * 0.28
                up = Vector((0, 0, 0.03 if nm == 'crest' else 0.0))
                lay.append([tuple(mid - half + up), tuple(mid + half + up), tuple(mid + half + up + Vector((0, 0, 0.04))), tuple(mid - half + up + Vector((0, 0, 0.04)))])
            K.loft_rings('E13_layer_%s%s' % (nm, sn), lay, 'shade2')
            K.strip('E13_corona_layer_%s%s' % (nm, sn), [tuple(Vector(r[2 if (side > 0 or nm == 'crest') else 1]) + Vector((0, 0, 0.003))) for r in lay[1:]], w=0.016, t=0.012)
            # the corona line along the outer rim (on the crest, both rims)
            K.strip('E13_corona_%s%s' % (nm, sn), rims[1:-1], w=0.02, t=0.014)
            if nm == 'crest':
                K.strip('E13_corona_%s_b' % nm, irims[1:-1], w=0.02, t=0.014)
            K.built.append(dict(id='plate_%s%s' % (nm, sn), kind='shade', inv=['fan'], shaped=True, detailed=True, subs=['band', 'corona', 'layer', 'plate']))

    # ---------------- the core, in the gap under the crest plate ----------------
    K.core('C1', (XCORE, 0.0, ZCORE), RCORE, inv='core', note='the trapped light core between the dart and the stern block, under the crest plate, seen through the gaps beside it')

    # ---------------- the gun, by data.js slot ----------------
    K.gun('T1', (-1.98, 0.0, 0.47), 0, 4, barrels=2, cal=0.042, blen=0.74, size=0.4, slot='T', weapon='gauss', inv='main_gun',
          note='the null cannon: twin rail pairs through a crescent shade on the block roof at the fan\'s root, firing forward over the plates')

    # ---------------- the engine ----------------
    K.engine('E1', (-3.25, 0.0, 0.03), 0.27, 0.49, bell=1.2, body_r=0.29, rings=2, nose='flat', inv='engine', src='picture', kw=dict(struts=12, seg=32),
             note='the small thin eclipse ring of pale light at the stern, no flame')

    # ---------------- fittings ----------------
    def chamfer_pt(secs, x, side, lower=True):
        s = _k.sec_at(secs, x)
        hw = s[1]; zb, zt, ct, cb = s[3], s[4], s[5], s[6]
        if lower:
            a = (hw, zb + cb); b = (hw - cb, zb)
        else:
            a = (hw, zt - ct); b = (hw - ct, zt)
        y = (a[0] + b[0]) / 2; z = (a[1] + b[1]) / 2
        n = Vector((0, (a[1] - b[1]) * (-1 if lower else 1), (b[0] - a[0]) * (-1 if lower else 1)))
        n = Vector((0, abs(n.y), -abs(n.z) if lower else abs(n.z))).normalized()
        return (x, side * y, z), (0, side * n.y, n.z)
    for side in (1, -1):
        sn = 'p' if side > 0 else 's'
        p_, n_ = chamfer_pt(HULL, 2.0, side)
        K.thruster('Q1' + sn, p_, n_, r=0.13, inv='nose_thrusters', note='nose lower chamfer, firing down and out under the plates')
        p_, n_ = chamfer_pt(BLOCK, -2.3, side)
        K.thruster('Q2' + sn, p_, n_, r=0.15, inv='stern_thrusters', note='stern block lower chamfer, firing down and out')
        for j, x in enumerate((1.4, 0.55)):
            s = _k.sec_at(HULL, x)
            K.lamp('L%d%s' % (j, sn), (x, side * s[1], -0.08), (0, side, 0), inv='lamps', note='corona strip light low on the dart\'s flank', up=(1, 0, 0))
        K.vent('V1' + sn, (-2.2, side * 0.42, 0.1), (0, side, 0), 0.22, 0.16, slats=3, inv='vents', note='heat slot panel on the block flank, aft of the plates\' roots')
        K.hatch('H1' + sn, (-2.18, side * 0.12, -0.34), (0, 0, -1), 0.17, inv='hatches', note='belly hatch on the stern block')

    # ---------------- the even panels, after every mount has claimed its keep-out ----------------
    for name, rings, faces, inv_id, mats in panel_jobs:
        EP.lay_panels(K, name, rings, faces, inv_id, size=PANEL, thick=0.022, gap=0.022, mats=mats, band=3)

    # ---------------- colour zones ----------------
    K.colour('violet-black shade plates, deep violet dart and block (paint stage)', 3.25, -3.25, 'whole ship')
    K.colour('green-white corona line', 2.8, -2.0, 'every plate\'s outer rim; both rims of the crest plate')
    K.colour('core light', -0.5, -1.4, 'the core under the crest plate')

    # ---------- INSIDE ----------
    secs = []
    for x in (2.3, 1.5, 0.7, -0.3):
        s_ = _k.sec_at(HULL, x); hw = s_[1] - 0.12
        secs.append((x, hw, hw, -0.08, -0.04, 0, 0))
    K.loft('in_deck_main', secs, 'darkdeck', inside=True)   # dark decks (the Eclipse liner), as E11 and E12
    K.inside.append(dict(kind='deck', name='main', z=-0.06, x=(-0.3, 2.3)))
    for i, x in enumerate((2.2, 1.45, 0.65, -0.15)):
        K.bulkhead('F%d' % i, x, inset=0.1, t=0.04)
    K.room('dark_decks', 'darkdeck', 1.5, 2.15, -0.14, 0.14, -0.02, 0.1, note='dark decks: the machine crew\'s stations, unlit')
    K.room('archive_vault', 'archive', 0.7, 1.4, -0.24, 0.24, -0.02, 0.12, note='the archive vault: the Starwrights\' stored selves')
    K.room('capacitors', 'machinery', -0.1, 0.6, -0.22, 0.22, -0.02, 0.12, note='the core\'s capacitor bank and the phase drive')
    K.room('conduits', 'machinery', -0.1, 2.15, -0.12, 0.12, -0.18, -0.09, note='power conduits from the core along the keel')
    for i, x in enumerate((-1.68, -2.1)):
        s_ = _k.sec_at(BLOCK, x)
        K.loft('in_bh_B%d' % i, [(x + 0.02, s_[1] - 0.1, s_[2] - 0.1, s_[3] + 0.1, s_[4] - 0.1, max(0, s_[5] - 0.05), max(0, s_[6] - 0.05)),
                                 (x - 0.02, s_[1] - 0.1, s_[2] - 0.1, s_[3] + 0.1, s_[4] - 0.1, max(0, s_[5] - 0.05), max(0, s_[6] - 0.05))], 'frame', inside=True)
        K.inside.append(dict(kind='bulkhead', name='B%d' % i, x=x))
    K.loft('in_deck_block', [(-1.72, 0.27, 0.27, 0.0, 0.04, 0, 0), (-2.3, 0.27, 0.27, 0.0, 0.04, 0, 0)], 'darkdeck', inside=True)
    K.inside.append(dict(kind='deck', name='block', z=0.02, x=(-2.3, -1.72)))
    K.room('magazine', 'magazine', -2.05, -1.72, -0.2, 0.2, 0.07, 0.24, note='the null cannon\'s capacitor magazine, under the gun')
    K.room('engine_room', 'engroom', -2.3, -2.12, -0.22, 0.22, -0.2, 0.22, note='the engine room and the drive\'s feed')
    K.room('phase_coils', 'machinery', -2.05, -1.72, -0.22, 0.22, -0.2, -0.04, note='the phase coils (data.js ab phase)')
    K.inside.append(dict(kind='space', name='core', mat='ecore', x=(XCORE - 0.24, XCORE + 0.24), y=(-0.24, 0.24), z=(ZCORE - 0.24, ZCORE + 0.24),
                         note='the core of trapped light, in the open under the crest plate (hp_core)'))
    K.armour('shade plates', 0.09, 'the fan: the thickest armour, held forward')
    K.armour('dart', 0.06, 'thin; the fan shades it')
    K.armour('stern block', 0.12, '')
    K.break_line('B-1', XCORE, 'the dart parts from the stern block at the core: the cage bursts, the nose and the plates\' fore halves tear away (a ragged bite where the core goes)',
                 path=[(-0.82, 2.6), (-0.82, 1.7), (-1.08, 1.05), (-0.84, 0.45), (-1.08, -0.2), (-0.84, -0.8), (-1.1, -1.5), (-1.1, -2.6)])
    K.inside.append(dict(kind='note', name='insides', note='Eclipse breaks in layers (factions.md): one authored break for a frigate (factions.md, the class table): the dart parts from the block at the core and the five plates tear across it, their fore halves going with the nose; no level peel plane (the crest slopes through any one height, so a plane would slice it rather than lift it); full interiors throughout (R215), hidden until a piece breaks.'))
    K.point('core', 'hp_core', (XCORE, 0, ZCORE))
    # two breach anchors on the shade plates (Frigate base 2, Eclipse +0): prow 1 (port), eng 1 (starboard)
    def blade_top(nm, side, t):
        r = blade_rings(nm, side)[0][int(round(t * N_BLADE))]
        c = (Vector(r[2]) + Vector(r[3])) / 2
        return (c.x, c.y, c.z + 0.002)
    K.point('breach', 'hp_breach_0', blade_top('inner', 1, 0.78), side='port', section='prow', note='on the inner shade plate')
    K.point('breach', 'hp_breach_1', blade_top('outer', -1, 0.16), side='stbd', section='eng', note='on the outer shade plate near its root')
    for i, side in enumerate((1, -1)):
        p_, n_ = chamfer_pt(HULL, 2.0, side)
        K.point('rcs', 'hp_rcs_%d' % i, p_, side='port' if side > 0 else 'stbd')
    for i, side in enumerate((1, -1)):
        K.point('board', 'hp_board_%d' % i, (0.0, side * _k.sec_at(HULL, 0.0)[1], -0.1), side='port' if side > 0 else 'stbd')

    # ---------- changed from the picture (the designer's calls, R207, R233, R236) ----------
    K.change('The plates gather at the stern by the engine and fan forward, their tips flanking the nose', 'the accepted beauty, the sheet\'s plan and the round 1 Fan direction all draw it so; designs.md says rooted at the bow. The pictures are what Ryan accepted (R229: the whole concept first)')
    K.change('Five plates: a crest plate on the spine and two a side, each with a stepped second layer on its root half', 'designs.md\'s count; the pictures\' extra blade edges read as the stepped layers. A generated sheet never settles counts (ships.md 5)')
    K.change('The outer plates bank down and outward and overlap the inner ones\' edges', 'the front of the fan reads as a layered stack (the sheet\'s front view, redrawn as a stack, issue 627) and the plates hold each other at their overlap')
    K.change('The core sits in the open between the dart and the stern block under the crest plate, the spine entering its hub collars', 'designs.md: "in a gap between the plates near their root ... partly covered, never a bare bulb"; the beauty shows it on one side only, a matched build puts it on the axis')
    K.change('The gun is the null cannon on the block roof at the plates\' root (data.js gauss T)', 'designs.md and the sheet; the beauty underplays it. Built from the lore (R221): twin rail pairs through a crescent shade')
    K.change('Engines are eclipse rings, not flame', 'factions.md: "no flaming bells. An eclipse ring of pale light"')
    K.change('Panels dead even, aligned rows on every face, tone in ordered bands (R243)', 'Ryan, Nov 13: "make the eclipse panels actually panels and dead even and ordered to align"; the kit lays them by size (eclipse parts.py even_panels)')
    K.change('Thrusters, belly hatches, heat panels and corona strip lights added', 'a ship in space needs thrusters; the picture shows no underside')
    K.change('The fan slimmed and flattened to the concept sheet\'s measured proportions (envelope length to beam 1.79 against the sheet\'s 1.87; the core 0.64 across)', 'the Board\'s massing check (ships.md 2c): the first layout read 1.38, a third too broad, and twice the sheet\'s height. The side stays taller than the sheet\'s (length to height 5.1 against 9.6) because the gun housing and the engine ring stand above and below the plates; the sheet\'s side view draws the gun as a thin fin')
    K.change('From above the mote is a leaf of blades with a dart nose, widest at a quarter of its length', 'family distinctness (R233): the flagship is a crescent, the cruiser a split oval ring, the flare one closed ring; no Eclipse class is a scaled copy of another from above')
    K.open_item('The underside of the dart and the block is designed here; the picture shows no underside')
    # ---------- the fit report's fix column: every finding on the first full layout ----------
    K.fix('C1 (the core) gimbal ring inside the dart and the stern block', 'the dart ends at 0.43 ahead of the core and the block starts 0.43 aft of it, inside the hub collars and clear of the gimbal ring')
    K.fix('H1p and H1s (belly hatches) inside the root collar', 'the hatches moved aft to 2.18, behind the collar')
    K.fix('Q2s (stern thruster) against H1s (belly hatch), after the hull was flattened', 'the stern thrusters moved aft to 2.3, the hatches in to 0.12 off the axis')
    K.fix('C1 (the core) gimbal ring inside the crest plate, after the plates were widened', 'the crest plate rises over the core, its underside 0.03 over the gimbal ring')
