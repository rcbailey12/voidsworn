"""Issue 861: rebuild A20 and capture its hangar cheeks with Cycles CPU.

blender -b -t 6 -P render_R283.py -- corsair_A20 TEMP_OUTPUT render
SHIP_FILE may name the unmodified design for the before captures.
All raw renders and the blend stay in TEMP_OUTPUT, outside the repository.
"""
import hashlib
import json
import os
from pathlib import Path

import bpy
from bpy_extras.object_utils import world_to_camera_view
from mathutils import Vector

REPO = Path(__file__).resolve().parents[4]
BUILD = REPO / 'tools/blender/build_sheets/build.py'
os.environ['SHEET_DEVICE'] = 'CPU'
scope = dict(__file__=str(BUILD), __name__='__main__')
exec(compile(BUILD.read_text(encoding='utf-8'), str(BUILD), 'exec'), scope)
K, ship, out = scope['K'], scope['ship'], Path(scope['OUT'])
dg = bpy.context.evaluated_depsgraph_get()
objects, counts = {}, dict(outside=0, inside=0)
for coll, role in ((K.coll, 'outside'), (K.cin, 'inside')):
    for obj in coll.objects:
        if obj.type != 'MESH':
            continue
        evaluated = obj.evaluated_get(dg)
        mesh = evaluated.to_mesh()
        mesh.calc_loop_triangles()
        counts[role] += len(mesh.loop_triangles)
        # Compare the built geometry, transforms and materials, including all insides.
        data = dict(vertices=[tuple(v.co) for v in mesh.vertices],
                    faces=[tuple(p.vertices) for p in mesh.polygons],
                    materials=[m.name for m in mesh.materials],
                    matrix=[tuple(row) for row in obj.matrix_world])
        objects[obj.name] = dict(role=role, triangles=len(mesh.loop_triangles),
                                sha256=hashlib.sha256(json.dumps(data).encode()).hexdigest())
        evaluated.to_mesh_clear()
record = dict(class_length=ship.LENGTH, model_length=scope['MODEL_LEN'],
              triangles=counts, objects=objects, fit_counts=scope['FIT']['counts'],
              exterior_meshes=sum(o.type == 'MESH' for o in K.coll.objects),
              exterior_materials=len({m.name for o in K.coll.objects if o.type == 'MESH' for m in o.data.materials}),
              device=bpy.context.scene.cycles.device)
(out / 'R283_geometry.json').write_text(json.dumps(record, indent=1) + '\n', encoding='utf-8')
if scope['MODE'] == 'render':
    sc = bpy.context.scene
    fc = json.loads((REPO / 'tools/blender/build_sheets/ships/corsair_A20_camera.json').read_text())
    for side, name in ((1, 'port'), (-1, 'starboard')):
        # Starboard uses the mirrored concept camera. Port is the actual concept camera.
        camera = scope['look_cam']('cheek_' + name, fc['az'] * side, fc['el'], fc['dist'],
                                   fc['mm'], tuple(fc['res']), fc['target'],
                                   fc.get('roll', 0) * side,
                                   (-fc.get('sx', 0) * side, -fc.get('sy', 0)))
        bpy.context.view_layer.update()
        corners = [world_to_camera_view(sc, camera, Vector((x, side * y, z)))
                   for x in (2.8, 6.0) for y in (1.6, 4.25) for z in (-1.15, 1.25)]
        # Crop a sub-frustum. The camera location, perspective and light never change.
        sc.render.use_border = True
        sc.render.use_crop_to_border = True
        sc.render.border_min_x = max(0.0, min(p.x for p in corners) - 0.015)
        sc.render.border_max_x = min(1.0, max(p.x for p in corners) + 0.015)
        sc.render.border_min_y = max(0.0, min(p.y for p in corners) - 0.015)
        sc.render.border_max_y = min(1.0, max(p.y for p in corners) + 0.015)
        scope['render'](camera, (3840, 2560), str(out / ('cheek_' + name + '.png')))
        sc.render.use_border = False
        sc.render.use_crop_to_border = False
print('R283 geometry: %s; length %.8f; triangles %s' % (out, record['model_length'], counts), flush=True)
