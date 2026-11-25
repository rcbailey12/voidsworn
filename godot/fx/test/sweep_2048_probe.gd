extends SceneTree
## Issue 2048 (Build G): look bench capture probe for before/after rows at cameras 170 and 26, per faction where it differs.
## Runs identically on origin/main (PROBE_TAG=before) and neon/issue-2048 (PROBE_TAG=after), then composes 1280x720
## before/after rows (PROBE_COMPOSE="<before_dir>;<after_dir>"), each picture stamped with its code name (<= 720 px tall).
##
## Items covered:
##   1. Shield hits (c170 + c26, per shielded faction: voidsworn, hegemony, corsair, ithar)
##      and shield collapse edge wave (c170 + c26, per shielded faction)
##   2. Small death bow vent (c170 + c26, per faction: voidsworn, hegemony, corsair, ithar, deathless)
##   3. Terrain polish: Dead Star INFALL motes, terrain_scorch.gd decals, DUST_SHADER (c170 + c26)
##   4. Layered fx_idle.gd motion pieces (VS_IDLE_MOTION=1 during capture only; c170 + c26, all 6 factions)
##
## Env:
##   PROBE_OUT      output folder (required)
##   PROBE_TAG      before | after (default after)
##   PROBE_COMPOSE  "<before_dir>;<after_dir>" to stitch 1280x720 before/after sheets without rendering
##   PROBE_ONLY     optional comma filter: shield,vent,terrain,idle (default all)
##   PROBE_BLOCKS   1 allows placeholder hulls (cloud syntax test only; never for Ryan)
## Prints SWEEP2048_DONE (or SWEEP2048_FAILED) last.

const FX := preload("res://fx/fx.gd")
const SV := preload("res://render/ship_view.gd")
const LOOK := preload("res://render/look.gd")
const CAMRIG := preload("res://render/camera_rig.gd")
const PG := preload("res://render/placeholder_guard.gd")
const PP := preload("res://tools/picture_provenance.gd")
const DEATH := preload("res://fx/fx_death.gd")
const SCORCH := preload("res://fx/terrain_scorch.gd")
const IDLE := preload("res://fx/fx_idle.gd")
const WORLD_SCRIPT := preload("res://world/world.gd")

const SHIELD_FACS := ["voidsworn", "hegemony", "corsair", "ithar"]
const VENT_FACS := ["voidsworn", "hegemony", "corsair", "ithar", "deathless"]
const ALL_FACS := ["hegemony", "voidsworn", "corsair", "ithar", "deathless", "chorus"]
const CAMS := [170, 26]
const HEX_S := 10.0
const HEX_W := 17.320508
const FRAME_SIZE := Vector2i(1280, 720)
const CELL_SIZE := Vector2i(640, 360)

var out := ""
var tag := "after"
var allow_blocks := false
var failed := false
var vp: SubViewport
var world: Node3D
var env: Environment
var key_light: DirectionalLight3D
var fill_light: DirectionalLight3D
var cam
var fx
var banner: Label
var manifest: Array = []


func _init() -> void:
	process_frame.connect(_run, CONNECT_ONE_SHOT)


func _env(k: String, d: String) -> String:
	var v := OS.get_environment(k)
	return v if not v.is_empty() else d


func _hex(q: int, r: int) -> Vector3:
	return Vector3(HEX_W * (q + r / 2.0), 0.0, 1.5 * HEX_S * r)


func _want(group: String) -> bool:
	var only := _env("PROBE_ONLY", "")
	if only.is_empty():
		return true
	return group in only.split(",")


func _run() -> void:
	out = _env("PROBE_OUT", "")
	if out.is_empty():
		push_error("SWEEP2048 PROBE_OUT is not set")
		print("SWEEP2048_FAILED")
		quit(2)
		return
	DirAccess.make_dir_recursive_absolute(out)
	var compose := _env("PROBE_COMPOSE", "")
	if not compose.is_empty():
		_compose_all(compose)
		print("SWEEP2048_" + ("FAILED" if failed else "DONE"))
		quit(1 if failed else 0)
		return

	tag = _env("PROBE_TAG", "after")
	allow_blocks = _env("PROBE_BLOCKS", "") == "1"
	var dir := out.path_join(tag)
	DirAccess.make_dir_recursive_absolute(dir)
	Engine.max_fps = 0
	AudioServer.set_bus_mute(0, true)
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	_setup_stage()

	if _want("shield"):
		await _capture_shields(dir)
	if _want("vent") and not failed:
		await _capture_small_vents(dir)
	if _want("terrain") and not failed:
		await _capture_terrain(dir)
	if _want("idle") and not failed:
		await _capture_idle(dir)

	var fp := FileAccess.open(dir.path_join("manifest.json"), FileAccess.WRITE)
	if fp == null:
		failed = true
		push_error("SWEEP2048 could not write manifest.json")
	else:
		fp.store_string(JSON.stringify({"tag": tag, "rows": manifest}, "  "))
		fp.close()

	OS.unset_environment("VS_IDLE_MOTION")
	_clear_fx()
	vp.queue_free()
	await process_frame
	SV.clear_static()
	FX.clear_static()
	SCORCH.clear_static()
	print("SWEEP2048_" + ("FAILED" if failed else "DONE"))
	if allow_blocks:
		quit(1 if failed else 0)
	else:
		PG.finish(1 if failed else 0)


