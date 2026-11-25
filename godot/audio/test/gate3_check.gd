extends SceneTree

const GUARD = preload("res://tools/ci/check_guard.gd")
const Sfx := preload("res://audio/sfx.gd")
const Kit := preload("res://ui/theme/orders_kit.gd")
const ROOT_WIRING := "../contrib/opus/sound/wiring_gate3.json"
var failures := 0


func _init() -> void:
	GUARD.arm(self, "gate3_check")
	_run.call_deferred()


func _check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		printerr("FAIL: ", message)


func _run() -> void:
	var wiring_path := ProjectSettings.globalize_path("res://").path_join(ROOT_WIRING).simplify_path()
	var plan = JSON.parse_string(FileAccess.get_file_as_string(wiring_path))
	if not plan is Dictionary or not plan.get("wires") is Array:
		printerr("FAIL: missing Gate 3 wiring plan")
		quit(1)
		return
	var index: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://audio/clips/index.json"))
	var s := Sfx.new()
	root.add_child(s)
	var ui := Sfx.new()
	ui.only = "ui_"
	root.add_child(ui)
	await process_frame
	var heard := []
	s.cue_started.connect(func(name, opts): heard.append([name, str(opts.get("variant", ""))]))
	var staged := 0
	for row in plan["wires"]:
		var id: String = row["id"]
		var key: String = row.get("append", id)
		var takes: Array = index.get(key, [])
		var expected_new := int(row["takes"])
		_check(s.clips.get(key, []).size() == takes.size(), key + " loads every indexed take")
		for i in expected_new:
			_check("%s_%d.ogg" % [id, i] in takes, id + " loads approved take %d" % (i + 1))
		if row.has("hold"):
			staged += 1
			continue
		var routes := []
		if row.has("append"):
			_check(takes.size() > expected_new, id + " kept the original take(s)")
			for cue in s.cues:
				var c: Dictionary = s.cues[cue]
				if _has_layer(c, key):
					routes.append([cue, ""])
				for v in c.get("variants", {}):
					if _has_layer(c["variants"][v], key):
						routes.append([cue, v])
		else:
			for v in row.get("variants", [""]):
				routes.append([row["cue"], v])
		_check(not routes.is_empty(), id + " has a cue route")
		for route in routes:
			var cue: String = route[0]
			var variant: String = route[1]
			var c: Dictionary = s.cues.get(cue, {})
			var branch: Dictionary = c if variant == "" else c.get("variants", {}).get(variant, {})
			_check(_has_layer(branch, key), id + " is on " + cue + ":" + variant)
			if cue.begins_with("ui_"):
				_check(ui.cues.has(cue) and ui.clips.has(key), cue + " loads in the UI-only player")
			if row.get("bed", false):
				s.terrain_bed(cue)
				s.terrain_bed(cue)
				var bed: AudioStreamPlayer = s._terrain_beds.get(cue)
				_check(bed != null and bed.playing and bed.bus == "ambient" and bed.stream.loop, cue + " starts a loop on the ambient bus")
				_check(s._terrain_beds.size() == 1, cue + " does not stack copies")
				s.stop_all()
				_check(s._terrain_beds.is_empty(), cue + " is retired with battle audio")
				continue
			if branch.is_empty():
				continue
			var played := {}
			var previous: AudioStream = null
			var repeated := false
			for i in 128:
				var layers := s._layers(cue, c, variant)
				var set_takes: Array = s.clips.get(key, [])
				for layer in layers:
					if layer.st in set_takes:
						played[layer.st] = true
						repeated = repeated or layer.st == previous
						previous = layer.st
			_check(played.size() == takes.size() and (takes.size() == 1 or not repeated),
				cue + ":" + variant + " uses all takes and never repeats a take back to back")
			heard.clear()
			s.play(cue, {"variant": variant, "duration": 0.3} if cue == "engine" else {"variant": variant})
			_check([cue, variant] in heard, cue + ":" + variant + " starts an actual voice")
			if cue == "engine":
				_check(s.by_cue[cue][0].players[0].stream.loop, "ship engine plays a bounded loop")
			s.stop_all()
	_check(_has_layer(s.cues["wreck"], "wreckSettle") and not index.has("death_wreck_settle"),
		"the wreck keeps today's sound")
	_check(Kit.press_cue("purchase") == "ui_purchase" and Kit.press_cue("install") == "ui_module_install"
		and Kit.press_cue("relic") == "ui_relic_socket", "shared UI hook owns the new one-shot cues")
	_check(plan["wires"].size() == 65 and staged == 2, "all 65 keeper IDs are accounted for, including two design holds")
	s.free()
	ui.free()
	print("GATE 3 CHECK ", "PASS" if failures == 0 else "FAIL (%d)" % failures)
	quit(0 if failures == 0 else 1)


func _has_layer(c: Dictionary, key: String) -> bool:
	return c.get("layers", []).any(func(layer): return layer.get("s") == key)
