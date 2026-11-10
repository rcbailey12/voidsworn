extends Node3D
# The battle world (API in godot/fx/API.md section 9). F4 feel pass rebuild (Ryan, Nov 1: "Background asteroids and
# imagery still needs a serious upgrade"), to the grand space-opera bar:
#   - the setting (world_sky.gd): the sector's region of space and the enemy faction pick the sky and the planet, so the
#     battles of one sector share them and each battle only turns the view a little;
#   - the sky: a ray-marched nebula baked on the GPU once per setting (world_bake.gd), pin-sharp stars per pixel, the
#     galaxy's band, the system's sun where the key light comes from;
#   - the system: a planet with atmosphere, clouds, night lights, rings and moons (world_planet.gd), placed beyond the
#     far side of the board where the default camera sees it;
#   - asteroids (world_rocks.gd, shapes from world/tools/rockgen.py): blockers on rock hexes, debris on debris hexes, a
#     scatter round the board's edge, a deep field and (on belt maps) a belt stream far below, a few mountain-sized rocks,
#     all holding their seeded poses, far ones sinking into the sky's haze; dust specks for depth when the camera moves;
#   - nebula and ion-storm clouds on their hexes; the dead star (R2, R24) with lensing and its accretion disc.
#
# Kept from G4's rules (BACKLOG section 3): no distant traffic ships; nothing on the board but blockers and debris on
# their own hexes; no rim wall; no two moons alike; mountains and the deep field keep out of the planet's disc.

const WS := preload("res://world/world_shaders.gd")
const SKY := preload("res://world/world_sky.gd")
const PL := preload("res://world/world_planet.gd")
const WR := preload("res://world/world_rocks.gd")
const BAKER := preload("res://world/world_bake.gd")
const FLOOK := preload("res://fx/faction_look.gd")
const BL := preload("res://world/board_look.gd")
const LIV := preload("res://world/world_living.gd")
const SUN := Vector3(0.45, 0.70, 0.55)   # toward the sun: the battle's key light shines along -SUN (look.gd KEY_DIR)
const BACKDROP_ROCK_ANGLE := 0.05

var quality := "max"
var notes: PackedStringArray = []
var setting := {}
var _spin: Array = []        # [node, axis, rate]
var _well := Vector3.INF
var _rng := RandomNumberGenerator.new()
var _planet_dir := Vector3.ZERO
var _planet_ang := 0.0
var _planet_pos := Vector3.ZERO
var _planet_R := 0.0
var _backdrop_radii := {}    # mesh radii about the shader's rotation origin
var _ring_n := Vector3.ZERO      # the planet's ring plane normal (zero: no rings)
# degrees about x. F4: the default camera looks down 34 degrees from +z; a tilt of -25 shows it the disc nearly edge on
# (about 9 degrees), the classic lensed look (the far side of the disc bent up over the shadow); -12 showed it face on.
var disc_tilt := -25.0
var _baker: Node = null
var _sky_mat: ShaderMaterial = null
var _look := {}
var _mats := {}
var _batch = null
var _center := Vector3.ZERO
var _lo := Vector3.ZERO
var _hi := Vector3.ZERO
var _yaw := 0.0
var _sky_tex: Texture2D = null
var _old_clouds: Array = []     # today's faint cloud billboards on nebula and storm hexes
var _under_mat: ShaderMaterial = null
var _terr_pts := {"neb": [], "storm": [], "debris": []}   # board positions of those hexes (the living look builds on them)
var _rock_kind := "stone"
var _fac := "voidsworn"
var _debris_ships: Array = []
var _living = null              # world_living.gd: B's gas, storm, debris and well (built the first time a look needs it)
var _pano: Texture2D = null     # the battle's painted panorama (battle.gd passes it; the dead-star board shows it, R2)
var pending_bakes := 0


# A sector's map and battles use the same inputs, including rival encounters and
# dead-star boards. Battle randomness changes the viewing angle only.
static func sector_setting(run: Dictionary) -> Dictionary:
	var map: Dictionary = run["map"] if run.get("map") is Dictionary else {}
	var biome: Dictionary = map["biome"] if map.get("biome") is Dictionary else {}
	return SKY.setting(biome, str(map.get("fac", "voidsworn")), "open", false, 0)


func prepare_sector(env: Environment, run: Dictionary, q: String) -> void:
	quality = q
	setting = sector_setting(run)
	_yaw = 0.0
	_baker = BAKER.service(get_tree())
	_make_sky(env)
	# Prime the surface even if this map rolled no planet stops.
	surface_material(SUN.normalized())


func surface_material(sun: Vector3) -> ShaderMaterial:
	var P: Dictionary = setting["planet"]
	var m := ShaderMaterial.new()
	var sh := Shader.new()
	sh.code = PL.SPHERE
	m.shader = sh
	m.set_shader_parameter("sun", sun)
	m.set_shader_parameter("atmo", P["atmo"])
	m.set_shader_parameter("flat_col", P["a"])
	var size := _planet_size()
	var seed := int(setting["seed"])
	_bake_planet(m, "planet|%d|%d|%d" % [int(P["kind"]), seed, size.x], P, seed, size)
	return m


func _planet_size() -> Vector2i:
	if OS.has_environment("VS_WORLD_PREVIEW"): return Vector2i(512, 256)
	return BAKER.PLANET_SIZE


func wait_ready() -> void:
	# Hard cap (Opus review, Nov 3): a bake that never finishes must never hold the loading cover.
	var t0 := Time.get_ticks_msec()
	while pending_bakes > 0 and Time.get_ticks_msec() - t0 < 20000: await get_tree().process_frame


func _sky_into(m: ShaderMaterial) -> void:
	if _sky_tex == null or m == null:
		return
	m.set_shader_parameter("sky_tex", _sky_tex)
	m.set_shader_parameter("has_sky", 1.0)
	m.set_shader_parameter("turn", Basis(Vector3.UP, -_yaw))


func well_position() -> Vector3:
	return _well


func step(dt: float) -> void:
	for s in _spin:
		var n: Node3D = s[0]
		if is_instance_valid(n):
			n.rotate(s[1], float(s[2]) * dt)


# ---------------------------------------------------------------- battle build (API.md 9)

