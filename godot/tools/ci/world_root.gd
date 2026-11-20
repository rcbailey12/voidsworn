# Issues 1309 and 1355: the one way a check hands a loaded ship to fx. The game roots fx at ShipView, an unscaled node in
# world units with the hull under it scaled so its length along x is HT.length_for(code, cls) * SHIP_K (render/ship_view.gd
# setup and fit). A check does the same, at the same length. Rooted at the glb scene itself, the analysis ran in the file's
# own frame (an export7 ship is about one unit long), where Godot's TriangleMesh hit test misses the small triangles:
# CD5 r5d's optic seat read as clear and its inside triangles as outside the ship.
const HT := preload("res://render/hull_table.gd")
const MIN_L := 2.0      # a world-size hull is longer than this (the smallest class, Squadron, is 3.84); a file-size one about 1
const FIT_TOL := 0.002  # a held hull's analysed length is within this share of its intended length (A17 14.6 vs Cruiser 14.5 is 0.7%)


# The ship's code and class as its export wrote them: the node carrying the export's extras (length_world, cls) is named
# with the ship's game code. Empty strings when the scene carries none (a built fixture).
static func code_and_class(scene: Node3D) -> Array:
	for nd in [scene] + scene.find_children("*", "Node3D", true, false):
		var ex = nd.get_meta("extras", {})
		if ex is Dictionary and ex.has("length_world"):
			return [String(nd.name), str(ex.get("cls", ""))]
	return ["", ""]


# The length ShipView draws a ship at: its own hull length (HULL_LEN, e.g. C15s_23) or its class length, times SHIP_K.
static func game_length(code: String, cls: String) -> float:
	return HT.length_for(code, cls) * HT.SHIP_K


# Puts scene under a new unscaled node in world (or under holder, when given) and scales scene so its length along x is
# length; with length 0 or less, the length ShipView draws this ship at (its export's code and class). A built fixture
# with no export extras passes scale instead (its own size times scale). The intended length is kept on the holder
# (meta fx_check_length, 0 for a fixture scale) for at_game_size. Returns the node to pass to fx.add_ship.
static func hold(world: Node, scene: Node3D, length := -1.0, scale := -1.0, holder: Node3D = null) -> Node3D:
	if holder == null:
		holder = Node3D.new()
		holder.name = String(scene.name) + "_root"
		world.add_child(holder)
	if scene.get_parent() != null:
		scene.get_parent().remove_child(scene)
	holder.add_child(scene)
	scene.scale = Vector3.ONE
	if scale > 0.0:
		scene.scale = Vector3.ONE * scale
		holder.set_meta("fx_check_length", 0.0)
		return holder
	if length <= 0.0:
		var cc := code_and_class(scene)
		length = game_length(cc[0], cc[1])
	var box := AABB()
	var first := true
	for mi in scene.find_children("*", "MeshInstance3D", true, false) + ([scene] if scene is MeshInstance3D else []):
		var m := mi as MeshInstance3D
		if m.mesh == null: continue
		var bb: AABB = (holder.global_transform.affine_inverse() * m.global_transform) * m.mesh.get_aabb()
		box = bb if first else box.merge(bb)
		first = false
	scene.scale = Vector3.ONE * (length / maxf(box.size.x, 0.0001))
	holder.set_meta("fx_check_length", length)
	return holder


# The check every caller runs once fx has the ship: its hull was analysed at world size, and at the length it was meant to
# be drawn at (want; 0 checks world size only, for a fixture held at a fixed scale).
static func at_game_size(s: Object, want: float) -> bool:
	if s == null or float(s.hull.L) <= MIN_L:
		return false
	return want <= 0.0 or absf(float(s.hull.L) - want) <= want * FIT_TOL


# The message for a failed at_game_size.
static func size_note(s: Object, want: float) -> String:
	return "the hull is analysed at L %.2f, not at the length the game draws it (%s)" % [float(s.hull.L) if s != null else 0.0,
		"%.2f" % want if want > 0.0 else "world size, over %.1f" % MIN_L]


static func held_length(holder: Node) -> float:
	return float(holder.get_meta("fx_check_length", 0.0))
