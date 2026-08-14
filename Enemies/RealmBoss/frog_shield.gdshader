shader_type spatial;

render_mode blend_mix, depth_draw_never, cull_back,
	unshaded, shadows_disabled;


// Transition

uniform float transition : hint_range(0.0, 1.0) = 1.0;
uniform float transition_softness : hint_range(0.01, 0.5) = 0.12;
uniform float transition_edge_width : hint_range(0.001, 0.25) = 0.06;
uniform float transition_edge_brightness : hint_range(0.0, 10.0) = 4.0;


// Colours

uniform vec4 shield_color : source_color =
	vec4(0.015, 0.16, 0.85, 1.0);

uniform vec4 energy_color : source_color =
	vec4(0.12, 0.65, 1.0, 1.0);

uniform vec4 highlight_color : source_color =
	vec4(0.55, 0.95, 1.0, 1.0);


// Transparency

uniform float base_opacity : hint_range(0.0, 1.0) = 0.12;
uniform float edge_opacity : hint_range(0.0, 1.0) = 0.65;

uniform float back_face_opacity : hint_range(0.0, 1.0) = 0.22;


// Fresnel

uniform float fresnel_power : hint_range(0.5, 10.0) = 3.5;
uniform float fresnel_brightness : hint_range(0.0, 10.0) = 2.0;


// Energy pattern

uniform float pattern_scale : hint_range(1.0, 40.0) = 12.0;
uniform float pattern_speed : hint_range(0.0, 5.0) = 0.45;
uniform float pattern_strength : hint_range(0.0, 3.0) = 0.8;

uniform float detail_scale : hint_range(1.0, 80.0) = 28.0;
uniform float detail_strength : hint_range(0.0, 2.0) = 0.35;


// Travelling pulses

uniform float pulse_speed : hint_range(0.0, 10.0) = 0.8;
uniform float pulse_frequency : hint_range(1.0, 30.0) = 9.0;
uniform float pulse_strength : hint_range(0.0, 3.0) = 0.65;


// Vertex movement

uniform float displacement_strength : hint_range(0.0, 1.0) = 0.08;
uniform float displacement_scale : hint_range(0.0, 5.0) = 0.8;
uniform float displacement_speed : hint_range(0.0, 5.0) = 0.55;


// Overall brightness

uniform float emission_strength : hint_range(0.0, 10.0) = 2.0;


varying vec3 local_position;


float energy_noise(vec3 position, float time) {
	float wave_a = sin(
		position.x * 1.15 +
		position.y * 0.83 +
		time
	);

	float wave_b = sin(
		position.y * 1.37 -
		position.z * 1.09 -
		time * 1.21
	);

	float wave_c = sin(
		position.z * 1.53 +
		position.x * 0.71 +
		time * 0.73
	);

	float wave_d = sin(
		(position.x + position.y - position.z) * 0.62 -
		time * 0.91
	);

	return (
		wave_a +
		wave_b +
		wave_c +
		wave_d
	) * 0.125 + 0.5;
}


void vertex() {
	vec3 sphere_direction = normalize(VERTEX);
	float displacement_time = TIME * displacement_speed;

	float displacement =
		sin(
			(sphere_direction.x + sphere_direction.z) *
			displacement_scale * 12.0 +
			displacement_time
		);

	displacement *= sin(
		sphere_direction.y *
		displacement_scale * 15.0 -
		displacement_time * 1.3
	);

	// Displacement fades alongside the transition.
	VERTEX += NORMAL *
		displacement *
		displacement_strength *
		transition;

	local_position = VERTEX;
}


void fragment() {
	vec3 sphere_direction = normalize(local_position);
	float time = TIME * pattern_speed;

	float broad_noise = energy_noise(
		sphere_direction * pattern_scale,
		time
	);

	float detail_noise = energy_noise(
		sphere_direction * detail_scale +
		vec3(time * 0.4, -time * 0.6, time * 0.25),
		-time * 1.45
	);

	float current_a = abs(
		sin(
			sphere_direction.x * pattern_scale +
			sphere_direction.y * pattern_scale * 0.73 +
			time * 2.0
		)
	);

	float current_b = abs(
		sin(
			sphere_direction.z * pattern_scale * 1.17 -
			sphere_direction.y * pattern_scale * 0.82 -
			time * 1.6
		)
	);

	float currents = 1.0 - min(current_a, current_b);
	currents = smoothstep(0.70, 0.97, currents);

	float pulse_phase =
		sphere_direction.y * pulse_frequency -
		TIME * pulse_speed;

	float pulse = pow(
		1.0 - abs(sin(pulse_phase)),
		18.0
	);

	float spark_pattern =
		sin(sphere_direction.x * 61.0 + TIME * 2.1) *
		sin(sphere_direction.y * 57.0 - TIME * 1.7) *
		sin(sphere_direction.z * 67.0 + TIME * 1.3);

	float sparks = smoothstep(0.88, 0.98, spark_pattern);

	float energy =
		smoothstep(0.52, 0.82, broad_noise) *
		pattern_strength;

	energy +=
		smoothstep(0.64, 0.90, detail_noise) *
		detail_strength;

	energy += currents * 0.65;
	energy += pulse * pulse_strength;
	energy += sparks * 0.8;

	float view_dot = abs(
		dot(normalize(NORMAL), normalize(VIEW))
	);

	float fresnel = pow(
		1.0 - clamp(view_dot, 0.0, 1.0),
		fresnel_power
	);

	float face_opacity =
		FRONT_FACING
		? 1.0
		: back_face_opacity;

	float color_mix = clamp(
		energy * 0.65 + fresnel,
		0.0,
		1.0
	);

	vec3 final_color = mix(
		shield_color.rgb,
		energy_color.rgb,
		color_mix
	);

	final_color = mix(
		final_color,
		highlight_color.rgb,
		clamp(
			fresnel * 0.75 +
			pulse * 0.35 +
			sparks * 0.5,
			0.0,
			1.0
		)
	);


	// Bottom-to-top transition

	float transition_position =
		sphere_direction.y * 0.5 + 0.5;

	float transition_mask = smoothstep(
		transition_position - transition_softness,
		transition_position + transition_softness,
		transition
	);


	// Bright leading edge of the transition

	float transition_distance = abs(
		transition - transition_position
	);

	float transition_edge =
		1.0 -
		smoothstep(
			0.0,
			transition_edge_width,
			transition_distance
		);

	// Prevent edge glow at fully hidden or fully visible values.
	transition_edge *= step(0.001, transition);
	transition_edge *= 1.0 - step(0.999, transition);


	float alpha =
		base_opacity +
		energy * 0.14 +
		fresnel * edge_opacity;

	alpha *= face_opacity;
	alpha *= transition_mask;


	// Transition edge becomes a bright cyan line.

	final_color = mix(
		final_color,
		highlight_color.rgb,
		transition_edge
	);

	float final_emission =
		emission_strength *
		(
			0.5 +
			energy +
			fresnel * fresnel_brightness
		);

	final_emission +=
		transition_edge *
		transition_edge_brightness;


	ALBEDO = final_color;

	EMISSION =
		final_color *
		final_emission *
		transition_mask;

	ALPHA = clamp(alpha, 0.0, 1.0);
}