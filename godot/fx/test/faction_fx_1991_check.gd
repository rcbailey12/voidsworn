extends SceneTree
# Issue 1991: inspect the colours and sprite kinds submitted by the live FX paths.
const FX := preload("res://fx/fx.gd")
const LOOK := preload("res://fx/faction_look.gd")
const DEATH := preload("res://fx/fx_death.gd")
const SH := preload("res://fx/fx_shaders.gd")
const WEAP := preload("res://fx/fx_weapons.gd")
const POOLS := preload("res://fx/fx_pool.gd")
const BLOCKERS := preload("res://world/blocker_visuals.gd")
const GUARD := preload("res://tools/ci/check_guard.gd")

var failures := 0


func _init() -> void:
	GUARD.arm(self, "faction_fx_1991_check")
	_run.call_deferred()


func _check(ok: bool, what: String) -> void:
	if not ok:
		failures += 1
		printerr("FAIL: ", what)


func _rgb(col: Color) -> Vector3:
	return Vector3(col.r, col.g, col.b)


func _ship(world: Node3D, fx: FX, faction: String, cls: String):
	var body := Node3D.new()
	world.add_child(body)
	var part := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(24, 5, 8) if cls == "Cruiser" else Vector3(3, 1, 2)
	part.mesh = box
	part.material_override = StandardMaterial3D.new()
	body.add_child(part)
	var core := Marker3D.new()
	core.name = "hp_core"
	body.add_child(core)
	var id := faction if cls == "Cruiser" else faction + "_wing"
	fx.add_ship(id, body, {"faction": faction, "cls": cls, "meshes": [part], "shielded": false})
	return fx.ship(id)


func _particles(fx: FX, pool_name: String) -> Array[Vector4]:
	var pool: POOLS.Pool = fx.pools[pool_name]
	var rows: Array[Vector4] = []
	for i in range(0, pool.pending.size(), POOLS.STRIDE * pool.vpp):
		rows.append(Vector4(pool.pending[i + 12], pool.pending[i + 13], pool.pending[i + 14], pool.pending[i + 18]))
	return rows


func _check_fire(fx: FX, s) -> void:
	var glow: Color = s.fac.damage_glow
	fx.tick(s.id, "fire")
	var flame: MeshInstance3D
	for child in fx.get_children():
		if child is MeshInstance3D and child.material_override is ShaderMaterial and child.has_meta("gas_root"):
			flame = child
	_check(flame != null, s.faction + " uses the layered fire tick")
	if flame != null:
		var tick_mat := flame.material_override as ShaderMaterial
		_check(tick_mat.get_shader_parameter("plasma") == 1.0 and tick_mat.get_shader_parameter("fac_mid") == glow
			and tick_mat.get_shader_parameter("fac_smoke") == 0.0, s.faction + " tick plume uses faction glow and no soot")
	var motes := _particles(fx, "spr") + _particles(fx, "smk")
	_check(motes.size() == 9, s.faction + " tick emits palette-coloured motes")
	var mote_kind := 20 if s.faction == "chorus" else SH.TICK_EMBER
	for row in motes:
		_check(int(row.w) == mote_kind and Vector3(row.x, row.y, row.z).is_equal_approx(_rgb(glow)), s.faction + " tick mote uses its damage glow")
	_check(fx._lev.size() == 1 and (fx._lev[0][4] as Color).is_equal_approx(glow), s.faction + " tick light uses its damage glow")
	fx.pools["spr"].flush()
	fx.pools["smk"].flush()
	fx._lev.clear()
	s._anchors["a1"] = {"p": Vector3(0, 2.5, 0), "n": Vector3.UP, "t": {}}
	var emitter := {"kind": "fire", "sec": 1, "st": 4, "id": "check"}
	_check(s._build_damage_emitter(fx, emitter) and emitter.has("mat"), s.faction + " breach keeps the attached damage plume")
	if emitter.has("mat"):
		var core: Vector3 = emitter.mat.get_shader_parameter("colour_core")
		_check(core.is_equal_approx(_rgb(s._plume_glow())), s.faction + " breach plume matches its damage profile")
		if s.faction == "hegemony":
			_check(core.z > core.y and core.y > core.x, "Directorate breach is blue, not amber")
		elif s.faction == "ithar":
			_check(emitter.mat.get_shader_parameter("core_power") == 0.0, "Glasswright breach has no thermal core")


