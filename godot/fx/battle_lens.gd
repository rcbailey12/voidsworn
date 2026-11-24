extends CompositorEffect
# Issue 1779. Two small dispatches per visible lens. Stage the displaced pixels before writing any scene color.
const SHADER := """
#version 450
layout(local_size_x = 8, local_size_y = 8) in;
layout(rgba16f, set = 0, binding = 0) uniform image2D scene_color;
layout(rgba16f, set = 0, binding = 1) uniform image2D scratch;
layout(set = 0, binding = 2) uniform sampler2D scene_depth;
layout(push_constant, std430) uniform Params {
	vec4 bounds; // pixel origin and extent
	vec4 lens;   // center in pixels, radius in pixels, time of flight (negative for the Dead Star)
	vec4 state;  // foreground depth limit, copy-back switch, padding
} p;

vec4 sample_color(vec2 at, ivec2 limit) {
	vec2 pos = clamp(at, vec2(0), vec2(limit));
	ivec2 lo = ivec2(floor(pos));
	ivec2 hi = min(lo + 1, limit);
	vec2 f = fract(pos);
	return mix(mix(imageLoad(scene_color, lo), imageLoad(scene_color, ivec2(hi.x, lo.y)), f.x),
		mix(imageLoad(scene_color, ivec2(lo.x, hi.y)), imageLoad(scene_color, hi), f.x), f.y);
}

void main() {
	ivec2 local = ivec2(gl_GlobalInvocationID.xy);
	if (any(greaterThanEqual(local, ivec2(p.bounds.zw)))) {
		return;
	}
	ivec2 pixel = ivec2(p.bounds.xy) + local;
	if (p.state.y > 0.5) {
		imageStore(scene_color, pixel, imageLoad(scratch, local));
		return;
	}
	vec4 color = imageLoad(scene_color, pixel);
	vec2 radial = vec2(pixel) + 0.5 - p.lens.xy;
	float radius = p.lens.z;
	float d = length(radial) / radius;
	bool well = p.lens.w < 0.0;
	float wave = well
		? smoothstep(0.50, 0.69, d) * (1.0 - smoothstep(0.69, 1.0, d))
		: (1.0 - smoothstep(0.0, 0.19, abs(d - 0.8))) * (1.0 - p.lens.w);
	if (wave > 0.0 && (!well || texelFetch(scene_depth, pixel, 0).r <= p.state.x)) {
		ivec2 limit = imageSize(scene_color) - 1;
		float shift = min(well ? 3.0 : 4.0, radius * 0.07) * wave;
		vec2 src = vec2(pixel) + normalize(radial) * shift;
		// Reverse Z. Foreground ships and the opaque core are excluded at both ends of the sample.
		if (!well || texelFetch(scene_depth, clamp(ivec2(round(src)), ivec2(0), limit), 0).r <= p.state.x) {
			color = sample_color(src, limit);
		}
	}
	imageStore(scratch, local, color);
}
"""

var _mutex := Mutex.new()
var _well := Vector4.ZERO
var _shock := Vector4.ZERO
var _well_depth := 0.0
var _rd: RenderingDevice
var _shader := RID()
var _pipeline := RID()
var _sampler := RID()
var _prepared := false


func _init() -> void:
	effect_callback_type = EFFECT_CALLBACK_TYPE_POST_TRANSPARENT
	access_resolved_color = true
	access_resolved_depth = true
	enabled = false


func set_lenses(well: Vector4, well_depth: float, shock: Vector4) -> void:
	_mutex.lock()
	_well = well
	_well_depth = well_depth
	_shock = shock
	_mutex.unlock()
	var active := well.z > 0.0 or shock.z > 0.0
	if enabled != active:
		enabled = active


func warm() -> void:
	RenderingServer.call_on_render_thread(_prepare)


# Camera coordinates normalized to the viewport. Radius is measured in screen heights.
static func project_lens(camera: Camera3D, center: Vector3, radius: float, age: float) -> Vector4:
	if center == Vector3.INF or camera.is_position_behind(center):
		return Vector4.ZERO
	var size := camera.get_viewport().get_visible_rect().size
	if size.x < 1.0 or size.y < 1.0:
		return Vector4.ZERO
	var origin := camera.unproject_position(center)
	var edge := camera.unproject_position(center + camera.global_transform.basis.x * radius)
	var screen_radius := edge.x - origin.x
	var reach := Vector2.ONE * screen_radius
	if not Rect2(-reach, size + 2.0 * reach).has_point(origin):
		return Vector4.ZERO
	return Vector4(origin.x / size.x, origin.y / size.y, screen_radius / size.y, age)


