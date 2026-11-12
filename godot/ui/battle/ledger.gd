extends Control
# The battle screen as the ember orders sheet: E1 LEDGER (issue 271 step 2; Ryan's pick R210, built as captured in step 1,
# docs/shots/ui_battle_ember/E1_ledger.jpg). The look is the campaign map's rail (contrib/opus/briefs/campaign_rail_orders_sheet.md,
# R176): no panels, words on a darkened edge of the scene, the Hollow Sun's ember the one accent, square corners, one box.
#
# One sheet on the left, read top to bottom in the order the player decides: whose turn, the ship, its hull and four
# shields, its guns, the target and the odds, the action, the other orders and the Command; the fleet at the foot. Top
# right: the menu, the enemy, Heat and the Nemesis. Bottom right: the last three lines of the log.
#
# SAY LESS (R177): what the sheet does not show is one hover or one key away (see hit() tips and docs/playbooks/screens.md).
# Faces: Big Shoulders Display for names in capitals (never under 28 px), Barlow for sentences and joining words, Azeret
# Mono for figures. Strengths: TEXT, TEXT2, and TEXT3 for joining words only. Colours: EMBER the accent, NEM the Nemesis
# only, GLACIER shield readouts only, DMG a damaged hull figure.
#
# layout() is pure: it turns the data the HUD hands over into words (items), marks and hit areas, with no drawing, so the
# headless check (godot/ui/battle/test/ledger_readability_test.gd) measures exactly what _draw() paints. Every number
# comes from the battle (battle.gd builds it from the rules' own queries); this file only places it.

signal act(name: String, arg: Variant)
signal hover_tip(bb: String, at: Vector2)   # "" hides

const GS := preload("res://ui/theme/glass_shell.gd")

const EMBER := GS.MAP_EMBER
const TEXT := GS.TEXT
const TEXT2 := GS.TEXT2
const TEXT3 := GS.TEXT3
const NEM := GS.NEM
const GLACIER := GS.GLACIER
const DMG := GS.HULL_LOW            # the game's existing damage colour (a hurt hull figure)
const HAIR := GS.SHEET_HAIR
const ON_EMBER := GS.ON_EMBER

# the sheet at the 1080 design height
const X0 := 52.0          # left margin
const CW := 560.0         # the sheet's width
const TOP := 40.0         # top margin
const FOOT := 48.0        # bottom margin
const VEIL_A := 0.94      # the left veil at full strength (its first 72%)
const VEIL_W := 0.45      # the left veil fades to nothing here (share of the window width), or further if the sheet needs it
const ROW_GAP := 36.0     # a fleet line
const ROW_GAP_TIGHT := 34.0

# the data of the moment (hud.gd hands it over; nothing here asks the battle)
var k := 1.0
var top := {}             # {round, turn, objective, end_text, end_on}
var info := {}            # {foe_name, foe_ships, heat, heat_tip}
var nem := {}             # {name, ship, flee, adapted, weak, state}
var rows: Array = []      # the fleet rows
var ship := {}            # the ship that is up or inspected (battle.gd _panel_info)
var target := {}          # battle.gd _target_info
var card := {}            # battle.gd _card_info
var cmd := {"label": "", "ready": false}
var ask := {}             # an issue 529 tree prompt {n, q, opts: [{id, n}]}, or {}
var log_lines: Array = []
var phase := {"kind": "", "text": "", "p": -1.0}
var retreat := {"on": false, "off": true}
var detail_bb := ""       # the ship name's hover layer (hud.gd _detail_bb)
var keys_bb := ""

# what layout() makes
var items: Array = []     # every word: {t, x, y, w, h, size, f, face, col, role}
var marks: Array = []     # lines, outlines, arcs, diamonds, veils
var hits: Array = []      # {r: Rect2, act, arg, tip}
var sheet_r := Rect2()    # the sheet's own area (clicks there never reach the board)
var veil_reach := 0.0
var fleet_fit := {}       # {shown, total, gap}: how many fleet lines fit, for the report and the check
var _dirty := true
var _hover := -1
var compact := 0          # 1 when the sheet ran out of room: guns that cannot fire fold into one line (hover lists them)

var f_name: Font
var f_body: Font
var f_med: Font
var f_num: Font


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	focus_mode = Control.FOCUS_NONE
	_fonts()
	resized.connect(mark)
	mouse_exited.connect(func() -> void:
		_hover = -1
		hover_tip.emit("", Vector2.ZERO))


func _fonts() -> void:
	if f_name == null:
		f_name = GS.sheet_name()
		f_body = GS.sheet_body()
		f_med = GS.sheet_medium()
		f_num = GS.num()


func mark() -> void:
	_dirty = true
	queue_redraw()


# ---------------------------------------------------------------- small pieces

func px(v: float) -> float:
	return round(v * k)


static func plain(s: String) -> String:
	var re := RegEx.new()
	re.compile("\\[[^\\]]*\\]")
	return re.sub(s, "", true).strip_edges()


func _face(f: Font) -> String:
	if f == f_name:
		return "BigShoulders"
	if f == f_num:
		return "AzeretMono"
	if f == f_med:
		return "Barlow Medium"
	return "Barlow"


func _w(s: String, f: Font, size: float) -> float:
	return f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, int(px(size))).x


# a word or line with its top at y; align 0 left, 1 right (x is the right edge), 2 centre. Returns its width.
func t(x: float, y: float, s: String, f: Font, size: float, col: Color, align := 0, role := "") -> float:
	if s == "":
		return 0.0
	var fs := int(px(size))
	var w := f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	var x0 := x if align == 0 else (x - w if align == 1 else x - w * 0.5)
	items.append({"t": s, "x": x0, "y": y, "w": w, "h": f.get_ascent(fs) + f.get_descent(fs), "asc": f.get_ascent(fs), "size": size, "f": f,
		"face": _face(f), "col": col, "role": role})
	return w


func item_rect(it: Dictionary) -> Rect2:
	return Rect2(float(it["x"]), float(it["y"]), float(it["w"]), float(it["h"]))


# a name in Big Shoulders capitals, shrunk to fit the width but never below 28; past that it wraps onto a second line
# (never trimmed). Returns the height used.
func name_fit(x: float, y: float, s: String, size: float, maxw: float, col: Color, align := 0) -> float:
	var u := s.to_upper()
	var fs := size
	while fs > 28 and _w(u, f_name, fs) > maxw:
		fs -= 1
	if _w(u, f_name, fs) <= maxw or not " " in u:
		t(x, y, u, f_name, fs, col, align, "name")
		return maxf(px(fs * 1.12), float(items[-1]["h"]))
	return para(x, y, u, f_name, fs, col, maxw, 1.18, align, "name")


