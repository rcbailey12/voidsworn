extends Control
## KEEL: two corner clusters, a decision shelf, and a floating battle log.
## layout() builds the exact words, art, and hit regions that _draw() uses.

signal act(name: String, arg: Variant)
signal hover_tip(bb: String, at: Vector2)

const GS := preload("res://ui/theme/glass_shell.gd")
const Brand := preload("res://ui/battle/brand.gd")
const Campaign := preload("res://campaign/campaign.gd")
const Icons := preload("res://ui/battle/icons/keel_icons.gd")
const EMBER := GS.MAP_EMBER
const TEXT := GS.TEXT
const TEXT2 := GS.TEXT2
const TEXT3 := GS.TEXT3
const NEM := GS.NEM
const GLACIER := GS.GLACIER
const DMG := GS.HULL_LOW
const SHELF_H := 248.0
const FLEET_H := 49.0
const FLEET_SLOT_W := 84.0
const FLEET_PAGING_W := 59.0
const COMPACT_MARGIN := 20.0
const MARGIN := 40.0

var k := 1.0
var top := {}
var info := {}
var nem := {}
var rows: Array = []
var ship := {}
var target := {}
var card := {}
var cmd := {}
var ask := {}
var log_lines: Array = []
var log_enabled := true
var log_collapsed := false
var phase := {}
var retreat := {}
var detail_bb := ""

var items: Array[Dictionary] = []
var marks: Array[Dictionary] = []
var hits: Array[Dictionary] = []
var sheet_r := Rect2()
var log_r := Rect2()
var blockers: Array[Rect2] = []
var fleet_fit := {}
var fleet_page := 0
var _fleet_id := ""
var _dirty := true
var _hover := -1

var f_name: Font
var f_body: Font
var f_med: Font
var f_num: Font


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	resized.connect(mark)
	mouse_exited.connect(func() -> void:
		_hover = -1
		queue_redraw()
		hover_tip.emit("", Vector2.ZERO))


func mark() -> void:
	_dirty = true
	queue_redraw()


func px(v: float) -> float:
	return roundf(v * k)


static var _tag_re: RegEx = null   # not GPU: compiled text patterns, built once (issue 1437 item 9)
static var _key_re: RegEx = null   # not GPU: a compiled text pattern


static func plain(bb: String) -> String:
	if _tag_re == null:
		_tag_re = RegEx.create_from_string("\\[[^\\]]*\\]")
	return _tag_re.sub(bb, "", true).strip_edges()


func _width(s: String, f: Font, fs: float) -> float:
	return f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, int(px(fs))).x


func _text_h(f: Font, fs: float) -> float:
	return f.get_height(int(px(fs)))


func _trim(s: String, f: Font, fs: float, w: float) -> String:
	if _width(s, f, fs) <= w:
		return s
	var text := s
	while not text.is_empty() and _width(text + "...", f, fs) > w:
		text = text.left(-1).strip_edges()
	return text + "..." if not text.is_empty() else ""


func _text(x: float, y: float, s: String, f: Font, fs: float, col: Color, role := "", edge := false) -> float:
	if s == "":
		return 0.0
	var n := int(px(fs))
	var w := _width(s, f, fs)
	var face := "BigShoulders" if f == f_name else ("AzeretMono" if f == f_num else "Barlow")
	items.append({"t": s, "x": x, "y": y, "w": w, "h": _text_h(f, fs), "asc": f.get_ascent(n), "size": fs,
		"f": f, "face": face, "col": col, "role": role, "edge": edge})
	return w


func _right(x: float, y: float, s: String, f: Font, fs: float, col: Color, role := "") -> float:
	return _text(x - _width(s, f, fs), y, s, f, fs, col, role)


func _lines(s: String, f: Font, fs: float, w: float) -> PackedStringArray:
	var result := PackedStringArray()
	var line := ""
	for word in s.split(" ", false):
		var next := (line + " " + word).strip_edges()
		if not line.is_empty() and _width(next, f, fs) > w:
			result.append(line)
			line = word
		else:
			line = next
	if line != "":
		result.append(line)
	return result


func _paragraph(x: float, y: float, s: String, w: float, count: int, col := TEXT2) -> float:
	var lines := _lines(s, f_body, 17, w)
	for i in mini(count, lines.size()):
		var line := lines[i] + ("..." if i == count - 1 and lines.size() > count else "")
		_text(x, y, _trim(line, f_body, 17, w), f_body, 17, col)
		y += ceilf(_text_h(f_body, 17)) + px(2)
	return y


func item_rect(it: Dictionary) -> Rect2:
	return Rect2(it.x, it.y, it.w, it.h)


func _name(r: Rect2, s: String, fs: float, col := TEXT) -> void:
	var u := s.to_upper()
	while fs > 28 and _width(u, f_name, fs) > r.size.x:
		fs -= 1
	_text(r.position.x, r.position.y, _trim(u, f_name, fs, r.size.x), f_name, fs, col, "name")


func _rect(r: Rect2, col: Color) -> void:
	marks.append({"k": "rect", "r": r, "col": col})


func _line(a: Vector2, b: Vector2, col: Color, w := 1.0) -> void:
	marks.append({"k": "line", "a": a, "b": b, "col": col, "w": maxf(1, px(w))})


func _veil(r: Rect2, alpha: float, feather: Vector4) -> void:
	marks.append({"k": "veil", "r": r, "a": alpha, "f": feather})


func _glyph(id: String, p: Vector2, s: float, col := TEXT, action := false) -> void:
	marks.append({"k": "glyph", "id": id, "r": Rect2(p, Vector2.ONE * px(s)), "col": col, "action": action})


func _silhouette(code: String, r: Rect2, col: Color, health: float) -> void:
	if code != "":
		marks.append({"k": "ship", "id": code, "r": r, "col": col, "health": health})


func _hit(r: Rect2, name: String, arg: Variant = null, tip := "") -> void:
	if name != "" or tip != "":
		hits.append({"r": r, "act": name, "arg": arg, "tip": tip})


func mine_turn() -> bool:
	return str(top.get("turn", "")).begins_with("Your turn") and not enemy_turn()


func enemy_turn() -> bool:
	return phase.get("kind", "") == "enemy" or top.get("turn", "") == "Enemy turn"


func _is_nem(nm: String) -> bool:
	return nm != "" and str(nem.get("name", "")).ends_with(nm)


