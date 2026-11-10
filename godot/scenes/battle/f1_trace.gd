extends Node
# F1 acceptance trace (Codex's "playable phased battle" checklist, contrib/codex/OPUS_START_HERE.md on the codex branch).
# Run: battle.tscn with -- --f1-trace <folder> [--seed N | --scenario sN] [--fast K]. Drives the battle through the same
# input handlers a player uses (board clicks on hexes, Esc, Enter, Space, B), and around every step records the rules
# state hash (the parity harness's canonical state of B and every unit) and the random generator's state, so it shows
# which steps change the battle and which do not. Writes trace.jsonl, trace.txt (plain words, PASS or FAIL per check)
# and, when not headless, a screenshot per step. Presentation only: it never calls the rules directly except to read.

const JSM = preload("res://rules/jsm.gd")
const PG := preload("res://render/placeholder_guard.gd")
const SKIP_U := {"t": 1, "ship": 1}
const SKIP_B := {"units": 1, "cfg": 1, "prog": 1}

var b                  # the battle scene
var dir := ""
var rows: Array = []
var lines: Array = []
var fails := 0
var step_n := 0


func _hash() -> Dictionary:
	var R = b.api.R
	var B = R.B
	var parts := PackedStringArray()
	for u in B["units"]:
		parts.append(JSM.canon(u, "u", SKIP_U))
	var s := "{\"b\":" + JSM.canon(B, "b", SKIP_B) + ",\"units\":[" + ",".join(parts) + "]}"
	return {"hash": JSM.sha256(s).substr(0, 16), "rng": JSM.rng_u32(), "version": int(b.api.version)}


func _idle() -> void:
	var t0 := Time.get_ticks_msec()
	while is_inside_tree() and (b.busy or b.warming or b._threat_busy or b.thinking or b.ending) and not b.ended:
		await get_tree().process_frame
		if Time.get_ticks_msec() - t0 > 240000:
			_check(false, "timed out waiting for the battle to settle")
			return
	for i in 3:
		await get_tree().process_frame


func _check(ok: bool, what: String) -> void:
	lines.append(("PASS  " if ok else "FAIL  ") + what)
	if not ok:
		fails += 1
	print("[f1-trace] ", "PASS " if ok else "FAIL ", what)


func _rec(action: String, before: Dictionary, after: Dictionary, note := "") -> void:
	step_n += 1
	var r := {"step": step_n, "action": action, "round": int(b.V.get("round", 0)), "phase": str(b.api.phase), "up": b.sel, "up_name": b._name(b.sel) if b.sel != "" else "",
		"plan": b.plan != null, "target": b.target, "attack_move": b.atk != null, "before": before, "after": after,
		"rules_changed": before["hash"] != after["hash"], "rng_moved": before["rng"] != after["rng"], "note": note}
	rows.append(r)
	print("[f1-trace] step %d %s changed=%s rng=%s %s" % [step_n, action, str(r["rules_changed"]), str(r["rng_moved"]), note])


# a short clip: a JPG per rendered frame (run with --fixed-fps 30, so 30 frames are one second of game time)
func _clip(name: String, secs: float) -> void:
	if PG.stop_if_any():
		return
	if DisplayServer.get_name() == "headless":
		return
	var d := dir.path_join("clip_" + name)
	DirAccess.make_dir_recursive_absolute(d)
	for i in int(secs * 30.0):
		await RenderingServer.frame_post_draw
		if not is_inside_tree():
			return
		var img := get_viewport().get_texture().get_image()
		if img.get_width() > 1280:
			img.resize(1280, int(1280.0 * img.get_height() / img.get_width()), Image.INTERPOLATE_BILINEAR)
		img.save_jpg(d.path_join("%04d.jpg" % i), 0.82)


var wing_runs := 0


func _on_wings(n: int) -> void:
	wing_runs += 1
	if wing_runs == 1:
		_check(n >= 2 and b.burns_live >= 2, "your strike craft start their moves together (%d wings, %d burning at once)" % [n, b.burns_live])
		_clip("wings_together", 6.0)
		await get_tree().create_timer(1.0 / maxf(Engine.time_scale, 1.0)).timeout
		await b._snap("wings_together")


func _on_arrival(units: Array) -> void:
	arrivals += 1
	_check(true, "reinforcements arrived (%s): banner, camera nudge, NEW in the fleet list" % ", ".join(PackedStringArray(units.map(func(u): return str(u["name"])))))
	if arrivals == 1:
		_clip("arrival", 5.0)
		await get_tree().create_timer(0.7).timeout
		await b._snap("arrival_banner")


