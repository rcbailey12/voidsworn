# A1 step 2: Pyre-Barge v15, the dressed version of Ryan's pick (Oct 24, FINDINGS R12): shape C (double-sided hulk) plus some of
# shape B's salvage junk, in the Corsair rust-and-bone palette, with the v14 detail pass (plating, repairs, pipes, vents, dents, jank).
# Frame: x aft (bow at -x), y to port, z up, length about 1.0, the same as c19_kit.py and barge_shapes.py.
# usage: python3 barge_v15.py out_prefix [--export]    (bpy module or Blender -P; --export also writes OUT_shell.glb and OUT_kit.glb)
# Space, not naval (CLAUDE.md): no keel, stem, sheer, crossbar mast or funnels. Guns face forward or out, never back.
import sys, os, math, random
HERE = os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0, os.path.join(HERE, '..', 'hs')); sys.path.insert(0, HERE)
import bpy, bmesh
from mathutils import Vector, Matrix
import hs_lib
from hs_lib import loft, frustum, box, cyl, barrel
import barge_shapes as B
GUN_DIRS = []  # (name, direction) for every barrel, for the no-backward-guns check
_barrel = B.barrel
def _rec_barrel(name, base, d, L, r):
    GUN_DIRS.append((name, Vector(d).normalized())); return _barrel(name, base, d, L, r)
B.barrel = _rec_barrel

# ---- palette (linear RGB). Art direction (art_direction_rey.md): Corsair base desaturated rust brown #59331f, trim ochre #a3542c,
# big patches of stolen Hegemony grey and bare metal, hot red glow #e0402c with dirty engines. "Bone" is the pale salvaged plating.
RUST = (.100, .034, .014); RUST_DK = (.060, .022, .010); OCHRE = (.366, .089, .025); BONE = (.50, .45, .35); HEG = (.20, .21, .22)
BARE = (.17, .165, .16); HEG = (.13, .135, .145); GUN = (.07, .07, .075); STEEL = (.13, .13, .14); DARK = (.025, .025, .028); GLOW = (.75, .05, .025)
COL = {}
def tag(rgb):
    for o in hs_lib.PARTS:
        if o.name not in COL: COL[o.name] = rgb

ZC = -.070
def shell_shapes():
    """the three lofted masses of shape C: the hexagon hull, the red superstructure on top and the ordnance block underneath"""
    def hexs(x, w, h, top_w=.50):
        half = [(w * top_w, ZC + h), (w, ZC), (w * top_w, ZC - h)]; return (x, B.mirror(half, ZC + h, ZC - h))
    st = [(-.490, .006, .006), (-.380, .085, .040), (-.250, .140, .068), (-.100, .165, .080), (.200, .165, .080), (.380, .140, .070), (.470, .110, .060)]
    hull = loft('hull', [hexs(*s) for s in st], bevel=0)
    sup = []
    for x, zt, wt, wb in ((-.200, ZC + .085, .050, .100), (-.130, .040, .050, .120), (.120, .046, .055, .125), (.300, .046, .055, .115), (.340, ZC + .085, .060, .090)):
        sup.append((x, B.mirror([(wt, zt), (wb, ZC + .078), (wb, ZC + .070)], zt + .002, ZC + .070)))
    sups = loft('superstructure', sup, bevel=0)
    keel = []
    for x, zb, wb_, wt_ in ((-.120, ZC - .140, .045, .095), (-.070, ZC - .155, .055, .110), (.180, ZC - .155, .055, .110), (.250, ZC - .130, .050, .090)):
        keel.append((x, B.mirror([(wt_, ZC - .070), (wt_, ZC - .078), (wb_, zb)], ZC - .070, zb)))
    ven = loft('ventral', keel, bevel=0)
    out = []
    for o, col in ((hull, None), (sups, RUST), (ven, RUST_DK)):
        hs_lib.PARTS.remove(o)  # the shell is kept apart from the kit (it is the surface the detail pass dresses)
        bpy.context.view_layer.objects.active = o; o.select_set(True)
        m = o.modifiers.new('bv', 'BEVEL'); m.width = .0025; m.segments = 2; m.limit_method = 'ANGLE'; m.angle_limit = math.radians(30)
        bpy.ops.object.modifier_apply(modifier='bv')
        sd = o.modifiers.new('sd', 'SUBSURF'); sd.subdivision_type = 'SIMPLE'; sd.levels = sd.render_levels = 3; bpy.ops.object.modifier_apply(modifier='sd')
        o.select_set(False)
        a = o.data.color_attributes.new('Col', 'FLOAT_COLOR', 'POINT')
        for v, d in zip(o.data.vertices, a.data):
            c = col or (RUST if v.co.z > ZC + .004 else RUST_DK)  # upper hull rust, lower hull darker: no single "waterline" band (both halves carry hardware)
            d.color = (*c, 1)
        out.append(o)
    return out

