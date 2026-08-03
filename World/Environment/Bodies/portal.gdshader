shader_type spatial;

render_mode unshaded, blend_add, cull_disabled, depth_draw_never;


// Portal colours

uniform vec4 inner_color : source_color =
	vec4(0.12, 0.01, 0.25, 1.0);

uniform vec4 energy_color : source_color =
	vec4(0.55, 0.08, 1.0, 1.0);

uniform vec4 highlight_color : source_color =
	vec4(0.95, 0.55, 1.0, 1.0);


// Transition

// Animate from 0.0 to 1.0 to open the portal.
// Animate from 1.0 to 0.0 to close it.
uniform float transition_progress :
	hint_range(0.0, 1.0) = 1.0;


// Player interaction

// Animate from 0.0 to 1.0 when the player enters.
// Produces a collapsing ring, flash and distortion pulse.
instance uniform float interaction_progress :
	hint_range(0.0, 1.0) = 0.0;


// Shape

uniform float portal_radius :
	hint_range(0.1, 0.7) = 0.46;

uniform float edge_softness :
	hint_range(0.001, 0.2) = 0.04;

uniform float rim_width :
	hint_range(0.01, 0.3) = 0.11;

uniform float oval_width :
	hint_range(0.1, 2.0) = 1.0;

uniform float oval_height :
	hint_range(0.1, 2.0) = 1.0;


// Animation

uniform float animation_speed :
	hint_range(0.0, 5.0) = 1.0;

uniform float swirl_strength :
	hint_range(0.0, 10.0) = 4.0;

uniform float distortion_strength :
	hint_range(0.0, 0.2) = 0.035;


// Player interaction appearance

uniform float interaction_distortion :
	hint_range(0.0, 0.2) = 0.045;

uniform float interaction_ring_width :
	hint_range(0.001, 0.1) = 0.025;

uniform float interaction_brightness :
	hint_range(0.0, 10.0) = 3.0;


// General appearance

uniform float brightness :
	hint_range(0.0, 10.0) = 2.5;

uniform float detail_scale :
	hint_range(1.0, 30.0) = 8.0;


float hash(vec2 position) {
	return fract(
		sin(
			dot(
				position,
				vec2(127.1, 311.7)
			)
		) * 43758.5453
	);
}


float noise(vec2 position) {
	vec2 cell = floor(position);
	vec2 fraction = fract(position);

	fraction =
		fraction
		* fraction
		* (3.0 - 2.0 * fraction);

	float bottom_left = hash(cell);

	float bottom_right = hash(
		cell + vec2(1.0, 0.0)
	);

	float top_left = hash(
		cell + vec2(0.0, 1.0)
	);

	float top_right = hash(
		cell + vec2(1.0, 1.0)
	);

	return mix(
		mix(
			bottom_left,
			bottom_right,
			fraction.x
		),
		mix(
			top_left,
			top_right,
			fraction.x
		),
		fraction.y
	);
}


float fbm(vec2 position) {
	float value = 0.0;
	float amplitude = 0.5;

	for (int index = 0; index < 5; index++) {
		value += noise(position) * amplitude;

		position =
			position * 2.03
			+ vec2(17.2, 9.3);

		amplitude *= 0.5;
	}

	return value;
}


