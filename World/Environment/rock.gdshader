shader_type spatial;

uniform vec3 light_color : source_color = vec3(0.62, 0.58, 0.52);
uniform vec3 dark_color : source_color = vec3(0.23, 0.25, 0.25);
uniform vec3 highlight_color : source_color = vec3(0.78, 0.73, 0.64);

uniform float pattern_scale : hint_range(0.5, 20.0) = 4.0;
uniform float color_variation : hint_range(0.0, 1.0) = 0.35;
uniform float roughness_value : hint_range(0.0, 1.0) = 0.95;

varying vec3 local_position;

float hash_3d(vec3 p) {
	p = fract(p * 0.1031);
	p += dot(p, p.yxz + 33.33);
	return fract((p.x + p.y) * p.z);
}

float value_noise(vec3 p) {
	vec3 cell = floor(p);
	vec3 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);

	float a = mix(hash_3d(cell), hash_3d(cell + vec3(1.0, 0.0, 0.0)), f.x);
	float b = mix(hash_3d(cell + vec3(0.0, 1.0, 0.0)),
				  hash_3d(cell + vec3(1.0, 1.0, 0.0)), f.x);
	float c = mix(hash_3d(cell + vec3(0.0, 0.0, 1.0)),
				  hash_3d(cell + vec3(1.0, 0.0, 1.0)), f.x);
	float d = mix(hash_3d(cell + vec3(0.0, 1.0, 1.0)),
				  hash_3d(cell + vec3(1.0, 1.0, 1.0)), f.x);

	return mix(mix(a, b, f.y), mix(c, d, f.y), f.z);
}

void vertex() {
	local_position = VERTEX;
}

void fragment() {
	float noise_value = value_noise(local_position * pattern_scale);

	// Turn smooth noise into distinct colour regions.
	float patches = floor(noise_value * 4.0) / 3.0;
	vec3 base_color = mix(dark_color, light_color, patches);

	// Add pale flecks on the brightest patches.
	float flecks = step(0.76, noise_value);
	base_color = mix(base_color, highlight_color, flecks * 0.55);

	ALBEDO = mix(light_color, base_color, color_variation);
	ROUGHNESS = roughness_value;
	SPECULAR = 0.15;
}