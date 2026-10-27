extends Node
# Effects gallery (G4): the six flagships at game scale, built by G2's own ShipView from res://gen (so they look exactly
# as in battle), with a scripted reel that plays every weapon look on shields and hulls, the damage ladder, shield
# breaks, deaths and wrecks, on the dead-star board with its backdrop.
#
# Run (from the repo's godot folder; Ryan's PC: tools/pc/jobs/g4_gallery_*.bat):
#   godot --path . res://fx/gallery/gallery.tscn -- [options]
#   (no option)            free viewing: the reel loops, 1 overview, 2 orbit, R restarts, F toggles reduce flashing, Esc quits
#   --shots DIR            fixed-angle stills on the reel's fixed clock, then quit (give the engine --fixed-fps 60)
#   --bench OUT.json       the reel with an orbiting camera, frame times measured, then quit
#   --res WxH              render size (default 1920x1080; 3840x2160 for 4K)
#   --quality max|high|low --tonemap agx|aces --reduce-flashing --no-fx --no-world --no-physics --only a,b --seconds S
#   --lo                   force the game-detail hulls even where max-detail 8K flagships exist

const FX := preload("res://fx/fx.gd")
const LOOK := preload("res://render/look.gd")
const SV := preload("res://render/ship_view.gd")
const WORLD_PATH := "res://world/world.gd"

const FLAGS := [
	{"id": "V", "fac": "voidsworn", "cls": "Dreadnought", "pos": Vector3(-46, 0, 30)},
	{"id": "H", "fac": "hegemony", "cls": "Super-dreadnought", "pos": Vector3(0, 0, 30)},
	{"id": "C", "fac": "corsair", "cls": "Battle-barge", "pos": Vector3(46, 0, 30)},
	{"id": "B", "fac": "chorus", "cls": "Bio-titan", "pos": Vector3(-46, 0, -30)},
	{"id": "I", "fac": "ithar", "cls": "Ark", "pos": Vector3(0, 0, -30)},
	{"id": "D", "fac": "deathless", "cls": "Tomb-ark", "pos": Vector3(46, 0, -30)},
]
const REEL_LEN := 26.0

var args := {}
var res := Vector2i(1920, 1080)
var vp: SubViewport
var world: Node3D
var cam: Camera3D
var env: Environment
var key: DirectionalLight3D
var fill: DirectionalLight3D
var fx = null
var wld = null
var ships := {}
var clock := 0.0
var frame_n := 0
var events: Array = []
var ev_i := 0
var mode := "view"
var started := false
var shot_queue: Array = []
var shots_dir := ""
var pending := 0
var cam_mode := "overview"
var bench_ms: PackedFloat64Array = []
var gpu_sum := 0.0
var gpu_n := 0
var bench_last := 0
var warm := 2.0
var notes: PackedStringArray = []
var quality := "max"
var pc0 := {}
var worst_t := 0.0
var worst_ms := 0.0
var holding := false
var moments := {}
var waiting: Array = []      # stills waiting for their moment: [name, file, eye, look, fov, offset]


func _ready() -> void:
	_parse_args()
	if args.has("shots"):
		mode = "shots"
	elif args.has("bench"):
		mode = "bench"
	quality = String(args.get("quality", "max"))
	if args.has("res"):
		var p := String(args["res"]).split("x")
		res = Vector2i(int(p[0]), int(p[1]))
	if args.has("no-physics"):
		PhysicsServer3D.set_active(false)
	_build_view()
	_build_env()
	_build_ships()
	if not args.has("no-world") and ResourceLoader.exists(WORLD_PATH):
		wld = load(WORLD_PATH).new()
		wld.name = "World"
		world.add_child(wld)
		wld.build_gallery(env, cam, {"quality": quality, "deadstar": Vector3(-130, -26, -165)})
	if not args.has("no-fx"):
		fx = FX.new()
		fx.name = "FX"
		world.add_child(fx)
		fx.manual = true
		fx.setup({"camera": cam if mode != "shots" else null, "quality": quality, "reduce_flashing": args.has("reduce-flashing"),
			"starboard_z": 1})
		if wld != null:
			fx.well = wld.well_position()
		for s in FLAGS:
			var sv: Node3D = ships[s["id"]]
			fx.add_ship(s["id"], sv, {"faction": s["fac"], "cls": s["cls"], "size": 1.25, "flagship": true, "meshes": sv.meshes})
			for e in sv.engines:
				(e as Node3D).visible = false   # G2's placeholder engine glows give way to the fx engines
		# a squadron for the strike run: a small wing beside the Voidsworn
		_events()
	print("[gallery] mode=%s res=%dx%d quality=%s renderer=%s adapter=%s" % [mode, res.x, res.y, quality,
		RenderingServer.get_current_rendering_method(), RenderingServer.get_video_adapter_name()])
	await _frame_drawn()
	await _frame_drawn()
	if fx != null and not args.has("no-warmup"):
		var w0 := Time.get_ticks_msec()
		await fx.warmup(cam)
		notes.append("shader warm-up %d ms" % (Time.get_ticks_msec() - w0))
	started = true
	if mode == "shots":
		shots_dir = _abs(String(args["shots"]))
		DirAccess.make_dir_recursive_absolute(shots_dir)
		shot_queue = _shot_list()