void fragment() {
	float time = TIME * animation_speed;

	// Smooth opening and closing.
	float transition = smoothstep(
		0.0,
		1.0,
		transition_progress
	);

	// Prevent a visible dot when the portal is closed.
	float transition_visibility = smoothstep(
		0.02,
		0.12,
		transition
	);

	float current_radius =
		portal_radius * transition;


	// Interaction pulse

	float interaction = clamp(
		interaction_progress,
		0.0,
		1.0
	);

	// Starts at zero, peaks halfway and returns to zero.
	float interaction_pulse = sin(
		interaction * PI
	);


	// Portal coordinates

	vec2 centred_uv = UV - vec2(0.5);

	centred_uv.x /= oval_width;
	centred_uv.y /= oval_height;

	float distance_from_centre =
		length(centred_uv);

	float angle = atan(
		centred_uv.y,
		centred_uv.x
	);


	// Unstable edge distortion

	float edge_noise = fbm(
		vec2(
			angle * detail_scale * 0.35,
			time * 0.7
		)
	);

	float current_distortion =
		(
			distortion_strength
			+ interaction_pulse
			* interaction_distortion
		)
		* transition;

	float distorted_radius =
		distance_from_centre
		+ (edge_noise - 0.5)
		* current_distortion;

	float current_softness = min(
		edge_softness,
		max(
			current_radius * 0.5,
			0.001
		)
	);

	float portal_mask =
		1.0 - smoothstep(
			current_radius - current_softness,
			current_radius,
			distorted_radius
		);


	// Swirling energy

	float swirl_angle =
		angle
		- time * 1.5
		+ distance_from_centre
		* swirl_strength;

	vec2 swirl_uv = vec2(
		cos(swirl_angle),
		sin(swirl_angle)
	);

	swirl_uv *=
		distance_from_centre
		* detail_scale;

	float energy_noise = fbm(
		swirl_uv
		+ vec2(
			time * 0.4,
			-time * 0.65
		)
	);

	float secondary_noise = fbm(
		swirl_uv * 1.8
		- vec2(
			time * 0.8,
			time * 0.3
		)
	);

	float energy = smoothstep(
		0.32,
		0.85,
		energy_noise * 0.7
		+ secondary_noise * 0.45
	);


	// Bright outer rim

	float current_rim_width = min(
		rim_width,
		current_radius * 0.6
	);

	float rim = smoothstep(
		current_radius - current_rim_width,
		current_radius
			- current_rim_width * 0.35,
		distorted_radius
	);

	rim *= 1.0 - smoothstep(
		current_radius
			- current_softness * 2.0,
		current_radius,
		distorted_radius
	);


	// Internal animated rings

	float ring_wave = sin(
		distance_from_centre * 85.0
		- time * 6.0
		+ energy_noise * 8.0
	);

	ring_wave = smoothstep(
		0.55,
		1.0,
		ring_wave
	);

	ring_wave *= smoothstep(
		current_radius * 0.25,
		max(current_radius, 0.001),
		distance_from_centre
	);


	// Player-entry feedback ring

	// Moves from the outer edge toward the centre.
	float interaction_ring_radius = mix(
		current_radius,
		0.0,
		interaction
	);

	float interaction_ring =
		1.0 - smoothstep(
			0.0,
			interaction_ring_width,
			abs(
				distance_from_centre
				- interaction_ring_radius
			)
		);

	interaction_ring *= interaction_pulse;
	interaction_ring *= portal_mask;


	// Colour

	float centre_fade = smoothstep(
		0.0,
		max(current_radius, 0.001),
		distance_from_centre
	);

	vec3 color = mix(
		inner_color.rgb,
		energy_color.rgb,
		energy * 0.75
			+ centre_fade * 0.25
	);

	color = mix(
		color,
		highlight_color.rgb,
		clamp(
			rim
			+ ring_wave * 0.35
			+ interaction_ring
			+ interaction_pulse * 0.18,
			0.0,
			1.0
		)
	);


	// Brightness

	float energy_brightness =
		0.55
		+ energy * 0.8
		+ rim * 1.6
		+ ring_wave * 0.4
		+ interaction_ring
			* interaction_brightness
		+ interaction_pulse * 0.8;

	ALBEDO = color;

	EMISSION =
		color
		* energy_brightness
		* brightness
		* transition_visibility;

	ALPHA =
		portal_mask
		* transition_visibility
		* clamp(
			0.65
			+ energy * 0.25
			+ rim
			+ interaction_ring,
			0.0,
			1.0
		);
}