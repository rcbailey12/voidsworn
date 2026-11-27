extends SceneTree
# Issue 1801: drive the real campaign rail, chart and overlays through the viewport.
const Campaign = preload("res://campaign/campaign.gd")
const UI = preload("res://ui/campaign/campaign_ui.gd")
const Map = preload("res://ui/campaign/map3d.gd")
const GS = preload("res://ui/theme/glass_shell.gd")
const Kit = preload("res://ui/theme/orders_kit.gd")
const ModalFocus = preload("res://ui/theme/modal_focus.gd")
const UiScale = preload("res://ui/ui_scale.gd")

class SoundProbe extends Node:
	var cues: Array[String] = []
	func play(cue: String) -> void:
		cues.append(cue)

var fails := 0
var c
var ui
var chart: Map
var focus_changes: Array[Control] = []

func _initialize() -> void:
	_run.call_deferred()

func _check(ok: bool, message: String) -> void:
	print(("PASS " if ok else "FAIL ") + message)
	if not ok: fails += 1

func _frames(n := 4) -> void:
	for i in n: await process_frame

func _key(code: int, shift := false) -> void:
	for pressed in [true, false]:
		var e := InputEventKey.new()
		e.keycode = code
		e.physical_keycode = code
		e.pressed = pressed
		e.shift_pressed = shift
		root.push_input(e, true)
	await _frames()

func _motion(at: Vector2, mask := 0) -> void:
	root.notify_mouse_entered()
	var e := InputEventMouseMotion.new()
	e.position = at
	e.global_position = at
	e.button_mask = mask
	Input.parse_input_event(e)
	Input.flush_buffered_events()

func _button(at: Vector2, which: MouseButton, pressed: bool, twice := false) -> void:
	var e := InputEventMouseButton.new()
	e.position = at
	e.button_index = which
	e.pressed = pressed
	e.double_click = twice
	root.push_input(e, true)

func _click(at: Vector2, twice := false) -> void:
	_motion(at)
	_button(at, MOUSE_BUTTON_LEFT, true, twice)
	_button(at, MOUSE_BUTTON_LEFT, false)

func _wheel(at: Vector2, which: MouseButton) -> void:
	_button(at, which, true)
	_button(at, which, false)

func _route(n: int) -> Button:
	return ui._rail_host.find_child("Route%d" % n, true, false)

func _center(control: Control) -> Vector2:
	return control.get_global_rect().get_center()

func _focus_stays_in(panel: Control) -> bool:
	var focused := root.gui_get_focus_owner()
	return panel != null and focused != null and panel.is_ancestor_of(focused) and focus_changes.all(panel.is_ancestor_of)

func _run() -> void:
	root.size = Vector2i(1920, 1080)
	UiScale.set_player(1.15)
	c = Campaign.new()
	var err: String = c.load_tables()
	if err != "":
		_check(false, err)
		quit(1)
		return
	c.persist_on = false
	c.fixed_clock = true
	c.teaching_tips = false
	for seed_value in range(1, 40):
		c.rng.rnd_seed(seed_value)
		c.newRun("vex", "voidsworn")
		c.ACT_enterNode(c.availableNodes()[0])
		if c.availableNodes().size() >= 4: break
	for i in 10: c.RUN["fleet"].append(c.newShip("penitent"))
	c.mapScreen()
	ui = UI.new()
	root.add_child(ui)
	ui.bind(c)
	chart = ui.map3d
	await _frames()
	var deadline := Time.get_ticks_msec() + 30000
	while chart.loading and Time.get_ticks_msec() < deadline:
		await process_frame
	if chart.loading or ui._routes.size() < 2:
		_check(false, "the seeded map loads with at least two routes")
		quit(1)
		return
	chart._arrival_tween.kill()
	chart._cam_focus = Vector3.ZERO
	chart._cam_zoom = 1.0
	chart._live_frame(0.5)
	chart.set_process(false)
	await _frames()
	root.gui_focus_changed.connect(func(f: Control): focus_changes.append(f))
	var first := str(ui._routes[0]["id"])
	var second := str(ui._routes[1]["id"])
	await _rail_and_chart(first, second)
	await _covers()
	await _drag_cancellation()
	await _double_click(first, second)
	print("MAP_INPUT fails=%d" % fails)
	quit(1 if fails else 0)

