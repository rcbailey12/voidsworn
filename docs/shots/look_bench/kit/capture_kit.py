"""Issue 367 capture adapter. Reuses the standing bench and real public calls.

python capture_kit.py --out DIR [--only ID] [--skip-row-warm]
Scratch scripts and logs stay in TEMP. No game source is edited by this adapter.
"""
import argparse
import json
import os
from pathlib import Path
import subprocess
import tempfile
import time

REPO = Path(__file__).resolve().parents[4]
GODOT = Path.home() / 'Downloads/voidsworn_test/godot/Godot_v4.7.2-stable_win64_console.exe'
SPEC = [
    ('doom', 'deathless', 'lance', 'doom'),
    ('macro', 'voidsworn', 'battery', 'hbattery'),
    ('auto', 'hegemony', 'battery', 'autocannon'),
    ('las', 'voidsworn', 'battery', 'turret'),
    ('plasma', 'hegemony', 'battery', 'hturbo'),
    ('scatter', 'corsair', 'battery', 'scatter'),
    ('prism', 'ithar', 'battery', 'shard'),
    ('needle', 'ithar', 'battery', 'turret'),
    ('lance', 'voidsworn', 'lance', 'lance'),
    ('ion', 'hegemony', 'lance', 'ion'),
    ('pulsar', 'ithar', 'lance', 'pulsar'),
    ('tendril', 'chorus', 'bio', 'tendril'),
    ('gauss', 'deathless', 'gauss', 'gauss'),
    ('torp', 'voidsworn', 'torp', 'torp'),
    ('rockets', 'corsair', 'torp', 'torp'),
    ('star', 'ithar', 'torp', 'startorp'),
    ('flak', 'corsair', 'flak', 'flak'),
    ('pflak', 'hegemony', 'flak', 'flak'),
    ('mflak', 'ithar', 'flak', 'flak'),
    ('gflak', 'deathless', 'flak', 'gsentry'),
    ('spores', 'chorus', 'flak', 'spores'),
    ('bioplasma', 'chorus', 'bio', 'bioplasma'),
    ('guns', 'hegemony', 'sq', 'guns'),
    ('bombs', 'voidsworn', 'sq', 'bombs'),
    ('sporeb', 'chorus', 'sq', 'sporeb'),
]


