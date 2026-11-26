extends SceneTree
# Issue 1360 (Ryan's pick B): storm lightning plays animated bolts baked in Blender (tools/blender/vfx/bake_storm_bolts.py).
# Checks, headless:
#   - every variant's atlas loads (fx/atlases/storm/bolt_<v>.png), is 4x4 cells of the manifest's size, lights up at its
#     return-stroke frame (BOLT_PEAK matches the manifest) and is dark again by its last frame;
#   - the frame clock: a strike runs frames 0 to 15 over BOLT_LIFE, then stops; a reduced or refused strike holds the
#     return-stroke frame under the old soft peak (0.22), with no flicker;
#   - the card puts the bolt's main channel on the ribbon's own start and end points;
#   - in a real battle with a storm, the bolts are baked cards on the flipbook shader with an atlas, at the same places as
#     the ribbon (VS_STORM_BOLTS=ribbon) and leaving the rest of the layout untouched, and a strike on the effects clock
#     (fx.now) plays its frames, swaps variant, and still lights the storm gas.

const GUARD := preload("res://tools/ci/check_guard.gd")
const API := preload("res://rules/battle_api.gd")
const LOOK := preload("res://world/board_look.gd")
const LIVING := preload("res://world/world_living.gd")
const BATTLE := preload("res://scenes/battle/battle.gd")
const STEP := 1.0 / 60.0
const SEED := 4103

var failures := 0


func _init() -> void:
	GUARD.arm(self, "storm_bolt_check")
	_run.call_deferred()


func _check(ok: bool, message: String) -> void:
	if ok:
		print("  ok: ", message)
	else:
		failures += 1
		printerr("FAIL: ", message)


func _atlases() -> void:
	var manifest_path: String = LIVING.BOLT_ATLAS_DIR + "bake_manifest.json"
	_check(FileAccess.file_exists(manifest_path), "the bake manifest is there")
	var manifest = JSON.parse_string(FileAccess.get_file_as_string(manifest_path))
	if not manifest is Dictionary:
		_check(false, "the bake manifest reads")
		return
	_check(int(manifest["frames"]) == LIVING.BOLT_FRAMES and int(manifest["grid"]) == LIVING.BOLT_GRID, "manifest frames and grid match the game")
	_check(is_equal_approx(float(manifest["bolt_top"]) - float(manifest["bolt_bottom"]), LIVING.BOLT_FILL), "the main channel fills BOLT_FILL of a tile")
	var cell := int(manifest["cell"])
	for key in LIVING.BOLT_VARIANTS:
		var v: Dictionary = manifest["variants"].get(key, {})
		_check(not v.is_empty() and str(v.get("code", "")).begins_with("STB-"), "variant %s has a code name (%s)" % [key, v.get("code", "")])
		var curve: Array = v.get("main_brightness", [])
		var peak := 0
		for i in curve.size():
			if float(curve[i]) > float(curve[peak]): peak = i
		_check(curve.size() == LIVING.BOLT_FRAMES and peak == int(LIVING.BOLT_PEAK[key]), "variant %s: BOLT_PEAK %d is its brightest frame (%d)" % [key, LIVING.BOLT_PEAK[key], peak])
		var tex: Texture2D = LIVING.bolt_atlas(key)
		_check(tex != null, "variant %s: the atlas loads" % key)
		if tex == null:
			continue
		_check(tex.get_width() == cell * LIVING.BOLT_GRID and tex.get_height() == cell * LIVING.BOLT_GRID, "variant %s: the atlas is 4x4 cells of %d px" % [key, cell])
		var img := tex.get_image()
		if img.is_compressed(): img.decompress()
		var lit := _cell_max(img, int(LIVING.BOLT_PEAK[key]), cell)
		var last := _cell_max(img, LIVING.BOLT_FRAMES - 1, cell)
		_check(lit.r > 0.9 and lit.b > 0.5 and lit.a > 0.3, "variant %s: the return stroke is hot with both glows (%s)" % [key, lit])
		_check(last.r < 0.02 and last.g < 0.02, "variant %s: the last frame is dark (%s)" % [key, last])


