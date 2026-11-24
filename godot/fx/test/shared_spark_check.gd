extends SceneTree
# Issue 2018: prove the live spawn path, its faction data and the retired drawing paths.

const FX := preload("res://fx/fx.gd")
const WEAP := preload("res://fx/fx_weapons.gd")
const POOLS := preload("res://fx/fx_pool.gd")

var failures := 0
var checks := 0


func _init() -> void:
	_run.call_deferred()


func _check(ok: bool, detail: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL shared sparks: " + detail)


func _scan(folder: String, legacy: RegEx) -> void:
	for sub in DirAccess.get_directories_at(folder):
		if sub != "test":
			_scan(folder.path_join(sub), legacy)
	for file in DirAccess.get_files_at(folder):
		if file.get_extension() not in ["gd", "gdshader"]:
			continue
		var path := folder.path_join(file)
		var lines := FileAccess.get_file_as_string(path).split("\n")
		var found := PackedStringArray()
		for i in lines.size():
			# Comments may mention migration history.
			if legacy.search(lines[i].get_slice("#", 0)) != null:
				found.append(str(i + 1))
		_check(found.is_empty(), "%s:%s still uses a retired spark path" % [path, ",".join(found)])


func _run() -> void:
	var legacy := RegEx.create_from_string("\\bstk\\s*[(]|fx_tear_sparks|death_spark_mesh|\"style\"\\s*:\\s*\"spark\"")
	if legacy == null:
		printerr("FAIL shared sparks: cannot build source guard")
		quit(1)
		return
	for folder in ["res://fx", "res://render", "res://scenes/battle"]:
		_scan(folder, legacy)
	var fx := FX.new()
	root.add_child(fx)
	fx.manual = true
	fx.setup({"quality": "max", "unit": 2.0})
	var streaks: POOLS.Pool = fx.pools["stk"]
	var glow: POOLS.Pool = fx.pools["spr"]
	var rows: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://fx/faction_looks.json"))
	var p := Vector3(1.0, 2.0, 3.0)
	var v := Vector3(9.0, 0.0, -6.0)
	for faction in ["voidsworn", "hegemony", "corsair", "ithar", "deathless", "chorus"]:
		var look: Dictionary = rows[faction]
		for role in FX.SparkRole.values():
			var before: int = streaks.emitted
			fx.spark(p, 1.5, 0.7, faction, 2.7, 0.05, 0.06, v, 1.2, 3.0, 6.0, role)
			if faction == "chorus":
				_check(streaks.emitted == before, "Chorus throws no spark in any role")
				continue
			var raw: Array = look["damage_glow"]
			if faction == "ithar" or (role == FX.SparkRole.DEATH and faction != "deathless"):
				raw = look["death"]["spark"]
			elif faction != "deathless":
				match role:
					FX.SparkRole.SHIELD: raw = look["shield"]
					FX.SparkRole.WEAPON: raw = look["weapon"]
					FX.SparkRole.ENGINE: raw = look["engine"]
			var start: int = before * POOLS.STRIDE * streaks.vpp
			var a := streaks.pending.slice(start, start + POOLS.STRIDE)
			var label := "%s role %d" % [faction, role]
			_check(streaks.emitted == before + 1 and a.size() == POOLS.STRIDE, label + " uses one pooled spark")
			if a.size() != POOLS.STRIDE:
				continue
			_check(Vector3(a[12], a[13], a[14]).is_equal_approx(Vector3(raw[0], raw[1], raw[2])), label + " keeps its JSON tint")
			_check(a[19] == FX.SPARK_KIND and a[1] == float(faction == "ithar"), label + " uses the shared spark and correct mask")
			_check(Vector3(a[4], a[5], a[6]).is_equal_approx(p) and Vector3(a[8], a[9], a[10]).is_equal_approx(v)
				and is_equal_approx(a[18], 1.2), label + " packs the requested origin, velocity and drag")
			_check(is_equal_approx(a[7], 1.5) and is_equal_approx(a[11], 0.7) and is_equal_approx(a[17], 0.12),
				label + " uses effect seconds and world units")
	_check(glow.emitted == 0, "shared sparks do not add a second sprite")
	var small := _shell_burst(fx, streaks, p, 0.5)
	var heavy := _shell_burst(fx, streaks, p, 1.75)
	_check(heavy.x > small.x and heavy.y > small.y and heavy.z > small.z,
		"heavier hits throw more sparks with more width and a longer life")
	var before: int = streaks.emitted
	var contact := {"p": p, "n": Vector3.UP, "shield": true}
	WEAP._impact(fx, "ion", 3, null, contact, 2.0, Color.WHITE, Vector3.RIGHT, {"shield": 8, "crit": true}, 1.0, 0.15)
	_check(streaks.emitted == before, "a fully absorbed ion crit has no spark spray")
	contact["breaking"] = true
	WEAP._impact(fx, "ion", 3, null, contact, 3.0, Color.WHITE, Vector3.RIGHT, {"shield": 8}, 1.0, 0.15)
	_check(streaks.emitted > before, "a shield break still throws sparks")
	fx.free()
	FX.clear_static()
	print("SHARED_SPARK %s: %d checks, %d failures" % ["PASS" if failures == 0 else "FAIL", checks, failures])
	quit(0 if failures == 0 else 1)


func _shell_burst(fx, pool: POOLS.Pool, p: Vector3, scale: float) -> Vector3:
	fx.rng.seed = 2018
	var before: int = pool.emitted
	var start: int = pool.pending.size()
	WEAP._throw_sparks(fx, p, Vector3.UP, Vector3.RIGHT, 2.0, scale, "corsair", 8, 32.0, 0.45, "shell")
	return Vector3(pool.emitted - before, pool.pending[start + 17], pool.pending[start + 11])
