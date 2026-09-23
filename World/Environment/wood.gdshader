shader_type spatial;

uniform vec3 light_color : source_color = vec3(0.66, 0.40, 0.21);
uniform vec3 mid_color : source_color = vec3(0.48, 0.27, 0.13);
uniform vec3 dark_color : source_color = vec3(0.30, 0.16, 0.09);

uniform float grain_scale : hint_range(1.0, 30.0) = 9.0;
uniform float grain_warp : hint_range(0.0, 2.0) = 0.35;
uniform float color_variation : hint_range(0.0, 1.0) = 0.7;

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
	float distance_from_center = length(local_position.xz);
	float warp = value_noise(local_position * vec3(3.0, 0.5, 3.0));

	float rings = sin(
		distance_from_center * grain_scale * 6.28318
		+ warp * grain_warp * 6.28318
		+ local_position.y * 0.5
	);

	vec3 wood_color = mid_color;

	if (rings > 0.35) {
		wood_color = light_color;
	} else if (rings < -0.45) {
		wood_color = dark_color;
	}

	ALBEDO = mix(mid_color, wood_color, color_variation);
	ROUGHNESS = 0.9;
	SPECULAR = 0.12;
}