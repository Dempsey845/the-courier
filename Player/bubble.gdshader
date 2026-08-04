shader_type spatial;

render_mode blend_mix, depth_prepass_alpha, cull_back,
	diffuse_burley, specular_schlick_ggx;


// Bubble appearance

uniform vec4 bubble_tint : source_color =
	vec4(0.55, 0.85, 1.0, 1.0);

uniform vec4 rim_color : source_color =
	vec4(0.75, 0.95, 1.0, 1.0);

uniform float transparency : hint_range(0.0, 1.0) = 0.12;
uniform float rim_strength : hint_range(0.0, 5.0) = 1.6;
uniform float rim_power : hint_range(0.5, 8.0) = 3.0;


// Refraction

uniform sampler2D screen_texture :
	hint_screen_texture, filter_linear_mipmap;

uniform float refraction_strength :
	hint_range(0.0, 0.1, 0.001) = 0.025;


// Iridescence

uniform float rainbow_strength :
	hint_range(0.0, 2.0) = 0.65;

uniform float rainbow_scale :
	hint_range(1.0, 30.0) = 8.0;

uniform float rainbow_speed :
	hint_range(-5.0, 5.0) = 0.35;


// Surface movement

uniform float wobble_strength :
	hint_range(0.0, 0.2) = 0.025;

uniform float wobble_scale :
	hint_range(0.1, 10.0) = 2.0;

uniform float wobble_speed :
	hint_range(0.0, 5.0) = 1.0;


varying vec3 world_position;


void vertex() {
	world_position = (
		MODEL_MATRIX * vec4(VERTEX, 1.0)
	).xyz;

	// Small animated deformation along the sphere's normals.
	float wobble =
		sin(VERTEX.y * wobble_scale + TIME * wobble_speed) *
		sin(VERTEX.x * wobble_scale * 1.37 - TIME * wobble_speed * 0.8) *
		sin(VERTEX.z * wobble_scale * 0.83 + TIME * wobble_speed * 0.6);

	VERTEX += NORMAL * wobble * wobble_strength;
}


void fragment() {
	vec3 normal = normalize(NORMAL);
	vec3 view_direction = normalize(VIEW);

	// Fresnel becomes stronger around the edge of the sphere.
	float fresnel = 1.0 - clamp(
		dot(normal, view_direction),
		0.0,
		1.0
	);

	float rim = pow(fresnel, rim_power) * rim_strength;

	// Slightly distort whatever is behind the bubble.
	vec2 refraction_offset =
		normal.xy *
		refraction_strength *
		(0.25 + fresnel * 0.75);

	vec3 refracted_scene = textureLod(
		screen_texture,
		SCREEN_UV + refraction_offset,
		0.0
	).rgb;

	// Animated thin-film rainbow effect.
	float rainbow_position =
		fresnel * rainbow_scale +
		world_position.y * 1.5 +
		TIME * rainbow_speed;

	vec3 rainbow = 0.5 + 0.5 * cos(
		rainbow_position +
		vec3(0.0, 2.094, 4.188)
	);

	float rainbow_mask =
		smoothstep(0.15, 0.85, fresnel) *
		(1.0 - smoothstep(0.85, 1.0, fresnel));

	vec3 iridescence =
		rainbow *
		rainbow_mask *
		rainbow_strength;

	vec3 final_color = mix(
		refracted_scene,
		bubble_tint.rgb,
		0.08 + fresnel * 0.12
	);

	final_color += iridescence;
	final_color += rim_color.rgb * rim;

	ALBEDO = final_color;
	EMISSION = iridescence * 0.45 + rim_color.rgb * rim * 0.25;

	METALLIC = 0.05;
	ROUGHNESS = 0.03;
	SPECULAR = 1.0;

	ALPHA = clamp(
		transparency +
		rim * 0.32 +
		rainbow_mask * rainbow_strength * 0.12,
		0.0,
		0.9
	);
}