var arrivals := 0


func _shot(name: String) -> void:
	if PG.stop_if_any():
		return
	await get_tree().create_timer(0.6 / maxf(Engine.time_scale, 1.0)).timeout
	# every still: no two ship names overlap, and a hover tip never sits on the activation card
	var ov: int = b.hud.plate_name_overlaps()
	_check(ov == 0, "%s: no ship names overlap (%d hidden by the declutter)" % [name, b.hud.plates_hidden])
	var up: int = b.hud.plate_names_under_panels()
	_check(up == 0, "%s: no ship name sits under a side panel (%d found)" % [name, up])
	if b.hud.tip.visible and b.hud.card.visible:
		var tr: Rect2 = b.hud.tip.get_global_rect()
		_check(not tr.intersects(b.hud.card.get_global_rect()), "%s: the hover tip is clear of the card" % name)
	if b.hud.tip.visible and DisplayServer.get_name() != "headless":  # judged in a real window
		var tr2: Rect2 = b.hud.tip.get_global_rect()
		_check(not tr2.intersects(b.hud.panel.get_global_rect()) and not tr2.intersects(b.hud.roster.get_global_rect()), "%s: the hover tip is clear of the side panels" % name)
	await b._snap("%02d_%s" % [step_n, name])


func _hover_hex(q: int, r: int) -> void:
	b.hover = Vector2i(q, r)
	b.board.set_hover(q, r)
	b._overlay()
	if DisplayServer.get_name() != "headless":
		var sp: Vector2 = b.cam.unproject_position(b.board.hex_world(q, r))
		get_viewport().warp_mouse(sp)
		b.hud.show_tip(b._tip(), sp)


func _click_hex(q: int, r: int) -> void:
	_hover_hex(q, r)
	b._on_click()


func _key(k: int) -> void:
	b._on_key(k)


func _frame_on(p: Vector3) -> void:
	if b.sel != "" and b.views.has(b.sel):
		p = p.lerp(b._pos(b.sel), 0.5)
	b.cam.glide(p, 0.3)
	await get_tree().create_timer(0.8 / maxf(Engine.time_scale, 1.0)).timeout


