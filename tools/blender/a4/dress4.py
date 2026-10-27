# A4 surface dressing that the A2 set (tools/blender/a2detail/dress.py) does not have: Corsair salvage patchwork on an AI hull.
# The barge grammar (tools/blender/a1/barge_v15.py, detail_lib.detail_pass with corsair=True): bolted stolen plates in rust, Hegemony grey,
# bare steel and bone, a few degrees off square, welded or riveted; pipe runs that break around parts; vents; junk boxes; hazard plates.
# Corsair is deliberately lopsided (CLAUDE.md exception), so placements are singles, not mirrored pairs.
import math, random
import numpy as np
from mathutils import Vector, Matrix
import detail_lib, dress
from dress import plate, vent, housing, tube_path, frame_for, mul, tag

SALVAGE = [((.100, .034, .014), .36), ((.16, .055, .022), .16), ((.060, .022, .010), .12), ((.20, .21, .22), .13), ((.19, .18, .17), .10),
           ((.42, .38, .30), .05), ((.30, .08, .025), .04), ((.12, .12, .13), .04)]


def pick(r, table):
    u = r.random(); acc = 0
    for c, w in table:
        acc += w
        if u <= acc: return c
    return table[0][0]


def singles(H, rng, count, accept, rad, k=1.0, tries=40):
    N = len(H.sp); made = 0; t = 0
    while made < count and t < count * tries:
        t += 1; i = int(rng.integers(N))
        if not accept(i): continue
        p = Vector(H.sp[i].tolist()); n = Vector(H.sn[i].tolist()); r = rad(rng) if callable(rad) else rad
        if not H.free(p, r, k): continue
        H.placed.append((p, r)); made += 1; yield p, n, r


# trophy plates (lore note Oct 27: Corsairs grimmer and more menacing, trophy plates): armour torn off the ships they took, in the victim's
# own paint and trim stripe, bolted on crooked with heavy clamps, a bone-white kill tally scratched across. Victims whose looks are settled
# only (Hegemony parade grey with blue, Voidsworn black with ember red, Chorus chitin with gold); Ithar and Deathless looks are changing.
TROPHY = [(((.55, .60, .66), (.06, .19, .62)), .45), (((.030, .028, .027), (.34, .045, .012)), .35), (((.10, .042, .075), (.37, .29, .045)), .20)]
BONE = (.62, .57, .46)


def trophy_plates(H, S, rng, r, count, props, loose=False):
    made = 0
    ok = lambda i: abs(H.sn[i][1]) > .55 and H.ao[i] > .45 and abs(H.cv[i]) < .10 and H.sp[i][0] > -.30
    if loose:  # the war-barge (dress over 1.2): its welded sponsons hide most flank, so decks and the outer flanks take trophies too
        ok = lambda i: (abs(H.sn[i][1]) > .45 or H.sn[i][2] > .75) and H.ao[i] > .40 and abs(H.cv[i]) < .12 and H.sp[i][0] > -.42
    for p, n, rad in singles(H, rng, count, ok, lambda g: g.uniform(.030, .040), k=1.0, tries=160 if loose else 80):
        (base, stripe) = pick(r, TROPHY); w, h = r.uniform(.045, .070), r.uniform(.026, .038)
        t, b, n1 = frame_for(n); Rm = Matrix.Rotation(math.radians(r.uniform(-14, 14)), 3, n1); t, b = Rm @ t, Rm @ b
        th = .0030; pts = detail_lib.outline(r.choice(('slant', 'trap', 'chamfer')), w, h, r)
        if not plate(H, S, f'ctro{made}', p, n1, t, b, pts, th, -.0003, mul(base, r.uniform(.8, 1.0)), dict(rgh=.45, met=.35), 2, random.Random(r.random())): continue
        top = p + n1 * (th - .0003)
        sv = r.uniform(-.25, .25) * h  # the victim's trim stripe across the plate
        detail_lib.obox(f'ctro{made}s', top + b * sv + n1 * .0010, t, b, n1, (w * .86, h * .16, .0010), bevel=0); tag(stripe, rgh=.45, met=.3)
        u0 = r.uniform(-.30, -.05) * w  # kill tally: groups of four strokes and a slash, scratched in bone white
        for g in range(r.choice((1, 2, 2, 3))):
            for k in range(4):
                detail_lib.obox(f'ctro{made}k{g}{k}', top + t * (u0 + g * w * .22 + k * w * .035) - b * h * .22 + n1 * .0010, t, b, n1, (w * .010, h * .32, .0008), bevel=0)
            detail_lib.obox(f'ctro{made}x{g}', top + t * (u0 + g * w * .22 + w * .052) - b * h * .22 + n1 * .0010, t, b, n1, (w * .16, h * .025, .0009), bevel=0, rot=math.radians(28))
        tag(BONE, rgh=.7, met=.05)
        for s in (-1, 1):  # heavy clamps biting over the plate edge onto the hull
            q = p + t * s * w * .44
            detail_lib.obox(f'ctro{made}c{s}', q + n1 * .0012, t, b, n1, (w * .07, h * .30, .0034), bevel=.0003)
        tag((.07, .07, .075), rgh=.55, met=.7)
        made += 1
    return made


