extends SceneTree
const BattleAPI = preload("res://rules/battle_api.gd")
func _init() -> void:
	var names = JSON.parse_string(FileAccess.get_file_as_string("res://rules/test/scenarios.json")).keys()
	var worst_t := 0.0; var worst_s := 0.0; var worst_r := 0.0
	var all_t: Array = []; var all_s: Array = []
	for i in range(0, names.size(), 12):
		var sc = names[i]
		var api = BattleAPI.new()
		api.load_rules()
		api.new_battle_scenario(sc)
		var v = api.view()
		var nu = v["units"].size()
		var t0 = Time.get_ticks_usec()
		api.threat_both()
		var tt = (Time.get_ticks_usec() - t0) / 1000.0
		# reach for first player unit
		var tr := 0.0
		for u in v["units"]:
			if u["side"] == "player" and not u["dead"]:
				t0 = Time.get_ticks_usec()
				api.compute_reach(str(u["id"]))
				tr = maxf(tr, (Time.get_ticks_usec() - t0) / 1000.0)
		var ts := 0.0
		# end player turn by stepping: time steps while enemy phase, up to 12
		var n := 0
		if api.has_method("end_turn"):
			api.end_turn()
		while n < 12 and api.phase == "enemy":
			t0 = Time.get_ticks_usec()
			api.step()
			ts = maxf(ts, (Time.get_ticks_usec() - t0) / 1000.0)
			n += 1
		all_t.append(tt); all_s.append(ts)
		print("%s units=%d threat_both=%.0f ms reach_max=%.0f ms step_max=%.0f ms (steps %d phase %s)" % [sc, nu, tt, tr, ts, n, api.phase])
	quit()