func _parse_args() -> void:
	var a := OS.get_cmdline_user_args()
	var i := 0
	while i < a.size():
		var k: String = a[i]
		if k.begins_with("--"):
			k = k.substr(2)
			if i + 1 < a.size() and not a[i + 1].begins_with("--"):
				args[k] = a[i + 1]
				i += 1
			else:
				args[k] = true
		i += 1


func _abs(p: String) -> String:
	if p.is_absolute_path():
		return p
	return ProjectSettings.globalize_path("res://").path_join(p).simplify_path()


func _build_view() -> void:
	vp = SubViewport.new()
	vp.size = res
	vp.msaa_3d = Viewport.MSAA_4X if quality != "low" else Viewport.MSAA_DISABLED
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(vp)
	var show := TextureRect.new()
	show.texture = vp.get_texture()
	show.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	show.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	show.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(show)
	world = Node3D.new()
	vp.add_child(world)
	cam = Camera3D.new()
	cam.fov = 40.0
	cam.near = 0.5
	cam.far = 4000.0
	world.add_child(cam)
	cam.current = true


func _build_env() -> void:
	env = Environment.new()
	var man: Dictionary = SV.manifest()
	if man.has("sky") and String(man["sky"]) != "" and ResourceLoader.exists(String(man["sky"])):
		var sky_res = load(String(man["sky"]))
		if sky_res is Sky:
			env.sky = sky_res
			env.background_mode = Environment.BG_SKY
		elif sky_res is Texture2D:
			var pm := PanoramaSkyMaterial.new()
			pm.panorama = sky_res
			var sky := Sky.new()
			sky.sky_material = pm
			env.sky = sky
			env.background_mode = Environment.BG_SKY
	if env.sky == null:
		env.background_mode = Environment.BG_COLOR
		env.background_color = Color(0.004, 0.005, 0.008)
	var we := WorldEnvironment.new()
	we.environment = env
	world.add_child(we)
	key = DirectionalLight3D.new()
	world.add_child(key)
	fill = DirectionalLight3D.new()
	world.add_child(fill)
	LOOK.apply(env, key, fill, {"quality": quality, "tonemap": String(args.get("tonemap", LOOK.TONEMAP))})
	notes.append("tonemap %s" % String(args.get("tonemap", LOOK.TONEMAP)))


func _build_ships() -> void:
	for s in FLAGS:
		var sv: Node3D = SV.new()
		sv.name = s["id"]
		world.add_child(sv)
		sv.setup({"id": s["id"], "fac": s["fac"], "cls": s["cls"], "facing": 0, "hp": 100, "maxHp": 100}, s["pos"], not args.has("lo"))
		for m in sv.meshes:
			var mi := m as MeshInstance3D
			for si in mi.mesh.get_surface_count():
				var mat := mi.get_active_material(si)
				if mat is BaseMaterial3D:
					mi.set_surface_override_material(si, LOOK.hull(mat, s["fac"], true))
		ships[s["id"]] = sv


# ---------------------------------------------------------------- the reel

func _ev(t: float, f: Callable) -> void:
	events.append([t, f])


func _hit(shield: bool, sec := "mid", crit := false) -> Dictionary:
	return {"shield": 8 if shield else 0, "hull": 0 if shield else 9, "section": sec, "crit": crit}


