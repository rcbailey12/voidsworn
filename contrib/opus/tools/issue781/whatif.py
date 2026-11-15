# Issue 781 what-if (evidence for a Board ruling, not a paint): the painted S8 with its hull and parts albedo maps multiplied in
# linear by K in memory (the stack and the job's files are not changed), rendered at the sheet's fitted camera and at the battle
# camera (34 degrees), the same game light, lift and cameras as issue 756's preview.py. It shows what "the battle median halfway
# to the concept" asks of the paint at both cameras.
# usage: python ../issue756/run_cpu.py whatif.py PAINTED.blend -- OUT_DIR k=1.85 [samples=16]
import os, sys, runpy
import numpy as np
import bpy

HERE = os.path.dirname(os.path.abspath(__file__))
a = sys.argv[sys.argv.index('--') + 1:]
OUT = a[0]; kw = dict(x.split('=', 1) for x in a[1:] if '=' in x); K = float(kw.get('k', 1.85))
for im in bpy.data.images:
    if im.name.endswith(('_hull_albedo.png', '_parts_albedo.png')) or im.name.endswith(('_hull_albedo', '_parts_albedo')):
        p = np.empty(len(im.pixels), np.float32); im.pixels.foreach_get(p); p = p.reshape(-1, 4)
        c = p[:, :3].astype(np.float64)
        c = np.where(c <= .04045, c / 12.92, ((c + .055) / 1.055) ** 2.4) * K
        c = np.clip(c, 0, 1); p[:, :3] = np.where(c <= .0031308, c * 12.92, 1.055 * c ** (1 / 2.4) - .055)
        im.pixels.foreach_set(p.ravel()); im.update(); print('[781] scaled', im.name, K, flush=True)
sys.argv = ['preview.py', '--', OUT, 'samples=' + kw.get('samples', '16'), 'only=battle']
R = runpy.run_path(os.path.join(HERE, '..', 'issue756', 'preview.py'), run_name='__main__')
G = R['G']; fc = G['fc']
o = G['look_cam'](fc['az'], fc['el'], fc['dist'], fc['mm'], tuple(fc['res']), fc['target'], fc.get('roll', 0), (-fc.get('sx', 0), -fc.get('sy', 0)))
G['shoot'](o, 'paint_beauty', float(kw.get('scale', '0.5')))
print('[781] whatif done', flush=True)
