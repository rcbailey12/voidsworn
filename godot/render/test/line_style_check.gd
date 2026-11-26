extends SceneTree
# Issue 1374 (Ryan, Nov 20 2026, R362; docs/playbooks/scale.md section 6): every board line shares one style. Checks:
#   - the board's and the battle's line colours (grid per look, move hexes, hover, threat, targets, terrain and hazard
#     edges, solid rim) are the role table's (render/line_style.gd ROLE), not their own numbers;
#   - every line shader carries the shared code (width by camera distance, glow and fade): the hex fill (move hex rims),
#     the grid rings, the terrain edges, the battle's path line and the storm bolts (colours: the old ribbon and issue 1360's baked bolts);
#   - a shared strip is one quad of six vertices, its distance runs from just outside the line to past the glow band, and
#     a centred half starts at the middle; core-only roles (grid, targets, hover) carry no glow.

const GUARD := preload("res://tools/ci/check_guard.gd")
const LS := preload("res://render/line_style.gd")
const BOARD := preload("res://render/board.gd")
const BATTLE := preload("res://scenes/battle/battle.gd")
const LIVING := preload("res://world/world_living.gd")

var failures := 0


func _init() -> void:
	GUARD.arm(self, "line_style_check")
	_run.call_deferred()


func _check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		print("FAIL: ", message)


func _run() -> void:
	# colours: one table
	var same := {
		"BOARD.BASE_RING": [BOARD.BASE_RING, "grid"], "BOARD.REACH_FILL": [BOARD.REACH_FILL, "move_fill"],
		"BOARD.REACH_HOT": [BOARD.REACH_HOT, "move_hot"], "BOARD.REACH_RING": [BOARD.REACH_RING, "move"],
		"BOARD.HOVER_RING": [BOARD.HOVER_RING, "hover"], "BOARD.THREAT": [BOARD.THREAT, "threat"],
		"BOARD.SOLID_EDGE_C": [BOARD.SOLID_EDGE_C, "edge_solid"], "BATTLE.TARGET_RING": [BATTLE.TARGET_RING, "target"],
		"BATTLE.TARGET_PLAN": [BATTLE.TARGET_PLAN, "target_plan"], "BATTLE.TARGET_ON": [BATTLE.TARGET_ON, "target_on"],
	}
	for look in BOARD.LOOK_RING:
		same["BOARD.LOOK_RING." + look] = [BOARD.LOOK_RING[look], "grid" if look == "today" else "grid_" + look]
	for kind in BOARD.EDGE_C:
		same["BOARD.EDGE_C." + kind] = [BOARD.EDGE_C[kind], "edge_" + kind]
	for name in same:
		_check(LS.ROLE.has(same[name][1]), "%s: no role %s in the table" % [name, same[name][1]])
		_check(same[name][0] == LS.col(same[name][1]), "%s is not the role table's %s" % [name, same[name][1]])
	# shaders: the shared code in each
	var shaders := {"board FILL (move hex rims)": BOARD.FILL_SHADER, "board RING (grid)": BOARD.RING_SHADER,
		"board EDGE (terrain and hazard edges)": BOARD.EDGE_SHADER, "shared line (path)": LS.SHADER, "storm bolts": LIVING.BOLT_SHADER,
		"storm bolts, baked (issue 1360)": LIVING.BOLT_FLIP_SHADER}
	for name in shaders:
		_check(shaders[name].code.contains('#include "res://shaders/line_style.gdshaderinc"'), "%s does not include the shared line code" % name)
	_check(BOARD.FILL_SHADER.code.contains("ls_line("), "the move hex rim does not draw through ls_line")
	_check(BOARD.RING_SHADER.code.contains("ls_core_w(") and BOARD.RING_SHADER.code.contains("ls_dim("), "the grid does not use the shared width and fade")
	for code in [LIVING.BOLT_SHADER.code, LIVING.BOLT_FLIP_SHADER.code]:
		_check(code.contains("LS_BOLT_CORE") and code.contains("LS_BOLT_SKIRT") and code.contains("LS_BOLT_CORONA"), "the storm bolts keep their own colours")
	var src := FileAccess.get_file_as_string("res://scenes/battle/battle.gd")
	_check(src.contains("path_line.material_override = Board.LS.material()"), "the path line does not use the shared line material")
	# strips
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	LS.strip_into(st, Vector3(0, 0, 0), Vector3(10, 0, 0), Vector3(0, 0, 1), Vector3(0, 0, 1), "edge_neb", LS.col("edge_neb"))
	var arr := st.commit().surface_get_arrays(0)
	var uv: PackedVector2Array = arr[Mesh.ARRAY_TEX_UV]
	_check(uv.size() == 6, "an edge strip has %d vertices, want 6" % uv.size())
	var lo := 1e9
	var hi := -1e9
	for u in uv:
		lo = minf(lo, u.x)
		hi = maxf(hi, u.x)
		_check(is_equal_approx(u.y, 1.0), "an edge strip carries no glow")
	_check(lo < 0.0 and hi >= LS.GLOW_W + LS.CORE_W, "an edge strip runs %.2f to %.2f, want from outside the line past the glow band" % [lo, hi])
	var sc := SurfaceTool.new()
	sc.begin(Mesh.PRIMITIVE_TRIANGLES)
	LS.strip_into(sc, Vector3.ZERO, Vector3(10, 0, 0), Vector3(0, 0, 1), Vector3(0, 0, 1), "path", Color(0, 0, 0, -1), true)
	for u in sc.commit().surface_get_arrays(0)[Mesh.ARRAY_TEX_UV]:
		_check(u.x >= 0.0 and is_equal_approx(u.y, 3.0), "a centred path half does not start at the middle with its glow (%s)" % u)
	for role in ["grid", "target", "hover"]:
		_check(LS.glow(role) == 0.0, "%s draws a glow band (the grid and rings stay core only, RULEBOOK 10.1)" % role)
	for role in ["edge_neb", "path", "move_edge"]:
		_check(LS.glow(role) == 1.0, "%s draws no glow band" % role)
	print("line_style_check: %d colour roles, %d shaders, strips checked" % [same.size(), shaders.size()])
	print("line_style_check: " + ("PASS" if failures == 0 else "FAIL (%d)" % failures))
	quit(0 if failures == 0 else 1)
