# R224 mesh density on a built sheet ship, before paint (issue 739): the mesh half of tools/recipe/density.py (the same
# definitions: triangles and edge features, edges whose faces meet at more than 30 degrees or open rims, per square unit of
# surface, per part kind, the hull its own row), read off the stage 4 build blend (tools/blender/r209/sheet_hull.py), so a sheet
# can report the rule before its stage 5 bake measures the paint half. Areas are in world units squared (the build is one
# ship length long; the scene's r209_length_world scales it back). A part kind more than 25 percent under the hull is flagged.
#   blender -b BUILD.blend -P mesh_density.py -- OUT.json
import os, sys, json
import bpy
import numpy as np
sys.path.insert(0, os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..', '..', 'recipe')))
import density as D

out_json = sys.argv[sys.argv.index('--') + 1] if '--' in sys.argv else 'mesh_density.json'
L = float(bpy.context.scene.get('r209_length_world', 1.0))
rows = {}
for o in bpy.context.scene.objects:
    if o.type != 'MESH' or o.get('role') == 'interior':
        continue
    mat = o.data.materials[0].name if o.data.materials else ''
    if mat in ('corona', 'ecore', 'lens'):
        continue      # light surfaces, as density.py leaves out the glow
    kind = 'hull' if o.get('role') == 'hull' else (o.get('part_kind') or 'part')
    V, T, _ = D._tris(o)
    if not len(T):
        continue
    a = np.linalg.norm(np.cross(V[T[:, 1]] - V[T[:, 0]], V[T[:, 2]] - V[T[:, 0]]), axis=1) / 2
    r = rows.setdefault(kind, dict(area=0.0, tris=0, sharp=0))
    r['area'] += float(a.sum()) * L * L; r['tris'] += len(T); r['sharp'] += D._sharp_edges(o)
res = {}
for k, r in rows.items():
    res[k] = dict(area=round(r['area'], 2), triangles=r['tris'], tris_per_unit2=round(r['tris'] / r['area'], 1), edges_per_unit2=round(r['sharp'] / r['area'], 1))
flags = []
h = res.get('hull')
for k, d in res.items():
    if k == 'hull' or not h:
        continue
    for q in ('tris_per_unit2', 'edges_per_unit2'):
        d[q + '_vs_hull'] = round(d[q] / max(h[q], 1e-9), 2)
        if d[q + '_vs_hull'] < D.UNDER:
            flags.append('%s: %s %s is %.2f of the hull\'s %s' % (k, q, d[q], d[q + '_vs_hull'], h[q]))
json.dump(dict(rule='R224: a part kind more than 25 percent under the hull is flagged (mesh half; the paint half is stage 5)', types=res, mesh_flags=flags),
          open(out_json, 'w'), indent=1)
for k, d in sorted(res.items()):
    print('%-10s area %7.2f  tris/u2 %7.1f  edges/u2 %6.1f  %s' % (k, d['area'], d['tris_per_unit2'], d['edges_per_unit2'],
          '' if k == 'hull' else 'vs hull %.2f / %.2f' % (d['tris_per_unit2_vs_hull'], d['edges_per_unit2_vs_hull'])))
print('MESH DENSITY flags: %d' % len(flags))
for f in flags:
    print('  ', f)
