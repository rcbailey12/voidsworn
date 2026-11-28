extends SceneTree
## Headless checks for SY-A. With a reviewed GPU checkout, add -- --shots DIR for the two labeled stills.

const Campaign := preload("res://campaign/campaign.gd")
const CampaignUI := preload("res://ui/campaign/campaign_ui.gd")
const Tips := preload("res://ui/campaign/campaign_tips.gd")
const Yard := preload("res://ui/campaign/shipyard.gd")
const Podium := preload("res://ui/campaign/flagship_podium.gd")
const ShipView := preload("res://render/ship_view.gd")
const HullTable := preload("res://render/hull_table.gd")
const PreviewOp := preload("res://campaign/preview_op.gd")
const UiScale := preload("res://ui/ui_scale.gd")
const Kit := preload("res://ui/theme/orders_kit.gd")
const Picture := preload("res://tools/picture_provenance.gd")
const Age := preload("res://render/hull_age.gd")

var C := Campaign.new()
var ui: CampaignUI
var fails := 0
var stop := {}

class CueEar extends Node:
	var heard: Array[String] = []

	func play(id: String) -> void:
		heard.append(id)


class SettingsHost extends Node:
	var settings := {"reduce_motion": true}


func _initialize() -> void: _run.call_deferred()


func _run() -> void:
	var err := C.load_tables()
	if not err.is_empty(): printerr(err); quit(1); return
	C.fixed_clock = true
	C.seed_rng(2080)
	C.newRun("vex", "voidsworn")
	C.RUN["credits"] = 650
	C.RUN["cpCap"] = 40
	C.RUN["inventory"] = ["prow"]
	C.RUN["fleet"].append(C.newShip("ascendant"))
	var s: Dictionary = C.flagshipOf()
	s["hp"] = 94.0
	s["yard_sections"] = {"prow": {"hp": 0.0, "max": 40.0, "broken": true}}
	C.modal_d = null
	stop = {"id": "SY-A", "type": "shipyard", "stock": {"hulls": ["warden"], "cap": [], "mods": [], "sold": []}}
	C.shipyardScreen(stop)
	ui = CampaignUI.new()
	root.add_child(ui)
	ui.C = C
	ui.use_3d_map = false
	ui.set_process(false)
	ui.teaching = Tips.new()
	ui.teaching.disabled = true
	ui.add_child(ui.teaching)
	var args := OS.get_cmdline_user_args()
	var shot_arg := args.find("--shots")
	if shot_arg >= 0:
		if shot_arg + 1 >= args.size() or DisplayServer.get_name() == "headless":
			printerr("FAIL: --shots needs a folder and a reviewed GPU checkout"); quit(1); return
		await _capture(args[shot_arg + 1])
		quit(1 if fails > 0 else 0)
		return
	await _resize(Vector2i(1920, 1080), 1.0)
	var yard := _yard()
	var before := _snapshot()
	var uid: String = s["uid"]
	check(yard.selected["uid"] == uid, "flagship selected on entry")
	check(_labels(yard).any(func(l): return l.text == s["cap"]["callsign"].to_upper()), "inspector reads the saved captain callsign")
	check(_meter_keys(yard) == ["hull", "shield_pool"], "one hull meter and one shield pool meter in inspector")
	var repair := _button("repair", uid)
	var preview: Label
	_hover(repair)
	for rendered in _preview_labels(yard):
		if rendered.get_meta("preview_row")["stat_key"] == "hull": preview = rendered
	check(preview != null and preview.text == "Hull 94 to 135 (+41)", "repair hover writes the exact live old, new and delta")
	check(_snapshot() == before, "opening and hovering the yard leave the run, RNG and UID alone")
	_expect_preview(yard, "repair", uid)
	_expect_preview(yard, "upgradeMk", uid)
	_expect_preview(yard, "refit", uid, 0)
	_expect_preview(yard, "buyHull", "warden")
	var fit := _button("equip", "0:" + uid)
	check(not fit.disabled, "a compatible hold refit can be fitted directly in the yard")
	fit.pressed.emit()
	check(s["mods"] == ["prow"] and C.RUN["inventory"].is_empty() and C.page["kind"] == "shipyard", "fit uses the live commit and returns to the yard")
	_hover(repair)
	var target: float = PreviewOp.plan(C, "repair", uid, -1)["ship"]["hp"]
	repair.pressed.emit()
	check(s["hp"] == target and not s.has("yard_sections"), "committed repair exactly matches preview and clears battle damage")
	await _resize(Vector2i(1920, 1080), 1.0)
	yard = _yard()
	repair = _button("repair", uid)
	check(repair.disabled and _reason_above(repair, "Hull already full."), "full hull reason is above Repair")
	_check_partial_repair(s)
	await _resize(Vector2i(1920, 1080), 1.0)
	yard = _yard()
	var other: Dictionary = C.RUN["fleet"].back()
	var before_select := _snapshot()
	_pick(other["uid"])
	await _frames()
	check(yard.selected["uid"] == other["uid"] and _snapshot() == before_select, "selecting a whole roster row changes only UI state")

	C.RUN["credits"] = 0
	C.shipyardScreen(stop)
	await _resize(Vector2i(1280, 720), 1.0)
	yard = _yard()
	var buy := _button("buyHull", "warden")
	check(buy.disabled and _reason_above(buy, "Not enough credits."), "unaffordable hull has its reason above it")
	_expect_preview(yard, "buyHull", "warden")
	_unhover(buy)
	await create_timer(0.22).timeout
	check(yard._preview_tpl.is_empty(), "a departed hover cannot replace the selected ship later")
	C.RUN["credits"] = 650
	C.shipyardScreen(stop)
	await _resize(Vector2i(1920, 1080), 1.0)
	var order := PreviewOp.plan(C, "buyHull", "warden", -1)
	var ear := CueEar.new()
	root.add_child(ear)
	var old_sound = Kit.sound
	Kit.sound = ear
	var funds: float = C.RUN["credits"]
	_button("buyHull", "warden").pressed.emit()
	Kit.sound = old_sound
	check(ear.heard == ["ui_reward"], "Buy Hull plays exactly one reward cue: " + str(ear.heard))
	ear.free()
	var bought: Dictionary = C.RUN["fleet"].back()
	var numbers := PreviewOp._stats(C, bought)
	check(order["rows"].all(func(row): return is_equal_approx(numbers[row["stat_key"]], row["new"])), "purchased hull has every previewed figure")
	check(funds - C.RUN["credits"] == order["rows"][0]["cost"], "the hull purchase charges the previewed price")
	await _resize(Vector2i(1920, 1080), 1.0)
	check(_yard().selected["uid"] == bought["uid"], "confirming a hull selects the real new ship")
	await _check_flagship_sale(uid)
	await _geometry()
	var damaged := Podium.damage_snapshot({"hp": 10, "yard_sections": {"eng": {"broken": true, "hp": 0, "max": 20}}}, 100)
	check(damaged["sec"]["eng"]["broken"] and damaged["sec"]["prow"].is_empty(), "wear never invents a broken section from total hull")
	await _check_loaded_mesh()
	print("SY-A Gantry: " + ("PASS" if fails == 0 else "FAIL (%d)" % fails))
	quit(1 if fails > 0 else 0)