func _rail_and_chart(first: String, second: String) -> void:
	ui.pick_route(second)
	await _frames()
	_click(_center(_route(1)))
	await _frames()
	_check(ui.picked == first and root.gui_get_focus_owner() == _route(1), "A1 clicking a route picks it and leaves focus in the rail")
	await _key(KEY_2)
	_check(ui.picked == second, "A1 the number key keeps its route after rail focus is restored")
	ui.pick_route(first)
	await _frames()
	var row := _route(1)
	var orders: ScrollContainer = ui._rail_host.find_child("OrdersScroll", true, false)
	var fleet: ScrollContainer = ui._rail_host.find_child("FleetScroll", true, false)
	orders.scroll_vertical = 55
	fleet.scroll_vertical = 65
	var orders_at := orders.scroll_vertical
	var fleet_at := fleet.scroll_vertical
	_check(orders_at > 0 and fleet_at > 0, "A4 the seeded rail can scroll both lists")
	chart.grab_focus()
	var stop: Dictionary = chart._nodes[second]
	var scale: float = ui.k
	var center := chart._screen(stop["pos"])
	var icon := chart._screen(stop["pos"] + Vector3(0, (stop["top"] + 0.6) * stop["sc"], 0))
	icon.y -= (GS.STOP_ICON_PX * 0.5 + GS.STOP_ICON_GAP) * scale
	var words: Rect2 = chart._words[chart._words.size() - ui._routes.size() + 1]
	var marker := words.position + Vector2.ONE * 17.0 * scale
	var name := Vector2(words.end.x - 4.0 * scale, words.get_center().y)
	_check(chart._node_at(marker) == second, "A2 the painted route marker hits its stop")
	_check(chart._node_at(name) == second, "A2 the painted stop name hits its stop")
	_check(chart._node_at(icon) == second, "A2 the painted type icon hits its stop")
	var boss: String = str(c.RUN["map"]["cols"].back()[0]["id"])
	var bounds := chart._body_rect(boss, scale)
	var hull_edge := Vector2(bounds.end.x - 3.0 * scale, bounds.get_center().y)
	_check(chart._node_at(hull_edge) == boss, "A2 the edge of the flagship hull hits beyond its centre ring")
	var sound := SoundProbe.new()
	root.add_child(sound)
	Kit.sound = sound
	chart._queued_jump = true
	chart._queued_id = first
	_motion(center)
	var preview := chart._hot
	await _frames()
	_check(preview == second and ui.picked == first and chart._queued_jump and is_instance_valid(row),
		"A4 hover previews the stop without changing the pick, queued jump or rail")
	_click(marker)
	await _frames(8)
	_check(ui.picked == second and not chart._queued_jump and "ui_click" in sound.cues, "A4 one map click picks the route with a click cue")
	orders = ui._rail_host.find_child("OrdersScroll", true, false)
	fleet = ui._rail_host.find_child("FleetScroll", true, false)
	_check(orders.scroll_vertical == orders_at and fleet.scroll_vertical == fleet_at, "A4 rebuilding for a new pick keeps both scroll positions")
	Kit.sound = null
	sound.queue_free()
	chart.grab_focus()
	for i in chart._kb_order.size():
		await _key(KEY_RIGHT)
		if chart._hot != "" and chart._hot not in chart._avail(): break
	_check(chart._hot_by_key and chart._hot not in chart._avail(), "A5 arrows reach a distant stop")
	for key in [KEY_ENTER, KEY_SPACE]:
		await _key(key)
		_check(not chart._flying, "A5 %s never flies to a different stop during keyboard inspection" % OS.get_keycode_string(key))
		chart._flying = false
	await _key(KEY_1)
	await _key(KEY_SPACE)
	_check(chart._flying and chart._flight_id == first, "A5 a number key picks a next jump and Space confirms that stop")
	chart._flying = false   # Leave the run on the same map for the remaining input checks.