func build(view: Dictionary, opts: Dictionary) -> void:
	var t0 := Time.get_ticks_usec()
	quality = String(opts.get("quality", "max"))
	if RenderingServer.get_current_rendering_method() == "gl_compatibility":
		quality = "low"
	var biome: Dictionary = opts.get("biome", {}) if opts.get("biome") is Dictionary else {}
	var fac := String(opts.get("fac", "voidsworn"))
	var hw: Callable = opts["hex_world"]
	var bseed := int(opts.get("seed", hash(str(view.get("round", 0)) + fac)))
	_rng.seed = bseed
	var map: Dictionary = view.get("map", {}) if view.get("map") is Dictionary else {}
	var terrain: Dictionary = view.get("terrain", {})
	# board bounds from the hexes in play
	var lo := Vector3(1e9, 0, 1e9)
	var hi := Vector3(-1e9, 0, -1e9)
	for k in terrain.keys():
		var qr := String(k).split(",")
		var p: Vector3 = hw.call(int(qr[0]), int(qr[1]))
		lo = lo.min(p)
		hi = hi.max(p)
	for u in view.get("units", []):
		var p: Vector3 = hw.call(int(u["q"]), int(u["r"]))
		lo = lo.min(p)
		hi = hi.max(p)
	if lo.x > hi.x:
		lo = Vector3(-150, 0, -100)
		hi = Vector3(150, 0, 100)
	# the board's full extent: terrain lists only special hexes, so widen to at least the camera's bounds when given
	var cam = opts.get("camera", null)
	if cam != null and "bounds" in cam and cam.bounds is Vector2:
		var b: Vector2 = cam.bounds
		lo = lo.min(Vector3(-b.x, 0, -b.y))
		hi = hi.max(Vector3(b.x, 0, b.y))
	_lo = lo
	_hi = hi
	_center = (lo + hi) * 0.5
	var deadstar: bool = map.has("deadstar") and map["deadstar"] != null
	var mk := map_kind(view)
	# The feature direction used to contain the battle yaw. That changed the bake
	# hash on every encounter, even when the sector's seed stayed the same.
	setting = opts.get("sector_setting", SKY.setting(biome, fac, mk, deadstar, 0)).duplicate(true)
	setting["yaw"] = SKY.setting(biome, fac, mk, deadstar, bseed)["yaw"]
	setting["deadstar"] = deadstar
	setting["map"] = mk
	_yaw = float(setting["yaw"])
	_baker = BAKER.service(get_tree())
	var env: Environment = opts.get("environment", null)
	if opts.get("pano") is Texture2D:
		_pano = opts["pano"]
	elif env != null and env.sky != null and env.sky.sky_material is ShaderMaterial and (env.sky.sky_material as ShaderMaterial).get_shader_parameter("pano") is Texture2D:
		_pano = (env.sky.sky_material as ShaderMaterial).get_shader_parameter("pano")
	if env != null:
		_make_sky(env)
	if deadstar:
		var ds: Dictionary = map["deadstar"]
		dead_star(hw.call(int(ds["q"]), int(ds["r"])) + Vector3(0, -10, 0), 1.0)
		if opts.has("fx") and opts["fx"] != null:
			opts["fx"].well = _well
	_look = {"board_c": _center, "haze": setting["haze"], "haze_r": Vector2(420.0, 2800.0), "haze_max": 0.62, "quality": quality,
		"glow": Vector3(0.3, 0.75, 1.0)}
	if _well != Vector3.INF:
		_look["rim_pos"] = _well
	if not deadstar:
		system(mk != "planet")
	_batch = WR.Batch.new()
	var rock_kind := String(setting["rock"])
	var counts := {"rock": 0, "debris": 0, "neb": 0, "storm": 0}
	var clouds := {"neb": [], "storm": []}
	for k in terrain.keys():
		var qr := String(k).split(",")
		var p: Vector3 = hw.call(int(qr[0]), int(qr[1]))
		var t := String(terrain[k])
		match t:
			"rock": blocker(p, rock_kind)
			"debris":
				debris_field(p, rock_kind)
				_terr_pts["debris"].append(p)
			"neb", "storm":
				clouds[t].append(p)
				_terr_pts[t].append(p)
		if counts.has(t):
			counts[t] += 1
	for t in clouds:
		if not (clouds[t] as Array).is_empty():
			cloud_hexes(clouds[t], t, fac)
	fields(mk, rock_kind)
	var n_rocks: int = _batch.build(self, Callable(WR, "mesh"))
	dust(mk)
	wisps()
	underlay()
	notes.append("setting: %s region, %s map, %s rock, planet %d (%s), sky for %s" % [setting["region"], mk, rock_kind, int(setting["planet_i"]),
		["gas giant", "ice giant", "terran", "volcanic", "barren", "ice world"][int(setting["planet"]["kind"])], str(setting["fac"])])
	notes.append("rocks: %d in all (%d rock hexes, %d debris hexes); clouds on %d nebula and %d storm hexes; built in %.0f ms" % [n_rocks,
		counts["rock"], counts["debris"], counts["neb"], counts["storm"], (Time.get_ticks_usec() - t0) / 1000.0])
	_rock_kind = rock_kind
	_fac = fac
	add_to_group("vs_world")
	set_look()


# The board look trial (world/board_look.gd): the dark floor under the board, today's faint clouds, and B's living
# terrain (gas, storm, debris, the well) shown or hidden for the current look. Called by the board when the look changes.
func set_look() -> void:
	var sp := BL.spec()
	if _under_mat != null:
		_under_mat.set_shader_parameter("vis", float(sp["underlay"]))
	for c in _old_clouds:
		if is_instance_valid(c):
			(c as Node3D).visible = bool(sp["old_clouds"])
	if bool(sp["living"]) and _living == null:
		var t0 := Time.get_ticks_usec()
		_living = LIV.new()
		_living.name = "Living"
		add_child(_living)
		_living.build(self)
		if not _debris_ships.is_empty(): _living.use_ship_debris(_debris_ships)
		notes.append("living terrain built in %.0f ms" % ((Time.get_ticks_usec() - t0) / 1000.0))
	if _living != null:
		_living.visible = bool(sp["living"])
		_living.set_gas_k(float(sp["gas_k"]))


# The map's kind from what is on it (the rules do not hand the map name to the scene): planet, station, graveyard (wrecks),
# storm, belt (many rocks), open.
static func map_kind(view: Dictionary) -> String:
	var map: Dictionary = view.get("map", {}) if view.get("map") is Dictionary else {}
	if map.get("planet") is Dictionary:
		return "planet"
	if map.get("station") != null and map.has("station"):
		return "station"
	if map.get("wrecks") != null and map.has("wrecks"):
		return "graveyard"
	var n_rock := 0
	var n_storm := 0
	for k in view.get("terrain", {}):
		var t := String(view["terrain"][k])
		if t == "rock":
			n_rock += 1
		elif t == "storm":
			n_storm += 1
	if n_storm >= 6:
		return "storm"
	if n_rock >= 14:
		return "belt"
	return "open"


func build_gallery(env: Environment, cam: Camera3D, opts: Dictionary) -> void:
	quality = String(opts.get("quality", "max"))
	if RenderingServer.get_current_rendering_method() == "gl_compatibility":
		quality = "low"
	_rng.seed = 7
	_lo = Vector3(-120, 0, -70)
	_hi = Vector3(120, 0, 70)
	_center = Vector3.ZERO
	setting = SKY.setting({"rock": "carbon", "planet": 5}, "corsair", "open", true, 7)
	_baker = BAKER.service(get_tree())
	_make_sky(env)
	disc_tilt = -24.0
	dead_star(opts.get("deadstar", Vector3(0, -20, -150)), 1.0)
	_look = {"board_c": _center, "haze": setting["haze"], "haze_r": Vector2(420.0, 2800.0), "haze_max": 0.62, "quality": quality, "rim_pos": _well}
	_batch = WR.Batch.new()
	for i in 3:
		blocker(Vector3(-40 + i * 70, -2, -95 + (i % 2) * 20), ["stone", "ice", "crystal"][i])
	fields("open", "carbon")
	_batch.build(self, Callable(WR, "mesh"))
	dust("open")


# ---------------------------------------------------------------- sky

func _make_sky(env: Environment) -> void:
	var m := ShaderMaterial.new()
	var sh := Shader.new()
	sh.code = SKY.SKY
	m.shader = sh
	var lamps: Array = SKY.lamps(setting)
	var lc: Array = []
	var lr := RandomNumberGenerator.new()
	lr.seed = int(setting["seed"]) + 9
	for k in lamps.size():
		var c: Vector3 = (setting["c3"] as Vector3).lerp(Vector3(0.85, 0.92, 1.0), lr.randf_range(0.3, 0.9))
		lc.append(c)
	m.set_shader_parameter("lamp", PackedVector4Array(lamps))
	m.set_shader_parameter("lamp_col", PackedVector3Array(lc))
	m.set_shader_parameter("seed", float(int(setting["seed"]) % 997))
	m.set_shader_parameter("band_n", setting["band_n"])
	m.set_shader_parameter("band", float(setting["band"]))
	m.set_shader_parameter("star_k", float(setting["stars"]))
	# Issue 232 E18/BD8 sheet: the live star occlusion floor, overridable for the density sweep (default 0.15).
	var sf := OS.get_environment("VS_STAR_FLOOR")
	m.set_shader_parameter("star_floor", float(sf) if sf != "" else 0.15)
	m.set_shader_parameter("sun_dir", SUN.normalized())
	m.set_shader_parameter("turn", Basis(Vector3.UP, -_yaw))
	# the panorama always rides on the sky material (shown only on the dead-star board): the battle keeps one Environment
	# and finds the painting on its sky's "pano" for the next battle
	if _pano != null:
		m.set_shader_parameter("pano", _pano)
	if bool(setting.get("deadstar", false)):
		# R2: the dead-star board keeps its painted sky; the gas goes over it at half strength, and no bright sun (the
		# painting's dim red dead sun is the light's source)
		m.set_shader_parameter("sun_k", 0.0)
		if _pano != null:
			m.set_shader_parameter("has_pano", 1.0)
			m.set_shader_parameter("neb_gain", 0.55)
	var h := float(ProjectSettings.get_setting("display/window/size/viewport_height", 1080))
	if is_inside_tree():
		h = maxf(h, float(get_viewport().get_visible_rect().size.y))
	m.set_shader_parameter("px", deg_to_rad(45.0) / h)
	var s := Sky.new()
	s.sky_material = m
	s.radiance_size = Sky.RADIANCE_SIZE_256
	s.process_mode = Sky.PROCESS_MODE_QUALITY
	env.sky = s
	env.background_mode = Environment.BG_SKY
	_sky_mat = m
	_bake_sky(lamps)


