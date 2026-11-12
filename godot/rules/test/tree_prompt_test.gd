# Issue 529: the tree prompts through the rules API the battle screen uses (the Godot twin of tree_last_rows_test.js).
#   godot --headless --path godot --script res://rules/test/tree_prompt_test.gd
# A "you may" skill asks yes or no when the Command is given (Vex's Debt Comes Due): yes delays the volley, no fires it now,
# the prompt sits in the rules state (view().ask) until answered and survives a JSON round trip (a saved battle keeps it).
# The Chorus role prompt asks each ship once at battle start; the change-role prompt works once per ship.
extends SceneTree
@warning_ignore_start("inference_on_variant", "untyped_declaration", "unsafe_property_access", "unsafe_method_access", "unsafe_cast", "unsafe_call_argument", "return_value_discarded")
const API = preload("res://rules/battle_api.gd")
var fails := 0


func ok(cond: bool, msg: String) -> void:
	print(("PASS " if cond else "FAIL ") + msg)
	if not cond: fails += 1


func battle(name: String):
	var api = API.new(); var err = api.load_rules()
	if err != "": printerr(err); quit(1); return null
	api.hard_stop = true
	api.new_battle_scenario(name)
	return api


func pending_debt(api) -> bool:
	for p in api.R.B.get("treePending", []):
		if p.get("k") == "debtDue": return true
	return false


func _init() -> void:
	# Debt Comes Due: the prompt, then each answer
	for ans in ["yes", "no"]:
		var api = battle("t7a_debtdue")
		var r = api.command_or_ask()
		var a = api.ask()
		ok(r == "ask" and a.get("kind") == "may" and a.get("key") == "vex:A:2:1" and a.get("opts", []).size() == 2, "Debt Comes Due opens a yes or no prompt at the Command (" + ans + ")")
		ok(api.view().get("ask") is Dictionary and not api.R.jt(api.R.B.get("cmdUsed")), "the open prompt shows in view() and the Command waits for it")
		var copy = JSON.parse_string(JSON.stringify(a))
		ok(copy is Dictionary and str(copy.get("key")) == "vex:A:2:1" and (copy.get("opts") as Array).size() == 2, "the open prompt is plain data, so a saved battle keeps it")
		ok(api.answer(ans), "the answer is taken")
		ok(api.ask().is_empty() and api.R.jt(api.R.B.get("cmdUsed")), "after the answer the prompt closes and the Command is given")
		ok(pending_debt(api) == (ans == "yes"), "answered " + ans + ": the volley is " + ("delayed to next round" if ans == "yes" else "fired now, nothing held"))
		ok(api.halted == "", "no rules error (" + ans + ")")
	# the bot path never asks
	var bot = battle("t7a_debtdue")
	ok(bot.command() and bot.ask().is_empty() and pending_debt(bot), "command() (the bot) takes the old default without a prompt")
	# Chorus roles: the battle-start prompt, one ship at a time, then the change-role prompt once per ship
	var api = battle("t529_roles_strike")
	var ships := []
	for u in api.view().units:
		if u.side == "player" and not u.squadron: ships.append(u.id)
	ok(api.roles_open() and api.ask().get("kind") == "role" and api.ask().get("id") == ships[0] and api.ask().get("opts", []).size() == 3, "the role prompt opens for the first ship with three choices")
	ok(api.answer("screen") and api.ask().get("id") == ships[1], "answering moves the prompt to the next ship")
	ok(api.answer("mend") and api.ask().is_empty(), "the prompt closes once every ship has a role")
	ok(api.role_of(ships[0]) == "screen" and api.role_of(ships[1]) == "mend", "the answers set the roles")
	ok(not api.roles_open(), "each ship is asked only once")
	ok(api.can_change_role(ships[0]) and api.change_role(ships[0]) and api.ask().get("kind") == "rolechange" and api.ask().get("opts", []).size() == 3, "the change prompt offers the two other roles or keep")
	ok(api.answer("strike") and api.role_of(ships[0]) == "strike" and not api.can_change_role(ships[0]), "the role changes once and cannot change again")
	var vu = null
	for u in api.view().units:
		if u.id == ships[1]: vu = u
	ok(vu != null and vu.get("role") == "mend" and vu.get("canRole") == true, "view() shows each ship's role and whether it may still change")
	ok(api.halted == "", "no rules error (roles)")
	print(("PASS" if fails == 0 else "FAIL") + ": tree prompts through the rules API (" + str(fails) + " failed)")
	quit(0 if fails == 0 else 1)
