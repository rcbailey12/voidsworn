# Build sheet blockout kit (issue 532). Runs inside Blender (4.5 on Ryan's PC, or the bpy module).
# One design per ship: the ship file (ships/<code>.py) calls these helpers for every mass and fitting and records every
# fitting in the feature table. The renders, the feature table, the INSIDE section, the fit check and the inventory ticks
# all come from this one model, so they agree by construction.
# Round 3 (R217, R218): every fitting is a real part shape from the Hullbreakers kit (tools/blender/kits/hullbreakers/
# parts.py), the same builders the real build uses; every object carries its part id (grp) and role ('mount' may sit into
# the hull, everything else must stay clear) for the fit check (clash.py); every part carries the inventory ids it fills.
# Hull plates carry thickness steps, bevels and rivets, and are cleared under every mount so parts sit on bare deck.
# Frame: +X bow, +Y port, +Z up (Blender). Station 0 percent is the prow tip (the most forward point of the model).
import math, os, sys
import bpy
import bmesh
from mathutils import Vector, Matrix

sys.path.insert(0, os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'kits', 'hullbreakers')))
import parts as HP  # noqa: E402

MATS = {
    # name: (rgb, emission strength). Colour zones are schematic: the beauty picture gives the finish.
    'soot': ((0.055, 0.050, 0.048), 0),      # soot black hull plate
    'rust': ((0.22, 0.09, 0.055), 0),        # rust plate
    'soot2': ((0.032, 0.030, 0.029), 0),     # darker soot plate
    'iron': ((0.10, 0.10, 0.105), 0),        # bare iron plate
    'blood': ((0.33, 0.05, 0.05), 0),        # dried-blood red band
    'violet': ((0.28, 0.12, 0.45), 0),       # violet Eclipse trophy plate
    'pale': ((0.36, 0.37, 0.38), 0),         # pale Hegemony grey trophy plate
    'steel': ((0.20, 0.20, 0.21), 0),        # gun metal and machinery
    'dark': ((0.012, 0.011, 0.011), 0),      # bores, throats, apertures, recesses
    'dish': ((0.62, 0.60, 0.56), 0),         # dish faces
    'glow': ((1.0, 0.25, 0.08), 8),          # engine throat glow
    'ember': ((0.9, 0.22, 0.06), 1.6),       # engine bell lining
    'light': ((1.0, 0.1, 0.05), 3),          # running lights
    'warhead': ((0.42, 0.12, 0.06), 0),      # rocket noses
    'brass': ((0.42, 0.30, 0.12), 0),        # salvaged rocket noses
    # inside (cutaway only)
    'deck': ((0.42, 0.40, 0.36), 0),
    'frame': ((0.30, 0.29, 0.27), 0),
    'core': ((1.0, 0.75, 0.2), 4),
    'engroom': ((0.85, 0.42, 0.12), 0),
    'magazine': ((0.75, 0.10, 0.08), 0),
    'machinery': ((0.35, 0.42, 0.45), 0),
    'hangar': ((0.25, 0.35, 0.55), 0),
    'crew': ((0.40, 0.45, 0.30), 0),
    'hold': ((0.45, 0.32, 0.18), 0),
    'bridge': ((0.60, 0.55, 0.25), 0),
    'armour': ((0.16, 0.15, 0.14), 0),
}
ARCS = {'F': (-60.0, 60.0), 'P': (30.0, 150.0), 'S': (-150.0, -30.0), 'T': (-180.0, 180.0), 'R': (120.0, 240.0)}  # core.js inArc


def mat(name):
    m = bpy.data.materials.get(name)
    if m:
        return m
    rgb, em = MATS[name]
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    b = m.node_tree.nodes.get('Principled BSDF')
    b.inputs['Base Color'].default_value = (*rgb, 1)
    b.inputs['Roughness'].default_value = 0.7
    b.inputs['Metallic'].default_value = 0.3 if name in ('steel', 'pale', 'dish', 'iron', 'brass') else 0.1
    if em:
        b.inputs['Emission Color'].default_value = (*rgb, 1)
        b.inputs['Emission Strength'].default_value = em
    m.diffuse_color = (*rgb, 1)
    return m


def _octa(hwp, hws, zb, zt, ct, cb, yo=0.0):
    w = (hwp + hws) * 0.49
    ct = max(0.0, min(ct, (zt - zb) * 0.49, w))
    cb = max(0.0, min(cb, (zt - zb) * 0.49, w))
    return [(yo + hwp, zt - ct), (yo + hwp - ct, zt), (yo - hws + ct, zt), (yo - hws, zt - ct),
            (yo - hws, zb + cb), (yo - hws + cb, zb), (yo + hwp - cb, zb), (yo + hwp, zb + cb)]


def _round_sec(hwp, hws, zb, zt, yo=0.0, n=20, p_top=6.0, p_bot=2.3):
    """a rounded wedge section (round 3c): a superellipse, flatter on top (p_top) and round in the flanks and belly (p_bot)"""
    zc = (zb + zt) / 2; hz = (zt - zb) / 2
    pts = []
    for i in range(n):
        t = 2 * math.pi * i / n
        c, s_ = math.cos(t), math.sin(t)
        p = p_top if s_ >= 0 else p_bot
        y = (hwp if c >= 0 else hws) * math.copysign(abs(c) ** (2.0 / p), c)
        z = zc + hz * math.copysign(abs(s_) ** (2.0 / p), s_)
        pts.append((yo + y, z))
    return pts


