# Issue 1333 audit, finding F1 (Godot). godot --headless --path godot --script <abs path to this file>
# Same setup as repro_eaten_core_boon.js. Exit 1 when the offer comes from the eaten core's patron (the bug).
extends SceneTree
const Campaign = preload("res://campaign/campaign.gd")
const JSM = preload("res://rules/jsm.gd")
func _init() -> void:
	var C = Campaign.new(); C.load_tables(); C.persist_on = false; C.fixed_clock = true
	JSM.rnd_seed(120); C.META = C.defaultMeta(); C.META["admirals"]["matriarch"] = true; C.newRun("matriarch", "chorus", {})
	C.RUN["patrons"] = ["star", "rook", "storm", "iron"]; C.RUN["eatenCore"] = "iron"; C.RUN["eatCoreSeen"] = true; C.RUN["sector"] = 3; C.RUN["credits"] = 200
	C.RUN["reward"] = {"kind": "elite", "rw": {"k": "boon", "p": "iron", "min": 1}, "stage": "pick", "relics": [], "wrecks": [], "prizes": [], "boonOffer": null, "modOffer": null}
	C.boonStep("iron", 1)
	var p = C.modal_d["data"]["patron"] if C.modal_d != null else "none"
	var ids = []
	for o in C.RUN["reward"]["boonOffer"]: ids.append(str(o["id"]) + " (" + str(C.BOONS[o["id"]].get("p")) + ")")
	print("godot: offer patron = %s; offer = %s" % [p, ", ".join(ids)])
	quit(1 if p == "iron" else 0)
