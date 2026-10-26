extends SceneTree
# Headless check of the portrait lookup:
#   godot --headless --path godot --script res://portraits/test/portraits_check.gd
# Every admiral gets a face (painting or crest), painted admirals get their painting, every Nemesis in index.json composes
# with each scar kind its faction can take. Prints PORTRAITS CHECK PASS or FAIL.

const Portraits := preload("res://portraits/portraits.gd")
var fails: Array = []


func _ok(c: bool, msg: String) -> void:
	if not c:
		fails.append(msg)
		print("  FAIL ", msg)


func _init() -> void:
	var crests = JSON.parse_string(FileAccess.get_file_as_string("res://portraits/crests/index.json"))
	var painted := 0
	for id in crests:
		var t: Texture2D = Portraits.face(id)
		_ok(t != null, "no face for " + id)
		_ok(Portraits.crest(id) != null, "no crest for " + id)
		if Portraits.has_painting(id):
			painted += 1
			_ok(t != null and t.get_width() >= 512, "painting for %s is too small" % id)
	print("  admirals %d, painted %d" % [crests.size(), painted])
	_ok(painted >= 7, "expected at least 7 painted admirals, got %d" % painted)
	var sc = JSON.parse_string(FileAccess.get_file_as_string("res://portraits/nemesis/scars/scars.json"))
	var nem := 0
	for fac in ["voidsworn", "hegemony", "corsair", "chorus", "ithar", "deathless"]:
		for id in Portraits.nemesis_ids(fac):
			var n := int(String(id).get_slice("_", 2))
			nem += 1
			_ok(Portraits.nemesis(fac, n, []) != null, "no Nemesis portrait for " + id)
			var kinds: Array = []
			for k in sc["kinds"]:
				if fac in sc["kinds"][k]:
					kinds.append(k)
			for k in kinds:
				_ok(Portraits.nemesis(fac, n, [k]) != null, "%s with scar %s" % [id, k])
			_ok(Portraits.nemesis(fac, n, kinds) != null, "%s with all scars" % id)
	print("  Nemesis portraits %d" % nem)
	Portraits.clear_static()
	print("PORTRAITS CHECK ", "PASS" if fails.is_empty() else "FAIL (%d)" % fails.size())
	quit(0 if fails.is_empty() else 1)