func _setup_stage() -> void:
	vp = SubViewport.new()
	vp.size = FRAME_SIZE
	vp.msaa_3d = Viewport.MSAA_4X
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(vp)
	world = Node3D.new()
	vp.add_child(world)
	env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.012, 0.016, 0.026)
	var we := WorldEnvironment.new()
	we.environment = env
	world.add_child(we)
	key_light = DirectionalLight3D.new()
	world.add_child(key_light)
	fill_light = DirectionalLight3D.new()
	world.add_child(fill_light)
	LOOK.apply(env, key_light, fill_light, {"quality": "max"})
	key_light.directional_shadow_max_distance = 600.0
	cam = CAMRIG.new()
	world.add_child(cam)
	cam.input_enabled = false
	cam.current = true
	banner = Label.new()
	banner.position = Vector2(12, 10)
	banner.add_theme_font_size_override("font_size", 22)
	banner.add_theme_color_override("font_color", Color(0.97, 0.96, 0.90))
	banner.add_theme_color_override("font_outline_color", Color(0.02, 0.02, 0.04, 0.95))
	banner.add_theme_constant_override("outline_size", 5)
	vp.add_child(banner)


func _clear_fx() -> void:
	if fx != null and is_instance_valid(fx):
		fx.release()
		fx.queue_free()
		fx = null
	for child in world.get_children():
		if child.has_meta("probe_temp"):
			child.queue_free()


func _fresh_fx(seed_v: int) -> void:
	_clear_fx()
	await process_frame
	fx = FX.new()
	fx.set_meta("probe_temp", true)
	world.add_child(fx)
	fx.manual = true
	fx.setup({"camera": cam, "quality": "max", "reduce_flashing": false, "shake": 0.0, "unit": 1.0, "seed": seed_v})


func _spawn_ship(sid: String, fac: String, cls: String, size_v: float, shielded: bool, pos := Vector3.ZERO):
	var sv := SV.new()
	sv.set_meta("probe_temp", true)
	world.add_child(sv)
	sv.setup({"id": sid, "fac": fac, "cls": cls, "facing": 0, "hp": 100, "maxHp": 100, "size": size_v}, pos, true)
	if not allow_blocks and not sv.a4:
		push_error("SWEEP2048 placeholder hull on %s (%s %s)" % [sid, fac, cls])
		failed = true
		return null
	var info := {"faction": fac, "cls": cls, "size": size_v, "meshes": sv.meshes, "shielded": shielded, "code": sv.code}
	fx.add_ship(sid, sv, info)
	return fx.ship(sid)


func _aim(target: Vector3, r: int, az := -PI / 2.0, elev := 0.95) -> void:
	cam.a = az
	cam.b = elev
	cam.r = float(r)
	cam.t = target
	cam.snap()


func _step_to(dt_total: float) -> void:
	var n := maxi(1, int(round(dt_total * 60.0)))
	for i in n:
		if fx != null:
			fx.step(1.0 / 60.0)
		await RenderingServer.frame_post_draw


func _grab_cell(code_label: String) -> Image:
	banner.text = code_label
	for i in 3:
		await RenderingServer.frame_post_draw
	var img: Image = vp.get_texture().get_image()
	img.convert(Image.FORMAT_RGBA8)
	img.resize(CELL_SIZE.x, CELL_SIZE.y, Image.INTERPOLATE_LANCZOS)
	return img


func _save_pair(dir: String, code: String, left: Image, right: Image) -> void:
	var row := Image.create(CELL_SIZE.x * 2, CELL_SIZE.y, false, Image.FORMAT_RGBA8)
	row.blit_rect(left, Rect2i(Vector2i.ZERO, CELL_SIZE), Vector2i(0, 0))
	row.blit_rect(right, Rect2i(Vector2i.ZERO, CELL_SIZE), Vector2i(CELL_SIZE.x, 0))
	var path := dir.path_join(code + ".png")
	PP.save_png(row, path, PP.capture_stage())
	manifest.append(code)
	print("[sweep2048] saved ", code, " (", tag, ")")


