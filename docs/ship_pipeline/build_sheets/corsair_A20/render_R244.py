"""CPU-only R244 sheet and comparison captures.

blender -b -t 6 -P render_R244.py -- corsair_A20 TEMP_OUTPUT render
Set SHIP_FILE to an earlier design file for the before captures.
The shared sheet renderer is executed unchanged except its GPU setup is replaced
in memory. This job must never use the GPU reserved for the Board's paint run.
"""
from pathlib import Path
import json
import math
import sys

import bpy
from mathutils import Vector
from mathutils.bvhtree import BVHTree

REPO = Path(__file__).resolve().parents[4]
BUILD = REPO / 'tools/blender/build_sheets/build.py'
source = BUILD.read_text(encoding='utf-8')
start = source.index("sc.cycles.device = 'GPU'")
end = source.index('sc.cycles.samples =', start)
source = source[:start] + "sc.cycles.device = 'CPU'\nprint('R244 render device: CPU', flush=True)\n" + source[end:]
scope = dict(__file__=str(BUILD), __name__='__main__')
exec(compile(source, str(BUILD), 'exec'), scope)

if scope['MODE'] != 'render':
    sys.exit(0)
out = Path(scope['OUT'])
K, ship = scope['K'], scope['ship']
render, look_cam = scope['render'], scope['look_cam']
for name, az, el, dist, mm, target in (
    ('bow_detail', 16, 10, 15, 56, (6.5, 0, -0.08)),
    ('flank_detail', 75, 16, 26, 50, (0, 0, -0.05)),
    ('flank_starboard', -75, 16, 26, 50, (0, 0, -0.05)),
):
    camera = look_cam(name, az, el, dist, mm, (1280, 720), target)
    render(camera, (1280, 720), str(out / (name + '.png')))

# Measure the real opening against ALL exterior surfaces, not only the tube.
# The old closed bow fails even though its tube mesh by itself has depth.
depsgraph = bpy.context.evaluated_depsgraph_get()
verts, faces, intact_verts, intact_faces = [], [], [], []
triangles = dict(outside=0, inside=0)
for collection, key in ((K.coll, 'outside'), (K.cin, 'inside')):
    for obj in collection.objects:
        if obj.type != 'MESH':
            continue
        evaluated = obj.evaluated_get(depsgraph)
        mesh = evaluated.to_mesh()
        mesh.calc_loop_triangles()
        triangles[key] += len(mesh.loop_triangles)
        offset = len(intact_verts)
        intact_verts.extend(obj.matrix_world @ v.co for v in mesh.vertices)
        intact_faces.extend(tuple(offset + i for i in p.vertices) for p in mesh.polygons)
        if key == 'outside':
            offset = len(verts)
            verts.extend(obj.matrix_world @ v.co for v in mesh.vertices)
            faces.extend(tuple(offset + i for i in p.vertices) for p in mesh.polygons)
        evaluated.to_mesh_clear()
bvh = BVHTree.FromPolygons(verts, faces)
intact_bvh = BVHTree.FromPolygons(intact_verts, intact_faces)
openings = []
for fid, y, radius in (('I1', 0.73, 0.56), ('I2', -0.73, 0.54)):
    depths, intact_depths = [], []
    for ring in (0.0, 0.5, 0.8):
        for i in range(1 if ring == 0 else 8):
            angle = i * math.tau / 8
            origin = Vector((8.14, y + radius * ring * math.cos(angle),
                             -0.12 + radius * ring * math.sin(angle)))
            hit = bvh.ray_cast(origin, Vector((-1, 0, 0)), 3.0)
            depths.append(round(hit[3], 4) if hit[0] is not None else None)
            hit = intact_bvh.ray_cast(origin, Vector((-1, 0, 0)), 3.0)
            intact_depths.append(round(hit[3], 4) if hit[0] is not None else None)
    openings.append(dict(id=fid, rays=len(depths), depths=depths,
                         minimum_depth=min(d for d in depths if d is not None),
                         intact_depths=intact_depths,
                         pass_depth=all(d is not None and d > 1.6 for d in depths),
                         interiors_clear=intact_depths == depths))
report = dict(device=bpy.context.scene.cycles.device, class_length=ship.LENGTH,
              model_length=scope['MODEL_LEN'], openings=openings,
              triangles=triangles, exterior_meshes=sum(o.type == 'MESH' for o in K.coll.objects),
              exterior_materials=len({m.name for o in K.coll.objects if o.type == 'MESH' for m in o.data.materials}),
              fit_counts=scope['FIT']['counts'])
(out / 'R244_geometry.json').write_text(json.dumps(report, indent=1) + '\n', encoding='utf-8')
print('R244 geometry:', json.dumps(report), flush=True)
