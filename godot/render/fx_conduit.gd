extends RefCounted
# A depth-tested, round effect path. The mesh gives the path a real silhouette at close zoom.
# The shader rolls the colour from a bright axial core to a soft sleeve, with a moving pattern.

const SH := preload("res://fx/fx_shaders.gd")

const SHADER := """
shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, fog_disabled, shadows_disabled;
""" + SH.COMMON + """
uniform vec4 tint : source_color = vec4(1.0);
uniform vec4 core : source_color = vec4(1.0);
uniform float gain = 0.0;
uniform float phase = 0.0;
uniform float pattern = 0.0;
uniform float pixels = 0.0;
uniform vec3 first_shift = vec3(0.0);
uniform vec3 last_shift = vec3(0.0);
varying vec3 radial;
varying vec3 eye;
void vertex() {
	vec3 offset = mix(first_shift, last_shift, UV.x);
	vec3 centre = (MODELVIEW_MATRIX * vec4(VERTEX - NORMAL * UV2.x + offset, 1.0)).xyz;
	float floor_r = px_world(pixels, -centre.z, PROJECTION_MATRIX);
	VERTEX += offset + NORMAL * max(0.0, floor_r * UV2.y - UV2.x);
	radial = MODELVIEW_NORMAL_MATRIX * NORMAL;
	eye = -centre;
}
void fragment() {
	float facing = clamp(abs(dot(radial, eye)) / max(length(radial) * length(eye), 0.001), 0.0, 1.0);
	float axial = pow(clamp(facing, 0., 1.), 5.);
	float x = UV.x;
	float travel = sin(6.2831853 * (x * 3.0 - phase * 1.6));
	float ribs = smoothstep(.1, .85, sin(6.2831853 * (x * 11.0 - phase)));
	float pulse = .66 + .34 * ribs;
	vec3 hue = tint.rgb;
	if (pattern == 1.) { // phase: a moving seam inside a quiet violet sheath
		pulse = .31 + .69 * smoothstep(.25, .97, travel);
	} else if (pattern == 2.) { // prism: pale glass with a restrained spectral edge
		vec3 split = .65 + .35 * cos(6.2831853 * (x * 2.5 - phase + vec3(0., .33, .67)));
		hue = mix(hue, split, .55 * (1. - axial));
		pulse = .48 + .52 * smoothstep(-.2, .9, travel);
	} else if (pattern == 3.) { // living tissue: a thicker rib and peristaltic wave
		pulse = .32 + .33 * ribs + .35 * smoothstep(-.5, .8, travel);
	} else if (pattern == 4.) { // current: narrow crawling banks, never a screen flash
		pulse = .58 + .42 * smoothstep(-.7, .8, travel);
	} else if (pattern == 5.) { // pod body: painted collars around a hot drive
		pulse = .42 + .32 * ribs + .26 * (1. - smoothstep(.05, .26, x));
	}
	ALBEDO = mix(hue * .68, core.rgb * 1.65, axial) * fx_gain;
	ALPHA = gain * (.28 * facing + .68 * axial) * mix(pulse, .72, fx_calm) * mix(1., .63, fx_calm);
}
"""


static func material(fx) -> ShaderMaterial:
	return fx.mat(SHADER, 1)


# UV2 carries the world radius and its taper so the projected pixel floor never squares off a tip.
static func mesh(path: PackedVector3Array, radii: PackedFloat32Array, sides: int) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var largest := 0.001
	for radius in radii:
		largest = maxf(radius, largest)
	var last := path.size() - 1
	for i in path.size():
		var axis := (path[mini(last, i + 1)] - path[maxi(0, i - 1)]).normalized()
		if axis == Vector3.ZERO:
			axis = Vector3.RIGHT
		var side := axis.cross(Vector3.UP).normalized()
		if side.length_squared() < 0.01:
			side = axis.cross(Vector3.RIGHT).normalized()
		var other := axis.cross(side)
		for j in sides + 1:
			var theta := TAU * float(j) / sides
			var n := side * cos(theta) + other * sin(theta)
			st.set_normal(n)
			st.set_uv(Vector2(float(i) / last, float(j) / sides))
			st.set_uv2(Vector2(radii[i], radii[i] / largest))
			st.add_vertex(path[i] + n * radii[i])
			if i > 0 and j > 0:
				var a := i * (sides + 1) + j
				var b := a - sides - 1
				for index in [a, b, a - 1, a - 1, b, b - 1]:
					st.add_index(index)
	return st.commit()


static func make(fx, path: PackedVector3Array, radii: PackedFloat32Array, tint: Color, core: Color,
		pattern: int, pixels: float, sides := 6) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.mesh = mesh(path, radii, sides)
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# Endpoint tracking and the pixel floor can grow beyond the unshifted mesh.
	node.extra_cull_margin = 24.0
	var mat := material(fx)
	mat.set_shader_parameter("tint", tint)
	mat.set_shader_parameter("core", core)
	mat.set_shader_parameter("pattern", float(pattern))
	mat.set_shader_parameter("pixels", pixels)
	mat.set_shader_parameter("gain", 0.0)
	node.material_override = mat
	return node
