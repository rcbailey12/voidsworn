extends SceneTree
const GUARD = preload("res://tools/ci/check_guard.gd")
# Headless check of the portrait lookup:
#   godot --headless --path godot --script res://portraits/test/portraits_check.gd
# Every admiral gets a face (painting or crest), painted admirals get their painting, every Nemesis in index.json composes
# with each scar kind its faction can take, and Eclipse faces change with restoration level while other
# factions ignore it. Prints PORTRAITS CHECK PASS or FAIL.

const Portraits := preload("res://portraits/portraits.gd")
const RUN4_ADMIRALS := [
	"vex", "kassar", "grax", "aelith", "nekhet", "matriarch",
	"ashgrove", "maren", "sable", "vaelen", "anuket", "mending",
]
const FIRST_PAINTINGS := ["ashgrove", "maren", "anuket"]
var fails: Array = []


func _ok(c: bool, msg: String) -> void:
	if not c:
		fails.append(msg)
		print("  FAIL ", msg)


func _init() -> void:
	GUARD.arm(self, "portraits_check")  # issue 632: a SCRIPT ERROR or a stuck run ends the check, never waits
	var crests = JSON.parse_string(FileAccess.get_file_as_string("res://portraits/crests/index.json"))
	var picks: Dictionary = Portraits._index().get("painted", {})
	var painted := 0
	for id in crests:
		var t: Texture2D = Portraits.face(id)
		var crest: Texture2D = Portraits.crest(id)
		_ok(t != null, "no face for " + id)
		_ok(crest != null, "no crest for " + id)
		if picks.has(id):
			painted += 1
			_ok(Portraits.has_painting(id) and t != crest, "picked painting for %s fell back to its crest" % id)
			_ok(t != null and t.get_width() >= 512, "painting for %s is too small" % id)
		else:
			_ok(not Portraits.has_painting(id) and t == crest, "unpainted admiral %s did not get its crest" % id)
	print("  admirals %d, painted %d" % [crests.size(), painted])
	_run4_check(picks, crests)
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


func _run4_check(picks: Dictionary, crests: Dictionary) -> void:
	for id in RUN4_ADMIRALS:
		var entry: Dictionary = picks.get(id, {})
		_ok(entry.get("faction", "") == crests[id]["faction"], "%s changed faction in the portrait index" % id)
		var run4 := "painted/%s.webp" % id
		var painting := Portraits._tex("res://portraits/" + run4)
		_ok(painting != null and painting.get_size() == Vector2(1024, 1024), "%s is missing its 1024 px run 4 painting" % id)
		var alts: Array = entry.get("alts", [])
		# Keep both versions selectable even if Ryan later swaps which one is picked.
		var choices: Array = alts + [entry.get("pick", "")]
		_ok(run4 in choices, "%s has no run 4 painting in its portrait choices" % id)
		if id not in FIRST_PAINTINGS:
			var previous := "alts/%s_pre1897.webp" % id
			_ok(previous in choices and FileAccess.file_exists("res://portraits/" + previous), "%s is missing its previous pick" % id)
	print("  run 4 portraits checked")


# Restoration frames (R78 Q17, issue 43): Eclipse portraits change with mastery level, every other
# faction ignores the level, and the change grows monotonically so each level reads.
func _restoration_check() -> void:
	var base: Texture2D = Portraits.face("nekhet")
	_ok(base != null, "no base face for nekhet")
	_ok(Portraits.face("nekhet", 0) == base, "level 0 must not reframe an Eclipse admiral")
	# Snapshot the plain face so a later in-place mark (the bleed face() guards against) is caught (opus_check_707 3a).
	var base_img: Image = base.get_image().duplicate() if base != null and base.get_image() != null else null
	var last := 0
	for lv in [1, 2, 3, 4, 5, 6, 7, 8]:
		var t: Texture2D = Portraits.face("nekhet", lv)
		_ok(t != null and t != base, "nekhet level %d shows no restoration frame" % lv)
		var diff := _diff_px(base, t)
		_ok(diff > last, "nekhet level %d adds no new marks (changed pixels %d, previous %d)" % [lv, diff, last])
		last = diff
	var plain_after: Texture2D = Portraits.face("nekhet")
	_ok(plain_after == base, "the plain face changed object after levelled calls")
	if base_img != null:
		_ok(_diff_px(ImageTexture.create_from_image(base_img), plain_after) == 0, "a levelled call marked the plain face in place (frame bleed)")
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
