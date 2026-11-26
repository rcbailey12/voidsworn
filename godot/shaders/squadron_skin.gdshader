shader_type spatial;
uniform vec4 paint : source_color;
uniform float organic = 0.0;
varying vec3 local;
void vertex() { local = VERTEX; }
void fragment() {
    float grain = fract(sin(dot(floor(local * 420.0), vec3(12.989, 78.233, 41.17))) * 43758.54);
    float patch = fract(sin(dot(floor(local * 27.0), vec3(19.43, 17.71, 83.11))) * 43758.54);
    float vein = 1.0 - smoothstep(0.03, 0.11, abs(sin(local.x * 48.0 + sin(local.z * 39.0) * 2.2 + local.y * 17.0)));
    float scratch = step(0.987, grain) * (1.0 - organic);
    ALBEDO = paint.rgb * (0.84 + grain * 0.18 + patch * 0.15) * (1.0 - vein * organic * 0.28) + scratch * 0.11;
    ROUGHNESS = mix(0.62, 0.45, organic) + (grain - 0.5) * 0.16;
    METALLIC = mix(0.48, 0.03, organic);
}
