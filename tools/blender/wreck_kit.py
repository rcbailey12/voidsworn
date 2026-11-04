"""Six reusable ship wrecks, built with the same parts as the ship kits.

Run with Blender 4.5: blender -b -P tools/blender/wreck_kit.py
Optional arguments after --: output directory. No downloaded assets or textures.
The runtime shader adds fine grime to the bevels, seams, ribs and fittings here.
Each export is centred and fits a unit sphere, so scale 3.8 never exceeds 7.6.
"""
import json
import math
import os
import random
import sys

import bpy
from mathutils import Vector
from mathutils.bvhtree import BVHTree

sys.path.insert(0, os.path.join(os.path.dirname(__file__), "hs"))
import hs_lib as kit

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
args = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
OUT = os.path.abspath(args[0]) if args else os.path.join(ROOT, "godot", "world", "wreckage")
HULL = (0.24, 0.28, 0.30, 0.0)
INNER = (0.085, 0.10, 0.115, 0.0)
FRAME = (0.16, 0.175, 0.18, 0.0)
EDGE = (0.38, 0.39, 0.37, 0.0)
RUST = (0.22, 0.095, 0.038, 0.0)
PAINT = (0.34, 0.18, 0.055, 0.0)
TORN = (0.055, 0.037, 0.026, 0.8)


def colour(obj, col):
    attr = obj.data.color_attributes.new(name="Color", type="FLOAT_COLOR", domain="CORNER")
    rng = random.Random(obj.name)
    for face in obj.data.polygons:
        tone = rng.uniform(0.87, 1.10)
        for li in face.loop_indices:
            attr.data[li].color = (*[c * tone for c in col[:3]], col[3])
    obj.data.color_attributes.active_color = attr
    return obj


def box(name, c, s, col=HULL, rot=(0, 0, 0), bevel=0.004):
    return colour(kit.box(name, c, s, rot=rot, bevel=bevel), col)


def cyl(name, c, r, length, col=FRAME, axis="Z", r2=None, seg=32):
    return colour(kit.cyl(name, c, r, length, axis=axis, r2=r2, seg=seg), col)


def beam(name, a, b, width=0.045, depth=None, col=FRAME):
    delta = Vector(b) - Vector(a)
    obj = box(name, (0, 0, 0), (width, depth or width, delta.length), col)
    obj.location = (Vector(a) + Vector(b)) * 0.5
    obj.rotation_euler = delta.to_track_quat("Z", "Y").to_euler()
    bpy.context.view_layer.objects.active = obj
    obj.select_set(True)
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=False)
    obj.select_set(False)
    return obj


def bolts(a, b, n=7):
    for j in range(n):
        p = Vector(a).lerp(Vector(b), j / max(1, n - 1))
        cyl("fastener", p, 0.012, 0.015, EDGE, seg=12)


def vent(c, n=7):
    box("vent bed", c, (0.32, 0.25, 0.026), INNER)
    for j in range(n):
        box("vent louvre", (c[0], c[1] - 0.10 + j * 0.20 / (n - 1), c[2] + 0.022),
            (0.28, 0.014, 0.024), FRAME)


def fragment():
    # Faceted armour shell, with torn ends and transverse ribs on its inside.
    rng = random.Random(60)
    for j in range(7):
        y = (j - 3) * 0.17
        z = 0.11 * (y / 0.51) ** 2
        length = rng.uniform(1.45, 1.82)
        centre_x = rng.uniform(-0.07, 0.07)
        box("torn armour strip", (centre_x, y, z),
            (length, 0.169, 0.070), HULL, rot=(y * 0.36, 0, 0))
        for x in (-0.46, 0.23):
            box("armour overlay", (x, y, z + 0.052), (0.61, 0.15, 0.035),
                PAINT if j == 2 else HULL, rot=(y * 0.36, 0, 0))
        box("fracture face", (centre_x + length * 0.5 - 0.008, y, z), (0.028, 0.16, 0.072), TORN)
    for x in (-0.57, 0.08, 0.57):
        for j in range(6):
            y0, y1 = (j - 3) * 0.17, (j - 2) * 0.17
            beam("inner rib", (x, y0, 0.11 * (y0 / 0.51) ** 2 - 0.045),
                 (x, y1, 0.11 * (y1 / 0.51) ** 2 - 0.045), 0.065, 0.12)
    beam("stringer", (-0.78, 0, -0.075), (0.70, 0, -0.075), 0.07)
    bolts((-0.65, -0.35, 0.08), (0.65, -0.35, 0.08))
    vent((0.10, 0.0, 0.076))


