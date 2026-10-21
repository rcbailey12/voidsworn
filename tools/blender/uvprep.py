# add xatlas UV charts ('u') to game hull JSONs. usage: uvprep.py <in_dir> <out_dir> <ref_hi_dir>
import sys, os, json, base64, glob, numpy as np, xatlas
IN, OUT, HI = sys.argv[1], sys.argv[2], sys.argv[3]
for f in sorted(glob.glob(os.path.join(IN, '*.json'))):
    j = json.load(open(f)); ext = np.array(j['ext']); code = os.path.basename(f)[:-5]
    P = np.frombuffer(base64.b64decode(j['p']), np.int16).reshape(-1, 3)
    Nq = np.frombuffer(base64.b64decode(j['q']), np.int8).reshape(-1, 3)
    I = np.frombuffer(base64.b64decode(j['i']), np.uint32 if j.get('i32') else np.uint16).reshape(-1, 3).astype(np.uint32)
    A = np.frombuffer(base64.b64decode(j['a']), np.uint8) if 'a' in j else None
    t = json.load(open(os.path.join(HI, code + '.json'))).get('t', 0); res = 2048 if t >= 26000 else 1024 if t >= 9000 else 512
    if 'hulls_hi' not in IN: res //= 2
    at = xatlas.Atlas(); at.add_mesh((P / 32767 * ext).astype(np.float32), I)
    co = xatlas.ChartOptions(); co.max_iterations = 2; co.normal_deviation_weight = 2.0; co.max_cost = 2.0
    po = xatlas.PackOptions(); po.resolution = res; po.padding = max(2, res // 512); po.bilinear = True; po.blockAlign = True
    at.generate(co, po); vm, Iu, UV = at[0]; vm = np.asarray(vm, np.int64); Iu = np.asarray(Iu, np.int64); UV = np.clip(np.asarray(UV, np.float64), 0, 1)
    n = len(vm); o = dict(j); o['n'] = n; o['t'] = len(Iu); o['i32'] = n >= 65535
    o['p'] = base64.b64encode(P[vm].tobytes()).decode(); o['q'] = base64.b64encode(Nq[vm].tobytes()).decode()
    o['i'] = base64.b64encode(Iu.astype(np.uint32 if o['i32'] else np.uint16).tobytes()).decode()
    o['u'] = base64.b64encode(np.round(UV * 65535).astype(np.uint16).tobytes()).decode()
    if A is not None: o['a'] = base64.b64encode(A[vm].tobytes()).decode()
    o['tex'] = {'res': res, 'v': 1}
    json.dump(o, open(os.path.join(OUT, code + '.json'), 'w'))
    print(code, res, 'charts', at.chart_count, 'util %.2f' % at.utilization, 'verts', len(P), '->', n, flush=True)
