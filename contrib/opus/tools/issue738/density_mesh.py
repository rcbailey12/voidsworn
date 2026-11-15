# usage: python density_mesh.py BUILD.blend OUT.json (with the bpy module)
# R224 mesh density on the stage 4 build (tools/recipe/density.py's mesh half, no paint yet): per part type, triangles and edge
# features (edges whose faces meet at more than 30 degrees, open rims) per square ship unit, against the hull's; under 0.75 flagged.
import os, sys, json, runpy, bpy, numpy as np
sys.path.insert(0, os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..', '..', '..', 'tools', 'recipe')))
import density as DN
bpy.ops.wm.open_mainfile(filepath=sys.argv[1])
rows = {}
for o in bpy.context.scene.objects:
    if o.type != 'MESH' or o.get('role') == 'interior':
        continue
    kind = 'hull' if o.get('role') == 'hull' else (o.get('part_kind') or 'part')
    V, T, _ = DN._tris(o)
    if not len(T):
        continue
    a = np.linalg.norm(np.cross(V[T[:, 1]] - V[T[:, 0]], V[T[:, 2]] - V[T[:, 0]]), axis=1) / 2
    r = rows.setdefault(kind, dict(area=0.0, tris=0, sharp=0))
    r['area'] += float(a.sum()); r['tris'] += len(T); r['sharp'] += DN._sharp_edges(o)
out = {}
for k, r in rows.items():
    out[k] = dict(triangles=r['tris'], area=round(r['area'], 5), tris_per_unit2=round(r['tris'] / r['area'], 1), edges_per_unit2=round(r['sharp'] / r['area'], 1))
h = out['hull']; flags = []
for k, d in out.items():
    if k == 'hull':
        continue
    for q in ('tris_per_unit2', 'edges_per_unit2'):
        d[q + '_vs_hull'] = round(d[q] / h[q], 2)
        if d[q] / h[q] < 0.75:
            flags.append('%s: %s %.2f of the hull' % (k, q, d[q] / h[q]))
json.dump(dict(types=out, flags=flags, rule='R224: a part type more than 25 percent under the hull is flagged (mesh half; the paint half runs at stage 5)'),
          open(sys.argv[2], 'w'), indent=1)
for k, d in sorted(out.items()):
    print('%-10s tris %7d  tris/u2 %7.1f  edges/u2 %7.1f  %s' % (k, d['triangles'], d['tris_per_unit2'], d['edges_per_unit2'],
                                                             '' if k == 'hull' else 'vs hull %.2f / %.2f' % (d['tris_per_unit2_vs_hull'], d['edges_per_unit2_vs_hull'])))
print('flags', flags)
