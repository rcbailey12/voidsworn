extends Node3D
# The hex board at the game's scale: pointy-top hexes of corner radius 10 (HEX_S), laid out as scene3d.js hexWorld does,
# with the world's z mirrored for Godot. One MultiMesh for the hex fills and one for the outlines (two draws for the
# whole board); overlays (move range, targets, hover, zones) only change instance colours.

const HT := preload("res://render/hull_table.gd")
const HS := 10.0
var HW := HS * sqrt(3.0)

var R = null                 # the rules (rules_bridge)
var ox := 0.0
var oz := 0.0
var cells: Array = []        # [{q, r}]
var index := {}              # "q,r" -> instance index
var fills: MultiMeshInstance3D
var rings: MultiMeshInstance3D
var base_fill := {}          # "q,r" -> Color (terrain zone tints)
var overlay := {}            # "q,r" -> Color
var ring_over := {}          # "q,r" -> Color
var hover_key := ""
var props: Node3D
var rock_meshes: Array = []

const FILL_SHADER := """
shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;
varying vec4 vcol;
varying vec2 vp;
void vertex() { vcol = COLOR; vp = VERTEX.xz; }
void fragment() {
	// soft inner falloff so a lit hex reads as a glow, not a flat plate
	float r = length(vp) / 10.0;
	float k = mix(0.75, 1.0, smoothstep(0.2, 0.95, r));
	ALBEDO = vcol.rgb;
	ALPHA = vcol.a * k;
}
"""
const RING_SHADER := """
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;
varying vec4 vcol;
void vertex() { vcol = COLOR; }
void fragment() { ALBEDO = vcol.rgb * vcol.a; }
"""


func hex_world(q: float, r: float, y := 0.0) -> Vector3:
	return Vector3(HW * (q + r / 2.0) + ox, y, 1.5 * HS * r + oz)


func world_hex(p: Vector3) -> Vector2i:
	var x := p.x - ox
	var z := p.z - oz
	var rr := z / (1.5 * HS)
	var qq := x / HW - rr / 2.0
	# cube rounding
	var cx := qq
	var cz := rr
	var cy := -cx - cz
	var rx := roundf(cx)
	var ry := roundf(cy)
	var rz := roundf(cz)
	var dx := absf(rx - cx)
	var dy := absf(ry - cy)
	var dz := absf(rz - cz)
	if dx > dy and dx > dz:
		rx = -ry - rz
	elif dy > dz:
		ry = -rx - rz
	else:
		rz = -rx - ry
	return Vector2i(int(rx), int(rz))


func key(q, r) -> String:
	return str(int(q)) + "," + str(int(r))


func build(rules) -> void:
	R = rules
	for c in get_children():
		c.queue_free()
	cells = R.boardHexes()
	# centre the board on the world origin (the game offsets by G.ox, G.oz the same way)
	var lo := Vector2(1e9, 1e9)
	var hi := Vector2(-1e9, -1e9)
	for h in cells:
		var p := Vector2(HW * (float(h.q) + float(h.r) / 2.0), 1.5 * HS * float(h.r))
		lo = lo.min(p)
		hi = hi.max(p)
	ox = -(lo.x + hi.x) * 0.5
	oz = -(lo.y + hi.y) * 0.5
	index.clear()
	for i in cells.size():
		index[key(cells[i].q, cells[i].r)] = i
	fills = _mm(_hex_mesh(HS * 0.985, false), FILL_SHADER)
	rings = _mm(_hex_mesh(HS, true), RING_SHADER)
	props = Node3D.new()
	props.name = "Terrain"
	add_child(props)
	_terrain()
	refresh()


func bounds() -> Vector2:
	var m := Vector2.ZERO
	for h in cells:
		var p := hex_world(h.q, h.r)
		m = m.max(Vector2(absf(p.x), absf(p.z)))
	return m + Vector2(HS, HS)


func _mm(mesh: Mesh, code: String) -> MultiMeshInstance3D:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = mesh
	mm.instance_count = cells.size()
	for i in cells.size():
		mm.set_instance_transform(i, Transform3D(Basis(), hex_world(cells[i].q, cells[i].r, -0.4)))
	var mi := MultiMeshInstance3D.new()
	mi.multimesh = mm
	var sh := Shader.new()
	sh.code = code
	var m := ShaderMaterial.new()
	m.shader = sh
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)
	return mi


# a pointy-top hexagon in the xz plane: a filled disc, or a thin ring (the outline)
func _hex_mesh(rad: float, ring: bool) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var pts: Array = []
	for i in 6:
		var an := deg_to_rad(60.0 * i + 30.0)
		pts.append(Vector2(cos(an), sin(an)))
	if ring:
		var w := 0.35
		for i in 6:
			var a: Vector2 = pts[i]
			var b: Vector2 = pts[(i + 1) % 6]
			var a0 := Vector3(a.x * rad, 0, a.y * rad)
			var b0 := Vector3(b.x * rad, 0, b.y * rad)
			var a1 := Vector3(a.x * (rad - w), 0, a.y * (rad - w))
			var b1 := Vector3(b.x * (rad - w), 0, b.y * (rad - w))
			for v in [a0, b0, b1, a0, b1, a1]:
				st.add_vertex(v)
	else:
		for i in 6:
			var a: Vector2 = pts[i]
			var b: Vector2 = pts[(i + 1) % 6]
			for v in [Vector3.ZERO, Vector3(a.x * rad, 0, a.y * rad), Vector3(b.x * rad, 0, b.y * rad)]:
				st.add_vertex(v)
	return st.commit()


