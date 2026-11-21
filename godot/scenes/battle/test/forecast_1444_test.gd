extends SceneTree
# Issue 1444 (Neon's player audit, findings 1 and 4): the battle screen forecasts every one-click action that can cost a
# ship, through the real battle.gd input, card, tip and overlay code on rules battles:
#  RAM-1  the first X (or the Ram button) arms the ram: nothing reaches the rules, the card and the button tip show the
#         target, the damage and the recoil, the overlay marks the run and the target; a recoil that would kill your own
#         ship adds a red warning; the second X, Enter or a click on the target rams; Esc drops it.
#  BRD-1  in boarding mode the hovered enemy's tip and the card show the capture chance, the expected kills and the crew
#         you would lose; the Board button tip lists them too.
#  NOVA-1 hovering a nova target hex shows the 7-hex blast on the board and names every ship inside it, friendly ships
#         in red under "Friendly fire", with a red ring on them.
#  WELL-1 the move tip of a reachable hex near the Hollow Sun says whether it slingshots, pulls or burns.
#  WING-1 an Aspect of the Brood flagship (fx.hive, no launch ability) gets the Wings stance buttons, and they work.

const Battle := preload("res://scenes/battle/battle.gd")
const API := preload("res://rules/battle_api.gd")
const Sfx := preload("res://audio/sfx.gd")

class TestBoard extends "res://render/board.gd":
	var last_fills := {}
	var last_rings := {}
	func refresh() -> void:
		pass
	func set_overlay(o: Dictionary, rings_o := {}, styles := {}) -> void:
		last_fills = o.duplicate()
		last_rings = rings_o.duplicate()
		super.set_overlay(o, rings_o, styles)

class TestHud extends "res://ui/battle/hud.gd":
	func toast(_text: String) -> void:
		pass

class TestBattle extends Battle:
	func _ready() -> void:
		set_process(false)
	func _refresh_ui() -> void:
		pass
	func _cmd(f: Callable) -> bool:
		return bool(f.call())  # the real command without its animation

var failures := 0


func _initialize() -> void:
	_run.call_deferred()


static func _hd(aq: int, ar: int, bq: int, br: int) -> int:
	return int((absi(aq - bq) + absi(aq + ar - bq - br) + absi(ar - br)) / 2)


func _check(ok: bool, msg: String) -> void:
	if ok:
		print("  ok: ", msg)
	else:
		failures += 1
		printerr("FAIL: ", msg)


func _battle(api) -> TestBattle:
	var b := TestBattle.new()
	b.api = api
	b.board = TestBoard.new()
	b.add_child(b.board)
	b.hud = TestHud.new()
	b.hud.log_text = RichTextLabel.new()
	b.hud.add_child(b.hud.log_text)
	b.sfx = Sfx.new()
	b.arrow = MeshInstance3D.new()
	b.path_line = MeshInstance3D.new()
	b.path_dots = MultiMeshInstance3D.new()
	b.path_dots.multimesh = MultiMesh.new()
	b.cam = Battle.CamRig.new()
	for n in [b.arrow, b.path_line, b.path_dots, b.cam]: b.add_child(n)
	root.add_child(b)
	return b


func _sync(b: TestBattle) -> void:
	b.api.version += 1   # the test moved ships by hand: drop the cached rules answers
	b.V = b.api.view()
	b._index_view()


func _clear(api, q: int, r: int) -> void:
	api.R.B["terrain"].erase(api.R.hkey(q, r))


func _done(b: TestBattle) -> void:
	b.hud.free()
	b.sfx.free()
	b.free()


