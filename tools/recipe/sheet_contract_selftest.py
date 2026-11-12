# Ship recipe: prove the build sheet contract (issue 592; tools/blender/build_sheets/contract.py). It builds the ship's sheet
# with the sheet kit, keeps the sheet's own records, applies the contract, and checks that every datum the recipe reads came
# from the sheet unchanged in all but units: the outside is one ship length long; the class length is the sheet's; every
# transverse seam sits at the sheet's x; every gun and launcher muzzle is the kit's own, in the right data.js slot; every turret
# pivot survives with its turning meshes; every engine exit is the sheet's; the insides are visible as role interior; the hull
# thickness is the sheet's, scaled. Then two broken inputs must be refused, each by name: a ship whose data.js weapon list
# lacks one of the sheet's weapons, and a sheet with two longitudinal seams (format version 1 holds one).
# Stage 4 runs it for every ship built from a sheet. usage: blender -b -P sheet_contract_selftest.py -- SHIP_JSON OUT_DIR
import os, sys, json, copy, importlib.util
HERE = os.path.dirname(os.path.abspath(__file__)); REPO = os.path.normpath(os.path.join(HERE, '..', '..'))
SHEETS = os.path.join(REPO, 'tools', 'blender', 'build_sheets'); sys.path.insert(0, SHEETS); sys.path.insert(0, HERE)
import bpy
from mathutils import Vector
import kit, contract, gamedata

a = sys.argv[sys.argv.index('--') + 1:]
SHIP = json.load(open(a[0])); OUT = a[1]; os.makedirs(OUT, exist_ok=True)
rows = []; bad = 0


def check(ok, what):
    global bad
    bad += not ok; rows.append(('ok  ' if ok else 'BAD ') + ' ' + what); print(rows[-1], flush=True)


def build():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    sp = importlib.util.spec_from_file_location(SHIP['sheet'], os.path.join(SHEETS, 'ships', SHIP['sheet'] + '.py'))
    d = importlib.util.module_from_spec(sp); sp.loader.exec_module(d)
    kit.use_kit(getattr(d, 'KIT', 'hullbreakers')); K = kit.Kit(SHIP['sheet'], d.LENGTH); d.build(K); K.finish(); bpy.context.view_layer.update()
    return d, K


d, K = build()
feats = copy.deepcopy(K.features); fit = copy.deepcopy(K.fitdata); inside = copy.deepcopy(K.inside)
shell = {o.name: md.thickness for o in bpy.context.scene.objects for md in o.modifiers if md.type == 'SOLIDIFY'}
n_inside = len(K.cin.objects)
rec = contract.to_recipe(K, SHIP); s = rec['scale']; sc = bpy.context.scene
outside = [o for o in K.coll.objects if o.type == 'MESH']
lo, hi = contract._bbox(outside)
check(abs((hi.x - lo.x) - 1.0) < 1e-4, f'the outside is one ship length long ({hi.x - lo.x:.6f})')
check(sc['r209_length_world'] == d.LENGTH, f'the class length is the sheet\'s ({sc["r209_length_world"]} = LENGTH {d.LENGTH})')
tx = sorted(r['x'] for r in inside if r.get('kind') == 'break' and r.get('orient', 'trans') == 'trans')
check(len(tx) == len(sc['r209_t_lines']) and all(abs(x * s - t) < 1e-6 for x, t in zip(tx, sc['r209_t_lines'])),
      f'{len(tx)} transverse seams at the sheet\'s stations')
hp = json.loads(sc['r209_hp']); weapons = gamedata.weapons(SHIP['game_ship'])
mz = {}
for m in hp['muzzles']: mz.setdefault(m['socket'], []).append(m)
ok = True
for f in fit:
    if f['kind'] not in ('gun', 'launcher'): continue
    src = f['muzzles'] if f['kind'] == 'gun' else [e['pos'] for e in f['apertures']]
    got = mz.get(f['id'], [])
    wk = next(x for x in feats if x['id'] == f['id']).get('weapon')
    ok &= len(got) == len(src) and all((Vector(m['tip']) - Vector(p) * s).length < 1e-6 for m, p in zip(got, src))
    ok &= all(weapons[m['slot']] == (wk, f['slot']) for m in got)
check(ok, f'{len(hp["muzzles"])} muzzles are the kit\'s own, each in the data.js slot of its weapon and arc')
pivots = [o for o in sc.objects if o.type == 'EMPTY' and o.get('turret')]
want = [f['id'] for f in fit if f['kind'] == 'gun' and f.get('mount') != 'casemate']
check(sorted(p.name[:-7] for p in pivots) == sorted(want) and all(any(c.type == 'MESH' for c in p.children) and isinstance(p['slot'], int) for p in pivots),
      f'{len(pivots)} turret pivots kept, each with its turning meshes and a data.js slot')
eng = [x for x in feats if x['kind'] == 'engine']
check(len(eng) == len(hp['engines']) and all((Vector(e['pos']) - Vector(x['exit']) * s).length < 1e-6 and abs(e['radius'] - x['radius'] * s) < 1e-9
                                             for e, x in zip(hp['engines'], eng)), f'{len(eng)} engine exits and bell radii are the sheet\'s')
ins = [o for o in sc.objects if o.type == 'MESH' and o.get('role') == 'interior']
check(len(ins) == n_inside > 0 and not any(o.hide_render for o in ins), f'{len(ins)} inside objects are visible role interior')
sk = [(o.name, md.thickness) for o in sc.objects for md in o.modifiers if md.type == 'SOLIDIFY']
check(sk and all(o.modifiers.get('skin') for o in sc.objects if o.name in shell) and all(abs(t - shell[n] * s) < 1e-9 for n, t in sk),
      f'the hull thickness is the sheet\'s, scaled, on {len(sk)} skin modifiers')

# broken inputs, each refused by name
d, K = build(); other = dict(SHIP, game_ship='c_marauder')
try: contract.to_recipe(K, other); check(False, 'a ship whose weapon list lacks a sheet weapon was refused')
except contract.ContractError as e: check('names 0 slots' in str(e), f'a ship whose weapon list lacks a sheet weapon was refused: {e}')
d, K = build()
K.inside += [dict(kind='break', name='L-a', x=0, orient='long', path=[(1, 0.5), (-1, 0.5)]), dict(kind='break', name='L-b', x=0, orient='long', path=[(1, 1.0), (-1, 1.0)])]
try: contract.to_recipe(K, SHIP); check(False, 'two longitudinal seams were refused')
except contract.ContractError as e: check('format version 1 holds one' in str(e), f'two longitudinal seams were refused: {e}')
json.dump(dict(ok=not bad, rows=rows, record=rec), open(os.path.join(OUT, 'sheet_contract_selftest.json'), 'w'), indent=1)
print('PASS the build sheet contract keeps the sheet\'s data' if not bad else 'FAIL the build sheet contract changed or lost a datum', flush=True)
sys.exit(1 if bad else 0)
