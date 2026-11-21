extends SceneTree
# Issue 1263: storm and nebula clouds must never end in a straight line. The cloud footprint texture (_mask: r the
# round field, g the edge feather) has to reach zero smoothly inside the texture on all four sides, with room for the
# shader's warp. Scans every texel row and column of a one-hex cloud, a dense storm block and a long nebula strip, in
# the storm and the nebula feather, and fails on any texel-to-texel drop in the faint outer band larger than a soft
# fade allows where it meets zero, or any non-zero edge texel (the shader's warp samples past the edge, where the clamp repeats it).

const GUARD := preload("res://tools/ci/check_guard.gd")
const WL := preload("res://world/world_living.gd")
const HIN := 8.660254
const FAINT := 0.0001    # the edge: one side of a texel pair is zero
const MAX_STEP := 0.01   # a soft fade arrives at zero flat; the old cut dropped 0.1 (one hex) to 0.27 (a hex row) to zero

var failures := 0


func _init() -> void:
	GUARD.arm(self, "cloud_edge_check")
	_run.call_deferred()


func _check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		print("FAIL: ", message)


func _hex(i: int, j: int) -> Vector3:
	# Neighbours sit 2 * HIN apart at multiples of 60 degrees, as in _mask's shared-edge test.
	return Vector3(i * 2.0 * HIN + j * HIN, 0.0, j * 2.0 * HIN * 0.8660254)


func _patches() -> Dictionary:
	var block: Array = []
	for j in 4:
		for i in 5:
			block.append(_hex(i - j / 2, j))
	var strip: Array = []
	for i in 7:
		strip.append(_hex(i, i % 2))
	return {"one hex": [Vector3.ZERO], "dense block": block, "strip": strip}


func _scan(name: String, img: Image) -> void:
	var w := img.get_width()
	var h := img.get_height()
	# Past the texture the shader clamps to its edge texels, so the outer two (the filter texel and its neighbour) are zero.
	var border := 2
	var worst := [0.0, 0.0]
	var border_bad := 0.0
	for channel in 2:
		for z in h:
			for x in w:
				var v := _at(img, x, z, channel)
				if x < border or z < border or x >= w - border or z >= h - border:
					border_bad = maxf(border_bad, v)
				for n in [Vector2i(x + 1, z), Vector2i(x, z + 1)]:
					if n.x >= w or n.y >= h: continue
					var u := _at(img, n.x, n.y, channel)
					if minf(u, v) > FAINT: continue
					worst[channel] = maxf(worst[channel], absf(u - v))
	print("%s: %dx%d texels, worst step onto zero r %.4f, g %.4f, edge texels %.4f" % [name, w, h, worst[0], worst[1], border_bad])
	_check(border_bad == 0.0, "%s: the texture's edge texels are %.4f, not zero (the clamp repeats them)" % [name, border_bad])
	_check(worst[0] <= MAX_STEP, "%s: round field steps %.4f in one texel (straight edge)" % [name, worst[0]])
	_check(worst[1] <= MAX_STEP, "%s: edge feather steps %.4f in one texel (straight edge)" % [name, worst[1]])


func _at(img: Image, x: int, z: int, channel: int) -> float:
	var c := img.get_pixel(x, z)
	return c.r if channel == 0 else c.g


func _run() -> void:
	_check(WL.GAS_FIELD_REACH >= WL.GAS_FEATHER_REACH + WL.GAS_WARP * sqrt(2.0),
		"the round field must outreach the feather plus the shader warp")
	_check(WL.GAS_CLOUD_MARGIN >= WL.GAS_FIELD_REACH + 1.0, "the texture margin must hold the field plus a filter texel")
	_check(WL.GAS_SHADER.contains("* %.1f;" % (WL.GAS_WARP * 2.0)), "GAS_SHADER's warp no longer matches GAS_WARP")
	# Run 2 (PC diagnosis): the visible straight edge was the cards' thin floor fade, the same height for every card.
	_check(WL.GAS_CARD_SUPPORT.contains("const float GAS_FLOOR_FADE = 5.0;") and WL.GAS_CARD_SUPPORT.contains("band < 0.5 ? GAS_FLOOR_FADE : 1.5"),
		"the bottom gas band must fade in over GAS_FLOOR_FADE (5), not the old 1.5")
	var gas := WL.new()
	gas.gas_route = "fog"
	var patches := _patches()
	for key in patches:
		for kind in [["storm", 1.5], ["nebula", 2.0]]:
			var mk: Array = gas._mask(patches[key], kind[1])
			_scan("%s %s" % [kind[0], key], mk[2])
	var span: float = gas.cloud_span()
	print("one hex cloud span %.1f units" % span)
	_check(span > 80.0 and span < 86.0, "the one hex cloud changed size (%.1f, was about 83)" % span)
	gas.free()
	print("cloud_edge_check: ", "PASS" if failures == 0 else "FAIL (%d)" % failures)
	quit(1 if failures > 0 else 0)
