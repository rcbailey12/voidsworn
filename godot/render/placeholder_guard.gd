extends RefCounted
# Stops a capture, probe, shot or bench run that drew a ship as a placeholder block.
# render/ship_view.gd notes every hull it could not load. The scripts that save pictures or measure a scene call
# stop_if_any() before their first picture, so a run on a checkout without godot/gen stops with a named hull and a
# non-zero exit code instead of saving a sheet of grey blocks. The game itself never calls this: a missing hull still
# draws the block, and GitHub's checks never reach this file.

static var count := 0
static var codes: Array = []
static var reported := false


# called by render/ship_view.gd when a ship falls back to the plain block
static func note(code: String) -> void:
	count += 1
	if not codes.has(code):
		codes.append(code)


# true when a placeholder was drawn: prints one line per hull code, asks the main loop to exit with code 1, and returns
# true so the caller can return at once (before it writes a picture).
static func stop_if_any() -> bool:
	if count <= 0:
		return false
	if not reported:
		reported = true
		for c in codes:
			printerr("placeholder hull: %s" % c)
		printerr("placeholder hull: %d hull(s) had no built file; no picture written" % count)
	var loop := Engine.get_main_loop()
	if loop is SceneTree:
		(loop as SceneTree).quit(1)
	return true


# the last line of a capture script: a normal exit code when every ship was real, 1 when any was a placeholder
static func finish(code := 0) -> void:
	var exit_code := 1 if stop_if_any() else code
	var loop := Engine.get_main_loop()
	if loop is SceneTree:
		(loop as SceneTree).quit(exit_code)
