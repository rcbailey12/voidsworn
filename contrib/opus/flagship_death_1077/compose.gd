extends SceneTree
## Issue 1077. The side-by-side clip: today's death (left) against the strain prototype (right), from capture.gd's
## frames. Run with --write-movie <file>.avi --fixed-fps 30 --resolution 1920x600 (run.bat). Arguments after --:
## the scratch directory, the radius, the commit label. One drawn frame per captured frame pair.

var left: TextureRect
var right: TextureRect
var beat: Label
var n := 0
var i := 0
var dir_off: String
var dir_on: String
var chapters: Array = []
var page: Control


func _initialize() -> void:
	# the project opens maximized, so on the PC the window is not the movie's size and the page came out scaled and clipped
	# (half size at 1236bbc3, three quarters at 66e55036). The page is a 1920x600 panel, scaled each frame to fill the
	# window's width from its top left; the movie then holds it across its full width (the review copy is cropped to it)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	page = Control.new()
	page.size = Vector2(1920, 600)
	root.add_child(page)
	_fit()
	var args := OS.get_cmdline_user_args()
	var scratch: String = args[0]
	var radius: String = args[1]
	var commit: String = args[2] if args.size() > 2 else ""
	dir_off = scratch.path_join("off_c" + radius)
	dir_on = scratch.path_join("strain_c" + radius)
	var tl = JSON.parse_string(FileAccess.get_file_as_string(dir_on.path_join("timeline.json")))
	var tl_off = JSON.parse_string(FileAccess.get_file_as_string(dir_off.path_join("timeline.json")))
	n = mini(int(tl.get("frames", 0)), int(tl_off.get("frames", 0))) if tl is Dictionary and tl_off is Dictionary else 0
	if tl is Dictionary: chapters = tl.get("chapters", [])
	var bg := ColorRect.new()
	bg.color = Color(0.02, 0.025, 0.035)
	bg.size = Vector2(1920, 600)
	page.add_child(bg)
	left = _panel(Vector2(0, 60))
	right = _panel(Vector2(960, 60))
	_label("A16 (C19_51, Ashfall battle-barge)  /  camera %s  /  issue 1077 prototype, not installed" % radius, Vector2(14, 6), 22, Color(0.92, 0.92, 0.9))
	_label("commit %s  /  stage: prototype clip (cloud code, PC render)" % commit.substr(0, 12), Vector2(1906, 10), 16, Color(0.6, 0.62, 0.66), true)
	_label("TODAY (death_story off)", Vector2(14, 34), 18, Color(0.75, 0.8, 0.9))
	_label("STRAIN PROTOTYPE (death_story = strain)", Vector2(974, 34), 18, Color(1.0, 0.7, 0.4))
	beat = _label("", Vector2(1906, 34), 18, Color(1.0, 0.85, 0.55), true)


func _panel(pos: Vector2) -> TextureRect:
	var t := TextureRect.new()
	t.position = pos
	t.size = Vector2(960, 540)
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_SCALE
	page.add_child(t)
	return t


func _label(text: String, pos: Vector2, size: int, col: Color, right_align := false) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	if right_align:
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		l.size = Vector2(900, 24)
		l.position = pos - Vector2(900, 0)
	else:
		l.position = pos
	page.add_child(l)
	return l


func _fit() -> void:
	var vis: Rect2 = root.get_visible_rect()
	page.position = vis.position
	page.scale = Vector2.ONE * (vis.size.x / 1920.0)


func _process(_dt: float) -> bool:
	_fit()
	if i >= n:
		print("COMPOSE1077 frames=", n)
		return true
	var a := Image.load_from_file(dir_off.path_join("frame_%04d.jpg" % i))
	var b := Image.load_from_file(dir_on.path_join("frame_%04d.jpg" % i))
	if a != null: left.texture = ImageTexture.create_from_image(a)
	if b != null: right.texture = ImageTexture.create_from_image(b)
	var name := ""
	for c in chapters:
		if int(c["frame"]) <= i: name = str(c["name"])
	beat.text = {"stage4": "stage 4 damage", "fatal": "fatal torpedo", "tell": "the tell (strain on the right)", "split": "the split",
		"wreck": "the wreck", "cold": "cold"}.get(name, name)
	i += 1
	return false
