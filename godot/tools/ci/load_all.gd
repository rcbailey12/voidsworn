# Loads every .gd script and every .tscn scene under godot/ and fails on any one that does not load (issue 359 part a).
#   godot --headless --path godot --script res://tools/ci/load_all.gd
# Typo insurance for GitHub's checks: before this, GitHub loaded only the rules and campaign files, so a typing mistake in
# the battle scene, the HUD, the effects, the world or the story passed every check. Loading compiles a script and every
# script it preloads; nothing is run. No texture or sound import is needed: no script or scene under godot/ preloads one
# (they load them at run time), so GitHub can do this on a fresh checkout without the slow asset import.
# Skipped on purpose, and only these: .godot (the editor cache) and gen (built ship files, never in git).
# Prints one line per failed file, then "load all: N scripts, M scenes, F failed"; exit code 1 when F > 0.
extends SceneTree

const SKIP_DIRS := [".godot", "gen"]

var scripts := 0
var scenes := 0
var failed: Array = []


func _init() -> void:
	var files: Array = []
	_walk("res://", files)
	files.sort()
	for f in files:
		var path: String = f
		if path.ends_with(".gd"):
			scripts += 1
			var s = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_REUSE)
			if s == null or not (s is GDScript) or not (s as GDScript).can_instantiate():
				failed.append(path)
		elif path.ends_with(".tscn"):
			scenes += 1
			var p = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_REUSE)
			if p == null or not (p is PackedScene) or not (p as PackedScene).can_instantiate():
				failed.append(path)
	for f in failed:
		printerr("load all: FAILED %s" % f)
	print("load all: %d scripts, %d scenes, %d failed" % [scripts, scenes, failed.size()])
	quit(1 if failed.size() > 0 else 0)


func _walk(dir: String, out: Array) -> void:
	var d := DirAccess.open(dir)
	if d == null:
		failed.append(dir)
		return
	d.include_hidden = false
	for sub in d.get_directories():
		if SKIP_DIRS.has(sub):
			continue
		_walk(dir.path_join(sub), out)
	for f in d.get_files():
		if f.ends_with(".gd") or f.ends_with(".tscn"):
			out.append(dir.path_join(f))
