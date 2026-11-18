extends SceneTree

const GUARD := preload("res://tools/ci/check_guard.gd")
const PROPS := preload("res://assets/ships/a4_props.gd")
const T2_PATH := "res://gen/ships/station_T2.scn"
const A4_PATH := "res://gen/ships/O1_37.scn"


func _init() -> void:
	GUARD.arm(self, "station_size_check")
	process_frame.connect(_run, CONNECT_ONE_SHOT)


func _run() -> void:
	# The game cache is optional in CI. Register both scenes in the resource cache
	# so the real loader takes its installed path there too.
	var stand_ins: Array[PackedScene] = []
	if not ResourceLoader.exists(T2_PATH):
		stand_ins = [_cache_scene(T2_PATH), _cache_scene(A4_PATH)]
		PROPS._man = {"ships": {"O1_37": {"res": A4_PATH}}}

	if not ResourceLoader.exists(T2_PATH):
		printerr("FAIL: T2 must be in the cache for this check")
		quit(1)
		return

	var large := PROPS.station(46.0)
	var large_ok := (large != null and large.scene_file_path == T2_PATH
		and large.has_meta("station_T2") and large.scale.is_equal_approx(Vector3.ONE))
	_report(large_ok, "station(46) returns T2 at unit scale")

	var small := PROPS.station(34.0)
	var small_ok: bool = (small != null and not small.has_meta("station_T2") and small.get_child_count() == 1
		and small.get_child(0).scene_file_path == A4_PATH
		and small.get_child(0).scale.is_equal_approx(Vector3.ONE * 34.0))
	_report(small_ok, "station(34) returns O1_37 at scale 34")

	if large != null:
		large.free()
	if small != null:
		small.free()
	stand_ins.clear()
	quit(0 if large_ok and small_ok else 1)


func _cache_scene(path: String) -> PackedScene:
	var node := Node3D.new()
	var scene := PackedScene.new()
	var packed := scene.pack(node)
	node.free()
	if packed != OK:
		return null
	scene.take_over_path(path)
	return scene


func _report(ok: bool, description: String) -> void:
	print("%s: %s" % ["PASS" if ok else "FAIL", description])