func _check_partial_repair(ship: Dictionary) -> void:
	ship["hp"] = C.derive(ship)["maxHp"] - 20.0
	C.RUN["credits"] = 9
	C.shipyardScreen(stop)
	ui.render()
	var uid: String = ship["uid"]
	var repair := _button("repair", uid)
	check(not repair.disabled and repair.text == "Repair 18 of 20 for 9", "the visible Repair label shows the partial quote")
	_hover(repair)
	var rows := _preview_labels(_yard()).map(func(l): return l.get_meta("preview_row"))
	var mark := _button("upgradeMk", uid)
	var quote: Dictionary = C.preview_op("upgradeMk", uid)[0]
	check(mark.text == "Mk II for " + C.numstr(quote["cost"]) and mark.disabled and _reason_above(mark, quote["disabled_reason"]), "Mark shows its previewed quote and disabled reason")
	repair.pressed.emit()
	check(rows.size() == 1 and ship["hp"] == rows[0]["new"] and 9.0 - C.RUN["credits"] == rows[0]["cost"], "the partial repair matches its visible hover row and bill")


func _check_flagship_sale(uid: String) -> void:
	_pick(uid)
	var sell := _button("sellShip", uid)
	check(not sell.disabled, "the flagship may be decommissioned with other ships in the fleet")
	if sell.disabled: return
	var previous_count: int = C.RUN["fleet"].size()
	sell.pressed.emit()
	await _resize(Vector2i(1920, 1080), 1.0)
	check(C.modal_d != null and C.modal_d["kind"] == "sell" and C.RUN["fleet"].size() == previous_count, "Decommission asks before selling the flagship")
	var confirm := _action_button(ui.modal_box, "sellConfirm", uid)
	check(confirm != null, "the sale modal offers a confirmation for the selected flagship")
	if confirm == null: return
	confirm.pressed.emit()
	var replacement = C.flagshipOf()
	check(C._ship(uid) == null and C.RUN["fleet"].size() == previous_count - 1, "the confirmed sale removes the old flagship")
	check(replacement != null and replacement["uid"] != uid, "Campaign hands the flag to a remaining ship")
	if replacement == null: return
	await _resize(Vector2i(1920, 1080), 1.0)
	check(_yard().selected["uid"] == replacement["uid"], "the Gantry selects the replacement flagship")
	C.RUN["fleet"] = [replacement]
	C.shipyardScreen(stop)
	await _resize(Vector2i(1920, 1080), 1.0)
	sell = _button("sellShip", replacement["uid"])
	check(sell.disabled and _reason_above(sell, "Keep at least one ship."), "the last ship cannot be decommissioned")


