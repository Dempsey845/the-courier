shader_type canvas_item;

render_mode unshaded;


// Portal colours

uniform vec4 inner_color : source_color =
	vec4(0.06, 0.005, 0.15, 1.0);

uniform vec4 energy_color : source_color =
	vec4(0.48, 0.035, 1.0, 1.0);

uniform vec4 highlight_color : source_color =
	vec4(1.0, 0.55, 1.0, 1.0);

uniform vec4 final_color : source_color =
	vec4(0.025, 0.0, 0.065, 1.0);


// Transition

// Animate 0.0 -> 1.0 to cover the screen.
// Animate 1.0 -> 0.0 after the new scene has loaded.
uniform float transition_progress :
	hint_range(0.0, 1.0) = 0.0;


// Shape

// Controls the initial portal size.
uniform float starting_radius :
	hint_range(0.0, 0.5) = 0.04;

uniform float edge_softness :
	hint_range(0.001, 0.2) = 0.035;

uniform float rim_width :
	hint_range(0.001, 0.25) = 0.075;


// Animation

uniform float animation_speed :
	hint_range(0.0, 5.0) = 1.0;

uniform float swirl_strength :
	hint_range(0.0, 20.0) = 7.0;

uniform float distortion_strength :
	hint_range(0.0, 0.2) = 0.045;

uniform float detail_scale :
	hint_range(1.0, 30.0) = 9.0;


// Appearance

uniform float brightness :
	hint_range(0.0, 5.0) = 1.65;

uniform float ring_density :
	hint_range(1.0, 30.0) = 12.0;

uniform float flash_strength :
	hint_range(0.0, 5.0) = 1.5;

uniform float final_darkening :
	hint_range(0.0, 1.0) = 0.82;


// Optional texture support

// Enable this if using a TextureRect and you want its texture
// to subtly influence the portal energy.
uniform bool use_texture = false;

uniform float texture_influence :
	hint_range(0.0, 1.0) = 0.2;


float hash(vec2 position) {
	return fract(
		sin(dot(position, vec2(127.1, 311.7)))
		* 43758.5453
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
	float bottom_right = hash(cell + vec2(1.0, 0.0));
	float top_left = hash(cell + vec2(0.0, 1.0));
	float top_right = hash(cell + vec2(1.0, 1.0));

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

	float transition = smoothstep(
		0.0,
		1.0,
		clamp(transition_progress, 0.0, 1.0)
	);

	// Resize coordinates so the portal remains circular,
	// even on a widescreen ColorRect.
	vec2 centred_uv = UV - vec2(0.5);

	float aspect_ratio =
		SCREEN_PIXEL_SIZE.y
		/ SCREEN_PIXEL_SIZE.x;

	centred_uv.x *= aspect_ratio;

	float distance_from_centre = length(centred_uv);

	float angle = atan(
		centred_uv.y,
		centred_uv.x
	);


	// The maximum possible radius changes with aspect ratio,
	// ensuring the corners are fully covered.
	float maximum_radius = length(
		vec2(aspect_ratio * 0.5, 0.5)
	);

	// Ease the expansion so it accelerates dramatically.
	float expansion = transition * transition;

	float current_radius = mix(
		starting_radius,
		maximum_radius + 0.12,
		expansion
	);


	// Unstable portal boundary

	float edge_noise = fbm(
		vec2(
			angle * detail_scale * 0.4,
			time * 0.75
		)
	);

	float distortion_fade =
		sin(transition * 3.14159265);

	float distorted_distance =
		distance_from_centre
		+ (edge_noise - 0.5)
		* distortion_strength
		* distortion_fade;

	float portal_mask =
		1.0 - smoothstep(
			current_radius - edge_softness,
			current_radius,
			distorted_distance
		);

	portal_mask *= smoothstep(
		0.0,
		0.025,
		transition
	);


	// Swirling vortex energy

	float swirl_angle =
		angle
		- time * 1.8
		+ distance_from_centre * swirl_strength
		- transition * 3.0;

	vec2 swirl_direction = vec2(
		cos(swirl_angle),
		sin(swirl_angle)
	);

	vec2 swirl_uv =
		swirl_direction
		* (
			distance_from_centre
			* detail_scale
			+ 0.5
		);

	float energy_noise = fbm(
		swirl_uv
		+ vec2(
			time * 0.45,
			-time * 0.65
		)
	);

	float secondary_noise = fbm(
		swirl_uv * 1.85
		- vec2(
			time * 0.9,
			time * 0.35
		)
	);

	float energy = smoothstep(
		0.3,
		0.82,
		energy_noise * 0.7
		+ secondary_noise * 0.45
	);


	// Expanding outer rim

	float rim =
		1.0 - smoothstep(
			0.0,
			rim_width,
			abs(
				distorted_distance
				- current_radius
			)
		);

	rim *= portal_mask;


	// Energy lines spiral towards the centre.

	float spiral_lines = sin(
		angle * 7.0
		+ distance_from_centre
			* ring_density
		* 6.0
		- time * 7.0
		+ energy_noise * 5.0
	);

	spiral_lines = smoothstep(
		0.55,
		1.0,
		spiral_lines
	);

	spiral_lines *= portal_mask;


	// Fast pulse travelling outwards during the transition.

	float pulse_radius = transition * maximum_radius;

	float pulse_ring =
		1.0 - smoothstep(
			0.0,
			0.035,
			abs(
				distance_from_centre
				- pulse_radius
			)
		);

	pulse_ring *= portal_mask;

	float pulse_visibility =
		sin(transition * 3.14159265);

	pulse_ring *= pulse_visibility;


	// Centre glow that flashes as the transition begins.

	float centre_glow =
		1.0 - smoothstep(
			0.0,
			mix(0.08, 0.42, transition),
			distance_from_centre
		);

	float entry_flash =
		exp(
			-28.0
			* pow(
				transition - 0.16,
				2.0
			)
		);

	entry_flash *= flash_strength;


	// Portal colouring

	float radial_gradient = clamp(
		distance_from_centre
		/ max(current_radius, 0.001),
		0.0,
		1.0
	);

	vec3 portal_color = mix(
		inner_color.rgb,
		energy_color.rgb,
		energy * 0.75
			+ radial_gradient * 0.22
	);

	float highlights = clamp(
		rim
		+ spiral_lines * 0.4
		+ pulse_ring
		+ centre_glow * entry_flash,
		0.0,
		1.0
	);

	portal_color = mix(
		portal_color,
		highlight_color.rgb,
		highlights
	);


	// TextureRect support

	if (use_texture) {
		vec4 texture_color = texture(
			TEXTURE,
			UV
		);

		portal_color = mix(
			portal_color,
			portal_color * texture_color.rgb * 1.5,
			texture_influence
		);
	}


	// Darken near the end so scene changes are hidden.

	float end_fade = smoothstep(
		0.72,
		1.0,
		transition
	);

	portal_color = mix(
		portal_color,
		final_color.rgb,
		end_fade * final_darkening
	);


	// Final output

	float energy_brightness =
		0.7
		+ energy * 0.75
		+ rim * 1.8
		+ spiral_lines * 0.35
		+ pulse_ring * 1.6
		+ centre_glow * entry_flash;

	portal_color *=
		energy_brightness
		* brightness;

	// Prevent excessive brightness once the screen is covered.
	portal_color = mix(
		portal_color,
		final_color.rgb,
		smoothstep(0.92, 1.0, transition)
	);

	COLOR = vec4(
		portal_color,
		portal_mask
	);
}