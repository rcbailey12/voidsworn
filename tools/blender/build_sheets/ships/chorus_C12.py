# chorus_C12: the drone-spawn, the Chorus frigate (class Frigate, 6.5 world units). Issue 1153 (R328, R330).
# Accepted picture: contrib/muse/design/class_family_chorus_2026_11/chorus_C12_drone_spawn_v10.jpg and
# chorus_C12_drone_spawn_sheet_v2.jpg (issue 631; Ryan accepted Nov 13); designs.md governs where a picture differs.
# data.js b_drone (Chorus drone-spawn): bioplasma F, tendril T (the F gun is Ryan's "send the frigate back on guns", issue 649);
# ability regrow; regen 3; speed 5, evasion 15 (the fastest in the faction); no shields.
# Designer of record: Opus (R205, R207). The concept guides; it is not traced. Built and judged from the WHOLE pictures first (R229).
# Measured off the v2 sheet's true views (side: bow LEFT, about 165 px a unit; plan: bow DOWN; bow-on below): a compact knot of
# grown flesh 4.1 long (knoll to stern), 2.6 across and 1.9 deep, narrow at the prow and widest a little aft of the middle; the
# knoll with its vent and spine crown stands out of the prow; the knotted tendril mound sits on the back at about two thirds
# aft, its five heavy tendrils draping back and down the flanks; three domes a side on the flanks; two sacs hang below; the
# stern ends in a ring of vents whose trailing membranes stream aft for about a third of the whole length.
# +X bow, +Y port, +Z up. Spine tips about x = +3.25, vent mouths x = -1.7, membrane tips about x = -3.25.
import math

CODE = 'chorus_C12'
NAME = 'The drone-spawn (Chorus frigate)'
FACTION = 'The Chorus (chorus)'
CLASS = 'Frigate'
LENGTH = 6.5
GAME = "data.js b_drone (cls 'Frigate'); length from godot/render/hull_table.gd CLS_LEN['Frigate'] = 6.5"
BEAUTY = 'contrib/muse/design/class_family_chorus_2026_11/chorus_C12_drone_spawn_v10.jpg'
KIT = 'chorus'
CONCEPT_SHEET = 'contrib/muse/design/class_family_chorus_2026_11/chorus_C12_drone_spawn_sheet_v2.jpg'
CONCEPT_VIEWS = dict(top=dict(box=(130, 20, 660, 940), largest=True, flip=False, rot=-90), side=dict(box=(790, 140, 1880, 640), largest=True, flip=False))
CROPS = [('bow (the knoll and its spine crown)', (230, 350, 1050, 1000)), ('midships (the tendril knot and the domes)', (700, 200, 1500, 900)),
         ('stern (the trailing membranes)', (1150, 50, 1920, 750))]
SHEET = dict(version=1, round='the first build sheet (issue 1153)', date='2026-11-19', blend='opus1153\\chorus_C12', px_per_unit=180, label_scale=1.6, bar_units=1.0,
             before='First full layout', before_note='The first complete C12 layout with the Chorus kit, run through the check before any fix.')

PEXP = (2.0, 1.9)    # round over the top and round in the belly: no flat faces (the family's rule, PR 628)
WOBBLE = (0.08, 4.3)  # the body's unevenness: a lumpy knot, never a turned egg
# a compact knot: narrow at the prow where the knoll stands out, widest a little aft of the middle, rounding into the stern
KEY = [
    (2.35, 0.44, 0.44, -0.36, 0.36),
    (1.9, 0.68, 0.68, -0.5, 0.45),
    (1.3, 0.94, 0.94, -0.66, 0.62),
    (0.6, 1.1, 1.1, -0.74, 0.8),
    (-0.1, 1.22, 1.22, -0.78, 0.92),
    (-0.7, 1.16, 1.16, -0.74, 0.9),
    (-1.15, 0.94, 0.94, -0.62, 0.76),
    (-1.5, 0.66, 0.66, -0.46, 0.56),
    (-1.8, 0.4, 0.4, -0.3, 0.36),
]