def dress_corsair(H, S, seed, P, amount=1.0):
    rng = np.random.default_rng(seed); r = random.Random(seed)
    dark = P['dark']; open_ok = lambda i: H.ao[i] > .42 and abs(H.cv[i]) < .14
    props = dict(rgh=.62, met=.32); n_pl = fit = nrun = 0
    n_tro = trophy_plates(H, S, rng, r, max(2, int(round(6 * amount))) + (6 if amount > 1.2 else 0), props, loose=amount > 1.2)
    # pipe runs along the flanks at uneven heights, port and starboard picked separately (lopsided on purpose)
    for side in (1, -1):
        rows = [r.uniform(.35, .62) for _ in range(r.choice((1, 2)))]
        for run in dress.side_rows(H, S, rows, step=.010):
            rr = run if side > 0 else []
            if side < 0:
                for q, qn in run:
                    q2, n2 = H.nearest(H.mirror_p(q) + Vector((0, 0, r.uniform(-.004, .004))), .01)
                    if q2 is None: break
                    rr.append((q2, n2 if n2.dot(H.mirror_v(qn)) > 0 else -n2))
                if len(rr) < 6: continue
            seg = rr[:max(6, int(len(rr) * r.uniform(.5, 1.0)))]
            pr = r.choice((.0018, .0024, .0030))
            if tube_path(f'cpipe{nrun}', seg, pr, pr, pr * .6, seg=8): tag(r.choice(((.07, .07, .075), (.17, .165, .16), (.16, .055, .022))), rgh=.5, met=.65)
            H.placed += [(q, .005) for q, _ in seg[::2]]
            for k in range(0, len(seg), r.choice((4, 5, 6))):
                q, qn = seg[k]; t, b, n1 = frame_for(qn); detail_lib.obox(f'cpbr{nrun}_{k}', q + qn * .0018, t, b, n1, (.003, .005, .0036), bevel=0)
            tag((.07, .07, .075), rgh=.6, met=.5)
            nrun += 1
    # salvage plates: mixed shapes and colours, off square, welded or riveted
    sizes = [(.60, (.032, .075), (.022, .045)), (.30, (.018, .032), (.012, .022)), (.10, (.010, .016), (.007, .012))]
    kinds = (('rect', .3), ('chamfer', .3), ('trap', .15), ('slant', .15), ('L', .1))
    for p, n, rad in singles(H, rng, int(380 * amount), open_ok, lambda g: g.uniform(.016, .038), k=.8):
        u = r.random(); acc = 0
        for wgt, wr, hr in sizes:
            acc += wgt
            if u <= acc: break
        w, h = min(r.uniform(*wr), rad * 2.3), min(r.uniform(*hr), rad * 1.7)
        kw = r.random(); acc = 0
        for kind, kp in kinds:
            acc += kp
            if kw <= acc: break
        pts = detail_lib.outline(kind, w, h, r); th = .0019 * r.uniform(.8, 1.4); col = mul(pick(r, SALVAGE), r.uniform(.85, 1.15))
        t, b, n1 = frame_for(n); Rm = Matrix.Rotation(math.radians(r.uniform(-7, 7)), 3, n1); t, b = Rm @ t, Rm @ b
        if plate(H, S, f'cpl{n_pl}', p, n1, t, b, pts, th, -.0004, col, props, r.choice((1, 2, 3, 0)) if w > .02 else r.choice((0, 1, 2)), random.Random(r.random())): n_pl += 1
    # fittings: vents, junk boxes, hazard-striped plates, a few lights
    side = lambda i: abs(H.sn[i][1]) > .6; top = lambda i: H.sn[i][2] > .7; below = lambda i: H.sn[i][2] < -.7
    for p, n, rad in singles(H, rng, int(30 * amount), lambda i: (side(i) or top(i)) and open_ok(i), .010, k=1.1):
        t, b, n1 = frame_for(n); w, h = r.uniform(.010, .020), r.uniform(.007, .013)
        if H.flat(p, n1, t, b, w * 1.3, h * 1.3, cos=.6): vent(f'cvent{fit}', p, n1, t, b, w, h, mul(dark, 1.6), mul(dark, .5)); fit += 1
    for p, n, rad in singles(H, rng, int(24 * amount), lambda i: (top(i) or below(i)) and open_ok(i), .012, k=1.2):
        t, b, n1 = frame_for(n); w, h = r.uniform(.010, .022), r.uniform(.008, .016)
        if H.flat(p, n1, t, b, w * 1.2, h * 1.2, cos=.6): housing(f'cjunk{fit}', p, n1, t, b, w, h, pick(r, SALVAGE), props=props); fit += 1
    for p, n, rad in singles(H, rng, int(8 * amount), lambda i: side(i) and open_ok(i), .014, k=1.2):
        t, b, n1 = frame_for(n); w, h = r.uniform(.016, .026), r.uniform(.008, .012)
        if not H.flat(p, n1, t, b, w * 1.2, h * 1.2, cos=.6): continue
        for k in range(6):
            detail_lib.obox(f'chaz{fit}_{k}', p + n1 * .0012 + t * (k - 2.5) * w / 6, t, b, n1, (w / 6.5, h, .0012), bevel=0, rot=0)
            tag(((.40, .30, .02), (.02, .02, .02))[k % 2], rgh=.55, met=.2)
        fit += 1
    dress.lights(H, rng, P['lens'], mul(dark, 1.5), props, n_pairs=2)
    print(f'dress corsair: {n_tro} trophy plates, {n_pl} salvage plates, {fit} fittings, {nrun} pipe runs')


