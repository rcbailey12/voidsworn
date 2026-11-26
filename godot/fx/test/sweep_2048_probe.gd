extends SceneTree
## Issue 2048 (Build G): look bench capture probe for before/after rows at cameras 170 and 26, per faction where it differs.
## Runs identically on pinned origin/main (PROBE_TAG=before) and neon/issue-2048 (PROBE_TAG=after), then composes 1280x720
## before/after rows (PROBE_COMPOSE="<before_dir>;<after_dir>"), each picture stamped with its code name (<= 720 px tall)
## and retaining both pinned source commits in manifests and composed provenance.
##
## Items covered:
##   1. Shield hits (c170 + c26, per shielded faction: voidsworn, hegemony, corsair, ithar)
##      and shield collapse edge wave (c170 + c26, per shielded faction)
##   2. Small death bow vent (c170 + c26, per faction: voidsworn, hegemony, corsair, ithar, deathless)
##   3. Terrain polish: Dead Star INFALL motes, terrain_scorch.gd decals, DUST_SHADER (c170 + c26)
##   4. Layered fx_idle.gd motion pieces (VS_IDLE_MOTION=1 during capture only; c170 + c26, all 6 factions)
##
## Env:
##   PROBE_OUT         output folder (required)
##   PROBE_TAG         before | after (default after)
##   PROBE_COMPOSE     "<before_dir>;<after_dir>" to stitch 1280x720 before/after sheets without rendering
##   PROBE_ONLY        optional comma filter from: shield,vent,terrain,idle (invalid names fail closed)
##   PROBE_BEFORE_SHA  pinned full 40-char baseline commit SHA (recorded in manifest and sheet header)
##   PROBE_AFTER_SHA   pinned full 40-char branch commit SHA (recorded in manifest and sheet header)
##   PROBE_BLOCKS      1 allows placeholder hulls (cloud syntax test only; never for Ryan)
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

const VALID_GROUPS := ["shield", "vent", "terrain", "idle"]
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
var groups: Array[String] = []
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


func _parse_groups() -> bool:
	var only := _env("PROBE_ONLY", "").strip_edges()
	if only.is_empty():
		for g in VALID_GROUPS:
			groups.append(g)
		return true
	for raw in only.split(","):
		var g := raw.strip_edges()
		if g.is_empty() or not (g in VALID_GROUPS):
			push_error("SWEEP2048 invalid PROBE_ONLY group '%s' (allowed: %s)" % [g, ",".join(VALID_GROUPS)])
			return false
		if not (g in groups):
			groups.append(g)
	if groups.is_empty():
		push_error("SWEEP2048 PROBE_ONLY selected zero groups")
		return false
	return true


func _expected_count() -> int:
	var n := 0
	if "shield" in groups:
		n += SHIELD_FACS.size() * CAMS.size() * 2
	if "vent" in groups:
		n += VENT_FACS.size() * CAMS.size()
	if "terrain" in groups:
		n += 3 * CAMS.size()
	if "idle" in groups:
		n += ALL_FACS.size() * CAMS.size()
	return n


func _short_sha(sha: String) -> String:
	var s := sha.strip_edges()
	return s.substr(0, mini(8, s.length())) if not s.is_empty() else "unpinned"


func _run() -> void:
	out = _env("PROBE_OUT", "")
	if out.is_empty():
		push_error("SWEEP2048 PROBE_OUT is not set")
		print("SWEEP2048_FAILED")
		quit(2)
		return
	if not _parse_groups():
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

	if "shield" in groups:
		await _capture_shields(dir)
	if "vent" in groups and not failed:
		await _capture_small_vents(dir)
	if "terrain" in groups and not failed:
		await _capture_terrain(dir)
	if "idle" in groups and not failed:
		await _capture_idle(dir)

	var expected := _expected_count()
	if manifest.is_empty() or manifest.size() != expected:
		push_error("SWEEP2048 row count mismatch for %s: captured %d, expected %d" % [tag, manifest.size(), expected])
		failed = true

	var commit_sha := _env("PROBE_BEFORE_SHA", "") if tag == "before" else _env("PROBE_AFTER_SHA", "")
	var fp := FileAccess.open(dir.path_join("manifest.json"), FileAccess.WRITE)
	if fp == null:
		failed = true
		push_error("SWEEP2048 could not write manifest.json")
	else:
		fp.store_string(JSON.stringify({
			"tag": tag,
			"commit": commit_sha,
			"groups": groups,
			"expected": expected,
			"rows": manifest,
		}, "  "))
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
	banner.add_theme_font_size_override("font_size", 20)
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


