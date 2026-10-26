extends Node3D
# Hull orientation check: every hull the game uses, flat on the board at facing 0 (bow toward +x, screen right), in
# rows by faction, with the battle's mirror and scale. Saves a top-down, a side and a three-quarter still, then quits.
#   godot --path godot res://scenes/battle/lineup.tscn -- --out <folder>

const HT := preload("res://render/hull_table.gd")
const ShipView := preload("res://render/ship_view.gd")
const Board := preload("res://render/board.gd")

var out := ""


func _ready() -> void:
	var a := OS.get_cmdline_user_args()
	for i in a.size():
		if a[i] == "--out" and i + 1 < a.size():
			out = a[i + 1]
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.05, 0.06, 0.08)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(1, 1, 1)
	env.ambient_light_energy = 0.5
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.tonemap_white = 8.0
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	var key := DirectionalLight3D.new()
	key.transform = Transform3D(Basis.looking_at(Vector3(-0.45, -0.7, -0.55).normalized(), Vector3.UP), Vector3.ZERO)
	key.light_energy = 2.0
	key.shadow_enabled = true
	add_child(key)
	var fill := DirectionalLight3D.new()
	fill.transform = Transform3D(Basis.looking_at(Vector3(0.6, -0.2, 0.75).normalized(), Vector3.UP), Vector3.ZERO)
	fill.light_color = Color(0.55, 0.65, 0.85)
	fill.light_energy = 0.5
	add_child(fill)
	# rows by faction prefix, ships spaced by their length; each row is its own node so the side view can stack the rows
	var rows := {}
	for k in HT.AI_HULLS:
		var fac: String = k.split("|")[0]
		var cls: String = k.split("|")[1]
		if not rows.has(fac):
			rows[fac] = []
		rows[fac].append([HT.AI_HULLS[k], fac, cls])
	var row_nodes: Array = []
	var row_h: Array = []
	var maxx := 0.0
	for fac in rows:
		var rn := Node3D.new()
		add_child(rn)
		row_nodes.append(rn)
		var x := 0.0
		var rowL := 0.0
		for e in rows[fac]:
			var cls: String = e[2]
			var L: float = HT.CLS_LEN.get(cls, 3.0) * HT.SHIP_K
			if fac == "obj":
				L = 46.0
			var sv = ShipView.new()
			rn.add_child(sv)
			var f2: String = fac if HT.FAC3D.has(fac) else "hegemony"
			sv.setup({"id": e[0], "fac": f2, "cls": cls, "facing": 0, "code": e[0], "L": L}, Vector3(x + L * 0.5, 0, 0), true)
			sv.set_process(false)
			var lbl := Label3D.new()
			lbl.text = "%s %s" % [e[0], cls]
			lbl.font_size = 48
			lbl.pixel_size = 0.04
			lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
			lbl.position = Vector3(x + L * 0.5, -maxf(5.0, L * 0.25), maxf(6.0, L * 0.35))
			lbl.modulate = Color(0.9, 0.85, 0.7)
			lbl.no_depth_test = true
			rn.add_child(lbl)
			# a thin red bar along +x below each ship, its right end marked: every bow must point at the marked end
			var ar := MeshInstance3D.new()
			var bm := BoxMesh.new()
			bm.size = Vector3(L * 1.05, 0.3, 0.3)
			ar.mesh = bm
			var am := StandardMaterial3D.new()
			am.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			am.albedo_color = Color(0.9, 0.2, 0.15)
			ar.material_override = am
			ar.position = Vector3(x + L * 0.5, -L * 0.22 - 1.0, 0)
			rn.add_child(ar)
			var tip := MeshInstance3D.new()
			var tb := BoxMesh.new()
			tb.size = Vector3(1.2, 1.2, 1.2)
			tip.mesh = tb
			tip.material_override = am
			tip.position = Vector3(x + L * 1.05, -L * 0.22 - 1.0, 0)
			rn.add_child(tip)
			x += L + 16.0
			rowL = maxf(rowL, L)
		maxx = maxf(maxx, x)
		row_h.append(rowL)
	var cam := Camera3D.new()
	add_child(cam)
	cam.current = true
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.far = 5000
	var cx := maxx * 0.5
	if out == "":
		return
	DirAccess.make_dir_recursive_absolute(out)
	for view in ["top", "side", "threequarter"]:
		var off := 0.0
		for i in row_nodes.size():
			var rn: Node3D = row_nodes[i]
			var gap := maxf(row_h[i] * 0.55, 20.0) + 14.0
			if view == "top":
				rn.position = Vector3(0, 0, off)
			else:
				rn.position = Vector3(0, -off, 0)
			off += gap
		cam.size = maxf(maxx * 1.05 * 9.0 / 16.0, off * 1.05)
		var mid := off * 0.5
		if view == "top":
			cam.look_at_from_position(Vector3(cx, 800, mid + 0.01), Vector3(cx, 0, mid), Vector3(0, 0, -1))
		elif view == "side":
			cam.look_at_from_position(Vector3(cx, -mid, 900), Vector3(cx, -mid, 0), Vector3.UP)
		else:
			cam.look_at_from_position(Vector3(cx, -mid + 500, 700), Vector3(cx, -mid, 0), Vector3.UP)
		for i in 8:
			await get_tree().process_frame
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(out.path_join("lineup_%s.png" % view))
		print("[lineup] ", out.path_join("lineup_%s.png" % view))
	get_tree().quit()
