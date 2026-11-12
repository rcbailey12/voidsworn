# Build sheet blockout kit (issue 532). Runs inside Blender (4.5 on Ryan's PC, or the bpy module).
# One design per ship: the ship file (ships/<code>.py) calls these helpers to make simple stand-in meshes for every
# mass and fitting, and records every fitting in the feature table. The renders, the feature table and the INSIDE
# section all come from this one model, so the views agree by construction.
# Frame: +X bow, +Y port, +Z up (Blender). Station 0 percent is the prow tip (the most forward point of the model).
import math
import bpy
import bmesh
from mathutils import Vector, Matrix

MATS = {
    # name: (rgb, emission strength). Colour zones are schematic: the beauty picture gives the finish.
    'soot': ((0.055, 0.050, 0.048), 0),      # soot black hull plate
    'rust': ((0.30, 0.12, 0.07), 0),         # rust plate
    'blood': ((0.33, 0.05, 0.05), 0),        # dried-blood red band
    'violet': ((0.28, 0.12, 0.45), 0),       # violet Eclipse trophy plate
    'pale': ((0.55, 0.56, 0.58), 0),         # pale Hegemony grey trophy plate
    'steel': ((0.20, 0.20, 0.21), 0),        # gun metal and machinery
    'dark': ((0.02, 0.02, 0.02), 0),         # intake throats, apertures
    'dish': ((0.62, 0.60, 0.56), 0),         # dish faces
    'glow': ((1.0, 0.25, 0.08), 6),          # engine glow
    'light': ((1.0, 0.1, 0.05), 3),          # running lights
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
    # chorus and eclipse palettes are added by their ship files
}


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
    b.inputs['Metallic'].default_value = 0.3 if name in ('steel', 'pale', 'dish') else 0.1
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
        self.hull_sections = None
        self.coll = bpy.data.collections.new(code)
        bpy.context.scene.collection.children.link(self.coll)
        self.cin = bpy.data.collections.new(code + '_inside')
        bpy.context.scene.collection.children.link(self.cin)

    # ---------- raw mesh ----------
    def _obj(self, name, verts, faces, m, inside=False, smooth=False):
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
        return ob

    def loft(self, name, sections, m, inside=False, shell=0.0, ytilt=None):
        """sections: (x, hw_port, hw_stbd, z_bottom, z_top, chamfer_top, chamfer_bottom[, y_offset]) bow first"""
        rings = []
        for s in sections:
            x, hwp, hws, zb, zt, ct, cb = s[:7]
            yo = s[7] if len(s) > 7 else 0.0
            rings.append([(x, y, z) for (y, z) in _octa(hwp, hws, zb, zt, ct, cb, yo)])
        verts = [v for r in rings for v in r]
        n = 8
        faces = []
        for i in range(len(rings) - 1):
            for j in range(n):
                a, b = i * n + j, i * n + (j + 1) % n
                faces.append((a, b, b + n, a + n))
        faces.append(tuple(range(n))[::-1])
        faces.append(tuple(range((len(rings) - 1) * n, len(rings) * n)))
        ob = self._obj(name, verts, faces, m, inside)
        # make normals point out
        bm = bmesh.new(); bm.from_mesh(ob.data); bmesh.ops.recalc_face_normals(bm, faces=bm.faces); bm.to_mesh(ob.data); bm.free()
        if shell:
            mod = ob.modifiers.new('shell', 'SOLIDIFY'); mod.thickness = shell; mod.offset = -1; mod.use_rim = True
        return ob

    def box(self, name, x0, x1, y0, y1, z0, z1, m, ch=0.0, inside=False, taper=0.0):
        """axis box from x0 (aft) to x1 (fore), y0 (stbd) to y1 (port); taper shrinks the fore end"""
        hw = (y1 - y0) / 2; yo = (y1 + y0) / 2
        secs = [(x1, hw - taper, hw - taper, z0, z1 - taper * 0.5, ch, ch * 0.5, yo), (x0, hw, hw, z0, z1, ch, ch * 0.5, yo)]
        return self.loft(name, secs, m, inside)

    def cyl(self, name, p0, p1, r0, m, r1=None, n=16, inside=False, cap=True):
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
        ob = self._obj(name, verts, faces, m, inside, smooth=True)
        bm = bmesh.new(); bm.from_mesh(ob.data); bmesh.ops.recalc_face_normals(bm, faces=bm.faces); bm.to_mesh(ob.data); bm.free()
        return ob

    def tube(self, name, pts, r, m, n=8):
        """a polyline tube (chains, cables), joined segments"""
        obs = []
        for i in range(len(pts) - 1):
            obs.append(self.cyl('%s_%d' % (name, i), pts[i], pts[i + 1], r, m, n=n))
        return obs

    # ---------- surface helpers ----------
    def hull(self, sections, m='soot', shell=0.25):
        self.hull_sections = sections
        return self.loft(self.code + '_hull', sections, m, shell=shell)

    def top_z(self, x, sections=None):
        s = sec_at(sections or self.hull_sections, x)
        return s[4]

    def side_y(self, x, side, z=None, sections=None):
        s = sec_at(sections or self.hull_sections, x)
        hw = s[1] if side > 0 else s[2]
        yo = s[7] if len(s) > 7 else 0.0
        return yo + side * hw

    # ---------- fittings ----------
    @staticmethod
    def aim_vec(yaw, pitch):
        y, p = math.radians(yaw), math.radians(pitch)
        return Vector((math.cos(y) * math.cos(p), math.sin(y) * math.cos(p), math.sin(p)))

    def gun(self, fid, pos, yaw, pitch=0.0, barrels=1, cal=0.12, blen=2.0, mount='turret', normal=(0, 0, 1),
            slot='', weapon='', src='picture', note='', size=1.0, m='steel'):
        """turret: ring and housing turning about the mount normal; barrels leave the housing front along yaw/pitch.
        normal (0,0,1) deck, (0,0,-1) belly, (0,+-1,0) a sponson shelf on the flank (housing still turns about the shelf normal)"""
        assert -100 < yaw < 100, fid + ' would aim aft'
        p = Vector(pos); nrm = Vector(normal).normalized(); d = self.aim_vec(yaw, pitch)
        s = size
        ring_r = 0.42 * s; hous = 0.36 * s
        self.cyl(fid + '_ring', p - nrm * 0.15, p + nrm * 0.14 * s, ring_r, m)
        hc = p + nrm * (0.14 * s + hous)
        # housing: a box aligned to the aim in the plane of the mount
        side = nrm.cross(d); side = side.normalized() if side.length > 1e-6 else Vector((0, 1, 0))
        fwd = side.cross(nrm).normalized()
        L = 0.85 * s; W = 0.7 * s * (1 + 0.25 * (barrels - 1)); H = 0.55 * s
        corners = []
        for a in (-L / 2, L / 2):
            for b in (-W / 2, W / 2):
                for c in (-H / 2, H / 2):
                    t = 0.18 * s if a > 0 else 0.0
                    corners.append(hc + fwd * a + side * b * (1 - t) + nrm * c * (1 - t))
        faces = [(0, 1, 3, 2), (4, 6, 7, 5), (0, 4, 5, 1), (2, 3, 7, 6), (0, 2, 6, 4), (1, 5, 7, 3)]
        ob = self._obj(fid + '_housing', corners, faces, m)
        bm = bmesh.new(); bm.from_mesh(ob.data); bmesh.ops.recalc_face_normals(bm, faces=bm.faces); bm.to_mesh(ob.data); bm.free()
        muzzles = []
        for i in range(barrels):
            off = (i - (barrels - 1) / 2) * cal * 3.2
            b0 = hc + fwd * (L * 0.35) + side * off
            b1 = b0 + d * blen
            self.cyl('%s_barrel%d' % (fid, i), b0, b1, cal, m, n=10)
            self.cyl('%s_brake%d' % (fid, i), b1 - d * 0.18 * s, b1, cal * 1.45, m, n=10)
            muzzles.append(tuple(b1))
        mname = 'ball casemate' if abs(nrm.z) < 0.5 else ('sponson turret' if mount == 'sponson' else ('belly turret' if nrm.z < 0 else 'turret'))
        self.features.append(dict(id=fid, kind='gun', what='%s %s' % ({1: 'single', 2: 'twin', 3: 'triple'}.get(barrels, str(barrels)), mname),
                                  count=barrels, pos=tuple(p), aim=(yaw, pitch), slot=slot, weapon=weapon, src=src, note=note,
                                  muzzle=muzzles, normal=tuple(nrm)))

    def launcher(self, fid, pos, rows, cols, tube_r=0.22, depth=2.0, yaw=0.0, pitch=8.0, slot='', weapon='', src='picture', note=''):
        p = Vector(pos)
        W = cols * tube_r * 2.3 + 0.3; H = rows * tube_r * 2.3 + 0.3
        self.box(fid + '_body', p.x - depth, p.x, p.y - W / 2, p.y + W / 2, p.z, p.z + H, 'steel', ch=0.08)
        d = self.aim_vec(yaw, pitch)
        for r in range(rows):
            for c in range(cols):
                cy = p.y + (c - (cols - 1) / 2) * tube_r * 2.3
                cz = p.z + 0.15 + tube_r * 1.15 + r * tube_r * 2.3
                t0 = Vector((p.x - depth * 0.6, cy, cz)); t1 = Vector((p.x + 0.25, cy, cz)) + d * 0.1
                self.cyl('%s_tube%d%d' % (fid, r, c), t0, t1, tube_r, 'steel', n=12)
                self.cyl('%s_mouth%d%d' % (fid, r, c), t1 - d * 0.02, t1 + d * 0.01, tube_r * 0.78, 'dark', n=12)
        self.features.append(dict(id=fid, kind='launcher', what='rocket rack, %d by %d tubes' % (rows, cols), count=rows * cols,
                                  pos=tuple(p), aim=(yaw, pitch), slot=slot, weapon=weapon, src=src, note=note))

    def engine(self, fid, pos, r, length, bell=1.25, src='picture', note='', yaw=180.0, pitch=0.0, m='steel'):
        """engine pod: body forward of pos, bell aft, glow disc at the exit (exhaust points aft: yaw 180)"""
        p = Vector(pos); d = -self.aim_vec(0, 0)  # aft
        front = p + Vector((length, 0, 0))
        self.cyl(fid + '_body', front, p, r * 0.85, m, r1=r)
        bell_end = p + d * (r * 0.9)
        self.cyl(fid + '_bell', p, bell_end, r, m, r1=r * bell, cap=False)
        self.cyl(fid + '_glow', bell_end - d * (r * 0.5), bell_end - d * (r * 0.45), r * bell * 0.92, 'glow')
        self.features.append(dict(id=fid, kind='engine', what='engine, bell %.1f across' % (2 * r * bell), count=1,
                                  pos=tuple(p), aim=(180.0, 0.0), src=src, note=note, exit=tuple(bell_end), radius=r * bell))

    def intake(self, fid, pos, r, length, src='picture', note=''):
        p = Vector(pos)
        self.cyl(fid + '_duct', p - Vector((length, 0, 0)), p, r, 'steel', r1=r * 1.08)
        self.cyl(fid + '_lip', p - Vector((0.25, 0, 0)), p + Vector((0.05, 0, 0)), r * 1.18, 'steel')
        self.cyl(fid + '_throat', p + Vector((0.051, 0, 0)), p + Vector((0.07, 0, 0)), r * 0.85, 'dark')
        self.features.append(dict(id=fid, kind='intake', what='wake-sniffer scoop, %.1f across' % (2 * r), count=1,
                                  pos=tuple(p), aim=(0.0, 0.0), src=src, note=note))

    def dish(self, fid, pos, r, yaw=0.0, pitch=15.0, src='picture', note=''):
        p = Vector(pos); d = self.aim_vec(yaw, pitch)
        self.cyl(fid + '_post', p, p + Vector((0, 0, r * 0.9)), r * 0.12, 'steel', n=8)
        c = p + Vector((0, 0, r * 0.9))
        self.cyl(fid + '_yoke', c - d * 0.15, c + d * 0.05, r * 0.22, 'steel', n=8)
        self.cyl(fid + '_dish', c + d * 0.05, c + d * (r * 0.45), r * 0.15, 'dish', r1=r, n=20, cap=True)
        self.cyl(fid + '_feed', c + d * 0.1, c + d * (r * 0.9), r * 0.04, 'steel', n=6)
        self.features.append(dict(id=fid, kind='dish', what='listening dish, %.1f across' % (2 * r), count=1,
                                  pos=tuple(p), aim=(yaw, pitch), src=src, note=note))

    def claw(self, fid, hinge, pts, w=0.45, src='picture', note='', m='steel', name='boarding claw'):
        """boarding claw: a hinge drum under the hull, then tapered segments through pts, the last a hook"""
        h = Vector(hinge)
        self.cyl(fid + '_hinge', h - Vector((0, w * 0.6, 0)), h + Vector((0, w * 0.6, 0)), w * 0.5, m)
        prev = h
        for i, q in enumerate(pts):
            q = Vector(q)
            k = 1.0 - 0.55 * i / max(1, len(pts) - 1)
            self.cyl('%s_seg%d' % (fid, i), prev, q, w * 0.55 * k, m, r1=w * 0.5 * k * (0.35 if i == len(pts) - 1 else 0.9), n=6)
            prev = q
        self.features.append(dict(id=fid, kind='claw', what='%s, %d segments' % (name, len(pts)), count=1,
                                  pos=tuple(h), aim=(0.0, -60.0), src=src, note=note, tip=tuple(Vector(pts[-1]))))

    def chain(self, fid, pts, r=0.09, src='picture', note=''):
        self.tube(fid, pts, r, 'steel', n=6)
        for q in (pts[0], pts[-1]):
            self.box(fid + '_lug', q[0] - 0.2, q[0] + 0.2, q[1] - 0.2, q[1] + 0.2, q[2] - 0.2, q[2] + 0.2, 'steel')
        self.features.append(dict(id=fid, kind='chain', what='lashing chain, taut between lugs', count=1,
                                  pos=tuple(Vector(pts[0])), end=tuple(Vector(pts[-1])), aim=None, src=src, note=note))

    def fitting(self, fid, what, pos, aim=None, src='picture', note='', kind='fitting'):
        self.features.append(dict(id=fid, kind=kind, what=what, count=1, pos=tuple(pos), aim=aim, src=src, note=note))

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
            # narrower where the chamfers cut in
            if z > s[4] - s[5]:
                k = s[5] - (s[4] - z); hwp -= k; hws -= k
            if z < s[3] + s[6]:
                k = s[6] - (z - s[3]); hwp -= k; hws -= k
            yo = s[7] if len(s) > 7 else 0.0
            secs.append((x, max(hwp, 0.2), max(hws, 0.2), z - t / 2, z + t / 2, 0, 0, yo))
        self.loft('in_deck_' + name, secs, 'deck', inside=True)
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

    def break_line(self, name, x, note=''):
        self.inside.append(dict(kind='break', name=name, x=x, note=note))

    def point(self, kind, name, pos, side='', section='', note=''):
        self.points.append(dict(kind=kind, name=name, pos=tuple(pos), side=side, section=section, note=note))

    def colour(self, name, x0, x1, where, note=''):
        self.inside.append(dict(kind='colour', name=name, x=(x0, x1), where=where, note=note))

    def change(self, what, why):
        self.changes.append((what, why))

    def open_item(self, what):
        self.tbd.append(what)
