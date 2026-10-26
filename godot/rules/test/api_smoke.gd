# Smoke test for the rules API (battle_api.gd): plays a scenario through the same calls the scene uses and prints the event counts.
#   godot --headless --path godot --script res://rules/test/api_smoke.gd -- [scenario]
extends SceneTree
const API = preload("res://rules/battle_api.gd")
func _init() -> void:
	var a := OS.get_cmdline_user_args(); var name := a[0] if a.size() > 0 else "s1"
	var api = API.new(); var err = api.load_rules()
	if err != "": printerr(err); quit(1); return
	api.new_battle_scenario(name)
	var counts := {}; var guard := 0; var think_max := 0.0
	while api.phase != "over" and guard < 2000:
		guard += 1
		var evs := []
		if api.phase == "player":
			var v = api.view(); var me = null
			for u in v.units:
				if u.side == "player" and not u.dead and not u.activated and not u.squadron: me = u; break
			if me == null: api.end_activation(); continue
			var states = api.reach(me.id)
			if states.size() > 1: api.move(me.id, states[states.size() / 2])
			for w in me.weapons:
				for t in v.units:
					if t.side == "enemy" and not t.dead and api.can_fire(me.id, w.i, t.id):
						api.fire(me.id, w.i, t.id); break
			if api.phase == "player": api.end_activation(me.id)
			evs = api.take_events()
		else:
			var t0 := Time.get_ticks_usec(); evs = api.step(); think_max = max(think_max, (Time.get_ticks_usec() - t0) / 1000.0)
		for e in evs: counts[e.t] = int(counts.get(e.t, 0)) + 1
	var v = api.view()
	print("api smoke ", name, ": ", api.phase, " ", v.over, " after round ", v.round, "; events ", counts, "; worst enemy step ", snappedf(think_max, 0.1), " ms; not ported: ", api.R.not_ported if api.R.not_ported != "" else "none")
	quit(0 if api.R.not_ported == "" else 3)