func _ram_setup(api) -> Array:
	api.new_battle_scenario("s1")
	var me: Dictionary = api.R.alive("player")[0]
	var foe: Dictionary = api.R.alive("enemy")[0]
	var d: Array = api.R.DIRS[0]
	me.merge({"q": 3, "r": 6, "facing": 0}, true)
	for i in range(1, 4):
		_clear(api, 3 + d[0] * i, 6 + d[1] * i)
	for x in api.R.B["units"]:
		if x != me and x != foe and int(x["r"]) == 6 and int(x["q"]) in [4, 5, 6]:
			x["q"] = int(x["q"]) + 9
	foe.merge({"q": 3 + d[0] * 3, "r": 6 + d[1] * 3}, true)
	return [me, foe]


func _ram() -> void:
	var api := API.new()
	api.load_rules()
	var pair := _ram_setup(api)
	var me: Dictionary = pair[0]
	var foe: Dictionary = pair[1]
	var b := _battle(api)
	_sync(b)
	b.sel = me["id"]
	var rm = b._ui(me["id"]).get("ram")
	_check(rm is Dictionary, "RAM-1 fixture: a ram is on (enemy three hexes dead ahead)")
	if not rm is Dictionary:
		_done(b)
		return
	api.take_events()
	var hp0 := float(foe["hp"])
	b._on_action("ram", null)
	_check(b.mode == "ram" and api.take_events().is_empty() and float(foe["hp"]) == hp0 and not bool(me.get("rammed", false)),
		"RAM-1 the first press only arms the ram (nothing reaches the rules)")
	var card := b._card_info()
	var hint := str(card.get("hint", ""))
	_check(hint.contains(str(foe["name"])) and hint.contains("%d hull" % int(rm["dmg"])) and hint.contains("%d recoil" % int(rm["recoil"])),
		"RAM-1 the card names the target, the damage (%d) and the recoil (%d)" % [int(rm["dmg"]), int(rm["recoil"])])
	_check((card.get("buttons", []) as Array).any(func(x): return x.get("act") == "confirm" and str(x.get("text", "")).begins_with("Ram") and x.get("primary", false)), "RAM-1 the card's primary button (the big action) is the ram")
	_check(not hint.contains("Warning"), "RAM-1 no red warning while the recoil (%d) is below the ship's hull (%s)" % [int(rm["recoil"]), str(me["hp"])])
	var tip := ""
	for o in b._panel_info().get("orders", []):
		if o.get("act") == "ram": tip = str(o.get("tip", ""))
	_check(tip.contains("%d hull" % int(rm["dmg"])) and tip.contains("%d recoil" % int(rm["recoil"])) and not tip.contains("[color"), "RAM-1 the Ram button tip carries the forecast as plain text")
	b._overlay()
	var tb: TestBoard = b.board
	var path_ok := true
	for p in rm["path"]:
		path_ok = path_ok and tb.last_rings.get(tb.key(p["q"], p["r"])) == Battle.Board.LS.col("ram")
	_check(path_ok and tb.last_rings.get(tb.key(foe["q"], foe["r"])) == Battle.Board.LS.col("danger"), "RAM-1 the overlay marks the %d-hex run and rings the target" % (rm["path"] as Array).size())
	b.hover = Vector2i(int(foe["q"]), int(foe["r"]))
	_check(b._tip().contains("recoil"), "RAM-1 hovering the target shows the ram forecast, not the gun tip")
	# a recoil that kills your own ship: the red warning
	var hp_me = me["hp"]
	me["hp"] = maxf(1.0, float(rm["recoil"]) - 1.0)
	_sync(b)
	_check(str(b._card_info().get("hint", "")).contains("Warning: the recoil will destroy your own ship"), "RAM-1 a lethal recoil shows the red warning")
	me["hp"] = hp_me
	_sync(b)
	# Esc drops it, nothing happens
	b._on_key(KEY_ESCAPE)
	_check(b.mode == "" and not bool(me.get("rammed", false)), "RAM-1 Esc drops the armed ram")
	# the second press rams
	b._on_action("ram", null)
	b._on_action("ram", null)
	var rammed := api.take_events().any(func(e): return e["t"] == "ram" and e["target"] == foe["id"])
	_check(rammed and bool(me.get("rammed", false)) and b.mode == "", "RAM-1 the second press rams")
	_done(b)
	# X then Enter; X then a click on the target
	for how in ["enter", "click", "the card's big button"]:
		var api2 := API.new()
		api2.load_rules()
		var pr := _ram_setup(api2)
		var b2 := _battle(api2)
		_sync(b2)
		b2.sel = pr[0]["id"]
		b2._on_key(KEY_X)
		var armed_only: bool = b2.mode == "ram" and not bool(pr[0].get("rammed", false))
		if how == "enter":
			b2._on_key(KEY_ENTER)
		elif how == "the card's big button":
			b2._on_action("confirm", null)
		else:
			b2.hover = Vector2i(int(pr[1]["q"]), int(pr[1]["r"]))
			b2._on_click()
		_check(armed_only and bool(pr[0].get("rammed", false)), "RAM-1 X arms, then %s rams" % how)
		_done(b2)