def frame():
    pts = []
    for j in range(19):
        a = math.radians(-35 + j * 14)
        pts.append(Vector((0.80 * math.cos(a), 0.80 * math.sin(a), 0)))
    for j, (a, b) in enumerate(zip(pts, pts[1:])):
        beam("frame web", a, b, 0.085, 0.15)
        for z in (-0.10, 0.10):
            beam("frame flange", a + Vector((0, 0, z)), b + Vector((0, 0, z)), 0.16, 0.04)
        if j % 3 == 0:
            cyl("rib fastener", a + Vector((0, 0, 0.127)), 0.021, 0.018, EDGE, seg=12)
    beam("bent snapped end", pts[-1], pts[-1] + Vector((0.23, -0.10, 0.24)), 0.09, 0.18, TORN)
    beam("bulkhead spoke", pts[6], pts[6] * 0.20, 0.09, 0.14)
    box("attached armour", (-0.05, 0.73, 0.14), (0.57, 0.25, 0.06), HULL)
    bolts((-0.24, 0.73, 0.176), (0.18, 0.73, 0.176), 5)


def truss():
    rails = [(0.0, 0.23), (-0.23, -0.17), (0.23, -0.17)]
    for y, z in rails:
        beam("longeron", (-0.92, y, z), (0.86, y, z), 0.055)
    for j in range(5):
        x0, x1 = -0.91 + j * 0.35, -0.56 + j * 0.35
        for i in range(3):
            y0, z0 = rails[i]
            y1, z1 = rails[(i + 1) % 3]
            beam("lattice diagonal", (x0, y0, z0), (x1, y1, z1), 0.027)
            beam("cross brace", (x0, y0, z0), (x0, y1, z1), 0.035)
    beam("broken spar", (0.80, 0.0, 0.23), (1.03, 0.06, 0.35), 0.055, col=TORN)
    box("cable tray", (-0.12, 0.0, -0.20), (1.40, 0.28, 0.045), INNER)
    for y in (-0.07, 0.0, 0.07):
        beam("exposed cable", (-0.75, y, -0.23), (0.74, y, -0.23), 0.018, col=RUST)
    box("junction box", (-0.42, 0, -0.31), (0.25, 0.22, 0.18), HULL)
    box("junction lid", (-0.42, 0, -0.41), (0.28, 0.25, 0.025), PAINT)


def section():
    box("deck", (0, 0, -0.25), (1.80, 1.12, 0.10), INNER)
    for x in (-0.62, 0, 0.62):
        for y in (-0.28, 0.28):
            box("deck plate", (x, y, -0.185), (0.58, 0.52, 0.026), HULL)
    box("standing wall", (0, -0.54, 0.13), (1.80, 0.10, 0.72), HULL)
    for x in (-0.70, -0.18, 0.42, 0.78):
        box("wall rib", (x, -0.46, 0.13), (0.06, 0.12, 0.70), FRAME)
        box("roof stub", (x, -0.46, 0.52), (0.06, 0.24, 0.10), TORN)
    for y in (-0.40, 0.40):
        box("bulkhead jamb", (-0.86, y, 0.10), (0.10, 0.30, 0.68), FRAME)
    box("bulkhead lintel", (-0.86, 0, 0.41), (0.10, 1.10, 0.12), FRAME)
    for x in (-0.69, -0.12, 0.49):
        box("broken wall stub", (x, 0.50, -0.12), (0.09, 0.09, 0.33), TORN)
    vent((0.33, 0.06, -0.166))
    beam("utility pipe", (-0.75, -0.39, -0.08), (0.80, -0.39, -0.08), 0.045, col=RUST)
    bolts((-0.70, -0.52, 0.495), (0.70, -0.52, 0.495))


