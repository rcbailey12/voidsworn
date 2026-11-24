extends RefCounted
# Issue 1582 (movement stage 2, Ryan approved Nov 21 2026): class altitude bands. A look only: the rules, arcs, hexes and
# clicks stay 2D on the battle plane (y = 0). Capitals and stations hold the plane; cruisers and destroyers sit a little
# above or below it; frigates and escorts screen a little further off it; strike craft patrol well above the ships.
# Which side and how far comes from the unit id, so a ship keeps its height for the whole battle and neighbours differ.
# Every number here is a tuning value chosen by eye at camera 170 (RULEBOOK 7.7).

# world units at full band (hex corner radius is 10; a frigate is about 10 long, a cruiser about 23)
const CAPITAL := 0.0
const LINE := [2.2, 3.4]       # cruisers, destroyers, transports, carriers: this far off the plane
const ESCORT := [3.4, 4.8]     # frigates and escorts
const WING := 10.0             # strike craft patrol this high above the plane
const BELOW_K := 0.7           # a ship below the plane sits a little closer to it (move overlays tint the plane)

const PLANE := ["Dreadnought", "Battleship", "Super-dreadnought", "Battle-barge", "Bio-titan", "Ark", "Tomb-ark",
	"Station"]
const LINE_CLS := ["Cruiser", "Destroyer", "Transport", "Carrier"]


# A seed in 0..1 from the unit id, stable across runs. md5, not String.hash: ids like p1, p2, p3 hash to neighbouring
# numbers and would all get the same height.
static func seed_of(id: String) -> float:
	return float(id.md5_text().substr(0, 7).hex_to_int()) / float(0x10000000)


# The band height for a battle unit view (the rules view's dictionary). Positive is up.
static func height(u: Dictionary) -> float:
	if bool(u.get("squadron", false)) or str(u.get("cls", "")) == "Squadron":
		return WING
	var cls := str(u.get("cls", "Frigate"))
	if cls in PLANE:
		return CAPITAL
	var s := seed_of(str(u.get("id", "")))
	var band: Array = LINE if cls in LINE_CLS else ESCORT
	var up := s < 0.6                 # a little more often above: the plane's overlays sit over ships below it
	var f := fposmod(s * 7.31, 1.0)    # how far inside the band, independent of the side
	var y := lerpf(float(band[0]), float(band[1]), f)
	return y if up else -y * BELOW_K
