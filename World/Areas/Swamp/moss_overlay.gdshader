shader_type spatial;

render_mode blend_mix, depth_draw_never, cull_back,
	diffuse_burley, specular_schlick_ggx;


uniform vec4 moss_color : source_color = vec4(
	0.30,
	0.42,
	0.06,
	1.0
);

uniform vec4 moss_highlight_color : source_color = vec4(
	0.52,
	0.62,
	0.10,
	1.0
);

uniform float roughness : hint_range(0.0, 1.0) = 0.9;

// Size of each pixel in world space.
uniform float pixels_per_unit : hint_range(1.0, 64.0, 1.0) = 12.0;

// Larger values create bigger moss clusters.
uniform float cluster_size : hint_range(0.1, 10.0, 0.1) = 2.5;

// How much of the suitable surface receives moss.
uniform float moss_coverage : hint_range(0.0, 1.0) = 0.55;

// Controls how far down the sides moss can grow.
uniform float minimum_upward_normal : hint_range(-1.0, 1.0) = 0.35;

// Softness of the slope transition.
uniform float slope_softness : hint_range(0.001, 1.0) = 0.2;

uniform float moss_opacity : hint_range(0.0, 1.0) = 1.0;

// Prevents the overlay from visually overlapping the original mesh.
uniform float surface_offset : hint_range(0.0, 0.02, 0.0001) = 0.002;

uniform vec2 moss_offset = vec2(0.0);

varying vec3 world_position;
varying vec3 world_normal;


float random_value(vec2 position) {
	return fract(
		sin(dot(position, vec2(127.1, 311.7))) *
		43758.5453
	);
}


float value_noise(vec2 position) {
	vec2 cell = floor(position);
	vec2 fraction = fract(position);

	float bottom_left = random_value(cell);
	float bottom_right = random_value(cell + vec2(1.0, 0.0));
	float top_left = random_value(cell + vec2(0.0, 1.0));
	float top_right = random_value(cell + vec2(1.0, 1.0));

	vec2 smooth_fraction = fraction * fraction *
		(3.0 - 2.0 * fraction);

	return mix(
		mix(bottom_left, bottom_right, smooth_fraction.x),
		mix(top_left, top_right, smooth_fraction.x),
		smooth_fraction.y
	);
}


void vertex() {
	VERTEX += NORMAL * surface_offset;

	world_position = (
		MODEL_MATRIX * vec4(VERTEX, 1.0)
	).xyz;

	world_normal = normalize(
		MODEL_NORMAL_MATRIX * NORMAL
	);
}


void fragment() {
	// Quantise the world position to create visible pixels.
	vec2 pixel_position = floor(
		(world_position.xz + moss_offset) *
		pixels_per_unit
	) / pixels_per_unit;

	// Large-scale noise produces connected moss clusters.
	float cluster_noise = value_noise(
		pixel_position * cluster_size
	);

	// Small noise breaks up the cluster edges.
	float detail_noise = random_value(
		floor(pixel_position * pixels_per_unit)
	);

	float moss_threshold = 1.0 - moss_coverage;

	float moss_mask = step(
		moss_threshold,
		cluster_noise + detail_noise * 0.18
	);

	// Restrict moss mainly to upward-facing geometry.
	float slope_mask = smoothstep(
		minimum_upward_normal - slope_softness,
		minimum_upward_normal + slope_softness,
		world_normal.y
	);

	moss_mask *= slope_mask;

	// Slight pixel-by-pixel colour variation.
	float highlight_mask = step(0.67, detail_noise);

	vec3 final_color = mix(
		moss_color.rgb,
		moss_highlight_color.rgb,
		highlight_mask
	);

	ALBEDO = final_color;
	ROUGHNESS = roughness;
	METALLIC = 0.0;

	ALPHA = moss_mask * moss_opacity;
}