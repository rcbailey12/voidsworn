extends SceneTree
const GUARD = preload("res://tools/ci/check_guard.gd")
# Issue 354 check: every picture a death spawns (vent, flash and any other baked kind) records its spawn with
# fx.record_spawn, and the gas root sits on the real plating, not at the centre of a picture pushed out by a fixed share
# of the ship's length. The test ship is the Eclipse cruiser, a disc with a tower, which does not fill its bounding box,
# so the old whole-box placement floats away from it.
#
# Run (Ryan's PC; needs the PC-built hulls in godot/gen):
#   godot --headless --path godot --script res://fx/test/death_spawn_check.gd
# Prints one line per death picture with the distance from its gas root to the ship's nearest hull sample, then PASS or
# FAIL, and exits 1 on any FAIL.
#
# The root of a baked vent picture is measured from the picture itself: the check reads the vent atlas and finds the
# lowest visible gas row in frame 0 inside the crop the shader samples, then places that point along the picture's up
# axis. It does not trust fx_death's VENT_ROOT_FRAC, so a picture changed without redoing that number (P3-16, issue 365)
# shows up here. The spawn bookkeeping is checked separately (every picture must be recorded), so a record that names a
# good point while the picture floats still fails.

const FX := preload("res://fx/fx.gd")
const SV := preload("res://render/ship_view.gd")
const PG := preload("res://render/placeholder_guard.gd")
const ROOT_FRAC := 0.40   # fallback only if the atlas cannot be read

var fx
var world: Node3D
var errors := 0
var pictures: Array = []
var root_frac := -1.0
var band := "cruiser"


func _init() -> void:
	GUARD.arm(self, "death_spawn_check")  # issue 632: a SCRIPT ERROR or a stuck run ends the check, never waits
	process_frame.connect(_run, CONNECT_ONE_SHOT)


func _run() -> void:
	world = Node3D.new()
	root.add_child(world)
	var cam := Camera3D.new()
	world.add_child(cam)
	cam.position = Vector3(0, 80, 120)
	fx = FX.new()
	world.add_child(fx)
	fx.manual = true
	fx.setup({"camera": cam, "quality": "max", "shake": 0.0})
	fx.check_radius = true
	var ship: Node3D = _ship("T", "deathless", "Cruiser")
	if PG.stop_if_any():
		return
	# Let the staggered cut precompute finish before the death, as a battle does.
	for i in 150:
		fx.step(1.0 / 60.0)
		await process_frame
	var hull = fx.ship("T").hull
	band = "small" if float(hull.L) < 18.0 else ("cruiser" if float(hull.L) < 30.0 else "capital")
	var samples := PackedVector3Array()
	for p in hull.sp:
		samples.append(fx.ship("T").to_world(p))
	var limit: float = 0.08 * float(hull.L)
	fx.effect_spawns.clear()
	var t: float = fx.now
	fx.death("T", "blast")
	while fx.now < t + 3.5:
		fx.step(1.0 / 60.0)
		_scan()
		await process_frame
	var kinds := {}
	for pic in pictures:
		var kind: String = pic["kind"]
		kinds[kind] = int(kinds.get(kind, 0)) + 1
		# Issue 462: a picture born on a drifting wreck piece carries that piece's frame; its hull samples move with it.
		var d: float = _nearest(pic["root"], samples) if pic["frame"] == null else _nearest(pic["root"], _moved(hull, pic["frame"]))
		var ok: bool = d <= limit
		print("%s %s root %.3f from the hull (limit %.3f)" % ["PASS" if ok else "FAIL", kind, d, limit])
		if not ok:
			errors += 1
	if pictures.is_empty():
		print("FAIL no death picture was spawned at all")
		errors += 1
	if fx.effect_spawns.size() < pictures.size():
		print("FAIL only %d of %d death pictures recorded a spawn with fx.record_spawn" % [fx.effect_spawns.size(), pictures.size()])
		errors += 1
	var stray: Array = fx.stray_spawns()
	if not stray.is_empty():
		print("FAIL stray death spawns: %s" % str(stray.slice(0, 8)))
		errors += 1
	print("DEATH_SPAWN pictures=%d vent=%d flash=%d cool=%d recorded=%d stray=%d errors=%d" % [
		pictures.size(), int(kinds.get("vent", 0)), int(kinds.get("flash", 0)), int(kinds.get("cool", 0)),
		fx.effect_spawns.size(), stray.size(), errors])
	print("DEATH_SPAWN " + ("PASS" if errors == 0 else "FAIL"))
	quit(1 if errors > 0 else 0)


func _ship(id: String, fac: String, cls: String) -> Node3D:
	var sv: Node3D = SV.new()
	sv.name = "ship_" + id
	world.add_child(sv)
	sv.setup({"id": id, "fac": fac, "cls": cls, "facing": 0, "hp": 100, "maxHp": 100, "size": 1.0}, Vector3.ZERO, true)
	var info := {"faction": fac, "cls": cls, "size": 1.0, "squadron": false, "flagship": false, "code": sv.code}
	if not sv.a4:
		info["meshes"] = sv.meshes
	fx.add_ship(id, sv, info)
	return sv


