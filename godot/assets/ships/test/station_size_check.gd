extends SceneTree
# Issue 975, then issue 1767 (World V2, R419): station_T2 is the one station on every station cluster and hole, and the
# board's derelict hulks come from all six factions. GitHub has no built ship files, so when the cache is missing the
# check stands in T2 as a box with T2's real bounds (99.2 x 69.3 x 70.2, production_checks.json) and every hulk code as
# the beacon stub box. It checks:
#   A4P: the big cluster gets T2 at unit scale; a smaller cluster and a lone hole get T2 scaled so its measured reach stays
#     inside the clearance; the biome station kind is recorded and lights a faint lamp in its colour; a hole has no debris;
#   A4P: the hulk pool holds all six factions, the draw prefers the battle's factions about 70 percent of the time, and the
#     derelict finish keeps Glasswright glass and Chorus chitin in their own hue (never the metal soot);
#   the real board: a teaching (3-hex) cluster, a big (19-hex) cluster and a station hole all build T2, level, inside their
#     clearance; a Chorus and Glasswright battle's hulk hexes draw their hulls, at positive scale (true chirality).

const GUARD := preload("res://tools/ci/check_guard.gd")
const PROPS := preload("res://assets/ships/a4_props.gd")
const BOARD := preload("res://render/board.gd")
const T2_PATH := "res://gen/ships/station_T2.scn"
const STUB := "res://render/test/fixtures/beacon/beacon_stub.tscn"
const HS := 10.0

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
	GUARD.arm(self, "station_size_check")
	process_frame.connect(_run, CONNECT_ONE_SHOT)


func _report(ok: bool, description: String) -> void:
	print("%s: %s" % ["PASS" if ok else "FAIL", description])
	if not ok:
		failures += 1


func _run() -> void:
	if not ResourceLoader.exists(T2_PATH):
		_keep.append(_t2_stand_in())
	if not ResourceLoader.exists(T2_PATH):
		_report(false, "T2 must be in the cache for this check")
		quit(1)
		return
	var ships := {}
	for fac in PROPS.HULKS:
		for code in PROPS.HULKS[fac]:
			ships[code] = {"res": STUB}
	PROPS._man = {"ships": ships}
	_props_checks()
	_hulk_checks()
	_board_checks()
	_keep.clear()
	quit(0 if failures == 0 else 1)


func _t2_stand_in() -> PackedScene:
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
	scene.take_over_path(T2_PATH)
	return scene


# the widest horizontal reach of a node's meshes from `centre`, in world units
func _reach(n: Node3D, centre: Vector3) -> float:
	var best := 0.0
	for mi in n.find_children("*", "MeshInstance3D", true, false):
		if not (mi as Node3D).is_visible_in_tree() or (mi as Node).get_parent().name == "station_T2_debris":
			continue
		var bb: AABB = (mi as MeshInstance3D).get_aabb()
		var xf: Transform3D = (mi as Node3D).global_transform
		for i in 8:
			var p: Vector3 = xf * bb.get_endpoint(i) - centre
			best = maxf(best, Vector2(p.x, p.z).length())
	return best


func _props_checks() -> void:
	var large := PROPS.station(46.0)
	_report(large != null and large.has_meta("station_T2") and large.scale.is_equal_approx(Vector3.ONE),
		"station(46) returns T2 at unit scale (the approved big station)")
	var small := PROPS.station(34.0, 2.0 * HS, "rig")
	var k_small: float = small.scale.x if small != null else 0.0
	var reach: float = PROPS._reach.get(T2_PATH, 0.0)
	_report(small != null and small.has_meta("station_T2") and k_small < 1.0 and reach * k_small <= 2.0 * HS + 0.01,
		"station(34) on a 3-hex cluster returns T2 at scale %.3f, reach %.1f inside clearance %.1f" % [k_small, reach * k_small, 2.0 * HS])
	var lamp: Node = small.find_child("station_kind_light", true, false) if small != null else null
	_report(small != null and small.get_meta("station_kind", "") == "rig" and lamp is OmniLight3D
		and (lamp as OmniLight3D).light_color.is_equal_approx(PROPS.STATION_KINDS["rig"]["light"]) and not (lamp as OmniLight3D).shadow_enabled,
		"the biome kind rig is recorded and lights one faint unshadowed amber lamp")
	var hole := PROPS.station(14.0, HS, "spire", false)
	_report(hole != null and hole.has_meta("station_T2") and reach * hole.scale.x <= HS + 0.01
		and hole.find_child("station_T2_debris", true, false) == null,
		"a lone station hole returns T2 inside one hex (reach %.1f), with no drifting debris" % (reach * hole.scale.x if hole else 0.0))
	var plain := PROPS.station(34.0, 2.0 * HS)
	_report(plain != null and plain.find_child("station_kind_light", true, false) == null,
		"no biome kind: no lamp")
	for n in [large, small, hole, plain]:
		if n != null:
			n.free()