func _tag_rev() -> String:
	var sha := _env("PROBE_BEFORE_SHA", "") if tag == "before" else _env("PROBE_AFTER_SHA", "")
	return "%s (%s)" % [tag.to_upper(), _short_sha(sha)]


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
	var err: Error = load("res://tools/picture_provenance.gd").save_png(row, path, PP.capture_stage())
	if err != OK or not FileAccess.file_exists(path):
		push_error("SWEEP2048 failed saving %s (err=%d)" % [path, int(err)])
		failed = true
		return
	manifest.append(code)
	print("[sweep2048] saved ", code, " (", tag, ")")


func _capture_shields(dir: String) -> void:
	OS.unset_environment("VS_IDLE_MOTION")
	var tr := _tag_rev()
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
			var a := await _grab_cell("%s | %s | t=0.08s" % [code_h, tr])
			await _step_to(0.18)
			var b := await _grab_cell("%s | %s | t=0.26s" % [code_h, tr])
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
			var ba := await _grab_cell("%s | %s | t=0.35s" % [code_b, tr])
			await _step_to(0.50)
			var bb := await _grab_cell("%s | %s | t=0.85s" % [code_b, tr])
			_save_pair(dir, code_b, ba, bb)


func _capture_small_vents(dir: String) -> void:
	OS.unset_environment("VS_IDLE_MOTION")
	var tr := _tag_rev()
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
			var a := await _grab_cell("%s | %s | t=0.03s" % [code, tr])
			await _step_to(0.084)
			var b := await _grab_cell("%s | %s | t=0.12s" % [code, tr])
			_save_pair(dir, code, a, b)


func _capture_terrain(dir: String) -> void:
	OS.unset_environment("VS_IDLE_MOTION")
	var tr := _tag_rev()
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
		var a := await _grab_cell("%s | %s | t=0.6s" % [code, tr])
		await _step_to(0.9)
		var b := await _grab_cell("%s | %s | t=1.5s" % [code, tr])
		_save_pair(dir, code, a, b)

	# 3B: terrain_scorch.gd decals (char crater + light-blue plasma melt) + cold first-mark timing
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
		var t0 := Time.get_ticks_usec()
		SCORCH.stamp(slab, {"position": Vector3(-3.2, 1.0, 0.0), "normal": Vector3.UP}, 4.8, false)
		var cold_ms := float(Time.get_ticks_usec() - t0) / 1000.0
		SCORCH.stamp(slab, {"position": Vector3(3.2, 1.0, 0.0), "normal": Vector3.UP}, 4.8, true)
		print("[sweep2048] scorch cold_ms=%.2f (%s c%d)" % [cold_ms, tag, r])
		_aim(Vector3(0.0, 1.0, 0.0), r, -PI / 2.0, 1.05)
		await _step_to(0.1)
		var code := "TERR_SCORCH_c%d" % r
		var a := await _grab_cell("%s | %s | cold=%.1fms" % [code, tr, cold_ms])
		_aim(Vector3(0.0, 1.0, 0.0), r, -PI / 4.0, 0.65)
		await _step_to(0.1)
		var b := await _grab_cell("%s | %s | raking light" % [code, tr])
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
		var a := await _grab_cell("%s | %s | t=0.5s" % [code, tr])
		await _step_to(1.2)
		var b := await _grab_cell("%s | %s | t=1.7s" % [code, tr])
		_save_pair(dir, code, a, b)


