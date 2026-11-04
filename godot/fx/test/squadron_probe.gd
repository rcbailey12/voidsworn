extends SceneTree
# Real battle scene and rules launches, at the normal camera and at close range.
# SQUADRON_OUT holds review captures; SQUADRON_FRAMES is optional scratch output.
const BATTLE := preload("res://scenes/battle/battle.tscn")
const API := preload("res://rules/battle_api.gd")
const SV := preload("res://render/ship_view.gd")
const FX := preload("res://fx/fx.gd")
const CASES := {"voidsworn": "reliquary", "hegemony": "h_vanguard", "corsair": "c_hulk", "chorus": "b_brood", "ithar": "i_carrier", "deathless": "d_harvester"}
var vp: SubViewport
var out := ""
var frames := ""

func _init() -> void:
	process_frame.connect(_run, CONNECT_ONE_SHOT)

func _run() -> void:
	out = OS.get_environment("SQUADRON_OUT")
	frames = OS.get_environment("SQUADRON_FRAMES")
	if out == "":
		push_error("Set SQUADRON_OUT")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(out)
	if frames != "": DirAccess.make_dir_recursive_absolute(frames)
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	seed(6701)
	vp = SubViewport.new()
	vp.size = Vector2i(2560, 1440)
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(vp)
	for fac in CASES:
		var only := OS.get_environment("SQUADRON_FACTION")
		if only != "" and fac != only: continue
		await _case(fac)
	SV.clear_static()
	FX.clear_static()
	print("SQUADRON_CAPTURE_COMPLETE " + out)
	quit()

func _case(fac: String) -> void:
	var b = BATTLE.instantiate()
	b.external = true
	b.args["quality"] = "max"
	b.args["no-tips"] = true
	vp.add_child(b)
	b.tips_off = true
	var api := API.new()
	api.load_rules()
	var sc := {"seed": 6701, "sector": 1, "admiral": "vex", "fleet": ["reliquary", "warden"], "fac": fac, "enemies": [CASES[fac], CASES[fac]], "obj": "rout", "shape": "open", "map": "open", "dep": "line", "kind": "battle"}
	api.new_battle_scenario(sc)
	b.battle_cfg = sc
	b.busy = true # Hold turn playback while reviewing the rules' initial wings.
	b.args["shots"] = out # Suppress the opening camera glide after warm-up.
	b.begin_with(api)
	b.set_process(false)
	b.cam.set_process(false)
	b.cam.input_enabled = false
	var warm_start := Time.get_ticks_msec()
	while b.warming:
		if Time.get_ticks_msec() - warm_start > 120000:
			push_error("Squadron capture warm-up timed out: " + fac)
			quit(1)
			return
		await process_frame
	var wings: Array = []
	for u in api.view().units:
		if u.side == "enemy" and u.squadron: wings.append(b.views[u.id])
	if wings.is_empty():
		if fac != "deathless":
			push_error("Expected launched squadrons: " + fac)
			quit(1)
			return
		await _snap(fac + "_battle_no_squadrons")
		print("SQUADRON_CAPTURE deathless: no launch hulls or squadrons in rules")
	else:
		var sv = wings[0]
		# Same camera angles, FOV and distance as a normal battle, centred on wing
		# and carrier so its craft remain easy to find in the full-size capture.
		b.cam.r = 170.0
		b.cam.b = 0.98
		b.cam.t = sv.global_position
		b.cam.snap()
		sv.set_selected(true)
		await _snap(fac + "_battle")
		if OS.get_environment("SQUADRON_BATTLE_ONLY") == "1":
			b.queue_free()
			for i in 5: await process_frame
			print("SQUADRON_BATTLE_CAPTURE " + fac)
			return
		b.hud.visible = false
		sv.set_selected(false)
		# Close views isolate one real wing under the battle's own lighting.
		# The preceding normal-distance shot retains the full board and carriers.
		for v in b.views.values():
			v.visible = v == sv
		if sv.marker != null: sv.marker.visible = false
		b.board.visible = false
		if b.gfx != null: b.gfx.visible = false
		b.cam.r = 29.0
		b.cam.b = 0.78
		b.cam.a = -1.1
		b.cam.t = sv.global_position + Vector3(-1, 0, 0)
		b.cam.snap()
		await _snap(fac + "_close")
		b.cam.b = 1.28
		b.cam.a = -0.3
		b.cam.snap()
		await _snap(fac + "_low")
		b.cam.b = 0.3
		b.cam.a = -PI / 2.0
		b.cam.snap()
		await _snap(fac + "_top")
		# Both player-selectable craft types on the three flexible factions.
		if fac in ["voidsworn", "hegemony", "ithar"]:
			var other := "fighter" if sv.squad_visual.kind == "bomber" else "bomber"
			var extra := SV.new()
			b.add_child(extra)
			extra.setup({"id": "review_extra", "fac": fac, "tpl": other, "cls": "Squadron", "facing": 0}, sv.position)
			extra.rotation.y = sv.rotation.y
			sv.visible = false
			b.cam.b = 0.78
			b.cam.a = -1.1
			b.cam.snap()
			await _snap(fac + "_" + other + "_close")
			extra.free()
			sv.visible = true
		if frames != "": await _motion(b, sv, fac)
		print("SQUADRON_CAPTURE %s wings=%d kind=%s" % [fac, wings.size(), sv.squad_visual.kind])
	b.queue_free()
	for i in 5: await process_frame

func _motion(b, sv, fac: String) -> void:
	# Four seconds each: launch, form up, then a curved bank. Fixed simulation
	# time makes motion review independent of screenshot encoding speed.
	b.cam.b = 0.78
	b.cam.a = -1.1
	b.cam.r = 39.0
	b.cam.t = sv.global_position + Vector3(-5, 0, 0)
	b.cam.snap()
	vp.size = Vector2i(1280, 720)
	for v in b.views.values(): v.set_process(false)
	sv.squadron_launch(sv.global_position + Vector3(-18, 0, 0))
	var start: Vector3 = sv.position
	var yaw0: float = sv.rotation.y
	var target := frames.path_join(fac)
	DirAccess.make_dir_recursive_absolute(target)
	for i in 96:
		var t := i / 24.0
		if t > 2.0:
			var q := (t - 2.0) / 2.0
			sv.position = start + Vector3(sin(q * PI) * 4.0, 0, sin(q * PI * 0.5) * 5.0)
			sv.rotation.y = yaw0 + sin(q * PI * 0.5) * 0.8
		sv.squad_visual.step(1.0 / 24.0, false)
		await RenderingServer.frame_post_draw
		var img := vp.get_texture().get_image()
		img.save_png(target.path_join("%04d.png" % i))
	vp.size = Vector2i(2560, 1440)

func _snap(name: String) -> void:
	for i in 5: await RenderingServer.frame_post_draw
	if vp.get_texture().get_image().save_png(out.path_join(name + ".png")) != OK:
		push_error("Could not save squadron capture: " + name)
		quit(1)
