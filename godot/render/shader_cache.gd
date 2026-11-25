extends RefCounted
# Code is the full key, including any defines. Callers share the shader and own their material and uniforms.
# Resources in this cache are immutable and cleared by static_caches.gd before shutdown.

# Issue 1434 (merging PR 1967 into PR 1445): one shader keep for the game. This is the same run-wide keep as
# render/shader_keep.gd (which the load bench watches, so a long frame names a new shader); for_code hands it on.
const SKEEP := preload("res://render/shader_keep.gd")


static func for_code(code: String) -> Shader:
	return SKEEP.of(code)


static func clear_static() -> void:
	SKEEP.clear_static()
