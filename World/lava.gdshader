shader_type spatial;

render_mode cull_disabled, depth_draw_opaque,
	diffuse_burley, specular_schlick_ggx;


// Colours

uniform vec4 deep_lava_color : source_color =
	vec4(0.35, 0.015, 0.005, 1.0);

uniform vec4 lava_color : source_color =
	vec4(1.0, 0.12, 0.01, 1.0);

uniform vec4 hot_lava_color : source_color =
	vec4(1.0, 0.75, 0.08, 1.0);

uniform vec4 crust_color : source_color =
	vec4(0.045, 0.025, 0.02, 1.0);


// Pattern

uniform float pattern_scale : hint_range(0.5, 20.0, 0.1) = 4.0;
uniform float flow_speed : hint_range(0.0, 2.0, 0.01) = 0.12;
uniform float distortion_strength : hint_range(0.0, 2.0, 0.01) = 0.65;

uniform float crust_amount : hint_range(0.0, 1.0, 0.01) = 0.52;
uniform float crust_softness : hint_range(0.01, 0.4, 0.01) = 0.08;

uniform float crack_width : hint_range(0.01, 0.5, 0.01) = 0.12;
uniform float highlight_amount : hint_range(0.0, 2.0, 0.01) = 0.8;


// Glow

uniform float emission_strength : hint_range(0.0, 15.0, 0.1) = 4.0;
uniform float crack_emission_strength : hint_range(0.0, 20.0, 0.1) = 8.0;
uniform float pulse_speed : hint_range(0.0, 5.0, 0.1) = 1.2;
uniform float pulse_amount : hint_range(0.0, 1.0, 0.01) = 0.15;


// Surface movement

uniform float displacement_strength : hint_range(0.0, 1.0, 0.01) = 0.12;
uniform float displacement_scale : hint_range(0.1, 10.0, 0.1) = 2.5;
uniform float wave_speed : hint_range(0.0, 5.0, 0.1) = 0.8;


// Material

uniform float roughness : hint_range(0.0, 1.0) = 0.72;
uniform float metallic : hint_range(0.0, 1.0) = 0.0;


varying vec3 world_position;


vec2 random_gradient(vec2 position) {
	float angle = fract(
		sin(dot(position, vec2(127.1, 311.7))) *
		43758.5453
	) * 6.283185;

	return vec2(cos(angle), sin(angle));
}


float gradient_noise(vec2 position) {
	vec2 cell = floor(position);
	vec2 local_position = fract(position);

	vec2 smooth_position =
		local_position * local_position *
		local_position *
		(local_position *
		(local_position * 6.0 - 15.0) + 10.0);

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
		smooth_position.x
	);

	float top = mix(
		top_left,
		top_right,
		smooth_position.x
	);

	return mix(bottom, top, smooth_position.y) * 0.5 + 0.5;
}


float fbm(vec2 position) {
	float result = 0.0;
	float amplitude = 0.5;
	float total_amplitude = 0.0;

	for (int index = 0; index < 5; index++) {
		result += gradient_noise(position) * amplitude;
		total_amplitude += amplitude;

		// Rotate and offset every layer so their grids don't align.
		position = vec2(
			position.x * 1.55 + position.y * 1.23,
			-position.x * 1.23 + position.y * 1.55
		);

		position += vec2(17.7, 9.2);
		amplitude *= 0.5;
	}

	return result / total_amplitude;
}


void vertex() {
	vec3 world_vertex =
		(MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;

	vec2 wave_position =
		world_vertex.xz * displacement_scale;

	float first_wave = fbm(
		wave_position +
		vec2(TIME * wave_speed, TIME * wave_speed * 0.37)
	);

	float second_wave = fbm(
		wave_position * 1.7 -
		vec2(TIME * wave_speed * 0.42, TIME * wave_speed * 0.65)
	);

	float displacement =
		(first_wave * 0.7 + second_wave * 0.3) - 0.5;

	VERTEX.y += displacement * displacement_strength;

	world_position =
		(MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}


void fragment() {
	vec2 coordinates = world_position.xz * pattern_scale;

	vec2 flow_direction = vec2(
		TIME * flow_speed,
		TIME * flow_speed * 0.38
	);

	// Two noise layers distort the main lava pattern.
	float distortion_x = fbm(
		coordinates * 0.45 + flow_direction
	);

	float distortion_y = fbm(
		coordinates * 0.45 -
		flow_direction * 0.73 +
		vec2(8.4, 3.1)
	);

	vec2 distorted_coordinates =
		coordinates +
		(vec2(distortion_x, distortion_y) - 0.5) *
		distortion_strength;

	float broad_pattern = fbm(
		distorted_coordinates * 0.55 +
		flow_direction
	);

	float detail_pattern = fbm(
		distorted_coordinates * 1.35 -
		flow_direction * 1.7
	);

	float lava_pattern =
		broad_pattern * 0.72 +
		detail_pattern * 0.28;

	// Dark crust forms over the brighter lava.
	float crust_mask = smoothstep(
		crust_amount - crust_softness,
		crust_amount + crust_softness,
		lava_pattern
	);

	// Creates a bright border immediately around crust shapes.
	float crack_outer = smoothstep(
		crust_amount - crack_width,
		crust_amount,
		lava_pattern
	);

	float crack_inner = smoothstep(
		crust_amount,
		crust_amount + crust_softness,
		lava_pattern
	);

	float crack_mask =
		clamp(crack_outer - crack_inner, 0.0, 1.0);

	// Hotter moving streams within exposed lava.
	float hot_pattern = fbm(
		distorted_coordinates * 2.2 +
		vec2(-TIME * flow_speed * 2.0, TIME * flow_speed)
	);

	hot_pattern = smoothstep(0.45, 0.8, hot_pattern);

	float pulse =
		1.0 +
		sin(
			TIME * pulse_speed +
			lava_pattern * 10.0
		) * pulse_amount;

	vec3 molten_colour = mix(
		deep_lava_color.rgb,
		lava_color.rgb,
		smoothstep(0.15, 0.7, hot_pattern)
	);

	molten_colour = mix(
		molten_colour,
		hot_lava_color.rgb,
		hot_pattern * highlight_amount
	);

	vec3 final_colour = mix(
		molten_colour,
		crust_color.rgb,
		crust_mask
	);

	final_colour = mix(
		final_colour,
		hot_lava_color.rgb,
		crack_mask
	);

	float molten_mask = 1.0 - crust_mask;

	vec3 emission =
		molten_colour *
		molten_mask *
		emission_strength *
		pulse;

	emission +=
		hot_lava_color.rgb *
		crack_mask *
		crack_emission_strength *
		pulse;

	ALBEDO = final_colour;
	EMISSION = emission;
	ROUGHNESS = mix(roughness * 0.65, roughness, crust_mask);
	METALLIC = metallic;
}