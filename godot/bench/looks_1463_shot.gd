extends "res://bench/scene_gate.gd"
# Issue 1463 option sheets (RULEBOOK 9.10, options first): the real battle scene with the real ships, built the scene
# gate's way (scene_gate.gd _build: 20 hulls, every faction), once per option of one look, then the pictures for that
# look's sheet. Each picture is 1280x720 with its code name stamped top left. Options are the launch options of
# render/look.gd look_option (forced here through LOOK.opt_force, never saved).
#
#   godot --path godot --rendering-method forward_plus --resolution 1920x1080 res://bench/looks_1463_shot.tscn --
#         --sheet SG|PL|ER|AB --out DIR [--opts a,b,c or a+b+c]
#
#   SG  sun glints on hulls: a Sunward, an Eclipse and a Glasswright hull at camera 170 and 26, options a b c
#   PL  the board planet: a (R01 off, the stand-in), b (R01 on a rocky board world, main today), c (R01 on a barren one)
#   ER  Eclipse revive: the Eclipse cruiser dies, its wreck settles, it rises; frames at 0.2, 0.5 and 0.8 s at camera
#       170, and 0.5 s close (camera 60); options a b
#   AB  ability looks: focus, surge, ionpulse and phase at camera 170 and close (camera 60), options a b c

const SHEET_OPTS := {"SG": ["a", "b", "c"], "PL": ["a", "b", "c"], "ER": ["a", "b"], "AB": ["a", "b", "c"]}
const SG_SHIPS := [["sunward", "voidsworn", "Cruiser"], ["eclipse", "deathless", "Cruiser"], ["glasswright", "ithar", "Destroyer"]]
var sheet := "SG"
var stamp: Label
var stamp_layer: CanvasLayer
var saved: Array = []


func _run() -> void:
	sheet = str(args.get("sheet", "SG")).to_upper()
	# "+" also separates (a .bat argument splits at commas)
	var opts: Array = Array(str(args.get("opts", ",".join(SHEET_OPTS.get(sheet, ["a"])))).replace("+", ",").split(",", false))
	build_wait_usec = int(float(args.get("build-wait-s", 120)) * 1000000.0)
	stamp_layer = CanvasLayer.new()
	stamp_layer.layer = 120
	add_child(stamp_layer)
	stamp = Label.new()
	stamp.position = Vector2(24, 18)
	stamp.add_theme_font_size_override("font_size", 40)
	stamp.add_theme_color_override("font_color", Color(1, 1, 1))
	stamp.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	stamp.add_theme_constant_override("outline_size", 10)
	stamp_layer.add_child(stamp)
	for o in opts:
		var opt := str(o)
		var seed := 4207
		var mode := "opt_%s_%s" % [sheet, opt]
		if sheet == "PL":
			args["map"] = "planet"
			seed = 4209 if opt == "c" else 4205   # board look kind: seed % 5 (render/board.gd PLANET_LOOKS): 0 rocky, 4 barren
			mode = "opt_PL_%s" % ("a" if opt == "a" else "b")
		if not await _build(mode, seed) or PG.stop_if_any():
			PG.finish(1)
			return
		_apply("base")
		b.hud.visible = false
		for k in 60:
			await get_tree().process_frame
		match sheet:
			"SG": await _sg(opt)
			"PL": await _pl(opt)
			"ER": await _er(opt)
			"AB": await _ab(opt)
		b.queue_free()
		b = null
		for k in 5:
			await get_tree().process_frame
	var f := FileAccess.open(out.path_join("looks_1463_%s.json" % sheet), FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify({"sheet": sheet, "options": opts, "pictures": saved}, "  ") + "\n")
		f.close()
	print("[looks1463] DONE %s, %d pictures" % [sheet, saved.size()])
	PG.finish(0)


func _aim(p: Vector3, r: float) -> void:
	b.cam.t = Vector3(p.x, 0, p.z)
	b.cam.r = r
	b.cam.snap()