func _mark(name: String, t: float) -> void:
	moments[name] = t
	var keep: Array = []
	for w in waiting:
		if w[0] == name:
			shot_queue.append([t + float(w[5]), w[1], w[2], w[3], w[4]])
		else:
			keep.append(w)
	waiting = keep
	shot_queue.sort_custom(func(a, b): return float(a[0]) < float(b[0]))


# fire a volley and mark the moment its shot `which` lands (on the effect clock)
func _vol(name: String, a: String, kind: String, t: String, opts: Dictionary, which := 0) -> void:
	var r: Dictionary = fx.volley(a, kind, t, opts)
	var imp: Array = r["impacts"]
	if name != "" and imp.size() > 0:
		_mark(name + "_fire", fx.now)
		_mark(name, fx.now + float(imp[mini(which, imp.size() - 1)]))


func _events() -> void:
	events.clear()
	ev_i = 0
	# broadsides on shields and hulls, every faction look in turn (A5 sheets 3)
	_ev(1.0, func(): _vol("macro", "V", "battery", "B", {"weapon_id": "hbattery", "shots": [true, true, true, false, true], "hits": [_hit(false, "mid"), _hit(false, "prow"), _hit(false, "mid", true), _hit(false, "eng")]}, 1))
	_ev(1.2, func(): _vol("prism", "I", "battery", "H", {"weapon_id": "shard", "shots": [true, true, true], "hits": [_hit(true), _hit(true), _hit(true)]}, 1))
	_ev(2.0, func(): _vol("plasma", "H", "battery", "D", {"weapon_id": "hturbo", "shots": [true, true, true], "hits": [_hit(false, "mid"), _hit(false, "prow"), _hit(false, "eng")]}, 1))
	_ev(2.2, func(): _vol("scatter", "C", "battery", "I", {"weapon_id": "scatter", "shots": [true, true, false, true, true], "hits": [_hit(true), _hit(true), _hit(true), _hit(true)]}))
	_ev(3.0, func(): _vol("rockets", "C", "torp", "V", {"weapon_id": "torp", "shots": [true, true], "hits": [_hit(true), _hit(true)], "pd": 1}))
	_ev(3.2, func(): _vol("las", "V", "battery", "D", {"weapon_id": "turret", "shots": [true, true], "hits": [_hit(false), _hit(false)]}))
	_ev(4.0, func(): _vol("lance", "V", "lance", "B", {"weapon_id": "lance", "shots": [true], "hits": [_hit(false, "prow")]}))
	_ev(5.0, func(): _vol("ion", "H", "lance", "I", {"weapon_id": "ion", "shots": [true], "hits": [_hit(true)]}))
	_ev(5.5, func(): _vol("gauss", "D", "gauss", "H", {"weapon_id": "gauss", "shots": [true, true, true], "hits": [_hit(false, "mid"), _hit(false, "mid"), _hit(false, "eng")]}))
	_ev(6.5, func(): _vol("spine", "B", "bio", "C", {"weapon_id": "bioplasma", "shots": [true, true], "hits": [_hit(false, "mid"), _hit(false, "prow")]}))
	_ev(6.7, func(): _vol("pulsar", "I", "lance", "V", {"weapon_id": "pulsar", "shots": [true, true], "hits": [_hit(true), _hit(true)]}))
	_ev(7.5, func(): _vol("doom", "D", "lance", "I", {"weapon_id": "doom", "shots": [true], "hits": [_hit(false, "mid", true)]}))
	_ev(7.6, func(): _vol("flak", "H", "flak", "B", {"weapon_id": "flak", "shots": [true, true, true]}, 1))
	_ev(7.7, func(): _vol("chaff", "C", "flak", "D", {"weapon_id": "flak", "shots": [true, true, true]}))
	_ev(8.5, func(): _vol("torp", "V", "torp", "D", {"weapon_id": "torp", "shots": [true], "hits": [_hit(false, "mid", true)]}))
	_ev(8.6, func(): _vol("tendril", "B", "bio", "H", {"weapon_id": "tendril", "shots": [true], "hits": [_hit(true)]}))
	_ev(9.0, func(): _vol("craft", "V", "sq", "I", {"weapon_id": "guns", "shots": [true, true, true], "hits": [_hit(true), _hit(true), _hit(true)]}, 1))
	_ev(9.2, func(): _vol("spores_sq", "B", "sq", "C", {"weapon_id": "sporeb", "shots": [true, true]}))
	_ev(9.4, func(): _vol("gflak", "D", "flak", "V", {"weapon_id": "gsentry", "shots": [true, true, true]}))
	_ev(9.6, func(): _vol("mflak", "I", "flak", "C", {"weapon_id": "flak", "shots": [true, true, true]}))
	_ev(9.8, func(): _vol("spores", "B", "flak", "H", {"weapon_id": "spores", "shots": [true, true, true]}))
	_ev(11.0, func(): _vol("star", "I", "torp", "B", {"weapon_id": "startorp", "shots": [true], "hits": [_hit(false, "mid")]}))
	_ev(11.2, func(): _vol("auto", "H", "battery", "C", {"weapon_id": "autocannon", "shots": [true, true, true], "hits": [_hit(true), _hit(true), _hit(true)]}))
	# the damage ladder on the barge and the Hegemony, one stage every 1.6 s; burning from stage 3
	for st in 5:
		var t := 1.5 + st * 1.6
		var hp: float = [1.0, 0.7, 0.5, 0.3, 0.12][st]
		_ev(t, func():
			fx.sync_ship("C", _unit(hp, st >= 3))
			_mark("stage%d" % st, fx.now))
		_ev(t + 0.4, func(): fx.sync_ship("H", _unit(minf(1.0, hp + 0.15), false, st == 4)))
	# shield breaks, each faction its own way
	_ev(10.0, func():
		fx.shield_break("V", 1)
		_mark("break_V", fx.now))
	_ev(10.6, func():
		fx.shield_break("H", 1)
		_mark("break_H", fx.now))
	_ev(11.2, func():
		fx.shield_break("C", 1)
		_mark("break_C", fx.now))
	_ev(11.8, func():
		fx.shield_break("I", 1)
		_mark("break_I", fx.now))
	# deaths: the real hulls break apart and drift as burning wrecks
	_ev(12.5, func():
		var td: float = fx.death("B", "big")
		_mark("death_big_cook", fx.now + td * 0.55)
		_mark("death_big", fx.now + td - 0.6))
	_ev(14.5, func(): _mark("death_flay", fx.now + fx.death("D", "flay") - 0.6))
	_ev(16.5, func(): _mark("death_cut", fx.now + fx.death("H", "cut") - 0.6))
	events.sort_custom(func(a, b): return float(a[0]) < float(b[0]))