func _capture_shields(dir: String) -> void:
	OS.unset_environment("VS_IDLE_MOTION")
	for fac in SHIELD_FACS:
		for r in CAMS:
			# 1A: heavy torpedo shield hit local ripple vs bubble wash
			await _fresh_fx(20481)
			var s = _spawn_ship("sh_" + fac, fac, "Cruiser", 0.85, true)
			if s == null:
				return
			_aim(Vector3.ZERO, r)
			await fx.warmup(cam)
			await _step_to(0.25)
			var pt: Dictionary = s.shield_point(Vector3(30.0, 2.0, 14.0))
			s.shield_hit(fx, pt["local"], fx.now, 2.86, 26.0, 1.1, 0.65)
			await _step_to(0.08)
			var code_h := "SHLD_HIT_%s_c%d" % [fac, r]
			var a := await _grab_cell("%s | %s | t=0.08s" % [code_h, tag.to_upper()])
			await _step_to(0.18)
			var b := await _grab_cell("%s | %s | t=0.26s" % [code_h, tag.to_upper()])
			_save_pair(dir, code_h, a, b)

			# 1B: clean collapse edge wave (1.225 s close)
			await _fresh_fx(20482)
			var sb = _spawn_ship("sb_" + fac, fac, "Cruiser", 0.85, true)
			if sb == null:
				return
			_aim(Vector3.ZERO, r)
			await fx.warmup(cam)
			await _step_to(0.25)
			var ptb: Dictionary = sb.shield_point(Vector3(30.0, 2.0, 14.0))
			sb.shield_break(fx, 0, ptb["local"])
			await _step_to(0.35)
			var code_b := "SHLD_BRK_%s_c%d" % [fac, r]
			var ba := await _grab_cell("%s | %s | t=0.35s" % [code_b, tag.to_upper()])
			await _step_to(0.50)
			var bb := await _grab_cell("%s | %s | t=0.85s" % [code_b, tag.to_upper()])
			_save_pair(dir, code_b, ba, bb)


func _capture_small_vents(dir: String) -> void:
	OS.unset_environment("VS_IDLE_MOTION")
	for fac in VENT_FACS:
		for r in CAMS:
			await _fresh_fx(20483)
			var s = _spawn_ship("fr_" + fac, fac, "Frigate", 0.55, false)
			if s == null:
				return
			_aim(Vector3.ZERO, r)
			await fx.warmup(cam)
			DEATH.precompute(fx, s)
			await _step_to(0.50)
			fx.death("fr_" + fac, "blast")
			await _step_to(0.033)
			var code := "DTH_VENT_%s_c%d" % [fac, r]
			var a := await _grab_cell("%s | %s | t=0.03s" % [code, tag.to_upper()])
			await _step_to(0.084)
			var b := await _grab_cell("%s | %s | t=0.12s" % [code, tag.to_upper()])
			_save_pair(dir, code, a, b)


func _capture_terrain(dir: String) -> void:
	OS.unset_environment("VS_IDLE_MOTION")
	# 3A: Dead Star INFALL motes
	for r in CAMS:
		await _fresh_fx(20484)
		var wld := WORLD_SCRIPT.new()
		wld.set_meta("probe_temp", true)
		world.add_child(wld)
		wld.build({"map": {"deadstar": {"q": 0, "r": 0}}, "terrain": {}, "units": [], "round": 1},
			{"biome": {"rock": "stone"}, "fac": "voidsworn", "hex_world": _hex, "camera": cam, "environment": env, "quality": "max", "seed": 2048})
		_aim(Vector3(16.0 if r == 26 else 0.0, 6.0 if r == 26 else 0.0, 0.0), r)
		await _step_to(0.6)
		var code := "TERR_INFALL_c%d" % r
		var a := await _grab_cell("%s | %s | t=0.6s" % [code, tag.to_upper()])
		await _step_to(0.9)
		var b := await _grab_cell("%s | %s | t=1.5s" % [code, tag.to_upper()])
		_save_pair(dir, code, a, b)

	# 3B: terrain_scorch.gd decals (char crater + light-blue plasma melt)
	for r in CAMS:
		await _fresh_fx(20485)
		var slab := MeshInstance3D.new()
		slab.set_meta("probe_temp", true)
		var bm := BoxMesh.new()
		bm.size = Vector3(14.0, 2.0, 8.0)
		slab.mesh = bm
		var smat := StandardMaterial3D.new()
		smat.albedo_color = Color(0.42, 0.40, 0.37)
		smat.roughness = 0.85
		slab.material_override = smat
		slab.layers |= SCORCH.RECEIVER
		world.add_child(slab)
		SCORCH.clear_static()
		SCORCH.stamp(slab, {"position": Vector3(-3.2, 1.0, 0.0), "normal": Vector3.UP}, 4.8, false)
		SCORCH.stamp(slab, {"position": Vector3(3.2, 1.0, 0.0), "normal": Vector3.UP}, 4.8, true)
		_aim(Vector3(0.0, 1.0, 0.0), r, -PI / 2.0, 1.05)
		await _step_to(0.1)
		var code := "TERR_SCORCH_c%d" % r
		var a := await _grab_cell("%s | %s | char + plasma" % [code, tag.to_upper()])
		_aim(Vector3(0.0, 1.0, 0.0), r, -PI / 4.0, 0.65)
		await _step_to(0.1)
		var b := await _grab_cell("%s | %s | raking light" % [code, tag.to_upper()])
		_save_pair(dir, code, a, b)

	# 3C: Debris & background DUST_SHADER
	for r in CAMS:
		await _fresh_fx(20486)
		var wld := WORLD_SCRIPT.new()
		wld.set_meta("probe_temp", true)
		world.add_child(wld)
		var terr := {"0,0": "debris", "1,0": "debris", "-1,0": "debris", "0,1": "debris", "0,-1": "debris"}
		wld.build({"map": {"kind": "graveyard"}, "terrain": terr, "units": [], "round": 1},
			{"biome": {"rock": "stone"}, "fac": "voidsworn", "hex_world": _hex, "camera": cam, "environment": env, "quality": "max", "seed": 2048})
		_aim(Vector3.ZERO, r)
		await _step_to(0.5)
		var code := "TERR_DUST_c%d" % r
		var a := await _grab_cell("%s | %s | t=0.5s" % [code, tag.to_upper()])
		await _step_to(1.2)
		var b := await _grab_cell("%s | %s | t=1.7s" % [code, tag.to_upper()])
		_save_pair(dir, code, a, b)


