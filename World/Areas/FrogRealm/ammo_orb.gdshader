shader_type spatial;

render_mode cull_disabled, depth_draw_opaque,
	diffuse_burley, specular_schlick_ggx;


// Fill

uniform float fill_progress : hint_range(0.0, 1.0) = 1.0;

// Local-space vertical bounds of the mesh.
uniform float fill_bottom = -0.5;
uniform float fill_top = 0.5;

uniform float surface_softness : hint_range(0.001, 0.1) = 0.015;
uniform float surface_wobble : hint_range(0.0, 0.15) = 0.025;
uniform float wobble_speed : hint_range(0.0, 5.0) = 1.5;


// Colours

uniform vec4 liquid_colour : source_color =
	vec4(0.32, 0.035, 0.72, 0.82);

uniform vec4 energy_colour : source_color =
	vec4(0.78, 0.18, 1.0, 1.0);

uniform vec4 highlight_colour : source_color =
	vec4(0.95, 0.62, 1.0, 1.0);


// Appearance

uniform float emission_strength : hint_range(0.0, 10.0) = 2.0;
uniform float fresnel_strength : hint_range(0.0, 5.0) = 1.5;
uniform float swirl_scale : hint_range(0.1, 20.0) = 5.0;
uniform float swirl_speed : hint_range(0.0, 5.0) = 0.8;

uniform float bubble_scale : hint_range(1.0, 50.0) = 14.0;
uniform float bubble_strength : hint_range(0.0, 1.0) = 0.3;


varying vec3 local_position;


float random_value(vec3 position) {
	return fract(
		sin(dot(position, vec3(12.9898, 78.233, 45.164)))
		* 43758.5453
	);
}


float hash(vec3 position) {
	position = fract(position * 0.3183099 + 0.1);
	position *= 17.0;

	return fract(
		position.x * position.y * position.z
		* (position.x + position.y + position.z)
	);
}


float smooth_noise(vec3 position) {
	vec3 cell = floor(position);
	vec3 fraction = fract(position);

	// Quintic interpolation hides the grid better than cubic smoothing.
	fraction = fraction * fraction * fraction
		* (fraction * (fraction * 6.0 - 15.0) + 10.0);

	float n000 = hash(cell + vec3(0.0, 0.0, 0.0));
	float n100 = hash(cell + vec3(1.0, 0.0, 0.0));
	float n010 = hash(cell + vec3(0.0, 1.0, 0.0));
	float n110 = hash(cell + vec3(1.0, 1.0, 0.0));
	float n001 = hash(cell + vec3(0.0, 0.0, 1.0));
	float n101 = hash(cell + vec3(1.0, 0.0, 1.0));
	float n011 = hash(cell + vec3(0.0, 1.0, 1.0));
	float n111 = hash(cell + vec3(1.0, 1.0, 1.0));

	float x00 = mix(n000, n100, fraction.x);
	float x10 = mix(n010, n110, fraction.x);
	float x01 = mix(n001, n101, fraction.x);
	float x11 = mix(n011, n111, fraction.x);

	float y0 = mix(x00, x10, fraction.y);
	float y1 = mix(x01, x11, fraction.y);

	return mix(y0, y1, fraction.z);
}


float fbm(vec3 position) {
	float result = 0.0;
	float amplitude = 0.5;

	// Rotates each noise layer so their grids don't align.
	mat3 rotation = mat3(
		vec3(0.00,  0.80,  0.60),
		vec3(-0.80, 0.36, -0.48),
		vec3(-0.60, -0.48, 0.64)
	);

	for (int octave = 0; octave < 4; octave++) {
		result += smooth_noise(position) * amplitude;
		position = rotation * position * 2.03 + vec3(7.1, 3.4, 5.8);
		amplitude *= 0.5;
	}

	return result;
}


void vertex() {
	local_position = VERTEX;
}


void fragment() {
	float progress = clamp(fill_progress, 0.0, 1.0);

	float wobble =
		sin(local_position.x * 5.0 + TIME * wobble_speed)
		* cos(local_position.z * 4.0 - TIME * wobble_speed * 0.8)
		* surface_wobble;

	float fill_height = mix(
		fill_bottom,
		fill_top,
		progress
	) + wobble;

	// Remove everything above the current liquid level.
	if (local_position.y > fill_height || progress <= 0.001) {
		discard;
	}

	float distance_from_surface = fill_height - local_position.y;

	float surface_glow = 1.0 - smoothstep(
		0.0,
		surface_softness * 5.0,
		distance_from_surface
	);

	vec3 swirl_position = local_position * swirl_scale;

	swirl_position += vec3(
		TIME * swirl_speed * 0.15,
		-TIME * swirl_speed,
		TIME * swirl_speed * 0.1
	);

	// Domain warping breaks up the remaining uniform pattern.
	vec3 warp = vec3(
		fbm(swirl_position + vec3(4.7, 1.3, 8.1)),
		fbm(swirl_position + vec3(9.2, 5.4, 2.6)),
		fbm(swirl_position + vec3(1.8, 7.5, 6.3))
	);

	float swirl = fbm(
		swirl_position + (warp - 0.5) * 2.0
	);

	swirl = smoothstep(0.3, 0.75, swirl);

	// Small rising magical bubbles.
	vec3 bubble_position = local_position * bubble_scale;
	bubble_position.y -= TIME * 2.0;

	float bubbles = smooth_noise(bubble_position);
	bubbles = smoothstep(0.83, 0.94, bubbles) * bubble_strength;

	float fresnel = pow(
		1.0 - max(dot(NORMAL, VIEW), 0.0),
		2.5
	);

	vec3 colour = liquid_colour.rgb;
	colour = mix(colour, energy_colour.rgb, swirl * 0.25);
	colour += highlight_colour.rgb * bubbles;
	colour += highlight_colour.rgb * surface_glow;
	colour += energy_colour.rgb * fresnel * fresnel_strength;

	ALBEDO = colour;
	ROUGHNESS = 0.18;
	METALLIC = 0.05;
	SPECULAR = 0.9;

	EMISSION =
		energy_colour.rgb * swirl * emission_strength
		+ highlight_colour.rgb * surface_glow * emission_strength
		+ highlight_colour.rgb * bubbles * emission_strength;

	ALPHA = clamp(
		liquid_colour.a
		+ fresnel * 0.15
		+ surface_glow * 0.15,
		0.0,
		1.0
	);
}