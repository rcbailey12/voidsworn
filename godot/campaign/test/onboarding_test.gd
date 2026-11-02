extends SceneTree
const Teaching = preload("res://ui/campaign/campaign_tips.gd")
const Battle = preload("res://scenes/battle/battle.gd")
const Campaign = preload("res://campaign/campaign.gd")
const API = preload("res://rules/battle_api.gd")
var fails := 0

class FakeHUD extends CanvasLayer:
	var tipcard: PanelContainer
	var last := ""
	func show_tipcard(id: String, _title: String, _body: String) -> void:
		last = id
		tipcard = PanelContainer.new()
	func hide_tipcard() -> void:
		if tipcard != null: tipcard.free()
		tipcard = null

class FakeAPI extends RefCounted:
	var version := 1
	var phase := "player"
	var n := 1
	var target := false
	var close := false
	var command := false
	var arrived := false
	var event = null
	func teaching_info() -> Dictionary: return {"battle": n, "event": event, "arrived": arrived}
	func can_command() -> bool: return command
	func ui_info(_id: String) -> Dictionary:
		return {"weapons": [{"targets": [{"can": target}]}], "board": [1] if close else [], "ram": null}

func check(ok: bool, label: String) -> void:
	if not ok: fails += 1; printerr("FAIL: " + label)
	else: print("PASS: " + label)

func _init() -> void:
	_run.call_deferred()

