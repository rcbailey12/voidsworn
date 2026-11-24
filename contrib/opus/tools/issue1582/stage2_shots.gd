extends SceneTree
# Issue 1582 cloud direction shots (not the PC done-when): stand-in hulls (the one ship glb in the repo, C19_51, for every
# slot) at their altitude bands with drop-lines on a hex plane, the battle camera at 170 and a low orbit, a strike craft
# dive strip, and the six factions' manoeuvring jets. Run under xvfb with lavapipe (Forward+):
#   VK_ICD_FILENAMES=/opt/lavapipe/lvp_icd.json xvfb-run -a -s "-screen 0 1280x720x24" godot --rendering-driver vulkan \
#     --path godot --script <this file> -- <out dir>
const SV := preload("res://render/ship_view.gd")
const ALT := preload("res://render/altitude_band.gd")
const FX := preload("res://fx/fx.gd")
const FXW := preload("res://fx/fx_weapons.gd")
const WING := preload("res://render/squadron_wing.gd")
const HS := 10.0
var out := "/tmp/stage2"
var world: Node3D
var cam: Camera3D
var fx
var real := false      # --real on the PC: the game's own installed hulls (godot/gen), no stand-in, no grey paint
var clips := false     # --clips: also save an orbit and a dive frame sequence (30 fps under --fixed-fps 30)


func _init() -> void:
	var a := OS.get_cmdline_user_args()
	for x in a:
		if x == "--real":
			real = true
		elif x == "--clips":
			clips = true
		elif not x.begins_with("--"):
			out = x
	DirAccess.make_dir_recursive_absolute(out)
	process_frame.connect(_run, CONNECT_ONE_SHOT)


func hexw(q: int, r: int) -> Vector3:
	return Vector3(HS * sqrt(3.0) * (q + r * 0.5), 0, HS * 1.5 * r)


func _grid() -> void:
	var im := ImmediateMesh.new()
	im.surface_begin(Mesh.PRIMITIVE_LINES)
	for q in range(-6, 7):
		for r in range(-4, 5):
			var c := hexw(q, r)
			for i in 6:
				var a0 := deg_to_rad(60.0 * i + 30.0)
				var a1 := deg_to_rad(60.0 * (i + 1) + 30.0)
				im.surface_add_vertex(c + Vector3(cos(a0), 0, sin(a0)) * HS * 0.97)
				im.surface_add_vertex(c + Vector3(cos(a1), 0, sin(a1)) * HS * 0.97)
	im.surface_end()
	var mi := MeshInstance3D.new()
	mi.mesh = im
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = Color(0.35, 0.42, 0.55, 0.5)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mi.material_override = m
	world.add_child(mi)


func _hull_scene() -> String:
	var doc := GLTFDocument.new()
	var st := GLTFState.new()
	var glb := ProjectSettings.globalize_path("res://").path_join("../assets/ships/C19_51/C19_51_v15_shell.glb")
	if doc.append_from_file(glb, st) != OK:
		push_error("no glb " + glb)
		return ""
	var n := doc.generate_scene(st)
	for c in n.get_children():
		_own(c, n)
	var ps := PackedScene.new()
	ps.pack(n)
	var p := "user://stage2_hull.tscn"
	ResourceSaver.save(ps, p)
	return p


func _own(c: Node, o: Node) -> void:
	c.owner = o
	for k in c.get_children():
		_own(k, o)


func _label(text: String) -> void:
	var cl := CanvasLayer.new()
	world.add_child(cl)
	var l := Label.new()
	l.text = text
	l.position = Vector2(16, 12)
	l.add_theme_font_size_override("font_size", 20)
	l.add_theme_color_override("font_color", Color(1, 0.75, 0.5))
	cl.add_child(l)
	cl.name = "label"


func _clear_label() -> void:
	var l = world.get_node_or_null("label")
	if l != null:
		l.free()


func _snap(name: String, text: String) -> void:
	_clear_label()
	_label(text)
	for i in 4:
		await process_frame
	await RenderingServer.frame_post_draw
	var img := root.get_viewport().get_texture().get_image()
	img.save_jpg(out.path_join(name + ".jpg"), 0.88)
	print("[shot] ", name)


func _cam(target: Vector3, r: float, polar: float, az := -PI / 2.0) -> void:
	# the rig's frame: polar angle from straight down (camera_rig b), azimuth a
	var off := Vector3(cos(az) * sin(polar), cos(polar), -sin(az) * sin(polar)) * r
	cam.global_position = target + off
	cam.look_at(target)


