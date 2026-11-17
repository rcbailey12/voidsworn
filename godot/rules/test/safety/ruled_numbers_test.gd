# Issue 979: independent expectations tied to FINDINGS, never generated from the oracle.
extends SceneTree

const JSM = preload("res://rules/jsm.gd")
const CheckGuard = preload("res://tools/ci/check_guard.gd")
# Label, exported table path, quoted value. R246's exact values are Board tuning,
# implementing Ryan's model, not numbers Ryan personally set (data.js:67).
const PICKS := [
	["R265 Eclipse flare hull", "HULLS/d_jackal/hp", 100],
	["R265 null lance damage", "W/nlance/dmg", 15],
	["R265 null lance shots", "W/nlance/shots", 3],
	["R265 null lance range", "W/nlance/r", 6],
	["R93 Thale hull bonus", "ADMIRALS/thale/fx/hpPct", 0.10],
	["R93 Thale shield bonus", "ADMIRALS/thale/fx/shPct", 0.10],
	["R93 Ashgrove squadron hull bonus", "ADMIRALS/ashgrove/fx/sqHp", 0.25],
	["R93 shared Iron Command base", "CMD_POW/iron/0", 0.40],
	["R63 Daybreak speed", "HULLS/ascendant/sp", 2],
	["R78 Cinder yards first run", "CINDER_FIRST_RUN", 3],
	["R246 tuning shield pool multiplier", "SHIELD_POOL_MULT", 2],
	["R246 tuning shield regeneration multiplier", "SHIELD_REGEN_MULT", 1.25],
	["R246 tuning shield routing loss", "SHIELD_ROUTE_LOSS", 0.30],
	["R246 tuning shield routing boost", "SHIELD_ROUTE_BOOST", 0.20],
	["R246 tuning maximum shield coverage", "SHIELD_COV_MAX", 0.95],
]

func _init() -> void:
	CheckGuard.arm(self, "ruled_numbers_test", 30.0)
	var doc: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://rules/data/tables.json"))
	var tables: Variant = doc.get("tables") if doc is Dictionary else null
	var bad := 0
	for pick: Array in PICKS:
		var got: Variant = tables
		for key: String in String(pick[1]).split("/"):
			if got is Dictionary:
				got = got.get(key)
			elif got is Array and key.is_valid_int() and int(key) >= 0 and int(key) < got.size():
				got = got[int(key)]
			else:
				got = null
		if got is String and got.begins_with("#d:"):
			got = JSM.from_hex64(got.substr(3))
		if (got is int or got is float) and got == pick[2]:
			print("PASS: ", pick[0], " = ", pick[2], " (", pick[1], ")")
		else:
			printerr("FAIL: ", pick[0], " (", pick[1], "): expected ", pick[2], ", got ", got)
			bad += 1
	print("ruled numbers: ", PICKS.size(), " checks, ", bad, " failures")
	quit(1 if bad else 0)
