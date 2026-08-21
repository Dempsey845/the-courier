shader_type spatial;

render_mode unshaded, blend_add, depth_draw_opaque, cull_disabled;


// Transition

uniform float transition : hint_range(0.0, 1.0) = 1.0;

// Set this to the cylinder's lowest local Y position.
// For a cylinder with a height of 10, use -5.
uniform float bottom_y = -5.0;


// Colours

uniform vec4 beam_colour : source_color =
	vec4(0.02, 0.45, 1.0, 1.0);

uniform vec4 swirl_colour : source_color =
	vec4(0.15, 0.85, 1.0, 1.0);

uniform float brightness :
	hint_range(0.0, 8.0) = 2.5;


// Swirls

uniform float swirl_amount :
	hint_range(0.0, 1.0) = 0.35;

uniform float swirl_count :
	hint_range(1.0, 12.0) = 4.0;

uniform float swirl_tightness :
	hint_range(0.0, 20.0) = 6.0;

uniform float swirl_speed :
	hint_range(-10.0, 10.0) = 1.5;

uniform float swirl_sharpness :
	hint_range(1.0, 12.0) = 5.0;


// Surface

uniform float opacity :
	hint_range(0.0, 1.0) = 0.85;

uniform float edge_glow :
	hint_range(0.0, 3.0) = 0.5;


void vertex() {
	float growth = smoothstep(0.0, 1.0, transition);

	// Collapse every vertex to the bottom, then restore its original height.
	VERTEX.y = mix(bottom_y, VERTEX.y, growth);
}


void fragment() {
	float angle = atan(VERTEX.z, VERTEX.x);

	// A spiral wrapping around the cylinder.
	float spiral = (
		angle * swirl_count
		+ VERTEX.y * swirl_tightness
		- TIME * swirl_speed
	);

	float swirl = sin(spiral) * 0.5 + 0.5;
	swirl = pow(swirl, swirl_sharpness);

	// Add a second softer spiral to keep the pattern less uniform.
	float secondary_spiral = sin(
		angle * (swirl_count * 0.5)
		- VERTEX.y * (swirl_tightness * 0.6)
		+ TIME * swirl_speed * 0.7
	);

	secondary_spiral = secondary_spiral * 0.5 + 0.5;
	secondary_spiral = pow(secondary_spiral, swirl_sharpness * 0.75);

	float combined_swirl = max(
		swirl,
		secondary_spiral * 0.55
	);

	vec3 colour = mix(
		beam_colour.rgb,
		swirl_colour.rgb,
		combined_swirl * swirl_amount
	);

	// Extra glow around the silhouette.
	float fresnel = 1.0 - abs(
		dot(normalize(NORMAL), normalize(VIEW))
	);

	colour += swirl_colour.rgb * fresnel * edge_glow;
	colour *= brightness;

	ALBEDO = colour;
	EMISSION = colour;
	ALPHA = opacity * beam_colour.a;
}