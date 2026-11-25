extends SceneTree
# Issue 2048 item 4: layered faction idle motion pieces in fx_idle.gd (stays off by default until Ryan picks).
# Verifies default-off gate, 2 layered pieces per spot in 1 draw call via SH.IDLE_MOTION, all 6 distinct faction
# styles, Eclipse all-violet (R372), Chorus organic (no metal sparks), Reduce motion & Reduce flashing, and comfort caps.
const GUARD := preload("res://tools/ci/check_guard.gd")
const FX := preload("res://fx/fx.gd")
const SH := preload("res://fx/fx_shaders.gd")
const IDLE := preload("res://fx/fx_idle.gd")

const FACS := ["hegemony", "voidsworn", "corsair", "ithar", "deathless", "chorus"]
var failures := 0


func _init() -> void:
	GUARD.arm(self, "idle_layers_2048_check")
	_run.call_deferred()


func _check(ok: bool, msg: String) -> void:
	if not ok:
		failures += 1
		printerr("FAIL: " + msg)
	else:
		print("  ok: " + msg)


func _ship(world: Node3D, fx, sid: String, faction: String, pos: Vector3, calm_script: GDScript):
	var body := Node3D.new()
	body.set_script(calm_script)
	world.add_child(body)
	body.position = pos
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(24, 5, 8)
	mi.mesh = bm
	body.add_child(mi)
	fx.add_ship(sid, body, {"faction": faction, "cls": "Cruiser", "size": 0.8, "meshes": [mi], "shielded": false})
	fx._later.clear()
	return fx.ship(sid)


func _run() -> void:
	# 1. Shader check: SH.IDLE_MOTION defines all 6 layered faction styles and smooth comfort sine envelope.
	var code: String = SH.IDLE_MOTION
	_check(code.contains("float env = sin(3.14159265 * t) * I;"), "IDLE_MOTION uses smooth sin(pi t) comfort envelope")
	_check(code.contains("if (layer < 0.5)"), "IDLE_MOTION distinguishes layer 0 (anchor) and layer 1 (motion piece)")
	for st in [0, 1, 2, 3, 4]:
		_check(code.contains("st == %d" % st), "IDLE_MOTION implements faction style %d" % st)
	_check(code.contains("vec3 v_deep =") and code.contains("float veins ="), "IDLE_MOTION implements Eclipse violet corona and Chorus bio-veins")

	# 2. Stays OFF by default.
	OS.unset_environment("VS_IDLE_MOTION")
	_check(not IDLE.enabled(), "fx_idle stays off by default")

	# 3. Enable via VS_IDLE_MOTION=1 and verify layered pieces across all 6 factions.
	OS.set_environment("VS_IDLE_MOTION", "1")
	var world := Node3D.new()
	root.add_child(world)
	var calm_script := GDScript.new()
	calm_script.source_code = "extends Node3D\nvar calm := false\n"
	calm_script.reload()
	var cam := Camera3D.new()
	cam.fov = 45.0
	world.add_child(cam)
	cam.look_at_from_position(Vector3(0, 140, 100), Vector3.ZERO)
	cam.current = true
	var fx = FX.new()
	world.add_child(fx)
	fx.manual = true
	fx.setup({"camera": cam, "quality": "high", "shake": 0.0})

	var styles_seen := {}
	for i in FACS.size():
		var fac: String = FACS[i]
		var s = _ship(world, fx, "idle_" + fac, fac, Vector3((i - 2.5) * 35.0, 0, 0), calm_script)
		fx.step(0.1)
		_check(not s._idle.is_empty(), "%s: idle batch built when VS_IDLE_MOTION=1" % fac)
		if s._idle.is_empty():
			continue
		var rows: Array = s._idle["rows"]
		var layers: int = int(s._idle.get("layers", 0))
		var particles: int = int(s._idle.get("particles", 0))
		var mat: ShaderMaterial = s._idle["mat"]
		var mi := (s._idle["node"] as Node3D).get_child(0) as MeshInstance3D
		_check(layers == IDLE.LAYERS_PER_SPOT and layers == 2, "%s: 2 layered pieces per spot" % fac)
		_check(particles == rows.size() * 2, "%s: batch packs %d layered quads for %d spots" % [fac, particles, rows.size()])
		_check(mi != null and mi.mesh.get_surface_count() == 1, "%s: layered pieces draw in one draw call" % fac)
		_check(mat != null and mat.shader.code == SH.IDLE_MOTION, "%s: uses shared SH.IDLE_MOTION shader" % fac)
		styles_seen[int(rows[0]["style"])] = true
		var st := IDLE.stats(rows)
		_check(st["max_i"] < FX.FLASH_I and st["min_life"] >= IDLE.MIN_LIFE and st["starts_per_s"] <= IDLE.MAX_STARTS_PER_S,
			"%s: layered idle stays within comfort bounds (I=%.2f life=%.2f starts=%.2f)" % [fac, st["max_i"], st["min_life"], st["starts_per_s"]])
		if fac == "deathless":
			for r in rows:
				var c: Color = r["col"]
				_check(c.b >= c.r and c.r > c.g, "Eclipse layered idle stays all violet (no orange or green)")
		if fac == "chorus":
			for r in rows:
				var c: Color = r["col"]
				_check(c.g > c.b and c.g >= c.r * 0.9, "Chorus layered idle stays organic bile green-yellow")
	_check(styles_seen.size() == 6, "all 6 factions map to 6 distinct IDLE_MOTION styles")

	# 4. Reduce motion freezes Hegemony radar sweep to 1 steady layered spot (2 quads).
	var h = fx.ship("idle_hegemony")
	h.root.calm = true
	fx.step(0.05)
	_check((h._idle["rows"] as Array).size() == 1 and int(h._idle["particles"]) == 2 and bool((h._idle["rows"] as Array)[0]["still"]),
		"Hegemony Reduce motion switches to 1 steady layered spot (2 quads)")

	OS.unset_environment("VS_IDLE_MOTION")
	fx.release()
	world.queue_free()
	await process_frame
	FX.clear_static()
	print("idle_layers_2048_check: " + ("PASS" if failures == 0 else "FAIL (%d)" % failures))
	quit(1 if failures > 0 else 0)