func _bake_sky(lamps: Array) -> void:
	pending_bakes += 1
	await _load_sky(lamps)
	pending_bakes -= 1


func _load_sky(lamps: Array) -> void:
	var size := Vector2i(4096, 2048) if quality != "low" else Vector2i(2048, 1024)
	if OS.has_environment("VS_WORLD_PREVIEW"):   # software rendering in the cloud: small bakes
		size = Vector2i(768, 384)
	var key := "sky|%d|%s|%d" % [int(setting["seed"]), setting["region"], size.x]
	var params := {"seed": float(int(setting["seed"]) % 997) * 0.37, "c1": setting["c1"], "c2": setting["c2"], "c3": setting["c3"],
		"neb": float(setting["neb"]), "cover": float(setting["cover"]), "dust": float(setting["dust"]), "band": float(setting["band"]),
		"band_n": setting["band_n"], "feature": setting["feature"], "steps": 48 if quality == "max" else (40 if quality == "high" else 26),
		"lamp": PackedVector4Array(lamps), "gal": PackedVector4Array(SKY.galaxies(setting))}
	var code := SKY.bake_code()
	var img: Image = await _baker.bake(key, code, params, size, 32)
	if img == null or _sky_mat == null: return
	var tex := BAKER.texture(img)
	_sky_mat.set_shader_parameter("neb_tex", tex)
	_sky_mat.set_shader_parameter("has_neb", 1.0)
	_sky_tex = tex
	for k in _mats: _sky_into(_mats[k])


# ---------------------------------------------------------------- the system: planet, rings, moons

const DIST := 3300.0


# The planet beyond the far side of the board, to one side and a little below the horizon, so the default battle camera
# (looking down about 34 degrees toward -z) has it filling an upper corner; moons elsewhere in that sky. with_planet off
# (planet maps, where the board has its own planet): the moons only.
func system(with_planet: bool) -> void:
	var P: Dictionary = setting["planet"]
	var r := RandomNumberGenerator.new()
	r.seed = int(setting["seed"]) * 11 + 3
	var turn := Basis(Vector3.UP, _yaw)
	var side := -1.0 if r.randf() < 0.5 else 1.0
	var giant: bool = int(P["kind"]) <= 1
	var ang := r.randf_range(0.15, 0.18) if giant else r.randf_range(0.11, 0.14)
	var az := side * r.randf_range(0.36, 0.5)
	var el := -r.randf_range(0.17, 0.22)
	var dir := turn * Vector3(sin(az) * cos(el), sin(el), -cos(az) * cos(el))
	var bake_q := _planet_size()
	if with_planet:
		_planet_dir = dir
		_planet_ang = ang
		var R := DIST * sin(ang)
		var tilt := Basis(Vector3(0, 0, 1), side * r.randf_range(0.18, 0.42)) * Basis(Vector3(1, 0, 0), r.randf_range(-0.25, 0.1))
		var node := _sphere(_center + dir * DIST, R, tilt, P, int(setting["seed"]), bake_q, r.randf_range(0.002, 0.006), Vector3.ONE, true)
		_planet_pos = node.position
		_planet_R = R
		if bool(P.get("rings", false)):
			_rings(node.position, R, tilt, P, r)
			_ring_n = (tilt * Vector3.UP).normalized()
	# moons: none alike (size, surface, tint and turn all differ), never over the planet
	var moons := int(P.get("moons", 1)) if with_planet else 1 + r.randi() % 2
	var placed: Array = []
	var tries := 0
	while placed.size() < moons and tries < 40:
		tries += 1
		var maz := r.randf_range(-0.95, 0.95)
		var mel := -r.randf_range(0.04, 0.42)
		var mdir := turn * Vector3(sin(maz) * cos(mel), sin(mel), -cos(maz) * cos(mel))
		var mang := r.randf_range(0.03, 0.04)
		if _planet_dir != Vector3.ZERO and acos(clampf(mdir.dot(_planet_dir), -1, 1)) < _planet_ang + mang + 0.04:
			continue
		var bad := false
		for q in placed:
			if acos(clampf(mdir.dot(q[0]), -1, 1)) < mang + q[1] + 0.05:
				bad = true
		if bad:
			continue
		var dist := DIST * r.randf_range(0.8, 1.15)
		if _through_board(_center + mdir * dist, 40.0 + dist * sin(mang)):
			continue
		placed.append([mdir, mang])
		var mkind := 4 if r.randf() < 0.65 else 5
		var tints := [Vector3(1.0, 0.95, 0.88), Vector3(0.85, 0.82, 0.8), Vector3(1.0, 0.86, 0.7), Vector3(0.9, 0.95, 1.05)]
		var MP := {"kind": mkind, "a": Vector3(0.5, 0.48, 0.45) if mkind == 4 else Vector3(0.8, 0.84, 0.88), "b": Vector3(0.22, 0.21, 0.2) if mkind == 4 else Vector3(0.5, 0.4, 0.32),
			"c": Vector3(0.65, 0.62, 0.58) if mkind == 4 else Vector3(0.6, 0.75, 0.9), "atmo": Vector3.ZERO, "rings": false}
		var mq := BAKER.MOON_SIZE
		if OS.has_environment("VS_WORLD_PREVIEW"):
			mq = Vector2i(256, 128)
		_sphere(_center + mdir * dist, dist * sin(mang), Basis(Vector3(r.randfn(), r.randfn(), r.randfn()).normalized(), r.randf() * TAU), MP,
			mkind * 1000 + int(setting["seed"]) % 7 + placed.size() * 101, mq, r.randf_range(0.0, 0.004), tints[placed.size() % tints.size()] * r.randf_range(0.8, 1.1), false)
	notes.append("system: %s, %d moons" % [("planet %d" % int(setting["planet_i"])) if with_planet else "no backdrop planet (the board has one)", placed.size()])


# r9: the light on a planet or moon. The battle's key light comes from behind the default camera, which lit every planet
# full face on (a flat disc, no terminator, its night lights and limb glow never seen). Far bodies take their own sun
# from the key light's side of the screen, about 70 degrees round from the viewer, so each shows a lit face, a soft
# terminator and a night side. Nobody can check the angle against the ships 3,000 units away; the side stays true.
func _body_sun(pos: Vector3) -> Vector3:
	var to_view := (_center - pos).normalized()
	var right := (-to_view).cross(Vector3.UP)
	if right.length() < 1e-3:
		return SUN.normalized()
	right = right.normalized()
	var s := 1.0 if SUN.dot(right) >= 0.0 else -1.0
	return (to_view * 0.34 + right * s * 0.88 + Vector3.UP * 0.33).normalized()


func _sphere(pos: Vector3, R: float, basis: Basis, P: Dictionary, bake_seed: int, bake_size: Vector2i, spin: float, tint: Vector3, main: bool) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 1.0
	sm.height = 2.0
	sm.radial_segments = 128 if main else 48
	sm.rings = 64 if main else 24
	mi.mesh = sm
	var m := ShaderMaterial.new()
	var sh := Shader.new()
	sh.code = PL.SPHERE
	m.shader = sh
	m.set_shader_parameter("flat_col", (P["a"] as Vector3) * 0.6)
	m.set_shader_parameter("sun", _body_sun(pos))
	var atmo: Vector3 = P.get("atmo", Vector3.ZERO)
	m.set_shader_parameter("atmo", atmo)
	m.set_shader_parameter("atmo_k", 0.0 if atmo.length() < 0.01 else (0.8 if int(P["kind"]) == 2 else 0.55))
	m.set_shader_parameter("spin", spin)
	m.set_shader_parameter("tint", tint)
	m.set_shader_parameter("light", 0.6 if main else 0.6)
	m.set_shader_parameter("rough", 1.0 if int(P["kind"]) >= 2 else 0.25)
	if bool(P.get("rings", false)):
		m.set_shader_parameter("ring", Vector4((basis * Vector3.UP).x, (basis * Vector3.UP).y, (basis * Vector3.UP).z, 1.0))
		m.set_shader_parameter("ring_r", Vector2(1.3, 2.3))
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.transform = Transform3D(basis.scaled(Vector3.ONE * R), pos)
	mi.extra_cull_margin = R
	add_child(mi)
	if atmo.length() > 0.01:
		var sh2 := MeshInstance3D.new()
		var sm2 := SphereMesh.new()
		sm2.radius = 1.0
		sm2.height = 2.0
		sm2.radial_segments = 96
		sm2.rings = 48
		sh2.mesh = sm2
		var am := ShaderMaterial.new()
		var ash := Shader.new()
		ash.code = PL.ATMO
		am.shader = ash
		am.set_shader_parameter("atmo", atmo)
		am.set_shader_parameter("sun", _body_sun(pos))
		am.set_shader_parameter("shell", 1.035)
		am.set_shader_parameter("k", 0.9 if int(P["kind"]) == 2 else 0.6)
		# far things draw first among the see-through ones, so the board's underlay covers them (r6: the glow's rim
		# showed across the board)
		am.render_priority = -60
		sh2.material_override = am
		sh2.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		sh2.transform = Transform3D(Basis.IDENTITY.scaled(Vector3.ONE * R * 1.035), pos)
		add_child(sh2)
	var key := "planet|%d|%d|%d" % [int(P["kind"]), bake_seed, bake_size.x]
	_bake_planet(m, key, P, bake_seed, bake_size)
	return mi


