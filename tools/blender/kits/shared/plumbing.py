# Shared plumbing for every faction parts kit (Ryan, Nov 9 14:52 CST, R151: parts are NOT one shared kit; only invisible plumbing is
# shared). Nothing here has a look of its own: no part shapes, no paint. A faction kit (tools/blender/kits/<faction>/kit.py) builds
# its own parts on top of this:
#   - frame and scale rules: the ship frame (x to the bow, y to port, z up, length 1.0) and the size classes every kit uses, so a
#     casemate from one kit and a turret from another read at the same scale on the same hull;
#   - mount sockets: where a part goes (position, the hull normal it seats on, its aim, its side), read from the ship's placement file
#     and seated on the real hull by ray cast, so parts never float or sink;
#   - the rules every part passes (owner, Oct 21 and 22): guns never aim backward or into the ship, matched pairs mirror exactly in
#     placement and size (detail may differ on a Hullbreaker hull), no part crosses a break line;
#   - tags the bake, LOD and export steps read (role, kind, size), and the gun registry the audit reads.
# The primitives (box, cyl, loft) come from tools/blender/hs/hs_lib.py; the bake, LOD and export steps are the r209 scripts
# (bakeAb6.py, export3.py), which take any kit's parts through the same tags.
import os, sys, math, json
HERE = os.path.dirname(os.path.abspath(__file__))
for p in (os.path.join(HERE, '..', '..', 'hs'), os.path.join(HERE, '..', '..', 'a1'), os.path.join(HERE, '..', '..', 'r209')):
    p = os.path.normpath(p)
    if p not in sys.path: sys.path.insert(0, p)
import bpy
from mathutils import Vector, Matrix
import hs_lib

# ---------------------------------------------------------------------------------------------------------------- scale rules
# Ship-length units (the hull is 1.0 long). A kit picks its sizes inside these classes; battle distance draws a 1.0 ship at about
# 180 px, so anything under MIN_FEATURE is sub-pixel there and is dropped by the LOD chain anyway.
SCALE = dict(
    MIN_FEATURE=.003,          # smallest detail worth modelling (rivets, weld beads) at the close-up camera
    BARREL_R=(.003, .012),     # gun barrel radius, small to heavy
    MOUNT_W=(.04, .12),        # casemate or turret footprint
    DRUM_R=(.010, .026),       # missile drum radius
    LOD_DROP=(.012, .028, .050),  # export3.py: parts smaller than these vanish at lod1, lod2, lod3
)

# ---------------------------------------------------------------------------------------------------------------- tags and registry
GUNS = []      # (name, aim, socket normal) for the audit
MUZZLES = []   # round 7: one record per weapon muzzle (name, socket, tip, aim, normal, radius); the game export's hard points
ENGINES = []   # round 7: one record per engine exit (name, pos, dir, radius)

def mark():
    return len(hs_lib.PARTS)

def tag(since, role='part', kind=None):
    """role: part | trim | dark | glow | decal (paint and export read it); kind: the paint band or part family"""
    for o in hs_lib.PARTS[since:]:
        o['role'] = role
        if kind: o['kind'] = kind

def register_gun(name, aim, normal=None, tip=None, socket=None, radius=None):
    """every barrel and launch mouth a kit builds: the audit reads the aim; with tip (the muzzle point) and socket (the socket's
    name) it also becomes a weapon hard point in the game export (tools/recipe/export7.py)"""
    GUNS.append((name, Vector(aim).normalized(), Vector(normal).normalized() if normal is not None else None))
    if tip is not None:
        MUZZLES.append(dict(name=name, socket=socket, tip=[round(v, 5) for v in tip], aim=[round(v, 5) for v in Vector(aim).normalized()],
                            normal=[round(v, 5) for v in (Vector(normal).normalized() if normal is not None else Vector((0, 0, 1)))],
                            radius=round(radius or 0.0, 5)))

def register_engine(name, pos, direction, radius):
    ENGINES.append(dict(name=name, pos=[round(v, 5) for v in pos], dir=[round(v, 5) for v in Vector(direction).normalized()], radius=round(radius, 5)))

def clear_registry():
    GUNS.clear(); MUZZLES.clear(); ENGINES.clear()

