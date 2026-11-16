# Insides inside the skin, and inside one compartment (issue 759; clash.py reads only the outside). Builds a build-sheet ship
# whose design file offers inside_ok(point) (the distance a point sits outside the inner skin of the mass that holds it; <= 0
# inside: hegemony_H10 does, for its wedge, rails and bay block), tests every vertex of every inside object, then reports, for
# every transverse seam, any inside object whose x span reaches into the seam's band (its plan path's x range, padded 0.1): an
# inside must sit in one compartment, so the game's death cut never leaves half of it outside its piece (ships.md 2c).
# usage: python inside_check.py hegemony_H10   (with the bpy module; exit 1 when a vertex is outside or an object crosses a seam)
import sys, os, importlib.util
REPO = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..', '..', '..'))
sys.path.insert(0, os.path.join(REPO, 'tools/blender/build_sheets'))
import bpy, kit
CODE = sys.argv[1] if len(sys.argv) > 1 else 'hegemony_H10'
bpy.ops.wm.read_factory_settings(use_empty=True)
sp = importlib.util.spec_from_file_location(CODE, os.path.join(REPO, 'tools/blender/build_sheets/ships', CODE + '.py'))
d = importlib.util.module_from_spec(sp); sp.loader.exec_module(d)
kit.use_kit(d.KIT); K = kit.Kit(d.CODE, d.LENGTH); d.build(K); K.finish(); bpy.context.view_layer.update()
bad = []; n = 0; worst = -9.0
for o in K.cin.objects:
    for v in o.data.vertices:
        w = o.matrix_world @ v.co; n += 1
        over = d.inside_ok(tuple(w))
        worst = max(worst, over)
        if over > 0.005:
            bad.append((o.name, round(w.x, 2), round(w.y, 2), round(w.z, 2), round(over, 3)))
print('inside vertices tested', n, 'objects', len(K.cin.objects), 'outside the inner skin', len(bad), 'worst', round(worst, 3))
for b in sorted(bad, key=lambda t: -t[4])[:15]:
    print('  OUT', b)
seams = [r for r in K.inside if r.get('kind') == 'break' and r.get('orient', 'trans') == 'trans']
cross = []
for r in seams:
    xs = [p[0] for p in r['path']]; lo, hi = min(xs) - 0.1, max(xs) + 0.1
    near = 99.0
    for o in K.cin.objects:
        ws = [o.matrix_world @ v.co for v in o.data.vertices]
        xa = min(v.x for v in ws); xb = max(v.x for v in ws)
        if xb > lo and xa < hi:
            cross.append((r['name'], o.name, round(xa, 2), round(xb, 2)))
        else:
            near = min(near, abs(xa - hi) if xa >= hi else abs(lo - xb))
    print('seam %s at %.2f (path %.2f to %.2f): nearest inside %.2f clear of the padded band' % (r['name'], r['x'], min(xs), max(xs), near))
print('transverse seams', len(seams), 'inside objects reaching a seam band', len(cross))
for c in cross[:20]:
    print('  CROSS', c)
sys.exit(1 if bad or cross else 0)
