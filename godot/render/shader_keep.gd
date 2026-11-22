extends RefCounted
# Issue 1434 (LOAD14: each new Shader resource compiled again on the main thread when a battle, the title backdrop or a
# squadron built its materials: the board's grid shaders 0.2 to 0.3 s, a Navy fighter wing 0.7 s, the effects shaders
# 0.6 s at every title). One Shader per source code for the whole session, so the second battle reuses the first one's
# compiled shader. Materials stay per object (their uniforms are their own); only the shared code is kept.
# GPU-holding static: render/static_caches.gd clears it before the engine exits.

static var _keep := {}   # shader code -> Shader


static func of(code: String) -> Shader:
	var s: Shader = _keep.get(code)
	if s == null:
		s = Shader.new()
		s.code = code
		_keep[code] = s
	return s


# a Shader built elsewhere (fx_hull.gd shared_shader) kept for the session too
static func keep(code: String, s: Shader) -> void:
	_keep[code] = s


static func has(code: String) -> bool:
	return _keep.has(code)


static func get_kept(code: String) -> Shader:
	return _keep.get(code)


static func clear_static() -> void:
	_keep.clear()
