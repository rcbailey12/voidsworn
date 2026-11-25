extends SceneTree
const GUARD = preload("res://tools/ci/check_guard.gd")
# Issue 710 (R247, docs/playbooks/scale.md): one scale table for the board's ships, squadrons, station, terrain and
# explosions, and the campaign sector map's stops. This check reads the live sizes from the code that draws them (never a
# copy of the table), works out each object's span in world units against HEX_S = 10, and fails when an object leaves its
# target range. It is the drift guard for issues 368 (terrain), 369 (planet and rocks) and 373 (station).
#
# Live sources, by object:
#   ships       render/hull_table.gd CLS_LEN, SHIP_K, SQUADRON_K; the glb manifest's length_world; ship_view's draw rule
#   station     render/board.gd STATION_* (the board), and ui/campaign/map3d.gd SHIPYARD_LEN (the map)
#   terrain     world/world_living.gd GAS_*, DEBRIS_ROCK_*; world/world.gd BLOCKER_*; world/rocks/rocks.json ext
#   planet      render/board.gd PLANET_R_DEFAULT, PLANET_EDGE_K and the planetEdge rule
#   wrecks      render/board.gd HULK_SCALE
#   explosions  fx/fx_death.gd CORE_FLASH_PX and STAGING_UNITS_PER_PIXEL; fx/fx_ship.gd the class bands and scale_k;
#               fx/fx_weapons.gd BIG_HIT_RING, VIS_K_HIT
#   map         ui/campaign/map3d.gd RING_R, TOKEN_*, REGION_NEBULA_SPREAD; ui/campaign/map3d_system.gd CLOUD_PUFF_MAX
#
#   godot --headless --path godot --script res://render/test/scale_check.gd
# Prints one PASS, FAIL or KNOWN line per object and exits 1 when any object outside the KNOWN list is out of range, or a KNOWN row passes.

const HT := preload("res://render/hull_table.gd")
const BRD := preload("res://render/board.gd")
const WL := preload("res://world/world_living.gd")
const WD := preload("res://world/world.gd")
const WR := preload("res://world/world_rocks.gd")
const FXD := preload("res://fx/fx_death.gd")
const FXS := preload("res://fx/fx_ship.gd")
const FXW := preload("res://fx/fx_weapons.gd")
const M3D := preload("res://ui/campaign/map3d.gd")
const M3S := preload("res://ui/campaign/map3d_system.gd")

const MANIFEST := "res://assets/ships/manifest.json"
const CLASSES := ["Transport", "Frigate", "Destroyer", "Cruiser", "Carrier", "Battleship", "Dreadnought",
	"Super-dreadnought", "Battle-barge", "Bio-titan", "Ark", "Tomb-ark"]
const LADDER := ["Frigate", "Destroyer", "Cruiser", "Battleship", "Dreadnought", "Super-dreadnought"]

var fails := 0
var checks := 0
var known_seen := 0
var hex := 0.0

# Rows that fail today on purpose, each with the job that must clear it (Board, Nov 15: merged as known rows so the check
# guards everything else now). A known row that fails prints KNOWN and does not fail the check; a known row that PASSES
# fails the check until its line here is deleted, so the job that fixes it also retires it (the same ratchet as
# contrib/opus/tools/checks_baseline.json). Nothing else may be added here without the Board's review.
const KNOWN := {
	"station (5+ hexes)": "issue 373 (station T2, PR 700)",
	"map station node": "issue 373 (the station on the sector map, R249)",
	"asteroid field biggest rock": "issue 369 (board planet and rocks)",
}


func _init() -> void:
	GUARD.arm(self, "scale_check")  # issue 632: a SCRIPT ERROR or a stuck run ends the check, never waits
	process_frame.connect(_run, CONNECT_ONE_SHOT)


func row(name: String, today: float, lo: float, hi: float, reason: String) -> void:
	checks += 1
	var ok := today >= lo - 0.001 and today <= hi + 0.001
	var verdict := "PASS" if ok else "FAIL"
	if KNOWN.has(name):
		known_seen += 1
		if ok:
			fails += 1
			verdict = "FAIL (known row now passes: delete its KNOWN line, %s)" % KNOWN[name]
		else:
			verdict = "KNOWN (%s clears it)" % KNOWN[name]
	elif not ok:
		fails += 1
	print("[scale] %-34s today %7.2f  target %7.2f .. %7.2f  %s  (%s)" % [name, today, lo, hi, verdict, reason])


