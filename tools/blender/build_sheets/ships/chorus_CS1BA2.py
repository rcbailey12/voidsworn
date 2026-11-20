# chorus_CS1BA2: the Chorus spore swarm craft, the Sealed Gills, sleek (data.js spore: cls 'Squadron', sporeb T; hp 26, sp 5).
# Issue 793. Concept of record: contrib/muse/design/squadron_concepts_2026_11/chorus/round_4/CS1BA2.jpg (design_notes_785_round4.md;
# Ryan, Nov 15 2026, R259: "the closed-hull Chorus direction is much better", the craft "a bit sleeker"; CS1B-A2 the pick). The
# written sheet governs where the render drifts: the render runs the stern out to a spike and the bone line into a point, the
# bow fork into two long prongs, and the amber too strong; the sheet tapers the hull behind a full-size orifice cluster and ends
# blunt, keeps the fork short, blunt and low, and the amber matte and muted.
# Designer of record: the Opus builder, the Board the final designer (R205, R207, R233, R236): CS1B-A2 is a base, not a trace.
# Ryan's words that bind (R254, R259): no canopy, no swept aero wings, no tail fins, nothing hung under a hull; the hull closed:
# no open grooves, no exposed fluid, no round clear domes; amber is translucent fluid colour only, no glow; each faction its own
# craft (R253). factions.md, The Chorus: grown, not built; no eyes, no face, no metal; dark olive-brown hide, ochre bone.
# Size: docs/playbooks/scale.md, Squadron row (binding): CLS_LEN['Squadron'] 1.6 long, drawn x SHIP_K 1.6 x SQUADRON_K 1.5 = 3.84.
# Every station and size below is a share of LENGTH (the U() helper). +X bow, +Y port, +Z up. Bow fork x = +0.8, the orifice
# cluster's mouths x = -0.8.
import math

CODE = 'chorus_CS1BA2'
NAME = 'Sealed Gills spore swarm (the Chorus spore swarm craft)'
FACTION = 'The Chorus (chorus)'
CLASS = 'Squadron'
LENGTH = 1.6
GAME = "data.js spore (cls 'Squadron', the Chorus wing: chorus sq 'spore'); length from godot/render/hull_table.gd CLS_LEN['Squadron'] = 1.6 (drawn x SHIP_K 1.6 x SQUADRON_K 1.5 = 3.84 on the board, docs/playbooks/scale.md)"
BEAUTY = 'contrib/muse/design/squadron_concepts_2026_11/chorus/round_4/CS1BA2.jpg'
KIT = 'chorus'
CONCEPT_SHEET = BEAUTY
CONCEPT_VIEWS = dict(top=dict(box=(30, 50, 1060, 660)), side=dict(box=(30, 50, 1060, 660)))
CROPS = [('bow (the fork, the bone line, the pore spots)', (30, 380, 520, 660)), ('midships (the sealed gill bladder)', (220, 120, 860, 600)),
         ('stern (the orifice cluster)', (600, 50, 1060, 380))]
SHEET = dict(version=1, round='first sheet', date='2026-11-15', blend='opus793', px_per_unit=900, view_pad=0.12, label_scale=1.5, bar_units=0.5,
             blend_where='rendered in the issue 793 sandbox (Blender 5.3, Cycles CPU); not on the PC: `build.py chorus_CS1BA2 <out> render` rebuilds it from this file',
             before='First full layout', before_note='The first complete layout, built with the Chorus kit\'s new craft parts and run through the fit check before any fix.',
             during='The table above is every finding, in the order the check made them.')


def U(v):
    """a share of the craft's length in world units"""
    return v * LENGTH


# ---------------------------------------------------------------------------------------------------- the body
# One grown spindle, drawn out along its flight axis (sleeker than CS1B-A: longer against beam and depth, lower): (n, half-beam,
# belly, top), shares of LENGTH, a rounded section (the sheet kit's superellipse, near an ellipse: grown, never a box). The bow
# tapers to a smooth blunt point; the stern tapers to a blunt end that carries the full-size orifice cluster.
BODY = [
    (0.500, 0.010, -0.004, 0.010),
    (0.470, 0.030, -0.016, 0.024),
    (0.420, 0.054, -0.028, 0.038),
    (0.330, 0.088, -0.042, 0.054),
    (0.200, 0.120, -0.054, 0.066),
    (0.050, 0.138, -0.060, 0.072),
    (-0.100, 0.140, -0.060, 0.070),
    (-0.250, 0.124, -0.054, 0.062),
    (-0.370, 0.096, -0.044, 0.050),
    (-0.440, 0.080, -0.040, 0.045),
    (-0.470, 0.072, -0.038, 0.042),
]
P_TOP, P_BOT = 2.5, 2.2
X_END = -0.47
SAC = dict(x0=0.25, x1=-0.33, th=0.62, w=0.05, out=0.016)   # the gill bladders: front, back, section angle (from the beam), half-width, swell


