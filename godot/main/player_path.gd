extends Node
# Drives the regular title, campaign controls and battle input handlers. The rules API is read-only here.
const ShipView = preload("res://render/ship_view.gd")
const PlaceholderGuard = preload("res://render/placeholder_guard.gd")
const HullAge = preload("res://render/hull_age.gd")
# Issue 1457: "stops" is each seed's planned route. When a planned stop is not an offered battle the recorder logs
# "route_drift" with the whole offer and takes the best offered battle instead; --player-path-strict fails there.
# Seed 10's 2-2 became an event stop on Nov 20 main, so seed 10 now drifts to 2-1 (a flagship battle against the Navy).
# Seed 121 is kept as a diagnostic, not an acceptance route (Artoo on issue 1457: a changed test route must not hide a
# campaign regression): its only Battle 3 is a relay hold against a Hullbreaker hulk-carrier and two raiders, which the
# scripted player still loses on Nov 21 main. Seed 31 is the Hullbreakers acceptance route; it plays its planned stops.
const Routes := {
	10: {"sector_enemy": "hegemony", "stops": ["0-0", "1-3", "2-2"]},
	31: {"sector_enemy": "corsair", "stops": ["0-0", "1-0", "2-0"]},
	121: {"sector_enemy": "corsair", "stops": ["0-0", "1-0", "2-0"], "diagnostic": true},
}
const BATTLE_TYPES := ["battle", "elite"]
const REWARD_ORDER := ["add", "tow", "mod", "cred", "ransom"]
const FPS := 30

var main: Node
var battle: Node
var route: Dictionary
var report_file: FileAccess
var battle_number := 0
var moved := {}
var last_cut := ""
var danger_seen := false
var first_preview := false
var rewards_seen := {}
var headless := false
var strict := false
var drift := []


# Called before Main loads settings or opens any screen. Godot may already have
# created its own log and cache directories, so check the root's files.
static func prepare_profile() -> String:
	var profile := OS.get_environment("VS_PLAYER_PATH_PROFILE").replace("\\", "/").simplify_path().trim_suffix("/")
	var temp := OS.get_environment("TEMP").replace("\\", "/").simplify_path().trim_suffix("/")
	var actual := ProjectSettings.globalize_path("user://").replace("\\", "/").simplify_path().trim_suffix("/")
	var user_dir := str(ProjectSettings.get_setting("application/config/custom_user_dir_name"))
	if not temp.is_absolute_path() or not profile.to_lower().begins_with(temp.to_lower() + "/voidsworn-player-path-") or \
			actual.to_lower() != profile.path_join(user_dir).to_lower():
		return "Godot must resolve user:// inside a dedicated temporary profile from player_path.bat"
	if not DirAccess.get_files_at("user://").is_empty():
		return "the recording profile already contains files"
	var marker := FileAccess.open("user://player_path_started", FileAccess.WRITE)
	if marker == null:
		return "the recording profile is not writable"
	marker.store_line("Player path recording profile")
	marker.close()
	return ""


func start(game: Node) -> void:
	main = game
	headless = DisplayServer.get_name() == "headless"
	var seed := int(main.args.get("player-path-seed", 0))
	if not Routes.has(seed):
		_fail("unknown seed, expected one of %s" % str(Routes.keys()))
		return
	route = Routes[seed]
	strict = main.args.has("player-path-strict")
	report_file = FileAccess.open(str(main.args["player-path"]), FileAccess.WRITE)
	if report_file == null:
		_fail("could not open the recording log")
		return
	var build_info = JSON.parse_string(FileAccess.get_file_as_string("res://build_info.json")) if FileAccess.file_exists("res://build_info.json") else null
	if not headless and (not build_info is Dictionary or str(build_info.get("commit", "")).is_empty() or \
			bool(build_info.get("source_dirty", false)) or not str(build_info.get("source_diff_sha256", "")).is_empty()):
		_fail("the installed recorder needs a build exported from a clean commit")
		return
	main.show_title()
	await _pause(1.5)
	if not headless and get_viewport().get_texture().get_size() != Vector2(1920, 1080):
		_fail("recording viewport is not 1920 by 1080")
		return
	_event("run", {"seed": seed, "sector_enemy": route.sector_enemy, "diagnostic": route.get("diagnostic", false), "strict": strict, "settings": main.settings,
		"manifest_sha256": FileAccess.get_sha256(ShipView.manifest_path), "mesh_lod_threshold": get_viewport().mesh_lod_threshold,
		"headless": headless, "build": build_info, "profile_isolated": true, "user_data_dir": ProjectSettings.globalize_path("user://")})
	if not _press(main.title, "New run"):
		_fail("New run button is unavailable")
		return
	await _pause(1.0)
	var steps := 0
	while steps < 70:
		steps += 1
		var host = main.campaign
		if not is_instance_valid(host):
			_fail("the campaign returned to title")
			return
		if is_instance_valid(battle):
			await _play_battle()
			if battle_number == 3 or main.is_queued_for_deletion():
				return
		elif not host.in_battle:
			if not await _campaign_step(host):
				return
		await _pause(0.4)
	_fail("campaign stopped making progress")


