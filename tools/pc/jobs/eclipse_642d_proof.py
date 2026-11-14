"""Issue 642 round 3 CPU proof on Blender 4.5. No GPU, installs, commits or deletes.
Run with Blender's Python: eclipse_642d_proof.py REPO NEW_TEMP_DIR.
The Board's GPU job is E11_E12_PAINT_642d.bat. This proof is deliberately separate.
"""
import hashlib
import json
import os
from pathlib import Path
import subprocess
import sys


def camera_pairs(sheets, concept, paint, pictures, cell):
    """Keep true 640x360 game-camera pixels beside the concept, named and below 720 pixels tall."""
    sys.path.insert(0, str(sheets))
    import paint_compare as pc
    from PIL import Image
    for radius in (170, 60):
        image = Image.new('RGB', (1280, 420), pc.BG)
        pc.head(image, f'{cell}, camera {radius}: concept (left), CPU game-light preview (right)',
                'Blender 4.5 CPU, lift 2.2, true game pixel size; actual in-game capture awaits the Board GPU job')
        image.paste(pc.fit(Image.open(concept).convert('RGB'), 636, 360), (0, 60))
        image.paste(Image.open(paint / f'paint_cam{radius}.png').convert('RGB'), (640, 60))
        image.save(pictures / f'{cell}_paint_cam{radius}.jpg', quality=95)