func _bake_planet(m: ShaderMaterial, key: String, P: Dictionary, bake_seed: int, size: Vector2i) -> void:
	pending_bakes += 1
	await _load_planet(m, key, P, bake_seed, size)
	pending_bakes -= 1


func _load_planet(m: ShaderMaterial, key: String, P: Dictionary, bake_seed: int, size: Vector2i) -> void:
	var params := {"seed": float(bake_seed % 997) * 0.71, "kind": int(P["kind"]), "ca": P["a"], "cb": P["b"], "cc": P["c"], "pass_id": 0}
	var code := PL.bake_code()
	var a: Image = await _baker.bake(key + "|a", code, params, size, 16)
	if a == null: return
	params["pass_id"] = 1
	var b: Image = await _baker.bake(key + "|b", code, params, size, 16)
	if b == null: return
	m.set_shader_parameter("tex_a", BAKER.texture(a))
	m.set_shader_parameter("tex_b", BAKER.texture(b))
	m.set_shader_parameter("has_tex", 1.0)


func _rings(pos: Vector3, R: float, basis: Basis, P: Dictionary, r: RandomNumberGenerator) -> void:
	var mi := MeshInstance3D.new()
	mi.mesh = _annulus(1.3, 2.3, 256, 1)
	var m := ShaderMaterial.new()
	var sh := Shader.new()
	sh.code = PL.RING
	m.shader = sh
	m.set_shader_parameter("sun", _body_sun(pos))
	m.set_shader_parameter("col_a", (P["c"] as Vector3) * 0.9)
	m.set_shader_parameter("col_b", (P["b"] as Vector3) * 1.2)
	m.set_shader_parameter("seed", r.randf() * 50.0)
	m.set_shader_parameter("ring_r", Vector2(1.3, 2.3))
	m.set_shader_parameter("light", 0.55)
	m.render_priority = -60
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.transform = Transform3D(basis.scaled(Vector3.ONE * R), pos)
	mi.extra_cull_margin = R * 2.5
	add_child(mi)

# ---------------------------------------------------------------- the dead star

func dead_star(c: Vector3, s: float) -> void:
	_well = c
	var root := Node3D.new()
	root.name = "DeadStar"
	root.position = c
	add_child(root)
	var Rsh := 15.0 * s
	# the black core (writes depth: ships behind it are hidden, as they would be)
	var core := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = Rsh
	sm.height = Rsh * 2.0
	core.mesh = sm
	var cm := StandardMaterial3D.new()
	cm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	cm.albedo_color = Color.BLACK
	core.material_override = cm
	core.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(core)
	# the accretion disc, tilted, turning (opaque where dense, so the lens bends its far side over the shadow)
	var tilt := Node3D.new()
	tilt.rotation = Vector3(deg_to_rad(disc_tilt), 0.0, deg_to_rad(6.0))
	root.add_child(tilt)
	var disc := MeshInstance3D.new()
	disc.mesh = _annulus(Rsh * 1.2, Rsh * 3.8, 192, 16)
	var dm := ShaderMaterial.new()
	var dsh := Shader.new()
	dsh.code = WS.DISC
	dm.shader = dsh
	dm.set_shader_parameter("r_in", Rsh * 1.2)
	dm.set_shader_parameter("r_out", Rsh * 3.8)
	dm.set_shader_parameter("spin", 0.35)
	dm.set_shader_parameter("gain", 0.62)
	dm.set_shader_parameter("inner", 1.0)
	disc.material_override = dm
	disc.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	tilt.add_child(disc)
	# the outer, thinning gas: see-through, drawn after the lens (render priority above it)
	var disc2 := MeshInstance3D.new()
	disc2.mesh = disc.mesh
	var dm2 := ShaderMaterial.new()
	var dsh2 := Shader.new()
	dsh2.code = WS.disc_soft()
	dm2.shader = dsh2
	for pn in ["r_in", "r_out", "spin", "gain"]:
		dm2.set_shader_parameter(pn, dm.get_shader_parameter(pn))
	dm2.render_priority = -10
	disc2.material_override = dm2
	disc2.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	tilt.add_child(disc2)
	# r18: thin glowing haze just above and below the disc, so it has thickness up close (Muse audit B4.5)
	if quality != "low":
		var hsh := Shader.new()
		hsh.code = WS.DISC_HAZE
		for k in 2:
			var hz := MeshInstance3D.new()
			hz.mesh = _annulus(Rsh * 1.15, Rsh * 4.2, 128, 10)
			var hm := ShaderMaterial.new()
			hm.shader = hsh
			hm.set_shader_parameter("r_in", Rsh * 1.15)
			hm.set_shader_parameter("r_out", Rsh * 4.2)
			hm.set_shader_parameter("spin", 0.35)
			hm.set_shader_parameter("seed", 3.7 * float(k + 1))
			hz.material_override = hm
			hz.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			hz.position = Vector3(0.0, Rsh * (0.07 if k == 0 else -0.07), 0.0)
			tilt.add_child(hz)
	# the lens over everything behind the hole (max and high)
	if quality != "low":
		var lens := MeshInstance3D.new()
		var qm := QuadMesh.new()
		qm.size = Vector2(1, 1)
		lens.mesh = qm
		var lm := ShaderMaterial.new()
		var lsh := Shader.new()
		lsh.code = WS.LENS
		lm.shader = lsh
		var half := Rsh * 5.0
		lm.set_shader_parameter("r_shadow", Rsh * 1.0 / half)
		lm.set_shader_parameter("r_einstein", Rsh * 1.6 / half)
		# the disc's lensed arcs and Doppler beaming are drawn in the lens (matching G3's map); it needs the disc's frame
		lm.set_shader_parameter("disc_basis", tilt.global_transform.basis.orthonormalized() if tilt.is_inside_tree() else Basis.from_euler(tilt.rotation))
		lm.set_shader_parameter("disc_r_mid", Rsh * 2.2)
		lm.set_shader_parameter("disc_reach", Rsh * 4.2)
		lm.set_shader_parameter("spin", 0.35)
		# F4: the lensed far side of the disc over the shadow a little stronger (it read faint and smeared in r1)
		lm.set_shader_parameter("arc_gain", 1.15)
		lm.render_priority = -30   # drawn first among the see-through things: it copies the opaque picture, so later effects (beams, trails in front of it) draw over it, not under it
		lens.material_override = lm
		lens.scale = Vector3.ONE * half
		lens.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		lens.extra_cull_margin = half * 4.0
		root.add_child(lens)
	# the disc's warm light (the lit gas): an omni light, no shadows. r10 lighting pass: it reaches further and falls off
	# more steeply, so ships near the well take a warm side light from the disc (the rocks' rim matches it) while the
	# far side of the board keeps the plain key light
	var l := OmniLight3D.new()
	l.light_color = Color(1.0, 0.6, 0.3)
	l.light_energy = 1.6
	l.omni_range = Rsh * 14.0
	l.omni_attenuation = 1.6
	l.shadow_enabled = false
	root.add_child(l)
	notes.append("dead star: core, lensing %s, accretion disc" % ("on" if quality != "low" else "off"))


