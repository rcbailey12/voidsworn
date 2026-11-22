extends SceneTree
# Issue 1450 picture UNDO-1: the real battle scene, one player ship moves one hex (keeping movement), and the KEEL shelf shows
# "Undo move" next to "End ship" (UNDO-0 is before the move). Then Backspace takes the move back (UNDO-2: the button is gone, the ship is back).
# Run: godot --path godot --script res://bench/undo_1450_shot.gd -- --out <folder> [--scenario s1]
const BattleScene = preload("res://scenes/battle/battle.tscn")
var b
var out_dir := "user://undo_1450"
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
	for k in 30:
		await process_frame


func _shot(name: String) -> void:
	await process_frame
	await process_frame
	var img: Image = root.get_texture().get_image()
	DirAccess.make_dir_recursive_absolute(out_dir)
	preload("res://tools/picture_provenance.gd").save_png(img, out_dir.path_join(name + ".png"), preload("res://tools/picture_provenance.gd").capture_stage())
	_say("[undo1450] saved " + name)


func _run() -> void:
	b = BattleScene.instantiate()
	b.tips_off = true
	root.add_child(b)
	await _wait_idle(180000)
	if not _idle():
		_say("[undo1450] FAIL battle never reached the player's turn")
		quit(1)
		return
	var ship := ""
	for u in b.V["units"]:
		if u["side"] == "player" and not u["dead"] and not u["activated"] and not u["squadron"]:
			ship = str(u["id"])
			break
	b.select(ship, "roster")
	var mp := int(b.api.unit(ship)["mp"])
	var st = null
	for s in b.api.reach(ship):
		if s.path.size() == 1 and not bool(s.path[0].get("rot", false)) and int(s.cost) < mp:
			st = s
			break
	var q0 := int(b.api.unit(ship)["q"])
	var r0 := int(b.api.unit(ship)["r"])
	b._refresh_ui()
	await _wait_idle(5000)
	_say("[undo1450] ship %s %s hull code %s at %d,%d" % [ship, str(b.VU[ship]["name"]), str(b.views[ship].code), q0, r0])
	await _shot("UNDO-0_before_move")
	b._cmd(func(): return b.api.move(ship, st))
	await _wait_idle(60000)
	b.sel = ship
	b._refresh_ui()
	await _wait_idle(5000)
	var vu: Dictionary = b.VU.get(ship, {})
	_say("[undo1450] moved %s from %d,%d to %d,%d; view undo %s" % [ship, q0, r0, int(vu.get("q", -1)), int(vu.get("r", -1)), str(vu.get("undo", false))])
	await _shot("UNDO-1_after_move")
	b._on_key(KEY_BACKSPACE)
	await _wait_idle(30000)
	b._refresh_ui()
	await _wait_idle(5000)
	vu = b.VU.get(ship, {})
	var back := int(vu.get("q", -1)) == q0 and int(vu.get("r", -1)) == r0
	_say("[undo1450] after Backspace %s stands at %d,%d (%s); view undo %s" % [ship, int(vu.get("q", -1)), int(vu.get("r", -1)), "back" if back else "NOT back", str(vu.get("undo", false))])
	await _shot("UNDO-2_after_backspace")
	var f := FileAccess.open(out_dir.path_join("undo_shot.txt"), FileAccess.WRITE)
	if f != null:
		f.store_string("\n".join(lines) + "\n")
		f.close()
	quit(0 if back else 1)
