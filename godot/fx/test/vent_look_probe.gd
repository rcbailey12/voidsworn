extends SceneTree
# Issue 281 vent gas review probe. Plays the weapon moments with the real battle pieces (G2's ShipView hulls from
# res://gen, G4's world and look) on a fixed effect clock, and records them for the before/after clips and contact sheet:
#   1. a macro salvo (Voidsworn heavy battery) and its hull hit,
#   2. a heavy hull hit.
# Each moment is captured at the battle camera and at close range. Two variants run in one process: "before" (today's
# look, the baked gas cell and the old round flash) and "after" (the shipped Cone B, a tight forward flash and jet).
# Each writes a raw RGB frame sequence (frame_00000.rgb, clip.json) plus the stills the contact sheet is built from.
#
# Run (Ryan's PC, from the repo root; needs godot/gen and the hull textures):
#   godot --path godot --fixed-fps 60 --resolution 640x360 --script res://fx/test/vent_look_probe.gd
# Env: VENT_OUT (output folder), VENT_ONLY (comma list: before,after), VENT_RANGE (battle, close, both),
#      VENT_W, VENT_H, VENT_FPS (clip fps, default 12), VENT_QUALITY (max, high, low).
# Prints [vent] lines and VENT_DONE.

const FX := preload("res://fx/fx.gd")
const SV := preload("res://render/ship_view.gd")
const LOOK := preload("res://render/look.gd")
const CAMRIG := preload("res://render/camera_rig.gd")
const WORLD_PATH := "res://world/world.gd"
const HEX_S := 10.0
const HEX_W := 17.320508

# [label, fx.vent_look]
const VARIANTS := [
	["before", "today"],
	["after", ""],
]

var vp: SubViewport
var world: Node3D
var cam: Camera3D
var env: Environment
var fx
var wld = null
var W := 640
var H := 360
var out := "/tmp"
var fps := 12
var step_skip := 5
var step_i := 0
var frame_i := 0
var rec_dir := ""
var rec_on := false
var cur_label := ""
var cur_range := ""
var stills: Array = []   # [{t, kind, done}]
var A = null
var T = null


func _init() -> void:
	process_frame.connect(_run, CONNECT_ONE_SHOT)


func _env(k: String, d: String) -> String:
	var v := OS.get_environment(k)
	return v if v != "" else d


func _hex(q: int, r: int) -> Vector3:
	return Vector3(HEX_W * (q + r / 2.0), 0, 1.5 * HEX_S * r)


func _run() -> void:
	W = int(_env("VENT_W", "640"))
	H = int(_env("VENT_H", "360"))
	fps = int(_env("VENT_FPS", "12"))
	step_skip = maxi(1, int(round(60.0 / float(fps))))
	out = _env("VENT_OUT", "/tmp/vent_fx")
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
	LOOK.apply(env, key, fill, {"quality": _env("VENT_QUALITY", "max")})
	key.directional_shadow_max_distance = 600.0
	cam = CAMRIG.new()
	world.add_child(cam)
	cam.input_enabled = false
	cam.current = true
	if ResourceLoader.exists(WORLD_PATH):
		wld = load(WORLD_PATH).new()
		world.add_child(wld)
		var terrain := {"0,-4": "rock", "-5,3": "rock", "4,3": "debris", "-1,5": "rock"}
		var units := [{"q": -3, "r": -2}, {"q": 3, "r": 2}]
		wld.build({"map": {}, "terrain": terrain, "units": units, "round": 1},
			{"biome": {"rock": "stone"}, "fac": "voidsworn", "hex_world": _hex, "camera": cam, "environment": env,
			"quality": "max", "seed": 7})
	fx = FX.new()
	world.add_child(fx)
	fx.manual = true
	fx.setup({"camera": cam, "quality": _env("VENT_QUALITY", "max"), "reduce_flashing": false, "shake": 0.0,
		"unit": 1.0})
	fx.check_radius = true
	_ship_reset()
	await fx.warmup(cam)
	var only := _env("VENT_ONLY", "")
	for v in VARIANTS:
		if only != "" and not (String(v[0]) in only.split(",")):
			continue
		await _variant(v)
	print("VENT_DONE")
	quit(0)


