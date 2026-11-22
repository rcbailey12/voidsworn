extends SceneTree
# Issue 1649 pictures: the real battle scene on scenario s1649_fold or s1649_frenzy. A player ship uses its ability (the
# "Fold skip" or "Blood frenzy" callout, and for Fold skip the violet after-image), then the battle plays on until the
# "Folded" miss or the "Blood frenzy +N" regrowth callout shows, and each moment is saved.
# Run: godot --path godot --script res://bench/abil_1649_shot.gd -- --scenario s1649_fold --out <folder>
const BattleScene = preload("res://scenes/battle/battle.tscn")
const PP = preload("res://tools/picture_provenance.gd")
var b
var out_dir := "user://abil_1649"
var lines: Array = []


func _init() -> void:
	var a := OS.get_cmdline_user_args()
	var i := a.find("--out")
	if i >= 0 and i + 1 < a.size():
		out_dir = a[i + 1]
	_run.call_deferred()


func _say(s: String) -> void:
	print(s)
	lines.append(s)


func _idle() -> bool:
	return b.api != null and not b.warming and not b.busy and not b.thinking and b.batches.is_empty() and b.api.phase == "player"


func _wait_idle(ms: int) -> void:
	var t0 := Time.get_ticks_msec()
	while not _idle() and Time.get_ticks_msec() - t0 < ms:
		await process_frame
	for k in 20:
		await process_frame


func _shot(name: String) -> void:
	await process_frame
	var img: Image = root.get_texture().get_image()
	DirAccess.make_dir_recursive_absolute(out_dir)
	PP.save_png(img, out_dir.path_join(name + ".png"), PP.capture_stage())
	_say("[abil1649] saved " + name)


# wait until a floating callout whose text starts with one of the prefixes is on screen, about 0.35 s in, then save it
func _watch(prefixes: Array, name: String, ms: int) -> bool:
	var t0 := Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < ms:
		for f in b.floats:
			var lbl = f.get("lbl")
			if lbl == null or not is_instance_valid(lbl): continue
			for p in prefixes:
				if str(lbl.text).begins_with(p) and float(f.get("t", 0.0)) >= 0.35:
					_say("[abil1649] callout '%s'" % lbl.text)
					await _shot(name)
					return true
		if _idle() and b.api.phase == "player" and Time.get_ticks_msec() - t0 > 4000:
			# the player's turn: let the bot play every ready player ship, so the battle keeps going
			var ready := false
			for u in b.V["units"]:
				if u["side"] == "player" and not u["dead"] and not u["activated"] and not u["squadron"]:
					ready = true
					b._cmd(func(): b.api.ai_activate(str(u["id"])); return true)
					break
			if not ready:
				b._cmd(func(): b.api.end_turn(); return true)
		await process_frame
	_say("[abil1649] no '%s' callout within %d ms" % [str(prefixes), ms])
	return false


func _run() -> void:
	b = BattleScene.instantiate()
	b.tips_off = true
	root.add_child(b)
	await _wait_idle(180000)
	var ship := ""
	var ab := ""
	for u in b.V["units"]:
		if u["side"] == "player" and not u["dead"] and not u["squadron"]:
			var a = b.api.unit(str(u["id"])).get("ab")
			if a == "phase" or a == "frenzy":
				ship = str(u["id"]); ab = str(a); break
	if ship == "":
		_say("[abil1649] FAIL no player ship with phase or frenzy"); quit(1); return
	b.select(ship, "roster")
	b._refresh_ui()
	await _wait_idle(5000)
	b._cmd(func(): return b.api.ability(ship))
	var ok := true
	if ab == "phase":
		ok = await _watch(["Fold skip"], "AB1649-1_fold_skip_used", 8000) and ok
		ok = await _watch(["Folded"], "AB1649-2_folded_miss", 600000) and ok
	else:
		ok = await _watch(["Blood frenzy"], "AB1649-3_blood_frenzy_used", 8000) and ok
		ok = await _watch(["Blood frenzy +"], "AB1649-4_blood_frenzy_regrow", 600000) and ok
	var f := FileAccess.open(out_dir.path_join("abil_1649_%s.txt" % ab), FileAccess.WRITE)
	if f != null:
		f.store_string("\n".join(lines) + "\n")
		f.close()
	quit(0 if ok else 1)