func _run() -> void:
	hex = float(HT.HEX_S)
	var across_flat := hex * sqrt(3.0)
	var across_corner := 2.0 * hex

	# 1. The ship classes, as the code draws them, and the glb manifest they are built from.
	var man: Dictionary = {}
	if FileAccess.file_exists(MANIFEST):
		var parsed = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST))
		if parsed is Dictionary:
			man = parsed
	var ships: Dictionary = man.get("ships", {}) if man.has("ships") else {}
	if ships.is_empty():
		_skip("the glb manifest (assets/ships/manifest.json) is missing or empty")

	var drawn := {}
	for c in CLASSES:
		drawn[c] = float(HT.CLS_LEN[c]) * float(HT.SHIP_K)
		var lo := 0.4 * across_corner
		var hi := 5.0 * across_corner
		row("ship %s" % c, float(drawn[c]), lo, hi, "a class length in hexes; capitals overhang their hex")
	for code in HT.HULL_LEN:
		row("ship hull %s" % code, float(HT.HULL_LEN[code]) * float(HT.SHIP_K), 0.4 * across_corner,
			5.0 * across_corner, "approved hull length; its export must match below")

	# Every hull must exist in the manifest at the length ShipView uses, including approved hull overrides.
	var manifest_bad := 0
	for key in HT.AI_HULLS.keys():
		var code := str(HT.AI_HULLS[key])
		var cls := str(key).split("|")[1]
		if not HT.CLS_LEN.has(cls):
			continue  # the station and the beacon size themselves on the board
		if not ships.has(code):
			manifest_bad += 1
			print("[scale] hull %s (%s) is missing from the glb manifest" % [code, key])
			continue
		var lw := float((ships[code] as Dictionary).get("length_world", -1.0))
		var expected := HT.length_for(code, cls)
		if absf(lw - expected) > 0.01:
			manifest_bad += 1
			print("[scale] hull %s says length_world %.2f, the hull table says %s = %.2f" % [code, lw, cls, expected])
	checks += 1
	if manifest_bad == 0:
		print("[scale] %-34s every hull's glb length matches the hull table  PASS" % "hull table vs glbs")
	else:
		fails += 1
		print("[scale] %-34s %d hull(s) differ  FAIL" % ["hull table vs glbs", manifest_bad])

	# the class ladder must read bigger at every step
	var ladder_bad := 0
	for i in range(1, LADDER.size()):
		if float(drawn[LADDER[i]]) <= float(drawn[LADDER[i - 1]]):
			ladder_bad += 1
			print("[scale] %s is not longer than %s" % [LADDER[i], LADDER[i - 1]])
	checks += 1
	if ladder_bad == 0:
		print("[scale] %-34s frigate < destroyer < cruiser < battleship < dreadnought < super-dreadnought  PASS" % "ship ladder")
	else:
		fails += 1
		print("[scale] %-34s %d step(s) out of order  FAIL" % ["ship ladder", ladder_bad])

	# fighters and bombers: each craft is a Squadron's length times SQUADRON_K
	var craft := float(HT.CLS_LEN["Squadron"]) * float(HT.SHIP_K) * float(HT.SQUADRON_K)
	row("fighter / bomber", craft, 2.0, 6.0, "tiny beside a frigate (%.2f)" % (0.5 * float(drawn["Frigate"])))
	row("fighter / bomber vs frigate", craft / float(drawn["Frigate"]), 0.0, 0.5, "a wing craft is under half a frigate's length")

	# 2. The big station: on the board it must dwarf every ship class.
	var station_big := float(BRD.STATION_BIG_LEN)
	var largest_ship := float(drawn["Super-dreadnought"])
	# the one-hex spot is the outpost now, fitted inside its hexes (Ryan, Nov 24 2026, issue 1791; station_size_check)
	row("station (5+ hexes)", station_big, 2.0 * largest_ship, 6.0 * largest_ship, "dwarfs every ship class")

	# 3. Terrain on the board.
	var gas := WL.new()
	var nebula: float = gas.cloud_span()
	gas.free()
	var veil := float(WL.GAS_VEIL_MAX) * float(WL.GAS_CLOUD_SCALE)
	var gas_lo := 1.5 * largest_ship
	var gas_hi := 6.0 * largest_ship
	row("nebula (one hex cloud)", nebula, gas_lo, gas_hi, "much larger than any ship, spilling past its hex")
	row("nebula (tying veil)", veil, across_corner, gas_hi, "the veil still spans more than a hex")
	row("ion storm (one hex cloud)", nebula, gas_lo, gas_hi, "much larger than any ship, spilling past its hex")

	var rock_ext := 0.0
	for r in (WR.lib().get("rocks", []) as Array):
		var ext: Array = (r as Dictionary).get("ext", [])
		for e in ext:
			rock_ext = maxf(rock_ext, float(e))
	if rock_ext <= 0.0:
		rock_ext = 2.0
	var biggest_rock := float(WD.BLOCKER_SCALE_MAX) * rock_ext
	var frigate := float(drawn["Frigate"])
	row("asteroid field biggest rock", biggest_rock, 2.0 * frigate, 8.0 * frigate, "the biggest rock dwarfs a frigate")

	var debris := float(WL.DEBRIS_ROCK_MAX) * rock_ext
	row("debris biggest piece", debris, 1.0, frigate, "debris is smaller than the smallest hull")

	var planet_d := 2.0 * (float(BRD.PLANET_R_DEFAULT) * float(BRD.PLANET_EDGE_K) * hex + hex * 0.5)
	row("board planet (diameter)", planet_d, 4.0 * across_corner, 20.0 * largest_ship, "a world reads bigger than the fleet beside it")

	var wreck := float(BRD.HULK_SCALE)
	var wreck_src := float(drawn["Destroyer"])
	row("wreck (board hulk)", wreck, 0.5 * wreck_src, 1.2 * wreck_src, "a wreck keeps most of the length of the hull it was")

	# 4. Explosions: death core flash and the big torpedo hit, by class.
	for c in CLASSES:
		var L := float(drawn[c])
		var band := "small"
		if c in FXS.DEATH_CAPITAL_CLASSES:
			band = "capital"
		elif c in FXS.DEATH_BIG_CLASSES:
			band = "cruiser"
		elif c == "Destroyer":
			band = "destroyer"   # issue 463: destroyers have their own flash row
		elif L >= 30.0:
			band = "capital"
		elif L >= 18.0:
			band = "cruiser"
		var flash := float(FXD.CORE_FLASH_PX[band]) * float(FXD.STAGING_UNITS_PER_PIXEL)
		row("death core flash %s" % c, flash, 0.3 * L, 3.0 * L, "sized to its ship (%s band)" % band)
		var k := maxf(clampf(L / float(FXS.SCALE_K_DIV), float(FXS.SCALE_K_MIN), float(FXS.SCALE_K_MAX)), float(FXW.VIS_K_HIT))
		var blast := float(FXW.BIG_HIT_RING) * k
		row("big hit blast %s" % c, blast, 0.2 * L, 2.0 * L, "sized to its ship (scale k %.2f)" % k)

	# 5. The campaign sector map: sizes there must agree with each other, not with the board's units.
	var node := float(M3D.RING_R)
	var fleet := float(M3D.TOKEN_FLAGSHIP_LEN)
	var escort := float(M3D.TOKEN_ESCORT_LEN)
	var station_node := float(M3D.SHIPYARD_LEN)
	var region := 2.0 * float(M3D.REGION_NEBULA_SPREAD) + float(M3S.CLOUD_PUFF_MAX) * float(M3D.REGION_NEBULA_SPREAD)
	row("map fleet vs escort", fleet / escort, 1.3, 4.0, "the flagship marker reads bigger than an escort")
	row("map station node", station_node, 1.5 * fleet, 6.0 * fleet, "a station node is larger than the fleet marker")
	row("map nebula region", region, 2.0 * node, 200.0, "a nebula region is larger than a stop's ring")
	row("map nebula vs fleet", region / fleet, 2.0, 40.0, "a nebula region is larger than the fleet marker")

	if known_seen != KNOWN.size():
		fails += 1
		print("[scale] FAIL: %d KNOWN rows name an object this check no longer measures; fix the KNOWN list" % (KNOWN.size() - known_seen))
	print("[scale] %s: %d of %d objects fail outside the KNOWN list, %d KNOWN rows (the sizes in docs/playbooks/scale.md)" % [
		"SCALE_CHECK PASS" if fails == 0 else "SCALE_CHECK FAIL", fails, checks, KNOWN.size()])
	quit(0 if fails == 0 else 1)


func _skip(what: String) -> void:
	checks += 1
	fails += 1
	print("[scale] FAIL: %s; the glb and rock lengths cannot be read" % what)
	quit(1)