func _capture_idle(dir: String) -> void:
	OS.set_environment("VS_IDLE_MOTION", "1")
	var tr := _tag_rev()
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
			var a := await _grab_cell("%s | %s | t=0.6s" % [code, tr])
			await _step_to(1.2)
			var b := await _grab_cell("%s | %s | t=1.8s" % [code, tr])
			_save_pair(dir, code, a, b)
	OS.unset_environment("VS_IDLE_MOTION")


func _read_manifest(path: String) -> Dictionary:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return {}
	var parsed = JSON.parse_string(f.get_as_text())
	return parsed if parsed is Dictionary else {}


func _compose_all(spec: String) -> void:
	var parts := spec.split(";")
	if parts.size() != 2:
		push_error("SWEEP2048 PROBE_COMPOSE must be '<before_dir>;<after_dir>'")
		failed = true
		return
	var bdir := parts[0]
	var adir := parts[1]
	var bdata := _read_manifest(bdir.path_join("manifest.json"))
	var adata := _read_manifest(adir.path_join("manifest.json"))
	if bdata.is_empty() or adata.is_empty() or not (bdata.get("rows") is Array) or not (adata.get("rows") is Array):
		push_error("SWEEP2048 missing or malformed before/after manifest.json")
		failed = true
		return
	var brows: Array = bdata["rows"]
	var arows: Array = adata["rows"]
	var expected := _expected_count()
	if arows.is_empty() or arows.size() != expected or brows != arows:
		push_error("SWEEP2048 manifest row mismatch: before=%d after=%d expected=%d" % [brows.size(), arows.size(), expected])
		failed = true
		return
	var before_sha := str(bdata.get("commit", _env("PROBE_BEFORE_SHA", "")))
	var after_sha := str(adata.get("commit", _env("PROBE_AFTER_SHA", "")))
	if before_sha.length() < 8 or after_sha.length() < 8:
		push_error("SWEEP2048 missing pinned before/after commit SHAs (before='%s' after='%s')" % [before_sha, after_sha])
		failed = true
		return
	var sheets_dir := out.path_join("sheets")
	DirAccess.make_dir_recursive_absolute(sheets_dir)
	var written: Array = []
	for code_v in arows:
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
		var out_path := sheets_dir.path_join(code + "_before_after.png")
		var err: Error = load("res://tools/picture_provenance.gd").save_png(sheet, out_path, PP.capture_stage())
		if err != OK or not FileAccess.file_exists(out_path):
			push_error("SWEEP2048 failed saving composed sheet %s (err=%d)" % [out_path, int(err)])
			failed = true
			continue
		# Augment the sheet's provenance sidecar with both pinned revisions so before and after commits stay recorded.
		var sidecar_path := out_path + ".provenance.json"
		var sc := _read_manifest(sidecar_path)
		if not sc.is_empty():
			sc["before_commit"] = before_sha
			sc["after_commit"] = after_sha
			var sf := FileAccess.open(sidecar_path, FileAccess.WRITE)
			if sf != null:
				sf.store_string(JSON.stringify(sc, "  "))
				sf.close()
		written.append(code + "_before_after.png")
	if written.size() != expected:
		push_error("SWEEP2048 composed %d sheets, expected %d" % [written.size(), expected])
		failed = true
	var cf := FileAccess.open(sheets_dir.path_join("composed_manifest.json"), FileAccess.WRITE)
	if cf == null:
		push_error("SWEEP2048 could not write composed_manifest.json")
		failed = true
	else:
		cf.store_string(JSON.stringify({
			"before_commit": before_sha,
			"after_commit": after_sha,
			"groups": groups,
			"expected": expected,
			"composed": written.size(),
			"files": written,
		}, "  "))
		cf.close()
	print("[sweep2048] composed ", written.size(), "/", expected, " before/after sheets in ", sheets_dir)