func _board() -> void:
	var api := API.new()
	api.load_rules()
	api.new_battle_scenario("s1")
	var me: Dictionary = api.R.alive("player")[0]
	var foe: Dictionary = api.R.alive("enemy")[0]
	me.merge({"q": 3, "r": 6, "facing": 0}, true)
	foe.merge({"q": 4, "r": 6}, true)
	var b := _battle(api)
	_sync(b)
	b.sel = me["id"]
	var bl: Array = b._ui(me["id"]).get("board", [])
	_check(not bl.is_empty(), "BRD-1 fixture: an adjacent enemy can be boarded")
	if bl.is_empty():
		_done(b)
		return
	var odds: Dictionary = bl[0]
	b._on_action("board", null)
	b.hover = Vector2i(int(foe["q"]), int(foe["r"]))
	var tip := b._tip()
	var loss := mini(int(odds["loss"]), int(me["crew"]) - 1)
	_check(tip.contains("%d%% capture chance" % int(odds["chance"])) and tip.contains("lose about %d of %d crew" % [loss, int(me["crew"])]) and tip.contains("Kills about %d" % int(odds["kill"])),
		"BRD-1 the hovered enemy's tip shows %d%% capture, %d kills, %d crew lost" % [int(odds["chance"]), int(odds["kill"]), loss])
	_check(tip.contains("capture likely") if bool(odds["capture"]) else (tip.contains("capture possible") if int(odds["chance"]) > 0 else tip.contains("no capture")), "BRD-1 the tip says whether a capture is possible")
	_check(str(b._card_info().get("hint", "")).contains("%d%% capture chance" % int(odds["chance"])), "BRD-1 the card lists the odds in boarding mode")
	var btip := ""
	for o in b._panel_info().get("orders", []):
		if o.get("act") == "board": btip = str(o.get("tip", ""))
	_check(btip.contains("%d%% capture chance" % int(odds["chance"])), "BRD-1 the Board button tip lists the odds")
	_done(b)


