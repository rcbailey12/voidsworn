extends SceneTree
# F3 probe (feel pass, effects at distance): every weapon family fired from a small ship (a frigate) and from a big ship
# (the faction's capital), each at a ship of its own size five hexes away, seen from the default battle camera
# (render/camera_rig.gd at its home angle, 170 units out, fov 45) and from the camera fully zoomed out (900 units, the
# rig's limit). The real battle pieces: G2's ShipView hulls from res://gen, G4's world (sky, rocks, dressing) and look.
#
# One sheet per family and size, NN_<family>_<size>.jpg: four columns (just before firing, the shot in flight, the hit,
# 0.45 s after the hit); the top row is the battle camera (the middle 1280x720 of a 1920x1080 frame, pixels as they are),
# the bottom row the zoomed-out camera (the middle 480x270, doubled with no smoothing so single pixels show).
#
# Run (Ryan's PC, from the job; needs --fixed-fps 60 so the clock is the same on every run):
#   godot --path godot --fixed-fps 60 --resolution 1920x1080 --script res://fx/test/fx_range_probe.gd
# Env: PROBE_OUT (folder), PROBE_ONLY (families, comma list), PROBE_SIZES (small,big), PROBE_CALM=1 (reduce flashing),
#      PROBE_QUALITY (max, high, low), PROBE_TRACE=1 (frames round the first impact from three views, see _trace),
#      PROBE_W, PROBE_H (render size, default 1920x1080). Prints [range] lines and FLASH_MAX (the most counted flashes
#      in any rolling second, which must stay at 3 or under).

const FX := preload("res://fx/fx.gd")
const WEAP := preload("res://fx/fx_weapons.gd")
const SV := preload("res://render/ship_view.gd")
const LOOK := preload("res://render/look.gd")
const CAMRIG := preload("res://render/camera_rig.gd")
const WORLD_PATH := "res://world/world.gd"
const HEX_S := 10.0
const HEX_W := 17.320508

const CAPITAL := {"voidsworn": "Dreadnought", "hegemony": "Super-dreadnought", "corsair": "Battle-barge", "chorus": "Bio-titan",
	"ithar": "Ark", "deathless": "Tomb-ark"}
# [family, attacker faction, rules kind, weapon id, target faction]
const FAMILIES := [
	["macro", "voidsworn", "battery", "hbattery", "hegemony"],
	["auto", "hegemony", "battery", "autocannon", "corsair"],
	["las", "voidsworn", "battery", "turret", "deathless"],
	["plasma", "hegemony", "battery", "hturbo", "voidsworn"],
	["scatter", "corsair", "battery", "scatter", "ithar"],
	["prism", "ithar", "battery", "shard", "corsair"],
	["needle", "ithar", "battery", "turret", "hegemony"],
	["lance", "voidsworn", "lance", "lance", "chorus"],
	["ion", "hegemony", "lance", "ion", "ithar"],
	["pulsar", "ithar", "lance", "pulsar", "voidsworn"],
	["doom", "deathless", "lance", "doom", "hegemony"],
	["torp", "voidsworn", "torp", "torp", "deathless"],
	["rockets", "corsair", "torp", "torp", "voidsworn"],
	["star", "ithar", "torp", "startorp", "chorus"],
	["flak", "hegemony", "flak", "flak", "corsair"],
	["spine", "chorus", "bio", "bioplasma", "ithar"],
	["tendril", "chorus", "bio", "tendril", "hegemony"],
	["gauss", "deathless", "gauss", "gauss", "voidsworn"],
	["craft", "voidsworn", "sq", "guns", "corsair"],
]
const SIZE := {"Frigate": 0.55, "capital": 1.25}

var vp: SubViewport
var world: Node3D
var cam: Camera3D
var env: Environment
var fx
var wld = null
var W := 1920
var H := 1080
var out := "/tmp"


func _init() -> void:
	process_frame.connect(_run, CONNECT_ONE_SHOT)


func _env(k: String, d: String) -> String:
	var v := OS.get_environment(k)
	return v if v != "" else d


func _hex(q: int, r: int) -> Vector3:
	return Vector3(HEX_W * (q + r / 2.0), 0, 1.5 * HEX_S * r)