func _variant(v: Array) -> void:
	fx.vent_look = str(v[1])
	print("[vent] variant %s look='%s'" % [v[0], fx.vent_look])
	_ship_reset()
	await _wait(0.3)
	var pick := _env("VENT_RANGE", "both")
	# battle crop: both ships framed by the default rig
	if pick == "both" or pick == "battle":
		_battle()
		await _wait(0.3)
		await _pass(String(v[0]), "battle")
	# close range: both ships framed at close range
	if pick == "both" or pick == "close":
		await _wait(1.0)
		_close_cam()
		await _wait(0.3)
		await _pass(String(v[0]), "close")
	var stray: Array = fx.stray_spawns()
	if not stray.is_empty():
		print("[vent] STRAY_FAIL %s stray weapon/vent spawns away from any ship: %s" % [v[0], str(stray.slice(0, 8))])
	else:
		print("[vent] stray none %s" % v[0])


func _ship_reset() -> void:
	for id in ["A", "T"]:
		if fx.ships.has(id):
			fx.remove_ship(id)
	for n in world.get_children():
		if n is Node3D and String(n.name).begins_with("ship_"):
			n.queue_free()
	A = _ship("A", "voidsworn", "Frigate", Vector3(-12, 0, 0), 0, false)
	T = _ship("T", "deathless", "Cruiser", Vector3(18, 0, 0), 3, false)


func _ship(id: String, fac: String, cls: String, pos: Vector3, facing: int, flag: bool) -> Node3D:
	var sv: Node3D = SV.new()
	sv.name = "ship_" + id
	world.add_child(sv)
	sv.setup({"id": id, "fac": fac, "cls": cls, "facing": facing, "hp": 100, "maxHp": 100, "size": 1.0}, pos, true)
	var info := {"faction": fac, "cls": cls, "size": 1.0, "squadron": false, "flagship": flag, "code": sv.code}
	if not sv.a4:
		info["meshes"] = sv.meshes
	fx.add_ship(id, sv, info)
	sv.fx_engines = true
	fx.set_engine(id, 0.3)
	return sv


func _pass(label: String, range_name: String) -> void:
	cur_label = label
	cur_range = range_name
	rec_dir = out.path_join("raw_%s_%s" % [label, range_name])
	DirAccess.make_dir_recursive_absolute(rec_dir)
	frame_i = 0
	step_i = 0
	stills = []
	var meta := {"label": label, "look": fx.vent_look, "range": range_name, "w": W, "h": H,
		"fps": fps, "frames": 0}
	# 1. macro salvo
	var t0: float = fx.now + 0.25
	rec_on = true
	_reseed(11)
	await _wait_capture(t0)
	var r: Dictionary = fx.volley("A", "battery", "T", {"weapon_id": "hbattery", "shots": [true, true, true, true],
		"hits": _hits(4)})
	var m0: float = t0 + float(r["impacts"][0])
	_still_at(t0 + 0.36, "macro_muzzle")
	_still_at(m0 + 0.09, "macro_hit")
	await _wait_capture(t0 + 1.55)
	rec_on = false
	# 2. heavy hull hit
	await _wait(t0 + 1.7)
	t0 = fx.now + 0.2
	rec_on = true
	_reseed(13)
	await _wait_capture(t0)
	r = fx.volley("A", "battery", "T", {"weapon_id": "hbattery", "shots": [true],
		"hits": [{"shield": 0, "hull": 9, "section": "mid", "crit": false}]})
	m0 = t0 + float(r["impacts"][0])
	_still_at(m0 + 0.14, "hull_hit")
	await _wait_capture(t0 + 1.2)
	rec_on = false
	meta["frames"] = frame_i
	var mf := FileAccess.open(rec_dir.path_join("clip.json"), FileAccess.WRITE)
	mf.store_string(JSON.stringify(meta, "  ") + "\n")
	mf.close()
	print("[vent] %s %s frames=%d" % [label, range_name, frame_i])