func _check_directorate_hits(fx: FX, s) -> void:
	var glow: Color = s.fac.damage_glow
	_check(glow.b > glow.g and glow.g > glow.r and glow.r >= 0.55, "Directorate damage glow is bright blue-white")
	var at := {"p": Vector3(0, 2.5, 0), "n": Vector3.UP, "gk": 1.0, "tk": 1.0}
	WEAP._shell_hit(fx, "macro", 2, s, at, fx.now, Color(1.0, 0.4, 0.1), Vector3.FORWARD, 1.0)
	var shell_sparks: int = fx.pools["stk"].emitted
	WEAP._crit(fx, s, at, fx.now + 0.3, 1.0, Color(1.0, 0.4, 0.1))
	_check(fx._lev.size() == 2, "Directorate shell hit and crit each light the hull")
	for light in fx._lev:
		_check((light[4] as Color).is_equal_approx(glow), "Directorate shell and crit light match the damage glow")
	var sparks := _particles(fx, "stk")
	_check(shell_sparks > 0 and fx.pools["stk"].emitted > shell_sparks, "Directorate shell hit and crit each throw sparks")
	for row in sparks:
		_check(Vector3(row.x, row.y, row.z).is_equal_approx(_rgb(glow)), "Directorate shell and crit sparks match the damage glow")
	fx.now += 0.05
	fx._run_later()
	var body := fx.get_node_or_null("fx_staged_body") as MeshInstance3D
	_check(body != null and body.material_override.get_shader_parameter("impact_tinted") == 1.0 and body.material_override.get_shader_parameter("impact_tint").is_equal_approx(_rgb(glow)), "Directorate shell fire body uses the same cool glow")


func _check_thrusters(world: Node3D, fx: FX) -> void:
	for faction in ["voidsworn", "corsair"]:
		var s = _ship(world, fx, faction, "Cruiser")
		s.wounds_v2 = false
		s._eng_sputter = true
		s._build_engines(fx)
		_check(s.sick_nozzle >= 0 and s.eng_soot == (faction == "corsair"),
			faction + " keeps its own exhaust when a legacy drive sputters")
	var glass = fx.ship("ithar")
	fx.pools["spr"].flush()
	glass._rv.x = 0.07
	glass._rcs(fx)
	var rcs := _particles(fx, "spr")
	_check(rcs.size() == 2, "Glasswright hit reaction fires two correction glints")
	for row in rcs:
		_check(row.w == 16 and Vector3(row.x, row.y, row.z).is_equal_approx(Vector3(1.0, 0.86, 0.57)),
			"Glasswright correction glints keep their R412 pale gold")
	fx.pools["spr"].flush()


func _check_chorus_tidal_and_boarding(fx: FX) -> void:
	var sparks: int = fx.pools["stk"].emitted
	fx.well = Vector3(60, -4, 30)
	fx.tick("chorus", "tidal")
	_check(fx.pools["stk"].emitted == sparks, "tidal damage never throws metal sparks off the Chorus")
	var bile: Color = fx.ship("chorus").fac.damage_glow
	var spores := _particles(fx, "smk")
	_check(not spores.is_empty(), "tidal damage still shows on the Chorus")
	for row in spores:
		_check(row.w == 20 and Vector3(row.x, row.y, row.z).is_equal_approx(_rgb(bile)),
			"Chorus tidal damage sheds bile-coloured spores")
	fx.pools["smk"].flush()
	fx.pools["stk"].flush()
	fx.spr_kinds.clear()
	fx.ship("chorus").root.position = Vector3(0, 0, 36)
	_check(fx.board("chorus", "ithar") > 0.0, "Chorus boards the Glasswright hull")
	var hatch := _particles(fx, "smk")
	_check(hatch.size() == 1 and hatch[0].w == 20 and Vector3(hatch[0].x, hatch[0].y, hatch[0].z).is_equal_approx(_rgb(bile)),
		"the Chorus attacker hatch releases a bile spore puff, not a fireball or vent gas")
	var glass_glow: Color = fx.ship("ithar").fac.damage_glow
	var glints := 0
	for row in _particles(fx, "spr"):
		if row.w == 16 and Vector3(row.x, row.y, row.z).is_equal_approx(_rgb(glass_glow * 0.55)):
			glints += 1
	_check(glints == 10 and not fx.spr_kinds.has(7), "the Glasswright breach vents stored-light glints, not gas")
	for pool in ["smk", "spr", "stk"]:
		fx.pools[pool].flush()
	fx._lev.clear()


func _check_death_overlays(fx: FX, s) -> void:
	var mesh: MeshInstance3D = s.meshes[0]
	var parent := mesh.get_parent()
	var timeline := DEATH.DeathTimeline.new(true, 1, "cruiser", "cut")
	DEATH._tell(fx, s, fx.now, timeline, "cut", PackedVector3Array())
	_check(mesh.material_overlay != null, s.faction + " tell installs a tear overlay")
	parent.remove_child(mesh)
	_check(mesh.material_overlay == null, s.faction + " tear detaches on tree exit before the split")
	parent.add_child(mesh)
	s.set_meta("death_melt", true)
	s.set_meta("last_hit", [s.hull.core])
	DEATH._melt_glow(fx, s, fx.now, timeline)
	_check(mesh.material_overlay != null, "melt installs a hull glow overlay")
	parent.remove_child(mesh)
	_check(mesh.material_overlay == null, "melt glow detaches on tree exit before the split")
	parent.add_child(mesh)
	s.remove_meta("death_melt")
	DEATH._tell(fx, s, fx.now, timeline, "melt", PackedVector3Array())
	var tear := mesh.material_overlay as ShaderMaterial
	_check(tear != null and tear.get_shader_parameter("tip").is_equal_approx(_rgb(DEATH.dstyle(s).fire)),
		"a tear reads its death style rather than picking green from the kill cause")
	var restored := StandardMaterial3D.new()
	mesh.material_overlay = restored
	parent.remove_child(mesh)
	_check(mesh.material_overlay == restored, "tree exit leaves replacement paint alone")
	parent.add_child(mesh)