func _run() -> void:
	W = int(_env("PROBE_W", "1920"))
	H = int(_env("PROBE_H", "1080"))
	out = _env("PROBE_OUT", "/tmp/f3_range")
	DirAccess.make_dir_recursive_absolute(out)
	vp = SubViewport.new()
	vp.size = Vector2i(W, H)
	vp.msaa_3d = Viewport.MSAA_4X
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(vp)
	world = Node3D.new()
	vp.add_child(world)
	env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.01, 0.012, 0.02)
	var we := WorldEnvironment.new()
	we.environment = env
	world.add_child(we)
	var key := DirectionalLight3D.new()
	world.add_child(key)
	var fill := DirectionalLight3D.new()
	world.add_child(fill)
	LOOK.apply(env, key, fill, {"quality": _env("PROBE_QUALITY", "max")})
	key.directional_shadow_max_distance = 600.0
	cam = CAMRIG.new()
	world.add_child(cam)
	cam.input_enabled = false
	cam.current = true
	# the battle's world: a sky with the enemy's nebula, a few rocks and the drifting dressing (no dead star)
	if ResourceLoader.exists(WORLD_PATH):
		wld = load(WORLD_PATH).new()
		world.add_child(wld)
		var terrain := {"0,-4": "rock", "-5,3": "rock", "4,3": "debris", "-1,5": "rock"}
		var units := [{"q": -6, "r": -3}, {"q": 6, "r": 3}]
		wld.build({"map": {}, "terrain": terrain, "units": units, "round": 1},
			{"biome": {"rock": "stone"}, "fac": "hegemony", "hex_world": _hex, "camera": cam, "environment": env, "quality": "max", "seed": 5})
	fx = FX.new()
	world.add_child(fx)
	fx.manual = true
	var calm := _env("PROBE_CALM", "") == "1"
	var qual := _env("PROBE_QUALITY", "max")
	fx.setup({"camera": cam, "quality": qual, "reduce_flashing": calm, "shake": 1.0, "unit": 1.0})
	print("[range] renderer=%s adapter=%s res=%dx%d calm=%s" % [RenderingServer.get_current_rendering_method(),
		RenderingServer.get_video_adapter_name(), W, H, str(calm)])
	_home()
	for i in 3:
		await RenderingServer.frame_post_draw
	var only := _env("PROBE_ONLY", "")
	var sizes := _env("PROBE_SIZES", "small,big").split(",")
	var warmed := false
	var idx := 0
	for fam in FAMILIES:
		if only != "" and not (String(fam[0]) in only.split(",")):
			continue
		for sz in sizes:
			idx += 1
			var big: bool = sz == "big"
			var a_cls: String = CAPITAL[fam[1]] if big else "Frigate"
			var t_cls: String = CAPITAL[fam[4]] if big else "Frigate"
			var a := _ship("A", fam[1], a_cls, _hex(-3, 0), 0, big)
			var t := _ship("T", fam[4], t_cls, _hex(2, 0), 2, big)
			if not warmed:
				await fx.warmup(cam)
				warmed = true
			await _wait(0.6)
			var res := await _volley(fam, idx, sz)
			print("[range] %02d %s %s attacker=%s %s target=%s %s impacts=%s" % [idx, fam[0], sz, fam[1], a_cls, fam[4], t_cls, str(res)])
			fx.remove_ship("A")
			fx.remove_ship("T")
			a.queue_free()
			t.queue_free()
			# let every particle of this volley run out before the next one
			await _wait(4.5)
	# the flash budget over the whole run (WCAG 2.3.1): the most counted flashes in any rolling second
	var mx := 0
	var fl: PackedFloat64Array = fx.flash_log
	for i in fl.size():
		var c := 0
		for j in fl.size():
			if fl[j] > fl[i] - 1.0 and fl[j] <= fl[i]:
				c += 1
		mx = maxi(mx, c)
	print("FLASH_MAX %d (counted flashes %d)" % [mx, fl.size()])
	print("[range] done")
	quit(0)


func _ship(id: String, fac: String, cls: String, pos: Vector3, facing: int, flag: bool) -> Node3D:
	var sv: Node3D = SV.new()
	sv.name = "ship_" + id
	world.add_child(sv)
	var size: float = SIZE["capital"] if flag else SIZE["Frigate"]
	sv.setup({"id": id, "fac": fac, "cls": cls, "facing": facing, "hp": 100, "maxHp": 100, "size": size}, pos, true)
	var info := {"faction": fac, "cls": cls, "size": size, "squadron": false, "flagship": flag, "code": sv.code}
	if not sv.a4:
		info["meshes"] = sv.meshes
	fx.add_ship(id, sv, info)
	sv.fx_engines = true
	fx.set_engine(id, 0.35)
	return sv


func _hits(n: int, shielded: bool) -> Array:
	var h := []
	for i in n:
		var on_sh := shielded and i == 0
		h.append({"shield": 8 if on_sh else 0, "hull": 0 if on_sh else 9, "section": ["mid", "prow", "mid", "eng"][i % 4], "crit": false})
	return h


func _volley(fam: Array, idx: int, sz: String) -> Array:
	var lk: String = WEAP.look_of(fam[2], fam[3], fam[1])
	var n: int = WEAP.default_shots(lk)
	var shots := []
	for i in n:
		shots.append(true)
	var shielded: bool = fx.ship("T").shielded
	fx.rng.seed = 1000 + idx
	var cols: Array = []
	cols.append(await _grab())
	var T0: float = fx.now
	var r: Dictionary = fx.volley("A", fam[2], "T", {"weapon_id": fam[3], "shots": shots, "hits": _hits(n, shielded)})
	var imp: Array = r["impacts"]
	var i0: float = float(imp[0]) if not imp.is_empty() else 0.4
	for m in [i0 * 0.6, i0 + 0.08, i0 + 0.45]:
		await _wait_until(T0 + m)
		cols.append(await _grab())
	_sheet(cols, "%s/%02d_%s_%s.jpg" % [out, idx, fam[0], sz])
	if _env("PROBE_TRACE", "") == "1":
		await _trace(fam, idx, sz)
	return imp


