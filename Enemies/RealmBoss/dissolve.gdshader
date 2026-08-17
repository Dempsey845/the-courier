shader_type spatial;

render_mode blend_mix, depth_draw_never, cull_disabled,
	unshaded, shadows_disabled;


// Dissolve animation

uniform float progress
	: hint_range(0.0, 1.0) = 0.0;

uniform float dissolve_softness
	: hint_range(0.001, 0.3) = 0.08;

uniform float noise_scale
	: hint_range(0.1, 30.0) = 3.0;

uniform float noise_strength
	: hint_range(0.0, 1.0) = 0.3;

uniform float noise_detail
	: hint_range(0.0, 1.0) = 0.35;


// Mesh bounds

uniform float minimum_height = -1.0;
uniform float maximum_height = 1.0;

uniform bool dissolve_bottom_to_top = true;


// Appearance

uniform vec4 inner_edge_colour : source_color =
	vec4(0.25, 0.02, 0.75, 1.0);

uniform vec4 outer_edge_colour : source_color =
	vec4(1.0, 0.2, 0.95, 1.0);

uniform vec4 trail_colour : source_color =
	vec4(0.15, 0.01, 0.35, 1.0);

uniform float edge_width
	: hint_range(0.001, 0.4) = 0.12;

uniform float edge_emission
	: hint_range(0.0, 30.0) = 10.0;

uniform float trail_width
	: hint_range(0.0, 0.5) = 0.18;

uniform float trail_opacity
	: hint_range(0.0, 1.0) = 0.35;

uniform float overlay_opacity
	: hint_range(0.0, 1.0) = 1.0;


// Surface offset prevents flickering with the base materials.

uniform float surface_offset
	: hint_range(0.0, 0.02) = 0.002;


// Galaxy speckles

uniform vec4 star_colour : source_color =
	vec4(0.9, 0.75, 1.0, 1.0);

uniform float star_scale
	: hint_range(2.0, 100.0) = 24.0;

uniform float star_density
	: hint_range(0.8, 0.9999) = 0.975;

uniform float star_emission
	: hint_range(0.0, 30.0) = 15.0;

uniform float animation_speed
	: hint_range(0.0, 3.0) = 0.15;


varying vec3 object_position;


// Random and noise

float random_31(vec3 position) {
	position = fract(
		position * vec3(0.1031, 0.1030, 0.0973)
	);

	position += dot(
		position,
		position.yzx + 33.33
	);

	return fract(
		(position.x + position.y) * position.z
	);
}


float value_noise_3d(vec3 position) {
	vec3 cell = floor(position);
	vec3 local_point = fract(position);

	vec3 smooth_point = (
		local_point
		* local_point
		* (3.0 - 2.0 * local_point)
	);

	float n000 = random_31(
		cell + vec3(0.0, 0.0, 0.0)
	);

	float n100 = random_31(
		cell + vec3(1.0, 0.0, 0.0)
	);

	float n010 = random_31(
		cell + vec3(0.0, 1.0, 0.0)
	);

	float n110 = random_31(
		cell + vec3(1.0, 1.0, 0.0)
	);

	float n001 = random_31(
		cell + vec3(0.0, 0.0, 1.0)
	);

	float n101 = random_31(
		cell + vec3(1.0, 0.0, 1.0)
	);

	float n011 = random_31(
		cell + vec3(0.0, 1.0, 1.0)
	);

	float n111 = random_31(
		cell + vec3(1.0, 1.0, 1.0)
	);

	float x00 = mix(
		n000,
		n100,
		smooth_point.x
	);

	float x10 = mix(
		n010,
		n110,
		smooth_point.x
	);

	float x01 = mix(
		n001,
		n101,
		smooth_point.x
	);

	float x11 = mix(
		n011,
		n111,
		smooth_point.x
	);

	float y0 = mix(
		x00,
		x10,
		smooth_point.y
	);

	float y1 = mix(
		x01,
		x11,
		smooth_point.y
	);

	return mix(
		y0,
		y1,
		smooth_point.z
	);
}