func _button_data(id: String) -> Dictionary:
	for b in card.get("buttons", []):
		if b.get("act") == id:
			return b
	return {}


static func _without_key(s: String) -> String:
	if _key_re == null:
		_key_re = RegEx.create_from_string("\\s+\\([A-Za-z0-9]+\\)$")
	return _key_re.sub(s, "")


func _action() -> Dictionary:
	if not mine_turn() or not ask.is_empty():
		return {}
	var b := _button_data("confirm")
	if bool(b.get("on", false)):
		var label := _without_key(str(b.get("text", "")))
		var gun := str(target.get("gun", ""))
		var glyph := "move" if label.begins_with("Move") else "focus"
		if label.begins_with("Fire") and int(target.get("bearing", 0)) == 1 and gun != "":
			label = "Fire the " + gun
			glyph = Icons.weapon(str(target.get("kind", "")))
		return {"label": label, "act": "confirm", "glyph": glyph, "tip": str(card.get("hint", "")) + "\nEsc cancels."}
	b = _button_data("end")
	if bool(b.get("on", false)):
		return {"label": "End ship", "act": "end", "glyph": "end", "tip": str(b.get("tip", ""))}
	b = _button_data("next")
	if bool(b.get("on", false)):
		return {"label": "Next ship", "act": "next", "glyph": "next", "tip": str(b.get("tip", "Switch to another ready ship."))}
	if card.is_empty() and bool(top.get("end_on", false)) and top.get("end_text", "") == "End turn":
		return {"label": "End turn", "act": "end", "glyph": "end", "tip": "End your turn; the enemy moves."}
	return {}


func ensure_layout() -> void:
	if _dirty:
		layout()


func layout() -> void:
	if f_name == null:
		var faces := Brand.keel_faces()
		f_name = faces[0]; f_body = faces[1]; f_med = faces[2]; f_num = faces[3]
	items.clear()
	marks.clear()
	hits.clear()
	blockers.clear()
	# A startup or headless control can be too small even for the compact shelf.
	var vs := size
	var min_width := 2 * px(COMPACT_MARGIN) + px(FLEET_SLOT_W) + px(FLEET_PAGING_W)
	if vs.x < min_width or vs.y < px(SHELF_H):
		vs = Vector2(1920, 1080) * k
	var compact := vs.x < px(1510)
	var pad := px(COMPACT_MARGIN if compact else MARGIN)
	var top_y := px(32 if not compact else 16)
	var usable := vs.x - 2 * pad
	var turn_w := minf(px(435), usable * 0.43)
	var foe_w := minf(px(470), usable * 0.49)
	_turn_block(Rect2(pad, top_y, turn_w, 0))
	_top_right(Rect2(vs.x - pad - foe_w, top_y, foe_w, 0))
	var shelf_y := vs.y - px(SHELF_H)
	sheet_r = Rect2(0, shelf_y, vs.x, vs.y - shelf_y)
	_veil(sheet_r, Brand.KEEL_VEIL, Vector4(0, px(17), 0, 0))
	blockers.append(sheet_r)
	var y := shelf_y + px(28)
	var gap := px(15 if compact else 22)
	var room := usable - gap * 3
	var ship_w := room * (0.245 if compact else 0.325)
	var gun_w := room * 0.248
	var target_w := room * (0.235 if compact else 0.187)
	var action_w := room - ship_w - gun_w - target_w
	var gun_x := pad + ship_w + gap
	var target_x := gun_x + gun_w + gap
	var action_x := target_x + target_w + gap
	var foot := vs.y - px(FLEET_H)
	_ship_block(Rect2(pad, y, ship_w, foot - y), compact)
	var after_guns := _guns(gun_x, y, gun_w)
	var after_odds := _target_block(target_x, y, target_w, compact)
	_status(gun_x, maxf(after_guns, after_odds) + px(3), gun_w + gap + target_w, foot)
	var primary := _action()
	if not primary.is_empty():
		_action_box(Rect2(action_x, y, action_w, px(56)), primary)
	if mine_turn() and ask.is_empty():
		_orders(action_x, y + px(62), action_w, foot, primary, compact)
	_fleet(pad, foot, usable)
	_log(vs.x - pad, shelf_y - px(12), minf(px(540), usable * 0.58))
	_hover = hit_at(get_local_mouse_position()) if is_inside_tree() else -1
	_dirty = false


func _turn_block(r: Rect2) -> void:
	var x := r.position.x
	var y := r.position.y
	var w := r.size.x
	var patch := marks.size()
	var first_word := items.size()
	_veil(Rect2(), Brand.KEEL_VEIL, Vector4(px(16), px(12), px(23), px(20)))
	_text(x, y, "Round %d" % int(top.get("round", 1)), f_body, 18, TEXT2)
	y += px(26)
	var turn := str(top.get("turn", ""))
	if enemy_turn():
		turn = "Enemy turn"
	elif mine_turn():
		turn = "Your turn"
	var tw := _text(x, y, turn, f_med, 23, EMBER if mine_turn() else TEXT)
	var cx := x + tw + px(18)
	var count := ""
	var tip := ""
	if mine_turn():
		var live := 0
		var waiting := PackedStringArray()
		var threatened := PackedStringArray()
		for row in rows:
			if row.get("status") == "Lost":
				continue
			live += 1
			if row.get("status") in ["Ready", "Up", "Acting"]:
				waiting.append(str(row.get("name", "")))
				if int(row.get("danger", 0)) > 0:
					threatened.append(waiting[-1])
		if live > 0:
			count = "%d of %d ships to act" % [waiting.size(), live]
			tip = "Still to act: %s. Tab jumps to the next." % ", ".join(waiting) if not waiting.is_empty() else "Every ship has acted."
			if not threatened.is_empty():
				tip += "\nThe enemy can reach these first: %s." % ", ".join(threatened)
	elif enemy_turn():
		var seg := plain(str(phase.get("text", ""))).split("  %s  " % char(183))
		if seg.size() > 1:
			count = seg[2] if seg.size() >= 4 else seg[1]
			tip = count + (" (%s)" % seg[3] if seg.size() >= 5 else "") + "\nEnter or Space hurries the enemy's turn."
	var cw := _text(cx, y + px(4), _trim(count, f_body, 17, x + w - cx), f_body, 17, TEXT2)
	if cw > 0:
		_hit(Rect2(cx, y, cw, px(28)), "", null, tip)
	y += px(34)
	if enemy_turn() and float(phase.get("p", -1)) >= 0.0:
		_line(Vector2(x, y), Vector2(x + w, y), GS.SHEET_HAIR, 2)
		_line(Vector2(x, y), Vector2(x + w * clampf(float(phase.p), 0, 1), y), TEXT2, 2)
		y += px(7)
	y = _paragraph(x, y, plain(str(top.get("objective", ""))), w, 2)
	var bounds := Rect2(x, r.position.y, w, y - r.position.y)
	if not enemy_turn() or float(phase.get("p", -1)) < 0.0:
		bounds = _fit_corner(bounds, first_word)
	marks[patch].r = Rect2(bounds.position - Vector2(px(16), px(12)), bounds.size + Vector2(px(39), px(32)))
	blockers.append(bounds)
	if not ask.is_empty():
		_prompt(x, y + px(22), w)