var _grey: StandardMaterial3D


# the stand-in glb has no textures in the cloud: one plain hull grey per faction tint so nothing blows out
func _paint(sv) -> void:
	if real:
		return
	if _grey == null:
		_grey = StandardMaterial3D.new()
		_grey.albedo_color = Color(0.42, 0.43, 0.45)
		_grey.metallic = 0.5
		_grey.roughness = 0.55
	for m in sv.meshes:
		(m as MeshInstance3D).material_override = _grey
		(m as MeshInstance3D).material_overlay = null


# one full turn round the board's middle at the battle camera's height, 8 s
func _orbit_clip() -> void:
	DirAccess.make_dir_recursive_absolute(out.path_join("clip_orbit"))
	_clear_label()
	for f in 240:
		_cam(Vector3.ZERO, 170.0, 0.98, -PI / 2.0 + TAU * f / 240.0)
		await RenderingServer.frame_post_draw
		root.get_viewport().get_texture().get_image().save_jpg(out.path_join("clip_orbit/%05d.jpg" % f), 0.85)
	print("[clip] orbit frames 240")


# issue 1582 (Artoo on PR 1874): every lineup slot's asked class, drawn class and hull source, so a placeholder or a
# swapped class is never passed off as an installed hull of the asked class
var slots: Array = []


func _band_mates(cls: String) -> Array:
	var same: Array = []
	if cls in ALT.PLANE:
		same = ALT.PLANE.duplicate()
		same.erase("Station")
	elif cls in ALT.LINE_CLS:
		same = ALT.LINE_CLS.duplicate()
	same.erase(cls)
	return same


func _slot(id: String, fac: String, asked: String, sv) -> void:
	var src := str(sv.hull_source)
	var drawn := str(sv.u.get("cls", asked))
	var state := "MISSING (placeholder)" if src == "" else ("swapped, same band" if drawn != asked else "ok")
	slots.append("%s %s asked %s drew %s source %s res %s: %s" % [id, fac, asked, drawn, src if src != "" else "-", str(sv.hull_res), state])


func _partial() -> bool:
	for l in slots:
		if not str(l).ends_with(": ok"):
			return true
	return false


func _write_slots() -> void:
	var f := FileAccess.open(out.path_join("slots.txt"), FileAccess.WRITE)
	for l in slots:
		f.store_line(str(l))
		print("[slot] ", l)
	f.store_line("PARTIAL" if _partial() else "ALL INSTALLED")
	f.close()