def build_array_spires(fingers, col, dark, props):
    """style 'array' (Oct 26, A4 review of H4: the 'mast' rebuild kept the AI's fat tubes, which read as funnels on a tower, a naval tell):
    each melted AI finger becomes a sensor array: a mount plate over the cut rim (as in dress.build_spires), a slim whip antenna (radius
    capped, so no fat pipes), a sensor pod a third of the way up, and on every other whip a small dish angled out to the side."""
    import bmesh, hs_lib
    n = 0; done = set()
    for f in fingers:
        x, y = float(f['c'][0]), float(f['c'][1]); z1, r = f['z1'], f['r']; lo, hi = f['rim_lo'], f['rim_hi']
        z0 = float(hi[2]); h = z1 - z0
        if h < .006: continue
        if f['group'] not in done:
            done.add(f['group']); x0, x1, y0, y1 = lo[0] - .0025, hi[0] + .0025, lo[1] - .0025, hi[1] + .0025
            if abs(y0 + y1) < .006: e = max(abs(y0), abs(y1)); y0, y1 = -e, e
            zt, zbm = float(hi[2]) + .0012, float(lo[2]) - .004
            hs_lib.box(f'spm{n}', ((x0 + x1) / 2, (y0 + y1) / 2, (zt + zbm) / 2), (max(x1 - x0, .006), max(y1 - y0, .006), zt - zbm), bevel=.0006); tag(mul(col, .8), **props)
        rw = min(r * .45, .0022); h = h * .85  # slim, and a little shorter than the melted tube it replaces
        hs_lib.cyl(f'spi{n}', (x, y, z0 + h * .5), rw, h, axis='Z', seg=8, r2=rw * .35, bevel=0); tag(mul(dark, 1.4), rgh=.4, met=.6)
        hs_lib.cyl(f'spp{n}', (x, y, z0 + h * .33), rw * 2.6, h * .09, axis='Z', seg=10, bevel=0); tag(mul(col, .95), **props)  # sensor pod
        if n % 2 == 0:  # dish: a shallow cone tipped out to the side it stands on
            side = 1 if y >= 0 else -1; R = Matrix.Rotation(side * math.radians(-62), 3, 'X')
            hs_lib.cyl(f'spd{n}', (x, y + side * rw * 3.5, z0 + h * .62), rw * 4.2, rw * 1.6, axis='Z', seg=14, r2=rw * .8, bevel=0, rot=R)
            tag(mul(col, 1.05), rgh=.35, met=.3)
        b = bmesh.new(); bmesh.ops.create_uvsphere(b, u_segments=8, v_segments=5, radius=max(.0010, rw * 1.1)); bmesh.ops.translate(b, verts=b.verts, vec=(x, y, z0 + h))
        hs_lib._obj(f'spf{n}', b, 0); tag(mul(col, .95), rgh=.3, met=.3)
        n += 1
    print(f'spires rebuilt as sensor arrays: {n}')
    return n