func _run() -> void:
	# This test must never touch the player's profile.
	var data := ProjectSettings.globalize_path("user://").replace("\\", "/")
	if not data.begins_with(ProjectSettings.globalize_path("res://..").simplify_path().replace("\\", "/").trim_suffix("/") + "/.onboarding_checks/"):
		printerr("Refusing to test outside the workspace: " + data); quit(2); return
	Teaching.save_opts({"speed": 0.45, "tipsOff": false, "extra": "preserved", "tips": {"threat": true}})
	Teaching.set_off(true)
	var o := Teaching.load_opts()
	check(o.speed == 0.45 and o.extra == "preserved" and o.tips.has("threat") and o.tips.has("start") and o.tips.has("turns"), "shared options preserve history, speed and unrelated fields")
	Teaching.set_off(false)
	var b = Battle.new()
	b.hud = FakeHUD.new()
	b.api = FakeAPI.new()
	b.user_speed = 0.45; Teaching.set_off(true); b._sync_teaching_switch()
	check(b.tips_off and b.user_speed == 0.45, "shared switch does not alter the battle speed")
	Teaching.set_off(false); b._sync_teaching_switch()
	b.args["no-tips"] = true; b._sync_teaching_switch()
	check(b.tips_off, "capture and test no-tips override still wins")
	b.args.erase("no-tips"); b._sync_teaching_switch()
	b.V = {"round": 1, "obj": {"type": "rout"}, "units": [{"id": "p1", "side": "player", "dead": false, "squadron": false, "activated": false, "active": false}]}
	b.VU = {"p1": b.V.units[0]}
	b.sel = "p1"
	b.tips = {"start": true, "turns": true}
	b.api.target = true; b._tutorial()
	check(b.tip_pending == "" and b.hud.tipcard == null, "deployment targets cannot pre-empt the first hand-over card")
	b.api.target = false; b.api.version += 1
	b.tip_handed = true
	b.tip_slot = "1:player:p1"
	b._tutorial()
	check(b.hud.last == "select", "first hand-over shows Moving and facing")
	b._tip_dismiss("got_it")
	check(not b.tips.has("select"), "dismissal alone does not retire an action card")
	b.api.target = true; b.api.version += 1
	b._tutorial()
	check(b.hud.tipcard == null and b.tip_pending == "target", "same activation holds just one pending card")
	b.tip_slot = "1:player:p2"
	b._tutorial()
	check(b.hud.last == "target", "pending target card shows on next activation")
	b._tip_completed({"t": "move", "unit": "p1"})
	check(b.tips.has("select"), "completed movement retires select after dismissal")
	b._tip_completed({"t": "fire", "unit": "p1"})
	check(b.tips.has("target") and b.tip_shot, "resolved shot retires target and earns Taking turns")
	b._tip_dismiss("got_it")
	b.tip_slot = "1:player:p1"; b._tutorial()
	check(b.hud.tipcard == null, "returning to an earlier activation cannot show another card")
	b.tip_slot = "1:player:p3"; b._tutorial()
	check(b.hud.last == "fired", "Taking turns follows the resolved shot")
	b._tip_dismiss("got_it"); b._tip_retire("fired", "end_ship")
	b.tip_enemy_done = true; b.tip_slot = "1:player:p4"; b._tutorial()
	check(b.hud.last == "move", "Shields and hull follows completed enemy activation")
	b._tip_dismiss("got_it")
	b.V.round = 2; b.tip_slot = "2:player:p1"; b._tutorial()
	check(b.hud.last == "threat", "round two earns Threat map")
	b._tip_dismiss("got_it")
	b.api.close = true; b.api.command = true; b.api.version += 1
	b.tip_slot = "2:player:p2"; b._tutorial()
	check(b.hud.tipcard == null, "battle one suppresses close and Command")
	b.api.n = 2; b.api.event = {"k": "reinf_enemy", "r": 3}; b._tutorial()
	check(b.hud.last == "reinforce_warn", "warning appears one round before scheduled arrival")
	b._tip_dismiss("got_it"); b.tip_slot = "2:player:p3"; b._tutorial()
	check(b.hud.last == "close", "battle two teaches available close action")
	b._tip_dismiss("got_it"); b._tip_completed({"t": "board", "unit": "p1"})
	check(b.tips.has("close"), "resolved boarding retires Close action")
	b.api.n = 3; b.tip_slot = "2:player:p4"; b._tutorial()
	check(b.hud.last == "resolve", "battle three permits ready Command")
	b._tip_dismiss("got_it"); b.V.obj.type = "hold"; b.tip_slot = "2:player:p5"; b._tutorial()
	check(b.hud.last == "objective", "non-rout battle teaches Objectives")
	b._tip_dismiss("got_it")
	var log = b.plog.summary("win", 2, {})
	check(log.tips.any(func(e): return e.k == "show") and log.tips.any(func(e): return e.k == "dismiss") and log.tips.any(func(e): return e.k == "retire"), "F1 play log contains shows, dismissals and retirements")
	b.hud.free(); b.free()
	var c = Campaign.new(); check(c.load_tables() == "", "campaign tables load")
	# Ordinary callers, bots and parity never opt in, even on a fresh profile.
	c.META = c.defaultMeta()
	c.newRun("vex", "voidsworn")
	check(not c.RUN.has("teachingGate"), "default campaign leaves teaching gate off")
	var normal := {"node": "a", "kind": "battle", "fac": "chorus"}
	check(c.teachingBattle(normal) == normal and not c.RUN.has("teachingBattles"), "gate off leaves config and run history unchanged")
	for runs in [0, 1, 2, 3]:
		for tips_on in [false, true]:
			c.RUN = null; c.SAVED_RUN = null; c.META = c.defaultMeta(); c.META.stats.runs = runs
			c.set_teaching_tips(tips_on); c.newRun("vex", "voidsworn")
			check((c.RUN.get("teachingGate") == true) == (tips_on and runs < 2), "gate before launch: tips %s, prior runs %d" % [tips_on, runs])
			c.set_teaching_tips(tips_on)
			check((c.RUN.get("teachingGate") == true) == (tips_on and runs < 2), "active run excluded from limit: tips %s, prior runs %d" % [tips_on, runs])
	c.RUN = null; c.SAVED_RUN = {"over": false}; c.META = c.defaultMeta(); c.META.stats.runs = 2
	c.set_teaching_tips(true)
	check(c.META.stats.finishedRuns == 1, "old profile migration excludes its saved unfinished run")
	c.newRun("vex", "voidsworn")
	check(c.RUN.get("teachingGate") == true and c.META.stats.finishedRuns == 1, "launching or replacing a run does not count as finishing it")
	var generated_shape = c.RUN.map.cols[0][0].teachingShape
	c.set_teaching_tips(false)
	check(c.RUN.map.cols[0][0].shape == generated_shape and not c.RUN.map.cols[0][0].has("teachingShape"), "tips off restores the original map shape without rerolling")
	c.set_teaching_tips(true)
	c.endRun(false)
	check(c.META.stats.finishedRuns == 2, "a loss counts as a finished run")
	c.newRun("vex", "voidsworn")
	check(c.RUN.get("teachingGate") != true, "two finished runs disable teaching despite more launches")
	c.RUN = {"sector": 1, "map": {"fac": "chorus"}, "teachingGate": true}
	check(c.nodeFaction({"id": "a", "type": "battle"}) == "hegemony", "map preview names the first teaching enemy")
	var first = c.teachingBattle({"node": "a", "kind": "battle", "fac": "chorus"})
	var retry = c.teachingBattle({"node": "a", "kind": "battle", "fac": "chorus"})
	var second = c.teachingBattle({"node": "b", "kind": "battle", "fac": "chorus"})
	check(c.nodeFaction({"id": "b", "type": "battle"}) == "corsair", "map preview names the second teaching enemy")
	check(first.fac == "hegemony" and first.edgeFeature and retry.teachingBattle == 1 and second.fac == "corsair", "campaign pins first two unique fights and preserves reload identity")
	check(c.rollBattleEvent(first, "reinf_ally") == null and c.rollBattleEvent(second, "flare").k == "reinf_enemy", "first fight suppresses arrivals, second forces enemy arrival")
	check(not c.teachingBattle({"node": "c", "kind": "elite", "fac": "chorus"}).has("teachingBattle"), "later fights keep their generated faction")
	var boss = c.teachingBattle({"node": "boss", "kind": "boss", "fac": "chorus"})
	c.RUN["sector"] = 2
	var later = c.teachingBattle({"node": "a", "kind": "battle", "fac": "chorus"})
	check(boss.runBattle == 4 and later.runBattle == 5 and later.fac == "chorus", "battle count advances through bosses and sectors without re-pinning enemies")
	c.SAVED_RUN = {"pos": "before", "curNode": null}
	c.RUN["pos"] = "battle"
	c.saveTeachingHistory()
	check(c.SAVED_RUN.pos == "before" and c.SAVED_RUN.curNode == null and c.SAVED_RUN.teachingBattles.size() == 5, "saving teaching history preserves the pre-battle reload checkpoint")
	var t = Teaching.new(); root.add_child(t); t.bind(c)
	# Start with clean teaching history, retaining the same isolated profile.
	var f := FileAccess.open(Teaching.OPTS, FileAccess.WRITE); f.store_string('{"speed":0.45,"tipsOff":false,"tips":{}}'); f.close()
	t.open_screen("map|1", ["c_map", "c_clock"])
	check(t.current == "c_map", "first map opens one card")
	t._action("tip_ok", "c_map")
	check(t.current == "c_clock", "dismissing map permits the clock exception")
	t._action("tip_ok", "c_clock"); t.open_screen("map|1", ["c_reward"])
	check(t.current == "", "ordinary cards cannot stack on one screen opening")
	t.open_screen("reward|1", ["c_reward"])
	check(t.current == "c_reward", "reward screen delivers its own card")
	t._action("tip_off", "")
	check(Teaching.is_off() and t.current == "", "card off link silences all teaching cards")
	t.open_screen("shipyard|1", ["c_shipyard"])
	check(t.current == "", "shared off flag suppresses campaign cards")
	t.toggle(); t.open_screen("shipyard|2", ["c_shipyard"])
	check(t.current == "c_shipyard", "campaign map switch re-enables cards")
	t._action("tip_ok", "c_shipyard")
	check(c.tel_log.any(func(e): return e.ev == "teaching_tip" and e.k == "dismiss"), "campaign card events reach existing telemetry")
	t.queue_free(); await process_frame
	print("ONBOARDING " + ("PASS" if fails == 0 else "FAIL: %d" % fails))
	quit(0 if fails == 0 else 1)
