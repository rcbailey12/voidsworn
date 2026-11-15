"""Run the unchanged R116 scene gate. Output is supplied by the caller."""
import argparse
import os
from pathlib import Path
import subprocess
import tempfile

REPO = Path(__file__).resolve().parents[4]
GODOT = Path.home() / 'Downloads/voidsworn_test/godot/Godot_v4.7.2-stable_win64_console.exe'

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--out', required=True)
    parser.add_argument('--project', type=Path, default=REPO / 'godot')
    parser.add_argument('--sessions', type=int, default=3)
    args = parser.parse_args()
    scratch = Path(tempfile.mkdtemp(prefix='voidsworn-367-gate-'))
    out = Path(args.out).resolve()
    out.mkdir(parents=True, exist_ok=True)
    env = dict(os.environ)
    # Keep the real profile and save files out of all benchmark runs.
    env['APPDATA'] = env['LOCALAPPDATA'] = str(scratch / 'profile')
    cmd = [str(GODOT), '--path', str(args.project), '--rendering-method', 'forward_plus',
           '--windowed', '--position', '-4000,-4000', '--resolution', '1920x1080',
           '--disable-vsync', '--log-file', str(scratch / 'engine.log'),
           'res://bench/scene_gate.tscn', '--', '--out', str(out),
           '--sessions', str(args.sessions), '--warmup', '120', '--frames', '360', '--modes', 'base,res_2160']
    print(f'LOG {scratch / "console.txt"}', flush=True)
    with (scratch / 'console.txt').open('w') as log:
        r = subprocess.run(cmd, env=env, stdout=log, stderr=subprocess.STDOUT,
            creationflags=getattr(subprocess, 'CREATE_NO_WINDOW', 0), timeout=1200)
    text = (scratch / 'console.txt').read_text(errors='replace')
    print(text[-5000:])
    if r.returncode or not (out / 'scene_gate.json').exists():
        raise SystemExit(r.returncode or 1)
