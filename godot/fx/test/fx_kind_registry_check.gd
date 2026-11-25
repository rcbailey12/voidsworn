extends SceneTree
# Issue 2176: check the shared effect IDs without a renderer.

const FX := preload("res://fx/fx.gd")
const SH := preload("res://fx/fx_shaders.gd")
const BREACH := preload("res://fx/fx_breach.gd")
const OPERAND := "(-?\\d+|[A-Za-z_]\\w*)"
const COMPARE := "\\s*(?:==|!=|<=|>=|<|>)\\s*"

var failures := 0


func _init() -> void:
	var families := {
		"SPRITE": FX.SpriteKind,
		"STREAK": FX.StreakKind,
		"RING": FX.RingKind,
		"RIBBON": FX.RibbonKind,
		"DISTORT": FX.DistortKind,
		"BREACH": FX.BreachStyle,
	}
	for family: String in families:
		_check_unique(family, families[family])

	_check_shader("SPRITE", SH.SPRITE, "\\b(?:k|kind)\\b", FX.SpriteKind)
	_check_shader("STREAK", SH.STREAK, "\\b(?:k|kind)\\b", FX.StreakKind)
	_check_shader("RING", SH.RING, "\\b(?:k|rk|kind)\\b", FX.RingKind)
	_check_shader("RIBBON", SH.RIBBON, "\\b(?:k|kind)\\b", FX.RibbonKind)
	_check_shader("DISTORT", SH.DISTORT, "\\b(?:k|kind)\\b", FX.DistortKind)
	var hole_style := "(?:\\bstyle\\b|int\\(\\s*CUSTOM2\\.w\\s*\\+\\s*0\\.5\\s*\\))"
	_check_shader("HOLE", SH.HOLE, hole_style, FX.BreachStyle)
	_check_shader("MARK", SH.MARK, "\\bstyle\\b", FX.BreachStyle)
	_check_breach_mirror()

	if failures == 0:
		print("PASS: six effect kind families have unique IDs and cover their shader branches and breach styles")
	quit(1 if failures else 0)


func _fail(message: String) -> void:
	failures += 1
	printerr("FAIL: ", message)


func _check_unique(family: String, kinds: Dictionary) -> void:
	var seen := {}
	for kind: String in kinds:
		var id: int = kinds[kind]
		if seen.has(id):
			_fail("%s kind %d is assigned to both %s and %s" % [family, id, seen[id], kind])
		seen[id] = kind


func _check_shader(label: String, source: String, selector: String, kinds: Dictionary) -> void:
	# Ignore comments and the shared math helpers, which have their own unrelated loop index k.
	var comments := RegEx.create_from_string("(?s:/\\*.*?\\*/)|//[^\\n]*")
	var code := comments.sub(source.replace(SH.COMMON, ""), "", true)
	var constants := {}
	var declaration := RegEx.create_from_string("(?:\\bconst\\s+int\\s+(\\w+)\\s*=\\s*|#define\\s+(\\w+)\\s+)(-?\\d+)\\b(?!\\.)")
	for entry in declaration.search_all(code):
		var name := entry.get_string(1) if entry.get_string(1) != "" else entry.get_string(2)
		constants[name] = entry.get_string(3).to_int()

	var right := RegEx.create_from_string(selector + COMPARE + OPERAND + "(?![\\w.])")
	var left := RegEx.create_from_string("(?<![\\w.])" + OPERAND + COMPARE + selector)
	for comparison in right.search_all(code) + left.search_all(code):
		var value := comparison.get_string(1)
		var id: Variant = value.to_int() if value.is_valid_int() else constants.get(value)
		if not kinds.values().has(id):
			_fail("%s shader uses an unregistered kind in %s" % [label, comparison.get_string()])


func _check_breach_mirror() -> void:
	var breach_script: Script = BREACH
	var constants := breach_script.get_script_constant_map()
	for style: String in FX.BreachStyle:
		if constants.get("S_" + style) != FX.BreachStyle[style]:
			_fail("BREACH S_%s does not match fx.gd" % style)
	for name: String in constants:
		if name.begins_with("S_") and not FX.BreachStyle.has(name.trim_prefix("S_")):
			_fail("BREACH %s is missing from fx.gd" % name)
