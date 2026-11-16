extends SceneTree
const GUARD = preload("res://tools/ci/check_guard.gd")
const CampaignScript = preload("res://campaign/campaign.gd")
const UIScript = preload("res://ui/campaign/campaign_ui.gd")
const Portraits = preload("res://portraits/portraits.gd")
# Issue 737 (Muse opus_check_707 condition 3b): the campaign screen's levelled face path.
# The campaign hook in godot/ui/campaign/campaign_ui.gd _face() reads an Eclipse admiral's restoration
# level from the campaign and hands it to Portraits.face. This check drives that hook for one Eclipse
# admiral at mastery levels 0, 3 and 8 and proves:
#   1. the level reaches portraits.face: each level returns exactly the picture that level draws, and the
#      picture changes with level, so the portrait can never freeze at the first level shown (the hook's
#      cache key must carry the level);
#   2. the faction the hook tests (C.ADMIRALS[id].fac) and the faction portraits.gd reads from
#      crests/index.json agree for every admiral, failing by name when they differ.
# Run: godot --headless --path godot --script res://portraits/test/campaign_face_check.gd

const ADMIRAL := "nekhet"   # an Eclipse (deathless) admiral with a lineage tree, so levels 0 to 8 exist
const LEVELS := [0, 3, 8]
const XP := {0: 0.0, 3: 30.0, 8: 230.0}   # LINEAGE_XP thresholds: level 3 opens at 30 XP, level 8 at 230

var fails: Array = []


func _ok(c: bool, msg: String) -> void:
	if not c:
		fails.append(msg)
		print("  FAIL ", msg)


func _init() -> void:
	GUARD.arm(self, "campaign_face_check")  # issue 632: a SCRIPT ERROR or a stuck run ends the check, never waits
	var C = CampaignScript.new()
	var err = C.load_tables()
	if err != "":
		print("CAMPAIGN FACE CHECK FAIL: ", err)
		quit(1); return
	if not C.ADMIRALS.has(ADMIRAL):
		print("CAMPAIGN FACE CHECK FAIL: no admiral ", ADMIRAL, " in C.ADMIRALS")
		quit(1); return
	if not C.LINEAGE_TREES.has(ADMIRAL):
		print("CAMPAIGN FACE CHECK FAIL: ", ADMIRAL, " has no lineage tree, so level 8 does not exist")
		quit(1); return
	C.META = C.migrateMeta(C.defaultMeta())
	var ui = UIScript.new()
	ui.C = C   # the campaign UI's own face path, without building the screens (headless, no window)

	# 1. the level reaches portraits.face and the picture changes with level
	var shots := {}
	for lv in LEVELS:
		C.META["mastery"][ADMIRAL] = XP[lv]
		var got: Texture2D = ui._face(ADMIRAL)
		var want: Texture2D = Portraits.face(ADMIRAL, lv)
		shots[lv] = got
		_ok(C.masteryLevel(ADMIRAL) == lv, "campaign mastery for %s must be %d, got %d" % [ADMIRAL, lv, C.masteryLevel(ADMIRAL)])
		_ok(got != null, "campaign face for %s at level %d is null" % [ADMIRAL, lv])
		_ok(got == want, "campaign face at level %d does not reach portraits.face level %d: the level is lost before the portrait" % [lv, lv])
	_ok(ui._faces.size() == LEVELS.size(), "the campaign face cache keeps one entry per level, found %d of %d (a key without the level freezes the portrait)" % [ui._faces.size(), LEVELS.size()])
	_ok(shots[0] != shots[3] and shots[3] != shots[8] and shots[0] != shots[8], "the campaign portrait is frozen at one picture across levels 0, 3 and 8")
	_ok(_diff_px(shots[0], shots[3]) > 0, "levels 0 and 3 draw the same pixels: the level never reached the picture")
	_ok(_diff_px(shots[3], shots[8]) > 0, "levels 3 and 8 draw the same pixels: the level never reached the picture")
	_ok(ui._face(ADMIRAL) == shots[8], "asking for the same level twice returns a different picture: the cache misses")

	# 2. the campaign hook and portraits.gd agree on every admiral's faction, by name
	var n := 0
	for id in C.ADMIRALS:
		var hook := str(C.ADMIRALS[id].get("fac", ""))
		var portrait := str(Portraits._restore_faction(str(id)))
		n += 1
		_ok(hook == portrait, "%s: campaign faction '%s' but portraits.gd reads '%s' from crests/index.json" % [id, hook, portrait])
	_ok(n == C.ADMIRALS.size() and n > 0, "checked %d of %d admirals" % [n, C.ADMIRALS.size()])

	if fails.is_empty():
		print("PASS campaign face: levels 0, 3 and 8 each reach portraits.face and the picture changes with level")
		print("PASS campaign face: C.ADMIRALS faction matches crests/index.json for all %d admirals, by name" % n)
	print("CAMPAIGN FACE CHECK ", "PASS" if fails.is_empty() else "FAIL (%d)" % fails.size())
	Portraits.clear_static()
	ui.free()   # the campaign UI is made outside the tree, so free it here (a bare Node waits for the tree)
	quit(0 if fails.is_empty() else 1)


# Pixels that differ enough between two textures, counted at 256 px so the count is cheap and stable.
# Works on duplicates: an imported texture may share its image with the texture, and this must never
# mark a face.
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
