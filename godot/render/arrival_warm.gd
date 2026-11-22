extends RefCounted
## Issue 1289: a ship that joins a battle after it starts (a reinforcement) paid for its hull's first sight in the frame it
## arrived: loading its model and paint, baking its fitted shield skin, building its effects and damage overlays and the
## renderer's first draw of all of them (about 1 s on the PC in an empty profile). The battle knows at its start which hull
## its reinforcement event brings (battle_api.arrival_previews), so this kit builds that hull once under the loading cover,
## exactly as an arriving ship is built (ShipView.setup and fx.add_ship), lets the battle warm-up draw and cut it with every
## other ship, then takes it out of the effects and hides it. The hidden copy stays in the scene until the battle ends, so
## the model, its paint copies and its shield skin stay loaded and the real arrival finds them all ready.
## Shared by the battle (scenes/battle/battle.gd _warmup) and the PC bench (contrib/opus/arrival_hitch_1289).

const SV := preload("res://render/ship_view.gd")

var views: Array = []   # [{"id": fx id, "sv": ShipView}]
var fx = null


# Build each preview hull at `at` under `parent` and give it to the effects, before the warm-up (prepare_battle_hulls and
# fx.warmup) runs. `previews` are view-like units (battle_api.arrival_previews).
func prepare(parent: Node, gfx, previews: Array, at: Vector3) -> void:
	fx = gfx
	for p in previews:
		var sv = SV.new()
		var id := str(p.get("id", "arrival_warm_%d" % views.size()))
		sv.name = id
		parent.add_child(sv)
		sv.setup(p, at, true)
		if gfx != null and gfx.has_method("add_ship"):
			var info := {"faction": str(sv.fac), "cls": str(p.get("cls", "")), "size": float(p.get("size", 1.0)),
				"squadron": false, "flagship": false, "code": sv.code}
			if not sv.a4:
				info["meshes"] = sv.meshes
			gfx.add_ship(id, sv, info)
			sv.fx_engines = true
		views.append({"id": id, "sv": sv})


# After the warm-up: out of the effects (no engines, colliders or cut kept for a ship that is not in the battle), hidden,
# and not processed. The node stays so its resources stay loaded.
func park() -> void:
	for v in views:
		if fx != null and is_instance_valid(fx) and fx.has_method("remove_ship"):
			fx.remove_ship(str(v["id"]))
		var sv = v["sv"]
		if is_instance_valid(sv):
			sv.visible = false
			sv.process_mode = Node.PROCESS_MODE_DISABLED


func release() -> void:
	park()
	for v in views:
		if is_instance_valid(v["sv"]):
			(v["sv"] as Node).queue_free()
	views.clear()
