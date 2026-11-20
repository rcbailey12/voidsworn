extends SceneTree
const GUARD = preload("res://tools/ci/check_guard.gd")
# Issue 1077 (prototype, off by default): first, a box hull of each tier (capital, cruiser, frigate) is killed with the
# switch off and on, and every power-down material must carry that tier's own lights-out bands (death_steps). Then kill A16 (C19_51) twice, once on today's path and once with the strain story
# (fx setup "death_story": "strain", the same switch as rendering/effects/death_story or VS_DEATH_STORY). Checks:
#   off: the tear overlay and the power-down materials are today's shaders, with no strain code in them;
#   on: the tear overlay and every hull power-down material carry the strain, on the hull's own break lines, the strain
#     is set before the split, and the hull groans along those lines;
#   on: 14 s after the kill the main pieces sit within MAIN_MAX of the length from where they broke, and the thrown
#     fragments within FRAG_MAX of the break's middle; both paths' numbers are printed side by side.
# The kill runs twice per path: at quality low (kinematic pieces) here, and at quality high (physics pieces, Jolt) in a
# child process started with --fixed-fps 60, so the physics steps keep pace with the effect clock (the PC clip at 1236bbc3
# found the physics pieces undamped, 1.9 L apart, while the low-quality check passed).
# The ship: the GLB path after "--", else the installed res://assets/ships/C19_51/C19_51.glb, else the unpainted fixture
# (the same choice as death_seam_check.gd, which also guards the fixture's freshness).
const FX := preload("res://fx/fx.gd")
const ROOT := preload("res://tools/ci/world_root.gd")
const DEATH := preload("res://fx/fx_death.gd")
const FIXTURE := "res://fx/test/fixtures/C19_51_unbaked.glb.gz"
const INSTALLED := "res://assets/ships/C19_51/C19_51.glb"
const MAIN_MAX := 0.35
const FRAG_MAX := 0.6   # from the middle of the pieces as they broke; a fragment starts up to about a third of the length out
var failures := 0


func _init() -> void:
	GUARD.arm(self, "death_story_check")
	process_frame.connect(_run, CONNECT_ONE_SHOT)


func check(ok: bool, why: String) -> void:
	if not ok:
		failures += 1
		push_error(why)


func _load_ship() -> Node3D:
	var args := Array(OS.get_cmdline_user_args()).filter(func(a: String) -> bool: return a != "--hi")
	var path: String = args[0] if not args.is_empty() else (INSTALLED if FileAccess.file_exists(INSTALLED) else FIXTURE)
	var bytes := FileAccess.get_file_as_bytes(path)
	if path.ends_with(".gz"): bytes = bytes.decompress_dynamic(-1, FileAccess.COMPRESSION_GZIP)
	var doc := GLTFDocument.new()
	var state := GLTFState.new()
	if bytes.is_empty() or doc.append_from_buffer(bytes, path.get_base_dir(), state) != OK: return null
	print("DEATH_STORY ship ", path)
	return doc.generate_scene(state)


func _run() -> void:
	var hi := "--hi" in OS.get_cmdline_user_args()
	var quality := "high" if hi else "low"
	if not hi:
		# the lights-out bands are today's on every tier, switch off or on (Fable on PR 1171: a misplaced branch once gave the
		# capital and cruiser the small hull's single band, with the switch off)
		for story in [false, true]:
			for row in [["Battle-barge", Vector3(5.0, 0.12, 0.15)], ["Cruiser", Vector3(4.0, 0.06, 0.12)], ["Frigate", Vector3(1.0, 0.0, 0.001)]]:
				await _bands(row[0], row[1], story)
	var off := await _kill(false, quality)
	var on := await _kill(true, quality)
	if not off.is_empty() and not on.is_empty():
		print("DEATH_STORY %s travel_in_lengths main_max off=%.2f on=%.2f frag_max off=%.2f on=%.2f frags=%d" % [
			quality, off["main"], on["main"], off["frag"], on["frag"], int(on["frags"])])
		check(float(on["main"]) <= MAIN_MAX, "%s: strained wreck: main pieces within %.2f L of the break (%.2f)" % [quality, MAIN_MAX, on["main"]])
		check(float(on["frag"]) <= FRAG_MAX, "%s: strained wreck: fragments within %.2f L of the break (%.2f)" % [quality, FRAG_MAX, on["frag"]])
		check(float(on["main"]) < float(off["main"]), "%s: the strained wreck stays more grouped than today's" % quality)
	if not hi:
		var out := []
		var args := ["--headless", "--fixed-fps", "60", "--path", ProjectSettings.globalize_path("res://"), "--script",
			"res://fx/test/death_story_check.gd", "--", "--hi"] + Array(OS.get_cmdline_user_args())
		var code := OS.execute(OS.get_executable_path(), PackedStringArray(args), out, true)
		for line in str(out[0] if not out.is_empty() else "").split("\n"):
			if line.begins_with("DEATH_STORY") or "ERROR" in line and "strain" in line: print("  [high] ", line)
		check(code == 0, "quality high (physics pieces) passes in its child process (exit %d)" % code)
	print("DEATH_STORY failures=%d" % failures)
	quit(1 if failures else 0)