func _cell_max(img: Image, frame: int, cell: int) -> Color:
	var x0 := (frame % LIVING.BOLT_GRID) * cell
	var y0 := (frame / LIVING.BOLT_GRID) * cell
	var m := Color(0, 0, 0, 0)
	for y in range(y0, y0 + cell, 2):
		for x in range(x0, x0 + cell, 2):
			var c := img.get_pixel(x, y)
			m = Color(maxf(m.r, c.r), maxf(m.g, c.g), maxf(m.b, c.b), maxf(m.a, c.a))
	return m


func _clock() -> void:
	_check(LIVING.bolt_frame(-0.01, false, 0).y == 0.0, "nothing before a strike")
	var last := -1.0
	var seen := {}
	var t := 0.0
	while t < LIVING.BOLT_LIFE:
		var fg: Vector2 = LIVING.bolt_frame(t, false, 0)
		if fg.x < last or fg.y != 1.0:
			_check(false, "frames run forward at full gain (%.3f s: frame %d)" % [t, fg.x])
			break
		last = fg.x
		seen[int(fg.x)] = true
		t += STEP
	_check(seen.size() == LIVING.BOLT_FRAMES, "a strike shows all %d frames at 60 fps (%d)" % [LIVING.BOLT_FRAMES, seen.size()])
	_check(LIVING.bolt_frame(LIVING.BOLT_LIFE + 0.001, false, 0).y == 0.0, "the strike stops after BOLT_LIFE")
	var top := 0.0
	for i in 80:
		var fg: Vector2 = LIVING.bolt_frame(i * STEP, true, 1)
		if fg.y > 0.0 and int(fg.x) != int(LIVING.BOLT_PEAK["b"]):
			_check(false, "a soft strike holds the return-stroke frame (%d)" % fg.x)
		top = maxf(top, fg.y)
	_check(top > 0.15 and top <= 0.22 + 1e-4, "a soft strike peaks under the old soft envelope (%.3f)" % top)
	var a := Vector3(3, 20, -4)
	var z := Vector3(10, 12, 3)
	var xf: Transform3D = LIVING.bolt_card_transform(a, z)
	var half := LIVING.BOLT_FILL * 0.5
	_check((xf * Vector3(0, half, 0)).distance_to(a) < 1e-3 and (xf * Vector3(0, -half, 0)).distance_to(z) < 1e-3, "the card's main channel runs from the bolt's start to its end")
	_check(absf(xf.basis.x.dot(xf.basis.y)) < 1e-3 and absf(xf.basis.z.dot(xf.basis.y)) < 1e-3 and absf(xf.basis.x.length() - xf.basis.y.length()) < 1e-3, "the card is square and square to its axis")


func _battle(style: String):
	OS.set_environment("VS_STORM_BOLTS", style)
	var api := API.new()
	var error := api.load_rules()
	if error != "":
		_check(false, error)
		return null
	var scenarios: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://rules/test/scenarios.json"))
	var scenario: Dictionary = scenarios["s1"]
	scenario["alt"] = false
	api.new_battle_scenario(scenario, SEED)
	var terrain: Dictionary = api.R.B["terrain"]
	terrain.clear()
	for q in range(-2, 3):
		terrain["%d,0" % q] = "storm"
	terrain["0,2"] = "storm"
	terrain["4,-3"] = "storm"
	terrain["-4,3"] = "debris"
	var battle = BATTLE.new()
	battle.external = true
	battle.showcase = true
	battle.args["quality"] = "max"
	root.add_child(battle)
	await battle._begin(api)
	battle.cam.t = Vector3.ZERO
	battle.cam.r = 170.0
	battle.cam.snap()
	return battle


func _layout(living) -> Array:
	var out: Array = []
	for b in living.bolts:
		out.append([b.pos, b.path, b.fork_paths])
	for child in living.get_children():
		if child is MultiMeshInstance3D and (child as MultiMeshInstance3D).multimesh != null:
			var mm := (child as MultiMeshInstance3D).multimesh
			out.append([mm.instance_count, mm.get_instance_transform(0) if mm.instance_count > 0 else null])
	return out