func _prompt(x: float, y0: float, w: float) -> void:
	var patch := marks.size()
	_veil(Rect2(), Brand.KEEL_VEIL, Vector4(px(12), px(12), px(16), px(14)))
	_name(Rect2(x, y0, w, px(36)), str(ask.get("n", "")), 30)
	var y := _paragraph(x, y0 + px(38), str(ask.get("q", "")), w, 4, TEXT) + px(7)
	var i := 0
	for o in ask.get("opts", []):
		i += 1
		var b := Rect2(x, y, w, px(32))
		_text(x, y + px(4), str(i), f_num, 18, EMBER)
		_text(x + px(32), y + px(3), _trim(str(o.get("n", "")), f_med, 19, w - px(32)), f_med, 19, TEXT)
		_hit(b, "ask", str(o.get("id", "")), str(o.get("d", "")))
		y += px(34)
	var bounds := Rect2(x, y0, w, y - y0)
	marks[patch].r = Rect2(bounds.position - Vector2(px(12), px(12)), bounds.size + Vector2(px(28), px(26)))
	blockers.append(bounds)


func _top_right(r: Rect2) -> void:
	var xr := r.end.x
	var y := r.position.y
	var patch := marks.size()
	var first_word := items.size()
	_veil(Rect2(), Brand.KEEL_VEIL, Vector4(px(25), px(12), px(14), px(20)))
	var mw := _right(xr, y, "Menu", f_med, 19, TEXT2)
	_hit(Rect2(xr - mw - px(6), y - px(5), mw + px(12), px(30)), "menu", null, "Settings, Controls, view options, retreat and quit.")
	if bool(retreat.get("on", false)):
		var rx := xr - mw - px(24)
		var disabled := bool(retreat.get("off", false))
		var rw := _right(rx, y, "Retreat", f_med, 19, TEXT3 if disabled else TEXT, "join" if disabled else "")
		_hit(Rect2(rx - rw - px(4), y - px(5), rw + px(8), px(30)), "" if disabled else "retreat", null, "Pull the fleet out of this battle.")
	y += px(36)
	var hw := 0.0
	if int(info.get("heat", -1)) >= 0:
		hw = _right(xr, y, str(clampi(int(info.heat), 0, 9)), f_num, 18, TEXT)
		hw += px(8) + _right(xr - hw - px(8), y, "Threat", f_body, 18, TEXT3, "join")
		_hit(Rect2(xr - hw - px(4), y - px(3), hw + px(8), px(27)), "", null, str(info.get("heat_tip", "Threat: the run's difficulty level, up to 9.")))
		hw += px(20)
	var faction := str(info.get("foe_name", ""))
	if faction != "":
		var n := int(info.get("foe_ships", 0))
		_right(xr - hw, y, _trim("%s, %d ship%s" % [faction, n, "" if n == 1 else "s"], f_med, 19, r.size.x - hw), f_med, 19, TEXT)
		y += px(30)
	if not nem.is_empty():
		var dw := _right(xr, y, "Dossier", f_body, 17, TEXT3, "join") + px(13)
		var nw := _width("Nemesis", f_med, 19) + px(11)
		var nm := str(nem.get("name", ""))
		if str(nem.get("state", "")) != "":
			nm += " (%s)" % str(nem.state)
		var used := _right(xr - dw, y, _trim(nm, f_med, 19, r.size.x - dw - nw), f_med, 19, TEXT)
		_right(xr - dw - used - px(11), y, "Nemesis", f_med, 19, NEM)
		_hit(Rect2(xr - dw - used - nw, y - px(3), dw + used + nw + px(4), px(28)), "", null, _nem_tip())
		y += px(24)
	var bounds := _fit_corner(Rect2(r.position, Vector2(r.size.x, y - r.position.y)), first_word)
	marks[patch].r = Rect2(bounds.position - Vector2(px(25), px(12)), bounds.size + Vector2(px(39), px(32)))
	blockers.append(bounds)


func _fit_corner(r: Rect2, first_word: int) -> Rect2:
	var left := r.end.x
	var right := r.position.x
	for i in range(first_word, items.size()):
		var word := item_rect(items[i])
		left = minf(left, word.position.x)
		right = maxf(right, word.end.x)
	return Rect2(left, r.position.y, right - left, r.size.y)


func _nem_tip() -> String:
	var s := "[b]%s[/b]" % str(nem.get("name", ""))
	if str(nem.get("ship", "")) != "":
		s += "\nAboard the %s." % str(nem.ship)
	if str(nem.get("flee", "")) != "":
		s += " " + str(nem.flee)
	for a in nem.get("adapted", []):
		s += "\nAdapted: %s%s" % [str(a[1]).trim_suffix("."), (" (%s)." % str(a[2])) if str(a[2]) != "" else "."]
	var weak: Array = nem.get("weak", [])
	if weak.is_empty():
		s += "\nWeakness: not found yet."
	for w in weak:
		s += "\nWeakness: %s (%s)." % [str(w[1]).trim_suffix("."), str(w[0]).to_lower()]
	return s


