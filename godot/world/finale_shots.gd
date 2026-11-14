extends SceneTree
# R78 Q18 capture harness: the run 5 finale board brightening sector by sector as the new sun catches. Builds the battle
# world on its own (no ships, so a checkout without godot/gen still captures the board and lights), saves one PNG per
# stage of the dawn sweep, and quits.
#
#   godot --path godot --resolution 1280x720 --script res://world/finale_shots.gd -- --out DIR
#
# The battle itself drives the stages from its round events (godot/world/world.gd finale_for_round); this harness calls
# finale_stage() directly so every stage can be seen.

const WORLD := preload("res://world/world.gd")

var out := "user://finale_shots"


func _init() -> void:
	process_frame.connect(_run, CONNECT_ONE_SHOT)


func _run() -> void:
	var a := OS.get_cmdline_user_args()
	var i := 0
	while i < a.size():
		if a[i] == "--out" and i + 1 < a.size():
			out = a[i + 1]
			i += 2
		else:
			i += 1
	DirAccess.make_dir_recursive_absolute(out)

	var stage_root := Node3D.new()
	stage_root.name = "FinaleStage"
	root.add_child(stage_root)

	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(1, 1, 1)
	env.ambient_light_energy = 0.5
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.tonemap_white = 8.0
	env.glow_enabled = true
	env.glow_hdr_threshold = 0.8
	env.glow_intensity = 0.6
	var we := WorldEnvironment.new()
	we.environment = env
	stage_root.add_child(we)

	var key := DirectionalLight3D.new()
	key.transform = Transform3D(Basis.looking_at(Vector3(-0.45, -0.70, -0.55).normalized(), Vector3.UP), Vector3.ZERO)
	key.light_color = Color(1.0, 0.96, 0.90)
	key.light_energy = 2.0
	key.shadow_enabled = true
	key.directional_shadow_max_distance = 600.0
	stage_root.add_child(key)
	var fill := DirectionalLight3D.new()
	fill.transform = Transform3D(Basis.looking_at(Vector3(0.6, -0.2, 0.75).normalized(), Vector3.UP), Vector3.ZERO)
	fill.light_color = Color(0.55, 0.65, 0.85)
	fill.light_energy = 0.5
	stage_root.add_child(fill)

	var cam := Camera3D.new()
	cam.fov = 55.0
	cam.near = 0.5
	cam.far = 4000.0
	stage_root.add_child(cam)
	cam.look_at_from_position(Vector3(0, 235, 370), Vector3(0, -6, 0), Vector3.UP)
	cam.current = true

	var hs := 10.0
	var hw := func(q: int, r: int) -> Vector3: return Vector3(hs * sqrt(3.0) * (q + r * 0.5), 0.0, 1.5 * hs * r)
	var terrain := {}
	for q in range(-8, 9):
		for r in range(-6, 7):
			terrain["%d,%d" % [q, r]] = ""
	var rocks := [[-7, -4], [-6, -4], [-7, -3], [-6, -3], [7, -4], [6, -4], [7, -3], [6, -3], [-8, 3], [8, 3], [-2, -5], [2, -5]]
	for k in rocks:
		terrain["%d,%d" % [k[0], k[1]]] = "rock"
	for k in [[-5, 2], [5, 2], [0, 4], [-1, 5], [1, 5], [-3, -1], [3, -1]]:
		terrain["%d,%d" % [k[0], k[1]]] = "debris"

	var w = WORLD.new()
	stage_root.add_child(w)
	w.build({"terrain": terrain, "map": {"deadstar": {"q": -6, "r": -5}}, "units": []},
		{"biome": {"rock": "ice", "planet": 7}, "fac": "deathless", "hex_world": hw, "environment": env,
		"quality": "max", "finale": true})
	await w.wait_ready()
	print("[finale_shots] finale=", w.finale, " children=", w.get_child_count(), " dawnie=", w._dawn_mat != null, " notes=", "; ".join(w.notes))
	for k in 30:
		await process_frame

	for s in 6:
		w.finale_stage(s)
		for k in 24:
			await process_frame
		await RenderingServer.frame_post_draw
		var img := root.get_texture().get_image()
		var p := out.path_join("finale_board_%d_of_6.png" % [s + 1])
		img.save_png(p)
		print("[finale_shots] ", p)

	# a wide view at full dawn, framed on the board and the Hollow Sun
	cam.look_at_from_position(Vector3(0, 420, 700), Vector3(-40, 0, -20), Vector3.UP)
	for k in 24:
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out.path_join("finale_board_wide.png"))
	print("[finale_shots] ", out.path_join("finale_board_wide.png"))
	print("[finale_shots] done")
	quit(0)
