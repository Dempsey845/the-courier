shader_type spatial;

render_mode blend_mix, depth_draw_opaque, cull_disabled,
	diffuse_burley, specular_schlick_ggx;


// Scene depth used for intersection foam.

uniform sampler2D depth_texture :
	hint_depth_texture,
	repeat_disable,
	filter_linear;

// Colours

uniform vec4 shallow_color : source_color =
	vec4(0.16, 0.69, 0.65, 0.85);

uniform vec4 deep_color : source_color =
	vec4(0.024, 0.24, 0.29, 0.93);

uniform vec4 highlight_color : source_color =
	vec4(0.73, 1.0, 0.91, 1.0);

uniform vec4 foam_color : source_color =
	vec4(0.91, 1.0, 0.95, 1.0);


// Surface appearance

uniform float roughness : hint_range(0.0, 1.0) = 0.22;
uniform float metallic : hint_range(0.0, 1.0) = 0.0;
uniform float specular : hint_range(0.0, 1.0) = 0.75;


// Waves

uniform float wave_height : hint_range(0.0, 5.0) = 0.8;
uniform float wave_scale : hint_range(0.001, 1.0) = 0.055;
uniform float wave_speed : hint_range(0.0, 5.0) = 0.65;

uniform vec2 wave_direction_1 = vec2(1.0, 0.35);
uniform vec2 wave_direction_2 = vec2(-0.4, 1.0);


// Stylisation

uniform float pattern_scale : hint_range(0.001, 2.0) = 0.035;
uniform float pattern_speed : hint_range(0.0, 5.0) = 0.18;

uniform float highlight_amount : hint_range(0.0, 1.0) = 0.32;
uniform float highlight_sharpness : hint_range(0.1, 10.0) = 5.0;

uniform float pixelation : hint_range(0.1, 256.0, 0.1) = 1.5;


// Foam patches

uniform float foam_amount : hint_range(0.0, 1.0) = 0.10;
uniform float foam_scale : hint_range(0.001, 2.0) = 0.08;
uniform float foam_speed : hint_range(0.0, 5.0) = 0.12;

// Foam around intersecting meshes.

uniform float edge_foam_width : hint_range(0.01, 10.0) = 3.0;
uniform float edge_foam_softness : hint_range(0.01, 2.0) = 0.6;
uniform float edge_foam_noise_scale : hint_range(0.01, 10.0) = 0.24;
uniform float edge_foam_noise_strength : hint_range(0.0, 1.0) = 0.35;
uniform float edge_foam_speed : hint_range(0.0, 5.0) = 0.16;


// Fresnel

uniform float fresnel_strength : hint_range(0.0, 2.0) = 0.35;
uniform float fresnel_power : hint_range(0.1, 10.0) = 3.5;

varying vec3 vertex_world_position;

// Generates a random 2D direction.

vec2 random_gradient(vec2 position) {
	position = vec2(
		dot(position, vec2(127.1, 311.7)),
		dot(position, vec2(269.5, 183.3))
	);

	return -1.0 + 2.0 * fract(
		sin(position) * 43758.5453123
	);
}

uniform float edge_fade_start : hint_range(0.0, 1.0) = 0.82;
uniform float edge_fade_end : hint_range(0.0, 1.0) = 0.98;

varying vec2 water_uv;


// Smooth gradient noise without obvious square cells.

float gradient_noise(vec2 position) {
	vec2 cell = floor(position);
	vec2 local_position = fract(position);

	// Quintic interpolation gives smoother cell transitions.
	vec2 blend = local_position *
		local_position *
		local_position *
		(
			local_position *
			(local_position * 6.0 - 15.0) +
			10.0
		);

	float bottom_left = dot(
		random_gradient(cell),
		local_position
	);

	float bottom_right = dot(
		random_gradient(cell + vec2(1.0, 0.0)),
		local_position - vec2(1.0, 0.0)
	);

	float top_left = dot(
		random_gradient(cell + vec2(0.0, 1.0)),
		local_position - vec2(0.0, 1.0)
	);

	float top_right = dot(
		random_gradient(cell + vec2(1.0, 1.0)),
		local_position - vec2(1.0, 1.0)
	);

	float bottom = mix(
		bottom_left,
		bottom_right,
		blend.x
	);

	float top = mix(
		top_left,
		top_right,
		blend.x
	);

	return mix(bottom, top, blend.y) * 0.5 + 0.5;
}


// Rotating each octave prevents a visible square grid.

