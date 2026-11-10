# Issue 209 round 3: the cost tables for the report, from the Godot bench (bench209.json), the cell records and the LOD exports.
# usage: python3 report3.py BENCH_JSON CELL_JSON_DIR GLB_DIR
import sys, os, json, statistics as st
B = json.load(open(sys.argv[1])); JD, GD = sys.argv[2], sys.argv[3]
E = {r['scaling_3d']: r for r in B['empty']}
# R116 gate, latest gate-scene readings (R118, after #220): frame median 6.0 ms at 1080p, GPU 5.45 ms with the 3D at 4K
GATE, FRAME_NOW, GPU4K_NOW = 12.5, 6.0, 5.45
def med(rows, key): return st.median(r[key] for r in rows) if rows else float('nan')
print('| Cell | Mode | Triangles drawn, 20 ships (all passes) | GPU ms 1080p | GPU ms, 3D at 4K | Frame ms 1080p | Draw calls | Share of 4K GPU room | Share of 1080p frame room |')
print('|---|---|---:|---:|---:|---:|---:|---:|---:|')
for c, cd in B['cells'].items():
    for mode in ('off', 'auto', 'hand'):
        rs = [r for r in cd['runs'] if r.get('mode') == mode]
        if not rs: continue
        r1 = [r for r in rs if r['scaling_3d'] == 1.0]; r2 = [r for r in rs if r['scaling_3d'] == 2.0]
        g1 = med(r1, 'gpu_median_ms') - E[1.0]['gpu_median_ms']; g2 = med(r2, 'gpu_median_ms') - E[2.0]['gpu_median_ms']
        f1 = med(r1, 'frame_median_ms') - E[1.0]['frame_median_ms']
        print(f"| {c} | {mode} | {int(med(r1, 'primitives')):,} | {g1:.2f} | {g2:.2f} | {f1:.2f} | {int(med(r1, 'draw_calls'))} | "
              f"{100 * g2 / (GATE - GPU4K_NOW):.0f}% | {100 * max(f1, 0) / (GATE - FRAME_NOW):.0f}% |")
print()
print('empty studio:', {k: round(v['gpu_median_ms'], 2) for k, v in E.items()}, 'frame', round(E[1.0]['frame_median_ms'], 2), 'texture prep s', round(B.get('texture_prep_seconds', 0), 1))
print()
print('| Cell | LOD0 | LOD1 | LOD2 | LOD3 |')
print('|---|---:|---:|---:|---:|')
for c in B['cells']:
    p = os.path.join(GD, f'{c}_lods.json')
    if os.path.exists(p):
        L = json.load(open(p)); print(f"| {c} | " + ' | '.join(f"{L[f'lod{k}']['triangles']:,}" for k in range(4)) + ' |')
print()
for c in B['cells']:
    p = os.path.join(JD, f'{c}.json')
    if not os.path.exists(p): continue
    m = json.load(open(p)); b = m.get('bake', {})
    print(c, dict(triangles=m.get('triangles'), surfaces=m.get('surfaces'), blocks=m.get('block_triangles'), plates=m.get('plate_triangles'), hero=m.get('hero_triangles'),
                  build_s=m.get('build_seconds'), audit=m.get('audit'), bake=b))