func watch_battle(b: Node, api, host: Node) -> void:
	battle = b
	battle_number += 1
	moved.clear()
	danger_seen = false
	first_preview = false
	last_cut = ""
	b.recording_cue.connect(_battle_cue)
	b.arrival.connect(_arrival)
	var cfg: Dictionary = host.cfg_now
	_event("battle_start", {"node": cfg.get("node"), "enemy": cfg.get("fac"), "objective": cfg.get("obj"), "seed": int(cfg.get("seed", 0)), "teaching_battle": cfg.get("teachingBattle", 0)})
	if battle_number == 2 and (cfg.get("obj") != "hold" or not api.teaching_info().get("event") is Dictionary):
		_fail("Battle 2 did not roll the relay and its teaching reinforcement")
	elif battle_number == 3 and cfg.get("fac") != route.sector_enemy:
		_fail("Battle 3 did not feature the route's Sector I enemy")


func _frame() -> int:
	return Engine.get_process_frames() if headless else Engine.get_frames_drawn()


func _event(kind: String, values := {}) -> void:
	var row := {"kind": kind, "frame": _frame(), "battle": battle_number}
	row.merge(values)
	report_file.store_line(JSON.stringify(row))
	report_file.flush()


func _fail(reason: String) -> void:
	printerr("[player-path] FAIL ", reason)
	if report_file != null:
		_event("failure", {"reason": reason})
		report_file.close()
	main.quit_clean(1)