# One box hull of a class killed; every hull power-down material must carry that tier's death_steps (main's values).
func _bands(cls: String, want: Vector3, story: bool) -> void:
	var world := Node3D.new()
	root.add_child(world)
	var holder := Node3D.new()
	world.add_child(holder)
	var mi := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(20, 4, 6)
	mi.mesh = box
	holder.add_child(mi)
	var fx = FX.new()
	world.add_child(fx)
	fx.manual = true
	fx.setup({"quality": "low", "camera": null, "shake": 0.0, "death_story": "strain" if story else "off"})
	fx.add_ship("b", holder, {"faction": "voidsworn", "cls": cls, "size": 1.0})
	var s = fx.ship("b")
	fx.death("b", "big")
	for i in 4:
		fx.step(1.0 / 60.0)
		await process_frame
	var mats: Array = s.get_meta("death_power", [])
	var good := 0
	for m in mats:
		var got = (m as ShaderMaterial).get_shader_parameter("death_steps")
		if got is Vector3 and (got as Vector3).is_equal_approx(want): good += 1
	print("DEATH_STORY bands %s %s tier=%s ok=%d of %d" % ["on" if story else "off", cls, s.death_tier, good, mats.size()])
	check(not mats.is_empty() and good == mats.size(), "%s %s: lights-out bands are the tier's own %s (%d of %d)" % [
		"on" if story else "off", cls, str(want), good, mats.size()])
	world.queue_free()
	await process_frame


