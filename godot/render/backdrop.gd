extends Node3D
# Interim backdrop dressing until godot/world (G4) lands: the A3 asteroid field (asteroids.json, seed 7, the same rocks
# as the effects proof) moved out round the board and below it, so it frames the battle without sitting on playable
# hexes, tumbling slowly; plus the A3 thin dust haze. Rocks come from gen/rocks (the field names its rock meshes).

var rocks: Array = []
var _t := 0.0


func build(board_bounds: Vector2, env: Environment) -> void:
	for c in get_children():
		c.queue_free()
	rocks.clear()
	var man := {}
	if FileAccess.file_exists("res://gen/manifest.json"):
		man = JSON.parse_string(FileAccess.get_file_as_string("res://gen/manifest.json"))
	var fp := str(man.get("field", ""))
	if fp == "" or not FileAccess.file_exists(fp):
		return
	var data = JSON.parse_string(FileAccess.get_file_as_string(fp))
	if not (data is Dictionary) or not data.has("rocks"):
		return
	var R0 := board_bounds.length() * 0.62 + 40.0
	var meshes := {}
	for r in data["rocks"]:
		var name: String = r["mesh"]
		if not meshes.has(name):
			var p := "res://gen/rocks/%s.res" % name
			meshes[name] = load(p) if ResourceLoader.exists(p) else null
		var m: Mesh = meshes[name]
		if m == null:
			continue
		var p0 := Vector3(r["position"][0], r["position"][1], r["position"][2])
		var d := Vector2(p0.x, p0.z)
		var ang := d.angle() if d.length() > 1.0 else randf() * TAU
		var rad := R0 + d.length() * 1.6
		var big := str(r.get("kind", "field")) != "field"
		var pos := Vector3(cos(ang) * rad * 1.15, p0.y * 2.0 - (70.0 if big else 45.0), sin(ang) * rad)
		var q: Array = r["rotation"]
		var e := {"pos": pos, "scale": float(r["scale"]) * (1.6 if big else 1.3), "rot": Basis(Quaternion(q[0], q[1], q[2], q[3])),
			"axis": Vector3(r["spin_axis"][0], r["spin_axis"][1], r["spin_axis"][2]).normalized(), "rate": float(r["spin_rate"])}
		var mi := MeshInstance3D.new()
		mi.mesh = m
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF if not big else GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		add_child(mi)
		e["node"] = mi
		rocks.append(e)
	_update()
	if RenderingServer.get_current_rendering_method() != "gl_compatibility":
		env.volumetric_fog_enabled = true
		env.volumetric_fog_density = 0.0001
		env.volumetric_fog_albedo = Color(0.42, 0.44, 0.5)
		env.volumetric_fog_length = 400.0
		env.volumetric_fog_anisotropy = 0.6
		env.volumetric_fog_sky_affect = 0.15


func _update() -> void:
	for e in rocks:
		(e["node"] as Node3D).transform = Transform3D(Basis(e["axis"], e["rate"] * _t) * e["rot"] * Basis.from_scale(Vector3.ONE * e["scale"]), e["pos"])


func _process(dt: float) -> void:
	_t += dt
	_update()
