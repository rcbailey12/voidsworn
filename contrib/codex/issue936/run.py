"""Repaint one capital at a time through recipe stages 5, 6 and 7.

Run with the PC's Python. Scratch logs stay in TEMP; review evidence goes to
board_b/issue-936/shots. Resume with --start A18, or --only A16.
"""
import argparse
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import time

REPO = Path(__file__).resolve().parents[3]
PC = REPO.parents[1]
PROOF = PC / 'board_b/issue-936/shots'
SCRATCH = Path(tempfile.gettempdir()) / 'voidsworn936'
BLENDER = PC / 'blender/blender-4.5.14-windows-x64/blender.exe'
GODOT = PC / 'godot/Godot_v4.7.2-stable_win64_console.exe'
PLAYABLE = PC / 'build/godot'
SHIPS = ['A16', 'A17', 'A18', 'A19', 'A20']
ENV = dict(os.environ, RECIPE_NOPAUSE='1', PC_GPU_ISSUE='936', PC_GPU_LANE='B',
           PICTURE_SOURCE_REPO=str(REPO), PICTURE_STAMP_TOOL=str(REPO / 'tools/picture_provenance.py'),
           PICTURE_PYTHON=shutil.which('python'), TMO_REPO='', TMO_OUT='', TMO_LOG='', TMO_ERR_LOG='')


def run(label, args, marker=None):
    log = SCRATCH / (label + '.log')
    print('START', label, flush=True)
    started = time.time()
    with log.open('w') as stream:
        p = subprocess.run([str(v) for v in args], cwd=REPO, env=ENV,
                           stdout=stream, stderr=subprocess.STDOUT)
    content = log.read_text(errors='replace')
    if p.returncode or (marker and marker not in content):
        raise RuntimeError(f'{label}: exit {p.returncode}, marker {marker!r}; {log}\n{content[-3000:]}')
    print('PASS', label, round(time.time() - started, 1), 'seconds', flush=True)


def blender(label, *args):
    run(label, [REPO / 'tools/pc/tmo.bat', '21600', BLENDER, '-b',
                '--python-exit-code', '1', *args], 'PASS issue936 captures')


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--start', choices=SHIPS, default='A16')
    ap.add_argument('--only', choices=SHIPS)
    ap.add_argument('--stage', type=int, choices=(5,6,7,8), default=5,
                    help='Resume at a recipe stage; 8 resumes installation and pictures')
    args = ap.parse_args()
    PROOF.mkdir(parents=True, exist_ok=True); SCRATCH.mkdir(parents=True, exist_ok=True)
    if not (PC / 'gpu_go.txt').read_text().startswith('GPU cleared'):
        raise RuntimeError('GPU is not cleared')
    print('Logs:', SCRATCH, flush=True)
    for cell in SHIPS[SHIPS.index(args.start):]:
        if args.only and cell != args.only:
            continue
        name = 'corsair_' + cell
        cfg = json.loads((REPO / f'tools/recipe/ships/{name}.json').read_text())
        code = cfg['game_code']; job = PC / 'recipe' / name
        out = PROOF / cell; out.mkdir(exist_ok=True)
        ENV['SHIP'] = name
        ENV['R209_SHIP'] = str(REPO / f'tools/recipe/ships/{name}.json')
        # Preserve main's paint before the normal recipe rebuilds the sheet.
        before = out / 'before'
        if not (before / 'engines.png').is_file():
            blender(cell + '_before', job / f'{cell}.blend', '-P', Path(__file__).with_name('capture.py'),
                    '--', before, name, REPO / cfg['concept'])
        for stage in ('5_paint_bake', '6_lod', '7_export'):
            if int(stage[0]) < args.stage:
                continue
            ENV['INSTALL_TO'] = str(REPO / 'godot')
            run(cell + '_' + stage, ['cmd.exe', '/d', '/c', REPO / f'tools/recipe/{stage}.bat'],
                'Stage ' + stage[0] + ' done:')
        # Same checked export installed into the playable game, with the recipe's
        # backup, manifest merge, cache refresh and ShipView readback.
        ENV['INSTALL_TO'] = str(PLAYABLE)
        run(cell + '_playable', ['cmd.exe', '/d', '/c', REPO / 'tools/recipe/7_export.bat'],
            'Stage 7 done: PASS')
        blender(cell + '_after', job / f'{cell}.blend', '-P', Path(__file__).with_name('capture.py'),
                '--', out / 'after', name, REPO / cfg['concept'])
        run(cell + '_game', [REPO / 'tools/pc/tmo.bat', '1800', GODOT, '--path', REPO / 'godot',
                            '--resolution', '1920x1080', 'res://assets/ships/test/a4_shots.tscn',
                            '--', '--out', SCRATCH / cell / 'game', '--facs', 'corsair', '--sets', 'cams', '--codes', code],
            '[a4shots] done')
        # Raw 1080p captures stay in TEMP; review.py delivers 720p sheets.
        # Copy the facts used in the review, never the large working blend/maps.
        for relative in (f'{cell}.json', 'density.json', 'audit.json', 'lights.json',
                         'surface/surface_check.json', f'export/{code}/{code}_check.json',
                         f'export/{code}/{code}_export.json', f'export/{code}/manifest_entry.json'):
            source = job / relative
            if source.is_file():
                shutil.copy2(source, out / source.name)
        print('DONE', cell, flush=True)


if __name__ == '__main__':
    main()
