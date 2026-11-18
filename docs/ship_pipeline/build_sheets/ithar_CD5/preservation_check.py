"""Run in Blender: -b --python-exit-code 1 -P THIS_FILE -- OUT.json.

Build run 2 and the current design, then compare all eight optical machine groups.
The baseline is read from the local Git object, without switching or changing Git.
"""
import ast
import hashlib
import importlib.util
import json
from pathlib import Path
import subprocess
import sys
import types

import bpy

sys.dont_write_bytecode = True
ROOT = Path(__file__).resolve().parents[4]
DESIGN = 'tools/blender/build_sheets/ships/ithar_CD5.py'
BASELINE = '23f61877'
sys.path[:0] = [str(ROOT / 'tools/blender/build_sheets'), str(ROOT / 'tools/recipe')]
import variants


def serial(value):
    if isinstance(value, (str, float, int, bool)) or value is None:
        return value
    try:
        return [serial(v) for v in value]
    except TypeError:
        return str(value)


def shader(material):
    tree = material.node_tree
    return dict(name=material.name, nodes=[
        dict(name=n.name, type=n.bl_idname, attribute=getattr(n, 'attribute_name', None),
             inputs=[(p.identifier, serial(p.default_value)) for p in n.inputs if hasattr(p, 'default_value')],
             ramp=[(e.position, list(e.color)) for e in n.color_ramp.elements] if hasattr(n, 'color_ramp') else None)
        for n in tree.nodes], links=[(l.from_node.name, l.from_socket.identifier,
                                     l.to_node.name, l.to_socket.identifier) for l in tree.links])


def snapshot(module):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    K = variants.build(module)
    bpy.context.view_layer.update()
    groups = {}
    for fid in ('L1', 'L2', 'O1', 'O2', 'O3', 'E1', 'E2', 'E3'):
        meshes = []
        for o in sorted(K.coll.objects, key=lambda ob: ob.name):
            if o.type != 'MESH' or o.get('grp') != fid:
                continue
            meshes.append(dict(name=o.name, parent=o.parent.name if o.parent else None,
                               role=o.get('role'), world_vertices=[list(o.matrix_world @ v.co) for v in o.data.vertices],
                               faces=[list(p.vertices) for p in o.data.polygons],
                               material_indices=[p.material_index for p in o.data.polygons],
                               materials=[shader(m) for m in o.data.materials]))
        record = dict(meshes=meshes, features=[f for f in K.features if f['id'] == fid],
                      fit=[f for f in K.fitdata if f['id'] == fid])
        groups[fid] = dict(sha256=hashlib.sha256(json.dumps(record, sort_keys=True).encode()).hexdigest(),
                           meshes=len(meshes), vertices=sum(len(m['world_vertices']) for m in meshes))
    hull = next(o for o in K.coll.objects if o.name == 'ithar_CD5_flowing_skin')
    z = [v.co.z for v in hull.data.vertices]
    return dict(groups=groups, skin_depth=max(z) - min(z))


old_source = subprocess.check_output(['git', 'show', BASELINE + ':' + DESIGN], cwd=ROOT).decode('utf-8')
old = types.ModuleType('cd5_run2')
old.__file__ = str(ROOT / DESIGN)
sys.modules[old.__name__] = old
exec(compile(old_source, old.__file__, 'exec'), old.__dict__)
spec = importlib.util.spec_from_file_location('cd5_run3', ROOT / DESIGN)
new = importlib.util.module_from_spec(spec)
sys.modules[new.__name__] = new
spec.loader.exec_module(new)
baseline = snapshot(old)
current = snapshot(new)
rows = {fid: dict(identical=baseline['groups'][fid] == current['groups'][fid],
                   run2=baseline['groups'][fid], run3=current['groups'][fid]) for fid in baseline['groups']}


def lance_ast(source):
    return ast.dump(next(n for n in ast.parse(source).body if isinstance(n, ast.FunctionDef) and n.name == 'lance'),
                    include_attributes=False)


manifest_path = 'docs/ship_pipeline/build_sheets/ithar_CD5/manifest.json'
old_manifest = json.loads(subprocess.check_output(['git', 'show', BASELINE + ':' + manifest_path], cwd=ROOT))
new_manifest = json.loads((ROOT / manifest_path).read_text())
fields = ('code', 'game_ship', 'cls', 'length_world', 'parts', 'masses', 'break_pieces',
          'whole_optics', 'hull_fractures', 'insides', 'turret_marking', 'stage', 'paint_stack')
manifest = {key: old_manifest[key] == new_manifest[key] for key in fields}
lance_ok = lance_ast(old_source) == lance_ast((ROOT / DESIGN).read_text())
result = dict(result='PASS' if all(r['identical'] for r in rows.values()) and all(manifest.values()) and lance_ok else 'FAIL',
              baseline_commit=subprocess.check_output(['git', 'rev-parse', BASELINE], cwd=ROOT).decode().strip(),
              design_sha256=hashlib.sha256((ROOT / DESIGN).read_bytes()).hexdigest(),
              compared='World vertices, faces, parents, materials and full shader inputs, feature and fit records',
              lance_function_ast_identical=lance_ok, optical_groups=rows, preserved_manifest_fields=manifest,
              skin_depth=dict(run2=baseline['skin_depth'], run3=current['skin_depth']))
out = Path(sys.argv[sys.argv.index('--') + 1])
out.write_text(json.dumps(result, indent=2) + '\n')
print(result['result'], 'CD5 run 2 optical geometry/materials/records and manifest layout')
if result['result'] != 'PASS':
    raise RuntimeError(json.dumps(result, indent=2))