func _covers() -> void:
	var rail_point := Vector2(12, 500)
	var map_point := Vector2(1280, 550)
	var zoom := chart._uz_t
	var pan := chart._pan_t
	_wheel(rail_point, MOUSE_BUTTON_WHEEL_UP)
	_button(rail_point, MOUSE_BUTTON_RIGHT, true)
	_motion(rail_point + Vector2(60, 40), MOUSE_BUTTON_MASK_RIGHT)
	_button(rail_point, MOUSE_BUTTON_RIGHT, false)
	_check(chart._uz_t == zoom and chart._pan_t == pan and not chart._drag, "A6 the Orders Sheet blocks chart wheel and drag")
	chart._uz_t = 0.75
	_click(rail_point, true)
	_check(chart._uz_t == 0.75, "A6 double-clicking the Orders Sheet cannot reset the chart")
	chart._uz_t = zoom
	var tf := chart.cam.global_transform
	var pos: Vector3 = chart._nodes[ui.picked]["pos"]
	var before := chart._screen(pos)
	chart.cam.global_position += pos - chart.cam.project_position(Vector2(180, before.y), -chart.cam.to_local(pos).z)
	var behind := chart._screen(pos)
	chart.overlay.queue_redraw()
	await _frames()
	_check(behind.x > 0 and behind.x < ui.px(ui.COL_W) and chart._node_at(behind) == "", "A6 a stop behind the rail cannot be hit")
	chart.cam.global_transform = tf
	chart.overlay.queue_redraw()
	await _frames()
	for drawer in ["key", "dossier"]:
		ui._open_overlay(drawer)
		await _frames()
		var panel := ModalFocus.top_panel()
		focus_changes.clear()
		await _key(KEY_TAB)
		await _key(KEY_TAB, true)
		await _key(KEY_LEFT)
		_check(_focus_stays_in(panel), "A7 %s traps Tab, Shift+Tab and arrows" % drawer)
		_motion(map_point)
		_wheel(map_point, MOUSE_BUTTON_WHEEL_DOWN)
		_button(map_point, MOUSE_BUTTON_RIGHT, true)
		_button(map_point, MOUSE_BUTTON_RIGHT, false)
		_check(ui._overlay == drawer, "A7 %s stays open on shade wheel and right-click" % drawer)
		var held := InputEventKey.new()
		held.physical_keycode = KEY_D
		held.pressed = true
		Input.parse_input_event(held)
		await _frames()
		pan = chart._pan_t
		chart._pan_keyboard(0.1)
		held.pressed = false
		Input.parse_input_event(held)
		_check(chart._pan_t == pan, "A7 %s blocks held WASD pan" % drawer)
		_click(map_point)
		await _frames()
		_check(ui._overlay == "", "A7 %s closes on a left click outside" % drawer)
	c.show_modal("retreat", {}, [["c3retreatNo", "", 1], ["c3retreatYes", "", 1]])
	zoom = chart._uz_t
	_wheel(map_point, MOUSE_BUTTON_WHEEL_UP)
	_check(chart._uz_t == zoom, "B1 a campaign modal blocks map input even before its shade draws")
	await _frames()
	var dialog := ModalFocus.top_panel()
	focus_changes.clear()
	for key in [KEY_TAB, KEY_TAB, KEY_DOWN, KEY_UP]: await _key(key)
	await _key(KEY_TAB, true)
	_check(_focus_stays_in(dialog), "B1 Tab, Shift+Tab and arrows stay inside the campaign modal")
	c.close_modal()
	await _frames()
	_check(root.gui_get_focus_owner() == chart, "B1 closing the modal returns the keyboard to the chart")

func _drag_cancellation() -> void:
	var at := Vector2(1200, 500)
	for gate in ["loading", "backdrop"]:
		var which := MOUSE_BUTTON_RIGHT if gate == "loading" else MOUSE_BUTTON_MIDDLE
		_motion(at)
		_button(at, which, true)
		_check(chart._drag, "A8 mouse button %d starts a chart drag" % which)
		chart.set(gate, true)
		_check(not chart._drag, "A8 %s cancels a held drag immediately" % gate)
		_button(at, which, false)
		chart.set(gate, false)
		var pan := chart._pan_t
		_motion(at + Vector2(35, 25))
		_check(not chart._drag and chart._pan_t == pan, "A8 releasing during %s leaves no drag on return" % gate)

func _double_click(first: String, second: String) -> void:
	ui.pick_route(first)
	await _frames()
	var bounds := _route(2).get_global_rect()
	var at := Vector2(bounds.get_center().x, bounds.position.y + 3.0)
	_click(at)
	await _frames()
	_check(ui.picked == second and not chart._flying, "A3 the first click picks the collapsed row without flying")
	_check(not _route(2).get_global_rect().has_point(at), "A3 the expanded route moves away from the initial pointer")
	_click(at, true)
	_check(chart._flying and chart._flight_id == second, "A3 a second click at the original row position jumps to that route")
