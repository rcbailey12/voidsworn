extends SceneTree
const BattleAPI = preload("res://rules/battle_api.gd")
func _init() -> void:
	for sc in ["s1", "s13", "s37", "s49", "t_heg_secondwave", "t_ecl_outshadow"]:
		var api = BattleAPI.new()
		api.load_rules()
		api.new_battle_scenario(sc)
		var line := "%s:" % sc
		for k in 4:
			var t0 = Time.get_ticks_usec()
			api.threat_both()
			line += " threat %.0f ms" % ((Time.get_ticks_usec() - t0) / 1000.0)
			var moved := false
			for u in api.view()["units"]:
				if u["side"] == "player" and not u["dead"] and not u.get("activated", false) and not u.get("squadron", false):
					var r = api.reach(str(u["id"]))
					if r.size() > 1:
						moved = api.move(str(u["id"]), r[r.size() / 2])
						if moved: break
			line += " (moved %s, v%d)" % [moved, api.version]
		print(line)
	quit()