func _nova() -> void:
	var api := API.new()
	api.load_rules()
	api.new_battle_scenario("s1")
	var mine: Array = api.R.alive("player")
	var me: Dictionary = mine[0]
	var pal: Dictionary = mine[1]
	me["ab"] = "nova"
	me.merge({"q": 2, "r": 6, "facing": 0}, true)
	var b := _battle(api)
	_sync(b)
	b.sel = me["id"]
	b._on_action("ability", null)
	var hs := b._ability_hexes()
	_check(b.mode == "nova" and not hs.is_empty(), "NOVA-1 fixture: nova aim mode with target hexes")
	if hs.is_empty():
		_done(b)
		return
	var c: Dictionary = hs[hs.size() / 2]
	# put a friendly ship on the ring of the blast and keep every other ship well away
	var ring := Vector2i(int(c["q"]) + 1, int(c["r"]))
	for x in api.R.B["units"]:
		if x != me and x != pal and _hd(int(x["q"]), int(x["r"]), int(c["q"]), int(c["r"])) <= 1:
			x["q"] = int(x["q"]) + 8
	pal.merge({"q": ring.x, "r": ring.y}, true)
	_sync(b)
	b.hover = Vector2i(int(c["q"]), int(c["r"]))
	var tip := b._tip()
	_check(tip.contains("Friendly fire: %s (ring, %d)" % [str(pal["name"]), int(round(20.0 * float(me["dmg"])))]) and tip.contains("[color=#ff4a4a]"), "NOVA-1 the tip names the friendly ship inside the blast in red")
	b._overlay()
	var tb: TestBoard = b.board
	var n := 0
	for k in tb.last_fills:
		if tb.last_fills[k] == Battle.Board.LS.col("blast_fill"): n += 1
	_check(n >= 4 and n <= 7 and tb.last_rings.get(tb.key(ring.x, ring.y)) == Battle.Board.LS.col("danger"), "NOVA-1 the overlay shows the blast (%d hexes on the board) and rings the friendly ship red" % n)
	# a clear blast says so, and the click still fires on a marked hex
	pal["q"] = int(pal["q"]) + 8
	_sync(b)
	_check(not b._tip().contains("Friendly fire"), "NOVA-1 no friendly-fire line when no friend is inside")
	# Artoo on PR 1459: the numbers are the rules' own (novaDamage): a squadron takes x1.5, a flagship carrying the
	# story power bonus adds it, per ship in the blast
	var foe = api.R.alive("enemy")[0]
	foe.merge({"q": int(c["q"]), "r": int(c["r"])}, true)
	_check(foe != null, "NOVA-1 fixture: an enemy at the blast centre")
	if foe != null:
		foe["isSq"] = true
		_sync(b)
		var want := int(round(40.0 * float(me["dmg"]) * 1.5))
		_check(b._tip().contains("%s (centre, %d)" % [str(foe["name"]), want]), "NOVA-1 a squadron at the centre shows %d (40 x1.5), not 40" % want)
		api.R.B["cfg"]["storyMods"] = {"power": true}
		me["pflag"] = true
		_sync(b)
		var mult := 1.0 + float(api.R.TB.BEAT3_REWARDS.power)
		var want2 := int(round(40.0 * float(me["dmg"]) * 1.5 * mult))
		var tip2 := b._tip()
		_check(want2 != want and tip2.contains("%s (centre, %d)" % [str(foe["name"]), want2]), "NOVA-1 a flagship with the story power bonus (x%.2f) shows %d on the squadron" % [mult, want2])
		var pv: Array = api.nova_preview(me["id"], int(c["q"]), int(c["r"]))
		var same := not pv.is_empty()
		for pr in pv:
			same = same and is_equal_approx(float(pr["dmg"]), float(api.R.novaDamage(api.unit(me["id"]), api.unit(pr["id"]), {"q": int(c["q"]), "r": int(c["r"])})))
		_check(same, "NOVA-1 every forecast number is the rules' novaDamage, the call the hit makes")
	# issue 1433: hovering a nova hex while a worker holds the rules lock answers "pending" at once (nova_preview locks),
	# and the same hover after the worker finishes shows the forecast
	var sem := Semaphore.new()
	var tid := WorkerThreadPool.add_task(func() -> void:
		api._enter()
		sem.wait()
		api._leave(false))
	var w0 := Time.get_ticks_msec()
	while int(api._depth) == 0 and Time.get_ticks_msec() - w0 < 2000:
		OS.delay_msec(1)
	b._threat_tid = tid
	b._threat_busy = true
	b._threat_gen = -99   # not this battle's: the reap below discards it instead of publishing a fake map
	b._ptr_depth += 1
	var c0 := Time.get_ticks_usec()
	var tp := b._tip()
	var ms := (Time.get_ticks_usec() - c0) / 1000.0
	b._ptr_depth -= 1
	_check(int(api._depth) > 0 and tp == "" and ms < 50.0 and b._ptr_stale, "NOVA-1 a nova hover while a worker holds the rules answers pending in %.1f ms, without waiting" % ms)
	sem.post()
	while not WorkerThreadPool.is_task_completed(tid):
		OS.delay_msec(1)
	b._ptr_depth += 1
	var tp2 := b._tip()
	b._ptr_depth -= 1
	_check(b._threat_tid < 0 and not b._threat_busy and tp2.contains("Nova shell") and tp2.contains("centre"), "NOVA-1 once the worker is done the same hover reaps it and shows the nova forecast")
	_done(b)