# PROBE_TRACE=1: the same volley again, and the frames round its first impact (0.1 s before to 1.2 s after) from three
# views (the battle camera, straight down, low from the side), each cropped round the target: one sheet per volley.
# For finding an effect that does not show (is it hidden behind the hull, or not drawn at all?).
func _trace(fam: Array, idx: int, sz: String) -> void:
	await _wait(4.5)
	var lk: String = WEAP.look_of(fam[2], fam[3], fam[1])
	var n: int = WEAP.default_shots(lk)
	var shots := []
	for i in n:
		shots.append(true)
	fx.rng.seed = 1000 + idx
	var T0: float = fx.now
	var r: Dictionary = fx.volley("A", fam[2], "T", {"weapon_id": fam[3], "shots": shots, "hits": _hits(n, fx.ship("T").shielded)})
	var imp: Array = r["impacts"]
	var i0: float = float(imp[0]) if not imp.is_empty() else 0.4
	var tp: Vector3 = fx.ship("T").root.global_position
	print("[trace] %02d %s %s target at %s length %.1f impacts %s" % [idx, fam[0], sz, str(tp), fx.ship("T").hull.L, str(imp)])
	var times := [-0.1, 0.02, 0.1, 0.25, 0.5, 1.2]
	var views := [0.98, 0.05, 1.36]
	var cw := 640
	var chh := 360
	var img := Image.create(cw * times.size(), chh * views.size(), false, Image.FORMAT_RGB8)
	for ti in times.size():
		await _wait_until(T0 + i0 + float(times[ti]))
		for vi in views.size():
			_home()
			cam.b = float(views[vi])
			cam.snap()
			await RenderingServer.frame_post_draw
			await RenderingServer.frame_post_draw
			var fr := vp.get_texture().get_image()
			fr.convert(Image.FORMAT_RGB8)
			var sp: Vector2 = cam.unproject_position(tp)
			var x0 := clampi(int(sp.x) - cw / 2, 0, W - cw)
			var y0 := clampi(int(sp.y) - chh / 2, 0, H - chh)
			img.blit_rect(fr, Rect2i(x0, y0, cw, chh), Vector2i(ti * cw, vi * chh))
	_home()
	img.save_jpg("%s/trace_%02d_%s_%s.jpg" % [out, idx, fam[0], sz], 0.9)
	print("[trace] wrote trace_%02d_%s_%s.jpg" % [idx, fam[0], sz])


func _home() -> void:
	cam.a = -PI / 2.0
	cam.b = 0.98
	cam.r = 170.0
	cam.t = Vector3(_hex(-3, 0).x * 0.5 + _hex(2, 0).x * 0.5, 0, 0)
	cam.snap()


func _far() -> void:
	cam.r = 900.0
	cam.snap()


func _step() -> void:
	fx.step(1.0 / 60.0)
	if wld != null and wld.has_method("step"):
		wld.step(1.0 / 60.0)


func _wait(s: float) -> void:
	await _wait_until(fx.now + s)


func _wait_until(t: float) -> void:
	while fx.now + 1e-4 < t:
		_step()
		await RenderingServer.frame_post_draw


# both cameras at this moment (the effect clock holds while the camera moves)
func _grab() -> Array:
	_home()
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var a := vp.get_texture().get_image()
	_far()
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var b := vp.get_texture().get_image()
	_home()
	return [a, b]


func _sheet(cols: Array, path: String) -> void:
	var cw := mini(1280, W)
	var ch := mini(720, H)
	var fw := mini(480, W)
	var fh := mini(270, H)
	var img := Image.create(cw * cols.size(), ch + fh * 2, false, Image.FORMAT_RGB8)
	img.fill(Color(0, 0, 0))
	for i in cols.size():
		var a: Image = cols[i][0]
		var b: Image = cols[i][1]
		a.convert(Image.FORMAT_RGB8)
		b.convert(Image.FORMAT_RGB8)
		img.blit_rect(a, Rect2i((W - cw) / 2, (H - ch) / 2, cw, ch), Vector2i(i * cw, 0))
		var c := b.get_region(Rect2i((W - fw) / 2, (H - fh) / 2, fw, fh))
		c.resize(fw * 2, fh * 2, Image.INTERPOLATE_NEAREST)
		img.blit_rect(c, Rect2i(0, 0, fw * 2, fh * 2), Vector2i(i * cw + (cw - fw * 2) / 2, ch))
	img.save_jpg(path, 0.9)
	print("[range] wrote %s" % path)
