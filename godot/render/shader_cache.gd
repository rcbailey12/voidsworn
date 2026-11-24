extends RefCounted
# Code is the full key, including any defines. Callers share the shader and own their material and uniforms.
# Resources in this cache are immutable and cleared by static_caches.gd before shutdown.

static var _shaders: Dictionary[String, Shader] = {}


static func for_code(code: String) -> Shader:
	if not _shaders.has(code):
		var shader := Shader.new()
		shader.code = code
		_shaders[code] = shader
	return _shaders[code]


static func clear_static() -> void:
	_shaders.clear()