def sec(n):
    s = sorted(BODY, key=lambda r: -r[0])
    if n >= s[0][0]:
        return list(s[0])
    if n <= s[-1][0]:
        return list(s[-1])
    for a, b in zip(s, s[1:]):
        if a[0] >= n >= b[0]:
            t = (a[0] - n) / (a[0] - b[0])
            return [a[i] + (b[i] - a[i]) * t for i in range(len(a))]


def flank_y(n, z):
    """the hull's half-beam at station n and height z (both shares), the rounded section's own curve"""
    _, hw, zb, zt = sec(n)
    zc = (zb + zt) / 2; hz = (zt - zb) / 2
    u = max(-1.0, min(1.0, (z - zc) / hz)); p = P_TOP if u >= 0 else P_BOT
    sn = abs(u) ** (p / 2.0); cs = max(0.0, 1 - sn * sn) ** 0.5
    return hw * cs ** (2.0 / p)


HULL = [(U(r[0]), U(r[1]), U(r[1]), U(r[2]), U(r[3]), 0.0, 0.0) for r in BODY]


def build(K):
    import bpy
    import kit as _k
    from mathutils import Vector
    HP = _k.HP
    for k_, v_ in getattr(HP, 'MATS', {}).items():   # the craft's amber blush lives in the faction kit (tools/blender/kits/chorus)
        _k.MATS.setdefault(k_, v_)
    K.hull_sections = [(U(r[0]), U(r[1]), U(r[1]), U(r[2]), U(r[3]), 0.0, 0.0) for r in BODY]
    K.hull_rounded = True
    K.p_top, K.p_bot = P_TOP, P_BOT
    ns = sorted({r[0] for r in BODY} | {round(0.48 - 0.03 * i, 3) for i in range(33) if 0.48 - 0.03 * i > X_END}, reverse=True)
    secs = [(U(r[0]), U(r[1]), U(r[1]), U(r[2]), U(r[3]), 0.0, 0.0) for r in [sec(n) for n in ns]]
    # the hide: callus pads with sense pores at the craft's own scale (the Chorus kit's pads; never panels)
    PAD = dict(courses=True, keep3d=True, size=(U(0.03), U(0.06)), thick=(U(0.0008), U(0.0018)), step=0.0, gap=U(0.005), over=0.0, skip=0.62,
               stack=0.0, rivets_share=0.0, rivet_r=U(0.0022), mats={'hide': 3, 'flesh2': 2})   # no rivet pores: the courses tool makes them iron
    body = K.loft(CODE + '_body', secs, 'flesh', shell=U(0.004), rounded=True, pexp=(P_TOP, P_BOT), n=28, smooth=True,
                  plates=dict(PAD, seed=61, inv='hide'))
    K.mass('Hull: the grown spindle', body, 'dark olive flesh', note='one sleek grown spindle, drawn out along its flight axis; a smooth blunt bow, the stern tapering to a blunt end that carries the orifice cluster')
    K.mark('body', 'hull', ['ridge', 'fold', 'pore'])

    # ---------------- the bone spine: one long low bone line along the back, splitting at the bow into a short blunt fork ----------------
    def ridge_pts(n0, n1, th_fn, out=0.0, k=20):
        pts, nrm = [], []
        for i in range(k + 1):
            n = n0 + (n1 - n0) * i / k
            q, nn = K.hpt(U(n), th_fn(n), out)
            pts.append(q); nrm.append(nn)
        return pts, nrm
    pts, nrm = ridge_pts(-0.4, 0.4, lambda n: math.pi / 2)
    wd = [U(0.012 + 0.012 * math.sin(math.pi * (i / 20) ** 0.8)) for i in range(21)]
    K.hull_detail('CS_spine', HP.welt(pts, nrm, wd, [w_ * 0.45 for w_ in wd], n=6), 'bone', inv='spine', kind='welt', subs=['welt'])
    for side in (1, -1):
        # the fork: the bone line parts round the bow's last tenth and runs down to the tip, low and blunt, never a prong
        pts, nrm = ridge_pts(0.4, 0.496, lambda n, s=side: math.pi / 2 - s * (0.18 + 4.5 * (n - 0.4)), k=10)
        wf = [U(0.012 - 0.005 * i / 10) for i in range(11)]
        K.hull_detail('CS_fork_%s' % ('p' if side > 0 else 's'), HP.welt(pts, nrm, wf, [w_ * 0.5 for w_ in wf], n=6), 'bone', inv='spine', kind='welt', subs=['welt'])
    # growth knuckles along the spine (the bone's growth lines)
    KV, KF = [], []
    for n in (-0.3, -0.18, -0.06, 0.06, 0.18, 0.3):
        q, nn = K.hpt(U(n), math.pi / 2, U(0.004))
        ax = Vector((1, 0, 0))
        vv, ff = HP.welt([q - Vector((0, U(0.016), 0)), q, q + Vector((0, U(0.016), 0))], [nn] * 3, U(0.006), U(0.004), n=4)
        o = len(KV); KV += vv; KF += [tuple(x + o for x in f) for f in ff]
    K.hull_detail('CS_spine_growth', (KV, KF), 'chitin', inv='spine', kind='welt', subs=['welt'])

    # ---------------- the sense pores along the bow ridge (the concept's spots: the Chorus has no eyes) ----------------
    PV, PF = [], []
    for side in (1, -1):
        for i, n in enumerate((0.36, 0.32, 0.285, 0.25, 0.215, 0.18)):
            th = math.pi / 2 - side * (0.32 + 0.06 * (i % 2))
            q, nn = K.hpt(U(n), th, -U(0.0005))
            vv, ff = HP.pore(q, nn, U(0.0045 + 0.0012 * (i % 3)), n=7)
            o = len(PV); PV += vv; PF += [tuple(x + o for x in f) for f in ff]
    K.hull_detail('CS_sense_pores', (PV, PF), 'pore', inv='sense_pores', kind='pore', subs=['rim', 'pit'])

    # ---------------- veins over the flanks and the belly, and fold rolls where the stern tapers ----------------
    VV, VF = [], []
    for side in (1, -1):
        for j, (th0, n0, n1) in enumerate(((0.62, 0.3, -0.36), (-0.55, 0.25, -0.4), (-1.15, 0.12, -0.3))):
            pts, nrm = ridge_pts(n0, n1, lambda n, t0=th0, s=side: (math.pi / 2 - s * (math.pi / 2 - t0)) + 0.08 * math.sin(n * 23 + j), k=18)
            vv, ff = HP.welt(pts, nrm, U(0.004), U(0.0025), n=4)
            o = len(VV); VV += vv; VF += [tuple(x + o for x in f) for f in ff]
    K.hull_detail('CS_veins', (VV, VF), 'vein', inv='veins', kind='vein', subs=['vein', 'branch'])
    FV, FF = [], []
    for side in (1, -1):
        for j, (n0, th0) in enumerate(((-0.345, 0.5), (-0.36, -0.2), (-0.375, 0.15))):
            # short creases where the stern draws in (never full rings: no grub segments, factions.md)
            pts, nrm = [], []
            for i in range(9):
                th = math.pi / 2 - side * (math.pi / 2 - th0) + side * 0.06 * i
                q, nn = K.hpt(U(n0 - 0.009 * i), th, 0.0); pts.append(q); nrm.append(nn)
            vv, ff = HP.welt(pts, nrm, U(0.006), U(0.003), n=4)
            o = len(FV); FV += vv; FF += [tuple(x + o for x in f) for f in ff]
    K.hull_detail('CS_stern_folds', (FV, FF), 'flesh2', inv='stern_folds', kind='welt', subs=['welt'])

    # ---------------- the weapon: two sealed gill bladders, one per flank (sporeb T, 2 shots) ----------------
    # each bladder lies along the upper flank between the bone line and the waist (the concept's big banded ovals either side of
    # the spine), its outward axis the flank's own normal there, swelling SAC['out'] proud of the hull at its middle
    x0, x1, th0, w, out = SAC['x0'], SAC['x1'], SAC['th'], SAC['w'], SAC['out']
    for side, fid in ((1, 'S1'), (-1, 'S2')):
        th = th0 if side > 0 else math.pi - th0
        F_, _ = K.hpt(U(x0), th, U(0.012)); B_, _ = K.hpt(U(x1), th, 0.0); M_, nM = K.hpt(U((x0 + x1) / 2), th, 0.0)   # the mouth stands just proud of the skin
        d_ = F_ - B_; d_.z = 0.0
        L_ = d_.length; yaw = math.degrees(math.atan2(d_.y, d_.x))
        fwd = d_.normalized()
        Am = Vector((F_.x, F_.y, (F_.z + B_.z) / 2)) - fwd * (L_ / 2)
        gap = max(0.0, (M_ - Am).dot(nM))
        tilt = math.degrees(math.atan2(nM.z, abs(nM.y)))
        K.launcher(fid, (F_.x, F_.y, (F_.z + B_.z) / 2), 1, 1, cell=U(2 * w), depth=L_, yaw=yaw, pitch=0.0, slot='T', weapon='sporeb', inv='gill_bladders',
                   variant=(side, tilt, gap + U(out)),
                   note='the %s acid sac (data.js sporeb T, 2 shots): a sealed gill bladder swelling the upper flank, gill bands across it, a closed sphincter at its front; each sac bursts every volley' % (
                       'port' if side > 0 else 'starboard'))
        K.features[-1]['what'] = 'sealed gill bladder, %.2f long, a closed sphincter at its front' % L_
        c_, r_ = K.keepouts.pop()
        for f_ in (-0.35, 0.0, 0.35):   # the bladder is long and narrow: keep-outs along it, not one circle round it all
            K.keepouts.append((M_ + fwd * (L_ * f_), U(0.06)))

    K.fix('S1 and S2: each launch cell covered by the body at 0.0 (EXIT): the sac\'s mouth sat in the skin, so the burst\'s rays started inside the hull',
          'the burst leaves through the pucker\'s centre (the exit radius 0.4 of the sphincter\'s), and the mouth stands 0.02 proud of the skin at the sac\'s front')
    K.fix('S1 and S2 across the seam B-1 at -0.50 (the stage 4 audit: a machine never crosses a seam, R226)',
          'the seam moved aft to -0.60, behind the sacs\' tails and ahead of the orifices\' roots; the pulse muscle shrunk to sit behind it')

    # ---------------- the drive: the muscle-ringed orifice cluster on the blunt stern ----------------
    ORI = [(0.022, 0.0195, 0.0135), (-0.023, 0.0185, 0.013), (0.021, -0.019, 0.0128), (-0.022, -0.0195, 0.0135)]   # (y, z, mouth radius)
    for i, (y, z, r) in enumerate(ORI):
        K.engine('E%d' % (i + 1), (U(X_END - 0.028), U(y), U(z + 0.001)), U(r), U(0.07), bell=1.0, kw=dict(craft=True, seed=i), inv='orifices',
                 note='%s orifice of the cluster: a muscle ring squeezing pulses of bile gas aft (no nozzle)' % ('upper port', 'upper starboard', 'lower port', 'lower starboard')[i])
        K.features[-1]['what'] = 'orifice, mouth %.3f across' % (2 * U(r))

    # ---------------- the armour shell (issue 1373, R362: the craft takes the Chorus hull finish of round G) ----------------
    # the C13 armadillo shell (issue 1291, Ryan Nov 20: grown chitin bands wrapping the body from belly edge to belly edge, lips
    # aft) at the craft's own scale: bands broken round the gill bladders and along the bone line, the nose and the orifice
    # cluster left bare; the grown skin paints it (tools/blender/kits/chorus/stack.py, the kit default since PR 1350)
    import sys as _sys
    if _k._KITS not in _sys.path:
        _sys.path.append(_k._KITS)
    from chorus import plates
    plates.armadillo(K, _k, U(0.40), U(-0.40), seed=1373, lo=-1.2, band=U(0.065), lap=1.45, thick=U(0.0079),
                     keep=('CS_spine', 'CS_fork'), scale=LENGTH / 9.5, res=0.3,
                     note='armadillo bands of grown chitin wrapping the craft from belly edge to belly edge, lips aft; broken round the gill bladders and along the bone line (round G, C13)')

    # ---------------- colour zones ----------------
    K.colour('dark olive-brown flesh and callused hide (factions.md; R204: colour fixed in the build, not by the concept\'s plum)', U(0.5), U(-0.5), 'whole body')
    K.colour('ochre bone: the spine line and its fork; chitin growth knuckles', U(0.5), U(-0.4), 'the back')
    K.colour('muted matte amber in the gill valleys (no glow); bile yellow-green only deep in the orifices', U(0.17), U(-0.5), 'the bladders, the orifices')

    # ---------------- INSIDE: kept small; grown organs, never boxes ----------------
    for side in (1, -1):
        K.organ_room('acid_gland_%s' % ('p' if side > 0 else 's'), 'gland', (U(-0.06), U(side * 0.07), U(0.0)), (U(0.17), U(0.04), U(0.03)), seed=3 + (side > 0),
                     note='the %s acid gland: it fills the sac behind it' % ('port' if side > 0 else 'starboard'))
    K.organ_room('ganglion', 'ganglion', (U(0.22), 0.0, U(0.004)), (U(0.07), U(0.035), U(0.028)), seed=7, note='the swarm-mind\'s ganglion: the craft\'s pilot, wired to the sense pores ahead of it')
    K.organ_room('gut', 'gut', (U(-0.22), 0.0, U(0.0)), (U(0.08), U(0.05), U(0.035)), seed=9, note='the gut that feeds the pulse muscles')
    K.organ_room('pulse_muscle', 'organ', (U(-0.42), 0.0, U(0.0)), (U(0.034), U(0.042), U(0.028)), seed=11, note='the pulse muscle behind the orifice cluster')
    K.armour('hide', U(0.004), 'callused hide over the whole body; the bladders\' skin thinnest')
    reach = 0.3
    K.break_line('B-1', U(-0.375), 'the body tears behind the bladders (the Chorus bursts and tears; only for the recipe\'s records: the game never breaks a craft)',
                 path=[(U(-0.375), U(reach)), (U(-0.375), U(0.1)), (U(-0.367), U(0.05)), (U(-0.383), U(0.0)), (U(-0.37), U(-0.05)), (U(-0.375), U(-0.1)), (U(-0.375), U(-reach))])
    K.inside.append(dict(kind='note', name='insides', note='A craft: the game shows its death as a spark and hides it (godot/fx/fx_death.gd _wing_death); nothing breaks open. These few grown organs are here because the build contract needs an inside (tools/blender/build_sheets/contract.py); they cost few triangles.'))
    K.point('core', 'hp_core', (U(-0.12), 0.0, U(0.0)))

    # ---------- changed from the picture (designer's decisions, R207, R233, R236) ----------
    K.change('Length 1.6 (CLS_LEN Squadron; drawn 3.84 on the board), the same as every craft; length to beam about 3.1',
             'docs/playbooks/scale.md, Squadron rows, binding; Ryan (R259): a bit sleeker, so the body is drawn out along its flight axis and kept low')
    K.change('Dark olive-brown flesh and ochre bone, not the render\'s plum',
             'factions.md (The Chorus: dark olive-brown hide, ochre bone, never red or magenta flesh) and R204 (colour is set in the build); the swarm reads as the same faction as the C10 and C11 hulls beside it')
    K.change('The concept\'s eye-spots along the bow ridge are sense pores: raised rims round sunk pits',
             'factions.md: the Chorus never has eyes; the kit\'s pores are its senses ("it tastes the dark")')
    K.change('The bow fork is the bone line parting round the last tenth of the bow and running down to the tip, low and blunt',
             'the round 4 notes: the render draws two long prongs; the sheet keeps the fork short, blunt and low (DeepSeek: never forward prongs)')
    K.change('The stern tapers to a blunt end that carries the full-size orifice cluster (four muscle-ringed orifices facing aft), short creases where it draws in (never full rings: no grub segments)',
             'the round 4 notes: the render runs the stern to a spike; the sheet tapers only the hull behind the cluster and ends blunt. The orifices are the drive, so they face aft')
    K.change('Each gill bladder is one sac part: a long low swell of the flank, six raised gill bands, a matte amber blush in the five valleys, a closed puckered sphincter at its front',
             'data.js sporeb (2 shots) is the swarm\'s only weapon, one sac per flank, both bursting every volley; the burst needs a mouth, kept shut at rest (nothing open, no exposed fluid, R259)')
    K.change('The sacs are fixed, aimed three degrees out from the bow', 'a craft turns onto its prey on a strafing run (the bomber\'s reading, weapon_match.py FITS sporeb: an acid sac on a launcher, issue 793)')
    K.change('No membranes trailing from the orifices', 'the capital ships\' trailing veils would hang far behind a 3.84 unit craft and read as a tail; the pulse shows in the bile glow deep in each orifice')
    K.change('A small inside: two acid glands, the ganglion, the gut, the pulse muscle; one seam (B-1)',
             'the game shows a craft\'s death as a spark and hides it (fx_death.gd _wing_death), so nothing breaks open; the build contract needs an inside and a seam')
    K.open_item('The flesh tones, the bone and the amber are schematic colour zones: the Chorus has no paint stack yet')
    K.open_item('data.js gives the Chorus hull colour as plum (#57364c) while factions.md and the C10 and C11 sheets use olive; the sheet follows factions.md. The Board may want the two brought in line')
    K.open_item('How a sheet craft reaches the game: the game builds every craft in code today (godot/render/squadron_craft.gd), so no stage 7 export or install here')