def _vane(name, x, y, z0, h, wb, wt, th, along_x):
    """a thin tapered radiator vane standing on (x, y, z0), height h, base width wb, top width wt, thickness th, in the x-z or y-z plane"""
    import bmesh, hs_lib
    bm = bmesh.new(); V = []
    for (w, z) in ((wb, z0), (wt, z0 + h)):
        for s in (-1, 1):
            for tt in (-1, 1):
                u, v = s * w / 2, tt * th / 2
                V.append(bm.verts.new((x + u, y + v, z) if along_x else (x + v, y + u, z)))
    # V: bottom (-,-) (-,+) (+,-) (+,+), top the same + 4
    for f in ((0, 2, 3, 1), (4, 5, 7, 6), (0, 1, 5, 4), (2, 6, 7, 3), (0, 4, 6, 2), (1, 3, 7, 5)): bm.faces.new([V[i] for i in f])
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    return hs_lib._obj(name, bm, 0)


def build_radiator_spires(fingers, col, dark, props, glow=(1.0, .42, .12)):
    """style 'radiator' (Oct 27 lore note: Voidsworn spires read as heat-radiator spires, not church spires): each melted AI finger becomes
    a heat-radiator spire at the same spot and height: a mount plate over the cut rim, a square core, a cross of thin flat radiator vanes
    with heat-pipe ribs running up them, ember-lit vent slits low on the vanes, and a flat emitter cap. No point, no finial, no gothic
    bands, no stepped collars (the first try with collars read as a pagoda)."""
    import hs_lib
    n = 0; done = set()
    for f in fingers:
        x, y = float(f['c'][0]), float(f['c'][1]); z1, r = f['z1'], f['r']; lo, hi = f['rim_lo'], f['rim_hi']
        z0 = float(hi[2]); h = z1 - z0
        if h < .006: continue
        if f['group'] not in done:
            done.add(f['group']); x0, x1, y0, y1 = lo[0] - .0025, hi[0] + .0025, lo[1] - .0025, hi[1] + .0025
            if abs(y0 + y1) < .006: e = max(abs(y0), abs(y1)); y0, y1 = -e, e
            zt, zbm = float(hi[2]) + .0012, float(lo[2]) - .004
            hs_lib.box(f'spm{n}', ((x0 + x1) / 2, (y0 + y1) / 2, (zt + zbm) / 2), (max(x1 - x0, .006), max(y1 - y0, .006), zt - zbm), bevel=.0006); tag(mul(col, .8), **props)
        # proportions of a radiator, not a needle: a wider core and vanes, height capped at about five vane widths (the V1b pass-3 sheet:
        # the tall thin ones still read as a steeple over the tower)
        r = max(r, .0035); zs = z0 - .0006; hh = min(h * .94, r * 2.6 * 5)
        hs_lib.cyl(f'spi{n}', (x, y, zs + hh * .5), r * .80, hh, axis='Z', seg=4, r2=r * .42, bevel=0); tag(mul(col, 1.05), **props)  # core
        th = max(.0007, r * .12)
        for k, ax in enumerate((True, False)):  # a cross of flat radiator vanes, nearly straight-sided (a steep taper or stepped collars read as a pagoda)
            _vane(f'spv{n}{k}', x, y, zs, hh * .90, r * 2.6, r * 1.7, th, ax)
        tag(mul(dark, 2.2), rgh=.4, met=.65)
        for k, ax in enumerate((True, False)):  # heat-pipe ribs running up each vane face (vertical, never stacked rings)
            for s_ in (-1, 1):
                for u_ in (-.85, -.45, .45, .85):
                    ox, oy = ((r * u_, s_ * th * .75) if ax else (s_ * th * .75, r * u_))
                    hs_lib.box(f'spr{n}{k}{s_}{u_}', (x + ox, y + oy, zs + hh * .44), ((r * .10, th * .6, hh * .80) if ax else (th * .6, r * .10, hh * .80)), bevel=0)
        tag(mul(dark, 1.6), rgh=.45, met=.6)
        for k, ax in enumerate((True, False)):  # ember vent slits low on each vane, both faces
            for s in (-1, 1):
                ox, oy = ((r * .95 * s, th * .6) if ax else (th * .6, r * .95 * s))
                hs_lib.box(f'spg{n}{k}{s}', (x + ox, y + oy, zs + hh * .34), ((r * .75, th * .5, hh * .48) if ax else (th * .5, r * .75, hh * .48)), bevel=0)
        tag(glow, emit=1.0, rgh=.3, met=0)  # Oct 27 (Opus: the Voidsworn line reads very dark): taller, wider vents at full glow
        hs_lib.cyl(f'spt{n}', (x, y, zs + hh + .0008), r * .55, .0018, axis='Z', seg=4, bevel=0); tag(mul(dark, 1.6), rgh=.45, met=.6)  # flat cap
        hs_lib.cyl(f'spl{n}', (x, y, zs + hh + .0019), r * .40, .0008, axis='Z', seg=8, bevel=0); tag(glow, emit=1.0, rgh=.2, met=0)   # emitter lens
        n += 1
    print(f'spires rebuilt as heat radiators: {n}')
    return n


