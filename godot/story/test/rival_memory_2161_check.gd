extends SceneTree
# Issue 2161 (R436 C40, issue 1407, Artoo on PR 1880): the six rival memory lines that still said "last time" are
# rewritten as first-meeting lines: no "last time", and each still names the same play style it answers.
#   godot --headless --path godot --script res://story/test/rival_memory_2161_check.gd

const GUARD := preload("res://tools/ci/check_guard.gd")
# faction, memory key, a word the line must still carry (so it still answers that play style)
const SIX := [
	["voidsworn", "lance", "beams"], ["voidsworn", "board", "breach"],
	["hegemony", "sq", "strike wings"], ["hegemony", "battery", "battery"],
	["corsair", "lance", "beams"], ["corsair", "battery", "close fire"]]
const RETURN_WORDS := ["last time", "last round", "last fight", "last battle", "our last engagement"]

var failures := 0


func _init() -> void:
	GUARD.arm(self, "rival_memory_2161_check")
	_run.call_deferred()


func _check(ok: bool, message: String) -> void:
	if ok:
		print("  ok: ", message)
	else:
		failures += 1
		printerr("FAIL: ", message)


func _run() -> void:
	var raw := FileAccess.get_file_as_string("res://story/data/rival_lines.json")
	var RL = JSON.parse_string(raw)
	_check(RL is Dictionary, "rival_lines.json parses")
	if not (RL is Dictionary):
		quit(1)
		return
	_check(not raw.contains("\u2014"), "no em dashes in rival_lines.json")
	for e in SIX:
		var fac: String = e[0]
		var key: String = e[1]
		var line := str(RL.get(fac, {}).get("memory", {}).get(key, ""))
		_check(line != "", "%s memory.%s exists" % [fac, key])
		for w in RETURN_WORDS:
			_check(not line.to_lower().contains(w), "%s memory.%s does not say '%s': %s" % [fac, key, w, line])
		_check(line.to_lower().contains(str(e[2])), "%s memory.%s still answers the '%s' play style" % [fac, key, key])
		_check(line.count("{") == line.count("}"), "%s memory.%s keeps balanced placeholders" % [fac, key])
	if failures == 0:
		print("PASS: rival_memory_2161_check (the six memory lines read as first meetings)")
	else:
		printerr("FAIL: rival_memory_2161_check: %d failed" % failures)
	quit(0 if failures == 0 else 1)
