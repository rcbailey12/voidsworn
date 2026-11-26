shader_type canvas_item;

void fragment() {
	// a base that can go negative, the undefined pow form
	float e = pow(a - b, 2.0);
	COLOR = vec4(vec3(e), 1.0);
}
