extends SceneTree
# Issue 2200 (Duet FX and battle perf audit F5 and F6), headless:
# F5. warm_munitions warms every kit body in fx/munition_bodies for the fleets on the board, the Chorus Acid Thorn bolt
#     included, so the first Chorus volley reads and builds nothing in the fight.
# F6. a nova draws no placeholder stub bolt: with the G4 effects present it goes through gfx.nova and never calls the
#     stub's bolt; with no G4 effects the scene's own flash is the fallback; Reduce flashing draws nothing at all.
# Run: godot --headless --path godot --script res://fx/test/munition_warm_nova_check.gd

const GUARD := preload("res://tools/ci/check_guard.gd")
const FX := preload("res://fx/fx.gd")
const WEAP := preload("res://fx/fx_weapons.gd")
const THORN := preload("res://fx/fx_acid_thorn.gd")
const BATTLE_SCENE := preload("res://scenes/battle/battle.tscn")

var failures := 0


# The placeholder fx stub, recorded: a nova must never reach its bolt.
class Stub extends Node3D:
	var bolts := 0
	var flashes := 0
	func bolt(..._a: Array) -> void: bolts += 1
	func beam(..._a: Array) -> void: pass
	func flash(..._a: Array) -> void: flashes += 1
	func clear() -> void: pass


# The G4 effects stand-in: nova answers on its own clock, so the nova branch settles at once.
class G4 extends Node:
	var now := 0.0
	var reduce_flashing := false
	var reduce_motion := false
	var kill_slowmo := false
	var shake_scale := 1.0
	var nova_calls := 0
	var pops := 0
	func nova(..._a: Array) -> float:
		nova_calls += 1
		return now
	func pop(..._a: Array) -> void: pops += 1
	func light(..._a: Array) -> void: pass


func _init() -> void:
	GUARD.arm(self, "munition_warm_nova_check", 180.0)
	_run.call_deferred()


func _check(ok: bool, message: String) -> void:
	print(("PASS " if ok else "FAIL ") + message)
	if not ok:
		failures += 1


func _ship(fx, id: String, faction: String) -> Node3D:
	var target := Node3D.new()
	target.name = id
	root.add_child(target)
	var mi := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(12, 2, 3)
	mi.mesh = box
	target.add_child(mi)
	fx.add_ship(id, target, {"meshes": [mi], "shielded": false, "faction": faction})
	return target


func _run() -> void:
	_warm()
	await _nova()
	print("MUNITION_WARM_NOVA_CHECK %s, %d failures" % ["PASS" if failures == 0 else "FAIL", failures])
	quit(1 if failures else 0)


# F5: warm_munitions warms every kit in fx/munition_bodies for the fleets on the board.
func _warm() -> void:
	var fx = FX.new()
	root.add_child(fx)
	fx.manual = true
	fx.setup({"quality": "high"})
	var ships: Array = []
	for row in [["chorus_0", "chorus"], ["voidsworn_0", "voidsworn"], ["corsair_0", "corsair"]]:
		ships.append(_ship(fx, str(row[0]), str(row[1])))
	var parent := Node3D.new()
	fx.add_child(parent)
	var warmed: int = WEAP.warm_munitions(fx, parent)
	var on_board := {"chorus": true, "voidsworn": true, "corsair": true}
	var kits := 0
	var missing: Array = []
	var dir := DirAccess.open(WEAP.MUNITIONS_DIR)
	if dir == null:
		_check(false, "F5: the munition body folder opens (%s)" % WEAP.MUNITIONS_DIR)
	else:
		for f in dir.get_files():
			if not str(f).ends_with(".glb"):
				continue
			var base := str(f).get_basename()
			var cut := base.find("_")
			if cut <= 0:
				continue
			var faction := base.substr(0, cut)
			var look := base.substr(cut + 1)
			if not on_board.has(faction):
				continue
			kits += 1
			if not fx.dstate.has("munition_%s_%s" % [faction, look]):
				missing.append(str(f))
	_check(kits == 3, "F5: fx/munition_bodies has one kit for each fleet on the board (%d)" % kits)
	_check(missing.is_empty(), "F5: warm_munitions warms every kit on the board (missing: %s)" % ("none" if missing.is_empty() else ", ".join(missing)))
	_check(warmed == kits, "F5: the warm count is every kit on the board (%d of %d)" % [warmed, kits])
	_check(fx.dstate.has("munition_chorus_bolt"), "F5: the Chorus Acid Thorn bolt is warmed before the fight")
	var thorn: Node3D = THORN._body(fx, 1.0)
	_check(thorn != null and thorn.get_node_or_null("kit_body") != null,
		"F5: the Acid Thorn flies the built chorus_bolt body")
	if thorn != null:
		thorn.free()
	for sh in ships:
		fx.remove_ship(str(sh.name))
		(sh as Node).free()
	fx.free()


# F6: a nova never draws the placeholder stub bolt, and Reduce flashing draws nothing.
func _nova() -> void:
	var b = BATTLE_SCENE.instantiate()
	b.tips_off = true
	b.external = true
	b.args["noworld"] = true
	b.args["quality"] = "low"
	root.add_child(b)
	b.args["scenario"] = "s1"
	b.args["seed"] = 2200
	b.start_default()
	var t0 := Time.get_ticks_msec()
	while (b.api == null or b.warming or b.busy or b.api.phase != "player") and Time.get_ticks_msec() - t0 < 120000:
		await process_frame
	_check(b.api != null and b.api.phase == "player", "F6: the test battle reaches the player's turn")
	if b.api == null or b.api.phase != "player":
		b.queue_free()
		await process_frame
		return
	var id := ""
	var hex := {}
	for u in b.V["units"]:
		if str(u.get("side", "")) == "player" and not bool(u.get("dead", false)):
			id = str(u["id"])
			hex = {"q": int(u.get("q", 0)), "r": int(u.get("r", 0))}
			break
	_check(id != "", "F6: the battle has a player ship to fire a nova")
	if id == "":
		b.queue_free()
		await process_frame
		return
	var stub := Stub.new()
	root.add_child(stub)
	b.fx = stub
	var g4 := G4.new()
	root.add_child(g4)
	b.gfx = g4
	b.speed = 0.001
	await b._play_event({"t": "ability", "unit": id, "ab": "nova", "hex": hex})
	_check(g4.nova_calls == 1, "F6: with G4 present a nova goes through gfx.nova")
	_check(stub.bolts == 0, "F6: with G4 present a nova draws no placeholder stub bolt")
	_check(stub.flashes == 0, "F6: with G4 present a nova draws no placeholder flash either")
	b.gfx = null
	b.reduce_flashing = true
	stub.bolts = 0
	stub.flashes = 0
	await b._play_event({"t": "ability", "unit": id, "ab": "nova", "hex": hex})
	_check(stub.bolts == 0 and stub.flashes == 0, "F6: Reduce flashing with no G4 draws no stub bolt and no flash")
	b.reduce_flashing = false
	b._stub_flashes.clear()
	stub.bolts = 0
	stub.flashes = 0
	await b._play_event({"t": "ability", "unit": id, "ab": "nova", "hex": hex})
	_check(stub.bolts == 0, "F6: the no-G4 fallback still draws no stub bolt")
	_check(stub.flashes > 0, "F6: the no-G4 fallback is the scene's own flash")
	stub.free()
	g4.free()
	b.queue_free()
	await process_frame