func _well() -> void:
	var api := API.new()
	api.load_rules()
	api.new_battle_scenario("s1")
	var me: Dictionary = api.R.alive("player")[0]
	me.merge({"q": 3, "r": 6, "facing": 0}, true)
	var b := _battle(api)
	var R = api.R
	# the Hollow Sun six hexes east: hexes near the ship sit at every band
	R.B["well"] = {"q": 9, "r": 6}
	_sync(b)
	b.sel = me["id"]
	b._update_reach()
	var seen := {}
	for k in b.reach_map:
		var st = b.reach_map[k]
		if b._unit_at(int(st.q), int(st.r)).size() > 0:
			continue
		b.hover = Vector2i(int(st.q), int(st.r))
		var tip := b._tip()
		var d := _hd(int(st.q), int(st.r), 9, 6)
		var band := "rim" if d <= int(R.WELL_RIM) else ("pull" if d <= int(R.WELL_PULL) else ("sling" if d <= int(R.WELL_ASSIST) else "none"))
		var want: String = {"rim": "Hollow Sun rim", "pull": "Hollow Sun pull", "sling": "Hollow Sun slingshot", "none": ""}[band]
		var ok: bool = tip.contains(want) if want != "" else not tip.contains("Hollow Sun")
		if not ok:
			_check(false, "WELL-1 hex %d,%d (%d from the sun) tip: %s" % [int(st.q), int(st.r), d, tip])
		seen[band] = true
	_check(seen.size() >= 3, "WELL-1 the move tip names the band on every reachable hex (bands seen: %s)" % ", ".join(PackedStringArray(seen.keys())))
	R.B["well"] = null
	_sync(b)
	var any := false
	for k in b.reach_map:
		var st = b.reach_map[k]
		b.hover = Vector2i(int(st.q), int(st.r))
		any = any or b._tip().contains("Hollow Sun")
	_check(not any, "WELL-1 no Hollow Sun line on a board without it")
	_done(b)


func _wing() -> void:
	var api := API.new()
	api.load_rules()
	api.new_battle_scenario("s1")
	var me: Dictionary = api.R.alive("player")[0]
	me["ab"] = null
	if not me.get("fx") is Dictionary: me["fx"] = {}
	me["fx"]["hive"] = 1
	me.erase("stance")
	var b := _battle(api)
	_sync(b)
	b.sel = me["id"]
	var wings: Array = []
	for o in b._panel_info().get("orders", []):
		if o.get("act") == "stance": wings.append(o)
	_check(wings.size() == 3, "WING-1 an Aspect of the Brood flagship gets the three Wings buttons (got %d)" % wings.size())
	if wings.size() == 3:
		_check(wings[0].get("active", false) and not wings[0].get("on", true) and wings[1].get("on", false), "WING-1 the default stance (strike) shows as current; the others can be picked")
		b._on_action("stance", "screen")
		_check(str(me.get("stance", "")) == "screen", "WING-1 picking Screen changes the stance in the rules")
	_done(b)


func _run() -> void:
	_ram()
	_board()
	_nova()
	_well()
	_wing()
	if failures == 0:
		print("PASS: forecast_1444_test: Ram, Board, Nova and Hollow Sun forecasts, Brood wing stances")
	else:
		printerr("FAIL: forecast_1444_test: %d failed" % failures)
	quit(0 if failures == 0 else 1)