func _annulus(r0: float, r1: float, seg: int, rings: int) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for j in rings:
		var a0 := r0 + (r1 - r0) * float(j) / rings
		var a1 := r0 + (r1 - r0) * float(j + 1) / rings
		for i in seg:
			var t0 := TAU * i / seg
			var t1 := TAU * (i + 1) / seg
			var p00 := Vector3(cos(t0) * a0, 0, sin(t0) * a0)
			var p01 := Vector3(cos(t1) * a0, 0, sin(t1) * a0)
			var p10 := Vector3(cos(t0) * a1, 0, sin(t0) * a1)
			var p11 := Vector3(cos(t1) * a1, 0, sin(t1) * a1)
			for v in [p00, p10, p11, p00, p11, p01]:
				st.set_normal(Vector3.UP)
				st.add_vertex(v)
	return st.commit()




# ---------------------------------------------------------------- asteroids

func _mat(kind: String) -> ShaderMaterial:
	if not _mats.has(kind):
		_mats[kind] = WR.material(kind, _look)
		_sky_into(_mats[kind])
	return _mats[kind]


# r6: the board's own blockers get a lifted copy of the kind's material (a little brighter, a stronger rim, no haze), so
# terrain reads at a glance against the dark board while the far rocks stay dark and quiet. r11: lift 1.55 to 1.2 (under
# the front key light 1.55 turned stone into pale blue plaster; F1's terrain fill now marks rock hexes, so the rock itself
# can stay rock-dark)
func _hero_mat(kind: String) -> ShaderMaterial:
	var key := kind + "|hero"
	if not _mats.has(key):
		var m: ShaderMaterial = WR.material(kind, _look)
		m.set_shader_parameter("lift", 1.2)
		m.set_shader_parameter("haze_max", 0.0)
		# r8: the blockers keep a little more of the ambient than the far rocks, so their dark side still reads on the board
		m.set_shader_parameter("amb", 0.65)
		_mats[key] = m
	return _mats[key]


func _crystal_mat() -> ShaderMaterial:
	if not _mats.has("_crystal"):
		_mats["_crystal"] = WR.crystal_material(_look)
	return _mats["_crystal"]


func _pick(kind: String, r: RandomNumberGenerator) -> String:
	var names: Array = WR.names_for(kind)
	if names.is_empty():
		return ""
	# the kind's first family is its most typical: weight it double
	var i := r.randi() % (names.size() + names.size() / 2)
	return names[i % names.size()]


func _rand_basis(r: RandomNumberGenerator) -> Basis:
	return Basis(Quaternion(r.randfn(), r.randfn(), r.randfn(), r.randfn()).normalized())


func _rand_axis(r: RandomNumberGenerator) -> Vector3:
	return Vector3(r.randfn(), r.randfn(), r.randfn()).normalized()


# A blocker on a rock hex: one big rock filling the hex, a few smaller ones round its foot. Obviously solid terrain: lit,
# shadow-casting, the crispest rocks on screen, and nothing like a hex fill or outline.
func blocker(p: Vector3, kind: String) -> void:
	var name := _pick(kind, _rng)
	if name == "":
		return
	var mat := _hero_mat(kind)
	# the longest half-length stays under the hex's inner radius (8.66), so a blocker never seems to fill a free neighbour
	var s := _rng.randf_range(6.4, 7.6)
	var b := _rand_basis(_rng)
	var crystal := kind == "crystal"
	_batch.add(name, mat, true, Transform3D(b.scaled(Vector3.ONE * s), p + Vector3(0, _rng.randf_range(0.5, 2.5), 0)),
		_rand_axis(_rng), 0.0 if crystal else _rng.randf_range(0.004, 0.012), _rng.randf())
	for i in _rng.randi_range(2, 4):
		var a := _rng.randf() * TAU
		var rr := _rng.randf_range(4.5, 6.2)
		var sn := _pick(kind, _rng)
		_batch.add(sn + "_lo" if _rng.randf() < 0.5 else sn, mat, true,
			Transform3D(_rand_basis(_rng).scaled(Vector3.ONE * _rng.randf_range(1.0, 2.2)), p + Vector3(cos(a) * rr, _rng.randf_range(-2.0, 4.0), sin(a) * rr)),
			_rand_axis(_rng), _rng.randf_range(0.02, 0.09), _rng.randf())
	if crystal:
		var names: Array = WR.lib().get("crystals", [])
		if not names.is_empty():
			for i in _rng.randi_range(1, 2):
				var cb := Basis(Vector3.UP, _rng.randf() * TAU) * Basis(Vector3(1, 0, 0), _rng.randf_range(-0.4, 0.4))
				var off := Vector3(_rng.randf_range(-3, 3), s * 0.35 + _rng.randf_range(0, 2), _rng.randf_range(-3, 3))
				_batch.add(names[_rng.randi() % names.size()], _crystal_mat(), true, Transform3D(cb.scaled(Vector3.ONE * _rng.randf_range(3.5, 5.5)), p + off),
					Vector3.UP, 0.0, _rng.randf())


func debris_field(p: Vector3, kind: String) -> void:
	var mat := _mat(kind)
	var pieces: Array = []
	for i in _rng.randi_range(8, 13):
		var a := _rng.randf() * TAU
		var rr := sqrt(_rng.randf()) * 7.5
		var s := 0.35 + 1.6 * pow(_rng.randf(), 2.2)
		pieces.append({"mesh": _pick(kind, _rng), "shadow": false,
			"xf": Transform3D(_rand_basis(_rng).scaled(Vector3.ONE * s), p + Vector3(cos(a) * rr, _rng.randf_range(-2.5, 3.0), sin(a) * rr)),
			"axis": _rand_axis(_rng), "rate": _rng.randf_range(0.06, 0.35), "seed": _rng.randf()})
	LIV.add_debris_rocks(_batch, pieces, mat)


# Is a point at the board's own height over the playable area (with a margin)? Nothing but blockers and debris goes there.
func _over_board(p: Vector3, margin: float) -> bool:
	return p.x > _lo.x - margin and p.x < _hi.x + margin and p.z > _lo.z - margin and p.z < _hi.z + margin


# Would a point below the board be seen through the board from the default camera (which looks toward -z, 34 degrees
# down: a point h below shows h / tan(34) nearer the camera) or from straight above? Such points are left empty, so
# the only rocks seen through the hexes are the board's own.
func _seen_on_board(p: Vector3, margin: float) -> bool:
	var h := -(p.y - _center.y)
	if h < 2.0:
		return _over_board(p, margin)
	if _over_board(p, margin):
		return true
	# the default camera (34 degrees down) and, r6, the camera tipped low (12 degrees: rocks under the near half of the
	# board showed through it as dark ghosts)
	# r11: and the camera orbited up to about 50 degrees either way (a close look from the side showed rocks under the
	# board as pale ghosts through its hexes)
	for k in [1.48, 4.7]:
		for yaw in [0.0, -0.45, 0.45, -0.9, 0.9]:
			var cx: float = p.x + h * k * sin(yaw)
			var cz: float = p.z + h * k * cos(yaw)
			if cx > _lo.x - margin and cx < _hi.x + margin and cz > _lo.z - margin and cz < _hi.z + margin:
				return true
	return false


# Would the battle camera (default or zoomed out) see a far point through the board? r2: moons and mountains seen
# through the hexes read as balls and boulders sitting on the board, so they keep out of that cone.
func _through_board(p: Vector3, pad: float) -> bool:
	for r in [170.0, 260.0, 640.0]:
		var cam := _center + Vector3(0.0, 0.557, 0.83) * float(r)
		if p.y >= _center.y - 1.0:
			continue
		var t := (cam.y - _center.y) / (cam.y - p.y)
		var hit := cam.lerp(p, t)
		# the pad is a world size at p: scale it to the board's distance along the ray
		var pd := pad * t
		if hit.x > _lo.x - pd - 30.0 and hit.x < _hi.x + pd + 30.0 and hit.z > _lo.z - pd - 30.0 and hit.z < _hi.z + pd + 30.0:
			return true
	return false


# Is a direction (seen from the board's centre) on the planet's disc?
func _on_planet(p: Vector3, pad: float) -> bool:
	if _planet_dir == Vector3.ZERO:
		return false
	# seen from the default battle camera (34 degrees up, about 170 out, toward +z) and from the zoomed-out one
	var pc := _center + _planet_dir * DIST
	for r in [170.0, 640.0]:
		var cam := _center + Vector3(0.0, 0.557, 0.83) * float(r)
		var d := (p - cam).normalized()
		var pd := (pc - cam).normalized()
		if acos(clampf(d.dot(pd), -1, 1)) < _planet_ang + pad:
			return true
	return false