func _run() -> void:
	root.size = Vector2i(1280, 720)
	world = Node3D.new()
	root.add_child(world)
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.02, 0.025, 0.04)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.35, 0.38, 0.45)
	e.glow_enabled = false
	e.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.environment = e
	world.add_child(env)
	var key := DirectionalLight3D.new()
	key.rotation = Vector3(-0.9, 0.6, 0)
	key.light_energy = 1.6
	world.add_child(key)
	cam = Camera3D.new()
	cam.fov = 45
	cam.far = 4000
	world.add_child(cam)
	cam.current = true
	_grid()
	var ships := {}
	if not real:
		var hp := _hull_scene()
		var man := {"ships": {}}
		man.ships["STAND"] = {"res": hp}
		SV._manifest = man
	var tag: String = "PC installed hulls" if real else "cloud stand-in hull (C19_51 on every slot)"
	fx = FX.new()
	world.add_child(fx)
	fx.setup({"quality": "high", "shake": 0.0, "camera": cam})
	var lineup := [["Dreadnought", "hegemony", -3, 0, true], ["Cruiser", "hegemony", -1, -1, true], ["Destroyer", "voidsworn", 1, -1, true],
		["Frigate", "corsair", 2, 0, true], ["Frigate", "ithar", -2, 2, false], ["Cruiser", "chorus", 0, 1, false],
		["Destroyer", "deathless", 2, 1, false], ["Battleship", "deathless", 3, -2, false], ["Frigate", "hegemony", -4, 2, true]]
	var i := 0
	for row in lineup:
		var sv := SV.new()
		world.add_child(sv)
		var id := "s%d_%s" % [i, row[0]]
		var u := {"id": id, "fac": row[1], "cls": row[0], "facing": 3 if row[4] else 0}
		if not real:
			u["code"] = "STAND"
		sv.setup(u, hexw(row[2], row[3]))
		# RUN5: a class with no installed hull for that faction drew the white placeholder block. On the PC, try the other
		# classes of the same altitude band only (Artoo on PR 1874: a cruiser in a frigate's slot would prove the line
		# band, not the escort band); each slot's asked class, drawn class and source go to slots.txt, and a still with
		# a missing or swapped hull says PARTIAL in its caption
		if real and str(sv.hull_source) == "":
			for c2 in _band_mates(str(row[0])):
				sv.free()
				sv = SV.new()
				world.add_child(sv)
				u["cls"] = c2
				sv.setup(u, hexw(row[2], row[3]))
				if str(sv.hull_source) != "":
					break
			if str(sv.hull_source) == "":   # none installed: keep the asked class (and its band), reported MISSING
				sv.free()
				sv = SV.new()
				world.add_child(sv)
				u["cls"] = row[0]
				sv.setup(u, hexw(row[2], row[3]))
		_slot(id, str(row[1]), str(row[0]), sv)
		sv.set_marker(row[4])
		sv.set_band(ALT.height(u))
		_paint(sv)
		fx.add_ship(id, sv, {"faction": row[1], "cls": u["cls"], "meshes": sv.meshes})
		_paint(sv)
		ships[id] = sv
		print("%s %s band %.2f" % [id, row[1], sv.band_y])
		i += 1
	if real:
		_write_slots()
		if _partial():
			tag += " · PARTIAL (slots.txt)"
	var wing := SV.new()
	world.add_child(wing)
	var wu := {"id": "w1", "fac": "hegemony", "cls": "Squadron", "squadron": true, "facing": 0}
	wing.setup(wu, hexw(0, -2))
	wing.set_band(ALT.height(wu))
	for k in 40:
		await process_frame
	_cam(Vector3(0, 0, 0), 170.0, 0.98)
	await _snap("ST2_a_camera170", "1582 stage 2 · %s · camera 170 · bands + drop-lines" % tag)
	_cam(Vector3(0, 0, 0), 150.0, 1.38, -PI / 2.0 + 0.5)
	await _snap("ST2_b_low_orbit", "1582 stage 2 · %s · low orbit: capitals on the plane, escorts above and below" % tag)
	if clips:
		await _orbit_clip()
	# hovered / selected line
	var any_id: String = str(ships.keys()[3])
	ships[any_id].set_selected(true)
	_cam(ships[any_id].position, 80.0, 0.98)
	for k in 20:
		await process_frame
	await _snap("ST2_c_selected_dropline", "1582 stage 2 · %s · selected frigate: brighter drop-line to its hex" % tag)
	ships[any_id].set_selected(false)
	# the dive strip: one craft at several moments of an attack pass onto a low target
	for c in world.get_children():
		if c is SV and c != wing:
			c.visible = false
	var target: SV = ships.values()[6]
	target.visible = true
	var from := wing.visual_position()
	var to := target.visual_position()
	fx.dstate["craft_runs"] = []
	FXW._strafe(fx, "fighter", from, to, fx.now, Color(0.7, 0.85, 1.0), {"engine": Color(0.45, 0.72, 1.0)}, 1.0, 1.0, 1, "hegemony")
	var run: Dictionary = fx.dstate["craft_runs"][0]
	for rr in fx.dstate["craft_runs"]:
		if rr != run:
			(rr["node"] as Node).queue_free()
	fx.dstate["craft_runs"] = []
	var marks := Node3D.new()
	world.add_child(marks)
	for k in 9:
		var u2 := float(k) / 8.0
		var n := WING.new()
		marks.add_child(n)
		n.setup("hegemony", "fighter", 2.4, 1, 1.0)
		n.set_process(false)
		n.position = FXW._dive_pos(run["a"], run["b"], run["dive"], u2)
		var ah: Vector3 = FXW._dive_pos(run["a"], run["b"], run["dive"], minf(u2 + 0.02, 1.0)) - FXW._dive_pos(run["a"], run["b"], run["dive"], maxf(u2 - 0.02, 0.0))
		var fl := Vector3(ah.x, 0, ah.z).normalized()
		n.basis = Basis(Vector3.UP, atan2(-fl.z, fl.x)) * Basis(Vector3(0, 0, 1), asin(clampf(ah.normalized().y, -1, 1)))
		n.step(0.0)
	if clips:
		# the real pass on the effect clock, side on: frames until the craft are released
		fx.dstate["craft_runs"] = []
		FXW._strafe(fx, "fighter", from, to, fx.now, Color(0.7, 0.85, 1.0), {"engine": Color(0.45, 0.72, 1.0)}, 1.0, 1.0, 1, "hegemony")
		var d2: Vector3 = to - from
		# RUN5: the frames kept the last still's label and the craft were specks at 75; close on the target, side on
		_clear_label()
		_cam(to + Vector3(0, 4, 0), 50.0, 1.45, atan2(-d2.z, d2.x) - PI / 2.0)
		DirAccess.make_dir_recursive_absolute(out.path_join("clip_dive"))
		# the effect clock steps exactly 1/30 s per saved frame, so the clip plays at game speed on any machine (RUN5's
		# frames ran on the wall clock and caught only part of the pass)
		fx.manual = true
		var f := 0
		while not fx.dstate.get("craft_runs", []).is_empty() and f < 300:
			fx.step(1.0 / 30.0)
			await RenderingServer.frame_post_draw
			root.get_viewport().get_texture().get_image().save_jpg(out.path_join("clip_dive/%05d.jpg" % f), 0.85)
			f += 1
		fx.manual = false
		print("[clip] dive frames ", f)
	(run["node"] as Node).queue_free()
	var im := ImmediateMesh.new()
	im.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
	for k in 81:
		im.surface_add_vertex(FXW._dive_pos(run["a"], run["b"], run["dive"], float(k) / 80.0))
	im.surface_end()
	var pl := MeshInstance3D.new()
	pl.mesh = im
	var pm := StandardMaterial3D.new()
	pm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	pm.albedo_color = Color(1, 0.6, 0.3)
	pl.material_override = pm
	marks.add_child(pl)
	var mid: Vector3 = (run["a"] + run["b"]) * 0.5
	var dirv: Vector3 = (run["b"] - run["a"])
	var az := atan2(-dirv.z, dirv.x) - PI / 2.0
	_cam(mid + Vector3(0, 3, 0), 75.0, 1.5, az)
	await _snap("ST2_d_wing_dive_strip", "1582 stage 2 · strike craft attack pass, 9 moments: patrol height, dive onto the target, climb out")
	marks.queue_free()
	# six faction jets: each stand-in fires a sidestep pair; frame 0.15 s later
	var facs := ["voidsworn", "hegemony", "corsair", "ithar", "chorus", "deathless"]
	var row6: Array = []
	for j in 6:
		var sv := SV.new()
		world.add_child(sv)
		var id: String = "f_" + str(facs[j])
		var fu := {"id": id, "fac": facs[j], "cls": "Destroyer", "facing": 0}
		if not real:
			fu["code"] = "STAND"
		sv.setup(fu, Vector3(-75 + j * 30, 0, 60))
		_paint(sv)
		if real:
			_slot(id, str(facs[j]), "Destroyer", sv)
		fx.add_ship(id, sv, {"faction": facs[j], "cls": "Destroyer", "meshes": sv.meshes})
		_paint(sv)
		row6.append(sv)
	for k in 10:
		await process_frame
	# one close frame per faction, a little after a one-hex slide starts (its side jets push it off), then one sheet
	var tiles: Array = []
	for j in 6:
		var sv = row6[j]
		for o in row6:
			o.visible = o == sv
		_cam(sv.position + Vector3(0, 1, 0), 42.0, 1.05, -PI / 2.0 + 0.35)
		sv.play_glide([{"kind": "run", "p": sv.position + Vector3(0, 0, -17.3)}], 0.9, {"mass": 0.6, "thrusters": true})
		for k in 7:
			await process_frame
		_clear_label()
		await RenderingServer.frame_post_draw
		var img := root.get_viewport().get_texture().get_image()
		img.resize(640, 360, Image.INTERPOLATE_LANCZOS)
		tiles.append(img)
		for k in 40:
			await process_frame
	var sheet := Image.create(1280, 1080, false, tiles[0].get_format())
	for j in 6:
		sheet.blit_rect(tiles[j], Rect2i(0, 0, 640, 360), Vector2i((j % 2) * 640, (j / 2) * 360))
	sheet.resize(960, 810, Image.INTERPOLATE_LANCZOS)
	sheet.save_jpg(out.path_join("ST2_e_faction_jets.jpg"), 0.88)
	print("[shot] ST2_e_faction_jets (rows: Sunward, Directorate / Hullbreakers, Glasswrights / Chorus, Eclipse)")
	if real:
		_write_slots()   # again, with the jets row
	quit(0)