def main():
    repo, out = (Path(a).resolve() for a in sys.argv[1:3])
    out.mkdir(parents=True, exist_ok=True)
    v = Path.home() / 'Downloads/voidsworn_test'
    blender = v / 'blender/blender-4.5.14-windows-x64/blender.exe'
    py = blender.parent / '4.5/python/bin/python.exe'
    recipe = repo / 'tools/recipe'
    r209 = repo / 'tools/blender/r209'
    sheets = repo / 'tools/blender/build_sheets'
    env = dict(os.environ, PYTHONDONTWRITEBYTECODE='1', E642_REPO=str(repo))
    result = {}

    def run(tag, cmd, extra=None):
        with (out / (tag + '.txt')).open('w') as log:
            p = subprocess.run([str(a) for a in cmd], env=dict(env, **(extra or {})), cwd=repo,
                               stdout=log, stderr=subprocess.STDOUT)
        result[tag] = p.returncode
        (out / 'result.json').write_text(json.dumps(result, indent=2))
        print(tag, 'PASS' if p.returncode == 0 else 'FAIL', flush=True)
        if p.returncode: raise SystemExit(p.returncode)

    def blend(tag, script, args, source=None, extra=None):
        cmd = [blender, '-b'] + ([source] if source else [])
        run(tag, cmd + ['-t', '8', '--python-exit-code', '1', '-P', script, '--'] + args, extra)

    cpu = out / 'cpu_bake.py'
    cpu.write_text("""import os,sys,runpy,types
import bpy
repo=os.environ['E642_REPO']
sys.path[:0]=[os.path.join(repo,'tools','blender','kits','shared'),os.path.join(repo,'tools','blender','r209')]
if os.environ.get('E642_BASELINE'):
    m=types.ModuleType('paint_stack'); m.__file__=os.path.join(repo,'tools','blender','kits','shared','paint_stack.py')
    sys.modules['paint_stack']=m
    exec(compile(open(os.environ['E642_BASELINE']).read(),m.__file__,'exec'),m.__dict__)
import paint_stack
def cpu(samples):
    sc=bpy.context.scene; sc.render.engine='CYCLES'; sc.cycles.samples=samples; sc.cycles.device='CPU'
    return 'CPU'
paint_stack.gpu=cpu
runpy.run_path(os.path.join(repo,'tools','blender','r209','bake_sheet.py'),run_name='__main__')
""")
    preview = out / 'preview.py'
    # A16 uses the exact previous machinery and the changed machinery with the same Blender and inputs.
    baseline = out / 'paint_stack_main.py'
    baseline.write_bytes(subprocess.check_output(['git', 'show',
        'f1424dd69e6c5b9cf193e59ecd9279d7d93a04fa:tools/blender/kits/shared/paint_stack.py'], cwd=repo))
    for name in ('before', 'after'):
        a16 = out / ('A16_' + name)
        blend('A16_' + name, cpu, [a16, 'none', 'none', 'A16', '256', '2'], extra={
            'R209_SHIP': str(recipe / 'ships/corsair_A16.json'),
            'E642_BASELINE': str(baseline) if name == 'before' else ''})
    hashes = {}
    for path in (out / 'A16_before').rglob('*.png'):
        rel = path.relative_to(out / 'A16_before'); other = out / 'A16_after' / rel
        a, b = (hashlib.sha256(p.read_bytes()).hexdigest() for p in (path, other))
        assert a == b, str(rel)
        hashes[str(rel)] = a
    (out / 'A16_byte_proof.json').write_text(json.dumps(hashes, indent=2))
    print('A16 all PNG maps and drawn textures byte-identical:', len(hashes), flush=True)

    for cell, code in [('E12', 'D21_23'), ('E11', 'D22_23')]:
        ship = 'deathless_' + cell
        shipj = recipe / 'ships' / (ship + '.json')
        env['R209_SHIP'] = str(shipj)
        job = out / cell
        job.mkdir(exist_ok=True)
        build = job / 'build'; source = job / (cell + '.blend')
        blend(cell + '_4_build', r209 / 'sheet_hull.py', [build, cell])
        blend(cell + '_4_contract', recipe / 'sheet_contract_selftest.py', [shipj, build])
        blend(cell + '_4_audit', recipe / 'audit.py', [job / 'audit.json'], build / (cell + '.blend'))
        blend(cell + '_4_selftest', recipe / 'audit_selftest.py', [job / 'audit_selftest'], build / (cell + '.blend'))
        blend(cell + '_5_bake', cpu, [job, 'none', 'none', cell, '2048', '6'])
        assert json.loads((job / (cell + '.json')).read_text())['paint']['device'] == 'CPU'
        blend(cell + '_5_surface', recipe / 'surface_check.py', [job / 'surface'], source)
        for check in ('licences', 'lights'):
            run(cell + '_5_' + check, [py, recipe / 'standing.py', check, '--ship', shipj, '--job', job])
        blend(cell + '_6_lod', r209 / 'export3.py', [job / 'glb' / (cell + '.glb')], source)
        export = job / 'export' / code
        blend(cell + '_7_export', recipe / 'export7.py', [shipj, export, 'maps=2048'], source)
        run(cell + '_7_check', [py, recipe / 'check_export.py', shipj, export])
        run(cell + '_7_selftest', [py, recipe / 'check_export_selftest.py', shipj, export])
        concept = repo / 'contrib/muse/design/concept_round8c_2026_11' / (ship + '_beauty.jpg')
        paint = job / 'paint'
        # Wrapper removes its own argument so paint_sheet sees its usual CLI; it then adds camera 60.
        preview.write_text("""import runpy,bpy,sys
a=sys.argv.index('--')+1
script=sys.argv.pop(a)
m=runpy.run_path(script)
c=bpy.context.scene.camera; c.location *= 60.0/170.0
m['shoot'](c,'paint_cam60',1.0)
""")
        blend(cell + '_pictures', preview, [sheets / 'paint_sheet.py', paint, ship, concept, 'lift=2.2',
                                           'samples=12', 'scale=0.5', 'sky_spec=0', 'cam170=1'], source)
        run(cell + '_compare', [py, sheets / 'paint_compare.py', paint, concept, '-', code, job / 'pictures',
                               'name=' + cell, 'stack=Eclipse', 'issue=642'])
        camera_pairs(sheets, concept, paint, job / 'pictures', cell)
    run('fixture', [py, recipe / 'sheet_fixture_hash.py', '--check'])
    print('CPU PROOF PASS: stage 4 contract/audit/selftest, stage 5 bake/surface/licences/lights, stage 6 LOD, stage 7 export/check/selftest.', flush=True)
    print('GPU scene gate, install and actual in-game pictures belong to the Board job.', flush=True)


if __name__ == '__main__':
    main()