func _pause(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


func _press(node: Node, caption: String) -> bool:
	var button := _button(node, caption)
	if button == null:
		return false
	button.pressed.emit()
	return true


func _button(node: Node, caption: String) -> Button:
	if node == null:
		return null
	for item in node.find_children("*", "Button", true, false):
		var button := item as Button
		if button.text == caption and button.is_visible_in_tree() and not button.disabled:
			return button
	return null


func _campaign_step(host: Node) -> bool:
	var c = host.C
	var ui = host.ui
	var keep_name := _button(host.story, "Keep the name")
	if keep_name != null:
		_event("campaign_card", {"id": "name_flagship"})
		await _pause(3.0)
		keep_name.pressed.emit()
		return true
	if ui.teaching.current != "":
		_event("campaign_card", {"id": ui.teaching.current})
		await _pause(3.0)
		_press(ui.teaching, "Got it")
		await _pause(0.35)
		return true
	var page: String = str(c.page.get("kind", ""))
	var on: Array = c.screen_acts().filter(func(a): return int(a[2]) == 1)
	if page == "map" and c.modal_d == null:
		if c.RUN.map.fac != route.sector_enemy:
			_fail("seed did not produce the expected Sector I enemy")
			return false
		var offered := _offered(c, on)
		var planned: String = route.stops[battle_number]
		var id := _pick_stop(c, offered, planned)
		if id != planned:
			var row := {"after_battle": battle_number, "planned": planned, "taken": id, "pos": c.RUN.get("pos"), "offered": offered}
			drift.append(row)
			_event("route_drift", row)
			printerr("[player-path] ROUTE DRIFT after Battle %d: planned %s, taking %s; offered %s" % [battle_number, planned, id, str(offered)])
			if strict or id == "":
				_fail("planned route %s is not an offered battle after Battle %d" % [planned, battle_number])
				return false
		_event("route_stop", {"id": id, "planned": planned, "offered": offered})
		# Issue 1448: on a fresh profile the sector map is still behind its loading cover here (its planet bakes queue
		# behind the title's), and a jump pressed then is dropped (map3d.fly_to refuses while loading), so every Windows
		# recording on a fresh profile failed at "jump to 0-0 did not open". A player waits for the cover; so does this.
		if not await _map_ready(ui):
			return false
		ui.pick_route(id)
		await _pause(1.0)
		var jumped := _frame()
		var jb = ui.get("_jump_btn")
		if jb is BaseButton and is_instance_valid(jb) and jb.is_visible_in_tree() and not jb.disabled:
			jb.pressed.emit()   # the Jump button, with its cue (issue 1448)
		else:
			ui._jump()
		# Normal map mode animates the ship's jump before handing over to the campaign.
		for i in 45:
			if host.in_battle or c.modal_d != null:
				_event("jump_open", {"id": id, "frames": _frame() - jumped})
				return true
			await _pause(0.2)
		var m = ui.get("map3d")
		if m != null:   # the map's state, for the failure below (its reason text stays the one run.ps1 retries on)
			_event("jump_stuck", {"id": id, "loading": m.get("loading"), "flying": m.get("_flying"), "picked": ui.get("picked")})
		_fail("jump to %s did not open" % id)
		return false
	if page == "end":
		_fail("the run ended before the three battles were recorded")
		return false
	var choice := _campaign_choice(on)
	if choice.is_empty():
		_fail("no supported player choice on %s: %s" % [page, str(on)])
		return false
	_event("campaign_choice", {"page": page, "action": choice[0], "choice": choice[1]})
	await _pause(1.0)
	# Issue 1448: press the button a player would, so the recording carries its cue; the action itself is the fallback.
	if not press_act(host, str(choice[0]), str(choice[1])):
		_event("choice_unpressed", {"action": choice[0], "choice": choice[1]})
		ui._campaign_action(str(choice[0]), str(choice[1]))
	return true


# The visible, enabled button tagged with this campaign action (campaign_ui.press_tag); true once it is pressed.
static func press_act(root: Node, act: String, arg: String) -> bool:
	if root == null:
		return false
	for n in root.find_children("*", "Control", true, false):
		if str(n.get_meta("press_act", "")) != act or str(n.get_meta("press_arg", "")) != arg:
			continue
		if n.is_queued_for_deletion() or not n.is_visible_in_tree() or bool(n.get("disabled")) or not n.has_signal("pressed"):
			continue
		n.emit_signal("pressed")
		return true
	return false


func _offered(c, on: Array) -> Array:
	var rows := []
	for n in c._nodes():
		if on.any(func(a): return a[0] == "enterNode" and a[1] == n["id"]):
			var t := str(n.get("type", ""))
			rows.append({"id": n["id"], "type": t, "enc": str(n.get("enc", "")),
				"fac": str(c.nodeFaction(n)) if t in BATTLE_TYPES else "", "nemesis": bool(c.nemNodeIs(n))})
	return rows


# The planned stop when it is an offered battle; otherwise the best offered battle: Battle 3 must meet the sector's
# own enemy, a plain battle before an elite, then a rout (the fight the scripted player plays best). "" when none fits.
# Waits (game time, at most map_wait_s) until the 3D sector map has finished loading; logs how long it waited.
var map_wait_s := 120
func _map_ready(ui) -> bool:
	var m = ui.get("map3d")
	if m == null or not is_instance_valid(m) or not m.visible or not bool(m.get("loading")):
		return true
	var start := _frame()
	while bool(m.get("loading")):
		if _frame() - start > map_wait_s * FPS:
			_fail("the sector map was still loading after %d s" % map_wait_s)
			return false
		await get_tree().process_frame
	_event("map_ready", {"waited_frames": _frame() - start})
	await _pause(0.5)
	return true


func _pick_stop(c, offered: Array, planned: String) -> String:
	var fits := func(n: Dictionary) -> bool:
		return n.type in BATTLE_TYPES and not n.nemesis and (battle_number < 2 or n.fac == route.sector_enemy)
	for n in offered:
		if n.id == planned and fits.call(n):
			return planned
	var best := ""
	var rank := -INF
	for n in offered:
		if not fits.call(n):
			continue
		# Battle 2 is the relay teaching battle, so it needs a hold node; later battles prefer a rout
		var score := (2.0 if n.type == "battle" else 0.0) + ((4.0 if n.enc == "hold" else 0.0) if battle_number == 1 else (1.0 if n.enc == "rout" else 0.0))
		if score > rank:
			best = n.id
			rank = score
	if best == "":
		# No battle fits from here: pass through a stop as a player would (a repair stop first) and plan again after it.
		for n in offered:
			if not n.type in BATTLE_TYPES and not n.nemesis and (best == "" or n.type in ["field", "drydock"]):
				best = n.id
	return best


func _campaign_choice(on: Array) -> Array:
	for name in ["startRun", "pickAspect", "prizeSet", "prizeConfirm", "takeSalvage", "salvageStep", "prizeStep",
		"takeBoon", "takeMod", "takeRelic", "takePerk", "rewardNext", "eventChoice", "closeModal"]:
		var best := []
		var rank := INF
		for a in on:
			if a[0] != name:
				continue
			if name != "prizeSet" and name != "takeSalvage":
				return a
			# Issue 1457: take the prize a player building a fleet for Battle 3 takes: a new ship first (add, then tow),
			# then a refit, then the money. The old first-listed pick refitted every time and the seed 121 fleet stayed at
			# three ships against a hulk-carrier and two raiders.
			var pick := str(a[1])
			var key := "%d:%s:%s" % [battle_number, name, pick.get_slice(":", 0)]
			var order := REWARD_ORDER.find(pick.get_slice(":", pick.get_slice_count(":") - 1))
			if rewards_seen.has(key) or order < 0 or order >= rank:
				continue
			best = a
			rank = order
		if not best.is_empty():
			var pick := str(best[1])
			rewards_seen["%d:%s:%s" % [battle_number, name, pick.get_slice(":", 0)]] = true
			return best
	return []


func _battle_cue(kind: String, description: String) -> void:
	if kind == "cut_start":
		last_cut = description
	elif kind == "cut_end":
		description = last_cut
		last_cut = ""
	_event(kind, {"text": description})


func _arrival(units: Array) -> void:
	for u in units:
		_event("arrival", {"ship": u.get("name", ""), "side": u.get("side", "")})


func _fleet() -> Array:
	var rows := []
	for u in battle.V.get("units", []):
		var sv = battle.views.get(u["id"])
		if sv == null or u.get("squadron", false) or u.get("dead", false):
			continue
		rows.append({"ship": u.get("name", ""), "class": u.get("cls", ""), "side": u.get("side", ""), "code": sv.code,
			"asset": ShipView.manifest().get("ships", {}).get(sv.code, {}).get("res", ""), "parted_hull": sv.a4,
			"layout": HullAge.layout(sv.code), "source": HullAge.resolved(sv).get("source", "")})
	return rows


func _play_battle() -> void:
	var b := battle
	var start := _frame()
	while not b.ended and (b.api == null or b.warming or b.opening):
		if _frame() - start > 30 * FPS:
			_fail("opening did not finish")
			return
		await get_tree().process_frame
	_event("board", {"fleet": _fleet(), "voice_on": b.voice != null, "hud": b.hud.visible, "cut_ins": b.cine, "tips_on": not b.tips_off})
	if not headless and PlaceholderGuard.stop_if_any():
		_fail("a required installed hull is missing")
		return
	# Headless cloud runs step frames faster than real time while timers keep game time, so allow more frames there.
	var deadline := _frame() + 600 * FPS * (4 if headless else 1)
	var seen_round := -1
	while _frame() < deadline:
		if int(b.V.get("round", 0)) != seen_round:
			seen_round = int(b.V.get("round", 0))
			_event("round", _snapshot(b))
		if b.hud.endcard != null:
			_event("end_card", {"result": b.result.get("result"), "rounds": b.result.get("rounds"), "errors": b.result.get("errors"), "fleet": _fleet()})
			await _pause(3.0)
			_event("battle_end")
			if b.result.get("result") != "win":
				_fail("the route lost Battle %d" % battle_number)
			elif battle_number == 3:
				_event("route_summary", {"planned": route.stops, "drift": drift})
				print("[player-path] completed three battles%s" % ("" if drift.is_empty() else " (route drift: %d stops, see route_drift rows)" % drift.size()))
				report_file.close()
				main.quit_clean(0)
			else:
				battle = null
				_press(b.hud, "Continue")
			return
		if not danger_seen and b._danger_shown() and not b._danger.is_empty():
			danger_seen = true
			_event("danger", {"round": b.V["round"]})
		if b.hud.tipcard != null and not b.busy:
			_event("teaching_card", {"id": b.tip_current, "round": b.V["round"]})
			await _pause(3.0)
			_press(b.hud.tipcard, "Got it")
			await _pause(0.3)
		elif b._can_act() and not b.ended:
			if b.sel.is_empty():
				_event("next_ship", {"round": b.V["round"]})
				b._on_key(KEY_TAB)
				await _pause(0.4)
			else:
				await _orders(b)
		else:
			await get_tree().process_frame
	_fail("Battle %d exceeded its replay limit" % battle_number)


# One line per round so a lost or stalled battle can be read back without the video.
func _snapshot(b: Node) -> Dictionary:
	var units := []
	for u in b.V.get("units", []):
		if not u.get("dead", false) and not u.get("squadron", false):
			units.append([u.get("name", ""), u.get("side", ""), int(u.get("q", 0)), int(u.get("r", 0)), int(u.get("hp", 0))])
	var row := {"round": b.V.get("round"), "units": units}
	var obj = b.V.get("obj")
	if obj is Dictionary:
		row["obj"] = obj
	return row


func _orders(b: Node) -> void:
	var u: Dictionary = b._sel_unit()
	var label := "%s:%s" % [b.V["round"], u["id"]]
	var foes: Array = b.V["units"].filter(func(e): return e["side"] == "enemy" and not e["dead"] and not e.get("squadron", false))
	var obj = b.V.get("obj")
	var rally: Dictionary = obj.get("hex", {}) if obj is Dictionary and obj.get("type") == "hold" else {}
	var plan := {}
	if not moved.has(label) and not foes.is_empty() and int(u.get("moveLeft", 0)) > 0:
		plan = _move_plan(b, u, foes, rally)
	if not rally.is_empty() and not plan.is_empty() and _distance(u, rally) > 1 and _distance(plan, rally) <= 1:
		moved[label] = true
		if await _move(b, u, plan):
			return
	var target: Dictionary = _target(b, foes, rally)
	if not target.is_empty():
		if b.api.can_command() and int(b.V["round"]) >= 2:
			_event("command", {"round": b.V["round"], "name": b._command_label()})
			b._on_key(KEY_C)
			await _pause(0.45)
			b._on_key(KEY_C)
			await _pause(0.2)
			return
		if b.target == target["id"]:
			b._on_key(KEY_ESCAPE)
		_point(b, target)
		await _pause(0.25)
		await _click(b, target)
		if b.target == target["id"]:
			_event("target_preview", {"ship": target["name"], "round": b.V["round"]})
			await _pause(0.65)
			await _clear_tip(b)
			if b.target != target["id"]:
				return
			b._on_key(KEY_ENTER)
			await _pause(0.2)
			return
	if not plan.is_empty() and not moved.has(label):
		moved[label] = true
		if rally.is_empty() and (first_preview or int(b.V["round"]) > 1):
			if await _attack_move(b, foes):
				return
		if await _move(b, u, plan):
			return
	if b._ui(u["id"]).get("orders", {}).get("brace", false):
		b._on_key(KEY_B)
	else:
		# The same handler as the End ship button, without Space's real-time debounce.
		b._on_action("end", null)
	await _pause(0.2)


func _move(b: Node, u: Dictionary, plan: Dictionary) -> bool:
	# Issue 1457: the first round's plan can be dropped while the preview shows (seed 121, Battle 3: the cruiser braced
	# in place in round 1). Plan the same hex once more before giving up, as a player clicks again.
	for attempt in 2:
		await _click(b, plan)
		if b.plan == null:
			return false
		_event("move_preview", {"hex": [plan.q, plan.r], "ship": u["name"], "round": b.V["round"]})
		await _pause(0.55)
		await _clear_tip(b)
		if b.plan == null or not b._can_act():
			_event("plan_dropped", {"hex": [plan.q, plan.r], "ship": u["name"], "round": b.V["round"]})
			await _pause(0.3)
			continue
		b._on_key(KEY_ENTER)
		await _pause(0.2)
		return true
	return false


# Issue 1457: a teaching card that opens while an order is previewed takes the Enter meant for the order, and the ship
# then sat out the round (seed 121, Battle 3 round 1). Read the card first, as a player would.
func _clear_tip(b: Node) -> void:
	if b.hud.tipcard != null:
		_event("teaching_card", {"id": b.tip_current, "round": b.V["round"]})
		await _pause(3.0)
		_press(b.hud.tipcard, "Got it")
		await _pause(0.3)


func _attack_move(b: Node, foes: Array) -> bool:
	for e in foes:
		if b._attack_move(e["id"]) == null:
			continue
		await _click(b, e)
		if b.atk != null:
			first_preview = true
			_event("attack_move_preview", {"ship": e["name"]})
			await _pause(0.85)
			await _clear_tip(b)
			if b.atk == null:
				return false
			b._on_key(KEY_ENTER)
			await _pause(0.2)
			return true
	return false


func _target(b: Node, foes: Array, rally: Dictionary) -> Dictionary:
	var best := {}
	var rank := -INF
	for e in foes:
		var guns: Array = b._firing_set(e["id"])
		if guns.is_empty():
			continue
		var damage := 0.0
		for wi in guns:
			var odds: Dictionary = b._fire_preview(b.sel, wi, e["id"])
			damage += float(odds.get("hull", 0.0)) + 0.4 * float(odds.get("shield", 0.0))
		var score := damage + 6.0 * guns.size() - 0.12 * float(e["hp"])
		if not rally.is_empty() and _distance(e, rally) <= 1:
			score += 70.0
		if score > rank:
			best = e
			rank = score
	return best


func _move_plan(b: Node, u: Dictionary, foes: Array, rally: Dictionary) -> Dictionary:
	var best := {}
	var rank := -INF
	# Issue 1457: distances go around blocking terrain. With straight-line distances the seed 121 cruiser and destroyer
	# shuffled behind an asteroid wall for 14 rounds while the relay was lost.
	var to_foe := _path_field(b, foes)
	var to_rally := _path_field(b, [rally]) if not rally.is_empty() else {}
	for st in b.reach_map.values():
		if (int(st.q) == int(u.q) and int(st.r) == int(u.r)) or not b._unit_at(int(st.q), int(st.r)).is_empty():
			continue
		var nearest := float(to_foe.get(_key(st), INF))
		if nearest == INF:
			for e in foes:
				nearest = minf(nearest, _distance(st, e))
		var score := float(st.get("guns", 0)) * 8.0 - nearest * 6.0 - float(st.cost) * 0.15 - 5.0 * int(b._danger_at(st))
		if not rally.is_empty():
			var d := float(to_rally.get(_key(st), _distance(st, rally)))
			if _distance(u, rally) <= 1:
				continue
			score -= 45.0 * maxf(0.0, d - 1.0)
		if score > rank:
			best = st
			rank = score
	return best


static func _key(h: Dictionary) -> String:
	return "%d,%d" % [int(h.q), int(h.r)]


# Steps from every open hex to the nearest of the goals, walking only hexes the board can be crossed through
# (read from the view's hexes and terrain; nothing is sent to the rules).
func _path_field(b: Node, goals: Array) -> Dictionary:
	var open := {}
	var terrain: Dictionary = b.V.get("terrain", {})
	var rules = b.api.R if b.api != null else null
	for h in b.V.get("hexes", []):
		var k := _key(h)
		if rules != null and rules.blocks(terrain.get(k)):
			continue
		open[k] = h
	var dist := {}
	var queue := []
	for g in goals:
		var k := _key(g)
		if not dist.has(k):
			dist[k] = 0
			queue.append(g)
	var dirs := [[1, 0], [1, -1], [0, -1], [-1, 0], [-1, 1], [0, 1]]
	var i := 0
	while i < queue.size():
		var h: Dictionary = queue[i]
		i += 1
		var d: int = dist[_key(h)]
		for dv in dirs:
			var n := {"q": int(h.q) + dv[0], "r": int(h.r) + dv[1]}
			var k := _key(n)
			if open.has(k) and not dist.has(k):
				dist[k] = d + 1
				queue.append(n)
	return dist


static func _distance(a: Dictionary, b: Dictionary) -> float:
	var dq := float(a.q) - float(b.q)
	var dr := float(a.r) - float(b.r)
	return maxf(maxf(absf(dq), absf(dr)), absf(dq + dr))


func _point(b: Node, hex: Dictionary) -> void:
	var p: Vector2 = b.cam.unproject_position(b.board.hex_world(int(hex.q), int(hex.r)))
	# Drive the same board hover as a real mouse. The recorder never sends a command to the rules.
	b._on_hover(p)
	if not headless and get_viewport().get_visible_rect().has_point(p):
		get_viewport().warp_mouse(p)


func _click(b: Node, hex: Dictionary) -> void:
	_point(b, hex)
	b._on_click()
	# Artoo on PR 1483: with issue 1433's queued clicks (PR 1443) a click made while the threat map computes is kept
	# and replayed when it lands, so "no plan yet" can mean "pending". Wait for the replay (bounded) before reading
	# the plan or target. On a build without the queue there is nothing to wait for.
	var start := _frame()
	while "_click_q" in b and not (b.get("_click_q") as Dictionary).is_empty() and _frame() - start < 5 * FPS:
		await get_tree().process_frame
	if "_click_q" in b and not (b.get("_click_q") as Dictionary).is_empty():
		_event("click_pending_timeout", {"hex": [hex.q, hex.r], "round": b.V["round"]})