func _hulk_checks() -> void:
	var facs := {}
	for v in 600:
		facs[PROPS.hulk_faction(PROPS.pick_hulk(v * 7919))] = true
	_report(facs.size() == 6 and not facs.has(""), "the hulk draw reaches all six factions: %s" % str(facs.keys()))
	var local := 0
	var n := 1000
	for v in n:
		var code := PROPS.pick_hulk(v * 104729 + 17, ["chorus", "ithar"])
		if PROPS.hulk_faction(code) in ["chorus", "ithar"]:
			local += 1
	# 70 percent local plus their share (4 of 8 hulls) of the 30 percent ambient draw: about 85 percent
	_report(local > n * 0.75 and local < n * 0.95, "a Chorus and Glasswright battle draws their hulks %d of %d times" % [local, n])
	var glass := StandardMaterial3D.new()
	glass.albedo_color = Color(0.5, 0.8, 0.9, 0.6)
	glass.roughness = 0.1
	glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass.emission_enabled = true
	var g := PROPS.derelict(glass, "ithar")
	_report(is_equal_approx(g.albedo_color.a, 0.6) and g.albedo_color.b > g.albedo_color.r and is_equal_approx(g.roughness, 0.1)
		and g.transparency == BaseMaterial3D.TRANSPARENCY_ALPHA and not g.emission_enabled,
		"a dead Glasswright keeps its glass hue, clarity and gloss, lights out")
	var chitin := StandardMaterial3D.new()
	chitin.albedo_color = Color(0.6, 0.3, 0.35)
	chitin.roughness = 0.5
	var c := PROPS.derelict(chitin, "chorus")
	var soot := PROPS.derelict(chitin, "hegemony")
	_report(c.albedo_color.r > c.albedo_color.g and not c.albedo_color.is_equal_approx(soot.albedo_color),
		"a dead Chorus keeps its own chitin colour, not the metal soot")
	_report(soot.albedo_color.is_equal_approx(Color(0.32, 0.29, 0.27)), "metal hulls keep the old soot finish")


func _board(terrain: Dictionary, holes: Array, units: Array, map: Dictionary, radius: int) -> Node3D:
	var hexes := []
	for q in range(-radius, radius + 1):
		for r in range(-radius, radius + 1):
			if absi(q + r) <= radius:
				hexes.append({"q": q, "r": r})
	var m := map.duplicate()
	m["holes"] = holes
	var rules := StubRules.new()
	rules.v = {"hexes": hexes, "terrain": terrain, "units": units, "map": m}
	rules.w = {"seed": 7, "biome": {"rock": "stone", "planet": 0, "station": "ring"}}
	var board: Node3D = BOARD.new()
	root.add_child(board)
	board.build(rules)
	return board


func _stations(board: Node3D) -> Array:
	var out: Array = []
	for n in board.find_children("*", "Node3D", true, false):
		if n.has_meta("station_T2"):
			out.append(n)
	return out


func _board_checks() -> void:
	var units := [{"id": "p1", "side": "player", "fac": "ithar", "q": 0, "r": 5}, {"id": "e1", "side": "enemy", "fac": "chorus", "q": 0, "r": -5}]
	# a teaching cluster: three station hexes, rules radius 1 (rules.gd edgeFeature for a defend battle)
	var tri := {"0,0": "station", "1,0": "station", "0,1": "station"}
	var b1 := _board(tri, [], units, {"station": {"q": 0, "r": 0}, "stationR": 1}, 6)
	var s1 := _stations(b1)
	var cen: Vector3 = (b1.hex_world(0, 0) + b1.hex_world(1, 0) + b1.hex_world(0, 1)) / 3.0
	var ok1 := s1.size() == 1
	if ok1:
		var st: Node3D = s1[0]
		var level: bool = absf(st.global_transform.basis.y.normalized().dot(Vector3.UP) - 1.0) < 1e-4
		var r := _reach(st, cen)
		ok1 = level and r <= 2.0 * HS + 0.05 and st.get_meta("station_kind") == "ring"
		print("  teaching cluster: scale %.3f, reach %.1f of 20.0, level %s" % [st.scale.x, r, str(level)])
	_report(ok1, "the teaching battle's 3-hex cluster builds T2 level and inside its clearance (no banked O1_37)")
	b1.free()
	# the big station: every hex within 2 of the centre (19 hexes)
	var big := {}
	for q in range(-2, 3):
		for r in range(-2, 3):
			if absi(q + r) <= 2:
				big["%d,%d" % [q, r]] = "station"
	var hulks := {"5,-1": "hulk", "-5,1": "hulk", "4,1": "hulk", "-4,-1": "hulk", "1,4": "hulk", "-1,-4": "hulk"}
	big.merge(hulks)
	var b2 := _board(big, [{"kind": "station", "cells": [[6, -3]]}], units, {"station": {"q": 0, "r": 0}, "stationR": 2}, 8)
	var s2 := _stations(b2)
	var big_one: Node3D = null
	var hole_one: Node3D = null
	for st in s2:
		if (st as Node3D).scale.is_equal_approx(Vector3.ONE):
			big_one = st
		else:
			hole_one = st
	_report(s2.size() == 2 and big_one != null, "the big cluster keeps T2 at unit scale")
	if hole_one != null:
		var hr := _reach(hole_one, b2.hex_world(6, -3))
		print("  station hole: scale %.3f, reach %.1f of 10.0" % [hole_one.scale.x, hr])
		_report(hr <= HS + 0.05 and hole_one.find_child("station_T2_debris", true, false) == null, "the station hole's T2 stays inside its hex")
	else:
		_report(false, "the station hole builds T2")
	var got := {}
	var mirrored := 0
	for n in b2.find_children("*", "Node3D", true, false):
		if n.has_meta("hulk_faction"):
			got[n.get_meta("hulk_faction")] = int(got.get(n.get_meta("hulk_faction"), 0)) + 1
			var bs: Basis = (n as Node3D).global_transform.basis
			if bs.determinant() <= 0.0:
				mirrored += 1
	var local := int(got.get("chorus", 0)) + int(got.get("ithar", 0))
	print("  hulks by faction: %s" % str(got))
	_report(local >= 3 and mirrored == 0, "a Chorus and Glasswright battle's six hulk hexes draw mostly their hulls (%d), none mirrored" % local)
	b2.free()
