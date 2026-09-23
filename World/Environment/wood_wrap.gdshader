shader_type spatial;

uniform vec3 light_color : source_color = vec3(0.66, 0.40, 0.21);
uniform vec3 mid_color : source_color = vec3(0.48, 0.27, 0.13);
uniform vec3 dark_color : source_color = vec3(0.30, 0.16, 0.09);

uniform float grain_scale : hint_range(1.0, 30.0) = 7.0;
uniform float grain_warp : hint_range(0.0, 2.0) = 0.35;
uniform float color_variation : hint_range(0.0, 1.0) = 0.8;
uniform float end_grain_blend : hint_range(0.0, 1.0) = 0.65;

varying vec3 local_position;
varying vec3 local_normal;

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

vec3 wood_palette(float pattern) {
	vec3 color = dark_color;

	if (pattern > 0.38) {
		color = mid_color;
	}

	if (pattern > 0.65) {
		color = light_color;
	}

	return color;
}

void vertex() {
	local_position = VERTEX;
	local_normal = NORMAL;
}

void fragment() {
	// Grain on the sides: sample noise much more slowly along Y,
	// stretching the colour patches along the length of the log.
	vec3 side_sample = local_position *
		vec3(grain_scale, 0.35, grain_scale);

	float side_grain = value_noise(side_sample);
	side_grain = side_grain * 0.8
		+ value_noise(side_sample * 2.0) * 0.2;

	// Rings on the cut ends, centred on the mesh's local Y axis.
	float warp = value_noise(
		local_position * vec3(2.0, 0.4, 2.0)
	);

	float radius = length(local_position.xz);
	float end_grain = sin(
		radius * grain_scale * 6.28318
		+ warp * grain_warp * 6.28318
	);

	end_grain = end_grain * 0.5 + 0.5;

	// Faces pointing up or down show rings; side-facing surfaces
	// show lengthwise grain. Smooth blending helps on rounded meshes.
	float facing_end = abs(normalize(local_normal).y);
	float end_amount = smoothstep(
		end_grain_blend,
		min(end_grain_blend + 0.25, 1.0),
		facing_end
	);

	vec3 side_color = wood_palette(side_grain);
	vec3 end_color = wood_palette(end_grain);
	vec3 wood_color = mix(side_color, end_color, end_amount);

	ALBEDO = mix(mid_color, wood_color, color_variation);
	ROUGHNESS = 0.9;
	SPECULAR = 0.12;
}