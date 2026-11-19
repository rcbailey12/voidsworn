extends "perf_1118.gd"

const LIGHTING := preload("probe_lighting.gd")

var lighting: RefCounted
var glass_ship: Node3D


func _switch(variant: String) -> int:
	lighting = LIGHTING.new()
	glass_ship = null
	var chorus_found := false
	var metal_found := false
	for view in _views():
		match view.code:
			"I8_37": glass_ship = view
			"B21_11": chorus_found = view.a4
			"C19_51": metal_found = view.a4
	if glass_ship == null or not glass_ship.a4 or not chorus_found or not metal_found:
		push_error("Scene 207 did not draw CD5, C11 and C19_51 from the isolated cache")
		return -1
	if not lighting.prepare(b, b.env, b.cam) or not lighting.apply(variant):
		return -1
	var materials: Array[ShaderMaterial] = lighting.apply_glass(glass_ship)
	lighting.aim(materials)
	if materials.size() != 5:
		push_error("Expected five run 4 glass surfaces in scene 207")
		return -1
	return materials.size()


func _measure(vrid: RID, variant: String) -> Dictionary:
	var row: Dictionary = await super._measure(vrid, variant)
	var count: int = lighting.active_glass_count(glass_ship)
	row["active_glass_after"] = count
	if count != 5:
		push_error("Run 4 glass lost surfaces during scene 207")
		failures += 1
	return row
