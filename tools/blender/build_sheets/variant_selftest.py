"""CPU proof for issue 812. Run with Blender and --python-exit-code 1.

  blender -b -t 4 --python-exit-code 1 -P variant_selftest.py -- OUT [--baseline=JSON]

OUT is a scratch folder. The optional baseline is a pre-change geometry snapshot,
not a fixed triangle budget. Exported GLBs are unbaked test assets, never installed.
"""
import hashlib
import importlib.util
import json
import os
import struct
import subprocess
import sys
from pathlib import Path

import bpy

HERE = Path(__file__).resolve().parent
REPO = HERE.parents[2]
RECIPE = REPO / 'tools/recipe'
sys.path[:0] = [str(HERE), str(RECIPE)]
import contract
import variants
import weapon_match
import clash
import gamedata

CASES = [('deathless_E14', 'd_jackal_h', 'deathless_E14_guard'),
         ('deathless_E13', 'd_scythe_s', 'deathless_E13_sentinel'),
         ('deathless_E12', 'd_harvester_t', 'deathless_E12_turreted')]


def design(code):
    spec = importlib.util.spec_from_file_location(code, HERE / 'ships' / (code + '.py'))
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def snapshot():
    """Hash every evaluated triangle in world space, including insides and shell modifiers."""
    digest = hashlib.sha256()
    count = 0
    dg = bpy.context.evaluated_depsgraph_get()
    for ob in sorted(bpy.context.scene.objects, key=lambda ob: ob.name):
        if ob.type != 'MESH':
            continue
        evaluated = ob.evaluated_get(dg)
        mesh = evaluated.to_mesh()
        mesh.calc_loop_triangles()
        digest.update(ob.name.encode())
        for tri in mesh.loop_triangles:
            for i in tri.vertices:
                digest.update(struct.pack('<3f', *(ob.matrix_world @ mesh.vertices[i].co)))
        count += len(mesh.loop_triangles)
        evaluated.to_mesh_clear()
    return dict(triangles=count, sha256=digest.hexdigest())


def build(code, game=None):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    K = variants.build(design(code), game)
    bpy.context.view_layer.update()
    return K


def command(args, log):
    with open(log, 'w', encoding='utf-8') as stream:
        result = subprocess.run([str(x) for x in args], stdout=stream, stderr=subprocess.STDOUT, timeout=180)
    if result.returncode:
        raise AssertionError(f'command failed ({result.returncode}): {log}')


def export(K, recipe, folder, out):
    ship_path = RECIPE / 'ships' / (recipe + '.json')
    ship = json.loads(ship_path.read_text())
    record = contract.to_recipe(K, ship)
    blend = folder / 'contract.blend'
    bpy.ops.wm.save_as_mainfile(filepath=str(blend))
    target = out / 'ships' / ship['game_code']
    command([bpy.app.binary_path, '-b', '-t', '4', str(blend), '--python-exit-code', '1', '-P',
             RECIPE / 'export7.py', '--', ship_path, target, 'unbaked=1'], folder / 'export.log')
    python = Path(bpy.app.binary_path).parent / ('%d.%d' % bpy.app.version[:2]) / 'python/bin/python.exe'
    command([python, RECIPE / 'check_export.py', ship_path, target, 'unbaked=1'], folder / 'check_export.log')
    check = json.loads((target / (ship['game_code'] + '_check.json')).read_text())
    assert check['ok'], check['problems']
    return record, check, str(target / (ship['game_code'] + '.glb'))


def main():
    args = sys.argv[sys.argv.index('--') + 1:]
    out = Path(args[0]); out.mkdir(parents=True, exist_ok=True)
    baseline_path = next((x.split('=', 1)[1] for x in args if x.startswith('--baseline=')), None)
    baseline = json.loads(Path(baseline_path).read_text()) if baseline_path else None
    report = dict(bases={}, variants={}, refused=[])
    for code in ('deathless_E11', 'deathless_E12', 'deathless_E13', 'deathless_E14'):
        K = build(code)
        actual = snapshot()
        if baseline:
            assert actual == baseline[code], f'{code} changed base triangles: {actual} != {baseline[code]}'
        match, problems = weapon_match.run(K, K.game_ship)
        assert not problems, problems
        report['bases'][code] = dict(actual, baseline_identical=bool(baseline), weapon_match=match['result'])
        print('PASS base', code, actual, flush=True)
        folder = out / code; folder.mkdir(exist_ok=True)
        record, check, glb = export(K, code, folder, out)
        report['bases'][code].update(contract=record, export=check, glb=glb)

    for code, game, recipe in CASES:
        K = build(code, game)
        match, problems = weapon_match.run(K, game)
        assert not problems, problems
        folder = out / game; folder.mkdir(exist_ok=True)
        fit = clash.run(K, str(folder), code, K.length)
        assert not any(fit['counts'].values()), fit['counts']
        before = snapshot()
        ship_path = RECIPE / 'ships' / (recipe + '.json')
        ship = json.loads(ship_path.read_text())
        # A correct build may never be paired with a different recipe or base output folder.
        for wrong in (dict(ship, game_ship=variants.base_game(design(code))), dict(ship, game_code='base_folder')):
            try:
                contract.to_recipe(K, wrong)
            except contract.ContractError:
                report['refused'].append(dict(variant=game, wrong_game=wrong['game_ship'], wrong_code=wrong['game_code']))
            else:
                raise AssertionError('a mismatched recipe was accepted')
        record, check, glb = export(K, recipe, folder, out)
        assert bpy.context.scene['r209_game_ship'] == game
        assert check['cls'] == gamedata.ship_attr(variants.base_game(design(code)), 'cls')
        # A base blend with a variant JSON must be refused by stage 7 itself.
        rejected = folder / 'rejected_base_export'
        with open(folder / 'rejected_base_export.log', 'w') as stream:
            result = subprocess.run([bpy.app.binary_path, '-b', '-t', '4', str(out / code / 'contract.blend'),
                                     '--python-exit-code', '1', '-P', str(RECIPE / 'export7.py'), '--',
                                     str(ship_path), str(rejected), 'unbaked=1'], stdout=stream, stderr=subprocess.STDOUT, timeout=60)
        status = (rejected / 'export_status.txt').read_text()
        assert result.returncode != 0 and 'FAILED' in status and 'named variant' in status, status
        report['refused'].append(dict(variant=game, base_blend_refused=status.strip()))
        report['variants'][game] = dict(sheet=code, geometry=before, fit=fit['counts'], weapon_match=match,
                                       contract=record, export=check, glb=glb)
        print('PASS variant contract, fit and GLB readback', game, flush=True)
    # Wrong family and undeclared variant must fail before geometry is built.
    for code, game in [('deathless_E14', 'd_scythe_s'), ('deathless_E14', 'unknown_variant')]:
        try:
            build(code, game)
        except ValueError as exc:
            report['refused'].append(str(exc))
        else:
            raise AssertionError(f'unsupported selection accepted: {code} {game}')
    module = design('deathless_E14')
    module.VARIANTS = {}
    try:
        variants.build(module, 'd_jackal_h')
    except ValueError as exc:
        assert 'no variant builder' in str(exc)
        report['refused'].append(str(exc))
    else:
        raise AssertionError('an undeclared same-family variant was accepted')
    (out / 'variant_selftest.json').write_text(json.dumps(report, indent=2))
    print('PASS per-variant parts, contracts, exports and base geometry', flush=True)


if __name__ == '__main__':
    main()
