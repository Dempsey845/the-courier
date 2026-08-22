shader_type spatial;

render_mode blend_mix, depth_draw_opaque, cull_back,
	diffuse_burley, specular_schlick_ggx;


// Petrification transition

uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform float transition_softness : hint_range(0.001, 0.25) = 0.06;
uniform float edge_width : hint_range(0.001, 0.25) = 0.045;

uniform float mesh_bottom = -1.0;
uniform float mesh_top = 1.0;


// Stone appearance

uniform vec4 stone_dark : source_color =
	vec4(0.12, 0.13, 0.14, 1.0);

uniform vec4 stone_colour : source_color =
	vec4(0.32, 0.34, 0.35, 1.0);

uniform vec4 stone_light : source_color =
	vec4(0.52, 0.54, 0.53, 1.0);

uniform vec4 transition_colour : source_color =
	vec4(0.72, 0.75, 0.68, 1.0);

uniform float stone_scale : hint_range(0.1, 20.0) = 4.0;
uniform float stone_contrast : hint_range(0.0, 2.0) = 0.8;

uniform float roughness : hint_range(0.0, 1.0) = 0.92;
uniform float metallic : hint_range(0.0, 1.0) = 0.0;


// Cracks

uniform vec4 crack_colour : source_color =
	vec4(0.025, 0.03, 0.035, 1.0);

uniform float crack_scale : hint_range(1.0, 40.0) = 11.0;
uniform float crack_width : hint_range(0.001, 0.2) = 0.035;
uniform float crack_strength : hint_range(0.0, 1.0) = 0.75;


// Transition shape

uniform float transition_noise_scale :
	hint_range(0.1, 20.0) = 3.0;

uniform float transition_noise_strength :
	hint_range(0.0, 0.5) = 0.12;


// Varying values

varying vec3 local_position;
varying vec3 world_position;


// Random and noise functions

float random_3d(vec3 value) {
	return fract(
		sin(dot(
			value,
			vec3(12.9898, 78.233, 37.719)
		)) * 43758.5453
	);
}


float value_noise(vec3 position) {
	vec3 cell = floor(position);
	vec3 fraction = fract(position);

	fraction = fraction * fraction * (
		3.0 - 2.0 * fraction
	);

	float n000 = random_3d(cell);
	float n100 = random_3d(cell + vec3(1.0, 0.0, 0.0));
	float n010 = random_3d(cell + vec3(0.0, 1.0, 0.0));
	float n110 = random_3d(cell + vec3(1.0, 1.0, 0.0));
	float n001 = random_3d(cell + vec3(0.0, 0.0, 1.0));
	float n101 = random_3d(cell + vec3(1.0, 0.0, 1.0));
	float n011 = random_3d(cell + vec3(0.0, 1.0, 1.0));
	float n111 = random_3d(cell + vec3(1.0, 1.0, 1.0));

	float bottom_1 = mix(n000, n100, fraction.x);
	float bottom_2 = mix(n010, n110, fraction.x);
	float top_1 = mix(n001, n101, fraction.x);
	float top_2 = mix(n011, n111, fraction.x);

	float bottom = mix(bottom_1, bottom_2, fraction.y);
	float top = mix(top_1, top_2, fraction.y);

	return mix(bottom, top, fraction.z);
}


float fractal_noise(vec3 position) {
	float result = 0.0;
	float amplitude = 0.5;

	for (int index = 0; index < 4; index++) {
		result += value_noise(position) * amplitude;
		position *= 2.03;
		amplitude *= 0.5;
	}

	return result;
}


void vertex() {
	local_position = VERTEX;
	world_position = (
		MODEL_MATRIX * vec4(VERTEX, 1.0)
	).xyz;
}


void fragment() {
	float mesh_height = max(mesh_top - mesh_bottom, 0.001);

	float height_position = clamp(
		(local_position.y - mesh_bottom) / mesh_height,
		0.0,
		1.0
	);

	// Uneven edge moving from the bottom to the top.
	float transition_noise = fractal_noise(
		world_position * transition_noise_scale
	);

	float noisy_height = height_position;
	noisy_height += (
		transition_noise - 0.5
	) * transition_noise_strength;

	float petrified_mask = 1.0 - smoothstep(
		progress - transition_softness,
		progress + transition_softness,
		noisy_height
	);

	// Prevent any stone remaining at exactly zero progress.
	petrified_mask *= smoothstep(
		0.0,
		0.015,
		progress
	);

	// Ensure the mesh is completely covered at progress 1.
	petrified_mask = mix(
		petrified_mask,
		1.0,
		smoothstep(0.985, 1.0, progress)
	);

	// Procedural stone surface.
	float large_stone_noise = fractal_noise(
		world_position * stone_scale
	);

	float fine_stone_noise = value_noise(
		world_position * stone_scale * 5.0
	);

	float stone_value = clamp(
		(large_stone_noise - 0.5) * stone_contrast + 0.5,
		0.0,
		1.0
	);

	vec3 final_stone_colour = mix(
		stone_dark.rgb,
		stone_colour.rgb,
		smoothstep(0.18, 0.55, stone_value)
	);

	final_stone_colour = mix(
		final_stone_colour,
		stone_light.rgb,
		smoothstep(0.62, 0.9, stone_value)
	);

	final_stone_colour *= mix(
		0.82,
		1.1,
		fine_stone_noise
	);

	// Thin procedural cracks.
	float crack_noise = fractal_noise(
		world_position * crack_scale
	);

	float crack_distance = abs(crack_noise - 0.5);

	float cracks = 1.0 - smoothstep(
		crack_width,
		crack_width * 2.5,
		crack_distance
	);

	// Break the cracks up so they do not cover everything.
	float crack_breakup = fractal_noise(
		world_position * crack_scale * 0.35
	);

	cracks *= smoothstep(0.43, 0.62, crack_breakup);
	cracks *= crack_strength;

	final_stone_colour = mix(
		final_stone_colour,
		crack_colour.rgb,
		cracks
	);

	// Highlight along the active petrification boundary.
	float edge_distance = abs(noisy_height - progress);

	float active_edge = 1.0 - smoothstep(
		edge_width,
		edge_width + transition_softness,
		edge_distance
	);

	active_edge *= step(0.001, progress);
	active_edge *= step(progress, 0.999);

	final_stone_colour = mix(
		final_stone_colour,
		transition_colour.rgb,
		active_edge * 0.75
	);

	ALBEDO = final_stone_colour;
	ROUGHNESS = roughness;
	METALLIC = metallic;

	// Slight surface roughness variation.
	NORMAL_MAP_DEPTH = mix(
		0.05,
		0.25,
		large_stone_noise
	);

	EMISSION = transition_colour.rgb
		* active_edge
		* 0.3;

	ALPHA = petrified_mask;

	// Remove the inactive transparent portion of the overlay.
	if (petrified_mask < 0.01) {
		discard;
	}
}