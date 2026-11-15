"""Replay audit sh_06 and log the live streak emitters without changing them.

Requires the preserved audit2 checkout on the PC. It must match the audit pin.
The wrapper only records calls; the original functions still emit every streak.
"""
import argparse
from collections import Counter
import json
import os
from pathlib import Path
import subprocess
import tempfile

REPO = Path(__file__).resolve().parents[4]
PIN = '70e87f2345adf171f4dd7a1a5aa52ac1d43e8338'
FX_TRACE = '''extends "res://fx/fx.gd"
var trace_origin := "warmup"
var trace_streaks: Array = []
func shield_break(id: String, quad: int) -> void:
	trace_origin = "break_" + id
	super.shield_break(id, quad)
func stk(p: Vector3, t: float, life: float, col: Color, i: float, length: float, w: float, kind: int, vel: Vector3,
		drag := 0.0, acc := 0.0, wpx := 0.0, lpx := 0.0) -> void:
	trace_streaks.append({"origin": trace_origin, "p": p, "t": t, "life": life,
		"colour": [col.r, col.g, col.b], "kind": kind, "velocity": vel,
		"length": length, "drag": drag, "stack": get_stack()})
	super.stk(p, t, life, col, i, length, w, kind, vel, drag, acc, wpx, lpx)
'''
DUMP = '''func _capture(path: String) -> void:
	var active: Array = []
	for rec in fx.trace_streaks:
		var age: float = fx.now - float(rec.t)
		if age < 0.0 or age >= float(rec.life):
			continue
		var row: Dictionary = rec.duplicate()
		if int(rec.kind) == 1:
			var vel: Vector3 = rec.velocity
			var decay := exp(-float(rec.drag) * age)
			var head: Vector3 = rec.p + vel * (1.0 - decay) / maxf(float(rec.drag), 0.0001)
			var tail: Vector3 = head - vel.normalized() * maxf(float(rec.length) * vel.length() * decay, 0.05)
			var h := cam.unproject_position(head)
			var t := cam.unproject_position(tail)
			row["head_px"] = [h.x, h.y]
			row["tail_px"] = [t.x, t.y]
			row["axis_px"] = h.distance_to(t)
		active.append(row)
	var f := FileAccess.open(path.get_base_dir().path_join("active_streaks.json"), FileAccess.WRITE)
	f.store_string(JSON.stringify({"clock": clock, "fx_now": fx.now, "active": active}, " "))
	f.close()
'''


def summarise(out):
    from PIL import Image, ImageDraw, ImageFont
    proof = json.loads((out/'active_streaks.json').read_text())
    green = [r for r in proof['active'] if r['kind'] == 1 and r['colour'][1] > r['colour'][0] + .05
             and r.get('axis_px', 0) > 50]
    assert green, 'No long green streaks reproduced'
    summary = dict(audit_pin=PIN, clock=proof['clock'],
        live_kind1_by_origin=dict(Counter(r['origin'] for r in proof['active'] if r['kind'] == 1)),
        long_green_count=len(green), long_green_origins=sorted({r['origin'] for r in green}),
        projected_axis_px_range=[min(r['axis_px'] for r in green), max(r['axis_px'] for r in green)],
        green_stack=green[0]['stack'])
    (out/'attribution_summary.json').write_text(json.dumps(summary, indent=2))
    source = Image.open(out/'g17_shield_break_hegemony.png').convert('RGB')
    sheet = Image.new('RGB', (1280, 720), '#0b1019')
    sheet.paste(source.resize((1226, 690), Image.Resampling.LANCZOS), (27, 30))
    font = ImageFont.truetype('C:/Windows/Fonts/consola.ttf', 18)
    ImageDraw.Draw(sheet).text((10, 5),
        f'sh_06 / AUDIT REPLAY / {len(green)} LONG GREEN SPORE SPARKS / ATTRIBUTION ONLY',
        font=font, fill='#f1d7a0')
    sheet.save(out/'sh_06_attribution.png')
    print('Live long green streaks:', summary['long_green_origins'], 'count', len(green))


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--out', type=Path, required=True)
    parser.add_argument('--summarise-only', action='store_true')
    parser.add_argument('--project', type=Path,
        default=Path.home() / 'Downloads/voidsworn_test/audit2/repo/godot')
    args = parser.parse_args()
    if args.summarise_only:
        summarise(args.out)
        return
    for name in ['fx/gallery/gallery.gd', 'fx/fx.gd', 'fx/fx_shaders.gd', 'fx/fx_weapons.gd', 'fx/fx_ship.gd']:
        expected = subprocess.check_output(['git', 'show', PIN + ':godot/' + name], cwd=REPO).decode()
        assert (args.project / name).read_text() == expected, 'Audit source drift: ' + name
    scratch = Path(tempfile.mkdtemp(prefix='voidsworn-367-trace-'))
    args.out.mkdir(parents=True, exist_ok=True)
    (scratch / 'trace_fx.gd').write_text(FX_TRACE)
    code = (args.project / 'fx/gallery/gallery.gd').read_text()
    code = code.replace('preload("res://fx/fx.gd")', 'preload("' + (scratch/'trace_fx.gd').as_posix() + '")')
    code = code.replace('\tvar r: Dictionary = fx.volley(a, kind, t, opts)',
        '\tfx.trace_origin = name\n\tvar r: Dictionary = fx.volley(a, kind, t, opts)')
    code = code.replace('\t_build_ships()\n', '''\t_build_ships()
	for sid in ships:
		var ship = ships[sid]
		var man: Dictionary = SV.manifest()
		var found := false
		for group in ["ships", "hi", "hulls"]:
			if man.has(group) and man[group].has(ship.code):
				found = found or ResourceLoader.exists(man[group][ship.code]["res"])
		if not found:
			push_error("TRACE placeholder hull: " + str(ship.code))
			get_tree().quit(3)
			return
''')
    code = code.replace('func _capture(path: String) -> void:', DUMP)
    (scratch / 'gallery.gd').write_text(code)
    (scratch / 'driver.gd').write_text('extends SceneTree\nfunc _initialize() -> void:\n\t_run.call_deferred()\nfunc _run() -> void:\n\troot.add_child(load("' +
        (scratch/'gallery.gd').as_posix() + '").new())\n')
    env = dict(os.environ, APPDATA=str(scratch/'profile'), LOCALAPPDATA=str(scratch/'profile'))
    godot = Path.home()/'Downloads/voidsworn_test/godot/Godot_v4.7.2-stable_win64_console.exe'
    cmd = [str(godot), '--path', str(args.project), '--fixed-fps', '60', '--debug',
        '--rendering-method', 'forward_plus', '--windowed', '--position', '-4000,-4000',
        '--resolution', '1920x1080', '--log-file', str(scratch/'engine.txt'),
        '--script', str(scratch/'driver.gd'), '--', '--shots', str(args.out),
        '--res', '2560x1440', '--quality', 'max', '--only', 'g17_shield_break_hegemony.png']
    print('LOG', scratch/'console.txt', flush=True)
    with (scratch/'console.txt').open('w') as log:
        result = subprocess.run(cmd, env=env, stdout=log, stderr=subprocess.STDOUT,
            creationflags=subprocess.CREATE_NO_WINDOW, timeout=420)
    text = (scratch/'console.txt').read_text(errors='replace')
    print(text[-2000:])
    assert result.returncode == 0, result.returncode
    summarise(args.out)


if __name__ == '__main__':
    main()
