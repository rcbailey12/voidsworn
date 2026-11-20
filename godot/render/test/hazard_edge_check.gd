extends SceneTree
# Issue 1267 (Ryan's pick 1, Nov 20): in the normal (cine) view, a faint line on the outer edge of nebula and ion storm
# patches shows where cover and shield drain stop, without pressing Z. Builds a board with a nebula patch, a storm patch
# (touching the nebula), a debris patch and a rock, and checks:
#   cine: the hazard outline holds exactly the outer boundary edges of the nebula and storm patches (no shared inner
#     edges, no debris or rock edges, nebula and storm colours only), at the faint gain, and the Z-only gas edges stay off;
#   Z (tactical): the hazard outline is off and the gas edges (every natural terrain hex edge) are as before, at 0.9;
#   a rebuild of the edges (a new wreck, PR 1246's _rebuild_edges) keeps both rules.

const GUARD := preload("res://tools/ci/check_guard.gd")
const BOARD := preload("res://render/board.gd")
const BL := preload("res://world/board_look.gd")
const VERTS_PER_EDGE := 12   # _edge_into: a line and a fading band, two triangles each

class StubRules extends RefCounted:
	var v := {}
	func view() -> Dictionary:
		return v

var failures := 0


func _init() -> void:
	GUARD.arm(self, "hazard_edge_check")
	_run.call_deferred()


func _check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		print("FAIL: ", message)


const NEIGHBOURS := [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1), Vector2i(1, -1), Vector2i(-1, 1)]


# outer edges of a hex patch: neighbours not in the same patch
func _outer(keys: Array) -> int:
	var n := 0
	for k in keys:
		var qr: PackedStringArray = str(k).split(",")
		for d in NEIGHBOURS:
			if not keys.has("%d,%d" % [int(qr[0]) + d.x, int(qr[1]) + d.y]):
				n += 1
	return n


func _verts(mi: MeshInstance3D) -> PackedVector3Array:
	if mi == null or mi.mesh == null:
		return PackedVector3Array()
	return mi.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]


func _colours(mi: MeshInstance3D) -> Dictionary:
	var out := {}
	if mi == null or mi.mesh == null:
		return out
	for c in mi.mesh.surface_get_arrays(0)[Mesh.ARRAY_COLOR]:
		out[Color((c as Color).r, (c as Color).g, (c as Color).b).to_html(false)] = true
	return out


func _gain(mi: MeshInstance3D) -> float:
	return float((mi.material_override as ShaderMaterial).get_shader_parameter("gain"))


func _expect(board, label: String, neb: Array, storm: Array, natural: int) -> void:
	BL.set_look("cine", false)
	BL.tactical = false
	board.apply_look(false)
	var hz: MeshInstance3D = board.hazard_edges
	_check(hz != null, "%s: no hazard outline mesh" % label)
	if hz == null:
		return
	var want := (_outer(neb) + _outer(storm)) * VERTS_PER_EDGE
	_check(_verts(hz).size() == want, "%s: the hazard outline has %d vertices, want %d (only the patches' outer edges)" % [label, _verts(hz).size(), want])
	var allowed: Array = [BOARD.EDGE_C["neb"], BOARD.EDGE_C["storm"]]
	for c in _colours(hz):
		var col := Color.html(c)
		var ok := false
		for a in allowed:
			ok = ok or (absf(col.r - a.r) < 0.02 and absf(col.g - a.g) < 0.02 and absf(col.b - a.b) < 0.02)
		_check(ok, "%s: the hazard outline carries a colour that is not nebula or storm (%s)" % [label, c])
	_check(hz.visible and is_equal_approx(_gain(hz), 0.25), "%s: cine hazard outline visible %s at gain %.2f, want visible at 0.25" % [label, hz.visible, _gain(hz)])
	_check(not board.gas_edges.visible, "%s: cine shows the Z-only gas edges" % label)
	BL.tactical = true
	board.apply_look(false)
	_check(not hz.visible, "%s: Z shows the hazard outline on top of its own gas edges" % label)
	_check(board.gas_edges.visible and is_equal_approx(_gain(board.gas_edges), 0.9), "%s: Z gas edges changed (gain %.2f)" % [label, _gain(board.gas_edges)])
	_check(_verts(board.gas_edges).size() == natural * VERTS_PER_EDGE, "%s: Z gas edges have %d vertices, want %d" % [label, _verts(board.gas_edges).size(), natural * VERTS_PER_EDGE])
	BL.tactical = false
	board.apply_look(false)
	print("%s: hazard outline %d edges (nebula %d, storm %d) at gain %.2f; Z gas edges %d" % [label, _verts(hz).size() / VERTS_PER_EDGE,
		_outer(neb), _outer(storm), _gain(hz), _verts(board.gas_edges).size() / VERTS_PER_EDGE])


func _run() -> void:
	var hexes: Array = []
	for r in range(-5, 6):
		for q in range(-7, 8):
			hexes.append({"q": q, "r": r})
	var neb := ["0,0", "1,0", "0,1", "1,1", "-1,1"]
	var storm := ["2,0", "3,0", "2,1", "3,-1"]   # "2,0" touches the nebula: that edge belongs to both patches' outsides
	var debris := ["-4,2", "-3,2"]
	var rock := ["4,3"]
	var terrain := {}
	for k in neb: terrain[k] = "neb"
	for k in storm: terrain[k] = "storm"
	for k in debris: terrain[k] = "debris"
	for k in rock: terrain[k] = "rock"
	var rules := StubRules.new()
	rules.v = {"hexes": hexes, "terrain": terrain}
	var board: Node3D = BOARD.new()
	root.add_child(board)
	board.build(rules)
	var natural := _outer(neb) + _outer(storm) + _outer(debris) + _outer(rock)
	_expect(board, "built", neb, storm, natural)
	board._rebuild_edges()
	_expect(board, "rebuilt", neb, storm, natural)
	board.free()
	print("hazard_edge_check: ", "PASS" if failures == 0 else "FAIL (%d)" % failures)
	quit(1 if failures > 0 else 0)
