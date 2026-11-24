extends SceneTree
# Issue 1982/1645 R4STALL job helper (PC job r4stall, not in the repo). Runs scenes/battle/battle.tscn exactly as the
# 1558A frame-time run did (its own args after --), and keeps a reference to each --torp-ft record's own frame list
# (battle.torp_ft["ms"], one entry per frame in ms, filled by battle.gd itself), so every frame of every record is
# written on exit to <--torp-shots DIR>/r4stall_frames.json as {tag: [ms, ...]}. Measures nothing itself.
var b: Node = null
var recs := {}


func _initialize() -> void:
	b = load("res://scenes/battle/battle.tscn").instantiate()
	root.add_child(b)


func _process(_delta: float) -> bool:
	if b != null and is_instance_valid(b):
		var t = b.get("torp_ft")
		if t is Dictionary and not t.is_empty() and t.has("ms"):
			var tag := str(t["tag"])
			if not recs.has(tag):
				recs[tag] = t["ms"]
				print("[r4stall] record %s" % tag)
	return false


func _finalize() -> void:
	var a := OS.get_cmdline_user_args()
	var dir := ""
	for i in a.size() - 1:
		if a[i] == "--torp-shots":
			dir = a[i + 1]
	if dir == "":
		return
	var f := FileAccess.open(dir.path_join("r4stall_frames.json"), FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(recs))
		print("[r4stall] wrote %d records" % recs.size())