func _ship_block(r: Rect2, compact: bool) -> void:
	var x := r.position.x
	var y := r.position.y
	if ship.is_empty():
		if mine_turn() and not card.is_empty():
			_paragraph(x, y + px(7), "Pick one of your ships.", r.size.x, 2, TEXT)
		return
	var nm := str(ship.get("name", ""))
	var left := r.size.x if compact else r.size.x * 0.52
	var bars_x := x if compact else x + left + px(14)
	var bars_w := r.end.x - bars_x
	_name(Rect2(x, y, left, px(41)), nm, 36, NEM if _is_nem(nm) else TEXT)
	var cls := str(ship.get("cls", ""))
	_text(x, y + px(43), _trim(cls, f_body, 18, left), f_body, 18, TEXT2)
	_hit(Rect2(x, y, left, px(65)), "", null, detail_bb)
	var mv: Array = ship.get("move", [])
	if ship.get("side") == "player" and mv.size() == 2:
		_glyph("move", Vector2(x, y + px(69)), 20, TEXT2)
		_text(x + px(28), y + px(67), "Move %d / %d" % [int(mv[0]), int(mv[1])], f_num, 17, TEXT2)
	var hp := float(ship.get("hp", 0))
	var mx := float(ship.get("maxHp", 1))
	var h := _ratio(hp, mx)
	var shape := Rect2(bars_x, y, bars_w, px(42)) if not compact else Rect2(x + left * 0.62, y + px(64), left * 0.38, px(27))
	_silhouette(str(ship.get("code", "")), shape, TEXT, h)
	if not compact:
		_hit(shape, "", null, detail_bb)
	var yy := y + px(95 if compact else 54)
	_integrity(bars_x, yy, bars_w, "Shield", float(ship.get("shp", 0)), float(ship.get("shMax", 0)), true, _routed_tag(ship.get("routed", [])))
	_integrity(bars_x, yy + px(43), bars_w, "Hull", hp, mx, false)
	_hit(Rect2(bars_x, yy, bars_w, px(82)), "", null, detail_bb)


# issue 1446: "starboard routed" for the KEEL shield readout (quad order prow, starboard, rear, port)
static func _routed_tag(sides) -> String:
	if not (sides is Array) or (sides as Array).is_empty():
		return ""
	var words := ["prow", "starboard", "rear", "port"]
	var names := PackedStringArray()
	for q in sides:
		names.append(words[int(q)])
	return "/".join(names) + " routed"


static func _ratio(value: float, cap: float) -> float:
	return clampf(value / cap, 0, 1) if cap > 0 else 0.0


func _integrity(x: float, y: float, w: float, label: String, value: float, cap: float, shield: bool, tag := "") -> void:
	var col := GLACIER if shield else (DMG if value < cap - 0.5 else TEXT)
	_glyph("shield" if shield else "hull", Vector2(x, y), 20, col)
	var lw := _text(x + px(27), y, label, f_med, 17, TEXT2)
	var numbers := "%s / %s" % [Campaign.hull_text(value), Campaign.hull_text(cap)] if cap > 0 else "None"
	_right(x + w, y, numbers, f_num, 17, col, "shield" if shield else "figure")
	if tag != "":
		# issue 1446 (R246): the routed side, in the shield colour, between the label and the numbers
		var room := w - px(27) - lw - px(8) - _width(numbers, f_num, 17) - px(8)
		var shown := _trim(tag, f_med, 15, room)
		if room > px(24) and shown != "":
			var tx := x + px(27) + lw + px(8)
			_text(tx, y + px(2), shown, f_med, 15, GLACIER, "shield")
	_bar(Rect2(x, y + px(24), w, px(9)), _ratio(value, cap), GLACIER if shield else TEXT, GS.SHIELD_TRACK if shield else Color(DMG, 0.25))


func _bar(r: Rect2, f: float, col: Color, track: Color) -> void:
	_rect(r, track)
	if f > 0.0:
		_rect(Rect2(r.position, Vector2(r.size.x * f, r.size.y)), col)


static func keyword_tip(line: String) -> String:
	var out := PackedStringArray()
	var keywords := {
		"Braced": "Braced: the ship takes 40% less hull damage until its next turn. A braced ship does not turn or fire. A Sunward ship also covers one adjacent ally facing the same way.",
		"On fire": "On fire: its shields falter and it can no longer repair itself.",
		"focusing its fire": "Focus fire: the enemy fleet favors this ship when it picks targets.",
		"Fired": "Most ships cannot move after firing. Glasswright ships and ships with the Slip the Net protocol can keep some movement."}
	for kw in keywords:
		if line.contains(kw):
			out.append(keywords[kw])
	return "\n".join(out)


func _status(x: float, y: float, w: float, foot: float) -> void:
	var fl := plain(str(ship.get("flags", "")))
	var say := fl if fl != "" else plain(str(card.get("say", "")))
	if say == "" or y + px(23) > foot:
		return
	var def := keyword_tip(fl)
	if fl != "":
		var id := "focus" if "focusing" in fl else ("brace" if "Braced" in fl else "battery")
		_glyph(id, Vector2(x, y), 20, TEXT2)
		x += px(28)
		w -= px(28)
	var end := _paragraph(x, y, say, w, mini(2, int((foot - y) / (ceilf(_text_h(f_body, 17)) + px(2)))))
	_hit(Rect2(x, y, w, end - y), "", null, say + ("\n" + def if def != "" else ""))


