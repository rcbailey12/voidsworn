# Hullbreaker patchwork geometry, issue 875 (Ryan R289).
# A16/A17 establish the character: mixed sizes, real thickness and stacked laps.
# The issue 633 courses and the shallow craft slabs lost that character.
import math
from types import MethodType
from mathutils import Vector


def install(K, HP):
    """Select this plater on one sheet instance, without changing the shared kit."""
    K._plates = MethodType(lambda self, name, rings, spec: patchwork(self, HP, name, rings, spec), K)


def patchwork(K, HP, name, rings, spec):
    """Lay mixed-size, skewed, overlapping slabs across each face, with welded laps.

    Opted into by the four issue 875 sheets. The shared sheet kit, A16 and A17
    keep their existing builders. Material weights and paint settings stay put.
    """
    import random
    from mathutils import Vector
    rnd = random.Random(spec.get('seed', 1))
    lo, hi = spec['size']; tlo, thi = spec['thick']
    lo, hi = lo * 0.6, hi * 1.6
    g = min(spec.get('gap', lo * .03), lo * .035, tlo * .25)
    mats = spec['mats']; names = list(mats); wts = [mats[k] for k in names]
    n = len(rings[0]); R = [[Vector(v) for v in r] for r in rings]
    cen = [sum(r, Vector()) / n for r in R]
    buckets = {k: ([], []) for k in names}
    RV, RF = [], []
    kept = 0
    stats = dict(name=name, areas=[], angles=[], welded_edges=0, stacked=0, kept=0)
    for j in spec.get('faces', range(n)):
        A = [r[j] for r in R]; B = [r[(j + 1) % n] for r in R]
        mids = [(a + b) / 2 for a, b in zip(A, B)]
        S = [0.0]
        for p0, p1 in zip(mids, mids[1:]):
            S.append(S[-1] + (p1 - p0).length)
        L = S[-1]
        W = [(b - a).length for a, b in zip(A, B)]
        if L < lo * 0.5 or max(W) < lo * 0.45:
            continue

        def at(s):
            # the ring interval and fraction at arc length s
            s = max(0.0, min(L, s))
            for i in range(len(S) - 1):
                if s <= S[i + 1] or i == len(S) - 2:
                    f = (s - S[i]) / max(S[i + 1] - S[i], 1e-9)
                    return i, max(0.0, min(1.0, f))

        def P(s, v):
            i, f = at(s)
            return A[i].lerp(A[i + 1], f).lerp(B[i].lerp(B[i + 1], f), v)

        def width(s):
            i, f = at(s)
            return W[i] + (W[i + 1] - W[i]) * f

        def normal(s):
            i, f = at(s)
            nrm = (B[i] - A[i]).cross(A[i + 1] - A[i])
            if nrm.length < 1e-9:
                nrm = (B[i + 1] - A[i + 1]).cross(A[i + 1] - A[i])
            nrm.normalize()
            if nrm.dot((A[i] + B[i + 1]) / 2 - (cen[i] + cen[i + 1]) / 2) < 0:
                nrm = -nrm
            return nrm
        # the guillotine: split the longer side of a cell at a random point until it is under its own drawn size
        cells, todo = [], [(0.0, L, 0.0, 1.0)]
        while todo:
            s0, s1, v0, v1 = todo.pop()
            ds = s1 - s0; dw = (v1 - v0) * max(width((s0 + s1) / 2), 1e-6); m = rnd.uniform(lo, hi)
            if max(ds, dw) <= m:
                cells.append((s0, s1, v0, v1)); continue
            f = rnd.uniform(0.3, 0.7)
            if min(ds, dw) < lo * 0.5 and max(ds, dw) < hi * 1.4:
                cells.append((s0, s1, v0, v1)); continue   # no slivers: a narrow cell stays one long plate
            if ds * rnd.uniform(0.8, 1.25) >= dw:
                sm = s0 + ds * f; todo += [(s0, sm, v0, v1), (sm, s1, v0, v1)]
            else:
                vm = v0 + (v1 - v0) * f; todo += [(s0, s1, v0, vm), (s0, s1, vm, v1)]
        rank = list(range(len(cells))); rnd.shuffle(rank)
        # the colours by shuffled quota from the weights, so each face carries the sheet's mix and no seed runs dark
        tot = sum(wts); quota = []
        for k_, w_k in zip(names, wts):
            quota += [k_] * int(round(len(cells) * w_k / tot))
        while len(quota) < len(cells):
            quota.append(rnd.choices(names, wts)[0])
        rnd.shuffle(quota)
        tally = dict(cells=len(cells), kept=0, keepout=0, skip=0)
        dt = (thi - tlo) / max(1, len(cells))
        for c_i, (s0, s1, v0, v1) in enumerate(cells):
            r_skip, r_turn, r_hard, r_stack, r_riv = rnd.random(), rnd.uniform(-1, 1), rnd.random(), rnd.random(), rnd.random()
            k = quota[c_i]; grow = rnd.uniform(1.0, 1.14)
            jit = [(rnd.uniform(-1, 1), rnd.uniform(-1, 1)) for _ in range(4)]
            sc, vc = (s0 + s1) / 2, (v0 + v1) / 2
            w_ = width(sc)
            if r_skip < spec.get('skip', 0.08) or w_ < 1e-6:
                tally['skip'] += 1; continue
            hs = max(0.0, (s1 - s0) / 2 * grow - g); hw = max(0.0, (v1 - v0) * w_ / 2 * grow - g)
            if hs < g or hw < g:
                continue
            pc = P(sc, vc)
            # a plate near a mount shrinks off it before it is dropped (big plates would otherwise clear wide rings round every mount)
            for _ in range(3):
                # Bound the whole turned slab and its second layer. The old
                # craft plater tested only the short half-width, letting a long
                # corner reach under a locker or dish after rotation.
                reach = 1.25 * math.hypot(hs, hw) + 2 * thi
                if not any((pc - c).length < r + reach for c, r in K.keepouts):
                    break
                hs, hw = hs * 0.6, hw * 0.6
            else:
                tally['keepout'] += 1; continue
            if hs < g or hw < g or hs * hw < lo * lo * .15:
                tally['keepout'] += 1; continue
            ang = math.radians(spec.get('turn', 12) * r_turn * (2.6 if r_hard < spec.get('hard', 0.35) else 1.0))
            ca, sa = math.cos(ang), math.sin(ang)
            bot = []
            for (qs, qw), (js, jw) in zip(((-hs, -hw), (hs, -hw), (hs, hw), (-hs, hw)), jit):
                qs += js * hs * 0.18; qw += jw * hw * 0.18
                rs_, rw_ = qs * ca - qw * sa, qs * sa + qw * ca
                ss = min(L - g, max(g, sc + rs_)); vv = min(1.0 - g / w_, max(g / w_, vc + rw_ / w_))
                bot.append(P(ss, vv))
            nrm = normal(sc)
            t = tlo + rank[c_i] * dt
            riv = r_riv < spec.get('rivets_share', 0.15)
            rr = min(spec.get('rivet_r', .035), t * .3, min(hs, hw) * .1)
            (V, F), (rv, rf) = HP.plate_slab(bot, nrm, t, rivets=riv, rr=rr)
            bv, bf = buckets[k]; o = len(bv); bv.extend(V); bf.extend([tuple(x + o for x in f) for f in F])
            if riv:
                o = len(RV); RV.extend(rv); RF.extend([tuple(x + o for x in f) for f in rf])
            kept += 1; tally['kept'] += 1; tally[k] = tally.get(k, 0) + 1
            stats['areas'].append(.5 * ((bot[1] - bot[0]).cross(bot[2] - bot[0]).length
                                       + (bot[2] - bot[0]).cross(bot[3] - bot[0]).length))
            stats['angles'].append(math.degrees(ang))
            # Rippling metal along the lap joins the slab to the skin below.
            # These are geometry, so the normal/occlusion bake sees the weld.
            for edge in range(4):
                if rnd.random() > .55:
                    continue
                va, vb = bot[edge], bot[(edge + 1) % 4]
                edge_len = (vb - va).length
                rr = min(t * .17, edge_len * .035)
                if rr <= 0:
                    continue
                steps = max(3, min(12, int(edge_len / max(t * 2, 1e-6))))
                bead = [va.lerp(vb, .05 + .9 * j_ / steps)
                        + nrm * (t * .9 + rr * .35 * math.sin(j_ * 2.4)) for j_ in range(steps + 1)]
                for qa, qb in zip(bead, bead[1:]):
                    vv_, ff_ = HP.rod(qa, qb, rr, 5)
                    bv_, bf_ = buckets.get('iron', buckets[k]); off_ = len(bv_)
                    bv_.extend(vv_); bf_.extend(tuple(v + off_ for v in f) for f in ff_)
                stats['welded_edges'] += 1
            if r_stack < spec.get('stack', 0.45):
                stats['stacked'] += 1
                # a smaller patch bolted over part of this plate, a second thickness step
                fu, fv = rnd.uniform(0.3, 0.55), rnd.uniform(0.3, 0.6)
                cu, cv = rnd.uniform(-0.5 + fu / 2, 0.5 - fu / 2), rnd.uniform(-0.5 + fv / 2, 0.5 - fv / 2)
                q = [bot[0].lerp(bot[1], 0.5 + cu + du).lerp(bot[3].lerp(bot[2], 0.5 + cu + du), 0.5 + cv + dv) + nrm * t
                     for du, dv in ((-fu / 2, -fv / 2), (fu / 2, -fv / 2), (fu / 2, fv / 2), (-fu / 2, fv / 2))]
                (V, F), _ = HP.plate_slab(q, nrm, tlo * 0.8, rivets=False)
                k2 = quota[(c_i + 7) % len(quota)]; bv, bf = buckets[k2]; o = len(bv); bv.extend(V); bf.extend([tuple(x + o for x in f) for f in F])
    for k, (V, Fc) in buckets.items():
        if V:
            K._obj('%s_plates_%s' % (name, k), V, Fc, k, grp='hull')
    if RV:
        K._obj('%s_rivets' % name, RV, RF, 'iron', grp='hull')
    for iid in ([spec['inv']] if isinstance(spec.get('inv'), str) else spec.get('inv', [])):
        K.built.append(dict(id=name + '_plates', kind='plate', inv=[iid], shaped=True, detailed=kept > 0, subs=['slab', 'step', 'bevel', 'rivet']))
    stats['kept'] = kept
    K.patchwork_report = getattr(K, 'patchwork_report', []) + [stats]
    return kept