func _unit(hp: float, burning: bool, eng_broken := false) -> Dictionary:
	return {"hp": 100.0 * hp, "maxHp": 100.0, "burning": burning, "sh": [5, 5, 5, 5],
		"sec": {"prow": {"hp": 30.0 * hp, "max": 30.0}, "mid": {"hp": 40.0 * hp, "max": 40.0}, "eng": {"hp": 30.0 * hp, "max": 30.0, "broken": eng_broken}}}


# ---------------------------------------------------------------- cameras

func _ship_c(id: String) -> Vector3:
	var sv: Node3D = ships[id]
	return sv.global_position


func _cam_at(eye: Vector3, look: Vector3, fov := 40.0) -> void:
	cam.fov = fov
	cam.global_position = eye
	cam.look_at(look, Vector3.UP)


func _set_cam(name: String, t: float) -> void:
	match name:
		"overview":
			_cam_at(Vector3(0, 78, 150), Vector3(0, -6, 0))
		"orbit":
			var a := deg_to_rad(200.0 + 120.0 * clampf(t / REEL_LEN, 0.0, 1.0))
			_cam_at(Vector3(sin(a) * 160.0, 72.0, cos(a) * 160.0), Vector3(0, -6, 0))
		_:
			pass


# A camera beside a firing line, so the attacker, the shot and the target are all in frame: eye and look for a line a->b,
# looking at the point `frac` along it, from `dist` away on the camera's side, `h` up.
func _side(a: Vector3, b: Vector3, frac: float, dist: float, h: float) -> Array:
	var d := (b - a).normalized()
	var perp := d.cross(Vector3.UP).normalized()
	if perp.z < 0.0:
		perp = -perp
	var look := a.lerp(b, frac)
	return [look + perp * dist + Vector3(0, h, 0), look]


