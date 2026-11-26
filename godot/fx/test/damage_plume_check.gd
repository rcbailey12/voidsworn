extends SceneTree

const GUARD := preload("res://tools/ci/check_guard.gd")
const FX := preload("res://fx/fx.gd")
const BREACH := preload("res://fx/fx_breach.gd")
const PLUME := preload("res://fx/fx_damage_plume.gd")
const WEAP := preload("res://fx/fx_weapons.gd")
const VIEW := preload("res://render/ship_view.gd")
const FACTIONS := ["voidsworn", "corsair", "hegemony", "deathless", "chorus", "ithar"]

var failures := 0
var world: Node3D
var fx


func _init() -> void:
	GUARD.arm(self, "damage_plume_check")
	_run.call_deferred()


func _check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)


func _setup() -> void:
	world = Node3D.new()
	root.add_child(world)
	fx = FX.new()
	world.add_child(fx)
	fx.manual = true
	fx.setup({"quality": "high", "death_story": "off", "shake": 0.0})


func _ship(faction: String):
	var body := Node3D.new()
	world.add_child(body)
	var core := Marker3D.new()
	core.name = "hp_core"
	body.add_child(core)
	var part := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(24, 5, 8)
	part.mesh = box
	body.add_child(part)
	fx.add_ship("T", body, {"faction": faction, "cls": "Battleship", "size": 1.0, "meshes": [part], "shielded": false})
	var s = fx.ship("T")
	for i in 3:
		s._anchors["a%d" % i] = {"p": Vector3(7 * (i - 1), 2.5, 0), "n": Vector3.UP, "t": {}}
	return s


func _material(e: Dictionary) -> ShaderMaterial:
	var m: ShaderMaterial = e.mat
	_check(m.get_shader_parameter("colour_atlas") is Texture2D, "live emitter samples the baked vent colour atlas")
	_check(m.get_shader_parameter("heat_atlas") is Texture2D, "live emitter samples baked vent heat separately")
	_check(e.node is MeshInstance3D and e.node.mesh is QuadMesh and e.particles == 1, "one plume card, no loose sprite batch")
	return m