def sec_at(sections, x):
    """interpolate a loft section list at station x (sections sorted bow first, x descending)"""
    s = sorted(sections, key=lambda r: -r[0])
    if x >= s[0][0]:
        return list(s[0])
    if x <= s[-1][0]:
        return list(s[-1])
    for a, b in zip(s, s[1:]):
        if a[0] >= x >= b[0]:
            t = (a[0] - x) / (a[0] - b[0])
            return [a[i] + (b[i] - a[i]) * t for i in range(len(a))]


class Kit:
    def __init__(self, code, length):
        self.code = code
        self.length = length
        self.features = []      # feature table rows
        self.masses = []        # major masses
        self.inside = []        # inside rows (decks, bulkheads, spaces, armour, breaks)
        self.points = []        # hard points (core, breach, rcs, board, bay)
        self.changes = []       # changed from the picture
        self.tbd = []           # still open
        self.built = []         # every part built: id, kind, inv ids, shaped, detailed (the inventory ticks)
        self.fitdata = []       # arcs, exhaust cones and apertures for the fit check
        self.keepouts = []      # (centre, radius): no hull plate under a mount
        self.allow = []         # (grp a, grp b, why): touching on purpose (a part mounted on another part)
        self.fixes = []         # (clash, how it was fixed): the fit report's second column
        self._pending = []
        self.hull_sections = None
        self.grp = 'hull'
        self.coll = bpy.data.collections.new(code)
        bpy.context.scene.collection.children.link(self.coll)
        self.cin = bpy.data.collections.new(code + '_inside')
        bpy.context.scene.collection.children.link(self.cin)

    # ---------- raw mesh ----------
    def _obj(self, name, verts, faces, m, inside=False, smooth=False, grp=None, role=None):
        me = bpy.data.meshes.new(name)
        me.from_pydata([tuple(v) for v in verts], [], faces)
        me.validate()
        me.update()
        ob = bpy.data.objects.new(name, me)
        (self.cin if inside else self.coll).objects.link(ob)
        ob.data.materials.append(mat(m))
        if smooth:
            for p in me.polygons:
                p.use_smooth = True
        ob['inside'] = inside
        ob['grp'] = grp or self.grp
        ob['role'] = role or ('hull' if (grp or self.grp) == 'hull' else 'mount')
        bm = bmesh.new(); bm.from_mesh(ob.data); bmesh.ops.recalc_face_normals(bm, faces=bm.faces); bm.to_mesh(ob.data); bm.free()
        return ob

    def loft(self, name, sections, m, inside=False, shell=0.0, ytilt=None, plates=None, grp=None, rounded=False):
        """sections: (x, hw_port, hw_stbd, z_bottom, z_top, chamfer_top, chamfer_bottom[, y_offset]) bow first.
        rounded: a rounded wedge section instead of the octagon (round 3c), the chamfers ignored"""
        rings = []
        for s in sections:
            x, hwp, hws, zb, zt, ct, cb = s[:7]
            yo = s[7] if len(s) > 7 else 0.0
            ring = _round_sec(hwp, hws, zb, zt, yo) if rounded else _octa(hwp, hws, zb, zt, ct, cb, yo)
            rings.append([(x, y, z) for (y, z) in ring])
        verts = [v for r in rings for v in r]
        n = len(rings[0])
        faces = []
        for i in range(len(rings) - 1):
            for j in range(n):
                a, b = i * n + j, i * n + (j + 1) % n
                faces.append((a, b, b + n, a + n))
        faces.append(tuple(range(n))[::-1])
        faces.append(tuple(range((len(rings) - 1) * n, len(rings) * n)))
        ob = self._obj(name, verts, faces, m, inside, grp=grp)
        if plates:
            self._pending.append((name, rings, plates))
        if shell:
            mod = ob.modifiers.new('shell', 'SOLIDIFY'); mod.thickness = shell; mod.offset = -1; mod.use_rim = True
        return ob

    def _plates(self, name, rings, spec):
        """armour slabs over the loft faces: plates of mixed size and thickness with bevelled edges and corner rivets, a
        second smaller slab stacked on some (a thickness step), a few in trophy colours; none under a mount (keep-outs).
        spec: dict(seed, size=(lo, hi), thick=(lo, hi), skip, stack, mats={mat: weight}, faces=[0..7], inv='inventory id')"""
        import random
        rnd = random.Random(spec.get('seed', 1))
        lo, hi = spec.get('size', (0.9, 2.2)); tlo, thi = spec.get('thick', (0.05, 0.2))
        mats = spec.get('mats', {'soot': 6, 'rust': 2, 'steel': 1})
        names = list(mats); wts = [mats[k] for k in names]
        n = len(rings[0])
        faces_ok = spec.get('faces', list(range(n)))
        buckets = {k: ([], []) for k in names}
        RV, RF = [], []
        cen = [Vector(map(lambda *c: sum(c) / n, *r)) for r in rings]
        kept = 0
        for i in range(len(rings) - 1):
            for j in faces_ok:
                A, B = Vector(rings[i][j]), Vector(rings[i][(j + 1) % n])
                D_, C = Vector(rings[i + 1][j]), Vector(rings[i + 1][(j + 1) % n])
                flen = (D_ - A).length; fw = (B - A).length
                if flen < 0.3 or fw < 0.2:
                    continue
                nrm = (B - A).cross(D_ - A)
                if nrm.length < 1e-6:
                    continue
                nrm.normalize()
                if nrm.dot((A + C) / 2 - (cen[i] + cen[i + 1]) / 2) < 0:
                    nrm = -nrm
                us = [0.0]
                while us[-1] < 1.0:
                    us.append(min(1.0, us[-1] + rnd.uniform(lo, hi) / flen))
                ncross = max(1, min(3, int(fw / 1.4 + rnd.random())))
                for a0, a1 in zip(us, us[1:]):
                    vs = sorted([0.0, 1.0] + [rnd.uniform(0.25, 0.75) for _ in range(ncross - 1)])
                    for b0, b1 in zip(vs, vs[1:]):
                        r_skip = rnd.random(); t = rnd.uniform(tlo, thi); k = rnd.choices(names, wts)[0]
                        r_stack = rnd.random(); fu = rnd.uniform(0.15, 0.5); fv = rnd.uniform(0.15, 0.5); t2 = rnd.uniform(tlo, thi)
                        if r_skip < spec.get('skip', 0.2):
                            continue
                        g = 0.04

                        def Pq(u, v):
                            return A.lerp(D_, u).lerp(B.lerp(C, u), v)
                        u0, u1 = a0 + g / flen, a1 - g / flen; v0, v1 = b0 + g / fw, b1 - g / fw
                        if u1 <= u0 or v1 <= v0:
                            continue
                        if self._kept_out(A, D_ - A, B - A, nrm, u0, u1, v0, v1, flen, fw):
                            continue
                        bot = [Pq(u0, v0), Pq(u1, v0), Pq(u1, v1), Pq(u0, v1)]
                        (V, F), (rv, rf) = HP.plate_slab(bot, nrm, t, rivets=spec.get('rivets', True))
                        bv, bf = buckets[k]; o = len(bv); bv.extend(V); bf.extend([tuple(x + o for x in f) for f in F])
                        o = len(RV); RV.extend(rv); RF.extend([tuple(x + o for x in f) for f in rf])
                        kept += 1
                        if r_stack < spec.get('stack', 0.3):
                            cu, cv = (u0 + u1) / 2, (v0 + v1) / 2
                            hu, hv = fu * (u1 - u0) / 2, fv * (v1 - v0) / 2 + 0.1 * (v1 - v0)
                            b2 = [Pq(cu - hu, cv - hv) + nrm * t, Pq(cu + hu, cv - hv) + nrm * t, Pq(cu + hu, cv + hv) + nrm * t, Pq(cu - hu, cv + hv) + nrm * t]
                            (V, F), (rv, rf) = HP.plate_slab(b2, nrm, t2, rivets=False)
                            o = len(bv); bv.extend(V); bf.extend([tuple(x + o for x in f) for f in F])
        for k, (V, Fc) in buckets.items():
            if V:
                self._obj('%s_plates_%s' % (name, k), V, Fc, k, grp='hull')
        if RV:
            self._obj('%s_rivets' % name, RV, RF, 'iron', grp='hull')
        if spec.get('inv'):
            for iid in ([spec['inv']] if isinstance(spec['inv'], str) else spec['inv']):
                self.built.append(dict(id=name + '_plates', kind='plate', inv=[iid], shaped=True, detailed=kept > 0 and spec.get('rivets', True),
                                       subs=['slab', 'step', 'bevel', 'rivet']))

    def _kept_out(self, A, du, dv, nrm, u0, u1, v0, v1, flen, fw):
        """True when a plate (the face patch u0..u1, v0..v1) comes within a keep-out's radius of its centre"""
        for c, r in self.keepouts:
            d = c - A
            if abs(d.dot(nrm)) > r + 0.6:
                continue
            # parametric position of the keep-out centre on the face (du, dv are not quite orthogonal: solve the 2 x 2)
            a11, a12, a22 = du.dot(du), du.dot(dv), dv.dot(dv)
            b1, b2 = d.dot(du), d.dot(dv)
            det = a11 * a22 - a12 * a12
            if abs(det) < 1e-9:
                continue
            u = (b1 * a22 - b2 * a12) / det; v = (a11 * b2 - a12 * b1) / det
            if u0 - r / flen <= u <= u1 + r / flen and v0 - r / fw <= v <= v1 + r / fw:
                return True
        return False

    def finish(self):
        """build the deferred hull plates, now that every mount has claimed its keep-out"""
        for name, rings, spec in self._pending:
            self._plates(name, rings, spec)
        self._pending = []

    def box(self, name, x0, x1, y0, y1, z0, z1, m, ch=0.0, inside=False, taper=0.0, plates=None, grp=None):
        """axis box from x0 (aft) to x1 (fore), y0 (stbd) to y1 (port); taper shrinks the fore end"""
        hw = (y1 - y0) / 2; yo = (y1 + y0) / 2
        secs = [(x1, hw - taper, hw - taper, z0, z1 - taper * 0.5, ch, ch * 0.5, yo), (x0, hw, hw, z0, z1, ch, ch * 0.5, yo)]
        return self.loft(name, secs, m, inside, plates=plates, grp=grp)

    def cyl(self, name, p0, p1, r0, m, r1=None, n=16, inside=False, cap=True, grp=None):
        p0, p1 = Vector(p0), Vector(p1)
        r1 = r0 if r1 is None else r1
        ax = (p1 - p0).normalized()
        u = ax.orthogonal().normalized(); w = ax.cross(u)
        verts = []
        for (p, r) in ((p0, r0), (p1, r1)):
            for i in range(n):
                a = 2 * math.pi * i / n
                verts.append(p + (u * math.cos(a) + w * math.sin(a)) * r)
        faces = [(i, (i + 1) % n, n + (i + 1) % n, n + i) for i in range(n)]
        if cap:
            faces.append(tuple(range(n))[::-1]); faces.append(tuple(range(n, 2 * n)))
        return self._obj(name, verts, faces, m, inside, smooth=True, grp=grp)

    # ---------- surface helpers ----------
    def hull(self, sections, m='soot', shell=0.25, plates=None, rounded=False):
        self.hull_sections = sections
        self.hull_rounded = rounded
        return self.loft(self.code + '_hull', sections, m, shell=shell, plates=plates, rounded=rounded)

    def surf(self, x, side, z):
        """the hull's flank surface y at station x and height z (rounded or octagonal section), signed by side"""
        s = sec_at(self.hull_sections, x)
        hw = s[1] if side > 0 else s[2]
        zb, zt = s[3], s[4]
        if getattr(self, 'hull_rounded', False):
            zc = (zb + zt) / 2; hz = (zt - zb) / 2
            u = max(-1.0, min(1.0, (z - zc) / hz)); p = 6.0 if u >= 0 else 2.3
            sn = abs(u) ** (p / 2.0); cs = max(0.0, 1 - sn * sn) ** 0.5
            return side * hw * cs ** (2.0 / p)
        return side * hw

    def surf_n(self, x, side, z):
        """outward normal of the hull flank at (x, z) on one side (from the section's curve)"""
        y1, y2 = self.surf(x, side, z - 0.05), self.surf(x, side, z + 0.05)
        n = Vector((0, side * 0.1, -side * (y2 - y1)))
        return tuple(n.normalized())

    def deck_z(self, x, y):
        """the hull's top at station x and offset y (the rounded section's deck curve)"""
        s = sec_at(self.hull_sections, x)
        hw = s[1] if y >= 0 else s[2]; zb, zt = s[3], s[4]
        if not getattr(self, 'hull_rounded', False):
            return zt
        zc = (zb + zt) / 2; hz = (zt - zb) / 2
        f = min(1.0, abs(y) / hw)
        return zc + hz * max(0.0, 1 - f ** 6.0) ** (1 / 6.0)

    def top_z(self, x, sections=None):
        s = sec_at(sections or self.hull_sections, x)
        return s[4]

    def side_y(self, x, side, z=None, sections=None):
        s = sec_at(sections or self.hull_sections, x)
        hw = s[1] if side > 0 else s[2]
        yo = s[7] if len(s) > 7 else 0.0
        return yo + side * hw

    # ---------- parts from the faction kit ----------
    def emit(self, fid, part, M, inv=(), keep=True, keep_r=None, pivot=None):
        """place a kit part: transform it, write one object per (role, material), register it for the inventory ticks
        and its mount footprint as a plate keep-out"""
        part.transform(M)
        groups = {}
        names = []
        for c in part.comps:
            key = (c['role'], c['mat'])
            V, F = groups.setdefault(key, ([], []))
            o = len(V); V.extend(c['verts']); F.extend([tuple(x + o for x in f) for f in c['faces']])
            names.append(c['name'])
        piv = None
        if pivot is not None:
            # R219: a turret's turning pieces hang from a pivot empty at the ring centre (local +Z = the mount normal),
            # their mesh in the pivot's own frame, so the game can turn the pivot about its up axis
            piv = bpy.data.objects.new(fid + '_turret', None)
            self.coll.objects.link(piv)
            piv.empty_display_type = 'ARROWS'; piv.empty_display_size = 0.6
            piv.matrix_world = M
            for k_, v_ in pivot.items():
                piv[k_] = v_
            Minv = M.inverted()
        for (role, m), (V, F) in groups.items():
            if role == 'turn' and piv is not None:
                ob = self._obj('%s_%s_%s' % (fid, role, m), [Minv @ v for v in V], F, m, grp=fid, role=role, smooth=False)
                ob.parent = piv
                ob['turret'] = 1
            else:
                ob = self._obj('%s_%s_%s' % (fid, role, m), V, F, m, grp=fid, role=role, smooth=False)
                if part.kind == 'gun':
                    ob['turret'] = 1 if pivot is not None else 0
                    if pivot is None:
                        ob['gun_fixed'] = 1
        if keep:
            mv = [v for c in part.comps if c['role'] == 'mount' for v in c['verts']]
            if mv:
                o = M.translation
                r = keep_r or min(2.5, max((v - o).length for v in mv) * 1.05)
                self.keepouts.append((Vector(o), r))
        inv = [inv] if isinstance(inv, str) else list(inv)
        self.built.append(dict(id=fid, kind=part.kind, inv=inv, shaped=True, detailed=HP.detail_ok(part.kind, names),
                               subs=sorted({n.rstrip('0123456789').split('_')[-1] for n in names})))
        return part

    def mark(self, iid, kind, subs, fid=None):
        """register hull shaping (type hull, tier, rib, pylon) for the inventory: subs are the sub-parts actually built"""
        need = HP.SUBPARTS.get(kind, [])
        self.built.append(dict(id=fid or iid, kind=kind, inv=[iid], shaped=True, detailed=all(s in subs for s in need), subs=list(subs)))

    @staticmethod
    def aim_vec(yaw, pitch):
        y, p = math.radians(yaw), math.radians(pitch)
        return Vector((math.cos(y) * math.cos(p), math.sin(y) * math.cos(p), math.sin(p)))

    def gun(self, fid, pos, yaw, pitch=0.0, barrels=1, cal=0.12, blen=2.0, mount='turret', normal=(0, 0, 1),
            slot='', weapon='', src='picture', note='', size=1.0, inv=(), variant=0, band=None):
        """a gun from the kit. turret: on a deck (normal +Z) or the belly (-Z), rest aim yaw, barrels elevated pitch.
        casemate: on a flank (normal +-Y), the ball in the sponson's outer face, barrels trained yaw (from the bow)."""
        assert -100 < yaw < 100, fid + ' would aim aft'
        p = Vector(pos); nrm = Vector(normal).normalized()
        if abs(nrm.z) > 0.5:
            fwd = Vector((math.cos(math.radians(yaw)), math.sin(math.radians(yaw)), 0))
            part = HP.gun(barrels, cal, blen, size, 'turret', pitch=pitch, variant=variant)
            M = HP.frame(p, fwd, nrm)
            kind = 'belly turret' if nrm.z < 0 else 'turret'
        else:
            # train: the angle from the flank normal toward the bow
            aim = self.aim_vec(yaw, pitch)
            train = math.degrees(math.acos(max(-1, min(1, aim.dot(nrm)))))
            part = HP.gun(barrels, cal, blen, size, 'casemate', pitch=90 - train, variant=variant)
            M = HP.frame(p, Vector((1, 0, 0)), nrm)
            kind = 'casemate'
        lo_, hi_ = ARCS.get(slot or 'T', (-180.0, 180.0))
        pv = None
        if kind != 'casemate':
            pv = dict(turret=1, slot=slot or 'T', weapon=weapon, arc_lo=lo_, arc_hi=hi_, arc_deg=hi_ - lo_, rest_yaw=float(yaw),
                      rest_pitch=float(pitch), turns_about='local +Z (the mount normal)', arc_frame='bearing from the bow, + to port (core.js inArc)')
        part = self.emit(fid, part, M, inv, pivot=pv)
        fd = part.fit
        piv = fd['pivot'][1] if kind != 'casemate' else fd['trunnion'][1]
        self.fitdata.append(dict(id=fid, kind='gun', slot=slot, pivot=tuple(piv), up=tuple(nrm), mount=kind, ring=tuple(p), rest_yaw=yaw,
                                 reach=fd['reach'], band=band or ((0, 10, 20, 30, 45, 60) if weapon == 'flak' else (0, 10, 20, 30) if kind != 'casemate' else (-10, 0, 10, 20)),
                                 muzzles=[tuple(m[1]) for m in fd['muzzles']], cal=cal * 1.55, hous_r=fd['radius'], rest_pitch=pitch))
        self.features.append(dict(id=fid, kind='gun', what='%s %s' % ({1: 'single', 2: 'twin', 3: 'triple'}.get(barrels, str(barrels)), kind),
                                  count=barrels, pos=tuple(p), aim=(yaw, pitch), slot=slot, weapon=weapon, src=src, note=note,
                                  muzzle=[tuple(m[1]) for m in fd['muzzles']], normal=tuple(nrm), inv=list(inv) if not isinstance(inv, str) else [inv]))

    def launcher(self, fid, pos, rows, cols, cell=0.44, depth=2.0, yaw=0.0, pitch=8.0, slot='', weapon='', src='picture', note='',
                 inv=(), variant=0):
        """a rocket rack from the kit on its ring at pos (deck), cells facing yaw, raised pitch"""
        p = Vector(pos)
        part = HP.rocket_rack(rows, cols, cell, depth, variant=variant)
        # the box pitches up about the yoke: rotate the non-mount comps about the trunnion line
        piv = Vector((-depth * 0.48, 0, 0.35 * cell + 0.25 * cell))
        R = Matrix.Translation(piv) @ Matrix.Rotation(-math.radians(pitch), 4, 'Y') @ Matrix.Translation(-piv)
        for c in part.comps:
            if c['role'] != 'mount':
                c['verts'] = [R @ v for v in c['verts']]
        for e in part.fit['exits']:
            e['pos'] = ('p', R @ e['pos'][1]); e['axis'] = ('d', (R.to_3x3() @ e['axis'][1]).normalized())
        M = HP.frame(p, Vector((math.cos(math.radians(yaw)), math.sin(math.radians(yaw)), 0)), (0, 0, 1))
        part = self.emit(fid, part, M, inv)
        ex = [dict(pos=tuple(e['pos'][1]), axis=tuple(e['axis'][1]), r=e['radius']) for e in part.fit['exits']]
        self.fitdata.append(dict(id=fid, kind='launcher', slot=slot, apertures=[dict(pos=e['pos'], dir=e['axis'], length=self.length * 0.8,
                                                                                     cone=4.0, what='launch cell') for e in ex]))
        self.features.append(dict(id=fid, kind='launcher', what='rocket rack, %d by %d cells' % (rows, cols), count=rows * cols,
                                  pos=tuple(p), aim=(yaw, pitch), slot=slot, weapon=weapon, src=src, note=note, inv=[inv] if isinstance(inv, str) else list(inv)))

    def engine(self, fid, pos, r, length, bell=1.25, src='picture', note='', inv=(), nose='dome', body_r=None, rings=3):
        """an engine from the kit: pos is the centre of the bell exit; the housing runs forward `length`; exhaust aft"""
        p = Vector(pos)
        rex = r * bell
        part = HP.engine_bell(rex, length, bell_len=rex * 1.1, body_r=body_r or r, rings=rings, nose=nose)
        part = self.emit(fid, part, HP.frame(p, (1, 0, 0), (0, 0, 1)), inv)
        rad = part.fit['radius']
        self.fitdata.append(dict(id=fid, kind='engine', cones=[dict(apex=tuple(p), dir=(-1, 0, 0), r0=rad, half=12.0,
                                                                    length=max(2.5 * 2 * rad, 0.22 * self.length))]))
        self.features.append(dict(id=fid, kind='engine', what='engine, bell %.1f across' % (2 * rad), count=1,
                                  pos=tuple(p), aim=(180.0, 0.0), src=src, note=note, exit=tuple(p), radius=rad, inv=[inv] if isinstance(inv, str) else list(inv)))

    def tube(self, fid, pos, r, depth, hood=0.0, grille=False, src='picture', note='', inv=(), what='front tube', bands=2, yaw=0.0, pitch=0.0):
        """a launch tube or scoop from the kit, mouth at pos, facing yaw/pitch"""
        p = Vector(pos)
        part = HP.launch_tube(r, depth, hood=hood, grille=grille, bands=bands)
        part = self.emit(fid, part, HP.frame(p, self.aim_vec(yaw, pitch), (0, 0, 1)), inv, keep_r=r * 1.4)
        self.fitdata.append(dict(id=fid, kind='tube', apertures=[dict(pos=tuple(p + self.aim_vec(yaw, pitch) * r * 0.1), dir=tuple(self.aim_vec(yaw, pitch)),
                                                                      length=self.length * 0.5, cone=6.0, what='mouth', r=r * 0.8)]))
        self.features.append(dict(id=fid, kind='intake', what='%s, %.1f across, %.1f deep' % (what, 2 * r, depth), count=1,
                                  pos=tuple(p), aim=(yaw, pitch), src=src, note=note, inv=[inv] if isinstance(inv, str) else list(inv)))

    def dish(self, fid, pos, r, yaw=0.0, pitch=15.0, src='picture', note='', inv=(), post=0.9):
        p = Vector(pos)
        part = HP.dish(r, post=post)
        # tilt the bowl (everything above the base) by pitch about the yoke
        h = r * post
        R = Matrix.Translation((0, 0, h)) @ Matrix.Rotation(-math.radians(pitch), 4, 'Y') @ Matrix.Translation((0, 0, -h))
        for c in part.comps:
            if c['name'] not in ('base', 'post'):
                c['verts'] = [R @ v for v in c['verts']]
        part = self.emit(fid, part, HP.frame(p, (math.cos(math.radians(yaw)), math.sin(math.radians(yaw)), 0), (0, 0, 1)), inv)
        d = self.aim_vec(yaw, pitch)
        self.fitdata.append(dict(id=fid, kind='dish', apertures=[dict(pos=tuple(p + Vector((0, 0, h)) + d * r * 0.9), dir=tuple(d), length=3.0,
                                                                      cone=8.0, what='dish beam', r=r * 0.5)]))
        self.features.append(dict(id=fid, kind='dish', what='listening dish, %.1f across' % (2 * r), count=1,
                                  pos=tuple(p), aim=(yaw, pitch), src=src, note=note, inv=[inv] if isinstance(inv, str) else list(inv)))

    def claw(self, fid, hinge, pts, w=0.45, src='picture', note='', name='boarding claw', inv=(), fingers=3, housing=None):
        """a claw or grapple from the kit: hinge drum at `hinge` (axis across the ship), segments through pts (world);
        housing (x0, x1, y0, y1, z0, z1): the armoured box the hinge sits in, part of the claw's mount"""
        h = Vector(hinge)
        if housing:
            self.box(fid + '_housing', *housing, 'steel', ch=0.12, grp=fid).__setitem__('role', 'mount')
        part = HP.claw(w * 0.5, [Vector(q) - h for q in pts], w=w, fingers=fingers)
        part = self.emit(fid, part, Matrix.Translation(h), inv, keep_r=w)
        self.features.append(dict(id=fid, kind='claw', what='%s, %d segments, %d fingers' % (name, len(pts), fingers), count=1,
                                  pos=tuple(h), aim=(0.0, -60.0), src=src, note=note, tip=tuple(part.fit['tip'][1]), inv=[inv] if isinstance(inv, str) else list(inv)))

    def prong(self, fid, root, length, width=0.4, thick=0.12, hook=0.35, yaw=0.0, droop=0.0, joints=2, src='picture', note='', inv=(),
              housing=None):
        """a long flat jaw prong from the kit, hinged at root, reaching forward (yaw toward port +)"""
        h = Vector(root)
        if housing:
            self.box(fid + '_housing', *housing, 'steel', ch=0.08, grp=fid)
        part = HP.prong(length, width, thick, hook=hook, joints=joints, droop=droop)
        part = self.emit(fid, part, HP.frame(h, self.aim_vec(yaw, 0), (0, 0, 1)), inv, keep_r=width)
        self.features.append(dict(id=fid, kind='claw', what='jaw prong, %.1f long, hooked tip' % length, count=1, pos=tuple(h), aim=(yaw, 0.0),
                                  src=src, note=note, tip=tuple(part.fit['tip'][1]), inv=[inv] if isinstance(inv, str) else list(inv)))

    def chain(self, fid, pts, r=0.045, src='picture', note='', inv=(), link=0.3):
        part = HP.chain(pts, link=link, r=r)
        self.emit(fid, part, Matrix.Identity(4), inv, keep=False)
        self.features.append(dict(id=fid, kind='chain', what='lashing chain, taut between lugs', count=1,
                                  pos=tuple(Vector(pts[0])), end=tuple(Vector(pts[-1])), aim=None, src=src, note=note, inv=[inv] if isinstance(inv, str) else list(inv)))

    def thruster(self, fid, pos, normal, src='designed', note='', inv=()):
        p = Vector(pos); n = Vector(normal).normalized()
        part = self.emit(fid, HP.thruster(0.35), HP.frame(p, n.orthogonal(), n), inv)
        self.fitdata.append(dict(id=fid, kind='thruster', cones=[dict(apex=tuple(p + n * 0.3), dir=tuple(n), r0=0.25, half=20.0, length=1.2)]))
        self.features.append(dict(id=fid, kind='thruster', what='attitude thruster quad', count=1, pos=tuple(p),
                                  aim=None, src=src, note=note, inv=[inv] if isinstance(inv, str) else list(inv)))

    def _surface_part(self, fid, part, pos, normal, up_hint, inv, what, kind, src, note, aperture=0.0, keep=True):
        p = Vector(pos); n = Vector(normal).normalized()
        u = Vector(up_hint)
        # local +Z = the surface normal; local +X lies along up_hint projected into the surface
        part = self.emit(fid, part, HP.frame(p, u - n * u.dot(n) if (u - n * u.dot(n)).length > 1e-4 else n.orthogonal(), n) @
                         Matrix.Rotation(0, 4, 'Z'), inv, keep=keep)
        if aperture:
            self.fitdata.append(dict(id=fid, kind=kind, apertures=[dict(pos=tuple(p + n * 0.12), dir=tuple(n), length=aperture, cone=0.0, what=kind)]))
        self.features.append(dict(id=fid, kind=kind, what=what, count=1, pos=tuple(p), aim=None, src=src, note=note,
                                  inv=[inv] if isinstance(inv, str) else list(inv)))
        return part

    def hatch(self, fid, pos, normal, w, h=None, round_=False, inv=(), src='picture', note='', up=(1, 0, 0)):
        return self._surface_part(fid, HP.hatch(w, h or w, round_=round_), pos, normal, up, inv,
                                  '%s hatch %.1f' % ('round' if round_ else 'square', w), 'hatch', src, note, aperture=0.6)

    def hatchbox(self, fid, pos, w, l, h, fins=0, yaw=0.0, inv=(), src='picture', note=''):
        p = Vector(pos)
        part = self.emit(fid, HP.hatchbox(w, l, h, fins), HP.frame(p, (math.cos(math.radians(yaw)), math.sin(math.radians(yaw)), 0), (0, 0, 1)), inv)
        self.features.append(dict(id=fid, kind='hatchbox', what='framed deck box %.1f x %.1f%s' % (l, w, ', %d armour fins' % fins if fins else ''),
                                  count=1, pos=tuple(p), aim=None, src=src, note=note, inv=[inv] if isinstance(inv, str) else list(inv)))

    def vent(self, fid, pos, normal, w, h, slats=5, inv=(), src='picture', note=''):
        return self._surface_part(fid, HP.vent(w, h, slats), pos, normal, (0, 0, 1) if abs(Vector(normal).z) < 0.7 else (1, 0, 0), inv,
                                  'louvre panel %.1f x %.1f' % (w, h), 'vent', src, note, aperture=0.4)

    def lamp(self, fid, pos, normal, inv=(), src='picture', note=''):
        return self._surface_part(fid, HP.lamp(0.08), pos, normal, (0, 0, 1) if abs(Vector(normal).z) < 0.7 else (1, 0, 0), inv,
                                  'running light', 'lamp', src, note, aperture=0.35)

    def slit(self, fid, pos, normal, w, h, inv=(), src='picture', note=''):
        return self._surface_part(fid, HP.slit(w, h), pos, normal, (0, 0, 1) if abs(Vector(normal).z) < 0.7 else (1, 0, 0), inv,
                                  'vision slit %.1f x %.2f' % (w, h), 'slit', src, note, aperture=0.5)

    def bay(self, fid, pos, w, l, inv=(), src='designed', note=''):
        return self._surface_part(fid, HP.bay(w, l), pos, (0, 0, -1), (1, 0, 0), inv, 'ventral launch bay %.1f x %.1f' % (l, w), 'bay', src, note,
                                  aperture=2.0)

    def antenna(self, fid, pos, h, whips=3, inv=(), src='picture', note=''):
        p = Vector(pos)
        self.emit(fid, HP.antenna(h, whips), HP.frame(p, (1, 0, 0), (0, 0, 1)), inv)
        self.features.append(dict(id=fid, kind='antenna', what='antenna array, %.1f tall, %d whips' % (h, whips), count=1, pos=tuple(p), aim=None,
                                  src=src, note=note, inv=[inv] if isinstance(inv, str) else list(inv)))

    def pipe(self, fid, pts, r=0.07, inv=(), src='picture', note=''):
        self.emit(fid, HP.pipe(pts, r), Matrix.Identity(4), inv, keep=False)
        self.features.append(dict(id=fid, kind='pipe', what='pipe run, %.2f bore' % (2 * r), count=1, pos=tuple(Vector(pts[0])),
                                  end=tuple(Vector(pts[-1])), aim=None, src=src, note=note, inv=[inv] if isinstance(inv, str) else list(inv)))

    def rib(self, fid, pts, w=0.14, t=0.1, inv=(), m='iron'):
        """a raised frame rib along the hull (a run of flat bars through pts, standing t proud)"""
        V, F = [], []
        for a, b in zip(pts, pts[1:]):
            vv, ff = HP.rod(Vector(a), Vector(b), w * 0.5, 4)
            o = len(V); V += vv; F += [tuple(x + o for x in f) for f in ff]
        self._obj(fid, V, F, m, grp='hull')
        for a, b in zip(pts, pts[1:]):
            for k in range(4):
                self.keepouts.append((Vector(a).lerp(Vector(b), (k + 0.5) / 4), 0.45))
        if inv:
            self.mark(inv, 'rib', ['rib'], fid=fid)

    def patch(self, fid, pos, normal, w, h, ang=0.0, lift=0.12, t=0.06, m='iron', inv=()):
        """a torn patch plate: crooked, one corner lifted, riveted"""
        p = Vector(pos); n = Vector(normal).normalized()
        u = n.orthogonal().normalized() if abs(n.z) > 0.7 else Vector((0, 0, 1)).cross(n).normalized()
        v = n.cross(u).normalized()
        c, s = math.cos(ang), math.sin(ang); u, v = u * c + v * s, v * c - u * s
        bot = [p - u * w / 2 - v * h / 2, p + u * w / 2 - v * h / 2, p + u * w / 2 + v * h / 2, p - u * w / 2 + v * h / 2]
        (V, F), (RV, RF) = HP.plate_slab(bot, n, t, lift=lift, rivets=True, rr=0.03)
        self._obj(fid + '_slab', V, F, m, grp='hull'); self._obj(fid + '_rivets', RV, RF, 'iron', grp='hull')
        if inv:
            self.built.append(dict(id=fid, kind='patch', inv=[inv], shaped=True, detailed=lift > 0, subs=['slab', 'lift', 'rivet']))

    def allow_touch(self, a, b, why):
        self.allow.append((a, b, why))

    def fix(self, clash, how):
        self.fixes.append((clash, how))

    def fitting(self, fid, what, pos, aim=None, src='picture', note='', kind='fitting', inv=()):
        self.features.append(dict(id=fid, kind=kind, what=what, count=1, pos=tuple(pos), aim=aim, src=src, note=note,
                                  inv=[inv] if isinstance(inv, str) else list(inv)))

    def mass(self, name, ob, role, src='picture', note=''):
        self.masses.append(dict(name=name, obj=ob.name, role=role, src=src, note=note))
        return ob

    # ---------- inside ----------
    def room(self, name, kind, x0, x1, y0, y1, z0, z1, note=''):
        self.box('in_' + name, x0, x1, y0, y1, z0, z1, kind, inside=True, ch=0.05)
        self.inside.append(dict(kind='space', name=name, mat=kind, x=(x0, x1), y=(y0, y1), z=(z0, z1), note=note))

    def deck(self, name, z, x0, x1, inset=0.35, t=0.08):
        secs = []
        for x in (x1, (x0 + x1) / 2, x0):
            s = sec_at(self.hull_sections, x)
            hwp = s[1] - inset; hws = s[2] - inset
            if z > s[4] - s[5]:
                k = s[5] - (s[4] - z); hwp -= k; hws -= k
            if z < s[3] + s[6]:
                k = s[6] - (z - s[3]); hwp -= k; hws -= k
            yo = s[7] if len(s) > 7 else 0.0
            secs.append((x, max(hwp, 0.2), max(hws, 0.2), z - t / 2, z + t / 2, 0, 0, yo))
        self.loft('in_deck_' + name, secs, 'deck', inside=True)
        self.inside.append(dict(kind='deck', name=name, z=z, x=(x0, x1)))

    def deck_box(self, name, z, x0, x1, hw, t=0.08):
        self.box('in_deck_' + name, x0, x1, -hw, hw, z - t / 2, z + t / 2, 'deck', inside=True)
        self.inside.append(dict(kind='deck', name=name, z=z, x=(x0, x1)))

    def bulkhead(self, name, x, inset=0.3, t=0.1, zmax=None):
        s = sec_at(self.hull_sections, x)
        zt = s[4] - inset if zmax is None else zmax
        sec = (x, s[1] - inset, s[2] - inset, s[3] + inset, zt, max(s[5] - inset * 0.5, 0), max(s[6] - inset * 0.5, 0), s[7] if len(s) > 7 else 0)
        a = list(sec); a[0] = x + t / 2; b = list(sec); b[0] = x - t / 2
        self.loft('in_bh_' + name, [tuple(a), tuple(b)], 'frame', inside=True)
        self.inside.append(dict(kind='bulkhead', name=name, x=x))

    def armour(self, zone, thick, note=''):
        self.inside.append(dict(kind='armour', name=zone, t=thick, note=note))

    def break_line(self, name, x, note='', path=None, kind='trans'):
        """path: the seam as (x, z) points from deck to belly, uneven along the patch plates (R186: never a straight cut)"""
        self.inside.append(dict(kind='break', name=name, x=x, note=note, path=path, orient=kind))

    def point(self, kind, name, pos, side='', section='', note=''):
        self.points.append(dict(kind=kind, name=name, pos=tuple(pos), side=side, section=section, note=note))

    def colour(self, name, x0, x1, where, note=''):
        self.inside.append(dict(kind='colour', name=name, x=(x0, x1), where=where, note=note))

    def change(self, what, why):
        self.changes.append((what, why))

    def open_item(self, what):
        self.tbd.append(what)