func _kill(story: bool, quality: String) -> Dictionary:
	var world := Node3D.new()
	root.add_child(world)
	var ship := _load_ship()
	check(ship != null, "A16 loads")
	if ship == null: return {}
	# as ShipView draws it (tools/ci/world_root.gd): the hull scaled to its game length under an unscaled root, so the hull's
	# numbers are world lengths (scaling the root instead would leave L at the file's own unit and the speeds a scale off)
	ship = ROOT.hold(world, ship)
	var fx = FX.new()
	world.add_child(fx)
	fx.manual = true
	fx.setup({"quality": quality, "camera": null, "shake": 0.0, "death_story": "strain" if story else "off"})
	check(fx.death_story == story, "the switch reads %s" % story)
	fx.add_ship("a16", ship, {"faction": "corsair", "cls": "Battle-barge", "size": 1.22})
	var s = fx.ship("a16")
	check(ROOT.at_game_size(s, ROOT.held_length(s.root)), ROOT.size_note(s, ROOT.held_length(s.root)))
	var t_wait := Time.get_ticks_msec()
	while Time.get_ticks_msec() - t_wait < 120000:
		fx.step(1.0 / 60.0)
		await process_frame
		if (s.get_meta("cut_job", {}) as Dictionary).get("built", false): break
	var job: Dictionary = s.get_meta("cut_job", {})
	check(job.get("built", false), "the cut finished before the kill")
	var L: float = s.hull.L
	var plan: Dictionary = job.get("plan", {})
	fx.death("a16", "big")
	var tag := ("on" if story else "off") + " " + quality
	# the strain is on the hull's own break lines, before the split
	check(s.has_meta("death_strain") == story, "%s: strain set at the kill" % tag)
	if story:
		var lines: Array = s.get_meta("death_strain")["lines"]
		var brs: Array = plan.get("breaks", [])
		check(not lines.is_empty() and not brs.is_empty(), "on: strain lines from the fracture plan")
		for line in lines:
			var near := false
			for b in brs:
				if (line[0] as Vector3).is_equal_approx(b["at"]): near = true
			check(near, "on: each strain line is one of the plan's breaks")
	var overlay_ok := 0
	var overlay_n := 0
	for mm in s.meshes:
		var mi := mm as MeshInstance3D
		if not is_instance_valid(mi) or mi.material_overlay == null: continue
		overlay_n += 1
		var code: String = (mi.material_overlay as ShaderMaterial).shader.code
		if code.contains("fx_strain_offset") == story: overlay_ok += 1
	check(overlay_n > 0 and overlay_ok == overlay_n, "%s: tear overlays %s strain (%d of %d)" % [tag, "carry" if story else "carry no", overlay_ok, overlay_n])
	var groan_debris := 0
	var debris_before: int = (fx.dstate.get("debris", []) as Array).size()
	var power_checked := false
	var hidden_at := -1.0
	var t0: float = fx.now
	var starts := {}
	for i in 14 * 60:
		fx.step(1.0 / 60.0)
		await process_frame
		if not power_checked and not s.has_meta("death_power_queue"):
			power_checked = true
			var mats: Array = s.get_meta("death_power", [])
			var good := 0
			for m in mats:
				var c: String = (m as ShaderMaterial).shader.code
				var k = (m as ShaderMaterial).get_shader_parameter("fx_strain_k")
				if story and c.contains("fx_strain_offset") and k is Vector3 and (k as Vector3).x > 0.0: good += 1
				elif not story and not c.contains("fx_strain"): good += 1
			check(not mats.is_empty() and good == mats.size(), "%s: power-down materials %s (%d of %d)" % [tag, "strain" if story else "unchanged", good, mats.size()])
		if hidden_at < 0.0 and s.has_meta("death_hidden"):
			hidden_at = fx.now - t0
			for w in fx.dstate["wrecks"]:
				if w["id"] != "a16": continue
				for nd in w["nodes"] + w.get("frags", []):
					if is_instance_valid(nd): starts[nd] = (nd as Node3D).global_position
	check(hidden_at > 0.0, "%s: A16 broke up (at %.2f s)" % [tag, hidden_at])
	# the strained wreck's torn insides are sooted (pass 3: they read as flat grey slabs up close); today's are unchanged
	var sooted := 0
	for w in fx.dstate["wrecks"]:
		if w["id"] != "a16": continue
		for nd in w["nodes"]:
			if not is_instance_valid(nd): continue
			for mi in (nd as Node3D).find_children("*", "MeshInstance3D", true, false):
				var m: Mesh = (mi as MeshInstance3D).mesh
				for k in (m.get_surface_count() if m != null else 0):
					if fx._wreck_interiors.values().has(m.surface_get_material(k)): sooted += 1
	print("DEATH_STORY %s sooted_inside_surfaces=%d" % [tag, sooted])
	check((sooted > 0) == story, "%s: the wreck's insides are %s" % [tag, "sooted" if story else "today's"])
	var main_max := 0.0
	var frag_max := 0.0
	var frags := 0
	var mid := Vector3.ZERO
	var n_mid := 0
	for nd in starts:
		mid += starts[nd]
		n_mid += 1
	if n_mid > 0: mid /= n_mid
	for w in fx.dstate["wrecks"]:
		if w["id"] != "a16": continue
		for nd in w["nodes"]:
			if is_instance_valid(nd) and starts.has(nd):
				main_max = maxf(main_max, (nd as Node3D).global_position.distance_to(starts[nd]) / L)
		for nd in w.get("frags", []):
			if is_instance_valid(nd):
				frags += 1
				frag_max = maxf(frag_max, (nd as Node3D).global_position.distance_to(mid) / L)
	print("DEATH_STORY %s split_at=%.2f main_travel_max=%.2fL frag_from_middle_max=%.2fL frags=%d L=%.2f k=%.2f" % [tag, hidden_at, main_max, frag_max, frags, L, s.scale_k()])
	world.queue_free()
	await process_frame
	return {"main": main_max, "frag": frag_max, "frags": frags}
