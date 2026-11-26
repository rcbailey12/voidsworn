extends SceneTree
# Issue 2171: real HUD, battle menu, profile, and hard-stop API; no 3D battle build needed.
const BATTLE := preload("res://scenes/battle/battle.tscn")
const MAIN := preload("res://main/main.gd")
const Teaching := preload("res://ui/campaign/campaign_tips.gd")
const API := preload("res://rules/battle_api.gd")
const THROWAWAY := preload("res://tools/throwaway_profile.gd")
var failures := 0


func check(ok: bool, message: String) -> void:
	print(("PASS " if ok else "FAIL ") + message)
	if not ok: failures += 1


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var profile := ProjectSettings.globalize_path("user://").replace("\\", "/")
	if not profile.contains("/godot_checks/xdg/") and THROWAWAY.refusal("battle_recovery_2171_test.gd") != "":
		check(false, "run the battle settings check with an isolated Godot profile")
		quit(1)
		return
	Teaching.set_off(false)
	var b = BATTLE.instantiate()
	b.external = true
	b.args["quality"] = "low"
	root.add_child(b)
	b.set_process(false)
	var main := MAIN.new()
	main._settings_to_battle(b)
	var observed := []
	b.option_changed.connect(func(key, value):
		if key == "tips":
			main._settings_to_battle(b)
			observed.append(b.tips_off == not value))
	b._toggle_opt("tips")
	check(observed == [true] and b.tips_off and Teaching.is_off(), "turning tips off survives a host settings sync")
	b._toggle_opt("tips")
	check(observed == [true, true] and not b.tips_off and not Teaching.is_off(), "turning tips on survives a host settings sync")
	b.args["no-tips"] = true
	b._sync_teaching_switch()
	b._save_opts()
	check(b.tips_off and not Teaching.is_off(), "a capture override never becomes the player's preference")
	b.args.erase("no-tips")

	var api := API.new()
	assert(api.load_rules() == "")
	api.new_battle_scenario("s1")
	api.hard_stop = true
	b.api = api
	api.R.np("2171 check reason")
	api.view()
	check(api.phase == "halted", "the real rules API entered its hard stop")
	b._runner()
	b._runner()
	var menu: Array = b.hud._last.get("show_menu", [])
	check(menu.size() >= 3 and menu[0] == "Battle stopped" and "2171 check reason" in menu[2],
		"the halt has a blocking message with the reason")
	check(b.errors.size() == 1 and "2171 check reason" in b.errors[0] and not b.busy,
		"the halt is reported once and the runner stops")
	b.free()
	main.free()
	quit(0 if failures == 0 else 1)
