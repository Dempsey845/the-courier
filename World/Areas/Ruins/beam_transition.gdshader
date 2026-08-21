shader_type canvas_item;

render_mode blend_mix;


// Transition

uniform float transition :
	hint_range(0.0, 1.0) = 0.0;

uniform float edge_softness :
	hint_range(0.001, 0.2) = 0.025;

uniform float wave_height :
	hint_range(0.0, 0.2) = 0.045;

uniform float wave_speed :
	hint_range(-10.0, 10.0) = 2.0;


// Colours

uniform vec4 base_colour : source_color =
	vec4(0.01, 0.12, 0.35, 1.0);

uniform vec4 beam_colour : source_color =
	vec4(0.02, 0.45, 1.0, 1.0);

uniform vec4 swirl_colour : source_color =
	vec4(0.15, 0.85, 1.0, 1.0);

uniform float brightness :
	hint_range(0.0, 5.0) = 1.5;


// Portal swirls

uniform float swirl_amount :
	hint_range(0.0, 1.0) = 0.45;

uniform float swirl_count :
	hint_range(1.0, 15.0) = 5.0;

uniform float swirl_tightness :
	hint_range(0.0, 30.0) = 10.0;

uniform float swirl_speed :
	hint_range(-10.0, 10.0) = 1.5;

uniform float swirl_sharpness :
	hint_range(1.0, 12.0) = 5.0;


// Transition edge

uniform float edge_width :
	hint_range(0.001, 0.2) = 0.055;

uniform float edge_brightness :
	hint_range(0.0, 10.0) = 4.0;


void fragment() {
	vec2 centered_uv = UV - vec2(0.5);

	// Slightly correct the circular calculations for wide screens.
	centered_uv.x *= SCREEN_PIXEL_SIZE.y / SCREEN_PIXEL_SIZE.x;

	float distance_from_center = length(centered_uv);
	float angle = atan(centered_uv.y, centered_uv.x);

	// Animated portal-like spiral.
	float spiral = (
		angle * swirl_count
		+ distance_from_center * swirl_tightness
		- TIME * swirl_speed
	);

	float swirl = sin(spiral) * 0.5 + 0.5;
	swirl = pow(swirl, swirl_sharpness);

	// A secondary spiral moving in the opposite direction.
	float secondary_spiral = sin(
		-angle * (swirl_count * 0.6)
		+ distance_from_center * (swirl_tightness * 1.4)
		+ TIME * swirl_speed * 0.7
	);

	secondary_spiral = secondary_spiral * 0.5 + 0.5;
	secondary_spiral = pow(
		secondary_spiral,
		swirl_sharpness * 0.75
	);

	float combined_swirl = max(
		swirl,
		secondary_spiral * 0.6
	);

	// Distort the leading edge using energy waves.
	float leading_wave =
		sin(UV.x * 14.0 + TIME * wave_speed) * wave_height;

	leading_wave +=
		sin(UV.x * 31.0 - TIME * wave_speed * 1.4)
		* wave_height
		* 0.35;

	// transition 0 = invisible.
	// transition 1 = fully covering the screen.
	float transition_height = transition * 1.2 - 0.1;
	float wipe_position = 1.0 - transition_height + leading_wave;

	float coverage = smoothstep(
		wipe_position - edge_softness,
		wipe_position + edge_softness,
		UV.y
	);

	// Bright energy line along the transition boundary.
	float edge_distance = abs(UV.y - wipe_position);

	float transition_edge = 1.0 - smoothstep(
		0.0,
		edge_width,
		edge_distance
	);

	transition_edge *= coverage;

	vec3 colour = mix(
		beam_colour.rgb,
		swirl_colour.rgb,
		combined_swirl * swirl_amount
	);

	// Darken the fully covered area slightly so it properly hides the scene.
	colour = mix(
		base_colour.rgb,
		colour,
		0.7
	);

	colour += swirl_colour.rgb
		* transition_edge
		* edge_brightness;

	colour *= brightness;

	COLOR = vec4(
		colour,
		coverage
	);
}