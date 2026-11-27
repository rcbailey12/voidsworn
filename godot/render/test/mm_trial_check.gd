extends SceneTree
# Issue 2001: exercise the trial loaders with the branch's imported maps, without a renderer.

const GUARD := preload("res://tools/ci/check_guard.gd")
const LOOK := preload("res://render/look.gd")
const PLANET := preload("res://world/world_planet.gd")

var failures := 0


func _init() -> void:
	GUARD.arm(self, "mm_trial_check")
	_run.call_deferred()


func _check_tile(tile: Texture2D, path: String) -> void:
	if tile == null or tile.resource_path != path:
		failures += 1
		printerr("MM_TRIAL CHECK FAIL: expected " + path)


func _check_ships(dir: String) -> void:
	for faction in LOOK.DETAIL_FACTIONS:
		var material := LOOK.hull(StandardMaterial3D.new(), faction) as BaseMaterial3D
		var prefix: String = dir + faction
		_check_tile(material.detail_albedo, prefix + "_grain.png")
		_check_tile(material.detail_normal, prefix + "_n.png")


func _check_planets(trial: bool) -> void:
	for kind in PLANET.MM_DETAIL_TILES:
		var tile := PLANET.trial_detail_tile(kind)
		var path := "res://world/detail/mm_trial/%s.png" % PLANET.MM_DETAIL_TILES[kind]
		if trial:
			_check_tile(tile, path)
		elif tile != null:
			failures += 1
			printerr("MM_TRIAL CHECK FAIL: loaded while off: " + path)


func _run() -> void:
	LOOK.v2_force = 1
	OS.unset_environment("VS_MM_TRIAL")
	_check_ships(LOOK.DETAIL_DIR)
	_check_planets(false)
	OS.set_environment("VS_MM_TRIAL", "1")
	_check_ships(LOOK.MM_DETAIL_DIR)
	_check_planets(true)
	OS.set_environment("VS_MM_TRIAL", "0")
	_check_ships(LOOK.DETAIL_DIR)
	_check_planets(false)
	if failures == 0:
		print("MM_TRIAL CHECK PASS")
	quit(0 if failures == 0 else 1)