def bell():
    # An open, thick-walled nozzle. The dark throat is recessed, never a solid cone.
    seg = 64
    rings = [(0.32, -0.66), (0.37, -0.37), (0.49, 0.05), (0.70, 0.57)]
    verts, faces = [], []
    for inset in (0, 0.045):
        for r, z in rings:
            for j in range(seg):
                a = j * math.tau / seg
                # One damaged lip, with the rest still recognisable as a bell.
                damage = 0.11 * math.sin(a * 7) if z > 0.5 and 0.2 < a < 1.2 else 0
                verts.append(((r - inset) * math.cos(a), (r - inset) * math.sin(a), z - damage))
    for shell in range(2):
        offset = shell * len(rings) * seg
        for k in range(len(rings) - 1):
            for j in range(seg):
                a, b = offset + k * seg + j, offset + k * seg + (j + 1) % seg
                face = (a, b, b + seg, a + seg)
                faces.append(tuple(reversed(face)) if shell else face)
    for k in (0, len(rings) - 1):
        for j in range(seg):
            a, b = k * seg + j, k * seg + (j + 1) % seg
            faces.append((a, a + len(rings) * seg, b + len(rings) * seg, b))
    mesh = bpy.data.meshes.new("nozzle")
    mesh.from_pydata(verts, [], faces)
    mesh.update()
    obj = bpy.data.objects.new("open engine bell", mesh)
    bpy.context.collection.objects.link(obj)
    kit.PARTS.append(obj)
    colour(obj, HULL)
    cyl("throat back", (0, 0, -0.64), 0.32, 0.04, INNER)
    cyl("mount flange", (0, 0, -0.72), 0.43, 0.09, FRAME)
    cyl("severed fuel neck", (0, 0, -0.85), 0.23, 0.22, TORN)
    for j in range(16):
        a = j * math.tau / 16
        beam("coolant stiffener", (0.36 * math.cos(a), 0.36 * math.sin(a), -0.50),
             (0.68 * math.cos(a), 0.68 * math.sin(a), 0.54), 0.025, col=FRAME)
        cyl("mount bolt", (0.37 * math.cos(a), 0.37 * math.sin(a), -0.78), 0.022, 0.035, EDGE, seg=12)


def sponson():
    # Detached ship battery, two barrels on a visible bearing and armoured saddle.
    box("sponson armour", (0.20, 0, -0.18), (1.02, 0.94, 0.40), HULL, bevel=0.035)
    box("torn mounting plate", (0.27, 0, -0.42), (1.15, 1.02, 0.08), TORN)
    cyl("bearing", (0.17, 0, 0.05), 0.35, 0.16, FRAME)
    box("gun cowling", (0.04, 0, 0.20), (0.79, 0.68, 0.28), HULL, bevel=0.04)
    for y in (-0.20, 0.20):
        cyl("barrel", (-0.68, y, 0.20), 0.070, 0.83, FRAME, axis="X")
        cyl("recoil collar", (-0.37, y, 0.20), 0.105, 0.20, HULL, axis="X")
        cyl("muzzle collar", (-1.07, y, 0.20), 0.095, 0.07, EDGE, axis="X")
        cyl("dark muzzle", (-1.108, y, 0.20), 0.054, 0.006, INNER, axis="X")
    vent((0.24, 0, 0.345))
    for y in (-0.42, 0.42):
        box("paint band", (0.28, y, 0.032), (0.60, 0.11, 0.025), PAINT)
        bolts((-0.20, y, 0.025), (0.62, y, 0.025), 7)
    # Audit the built meshes, so changing a fitting's pose cannot bypass this.
    # Bow is -X in the ship-kit frame; both barrels must clear the cowling.
    barrels = [o for o in kit.PARTS if o.name.startswith("barrel")]
    muzzles = [o for o in kit.PARTS if o.name.startswith("dark muzzle")]
    centres = lambda o: sum((v.co for v in o.data.vertices), Vector()) / len(o.data.vertices)
    cowling = next(o for o in kit.PARTS if o.name == "gun cowling")
    front = min(v.co.x for v in cowling.data.vertices)
    assert len(barrels) == len(muzzles) == 2
    for barrel, muzzle in zip(barrels, muzzles):
        base, tip = centres(barrel), centres(muzzle)
        assert (tip - base).normalized().x < -0.99 and tip.x < front
    assert abs(centres(barrels[0]).y + centres(barrels[1]).y) < 0.00001