def dense(key, step=0.15):
    out = []
    for i in range(len(key) - 1):
        a, b = key[i], key[i + 1]
        p0 = key[max(0, i - 1)]; p3 = key[min(len(key) - 1, i + 2)]
        n = max(1, int(round((a[0] - b[0]) / step)))
        for k in range(n):
            t = k / n
            row = []
            for c in range(5):
                P0, P1, P2, P3 = p0[c], a[c], b[c], p3[c]
                row.append(0.5 * ((2 * P1) + (-P0 + P2) * t + (2 * P0 - 5 * P1 + 4 * P2 - P3) * t * t + (-P0 + 3 * P1 - 3 * P2 + P3) * t ** 3))
            out.append(tuple(row) + (0, 0))
    out.append(tuple(key[-1]) + (0, 0))
    return out


HULL = dense(KEY, step=0.05)   # issue 1291: fine stations, so the folds grown into the skin hold their shape
MOUND_X = -0.45
DOMES = (1.3, 0.5, -1.12)
SACS = ((0.3, 1, 0.38), (-0.6, -1, 0.34))   # (x, side, r): the regrow reserve, one each side, staggered
VENTS = 4
R_T = 0.11   # the tendrils' root radius
ARCH = 0.32  # how high the tendrils arch off the back before they drape