# A camera on one of a ship's damage anchors ("C:a1:front" or "C:b1:side"): straight on, or from the side and a little above.
func _anchor_cam(spec: String) -> Array:
	var parts := spec.split(":")
	var s = fx.ship(parts[0]) if fx != null else null
	if s == null or not s._anchors.has(parts[1]):
		var c := _ship_c(parts[0])
		return [c + Vector3(-8, 22, 24), c]
	var A: Dictionary = s._anchors[parts[1]]
	var p: Vector3 = s.to_world(A["p"])
	var n: Vector3 = s.dir_world(A["n"]).normalized()
	var t1 := n.cross(Vector3.UP if absf(n.y) < 0.9 else Vector3.RIGHT).normalized()
	var R: float = s.hull.L * 0.05
	if parts[2] == "side":
		return [p + n * R * 3.2 + t1 * R * 4.5 + Vector3(0, R * 1.5, 0), p]
	return [p + n * R * 6.5 + t1 * R * 1.5 + Vector3(0, R, 0), p]


# Stills: [time or moment name, file, eye, look, fov, offset]. A moment is when an effect really lands (marked by the
# reel on the effect clock), so every still catches its effect at the same instant on every run and machine.
func _shot_list() -> Array:
	var L := []
	var V := _ship_c("V")
	var H := _ship_c("H")
	var C := _ship_c("C")
	var B := _ship_c("B")
	var I := _ship_c("I")
	var D := _ship_c("D")
	L.append([0.8, "g01_overview_idle.png", Vector3(0, 78, 150), Vector3(0, -6, 0), 40.0, 0.0])
	L.append([0.8, "g02_engines_close.png", V + Vector3(-42, 14, 26), V + Vector3(-8, 0, 0), 38.0, 0.0])
	var s_g03 := _side(V, B, 0.55, 70.0, 26.0)
	L.append(["macro", "g03_macro_broadside.png", s_g03[0], s_g03[1], 42.0, 0.05])
	var s_g04 := _side(I, H, 0.75, 50.0, 18.0)
	L.append(["prism", "g04_prism_on_shield.png", s_g04[0], s_g04[1], 40.0, 0.06])
	var s_g05 := _side(H, D, 0.5, 70.0, 24.0)
	L.append(["plasma", "g05_plasma_bolts.png", s_g05[0], s_g05[1], 44.0, -0.3])
	L.append(["plasma", "g05b_plasma_on_hull.png", D + Vector3(-26, 18, 26), D, 38.0, 0.08])
	var s_g06 := _side(C, V, 0.45, 64.0, 24.0)
	L.append(["rockets", "g06_rockets_inbound.png", s_g06[0], s_g06[1], 40.0, -0.55])
	var s_g07 := _side(V, B, 0.5, 72.0, 20.0)
	L.append(["lance", "g07_lance_burn.png", s_g07[0], s_g07[1], 46.0, 0.3])
	L.append(["lance", "g07b_lance_trench.png", B + Vector3(-22, 12, 26), B + Vector3(0, 0, 6), 34.0, 0.6])
	var s_g08 := _side(H, I, 0.7, 54.0, 20.0)
	L.append(["ion", "g08_ion_on_shield.png", s_g08[0], s_g08[1], 40.0, 0.25])
	var s_g09 := _side(D, H, 0.6, 70.0, 22.0)
	L.append(["gauss", "g09_gauss_punch.png", s_g09[0], s_g09[1], 38.0, 0.06])
	var s_g10 := _side(B, C, 0.5, 70.0, 24.0)
	L.append(["spine", "g10_bio_spines.png", s_g10[0], s_g10[1], 40.0, -0.25])
	L.append(["spine", "g10b_bio_splash.png", C + Vector3(-24, 16, -30), C, 38.0, 0.25])
	var s_g11 := _side(D, I, 0.5, 54.0, 18.0)
	L.append(["doom", "g11_doom_arc.png", s_g11[0], s_g11[1], 44.0, 0.15])
	var s_g12 := _side(H, B, 0.7, 60.0, 24.0)
	L.append(["flak", "g12_flak.png", s_g12[0], s_g12[1], 40.0, 0.1])
	var s_g13a := _side(V, D, 0.55, 80.0, 30.0)
	L.append(["torp", "g13a_torpedo_flight.png", s_g13a[0], s_g13a[1], 46.0, -0.5])
	# framed on the side the torpedo comes in from (r2: the hit landed just below the frame)
	L.append(["torp", "g13_torpedo_hit.png", D + Vector3(-58, 34, 44), D.lerp(V, 0.12) + Vector3(0, -3, 0), 40.0, 0.12])
	var s_g14 := _side(V, I, 0.6, 64.0, 24.0)
	L.append(["craft", "g14_strike_craft.png", s_g14[0], s_g14[1], 42.0, -0.15])
	L.append(["stage4", "g15_breach_barge.png", C + Vector3(-8, 22, 24), C + Vector3(-2, 0, 0), 36.0, 0.4])
	L.append(["stage2", "g15a_dented_barge.png", C + Vector3(-8, 22, 24), C + Vector3(-2, 0, 0), 36.0, 0.5])
	# close on the barge's holes: the eye is worked out at the moment from where fx put each hole
	L.append(["stage3", "g15b_hole_close.png", "C:a1:front", "", 34.0, 1.2])
	L.append(["stage4", "g15c_breach_close.png", "C:a1:front", "", 34.0, 1.4])
	L.append(["stage4", "g15d_breach_side.png", "C:a1:side", "", 34.0, 1.4])
	L.append(["stage4", "g15e_bow_breach.png", "C:a2:front", "", 34.0, 1.4])
	L.append(["stage4", "g15f_edge_bite.png", "C:b1:side", "", 34.0, 1.4])
	L.append(["break_V", "g16_shield_break_voidsworn.png", V + Vector3(-10, 14, 42), V, 40.0, 0.12])
	L.append(["break_H", "g17_shield_break_hegemony.png", H + Vector3(-10, 14, 42), H, 40.0, 0.12])
	L.append(["break_C", "g18_shield_break_corsair.png", C + Vector3(-10, 14, 42), C, 40.0, 0.25])
	L.append(["break_I", "g19_shield_break_ithar.png", I + Vector3(-10, 22, 56), I, 40.0, 0.2])
	# the same breaks half a second on, when each faction's way of coming apart shows (r5)
	L.append(["break_V", "g16b_shield_break_voidsworn_later.png", V + Vector3(-10, 14, 42), V, 40.0, 0.5])
	L.append(["break_H", "g17b_shield_break_hegemony_later.png", H + Vector3(-10, 14, 42), H, 40.0, 0.5])
	L.append(["break_C", "g18b_shield_break_corsair_later.png", C + Vector3(-10, 14, 42), C, 40.0, 0.55])
	var s_g20 := _side(I, B, 0.5, 60.0, 24.0)
	L.append(["star", "g20_star_torpedo.png", s_g20[0], s_g20[1], 42.0, -0.4])
	L.append(["death_big_cook", "g21a_death_cookoff.png", B + Vector3(-40, 30, -50), B, 46.0, 0.0])
	L.append(["death_big", "g21_death_big.png", B + Vector3(-40, 30, -50), B, 46.0, 1.0])
	L.append(["death_big", "g21b_death_big_after.png", B + Vector3(-40, 30, -50), B, 46.0, 3.0])
	L.append(["death_flay", "g22_death_flay.png", D + Vector3(40, 26, -50), D, 46.0, 1.0])
	L.append(["death_cut", "g23_death_cut.png", H + Vector3(0, 40, 60), H, 46.0, 1.0])
	L.append([26.0, "g24_wrecks_drifting.png", Vector3(0, 70, 140), Vector3(0, -6, -10), 42.0, 0.0])
	var only := String(args.get("only", ""))
	if only != "":
		var keep := []
		for s in L:
			for o in only.split(","):
				if String(s[1]).contains(o):
					keep.append(s)
					break
		L = keep
	var timed := []
	for s in L:
		if s[0] is String:
			waiting.append(s)
		else:
			timed.append([float(s[0]), s[1], s[2], s[3], s[4]])
	timed.sort_custom(func(a, b): return float(a[0]) < float(b[0]))
	return timed


