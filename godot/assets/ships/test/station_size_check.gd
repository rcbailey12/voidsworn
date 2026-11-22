extends SceneTree
# Issue 975, then issue 1767 (World V2, R419): station_T2 is the one station on every station cluster and hole, and the
# board's derelict hulks come from all six factions. GitHub has no built ship files, so when the cache is missing the
# check stands in T2 as a box with T2's real bounds (99.2 x 69.3 x 70.2, production_checks.json) and every hulk code as
# the beacon stub box. It checks:
#   A4P: the big cluster gets T2 at unit scale; a smaller cluster and a lone hole get T2 scaled so every mesh box (corners
#     and points along each edge, at the placed bearing) projects inside the cluster's own hexes, tested here with its own
#     point-in-hex sum, not A4P's (Artoo on PR 1772: a circle round the corners let the flats overhang); the biome station kind is recorded and lights a faint lamp in its colour; a hole has no debris;
#   A4P: the hulk pool holds all six factions, each faction drawn equally often (then one of its hulls), the draw prefers the battle's factions about 70 percent of the time, and the
#     derelict finish keeps Glasswright glass and Chorus chitin in their own hue (never the metal soot);
#   the real board: a teaching (3-hex) cluster and a station hole build T2, level, inside their own hexes (the teaching
#     cluster on six board seeds, so six bearings); the big (19-hex) cluster keeps unit scale; a Chorus and Glasswright battle's hulk hexes draw their hulls, at positive scale (true chirality).

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
	var ships := {"O1_37": {"res": STUB}}
	for fac in PROPS.HULKS:
		for code in PROPS.HULKS[fac]:
			ships[code] = {"res": STUB}
	PROPS._man = {"ships": ships}
	_props_checks()
	_hulk_checks()
	_board_checks()
	_old_path_checks()
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


# the points of a node's mesh boxes (corners and points along every edge) that fall outside the pointy-top hexes of
# corner radius `hex_r` round `cells` (board x, z); the debris field is left out (it drifts below the board by design)
func _outside(n: Node3D, cells: Array, hex_r: float) -> int:
	var bad := 0
	var a := hex_r * sqrt(3.0) / 2.0
	for mi in n.find_children("*", "MeshInstance3D", true, false):
		if (mi as Node).get_parent().name == "station_T2_debris":
			continue
		var bb: AABB = (mi as MeshInstance3D).get_aabb()
		var xf: Transform3D = (mi as Node3D).global_transform
		for i in 8:
			for j in 8:
				if not [1, 2, 4].has(i ^ j) or j < i:
					continue
				for t in 9:
					var p: Vector3 = xf * bb.get_endpoint(i).lerp(bb.get_endpoint(j), float(t) / 8.0)
					var inside := false
					for c in cells:
						var dx := absf(p.x - (c as Vector2).x)
						var dz := absf(p.z - (c as Vector2).y)
						# a pointy-top hex (corners toward +z and -z): inside its flats and inside its slanted sides
						if dx <= a + 1e-3 and dz + dx / sqrt(3.0) <= hex_r + 1e-3:
							inside = true
							break
					if not inside:
						bad += 1
	return bad