def light_clusters(H, S, seed, P, count=8):
    """Hegemony (Oct 27): what the long row of lit windows along each flank becomes: recessed light clusters (an armoured frame round a
    dark recess with a small grid of lit ports) and, beside every other one, a sensor housing. Mirrored port and starboard pairs."""
    from dress import mirrored_frame, housing
    rng = np.random.default_rng(seed + 77); r = random.Random(seed + 77); made = 0
    base, dark, lens = P['base'], P['dark'], P['lens']; props = dict(rgh=.46, met=.16)
    side = lambda i: abs(Vector(H.sn[i].tolist()).dot(H.m)) > .7 and H.ao[i] > .5 and abs(H.cv[i]) < .10 and abs(H.sp[i][0]) < .40
    for p, n, mir, rad in H.pairs(rng, count, side, .016, k=1.2):
        t, b, n1 = frame_for(n); w, h = r.uniform(.016, .026), r.uniform(.007, .010)
        if not H.flat(p, n1, t, b, w * 1.3, h * 1.5): continue
        sides = [(p, n1, t, b)]
        if mir:
            t2, b2, n2 = mirrored_frame(H, mir[1], t)
            if not H.flat(mir[0], n2, t2, b2, w * 1.3, h * 1.5): continue
            sides.append((mir[0], n2, t2, b2))
        cols, rows = (4 if w > .02 else 3), 2
        for s_, (q, nn, tt, bb) in enumerate(sides):
            nm = f'hlc{made}{"ab"[s_]}'
            detail_lib.obox(nm + 'k', q + nn * .0004, tt, bb, nn, (w, h, .0010), bevel=0); tag(mul(dark, .45), rgh=.8, met=.2)  # dark recess
            for sx in (-1, 1):  # armoured frame round it
                detail_lib.obox(nm + f'fa{sx}', q + tt * sx * w * .53 + nn * .0012, tt, bb, nn, (w * .07, h * 1.2, .0026), bevel=.0002)
                detail_lib.obox(nm + f'fb{sx}', q + bb * sx * h * .56 + nn * .0012, tt, bb, nn, (w * 1.12, h * .12, .0026), bevel=.0002)
            tag(mul(base, .92), **props)
            for i in range(cols):
                for j in range(rows):
                    c = q + tt * (i - (cols - 1) / 2) * w * .22 + bb * (j - .5) * h * .42 + nn * .0010
                    detail_lib.obox(nm + f'l{i}{j}', c, tt, bb, nn, (w * .13, h * .26, .0008), bevel=0)
            tag(lens, emit=1.0, rgh=.2, met=0)
            if made % 2 == 0:  # a sensor housing beside it
                housing(nm + 's', q + tt * w * .85, nn, tt, bb, h * .9, h * .9, mul(base, .9), dome=True, props=props)
        made += 1
    print(f'dress hegemony: {made} light cluster pairs')
    return made