# Scan the children fx_death adds for a baked picture and keep the ones not seen yet. A sibling with the same name is
# renamed by Godot (a second "fx_baked_cool" becomes "@MeshInstance3D@N"), so identify pictures by their metadata.
func _scan() -> void:
	for node in fx.get_children():
		if not (node is MeshInstance3D):
			continue
		var kind := ""
		if node.has_meta("fx_picture_kind"):
			kind = String(node.get_meta("fx_picture_kind"))
		elif String(node.name).begins_with("fx_baked_"):
			kind = String(node.name).trim_prefix("fx_baked_")
		elif node.material_override is ShaderMaterial and (node.material_override as ShaderMaterial).get_shader_parameter("extent") != null:
			# The code before issue 354 has no picture metadata, and Godot renames a duplicate sibling, so read the
			# kind from the shader it was built with.
			var m := node.material_override as ShaderMaterial
			kind = "vent" if float(m.get_shader_parameter("directional")) > 0.5 else ("flash" if float(m.get_shader_parameter("plasma")) > 0.5 else "cool")
		if kind == "":
			continue
		var seen := false
		for pic in pictures:
			if pic["node"] == node:
				seen = true
				break
		if seen:
			continue
		pictures.append({"node": node, "kind": kind, "root": _picture_root(node), "frame": node.get_meta("spawn_frame", null)})


# The root is worked out from the picture as it is drawn, never from the spawn bookkeeping: the vent's visible gas
# starts at the share measured from the atlas (about 0.40 of the picture height) along its up axis from the picture
# centre. Flash and cool pictures are centred on their spawn point. A record that names a good point while the picture
# floats still fails here.
func _picture_root(node: Node3D) -> Vector3:
	var is_vent: bool = (str(node.get_meta("fx_picture_kind", "")) == "vent") or String(node.name).begins_with("fx_baked_vent")
	var m = node.material_override
	if not is_vent and m is ShaderMaterial:
		is_vent = float((m as ShaderMaterial).get_shader_parameter("directional")) > 0.5
	if is_vent and m is ShaderMaterial:
		var up = (m as ShaderMaterial).get_shader_parameter("tear_normal")
		var extent = (m as ShaderMaterial).get_shader_parameter("extent")
		if up is Vector3 and extent != null:
			if root_frac < 0.0:
				root_frac = _measure_root(m as ShaderMaterial)
			return node.global_position + (up as Vector3) * float(extent) * root_frac
	return node.global_position


# Read frame 0 of the vent atlas and find the lowest visible gas row inside the crop the shader samples. The picture's
# gas root is that row: its distance from the picture centre, as a share of the crop height.
func _measure_root(m: ShaderMaterial) -> float:
	var rect = m.get_shader_parameter("atlas_rect")
	if not (rect is Vector4):
		print("WARN the vent picture has no atlas crop; using the recorded root share %.2f" % ROOT_FRAC)
		return ROOT_FRAC
	# Read the source picture, not the imported copy: the imported Texture2D may carry mipmap or alpha-border
	# processing that changes the lowest visible row, and this must also work before the project is imported.
	var path := "res://fx/atlases/death/%s/vent_color.png" % band
	var img := Image.new()
	var bytes := FileAccess.get_file_as_bytes(path)
	if bytes.is_empty() or img.load_png_from_buffer(bytes) != OK or img.is_empty():
		print("WARN cannot read %s; using the recorded root share %.2f" % [path, ROOT_FRAC])
		return ROOT_FRAC
	var r: Vector4 = rect
	var cell: int = img.get_height() / 4
	var x0: int = maxi(0, int(floor(r.x * cell)))
	var x1: int = mini(cell, int(ceil((r.x + r.z) * cell)))
	var y0: int = maxi(0, int(floor(r.y * cell)))
	var y1: int = mini(cell, int(ceil((r.y + r.w) * cell)))
	var low := -1
	for y in range(y0, y1):
		for x in range(x0, x1):
			if img.get_pixel(x, y).a > 0.12:
				low = y
				break
	if low < 0:
		print("WARN no gas found in %s; using the recorded root share %.2f" % [path, ROOT_FRAC])
		return ROOT_FRAC
	var share: float = (float(low) / float(cell) - r.y) / r.w - 0.5
	print("vent atlas root %.3f of the picture height (%s)" % [share, path])
	return share


func _moved(hull, frame: Transform3D) -> PackedVector3Array:
	var out := PackedVector3Array()
	for p in hull.sp:
		out.append(frame * p)
	return out


func _nearest(p: Vector3, samples: PackedVector3Array) -> float:
	var best := INF
	for q in samples:
		best = minf(best, p.distance_to(q))
	return best