func _capture_idle(dir: String) -> void:
	OS.set_environment("VS_IDLE_MOTION", "1")
	for fac in ALL_FACS:
		for r in CAMS:
			await _fresh_fx(20487)
			var s = _spawn_ship("id_" + fac, fac, "Cruiser", 0.85, false)
			if s == null:
				return
			_aim(Vector3.ZERO, r, -PI / 2.0 + 0.35, 0.85)
			await fx.warmup(cam)
			await _step_to(0.6)
			var code := "IDLE_%s_c%d" % [fac, r]
			var a := await _grab_cell("%s | %s | t=0.6s" % [code, tag.to_upper()])
			await _step_to(1.2)
			var b := await _grab_cell("%s | %s | t=1.8s" % [code, tag.to_upper()])
			_save_pair(dir, code, a, b)
	OS.unset_environment("VS_IDLE_MOTION")


func _compose_all(spec: String) -> void:
	var parts := spec.split(";")
	if parts.size() != 2:
		push_error("SWEEP2048 PROBE_COMPOSE must be '<before_dir>;<after_dir>'")
		failed = true
		return
	var bdir := parts[0]
	var adir := parts[1]
	var mf := FileAccess.open(adir.path_join("manifest.json"), FileAccess.READ)
	if mf == null:
		push_error("SWEEP2048 missing after manifest in " + adir)
		failed = true
		return
	var data = JSON.parse_string(mf.get_as_text())
	if not (data is Dictionary) or not (data.get("rows") is Array):
		push_error("SWEEP2048 malformed after manifest")
		failed = true
		return
	var sheets_dir := out.path_join("sheets")
	DirAccess.make_dir_recursive_absolute(sheets_dir)
	var composed := 0
	for code_v in data["rows"]:
		var code := str(code_v)
		var b_img := Image.new()
		var a_img := Image.new()
		if b_img.load(bdir.path_join(code + ".png")) != OK:
			push_error("SWEEP2048 missing before image for " + code)
			failed = true
			continue
		if a_img.load(adir.path_join(code + ".png")) != OK:
			push_error("SWEEP2048 missing after image for " + code)
			failed = true
			continue
		b_img.convert(Image.FORMAT_RGBA8)
		a_img.convert(Image.FORMAT_RGBA8)
		# Final before/after comparison sheet: 1280x720 (never taller than 720 px), top = BEFORE (main), bottom = AFTER (branch).
		var sheet := Image.create(1280, 720, false, Image.FORMAT_RGBA8)
		sheet.fill(Color(0.02, 0.02, 0.03, 1.0))
		sheet.blit_rect(b_img, Rect2i(0, 0, mini(1280, b_img.get_width()), mini(360, b_img.get_height())), Vector2i(0, 0))
		sheet.blit_rect(a_img, Rect2i(0, 0, mini(1280, a_img.get_width()), mini(360, a_img.get_height())), Vector2i(0, 360))
		PP.save_png(sheet, sheets_dir.path_join(code + "_before_after.png"), PP.capture_stage())
		composed += 1
	print("[sweep2048] composed ", composed, " before/after sheets in ", sheets_dir)