func _geometry() -> void:
	for i in 18:
		var s := C.newShip("warden")
		s["name"] = "A Very Long Ship Name For A Crowded Gantry Test " + str(i)
		C.RUN["fleet"].append(s)
	C.shipyardScreen(stop)
	for specimen in [[Vector2i(1920, 1080), 1.0], [Vector2i(1280, 720), 1.4], [Vector2i(1024, 768), 1.4], [Vector2i(800, 800), 1.4]]:
		await _resize(specimen[0], specimen[1])
		var yard := _yard()
		var screen := Rect2(Vector2.ZERO, Vector2(root.size))
		var bay: Rect2 = yard._stage.get_global_rect()
		check(not yard._bay_code.text.is_empty() and yard._bay_code.size.x >= ui.px(40), "ship code fits the bay heading")
		check(yard._roster.get_child_count() == C.RUN["fleet"].size(), "whole fleet reachable in roster at %s" % str(specimen))
		check(yard.market_scroll.get_v_scroll_bar().max_value > yard.market_scroll.size.y, "long roster scrolls at %s" % str(specimen))
		check(bay.size.x > ui.px(200) and bay.size.y > ui.px(220), "bay gets useful room at %s: %s" % [str(specimen), str(bay)])
		if not yard._compact:
			check(screen.encloses(bay) and not bay.intersects(yard._inspector.get_global_rect()), "bay and inspector do not overlap at %s" % str(specimen))
		else:
			check(yard._narrow_scroll.get_v_scroll_bar().max_value > screen.size.y, "narrow stack remains scrollable")
		for l: Label in _labels(yard):
			check(l.get_theme_font_size("font_size") >= ui.px(17), "readable font floor for " + l.text)