func _prepare() -> bool:
	if _prepared:
		return _pipeline.is_valid() and _sampler.is_valid()
	_prepared = true
	_rd = RenderingServer.get_rendering_device()
	if _rd == null:
		return false
	var source := RDShaderSource.new()
	source.source_compute = SHADER
	var spirv := _rd.shader_compile_spirv_from_source(source)
	if not spirv.compile_error_compute.is_empty():
		push_error("Battle lens compute shader: " + spirv.compile_error_compute)
		return false
	_shader = _rd.shader_create_from_spirv(spirv)
	if not _shader.is_valid():
		return false
	_pipeline = _rd.compute_pipeline_create(_shader)
	_sampler = _rd.sampler_create(RDSamplerState.new())
	return _pipeline.is_valid() and _sampler.is_valid()


func _render_callback(_type: int, data: RenderData) -> void:
	_mutex.lock()
	var well := _well
	var shock := _shock
	var depth := _well_depth
	_mutex.unlock()
	if (well.z <= 0.0 and shock.z <= 0.0) or not _prepare():
		return
	var buffers := data.get_render_scene_buffers() as RenderSceneBuffersRD
	if buffers == null or buffers.get_view_count() != 1:
		return
	var size := buffers.get_internal_size()
	if size.x < 32 or size.y < 32:
		return
	var color := buffers.get_color_layer(0)
	var depth_texture := buffers.get_depth_layer(0)
	if not color.is_valid() or not depth_texture.is_valid():
		return
	var scratch_size := Vector2i(ceilf(size.x * 0.5), ceilf(size.y * 0.5))
	var scratch := buffers.create_texture(&"battle_lens", &"scratch", RenderingDevice.DATA_FORMAT_R16G16B16A16_SFLOAT,
		RenderingDevice.TEXTURE_USAGE_STORAGE_BIT, RenderingDevice.TEXTURE_SAMPLES_1, scratch_size, 1, 1, true, false)
	if not scratch.is_valid():
		return
	var uniforms := UniformSetCacheRD.get_cache(_shader, 0, [
		_uniform(0, RenderingDevice.UNIFORM_TYPE_IMAGE, [color]),
		_uniform(1, RenderingDevice.UNIFORM_TYPE_IMAGE, [scratch]),
		_uniform(2, RenderingDevice.UNIFORM_TYPE_SAMPLER_WITH_TEXTURE, [_sampler, depth_texture]),
	])
	if not uniforms.is_valid():
		return
	_dispatch(uniforms, size, scratch_size, well, depth)
	_dispatch(uniforms, size, scratch_size, shock, 0.0)


static func _uniform(binding: int, type: int, ids: Array[RID]) -> RDUniform:
	var uniform := RDUniform.new()
	uniform.binding = binding
	uniform.uniform_type = type
	for id in ids:
		uniform.add_id(id)
	return uniform


func _dispatch(uniforms: RID, size: Vector2i, scratch_size: Vector2i, lens: Vector4, depth: float) -> void:
	var radius := minf(lens.z * size.y, float(mini(scratch_size.x, scratch_size.y) - 2) * 0.5)
	if radius < 2.0:
		return
	var center := Vector2(lens.x * size.x, lens.y * size.y)
	var extent := Vector2.ONE * radius
	var min_corner := Vector2i((center - extent).floor()).clamp(Vector2i.ZERO, size)
	var max_corner := Vector2i((center + extent).ceil()).clamp(Vector2i.ZERO, size)
	var rect := max_corner - min_corner
	if rect.x <= 0 or rect.y <= 0:
		return
	var constants := PackedFloat32Array([
		min_corner.x, min_corner.y, rect.x, rect.y,
		center.x, center.y, radius, lens.w,
		depth, 0.0, 0.0, 0.0,
	])
	var groups := Vector2i(ceilf(rect.x / 8.0), ceilf(rect.y / 8.0))
	var list := _rd.compute_list_begin()
	_rd.compute_list_bind_compute_pipeline(list, _pipeline)
	_rd.compute_list_bind_uniform_set(list, uniforms, 0)
	_rd.compute_list_set_push_constant(list, constants.to_byte_array(), 48)
	_rd.compute_list_dispatch(list, groups.x, groups.y, 1)
	_rd.compute_list_add_barrier(list)
	constants[9] = 1.0
	_rd.compute_list_set_push_constant(list, constants.to_byte_array(), 48)
	_rd.compute_list_dispatch(list, groups.x, groups.y, 1)
	_rd.compute_list_end()


func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE and _rd != null:
		if _shader.is_valid():
			RenderingServer.call_on_render_thread(_rd.free_rid.bind(_shader)) # Frees its pipeline with it.
		if _sampler.is_valid():
			RenderingServer.call_on_render_thread(_rd.free_rid.bind(_sampler))
