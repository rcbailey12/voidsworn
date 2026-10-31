"""Blender-only diagnostic importer. Never saves or exports a replacement asset."""
import argparse
import hashlib
import html
import json
import math
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from qa_math import frame, direction_status, mirror_error
import bpy
from mathutils import Vector


def arguments():
    p = argparse.ArgumentParser()
    p.add_argument("--asset")
    p.add_argument("--out", required=True)
    p.add_argument("--forward", required=True)
    p.add_argument("--up", required=True)
    p.add_argument("--render", action="store_true")
    p.add_argument("--self-test", action="store_true")
    return p.parse_args(sys.argv[sys.argv.index("--") + 1:])


def fixture():
    bpy.ops.mesh.primitive_cube_add()
    hull = bpy.context.object
    hull.name = "qa_fixture_hull"
    hull.scale = (3, 1, 1)
    hull["qa_role"] = "hull"
    bpy.ops.mesh.primitive_cube_add(location=(0, 2, 0))
    gun = bpy.context.object
    gun.name = "qa_fixture_backward_weapon"
    gun.scale = (0.8, 0.2, 0.2)
    gun["qa_role"] = "weapon"
    gun["qa_forward"] = [-1.0, 0.0, 0.0]
    mat = bpy.data.materials.new("qa_missing_texture")
    mat.use_nodes = True
    node = mat.node_tree.nodes.new("ShaderNodeTexImage")
    image = bpy.data.images.new("qa_missing", 16, 16)
    image.source = "FILE"
    image.filepath = str(Path(bpy.app.tempdir) / "VOIDSWORN_INTENTIONALLY_MISSING_TEXTURE.png")
    node.image = image
    gun.data.materials.append(mat)


def inspect(meshes, f, side):
    issues, objects, corners, pairs = [], [], [], {}
    for o in meshes:
        points = [o.matrix_world @ Vector(v) for v in o.bound_box]
        corners.extend(points)
        missing_slots = sum(1 for poly in o.data.polygons if poly.material_index >= len(o.material_slots) or o.material_slots[poly.material_index].material is None)
        nonfinite = sum(1 for v in o.data.vertices if not all(math.isfinite(x) for x in v.co))
        degenerate = sum(1 for p in o.data.polygons if p.area <= 1e-14)
        if missing_slots:
            issues.append({"object": o.name, "kind": "UNASSIGNED_FACES", "count": missing_slots, "severity": "REVIEW"})
        if nonfinite:
            issues.append({"object": o.name, "kind": "NONFINITE_VERTICES", "count": nonfinite, "severity": "ERROR"})
        if degenerate:
            issues.append({"object": o.name, "kind": "ZERO_AREA_FACES", "count": degenerate, "severity": "REVIEW"})
        if o.matrix_world.determinant() < 0:
            issues.append({"object": o.name, "kind": "NEGATIVE_DETERMINANT", "severity": "REVIEW"})
        scales = [abs(x) for x in o.matrix_world.to_scale()]
        if min(scales) < 1e-12 or max(scales) - min(scales) > max(scales) * 1e-5:
            issues.append({"object": o.name, "kind": "NONUNIFORM_OR_ZERO_SCALE", "scale": scales, "severity": "REVIEW"})
        textured = False
        for slot in o.material_slots:
            mat = slot.material
            if mat and mat.use_nodes:
                for node in mat.node_tree.nodes:
                    if node.type != "TEX_IMAGE":
                        continue
                    textured = True
                    image = node.image
                    if image is None:
                        issues.append({"object": o.name, "kind": "EMPTY_IMAGE_NODE", "severity": "REVIEW"})
                    elif image.source == "FILE" and not image.packed_file and not Path(bpy.path.abspath(image.filepath)).is_file():
                        issues.append({"object": o.name, "kind": "MISSING_TEXTURE_FILE", "image": image.name, "severity": "ERROR"})
        if textured and not o.data.uv_layers:
            issues.append({"object": o.name, "kind": "TEXTURED_WITHOUT_UV", "severity": "REVIEW"})
        role = o.get("qa_role", "UNTAGGED")
        if role == "weapon":
            local = o.get("qa_forward")
            if local is None or len(local) != 3:
                issues.append({"object": o.name, "kind": "WEAPON_AXIS_UNVERIFIED", "severity": "REVIEW"})
            else:
                vector = o.matrix_world.to_3x3() @ Vector(local)
                status = direction_status(vector, f)
                if status != "FORWARD_OR_SIDE":
                    issues.append({"object": o.name, "kind": "WEAPON_" + status, "severity": "REVIEW"})
        if o.get("qa_pair"):
            pairs.setdefault(str(o["qa_pair"]), []).append(o)
        objects.append({"name": o.name, "role": role, "vertices": len(o.data.vertices), "faces": len(o.data.polygons), "materialSlots": len(o.material_slots), "uvLayers": len(o.data.uv_layers)})
    low = Vector(tuple(min(v[i] for v in corners) for i in range(3)))
    high = Vector(tuple(max(v[i] for v in corners) for i in range(3)))
    center = (low + high) / 2
    span = max(high - low)
    if not math.isfinite(span) or span <= 1e-12:
        raise ValueError("Asset has invalid or empty world bounds")
    for key, members in pairs.items():
        if len(members) != 2:
            issues.append({"pair": key, "kind": "PAIR_MEMBER_COUNT", "count": len(members), "severity": "REVIEW"})
        else:
            error = mirror_error(members[0].matrix_world.translation, members[1].matrix_world.translation, side, center)
            if error > span * 0.01:
                issues.append({"pair": key, "kind": "DECLARED_PAIR_ASYMMETRY", "relativeError": error / span, "severity": "REVIEW"})
    return {"objects": objects, "issues": issues, "bounds": {"min": list(low), "max": list(high)}, "untaggedObjects": sum(o["role"] == "UNTAGGED" for o in objects)}, center, span