# ---------------------------------------------------------------- frame loop

func _process(delta: float) -> void:
	if not started or holding:
		return
	var dt := delta
	if mode == "shots":
		dt = 1.0 / 60.0
	clock += dt
	frame_n += 1
	if fx != null:
		fx.step(dt)
		clock = fx.now
	while fx != null and ev_i < events.size() and float(events[ev_i][0]) <= clock:
		(events[ev_i][1] as Callable).call()
		ev_i += 1
	if wld != null:
		wld.step(dt)
	match mode:
		"shots":
			_process_shots()
		"bench":
			_process_bench()
		_:
			_set_cam(cam_mode, fmod(clock, REEL_LEN))
			if clock > REEL_LEN + 2.0:
				get_tree().reload_current_scene()


func _unhandled_input(ev: InputEvent) -> void:
	if ev is InputEventKey and ev.pressed:
		match (ev as InputEventKey).keycode:
			KEY_1: cam_mode = "overview"
			KEY_2: cam_mode = "orbit"
			KEY_R: get_tree().reload_current_scene()
			KEY_F:
				if fx != null:
					fx.reduce_flashing = not fx.reduce_flashing
			KEY_ESCAPE: get_tree().quit()


func _process_shots() -> void:
	if shot_queue.is_empty():
		if pending == 0 and (waiting.is_empty() or clock > REEL_LEN + 4.0):
			for w in waiting:
				print("[gallery] no moment %s for %s" % [w[0], w[1]])
			get_tree().quit()
		return
	var s: Array = shot_queue[0]
	if clock + 1e-4 >= float(s[0]):
		# every still due at this moment: hold the clock while the camera moves between them
		holding = true
		while not shot_queue.is_empty() and float(shot_queue[0][0]) <= clock + 1e-4:
			var q: Array = shot_queue.pop_front()
			if fx != null:
				for sid in fx.ships:
					fx.ships[sid].flush_damage(fx)
			if q[2] is String:
				var ec: Array = _anchor_cam(q[2])
				_cam_at(ec[0], ec[1], q[4])
			else:
				_cam_at(q[2], q[3], q[4])
			await _capture(shots_dir.path_join(q[1]))
		holding = false