const ZONE_TINT := {"neb": Color(0.69, 0.49, 1.0, 0.16), "debris": Color(0.83, 0.75, 0.53, 0.12), "storm": Color(1.0, 0.91, 0.4, 0.13)}
const BASE_FILL := Color(0.04, 0.06, 0.09, 0.18)
const BASE_RING := Color(0.45, 0.65, 1.0, 0.16)


func refresh() -> void:
	var fm := fills.multimesh
	var rm := rings.multimesh
	for i in cells.size():
		var k := key(cells[i].q, cells[i].r)
		var c: Color = overlay.get(k, base_fill.get(k, BASE_FILL))
		fm.set_instance_color(i, c)
		var rc: Color = ring_over.get(k, BASE_RING)
		if k == hover_key:
			rc = Color(1.0, 0.82, 0.4, 0.9)
		rm.set_instance_color(i, rc)


func set_overlay(o: Dictionary, rings_o := {}) -> void:
	overlay = o
	ring_over = rings_o
	refresh()


func set_hover(q: int, r: int) -> void:
	var k := key(q, r) if index.has(key(q, r)) else ""
	if k != hover_key:
		hover_key = k
		refresh()


func on_board(q: int, r: int) -> bool:
	return index.has(key(q, r))


# ---------------------------------------------------------------- terrain props

func _rock_lib() -> Array:
	var man = JSON.parse_string(FileAccess.get_file_as_string("res://gen/manifest.json")) if FileAccess.file_exists("res://gen/manifest.json") else null
	var set_name := "RST"
	var biome = R.B.get("biome")
	if biome is Dictionary and HT.ROCK_SET.has(biome.get("rock", "")):
		set_name = HT.ROCK_SET[biome["rock"]]
	var out: Array = []
	if man is Dictionary:
		for code in man["rocks"]:
			if man["rocks"][code]["set"] == set_name:
				out.append(load(man["rocks"][code]["res"]))
	return out


func _terrain() -> void:
	base_fill.clear()
	rock_meshes = _rock_lib()
	var rng := RandomNumberGenerator.new()
	rng.seed = int(R.B.get("seed", 1))
	var T: Dictionary = R.B["terrain"]
	for k in T:
		var typ: String = T[k]
		var qr: PackedStringArray = k.split(",")
		var q := int(qr[0])
		var r := int(qr[1])
		var c := hex_world(q, r)
		if ZONE_TINT.has(typ):
			base_fill[k] = ZONE_TINT[typ]
		match typ:
			"rock":
				_rocks(c, rng, 3 + rng.randi() % 3, 2.5, 6.5)
			"hulk":
				_rocks(c, rng, 2, 1.5, 3.0)
				_hulk(c, rng)
			"debris":
				_rocks(c, rng, 5, 0.5, 1.4)
			"station":
				_station(c, rng)
	_planet()


func _rocks(c: Vector3, rng: RandomNumberGenerator, n: int, s0: float, s1: float) -> void:
	if rock_meshes.is_empty():
		return
	for i in n:
		var mi := MeshInstance3D.new()
		mi.mesh = rock_meshes[rng.randi() % rock_meshes.size()]
		var s := rng.randf_range(s0, s1)
		var off := Vector3(rng.randf_range(-5.5, 5.5), rng.randf_range(-2.5, 2.5), rng.randf_range(-5.5, 5.5))
		mi.transform = Transform3D(Basis.from_euler(Vector3(rng.randf() * TAU, rng.randf() * TAU, rng.randf() * TAU)).scaled(Vector3.ONE * s), c + off)
		props.add_child(mi)


func _hulk(c: Vector3, rng: RandomNumberGenerator) -> void:
	var codes := ["H8_23", "V15_37", "C14s_23", "D20_23"]
	var code: String = codes[rng.randi() % codes.size()]
	var p := "res://gen/hulls/%s.res" % code
	if not ResourceLoader.exists(p):
		return
	var mi := MeshInstance3D.new()
	mi.mesh = load(p)
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.09, 0.08, 0.075)
	m.roughness = 0.85
	m.metallic = 0.3
	mi.material_override = m
	mi.transform = Transform3D(Basis.from_euler(Vector3(rng.randf_range(-0.5, 0.5), rng.randf() * TAU, rng.randf_range(-0.6, 0.6))).scaled(Vector3(11, 11, -11)), c)
	props.add_child(mi)


func _station(c: Vector3, rng: RandomNumberGenerator) -> void:
	var p := "res://gen/hulls/O1_37.res"
	if not ResourceLoader.exists(p):
		return
	var mi := MeshInstance3D.new()
	mi.mesh = load(p)
	mi.transform = Transform3D(Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3(14, 14, -14)), c)
	props.add_child(mi)


func _planet() -> void:
	var meta = R.B.get("map")
	if not (meta is Dictionary) or not meta.has("planet"):
		return
	var pl = meta["planet"]
	if not (pl is Dictionary) or not pl.has("q"):
		return
	var rad: float = R.planetEdge(pl.get("R", 3)) if pl.has("R") else 40.0
	var sp := SphereMesh.new()
	sp.radius = rad
	sp.height = rad * 2.0
	sp.radial_segments = 96
	sp.rings = 48
	var mi := MeshInstance3D.new()
	mi.mesh = sp
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.33, 0.29, 0.27)
	m.roughness = 0.95
	mi.material_override = m
	mi.position = hex_world(pl.q, pl.r, -rad * 0.55)
	props.add_child(mi)
