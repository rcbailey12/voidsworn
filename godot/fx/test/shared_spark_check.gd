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
		for i in lines.size():
			lines[i] = lines[i].get_slice("#", 0) # Comments may mention migration history.
		var source := "\n".join(lines)
		var found := PackedStringArray()
		for hit in legacy.search_all(source):
			found.append(str(source.left(hit.get_start()).count("\n") + 1))
		_check(found.is_empty(), "%s:%s still uses a retired spark path" % [path, ",".join(found)])


func _run() -> void:
	# Sprite kind 19 is reserved for the existing slow coals and stationary glow.
	var legacy := RegEx.create_from_string("fx_tear_sparks|death_spark_mesh|\"style\"\\s*:\\s*\"spark\""
		+ "|\\bsprx?\\s*[(](?:[^\\n]*,[ \\t\\r]*\\n)*[^\\n]*,\\s*19\\s*[,)]")
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
			elif faction == "deathless" and role == FX.SparkRole.ENGINE:
				raw = look["accent"]
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
	_check_compatibility(fx, streaks, p, v)
	_check_hull_hits(fx, streaks, p)
	_check_chorus_wound(fx, streaks)
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


func _check_compatibility(fx, pool: POOLS.Pool, p: Vector3, v: Vector3) -> void:
	var start: int = pool.pending.size()
	var col := Color(0.3, 0.5, 0.7)
	fx.stk(p, 1.5, 0.7, col, 2.0, 0.08, 0.07, 1, v)
	_check(pool.pending[start + 19] == FX.SPARK_KIND
		and Vector3(pool.pending[start + 12], pool.pending[start + 13], pool.pending[start + 14]).is_equal_approx(Vector3(col.r, col.g, col.b)),
		"legacy spark uses the shared mask and keeps its tint")
	start = pool.pending.size()
	fx.stk(p, 1.5, 0.7, col, 2.0, 4.8, 0.07, 0, v)
	_check(pool.pending[start + 19] == 0.0 and is_equal_approx(pool.pending[start + 16], 4.8),
		"legacy Nova and warp flight kind keeps its world length and mask")
	start = pool.pending.size()
	fx._thrust_spark(p, 0.5, "corsair", 0.28, v)
	_check(is_equal_approx(pool.pending[start + 17], 0.28), "ShipView grit width is already in world units")


func _check_hull_hits(fx, pool: POOLS.Pool, p: Vector3) -> void:
	var contact := {"p": p, "n": Vector3.UP}
	var ship := FX.SHIP.new()
	ship.root = Node3D.new()
	root.add_child(ship.root)
	ship.fac = fx.faction_info(ship.faction)
	ship.hull = FX.SHIP.HULL.new()
	var before: int = pool.emitted
	for crit in [false, true]:
		WEAP._impact(fx, "spine", 2, ship, contact, 1.0, Color.GREEN, Vector3.RIGHT, {"hull": 8, "crit": crit}, 1.0, 0.15)
		_check(pool.emitted == before, "bio hull hit (crit=%s) has no metal spark spray" % crit)
	var start: int = pool.pending.size()
	WEAP._energy_hit(fx, "plasma", 2, ship, contact, 2.0, Color.WHITE, Vector3.RIGHT, 1.0)
	var slag := WEAP.PLASMA_HOT
	_check(pool.emitted > before and pool.pending[start + 19] == FX.SPARK_KIND
		and Vector3(pool.pending[start + 12], pool.pending[start + 13], pool.pending[start + 14]).is_equal_approx(Vector3(slag.r, slag.g, slag.b)),
		"plasma on metal uses the shared mask with blue slag tint")
	ship.root.free()


func _check_chorus_wound(fx, pool: POOLS.Pool) -> void:
	var ship := FX.SHIP.new()
	ship.root = Node3D.new()
	root.add_child(ship.root)
	ship.faction = "chorus"
	ship.wounds_v2 = false
	ship.hull = FX.SHIP.HULL.new()
	ship.hull.turrets.append({"xf": Transform3D.IDENTITY})
	ship._jammed[1] = {"k": 0, "next": fx.now}
	var sparks: int = pool.emitted
	var lights: int = fx._lev.size()
	ship._wound_step(fx)
	_check(ship._jammed[1]["next"] > fx.now and pool.emitted == sparks and fx._lev.size() == lights,
		"Chorus jammed turret throws no sparks or spark light with Wounds V2 off")
	ship.root.free()


func _shell_burst(fx, pool: POOLS.Pool, p: Vector3, scale: float) -> Vector3:
	fx.rng.seed = 2018
	var before: int = pool.emitted
	var start: int = pool.pending.size()
	WEAP._throw_sparks(fx, p, Vector3.UP, Vector3.RIGHT, 2.0, scale, "corsair", 8, 32.0, 0.45, "shell")
	return Vector3(pool.emitted - before, pool.pending[start + 17], pool.pending[start + 11])
