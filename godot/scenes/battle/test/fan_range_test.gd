extends SceneTree

const Battle = preload("res://scenes/battle/battle.gd")
const Board = preload("res://render/board.gd")
const Rules = preload("res://rules/rules.gd")
const ShipView = preload("res://render/ship_view.gd")

func _initialize() -> void:
	var battle := Battle.new()
	var board := Board.new()
	battle.board = board
	battle.add_child(board)
	var host := Node3D.new()
	battle.add_child(host)
	battle.views["ship"] = host
	battle.args["arc-fill"] = true
	var rules := Rules.new()
	var failed := false
	for reach in range(1, 8):
		var mismatches := 0
		var checked := 0
		for facing in 6:
			var ship := {"q": 0, "r": 0, "facing": facing, "weapons": []}
			battle.VU["ship"] = ship
			host.rotation.y = ShipView.yaw_of(facing)
			for arc in Battle.ARC_SPAN:
				ship.weapons = [{"arc": arc, "range": reach, "ready": true, "kind": "macro"}]
				battle.fan_key = ""
				battle._fans("ship")
				var fan = battle.fan_root
				if fan == null or fan.get_child_count() != 2:
					printerr("FAN RANGE FAIL: missing fill or outline for arc ", arc)
					battle.free()
					quit(1)
					return
				var fill: PackedVector3Array = fan.get_child(0).mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
				var edge: PackedVector3Array = fan.get_child(1).mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
				var polygon := PackedVector2Array([Vector2.ZERO])
				# Each fill triangle runs from the origin to consecutive outer edge points.
				for i in range(0, fill.size(), 3):
					var outer := i * 2
					if not edge[outer].is_equal_approx(fill[i + 1]) or not edge[outer + 1].is_equal_approx(fill[i + 2]):
						printerr("FAN RANGE FAIL: fill and outline disagree for arc ", arc)
						failed = true
					polygon.append(_xz(edge[outer]))
				polygon.append(_xz(edge[(fill.size() - 3) * 2 + 1]))
				# The radius is under 122 world units. Eleven axial steps put a centre
				# at least 165 units out, so this window includes every possible overlap.
				for q in range(-10, 11):
					for r in range(-10, 11):
						if q == 0 and r == 0: continue
						var hex := {"q": q, "r": r}
						var centre := board.hex_world(q, r) - board.hex_world(0, 0)
						var local := centre.rotated(Vector3.UP, -host.rotation.y)
						var drawn := Geometry2D.is_point_in_polygon(_xz(local), polygon)
						var distance := rules.hdist(ship, hex)
						var legal := distance <= reach and rules.inArc(ship, hex, arc)
						checked += 1
						if drawn == legal: continue
						mismatches += 1
						print("range %d facing %d arc %s hex (%d,%d), rules distance %d, centre %.2f: drawn=%s legal=%s" %
							[reach, facing, arc, q, r, distance, centre.length(), drawn, legal])
				fan.free()
				battle.fan_root = null
		print("FAN RANGE %d: %d mismatches / %d centres%s" %
			[reach, mismatches, checked, " (reported only, all six facings)" if reach == 7 else ""])
		if reach < 7 and mismatches != 0: failed = true
	battle.free()
	quit(1 if failed else 0)

func _xz(v: Vector3) -> Vector2:
	return Vector2(v.x, v.z)
