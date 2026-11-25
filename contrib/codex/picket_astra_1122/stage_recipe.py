"""Stage this blind build in a private recipe tree. Stock launchers retain their own checks and GPU claims."""
import argparse
import os
from pathlib import Path
import shutil
import subprocess
import tempfile

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
SHIP = 'hegemony_H7A'


def prepare(runtime, job):
    def copy(source, relative=None):
        target = runtime / (relative or source.relative_to(ROOT))
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(source, target)

    # Copy code only. Import paths in the recipe are relative to the private tree.
    for folder in ('tools/recipe', 'tools/blender/build_sheets', 'tools/blender/r209',
                   'tools/blender/hs', 'tools/blender/a1', 'tools/blender/hull_repair',
                   'tools/blender/kits/shared', 'tools/blender/kits/hegemony',
                   'tools/blender/kits/hullbreakers'):
        for source in (ROOT / folder).glob('*'):
            if source.is_file() and source.suffix in ('.py','.bat','.json'):
                copy(source)
    for relative in ('tools/pc/tmo.bat','tools/pc/trellis_fleet.py',
                     'tools/blender/r209/godot/project.godot','tools/blender/r209/godot/bench209r3.gd',
                     'godot/render/look.gd','godot/fx/faction_looks.json','godot/rules/data/tables.json',
                     'godot/tools/picture_provenance.gd',
                     'contrib/muse/design/class_family_hegemony_2026_11/picket_beauty.webp'):
        copy(ROOT / relative)
    copy(HERE / (SHIP+'.py'), Path('tools/blender/build_sheets/ships') / (SHIP+'.py'))
    copy(HERE / (SHIP+'.json'), Path('tools/recipe/ships') / (SHIP+'.json'))
    # Stamps must hash this checkout, which owns the uncommitted sheet. Also handle
    # the explicit --repo argument from the isolated stage 6 Godot project.
    provenance = runtime / 'tools/picture_provenance.py'
    provenance.write_text(
        'import runpy, sys\nfrom pathlib import Path\n'
        f'root = Path({str(ROOT)!r})\n'
        "if '--repo' in sys.argv: sys.argv[sys.argv.index('--repo')+1] = str(root)\n"
        "globals().update(runpy.run_path(str(root/'tools/picture_provenance.py'), run_name=__name__))\n",
        encoding='utf-8')
    env = runtime / 'tools/recipe/env.bat'
    env.write_text(env.read_text().replace(r'set JOB=%V%\recipe\%SHIP%', f'set "JOB={job}"'))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--first', type=int, choices=range(1,8), default=1)
    parser.add_argument('--last', type=int, choices=range(1,8), default=7)
    args = parser.parse_args()
    if args.first > args.last:
        parser.error('first stage must be at or before the last')
    scratch = Path(tempfile.gettempdir()) / 'picket-astra-1732'
    runtime, job = scratch / 'source', scratch / 'job'
    prepare(runtime, job)
    env = dict(os.environ, SHIP=SHIP, RECIPE_NOPAUSE='1', INSTALL_TO='', PYTHONDONTWRITEBYTECODE='1')
    if env.get('PC_GPU_MODE', '').lower() == 'none':
        del env['PC_GPU_MODE']
    for number in range(args.first, args.last+1):
        stage, = (runtime/'tools/recipe').glob(f'{number}_*.bat')
        subprocess.run([str(stage)], cwd=runtime, env=env, check=True)
    print(f'Picket recipe output in {job}')


if __name__ == '__main__':
    main()