func _props_checks() -> void:
	var large := PROPS.station(46.0)
	_report(large != null and large.has_meta("station_T2") and large.scale.is_equal_approx(Vector3.ONE),
		"station(46) returns T2 at unit scale (the approved big station)")
	# a 3-hex cluster round its centre, as the board passes it (pointy-top hexes, corner radius 10)
	var hw := HS * sqrt(3.0)
	var tri: Array = [Vector2(0, 0), Vector2(hw, 0), Vector2(hw / 2.0, 1.5 * HS)]
	var cen: Vector2 = (tri[0] + tri[1] + tri[2]) / 3.0
	var rel: Array = []
	for c in tri:
		rel.append((c as Vector2) - cen)
	var worst := 0
	var k_min := 1.0
	var k_max := 0.0
	for i in 12:
		var bearing := float(i) * 0.5
		var small := PROPS.station(34.0, 2.0 * HS, "rig", true, rel, HS, bearing)
		if small == null or not small.has_meta("station_T2"):
			worst = 99999
			break
		var k: float = small.scale.x
		k_min = minf(k_min, k)
		k_max = maxf(k_max, k)
		small.transform = Transform3D(Basis.from_euler(Vector3(0, bearing, 0)).scaled(Vector3.ONE * k), Vector3.ZERO)
		root.add_child(small)
		worst = maxi(worst, _outside(small, rel, HS))
		if i == 0:
			var lamp: Node = small.find_child("station_kind_light", true, false)
			_report(small.get_meta("station_kind", "") == "rig" and lamp is OmniLight3D
				and (lamp as OmniLight3D).light_color.is_equal_approx(PROPS.STATION_KINDS["rig"]["light"]) and not (lamp as OmniLight3D).shadow_enabled,
				"the biome kind rig is recorded and lights one faint unshadowed amber lamp")
		small.free()
	_report(worst == 0 and k_min > 0.05, "a 3-hex cluster's T2 projects inside its three hexes at 12 bearings (scale %.3f to %.3f, %d points outside)" % [k_min, k_max, worst])
	var hole := PROPS.station(14.0, HS, "spire", false, [Vector2.ZERO], HS, 0.0)
	var out_hole := 99999
	if hole != null:
		root.add_child(hole)
		out_hole = _outside(hole, [Vector2.ZERO], HS)
	_report(hole != null and hole.has_meta("station_T2") and out_hole == 0 and hole.find_child("station_T2_debris", true, false) == null,
		"a lone station hole's T2 projects inside its one hex (scale %.3f, %d points outside), with no drifting debris" % [hole.scale.x if hole else 0.0, out_hole])
	var plain := PROPS.station(34.0, 2.0 * HS, "", true, rel, HS, 0.0)
	_report(plain != null and plain.find_child("station_kind_light", true, false) == null,
		"no biome kind: no lamp")
	for n in [large, hole, plain]:
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
	var grey := StandardMaterial3D.new()
	grey.albedo_color = Color(0.7, 0.7, 0.7)
	var navy := PROPS.derelict(grey, "hegemony")
	var crusade := PROPS.derelict(grey, "voidsworn")
	var hull_breaker := PROPS.derelict(grey, "corsair")
	print("  grey paint burnt: hegemony %.3f, voidsworn %.3f, corsair %.3f linear" % [PROPS.linear_luma(navy.albedo_color), PROPS.linear_luma(crusade.albedo_color), PROPS.linear_luma(hull_breaker.albedo_color)])
	_report(PROPS.linear_luma(hull_breaker.albedo_color) <= PROPS.linear_luma(crusade.albedo_color) + 1e-4
		and PROPS.linear_luma(crusade.albedo_color) < PROPS.linear_luma(navy.albedo_color),
		"metal hulks burn by their own wound profile (Hullbreakers sootiest, Directorate cleanest), not one shared soot")
	# an equal draw per faction when no faction is local (two-hull factions are not drawn twice as often)
	var per := {}
	for v in 6000:
		var f := PROPS.hulk_faction(PROPS.pick_hulk(v * 2654435 + 7))
		per[f] = int(per.get(f, 0)) + 1
	var lo := 6000
	var hi := 0
	for f in per:
		lo = mini(lo, per[f])
		hi = maxi(hi, per[f])
	_report(per.size() == 6 and lo > 6000 * 0.12 and hi < 6000 * 0.22, "an ambient draw gives each faction about a sixth: %s" % str(per))
	# a textured pale glass hull stays in the dull band once its texture is counted (Fable on PR 1772, H9)
	var img := Image.create(8, 8, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.95, 0.97, 1.0))
	var pale := StandardMaterial3D.new()
	pale.albedo_texture = ImageTexture.create_from_image(img)
	var pg := PROPS.derelict(pale, "ithar")
	var eff := PROPS.texture_mean(pale) * pg.albedo_color
	var ye := PROPS.linear_luma(Color(eff.r, eff.g, eff.b))
	_report(ye <= PROPS.HULK_BAND.y + 1e-3 and ye >= PROPS.HULK_BAND.x - 1e-3, "a textured pale Glasswright hulk lands at %.3f linear, inside the dull band" % ye)


