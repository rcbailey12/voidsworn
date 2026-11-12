extends SceneTree
# Issue 557: the unchanged #207 scene, replacing its Hullbreaker capital's visual asset with the exported test hull.
# Set INTERIORS_BENCH_SCENE to the installed.scn saved by authored_interiors_probe. Normal scene_gate arguments apply.
const SV = preload("res://render/ship_view.gd")

func _init() -> void:
	process_frame.connect(_run, CONNECT_ONE_SHOT)

func _run() -> void:
	var installed := OS.get_environment("INTERIORS_BENCH_SCENE")
	if not FileAccess.file_exists(installed):
		push_error("INTERIORS_BENCH_SCENE must name an installed export")
		quit(2)
		return
	SV.manifest()["ships"]["C19_51"] = {"res": installed}
	root.add_child(load("res://bench/scene_gate.tscn").instantiate())
