# Insides inside the skin (issue 738; clash.py reads only the outside): builds a build-sheet ship whose design file offers
# half_ring(x, inset), hw_at(x, z, inset), SHELL and ST (voidsworn_S8 does), then tests every vertex of every inside object
# against the hull's inner skin (the section inset by the shell) at its own station and height, and reports, for every
# longitudinal seam, the inside objects in its span that straddle its level plane and the clear band kept above and below it
# (the game tears a peel with a V kink and waves, godot/fx/fx_death.gd, so the band is reported, not judged here).
# usage: python inside_check.py voidsworn_S8   (with the bpy module; exit 1 when a vertex is outside or an object straddles)
import sys, os, importlib.util
REPO = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..', '..', '..'))
sys.path.insert(0, os.path.join(REPO, 'tools/blender/build_sheets'))
import bpy, kit
CODE = sys.argv[1] if len(sys.argv) > 1 else 'voidsworn_S8'
bpy.ops.wm.read_factory_settings(use_empty=True)
sp = importlib.util.spec_from_file_location(CODE, os.path.join(REPO, 'tools/blender/build_sheets/ships', CODE + '.py'))
d = importlib.util.module_from_spec(sp); sp.loader.exec_module(d)
kit.use_kit(d.KIT); K = kit.Kit(d.CODE, d.LENGTH); d.build(K); K.finish(); bpy.context.view_layer.update()
bad = []; n = 0; worst = 0.0
for o in K.cin.objects:
    for v in o.data.vertices:
        w = o.matrix_world @ v.co; n += 1
        h = d.half_ring(w.x, d.SHELL)
        zt, zb = h[0][1], h[-1][1]
        hw = d.hw_at(w.x, w.z, d.SHELL)
        over = max(abs(w.y) - hw, w.z - zt, zb - w.z, w.x - d.ST[0][0], d.ST[-1][0] - w.x)
        if hw <= 0:
            over = max(over, 0.01)
        worst = max(worst, over)
        if over > 0.005:
            bad.append((o.name, round(w.x, 2), round(w.y, 2), round(w.z, 2), round(over, 3)))
print('inside vertices tested', n, 'objects', len(K.cin.objects), 'outside the inner skin', len(bad), 'worst', round(worst, 3))
for b in bad[:12]:
    print('  OUT', b)
longs = [r for r in K.inside if r.get('kind') == 'break' and r.get('orient') == 'long']
cross = []
for r in longs:
    z = sum(p[1] for p in r['path']) / len(r['path']); x0 = min(p[0] for p in r['path']); x1 = max(p[0] for p in r['path'])
    above, below = 99.0, 99.0
    for o in K.cin.objects:
        ws = [o.matrix_world @ v.co for v in o.data.vertices]
        lo = min(v.z for v in ws); hi = max(v.z for v in ws); xa = min(v.x for v in ws); xb = max(v.x for v in ws)
        if not (xb > x0 and xa < x1):
            continue
        if lo < z < hi:
            cross.append((r['name'], o.name, round(lo, 2), round(hi, 2)))
        elif lo >= z:
            above = min(above, lo - z)
        else:
            below = min(below, z - hi)
    print('seam %s: level %.2f over %.2f to %.2f; clear band to the nearest inside: %.2f above, %.2f below' % (r['name'], z, x0, x1, above, below))
print('longitudinal seams', len(longs), 'inside objects straddling a peel plane in its span', len(cross))
for c in cross[:20]:
    print('  CROSS', c)
sys.exit(1 if bad or cross else 0)
