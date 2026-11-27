extends SceneTree
## Issue 1968. Evaluate the shipped shader expressions on the CPU, with no renderer.

const GUARD := preload("res://tools/ci/check_guard.gd")
const FX := preload("res://fx/fx_shaders.gd")
const WORLD := preload("res://world/world.gd")
const SKY := preload("res://world/world_sky.gd")
const LIVING := preload("res://world/world_living.gd")
const HEIGHT_1080 := 1080.0
const HEIGHT_2160 := 2160.0

var _failures := 0


func _init() -> void:
	GUARD.arm(self, "pixel_scale_check")
	_run.call_deferred()


func _check(ok: bool, message: String) -> void:
	if not ok:
		_failures += 1
		printerr("FAIL: " + message)


func _near(actual: float, expected: float, name: String) -> void:
	_check(is_finite(actual) and absf(actual - expected) <= absf(expected) * 0.000001 + 0.000000001,
		"%s got %.12f, expected %.12f" % [name, actual, expected])


func _rhs(code: String, name: String) -> String:
	var marker := " " + name + " = "
	_check(code.contains(marker), "missing shader assignment to " + name)
	return code.get_slice(marker, 1).get_slice(";", 0)


func _value(source: String, inputs: Dictionary) -> float:
	var expr := Expression.new()
	var code := source.replace("VIEWPORT_SIZE.y", "height").replace(" || ", " or ")
	var names := PackedStringArray(inputs.keys())
	if code.contains(" ? "):
		var arms := code.get_slice(" ? ", 1)
		return _value(arms.get_slice(" : ", 0) if _value(code.get_slice(" ? ", 0), inputs) != 0.0
			else arms.get_slice(" : ", 1), inputs)
	if expr.parse(code, names) != OK:
		_check(false, "cannot parse shader expression `%s`: %s" % [code, expr.get_error_text()])
		return NAN
	var result: Variant = expr.execute(inputs.values(), null, false)
	if expr.has_execute_failed():
		_check(false, "cannot evaluate shader expression `%s`: %s" % [code, expr.get_error_text()])
		return NAN
	return float(result)


func _ribbon(height: float) -> void:
	var code: String = FX.RIBBON.get_slice("void fragment() {", 1)
	var ratio := height / HEIGHT_1080
	# Every new beam's layers receive the same signed coordinate in 1080-line pixels.
	# Sample both sides, including a projected close-up width. A 4K framebuffer must
	# double the physical pixels per detail, not the reference width the shader sees.
	for width in [26.0, 60.0, 120.0]:
		for side in [-0.6, 0.0, 0.35]:
			var inputs := {"height": height, "vSide": side, "vPixels": width * ratio}
			inputs["fr"] = _value(_rhs(code, "fr"), inputs)
			_near(_value(_rhs(code, "beam_y"), inputs), side * width * 0.5,
				"beam detail at %dp, %.0f px base, side %.2f" % [height, width, side])
	_check(code.contains("beam_layers(k, s, beam_y,"), "layered beams consume the scaled signed width")


func _trail(height: float) -> void:
	var ratio := height / HEIGHT_1080
	var du := 0.2 / ratio  # A sample projection, in world units per render pixel.
	var kit := FX.kit_trail_code(8)
	for code in [FX.TRAIL, kit]:
		_check(_rhs(code, "du").ends_with("PROJECTION_MATRIX, VIEWPORT_SIZE.y)"), "trail uses the live pixel projection")
		var floor_world := _value(_rhs(code, "trail_floor"), {"du": du, "height": height})
		_near(floor_world / du, 10.0 * ratio, "trail pixel floor at %dp" % height)
	_check(FX.TRAIL.contains("w = max(w, trail_floor);"), "the ship trail applies its floor")
	_check(kit.contains("w = i < n ? max(w, trail_floor) : 0.0;"), "the kit trail applies its floor and collapses unused segments")


func _world(height: float) -> void:
	var ratio := height / HEIGHT_1080
	var angle_1080 := deg_to_rad(45.0) / HEIGHT_1080  # The value set by main's world builder.
	var angle_per_px := angle_1080 / ratio
	var star_px := _value(_rhs(SKY.SKY, "px"), {})
	var star_sig := _rhs(SKY.SKY, "sig").replace("mix(", "lerpf(")
	var faint_sigma := _value(star_sig, {"px": star_px, "m": 0.0})
	var bright_sigma := _value(star_sig, {"px": star_px, "m": 1.0})
	_near(star_px / angle_per_px, ratio, "sky reference pixel at %dp" % height)
	_check(faint_sigma / angle_per_px >= 0.7 * ratio, "faint star still lights adjacent pixels at %dp" % height)
	_check(bright_sigma / angle_per_px <= 1.0 * ratio and bright_sigma > faint_sigma,
		"bright stars are still pinpoints at %dp" % height)
	var depth := 500.0
	var dust: String = WORLD.DUST_SHADER
	var dust_inputs := {"height": height, "depth": depth, "px_1080": _value(_rhs(dust, "px_1080"), {})}
	dust_inputs["fr"] = _value(_rhs(dust, "fr"), dust_inputs)
	dust_inputs["px"] = _value(_rhs(dust, "px"), dust_inputs)
	_near(dust_inputs["px"], angle_per_px, "dust render pixel angle at %dp" % height)
	var dust_floor := _value(_rhs(dust, "mins"), dust_inputs)
	_near(dust_floor / (depth * angle_per_px), 1.6 * ratio, "dust pixel floor at %dp" % height)
	var attenuation := _value(_rhs(dust, "k"), {"size": 0.25, "mins": dust_floor})
	_near(attenuation, 0.25 / (depth * angle_1080 * 1.6), "dust attenuation at %dp" % height)

	var well: String = LIVING.WELL_SHADER
	# Sample an axis-aligned shift at full rim, with the screen texture matching the viewport.
	var shift := _rhs(well, "shift").replace(
		"normalize(dv + vec2(0.000001)) / vec2(textureSize(screen_tex, 0))", "1.0 / height")
	var fr := _value(_rhs(well, "fr"), {"height": height})
	var chroma := _value(_rhs(well, "chroma_px"), {})
	var offset := _value(shift, {"height": height, "chroma_px": chroma, "rim": 1.0, "fr": fr})
	_near(offset * height, 1.5 * ratio, "well chromatic shift at %dp" % height)


func _run() -> void:
	var world_code := FileAccess.get_file_as_string("res://world/world.gd")
	_check(not world_code.is_empty() and not world_code.contains('set_shader_parameter("px",'),
		"the world builder must leave star and dust sizes to their shaders")
	for height in [HEIGHT_1080, HEIGHT_2160]:
		_ribbon(height)
		_trail(height)
		_world(height)
	if _failures == 0:
		print("PASS: beam details, trail floors, stars, dust and well use their 1080-line sizes at both 1080p and 2160p")
	quit(1 if _failures else 0)