# Bound the real mesh, including the shader's seeded rotation, rather than assuming every rock is two units long.
# Use the nearest point along the default and low battle camera's zoom paths, so the cap holds between zoom stops too.
func _backdrop_scale(nm: String, s: float, p: Vector3, max_length := INF) -> float:
	if not _backdrop_radii.has(nm):
		var mesh := WR.mesh(nm)
		var radius := 0.0
		for surface in mesh.get_surface_count():
			var vertices: PackedVector3Array = mesh.surface_get_arrays(surface)[Mesh.ARRAY_VERTEX]
			for v in vertices:
				radius = maxf(radius, v.length())
		_backdrop_radii[nm] = maxf(radius, 0.001)
	var diameter := 2.0 * float(_backdrop_radii[nm])
	var dist := p.distance_to(_center)
	for pitch in [0.98, 1.32]:
		var axis := Vector3(0.0, cos(float(pitch)), sin(float(pitch)))
		var rr := clampf((p - _center).dot(axis), 0.0, 900.0)
		dist = minf(dist, p.distance_to(_center + axis * rr))
	# The exact sphere angle stays below 0.05, including the small-angle rounding margin.
	var length_cap := minf(max_length, 2.0 * sin(BACKDROP_ROCK_ANGLE * 0.5) * dist)
	s = minf(s, length_cap / diameter)
	var angle := 2.0 * asin(clampf(diameter * s / (2.0 * maxf(dist, 0.001)), 0.0, 1.0))
	assert(angle <= BACKDROP_ROCK_ANGLE + 0.000001, "Backdrop rock exceeds 0.05 rad")
	assert(_planet_ang == 0.0 or angle * 4.4 <= 2.0 * _planet_ang + 0.000001, "Backdrop rock exceeds planet scale margin")
	return s


# The layers round and below the board, by map: an edge scatter (near the board's height, outside it), a deep field far
# below (seen through the board, small and hazed), a belt stream on belt maps, and a few mountain-sized rocks.
func fields(mk: String, kind: String) -> void:
	var r := RandomNumberGenerator.new()
	r.seed = int(setting.get("seed", 7)) * 7 + hash(mk)
	var dens := float(setting.get("rocks", 0.8))
	var N := {"belt": [80, 260, 420, 7], "open": [20, 110, 0, 3], "station": [34, 150, 0, 4], "planet": [26, 120, 0, 3],
		"storm": [30, 150, 0, 4], "graveyard": [44, 190, 0, 4]}.get(mk, [24, 120, 0, 3])
	var lowq := quality == "low"
	var mat := _mat(kind)
	var ext := (_hi - _lo) * 0.5
	# 1. the edge scatter. r2: beyond the far edge the rocks may ride at the board's height (they stand against the sky
	# there and frame the battle); along the sides they sit well below it, so from the battle camera none of them seems to
	# rest on a hex; on the camera's side (+z) they keep low and far out, so none passes in front of the board.
	var placed := 0
	var tries := 0
	while placed < int(N[0] * dens) and tries < 3000:
		tries += 1
		var a := r.randf() * TAU
		var k := r.randf_range(1.0, 2.2)
		var p := _center + Vector3(cos(a) * (ext.x + 60.0) * k, 0.0, sin(a) * (ext.z + 60.0) * k)
		var far := p.z < _lo.z - 30.0
		var near := p.z > _hi.z - 20.0
		p.y = _center.y + (r.randf_range(-40.0, 12.0) if far else (r.randf_range(-140.0, -90.0) if near else r.randf_range(-75.0, -28.0)))
		var s := 1.6 + 7.0 * pow(r.randf(), 2.5) + (8.0 if r.randf() < 0.06 else 0.0)
		if _seen_on_board(p, 40.0 + s) or _on_planet(p, 0.05):
			continue
		var nm := _pick(kind, r)
		nm = nm if s > 5.0 else nm + "_lo"
		s = _backdrop_scale(nm, s, p, 20.0)
		_batch.add(nm, mat, true, Transform3D(_rand_basis(r).scaled(Vector3.ONE * s), p), _rand_axis(r), r.randf_range(0.01, 0.07) * (3.0 / (2.0 + s)), r.randf())
		placed += 1
	# 2. the deep field: far below, wide, sizes growing with depth so it reads as a volume, never right under a ship's hex
	var deep := 0
	tries = 0
	while deep < int(N[1] * dens * (0.6 if lowq else 1.0)) and tries < 4000:
		tries += 1
		var a := r.randf() * TAU
		var dist := r.randf_range(800.0, 1500.0)
		var depth := dist * r.randf_range(0.35, 0.85)
		var rad := sqrt(dist * dist - depth * depth)
		var p := _center + Vector3(cos(a) * rad, -depth, sin(a) * rad)
		if _on_planet(p, 0.03):
			continue
		var s := (3.0 + depth * 0.035) * (0.5 + 1.6 * pow(r.randf(), 2.0))
		if _seen_on_board(p, 30.0 + s):
			continue
		var nm := _pick(kind, r)
		nm = nm if s > 22.0 else nm + "_lo"
		s = _backdrop_scale(nm, s, p, 40.0)
		_batch.add(nm, mat, false, Transform3D(_rand_basis(r).scaled(Vector3.ONE * s), p), _rand_axis(r), r.randf_range(0.005, 0.04), r.randf())
		deep += 1
	# 3. the belt stream: a river of rock under the board, out to the horizon both ways
	var belt := 0
	if N[2] > 0:
		# beyond the board's far side, running across the view to the horizon both ways
		var th := r.randf_range(-0.35, 0.35)
		var ax := Vector3(cos(th), 0, sin(th))
		var side := Vector3(-ax.z, 0, ax.x)
		var depth := r.randf_range(150.0, 240.0)
		var o := Vector3(_center.x, _center.y - depth, _lo.z - depth * 1.48 - r.randf_range(380.0, 620.0))
		var tilt := r.randf_range(-0.06, 0.06)
		for i in int(N[2] * (0.6 if lowq else 1.0)):
			var sv := r.randf_range(-2600.0, 2600.0)
			var w := r.randfn() * 170.0
			var p := o + ax * sv + side * w + Vector3(0, r.randfn() * 45.0 + sv * tilt, 0)
			if p.distance_to(_center) < 600.0 or _on_planet(p, 0.02):
				continue
			var s := 4.0 + 30.0 * pow(r.randf(), 3.0) + absf(sv) * 0.004
			if _seen_on_board(p, 30.0 + s):
				continue
			var nm := _pick(kind, r)
			nm = nm if s > 22.0 else nm + "_lo"
			s = _backdrop_scale(nm, s, p, 30.0)
			_batch.add(nm, mat, false, Transform3D(_rand_basis(r).scaled(Vector3.ONE * s), p), _rand_axis(r), r.randf_range(0.004, 0.03), r.randf())
			belt += 1
	# 4. mountains: a few huge rocks far out, below the horizon, clear of the planet and of the board's footprint
	var mts := 0
	tries = 0
	while mts < N[3] and tries < 200:
		tries += 1
		var az := r.randf() * TAU
		var el := -r.randf_range(0.08, 0.6)
		var d := Vector3(cos(az) * cos(el), sin(el), sin(az) * cos(el))
		var dist := r.randf_range(900.0, 2300.0)
		var p := _center + d * dist
		var s := r.randf_range(70.0, 220.0) * (dist / 1600.0)
		if _on_planet(p, 0.08 + s / dist):
			continue
		if Vector2(p.x - _center.x, p.z - _center.z).length() < 520.0 or _through_board(p, s):
			continue
		var nm := _pick(kind, r)
		s = _backdrop_scale(nm, s, p)
		_batch.add(nm, mat, false, Transform3D(_rand_basis(r).scaled(Vector3.ONE * s), p), _rand_axis(r), r.randf_range(0.0015, 0.006), r.randf())
		mts += 1
	# crystal fields: free crystal clusters drift among the edge rocks
	if kind == "crystal":
		var names: Array = WR.lib().get("crystals", [])
		for i in (12 if not names.is_empty() else 0):
			var a := r.randf() * TAU
			var p := _center + Vector3(cos(a) * (ext.x + 60.0) * r.randf_range(1.0, 1.8), r.randf_range(-40.0, 5.0), sin(a) * (ext.z + 60.0) * r.randf_range(1.0, 1.8))
			if _over_board(p, 30.0):
				continue
			var nm: String = names[r.randi() % names.size()]
			var s := _backdrop_scale(nm, r.randf_range(2.0, 6.0), p, 20.0)
			_batch.add(nm, _crystal_mat(), false, Transform3D(_rand_basis(r).scaled(Vector3.ONE * s), p), _rand_axis(r), r.randf_range(0.01, 0.05), r.randf())
	notes.append("fields: %d edge rocks, %d deep, %d belt, %d mountains" % [placed, deep, belt, mts])