def render_grid(meshes, center, span, forward, up, side, out):
    scene = bpy.context.scene
    try:
        scene.render.engine = "BLENDER_EEVEE_NEXT"
    except TypeError:
        scene.render.engine = "BLENDER_EEVEE"
    scene.render.resolution_x = scene.render.resolution_y = 768
    scene.render.resolution_percentage = 100
    scene.render.image_settings.file_format = "PNG"
    scene.render.film_transparent = False
    scene.view_settings.view_transform = "Standard"
    scene.view_settings.exposure = 0
    scene.view_settings.gamma = 1
    world = bpy.data.worlds.new("QA_WORLD")
    world.use_nodes = True
    world.node_tree.nodes["Background"].inputs[0].default_value = (0.04, 0.04, 0.04, 1)
    world.node_tree.nodes["Background"].inputs[1].default_value = 0.5
    scene.world = world
    for name, offset, energy in [("KEY", (1, -2, 3), 600), ("FILL", (-2, 2, 1), 250), ("RIM", (-2, -1, 2), 450)]:
        data = bpy.data.lights.new("QA_" + name, "AREA")
        data.energy = energy * span * span
        data.shape = "DISK"
        data.size = span * 1.5
        lamp = bpy.data.objects.new(data.name, data)
        scene.collection.objects.link(lamp)
        lamp.location = center + Vector(offset) * span
        lamp.rotation_euler = (center - lamp.location).to_track_quat("-Z", "Y").to_euler()
    data = bpy.data.cameras.new("QA_CAMERA")
    camera = bpy.data.objects.new(data.name, data)
    scene.collection.objects.link(camera)
    scene.camera = camera
    data.type = "ORTHO"
    data.clip_start = span / 10000
    data.clip_end = span * 100
    clay = bpy.data.materials.new("QA_CLAY")
    clay.diffuse_color = (0.45, 0.45, 0.45, 1)
    clay.use_nodes = True
    clay.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value = clay.diffuse_color
    clay.node_tree.nodes["Principled BSDF"].inputs["Roughness"].default_value = 0.7
    projections = [v.dot(Vector(forward)) for o in meshes for v in [o.matrix_world @ Vector(b) for b in o.bound_box]]
    length = max(projections) - min(projections)
    images = []
    for material in ["painted", "clay"]:
        scene.view_layers[0].material_override = clay if material == "clay" else None
        for region, offset in [("bow", 1 / 3), ("midship", 0), ("stern", -1 / 3)]:
            target = center + Vector(forward) * (length * offset)
            for view, direction in [("top", up), ("side", side), ("below", tuple(-x for x in up))]:
                camera.location = target + Vector(direction) * span * 3
                camera.rotation_euler = (target - camera.location).to_track_quat("-Z", "Y").to_euler()
                data.ortho_scale = span * 0.65
                name = material + "_" + region + "_" + view + ".png"
                scene.render.filepath = str(out / name)
                bpy.ops.render.render(write_still=True)
                images.append({"material": material, "region": region, "view": view, "file": name})
    return images