def dressing():
    # top: the concept's signature masses, kept where the concept has them
    B.bridge_and_rack(z_off=-.012); tag(OCHRE)
    for nm in list(COL):  # rust body, bone roof, ochre only as trim (the all-ochre tier read as orange plastic)
        if nm.startswith('tier'): COL[nm] = RUST
        elif nm.startswith('roof'): COL[nm] = BONE
        elif nm.startswith(('plinth', 'rackcolumn')): COL[nm] = STEEL
        elif nm.startswith('windows'): COL[nm] = DARK
        elif nm.startswith(('drum', 'tube')): COL[nm] = GUN
    B.antenna_array(.032, 0, .092, h=.14); tag(STEEL)
    for o in hs_lib.PARTS:
        if o.name.startswith('dish') and o.name not in ('dishstrut0', 'dishstrut1'): COL[o.name] = BONE
    # underside: bay doors and the ventral sensor array (the answer to the top array)
    for k in range(5): box(f'bayslat{k}', (-.050 + k * .045, 0, ZC - .158), (.030, .080, .006), bevel=.001)
    tag(DARK)
    B.antenna_array(.215, 0, ZC - .132, h=.10, flip=True); tag(STEEL)
    # engine pods, deliberately mismatched (shape B's junk): port is the standard pod, starboard a stolen oversized donor engine
    box('pylonP', (.090, .175, ZC), (.140, .040, .022), bevel=.002); tag(STEEL)
    cyl('nacelleP', (.110, .215, ZC), .040, .300, axis='X', seg=28, bevel=.004); tag(RUST)
    for k in range(4): cyl(f'nacbandP{k}', (-.010 + k * .075, .215, ZC), .0415, .008, axis='X', seg=28, bevel=0)
    tag(OCHRE)
    B.engine_bell((.263, .215, ZC), .045, .055); tag(GUN)
    box('nacelleplateP', (.020, .215, ZC + .036), (.100, .040, .010), bevel=.002); tag(BONE)
    DY, DZ, DR = -.226, ZC - .016, .049  # stolen Hegemony engine: bigger than the port pod, never repainted, held on with straps
    box('pylonS', (.140, -.150, ZC - .012), (.150, .060, .030), rot=(0, 0, .04), bevel=.003); tag(BARE)
    cyl('donorpod', (.150, DY, DZ), DR, .330, axis='X', seg=36, bevel=.004); tag(HEG)
    for k in range(7): cyl(f'donorrib{k}', (.005 + k * .048, DY, DZ), DR + .0025, .006, axis='X', seg=36, bevel=.0008)  # structural rings
    tag(GUN)
    for a_ in (35, 145, 215, 325):  # lengthwise rails between the rings
        r_ = math.radians(a_); box(f'donorrail{a_}', (.150, DY + math.cos(r_) * (DR + .002), DZ + math.sin(r_) * (DR + .002)), (.300, .006, .006), rot=(r_, 0, 0), bevel=.0006)
    tag(STEEL)
    box('donorhatch', (.120, DY - DR * .55, DZ + DR * .80), (.060, .030, .006), rot=(-.6, 0, 0), bevel=.001); tag(BARE)
    box('donorpatch', (.215, DY - DR * .30, DZ + DR * .95), (.050, .040, .005), rot=(-.3, .05, .1), bevel=.001); tag(RUST)  # a Corsair repair patch
    cyl('donorintake', (-.017, DY, DZ), DR * .86, .014, axis='X', seg=36, bevel=.002); tag(DARK)
    for k in range(5): box(f'donorgrille{k}', (-.025, DY, DZ - DR * .6 + k * DR * .3), (.004, DR * 1.5, .004), bevel=0)
    tag(STEEL)
    for k in range(3): box(f'donorstrap{k}', (.050 + k * .090, DY + .016, DZ + DR - .002), (.010, .062, .006), rot=(-.40, 0, 0), bevel=0)  # crude straps over the pod, sunk into it
    tag(RUST)
    B.engine_bell((.318, DY, DZ), .062, .065); tag(GUN)
    # stolen block (shape B's cargo section, cut down) hung under the port side, a few degrees off true
    B.loft('cargo', [(x, B.mirror([(.050, ZC - .110), (.055, ZC - .135), (.050, ZC - .170)], ZC - .105, ZC - .175)) for x in (-.180, -.150, .020, .050)], bevel=.003)
    o = bpy.data.objects['cargo']; o.location = (0, .085, 0); o.rotation_euler = (0, .035, .03); tag(BONE)
    for x in (-.120, -.010): box(f'cargopylon{x}', (x, .085, ZC - .098), (.018, .026, .026), bevel=.002)
    tag(STEEL)
    for k in range(3): box(f'cargoband{k}', (-.150 + k * .080, .085, ZC - .140), (.008, .114, .072), bevel=.001)
    tag(RUST)
    # radiators (no funnels) and the stern engines
    B.radiator_pair(.390, 0, ZC + .060, splay=12, n=2, L=.080, H=.075); tag(BARE)
    B.radiator_pair(.390, 0, ZC - .060, flip=True, splay=14, n=2, L=.080, H=.060); tag(BARE)
    B.engine_bell((.473, 0, ZC + .022), .032, .050); B.engine_bell((.473, 0, ZC - .030), .036, .050); tag(GUN)
    # guns: forward along the prow, and forward-and-out on the flanks, never back
    B.bow_guns(-.380, (.050, -.050), ZC, L=.055); tag(GUN)
    B.side_guns([(-.140, .120, ZC + .045), (.235, .120, ZC + .048)], up=.25); tag(GUN)
    # salvage: a stolen Hegemony armour plate on the port bow, a bone plate on the starboard bow, hazard bar on the ventral nose
    import detail_lib
    from mathutils.bvhtree import BVHTree
    HB = BVHTree.FromObject(bpy.data.objects['hull'], bpy.context.evaluated_depsgraph_get())
    for nm, x, z, side, sz, tw, col in (('donorplate', -.180, ZC + .038, 1, (.090, .046, .010), .05, HEG), ('boneplate', -.230, ZC + .026, -1, (.070, .040, .010), -.08, BONE)):
        h = HB.ray_cast(Vector((x, side * .6, z)), Vector((0, -side, 0)), 1.0)  # sit on the real flank, a little sunk, never floating
        n = Vector(h[1]).normalized(); n = n if n.y * side > 0 else -n; t_, b_, n = detail_lib.frame(n)
        detail_lib.obox(nm, Vector(h[0]) + n * .002, t_, b_, n, sz, bevel=.002, rot=tw); tag(col)
    for k in range(6): box(f'navhaz{k}', (-.135 + k * .006, 0, ZC - .143), (.004, .060, .003), rot=(0, 0, .5)); tag(((.40, .30, .02), (.02, .02, .02))[k % 2])
    # engine glow discs, so the engines read lit in studio renders (the game draws its own plumes)
    for nm, c, r in (('glowP', (.299, .215, ZC), .036), ('glowS', (.355, -.226, ZC - .016), .050), ('glowT', (.512, 0, ZC + .022), .026), ('glowB', (.512, 0, ZC - .030), .029)):
        cyl(nm, c, r, .002, axis='X', seg=24, bevel=0)
    tag(GLOW)

