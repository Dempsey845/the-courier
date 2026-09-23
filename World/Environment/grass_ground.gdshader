shader_type spatial;

uniform vec3 light_color : source_color = vec3(0.43, 0.61, 0.25);
uniform vec3 mid_color : source_color = vec3(0.28, 0.48, 0.19);
uniform vec3 dark_color : source_color = vec3(0.17, 0.34, 0.15);

uniform float patch_size : hint_range(0.25, 20.0) = 4.0;
uniform float color_variation : hint_range(0.0, 1.0) = 0.8;

varying vec3 world_position;

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
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec3 sample_position = world_position / patch_size;

	float broad = value_noise(sample_position);
	float detail = value_noise(sample_position * 3.0);

	float pattern = broad * 0.8 + detail * 0.2;

	vec3 grass_color = dark_color;

	if (pattern > 0.42) {
		grass_color = mid_color;
	}

	if (pattern > 0.58) {
		grass_color = light_color;
	}

	ALBEDO = mix(mid_color, grass_color, color_variation);
	ROUGHNESS = 1.0;
	SPECULAR = 0.05;
}