func _board(terrain: Dictionary, holes: Array, units: Array, map: Dictionary, radius: int, seed := 7) -> Node3D:
	var hexes := []
	for q in range(-radius, radius + 1):
		for r in range(-radius, radius + 1):
			if absi(q + r) <= radius:
				hexes.append({"q": q, "r": r})
	var m := map.duplicate()
	m["holes"] = holes
	var rules := StubRules.new()
	rules.v = {"hexes": hexes, "terrain": terrain, "units": units, "map": m}
	rules.w = {"seed": seed, "biome": {"rock": "stone", "planet": 0, "station": "ring"}}
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
	var ok1 := true
	for seed in [1, 2, 3, 4, 5, 6]:
		var b1 := _board(tri, [], units, {"station": {"q": 0, "r": 0}, "stationR": 1}, 6, seed)
		var s1 := _stations(b1)
		var one := s1.size() == 1
		if one:
			var st: Node3D = s1[0]
			var level: bool = absf(st.global_transform.basis.y.normalized().dot(Vector3.UP) - 1.0) < 1e-4
			var cells: Array = []
			for k in tri:
				var qr: PackedStringArray = k.split(",")
				var w: Vector3 = b1.hex_world(int(qr[0]), int(qr[1]))
				cells.append(Vector2(w.x, w.z))
			var bad := _outside(st, cells, HS)
			one = level and bad == 0 and st.get_meta("station_kind") == "ring"
			print("  teaching cluster on the board, seed %d: scale %.3f, %d points outside, level %s" % [seed, st.scale.x, bad, str(level)])
		ok1 = ok1 and one
		b1.free()
	_report(ok1, "the teaching battle's 3-hex cluster builds T2 level and inside its own hexes on the board (no banked O1_37)")
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
		var hp: Vector3 = b2.hex_world(6, -3)
		var hb := _outside(hole_one, [Vector2(hp.x, hp.z)], HS)
		print("  station hole on the board: scale %.3f, %d points outside" % [hole_one.scale.x, hb])
		_report(hb == 0 and hole_one.find_child("station_T2_debris", true, false) == null, "the station hole's T2 stays inside its hex on the board")
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


# VS_1767_OLD=1 (before pictures only): the old path comes back whole, and nothing of it leaks when the switch is off
func _old_path_checks() -> void:
	OS.set_environment("VS_1767_OLD", "1")
	var small := PROPS.station(34.0, 2.0 * HS, "rig", true, [Vector2.ZERO], HS, 0.0)
	var big := PROPS.station(46.0, 3.0 * HS, "rig")
	var facs := {}
	for v in 400:
		facs[PROPS.hulk_faction(PROPS.pick_hulk(v * 7919))] = true
	var glass := StandardMaterial3D.new()
	glass.albedo_color = Color(0.5, 0.8, 0.9)
	var g := PROPS.derelict(glass, "ithar")
	OS.set_environment("VS_1767_OLD", "")
	_report(small != null and not small.has_meta("station_T2") and small.get_child_count() == 1
		and small.get_child(0).scale.is_equal_approx(Vector3.ONE * 34.0), "VS_1767_OLD: a small cluster gets O1_37 at its size again")
	_report(big != null and big.has_meta("station_T2") and big.find_child("station_kind_light", true, false) == null,
		"VS_1767_OLD: the big cluster keeps T2 with no kind lamp")
	_report(facs.size() == 4 and not facs.has("chorus") and not facs.has("ithar"), "VS_1767_OLD: the old four factions' hulks only")
	_report(g.albedo_color.is_equal_approx(Color(0.32, 0.29, 0.27)), "VS_1767_OLD: the old soot on every hulk")
	var after := PROPS.station(34.0, 2.0 * HS, "", true, [Vector2.ZERO], HS, 0.0)
	_report(after != null and after.has_meta("station_T2"), "switch off again: T2 is back")
	for n in [small, big, after]:
		if n != null:
			n.free()