func _check_wreck(world: Node3D) -> void:
	var blockers := BLOCKERS.new()
	world.add_child(blockers)
	var view := {"map": {"holes": [{"kind": "deadstar", "cells": [[0, 0]]}]}, "terrain": {"1,0": "planet", "2,0": "station"}}
	blockers.build(view, func(q: int, r: int) -> Vector3: return Vector3(q * 17.0, 0, r * 17.0))
	for key in ["0,0", "1,0", "2,0"]:
		var outline: Node3D = blockers.visuals.get(key)
		_check(outline != null and outline.get_child_count() == 6 and outline.position.y > 0.0,
			key + " keeps six visible segments above the board")
		if outline == null:
			continue
		for segment in outline.get_children():
			var mat := (segment as MeshInstance3D).material_override as StandardMaterial3D
			_check(not mat.no_depth_test and mat.emission_enabled, key + " segment depth-tests and keeps its emission")
	# faction_death_style_check also advances the real seam clock and checks the six material families.
	_check(DEATH.SLAG.contains("base = scorch_tint") and DEATH.SLAG.contains("hot * seam * temperature * temperature")
		and not DEATH.SLAG.contains("face_glow"), "cold caps take dark hull pigment and emit heat only along the cooling seam")


func _run() -> void:
	var world := Node3D.new()
	root.add_child(world)
	var fx := FX.new()
	world.add_child(fx)
	fx.manual = true
	fx.setup({"quality": "high"})
	fx.compat = false
	fx.spr_kinds = {}
	for faction in ["deathless", "ithar", "chorus", "hegemony"]:
		_check_fire(fx, _ship(world, fx, faction, "Cruiser"))
	var glass: Color = fx.ship("ithar").fac.damage_glow
	var bile: Color = fx.ship("chorus").fac.damage_glow
	_check(glass.b >= glass.g and glass.g >= glass.r, "Glasswright damage light is stored white light")
	_check(bile.g > bile.r and bile.r > bile.b, "Chorus damage light is bile green")
	_check(SH.SPRITE.contains("k == 26 ? vCol.rgb") and SH.SPRITE.contains("mix(vCol.rgb, vec3(1.0), 0.5) * pow(heat"), "faction flame keeps its palette through the hot core")
	var eclipse = fx.ship("deathless")
	var violet: Color = eclipse.fac.damage_glow
	_check(violet.b > violet.r and violet.r > violet.g, "Eclipse damage light is violet")
	_check(not eclipse._trails.is_empty(), "Eclipse has an engine trail")
	for trail in eclipse._trails:
		var mat: ShaderMaterial = trail.mi.material_override
		_check(mat.get_shader_parameter("trail_ember").is_equal_approx(_rgb(violet)), "Eclipse trail embers use its damage glow")
	_check(SH.TRAIL.contains("col += trail_ember * spow") and SH.TRAIL.contains("st == 3 ? vec3(1.0)"), "ship trail keeps the palette and a neutral core")
	_check(FX.spark_colour("deathless", FX.SparkRole.ENGINE).is_equal_approx(eclipse.fac.accent), "Eclipse drive sparks keep their white-gold accent")
	DEATH.BEATS._implode(fx, eclipse, Vector3.ZERO, fx.now)
	var implosion := _particles(fx, "smk")
	_check(implosion.size() == 1 and implosion[0].w == 8 and implosion[0].z > implosion[0].x, "Eclipse implosion ends in a violet puff without an orange birth flash")
	fx.pools["smk"].flush()
	var wing = _ship(world, fx, "chorus", "Squadron")
	var before_sparks: int = fx.pools["stk"].emitted
	var before_shards: int = fx.pools["shd"].emitted
	var before_callbacks: int = fx._later.size()
	DEATH.death(fx, wing, "blast")
	var spores := _particles(fx, "smk")
	_check(spores.size() == 3 and fx.pools["stk"].emitted == before_sparks and fx.pools["shd"].emitted == before_shards
		and fx._later.size() == before_callbacks, "Chorus wing releases spores and wet flecks without metal or a delayed fire picture")
	for row in spores:
		_check(row.w == 20 and row.y > row.x and row.x > row.z, "Chorus wing spills bile-coloured organic sprites")
	fx.pools["smk"].flush()
	_check_thrusters(world, fx)
	_check_chorus_tidal_and_boarding(fx)
	_check_death_overlays(fx, fx.ship("voidsworn"))
	_check_directorate_hits(fx, fx.ship("hegemony"))
	_check_wreck(world)
	world.free()
	FX.clear_static()
	print("FACTION_FX_1991 failures=", failures)
	quit(1 if failures else 0)
