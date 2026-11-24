extends RefCounted
# Issue 1410 (R368, Ryan, Nov 20 2026: "we need to start using the actual new ships for references rather than the old
# builds"): says which ship model a bench or capture drew, and flags an old Nov 1 hull. Benches pick ships by game id and
# class, so an old hull could end up in a reference picture unnoticed (the 1399 death bench drew I15_11's old prism).
#
# Read this before trusting a NEW: the `_parts_` test below detects the OLD Nov 1 LAYOUT only (a hull with no `_parts_`
# texture maps in assets/ships/manifest.json). It is not proof the model is the approved one (Artoo, Nov 20: B21_11 has
# parts maps but still waits on issue 1291). Hash-checking against the approved publish is a later job.
#
# Static functions only, no node. Read only: nothing here changes any asset (ShipView records hull_source and hull_res itself).

const MANIFEST := "res://assets/ships/manifest.json"

# Codes the guard lets through although their layout is OLD. O1_37 is the teaching station: its rebuild is tracked in
# issues 1767 and 1791, and until it lands the teaching battles keep it on purpose. Add a code here only with a ruling.
const TEACHING_EXCEPTIONS := ["O1_37"]

static var _rows = null


# The manifest's ship rows, read from the tracked file (never from a typed list), cached for the run.
static func rows() -> Dictionary:
	if _rows == null:
		_rows = {}
		if FileAccess.file_exists(MANIFEST):
			var parsed = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST))
			if parsed is Dictionary and parsed.get("ships") is Dictionary:
				_rows = parsed["ships"]
	return _rows


# "NEW" when the code's row lists any file containing `_parts_`, "OLD" when the row exists without one, "UNLISTED" when
# the manifest has no row for the code.
static func layout(code: String) -> String:
	var all := rows()
	if not all.has(code):
		return "UNLISTED"
	var row = all[code]
	var files = row.get("files", {}) if row is Dictionary else {}
	for f in files:
		if str(f).contains("_parts_"):
			return "NEW"
	return "OLD"


# For a built ShipView: {code, source, res}, the hull ShipView actually drew. ShipView.setup records the manifest section
# ("ships", "hi" or "hulls") and resource path of the hull it loaded successfully (hull_source, hull_res); an entry that
# is listed but fails to load (a mesh where a scene is required) is skipped there and so is never reported here (Astra
# audit of PR 1814, issue 1832). source is "placeholder" when nothing loaded (the plain block, e.g. a copy without gen/).
static func resolved(sv) -> Dictionary:
	var code := str(sv.code)
	var source := str(sv.hull_source)
	if source == "":
		return {"code": code, "source": "placeholder", "res": ""}
	return {"code": code, "source": source, "res": str(sv.hull_res)}


static func label(code: String) -> String:
	match layout(code):
		"NEW":
			return "%s NEW" % code
		"OLD":
			return "%s OLD hull" % code
	return "%s UNLISTED" % code


# "" when every code is NEW or a named teaching exception; otherwise a message naming each OLD or UNLISTED code.
# ALLOW_OLD_HULLS=1 in the environment turns the guard off (returns "" for everything).
static func guard(codes: Array) -> String:
	if OS.get_environment("ALLOW_OLD_HULLS") == "1":
		return ""
	var bad := []
	for c in codes:
		var code := str(c)
		if TEACHING_EXCEPTIONS.has(code) or layout(code) == "NEW":
			continue
		if not bad.has(code):
			bad.append(label(code))
	if bad.is_empty():
		return ""
	return "old or unlisted hull in a reference run: %s (set ALLOW_OLD_HULLS=1 to draw it on purpose; R368)" % ", ".join(bad)
