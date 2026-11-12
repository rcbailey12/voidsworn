extends SceneTree
# Issue 588, HD6: the battle log view keeps the newest 200 entries, the browser's cap (ui3d.js log(): while
# el.childNodes.length > 200 remove the first child). The rules' own log array is never capped: saves, the debrief and
# the rules oracle still see every entry. This drives the HUD's real add path (hud.gd add_log) and checks both sides.
#   godot --headless --path godot --script res://ui/battle/test/battle_log_cap_test.gd

const HUD := preload("res://ui/battle/hud.gd")
const API := preload("res://rules/battle_api.gd")
const VIEW_CAP := 200

var fails := 0


func check(ok: bool, what: String) -> void:
	if ok:
		print("PASS: " + what)
	else:
		fails += 1
		print("FAIL: " + what)


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var h = HUD.new()
	root.add_child(h)
	await process_frame
	await process_frame

	# A real rules battle so its own log array exists beside the HUD's view. The HUD never receives this array.
	var api = API.new()
	var err: String = api.load_rules()
	check(err == "", "the rules load for the reference log" + (": " + err if err != "" else ""))
	api.new_battle_scenario("s1")
	var rules_log: Array = api.R.B.get("log", [])
	var rules_before := rules_log.size()
	var rules_text := JSON.stringify(rules_log)

	# A long fight: 260 entries in through the HUD's own add path.
	for i in 260:
		h.add_log("line-%03d" % i, "x")
	var parsed: String = h.log_text.get_parsed_text()
	var lines: Array = Array(parsed.split("\n", false))
	check(lines.size() == VIEW_CAP, "the view keeps %d entries (%d)" % [VIEW_CAP, lines.size()])
	# Each entry ends in a newline, leaving one empty paragraph after the last entry.
	check(h.log_text.get_paragraph_count() == VIEW_CAP + 1, "the view holds %d entries plus the trailing empty paragraph (%d)" % [VIEW_CAP, h.log_text.get_paragraph_count()])
	check(lines.size() > 0 and str(lines[lines.size() - 1]).contains("line-259"), "the newest entry stays in the view")
	check(not parsed.contains("line-000"), "the oldest entry leaves the view")
	check(parsed.contains("line-060") and not parsed.contains("line-059"), "the first kept entry is entry 60, so the view holds the newest 200")
	check(h._log_lines.size() == VIEW_CAP, "the sheet's plain line list also keeps %d entries (%d)" % [VIEW_CAP, h._log_lines.size()])
	check(str(h._log_lines[0]).contains("line-060") and str(h._log_lines[VIEW_CAP - 1]).contains("line-259"), "the plain line list starts at entry 60 and ends at entry 259")

	check(rules_log.size() == rules_before, "the rules log still holds all %d entries" % rules_before)
	check(JSON.stringify(rules_log) == rules_text, "the rules log array is byte for byte unchanged")

	# A short fight: nothing is dropped at all.
	h.log_text.clear()
	h._log_lines.clear()
	for i in 5:
		h.add_log("short-%d" % i, "x")
	check(h.log_text.get_paragraph_count() == 6, "five entries make five view entries plus the trailing empty paragraph (%d)" % h.log_text.get_paragraph_count())
	check(h._log_lines.size() == 5 and h.log_text.get_parsed_text().contains("short-0"), "a short fight keeps every entry")

	print("battle log cap: %d checks failed" % fails)
	quit(1 if fails > 0 else 0)