# ---------------------------------------------------------------- gas wisps (depth and parallax)

# F4 r4: the sky's nebula is infinitely far, so it never moves against the board. A few dozen large, faint clouds of the
# setting's gas at middle distance (round and below the board, never behind its hexes) slide past each other and past
# the sky whenever the camera turns or zooms, which gives the space its depth. Noise comes from one small pre-made
# texture (two reads per pixel), so the overdraw stays cheap.
const WISP_SHADER := """
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;
uniform sampler2D noise : filter_linear_mipmap, repeat_enable;
uniform vec3 c_a = vec3(0.4, 0.2, 0.1);
uniform vec3 c_b = vec3(0.1, 0.15, 0.3);
uniform float gain = 0.06;
varying vec4 vI;
varying vec2 vQ;
void vertex() {
	vI = INSTANCE_CUSTOM;
	vec4 c = MODELVIEW_MATRIX * vec4(0.0, 0.0, 0.0, 1.0);
	float a = vI.y * 6.2831;
	vec2 q = mat2(vec2(cos(a), sin(a)), vec2(-sin(a), cos(a))) * VERTEX.xy;
	vQ = VERTEX.xy * 2.0;
	c.xy += q * vI.x;
	POSITION = PROJECTION_MATRIX * c;
}
void fragment() {
	float r = length(vQ);
	if (r > 1.0) { discard; }
	vec2 uv = vQ * 0.35 + vI.zw * 7.0 + vec2(TIME * 0.0015, 0.0);
	float n = texture(noise, uv).r;
	float m = texture(noise, uv * 2.3 + n * 0.25 + 0.5).r;
	float d = smoothstep(0.42, 0.85, n * 0.65 + m * 0.35) * smoothstep(1.0, 0.25, r);
	ALBEDO = mix(c_b, c_a, smoothstep(0.3, 0.7, m)) * d * gain;
}
"""


func wisps() -> void:
	if quality == "low":
		return
	var r := RandomNumberGenerator.new()
	r.seed = int(setting.get("seed", 7)) + 313
	var n := int(26 + 34 * float(setting.get("neb", 0.5)))
	var mm := _quad_mm(n)
	var i := 0
	var tries := 0
	while i < n and tries < n * 30:
		tries += 1
		var a := r.randf() * TAU
		var rad := r.randf_range(300.0, 1500.0)
		var p := _center + Vector3(cos(a) * rad * 1.2, -r.randf_range(80.0, 520.0), sin(a) * rad)
		var sz := r.randf_range(180.0, 520.0)
		if _seen_on_board(p, sz * 0.45) or _through_board(p, sz * 0.45):
			continue
		mm.set_instance_transform(i, Transform3D(Basis.IDENTITY, p))
		mm.set_instance_custom_data(i, Color(sz, r.randf(), r.randf(), r.randf()))
		i += 1
	mm.visible_instance_count = i
	var mi := MultiMeshInstance3D.new()
	mi.multimesh = mm
	var m := ShaderMaterial.new()
	var sh := Shader.new()
	sh.code = WISP_SHADER
	m.shader = sh
	m.set_shader_parameter("noise", _wisp_noise())
	m.set_shader_parameter("c_a", setting["c1"])
	m.set_shader_parameter("c_b", setting["c2"])
	m.set_shader_parameter("gain", 0.05 + 0.07 * float(setting.get("neb", 0.5)))
	m.render_priority = -25
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.extra_cull_margin = 600.0
	add_child(mi)
	notes.append("wisps: %d gas clouds at middle distance" % i)


static var _wnoise: Texture2D = null


static func _wisp_noise() -> Texture2D:
	if _wnoise != null:
		return _wnoise
	var t := NoiseTexture2D.new()
	t.width = 512
	t.height = 512
	t.seamless = true
	t.generate_mipmaps = true
	var fn := FastNoiseLite.new()
	fn.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	fn.frequency = 0.008
	fn.fractal_type = FastNoiseLite.FRACTAL_FBM
	fn.fractal_octaves = 5
	fn.domain_warp_enabled = true
	fn.domain_warp_amplitude = 40.0
	t.noise = fn
	t.normalize = true
	_wnoise = t
	return t


# ---------------------------------------------------------------- the board's underlay

# F4 r2: the board's hexes are mostly see-through (board.gd BASE_FILL is 18% opaque), so whatever lies under the board
# showed through them: bright nebula, the planet in low views, far rocks as pale ghosts. That fought the move hexes
# (Ryan, Nov 1: "Hard to tell what's movement squares versus other map hexes"). A dark, smoked layer a little under the
# board calms the space behind the play area, fading out softly past its edges so the sky round the board stays rich.
# On the dead-star board it opens round the well, so the hole, its disc and its lensing are never dimmed.
const UNDERLAY_SHADER := """
shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;
uniform vec2 half_ext = vec2(150.0, 100.0);
uniform vec3 centre = vec3(0.0);
uniform float fade = 90.0;
uniform float k = 0.76;
uniform vec3 col = vec3(0.008, 0.011, 0.018);
uniform vec3 well = vec3(0.0);
uniform float well_r = 0.0;
uniform vec4 planet = vec4(0.0);    // xyz centre, w radius (0: none)
uniform vec3 ring_n = vec3(0.0);
uniform float vis = 1.0;    // the board look trial: 0 hides the floor (looks A, B, C), a part of it in C's tactical grid
varying vec3 vW;
void vertex() { vW = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment() {
	vec2 q = abs(vW.xz - centre.xz) - half_ext;
	float sd = length(max(q, vec2(0.0))) + min(max(q.x, q.y), 0.0);
	// thicker at grazing angles, like smoked glass seen edge on: when the camera tips low, the far half of the board
	// would otherwise show the planet and far rocks below the horizon right through the hexes
	float graze = 1.0 - abs(dot(normalize(CAMERA_POSITION_WORLD - vW), vec3(0.0, 1.0, 0.0)));
	float a = mix(k, 0.94, graze * graze);
	// where the view ray goes on to the system's planet or its rings, the board is all but opaque: the planet shows past
	// the board's edges, never through the hexes (it lies below the board's plane, beyond its far side)
	if (planet.w > 0.0) {
		vec3 ro = CAMERA_POSITION_WORLD;
		vec3 rd = normalize(vW - ro);
		vec3 oc = planet.xyz - ro;
		float tc = dot(oc, rd);
		float dperp = length(oc - rd * tc) / planet.w;
		float hit = (tc > 0.0) ? smoothstep(1.12, 0.98, dperp) : 0.0;
		if (dot(ring_n, ring_n) > 0.5) {
			float den = dot(rd, ring_n);
			if (abs(den) > 1e-4) {
				float t = dot(oc, ring_n) / den;
				float rr = length(ro + rd * t - planet.xyz) / planet.w;
				hit = max(hit, (t > 0.0 ? smoothstep(1.2, 1.32, rr) * smoothstep(2.42, 2.28, rr) : 0.0));
			}
		}
		a = mix(a, 0.97, hit);
	}
	a *= 1.0 - smoothstep(-fade * 0.25, fade, sd);
	if (well_r > 0.0) {
		a *= smoothstep(well_r, well_r * 1.5, length(vW.xz - well.xz));
	}
	ALBEDO = col;
	ALPHA = a * vis;
}
"""