func _in_battle() -> void:
	var ribbon = await _battle("ribbon")
	if ribbon == null: return
	var old_living = ribbon.world._living
	_check(old_living != null and old_living.bolt_style == "ribbon" and not old_living.bolts.is_empty(), "VS_STORM_BOLTS=ribbon keeps the old ribbon")
	if old_living == null or old_living.bolts.is_empty():
		ribbon.free()
		return
	var rb: Dictionary = old_living.bolts[0]
	_check(rb.mi.mesh is ArrayMesh and (rb.mi.material_override as ShaderMaterial).shader == LIVING.BOLT_SHADER, "the ribbon draws its own mesh and shader")
	var before := _layout(old_living)
	var count: int = old_living.bolts.size()
	ribbon.free()

	var battle = await _battle("")
	if battle == null: return
	var living = battle.world._living
	_check(living != null and living.bolt_style == "baked", "storms use the baked bolts by default")
	if living == null:
		battle.free()
		return
	_check(living.bolts.size() == count and str(_layout(living)) == str(before),
		"baked bolts sit where the ribbon did (%d bolts) and the rest of the layout is unchanged" % living.bolts.size())
	for b in living.bolts:
		var mi: MeshInstance3D = b.mi
		var m := mi.material_override as ShaderMaterial
		_check(mi.mesh is QuadMesh and m != null and m.shader == LIVING.BOLT_FLIP_SHADER and m.get_shader_parameter("atlas") is Texture2D,
			"bolt %s is a card on the flipbook shader with an atlas" % mi.name)
		_check(mi.is_visible_in_tree() and mi.custom_aabb.size != Vector3.ZERO, "the card is drawn and has bounds")
	# One strike on every storm patch, on the effects clock.
	var gfx = battle.gfx
	_check(gfx != null, "the battle has its effects clock")
	if gfx == null:
		battle.free()
		return
	for reduced in [false, true]:
		battle.reduce_flashing = reduced
		gfx.reduce_flashing = reduced
		gfx._flashes.clear()
		gfx.flash_cands.clear()
		var variants := []
		for b in living.bolts: variants.append(b.variant)
		for burst in living._storm_bursts: burst.next = gfx.now
		var frames := {}
		var gains := {}
		var lit_gas := false
		for step in 90:
			gfx.now += STEP
			living._process(STEP)
			for i in living.bolts.size():
				var b: Dictionary = living.bolts[i]
				if float(b.gain) > 0.0:
					if not frames.has(i): frames[i] = {}
					frames[i][int(b.frame)] = true
					gains[i] = maxf(gains.get(i, 0.0), float(b.gain))
			for mat in living.storm_mats:
				var fl = mat.get_shader_parameter("flashes")
				if fl is Array and not fl.is_empty() and (fl[0] as Vector4).w > 0.0: lit_gas = true
			for burst in living._storm_bursts: burst.next = INF
		var tag := "Reduced Flashing" if reduced else "Standard"
		_check(frames.size() == living.bolts.size(), "%s: every bolt strikes (%d of %d)" % [tag, frames.size(), living.bolts.size()])
		var full := 0
		for i in frames:
			var b: Dictionary = living.bolts[i]
			if gains[i] >= 1.0 and frames[i].size() >= LIVING.BOLT_FRAMES - 1: full += 1
			elif not (gains[i] <= 0.22 + 1e-4 and frames[i].size() == 1):
				_check(false, "%s: bolt %d plays either the whole strike or the soft hold (%d frames, gain %.2f)" % [tag, i, frames[i].size(), gains[i]])
			if b.variant == variants[i] or b.mi.material_override != living._bolt_mats[b.variant]:
				_check(false, "%s: bolt %d moves to its next variant" % [tag, i])
		_check(full > 0 if not reduced else full == 0, "%s: %d bolts play the whole strike" % [tag, full])
		_check(lit_gas, "%s: a strike still lights the storm gas" % tag)
		var done := true
		for b in living.bolts:
			if float(b.gain) > 0.0: done = false
		_check(done, "%s: every strike has ended 1.5 s later" % tag)
	battle.free()


func _run() -> void:
	OS.set_environment("VS_NEBULA_ROUTE", "fog")
	LOOK.set_look("cine", false)
	_atlases()
	_clock()
	await _in_battle()
	OS.set_environment("VS_STORM_BOLTS", "")
	if failures == 0:
		print("storm bolts: PASS (atlases, frame clock, card, in battle Standard and Reduced Flashing, ribbon fallback)")
	else:
		print("storm bolts: FAIL (%d)" % failures)
	quit(0 if failures == 0 else 1)
