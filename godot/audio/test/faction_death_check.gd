extends SceneTree
const GUARD = preload("res://tools/ci/check_guard.gd")
# Issue 1238 (Neon audit F5.1, F5.4): the real FX death, the real death sound observer and the real cue player together.
# A Chorus cruiser and a Chorus Bio-Titan hold for their class's length before the skin ruptures (not 0.35 s like a drone),
# get the kill slow-motion beat at the rupture, and every death cue they start is the Chorus's own (wet and breathing,
# no steel layer). A Glasswright death ends in a glass shatter with no steel under it. A Sunward cruiser is unchanged.
# Prints a timing trace: each cue's start on the effect clock, the variant it played and its clip sets.
# Set DEATH_TRACE_OUT to also write the trace to that file.
const FX := preload("res://fx/fx.gd")
const Sfx := preload("res://audio/sfx.gd")
const DeathAudio := preload("res://audio/death_audio.gd")
const STEEL := ["scrape", "hullHitBig", "crackSettle", "wreckSettle", "heavyPlate", "debris", "boomBig", "ionCharge"]
var fails: Array = []
var trace: PackedStringArray = []
var s: Node
var fx
var started: Array = []   # [{cue, variant, t}]

func _init() -> void:
	GUARD.arm(self, "faction_death_check")
	call_deferred("_run")

func _ok(c: bool, message: String) -> void:
	if not c:
		fails.append(message)
		print("  FAIL ", message)

# The clip sets a cue actually plays for a variant: a replace variant's own, else the base plus any added variant.
func _clips(cue: String, variant: String) -> Array:
	var c: Dictionary = s.cues[cue]
	var v: Dictionary = c.get("variants", {}).get(variant, {})
	var out: Array = []
	if not bool(v.get("replace", false)):
		for l in c.layers:
			if l.has("s"): out.append(str(l.s))
	for l in v.get("layers", []):
		if l.has("s"): out.append(str(l.s))
	return out

func _run() -> void:
	s = Sfx.new()
	root.add_child(s)
	await process_frame
	s.cue_started.connect(func(n, o): started.append({"cue": n, "variant": str(o.get("variant", "")), "t": fx.now if fx != null else -1.0}))
	var specs := [["chorus", "Cruiser", 0.9, 1.38], ["chorus", "Bio-titan", 1.25, 2.0], ["chorus", "Frigate", 0.55, 0.35],
		["ithar", "Cruiser", 0.9, 1.38], ["voidsworn", "Cruiser", 0.9, 1.38]]
	for spec in specs:
		await _one(spec[0], spec[1], float(spec[2]), float(spec[3]))
	s.stop_all()
	s.free()
	await create_timer(0.15).timeout
	var out := OS.get_environment("DEATH_TRACE_OUT")
	if out != "":
		var f := FileAccess.open(out, FileAccess.WRITE)
		if f != null:
			f.store_string("\n".join(trace) + "\n")
	print("FACTION DEATH CHECK ", "PASS" if fails.is_empty() else "FAIL (%d)" % fails.size())
	quit(0 if fails.is_empty() else 1)

func _one(fac: String, cls: String, size: float, want_split: float) -> void:
	var world := Node3D.new()
	root.add_child(world)
	fx = FX.new()
	world.add_child(fx)
	fx.manual = true
	fx.setup({"quality": "high", "shake": 0.0})
	fx.kill_slowmo = true
	var r := Node3D.new()
	world.add_child(r)
	var mi := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(24, 4, 6)
	box.subdivide_width = 23
	box.subdivide_height = 3
	box.subdivide_depth = 5
	mi.mesh = box
	r.add_child(mi)
	fx.add_ship("T", r, {"faction": fac, "cls": cls, "size": size, "meshes": [mi]})
	var ship = fx.ship("T")
	var d := DeathAudio.new()
	d.sfx = s
	d.fx = fx
	d.set_process(false)
	root.add_child(d)
	for i in 30:
		fx.step(1.0 / 60.0)
		await process_frame
	s.stop_all()
	s.last.clear()
	started.clear()
	var T0: float = fx.now
	fx.death("T", "blast")
	d.watch("T", Vector3.ZERO)
	var split := -1.0
	var slow_seen := false
	var core_at := -1.0
	# The effect clock follows real time, so a cue's real start maps onto the picture's time.
	var last_ms := Time.get_ticks_msec()
	while fx.now - T0 < want_split + 3.0:
		await create_timer(1.0 / 60.0).timeout
		var now_ms := Time.get_ticks_msec()
		fx.step(minf((now_ms - last_ms) / 1000.0, 0.05))
		last_ms = now_ms
		d._process(0.0)
		if split < 0.0 and ship.has_meta("death_hidden"):
			split = fx.now - T0
		if float(fx.get("_death_slow_left")) > 0.0:
			slow_seen = true
		if core_at < 0.0 and fx.death_core_at("T") >= 0.0 and not ship.death_core_pending:
			core_at = fx.death_core_at("T") - T0
	var label := "%s %s" % [fac, cls]
	trace.append("== %s: rupture/split at %.2f s, kill beat core at %.2f s, slow motion %s" % [label, split, core_at, "yes" if slow_seen else "no"])
	print(trace[-1])
	for e in started:
		var clips := _clips(e.cue, e.variant) if s.cues.has(e.cue) else []
		var line := "   %6.2f s  %-16s %-10s %s" % [float(e.t) - T0, e.cue, e.variant if e.variant != "" else "-", ", ".join(clips)]
		trace.append(line)
		print(line)
	_ok(split >= want_split - 0.05 and split <= want_split + 0.25, "%s splits at its class time (%.2f s, want %.2f)" % [label, split, want_split])
	var cues := started.map(func(e): return e.cue)
	if ship.death_big:
		_ok(slow_seen, label + " gets the kill slow-motion beat")
		_ok(core_at >= split - 0.01, label + " kill beat comes at or after the split (%.2f s)" % core_at)
		_ok(cues.has("boom_l") and cues.has("death_tail") and cues.has("wreck"), label + " plays its break, tail and wreck")
		var crack_t := -1.0
		var boom_t := -1.0
		for e in started:
			if e.cue == "death_crack" and crack_t < 0.0: crack_t = float(e.t) - T0
			if e.cue == "boom_l" and boom_t < 0.0: boom_t = float(e.t) - T0
		_ok(crack_t >= 0.0 and crack_t < boom_t, label + " cracks before it breaks (crack %.2f s, break %.2f s)" % [crack_t, boom_t])
	else:
		_ok(cues.has("boom_s"), label + " bursts with boom_s")
	if fac == "chorus" or fac == "ithar":
		for e in started:
			for c in _clips(e.cue, e.variant):
				_ok(not STEEL.has(c), "%s %s plays no steel layer (%s)" % [label, e.cue, c])
	if fac == "ithar":
		var shatter := false
		for e in started:
			if e.cue == "boom_l" and _clips(e.cue, e.variant).has("shieldShatter"):
				shatter = true
		_ok(shatter, label + " breaks with a glass shatter")
	if fac == "voidsworn":
		for e in started:
			_ok(_clips(e.cue, e.variant) == _clips(e.cue, ""), label + " " + e.cue + " keeps its steel sound")
	s.stop_all()
	d.free()
	fx.release()
	world.queue_free()
	fx = null
	await process_frame
