shader_type canvas_item;

void fragment() {
	// the same base squared as a product, which is safe for negative values
	float e = (a - b) * (a - b);
	COLOR = vec4(vec3(e), 1.0);
}