float fractal_noise(vec2 position) {
	float result = 0.0;
	float amplitude = 0.52;
	float total_amplitude = 0.0;

	mat2 octave_rotation = mat2(
		vec2(0.80, 0.60),
		vec2(-0.60, 0.80)
	);

	for (int index = 0; index < 4; index++) {
		result += gradient_noise(position) * amplitude;
		total_amplitude += amplitude;

		position =
			octave_rotation *
			position *
			2.03 +
			vec2(13.7, 9.2);

		amplitude *= 0.5;
	}

	return result / total_amplitude;
}


void vertex() {
	water_uv = UV;
	
	vec2 world_position = (
		MODEL_MATRIX *
		vec4(VERTEX, 1.0)
	).xz;

	vec2 direction_1 = normalize(wave_direction_1);
	vec2 direction_2 = normalize(wave_direction_2);

	float first_wave = sin(
		dot(world_position, direction_1) * wave_scale +
		TIME * wave_speed
	);

	float second_wave = sin(
		dot(world_position, direction_2) *
		wave_scale *
		1.73 -
		TIME *
		wave_speed *
		1.28
	);

	float small_wave = sin(
		(world_position.x + world_position.y) *
		wave_scale *
		3.2 +
		TIME *
		wave_speed *
		1.7
	);

	VERTEX.y += (
		first_wave * 0.5 +
		second_wave * 0.35 +
		small_wave * 0.15
	) * wave_height;
	
	vertex_world_position = (
		MODEL_MATRIX *
		vec4(VERTEX, 1.0)
	).xyz;
}


