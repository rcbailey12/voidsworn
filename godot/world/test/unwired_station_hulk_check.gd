extends SceneTree
# R420 Law 5, gate 6.2 item 1 (contrib/opus/plans/global_cohesion_standard.md), the station and hulk half (issue 1767;
# the planet half belongs to issue 1765): an approved asset must be reached by the live board, not only by a bench.
#   station_T2: the real render/board.gd build puts T2 (not O1_37) on a small (3-hex) cluster, the big (19-hex) cluster
#     and a station hole whenever T2 is installed (GitHub stands it in as a box with T2's bounds);
#   hulks: A4P.HULKS names a hull for every faction in the rules FACTIONS table, every named code is a manifest ship of
#     that faction, and the real board's _hulk() draws all six factions over a field of hulk hexes;
#   band and identity: every faction's derelict finish keeps base albedo inside band 3 (0.04 to 0.30 linear), Eclipse
#     hulks carry no green, Glasswright and Chorus hulks no metal soot.

const GUARD := preload("res://tools/ci/check_guard.gd")
const A4P := preload("res://assets/ships/a4_props.gd")
const BOARD := preload("res://render/board.gd")
const STUB := "res://render/test/fixtures/beacon/beacon_stub.tscn"
const SOOT := Color(0.32, 0.29, 0.27)

class StubRules extends RefCounted:
	var v := {}
	var w := {}
	func view() -> Dictionary:
		return v
	func world_info() -> Dictionary:
		return w

var failures := 0
var _keep: Array = []


func _init() -> void:
	GUARD.arm(self, "unwired_station_hulk_check")
	process_frame.connect(_run, CONNECT_ONE_SHOT)


func _report(ok: bool, what: String) -> void:
	print("%s: %s" % ["PASS" if ok else "FAIL", what])
	if not ok:
		failures += 1


func _run() -> void:
	if not ResourceLoader.exists(A4P.T2_PATH):
		var node := Node3D.new()
		var mi := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(99.2, 69.3, 70.2)
		mi.mesh = box
		node.add_child(mi)
		mi.owner = node
		var scene := PackedScene.new()
		scene.pack(node)
		node.free()
		scene.take_over_path(A4P.T2_PATH)
		_keep.append(scene)
	var ships := {"O1_37": {"res": STUB}}
	for fac in A4P.HULKS:
		for code in A4P.HULKS[fac]:
			ships[code] = {"res": STUB}
	A4P._man = {"ships": ships}
	_hulk_table()
	_board_wiring()
	_finishes()
	_keep.clear()
	quit(0 if failures == 0 else 1)


func _hulk_table() -> void:
	var tables: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://rules/data/tables.json"))
	var facs: Dictionary = tables.get("tables", tables)["FACTIONS"]
	var man: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/ships/manifest.json"))
	var rows: Dictionary = man.get("ships", man)
	var missing: Array = []
	var wrong: Array = []
	for fac in facs:
		if not A4P.HULKS.has(fac) or (A4P.HULKS[fac] as Array).is_empty():
			missing.append(fac)
	for fac in A4P.HULKS:
		for code in A4P.HULKS[fac]:
			if not rows.has(code) or str(rows[code].get("faction", "")) != fac:
				wrong.append(code)
	_report(missing.is_empty(), "A4P.HULKS names a hulk for every rules faction (missing: %s)" % str(missing))
	_report(wrong.is_empty(), "every hulk code is a manifest ship of its faction (wrong: %s)" % str(wrong))


func _board(terrain: Dictionary, holes: Array, map: Dictionary, radius: int) -> Node3D:
	var hexes := []
	for q in range(-radius, radius + 1):
		for r in range(-radius, radius + 1):
			if absi(q + r) <= radius:
				hexes.append({"q": q, "r": r})
	var m := map.duplicate()
	m["holes"] = holes
	var rules := StubRules.new()
	rules.v = {"hexes": hexes, "terrain": terrain, "units": [], "map": m}
	rules.w = {"seed": 11, "biome": {"rock": "stone", "planet": 0, "station": "rig"}}
	var board: Node3D = BOARD.new()
	root.add_child(board)
	board.build(rules)
	return board


func _count(board: Node3D, meta: String) -> Dictionary:
	var out := {}
	for n in board.find_children("*", "Node3D", true, false):
		if n.has_meta(meta):
			var k := str(n.get_meta(meta))
			out[k] = int(out.get(k, 0)) + 1
	return out


func _board_wiring() -> void:
	var small := _board({"0,0": "station", "1,0": "station", "0,1": "station"}, [{"kind": "station", "cells": [[4, -2]]}],
		{"station": {"q": 0, "r": 0}, "stationR": 1}, 6)
	var t2 := _count(small, "station_T2")
	var o1 := small.find_children("*", "", true, false).filter(func(n): return n.has_meta("station_kind") and not n.has_meta("station_T2"))
	_report(int(t2.get("true", 0)) == 2 and o1.is_empty(), "a small cluster and a station hole both get station_T2, no O1_37 (%s)" % str(t2))
	small.free()
	var big := {}
	for q in range(-2, 3):
		for r in range(-2, 3):
			if absi(q + r) <= 2:
				big["%d,%d" % [q, r]] = "station"
	var b2 := _board(big, [], {"station": {"q": 0, "r": 0}, "stationR": 2}, 6)
	_report(int(_count(b2, "station_T2").get("true", 0)) == 1, "the big cluster gets station_T2")
	b2.free()
	# a field of hulk hexes with no units (no local faction): the draw must reach every faction
	var field := {}
	for q in range(-6, 7):
		for r in range(-6, 7):
			if absi(q + r) <= 6 and (q * 7 + r * 3) % 4 == 0:
				field["%d,%d" % [q, r]] = "hulk"
	var b3 := _board(field, [], {}, 7)
	var got := _count(b3, "hulk_faction")
	_report(got.size() == 6, "the live _hulk() draws all six factions over %d hulk hexes: %s" % [field.size(), str(got)])
	b3.free()


func _finishes() -> void:
	# a bright, a mid and a near-black source paint per faction
	var sources := [Color(0.95, 0.93, 0.9), Color(0.5, 0.62, 0.7), Color(0.05, 0.05, 0.06)]
	for fac in A4P.HULKS:
		var worst := ""
		for c in sources:
			var src := StandardMaterial3D.new()
			src.albedo_color = c
			src.metallic = 0.0
			var d := A4P.derelict(src, fac)
			var y := A4P.linear_luma(d.albedo_color)
			if y < A4P.HULK_BAND.x - 1e-3 or y > A4P.HULK_BAND.y + 1e-3:
				worst = "luma %.3f from %s" % [y, str(c)]
			var g := d.albedo_color
			if fac == "deathless" and g.g > g.r * 1.15 and g.g > g.b * 1.15:
				worst = "green %s" % str(g)
			if fac in ["chorus", "ithar"] and g.is_equal_approx(SOOT):
				worst = "metal soot"
			if d.emission_enabled:
				worst = "lights still on"
		_report(worst == "", "%s derelicts stay in band 3 with their identity (%s)" % [fac, worst if worst != "" else "ok"])