func _guns(x: float, y: float, w: float) -> float:
	var weapons: Array = ship.get("weapons", [])
	var step := px(24 if weapons.size() > 4 else 36)
	var mine: bool = ship.get("side") == "player" and mine_turn() and ask.is_empty()
	for gun in weapons:
		var hit_v := int(gun.get("hit", -1))
		var why := str(gun.get("why", ""))
		var dist := int(gun.get("distance", -1))
		var max_dist := int(gun.get("range", 1))
		var active := bool(gun.get("armed", false))
		var col := TEXT if hit_v >= 0 or (dist < 0 and bool(gun.get("ready", false))) else TEXT2
		var result := "%d%%" % hit_v if hit_v >= 0 else ("Out" if dist > max_dist else ("Ready" if why in ["", "ready"] else ("CD %s" % why.get_slice(" ", 1) if why.begins_with("reloading ") else ("No shot" if dist >= 0 else why.capitalize()))))
		var rw := maxf(_width(result, f_num, 17), px(46))
		var band_w := clampf(w * 0.25, px(40), px(170))
		var band_x := x + w - rw - band_w - px(19)
		var arc_x := band_x - px(53)
		var cy := y + step * 0.5
		var ty := roundf(cy - _text_h(f_med, 17) * 0.5)
		_glyph(Icons.weapon(str(gun.get("kind", ""))), Vector2(x, cy - px(10)), 20, EMBER if active else col)
		var nm := str(gun.get("name", ""))
		_text(x + px(29), ty, _trim(nm, f_med, 17, arc_x - x - px(31)), f_med, 17, col)
		_glyph("arc", Vector2(arc_x, cy - px(10)), 20, col)
		_text(arc_x + px(22), ty, str(gun.get("arc", "")), f_num, 17, col)
		_range_band(band_x, cy, band_w, max_dist, dist, col, hit_v >= 0)
		_right(x + w, ty, result, f_num, 17, EMBER if hit_v >= 0 and int(gun.get("i", -1)) == int(target.get("gun_index", -2)) else col)
		var tip := nm + ": " + plain(str(gun.get("desc", "")))
		if dist >= 0:
			tip += "\nTarget %d hexes away%s." % [dist, "" if hit_v >= 0 or why == "" else ": " + why]
		if int(gun.get("dmg", -1)) >= 0:
			tip += "\nExpected about %d damage at %d%% to hit." % [int(gun.dmg), hit_v]
		if str(gun.get("cost", "")) != "":
			tip += "\n" + ("Free: it can fire every round." if gun.cost == "free" else "Cooldown: %s rounds before it fires again." % str(gun.cost).trim_prefix("CD "))
		if str(gun.get("arc_tip", "")) != "":
			tip += "\n" + str(gun.arc_tip)
		var wi := int(gun.get("i", 0))
		if mine:
			tip += "\nClick or press %d to fire this gun alone%s." % [wi + 1, " (armed now)" if active else ""]
		_hit(Rect2(x, y, w, step), "arm" if mine else "", wi, tip)
		y += step
	return y


func _range_band(x: float, y: float, w: float, cap: int, dist: int, col: Color, can_fire: bool) -> void:
	_line(Vector2(x, y), Vector2(x + w, y), col)
	for xx in [x, x + w]:
		_line(Vector2(xx, y - px(4)), Vector2(xx, y + px(4)), col)
	if dist < 0:
		return
	var dx := x + w * clampf(float(dist - 1) / maxf(1, cap - 1), 0, 1)
	if dist > cap:
		dx = x + w + px(9)
	marks.append({"k": "diamond", "p": Vector2(dx, y), "s": px(5), "col": EMBER if can_fire else col})


func _target_block(x: float, y: float, w: float, compact: bool) -> float:
	if target.is_empty():
		return y
	var nm := str(target.get("name", ""))
	var col := NEM if bool(target.get("nem", false)) or _is_nem(nm) else TEXT
	_text(x, y, "Target", f_body, 17, TEXT3, "join")
	_name(Rect2(x, y + px(22), w, px(33)), nm, 30, col)
	_hit(Rect2(x, y, w, px(54)), "", null, _target_tip())
	var bearing := int(target.get("bearing", 0))
	if bearing <= 0:
		return _paragraph(x, y + px(61), plain(str(target.get("line", ""))), w, 3)
	var yy := y + px(58)
	var ow := _text(x, yy, "%d%%" % int(target.get("hit", 0)), f_num, 34, EMBER, "focus")
	var shield := int(target.get("exp_shields", 0))
	var hull := int(target.get("exp_hull", 0))
	var summary := "About %d damage" % (shield + hull)
	if shield == 0:
		summary += ", all to hull"
	var wrap_hull := shield == 0 and _width(summary, f_num, 17) > w
	if wrap_hull:
		summary = summary.trim_suffix(", all to hull")
	var inline := not compact and ow + px(12) + _width(summary, f_num, 17) <= w
	_text(x + (ow + px(12) if inline else 0.0), yy + px(12 if inline else 41), _trim(summary, f_num, 17, w), f_num, 17, TEXT)
	var by := yy + px(41 if inline else 67)
	if shield > 0:
		_glyph("shield", Vector2(x, by), 20, GLACIER)
		var sw := _text(x + px(24), by, "%d to shields" % shield, f_num, 17, GLACIER, "shield")
		var hx := x + sw + px(35)
		var split := "%d to hull" % hull
		if hx + px(24) + _width(split, f_num, 17) > x + w:
			hx = x
			by += px(23)
		_glyph("hull", Vector2(hx, by), 20)
		_text(hx + px(24), by, split, f_num, 17, TEXT)
		by += px(23)
	else:
		if wrap_hull:
			_text(x, by, "All to hull", f_num, 17, TEXT)
			by += px(23)
		else:
			by = yy + px(68 if not inline else 40)
	var gun := str(target.get("gun", ""))
	var tip := "%d%% to hit%s." % [int(target.get("hit", 0)), " with " + gun if gun != "" else ""]
	if bearing > 1:
		tip += " Damage is for all %d bearing guns." % bearing
	_hit(Rect2(x, yy, w, by - yy), "", null, tip + "\n" + _target_tip())
	return by


func _target_tip() -> String:
	var hp := float(target.get("hp", 0))
	var s := "%s\nHull %s / %s" % [str(target.get("name", "")), Campaign.hull_text(hp), Campaign.hull_text(target.get("maxHp", 0))]
	var defenses := str(target.get("defenses", ""))
	if defenses != "":
		s += ", " + defenses
	s += "."
	if float(target.get("shMax", 0)) > 0.0:
		var sh: Array = target.get("sh", [0, 0, 0, 0])
		var parts := PackedStringArray()
		var words := ["prow", "starboard", "rear", "port"]
		var routed: Array = target.get("routed", [])
		for i in mini(sh.size(), 4):
			parts.append("%s %d%s" % [words[i], int(sh[i]), " (routed)" if i in routed else ""])
		s += "\nShield pool %d of %d. Sides catch: %s." % [int(target.get("shp", 0)), int(target.shMax), ", ".join(parts)]
		if bool(target.get("struck_routed", false)):
			s += "\nThis volley hits its %s side, where it routed power: that side catches more, but each hit drains the pool 30%% faster." % words[int(target.get("quad", 0))]
	if str(target.get("line", "")) != "":
		s += "\n" + plain(str(target.line))
	return s


