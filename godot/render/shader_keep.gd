extends RefCounted
# Issue 1434 (LOAD14: each new Shader resource compiled again on the main thread when a battle, the title backdrop or a
# squadron built its materials: the board's grid shaders 0.2 to 0.3 s, a Navy fighter wing 0.7 s, the effects shaders
# 0.6 s at every title). One Shader per source code for the whole session, so the second battle reuses the first one's
# compiled shader. Materials stay per object (their uniforms are their own); only the shared code is kept.
# GPU-holding static: render/static_caches.gd clears it before the engine exits.

static var _keep := {}   # shader code -> Shader
# issue 1434 (LOAD17: a 796 ms title draw with 0 pipelines, so shader source work, not pipelines): the load bench turns
# watch on and reads made each frame, so a long draw names the new shaders the frame before it made (not GPU: text)
static var watch := false
static var made: Array = []
static var seen := {}   # issue 1434 (LOAD19): every code hash made this launch -> where, for the bench's launch-to-launch check


static func of(code: String) -> Shader:
	var s: Shader = _keep.get(code)
	if s == null:
		s = Shader.new()
		s.code = code
		_keep[code] = s
		_note(code)
	return s


# a Shader built elsewhere (fx_hull.gd shared_shader) kept for the session too
static func keep(code: String, s: Shader) -> void:
	if not _keep.has(code):
		_note(code)
	_keep[code] = s


static func _note(code: String) -> void:
	if not watch:
		return
	var at := "?"
	for fr in get_stack().slice(2, 4):
		at = "%s:%d" % [str(fr["source"]).get_file(), int(fr["line"])]
		if not at.begins_with("fx_hull.gd"):
			break
	var h := "%08x" % (code.hash() & 0xffffffff)
	made.append("%s %s" % [at, h])
	seen[h] = at


static func take_made() -> String:
	if made.is_empty():
		return "-"
	var n := made.size()
	var said := ", ".join(PackedStringArray(made.slice(0, 6))) + (" and %d more" % (n - 6) if n > 6 else "")
	made.clear()
	return "%d: %s" % [n, said]


static func has(code: String) -> bool:
	return _keep.has(code)


static func get_kept(code: String) -> Shader:
	return _keep.get(code)


static func clear_static() -> void:
	_keep.clear()
	made.clear()
	seen.clear()