def build(K):
    import kit as _k
    from mathutils import Vector
    import bpy as _bpy
    import random
    import sys
    if _k._KITS not in sys.path:
        sys.path.append(_k._KITS)
    from chorus import plates, body
    HP = _k.HP
    plates.register(_k)   # the armour shell's materials (R341)

    # issue 1291 (R349, C13 round G accepted Nov 20): lumpy fused swellings and deep folds grown into the skin itself; calm round
    # the knoll, the tendril knot, the domes, the sacs, the siphons and the vent ring
    calm = [(2.2, 0.0, 0.5), (2.2, math.pi, 0.5), (2.2, math.pi / 2, 0.5), (2.2, -math.pi / 2, 0.5), (MOUND_X, math.pi / 2, 0.5),
            (1.75, -0.55, 0.3), (1.75, math.pi + 0.55, 0.3), (-1.5, 0.6, 0.3), (-1.5, math.pi - 0.6, 0.3)]
    calm += [(x, th, 0.5) for x in DOMES for th in (-0.12, math.pi + 0.12)]
    calm += [(x, -1.2 if side > 0 else math.pi + 1.2, r * 1.6) for (x, side, r) in SACS]
    K.wob_fn = body.field(1153, 2.3, -1.75, swell=18, folds=20, wrinkles=100, sweeps=28, depth=0.11, height=(0.1, 0.24),
                          size=(0.3, 0.6), keep=calm, shell=(2.15, -1.85, plates.WRAP))   # the armadillo shell below: no creases under it
    hull = K.hull(HULL, 'flesh', shell=0.14, rounded=True, pexp=PEXP, n=110, smooth=True, wobble=WOBBLE)
    K.mass('Hull: the compact knot of flesh', hull, 'dark olive flesh', note='narrow at the prow, widest a little aft of the middle, rounding into the stern')
    K.mark('body', 'hull', ['ridge', 'fold', 'pore'])
    K.mark('hide', 'plate', ['pad', 'pore'])

    def side_th(th, side):
        return th if side > 0 else math.pi - th

    # ---------------- the prow knoll (bioplasma F, the spine volley) ----------------
    K.spinal('M1', (2.15, 0.0, 0.0), 0.72, r=0.42, slot='F', weapon='bioplasma', inv='knoll', style='knoll', lip_r=0.74, teeth=8, seed=7,
             gland_at=0.12, crown=12,
             note='the knoll: the head ends in a round puckered mouth of raw flesh, a big deep dark bore (about half the head\'s width) with a fat lip ringed by short bone hooks; the bile gland lies deep down the bore')
    K.mass('Prow knoll', _bpy.data.objects['M1_mount_tissue'], 'raw flesh, bone hooks', note='the gun and nothing else at the prow (Ryan\'s edits, issue 631)')

    # ---------------- the tendril knot (tendril T, fixed) ----------------
    zm = K.deck_z(MOUND_X, 0.0)
    mpos = Vector((MOUND_X, 0.0, zm - 0.05))
    rnd = random.Random(1153)

    def lay(xs, ths, side, hang=None):
        """a tendril's path laid on the hull (out by its radius and a gap), then hanging free at its end"""
        pts = [Vector((MOUND_X + 0.12 * (xs[0] - MOUND_X), 0.0, zm + 0.3))]
        n_ = 14
        for j in range(n_ + 1):
            t = j / n_
            arch = ARCH * math.sin(math.pi * min(1.0, t * 1.6)) * (1 - t) ** 0.5   # the cables rise out of the knot before they lie down
            x = xs[0] + (xs[1] - xs[0]) * t + 0.09 * math.sin(t * 6.5 + 2 * side + xs[0])
            th = ths[0] + (ths[1] - ths[0]) * t + 0.06 * math.sin(t * 4 + side)
            p_, n0 = K.hpt(x, side_th(th, side) if side else th, out=R_T + 0.15 + arch)
            pts.append(p_)
        if hang:
            e = pts[-1]; d0 = (pts[-1] - pts[-2]).normalized()
            for j in range(1, 7):
                t = j / 6
                d = (d0 * (1 - t) + Vector((hang[1] * t * 0.6, side * 0.08, -1.0)) * t).normalized()
                e = e + d * hang[0] / 6
                pts.append(e.copy())
        return [tuple(p_ - mpos) for p_ in pts]
    drape = []
    for side in (1, -1):
        # fore: across the flank just behind the knot and down below the waterline, the tip hanging free
        drape.append(dict(pts=lay((MOUND_X + 0.25, MOUND_X + 0.5), (math.pi / 2 - 0.2, -0.32), side, hang=(0.5, 0.5)), r=R_T * rnd.uniform(0.95, 1.1)))
        # aft: back and down the rear flank, hanging below the stern quarter
        drape.append(dict(pts=lay((MOUND_X - 0.1, MOUND_X - 0.25), (math.pi / 2 - 0.25, -0.25), side, hang=(0.45, 0.4)), r=R_T * rnd.uniform(0.9, 1.0)))
    # the fifth lies straight back along the spine and down over the stern, stopping short of the vents
    drape.append(dict(pts=lay((MOUND_X - 0.2, -1.35), (math.pi / 2, math.pi / 2), 0), r=R_T * 0.92))
    K.gun('T1', tuple(mpos), 0, 0, barrels=2, cal=2 * R_T, blen=1.5, size=1.45, slot='T', weapon='tendril', inv='tendril_knot', fixed=True,
          kw=dict(drape=drape, seed=5),
          note='boarding tendrils: a low mound of knotted muscle holding five heavy tendrils with blunt rounded tips and no claws, draped back over the hull and down its flanks at rest (fixed: they reach every way at once)')
    K.mass('Tendril knot', _bpy.data.objects['T1_mount_flesh'], 'flesh mound, tendrils', note='the knot with a crown on the back: the frigate\'s mark from above (R233)')

    # ---------------- the domes on the flanks (bile stores) ----------------
    caps = []   # issue 1291 round G (Ryan: "caps, but flatter"): flat chitin caps over the domes' tops, the crowns open
    for i, x in enumerate(DOMES):
        for side in (1, -1):
            sn = 'p' if side > 0 else 's'
            pos, nrm = K.hpt(x, side_th(-0.12, side), out=-0.015)
            fid = 'S%d%s' % (i + 1, sn)
            r = (0.3, 0.33, 0.24)[i]
            K.organ(fid, HP.sac(r, h=r * 1.02, seed=70 + 2 * i + (side > 0), kind='sac', glow=1, rim=1.0, armour=True), pos, nrm, fwd=(1, 0, 0), inv='bile_domes',
                    what='bile dome, %.1f across' % (2 * r), note='a bile store in a wrinkled socket, fed forward to the knoll by the veins')
            K.mass('Bile dome %d (%s)' % (i + 1, 'port' if side > 0 else 'starboard'), _bpy.data.objects['%s_mount_flesh' % fid], 'flesh dome', note='a dome on the flank')
            caps.append(((fid + '_',), tuple(pos), tuple(nrm), r, 1.2, 0.5))   # the crown's bile window open

    # ---------------- the hanging sacs (the regrow reserve, regen 3) ----------------
    for i, (x, side, r) in enumerate(SACS):
        sn = 'p' if side > 0 else 's'
        pos, nrm = K.hpt(x, side_th(-1.2, side), out=-0.02)
        hang = (Vector(nrm) * 0.45 + Vector((0, 0, -0.9))).normalized()
        fid = 'R%d%s' % (i + 1, sn)
        K.organ(fid, HP.sac(r, h=r * 2.0, seed=90 + i, kind='sac', glow=1, hang=1.9), pos, hang, fwd=(1, 0, 0), inv='reserve_sacs',
                what='regrowth sac, %.1f across, hanging' % (2 * r), note='the regrow reserve: flesh the body draws on to close its wounds (regen 3)')
        K.mass('Reserve sac %d (%s)' % (i + 1, 'port' if side > 0 else 'starboard'), _bpy.data.objects['%s_mount_flesh' % fid], 'flesh sac', note='hanging below the hull')

    # ---------------- siphons ----------------
    for side in (1, -1):
        sn = 'p' if side > 0 else 's'
        pos, nrm = K.hpt(1.75, side_th(-0.55, side), out=-0.02)
        K.thruster('Q1' + sn, tuple(pos), tuple(nrm), r=0.12, inv='siphons', note='siphon below the prow: swings the bow')
        pos, nrm = K.hpt(-1.5, side_th(0.6, side), out=-0.02)
        K.thruster('Q2' + sn, tuple(pos), tuple(nrm), r=0.11, inv='siphons', note='siphon aft: swings the stern')

    # ---------------- the vent ring and its trailing membranes (engines) ----------------
    for k in range(VENTS):
        a = 2 * math.pi * (k + 0.25) / VENTS
        y, z = 0.22 * math.cos(a), 0.01 + 0.2 * math.sin(a)
        K.engine('E%d' % (k + 1), (-1.93, y, z), 0.075, 0.42, bell=1.0, body_r=0.1, inv='vents', src='picture',
                 kw=dict(trail='veil', trails=3, trail_len=1.55, veil=2.7, fan=0.52, splay=30.0, out_dir=(0, math.cos(a), math.sin(a)), seed=k),
                 note='pulse vent with three wide flowing veils that fan, cup and curl, splayed away from the ring\'s centre')
    K.mass('Vent ring', _bpy.data.objects['E1_mount_flesh'], 'flesh', note='four pulse vents round the stern\'s end, their veils streaming aft')

    # ---------------- the armour (issue 1291, R349, the C13 round G look on the shared kit) ----------------
    # armadillo bands of grown chitin wrapping the body down to the keel (plates.WRAP), broken round the
    # knoll, the tendril knot, the domes, the sacs, the siphons and the vents; the draped tendrils lie over the shell (skipped
    # as keep-outs); flat caps over the domes; the belly is banded too
    plates.armadillo(K, _k, 2.15, -1.85, seed=1346, band=0.3, lap=1.45, thick=0.05, skip=('T1_body_',),
                     note='armadillo bands of grown chitin wrapping the body down to the keel, lips aft; broken round the knoll, the knot, domes, sacs, siphons and vents; hide rolled at the edges; the tendrils lie over it')
    plates.dome_caps(K, _k, caps, seed=1347, flat=True,
                     note='flat grown chitin caps over the bile domes, two rings of thin plates lying close, the bile window open at each crown (round G)')

    # ---------------- colour zones ----------------
    K.colour('dark olive flesh, callused olive hide, dark red veins (paint stage, R349)', 2.35, -1.75, 'whole body')
    K.colour('grown chitin, bone to horn, over olive-brown hide (R349)', 2.15, -1.85, 'the armadillo bands, belly edge to belly edge')
    K.colour('raw puckered flesh', 3.0, 2.2, 'the prow knoll')
    K.colour('pale ochre bone', 3.0, 2.8, 'the short hooks round the bore')
    K.colour('bile yellow-green light', 3.0, 2.4, 'the gland deep in the knoll\'s vent')
    K.colour('bile yellow-green light', -1.7, -3.25, 'the vents and the light in the membranes')
    K.colour('dim bile', 2.2, -1.5, 'the dome windows, the tendril tips\' acid pores')

    # ---------- INSIDE: flesh, bone and organs ----------
    K.septum('lower', -0.42, 1.9, -1.3, inset=0.22, t=0.05)
    K.septum('upper', 0.38, 1.9, -1.3, inset=0.22, t=0.05)
    for i, x in enumerate((1.95, 1.4, 0.85, 0.3, -0.25, -0.8, -1.3)):
        K.hoop('F%d' % i, x, inset=0.18, w=0.08, t=0.07)
    K.organ_room('bile_gland', 'gland', (1.75, 0.0, -0.05), (0.32, 0.26, 0.24), note='the knoll\'s bile gland: the shot\'s magazine', seed=1)
    K.organ_room('ganglion', 'ganglion', (1.2, 0.0, 0.5), (0.24, 0.2, 0.15), note='the Node: the knot of nerve that steers the body', seed=3)
    for i, x in enumerate(DOMES):
        for side in (1, -1):
            K.organ_room('bile_store_%d%s' % (i + 1, 'p' if side > 0 else 's'), 'gland', (x, side * (0.56 - 0.06 * i), -0.15), (0.2, 0.14, 0.15),
                         note='the bile store behind the dome', seed=10 + i)
    K.organ_room('heart_vat', 'vat', (0.25, 0.0, 0.0), (0.42, 0.34, 0.3), note='the heart vat: the core (hp_core), lit bile-green', seed=20)
    K.organ_room('gut', 'gut', (0.95, 0.0, -0.4), (0.55, 0.34, 0.2), note='the gut (kept well off the belly skin: death seam check, issue 1153 run 1)', seed=21)
    for i, (x, side, r) in enumerate(SACS):
        K.organ_room('regrowth_%d' % (i + 1), 'organ', (x, side * 0.32, -0.5), (0.26, 0.2, 0.16), note='regrowth tissue over the reserve sac (regen 3)', seed=23 + i)
    K.organ_room('knot_muscle', 'organ', (MOUND_X, 0.0, 0.52), (0.42, 0.3, 0.16), note='the knot\'s root muscle: it throws the tendrils', seed=25)
    K.organ_room('pulse_bladder', 'engroom', (-1.3, 0.0, 0.0), (0.28, 0.26, 0.22), note='the pulse bladder: fills and squeezes the four vents (the engine room)', seed=26)
    K.armour('prow and knoll', 0.2, 'the thickest flesh, over the knoll\'s root')
    K.armour('back (the knot)', 0.18, 'thick folded flesh under the knot\'s root')
    K.armour('flanks and domes', 0.12, 'thin over the domes: they rupture first')
    K.armour('belly', 0.12, '')
    K.armour('stern', 0.1, '')
    # one break line (Frigate: 1, factions.md): the head tears away ahead of the knot, opening the gut, the Node and the heart vat's fore end
    K.break_line('B-1', 0.85, 'ahead of the knot: the prow and the knoll tear away, opening the gland, the Node and the gut; the fore domes burst first',
                 path=[(1.0, 3.0), (1.0, 1.15), (0.7, 0.6), (0.98, 0.1), (0.72, -0.45), (0.95, -1.1), (0.95, -3.0)])
    K.inside.append(dict(kind='note', name='insides', note='Flesh, bone and organs through the whole body (R215), hidden until a piece breaks: bone hoops for frames, '
                                                          'membrane septa for decks, organs and chambers that never reach the skin. The Chorus bursts and tears: sacs rupture first, '
                                                          'then the body tears open along a ragged line (R186).'))
    K.point('core', 'hp_core', (0.25, 0.0, 0.0))
    # two breach anchors (Frigate base 2; the Chorus extra is for the big ones only): prow and engine, opposite sides
    for i, (x, th, sec, side) in enumerate(((1.5, 0.15, 'prow', 1), (-0.95, -0.5, 'eng', -1))):
        pos, nrm = K.hpt(x, side_th(th, side), out=0.02)
        K.point('breach', 'hp_breach_%d' % i, tuple(pos), side='port' if side > 0 else 'stbd', section=sec, note='open hide beside a dome')
    for i, (x, th, side) in enumerate(((1.75, -0.55, 1), (1.75, -0.55, -1), (-1.5, 0.6, 1), (-1.5, 0.6, -1))):
        pos, nrm = K.hpt(x, side_th(th, side), out=0.02)
        K.point('rcs', 'hp_rcs_%d' % i, tuple(pos), side='port' if side > 0 else 'stbd')
    # boarding origins (export7: one port, one starboard on the mid hull): where the boarding parties leave the body
    for i, side in enumerate((1, -1)):
        pos, nrm = K.hpt(0.55, side_th(0.35, side), out=0.02)
        K.point('board', 'hp_board_%d' % i, tuple(pos), side='port' if side > 0 else 'stbd')

    # ---------- changed from the picture (designer's decisions, R207) ----------
    K.change('The C13 round G look on the shared kit: lumpy swellings and folds grown into the skin (body.field), armadillo bands of grown '
             'chitin down to the keel, flat chitin caps over the domes, the belly banded too (Ryan, Nov 20: armour almost everywhere); the R341 scute shell removed',
             'Ryan, Nov 20 (R349; C13 round G accepted in game, PR 1308): armour across the entire body, grown not tiled, "caps, but flatter"; '
             'issue 1291 brings C10 to C12 to the same kit calls')
    K.change('Colour: bile yellow-green light over dark olive flesh, pale ochre bone; hard chitin plates over most of the hull in the paint (R325, Ryan Nov 19)',
             'R204 and the lore: the colour is fixed in the build; the picture renders the family\'s grey-amber anchor palette')
    K.change('The head\'s puckered mouth is the spine volley (bioplasma F): one deep dark bore about half the lip\'s width, in a soft puckered lip that flares from a waist, twelve short bone hooks set into the lip (Board on blockout v2: a deep bore, never a disc or a lit dot; the head blends into the body; Board on v3: open the bore so it dominates bow-on, no straight collar)',
             'data.js b_drone has one bioplasma slot (issue 649, Ryan\'s "send the frigate back on guns"); 2 shots leave the one vent in turn')
    K.change('The tendril mound is fixed, not a turret: a knot of muscle holding five draped tendrils (new kit part type drape; accepted by the Board on blockout v2)', 'the slot is all round (T); tendrils lying over the hull reach every way at once, as C11\'s mane (issue 623); a turning crown would sweep them through the hull')
    K.change('The tendrils are laid on the hull clear of the hide and hang free below the waterline at their tips', 'they must not sit in the hull (fit check CLASH); the picture\'s tips hang off the flanks')
    K.change('The domes on the flanks are bile stores feeding the knoll; veins run forward to it', 'every part has a job (R221); designs.md does not name them; the picture shows three a side')
    K.change('The two hanging sacs are the regrow reserve, one each side, staggered', 'designs.md (regen 3); staggered so neither hides behind the other in the side view')
    K.change('The stern is a ring of four pulse vents with three wide flowing veils each (a new kit trail, veil: thin sheets that fan, cup and curl), about 1.45 long', 'factions.md: no nozzles, trailing membranes; the picture\'s veils, cut to fit the 6.5 length; the Board on blockout v2: fewer, wider, curved sheets, never stiff blades')
    K.change('Siphons added, a pair forward and a pair aft', 'a ship in space must turn; the picture shows none')
    K.change('The back is wrinkled flesh with seven long folds running bow to stern under the tendrils; no bone on the back', 'the Board on blockout v2: the picture\'s back reads as lengthwise folds and ridges, and the scattered bone chunks read as debris; large relief that reads at camera 170')
    K.open_item('The belly is designed here: the sheet\'s bow-on view shows only the two sacs below')