func _action_box(r: Rect2, a: Dictionary) -> void:
	marks.append({"k": "action", "r": r})
	var fs := 32.0
	var lab := str(a.label).to_upper()
	while fs > 28 and _width(lab, f_name, fs) > r.size.x - px(64):
		fs -= 1
	lab = _trim(lab, f_name, fs, r.size.x - px(64))
	var start := roundf(r.get_center().x - (_width(lab, f_name, fs) + px(35)) * 0.5)
	_glyph(str(a.glyph), Vector2(start, r.get_center().y - px(12)), 24, EMBER, true)
	_text(start + px(35), roundf(r.get_center().y - _text_h(f_name, fs) * 0.5), lab, f_name, fs, EMBER, "action")
	_hit(r, a.act, null, str(a.tip))


func _orders(x: float, y: float, w: float, foot: float, primary: Dictionary, compact: bool) -> void:
	var orders: Array[Dictionary] = []
	var turn := {}
	var mode := str(primary.get("act", ""))
	if not card.is_empty():
		for o in ship.get("orders", []):
			var id := str(o.act)
			if id in ["rotl", "rotr"]:
				turn[id] = bool(o.get("on", false))
				continue
			if not bool(o.get("on", false)) and id in ["ram", "board"]:
				continue
			var original := str(o.get("text", ""))
			var label := _without_key(original)
			var key := str(o.get("ability", id))
			if key == "focus":
				label = "Focus fire"
			orders.append({"act": id, "arg": o.get("arg"), "on": o.get("on", false), "label": label,
				"tip": original + "\n" + str(o.get("tip", "")), "glyph": Icons.order(key),
				"active": bool(o.get("active", false)), "cooldown": int(o.get("cooldown", 0))})
	if not turn.is_empty():
		orders.insert(mini(2, orders.size()), {"act": "turn", "left": turn.get("rotl", false), "right": turn.get("rotr", false)})
	if bool(cmd.get("available", false)) or bool(cmd.get("ready", false)):
		var tip := "Your Admiral's Command, once per battle: %s." % str(cmd.get("label", "Command"))
		var details := str(cmd.get("tip", ""))
		if details != "": tip += "\n" + details
		if cmd.get("ready", false): tip += "\nPress the order twice to give it (click or use C)."
		orders.append({"act": "command", "label": str(cmd.get("label", "Command")), "on": bool(cmd.get("ready", false)), "glyph": Icons.order(str(cmd.get("id", "command"))),
			"tip": tip, "active": cmd.get("active", false)})
	for id in ["end", "undo", "next", "cancel"]:   # issue 1450: Undo move sits next to End ship
		var b := _button_data(id)
		if id != mode and bool(b.get("on", false)):
			orders.append({"act": id, "label": _without_key(str(b.text)), "on": true, "glyph": id, "tip": b.get("tip", "Cancel the current plan.")})
	if orders.is_empty():
		return
	var cols := 3 if not compact or w >= px(320) else 2
	# Dense order lists get a third column and smaller glyphs.
	var n_rows := int(ceilf(float(orders.size()) / cols))
	if n_rows > 4:
		cols = 3
		n_rows = int(ceilf(float(orders.size()) / cols))
	var dy := minf(px(53), floorf((foot - y - px(5)) / n_rows))
	var glyph_h := 32 if dy >= px(40) and w / cols >= px(110) else 20
	var cell_w := w / cols
	for i in orders.size():
		var r := Rect2(x + float(i % cols) * cell_w, y + floorf(float(i) / cols) * dy, cell_w, dy)
		var o := orders[i]
		if o.act == "turn":
			_turn_order(r, o)
		else:
			_order(r, o, glyph_h)


func _turn_order(r: Rect2, order: Dictionary) -> void:
	var x := r.position.x
	var y := r.get_center().y - px(10)
	var mid := roundf(r.get_center().x)
	_glyph("turn_left", Vector2(x, y), 20, TEXT if order.left else TEXT3)
	_glyph("turn", Vector2(r.end.x - px(26), y), 20, TEXT if order.right else TEXT3)
	if r.size.x >= px(83):
		_text(mid - _width("Turn", f_med, 17) * 0.5 - px(3), y, "Turn", f_med, 17, TEXT2)
	_hit(Rect2(x, r.position.y, mid - x, r.size.y), "rotl" if order.left else "", null, "Turn left. The odds update for the new facing.")
	_hit(Rect2(mid, r.position.y, r.end.x - mid, r.size.y), "rotr" if order.right else "", null, "Turn right. The odds update for the new facing.")


func _order(r: Rect2, o: Dictionary, preferred_size: int) -> void:
	var x := r.position.x
	var enabled := bool(o.on)
	var active := bool(o.get("active", false))
	var col := TEXT if enabled or active else TEXT3
	var cooldown := int(o.get("cooldown", 0))
	var label := str(o.label)
	if cooldown > 0:
		label = "%d %s" % [cooldown, "round" if cooldown == 1 else "rounds"]
	# Give long order names the space before losing words to an ellipsis.
	var icon_size := preferred_size
	if _width(label, f_med, 17) > r.size.x - px(icon_size + 13):
		icon_size = mini(preferred_size, 24)
	var gy := roundf(r.get_center().y - px(icon_size) * 0.5)
	_glyph(str(o.glyph), Vector2(x, gy), icon_size, EMBER if active else col)
	if cooldown > 0:
		marks.append({"k": "arc", "p": Vector2(x, gy) + Vector2.ONE * px(icon_size) * 0.5, "s": px(icon_size) * 0.5, "col": EMBER})
	var room := r.size.x - px(icon_size + 13)
	var label_w := _text(x + px(icon_size + 6), roundf(r.get_center().y - _text_h(f_med, 17) * 0.5), _trim(label, f_med, 17, room), f_med, 17, col, "join" if col == TEXT3 else "")
	if active:
		_rect(Rect2(x, r.end.y - px(3), label_w + px(icon_size + 6), px(2)), EMBER)
	_hit(r, str(o.act) if enabled else "", o.get("arg"), str(o.get("tip", "")))


