extends SceneTree
## Issue 2081: one comms display, ordered bounded backlog, event ownership, clear on battle end and no input.

const API := preload("res://rules/battle_api.gd")
const Campaign := preload("res://campaign/campaign.gd")
const CampaignUI := preload("res://ui/campaign/campaign_ui.gd")
const Portraits := preload("res://portraits/portraits.gd")
const StaticCaches := preload("res://render/static_caches.gd")
const Guard := preload("res://tools/ci/check_guard.gd")
const CommsBanner := preload("res://ui/battle/comms_banner.gd")
const K := CommsBanner.Kind
const CAPTAIN := {"id": "cap-1", "name": "Mara Venn", "callsign": "Cinder"}
const ADMIRAL := {"id": "vex", "name": "Admiral Vex"}

class Probe extends Node:
	var clicks := 0
	func _unhandled_input(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed:
			clicks += 1

class Playback extends "res://scenes/battle/battle.gd":
	func wait(_ms: float, _skippable_cut := false) -> void:
		pass

var failures := 0


func _init() -> void:
	Guard.arm(self, "turn_corner_check")
	_run.call_deferred()


func _check(ok: bool, message: String) -> void:
	print(("PASS: " if ok else "FAIL: ") + message)
	if not ok:
		failures += 1


func _queue(b: Playback) -> void:
	var banner: CommsBanner = b.hud.comms
	banner.clear()
	banner.set_process(false)
	b.hud.set_top(1, "player", "Objective: break their fleet", "", false, false, false)
	banner.enqueue(K.HAIL, ADMIRAL, "Contact.")
	b.hud._layout()
	banner._process(0.0)
	banner._process(0.21)
	_check(banner.current.get("kind") == K.HAIL and banner.visible and is_equal_approx(banner.modulate.a, 1.0),
		"only the active message is visible after the 200 ms slide")
	var shown_line := banner._line.text
	banner.enqueue(K.HAIL, ADMIRAL, "Low priority.")
	banner.enqueue(K.COMMAND, ADMIRAL, "Iron is active.")
	banner.enqueue(K.KILL, CAPTAIN, "First target destroyed.")
	banner.enqueue(K.SELECTED_LOSS, CAPTAIN, "Prow destroyed.")
	banner.enqueue(K.HAIL, ADMIRAL, "Newest low priority.")
	banner._process(0.6)
	banner.enqueue(K.KILL, CAPTAIN, "Second target destroyed.")
	_check(banner.pending.map(func(e): return e["kind"]) == [K.SELECTED_LOSS, K.KILL, K.COMMAND],
		"three waiting messages in priority order, with old and new hails dropped first")
	_check(banner._line.text == shown_line and banner.pending[1].get("line") == "2 kills",
		"higher priority waits and repeated kills coalesce in pending")
	var home: Rect2 = b.hud.ledger.comms_slot
	var middle := home.get_center()
	_check(home.has_area() and home.end.y < b.hud.ledger.sheet_r.position.y and not b.hud.over_ui(middle),
		"below the turn block and clear of the fire controls and HUD input regions")
	_check(b.hud.hud_blockers().has(banner.get_global_rect()), "ship labels avoid the banner without blocking clicks")
	_check(root.gui_get_focus_owner() == null and _ignores_mouse(banner), "banner and every child ignore mouse and focus")
	var probe := Probe.new()
	root.add_child(probe)
	for pressed in [true, false]:
		var click := InputEventMouseButton.new()
		click.button_index = MOUSE_BUTTON_LEFT
		click.position = middle
		click.global_position = middle
		click.pressed = pressed
		root.push_input(click)
	_check(probe.clicks == 1, "a real viewport click passes through the active banner")
	probe.free()
	banner._process(2.89)
	_check(banner.current.get("kind") == K.HAIL and is_equal_approx(banner.modulate.a, 1.0),
		"active banner holds for about 3.5 seconds")
	banner._process(0.08)
	_check(banner.current.get("kind") == K.HAIL and banner.modulate.a < 1.0, "active banner slides away")
	banner._process(0.2)
	_check(banner.current.get("kind") == K.SELECTED_LOSS, "selected ship section loss plays next")
	_check(banner._speaker.text == "MARA VENN" and banner._callsign.text == "CINDER", "name and callsign have separate space")
	banner._process(4.0)
	_check(banner.current.get("kind") == K.KILL and banner._line.text == "2 kills", "merged kills play before Command")
	banner._process(4.0)
	_check(banner.current.get("kind") == K.COMMAND, "Command plays after kills")
	banner.clear()
	banner.enqueue(K.KILL, CAPTAIN, "One target destroyed.")
	banner._process(0.0)
	banner._process(0.5)
	banner.enqueue(K.KILL, CAPTAIN, "Two targets destroyed.")
	_check(banner._line.text == "2 kills" and banner.pending.is_empty(), "repeated kills also merge into the active banner")
	banner._process(1.01)
	banner.enqueue(K.KILL, CAPTAIN, "Later target destroyed.")
	banner.enqueue(K.KILL, {"id": "cap-2"}, "Different captain.")
	_check(banner.pending.size() == 2 and banner.pending[0]["line"] == "Later target destroyed.",
		"later kills and another captain stay separate, with equal priority in arrival order")
	banner.clear()
	banner.place(home, b.hud.k, true, true)
	banner.enqueue(K.HAIL, ADMIRAL, "Still.")
	banner._process(0.0)
	_check(banner.position == home.position and banner.modulate.a == 1.0, "Reduce motion shows the banner without sliding")
	banner.enqueue(K.COMMAND, ADMIRAL, "After resize.")
	b.hud.k -= 0.05
	b.hud._rebuild()
	_check(b.hud.comms == banner and banner.get_parent() == b.hud.root and banner.current.get("kind") == K.HAIL
		and banner.pending.size() == 1, "HUD scale rebuild keeps the active line and backlog")
	banner.clear()


func _ignores_mouse(n: Node) -> bool:
	if n is Control and (n.mouse_filter != Control.MOUSE_FILTER_IGNORE or n.focus_mode != Control.FOCUS_NONE):
		return false
	for child in n.get_children():
		if not _ignores_mouse(child):
			return false
	return true


func _run() -> void:
	var campaign := Campaign.new()
	campaign.persist_on = false
	campaign.fixed_clock = true
	var api := API.new()
	if campaign.load_tables() != "" or api.load_rules() != "":
		_check(false, "load campaign and battle tables")
		quit(1)
		return
	API.JSM.rnd_seed(2081)
	campaign.newRun("vex", "voidsworn")
	api.new_battle(campaign.RUN, {"campaign": true, "seed": 2081, "kind": "battle", "obj": "rout", "col": 2,
		"map": "open", "shape": "open", "arena": "strip", "fac": "hegemony",
		"enemies": [{"tpl": "h_picket"}, {"tpl": "h_picket"}]})
	if api.phase != "player":
		_check(false, "test battle must be in the player phase")
		quit(1)
		return
	var battle := Playback.new()
	battle.external = true
	battle.args = {"noworld": true}
	root.add_child(battle)
	await battle._begin(api)
	var banner: CommsBanner = battle.hud.comms
	banner.set_process(false)
	_check(banner.pending.any(func(e): return e["kind"] == K.HAIL) or banner.current.get("kind") == K.HAIL,
		"the opening story line reaches the comms banner")
	_queue(battle)
	var player: Dictionary = api.R.caps("player")[0]
	var enemy: Dictionary = api.R.caps("enemy")[0]
	var p := str(player["id"])
	var e := str(enemy["id"])
	battle.sel = p
	battle.VU[p]["captain"]["trait_line"] = "Prow battery gets extra range."
	battle.hud.set_panel(battle._panel_info())
	battle.hud.ledger.ensure_layout()
	var captain: Dictionary = player["ship"]["cap"]
	var words: Array = battle.hud.ledger.items.map(func(item): return item["t"])
	_check(words.has(captain["callsign"]) and words.has("Prow battery gets extra range.")
		and battle.hud.ledger.marks.any(func(m): return m.k == "portrait"),
		"the existing KEEL panel draws the selected captain's face, callsign and trait")
	var losses := [{"t": "section_down", "unit": p, "section": "prow"},
		{"t": "section_down", "unit": p, "section": "eng"}]
	battle._comms_section_losses(losses)
	_check(banner.pending.size() == 1 and banner.pending[0]["line"] == "Prow and engines destroyed."
		and banner.pending[0]["kind"] == K.SELECTED_LOSS and banner.pending[0]["identity"]["callsign"] == captain["callsign"],
		"two losses in one volley produce one selected captain message")
	battle._comms_kill({"unit": e, "by": p}, {"units": [{"id": e, "side": "enemy", "rising": 2}]})
	_check(banner.pending.size() == 1, "a reassembling Eclipse ship is not called a kill")
	battle._comms_kill({"unit": e, "by": p}, {"units": [{"id": e, "side": "enemy", "name": "Enemy picket"}]})
	_check(banner.pending.any(func(msg): return msg["kind"] == K.KILL), "a confirmed kill gets the acting captain")
	var accepted := api.command()
	var command_events := api.take_events().filter(func(ev): return ev["t"] == "command")
	_check(accepted and command_events.size() == 1, "the real Command produces a playback event")
	for ev in command_events:
		await battle._play_event(ev)
	var adm: Dictionary = banner.pending.back().get("identity", {}) if not banner.pending.is_empty() else {}
	_check(adm.get("id") == "vex" and adm.get("face") == Portraits.face("vex"),
		"the Command uses the actual admiral's identity and portrait")
	banner._process(0.0)
	battle._end_flow()
	_check(banner.pending.is_empty() and banner.current.is_empty() and not banner.visible,
		"the battle end clears both the active message and backlog")
	battle._retire()
	# Let the now-stale end-card timer return before freeing the battle.
	await create_timer(1.25).timeout
	battle.free()
	_fallen(campaign, api, player, enemy)
	await process_frame
	StaticCaches.clear_all()
	quit(0 if failures == 0 else 1)


func _fallen(c: Campaign, api: API, target: Dictionary, killer: Dictionary) -> void:
	var rules = api.R
	var gun: Dictionary = killer["weapons"][0]
	var source: Dictionary = rules.CombatRecords.source(killer, gun)
	var hit: Dictionary = rules.CombatRecords.hit(rules.B, source, target, 0.0, float(target["hp"]))
	rules.killUnit(target, killer, false, hit)
	# Pick a seed whose first draw is a death (the escape roll is the only draw before recording this loss).
	var seed_value := 1
	while true:
		API.JSM.rnd_seed(seed_value)
		if API.JSM.rnd() >= 0.6:
			break
		seed_value += 1
	API.JSM.rnd_seed(seed_value)
	c.B = rules.B
	c.finishBattle("retreat")
	_check(c.RUN["fallen"].size() == 1, "settlement puts a captain who did not escape on the fallen roll")
	if c.RUN["fallen"].size() != 1:
		return
	var row: Dictionary = c.RUN["fallen"][0]
	var ui := CampaignUI.new()
	ui.C = c
	var loss: Dictionary = row.get("loss", {})
	var recorded: Dictionary = rules.B["lost_ship_records"][0]
	recorded["weapon_name"] = "Mutation after settlement"
	_check(loss.get("weapon_name") == gun["n"], "the fallen roll retains the killmail by value")
	_check(ui._fallen_loss_line(row).contains(str(killer["name"]) + " with " + str(gun["n"])),
		"the fallen roll names battle, round, killer and weapon from that killmail")
	_check(ui._fallen_loss_line({"sector": 2}) == "Lost in sector II", "older fallen entries still have their sector line")
	ui.free()
