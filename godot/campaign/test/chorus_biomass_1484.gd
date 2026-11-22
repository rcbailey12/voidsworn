# Issue 1484 (R382, RULEBOOK 11.9): Chorus biomass pays for refits, class refit tracks, protocol rerolls and the Sector 3 late
# market. The Godot twin of contrib/opus/tools/chorus_biomass_1484_tests.js: a Chorus run pays biomass when it covers the price,
# otherwise credits, one purse per purchase; a Crusade run pays credits.
# Headless:
#   godot --headless --path godot --script res://campaign/test/chorus_biomass_1484.gd
extends SceneTree

const Campaign = preload("res://campaign/campaign.gd")
const JSM = preload("res://rules/battle_api.gd").JSM

var C = Campaign.new()
var fails := 0
const KINDS = ["mod", "track", "relic", "cp", "reroll"]

func _initialize() -> void: _run.call_deferred()

func check(ok: bool, what: String) -> void:
	if ok: print("ok    " + what)
	else:
		fails += 1; printerr("FAIL  " + what)

func _start(admiral: String, fac: String, bio: float, cred: float) -> Dictionary:
	JSM.rnd_seed(1484)
	C.META["admirals"][admiral] = true
	C.newRun(admiral, fac)
	var R = C.RUN; R["sector"] = 3.0; R["map"]["cond"] = null; R["bio"] = bio; R["credits"] = cred
	var n = {"id": "y", "col": 0, "type": "shipyard"}
	C.yard_node = n; C.shipyardStock(n)
	return R

# tries every purchase once; returns what each cost and whether it took effect
func _buy_all() -> Dictionary:
	var R = C.RUN; var st = C.yard_node["stock"]; var got = {}
	var m = st["mods"][0]; var mc = C.jsround(float(C.MODULES[m]["cost"]) * C.priceMult()); var inv = R["inventory"].size()
	C.ACT_buyMod("0"); got["mod"] = {"cost": mc, "ok": R["inventory"].size() == inv + 1 and C._has_num(st["sold"], 0)}
	var cls = C.HULLS[R["fleet"][0]["tpl"]]["cls"]; var lv = C.classTrack(cls); var tc = C.classTrackCost(cls)
	C.ACT_buyTrack(cls); got["track"] = {"cost": tc, "ok": C.classTrack(cls) == lv + 1}
	var relic = null
	for o in C.lateShopOffers():
		if o["kind"] == "relic" and not C.jt(o["done"]) and relic == null: relic = o
	if relic != null:
		var rl = R["relics"].size()
		C.ACT_lateBuy(relic["id"]); got["relic"] = {"cost": relic["cost"], "ok": R["relics"].size() == rl + 1}
	var cpo = null
	for o in C.lateShopOffers():
		if o["kind"] == "cp": cpo = o
	var cap = float(R["cpCap"])
	C.ACT_lateBuy("cp"); got["cp"] = {"cost": cpo["cost"], "ok": float(R["cpCap"]) == cap + 1}
	var p = R["patrons"][0]; var rc = C.boonRerollCost()
	R["reward"] = {"kind": "story", "rw": {"k": "boon", "p": p}, "stage": "pick", "relics": [], "wrecks": [], "prizes": [], "boonOffer": C.rollBoonOffer(p, 0), "modOffer": null}
	var off = C.boonReroll(p, 0); got["reroll"] = {"cost": rc, "ok": off != null and C.jt(R["reward"].get("rerolled"))}
	return got

func _sum(g: Dictionary) -> float:
	var s = 0.0
	for k in KINDS:
		if g.has(k): s += float(g[k]["cost"])
	return s

func _run() -> void:
	var err: String = C.load_tables()
	if err != "":
		printerr("FAIL: " + err); quit(1); return
	C.fixed_clock = true

	var R = _start("matriarch", "chorus", 5000.0, 0.0); var g = _buy_all()
	for k in KINDS: check(g.has(k) and g[k]["ok"], "Chorus with biomass buys the " + k)
	check(float(R["bio"]) == 5000.0 - _sum(g), "Chorus biomass pays the whole bill (" + str(R["bio"]) + ")")
	check(float(R["credits"]) == 0.0, "Chorus credits are untouched")

	R = _start("matriarch", "chorus", 0.0, 5000.0); g = _buy_all()
	for k in KINDS: check(g.has(k) and g[k]["ok"], "Chorus with credits only still buys the " + k)
	check(float(R["credits"]) == 5000.0 - _sum(g) and float(R["bio"]) == 0.0, "Chorus credits pay when biomass is short (" + str(R["credits"]) + ")")

	R = _start("matriarch", "chorus", 20.0, 20.0); g = _buy_all()
	for k in KINDS: check(g.has(k) and not g[k]["ok"], "Chorus with neither purse covering the price cannot buy the " + k)
	check(float(R["credits"]) == 20.0 and float(R["bio"]) == 20.0, "a short Chorus purse is never split")

	R = _start("vex", "voidsworn", 0.0, 5000.0); g = _buy_all()
	for k in KINDS: check(g.has(k) and g[k]["ok"], "Crusade with credits buys the " + k)
	check(float(R["credits"]) == 5000.0 - _sum(g), "Crusade credits pay the whole bill (" + str(R["credits"]) + ")")

	if fails == 0: print("PASS: Chorus biomass pays for refits, tracks, rerolls and the late market (issue 1484)")
	quit(1 if fails else 0)
