extends SceneTree
# Renders the real HUD card widget in isolation. No campaign save or battle simulation.
const Teaching = preload("res://ui/campaign/campaign_tips.gd")
const Battle = preload("res://scenes/battle/battle.gd")
const Campaign = preload("res://campaign/campaign.gd")
const CampaignUI = preload("res://ui/campaign/campaign_ui.gd")
var folder := ""
var checks := 0
class CaptureErrors extends Logger:
	var n := 0
	func _log_error(_function: String, _file: String, _line: int, _code: String, rationale: String, _editor_notify: bool, error_type: int, _script_backtraces: Array) -> void:
		if error_type != Logger.ERROR_TYPE_WARNING and not rationale.contains("root certificate"): n += 1
var errors := CaptureErrors.new()

func _init() -> void:
	OS.add_logger(errors)
	_run.call_deferred()

func _frames() -> void:
	for i in 8: await process_frame
	await RenderingServer.frame_post_draw

func _shot(name: String) -> void:
	await _frames()
	var img := root.get_texture().get_image()
	if img.save_png(folder.path_join(name + ".png")) != OK: checks += 1

func _run() -> void:
	create_timer(30.0).timeout.connect(func(): quit(1))
	folder = OS.get_cmdline_user_args()[0]
	if not folder.replace("\\", "/").begins_with(ProjectSettings.globalize_path("res://..").simplify_path().replace("\\", "/")):
		quit(2); return
	DirAccess.make_dir_recursive_absolute(folder)
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_size(Vector2i(1920, 1080))
	root.size = Vector2i(1920, 1080)
	root.content_scale_size = Vector2i(1920, 1080)
	var bg := ColorRect.new(); bg.color = Color("#0f1626"); bg.set_anchors_preset(Control.PRESET_FULL_RECT); root.add_child(bg)
	var title := Label.new(); title.text = "Teaching card layout check - actual HUD widget, no battle assets"; title.position = Vector2(480, 950); title.add_theme_font_size_override("font_size", 22); root.add_child(title)
	if ResourceLoader.exists("res://gen/onboarding_before_hud.gd"):
		var before = load("res://gen/onboarding_before_hud.gd").new(); root.add_child(before)
		var old = JSON.parse_string(FileAccess.get_file_as_string("res://gen/onboarding_before_select.json"))
		before.show_tipcard(old[0], old[1], old[2])
		await _shot("before_select_1080")
		before.queue_free(); await process_frame
	var hud = Teaching.HUD.new(); root.add_child(hud)
	for card in Battle.TIPS:
		hud.show_tipcard(card[0], card[1], card[2])
		await _shot("battle_" + card[0] + "_1080")
		if hud.tipcard.get_global_rect().end.y > 940: checks += 1; printerr("Card is too tall: " + card[0])
	hud.queue_free(); await process_frame
	var t = Teaching.new(); root.add_child(t)
	Teaching.set_off(false)
	for card in Teaching.CARDS:
		t.screen = "map|capture"; t.shown_on_screen = false
		var f := FileAccess.open(Teaching.OPTS, FileAccess.WRITE); f.store_string('{"tips":{},"tipsOff":false}'); f.close()
		t.try_show(card[0]); await _shot("campaign_" + card[0] + "_1080")
		if t.hud.tipcard.get_global_rect().end.y > 940: checks += 1; printerr("Card is too tall: " + card[0])
		t._dismiss("capture", false)
	t.queue_free(); await process_frame
	# The map toggle is checked in its real campaign column. This checkout omits the battle art bundle.
	var c = Campaign.new(); c.load_tables(); c.fixed_clock = true
	c.JSM.rnd_seed(1234); c.titleScreen(); c.act("newRunScreen"); c.act("startRun"); c.act("pickAspect", c.W["aspOffer"][0]); c.close_modal(); c.mapScreen()
	var ui = CampaignUI.new(); root.add_child(ui); ui.use_3d_map = false; ui.bind(c)
	ui.teaching.disabled = true
	await _shot("campaign_map_toggle_1080")
	ui.queue_free(); await process_frame
	print("CARD VISUAL " + ("PASS" if checks == 0 and errors.n == 0 else "FAIL"))
	quit(0 if checks == 0 and errors.n == 0 else 1)