func _check_wounds(faction: String) -> void:
	_setup()
	var s = _ship(faction)
	# Allocator entry is the same one sync_ship reaches, independent of geometry rebuild timing.
	s.stage = [0, 1, 0]
	s._refresh_damage_emitters(fx)
	var scorch: Dictionary = s._damage_emitters[0]
	var m := _material(scorch)
	_check(scorch.form == PLUME.Form.SCORCH and m.get_shader_parameter("core_power") == 0.0, "stage 1 is cold")
	fx.step(PLUME.SCORCH_LIFE + 0.01)
	await process_frame
	_check(not is_instance_valid(scorch.node), "stage 1 has no permanent emitter")
	s.stage = [2, 1, 0]
	s._refresh_damage_emitters(fx)
	_check(not is_instance_valid(scorch.node) and s.damage_counts().particles == 1, "unrelated damage does not replay stage 1")
	s.stage = [0, 2, 0]
	s._refresh_damage_emitters(fx)
	var dent: Dictionary = s._damage_emitters[0]
	m = _material(dent)
	_check(dent.form == PLUME.Form.DENT and m.get_shader_parameter("core_power") == 0.0, "stage 2 has a sheath, no flame")
	var glow: Color = s.fac.damage_glow
	var accent: Color = BREACH.wound_col(s.fac.wound, "interior_accent", glow)
	var core_tint := accent if faction in ["hegemony", "deathless", "chorus"] else glow
	for st in [3, 4]:
		s.stage = [0, st, 0]
		s._refresh_damage_emitters(fx)
		var wound: Dictionary = s._damage_emitters[0]
		m = _material(wound)
		var core: Vector3 = m.get_shader_parameter("colour_core")
		var sheath: Vector3 = m.get_shader_parameter("colour_sheath")
		var power: float = m.get_shader_parameter("core_power")
		_check(core.is_equal_approx(Vector3(core_tint.r, core_tint.g, core_tint.b)), faction + " uses its existing wound colour")
		_check(power == 0.0 if faction == "ithar" else power > 0.0, faction + " only has its permitted core")
		_check(faction != "ithar" or sheath.x > 0.20 and sheath.z >= sheath.x, "glass sheath is pale, not soot")
		_check(faction != "deathless" or (core.z > core.x and sheath.z > sheath.x), "Eclipse core and sheath stay violet")
		_check(faction != "hegemony" or (core.z > core.y and core.y > core.x and sheath.z > sheath.x),
			"Meridian wounds use cold blue ionisation and vapour, not gold fire or soot")
		_check(faction != "chorus" or (core.x > core.y and sheath.x > sheath.y and sheath.y > sheath.z and power < 0.6),
			"Chorus keeps ochre wound gas and a faint organic pulse")
		_check(m.get_shader_parameter("core_clip") <= 0.70 and m.get_shader_parameter("period") > 0.70,
			"hot core goes out before 0.70 seconds with cold time between pulses")
		_check(wound.form == PLUME.Form.WOUND and s.damage_counts().fire == 1 and s.damage_counts().smoke == 0,
			"stages 3 and 4 combine core and sheath instead of duplicating smoke")
		var anchor: Dictionary = s._anchor(1, "a")
		var offset: Vector3 = wound.source - anchor.p
		_check(offset.dot(anchor.n) < 0.0 if st == 4 else offset.is_zero_approx(), "previous wound placement is preserved")
		_check(wound.light.col == core_tint and wound.light.local_only and is_equal_approx(wound.light.reach * fx.unit, s.hull.L * 0.13),
			"wound light is local, follows the hull, and uses its existing colour")
		var vent: Dictionary = s._damage_emitters[1]
		_check(vent.form == PLUME.Form.VENT and _material(vent).get_shader_parameter("core_power") == 0.0, "heavy vent stays cold")
	# A dead mount/nozzle and jammed turret go through the same plume builder with their own points.
	var mount := Vector3(2, 3, 1)
	var e := {"id": "mount", "mp": mount}
	s._build_wisp(fx, e)
	var wisp := _material(e)
	_check(e.form == PLUME.Form.WISP and e.source == mount, "wisp starts at its own hard point")
	var wisp_sheath: Vector3 = wisp.get_shader_parameter("colour_sheath")
	_check(faction != "chorus" or (wisp_sheath.x > wisp_sheath.y and wisp_sheath.y > wisp_sheath.z), "Chorus mount wisp stays ochre")
	_check(faction != "hegemony" or (wisp_sheath.z > wisp_sheath.y and wisp_sheath.y > wisp_sheath.x), "Meridian mount wisp stays cold blue")
	await process_frame
	fx.step(0.1)
	var lamp: OmniLight3D = fx._lpool[0]
	_check(lamp.visible and lamp.omni_range < s.hull.L * 0.14 and lamp.light_volumetric_fog_energy == 0.0,
		"wound light uses the bounded pool, with no fog scattering")
	var cavity: Dictionary = fx.light_source(s.root, Vector3.LEFT * 2.0, Color.WHITE, 0.12, 0.0, 1.7)
	fx.light(Vector3.RIGHT * 2.0, fx.now, 0.5, 0.12, Color.WHITE, 1)
	fx.step(0.1)
	var found_cavity := false
	for i in [1, 2]:
		var other: OmniLight3D = fx._lpool[i]
		_check(other.light_volumetric_fog_energy == 1.0, "local wound light does not use either fog slot")
		if other.global_position.is_equal_approx(Vector3.LEFT * 2.0):
			found_cavity = is_equal_approx(other.omni_range, 1.7 * fx.unit) and is_equal_approx(other.omni_attenuation, fx.REACH_ATTEN)
	_check(found_cavity, "the cavity light keeps main's range, reach falloff and fog with the six-argument call")
	cavity.on = false
	fx._lev.clear()
	fx.reduce_flashing = true
	fx.step(0.1)
	_check(fx.flash_log.is_empty() and fx.flash_area_log.is_empty(), "persistent plumes never spend a counted flash")
	s.dead = true
	s._update_damage_emitters(fx)
	fx.step(0.1)
	_check(not lamp.visible, "dead ship has no continuing wound light")
	await _end()


func _check_wing() -> void:
	_setup()
	var view := VIEW.new()
	world.add_child(view)
	view.setup({"id": "wing", "fac": "chorus", "cls": "Squadron", "hp": 100, "maxHp": 100}, Vector3.ZERO, true)
	view.set_process(false)
	fx.add_ship("wing", view, {"faction": "chorus", "cls": "Squadron", "meshes": view.meshes, "shielded": false})
	var wing = fx.ship("wing")
	var emitted: int = fx.pools.smk.emitted
	wing.sync(fx, {"hp": 49, "maxHp": 100})
	fx.step(0.2)
	var plume: MeshInstance3D = wing._wing_smoke
	var exhaust: Dictionary = view.hull.damage_exhaust()
	_check(is_instance_valid(plume) and plume.get_parent() == exhaust.parent and plume.position == exhaust.p,
		"damaged wing ribbon follows a real moving craft exhaust")
	fx.step(0.2)
	_check(wing._wing_smoke == plume and fx.pools.smk.emitted == emitted, "wing does not emit the old pooled smoke dots")
	wing.sync(fx, {"hp": 50, "maxHp": 100})
	fx.step(0.2)
	_check(wing._wing_smoke == null and plume.is_queued_for_deletion(), "repair stops the wing ribbon at half HP")
	await _end()