def main():
    args = arguments()
    f, u, side = frame(args.forward, args.up)
    out = Path(args.out).resolve()
    if (out / "report.json").exists():
        raise ValueError("Output already contains a report; select a new directory")
    out.mkdir(parents=True, exist_ok=True)
    bpy.ops.wm.read_factory_settings(use_empty=True)
    source = None
    if args.self_test:
        fixture()
    else:
        source = Path(args.asset or "").resolve()
        if source.suffix.lower() not in [".glb", ".gltf"] or not source.is_file():
            raise ValueError("Choose an existing GLB or glTF asset")
        bpy.ops.import_scene.gltf(filepath=str(source))
    # Only imported meshes are measured. Rigs/lights/cameras from the asset do not influence diagnostic lighting.
    meshes = [o for o in bpy.context.scene.objects if o.type == "MESH"]
    if not meshes:
        raise ValueError("No mesh objects imported")
    for o in list(bpy.context.scene.objects):
        if o.type in ["LIGHT", "CAMERA"]:
            bpy.data.objects.remove(o, do_unlink=True)
    report, center, span = inspect(meshes, f, side)
    report.update({"status": "DIAGNOSTIC_ONLY_REVIEW_REQUIRED", "blender": bpy.app.version_string, "source": str(source) if source else "GENERATED_SELF_TEST", "sourceSHA256": hashlib.sha256(source.read_bytes()).hexdigest() if source else None, "forward": args.forward, "up": args.up, "images": [], "limits": ["No game-renderer or GPU-performance acceptance.", "Untagged weapon direction, mounting, hull penetration and faction grammar require visual review.", "Pair checks use declared qa_pair tags; Corsair asymmetry is a review note.", "Degenerate/nonuniform/UV flags are observations, not automatic cleanup instructions.", "glTF dependency images are inspected after import; source hash covers the primary file only."]})
    if args.self_test:
        kinds = {x["kind"] for x in report["issues"]}
        assert "WEAPON_BACKWARD" in kinds and "MISSING_TEXTURE_FILE" in kinds and "UNASSIGNED_FACES" in kinds
        report["selfTest"] = "PASS"
    if args.render:
        report["images"] = render_grid(meshes, center, span, f, u, side, out)
        assert len(report["images"]) == 18 and all((out / x["file"]).is_file() for x in report["images"])
    if source and hashlib.sha256(source.read_bytes()).hexdigest() != report["sourceSHA256"]:
        raise RuntimeError("Input changed during inspection")
    (out / "report.json").write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    cards = "".join('<figure><img src="' + html.escape(x["file"]) + '"><figcaption>' + html.escape(x["material"] + " / " + x["region"] + " / " + x["view"]) + '<br><label>Manual verdict <select><option>UNREVIEWED</option><option>Clean</option><option>Rebuild by hand</option></select></label><textarea placeholder="Part and reason; print to preserve notes"></textarea></figcaption></figure>' for x in report["images"])
    page = '<!doctype html><html><meta charset="utf-8"><title>Voidsworn diagnostic sheet</title><style>body{font:16px system-ui;background:#eee;color:#111;margin:24px}.grid{display:grid;grid-template-columns:repeat(3,1fr);gap:12px}figure{margin:0;background:white;padding:8px}img{width:100%}textarea{display:block;width:95%;min-height:70px}pre{white-space:pre-wrap}@media print{textarea{border:0}}</style><h1>Diagnostic sheet: manual review required</h1><p>Studio renders support inspection. In-game screenshots at battle zoom remain the visual acceptance test. No production model has been changed. Forward ' + html.escape(args.forward) + ', up ' + html.escape(args.up) + ' in imported Blender space.</p><p>Notes are not saved automatically. Print to PDF to preserve completed verdicts.</p><div class="grid">' + cards + '</div><h2>Observations</h2><pre>' + html.escape(json.dumps(report, indent=2)) + '</pre></html>'
    (out / "contact_sheet.html").write_text(page, encoding="utf-8")
    print("VOIDSWORN_QA_COMPLETE " + str(out / "report.json"))


if __name__ == "__main__":
    main()