def audit_parts():
    # Every fitting must touch another part. Bounding boxes shortlist neighbours;
    # BVH intersection or a close surface catches floating rivets and decorations.
    bpy.context.view_layer.update()
    deps = bpy.context.evaluated_depsgraph_get()
    entries = []
    for obj in kit.PARTS:
        mesh = obj.evaluated_get(deps).to_mesh()
        points = [obj.matrix_world @ v.co for v in mesh.vertices]
        polys = [tuple(p.vertices) for p in mesh.polygons]
        tree = BVHTree.FromPolygons(points, polys)
        lo = Vector(tuple(min(v[i] for v in points) for i in range(3)))
        hi = Vector(tuple(max(v[i] for v in points) for i in range(3)))
        entries.append((obj.name, tree, points, lo, hi))
        obj.evaluated_get(deps).to_mesh_clear()
    for i, (name, tree, points, lo, hi) in enumerate(entries):
        attached = False
        for j, (_, other, _, olo, ohi) in enumerate(entries):
            if i == j or any(hi[k] + 0.0015 < olo[k] or ohi[k] + 0.0015 < lo[k] for k in range(3)):
                continue
            if tree.overlap(other) or any(other.find_nearest(p)[3] < 0.0015 for p in points):
                attached = True
                break
        if not attached:
            raise RuntimeError("Floating wreck fitting: " + name)


def export(name, builder):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    kit.PARTS.clear()
    builder()
    audit_parts()
    obj = kit.finish(name)
    # Recentre on the bounds, then constrain the whole mesh, including fittings.
    low = Vector(tuple(min(v.co[i] for v in obj.data.vertices) for i in range(3)))
    high = Vector(tuple(max(v.co[i] for v in obj.data.vertices) for i in range(3)))
    centre = (low + high) * 0.5
    radius = max((v.co - centre).length for v in obj.data.vertices)
    for v in obj.data.vertices:
        v.co = (v.co - centre) / radius
    obj.location = (0, 0, 0)
    obj.data.calc_loop_triangles()
    triangles = len(obj.data.loop_triangles)
    path = os.path.join(OUT, name + ".glb")
    bpy.ops.export_scene.gltf(filepath=path, export_format="GLB", use_selection=True,
                              export_materials="NONE", export_vertex_color="ACTIVE",
                              export_all_vertex_colors=True, export_animations=False)
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    bpy.ops.import_scene.gltf(filepath=path)
    imported = 0
    for piece in bpy.context.scene.objects:
        if piece.type == "MESH":
            piece.data.calc_loop_triangles()
            imported += len(piece.data.loop_triangles)
            assert piece.data.color_attributes, "Missing vertex paint"
    assert imported == triangles, (name, imported, triangles)
    print("[wreck]", name, triangles, "triangles; attachment and reimport checks PASS")
    return {"name": name, "triangles": triangles, "radius": 1.0}


os.makedirs(OUT, exist_ok=True)
manifest = [export(name, builder) for name, builder in [
    ("hull_fragment", fragment), ("broken_frame", frame), ("truss", truss),
    ("hull_section", section), ("engine_bell", bell), ("weapon_sponson", sponson)]]
with open(os.path.join(OUT, "kit.json"), "w", encoding="utf-8") as stream:
    json.dump({"pieces": manifest, "source": "tools/blender/wreck_kit.py"}, stream, indent=2)
    stream.write("\n")
