extends SceneTree
const GUARD = preload("res://tools/ci/check_guard.gd")
# Count actual player starts, not requests or pending timers. Keep all existing caps.
const Sfx := preload("res://audio/sfx.gd")
const FX := preload("res://fx/fx.gd")
const VIEW := preload("res://render/ship_view.gd")
const RULES := preload("res://rules/rules.gd")
const BEARING := {"F": Vector3.RIGHT, "P": Vector3.FORWARD, "S": Vector3.BACK,
	"R": Vector3.LEFT, "T": Vector3(1, 0, 1)}
var fails: Array = []
var starts := {}
var peak := {}
var global_peak := 0
var s: Node

func _init() -> void:
	GUARD.arm(self, "salvo_check")  # issue 632: a SCRIPT ERROR or a stuck run ends the check, never waits
	call_deferred("_run")

func _ok(c: bool, message: String) -> void:
	if not c:
		fails.append(message)
		print("  FAIL ", message)

func _started(name: String, _options: Dictionary) -> void:
	starts[name] = int(starts.get(name, 0)) + 1
	var voices: Array = s.by_cue.get(name, [])
	peak[name] = maxi(int(peak.get(name, 0)), voices.size())
	_ok(voices.size() <= int(s.cues[name].max), name + " per-cue cap")
	_ok(s.active.size() <= s.max_voices, "global cap")
	global_peak = maxi(global_peak, s.active.size())
	var audible := false
	for p in voices.back().players:
		if p is AudioStreamPlayer and p.playing:
			audible = true
	_ok(audible, name + " has actually started a player")

func _salvo(name: String, count: int, twin := false) -> void:
	s.stop_all()
	s.salvo.clear()
	starts.clear()
	peak.clear()
	seed(7341)
	for i in count:
		if twin:
			s.gun("gun", false, "twin")
		else:
			s.play(name)
	await create_timer(float(s.cues[name].defer) + 0.15).timeout
	var want := count * (2 if twin else 1)
	_ok(int(starts.get(name, 0)) == want, "%s: %d of %d actual starts" % [name, starts.get(name, 0), want])
	print("  %s%s %d/%d starts, peak %d/%d" % [name, " twin" if twin else "", starts.get(name, 0), want, peak.get(name, 0), s.cues[name].max])

func _slab(parent: Node, length: float) -> MeshInstance3D:
	var hull := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(length, length * 0.2, length * 0.35)
	hull.mesh = box
	parent.add_child(hull)
	return hull

func _hull_volleys() -> void:
	var rules := RULES.new()
	var error := rules.load_tables("res://rules/data/tables.json")
	_ok(error.is_empty(), error)
	if not error.is_empty():
		return
	var installed := VIEW.manifest()
	var volleys := 0
	var skipped_shots := 0
	var fixtures := 0
	for id in rules.HULLS:
		var hull: Dictionary = rules.HULLS[id]
		var faction := str(hull.get("fac", "voidsworn"))
		var world := Node3D.new()
		root.add_child(world)
		var fx := FX.new()
		world.add_child(fx)
		fx.manual = true
		fx.defer_initial_cuts = true
		fx.setup({"quality": "low"})
		var shooter: Node3D
		var meshes: Array
		if installed.is_empty() and hull.cls != "Squadron":
			# Source-only CI exercises the real surface-ray fallback for each loadout.
			shooter = _slab(world, VIEW.HT.length_for("", hull.cls) * VIEW.HT.SHIP_K)
			meshes = [shooter]
			fixtures += 1
		else:
			var view := VIEW.new()
			world.add_child(view)
			view.setup({"id": id, "tpl": id, "cls": hull.cls, "fac": faction, "facing": 0}, Vector3.ZERO)
			shooter = view
			meshes = view.meshes
			if installed.get("ships", {}).has(view.code):
				_ok(view.a4, "%s loaded its installed ship model (%s)" % [id, view.code])
			elif hull.cls != "Squadron":
				_ok(installed.get("hulls", {}).has(view.code) or installed.get("hi", {}).has(view.code),
					"%s has an installed hull (%s)" % [id, view.code])
		fx.add_ship(id, shooter, {"cls": hull.cls, "faction": faction, "meshes": meshes, "shielded": false})
		var target := _slab(world, 12.0)
		fx.add_ship("target", target, {"meshes": [target], "shielded": false})
		for slot in hull.w.size():
			var mount: Array = hull.w[slot]
			var wid: String = mount[0]
			var weapon: Dictionary = rules.WPN[wid]
			var shots: Array = []
			shots.resize(int(weapon.shots))
			shots.fill(false)
			var bearing: Vector3 = BEARING[mount[1]]
			target.position = bearing.normalized() * 75.0
			var result := fx.volley(id, weapon.k, "target", {"slot": slot, "weapon_id": wid, "shots": shots})
			var lost := int(result.get("skipped", 0))
			_ok(lost == 0 and result.fires.size() == shots.size(),
				"%s slot %d (%s): %d skipped, %d/%d fired" % [id, slot, wid, lost, result.fires.size(), shots.size()])
			skipped_shots += lost
			volleys += 1
		fx.release()
		world.free()
		VIEW.clear_look_cache()
		await process_frame
	_ok(volleys > 0, "hull walk exercised weapon slots")
	print("  %d hull templates, %d volleys, %d skipped shots (%d stand-in hulls)" % [rules.HULLS.size(), volleys, skipped_shots, fixtures])

func _run() -> void:
	s = Sfx.new()
	root.add_child(s)
	await process_frame
	s.cue_started.connect(_started)
	for name in s.cues:
		if not name.begins_with("gun_"):
			continue
		var c: Dictionary = s.cues[name]
		_ok(float(c.defer) >= maxf(float(c.gap) * 2.5, float(c.gap) * int(c.max)), name + " defer validation")
		await _salvo(name, 20)
	await _salvo("gun_shell", 20, true)
	# Additional overload: every family together forces the global cap to bite.
	s.stop_all()
	starts.clear()
	global_peak = 0
	var longest := 0.0
	for name in s.cues:
		if name.begins_with("gun_"):
			longest = maxf(longest, float(s.cues[name].defer))
			for i in 20:
				s.play(name)
	await create_timer(longest + 0.15).timeout
	for name in s.cues:
		if name.begins_with("gun_"):
			_ok(int(starts.get(name, 0)) == 20, name + " loses no starts in mixed overload")
	_ok(global_peak == s.max_voices, "mixed overload actually reaches the global cap")
	print("  mixed overload 200/200 gun starts, global peak %d/%d" % [global_peak, s.max_voices])
	# stop_all must also cancel starts that have not yet come due.
	s.stop_all()
	starts.clear()
	for i in 20:
		s.play("gun_sq")
	s.stop_all()
	var before := int(starts.get("gun_sq", 0))
	await create_timer(float(s.cues.gun_sq.defer) + 0.1).timeout
	_ok(int(starts.get("gun_sq", 0)) == before, "stop_all cancels pending starts")
	s.free()
	await _hull_volleys()
	print("SALVO CHECK ", "PASS" if fails.is_empty() else "FAIL (%d)" % fails.size())
	quit(0 if fails.is_empty() else 1)
