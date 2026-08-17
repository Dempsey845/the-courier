shader_type spatial;

render_mode blend_mix, depth_draw_opaque, cull_back,
	diffuse_burley, specular_schlick_ggx;


varying vec3 object_position;
varying vec3 object_normal;


// Colours

uniform vec4 deep_space_colour : source_color =
	vec4(0.008, 0.002, 0.035, 1.0);

uniform vec4 purple_colour : source_color =
	vec4(0.25, 0.015, 0.65, 1.0);

uniform vec4 nebula_colour : source_color =
	vec4(0.8, 0.08, 1.0, 1.0);

uniform vec4 energy_colour : source_color =
	vec4(0.25, 0.3, 1.0, 1.0);

uniform vec4 star_colour : source_color =
	vec4(0.9, 0.75, 1.0, 1.0);


// Surface

uniform float roughness : hint_range(0.0, 1.0) = 0.3;
uniform float metallic : hint_range(0.0, 1.0) = 0.15;

uniform float emission_strength :
	hint_range(0.0, 8.0) = 2.5;


// Mapping

uniform float pattern_world_size :
	hint_range(0.5, 30.0) = 8.0;

uniform float triplanar_sharpness :
	hint_range(1.0, 16.0) = 6.0;


// Galaxy pattern

uniform float galaxy_scale :
	hint_range(0.1, 20.0) = 1.5;

uniform float nebula_detail :
	hint_range(1.0, 10.0) = 4.0;

uniform float swirl_strength :
	hint_range(0.0, 3.0) = 0.35;

uniform float animation_speed :
	hint_range(0.0, 2.0) = 0.08;


// Stars

uniform float star_scale :
	hint_range(1.0, 200.0) = 18.0;

uniform float star_density :
	hint_range(0.9, 0.999) = 0.985;

uniform float star_brightness :
	hint_range(0.0, 10.0) = 4.0;

uniform float twinkle_speed :
	hint_range(0.0, 10.0) = 2.0;


// Edge glow

uniform float edge_glow_strength :
	hint_range(0.0, 8.0) = 1.5;

uniform float edge_glow_power :
	hint_range(0.5, 8.0) = 3.0;


void vertex() {
	object_position = VERTEX;
	object_normal = NORMAL;
}


float random_2d(vec2 position) {
	return fract(
		sin(dot(position, vec2(127.1, 311.7)))
		* 43758.5453
	);
}


float value_noise(vec2 position) {
	vec2 cell = floor(position);
	vec2 noise_position = fract(position);

	noise_position = noise_position
		* noise_position
		* (3.0 - 2.0 * noise_position);

	float bottom_left = random_2d(cell);

	float bottom_right = random_2d(
		cell + vec2(1.0, 0.0)
	);

	float top_left = random_2d(
		cell + vec2(0.0, 1.0)
	);

	float top_right = random_2d(
		cell + vec2(1.0, 1.0)
	);

	float bottom = mix(
		bottom_left,
		bottom_right,
		noise_position.x
	);

	float top = mix(
		top_left,
		top_right,
		noise_position.x
	);

	return mix(
		bottom,
		top,
		noise_position.y
	);
}


float fbm(vec2 position) {
	float result = 0.0;
	float amplitude = 0.5;

	for (int layer = 0; layer < 5; layer++) {
		result += value_noise(position) * amplitude;

		position = position * nebula_detail
			+ vec2(13.7, 9.2);

		amplitude *= 0.5;
	}

	return result;
}


vec2 get_triplanar_coordinates(
	vec3 position,
	vec3 normal
) {
	normal = normalize(normal);

	vec3 weights = pow(
		abs(normal),
		vec3(triplanar_sharpness)
	);

	weights /= max(
		weights.x + weights.y + weights.z,
		0.0001
	);

	vec2 x_projection = position.zy;
	vec2 y_projection = position.xz;
	vec2 z_projection = position.xy;

	vec2 coordinates =
		x_projection * weights.x
		+ y_projection * weights.y
		+ z_projection * weights.z;

	return coordinates / pattern_world_size;
}


void fragment() {
	vec2 surface_coordinates =
		get_triplanar_coordinates(
			object_position,
			object_normal
		);

	vec2 coordinates =
		surface_coordinates * galaxy_scale;

	float time = TIME * animation_speed;

	float distortion = fbm(
		coordinates * 0.55
		+ vec2(time, -time * 0.7)
	);

	vec2 galaxy_coordinates = coordinates;

	galaxy_coordinates.x += sin(
		coordinates.y * 1.8
		+ distortion * 5.0
		+ time
	) * swirl_strength;

	galaxy_coordinates.y += cos(
		coordinates.x * 1.4
		- distortion * 4.0
		- time
	) * swirl_strength;

	float large_nebula = fbm(
		galaxy_coordinates * 0.45
		+ vec2(time * 0.4, -time * 0.25)
	);

	float fine_nebula = fbm(
		galaxy_coordinates * 1.25
		- vec2(time * 0.25, time * 0.35)
	);

	float nebula = smoothstep(
		0.3,
		0.82,
		large_nebula * 0.75
		+ fine_nebula * 0.45
	);

	float bright_nebula = smoothstep(
		0.58,
		0.9,
		fine_nebula * large_nebula
	);

	vec2 star_coordinates =
		surface_coordinates * star_scale;

	vec2 star_cell = floor(star_coordinates);

	vec2 star_position =
		fract(star_coordinates) - 0.5;

	float star_random = random_2d(star_cell);

	float star_exists = step(
		star_density,
		star_random
	);

	float star_distance = length(star_position);

	float star_shape = smoothstep(
		0.09,
		0.0,
		star_distance
	);

	float star_cross = (
		smoothstep(
			0.025,
			0.0,
			abs(star_position.x)
		)
		+ smoothstep(
			0.025,
			0.0,
			abs(star_position.y)
		)
	) * smoothstep(
		0.3,
		0.0,
		star_distance
	);

	float twinkle =
		0.65
		+ 0.35 * sin(
			TIME * twinkle_speed
			+ star_random * 30.0
		);

	float stars = (
		star_shape
		+ star_cross * 0.35
	) * star_exists * twinkle;

	float fresnel = pow(
		1.0 - clamp(
			dot(NORMAL, VIEW),
			0.0,
			1.0
		),
		edge_glow_power
	);

	vec3 surface_colour = deep_space_colour.rgb;

	surface_colour = mix(
		surface_colour,
		purple_colour.rgb,
		nebula
	);

	surface_colour = mix(
		surface_colour,
		nebula_colour.rgb,
		bright_nebula
	);

	surface_colour += (
		energy_colour.rgb
		* large_nebula
		* fine_nebula
		* 0.6
	);

	vec3 emission =
		surface_colour * emission_strength;

	emission += (
		star_colour.rgb
		* stars
		* star_brightness
	);

	emission += (
		nebula_colour.rgb
		* fresnel
		* edge_glow_strength
	);

	ALBEDO = surface_colour;
	EMISSION = emission;
	ROUGHNESS = roughness;
	METALLIC = metallic;
}