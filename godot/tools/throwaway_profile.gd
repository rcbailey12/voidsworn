extends RefCounted
# Issue 1369: one owner of the throwaway Godot profile. On the PC every Godot start goes through tmo.bat, and the watchdog
# (tools/pc/run_timeout.ps1, PR 1249) gives it a fresh profile: APPDATA = <scratch>\godot-profile-<id>, with the scratch
# folder's .voidsworn-run-owner token beside it, removed when the run ends. A capture that drives the real main scene
# (it saves the campaign and may save settings) checks here that user:// sits inside that profile, never Ryan's own.
# PC_REAL_PROFILE=1 turns the watchdog profile off, so such a capture then refuses.


static func norm(p: String) -> String:
	return p.replace("\\", "/").simplify_path().trim_suffix("/")


# true when udir (user:// made absolute) is inside the watchdog profile named by appdata
static func in_watchdog_profile(udir: String, appdata: String) -> bool:
	var app := norm(appdata)
	if app == "" or not app.get_file().to_lower().begins_with("godot-profile-"):
		return false
	if not norm(udir).to_lower().begins_with(app.to_lower() + "/"):
		return false
	return FileAccess.file_exists(app.get_base_dir().path_join(".voidsworn-run-owner"))


# "" when this process may write user://, otherwise the reason it may not. Only Windows has a player profile to protect.
static func refusal(script_name: String) -> String:
	if OS.get_name() != "Windows":
		return ""
	var udir := ProjectSettings.globalize_path("user://")
	if in_watchdog_profile(udir, OS.get_environment("APPDATA")):
		return ""
	return "user:// (%s) is not inside the watchdog's throwaway profile (APPDATA %s); start %s through tools/pc/tmo.bat without PC_REAL_PROFILE=1" \
			% [norm(udir), OS.get_environment("APPDATA"), script_name]
