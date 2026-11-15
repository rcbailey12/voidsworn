"""Real sheet builds, variant contracts and unpainted stage 7 exports (issue 812).
blender -b -t 4 -P variant_selftest.py -- OUT [BASELINE_JSON]
OUT is a scratch folder. The optional baseline is an earlier snapshot.json from this script.
The snapshot hashes every evaluated triangle, in object name order, including insides, in world coordinates.
"""
import hashlib
import importlib.util
import json
import os
import runpy
import struct
import sys

import bpy

HERE = os.path.dirname(os.path.abspath(__file__))
RECIPE = os.path.normpath(os.path.join(HERE, '..', '..', 'recipe'))
sys.path.insert(0, HERE)
sys.path.insert(0, RECIPE)
import kit
import contract
import gamedata
import weapon_match
import clash
from variant_recipe import make_variant

CASES = [('E14', 'd_jackal_h'), ('E13', 'd_scythe_s'), ('E12', 'd_harvester_t')]


def design(code):
    spec = importlib.util.spec_from_file_location(code, os.path.join(HERE, 'ships', code + '.py'))
    d = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(d)
    return d


def build(d, game=None):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    return kit.build_sheet(d, game_ship=game)


def snapshot(K):
    h = hashlib.sha256()
    count = 0
    dg = bpy.context.evaluated_depsgraph_get()
    for ob in sorted(list(K.coll.objects) + list(K.cin.objects), key=lambda o: o.name):
        if ob.type != 'MESH':
            continue
        evaluated = ob.evaluated_get(dg)
        me = evaluated.to_mesh()
        me.calc_loop_triangles()
        h.update(ob.name.encode())
        for t in me.loop_triangles:
            for i in t.vertices:
                h.update(struct.pack('<3f', *(ob.matrix_world @ me.vertices[i].co)))
        count += len(me.loop_triangles)
        evaluated.to_mesh_clear()
    return dict(triangles=count, sha256=h.hexdigest())


def export_recipe(recipe_path, export):
    saved = sys.argv
    sys.argv = ['export7.py', '--', recipe_path, export, 'unbaked=1']
    try:
        runpy.run_path(os.path.join(RECIPE, 'export7.py'), run_name='__main__')
    finally:
        sys.argv = saved


def main(out, baseline=None):
    os.makedirs(out, exist_ok=True)
    rows = []

    def check(ok, message):
        rows.append(dict(ok=bool(ok), message=message))
        print(('PASS ' if ok else 'FAIL ') + message, flush=True)
        if not ok:
            raise AssertionError(message)

    def refuses(fn, text):
        try:
            fn()
        except ValueError as e:
            check(text in str(e), 'refused: ' + str(e))
        else:
            check(False, 'did not refuse: ' + text)

    original = json.load(open(baseline)) if baseline else None
    snapshots = {}
    for short in ('E11', 'E12', 'E13', 'E14'):
        code = 'deathless_' + short
        d = design(code)
        K = build(d)
        snapshots[code] = snapshot(K)
        if original:
            check(snapshots[code] == original[code], code + ': triangles identical to the pre-change build')
        wm, probs = weapon_match.run(K, K.game_ship)
        check(not probs, code + ': base weapon match: ' + str(probs))
        base_path = os.path.join(RECIPE, 'ships', code + '.json')
        base = json.load(open(base_path))
        contract.to_recipe(K, base)
        export_recipe(base_path, os.path.join(out, 'ships', base['game_code']))
    json.dump(snapshots, open(os.path.join(out, 'snapshot.json'), 'w'), indent=2)

    for short, game in CASES:
        code = 'deathless_' + short
        d = design(code)
        base = json.load(open(os.path.join(RECIPE, 'ships', code + '.json')))
        ship = make_variant(base, game)
        recipe_path = os.path.join(out, game + '.json')
        json.dump(ship, open(recipe_path, 'w'), indent=1)
        work = os.path.join(out, game)
        os.makedirs(work, exist_ok=True)
        K = build(d, game)
        check(K.variant == game and K.game_ship == game, game + ': named selection reaches the sheet')
        wm, probs = weapon_match.run(K, game)
        json.dump(wm, open(os.path.join(work, 'weapon_match.json'), 'w'), indent=1)
        check(not probs, game + ': every variant slot has the right visible mount: ' + str(probs))
        fit = clash.run(K, work, code, d.LENGTH)
        check(not any(fit['counts'].values()), game + ': fit has zero clashes: ' + str(fit['counts']))
        check(gamedata.ship_attr(game, 'cls') == d.CLASS, game + ': inherits the base class')
        check(gamedata.ship_attr(game, 'fac') == 'deathless', game + ': inherits the base faction')
        refuses(lambda: contract.to_recipe(K, base), 'rebuild the selected hull')
        refuses(lambda: contract.to_recipe(K, dict(ship, game_code=base['game_code'])), 'base asset is preserved')
        rec = contract.to_recipe(K, ship)
        json.dump(rec, open(os.path.join(work, 'contract.json'), 'w'), indent=1)
        check(rec['length_world'] == d.LENGTH, game + ': keeps the base class length')
        bpy.ops.wm.save_as_mainfile(filepath=os.path.join(work, 'variant.blend'))
        export = os.path.join(out, 'ships', ship['game_code'])
        # Stage 7 must reject the wrong recipe even when the geometry already passed the build contract.
        try:
            export_recipe(os.path.join(RECIPE, 'ships', code + '.json'), os.path.join(work, 'rejected_export'))
        except SystemExit as e:
            check(e.code == 2, game + ': stage 7 refuses a blend built for a different game id')
        else:
            check(False, game + ': stage 7 accepted the wrong recipe')
        export_recipe(recipe_path, export)
        check(os.path.exists(os.path.join(export, ship['game_code'] + '.glb')), game + ': real stage 7 GLB written')
        # A variant built in this process must not leak into a later base build.
        check(snapshot(build(d)) == snapshots[code], game + ': rebuilding base after variant is identical')
        build(d)
        refuses(lambda: kit.build_sheet(d, game_ship='d_boss'), 'not a variant')
        if game == 'd_jackal_h':
            saved_variants = d.VARIANTS
            d.VARIANTS = ()
            refuses(lambda: kit.build_sheet(d, game_ship=game), 'no authored variant parts')
            d.VARIANTS = saved_variants
    json.dump(dict(result='PASS', rows=rows, bases=snapshots), open(os.path.join(out, 'variant_selftest.json'), 'w'), indent=2)
    print('PASS per-variant parts: base identity, named parts, checks, contracts and stage 7 exports', flush=True)


if __name__ == '__main__':
    main(*sys.argv[sys.argv.index('--') + 1:])
