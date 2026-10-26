extends RefCounted
# What the renderer needs to know about the game's hulls, taken from ships3d.js: which mesh each faction and class uses
# (AI_HULLS), how long each class is on the board (CLS_LEN), the faction colours (FAC3D) and the hull finish the A2 test
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
# the six flagships have max-detail 8K versions (enginetest assets/hi); the barge is a shell plus a kit
const HI_FILES := {"V1b_r_23": ["V1b_r_23.glb"], "H4_11": ["H4_11.glb"], "C19_51": ["C19_51_shell.glb", "C19_51_kit.glb"],
	"B16_23": ["B16_23.glb"], "I8_37": ["I8_37.glb"], "D22_23": ["D22_23.glb"]}

const CLS_LEN := {"Squadron": 1.6, "Transport": 11.0, "Frigate": 6.5, "Destroyer": 9.5, "Cruiser": 14.5, "Carrier": 16.5, "Battleship": 21.0,
	"Dreadnought": 27.0, "Super-dreadnought": 31.0, "Battle-barge": 26.0, "Bio-titan": 28.0, "Ark": 26.0, "Tomb-ark": 28.0}

# hull base colour (sRGB hex), metal, roughness per faction (the A2 test's finish)
const FINISH := {
	"voidsworn": ["#4a4440", 0.3, 0.55], "hegemony": ["#c4ccd5", 0.4, 0.48], "corsair": ["#6a2c22", 0.35, 0.62],
	"chorus": ["#57364c", 0.05, 0.38], "ithar": ["#e4ebe7", 0.25, 0.42], "deathless": ["#2c3431", 0.55, 0.5],
}

# FAC3D: windows, engines, weapon bolts and beams, shields (linear RGB)
const FAC3D := {
	"voidsworn": {"win": Color(1, .42, .12), "eng": Color(1, .5, .16), "bolt": Color(1, .52, .18), "beam": Color(1, .45, .15), "shield": Color(1, .46, .16)},
	"hegemony": {"win": Color(.78, .9, 1), "eng": Color(.45, .72, 1), "bolt": Color(.5, .78, 1), "beam": Color(.55, .82, 1), "shield": Color(.38, .68, 1)},
	"corsair": {"win": Color(1, .4, .2), "eng": Color(1, .38, .16), "bolt": Color(.95, .2, .1), "beam": Color(.95, .22, .1), "shield": Color(.85, .16, .1)},
	"chorus": {"win": Color(.85, .92, .25), "eng": Color(.8, .9, .28), "bolt": Color(.82, .92, .22), "beam": Color(.85, .9, .3), "shield": Color(.9, .82, .22)},
	"ithar": {"win": Color(.6, 1, .82), "eng": Color(.62, 1, .84), "bolt": Color(.7, 1, .86), "beam": Color(.75, 1, .88), "shield": Color(.72, 1, .86)},
	"deathless": {"win": Color(.15, 1, .35), "eng": Color(.15, 1, .35), "bolt": Color(.2, 1, .38), "beam": Color(.2, 1, .38), "shield": Color(.18, 1, .36)},
}

# rock libraries (scene3d.js ROCK_SET, ROCK_TINT): biome rock kind -> mesh set, dark albedo per set
const ROCK_SET := {"stone": "RST", "carbon": "RCA", "iron": "RCA", "crystal": "RCR", "ice": "RIC"}
const ROCK_TINT := {"RST": Color(.34, .31, .28), "RCA": Color(.27, .255, .245), "RCR": Color(.25, .27, .28), "RIC": Color(.34, .4, .47)}


static func code_for(fac: String, cls: String) -> String:
	return AI_HULLS.get(fac + "|" + cls, "")


static func srgb(hex: String) -> Color:
	return Color(hex).srgb_to_linear()
