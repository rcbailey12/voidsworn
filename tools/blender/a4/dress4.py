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


def dress_corsair(H, S, seed, P, amount=1.0):
    rng = np.random.default_rng(seed); r = random.Random(seed)
    dark = P['dark']; open_ok = lambda i: H.ao[i] > .42 and abs(H.cv[i]) < .14
    props = dict(rgh=.62, met=.32); n_pl = fit = nrun = 0
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
    print(f'dress corsair: {n_pl} salvage plates, {fit} fittings, {nrun} pipe runs')


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
