extends SceneTree

const Look := preload("res://render/look.gd")
const Rig := preload("res://render/camera_rig.gd")
const WorldSky := preload("res://world/world_sky.gd")
const Lens := preload("res://fx/battle_lens.gd")
const TerrainScorch := preload("res://fx/terrain_scorch.gd")
const Battle := preload("res://scenes/battle/battle.tscn")
var failures := 0


func _initialize() -> void:
	_run.call_deferred()


func _check(ok: bool, detail: String) -> void:
	if not ok:
		failures += 1
		printerr("FAIL: " + detail)


func _run() -> void:
	var textures := {}
	for region in WorldSky.REGION:
		var lut := Look.battle_lut(region)
		_check(lut != null and lut.get_width() == 33 and lut.get_height() == 33 and lut.get_depth() == 33,
			region + " must import as a 33 x 33 x 33 Texture3D")
		if lut != null:
			textures[lut.resource_path] = true
	_check(textures.size() == WorldSky.REGION.size(), "each region needs its own grade")
	_check(Look.battle_lut("unknown") == Look.battle_lut("frontier"), "unknown regions fall back to Frontier")
	for faction in ["ithar", "deathless", "chorus"]:
		_check(Look.ssr_candidate("max", [{"fac": faction}]), faction + " qualifies for Max SSR")
		_check(not Look.ssr_candidate("high", [{"fac": faction}]), "High does not qualify")
		_check(not Look.ssr_candidate("max", [{"fac": faction, "dead": true}, {"fac": faction, "fled": true},
			{"fac": faction, "squadron": true}]), "dead, fled and squadron hulls do not qualify")
	_check(not Look.ssr_candidate("max", [{"fac": "voidsworn"}]), "opaque metal fleet leaves SSR off")

	var lens := Lens.new()
	_check(not lens.enabled, "a fresh compositor is idle")
	lens.set_lenses(Vector4.ZERO, 0.0, Vector4(0.5, 0.5, 0.1, 0.25))
	_check(lens.enabled, "an active shockwave wakes the compositor")
	lens.set_lenses(Vector4.ZERO, 0.0, Vector4.ZERO)
	_check(not lens.enabled, "removing the sources turns the compositor off")
	var pose := Transform3D(Basis.from_scale(Vector3(2, 3, 4)), Vector3(9, 5, -7))
	var surface := TerrainScorch.surface_hit(BoxMesh.new(), pose)
	_check(not surface.is_empty() and is_equal_approx(surface["position"].y, 6.5) and surface["normal"].is_equal_approx(Vector3.UP),
		"a mark attaches on the real transformed surface")

	for flag in ["LUT", "DOF", "SSR", "LENSING", "SHOCKWAVE", "DECALS"]:
		OS.set_environment("VS_BATTLE_" + flag, "1")
		_check(not Look.post_fx_enabled(flag), flag + " stays off without a Forward+ display")
	var b = Battle.instantiate()
	b.external = true
	root.add_child(b)
	_check(not b.env.adjustment_enabled and not b.env.ssr_enabled and b._battle_lens == null,
		"the normal battle starts with today's Environment and no compositor")
	var rig := b.cam as Camera3D
	_check(rig.attributes == null, "tactical camera has no DoF resource on entry")
	rig.r = 170.0
	rig.snap()
	rig.r = 60.0
	rig.set_close_dof(true, 20.0)
	rig._step_close_dof(0.1)
	var attributes := rig.attributes as CameraAttributesPractical
	_check(not attributes.dof_blur_far_enabled, "the far blur waits as the camera leaves c170")
	rig.snap()
	rig._step_close_dof(0.1)
	_check(attributes.dof_blur_far_enabled and not attributes.dof_blur_near_enabled and
		attributes.dof_blur_far_distance > 80.0 and attributes.dof_blur_amount < Rig.DOF_AMOUNT,
		"the approach eases in a far-only kernel past the subject")
	b.cine_saved = {"a": rig.a, "b": rig.b, "r": 170.0, "t": rig.t}
	b._death_dof = true
	b._kill_let_go()
	_check(rig.r == 170.0 and not attributes.dof_blur_far_enabled and attributes.dof_blur_amount == 0.0,
		"release disables DoF immediately while the camera eases back")
	b.queue_free()
	await process_frame
	print("Battle post-FX headless check: %d failure(s)" % failures)
	quit(1 if failures else 0)