def hardpoint_data(sockets):
    """what the game export needs from the build: every muzzle with its socket's weapon slot and side, and the engine exits.
    A hull module stores this on the scene (scene['r209_hp']) so it travels in the saved blend."""
    by = {s.name: s for s in sockets}; out = []
    for m in MUZZLES:
        s = by.get(m['socket']); out.append(dict(m, part=s.part if s else None, slot=getattr(s, 'slot', None) if s else None, side=s.side if s else 0))
    return dict(muzzles=out, engines=list(ENGINES))

def aim_ok(aim, normal=None):
    """owner rule: guns aim forward or out to the side, never backward (x < -0.05) and never into the ship (against the mount normal)"""
    a = Vector(aim).normalized()
    if a.x < -.05: return False
    if normal is not None and a.dot(Vector(normal).normalized()) < -.05: return False
    return True

def audit_guns():
    return [n for n, a, nn in GUNS if not aim_ok(a, nn)]

# ---------------------------------------------------------------------------------------------------------------- sockets
class Socket:
    """one mount point: pos (ship frame), normal (the hull surface it sits on, outward), aim (where a gun points), side (+1 port,
    -1 starboard, 0 centreline), size (the part's main dimension), variant (a kit's own choice: mismatched salvage, borrowed parts)"""
    def __init__(self, name, part, pos, normal=(0, 0, 1), aim=(1, 0, 0), side=0, size=.05, variant=0, extra=None):
        self.name, self.part = name, part
        self.pos, self.normal, self.aim = Vector(pos), Vector(normal).normalized(), Vector(aim).normalized()
        self.side, self.size, self.variant, self.extra = side, size, variant, dict(extra or {})

    def mirrored(self, name=None):
        m = lambda v: Vector((v.x, -v.y, v.z))
        return Socket(name or self.name + '_s', self.part, m(self.pos), m(self.normal), m(self.aim), -self.side, self.size,
                      self.variant, self.extra)

def sockets_from(path_or_dict):
    """the ship's placement file (tools/recipe/ships/<ship>.json, 'parts' list). Each entry: name, part, pos, normal, aim, size,
    variant, extra, and pair: true to add the starboard mirror (matched pairs mirror exactly); slot (and slot_s for the mirror):
    the 0-based weapon slot of the game ship's data.js weapon list this socket's muzzles fire for (none: no hard point)"""
    d = json.load(open(path_or_dict)) if isinstance(path_or_dict, str) else path_or_dict
    out = []
    for e in d['parts']:
        s = Socket(e['name'], e['part'], e['pos'], e.get('normal', (0, 0, 1)), e.get('aim', (1, 0, 0)), 1 if e.get('pair') else e.get('side', 0),
                   e.get('size', .05), e.get('variant', 0), e.get('extra'))
        s.seat_mode = e.get('seat', 'abs'); s.slot = e.get('slot'); out.append(s)       # slot: the game weapon slot this socket serves
        if e.get('pair'):
            m = s.mirrored(e['name'] + '_s'); m.variant = e.get('variant_s', s.variant); m.seat_mode = s.seat_mode
            m.slot = e.get('slot_s', s.slot); out.append(m)
    return out

class Seat:
    """ray casts onto the real hull (blocks plus plates), so a part's mount lands on the surface it is drawn on"""
    def __init__(self, hull_objs):
        from mathutils.bvhtree import BVHTree
        import bmesh
        bm = bmesh.new()
        for o in hull_objs:
            me = o.evaluated_get(bpy.context.evaluated_depsgraph_get()).to_mesh(); t = bmesh.new(); t.from_mesh(me)
            bmesh.ops.transform(t, matrix=o.matrix_world, verts=t.verts); m2 = bpy.data.meshes.new('_t'); t.to_mesh(m2); t.free(); bm.from_mesh(m2)
            bpy.data.meshes.remove(m2); o.evaluated_get(bpy.context.evaluated_depsgraph_get()).to_mesh_clear()
        self.T = BVHTree.FromBMesh(bm); bm.free()

    def hit(self, origin, direction, reach=1.2):
        loc, nrm, _, _ = self.T.ray_cast(Vector(origin), Vector(direction).normalized(), reach)
        return (loc, nrm) if loc is not None else (None, None)

    def flank(self, x, z, s):
        loc, n = self.hit((x, s * .6, z), (0, -s, 0)); return (abs(loc.y), n) if loc is not None else (None, None)

    def top(self, x, y, L=0.0, W=0.0):
        """highest hull point under a footprint L (along x) by W (along y)"""
        zs = []
        for xx in (x - L / 2, x, x + L / 2):
            for yy in (y - W / 2, y, y + W / 2):
                loc, n = self.hit((xx, yy, .6), (0, 0, -1))
                if loc is not None: zs.append(loc.z)
        return max(zs) if zs else None

