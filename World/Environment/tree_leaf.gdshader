shader_type spatial;
render_mode cull_disabled;

uniform vec3 light_color : source_color = vec3(0.44, 0.67, 0.29);
uniform vec3 mid_color : source_color = vec3(0.24, 0.46, 0.20);
uniform vec3 dark_color : source_color = vec3(0.12, 0.29, 0.16);

uniform float pattern_scale : hint_range(0.5, 20.0) = 4.0;
uniform float color_variation : hint_range(0.0, 1.0) = 0.8;

uniform float wind_strength : hint_range(0.0, 0.2) = 0.02;
uniform float wind_speed : hint_range(0.0, 5.0) = 1.2;

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

	float sway = sin(TIME * wind_speed + VERTEX.x * 2.0 + VERTEX.z);
	float smaller_sway = sin(TIME * wind_speed * 1.7 + VERTEX.z * 3.0);

	VERTEX.x += sway * wind_strength;
	VERTEX.z += smaller_sway * wind_strength * 0.5;
}

void fragment() {
	float noise_value = value_noise(local_position * pattern_scale);

	vec3 leaf_color = dark_color;

	if (noise_value > 0.38) {
		leaf_color = mid_color;
	}

	if (noise_value > 0.62) {
		leaf_color = light_color;
	}

	ALBEDO = mix(mid_color, leaf_color, color_variation);
	ROUGHNESS = 0.95;
	SPECULAR = 0.1;
}