func _fleet(x: float, y: float, w: float) -> void:
	var count := rows.size()
	if count == 0:
		fleet_fit = {"shown": 0, "total": 0}
		return
	_line(Vector2(x, y), Vector2(x + w, y), GS.SHEET_HAIR)
	var minimum := px(FLEET_SLOT_W)
	var gap := px(8)
	var paging := px(FLEET_PAGING_W)
	var capacity := maxi(1, int((w + gap) / (minimum + gap)))
	if count > capacity:
		capacity = maxi(1, int((w - paging + gap) / (minimum + gap)))
	var n := mini(count, capacity)
	var selected := ""
	for i in count:
		if bool(rows[i].get("sel", false)):
			selected = str(rows[i].get("id", ""))
			if selected != _fleet_id:
				fleet_page = int(floorf(float(i) / n))
			break
	_fleet_id = selected
	var last_page := int(ceilf(float(count) / n)) - 1
	fleet_page = clampi(fleet_page, 0, last_page)
	var paged := last_page > 0
	var cell := minf(px(383), floorf((w - (paging if paged else 0.0) + gap) / n) - gap)
	var shown := mini(n, count - fleet_page * n)
	for i in shown:
		var r: Dictionary = rows[fleet_page * n + i]
		_fleet_slot(Rect2(x + (cell + gap) * i, y + px(3), cell, px(FLEET_H - 5)), r)
	if paged:
		for d in [-1, 1]:
			var p := Vector2(x + w - px(56 if d < 0 else 27), y + px(13))
			var enabled: bool = fleet_page + d >= 0 and fleet_page + d <= last_page
			_glyph("back" if d < 0 else "next", p, 20, TEXT if enabled else TEXT3)
			_hit(Rect2(p - Vector2(px(3), px(5)), Vector2(px(26), px(31))), "fleet_page" if enabled else "", d,
				("Previous fleet page" if d < 0 else "Next fleet page") + " (%d of %d)." % [fleet_page + 1, last_page + 1])
	fleet_fit = {"shown": shown, "total": count, "page": fleet_page, "pages": last_page + 1}


func _fleet_slot(r: Rect2, row: Dictionary) -> void:
	var x := r.position.x
	var y := r.position.y
	var st := str(row.get("status", ""))
	var done := bool(row.get("done", false))
	var col := TEXT2 if done else TEXT
	var hp := float(row.get("hp", 0))
	var h := _ratio(hp, float(row.get("maxHp", 1)))
	var hull_col := (DMG if h < 1.0 else col) if st != "Lost" else TEXT2
	var hull := "Lost" if st == "Lost" else Campaign.hull_text(hp)
	var fw := _width(hull, f_num, 17)
	var wide := r.size.x >= px(205)
	if wide:
		var sw := minf(px(60), r.size.x * 0.18)
		_silhouette(str(row.get("code", "")), Rect2(x, y + px(11), sw, px(19)), col, h)
		var nx := x + sw + px(9)
		var bx := r.end.x - fw - px(95)
		_text(nx, y + px(10), _trim(str(row.get("name", "")), f_med, 17, bx - nx - px(10)), f_med, 17, col)
		_fleet_bars(bx, y + px(14), px(85), row, h, col)
		_right(r.end.x, y + px(9), hull, f_num, 17, hull_col)
	else:
		_text(x, y, _trim(str(row.get("name", "")), f_med, 17, r.size.x - px(2)), f_med, 17, col)
		var sw := minf(px(53), r.size.x * 0.30)
		_silhouette(str(row.get("code", "")), Rect2(x, y + px(24), sw, px(17)), col, h)
		var bx := x + sw + px(5)
		_fleet_bars(bx, y + px(28), maxf(px(4), r.end.x - bx - fw - px(7)), row, h, col)
		_right(r.end.x, y + px(21), hull, f_num, 17, hull_col)
	if bool(row.get("sel", false)) or st == "Acting":
		_rect(Rect2(x, r.end.y - px(1), r.size.x, px(2)), EMBER)
	var tip := "%s\n%s. %s." % [str(row.get("name", "")), str(row.get("cls", "")), st]
	if st != "Lost":
		tip += " Hull %s / %s." % [Campaign.hull_text(hp), Campaign.hull_text(row.get("maxHp", 0))]
		if float(row.get("shMax", 0)) > 0.0:
			tip += " Shield pool %d / %d." % [int(row.get("shp", 0)), int(row.shMax)]
		if int(row.get("danger", 0)) > 0:
			tip += "\nThe enemy can reach it first (%d guns)." % int(row.danger)
		if bool(row.get("new", false)):
			tip += "\nArrived this round."
	if bool(row.get("flag", false)):
		tip += "\nYour flagship."
	_hit(r, "pick", row.get("id"), tip + "\nClick to pick it.")


func _fleet_bars(x: float, y: float, w: float, row: Dictionary, h: float, col: Color) -> void:
	_bar(Rect2(x, y, w, px(3)), _ratio(float(row.get("shp", 0)), float(row.get("shMax", 0))), GLACIER, GS.SHIELD_TRACK)
	_bar(Rect2(x, y + px(5), w, px(4)), h, col, Color(DMG, 0.25))


func _log(right: float, bottom: float, w: float) -> void:
	log_r = Rect2()
	if not log_enabled:
		return
	var h := px(31 if log_collapsed else 119)
	log_r = Rect2(right - w, bottom - h, w, h)
	var x := log_r.position.x + px(12)
	var y := log_r.position.y + px(5)
	_veil(log_r.grow_individual(px(9), px(7), px(9), px(7)), Brand.KEEL_LOG_VEIL, Vector4.ONE * px(9))
	var lw := _text(x, y, "Log", f_med, 17, TEXT, "log", true)
	_glyph("expand" if log_collapsed else "collapse", Vector2(right - px(30), y), 20, TEXT)
	var entries := log_lines.slice(maxi(0, log_lines.size() - (1 if log_collapsed else 3)))
	for i in entries.size():
		var tx := x + (lw + px(14) if log_collapsed else 0.0)
		var ty := y if log_collapsed else y + px(28 + i * 26)
		var col := TEXT if i == entries.size() - 1 else TEXT2
		var entry := str(entries[i])
		var caption := _trim(entry, f_body, 17, right - tx - px(41 if log_collapsed else 12))
		_text(tx, ty, caption, f_body, 17, col, "log", true)
		if not log_collapsed and caption != entry:
			_hit(Rect2(tx, ty, right - tx, px(25)), "", null, entry)
	var log_tip := "Expand the battle log." if log_collapsed else "Collapse the battle log."
	if log_collapsed and not entries.is_empty():
		log_tip = str(entries[-1]) + "\n" + log_tip
	_hit(Rect2(log_r.position, Vector2(w, px(29))), "log_collapse", null, log_tip + " L opens the full history.")
	blockers.append(log_r)