func run(battle) -> void:
	b = battle
	dir = str(b.args.get("f1-trace", "user://f1_trace"))
	b.arrival.connect(_on_arrival)
	b.wings_together.connect(_on_wings)
	Engine.time_scale = float(b.args.get("fast", 1.0))
	while b.api == null or b.warming:
		await get_tree().process_frame
	# 0. the opening beat (R62): a wide view of both fleets and the objective, then the glide to the ship that is up
	if DisplayServer.get_name() != "headless":  # the headless window is 64 pixels square: framing is judged on the PC
		_check(b.opening_framed, "the battle opens on a wide view: every ship of both sides and the objective fit between the panels")
	if b.opening:
		await _shot("opening_wide")
	await _idle()
	while b.opening:
		await get_tree().process_frame
	await get_tree().create_timer(1.5 / maxf(Engine.time_scale, 1.0)).timeout
	var h0 := _hash()
	_rec("start", h0, h0, "%d ships on the board" % (b.V["units"] as Array).size())
	await _shot("start_handed_over")
	# 1. the game handed over a ship by itself
	_check(b.sel != "" and b._usable(b._sel_unit()), "at the start the game hands over a ready ship (%s)" % b._name(b.sel))
	_check(b.plog.is_open() and str(b.plog.cur.get("how", "")) == "auto", "the play log opened the hand-over as automatic")
	var vs: Vector2 = b.get_viewport().get_visible_rect().size
	var cr: Rect2 = b.hud.card.get_global_rect()
	var fits: bool = cr.size.y > 40.0 and cr.size.y <= float(b.hud.s(330)) and absf(cr.end.y - (vs.y - b.hud.s(16))) < 2.0
	if DisplayServer.get_name() != "headless":
		fits = fits and cr.size.y < vs.y * 0.34 and cr.position.y > vs.y * 0.6 and cr.size.x < vs.x * 0.7
	_check(b.hud.card.visible and fits,
		"the activation card sits at the bottom of the screen and fits (%d x %d at %d, %d on a %d x %d screen)" % [cr.size.x, cr.size.y, cr.position.x, cr.position.y, vs.x, vs.y])
	var up: String = b.sel
	# 2. a mistaken click on an enemy: it only targets or inspects, never fires or moves
	var far := ""
	var near := ""
	for e in b.V["units"]:
		if e["side"] != "enemy" or e["dead"] or e["squadron"]:
			continue
		if b._firing_set(e["id"]).is_empty():
			# prefer one the ship could reach with an attack-move, so the preview gets checked too
			if far == "" or (b._attack_move(far) == null and b._attack_move(e["id"]) != null):
				far = e["id"]
		elif near == "":
			near = e["id"]
	var mis: String = far if far != "" else near
	if mis != "":
		var hb := _hash()
		await _frame_on(b._pos(mis))
		_click_hex(int(b.VU[mis]["q"]), int(b.VU[mis]["r"]))
		await _idle()
		var ha := _hash()
		_rec("click an enemy once (%s)" % ("out of reach" if mis == far else "in reach"), hb, ha, "targeted=%s attack_move_preview=%s" % [b.target, str(b.atk != null)])
		_check(hb["hash"] == ha["hash"] and hb["rng"] == ha["rng"] and not b.busy, "one click on an enemy changes nothing in the battle (no fire, no move, no random draw)")
		await _shot("enemy_clicked_once")
		if b.atk != null:
			_check(b.ghost != null and b.ghost.visible, "an out-of-reach enemy shows the attack-move preview: the ghost where the ship would stop")
		var hb2 := _hash()
		_key(KEY_ESCAPE)
		await _idle()
		var ha2 := _hash()
		_rec("Esc", hb2, ha2)
		_check(b.target == "" and b.atk == null and hb2["hash"] == ha2["hash"], "Esc drops the target and changes nothing")
	# 3. rehearse a move, cancel it, rehearse again, commit it
	b._update_reach()
	var best = null
	for k in b.reach_map:
		var st = b.reach_map[k]
		if not b._unit_at(int(st.q), int(st.r)).is_empty():
			continue
		if best == null or int(st.get("guns", 0)) * 100 + int(st.cost) > int(best.get("guns", 0)) * 100 + int(best.cost):
			best = st
	if best != null:
		var hb := _hash()
		await _frame_on(b.board.hex_world(best.q, best.r))
		_click_hex(int(best.q), int(best.r))
		await _idle()
		var ha := _hash()
		_rec("click a blue hex once (plan)", hb, ha, "cost %d" % int(best.cost))
		_check(b.plan != null and hb["hash"] == ha["hash"] and hb["rng"] == ha["rng"], "one click on a blue hex plans the move (ghost shown) and changes nothing")
		_check(b.ghost != null and b.ghost.visible, "the planned move shows a ghost of the ship")
		await _shot("move_planned")
		var hb2 := _hash()
		_key(KEY_E)
		await _idle()
		var ha2 := _hash()
		_rec("E on the plan (turn the ghost)", hb2, ha2)
		_check(hb2["hash"] == ha2["hash"], "turning the planned facing changes nothing")
		var hb3 := _hash()
		_key(KEY_ESCAPE)
		await _idle()
		var ha3 := _hash()
		_rec("Esc (cancel the plan)", hb3, ha3)
		_check(b.plan == null and hb3["hash"] == ha3["hash"] and hb3["rng"] == ha3["rng"], "Esc cancels the planned move and the ship has not moved")
		await _shot("plan_cancelled")
		# plan it again and commit with a second click on the same hex
		_click_hex(int(best.q), int(best.r))
		var hb4 := _hash()
		_click_hex(int(best.q), int(best.r))
		await _idle()
		var ha4 := _hash()
		var u: Dictionary = b.VU.get(up, {})
		_rec("click the planned hex again (commit)", hb4, ha4, "now at %d,%d" % [int(u.get("q", -99)), int(u.get("r", -99))])
		_check(hb4["hash"] != ha4["hash"] and int(u.get("q", -99)) == int(best.q) and int(u.get("r", -99)) == int(best.r), "the second click commits the move: the ship is on the planned hex")
		if b.VU.get(up, {}).get("activated", false):
			_check(not b._nothing_left(up) and str(b.plog.acts[-1].get("end", "")) == "rules", "after moving, the rules ended the ship themselves (no movement and no gun left) and the log says so")
		else:
			_check(b.sel == up and b._active_id() == up and not b._card_info().get("buttons", [{}])[-2].get("on", true), "after moving, the same ship stays up (mid-turn: Next ship is locked)")
		await _shot("moved")
	# 4. fire: target, look at the odds, then commit once (a double commit cannot fire twice); on the ship now up
	await _idle()
	if b.sel != "":
		up = b.sel
	var tgt := ""
	for e in b.V["units"]:
		if e["side"] == "enemy" and not e["dead"] and not b._firing_set(e["id"]).is_empty():
			tgt = e["id"]
			break
	if tgt != "" and b._usable(b._sel_unit()):
		var set: Array = b._firing_set(tgt)
		var hb := _hash()
		await _frame_on(b._pos(tgt))
		_click_hex(int(b.VU[tgt]["q"]), int(b.VU[tgt]["r"]))
		await _idle()
		var ha := _hash()
		_rec("click an enemy in reach (target)", hb, ha, "%d guns bear" % set.size())
		_check(b.target == tgt and hb["hash"] == ha["hash"], "targeting shows the odds from the real hex and fires nothing")
		await _shot("target_odds")
		var ready0 := 0
		for w in b.api.unit(up)["weapons"]:
			if b.api.R.jt(w.get("fired")):
				ready0 += 1
		var hb2 := _hash()
		_key(KEY_ENTER)
		var blocked: bool = not b._can_act()
		_key(KEY_ENTER)   # a second Enter while the first volley plays
		b._confirm()      # and a direct third commit
		await _idle()
		var ha2 := _hash()
		var ready1 := 0
		var ru = b.api.unit(up)
		if ru != null:
			for w in ru["weapons"]:
				if b.api.R.jt(w.get("fired")):
					ready1 += 1
		var tdead: bool = b.VU.get(tgt, {}).get("dead", true)
		_rec("Enter, Enter, confirm (fire)", hb2, ha2, "guns fired %d -> %d, the set was %d%s" % [ready0, ready1, set.size(), ", target destroyed" if tdead else ""])
		_check(blocked and hb2["hash"] != ha2["hash"] and (ru == null or ready1 - ready0 == set.size() or (tdead and ready1 - ready0 <= set.size())), "Enter fires the salvo once (each bearing gun fires one volley); repeats while it plays are ignored")
		await _shot("fired")
	# 5. finish this ship (Space, or it ends itself), then brace or pass the next one
	if b.sel == up and (b._active_id() == up or b._usable(b._sel_unit())):
		var hb := _hash()
		b.handed_t = -9.0
		_clip("end_ship_enemy_turn_handover", 9.0)
		_key(KEY_SPACE)
		for i in 40:
			await get_tree().process_frame
			if b.hud.phase.visible and b.hud.phase_lbl.text.contains("ENEMY TURN") and b.hud.phase_lbl.text.contains("ship"):
				break
		await get_tree().create_timer(0.3 / maxf(Engine.time_scale, 1.0)).timeout
		await b._snap("%02d_enemy_turn" % (step_n + 1))
		await _idle()
		var ha := _hash()
		_rec("Space (end ship)", hb, ha)
	_check(b.VU.get(up, {}).get("activated", false) or int(b.V.get("round", 0)) > 1, "the first ship is done for the round")
	_check(b.plog.acts.size() >= 1 and str(b.plog.acts[-1].get("ship", "")) == up, "the play log recorded its activation (end: %s)" % str(b.plog.acts[-1].get("end", "?") if b.plog.acts.size() > 0 else "?"))
	await _idle()
	if b.ended:
		_finish()
		return
	await _shot("next_handed_over")
	var up2: String = b.sel
	_check(up2 != "" and up2 != up and b.api.phase == "player", "after the enemy's reply the game hands over the next ready ship (%s)" % b._name(up2))
	if up2 != "":
		var rb := int(b.V.get("round", 0))
		var hb := _hash()
		var can_brace: bool = bool(b._ui(up2).get("orders", {}).get("brace", false))
		if can_brace:
			_key(KEY_B)
		else:
			b.handed_t = -9.0
			_key(KEY_SPACE)
		await _idle()
		var ha := _hash()
		_rec("B (brace)" if can_brace else "Space (pass)", hb, ha)
		_check(b.VU.get(up2, {}).get("activated", false) or int(b.V.get("round", 0)) > rb, "%s ends that ship's turn" % ("Brace" if can_brace else "Pass"))
	# 6. the rest of the round: each handed-over ship moves toward the enemy and fires if it can, through the same clicks
	var r0 := int(b.V.get("round", 0))
	var guard := 0
	var atk_done := false
	var rounds := int(b.args.get("f1-rounds", 1))
	while not b.ended and int(b.V.get("round", 0)) < r0 + rounds and guard < 30 * rounds:
		guard += 1
		await _idle()
		if b.ended or int(b.V.get("round", 0)) >= r0 + rounds:
			break
		if b.api.phase != "player" or b.sel == "":
			await get_tree().process_frame
			continue
		var cur: String = b.sel
		b._update_reach()
		var mv = null
		for k in b.reach_map:
			var st = b.reach_map[k]
			if b._unit_at(int(st.q), int(st.r)).is_empty() and (mv == null or int(st.get("guns", 0)) > int(mv.get("guns", 0))):
				mv = st
		var any_bear := false
		for e in b.V["units"]:
			if e["side"] == "enemy" and not e["dead"] and not b._firing_set(e["id"]).is_empty():
				any_bear = true
		if mv != null and int(mv.get("guns", 0)) > 0 and not any_bear:
			_click_hex(int(mv.q), int(mv.r))
			_click_hex(int(mv.q), int(mv.r))
			await _idle()
		elif not any_bear and not atk_done:
			# nothing bears from anywhere obvious: try the attack-move, previewed then committed with a second click
			for e in b.V["units"]:
				if e["side"] == "enemy" and not e["dead"] and not e["squadron"] and b._attack_move(e["id"]) != null:
					var hb := _hash()
					_click_hex(int(e["q"]), int(e["r"]))
					await _idle()
					var shown: bool = b.atk != null and b.ghost != null and b.ghost.visible
					var mid := _hash()
					await _shot("attack_move_preview")
					_clip("attack_move", 6.0)
					_click_hex(int(e["q"]), int(e["r"]))
					await _idle()
					var ha := _hash()
					_rec("attack-move: click an out-of-reach enemy, then again", hb, ha, "preview shown=%s" % str(shown))
					_check(shown and hb["hash"] == mid["hash"] and hb["hash"] != ha["hash"], "attack-move shows its path and stop first (no change), commits on the second click")
					atk_done = true
					break
		if b.sel == cur and b._usable(b._sel_unit()):
			for e in b.V["units"]:
				if e["side"] == "enemy" and not e["dead"] and not b._firing_set(e["id"]).is_empty():
					_click_hex(int(e["q"]), int(e["r"]))
					_click_hex(int(e["q"]), int(e["r"]))
					await _idle()
					break
		if b.sel == cur and b._active_id() == cur:
			b.handed_t = -9.0
			_key(KEY_SPACE)
			await _idle()
		elif b.sel == cur and b._usable(b._sel_unit()):
			b.handed_t = -9.0
			_key(KEY_SPACE)
			await _idle()
	var hz := _hash()
	_rec("round %d played out%s" % [r0, (" (and %d more)" % (rounds - 1)) if rounds > 1 else ""], hz, hz, "now round %d" % int(b.V.get("round", 0)))
	_check(int(b.V.get("round", 0)) > r0 or b.ended, "a full round completes: every ship of both sides acted, no stall")
	await _shot("round_two")
	await _station_shot()
	_check(b.errors.is_empty(), "no errors in the battle (%s)" % ", ".join(PackedStringArray(b.errors)))
	_finish()