func _still_at(t: float, kind: String) -> void:
	stills.append({"t": t, "kind": kind, "done": false})


func _hits(n: int) -> Array:
	var h := []
	for i in n:
		h.append({"shield": 0, "hull": 9, "section": "mid", "crit": false})
	return h


func _reseed(seed: int) -> void:
	fx.rng.seed = seed
	if fx.ship("T") != null:
		fx.ship("T").hull._rng.seed = seed + 3


func _battle() -> void:
	# the normal rig angle, pulled in to a battle crop on the pair so the gas reads on a phone
	cam.a = -PI / 2.0
	cam.b = 0.98
	cam.r = 60.0
	cam.t = Vector3(3, 0, 0)
	cam.snap()


func _close_cam() -> void:
	cam.a = -PI / 2.0
	cam.b = 1.02
	cam.r = 20.0
	cam.t = Vector3(3, 0.8, 0)
	cam.snap()


func _step() -> void:
	fx.step(1.0 / 60.0)
	if wld != null and wld.has_method("step"):
		wld.step(1.0 / 60.0)
	step_i += 1


func _wait(s: float) -> void:
	await _wait_until(fx.now + s)


func _wait_until(t: float) -> void:
	while fx.now + 1e-4 < t:
		_step()
		await RenderingServer.frame_post_draw


# capture loop: one raw frame every step_skip steps, and any due still as a PNG
func _wait_capture(t: float) -> void:
	var guard := 0
	while fx.now + 1e-4 < t:
		_step()
		await RenderingServer.frame_post_draw
		if rec_on and (step_i % step_skip == 0):
			_raw_frame()
		await _grab_stills()
		guard += 1
		if guard % 300 == 0:
			print("[vent] wait step=%d now=%.3f target=%.3f speed=%.3f" % [step_i, fx.now, t, fx._speed])
		if guard > 20000:
			print("[vent] GUARD stop now=%.3f target=%.3f" % [fx.now, t])
			break


func _grab_stills() -> void:
	for s in stills:
		if bool(s["done"]):
			continue
		if fx.now + 1e-4 >= float(s["t"]):
			s["done"] = true
			await _still(String(s["kind"]))


func _raw_frame() -> void:
	var img := vp.get_texture().get_image()
	if img == null or img.is_empty():
		return
	img.convert(Image.FORMAT_RGB8)
	var f := FileAccess.open(rec_dir.path_join("frame_%05d.rgb" % frame_i), FileAccess.WRITE)
	f.store_buffer(img.get_data())
	f.close()
	frame_i += 1


func _still(kind: String) -> void:
	DirAccess.make_dir_recursive_absolute(out.path_join("stills"))
	var img := vp.get_texture().get_image()
	if img == null or img.is_empty():
		return
	img.save_png(out.path_join("stills").path_join("%s_%s_%s.png" % [cur_label, cur_range, kind]))
	# a tight crop on the vent itself, so the gas can be judged rather than the whole tableau
	var keep := [cam.a, cam.b, cam.r, cam.t]
	_crop_cam(kind)
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	img = vp.get_texture().get_image()
	if img != null and not img.is_empty():
		img.save_png(out.path_join("stills").path_join("%s_%s_%s_crop.png" % [cur_label, cur_range, kind]))
	cam.a = keep[0]
	cam.b = keep[1]
	cam.r = keep[2]
	cam.t = keep[3]
	cam.snap()
	await RenderingServer.frame_post_draw


func _crop_cam(kind: String) -> void:
	var muzzle: bool = kind == "macro_muzzle" or kind == "light_gun"
	cam.a = -PI / 2.0
	cam.b = 1.12
	if muzzle:
		cam.t = A.global_position + Vector3(7.0, 0.5, 0)
		cam.r = 10.0
	else:
		cam.t = T.global_position + Vector3(-7.0, 1.5, 0)
		cam.r = 15.0 if kind == "hull_hit" else 13.0
	cam.snap()
