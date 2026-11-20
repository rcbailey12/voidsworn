extends RefCounted
# What the renderer needs to know about the game's hulls, taken from ships3d.js: which mesh each faction and class uses
# (AI_HULLS), how long each class is on the board (CLS_LEN), and the hull finish the A2 test
# used (base colour, metal, roughness per faction). The hex is HEX_S = 10 (corner radius), as in the game.

const HEX_S := 10.0

const AI_HULLS := {
	"hegemony|Frigate": "H7_23", "hegemony|Destroyer": "H8_23", "hegemony|Cruiser": "H9_23", "hegemony|Battleship": "H10_23", "hegemony|Super-dreadnought": "H4_11",
	"voidsworn|Frigate": "V14_23", "voidsworn|Destroyer": "V15_37", "voidsworn|Cruiser": "V16_37", "voidsworn|Battleship": "V17_37", "voidsworn|Dreadnought": "V1b_r_23", "voidsworn|Carrier": "V18_51",
	"corsair|Frigate": "C13s_23", "corsair|Destroyer": "C14s_23", "corsair|Cruiser": "C15s_23", "corsair|Carrier": "C16s_23", "corsair|Battle-barge": "C19_51",
	"chorus|Frigate": "B19_11", "chorus|Destroyer": "B20_11", "chorus|Cruiser": "B21_11", "chorus|Carrier": "B22_11", "chorus|Bio-titan": "B16_23",
	"ithar|Frigate": "I14_23", "ithar|Destroyer": "I11_37", "ithar|Cruiser": "I15_11", "ithar|Carrier": "I16_11", "ithar|Ark": "I8_37",
	"deathless|Frigate": "D9_23", "deathless|Destroyer": "D20_23", "deathless|Cruiser": "D21_23", "deathless|Tomb-ark": "D22_23",
	"craft|fighter": "S1_51", "craft|bomber": "S2_23", "craft|spore": "B23_51",
	"obj|station": "O1_37", "obj|transport": "O2_37", "obj|beacon": "O3_11",
}
# meshed side-on in the source (spike prow along z): +1 turns -z to the bow, -1 turns +z
const AI_HULL_YAW := {"I14_23": 1, "I15_11": -1}
# Height above the board after fitting, in drawn game units. R266: E14's upright ring must clear the board,
# including the 0.25-unit idle bob. A model-space offset would be undone by ShipView's centring.
const HULL_LIFT := {"D20_23": 5.15}
# the six flagships have max-detail 8K versions (enginetest assets/hi); the barge is a shell plus a kit
const HI_FILES := {"V1b_r_23": ["V1b_r_23.glb"], "H4_11": ["H4_11.glb"], "C19_51": ["C19_51_shell.glb", "C19_51_kit.glb"],
	"B16_23": ["B16_23.glb"], "I8_37": ["I8_37.glb"], "D22_23": ["D22_23.glb"]}

# Ships draw SHIP_K times their class length on the board (owner read of the first Godot shots, Oct 26: a frigate should
# fill most of its hex and capitals overhang, as the browser game's framing shows them)
const SHIP_K := 1.6
const SQUADRON_K := 1.5
const CLS_LEN := {"Squadron": 1.6, "Transport": 11.0, "Frigate": 6.5, "Destroyer": 9.5, "Cruiser": 14.5, "Carrier": 16.5, "Battleship": 21.0,
	"Dreadnought": 27.0, "Super-dreadnought": 31.0, "Battle-barge": 26.0, "Bio-titan": 28.0, "Ark": 26.0, "Tomb-ark": 28.0}
# R229: A17's approved claw-tip-to-stern length is 14.6 (its sheet and installed manifest).
# scale_check checks these hull lengths against the exports; other hulls keep their class length.
# The Relay beacon O3_11 is 7.5 long, rail end to rail end (Board lock, Nov 20 2026, issue 1413: designs.md's proposal;
# no class length exists for a placed objective).
const HULL_LEN := {"C15s_23": 14.6, "O3_11": 7.5}


static func length_for(code: String, cls: String) -> float:
	return float(HULL_LEN.get(code, CLS_LEN.get(cls, 10.0)))

# hull base colour (sRGB hex), metal, roughness per faction (the A2 test's finish)
const FINISH := {
	"voidsworn": ["#4a4440", 0.3, 0.55], "hegemony": ["#c4ccd5", 0.4, 0.48], "corsair": ["#6a2c22", 0.35, 0.62],
	"chorus": ["#57364c", 0.05, 0.38], "ithar": ["#e4ebe7", 0.25, 0.42], "deathless": ["#2c3431", 0.55, 0.5],
}

# Faction effect colours (engines, weapons, shields) live in fx/faction_looks.json, read through fx/faction_look.gd
# (issue 1205, R333). The old FAC3D table here overrode it (Eclipse all green) and is gone; a check fails if it returns.

# rock libraries (scene3d.js ROCK_SET, ROCK_TINT): biome rock kind -> mesh set, dark albedo per set
const ROCK_SET := {"stone": "RST", "carbon": "RCA", "iron": "RCA", "crystal": "RCR", "ice": "RIC"}
const ROCK_TINT := {"RST": Color(.34, .31, .28), "RCA": Color(.27, .255, .245), "RCR": Color(.25, .27, .28), "RIC": Color(.34, .4, .47)}


static func code_for(fac: String, cls: String) -> String:
	return AI_HULLS.get(fac + "|" + cls, "")


static func srgb(hex: String) -> Color:
	return Color(hex).srgb_to_linear()
