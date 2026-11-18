extends SceneTree
# Issue 729: the Career screen's dim labels (RUNS, No service yet, Empty refit slot, the experience lines) are drawn in
# the screen's BONE3 over its backing. RULEBOOK 9.4 needs 4.5 to 1. This check builds the real Career screen from a
# fresh default profile at 1080 and 1440, finds every label drawn in BONE3, reads the card behind it, and measures the
# contrast with the same luminance and contrast functions as ledger_readability_test.gd. CR4's transparent layout
# wrappers are composited over the opaque screen, rather than treating their unused RGB as a visible white card.
# Run: godot --headless --path godot --script res://ui/career/test/career_readability_test.gd

const Screen = preload("res://ui/career/career_screen.gd")
const StoryScript = preload("res://story/story.gd")
const Career = preload("res://story/career.gd")

var fails := 0


func check(ok: bool, what: String) -> void:
	print(("PASS: " if ok else "FAIL: ") + what)
	if not ok:
		fails += 1


static func lum(c: Color) -> float:
	var f := func(v: float) -> float: return v / 12.92 if v <= 0.03928 else pow((v + 0.055) / 1.055, 2.4)
	return 0.2126 * f.call(c.r) + 0.7152 * f.call(c.g) + 0.0722 * f.call(c.b)


static func contrast(a: Color, b: Color) -> float:
	var la := lum(a)
	var lb := lum(b)
	return (maxf(la, lb) + 0.05) / (minf(la, lb) + 0.05)


func _initialize() -> void:
	_run.call_deferred()


func labels(n: Node, out: Array) -> void:
	if n is CanvasItem and not (n as CanvasItem).is_visible_in_tree():
		return
	if n is Label:
		out.append(n)
	for c in n.get_children():
		labels(c, out)


# Composite every ancestor backing, outermost first, including transparent layout wrappers.
func card_bg(l: Control, bg: Color) -> Color:
	var p := l.get_parent()
	var layers: Array[Color] = []
	while p != null:
		if p is PanelContainer:
			var sb := (p as PanelContainer).get_theme_stylebox("panel")
			if sb is StyleBoxFlat:
				layers.push_front((sb as StyleBoxFlat).bg_color)
		p = p.get_parent()
	for layer in layers:
		bg = bg.blend(layer)
	return bg


func screen_bg(scr: Node) -> Color:
	for c in scr.get_children():
		if c is ColorRect:
			return (c as ColorRect).color
	return Color(0, 0, 0)


func _run() -> void:
	for sz in [Vector2i(1920, 1080), Vector2i(2560, 1440)]:
		root.size = sz
		root.content_scale_size = Vector2i.ZERO
		await process_frame
		var S = StoryScript.new()
		root.add_child(S)
		await process_frame
		S.career.P = Career.default_profile()
		var scr = S.open_career()
		await process_frame
		await process_frame
		var tag := "%dx%d" % [sz.x, sz.y]
		check(scr != null, "%s: the Career screen opens" % tag)
		if scr == null:
			S.queue_free()
			await process_frame
			continue
		var bg := screen_bg(scr)
		var dim := 0
		var worst := 99.0
		var worst_t := ""
		var runs := false
		var runs_c := 0.0
		for t in ["records", "medals", "titles", "history", "chronicle"]:
			scr.set_tab(t)
			await process_frame
			var ls: Array = []
			labels(scr, ls)
			for l in ls:
				var col: Color = (l as Label).get_theme_color("font_color")
				if not col.is_equal_approx(Screen.BONE3):
					continue
				dim += 1
				var card := card_bg(l, bg)
				var c := contrast(col, card)
				if c < worst:
					worst = c
					worst_t = "%s on #%s" % [str((l as Label).text).substr(0, 30), card.to_html(false)]
				if c < 4.5:
					check(false, "%s: '%s' is %.2f to 1 on its card #%s (needs 4.5)" % [tag, str((l as Label).text).substr(0, 30), c, card.to_html(false)])
				if str((l as Label).text) == "RUNS":
					runs = true
					runs_c = c
		check(dim > 0, "%s: the screen draws its dim labels in BONE3 (%d found)" % [tag, dim])
		check(worst >= 4.5, "%s: every dim BONE3 label is %.2f to 1 or better on its card (%s)" % [tag, worst, worst_t])
		check(runs, "%s: the RUNS stat label is drawn in BONE3" % tag)
		check(runs_c >= 4.5, "%s: RUNS is %.2f to 1 on its card (needs 4.5)" % [tag, runs_c])
		check(contrast(Screen.BONE3, Screen.IRON) >= 4.5, "%s: BONE3 over the card IRON is %.2f to 1" % [tag, contrast(Screen.BONE3, Screen.IRON)])
		check(contrast(Screen.BONE3, Screen.INK) >= 4.5, "%s: BONE3 over the INK panel is %.2f to 1" % [tag, contrast(Screen.BONE3, Screen.INK)])
		check(contrast(Screen.BONE3, bg) >= 4.5, "%s: BONE3 over the screen behind the cards is %.2f to 1" % [tag, contrast(Screen.BONE3, bg)])
		scr.queue_free()
		S.queue_free()
		await process_frame
	print("career readability: %d checks failed" % fails)
	quit(1 if fails > 0 else 0)