void fragment() {
	vec2 world_position = vertex_world_position.xz;

	vec2 pixel_position = world_position;


	// Broad colour variation.

	vec2 color_position =
		pixel_position * pattern_scale;

	float color_noise_1 = fractal_noise(
		color_position * 0.55 +
		vec2(
			TIME * pattern_speed * 0.18,
			TIME * pattern_speed * 0.09
		)
	);

	float color_noise_2 = fractal_noise(
		color_position * 1.3 +
		vec2(
			-TIME * pattern_speed * 0.1,
			TIME * pattern_speed * 0.16
		)
	);

	float water_mix = clamp(
		color_noise_1 * 0.72 +
		color_noise_2 * 0.28,
		0.0,
		1.0
	);

	water_mix = smoothstep(
		0.18,
		0.82,
		water_mix
	);

	vec4 water_color = mix(
		deep_color,
		shallow_color,
		water_mix
	);


	// Distort the wave coordinates with broad noise.

	vec2 wave_position =
		pixel_position * pattern_scale;

	float coordinate_warp = fractal_noise(
		wave_position * 0.45 +
		vec2(
			TIME * pattern_speed * 0.12,
			-TIME * pattern_speed * 0.08
		)
	);

	coordinate_warp =
		coordinate_warp * 2.0 - 1.0;

	vec2 warped_position =
		wave_position +
		vec2(
			coordinate_warp,
			-coordinate_warp * 0.65
		) * 1.8;


	// Organic directional wave crests.
	//
	// One main direction avoids the crossed grid pattern.
	// Noise bends and breaks the lines into separate wavelets.

	float fine_warp = fractal_noise(
		wave_position * 1.25 +
		vec2(
			-TIME * pattern_speed * 0.11,
			TIME * pattern_speed * 0.08
		)
	);

	fine_warp = fine_warp * 2.0 - 1.0;

	vec2 crest_direction =
		normalize(vec2(1.0, 0.38));

	float wave_field_1 = sin(
		dot(
			warped_position,
			crest_direction
		) * 4.0 +
		fine_warp * 2.4 +
		TIME * pattern_speed * 1.5
	);

	wave_field_1 =
		wave_field_1 * 0.5 + 0.5;


	// Only retain a narrow part of each wave.

	float wave_crests = smoothstep(
		0.80,
		0.96,
		wave_field_1
	);


	// Use two different noise scales to break the lines apart.

	float large_breakup = fractal_noise(
		wave_position * 1.4 +
		vec2(
			TIME * pattern_speed * 0.12,
			-TIME * pattern_speed * 0.07
		)
	);

	float small_breakup = fractal_noise(
		wave_position * 3.7 +
		vec2(
			-TIME * pattern_speed * 0.2,
			TIME * pattern_speed * 0.13
		)
	);

	float crest_breakup = mix(
		large_breakup,
		small_breakup,
		0.35
	);

	crest_breakup = smoothstep(
		0.44,
		0.63,
		crest_breakup
	);


	// Vary the strength so the crests don't look uniform.

	float crest_strength = mix(
		0.45,
		1.0,
		large_breakup
	);

	float highlight_mask =
		wave_crests *
		crest_breakup *
		crest_strength *
		highlight_amount;


	// Small isolated surface highlights.

	float sparkle_noise = fractal_noise(
		wave_position * 4.0 +
		vec2(
			TIME * pattern_speed * 0.4,
			TIME * pattern_speed * 0.16
		)
	);

	float sparkle_mask = smoothstep(
		0.73,
		0.86,
		sparkle_noise
	);

	sparkle_mask *= smoothstep(
		0.65,
		0.94,
		wave_field_1
	);

	highlight_mask = clamp(
		highlight_mask +
		sparkle_mask * highlight_amount * 0.45,
		0.0,
		1.0
	);


	// Scattered surface foam.

	vec2 foam_position =
		pixel_position * foam_scale +
		vec2(
			-TIME * foam_speed,
			TIME * foam_speed * 0.7
		);

	float surface_foam_noise =
		fractal_noise(foam_position);

	float surface_foam_mask = smoothstep(
		1.0 - foam_amount,
		1.0,
		surface_foam_noise
	);

	// Break surface foam apart instead of creating continuous lines.
	float surface_foam_breakup = fractal_noise(
		foam_position * 2.7 +
		vec2(
			TIME * foam_speed * 0.3,
			0.0
		)
	);

	surface_foam_mask *= smoothstep(
		0.42,
		0.66,
		surface_foam_breakup
	);


	// Reconstruct scene geometry from the depth texture.

	float raw_scene_depth =
		texture(depth_texture, SCREEN_UV).r;

	vec3 scene_ndc = vec3(
		SCREEN_UV * 2.0 - 1.0,
		raw_scene_depth
	);

	vec4 scene_view_position =
		INV_PROJECTION_MATRIX *
		vec4(scene_ndc, 1.0);

	scene_view_position.xyz /=
		scene_view_position.w;

	float depth_difference = max(
		VERTEX.z - scene_view_position.z,
		0.0
	);


	// Noisy foam around intersecting meshes.

	vec2 edge_noise_position =
		pixel_position * edge_foam_noise_scale +
		vec2(
			TIME * edge_foam_speed,
			-TIME * edge_foam_speed * 0.73
		);

	float edge_noise =
		fractal_noise(edge_noise_position);

	float centred_edge_noise =
		edge_noise * 2.0 - 1.0;

	float noisy_foam_width =
		edge_foam_width *
		(
			1.0 +
			centred_edge_noise *
			edge_foam_noise_strength
		);

	noisy_foam_width = max(
		noisy_foam_width,
		0.01
	);

	float edge_foam_mask =
		1.0 -
		smoothstep(
			max(
				noisy_foam_width -
				edge_foam_softness,
				0.0
			),
			noisy_foam_width,
			depth_difference
		);


	// Give the edge foam a solid inner section and broken outer edge.

	float inner_edge_foam =
		1.0 -
		smoothstep(
			0.0,
			noisy_foam_width * 0.42,
			depth_difference
		);

	float outer_edge_breakup = smoothstep(
		0.27,
		0.62,
		edge_noise
	);

	edge_foam_mask *= mix(
		0.55,
		1.0,
		outer_edge_breakup
	);

	edge_foam_mask = max(
		edge_foam_mask,
		inner_edge_foam
	);

	float combined_foam_mask = clamp(
		max(
			surface_foam_mask,
			edge_foam_mask
		),
		0.0,
		1.0
	);


	// Fresnel rim.

	float fresnel = pow(
		1.0 - clamp(
			dot(NORMAL, VIEW),
			0.0,
			1.0
		),
		fresnel_power
	);


	// Final colour.

	vec3 final_color = water_color.rgb;

	final_color = mix(
		final_color,
		highlight_color.rgb,
		highlight_mask
	);

	final_color = mix(
		final_color,
		foam_color.rgb,
		combined_foam_mask
	);

	final_color +=
		highlight_color.rgb *
		fresnel *
		fresnel_strength;

	ALBEDO = final_color;

	ROUGHNESS = mix(
		roughness,
		0.68,
		combined_foam_mask
	);

	METALLIC = metallic;
	SPECULAR = specular;
	
	vec2 distance_from_centre =
	abs(water_uv - vec2(0.5)) * 2.0;

	float edge_distance = max(
		distance_from_centre.x,
		distance_from_centre.y
	);

	float edge_fade =
		1.0 -
		smoothstep(
			edge_fade_start,
			edge_fade_end,
			edge_distance
		);

	ALPHA = clamp(
		(
			water_color.a +
			fresnel * 0.12 +
			combined_foam_mask * 0.35
		) * edge_fade,
		0.0,
		1.0
	);
}
