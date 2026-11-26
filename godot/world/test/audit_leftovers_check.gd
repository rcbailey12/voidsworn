extends SceneTree

const GUARD := preload("res://tools/ci/check_guard.gd")
const LIVING := preload("res://world/world_living.gd")
const WORLD := preload("res://world/world.gd")
const BLOCKERS := preload("res://world/blocker_visuals.gd")
const BL := preload("res://world/board_look.gd")
const BATTLE := preload("res://scenes/battle/battle.tscn")
const GALLERY := preload("res://fx/gallery/gallery.gd")
const SV := preload("res://render/ship_view.gd")
const HT := preload("res://render/hull_table.gd")

class LookBench extends "res://bench/look_bench.gd":
	func _ready() -> void:
		pass

	func _grid() -> void:
		pass

class NebulaBench extends "res://world/nebula_bench.gd":
	func _ready() -> void:
		pass

var failures := 0
var worlds_added := 0
var ships_added := 0
var first_world_tier := ""


func _init() -> void:
	GUARD.arm(self, "audit_leftovers_check")
	_run.call_deferred()


func _check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		print("FAIL: ", message)


func _wreck_kit() -> void:
	var fixture := "user://wreck_kit_%d" % OS.get_process_id()
	var first := fixture.path_join("first_missing")
	var later := fixture.path_join("later_missing")
	DirAccess.make_dir_recursive_absolute(first)
	DirAccess.make_dir_recursive_absolute(later)
	var piece: String = LIVING.WRECK_NAMES[0] + ".glb"
	var src: String = LIVING.WRECK_DIR.path_join(piece)
	_check(DirAccess.copy_absolute(src, later.path_join(piece)) == OK, "copied the intact first piece into the later-gap kit")
	var original := LIVING._shard_meshes()
	_check(original.size() == LIVING.WRECK_NAMES.size(), "the complete kit still loads every piece")
	for directory in [first, later]:
		var meshes := LIVING._load_wreck_kit(directory)
		_check(meshes.size() == 1 and meshes[0] is BoxMesh, "a kit gap selects the whole solid fallback")
		if meshes.is_empty(): continue
		LIVING._wreck_mesh_cache = meshes
		var blocker := BLOCKERS.new()
		root.add_child(blocker)
		var centre := Vector3(32, 0, 9)
		blocker.build({"map": {"holes": [{"kind": "hulk", "cells": [[2, 0]]}]}},
			func(_q, _r): return centre)
		var hulk: Node3D = blocker.visuals.get("2,0")
		_check(hulk != null and hulk.get_child_count() == 9 and BLOCKERS.solid_at(hulk, centre),
			"the actual blocked hex has solid wreck geometry at its centre")
		blocker.free()
	LIVING._wreck_mesh_cache = original


func _gallery_msaa() -> void:
	var battle := BATTLE.instantiate()
	battle.external = true
	battle.args["nofx"] = true
	root.add_child(battle)
	var tiers := {"low": Viewport.MSAA_DISABLED, "high": Viewport.MSAA_2X, "max": Viewport.MSAA_4X}
	for tier in tiers:
		battle._apply_quality(tier)
		var gallery := GALLERY.new()
		gallery.quality = tier
		gallery._build_view()
		_check(root.msaa_3d == tiers[tier] and gallery.vp.msaa_3d == root.msaa_3d,
			"%s gallery and battle select the same MSAA" % tier)
		gallery.free()
	battle.free()