func _capture(out: String) -> void:
	check(not Picture.capture_is_direction_check(), "captures need the real Forward+ GPU renderer")
	check(DirAccess.make_dir_recursive_absolute(out) == OK, "capture folder is writable")
	if fails > 0: return
	await _resize(Vector2i(1920, 1080), 1.0)
	for tpl in ["warden", "ascendant"]:
		var candidates: Array = C.RUN["fleet"].filter(func(s): return s["tpl"] == tpl)
		check(not candidates.is_empty(), tpl + " is in the capture fleet")
		if fails > 0: return
		_pick(candidates[0]["uid"])
		await _frames()
		var podium = _yard()._podium
		podium.spin = false
		check(podium.installed and Age.guard([podium.code]).is_empty(), "installed reviewed hull for " + tpl + " (" + podium.code + ")")
		if fails > 0: return
		_check_projection(podium, true)
		if fails > 0: return
		await RenderingServer.frame_post_draw
		var image := root.get_texture().get_image()
		check(absf(float(image.get_width()) / float(image.get_height()) - 16.0 / 9.0) < 0.01, "capture is 16:9")
		if fails > 0: return
		image.resize(1280, 720, Image.INTERPOLATE_LANCZOS)
		var file: String = "SY-A_" + podium.code + ".png"
		check(preload("res://tools/picture_provenance.gd").save_png(image, out.path_join(file), Picture.capture_stage()) == OK, "saved " + file)
		print("SY-A " + file)


func _check_loaded_mesh() -> void:
	# CI has no installed hulls. Let ShipView fit one mesh for each real hull class through the yard.
	var manifest := ShipView.manifest()
	var saved := manifest.duplicate(true)
	var codes := {}
	var hulls := {}
	var fleet := [C.newShip("warden"), C.newShip("ascendant")]
	for ship: Dictionary in fleet:
		var cls: String = C.HULLS[ship["tpl"]]["cls"]
		var code := HullTable.code_for(C.factionOfTpl(ship["tpl"]), cls)
		var box := BoxMesh.new()
		box.size = Vector3(10.0, 2.4, 3.8) if cls == "Dreadnought" else Vector3(10.0, 2.0, 3.0)
		var mesh := ArrayMesh.new()
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, box.get_mesh_arrays())
		var model := "user://gantry_2080_%s_%d.res" % [code, Time.get_ticks_usec()]
		var ok := ResourceSaver.save(mesh, model) == OK
		check(ok, "%s mesh fixture can be saved" % code)
		if ok: hulls[code] = {"res": model}
		codes[ship["uid"]] = code
	manifest.clear()
	manifest["hulls"] = hulls
	C.RUN["fleet"] = fleet
	C.RUN["credits"] = 9
	var escort: Dictionary = fleet[0]
	escort["hp"] = floorf(C.derive(escort)["maxHp"] * 0.35)
	escort["yard_sections"] = {"prow": {"hp": 0.0, "max": 40.0, "broken": true}}
	var settings := SettingsHost.new()
	settings.name = "Main"
	root.add_child(settings)
	C.ensureFlagship()
	C.shipyardScreen(stop)
	await _resize(Vector2i(1920, 1080), 1.0)
	var spans := []
	for ship: Dictionary in fleet:
		var uid: String = ship["uid"]
		_pick(uid)
		await _frames()
		var yard := _yard()
		var stage := yard._podium
		check(yard.selected["uid"] == uid and stage.installed and yard._bay_code.text == codes[uid], "%s selected in the bay" % codes[uid])
		if stage.installed:
			check(not stage.spin, "%s holds still with reduced motion" % codes[uid])
			spans.append(stage._bounds.get_longest_axis_size())
			for pitch in [4.0, 18.0, 44.0]:
				stage._pitch = pitch
				stage._frame()
				for yaw in range(-23, 337, 30):
					stage._pivot.rotation_degrees.y = float(yaw)
					_check_projection(stage, yaw == -23 and pitch == 18.0)
			if ship == escort: await _check_projected_wear(ship, stage)
	check(spans.size() == 2 and spans[1] > 3.0 * spans[0], "the framing check covers distinct escort and dreadnought scales")
	settings.free()
	manifest.clear()
	manifest.merge(saved)
	for fixture: Dictionary in hulls.values(): DirAccess.remove_absolute(ProjectSettings.globalize_path(fixture["res"]))