# a sentence wrapped to a width; returns the height used
func para(x: float, y: float, s: String, f: Font, size: float, col: Color, maxw: float, lh := 1.3, align := 0, role := "") -> float:
	var line := ""
	var yy := y
	var fs := int(px(size))
	for wd in s.split(" "):
		var tryl: String = wd if line == "" else line + " " + wd
		if f.get_string_size(tryl, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x > maxw and line != "":
			t(x, yy, line, f, size, col, align, role)
			yy += px(size * lh)
			line = wd
		else:
			line = tryl
	if line != "":
		t(x, yy, line, f, size, col, align, role)
		yy += px(size * lh)
	return yy - y


func lines_h(s: String, f: Font, size: float, maxw: float, lh := 1.3) -> float:
	var n := 1
	var line := ""
	var fs := int(px(size))
	for wd in s.split(" "):
		var tryl: String = wd if line == "" else line + " " + wd
		if f.get_string_size(tryl, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x > maxw and line != "":
			n += 1
			line = wd
		else:
			line = tryl
	return n * px(size * lh)


func hair(x0: float, x1: float, y: float) -> void:
	marks.append({"k": "line", "a": Vector2(x0, y), "b": Vector2(x1, y), "col": HAIR, "w": maxf(1.0, px(1))})


# an area the pointer can use: a click sends act (when given), hovering shows tip (when given)
func hit(r: Rect2, a: String, arg: Variant = null, tip := "") -> void:
	hits.append({"r": r, "act": a, "arg": arg, "tip": tip})


# a key after a word, in the figure face and the second strength (no key caps, no badges). Returns the width.
func keyed(x: float, y: float, word: String, key: String, col := TEXT, size := 20.0, a := "", arg: Variant = null, tip := "") -> float:
	var w := t(x, y, word, f_med, size, col)
	if key != "":
		w += px(8)
		w += t(x + w, y + px(1), key, f_num, 18, TEXT2, 0, "key")
	if a != "" or tip != "":
		hit(Rect2(x - px(4), y - px(4), w + px(8), px(size + 10)), a, arg, tip)
	return w


func keyed_w(word: String, key: String, size := 20.0) -> float:
	return _w(word, f_med, size) + (px(8) + _w(key, f_num, 18) if key != "" else 0.0)


# ---------------------------------------------------------------- the data, read

func mine_turn() -> bool:
	return str(top.get("turn", "")).begins_with("Your turn")


func enemy_turn() -> bool:
	return str(phase.get("kind", "")) == "enemy" or str(top.get("turn", "")) == "Enemy turn"


func is_nem(nm: String) -> bool:
	return nm != "" and str(nem.get("name", "")) != "" and (nm == str(nem.get("name", "")) or str(nem.get("name", "")).ends_with(nm))


# the gun the big odds are for: the armed gun when it can fire, else the bearing gun with the best odds
func focus_gun() -> Dictionary:
	var best := {}
	var n := 0
	for w in ship.get("weapons", []):
		if int(w.get("hit", -1)) < 0:
			continue
		n += 1
		if bool(w.get("armed", false)):
			best = w
			break
		if best.is_empty() or int(w["hit"]) > int(best["hit"]):
			best = w
	return {"gun": best, "n": n}


func expect_line() -> String:
	var es: Array = target.get("exp_sh", [0, 0, 0, 0])
	var eh := float(target.get("exp_hull", 0))
	var bq := 0
	var tot := eh
	for i in 4:
		tot += float(es[i]) if i < es.size() else 0.0
		if i < es.size() and float(es[i]) > float(es[bq]):
			bq = i
	if tot < 0.5:
		return plain(str(target.get("line", "")))
	var facing: String = ["prow", "starboard", "rear", "port"][bq]
	if es.size() > bq and float(es[bq]) > 0.5:
		return "About %d damage: %d to its %s shield, %d to hull." % [int(round(tot)), int(round(float(es[bq]))), facing, int(round(eh))]
	return "About %d damage, all to hull." % int(round(tot))


func card_button(a: String) -> Dictionary:
	for b in card.get("buttons", []):
		if str(b.get("act", "")) == a:
			return b
	return {}


static func strip_key(s: String) -> Array:
	var re := RegEx.new()
	re.compile("^(.*?)\\s*\\((\\w+)\\)$")
	var m := re.search(s)
	if m != null:
		return [m.get_string(1), m.get_string(2)]
	return [s, ""]


# the one box: what Enter (or Space, or Tab) does next
func action() -> Dictionary:
	if not ask.is_empty():
		return {}
	var conf := card_button("confirm")
	if not conf.is_empty() and bool(conf.get("on", true)):
		var lbl: String = strip_key(str(conf.get("text", "")))[0]
		var fg := focus_gun()
		if lbl.begins_with("Fire ") and int(fg["n"]) == 1 and not (fg["gun"] as Dictionary).is_empty():
			lbl = "Fire the %s" % str(fg["gun"].get("name", ""))
		return {"label": lbl, "key": "Enter", "act": "confirm", "tip": str(card.get("hint", "")) + "\nEsc cancels."}
	var steps: Array = card.get("steps", [])
	if not steps.is_empty():
		var e := card_button("end")
		return {"label": "End ship", "key": "Space", "act": "end", "tip": str(e.get("tip", ""))}
	var nx := card_button("next")
	if not nx.is_empty() and bool(nx.get("on", true)):
		return {"label": "Next ship", "key": "Tab", "act": "next", "tip": str(nx.get("tip", "Switch to another ready ship."))}
	if card.is_empty() and bool(top.get("end_on", false)) and str(top.get("end_text", "")) == "End turn":
		return {"label": "End turn", "key": "Space", "act": "end", "tip": "End your turn; the enemy moves."}
	return {}


# ---------------------------------------------------------------- layout

func layout() -> void:
	compact = 0
	_layout_once()
	# a very full sheet (a six-gun ship with every order) leaves no room for the fleet: fold the guns that cannot fire
	if _content_end > size.y - px(FOOT) - px(ROW_GAP_TIGHT) * 2 - px(32) and _foldable() > 1:
		compact = 1
		_layout_once()


var _content_end := 0.0


func _foldable() -> int:
	var n := 0
	for w in ship.get("weapons", []):
		if int(w.get("hit", -1)) < 0 and not bool(w.get("armed", false)):
			n += 1
	return n


func _layout_once() -> void:
	_fonts()
	items = []
	marks = []
	hits = []
	var vs := size
	if vs.x < 10 or vs.y < 10:
		vs = Vector2(1920, 1080) * k
	var W := vs.x
	var H := vs.y
	var x := px(X0)
	var cw := px(CW)
	sheet_r = Rect2(0, 0, x + cw + px(24), H)
	veil_reach = maxf(W * VEIL_W, (x + cw + px(16)) / 0.72)
	marks.append({"k": "veil", "reach": veil_reach, "a0": VEIL_A})
	marks.append({"k": "corner", "c": Vector2(W, 0), "rx": px(780), "ry": px(300), "a": 0.9})
	marks.append({"k": "corner", "c": Vector2(W, H), "rx": px(1150), "ry": px(340), "a": 0.9})
	var y := px(TOP)
	y += _turn_line(x, y, cw)
	var obj := plain(str(top.get("objective", "")))
	if obj != "":
		y += para(x, y, obj, f_body, 19, TEXT2, cw) + px(18)
	else:
		y += px(18)
	y = _ship_block(x, y, cw)
	# the focus: the shot (or the tree prompt in its place: it is asked after the Command, and nothing else acts until it is
	# answered, issue 529), then the action
	if not ask.is_empty():
		hair(x, x + cw, y)
		y += px(18)
		y += _prompt(x, y, cw) + px(12)
	elif mine_turn() and not card.is_empty():
		if not ship.is_empty() or not target.is_empty():
			hair(x, x + cw, y)
			y += px(18)
		y = _focus(x, y, cw)
	elif enemy_turn():
		y += para(x, y, "Enter or Space hurries the enemy's turn.", f_body, 19, TEXT2, cw) + px(8)
	var fy_min := y
	_content_end = y
	_fleet(x, fy_min, cw, H)
	_top_right(W - px(52), px(TOP))
	_log_right(W - px(52), px(600), H - px(40))
	_dirty = false


func _turn_line(x: float, y: float, cw: float) -> float:
	var parts: Array = [["Round %d" % int(top.get("round", 1)), TEXT2]]
	var turn := str(top.get("turn", ""))
	var count_tip := ""
	if enemy_turn():
		parts.append(["Enemy turn", TEXT])
		var pt := plain(str(phase.get("text", "")))
		var seg := pt.split("  ·  ")
		if seg.size() > 1 and str(seg[1]).strip_edges() != "":
			parts.append([str(seg[1]).strip_edges(), TEXT2])
	elif turn.begins_with("Your turn"):
		parts.append(["Your turn", EMBER])
		var pend := 0
		var tot := 0
		var names := PackedStringArray()
		var reach := PackedStringArray()
		for r in rows:
			var st := str(r.get("status", ""))
			if st == "Lost":
				continue
			tot += 1
			if st in ["Ready", "Up", "Acting"]:
				pend += 1
				names.append(str(r.get("name", "")))
				if int(r.get("danger", 0)) > 0:
					reach.append(str(r.get("name", "")))
		if tot > 0:
			parts.append(["%d of %d ships to act" % [pend, tot], TEXT2])
			count_tip = "Still to act: %s. Tab jumps to the next." % ", ".join(names) if not names.is_empty() else "Every ship has acted."
			if not reach.is_empty():
				count_tip += "\nThe enemy can reach these first: %s." % ", ".join(reach)
	elif turn != "":
		parts.append([turn, TEXT])
	var xx := x
	for i in parts.size():
		var p: Array = parts[i]
		var w := t(xx, y, str(p[0]), f_med, 19, p[1])
		if i == parts.size() - 1 and count_tip != "":
			hit(Rect2(xx - px(4), y - px(4), w + px(8), px(28)), "", null, count_tip)
		xx += w + px(18)
	var h := px(30)
	if enemy_turn() and float(phase.get("p", -1.0)) >= 0.0:
		var p := clampf(float(phase.get("p", 0.0)), 0.0, 1.0)
		marks.append({"k": "line", "a": Vector2(x, y + px(28)), "b": Vector2(x + cw, y + px(28)), "col": HAIR, "w": maxf(1.0, px(2))})
		marks.append({"k": "line", "a": Vector2(x, y + px(28)), "b": Vector2(x + cw * p, y + px(28)), "col": TEXT2, "w": maxf(1.0, px(2))})
		h += px(8)
	return h


# the ship that is up (or inspected): name, class, hull, movement, the four shields, flags, guns
func _ship_block(x: float, y: float, cw: float) -> float:
	if ship.is_empty():
		var say := ""
		if mine_turn() and not card.is_empty():
			say = str(card.get("say", "Pick a ship: click one of yours or press Tab."))
		if say != "":
			y += px(8)
			y += para(x, y, say, f_body, 20, TEXT, cw) + px(14)
		return y
	var mine := str(ship.get("side", "")) == "player"
	var nm := str(ship.get("name", ""))
	var ncol := TEXT if mine or not is_nem(nm) else NEM
	var top_y := y
	var nh := name_fit(x, y, nm, 64, cw, ncol)
	hit(Rect2(x, top_y, cw * 0.8, nh), "", null, detail_bb)
	y += nh + px(8)
	t(x, y, str(ship.get("cls", "")), f_med, 21, TEXT)
	y += px(40)
	var hp := float(ship.get("hp", 0))
	var mx := float(ship.get("maxHp", 1))
	_hull_fig(x, y + px(20), hp, mx)
	if mine:
		var mv: Array = ship.get("move", [])
		if mv.size() == 2:
			t(x, y + px(62), "Move %d of %d" % [int(mv[0]), int(mv[1])], f_body, 19, TEXT2)
	if float(ship.get("shMax", 0)) > 0.0:
		_shield_plan(Vector2(x + cw - px(70), y + px(46)), ship.get("sh", []), float(ship.get("shMax", 1)))
	y += px(124)
	var fl := plain(str(ship.get("flags", "")))
	if fl != "":
		var fh := para(x, y, fl, f_body, 19, TEXT, cw)
		var defs := keyword_tip(fl)
		if defs != "":
			hit(Rect2(x, y, cw, fh), "", null, defs)
		y += fh + px(6)
	y += px(6)
	y += _gun_rows(x, y, cw) + px(14)
	return y


# hull as figures: "135 / 135", the first in the damage colour when hurt
# the one-layer keyword definitions (Glass Shell follow-up 14, Muse synthesis pattern 8): the state words a status line
# uses, defined on hover over that line
const KEYWORDS := {
	"Braced": "Braced: the ship takes 40% less hull damage until its next turn. A braced ship does not turn or fire.",
	"On fire": "On fire: its shields falter and it can no longer repair itself.",
	"Torpedoes inbound": "Torpedoes inbound: a torpedo is locked on this ship's marked hex. Move 3 or more hexes away from it to dodge.",
	"focusing its fire": "Focus fire: the enemy fleet favours this ship when it picks targets.",
	"Fired": "Ships move, then fire: after firing, half the movement left can still be used to slip away.",
}


static func keyword_tip(line: String) -> String:
	var out := PackedStringArray()
	for kw in KEYWORDS:
		if line.contains(kw):
			out.append(str(KEYWORDS[kw]))
	return "\n".join(out)


func _hull_fig(x: float, y: float, hp: float, mx: float, size := 26.0) -> void:
	var a := str(int(round(hp)))
	var bb := " / %d" % int(round(mx))
	var ww := _w("Hull ", f_body, 19)
	t(x, y + px(size - 19) * 0.7, "Hull", f_body, 19, TEXT3, 0, "join")
	var wa := t(x + ww, y, a, f_num, size, TEXT if hp >= mx - 0.5 else DMG, 0, "figure")
	t(x + ww + wa, y, bb, f_num, size, TEXT2, 0, "figure")


# the ship seen from above with its four shield facings: prow up, rear down, port left, starboard right. The figure of each
# facing beside its arc; the arc's lit share is its charge. Glacier is used for nothing else.
func _shield_plan(c: Vector2, sh: Array, shmax: float) -> void:
	var s := px(1.0)
	marks.append({"k": "hull", "c": c, "s": s})
	var R := 34.0 * s
	var lw := maxf(2.0, px(3))
	var mids := [-PI / 2, 0.0, PI / 2, PI]   # prow, starboard, rear, port (screen angles, y down)
	var words := ["prow", "starboard", "rear", "port"]
	var tip := "Shields, %d each at full: " % int(round(shmax))
	for q in 4:
		var v := float(sh[q]) if q < sh.size() else 0.0
		var f := clampf(v / maxf(shmax, 1.0), 0.0, 1.0)
		marks.append({"k": "arc", "c": c, "r": R, "a0": mids[q] - 0.62, "a1": mids[q] + 0.62, "col": Color(TEXT3, 0.45), "w": lw})
		if f > 0.0:
			marks.append({"k": "arc", "c": c, "r": R, "a0": mids[q] - 0.62 * f, "a1": mids[q] + 0.62 * f, "col": GLACIER, "w": lw})
		var label := str(int(round(v)))
		var col := GLACIER if v > 0.5 else TEXT2
		var hgt := f_num.get_ascent(int(px(19)))
		match q:
			0: t(c.x, c.y - R - px(8) - hgt, label, f_num, 19, col, 2, "shield")
			1: t(c.x + R + px(8), c.y - hgt * 0.5, label, f_num, 19, col, 0, "shield")
			2: t(c.x, c.y + R + px(6), label, f_num, 19, col, 2, "shield")
			3: t(c.x - R - px(8), c.y - hgt * 0.5, label, f_num, 19, col, 1, "shield")
		tip += "%s [color=#92b8e8]%d[/color]%s" % [words[q], int(round(v)), ", " if q < 3 else "."]
	hit(Rect2(c - Vector2(R + px(40), R + px(34)), Vector2(2 * R + px(80), 2 * R + px(64))), "", null, tip)


func _gun_rows(x: float, y: float, cw: float) -> float:
	var yy := y
	var fg: Dictionary = focus_gun()["gun"]
	var mine := str(ship.get("side", "")) == "player"
	var i := 0
	var folded: Array = []
	for wpn in ship.get("weapons", []):
		i += 1
		var hit_v := int(wpn.get("hit", -1))
		if compact > 0 and hit_v < 0 and not bool(wpn.get("armed", false)):
			folded.append([i, wpn])
			continue
		var on_focus: bool = hit_v >= 0 and fg == wpn
		var ncol := TEXT if (hit_v >= 0 or bool(wpn.get("ready", false))) else TEXT2
		var nw := t(x, yy, str(wpn.get("name", "")), f_med, 20, ncol)
		t(x + nw + px(10), yy + px(2), ("%s %s" % [str(wpn.get("arc", "")), str(wpn.get("rng", ""))]).strip_edges(), f_num, 17, TEXT2, 0, "figure")
		if hit_v >= 0:
			t(x + cw, yy - px(1), "%d%%" % hit_v, f_num, 22, EMBER if on_focus else TEXT, 1, "figure")
		else:
			var why := str(wpn.get("why", wpn.get("right", "")))
			if why == "ready" and not target.is_empty():
				why = "won't bear"
			t(x + cw, yy + px(1), why, f_body, 18, TEXT2, 1)
		# damage and cost wait for hover; a click arms this gun alone (or its number key)
		var tip := plain(str(wpn.get("desc", "")))
		if int(wpn.get("dmg", -1)) >= 0 and hit_v >= 0:
			tip += "\nExpected about %d damage at %d%% to hit." % [int(wpn["dmg"]), hit_v]
		var cost := str(wpn.get("cost", ""))
		if cost != "":
			tip += "\n" + ("Free: it can fire every round." if cost == "free" else "Cooldown: %s rounds before it fires again." % cost.trim_prefix("CD "))
		if str(wpn.get("arc_tip", "")) != "":
			tip += "\n" + str(wpn["arc_tip"])
		if mine:
			tip += "\nClick or press %d to fire this gun alone%s." % [i, " (armed now)" if bool(wpn.get("armed", false)) else ""]
		hit(Rect2(x - px(4), yy - px(3), cw + px(8), px(29)), "arm" if mine else "", wpn.get("i", i - 1), tip)
		yy += px(31)
	if not folded.is_empty():
		var names := PackedStringArray()
		for f in folded:
			names.append("%d %s (%s %s): %s" % [int(f[0]), str(f[1].get("name", "")), str(f[1].get("arc", "")), str(f[1].get("rng", "")), str(f[1].get("why", f[1].get("right", "")))])
		var lw := t(x, yy, "%d more gun%s, none bears" % [folded.size(), "" if folded.size() == 1 else "s"], f_body, 19, TEXT2)
		hit(Rect2(x - px(4), yy - px(3), lw + px(8), px(29)), "", null, "\n".join(names) + "\nPress a gun's number to arm it.")
		yy += px(31)
	return yy - y


func _focus(x: float, y: float, cw: float) -> float:
	var fgi := focus_gun()
	var G: Dictionary = fgi["gun"]
	if not target.is_empty():
		var tw := t(x, y + px(6), "Target", f_body, 19, TEXT3, 0, "join")
		var nm := str(target.get("name", ""))
		var ty := y
		var nh := name_fit(x + tw + px(14), y, nm, 34, cw - tw - px(14), NEM if bool(target.get("nem", false)) or is_nem(nm) else TEXT)
		hit(Rect2(x + tw + px(10), ty - px(2), cw - tw - px(10), nh + px(4)), "", null, _target_tip())
		y += maxf(nh, px(38)) + px(8)
		if not G.is_empty():
			var ow := t(x, y - px(8), "%d%%" % int(G["hit"]), f_num, 64, EMBER, 0, "focus")
			var with := "to hit with the %s" % str(G.get("name", ""))
			if int(fgi["n"]) > 1:
				with += ", %d guns bear" % int(fgi["n"])
			var ex := x + ow + px(18)
			var ew := cw - ow - px(18)
			var h1 := para(ex, y + px(4), with, f_med, 20, TEXT, ew, 1.25)
			var h2 := para(ex, y + px(4) + h1 + px(4), expect_line(), f_body, 19, TEXT2, ew)
			y += maxf(px(92), px(4) + h1 + px(4) + h2 + px(10))
		else:
			y += para(x, y, plain(str(target.get("line", ""))), f_body, 19, TEXT2, cw) + px(10)
	# one short sentence for what to do now (battle.gd _card_info "say"); the full hint is on the action's hover
	var say := str(card.get("say", ""))
	if say != "":
		y += para(x, y, say, f_body, 19, TEXT2, cw) + px(10)
	var A := action()
	if not A.is_empty():
		y += _action_box(x, y, cw, A) + px(18)
	y += _orders(x, y, cw, A) + px(4)
	_command_row(x, y, cw, A)
	y += px(34)
	return y


func _target_tip() -> String:
	var hp := float(target.get("hp", 0))
	var eh := float(target.get("exp_hull", 0))
	var s := "Hull %d / %d" % [int(round(hp)), int(round(float(target.get("maxHp", 0))))]
	if eh > 0.5:
		s += ", to about %d after the volley" % int(round(maxf(0.0, hp - eh)))
	s += "."
	if float(target.get("shMax", 0)) > 0.0:
		var sh: Array = target.get("sh", [0, 0, 0, 0])
		var words := ["prow", "starboard", "rear", "port"]
		var parts := PackedStringArray()
		for i in 4:
			parts.append("%s [color=#92b8e8]%d[/color]" % [words[i], int(round(float(sh[i]) if i < sh.size() else 0.0))])
		s += "\nShields: " + ", ".join(parts) + "."
	if str(target.get("line", "")) != "":
		s += "\n" + plain(str(target["line"]))
	return s


# the one box on the screen: a square ember outline, filled ember while the pointer is on it
func _action_box(x: float, y: float, w: float, A: Dictionary) -> float:
	var h := px(56)
	var r := Rect2(x, y, w, h)
	marks.append({"k": "action", "r": r})
	var lab := str(A["label"]).to_upper()
	var fs := 34.0
	var room := w - px(140)
	while fs > 28 and _w(lab, f_name, fs) > room:
		fs -= 1
	t(x + px(16), y + px(9), lab, f_name, fs, EMBER, 0, "action")
	var key := str(A["key"])
	var kw := _w(key, f_med, 20)
	var ax := x + w - px(18)
	marks.append({"k": "arrow", "p": Vector2(ax, y + h * 0.5)})
	t(ax - px(18) - kw, y + px(15), key, f_med, 20, EMBER, 0, "action")
	hit(r, str(A["act"]), null, str(A.get("tip", "")))
	return h


# the orders that can be given now, as words with their keys; Turn carries both its keys (Q left, E right). Orders that
# cannot be given now are not listed (their keys still answer, with the reason); Ram and Board appear when they can be used.
func _orders(x: float, y: float, w: float, A: Dictionary) -> float:
	var list: Array = []
	var turn_on := false
	for o in ship.get("orders", []):
		if not bool(o.get("on", false)):
			continue
		var a := str(o.get("act", ""))
		if a in ["rotl", "rotr"]:
			turn_on = true
			continue
		var tk: Array = strip_key(str(o.get("text", "")))
		list.append({"w": tk[0], "k": tk[1], "act": a, "arg": o.get("arg"), "tip": str(o.get("tip", ""))})
	if turn_on:
		list.append({"turn": true})
	var nx := card_button("next")
	if not nx.is_empty() and bool(nx.get("on", true)) and str(A.get("act", "")) != "next":
		list.append({"w": "Next ship", "k": "Tab", "act": "next", "arg": null, "tip": str(nx.get("tip", ""))})
	var xx := x
	var yy := y
	for o in list:
		var ww: float
		if o.has("turn"):
			ww = _w("Turn", f_med, 20) + px(8) + _w("Q", f_num, 18) + px(10) + _w("E", f_num, 18)
		else:
			ww = keyed_w(str(o["w"]), str(o["k"]))
		if xx + ww > x + w and xx > x:
			xx = x
			yy += px(30)
		if o.has("turn"):
			var tw := t(xx, yy, "Turn", f_med, 20, TEXT)
			var qx := xx + tw + px(8)
			var qw := t(qx, yy + px(1), "Q", f_num, 18, TEXT2, 0, "key")
			var ex := qx + qw + px(10)
			var ew := t(ex, yy + px(1), "E", f_num, 18, TEXT2, 0, "key")
			hit(Rect2(xx - px(4), yy - px(4), (qx + qw + px(4)) - (xx - px(4)), px(30)), "rotl", null, "Turn left (Q). The odds update for the new facing.")
			hit(Rect2(ex - px(4), yy - px(4), ew + px(8), px(30)), "rotr", null, "Turn right (E).")
		else:
			keyed(xx, yy, str(o["w"]), str(o["k"]), TEXT, 20.0, str(o["act"]), o["arg"], str(o["tip"]))
		xx += ww + px(28)
	return (yy - y) + (px(30) if not list.is_empty() else 0.0)


func _command_row(x: float, y: float, w: float, A: Dictionary) -> void:
	if bool(cmd.get("ready", false)):
		var cw0 := t(x, y + px(1), "Command", f_body, 19, TEXT3, 0, "join")
		keyed(x + cw0 + px(10), y, str(cmd.get("label", "Command")), "C", TEXT, 20.0, "command", null,
			"Your Admiral's Command, once per battle: %s. Click twice (or press C) to give it." % str(cmd.get("label", "")))
	var e := card_button("end")
	if not e.is_empty() and str(A.get("act", "")) != "end":
		var ew := keyed_w("End ship", "Space")
		keyed(x + w - ew, y, "End ship", "Space", TEXT2, 20.0, "end", null, str(e.get("tip", "")))


# the tree prompt (issue 529) in the place of the shot: the skill's name, its question, the choices numbered (keys 1 to 3)
func _prompt(x: float, y: float, w: float) -> float:
	var yy := y
	yy += name_fit(x, yy, str(ask.get("n", "")), 32, w, TEXT) + px(6)
	yy += para(x, yy, str(ask.get("q", "")), f_body, 20, TEXT, w)
	yy += px(8)
	var i := 0
	for o in ask.get("opts", []):
		i += 1
		var h := px(48)
		var r := Rect2(x, yy, w, h)
		if i == 1:
			marks.append({"k": "action", "r": r})
		t(x + px(16), yy + px(6), str(i), f_name, 32, EMBER if i == 1 else TEXT, 0, "name")
		t(x + px(52), yy + px(12), str(o.get("n", "")), f_med, 21, TEXT)
		hit(r, "ask", str(o.get("id", "")), str(o.get("d", "")))
		yy += h + px(6)
	return yy - y


# the fleet at the foot, as on the map: one line per ship, the name on the left and its hull figure at the right edge. The
# lines that fit are shown (36 px each, then 31); past that, ships that have acted go into one "and N more" line (hover
# lists them, Tab still reaches every ready ship).
func _fleet(x: float, y_min: float, w: float, H: float) -> void:
	var live: Array = rows.duplicate()
	if live.is_empty():
		fleet_fit = {"shown": 0, "total": 0, "gap": ROW_GAP}
		return
	var room := (H - px(FOOT)) - (y_min + px(32))
	var gap := ROW_GAP
	var n := live.size()
	if px(gap) * n > room:
		gap = ROW_GAP_TIGHT
	var fit := int(floor(room / px(gap)))
	if fit < 2 and n > 1:
		# no room for the lines: one summary line (hover lists every ship; Tab and the board still pick them)
		var fy1 := H - px(FOOT) - px(gap)
		hair(x, x + w, fy1 - px(16))
		var pend := 0
		var names := PackedStringArray()
		for r in live:
			if str(r.get("status", "")) in ["Ready", "Up", "Acting"]:
				pend += 1
			names.append("%s %s" % [str(r.get("name", "")), "lost" if str(r.get("status", "")) == "Lost" else str(int(round(float(r.get("hp", 0)))))])
		var fw0 := t(x + px(24), fy1 + px(5), "Fleet", f_body, 19, TEXT3, 0, "join")
		var fw1 := t(x + px(24) + fw0 + px(10), fy1 + px(4), "%d ships, %d to act" % [n, pend], f_med, 20, TEXT)
		hit(Rect2(x + px(20), fy1, fw0 + fw1 + px(18), px(gap)), "next", null, ", ".join(names) + ".\nClick or press Tab for the next ship to act.")
		fleet_fit = {"shown": 0, "total": n, "gap": gap, "fit": fit, "summary": true}
		return
	fit = maxi(1, fit)
	var shown: Array = live
	var rest: Array = []
	if n > fit:
		# keep the ship that is up and those still to act; fold the rest into one line
		var order: Array = []
		for pass_i in 3:
			for r in live:
				var st := str(r.get("status", ""))
				var cls := 0 if bool(r.get("sel", false)) or st in ["Up", "Acting"] else (1 if st == "Ready" else 2)
				if cls == pass_i:
					order.append(r)
		shown = order.slice(0, fit - 1)
		rest = order.slice(fit - 1)
		# keep the fleet's own order among the lines shown
		var keep: Array = []
		for r in live:
			if r in shown:
				keep.append(r)
		shown = keep
	var lines := shown.size() + (1 if not rest.is_empty() else 0)
	var fy := H - px(FOOT) - px(gap) * lines
	hair(x, x + w, fy - px(16))
	var nx := x + px(24)
	var nw := w - px(24)
	var yy := fy
	for r in shown:
		var done := bool(r.get("done", false))
		var lost := str(r.get("status", "")) == "Lost"
		var col := TEXT2 if done or lost else TEXT
		if bool(r.get("flag", false)):
			marks.append({"k": "diamond", "c": Vector2(nx - px(14), yy + px(28 * 0.55)), "r": px(5), "col": EMBER})
		if bool(r.get("sel", false)):
			marks.append({"k": "rect", "r": Rect2(nx - px(34), yy + px(4), px(3), px(26)), "col": EMBER})
		var fw := _w("999", f_num, 19) + px(16)
		var nm_fs := 28.0
		var up := str(r.get("name", "")).to_upper()
		t(nx, yy, up, f_name, nm_fs, col, 0, "name")
		var hp := float(r.get("hp", 0))
		var mx := float(r.get("maxHp", 1))
		if lost:
			t(nx + nw, yy + px(5), "lost", f_body, 19, TEXT2, 1)
		else:
			t(nx + nw, yy + px(28 * 0.22), str(int(round(hp))), f_num, 19, (TEXT if hp >= mx - 0.5 else DMG) if not done else TEXT2, 1, "figure")
		hit(Rect2(nx - px(36), yy, nw + px(36), px(gap)), "pick", r.get("id"), _row_tip(r))
		yy += px(gap)
		if _w(up, f_name, nm_fs) > nw - fw:
			push_warning("ledger: fleet name %s is wider than its line" % up)
	if not rest.is_empty():
		var names := PackedStringArray()
		for r in rest:
			names.append("%s %d" % [str(r.get("name", "")), int(round(float(r.get("hp", 0))))])
		var lw := t(nx, yy + px(5), "and %d more" % rest.size(), f_body, 19, TEXT2)
		hit(Rect2(nx - px(4), yy, lw + px(8), px(gap)), "", null, ", ".join(names) + ".")
	fleet_fit = {"shown": shown.size(), "total": n, "gap": gap, "fit": fit}


func _row_tip(r: Dictionary) -> String:
	var st := str(r.get("status", ""))
	var s := "%s. %s." % [str(r.get("cls", "")), {"Up": "Up now", "Acting": "Acting now", "Ready": "Ready to act", "Done": "Has acted this round", "Lost": "Lost"}.get(st, st)]
	if st != "Lost":
		s += " Hull %d / %d." % [int(round(float(r.get("hp", 0)))), int(round(float(r.get("maxHp", 0))))]
		var f := float(r.get("hp", 0)) / maxf(float(r.get("maxHp", 1)), 1.0)
		if f < 0.35:
			s += " Hull below 35%."
		if int(r.get("danger", 0)) > 0:
			s += "\nThe enemy can reach it first (%d guns)." % int(r["danger"])
		if bool(r.get("new", false)):
			s += "\nArrived this round."
	if bool(r.get("flag", false)):
		s += "\nYour flagship."
	s += "\nClick to pick it."
	return s


# top right, right aligned at xr: the menu (and Retreat when it can be used), the enemy and Heat, the Nemesis
func _top_right(xr: float, y: float) -> void:
	var mw := keyed_w("Menu", "Esc", 19)
	keyed(xr - mw, y, "Menu", "Esc", TEXT2, 19.0, "menu", null, "Options, keys, the threat map, speed, retreat and quit.")
	if bool(retreat.get("on", false)):
		var rw := _w("Retreat", f_med, 19)
		var rx := xr - mw - px(28) - rw
		t(rx, y, "Retreat", f_med, 19, TEXT2 if bool(retreat.get("off", false)) else TEXT)
		hit(Rect2(rx - px(4), y - px(4), rw + px(8), px(28)), "" if bool(retreat.get("off", false)) else "retreat", null, "Pull the fleet out of this battle.")
	var yy := y + px(38)
	var hw := 0.0
	if int(info.get("heat", -1)) >= 0:
		hw = t(xr, yy + px(1), str(clampi(int(info["heat"]), 0, 9)), f_num, 19, TEXT, 1, "figure")
		var hx := xr - hw - px(8)
		var lw := t(hx, yy, "Heat", f_body, 19, TEXT3, 1, "join")
		hit(Rect2(hx - lw - px(4), yy - px(4), lw + hw + px(16), px(28)), "", null, str(info.get("heat_tip", "Heat: the run's difficulty level, up to 9.")))
		hw += px(8) + lw + px(24)
	var fname := str(info.get("foe_name", ""))
	if fname != "":
		var n := int(info.get("foe_ships", 0))
		t(xr - hw, yy, "%s, %d ship%s" % [fname, n, "" if n == 1 else "s"], f_med, 19, TEXT, 1)
	yy += px(30)
	if not nem.is_empty():
		var dw := t(xr, yy, "Dossier", f_body, 18, TEXT3, 1, "join") + px(16)
		var st := str(nem.get("state", ""))
		var sw := 0.0
		if st != "":
			sw = t(xr - dw, yy, st, f_body, 19, TEXT2, 1) + px(10)
		var nw := t(xr - dw - sw, yy, str(nem.get("name", "")), f_med, 19, TEXT, 1)
		var lw := t(xr - dw - sw - nw - px(10), yy, "Nemesis", f_med, 19, NEM, 1)
		var x0 := xr - dw - sw - nw - px(10) - lw
		hit(Rect2(x0 - px(4), yy - px(4), xr - x0 + px(8), px(28)), "", null, _nem_tip())


func _nem_tip() -> String:
	var s := "[b]%s[/b]" % str(nem.get("name", ""))
	if str(nem.get("ship", "")) != "":
		s += "\nAboard the %s." % str(nem["ship"])
	if str(nem.get("flee", "")) != "":
		s += " He %s." % str(nem["flee"])
	for a in nem.get("adapted", []):
		s += "\nAdapted: %s%s" % [str(a[1]).trim_suffix("."), (" (%s)." % str(a[2])) if str(a[2]) != "" else "."]
	var weak: Array = nem.get("weak", [])
	if weak.is_empty():
		s += "\nWeakness: not found yet."
	for w in weak:
		s += "\nWeakness: %s (%s)." % [str(w[1]).trim_suffix("."), str(w[0]).to_lower()]
	return s


# the last three lines of the log, left aligned in a block whose right edge is xr and whose foot is at bottom; "Log L"
# above it (L or a click opens the full log)
func _log_right(xr: float, w: float, bottom: float) -> void:
	var L: Array = log_lines.slice(maxi(0, log_lines.size() - 3))
	var x0 := xr - w
	var tot := 0.0
	for l in L:
		tot += lines_h(str(l), f_body, 18, w, 1.28) + px(4)
	var yy := bottom - tot
	var lw := t(x0, yy - px(30), "Log", f_body, 18, TEXT3, 0, "join")
	lw += px(8) + t(x0 + lw + px(8), yy - px(29), "L", f_num, 18, TEXT2, 0, "key")
	hit(Rect2(x0 - px(4), yy - px(34), lw + px(8), px(28)), "log", null, "Open the full battle log (L).")
	for i in L.size():
		var col := TEXT if i == L.size() - 1 else TEXT2
		yy += para(x0, yy, str(L[i]), f_body, 18, col, w, 1.28) + px(4)


# ---------------------------------------------------------------- drawing

func _draw() -> void:
	if _dirty:
		layout()
	for m in marks:
		match str(m["k"]):
			"veil":
				_veil(float(m["reach"]), float(m["a0"]))
			"corner":
				_corner(m["c"], float(m["rx"]), float(m["ry"]), float(m["a"]))
			"line":
				draw_line(m["a"], m["b"], m["col"], float(m["w"]))
			"rect":
				draw_rect(m["r"], m["col"])
			"diamond":
				var c: Vector2 = m["c"]
				var r := float(m["r"])
				draw_colored_polygon(PackedVector2Array([c + Vector2(0, -r), c + Vector2(r, 0), c + Vector2(0, r), c + Vector2(-r, 0)]), m["col"])
			"arc":
				draw_arc(m["c"], float(m["r"]), float(m["a0"]), float(m["a1"]), 16, m["col"], float(m["w"]))
			"hull":
				var c: Vector2 = m["c"]
				var s := float(m["s"])
				var pts := PackedVector2Array([Vector2(0, -24), Vector2(8, -10), Vector2(8, 18), Vector2(-8, 18), Vector2(-8, -10), Vector2(0, -24)])
				for i in pts.size():
					pts[i] = c + pts[i] * s
				draw_polyline(pts, TEXT3, maxf(1.0, px(1.5)))
			"action":
				var r: Rect2 = m["r"]
				if _hover >= 0 and hits[_hover]["r"] == r:
					draw_rect(r, EMBER)
				else:
					draw_rect(r, EMBER, false, maxf(2.0, px(2)))
			"arrow":
				var p: Vector2 = m["p"]
				var hov := _hover >= 0 and Rect2(hits[_hover]["r"]).has_point(p - Vector2(px(2), 0))
				draw_colored_polygon(PackedVector2Array([p + Vector2(-px(10), -px(7)), p, p + Vector2(-px(10), px(7))]), ON_EMBER if hov else EMBER)
	var hov_r := Rect2(hits[_hover]["r"]) if _hover >= 0 else Rect2()
	for it in items:
		var col: Color = it["col"]
		if str(it["role"]) == "action" and _hover >= 0 and hov_r.encloses(item_rect(it)):
			col = ON_EMBER
		draw_string(it["f"], Vector2(float(it["x"]), float(it["y"]) + float(it["asc"])), str(it["t"]), HORIZONTAL_ALIGNMENT_LEFT, -1, int(px(float(it["size"]))), col)


# one smooth veil from the left edge, never a panel: full strength over its first 72% (the words stay inside that), then
# fading to nothing at reach
func _veil(reach: float, a0: float) -> void:
	var H := size.y
	var stops := [[0.0, a0 + 0.02], [0.72, a0], [1.0, 0.0]]
	for i in 2:
		var p0: float = reach * float(stops[i][0])
		var p1: float = reach * float(stops[i + 1][0])
		var c0 := Color(0, 0, 0, float(stops[i][1]))
		var c1 := Color(0, 0, 0, float(stops[i + 1][1]))
		draw_polygon(PackedVector2Array([Vector2(p0, 0), Vector2(p1, 0), Vector2(p1, H), Vector2(p0, H)]), PackedColorArray([c0, c1, c1, c0]))


# the veil's strength at a point (the check composites the board under the words with this)
static func veil_alpha(x: float, reach: float, a0: float) -> float:
	if x <= reach * 0.72:
		return lerpf(a0 + 0.02, a0, x / maxf(reach * 0.72, 1.0))
	if x >= reach:
		return 0.0
	return lerpf(a0, 0.0, (x - reach * 0.72) / (reach * 0.28))


# a soft dark corner: darkest at the screen corner c, fading smoothly over rx across and ry up or down; a grid of quads with
# the strength at each vertex, so there is no edge or disc to see
const CORNER_NX := 24
const CORNER_NY := 14


static func corner_alpha_at(u: float, v: float, a: float) -> float:
	var fu := clampf((1.0 - u) * 2.2, 0.0, 1.0)
	var fv := clampf((1.0 - v) * 2.2, 0.0, 1.0)
	return a * fu * fu * (3.0 - 2.0 * fu) * fv * fv * (3.0 - 2.0 * fv)


# the corner's strength at a screen point as drawn (the lowest vertex of the quad it falls in, so the check never
# overstates it)
static func corner_alpha(p: Vector2, c: Vector2, rx: float, ry: float, a: float) -> float:
	var u := absf(p.x - c.x) / rx
	var v := absf(p.y - c.y) / ry
	if u >= 1.0 or v >= 1.0:
		return 0.0
	var i := floorf(u * CORNER_NX)
	var j := floorf(v * CORNER_NY)
	var lo := 1.0
	for di in 2:
		for dj in 2:
			lo = minf(lo, corner_alpha_at((i + di) / CORNER_NX, (j + dj) / CORNER_NY, a))
	return lo


func _corner(c: Vector2, rx: float, ry: float, a: float) -> void:
	var sx := -1.0 if c.x > size.x * 0.5 else 1.0
	var sy := -1.0 if c.y > size.y * 0.5 else 1.0
	for i in CORNER_NX:
		for j in CORNER_NY:
			var u0 := float(i) / CORNER_NX
			var u1 := float(i + 1) / CORNER_NX
			var v0 := float(j) / CORNER_NY
			var v1 := float(j + 1) / CORNER_NY
			var pts := PackedVector2Array([Vector2(c.x + sx * u0 * rx, c.y + sy * v0 * ry), Vector2(c.x + sx * u1 * rx, c.y + sy * v0 * ry),
				Vector2(c.x + sx * u1 * rx, c.y + sy * v1 * ry), Vector2(c.x + sx * u0 * rx, c.y + sy * v1 * ry)])
			var cols := PackedColorArray([Color(0, 0, 0, corner_alpha_at(u0, v0, a)), Color(0, 0, 0, corner_alpha_at(u1, v0, a)),
				Color(0, 0, 0, corner_alpha_at(u1, v1, a)), Color(0, 0, 0, corner_alpha_at(u0, v1, a))])
			draw_polygon(pts, cols)


# the darkening under a screen point from every veil (stacked as the GPU blends them)
func dark_at(p: Vector2) -> float:
	var keep := 1.0
	for m in marks:
		match str(m["k"]):
			"veil":
				keep *= 1.0 - veil_alpha(p.x, float(m["reach"]), float(m["a0"]))
			"corner":
				keep *= 1.0 - corner_alpha(p, m["c"], float(m["rx"]), float(m["ry"]), float(m["a"]))
	return 1.0 - keep


# ---------------------------------------------------------------- the pointer

func _has_point(p: Vector2) -> bool:
	if _dirty:
		layout()
	if sheet_r.has_point(p):
		return true
	return hit_at(p) >= 0


func hit_at(p: Vector2) -> int:
	for i in range(hits.size() - 1, -1, -1):
		if Rect2(hits[i]["r"]).has_point(p):
			return i
	return -1


func _gui_input(e: InputEvent) -> void:
	if e is InputEventMouseMotion:
		var i := hit_at((e as InputEventMouseMotion).position)
		if i != _hover:
			_hover = i
			queue_redraw()
			mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if i >= 0 and str(hits[i]["act"]) != "" else Control.CURSOR_ARROW
			var tip := str(hits[i]["tip"]) if i >= 0 else ""
			hover_tip.emit(tip, (hits[i]["r"] as Rect2).position if i >= 0 else Vector2.ZERO)
	elif e is InputEventMouseButton and (e as InputEventMouseButton).pressed and (e as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		var i := hit_at((e as InputEventMouseButton).position)
		accept_event()
		if i >= 0 and str(hits[i]["act"]) != "":
			act.emit(str(hits[i]["act"]), hits[i]["arg"])
	elif e is InputEventMouseButton:
		# the wheel and the right button over the sheet do nothing (the board is not under it)
		accept_event()
