"""Paint-only proof at the saved concept camera and a stern quarter.

Blender -b SHIP.blend -P capture.py -- OUT SHEET CONCEPT
Uses the normal paint-sheet light and cameras. No geometry is changed.
"""
from pathlib import Path
import sys
import hashlib
import json
import math
import numpy as np

repo = Path(__file__).resolve().parents[3]
source = repo / 'tools/blender/build_sheets/paint_sheet.py'
out, sheet, concept = sys.argv[sys.argv.index('--') + 1:]
sys.argv = [str(source), '--', out, sheet, concept, 'lift=1.25',
            'samples=48', 'scale=0.5', 'gpu=1', 'sky_spec=0']
# Reuse the shared setup and helpers without rendering its full contact sheet.
scope = {'__file__': str(source), '__name__': 'issue936_capture'}
exec(compile(source.read_text().split('\nbeauty = look_cam(')[0], str(source), 'exec'), scope)
fc = scope['fc']; look = scope['look_cam']; shoot = scope['shoot']
cam = look(fc['az'], fc['el'], fc['dist'], fc['mm'], tuple(fc['res']),
           fc['target'], fc.get('roll', 0), (-fc.get('sx', 0), -fc.get('sy', 0)))
shoot(cam, 'beauty', .5)
unit = scope['S']
cam = look(145, 22, 1.6 / unit, 52, (1280, 720), (-.30 / unit, 0, .015 / unit))
shoot(cam, 'engines', 1)
cam = scope['ortho']('plate_measure', (0, 0, 3), (0, 0, 0), (0, -1, 0), 1.12, (1280, 560))
shoot(cam, 'top', 1)
# Report the actual painted meshes, not just the design's requested plate size.
areas = []; angles = []; digest = hashlib.sha256(); triangles = 0
for ob in sorted(scope['sc'].objects, key=lambda o: o.name):
    if ob.type != 'MESH':
        continue
    me = ob.data; me.calc_loop_triangles(); triangles += len(me.loop_triangles)
    digest.update(ob.name.encode())
    points = np.asarray([tuple(ob.matrix_world @ v.co) for v in me.vertices], dtype='<f4')
    digest.update(points.tobytes())
    for face in me.polygons:
        digest.update(np.asarray(face.vertices[:], dtype='<i4').tobytes())
    if '_plates_' not in ob.name:
        continue
    # plate_slab makes eight vertices and six quads. Rivet and weld rods have
    # different topology; identify the kit's slabs without an area-size cutoff.
    parent = list(range(len(me.vertices)))
    def root(i):
        while parent[i] != i:
            parent[i] = parent[parent[i]]; i = parent[i]
        return i
    for edge in me.edges:
        a, b = edge.vertices; parent[root(a)] = root(b)
    components = {}
    for face in me.polygons:
        k = root(face.vertices[0])
        vertices, faces = components.setdefault(k, (set(), []))
        vertices.update(face.vertices); faces.append(face)
    for vertices, faces in components.values():
        if len(vertices) != 8 or len(faces) != 6 or any(len(f.vertices) != 4 for f in faces):
            continue
        def area(f):
            p = points[list(f.vertices)]
            return sum(float(np.linalg.norm(np.cross(p[i]-p[0], p[i+1]-p[0]))) / 2 for i in range(1,len(p)-1))
        face = max(faces, key=area)
        areas.append(area(face) / scope['S'] ** 2)
        verts = points[list(face.vertices)]
        edge = max((verts[(i+1) % len(verts)] - p for i,p in enumerate(verts)), key=np.linalg.norm)
        normal = np.cross(verts[1]-verts[0], verts[2]-verts[0]); normal /= np.linalg.norm(normal)
        axis = np.array((1.,0.,0.)); axis -= normal * float(normal[0])
        if np.linalg.norm(axis) < 1e-7:
            axis = np.array((0.,1.,0.)); axis -= normal * float(normal[1])
        axis /= np.linalg.norm(axis)
        angle = math.degrees(math.atan2(float(edge @ np.cross(normal,axis)), float(edge @ axis)))
        angles.append((angle + 90) % 180 - 90)
measurement = dict(geometry_sha256=digest.hexdigest(), triangles=triangles,
    plate_components=len(areas), plate_area_world2_p10_p50_p90=np.percentile(areas, [10,50,90]).tolist() if areas else [],
    plate_edge_angle_degrees_p10_p50_p90=np.percentile(angles, [10,50,90]).tolist() if angles else [],
    method='Actual painted armour objects named _plates_: each disconnected 8-vertex, 6-quad component is the kit plate_slab; rivet and weld rods are excluded by topology. Includes overlaid slabs. Area is the largest world-space face. Angles are longest-edge face-plane headings modulo 180, relative to projected ship X (ship Y on bow/stern faces). Review evidence, no pass bar.')
engines={}
for ob in scope['sc'].objects:
    if ob.type!='MESH' or ob.get('part_kind')!='engine':
        continue
    ca=ob.data.color_attributes.get('ps_glow')
    if ca is None:
        continue
    engines.setdefault(ob.get('grp',ob.name),set()).update(round(float(v.color[1]),6) for v in ca.data)
measurement['engine_seeds']={k:sorted(v) for k,v in engines.items()}
measurement['engines_share_seed']=len(set(v for values in engines.values() for v in values))==1
(Path(out) / 'painted_mesh_measure.json').write_text(json.dumps(measurement, indent=2))
print('PASS issue936 captures', flush=True)
