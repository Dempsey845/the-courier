shader_type spatial;
render_mode cull_disabled;

uniform vec4 tongue_colour : source_color = vec4(
	0.95, 0.16, 0.3, 1.0
);

uniform vec4 groove_colour : source_color = vec4(
	0.55, 0.035, 0.08, 1.0
);

uniform float original_length = 2.0;

uniform float extension : hint_range(0.0, 1.0) = 0.0;

uniform float sideways_curve : hint_range(-1.0, 1.0) = 0.3;
uniform float vertical_curve : hint_range(-1.0, 1.0) = -0.12;

uniform float root_width : hint_range(0.1, 2.0) = 0.6;
uniform float middle_width : hint_range(0.1, 2.0) = 1.0;
uniform float tip_width : hint_range(0.1, 2.0) = 1.2;

uniform float twist_amount : hint_range(0.0, 3.14) = 0.65;
uniform float twist_speed : hint_range(0.0, 10.0) = 3.0;
uniform float twist_waves : hint_range(0.0, 5.0) = 1.5;

uniform float wriggle_amount : hint_range(0.0, 0.5) = 0.06;
uniform float wriggle_speed : hint_range(0.0, 10.0) = 4.0;

uniform float extension_wave_amount : hint_range(0.0, 1.0) = 0.25;
uniform float extension_wave_count : hint_range(0.0, 5.0) = 1.5;
uniform float extension_wave_travel : hint_range(0.0, 5.0) = 1.0;

uniform float roughness : hint_range(0.0, 1.0) = 0.7;
uniform float specular : hint_range(0.0, 1.0) = 0.3;

varying float tongue_progress;
varying float tongue_centre;


void vertex() {
	float progress = clamp(
		(VERTEX.z / original_length) + 0.5,
		0.0,
		1.0
	);

	tongue_progress = progress;

	// Narrow root, wider body and bulbous tip.
	float width;

	if (progress < 0.7) {
		width = mix(
			root_width,
			middle_width,
			smoothstep(0.0, 0.7, progress)
		);
	} else {
		width = mix(
			middle_width,
			tip_width,
			smoothstep(0.7, 1.0, progress)
		);
	}

	VERTEX.x *= width;

	// Slightly thicken the end of the tongue.
	float tip_bulge = smoothstep(
		0.72,
		0.92,
		progress
	);

	VERTEX.y *= mix(
		1.0,
		1.25,
		tip_bulge
	);

	// Keep the root stable while twisting the body and tip.
	float twist_mask = smoothstep(
		0.05,
		0.4,
		progress
	);

	float twist_angle = sin(
		TIME * twist_speed +
		progress * twist_waves * TAU
	);

	twist_angle *= twist_amount * twist_mask;

	float twist_cos = cos(twist_angle);
	float twist_sin = sin(twist_angle);

	// Twist the cross-section around the local Z axis.
	vec2 twisted_position = vec2(
		VERTEX.x * twist_cos -
		VERTEX.y * twist_sin,

		VERTEX.x * twist_sin +
		VERTEX.y * twist_cos
	);

	VERTEX.x = twisted_position.x;
	VERTEX.y = twisted_position.y;

	// Rotate normals with the twisted geometry.
	vec2 twisted_normal = vec2(
		NORMAL.x * twist_cos -
		NORMAL.y * twist_sin,

		NORMAL.x * twist_sin +
		NORMAL.y * twist_cos
	);

	NORMAL.x = twisted_normal.x;
	NORMAL.y = twisted_normal.y;

	tongue_centre = abs(VERTEX.x);

	// This shape reaches zero at both ends, keeping the
	// tongue's root and tip at their intended positions.
	float curve = sin(progress * PI);

	VERTEX.x += curve * sideways_curve;
	VERTEX.y += curve * vertical_curve;
	
		// Extension value without elastic overshoot.
	float extension_progress = clamp(
		extension,
		0.0,
		1.0
	);

	// Zero when retracted or fully extended, strongest
	// halfway through the extension.
	float transition_wave_strength = (
		4.0 *
		extension_progress *
		(1.0 - extension_progress)
	);

	// Move the wave forward as the tongue extends.
	float extension_wave = sin(
		progress * extension_wave_count * TAU -
		extension_progress * extension_wave_travel * TAU
	);

	// Keep the root and tip correctly positioned.
	float extension_wave_mask = sin(progress * PI);

	VERTEX.y += (
		extension_wave *
		extension_wave_amount *
		extension_wave_mask *
		transition_wave_strength
	);

	// Subtle animated movement along the tongue.
	float wriggle = sin(
		TIME * wriggle_speed +
		progress * TAU * 2.0
	);

	VERTEX.x += (
		wriggle *
		wriggle_amount *
		curve
	);
		
	// Allow values above 1.0 for springy overshoot.
	float extension_amount = max(extension, 0.0);

	// Keep thickness controlled even while length overshoots.
	float thickness_amount = smoothstep(
		0.0,
		1.0,
		clamp(extension, 0.0, 1.0)
	);

	// Assumes the negative-Z end is attached to the mouth.
	float root_z = -original_length * 0.5;

	// Collapse every vertex toward the root.
	VERTEX.z = mix(
		root_z,
		VERTEX.z,
		extension_amount
	);

	// Remove remaining width and thickness when retracted.
	VERTEX.xy *= thickness_amount;
}


void fragment() {
	vec3 colour = tongue_colour.rgb;

	// Darker near the mouth.
	colour *= mix(
		0.75,
		1.0,
		smoothstep(
			0.0,
			0.4,
			tongue_progress
		)
	);

	// Central groove near the end of the tongue.
	float groove_position = 1.0 - smoothstep(
		0.015,
		0.07,
		tongue_centre
	);

	float groove_length = smoothstep(
		0.55,
		0.75,
		tongue_progress
	);

	float groove = (
		groove_position *
		groove_length
	);

	ALBEDO = mix(
		colour,
		groove_colour.rgb,
		groove * 0.65
	);

	ROUGHNESS = roughness;
	SPECULAR = specular;
}