extends SceneTree
const GUARD = preload("res://tools/ci/check_guard.gd")
# Headless check of the portrait lookup:
#   godot --headless --path godot --script res://portraits/test/portraits_check.gd
# Every admiral gets a face (painting or crest), painted admirals get their painting, every Nemesis in index.json composes
# with each scar kind its faction can take, and Eclipse faces change with restoration level while other
# factions ignore it. Prints PORTRAITS CHECK PASS or FAIL.

const Portraits := preload("res://portraits/portraits.gd")
var fails: Array = []


func _ok(c: bool, msg: String) -> void:
	if not c:
		fails.append(msg)
		print("  FAIL ", msg)


func _init() -> void:
	GUARD.arm(self, "portraits_check")  # issue 632: a SCRIPT ERROR or a stuck run ends the check, never waits
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
	_restoration_check()
	Portraits.clear_static()
	print("PORTRAITS CHECK ", "PASS" if fails.is_empty() else "FAIL (%d)" % fails.size())
	quit(0 if fails.is_empty() else 1)


# Restoration frames (R78 Q17, issue 43): Eclipse portraits change with mastery level, every other
# faction ignores the level, and the change grows monotonically so each level reads.
func _restoration_check() -> void:
	var base: Texture2D = Portraits.face("nekhet")
	_ok(base != null, "no base face for nekhet")
	_ok(Portraits.face("nekhet", 0) == base, "level 0 must not reframe an Eclipse admiral")
	var last := 0
	for lv in [1, 2, 3, 4, 5, 6, 7, 8]:
		var t: Texture2D = Portraits.face("nekhet", lv)
		_ok(t != null and t != base, "nekhet level %d shows no restoration frame" % lv)
		var diff := _diff_px(base, t)
		_ok(diff > last, "nekhet level %d adds no new marks (changed pixels %d, previous %d)" % [lv, diff, last])
		last = diff
	_ok(Portraits.face("nekhet", 8, 3) != Portraits.face("nekhet", 8), "capstone adds no hairline beyond level 8")
	_ok(_diff_px(Portraits.face("nekhet", 8), Portraits.face("nekhet", 8, 3)) > 0, "capstone hairline changes nothing")
	for other in ["vex", "grax", "matriarch", "aelith"]:
		_ok(Portraits.face(other, 8) == Portraits.face(other), "%s must ignore restoration level" % other)
	for id in ["sekhmar", "anuket", "khepra"]:
		_ok(Portraits.face(id, 4) != Portraits.face(id), "%s level 4 shows no restoration frame" % id)
	print("  restoration frames checked")


# Pixels that differ enough between two textures, counted at 256 px so the count is cheap and stable.
# Works on duplicates: an imported texture may share its image with the texture, and this must
# never mark the plain face.
func _diff_px(a: Texture2D, b: Texture2D) -> int:
	if a == null or b == null:
		return -1
	var ia: Image = null
	var ib: Image = null
	if a.get_image() != null:
		ia = a.get_image().duplicate()
	if b.get_image() != null:
		ib = b.get_image().duplicate()
	if ia == null or ib == null:
		return -1
	if ia.is_compressed():
		ia.decompress()
	if ib.is_compressed():
		ib.decompress()
	ia.resize(256, 256, Image.INTERPOLATE_BILINEAR)
	ib.resize(256, 256, Image.INTERPOLATE_BILINEAR)
	var n := 0
	for y in range(256):
		for x in range(256):
			var pa := ia.get_pixel(x, y)
			var pb := ib.get_pixel(x, y)
			if absf(pa.r - pb.r) + absf(pa.g - pb.g) + absf(pa.b - pb.b) > 0.2:
				n += 1
	return n
