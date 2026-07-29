shader_type spatial;

render_mode blend_add, depth_draw_never, cull_back, unshaded;


// Animation

uniform float progress : hint_range(0.0, 1.0) = 0.0;

uniform float transition_softness :
	hint_range(0.001, 0.25) = 0.06;


// Appearance

uniform vec4 shield_color : source_color =
	vec4(0.35, 0.85, 1.0, 1.0);

uniform vec4 highlight_color : source_color =
	vec4(0.8, 1.0, 1.0, 1.0);

uniform float opacity :
	hint_range(0.0, 1.0) = 0.6;

uniform float rim_power :
	hint_range(0.5, 8.0) = 2.5;

uniform float rim_strength :
	hint_range(0.0, 4.0) = 1.5;


// Shell

/// Pushes the overlay slightly outside Pip's mesh.
uniform float shell_offset :
	hint_range(0.0, 0.01, 0.0001) = 0.008;


// Animated pattern

uniform float pattern_scale :
	hint_range(1.0, 100.0) = 25.0;

uniform float animation_speed :
	hint_range(0.0, 10.0) = 1.5;

uniform float shimmer_strength :
	hint_range(0.0, 1.0) = 0.25;


// Produces stable procedural noise.
float random_value(vec2 position) {
	return fract(
		sin(dot(position, vec2(12.9898, 78.233))) *
		43758.5453
	);
}


void vertex() {
	// Expand the overlay to prevent z-fighting with Pip's material.
	VERTEX += NORMAL * shell_offset * progress;
}


void fragment() {
	vec3 normal = normalize(NORMAL);
	vec3 view_direction = normalize(VIEW);

	// Stronger around the silhouette of the character.
	float fresnel = pow(
		1.0 - max(dot(normal, view_direction), 0.0),
		rim_power
	);

	// Pixelated pattern used to reveal and hide the shield.
	vec2 pattern_uv = floor(
		UV * pattern_scale
	);

	float pattern = random_value(pattern_uv);

	float reveal = smoothstep(
		pattern - transition_softness,
		pattern + transition_softness,
		progress
	);

	// Gentle energy moving across the surface.
	float shimmer = sin(
		UV.y * pattern_scale +
		UV.x * pattern_scale * 0.5 -
		TIME * animation_speed
	);

	shimmer = shimmer * 0.5 + 0.5;

	vec3 color = mix(
		shield_color.rgb,
		highlight_color.rgb,
		shimmer * shimmer_strength
	);

	float rim = fresnel * rim_strength;

	ALBEDO = color;
	EMISSION = color * (0.35 + rim);

	ALPHA = reveal *
		progress *
		opacity *
		(0.35 + rim);
}