func _check_hulk(faction: String) -> void:
	_setup()
	var s = _ship(faction)
	# Chorus burnouts still rupture. Boarding is the existing way to leave a cold organic hulk.
	fx.death("T", "board" if faction == "chorus" else "dark")
	fx.step(0.80)
	if fx.dstate.wrecks.is_empty():
		_check(false, faction + " did not leave a hulk")
		await _end()
		return
	var wreck: Dictionary = fx.dstate.wrecks[0]
	var hulk: Node3D = wreck.nodes[0]
	var vent := hulk.get_node("fx_hulk_vent") as MeshInstance3D
	var m := vent.material_override as ShaderMaterial
	_check(vent.mesh is QuadMesh and m.get_shader_parameter("colour_atlas") is Texture2D, "hulk owns one baked vent")
	_check(m.get_shader_parameter("core_power") == 0.0 and wreck.lights.is_empty() and fx.flash_log.is_empty(), "hulk is cold and unlit")
	var start: float = m.get_shader_parameter("density")
	_check(is_equal_approx(start, PLUME.HULK_DENSITY), "hulk starts at full density")
	var stem: Vector3 = vent.position
	fx.remove_ship("T")
	s.root.queue_free()
	fx.step(2.0)
	_check(is_instance_valid(vent) and vent.position == stem, "vent follows the drifting wreck after live ship removal")
	fx.step(28.0)
	await process_frame
	var middle: float = m.get_shader_parameter("density")
	_check(is_instance_valid(vent) and middle < start and middle > PLUME.HULK_WISP_DENSITY,
		"cold vent is still attached and thinning at 30 seconds")
	fx.step(31.0)
	var settled: float = m.get_shader_parameter("density")
	fx.step(60.0)
	await process_frame
	_check(is_instance_valid(vent) and vent.is_visible_in_tree() and vent.get_parent() == hulk
		and fx.now - float(wreck.t0) >= 120.0, "hulk still emits after 120 seconds")
	_check(settled > 0.0 and settled < middle and is_equal_approx(settled, m.get_shader_parameter("density"))
		and m.get_shader_parameter("life_s") == 0.0 and not wreck.has("vent_material"),
		"the thin lasting wisp settles after a minute without an expiry or further density updates")
	fx.clear_wreck("T")
	await process_frame
	_check(not is_instance_valid(vent), "clearing the wreck also clears its vent")
	await _end()


func _check_crits(faction: String, calm: bool) -> void:
	_setup()
	fx.reduce_flashing = calm
	var s = _ship(faction)
	var hit := {"p": Vector3(0, 2.5, 0), "n": Vector3.UP}
	var before: int = fx.pools.stk.emitted
	WEAP._crit(fx, s, hit, fx.now + 0.08, 1.0, Color(1, 0.3, 0.02))
	fx.step(0.16)
	var flash := fx.get_node_or_null("fx_staged_flash") as MeshInstance3D
	_check(flash != null and fx.get_node_or_null("fx_staged_body") == null and fx.get_node_or_null("fx_weapon_vent") == null,
		faction + " crit draws a clean flash only, with no thermal body or warm vent")
	if flash != null:
		var m := flash.material_override as ShaderMaterial
		var glow: Color = s.fac.damage_glow
		var tint: Vector3 = m.get_shader_parameter("impact_tint")
		_check(m.get_shader_parameter("impact_tinted") == 1.0 and m.get_shader_parameter("impact_clean") == 1.0
			and tint.is_equal_approx(Vector3(glow.r, glow.g, glow.b)), faction + " crit takes the target palette, not orange or cream")
		_check((not calm or m.get_shader_parameter("soft_flash") == 1.0) and m.get_shader_parameter("lifetime") <= 0.70,
			"the crit respects the flash controls")
	if faction == "chorus":
		_check(fx.pools.stk.emitted == before, "Chorus crit adds no metal sparks")
	_check(not calm or fx.flash_log.is_empty() and fx.flash_area_log.is_empty(), "Reduce Flashing books no crit flashes")
	await _end()


func _end() -> void:
	fx.release()
	world.queue_free()
	await process_frame


func _run() -> void:
	OS.set_environment("VS_WOUNDS_V2", "1")
	for faction in FACTIONS:
		await _check_wounds(faction)
	await _check_wing()
	for faction in ["hegemony", "deathless", "chorus", "ithar"]:
		await _check_hulk(faction)
	for faction in ["deathless", "chorus", "ithar"]:
		for calm in [false, true]:
			await _check_crits(faction, calm)
	FX.clear_static()
	print("DAMAGE_PLUME failures=%d" % failures)
	quit(1 if failures else 0)