def resolve(sockets, seat):
    """seat each socket on the real hull: 'flank' finds y (and a level outward normal) at (x, z) on the socket's side; 'top' finds the
    deck height under (x, y) and adds extra['above'] (extra['seat_at'] = [x, y] reads the deck height there instead, for a part
    that comes out from under a hood onto a lower deck); 'abs' keeps pos as given"""
    for s in sockets:
        mode = getattr(s, 'seat_mode', 'abs')
        if mode == 'flank':
            sd = s.side or 1; y, n = seat.flank(s.pos.x, s.pos.z, sd)
            if y is None: raise RuntimeError(f'socket {s.name}: no hull at x {s.pos.x} z {s.pos.z}')
            s.pos.y = sd * y; n = Vector((n.x, n.y, 0))
            if n.y * sd < 0: n = -n
            s.normal = n.normalized()
        elif mode == 'top':
            at = s.extra.get('seat_at', (s.pos.x, s.pos.y)); z = seat.top(at[0], at[1])
            if z is None: raise RuntimeError(f'socket {s.name}: no deck at x {s.pos.x} y {s.pos.y}')
            s.pos.z = z + s.extra.get('above', 0.0); s.normal = Vector((0, 0, 1))
    return sockets

# ---------------------------------------------------------------------------------------------------------------- small helpers
def frame(aim, up=(0, 0, 1)):
    """rotation whose X axis is aim and whose Z axis is as close to up as possible"""
    return Vector(aim).normalized().to_track_quat('X', 'Z').to_matrix()

def lod_size(objs):
    for o in objs:
        w = [o.matrix_world @ Vector(b) for b in o.bound_box]
        o['size'] = (Vector([max(v[i] for v in w) for i in range(3)]) - Vector([min(v[i] for v in w) for i in range(3)])).length

# ---------------------------------------------------------------------------------------------------------------- audit
def audit(hull_objs, part_objs, guns=(), t_lines=None, l_line=None):
    """common.audit's checks in one pass (a kit adds hundreds of small parts; the pairwise version rebuilt a tree per part):
    parts that neither touch the hull nor another part (floating), parts across a break line, guns aimed backward"""
    import bmesh
    from mathutils.bvhtree import BVHTree
    import common as C
    t_lines = C.T_LINES if t_lines is None else t_lines; l_line = C.L_LINE if l_line is None else l_line
    probs = [f'gun {nm} aims backward (x {d.x:+.2f})' for nm, d in guns if d.x < -.05]; cross = []
    T = C.bvh(hull_objs); allp = list(part_objs)
    bm = bmesh.new(); owner = []; dg = bpy.context.evaluated_depsgraph_get()
    for k, o in enumerate(allp):
        oe = o.evaluated_get(dg); me = oe.to_mesh(); t = bmesh.new(); t.from_mesh(me); t.transform(o.matrix_world)
        owner += [k] * len(t.faces); tm = bpy.data.meshes.new('tmp'); t.to_mesh(tm); t.free(); bm.from_mesh(tm); bpy.data.meshes.remove(tm); oe.to_mesh_clear()
    ALL = BVHTree.FromBMesh(bm); bm.free()
    touching = set(owner[a] for a, b in ALL.overlap(ALL) if owner[a] != owner[b])
    for k, o in enumerate(allp):
        w = [o.matrix_world @ Vector(b) for b in o.bound_box]; lo = Vector([min(v[i] for v in w) for i in range(3)]); hi = Vector([max(v[i] for v in w) for i in range(3)])
        for x in t_lines:
            if lo.x < x - .002 and hi.x > x + .002: cross.append(o.name)
        if lo.x < l_line[2] and hi.x > l_line[1] and lo.z < l_line[0] - .002 < l_line[0] + .002 < hi.z: cross.append(o.name)
        if k in touching or T.overlap(C.bvh([o])): continue
        dmin = 9
        for v in list(o.data.vertices)[::max(1, len(o.data.vertices) // 150)]:
            h = T.find_nearest(o.matrix_world @ v.co)
            if h[0] is not None: dmin = min(dmin, h[3])
        if dmin > .002: probs.append(f'part {o.name} floats {dmin * 41.6:.2f} game units off the hull')
    return dict(problems=probs, parts=len(allp), crossing_break_lines=sorted(set(cross)))