func _capture(path: String) -> void:
	pending += 1
	await _frame_drawn()
	await _frame_drawn()
	var img := vp.get_texture().get_image()
	if img != null and not img.is_empty():
		img.convert(Image.FORMAT_RGB8)
		img.save_png(path)
		print("[gallery] wrote %s at t=%.2f" % [path, clock])
	pending -= 1


func _process_bench() -> void:
	_set_cam("orbit", clock)
	var now := Time.get_ticks_usec()
	if clock < warm:
		bench_last = now
		return
	if bench_ms.is_empty() and gpu_n == 0:
		RenderingServer.viewport_set_measure_render_time(vp.get_viewport_rid(), true)
		for m in ["DRAW", "SURFACE", "SPECIALIZATION", "MESH"]:
			pc0[m] = Performance.get_monitor(Performance.get("PIPELINE_COMPILATIONS_" + m))
	var fms := (now - bench_last) / 1000.0
	if fms > worst_ms:
		worst_ms = fms
		worst_t = clock
	bench_ms.append(fms)
	bench_last = now
	var g := RenderingServer.viewport_get_measured_render_time_gpu(vp.get_viewport_rid())
	if g > 0.0:
		gpu_sum += g
		gpu_n += 1
	if clock >= float(args.get("seconds", REEL_LEN)):
		_finish_bench()


func _finish_bench() -> void:
	started = false
	var s := bench_ms.duplicate()
	s.sort()
	var n := s.size()
	var tot := 0.0
	for v in s:
		tot += v
	var k := maxi(1, int(ceil(n * 0.01)))
	var worst := 0.0
	for i in k:
		worst += s[n - 1 - i]
	worst /= k
	var out := {"mode": "gallery", "quality": quality, "fx": fx != null, "world": wld != null, "physics": not args.has("no-physics"),
		"tonemap": String(args.get("tonemap", LOOK.TONEMAP)), "width": res.x, "height": res.y, "frames": n,
		"avg_ms": snappedf(tot / maxf(n, 1), 0.001), "p99_ms": snappedf(worst, 0.001), "max_ms": snappedf(s[n - 1] if n > 0 else 0.0, 0.001),
		"gpu_ms": snappedf(gpu_sum / maxf(gpu_n, 1), 0.001), "particles": fx.particles_emitted() if fx != null else 0,
		"adapter": RenderingServer.get_video_adapter_name(), "worst_frame_at": snappedf(worst_t, 0.01), "notes": "; ".join(notes)}
	for m in pc0:
		out["pipeline_compiles_" + String(m).to_lower()] = Performance.get_monitor(Performance.get("PIPELINE_COMPILATIONS_" + m)) - float(pc0[m])
	var path := _abs(String(args["bench"]))
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(JSON.stringify(out, "  ") + "\n")
	f.close()
	print("[gallery] ", JSON.stringify(out))
	get_tree().quit()


func _frame_drawn() -> Signal:
	return RenderingServer.frame_post_draw