float fractal_noise_3d(vec3 position) {
	float result = 0.0;
	float amplitude = 0.5;

	for (int octave = 0; octave < 4; octave++) {
		result += (
			value_noise_3d(position)
			* amplitude
		);

		position = (
			position * 2.03
			+ vec3(17.1, 9.2, 13.7)
		);

		amplitude *= 0.5;
	}

	return result;
}


float create_stars(vec3 position) {
	vec3 star_grid = position * star_scale;
	vec3 star_cell = floor(star_grid);
	vec3 star_position = fract(star_grid) - 0.5;

	float star_random = random_31(star_cell);

	float star = step(
		star_density,
		star_random
	);

	float star_size = mix(
		0.04,
		0.15,
		random_31(star_cell + vec3(7.3))
	);

	star *= 1.0 - smoothstep(
		star_size,
		star_size * 2.5,
		length(star_position)
	);

	float twinkle = (
		sin(
			TIME * 5.0
			+ star_random * TAU
		) * 0.25
		+ 0.75
	);

	return star * twinkle;
}


void vertex() {
	object_position = VERTEX;

	// Push the overlay slightly above the original surface.
	VERTEX += NORMAL * surface_offset;
}


void fragment() {
	float height_range = max(
		maximum_height - minimum_height,
		0.0001
	);

	float height_value = clamp(
		(object_position.y - minimum_height)
		/ height_range,
		0.0,
		1.0
	);

	if (!dissolve_bottom_to_top) {
		height_value = 1.0 - height_value;
	}

	vec3 animated_position = (
		object_position * noise_scale
		+ vec3(
			TIME * animation_speed,
			0.0,
			-TIME * animation_speed * 0.5
		)
	);

	float large_noise = fractal_noise_3d(
		animated_position
	);

	float small_noise = value_noise_3d(
		animated_position * 3.5
	);

	float dissolve_noise = mix(
		large_noise,
		small_noise,
		noise_detail
	);

	dissolve_noise = (
		dissolve_noise - 0.5
	) * noise_strength;

	// Moves slightly beyond both ends so progress 0 is invisible
	// and progress 1 fully passes over the mesh.
	float threshold = mix(
		-noise_strength - edge_width,
		1.0 + noise_strength + edge_width,
		progress
	);

	float dissolve_field = (
		height_value + dissolve_noise
	);

	float distance_from_edge = (
		dissolve_field - threshold
	);

	float outer_edge = 1.0 - smoothstep(
		0.0,
		edge_width,
		abs(distance_from_edge)
	);

	float inner_edge = 1.0 - smoothstep(
		0.0,
		edge_width * 0.45,
		abs(distance_from_edge)
	);

	float trail = (
		1.0 - smoothstep(
			0.0,
			max(trail_width, 0.0001),
			-distance_from_edge
		)
	);

	trail *= step(
		distance_from_edge,
		0.0
	);

	float stars = create_stars(
		object_position
	);

	stars *= max(
		outer_edge,
		trail
	);

	vec3 edge_colour = mix(
		inner_edge_colour.rgb,
		outer_edge_colour.rgb,
		inner_edge
	);

	vec3 final_colour = mix(
		trail_colour.rgb,
		edge_colour,
		outer_edge
	);

	final_colour += (
		star_colour.rgb
		* stars
		* 2.0
	);

	float final_alpha = max(
		outer_edge,
		trail * trail_opacity
	);

	final_alpha = max(
		final_alpha,
		stars
	);

	ALBEDO = final_colour;

	EMISSION = (
		edge_colour
		* outer_edge
		* edge_emission
		+ star_colour.rgb
		* stars
		* star_emission
	);

	ALPHA = clamp(
		final_alpha
		* overlay_opacity,
		0.0,
		1.0
	);
}