extends SceneTree
# R80 contracts on actual rebuilt arrays, shader mouths and emitter allocations.
const FX := preload("res://fx/fx.gd")
const BREACH := preload("res://fx/fx_breach.gd")
var failures := 0
var fx
var world: Node3D

func _init() -> void:
	process_frame.connect(_run, CONNECT_ONE_SHOT)

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

func _ship(sid: String, faction: String, size: float, squad := false):
	var body := Node3D.new()
	world.add_child(body)
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(24, 5, 8)
	bm.subdivide_width = 17
	bm.subdivide_depth = 7
	var am := ArrayMesh.new()
	am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, bm.get_mesh_arrays())
	mi.mesh = am
	body.add_child(mi)
	fx.add_ship(sid, body, {"faction": faction, "cls": "Squadron" if squad else "Cruiser", "size": size, "meshes": [mi], "shielded": false})
	fx._later.clear()
	var s = fx.ship(sid)
	for i in 3:
		s._anchors["a%d" % i] = {"p": Vector3((i - 1) * 7, 2.5, 0), "n": Vector3.UP, "t": {}}
	return s

func flush(s) -> void:
	for i in 5:
		if s._dmg_task >= 0: s.flush_damage(fx)

func _run() -> void:
	world = Node3D.new()
	root.add_child(world)
	fx = FX.new()
	world.add_child(fx)
	fx.manual = true
	fx.setup({"quality": "high", "shake": 0.0})
	for faction in ["hegemony", "voidsworn", "corsair", "chorus", "ithar", "deathless"]:
		var s = _ship(faction, faction, 0.8)
		var patch = BREACH.surface(Vector3(0, 2.5, 0), Vector3.UP, 1.5, 66, BREACH.S_PATCH)
		var supported := BREACH.Part.new()
		BREACH._patch(supported, patch, s.hull)
		check(not supported.pos.is_empty(), "raised patch fits broad supporting skin")
		patch = BREACH.surface(Vector3(0, 2.5, 3.9), Vector3.UP, 1.5, 66, BREACH.S_PATCH)
		var unsupported := BREACH.Part.new()
		BREACH._patch(unsupported, patch, s.hull)
		check(unsupported.pos.is_empty(), "unsupported raised patch falls back to conforming overlay")
		for fraction in [1.0, 0.81, 0.8, 0.61, 0.6, 0.41, 0.4, 0.21, 0.2, 0.01]:
			s.sync(fx, {"hp": fraction * 100, "maxHp": 100})
			flush(s)
			for entries in s._ents:
				for e in entries:
					check(not e.has_cut() or fraction <= 0.2, "cuts only at <=20 percent: %s %.2f" % [faction, fraction])
			if fraction > 0.2 and not s._dmg_job.is_empty():
				check(BREACH._mouth_uniforms(s._dmg_job.ents).count == 0, "no hidden shader perforations")
		for e in s._ents[1]:
			if e.has_cut():
				check(is_equal_approx(e.R, s.hull.L * 0.032), "tight throat radius")
				check(e.D >= s.hull.L * 0.15 and e.D <= s.hull.L * 0.2, "recessed throat depth")
		for e in s._damage_emitters:
			if e.kind == "fire":
				check((e.source - s._anchor(e.sec, "a").p).dot(s._anchor(e.sec, "a").n) < 0.0, "stage 4 source seated inside")
			if faction in ["chorus", "ithar"]: check(e.sprite_kind != 25 and e.sprite_kind != 1, "living and crystal hulls never use flame")
		s.add_mark(fx, "torp", 4, Vector3(0, 2.5, 0), Vector3.UP, Vector3.DOWN)
		flush(s)
		s.sync(fx, {"hp": 100, "maxHp": 100})
		flush(s)
		check(s.stage == [0, 0, 0], "repair restores stage")
		check(s._marks.size() > 0, "repair retains weapon scars")
		check(s._ents[1].any(func(e): return e.style == BREACH.S_PATCH), "repair adds a patch")
		check(BREACH._mouth_uniforms(s._dmg_job.ents).count == 0, "repair seals every hole")
		fx.step(0.81)
		check(s.damage_counts().fire == 0 and s.damage_counts().smoke == 0, "repair emitter fade <=0.8 seconds")
		fx.compat = true
		s.set_stages(fx, [4, 4, 4])
		flush(s)
		check(s._dmg_job.ents.all(func(e): return e.kind == BREACH.K_SURFACE), "safe mode only flat marks")
		check(s._dmg_job.out.inside == null, "safe mode no dent/break/patch geometry")
		check(s.damage_counts().particles == 0, "safe mode no persistent damage particles")
		fx.compat = false
		s.sync(fx, {"hp": 100, "maxHp": 100, "sec": {"mid": {"hp": 95, "max": 100, "broken": true}}})
		flush(s)
		check(s.stage[1] == 4, "broken section opens at stage 4 even with reported HP remaining")
		fx.remove_ship(faction)
		s.root.queue_free()
	for weight in [1, 2, 3, 4]:
		var s = _ship("cap%d" % weight, "hegemony", [0.0, 0.55, 0.8, 1.0, 1.3][weight])
		var caps := Vector2i(1, 2) if weight == 1 else (Vector2i(2, 3) if weight == 2 else Vector2i(3, 4))
		for st in [1, 2, 3, 4]:
			s.set_stages(fx, [st, st, st])
			flush(s)
			var counts: Dictionary = s.damage_counts()
			check(counts.fire <= caps.x and counts.smoke + counts.vent <= caps.y, "class cap %d stage %d" % [weight, st])
			if st == 1: check(counts.particles == 0, "stage 1 no permanent emitters")
			if st == 2: check(counts.fire == 0 and counts.smoke > 0, "smoke starts at stage 2")
			s.sync(fx, {"hp": [100, 70, 50, 30, 10][st], "maxHp": 100, "burning": true})
			var count: Dictionary = s.damage_counts()
			check(count.fire <= caps.x and count.smoke + count.vent <= caps.y, "burning shares class caps")
			s.sync(fx, {"hp": 100, "maxHp": 100, "burning": false})
			flush(s)
			fx.step(0.81)
	var wing = _ship("wing", "hegemony", 0.2, true)
	wing.sync(fx, {"hp": 49, "maxHp": 100})
	var emitted: int = fx.pools.smk.emitted
	fx.step(0.2)
	check(wing.stage == [0, 0, 0] and wing._orig.is_empty(), "squadrons retain clean surfaces")
	check(fx.pools.smk.emitted > emitted, "below-half squadron emits pooled smoke ribbon")
	wing.sync(fx, {"hp": 50, "maxHp": 100})
	emitted = fx.pools.smk.emitted
	fx.step(0.2)
	check(fx.pools.smk.emitted == emitted, "squadron stops smoke at half health")
	var flashes: int = fx.flash_log.size()
	for i in 120: fx.step(1.0 / 60.0)
	check(fx.flash_log.size() == flashes, "persistent wounds spend zero counted flashes")
	fx.reduce_flashing = true
	for i in 120: fx.step(1.0 / 60.0)
	check(fx.flash_log.size() == flashes, "calm mode wounds spend zero counted flashes")
	print("DAMAGE_SURFACE failures=%d" % failures)
	fx.release()
	world.queue_free()
	await process_frame
	FX.clear_static()
	quit(1 if failures else 0)
