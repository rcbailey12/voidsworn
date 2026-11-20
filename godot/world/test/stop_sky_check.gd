extends SceneTree
# Issue 1272: skies react to rival, boss and wreck-field (salvage) stops, and a campaign shows more backdrop vistas.
#   godot --headless --path godot --script res://world/test/stop_sky_check.gd
# Walks 40 seeded campaigns through all three sectors with the real campaign generator (genSector, pickRegion, rollBiome,
# regionMap, nodeFaction), builds each fight stop's backdrop setting exactly as main.gd and world.gd do, and checks:
# the distinct vistas (planet look, sky, planet framing) per campaign go up from today's (one setting per sector); each mood
# changes the sky measurably from a plain stop of the same sector; the sector's anchor planet never changes between stops;
# a stop with no mood is today's sector setting plus the default framing; the stop is stable across a save (3 vs 3.0).
const CampaignScript = preload("res://campaign/campaign.gd")
const JSM = preload("res://rules/jsm.gd")
const WORLD = preload("res://world/world.gd")
const SKY = preload("res://world/world_sky.gd")
const MAIN = preload("res://main/main.gd")

var fails := 0

class FakeRules:
	var B := {}

class FakeApi:
	var R := FakeRules.new()


func check(ok: bool, what: String) -> void:
	if not ok:
		fails += 1
		printerr("FAIL: " + what)


func _sky_key(s: Dictionary) -> String:
	var c1: Vector3 = s["c1"]
	var c3: Vector3 = s["c3"]
	return "%s|%.3f,%.3f,%.3f|%.3f,%.3f,%.3f|%.3f|%.3f|%.3f" % [s["region"], c1.x, c1.y, c1.z, c3.x, c3.y, c3.z, s["neb"], s["dust"], s["band"]]


func _sky_gap(a: Dictionary, b: Dictionary) -> float:
	return ((a["c1"] as Vector3) - (b["c1"] as Vector3)).length() + absf(float(a["neb"]) - float(b["neb"])) \
		+ absf(float(a["dust"]) - float(b["dust"])) + absf(float(a["band"]) - float(b["band"]))


func _initialize() -> void:
	var C = CampaignScript.new()
	var err: String = C.load_tables()
	if err != "":
		printerr(err)
		quit(1)
		return
	C.fixed_clock = true
	var today_total := 0
	var new_total := 0
	var looks := {}
	var moods := {"plain": 0, "rival": 0, "boss": 0, "salvage": 0}
	var runs := 40
	var min_gap := {}
	for seed in range(1, runs + 1):
		JSM.rnd_seed(seed)
		C.META = C.defaultMeta()
		C.newRun("vex", "voidsworn")
		var today := {}
		var vistas := {}
		for sector in [1, 2, 3]:
			C.RUN["sector"] = float(sector)
			C.RUN["map"] = C.genSector(sector)
			var m: Dictionary = C.RUN["map"]
			m["region"] = C.pickRegion(m["fac"])
			m["biome"] = C.rollBiome(m["region"])
			var base: Dictionary = SKY.setting(m["biome"], str(m["fac"]), "open", false, 0)
			today[str(base["planet_i"]) + "|" + _sky_key(base)] = true
			var sector_s: Dictionary = WORLD.sector_setting(C.RUN)
			looks[int(sector_s["planet_i"])] = true
			var plain_sky := {}
			var by_mood := {}
			for col in m["cols"]:
				for n in col:
					if not (n["type"] in ["battle", "elite", "boss"]): continue
					var fac: String = str(m["fac"]) if n["type"] == "boss" else str(C.nodeFaction(n))
					var map_name: String = str(C.regionMap(m["region"], n["col"], m["cols"].size()))
					var api := FakeApi.new()
					api.R.B = {"cfg": {"kind": n["type"], "fac": fac, "node": n["id"]}}
					var stop: Dictionary = MAIN.stop_of(api, C.RUN)
					var s: Dictionary = SKY.stop_mood(sector_s, stop, map_name)
					check(int(s["planet_i"]) == int(sector_s["planet_i"]), "seed %d sector %d: the anchor planet stays at every stop" % [seed, sector])
					moods[s["mood"]] += 1
					vistas["%d|%s|%.2f|%.2f" % [int(s["planet_i"]), _sky_key(s), float(s["frame_scale"]), float(s["frame_az"])]] = true
					if s["mood"] == "plain": plain_sky = s
					else: by_mood[s["mood"]] = s
			for mood in by_mood:
				if plain_sky.is_empty(): break
				var gap := _sky_gap(by_mood[mood], plain_sky)
				check(gap > 0.05, "seed %d sector %d: a %s stop changes the sky measurably (gap %.3f)" % [seed, sector, mood, gap])
				min_gap[mood] = minf(float(min_gap.get(mood, 99.0)), gap)
				if mood == "boss":
					check(float(by_mood[mood]["frame_scale"]) > 1.4, "boss stops bring the planet nearer")
		today_total += today.size()
		new_total += vistas.size()
	# the empty stop (quick battles, no campaign) is today's sector setting with the default framing
	var any_s: Dictionary = WORLD.sector_setting(C.RUN)
	var plain_s: Dictionary = SKY.stop_mood(any_s, {}, "open")
	check(_sky_key(plain_s) == _sky_key(any_s) and float(plain_s["frame_scale"]) == 1.0 and float(plain_s["frame_az"]) == 0.0, "no stop, no change")
	# a saved run reads ids back as floats: the stop, and so its framing, must not move
	var a1 := FakeApi.new()
	a1.R.B = {"cfg": {"kind": "battle", "fac": "hegemony", "node": 3}}
	var a2 := FakeApi.new()
	a2.R.B = {"cfg": {"kind": "battle", "fac": "hegemony", "node": 3.0}}
	check(MAIN.stop_of(a1, {"sector": 2, "map": {"fac": "hegemony"}}) == MAIN.stop_of(a2, {"sector": 2.0, "map": {"fac": "hegemony"}}), "stop survives save and load")
	print("STOP_SKY campaigns %d | backdrop vistas per campaign: today %.1f, now %.1f | planet looks seen %d of %d | stops plain %d rival %d boss %d salvage %d" % [
		runs, float(today_total) / runs, float(new_total) / runs, looks.size(), SKY.PLANETS.size() + SKY.PLANETS_ALT.size(),
		moods["plain"], moods["rival"], moods["boss"], moods["salvage"]])
	print("STOP_SKY smallest sky change from a plain stop of the same sector: ", min_gap)
	check(float(new_total) / runs >= 2.0 * float(today_total) / runs, "a campaign shows at least twice today's vistas")
	check(looks.size() > SKY.PLANETS.size(), "campaigns show more planet looks than the eight base ones")
	for k in ["rival", "boss", "salvage"]:
		check(moods[k] > 0, "the walk meets %s stops" % k)
	if fails == 0: print("stop sky check: ok")
	quit(1 if fails > 0 else 0)
