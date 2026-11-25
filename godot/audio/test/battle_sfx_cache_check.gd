extends SceneTree

const GUARD := preload("res://tools/ci/check_guard.gd")
const BATTLE := preload("res://scenes/battle/battle.tscn")
const SFX := preload("res://audio/sfx.gd")
var failures := 0


class CatalogLog extends Logger:
	var loads := 0

	func _log_message(message: String, _error: bool) -> void:
		if Thread.is_main_thread() and message.begins_with("[sfx] ") and message.contains("clip sets, loaded in"):
			loads += 1


func _init() -> void:
	GUARD.arm(self, "battle_sfx_cache_check")
	_run.call_deferred()


func _check(ok: bool, message: String) -> void:
	print(("  ok: " if ok else "  FAIL: ") + message)
	if not ok:
		failures += 1


func _open_battle() -> Node3D:
	var battle := BATTLE.instantiate() as Node3D
	battle.external = true
	battle.args["quality"] = "low"
	root.add_child(battle)
	return battle


func _run() -> void:
	var catalog_log := CatalogLog.new()
	OS.add_logger(catalog_log)
	var silent := SFX.new()
	silent.silent = true
	var bus_count := AudioServer.bus_count
	root.add_child(silent)
	silent.ambient_start()
	_check(silent.cues.is_empty() and catalog_log.loads == 0 and AudioServer.bus_count == bus_count,
		"silent start reads no catalog and sets up no buses")

	var ui := SFX.new()
	ui.only = "ui_"
	root.add_child(ui)
	_check(ui.cues.has("ui_click") and not ui.cues.has("gun_shell"), "menu sounds only load the UI bank")
	var sfx_bus := AudioServer.get_bus_index("sfx")
	var ui_db := AudioServer.get_bus_volume_db(sfx_bus)
	silent.set_volume(0.0)
	silent.quiet(-18.0, 1.0)
	_check(not AudioServer.is_bus_mute(sfx_bus) and AudioServer.get_bus_volume_db(sfx_bus) == ui_db,
		"silent mix changes leave the menu bus alone")
	silent.free()
	var ui_loads := catalog_log.loads
	var first := _open_battle()
	var cues: Dictionary = first.sfx.cues
	var clips: Dictionary = first.sfx.clips
	var synth: Dictionary = first.sfx.synth
	_check(catalog_log.loads == ui_loads + 1 and cues.has("gun_shell") and not clips.is_empty(),
		"first battle loads the full catalog")
	first.sfx.rr["test"] = 1
	first.free()
	var second := _open_battle()
	_check(catalog_log.loads == ui_loads + 1 and is_same(cues, second.sfx.cues)
		and is_same(clips, second.sfx.clips) and is_same(synth, second.sfx.synth),
		"second battle reuses the catalog without rebuilding it or reading import sidecars")
	_check(not second.sfx.rr.has("test") and second.sfx.active.is_empty(), "the second battle has fresh playback state")
	second.free()
	ui.free()
	print("battle_sfx_cache_check: %d failures" % failures)
	quit(1 if failures else 0)