func _check_projected_wear(ship: Dictionary, stage: Podium) -> void:
	var uid: String = ship["uid"]
	var dressing = stage._fx.ship(uid)
	var repair := _button("repair", uid)
	var before := _snapshot()
	var wear: float = dressing.hull_wear
	_hover(repair)
	var projected: float = dressing.hull_wear
	check(projected > 0.0 and projected < wear, "affordable partial repair previews less wear, not a pristine hull")
	check(_snapshot() == before, "model preview leaves the damaged ship, purse and RNG unchanged")
	_unhover(repair)
	check(is_equal_approx(dressing.hull_wear, wear), "leaving hover restores the original wear")
	_hover(repair)
	repair.pressed.emit()
	await _resize(Vector2i(1920, 1080), 1.0)
	var committed := _yard()._podium
	check(committed.installed and is_instance_valid(committed._fx) and is_equal_approx(committed._fx.ship(uid).hull_wear, projected), "committed partial repair has exactly the previewed wear")
	check(not ship.has("yard_sections"), "committed partial repair removes the recorded cutout")


func _check_projection(stage: Podium, check_fill: bool) -> void:
	var camera := stage._camera
	var rect := camera.get_viewport().get_visible_rect()
	var points := Rect2(camera.unproject_position(stage._pivot.to_global(stage._bounds.get_endpoint(0))), Vector2.ZERO)
	for i in range(1, 8):
		points = points.expand(camera.unproject_position(stage._pivot.to_global(stage._bounds.get_endpoint(i))))
	check(rect.encloses(points), stage.code + " mesh bounds fit the bay")
	if check_fill and rect.size.x > 0.0 and rect.size.y > 0.0:
		check(maxf(points.size.x / rect.size.x, points.size.y / rect.size.y) > 0.6, stage.code + " fills the bay from the opening angle")


func _reason_above(button: Button, reason: String) -> bool:
	if button == null or button.get_index() == 0: return false
	var previous := button.get_parent().get_child(button.get_index() - 1)
	return previous is Label and previous.text == reason


func _expect_preview(yard: Yard, action: String, key: String, slot := -1) -> void:
	var cmd := "equip" if action == "refit" else action
	var arg := "%d:%s" % [slot, key] if action == "refit" else key
	var button := _button(cmd, arg)
	check(button != null, "candidate button for " + action)
	if button == null: return
	var before := _snapshot()
	_hover(button)
	var rows: Array = PreviewOp.plan(C, action, key, slot)["rows"]
	var expected := rows.filter(func(r): return not is_zero_approx(float(r["delta"])))
	var actual := _preview_labels(yard).map(func(l): return l.get_meta("preview_row"))
	check(actual == expected, action + " renders the PreviewOp rows exactly")
	check(_snapshot() == before, action + " preview is read-only")
	_unhover(button)


func _pick(uid: String) -> void:
	var matches: Array = _yard().find_children("*", "Button", true, false).filter(func(b): return b.get_meta("yard_ship", "") == uid)
	check(matches.size() == 1, "one fleet row for " + uid)
	if not matches.is_empty(): matches[0].pressed.emit()


func _hover(button: Button) -> void: button.get_parent().mouse_entered.emit()
func _unhover(button: Button) -> void: button.get_parent().mouse_exited.emit()
func _labels(n: Node) -> Array: return n.find_children("*", "Label", true, false)
func _preview_labels(yard: Yard) -> Array: return _labels(yard).filter(func(l): return l.has_meta("preview_row"))
func _meter_keys(yard: Yard) -> Array: return yard._meters.keys()
func _snapshot() -> String: return C.save_text() + "|" + str(C.rng.rng_s) + "|" + str(C.UID)


func _yard() -> Yard:
	for child in ui.page_box.get_children():
		if child is Yard and not child.is_queued_for_deletion(): return child
	return null


func _button(action: String, arg: String) -> Button:
	return _action_button(_yard(), action, arg)


func _action_button(under: Node, action: String, arg: String) -> Button:
	for b in under.find_children("*", "Button", true, false):
		if b.get_meta("press_act", "") == action and b.get_meta("press_arg", "") == arg: return b
	return null


func _resize(res: Vector2i, scale: float) -> void:
	root.size = res
	UiScale.set_player(scale)
	ui._rescale()
	ui.render()
	await _frames()


func _frames() -> void:
	for i in 5: await process_frame


func check(ok: bool, message: String) -> void:
	if not ok:
		fails += 1
		printerr("FAIL: " + message)