def audit(shells, hardware):
    """A1 automatic checks (plan section 4): every hand-built part touches the hull or another part (no floating parts) and no gun
    points backward (bow is -x, so a barrel's x must not be positive). Returns a list of problems; empty means pass."""
    from mathutils.bvhtree import BVHTree
    probs = []
    for nm, d in GUN_DIRS:
        if d.x > .05: probs.append(f'gun {nm} points backward (x {d.x:+.2f})')
    dg = bpy.context.evaluated_depsgraph_get()
    def bvh(objs):
        bm = bmesh.new()
        for o in objs:
            m = o.evaluated_get(dg).to_mesh(); m.transform(o.matrix_world); bm.from_mesh(m); o.evaluated_get(dg).to_mesh_clear()
        t = BVHTree.FromBMesh(bm); bm.free(); return t
    for o in hardware:
        if o.name.startswith('glow'): continue
        others = [x for x in shells + hs_lib.PARTS if x is not o and not x.name.startswith('glow')]
        # one BVH per part would be slow; group by nearby objects only
        def box_of(x, m=0.):
            w = [x.matrix_world @ Vector(b) for b in x.bound_box]
            return Vector((min(v.x for v in w) - m, min(v.y for v in w) - m, min(v.z for v in w) - m)), Vector((max(v.x for v in w) + m, max(v.y for v in w) + m, max(v.z for v in w) + m))
        lo, hi = box_of(o, .02)
        near = [x for x in others if (lambda a, b: all(a[i] <= hi[i] and b[i] >= lo[i] for i in range(3)))(*box_of(x))]  # bounding boxes overlap
        T = bvh(near) if near else None
        if T is None: probs.append(f'part {o.name} has nothing near it'); continue
        P = bvh([o])
        if T.overlap(P): continue  # its surface crosses the hull or another part: mounted (sunk-in counts)
        verts = o.data.vertices; step = max(1, len(verts) // 200); dmin = 9  # no crossing: then it must at least touch
        for v in list(verts)[::step]:
            h = T.find_nearest(o.matrix_world @ v.co)
            if h[0] is not None: dmin = min(dmin, h[3])
        if dmin > .0015: probs.append(f'part {o.name} floats ({dmin * 1000:.1f} mm in ship units from the nearest surface)')
    return probs

def build(seed=19):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    shells = shell_shapes()
    dressing()
    hardware = list(hs_lib.PARTS)
    import detail_lib
    others = [o for o in hs_lib.PARTS if not o.name.startswith(('glow', 'navhaz'))]
    S0 = detail_lib.Surface(shells, others); rr = random.Random(11); spots = []
    for k in range(60):
        if len(spots) >= 12: break
        s_ = rr.choice((1, -1)); p_, n_ = S0.hit(Vector((rr.uniform(-.30, .44), s_ * .6, rr.uniform(ZC - .07, ZC + .07))), Vector((0, -s_, 0)), .008)
        if p_ is not None: spots.append((p_, rr.uniform(.010, .020), rr.uniform(.0025, .0045)))
    for sh in shells: detail_lib.dents(sh, spots)
    FL = [(Vector((.090, .175, ZC)), (.12, .03)), (Vector((.140, -.150, ZC - .01)), (.13, .04)), (Vector((.202, 0, .03)), (.06, .06)), (Vector((.215, 0, ZC - .132)), (.05, .05))]
    # step 3 (Oct 25): Corsair patchwork (art direction: "large patches of stolen Hegemony grey and bare metal, the patchwork is the
    # identity"). Each plate picks its paint from a weighted list keyed by its position, so the pick is stable between builds.
    RUST_LT = (.16, .055, .022)
    HEG_LT, BARE_LT = (.24, .25, .26), (.23, .22, .21)  # lighter than the parts' grey: plates must show in the game's darker light
    PATCH = [(RUST, .42), (RUST_LT, .14), (RUST_DK, .10), (HEG_LT, .15), (BARE_LT, .10), (BONE, .06), (OCHRE, .03)]
    def base(p):
        k = random.Random(hash((round(p.x, 3), round(p.y, 3), round(p.z, 3))) & 0xffffffff).random(); acc = 0
        for c, w in PATCH:
            acc += w
            if k <= acc: return c if c not in (RUST, RUST_LT) or p.z > ZC + .004 else RUST_DK
        return RUST
    detail_lib.detail_pass(shells, others, tag, base, (-.42, .46, ZC - .075, ZC + .075), corsair=True, seed=seed, flanges=FL)
    # big stolen panels on the wide plain surfaces (the superstructure top and the upper flanks read plain in game, Oct 25)
    S1 = detail_lib.Surface(shells, others); r1 = random.Random(seed + 5)
    def salvage(p, r_): return r_.choice((HEG_LT, HEG_LT, BARE_LT, BONE, (.15, .15, .16)))
    big = [(.6, (.07, .11), (.04, .065)), (.4, (.05, .07), (.03, .045))]
    detail_lib.scatter_plates(S1, tag, lambda r_: Vector((r_.uniform(-.20, .33), r_.uniform(-.11, .11), .5)), Vector((0, 0, -1)), lambda n: n.z > .5,
                              base, r1, True, 16, big, th=.0028, kinds=(('rect', .4), ('chamfer', .35), ('trap', .25)), tint=salvage, name='bigtop')
    for s_ in (1, -1):
        detail_lib.scatter_plates(S1, tag, lambda r_: Vector((r_.uniform(-.30, .30), s_ * .6, r_.uniform(ZC - .01, ZC + .06))), Vector((0, -s_, 0)),
                                  lambda n: abs(n.y) > .35, base, r1, True, 8, big, th=.0028, kinds=(('rect', .5), ('slant', .5)), tint=salvage, name=f'bigfl{s_}_')
    detail_lib.scatter_plates(S1, tag, lambda r_: Vector((r_.uniform(-.30, .30), r_.uniform(-.10, .10), -.6)), Vector((0, 0, 1)), lambda n: n.z < -.5,
                              base, r1, True, 6, big, th=.0030, kinds=(('rect', .5), ('chamfer', .5)), tint=salvage, name='bigbelly')
    probs = audit(shells, hardware); print('audit:', 'PASS' if not probs else 'FAIL'); [print('  ', p_) for p_ in probs]
    for o in hs_lib.PARTS:
        c = COL.get(o.name, STEEL); a = o.data.color_attributes.new('Col', 'FLOAT_COLOR', 'POINT')
        for d in a.data: d.color = (c[0], c[1], c[2], 1)
    kit = hs_lib.finish('C19v15_kit')
    return shells, kit

def color_material():
    m = bpy.data.materials.new('vcol'); m.use_nodes = True; nt = m.node_tree; b = nt.nodes['Principled BSDF']
    at = nt.nodes.new('ShaderNodeAttribute'); at.attribute_name = 'Col'; nt.links.new(at.outputs['Color'], b.inputs['Base Color'])
    b.inputs['Roughness'].default_value = .62; b.inputs['Metallic'].default_value = .35
    # engine glow: emission where the vertex colour is the glow red
    sep = nt.nodes.new('ShaderNodeSeparateColor'); nt.links.new(at.outputs['Color'], sep.inputs[0])
    gt = nt.nodes.new('ShaderNodeMath'); gt.operation = 'GREATER_THAN'; gt.inputs[1].default_value = .6; nt.links.new(sep.outputs[0], gt.inputs[0])
    em = nt.nodes.new('ShaderNodeMath'); em.operation = 'MULTIPLY'; em.inputs[1].default_value = 12.0; nt.links.new(gt.outputs[0], em.inputs[0])
    nt.links.new(at.outputs['Color'], b.inputs['Emission Color']); nt.links.new(em.outputs[0], b.inputs['Emission Strength'])
    return m

def export(shells, kit, pre):
    """the game converter (pixal_to_game.py) reads one mesh per file, so the three shell masses are joined first"""
    bpy.ops.object.select_all(action='DESELECT')
    for o in shells: o.select_set(True)
    bpy.context.view_layer.objects.active = shells[0]; bpy.ops.object.join(); shell = bpy.context.view_layer.objects.active; shell.name = 'C19v15_shell'
    try: bpy.ops.object.shade_smooth_by_angle(angle=math.radians(35), keep_sharp_edges=True)
    except Exception: pass
    for objs, nm in (([shell], pre + '_shell.glb'), ([kit], pre + '_kit.glb')):
        bpy.ops.object.select_all(action='DESELECT')
        for o in objs:
            o.select_set(True)
            try: o.data.color_attributes.active_color_name = 'Col'
            except Exception: pass
        bpy.context.view_layer.objects.active = objs[0]
        bpy.ops.export_scene.gltf(filepath=nm, export_format='GLB', use_selection=True, export_vertex_color='ACTIVE', export_all_vertex_colors=True)
    # reimport check: each file must come back with the same triangle count and finite positions
    for objs, nm in (([shell], pre + '_shell.glb'), ([kit], pre + '_kit.glb')):
        want = sum(len(p.vertices) - 2 for o in objs for p in o.data.polygons)
        before = set(bpy.context.scene.objects); bpy.ops.import_scene.gltf(filepath=nm); new = [o for o in set(bpy.context.scene.objects) - before if o.type == 'MESH']
        got = sum(len(p.vertices) - 2 for o in new for p in o.data.polygons); fin = all(all(math.isfinite(c) for c in v.co) for o in new for v in o.data.vertices)
        print('reimport', os.path.basename(nm), 'PASS' if got == want and fin else 'FAIL', want, got)
        for o in new: bpy.data.objects.remove(o)

if __name__ == '__main__':
    a = sys.argv[sys.argv.index('--') + 1:] if '--' in sys.argv else sys.argv[1:]
    pre = a[0]
    shells, kit = build()
    tris = sum(len(p.vertices) - 2 for o in shells + [kit] for p in o.data.polygons); print('tris', tris)
    bpy.ops.wm.save_as_mainfile(filepath=pre + '.blend')
    if '--export' in a: export(shells, kit, pre)