func _draw() -> void:
	ensure_layout()
	var hovered := hits[_hover] if _hover >= 0 else {}
	var hr := Rect2(hovered.get("r", Rect2()))
	for m in marks:
		match m.k:
			"veil": _paint_veil(m.r, m.a, m.f)
			"rect": draw_rect(m.r, m.col)
			"line": draw_line(m.a, m.b, m.col, m.w)
			"diamond":
				var p: Vector2 = m.p
				var d := Vector2.ONE * float(m.s)
				draw_colored_polygon(PackedVector2Array([p - Vector2(0, d.y), p + Vector2(d.x, 0), p + Vector2(0, d.y), p - Vector2(d.x, 0)]), m.col)
			"arc": draw_arc(m.p, m.s, -PI / 2, PI / 4, 12, m.col, maxf(1, px(1.4)), true)
			"glyph":
				var tint: Color = m.col
				if bool(m.action) and hr.encloses(m.r):
					tint = GS.ON_EMBER
				draw_texture_rect(Icons.glyph(m.id), m.r, false, tint)
			"ship": _paint_silhouette(m)
			"action":
				if hr == m.r:
					draw_rect(m.r, EMBER)
				else:
					draw_rect(Rect2(m.r).grow(-maxf(2.0, px(2)) * 0.5), EMBER, false, maxf(2.0, px(2)))
	for it in items:
		var col: Color = it.col
		if it.role == "action" and hr.encloses(item_rect(it)):
			col = GS.ON_EMBER
		var p := Vector2(it.x, it.y + it.asc)
		if bool(it.edge):
			draw_string_outline(it.f, p, it.t, HORIZONTAL_ALIGNMENT_LEFT, -1, int(px(it.size)), int(maxf(2, px(3))), Brand.KEEL_TEXT_EDGE)
		draw_string(it.f, p, it.t, HORIZONTAL_ALIGNMENT_LEFT, -1, int(px(it.size)), col)


func _paint_silhouette(m: Dictionary) -> void:
	var tex := Icons.silhouette(m.id)
	if tex == null:
		return
	var bounds: Rect2 = m.r
	var source := tex.get_size()
	var fit := source * minf(bounds.size.x / source.x, bounds.size.y / source.y)
	var r := Rect2(bounds.get_center() - fit * 0.5, fit)
	var missing := 1.0 - float(m.health)
	if missing > 0.0:
		var cut := source.x * missing
		draw_texture_rect_region(tex, Rect2(r.position, Vector2(fit.x * missing, fit.y)), Rect2(0, 0, cut, source.y), Color(DMG, 0.7))
		if missing < 1.0:
			draw_texture_rect_region(tex, Rect2(r.position + Vector2(fit.x * missing, 0), Vector2(fit.x * (1 - missing), fit.y)), Rect2(cut, 0, source.x - cut, source.y), m.col)
	else:
		draw_texture_rect(tex, r, false, m.col)


static func _strength(r: Rect2, f: Vector4, at: Vector2) -> float:
	if not r.has_point(at):
		return 0.0
	var a := minf(clampf((at.x - r.position.x) / maxf(f.x, 0.001), 0, 1), clampf((r.end.x - at.x) / maxf(f.z, 0.001), 0, 1))
	var b := minf(clampf((at.y - r.position.y) / maxf(f.y, 0.001), 0, 1), clampf((r.end.y - at.y) / maxf(f.w, 0.001), 0, 1))
	return minf(a, b)


func _paint_veil(r: Rect2, alpha: float, f: Vector4) -> void:
	var xs := [r.position.x, r.position.x + f.x, r.end.x - f.z, r.end.x]
	var ys := [r.position.y, r.position.y + f.y, r.end.y - f.w, r.end.y]
	for i in 3:
		for j in 3:
			if xs[i + 1] <= xs[i] or ys[j + 1] <= ys[j]:
				continue
			var points := PackedVector2Array([Vector2(xs[i], ys[j]), Vector2(xs[i + 1], ys[j]), Vector2(xs[i + 1], ys[j + 1]), Vector2(xs[i], ys[j + 1])])
			var cols := PackedColorArray()
			for p in points:
				var a := _strength(r.grow(0.001), f, p)
				cols.append(Color(0, 0, 0, alpha * a))
			draw_polygon(points, cols)


func dark_at(p: Vector2) -> float:
	var keep := 1.0
	for m in marks:
		if m.k == "veil":
			keep *= 1.0 - float(m.a) * _strength(m.r, m.f, p)
	return 1.0 - keep


func _has_point(p: Vector2) -> bool:
	ensure_layout()
	# Only interactive areas, the shelf/log and the corner words take input (issue 1559 item 20: a click on "Round N", the
	# objective or the foe's name planned a move on the board under it). The veils' soft edges past the words are cosmetic.
	if sheet_r.has_point(p) or log_r.has_point(p) or hit_at(p) >= 0:
		return true
	for b in blockers:
		if b.has_point(p):
			return true
	return false


func hit_at(p: Vector2) -> int:
	for i in range(hits.size() - 1, -1, -1):
		if Rect2(hits[i].r).has_point(p):
			return i
	return -1


func _gui_input(e: InputEvent) -> void:
	ensure_layout()
	if e is InputEventMouseMotion:
		_hover = hit_at(e.position)
		var h := hits[_hover] if _hover >= 0 else {}
		mouse_default_cursor_shape = CURSOR_POINTING_HAND if h.get("act", "") != "" else CURSOR_ARROW
		hover_tip.emit(str(h.get("tip", "")), Rect2(h.get("r", Rect2())).position)
		queue_redraw()
	elif e is InputEventMouseButton:
		accept_event()
		if not e.pressed:
			return
		if e.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN] and e.position.y >= sheet_r.end.y - px(FLEET_H):
			fleet_page += -1 if e.button_index == MOUSE_BUTTON_WHEEL_UP else 1
			mark()
			return
		if e.button_index == MOUSE_BUTTON_LEFT:
			var i := hit_at(e.position)
			if i < 0:
				return
			var h := hits[i]
			if h.act == "fleet_page":
				fleet_page += int(h.arg)
				mark()
			elif h.act != "":
				act.emit(h.act, h.arg)