func underlay() -> void:
	var ext := (_hi - _lo) * 0.5
	var mi := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(ext.x * 2.0 + 260.0, ext.z * 2.0 + 260.0)
	mi.mesh = pm
	var m := ShaderMaterial.new()
	var sh := Shader.new()
	sh.code = UNDERLAY_SHADER
	m.shader = sh
	m.set_shader_parameter("half_ext", Vector2(ext.x + 10.0, ext.z + 10.0))
	m.set_shader_parameter("centre", _center)
	# a hint of the setting's own colour, so it reads as deep space and not a black sheet
	m.set_shader_parameter("col", Vector3(0.006, 0.009, 0.016).lerp(setting.get("haze", Vector3.ZERO) as Vector3, 0.35))
	if _planet_R > 0.0:
		m.set_shader_parameter("planet", Vector4(_planet_pos.x, _planet_pos.y, _planet_pos.z, _planet_R))
		m.set_shader_parameter("ring_n", _ring_n)
	if _well != Vector3.INF:
		m.set_shader_parameter("well", _well)
		m.set_shader_parameter("well_r", 15.0 * 4.4)
	# drawn after the lens (which copies the screen, render_priority -30) and before the board's own fills
	m.render_priority = -20
	_under_mat = m
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# below the feet of the board's rocks and debris, above anything deep
	mi.position = Vector3(_center.x, _center.y - 9.0, _center.z)
	add_child(mi)


# ---------------------------------------------------------------- clouds and dust

const CLOUD_SHADER := """
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;
""" + "%NOISE%" + """
uniform vec3 c_a = vec3(0.4, 0.3, 0.7);
uniform vec3 c_b = vec3(0.2, 0.4, 0.8);
uniform float gain = 0.3;
uniform float storm = 0.0;
uniform vec3 bolt = vec3(0.75, 0.85, 1.0);
varying vec4 vI;
varying vec2 vQ;
void vertex() {
	vI = INSTANCE_CUSTOM;
	vec4 c = MODELVIEW_MATRIX * vec4(0.0, 0.0, 0.0, 1.0);
	float a = vI.y * 6.2831;
	vec2 q = mat2(vec2(cos(a), sin(a)), vec2(-sin(a), cos(a))) * VERTEX.xy;
	vQ = VERTEX.xy * 2.0;
	c.xy += q * vI.x;
	POSITION = PROJECTION_MATRIX * c;
}
void fragment() {
	float r = length(vQ);
	if (r > 1.0) { discard; }
	vec2 p = vQ * 1.6 + vI.y * 37.0 + vec2(TIME * 0.015, TIME * 0.008);
	float n = wfbm(p * 1.3 + wfbm(p * 0.8 + 3.0) * 1.5);
	float a = smoothstep(1.0, 0.15, r) * smoothstep(0.3, 0.75, n) * vI.z;
	vec3 c = mix(c_a, c_b, smoothstep(0.35, 0.7, wfbm(p * 0.7 + 9.0)));
	vec3 col = c * a * gain;
	if (storm > 0.5) {
		// ion storm: now and then a cloud lights from inside, a branching flash
		float ph = fract(TIME * (0.11 + vI.w * 0.07) + vI.w * 13.0);
		float fl = smoothstep(0.0, 0.01, ph) * smoothstep(0.08, 0.02, ph) * (0.6 + 0.4 * sin(TIME * 41.0 + vI.w * 9.0));
		// r2: the cloud lights from inside as one soft glow, with only faint brighter folds where it is densest (r1's
		// sharp veins drew white wire scribbles over the hexes)
		float vein = smoothstep(0.8, 0.97, 1.0 - abs(wfbm(p * 1.6 + vI.w * 5.0) * 2.0 - 1.0));
		col += bolt * a * (1.1 + vein * 0.5) * fl * smoothstep(1.0, 0.2, r);
	}
	ALBEDO = col;
}
"""

const DUST_SHADER := """
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;
uniform vec3 col = vec3(0.6, 0.58, 0.55);
uniform float px = 0.0008;
varying float vA;
varying vec2 vQ;
void vertex() {
	vec4 c = MODELVIEW_MATRIX * vec4(0.0, 0.0, 0.0, 1.0);
	float size = INSTANCE_CUSTOM.x;
	float depth = max(-c.z, 1.0);
	float mins = depth * px * 1.6;
	float s = max(size, mins);
	float k = clamp(size / mins, 0.0, 1.0);
	vA = k * k * INSTANCE_CUSTOM.y * smoothstep(1600.0, 600.0, depth);
	vQ = VERTEX.xy * 2.0;
	c.xy += VERTEX.xy * s;
	POSITION = PROJECTION_MATRIX * c;
}
void fragment() {
	float r = length(vQ);
	ALBEDO = col * exp(-r * r * 4.0) * vA;
}
"""


func _quad_mm(n: int) -> MultiMesh:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_custom_data = true
	var qm := QuadMesh.new()
	qm.size = Vector2(1, 1)
	mm.mesh = qm
	mm.instance_count = n
	return mm


# Nebula and ion-storm hexes: soft lit clouds over the hexes (a few billboards each, drifting), the storm's flickering
# from inside. Kept faint so ships and the hex overlays stay readable through them.
func cloud_hexes(ps: Array, t: String, fac: String) -> void:
	var per := 4 if quality != "low" else 2
	var mm := _quad_mm(ps.size() * per)
	var i := 0
	for p in ps:
		for k in per:
			var off := Vector3(_rng.randf_range(-5, 5), _rng.randf_range(0.5, 4.0), _rng.randf_range(-5, 5))
			mm.set_instance_transform(i, Transform3D(Basis.IDENTITY, p + off))
			mm.set_instance_custom_data(i, Color(_rng.randf_range(11.0, 17.0), _rng.randf(), _rng.randf_range(0.6, 1.0), _rng.randf()))
			i += 1
	var mi := MultiMeshInstance3D.new()
	mi.multimesh = mm
	var m := ShaderMaterial.new()
	var sh := Shader.new()
	sh.code = CLOUD_SHADER.replace("%NOISE%", WS.NOISE)
	m.shader = sh
	var b: Array = FLOOK.of(fac).get("nebula", FLOOK.of("voidsworn")["nebula"])
	if t == "storm":
		m.set_shader_parameter("c_a", Vector3(0.22, 0.26, 0.55))
		m.set_shader_parameter("c_b", Vector3(0.42, 0.3, 0.7))
		m.set_shader_parameter("storm", 1.0)
		m.set_shader_parameter("gain", 0.2)
	else:
		m.set_shader_parameter("c_a", b[1])
		m.set_shader_parameter("c_b", (b[2] as Vector3) * 0.7)
		m.set_shader_parameter("gain", 0.19)
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.extra_cull_margin = 20.0
	add_child(mi)
	_old_clouds.append(mi)


# Dust specks through the space round and below the board (never over it at ship height): they slide past at different
# depths whenever the camera moves, which gives the scene its depth.
func dust(mk: String) -> void:
	var n := {"belt": 2600, "graveyard": 2000, "storm": 1600}.get(mk, 1300)
	if quality == "low":
		n /= 3
	var r := RandomNumberGenerator.new()
	r.seed = int(setting.get("seed", 7)) + 77
	var mm := _quad_mm(n)
	var i := 0
	var tries := 0
	while i < n and tries < n * 4:
		tries += 1
		var p := _center + Vector3(r.randf_range(-750, 750), r.randf_range(-420, 70), r.randf_range(-620, 620))
		if p.y > -25.0 and _over_board(p, 20.0):
			continue
		mm.set_instance_transform(i, Transform3D(Basis.IDENTITY, p))
		mm.set_instance_custom_data(i, Color(r.randf_range(0.25, 0.9), r.randf_range(0.25, 1.0), 0, 0))
		i += 1
	mm.visible_instance_count = i
	var mi := MultiMeshInstance3D.new()
	mi.multimesh = mm
	var m := ShaderMaterial.new()
	var sh := Shader.new()
	sh.code = DUST_SHADER
	m.shader = sh
	m.set_shader_parameter("col", Vector3(0.55, 0.52, 0.48).lerp(setting.get("c1", Vector3(0.5, 0.5, 0.5)), 0.25) * 0.9)
	var h := float(ProjectSettings.get_setting("display/window/size/viewport_height", 1080))
	if is_inside_tree():
		h = maxf(h, float(get_viewport().get_visible_rect().size.y))
	m.set_shader_parameter("px", deg_to_rad(45.0) / h)
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.extra_cull_margin = 100.0
	add_child(mi)


# ShipView scenes are already loaded by the battle; no asset path or GLB import.
func use_ship_debris(ships: Array) -> void:
	_debris_ships = ships
	if _living != null: _living.use_ship_debris(ships)