func _look_fog() -> void:
	var look := LookBench.new()
	root.add_child(look)
	look._setup_view()
	var terrain := {}
	for key in LookBench.STORM_HEXES:
		terrain[key] = "storm"
	await look._world(LookBench.SKIES[-1][1], terrain, [{"q": 0, "r": 0}])
	var fogs: Array = look.wld.find_children("*", "FogVolume", true, false)
	_check(look.env.volumetric_fog_enabled and not fogs.is_empty(), "look bench's Max storm row enables its fog volumes")
	var mat := StandardMaterial3D.new()
	mat.set_meta("look_hull", true)
	var hull := MeshInstance3D.new()
	hull.mesh = BoxMesh.new()
	hull.material_override = mat
	look.world.add_child(hull)
	await process_frame
	_check(mat.disable_fog, "the look bench applies the battle hull fog policy")
	BL.set_look("holo", false)
	look.wld.set_look()
	_check(not look.env.volumetric_fog_enabled, "hidden storm volumes stop volumetric fog")
	BL.set_look("cine", false)
	look.wld.set_look()
	_check(look.env.volumetric_fog_enabled, "showing storm terrain restores its fog")
	for tier in ["high", "low"]:
		look.wld.quality = tier
		look.wld.set_look()
		_check(not look.env.volumetric_fog_enabled, "%s never enables volumetric fog, even with visible volumes" % tier)
	look.wld.quality = "max"
	var prior_route := OS.get_environment("VS_NEBULA_ROUTE")
	OS.set_environment("VS_NEBULA_ROUTE", "today")
	look.wld.set_look()
	_check(not look.env.volumetric_fog_enabled, "the Today route never enables volumetric fog, even with visible volumes")
	if prior_route.is_empty(): OS.unset_environment("VS_NEBULA_ROUTE")
	else: OS.set_environment("VS_NEBULA_ROUTE", prior_route)
	await look._world(LookBench.SKIES[-1][1], {}, [{"q": 0, "r": 0}])
	_check(not look.env.volumetric_fog_enabled and look.wld.find_children("*", "FogVolume", true, false).is_empty(),
		"a clear world clears the fog pass after a storm")
	look.free()


func _fixture_hulls() -> void:
	var fixture := "user://bench_hull_%d.tscn" % OS.get_process_id()
	var hull := Node3D.new()
	var part := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(12.0, 3.0, 4.0)
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, box.get_mesh_arrays())
	part.mesh = mesh
	hull.add_child(part)
	part.owner = hull
	var core := Node3D.new()
	core.name = "hp_core"
	hull.add_child(core)
	core.owner = hull
	var scene := PackedScene.new()
	_check(scene.pack(hull) == OK and ResourceSaver.save(scene, fixture) == OK, "saved the bench's stand-in hull")
	hull.free()
	var ships := {}
	for code in HT.AI_HULLS.values():
		ships[code] = {"res": fixture}
	SV._manifest = {"ships": ships}


func _added(node: Node) -> void:
	if node.scene_file_path == "res://scenes/battle/battle.tscn":
		# Build and warm the full scene without waiting for the bot to take a turn.
		node.showcase = true
	elif node.get_script() == WORLD:
		worlds_added += 1
		if worlds_added == 1:
			first_world_tier = str(node.get_parent().args["quality"])
	elif node.get_script() == SV:
		ships_added += 1


func _nebula_build(map_case: String, tier: String) -> void:
	worlds_added = 0
	ships_added = 0
	first_world_tier = ""
	var bench := NebulaBench.new()
	bench.map_case = map_case
	bench.route = "fog"
	bench.args["terrain-tier"] = tier
	root.add_child(bench)
	node_added.connect(_added)
	await bench._build("base", 4207)
	node_added.disconnect(_added)
	var battle = bench.b
	var unit_count: int = battle.V["units"].size()
	_check(worlds_added == 1 and ships_added == unit_count,
		"%s/%s builds one world and one fleet (got %d worlds and %d ship views for %d units)" %
		[map_case, tier, worlds_added, ships_added, unit_count])
	_check(first_world_tier == tier and battle.world.quality == tier and battle.gfx.quality == tier,
		"the initial scene, sampled terrain and FX all use %s" % tier)
	var gas := "neb" if map_case == "nebula" else "storm"
	_check(bench.build_ms > 0.0 and int(bench.patch_rows.get(gas, {}).get("hexes", 0)) > 0,
		"the timed scene has the selected terrain and patch metadata")
	bench.free()


func _run() -> void:
	OS.set_environment("VS_NEBULA_ROUTE", "fog")
	OS.set_environment("VS_SHIELD_SHAPE", "egg")
	BL.set_look("cine", false)
	_wreck_kit()
	_gallery_msaa()
	await _look_fog()
	_fixture_hulls()
	await _nebula_build("storm", "max")
	await _nebula_build("nebula", "high")
	SV.clear_static()
	print("World and bench audit failures=%d" % failures)
	quit(0 if failures == 0 else 1)
