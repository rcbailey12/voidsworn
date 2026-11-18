"""Measure issue 876 geometry against both earlier source revisions, inside Blender.

Usage: blender -b --python-exit-code 1 -P r292_geometry.py -- REPO RUN0.py RUN1.py OUT.json
Extract run 0 from 2ca44f51 and run 1 from ed59692f with git show first.
Only the current A17 outer support is changed. Evaluated world-space triangles,
materials, inside records, hardpoints, weapons and all other fittings are compared.
"""
import copy
import hashlib
import importlib.util
import json
import sys
from collections import Counter
from pathlib import Path

import bpy

repo, run0, run1, out = map(Path, sys.argv[sys.argv.index('--') + 1:])
sys.path.insert(0, str(repo / 'tools/blender/build_sheets'))
import variants


def snapshot(path):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    spec = importlib.util.spec_from_file_location('a17_revision', path)
    design = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(design)
    kit = variants.build(design)
    bpy.context.view_layer.update()
    graph = bpy.context.evaluated_depsgraph_get()
    objects = {}
    for interior, collection in ((False, kit.coll), (True, kit.cin)):
        for ob in collection.objects:
            if ob.type != 'MESH':
                continue
            evaluated = ob.evaluated_get(graph)
            mesh = evaluated.to_mesh()
            mesh.calc_loop_triangles()
            triangles = Counter()
            for tri in mesh.loop_triangles:
                vertices = tuple(tuple(round(float(v), 5) for v in ob.matrix_world @ mesh.vertices[i].co) for i in tri.vertices)
                material = mesh.materials[tri.material_index].name if mesh.materials else ''
                triangles[(material, vertices)] += 1
            evaluated.to_mesh_clear()
            objects[ob.name] = dict(interior=interior, triangles=triangles)
    return dict(source_sha256=hashlib.sha256(path.read_bytes()).hexdigest(), objects=objects,
                inside=copy.deepcopy(kit.inside), features=copy.deepcopy(kit.features),
                points=copy.deepcopy(kit.points), fitdata=copy.deepcopy(kit.fitdata))


def budget(snapshot):
    objects = snapshot['objects']
    exterior = sum(sum(o['triangles'].values()) for o in objects.values() if not o['interior'])
    interior = sum(sum(o['triangles'].values()) for o in objects.values() if o['interior'])
    return dict(exterior_triangles=exterior, interior_triangles=interior, total_triangles=exterior + interior,
                exterior_objects=sum(not o['interior'] for o in objects.values()),
                interior_objects=sum(o['interior'] for o in objects.values()),
                materials=len({mat for o in objects.values() for mat, vertices in o['triangles']}))


def compare(before, after, from_run):
    old, new = before['objects'], after['objects']
    changed = sorted(name for name in old.keys() | new.keys() if old.get(name) != new.get(name))
    vertices = []
    changed_interior = []
    for name in changed:
        a = old.get(name, dict(triangles=Counter(), interior=False))
        b = new.get(name, dict(triangles=Counter(), interior=False))
        if a['interior'] or b['interior']:
            changed_interior.append(name)
        for material, tri in (a['triangles'] - b['triangles']) + (b['triangles'] - a['triangles']):
            vertices.extend(tri)
    lo = [min(p[i] for p in vertices) for i in range(3)]
    hi = [max(p[i] for p in vertices) for i in range(3)]
    # Run 1 also cleared existing base-hull plates under the relocated ramp slits.
    # Their corners reach x -0.696. Run 2 changes only U2 and its attached roof plates.
    xmin = -0.8 if from_run == 0 else 0.5
    local = all(xmin <= x <= 2.95 and -2.3 <= y <= 2.3 and 0.3 <= z <= 1.76 for x, y, z in vertices)
    weapon_ids = {f['id'] for f in before['features'] if f['kind'] in ('gun', 'launcher')}
    weapon_meshes = [name for name in old if any(name.startswith(fid + '_') for fid in weapon_ids)]
    # Run 1 moved SL1 and SL2 from the blocked ramp face onto the flanks. Run 2 keeps them there.
    allowed_features = {'SL1', 'SL2'} if from_run == 0 else set()
    checks = dict(
        interior_meshes_unchanged=not changed_interior,
        inside_records_unchanged=before['inside'] == after['inside'],
        weapon_meshes_unchanged=all(old[name] == new.get(name) for name in weapon_meshes),
        weapons_unchanged=[f for f in before['features'] if f['id'] in weapon_ids] ==
                          [f for f in after['features'] if f['id'] in weapon_ids],
        hardpoints_unchanged=before['points'] == after['points'],
        weapon_fit_records_unchanged=[f for f in before['fitdata'] if f['kind'] in ('gun', 'launcher')] ==
                                     [f for f in after['fitdata'] if f['kind'] in ('gun', 'launcher')],
        other_features_unchanged=[f for f in before['features'] if f['id'] not in allowed_features] ==
                                 [f for f in after['features'] if f['id'] not in allowed_features],
        exterior_changes_local=local)
    return dict(result='PASS' if all(checks.values()) else 'FAIL', checks=checks,
                changed_objects=changed, changed_triangle_bounds=dict(lo=lo, hi=hi),
                triangle_delta=budget(after)['total_triangles'] - budget(before)['total_triangles'])


current = repo / 'tools/blender/build_sheets/ships/corsair_A17.py'
snapshots = [snapshot(path) for path in (run0, run1, current)]
proof = dict(stage='unpainted sheet', budgets=[budget(s) for s in snapshots],
             source_sha256=[s['source_sha256'] for s in snapshots],
             run0_to_run2=compare(snapshots[0], snapshots[2], 0),
             run1_to_run2=compare(snapshots[1], snapshots[2], 1))
out.write_text(json.dumps(proof, indent=1) + '\n')
print(json.dumps(proof, indent=1))
sys.exit(0 if all(proof[key]['result'] == 'PASS' for key in ('run0_to_run2', 'run1_to_run2')) else 1)