def rows():
    result = []
    for name, faction, kind, weapon in SPEC:
        result.append(dict(id=name, label=name, group='weapon kit',
            att=[faction, 'Cruiser'], tgt=['hegemony', 'Cruiser'],
            do='volley', kind=kind, weapon=weapon, shots=1, on='hull',
            focus='path', windows=[['fire', 0.0, 66]], key=30))
    for kind in [0, 1, 3]:
        result.append(dict(id=f'ribbon_{kind}', label=f'ribbon {kind}', group='nozzle shader sample',
            att=['corsair' if kind == 3 else 'voidsworn', 'Cruiser'],
            tgt=['hegemony', 'Cruiser'], do='kit_ribbon', ribbon=kind,
            focus='attacker_engines', engine=0.0,
            windows=[['event', 0.0, 66]], key=20))
    for name, faction in [('torp_intercept', 'voidsworn'), ('rocket_intercept', 'corsair'), ('star_intercept', 'ithar')]:
        result.append(dict(id=name, label=name, group='point defence', att=[faction, 'Cruiser'],
            tgt=['hegemony', 'Cruiser'], do='volley', kind='torp',
            weapon='startorp' if faction == 'ithar' else 'torp', shots=1, pd=True,
            on='hull', focus='path', windows=[['fire', 0.0, 66]], key=35))
    result.append(dict(id='torp_lane', label='travelling torpedo', group='weapon kit',
        att=['voidsworn', 'Cruiser'], tgt=['hegemony', 'Cruiser'], do='kit_lane',
        focus='path', windows=[['event', 0.0, 66]], key=30))
    result.append(dict(id='moving_trail', label='curved engine history', group='engine kit',
        att=['voidsworn', 'Cruiser'], tgt=['hegemony', 'Cruiser'], do='kit_move',
        focus='attacker_engines', engine=1.2, windows=[['event', 0.0, 66]], key=30))
    for faction in ['voidsworn', 'hegemony', 'ithar', 'corsair']:
        result.append(dict(id=f'flakes_{faction}', label=f'shield {faction}', group='shield flakes',
            att=['deathless', 'Cruiser'], tgt=[faction, 'Cruiser'], do='kit_break',
            focus='target', windows=[['event', 0.0, 66]], key=12))
    result.append(dict(id='bay', label='craft launch', group='weapon kit',
        att=['voidsworn', 'Carrier'], tgt=['hegemony', 'Cruiser'], do='launch',
        focus='attacker', windows=[['event', 0.0, 66]], key=12))
    original = json.loads((REPO / 'godot/bench/look_moments.json').read_text())
    result += [r for r in original['rows'] if r['id'] in
        ['p_las_muzzle', 'p_prism_muzzle', 'p_missile_launch', 'p_torp_shield',
         'p_lance_burn', 'p_bile_hit', 'p_gauss_exit', 'p_crit']]
    return result


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--out', required=True)
    parser.add_argument('--only')
    parser.add_argument('--project', type=Path, default=REPO / 'godot')
    parser.add_argument('--skip-row-warm', action='store_true')
    parser.add_argument('--cameras', default='170,60,26')
    args = parser.parse_args()
    out = Path(args.out).resolve()
    out.mkdir(parents=True, exist_ok=True)
    scratch = Path(tempfile.mkdtemp(prefix='voidsworn-367-'))
    cfg = dict(cameras=[int(c) for c in args.cameras.split(',')], cell=[640, 360],
        crop={'170': [640, 360], '60': [1920, 1080], '26': [1920, 1080]}, rows=rows())
    (scratch / 'rows.json').write_text(json.dumps(cfg, indent=1))
    code = (REPO / 'godot/bench/look_bench.gd').read_text()
    # The stock bench keeps every second frame. The tracer proof needs 60 Hz.
    code = code.replace('w["next"] = steps + 2', 'w["next"] = steps + (1 if id in ["gauss", "gflak"] else 2)')
    code = code.replace('focus += Vector3(float(fo[0]), 0.0, float(fo[1]))',
        'focus += Vector3(float(fo[0]), 0.0, float(fo[1]))\n\tif row.get("focus", "") == "path":\n\t\tfocus = (A.global_position + T.global_position) * 0.5')
    # Isolated shield breaks have no preceding volley to confuse attribution.
    # Nozzle samples use the real hull nozzle and the public ribbon pool.
    code = code.replace('shots.append(true)', 'shots.append(not bool(row.get("pd", false)))')
    code = code.replace('"slot": int(row.get("slot", -1)),', '"slot": int(row.get("slot", -1)), "pd": 1 if bool(row.get("pd", false)) else 0,')
    code = code.replace('elif what == "break":', '''elif what == "kit_lane":
		fx.torp_lane("kit", "A", T.global_position, 2)
		fx.torp_launch("kit")
	elif what == "kit_move":
		A.play_moves([{"kind": "run", "w": 1.0, "yaw": 0.0, "pts": [A.position, A.position + Vector3(8, 0, 3), A.position + Vector3(20, 0, 7)]}], 2.0)
		A.set_meta("kit_move", true)
	elif what == "kit_break":
		var target_ship = fx.ship("T")
		if target_ship == null or target_ship._shield_mat == null:
			_placeholder("shield-break fixture has no live shield")
			return false
		fx.shield_break("T", 3)
	elif what == "kit_ribbon":
		var sh = fx.ship("A")
		if sh.hull.nozzles.is_empty():
			_placeholder("no nozzle for kit sample")
			return false
		var nz: Dictionary = sh.hull.nozzles[0]
		var pos: Vector3 = sh.to_world(nz["p"])
		var axis: Vector3 = sh.dir_world(nz.get("d", Vector3.LEFT))
		fx.rib(pos, axis, 12.0, t_ev, 0.85, sh.fac["engine"], 2.0, 1.8, 0.3, int(row["ribbon"]))
	elif what == "break":''')
    code = code.replace('\tfx.step(STEP)', '''	if A != null and is_instance_valid(A) and A.has_meta("kit_move") and A.path_dur > 0.0:
		A._seg_step(STEP)
		fx.set_engine("A", A.thrust)
	fx.step(STEP)''')
    code = code.replace('func _clear() -> void:\n\tfor id in fx.ships.keys():', '''func _clear() -> void:
	# Reap completed cut jobs before removing the ship from the registry.
	# Otherwise the worker pool retains their meshes past renderer shutdown.
	for sid in fx.ships.keys():
		var sh = fx.ships[sid]
		sh.wait_damage()
		if sh.has_meta("cut_task"):
			WorkerThreadPool.wait_for_task_completion(int(sh.get_meta("cut_task")))
			sh.remove_meta("cut_task")
		if sh.has_meta("cut_job"):
			sh.remove_meta("cut_job")
	for id in fx.ships.keys():''')
    ribbon_ids = ['doom', 'lance', 'ion', 'pulsar', 'needle', 'tendril',
                  'ribbon_0', 'ribbon_1', 'ribbon_3', 'moving_trail', 'p_lance_burn']
    ids = '[' + ', '.join('"' + x + '"' for x in ribbon_ids) + ']'
    code = code.replace('\tvar ci := 0', '\tvar native_strip: Image = null\n\tif int(r) == 60 and id in ' + ids + ':\n\t\tnative_strip = Image.create_empty(cell.x * total, cell.y, false, Image.FORMAT_RGB8)\n\tvar ci := 0')
    line = '\t\t\t\tstrip.blit_rect(_crop(img, crop, cell), Rect2i(Vector2i.ZERO, cell), Vector2i(ci * cell.x, 0))'
    code = code.replace(line, line + '\n\t\t\t\tif native_strip != null:\n\t\t\t\t\tnative_strip.blit_rect(_crop(img, cell, cell), Rect2i(Vector2i.ZERO, cell), Vector2i(ci * cell.x, 0))')
    code = code.replace('\tstrip.save_png(d.path_join(name))', '\tstrip.save_png(d.path_join(name))\n\tif native_strip != null:\n\t\tnative_strip.save_png(d.path_join(name.trim_suffix(".png") + "_native.png"))')
    code = code.replace('\t_log("%s at %d: %d cells"', '\tif native_strip != null:\n\t\treport["stills"][-1]["native_file"] = "moments/" + name.trim_suffix(".png") + "_native.png"\n\t_log("%s at %d: %d cells"')
    # The standing bench leaves world's static rock meshes alive at shutdown
    # on this checkout. Release them while the renderer is still running.
    code = code.replace('\tget_tree().quit(0)', '''	vp.queue_free()
	await get_tree().process_frame
	load("res://world/world_bake.gd").clear_static()
	load("res://world/world_rocks.gd")._meshes.clear()
	load("res://world/world_rocks.gd")._detail = null
	load("res://world/world_living.gd")._wreck_mesh_cache.clear()
	load("res://world/blocker_visuals.gd")._wreck_meshes.clear()
	load("res://world/blocker_visuals.gd")._wreck_mat = null
	load("res://world/world.gd")._wnoise = null
	get_tree().quit(0)''')
    code = code.replace('\tSV.clear_static()', '\tSV.clear_static()\n\tSV._pm = null')
    (scratch / 'bench.gd').write_text(code)
    (scratch / 'driver.gd').write_text('extends SceneTree\nfunc _initialize() -> void:\n\troot.add_child(load(OS.get_environment("KIT_BENCH_SCRIPT")).new())\n')
    env = dict(os.environ, KIT_BENCH_SCRIPT=str(scratch / 'bench.gd'))
    profile = Path(tempfile.gettempdir()) / 'voidsworn-367-profile'
    profile.mkdir(exist_ok=True)
    env['APPDATA'] = env['LOCALAPPDATA'] = str(profile)
    cmd = [str(GODOT), '--path', str(args.project), '--rendering-method', 'forward_plus',
        '--fixed-fps', '60', '--disable-vsync', '--resolution', '1920x1080',
        '--windowed', '--position', '-4000,-4000', '--log-file', str(scratch / 'engine.log'),
        '--script', str(scratch / 'driver.gd'), '--',
        '--out', str(out), '--moments', str(scratch / 'rows.json'), '--part', 'moments']
    if args.only:
        cmd += ['--only', args.only]
    if args.skip_row_warm:
        cmd += ['--no-warm']
    print(f'LOG {scratch / "console.txt"}', flush=True)
    hashes = {str(p.relative_to(args.project)): __import__('hashlib').sha256(p.read_bytes()).hexdigest()
              for p in [args.project / 'fx' / name for name in ['fx.gd', 'fx_shaders.gd', 'fx_weapons.gd']]}
    (out / 'source_hashes.json').write_text(json.dumps(hashes, indent=2))
    with (scratch / 'console.txt').open('w') as log:
        proc = subprocess.Popen(cmd, env=env, stdout=log, stderr=subprocess.STDOUT,
            creationflags=getattr(subprocess, 'CREATE_NO_WINDOW', 0))
        start = time.monotonic()
        completed_at = None
        stopped = False
        while proc.poll() is None:
            time.sleep(1)
            current = (scratch / 'console.txt').read_text(errors='replace')
            if 'LOOK_BENCH_DONE' in current and completed_at is None:
                completed_at = time.monotonic()
            if time.monotonic() - start > 2100 or (completed_at and time.monotonic() - completed_at > 15):
                subprocess.run(['taskkill', '/PID', str(proc.pid), '/T', '/F'], capture_output=True)
                stopped = True
                break
        proc.wait(timeout=15)
    (out / 'process.json').write_text(json.dumps(dict(exit=proc.returncode,
        stopped_after_completion=bool(stopped and completed_at), log=str(scratch / 'console.txt')), indent=2))
    output = (scratch / 'console.txt').read_text(errors='replace')
    print(output[-6500:])
    if proc.returncode and not (stopped and completed_at):
        raise SystemExit(proc.returncode)
    if 'LOOK_BENCH_DONE' not in output:
        raise SystemExit('No bench completion marker')
    errors = [line for line in output.split('LOOK_BENCH_DONE')[0].splitlines() if ('ERROR:' in line or 'SHADER ERROR' in line)
              and 'root certificate store' not in line]
    if errors:
        raise SystemExit('Capture has errors: ' + '\n'.join(errors[:12]))


if __name__ == '__main__':
    main()