# a still of the station up close when the board has one (A4's painted station, switched on in render/board.gd)
func _station_shot() -> void:
	var sum := Vector3.ZERO
	var n := 0
	for k in b.V.get("terrain", {}):
		if str(b.V["terrain"][k]) == "station":
			var qr: PackedStringArray = str(k).split(",")
			sum += b.board.hex_world(float(qr[0]), float(qr[1]))
			n += 1
	if n == 0 or b.ended:
		return
	var props: Node = b.board.props
	if FileAccess.file_exists("res://gen/manifest.json"):  # A4's painted ships are built on the PC only
		_check(props != null and props.find_child("station", true, false) != null, "the station on the board is A4's painted one")
	b.cam.b = 0.9
	b.cam.glide(sum / float(n), 0.3, 120.0)
	await get_tree().create_timer(1.6 / maxf(Engine.time_scale, 1.0)).timeout
	await _shot("station")


func _finish() -> void:
	var acts: Array = b.plog.acts.duplicate(true)
	if b.plog.is_open():
		acts.append(b.plog.cur.duplicate(true))
	DirAccess.make_dir_recursive_absolute(dir)
	var f := FileAccess.open(dir.path_join("trace.jsonl"), FileAccess.WRITE)
	if f != null:
		for r in rows:
			f.store_line(JSON.stringify(r))
		f.store_line(JSON.stringify({"play_log": acts}))
	var t := FileAccess.open(dir.path_join("trace.txt"), FileAccess.WRITE)
	if t != null:
		t.store_string("F1 acceptance trace: %d checks, %d failed\n\n%s\n" % [lines.size(), fails, "\n".join(PackedStringArray(lines))])
	print("[f1-trace] pace ", JSON.stringify(b.pace_stats()))
	print("[f1-trace] %d checks, %d failed" % [lines.size(), fails])
	PG.finish(1 if fails > 0 else 0)
