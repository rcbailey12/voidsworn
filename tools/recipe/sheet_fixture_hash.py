"""Check the A16 seam fixture, or rebuild the fixture and its record together.

   python tools/recipe/sheet_fixture_hash.py --check
   python tools/recipe/sheet_fixture_hash.py --bake BLENDER_EXE
   python tools/recipe/sheet_fixture_hash.py --bake BLENDER_EXE --out DIR

--out DIR bakes a fresh pair into DIR and leaves the committed fixture alone (issue 1174: CI bakes into its temp folder when
the record is stale, then runs death_seam_check.gd on DIR/C19_51_unbaked.glb.gz). --check --quiet-stale exits 3, not 1,
when the record is only stale, so CI can tell "rebake" from a broken record.

The first record line, file list and data.js extract also feed death_seam_check.gd.
The last line pins the exact gzip bytes used by the CI fixture check.
"""
import argparse
import gzip
import hashlib
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile

HERE = Path(__file__).resolve().parent
REPO = HERE.parent.parent
sys.path.insert(0, str(HERE))
HULL_BUILDER = 'tools/blender/r209/sheet_hull.py'
EXPORTER = 'tools/recipe/export7.py'
SHIP_JSON = 'tools/recipe/ships/corsair_A16.json'
FILES = (
    'tools/blender/build_sheets/ships/corsair_A16.py',
    'tools/blender/build_sheets/kit.py',
    'tools/blender/kits/hullbreakers/parts.py',
    'tools/blender/build_sheets/contract.py',
    'tools/blender/build_sheets/variants.py',
    EXPORTER, HULL_BUILDER, SHIP_JSON,
    'tools/blender/kits/shared/hardpoints.py',
    'tools/blender/kits/shared/turrets.py',
    'tools/recipe/gamedata.py',
)
OUT = REPO / 'godot/fx/test/fixtures/C19_51_unbaked.sheet.txt'
FIXTURE = OUT.with_name('C19_51_unbaked.glb.gz')
EXTRACT_MARK = '# data.js entry %s: the fields the build reads (tools/recipe/gamedata.py), sorted keys, JSON'


def extract():
    """Hash the A16 fields used by the build, so unrelated rules edits do not mark it stale."""
    import gamedata
    with (REPO / SHIP_JSON).open(encoding='utf-8') as source:
        ship = json.load(source)
    game = ship['game_ship']
    fields = dict(cls=gamedata.ship_attr(game, 'cls', default='Cruiser'),
                  fac=gamedata.ship_attr(game, 'fac', default=ship.get('faction')),
                  hangar=int(gamedata.ship_attr(game, 'hangar', default=0) or 0),
                  weapons=[list(w) for w in gamedata.weapons(game)])
    return json.dumps(fields, sort_keys=True, separators=(',', ':')), game


def digest(text):
    h = hashlib.sha256()
    for name in FILES:
        h.update((REPO / name).read_bytes().replace(b'\r\n', b'\n'))
    h.update((text + '\n').encode('utf-8'))
    return h.hexdigest()


def record(text, game, input_digest, fixture_bytes):
    fixture_digest = hashlib.sha256(fixture_bytes).hexdigest()
    return '\n'.join((f'sha256 {input_digest}', *FILES, EXTRACT_MARK % game, text,
                      f'# fixture sha256 {fixture_digest}', ''))


class Stale(ValueError):
    """The record no longer matches the A16 inputs or the compressed GLB: a rebake fixes it."""


def check(out=None, fixture=None):
    out, fixture = out or OUT, fixture or FIXTURE
    text, game = extract()
    expected = record(text, game, digest(text), fixture.read_bytes())
    if out.read_text(encoding='utf-8') != expected:
        raise Stale('fixture record is stale or the compressed GLB changed. Rebuild with --bake.')
    print('PASS fixture record matches the A16 inputs and compressed GLB')


def bake(blender, dest=None):
    text, game = extract()
    input_digest = digest(text)
    ship_path = REPO / SHIP_JSON
    ship = json.loads(ship_path.read_bytes())
    work = Path(tempfile.mkdtemp(prefix='a16-fixture-'))
    export = work / 'export'
    env = dict(os.environ, R209_SHIP=str(ship_path))

    def run_blender(*args):
        command = [blender, *map(str, args)]
        if os.name == 'nt':
            watchdog = REPO / 'tools/pc/tmo.bat'
            command = [str(watchdog), '21600', *command]
        subprocess.run(command, cwd=REPO, env=env, check=True)

    run_blender('-b', '--python-exit-code', '1', '-P', REPO / HULL_BUILDER, '--', work, ship['cell'])
    run_blender('-b', work / (ship['cell'] + '.blend'), '--python-exit-code', '1', '-P', REPO / EXPORTER,
                '--', ship_path, export, 'maps=2048', 'unbaked=1')
    if not (export / 'export_status.txt').read_text(encoding='utf-8').startswith('WRITTEN '):
        raise ValueError(f'A16 export was not written. See {work}')
    glb = (export / (ship['game_code'] + '.glb')).read_bytes()
    if not glb.startswith(b'glTF'):
        raise ValueError(f'A16 export is not a GLB. See {work}')
    if extract() != (text, game) or digest(text) != input_digest:
        raise ValueError('A16 inputs changed during the bake. Run it again.')
    compressed = gzip.compress(glb, compresslevel=9, mtime=0)
    # Stage both files on the destination volume. An interrupted publish is
    # caught by --check, since the record describes one exact compressed file.
    out, fixture = (OUT, FIXTURE) if dest is None else (Path(dest) / OUT.name, Path(dest) / FIXTURE.name)
    out.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.NamedTemporaryFile(dir=out.parent, delete=False) as output:
        output.write(compressed)
    with tempfile.NamedTemporaryFile(dir=out.parent, delete=False) as metadata:
        metadata.write(record(text, game, input_digest, compressed).encode('utf-8'))
    os.replace(output.name, fixture)
    os.replace(metadata.name, out)
    check(out, fixture)
    print(f'BAKED {fixture}')


def main():
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    mode = parser.add_mutually_exclusive_group(required=True)
    mode.add_argument('--check', action='store_true')
    mode.add_argument('--bake', metavar='BLENDER_EXE')
    parser.add_argument('--out', metavar='DIR', help='with --bake: write the fresh pair here, not over the committed one')
    parser.add_argument('--quiet-stale', action='store_true', help='with --check: exit 3 when the record is only stale')
    args = parser.parse_args()
    if args.out and not args.bake:
        parser.error('--out goes with --bake')
    try:
        if args.check:
            check()
        else:
            bake(args.bake, args.out)
    except Stale as exc:
        print('STALE' if args.quiet_stale else 'FAIL', exc)
        return 3 if args.quiet_stale else 1
    except (OSError, ValueError, subprocess.CalledProcessError) as exc:
        print('FAIL', exc)
        return 1
    return 0


if __name__ == '__main__':
    sys.exit(main())
