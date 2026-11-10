extends SceneTree
# Issue 354 capture: a 30 frames a second strip of the death vent beat, for a frigate, a cruiser and a capital at the
# battle camera (r 170) and the closest the game allows (r 26). The look bench's death rows jump from the death call to
# the split, so they never show the vent at 0.12 s (small) or 0.30 s (big); this probe holds the effect clock and takes
# one 384x216 cell every 1/30 s of effect time for the first 0.8 s, across the vent and its drift. Camera 170 is a 1 to 1
# pixel crop of a 1920x1080 frame; camera 26 is the bench's 1152x648 crop scaled to the same cell.
#
# Run (Ryan's PC; needs the PC-built hulls in godot/gen):
#   godot --path godot --fixed-fps 60 --disable-vsync --resolution 1920x1080 --script res://fx/test/death_vent_strip_probe.gd
# Env: DV_OUT (output folder), DV_CLASS (frigate,cruiser,capital; default all), DV_CAM (170,26; default both).
# Prints [death_strip] lines and DEATH_STRIP_DONE. Stops with "placeholder hull" if a hull is not built.

const FX := preload("res://fx/fx.gd")
const SV := preload("res://render/ship_view.gd")
const LOOK := preload("res://render/look.gd")
const CAMRIG := preload("res://render/camera_rig.gd")
const PG := preload("res://render/placeholder_guard.gd")
const WORLD_PATH := "res://world/world.gd"
const HEX_S := 10.0
const HEX_W := 17.320508
const W := 1920
const H := 1080
const CELL := Vector2i(384, 216)
const FPS := 30

const CASES := [
	["frigate", "corsair", "Frigate", "blast"],
	["cruiser", "voidsworn", "Cruiser", "big"],
	["capital", "hegemony", "Super-dreadnought", "cut"],
]

var vp: SubViewport
var world: Node3D
var env: Environment
var cam
var fx
var wld = null
var out := ""
var ship: Node3D = null


func _init() -> void:
	process_frame.connect(_run, CONNECT_ONE_SHOT)


func _env(k: String, d: String) -> String:
	var v := OS.get_environment(k)
	return v if v != "" else d


func _hex(q: int, r: int) -> Vector3:
	return Vector3(HEX_W * (q + r / 2.0), 0, 1.5 * HEX_S * r)


func _run() -> void:
	out = _env("DV_OUT", "/tmp/death_vent_strip")
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
	LOOK.apply(env, key, fill, {"quality": "max"})
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
	fx.setup({"camera": cam, "quality": "max", "reduce_flashing": false, "shake": 0.0, "unit": 1.0})
	fx.check_radius = true
	var only_cls := _env("DV_CLASS", "frigate,cruiser,capital")
	var only_cam := _env("DV_CAM", "170,26")
	for c in CASES:
		if not (String(c[0]) in only_cls.split(",")):
			continue
		for r in [170, 26]:
			if not (str(r) in only_cam.split(",")):
				continue
			await _pass(String(c[0]), String(c[1]), String(c[2]), String(c[3]), r)
	print("DEATH_STRIP_DONE")
	PG.finish(0)


func _pass(label: String, fac: String, cls: String, cause: String, r: int) -> void:
	_reset()
	ship = _ship("T", fac, cls)
	if PG.stop_if_any():
		return
	cam.a = -PI / 2.0
	cam.b = 0.98
	cam.r = float(r)
	cam.t = Vector3.ZERO
	cam.snap()
	await _wait(0.2)
	await fx.warmup(cam)
	# engine up and the staggered cut precompute, as a battle has them before the kill
	for i in 72:
		_step()
		await RenderingServer.frame_post_draw
	var t_ev: float = fx.now
	fx.death("T", cause)
	var strip := Image.create_empty(CELL.x * 24, CELL.y, false, Image.FORMAT_RGB8)
	var next_t: float = t_ev
	for ci in 24:
		while fx.now + 1e-4 < next_t:
			_step()
			await RenderingServer.frame_post_draw
		var img := _grab()
		if img != null:
			strip.blit_rect(img, Rect2i(Vector2i.ZERO, CELL), Vector2i(ci * CELL.x, 0))
		next_t += 1.0 / float(FPS)
	var name := "%s_c%d.png" % [label, r]
	strip.save_png(out.path_join(name))
	print("[death_strip] %s r=%d t=%.2f cells=%d %s" % [label, r, t_ev, 24, name])


func _reset() -> void:
	for id in ["T"]:
		if fx.ships.has(id):
			fx.remove_ship(id)
	for n in world.get_children():
		if n is Node3D and String(n.name).begins_with("ship_"):
			n.queue_free()
	ship = null


func _ship(id: String, fac: String, cls: String) -> Node3D:
	var sv: Node3D = SV.new()
	sv.name = "ship_" + id
	world.add_child(sv)
	sv.setup({"id": id, "fac": fac, "cls": cls, "facing": 0, "hp": 100, "maxHp": 100, "size": 1.0}, Vector3.ZERO, true)
	var info := {"faction": fac, "cls": cls, "size": 1.0, "squadron": false, "flagship": false, "code": sv.code}
	if not sv.a4:
		info["meshes"] = sv.meshes
	fx.add_ship(id, sv, info)
	sv.process_mode = Node.PROCESS_MODE_DISABLED   # hold the hull still, as the look bench parks ShipView
	return sv


func _step() -> void:
	fx.step(1.0 / 60.0)
	if wld != null and wld.has_method("step"):
		wld.step(1.0 / 60.0)


func _wait(s: float) -> void:
	var t: float = fx.now + s
	while fx.now + 1e-4 < t:
		_step()
		await RenderingServer.frame_post_draw


func _grab() -> Image:
	if PG.stop_if_any():
		return null
	var img := vp.get_texture().get_image()
	if img == null or img.is_empty():
		return null
	var crop := Vector2i(384, 216) if cam.r > 100.0 else Vector2i(1152, 648)
	var at := Vector2i((W - crop.x) / 2, (H - crop.y) / 2)
	var c := img.get_region(Rect2i(at, crop))
	c.convert(Image.FORMAT_RGB8)
	if crop != CELL:
		c.resize(CELL.x, CELL.y, Image.INTERPOLATE_LANCZOS)
	return c