func _pic(code: String) -> void:
	stamp.text = code
	await get_tree().process_frame
	await _post()
	var img := get_viewport().get_texture().get_image()
	if img == null or img.is_empty():
		print("[looks1463] FAIL no image for " + code)
		return
	img.resize(1280, 720, Image.INTERPOLATE_LANCZOS)
	var path := out.path_join(code + ".png")
	var err = preload("res://tools/picture_provenance.gd").save_png(img, path, preload("res://tools/picture_provenance.gd").capture_stage())
	if err != OK:
		print("[looks1463] FAIL could not save %s (%s)" % [code, str(err)])
		return
	saved.append(code)
	print("[looks1463] saved " + code)


func _unit(fac: String, cls: String) -> Dictionary:
	for u in b.V.get("units", []):
		if str(u.get("fac", "")) == fac and str(u.get("cls", "")) == cls:
			return u
	for u in b.V.get("units", []):
		if str(u.get("fac", "")) == fac:
			return u
	return {}


func _pos(id: String) -> Vector3:
	var sv = b.views.get(id)
	return sv.global_position if sv != null and is_instance_valid(sv) else Vector3.ZERO


func _sec(s: float) -> void:
	await get_tree().create_timer(s).timeout


func _sg(opt: String) -> void:
	for row in SG_SHIPS:
		var u := _unit(row[1], row[2])
		if u.is_empty():
			print("[looks1463] no %s ship" % row[0])
			continue
		for r in [170.0, 26.0]:
			_aim(_pos(str(u["id"])), r)
			await _sec(0.5)
			await _pic("SG-%s_%s_c%d" % [opt.to_upper(), row[0], int(r)])


func _pl(opt: String) -> void:
	var pn = b.board.planet_node
	if pn == null or not is_instance_valid(pn):
		print("[looks1463] FAIL no board planet")
		return
	print("[looks1463] planet %s look %s" % [str(pn.get_meta("planet_code", "stand-in")), str(pn.get_meta("planet_look", "?"))])
	var sp: SphereMesh = pn.mesh
	var p: Vector3 = pn.global_position
	_aim(p + Vector3(sp.radius * 0.6, 0, sp.radius * 0.6), 170.0)
	await _sec(0.6)
	await _pic("PL-%s_c170" % opt.to_upper())
	_aim(p + Vector3(sp.radius * 0.5, 0, sp.radius * 0.5), 70.0)
	await _sec(0.6)
	await _pic("PL-%s_close" % opt.to_upper())


func _er(opt: String) -> void:
	var id := _eclipse_cruiser()
	if id == "":
		print("[looks1463] FAIL no Eclipse cruiser")
		return
	var at := _pos(id)
	for pass_i in 2:
		var r := 170.0 if pass_i == 0 else 60.0
		_aim(at, r)
		b.gfx.death(id, "big")
		await _sec(7.0)   # the wreck breaks, burns and settles in its hex (fx_death LEASH_SETTLED 5.5 s)
		if pass_i == 0:
			await _pic("ER-%s_c170_wreck" % opt.to_upper())
		_revive(id)
		var t := 0.0
		for at_s in ([0.2, 0.5, 0.8, 1.4] if pass_i == 0 else [0.5]):
			await _sec(float(at_s) - t)
			t = float(at_s)
			await _pic("ER-%s_%s_%03dms" % [opt.to_upper(), "c170" if pass_i == 0 else "close", int(at_s * 1000.0)])
		await _sec(1.5)


func _ab(opt: String) -> void:
	for pick in _ability_ships():
		var id := str(pick[0])
		var ab := str(pick[1])
		for r in [170.0, 60.0]:
			_aim(_pos(id), r)
			await _sec(1.2)
			b.gfx.ability(id, ab)
			await _sec(0.45)
			await _pic("AB-%s_%s_%s" % [opt.to_upper(), ab, "c170" if r == 170.0 else "close"])
