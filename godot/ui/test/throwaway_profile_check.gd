extends SceneTree
# Issue 1369: tools/throwaway_profile.gd accepts user:// only inside a watchdog profile (godot-profile-<id> under a scratch
# folder that holds .voidsworn-run-owner), so front_end_shots and hit_timing_capture run under tmo.bat and refuse otherwise.
# godot --headless --path godot --script res://ui/test/throwaway_profile_check.gd

const TP := preload("res://tools/throwaway_profile.gd")
var _bad := 0


func _check(name: String, got: bool, want: bool) -> void:
	if got != want:
		_bad += 1; printerr("[throwaway-profile] FAIL ", name, ": got ", got, ", want ", want)
	else:
		print("[throwaway-profile] ok ", name)


func _initialize() -> void:
	var base := ProjectSettings.globalize_path("user://").path_join("throwaway_profile_check_%d" % Time.get_ticks_usec())
	var scratch := base.path_join("voidsworn-run-ab12")
	var prof := scratch.path_join("Godot-Profile-0f0f")
	DirAccess.make_dir_recursive_absolute(prof)
	var udir := prof.path_join("Godot/app_userdata/Voidsworn")
	_check("no owner token refuses", TP.in_watchdog_profile(udir, prof), false)
	var f := FileAccess.open(scratch.path_join(".voidsworn-run-owner"), FileAccess.WRITE)
	f.store_string("0123456789abcdef0123456789abcdef"); f.close()
	_check("watchdog profile accepted", TP.in_watchdog_profile(udir, prof), true)
	_check("backslashes and a trailing slash accepted", TP.in_watchdog_profile(udir.replace("/", "\\"), prof.replace("/", "\\") + "\\"), true)
	_check("user:// outside the profile refuses", TP.in_watchdog_profile(base.path_join("Godot/app_userdata/Voidsworn"), prof), false)
	_check("a sibling with the same prefix refuses", TP.in_watchdog_profile(prof + "x/Godot", prof), false)
	_check("APPDATA not named godot-profile- refuses", TP.in_watchdog_profile(scratch.path_join("Roaming/Godot"), scratch.path_join("Roaming")), false)
	_check("empty APPDATA refuses", TP.in_watchdog_profile(udir, ""), false)
	# refusal_for takes the platform and paths as given, so this check passes the same way on Linux CI and under the
	# Windows watchdog (Artoo on PR 1370: the live refusal() is rightly empty there)
	_check("Windows in the watchdog profile runs", TP.refusal_for("Windows", udir, prof, "x") == "", true)
	_check("Windows outside it refuses", TP.refusal_for("Windows", base.path_join("Godot/app_userdata/Voidsworn"), prof, "x") != "", true)
	_check("Windows with the player's own APPDATA refuses", TP.refusal_for("Windows", "C:/Users/r/AppData/Roaming/Godot/app_userdata/Voidsworn", "C:/Users/r/AppData/Roaming", "x") != "", true)
	_check("Linux never refuses", TP.refusal_for("Linux", "/home/x/.local/share/godot", "", "x") == "", true)
	DirAccess.remove_absolute(scratch.path_join(".voidsworn-run-owner"))
	for d in [prof, scratch, base]: DirAccess.remove_absolute(d)
	print("Throwaway profile: ", "PASS" if _bad == 0 else "FAIL %d" % _bad)
	quit(0 if _bad == 0 else 1)
