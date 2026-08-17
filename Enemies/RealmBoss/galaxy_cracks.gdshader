shader_type spatial;

render_mode blend_mix, depth_draw_opaque, cull_disabled,
	diffuse_burley, specular_schlick_ggx;


// Base material

uniform vec4 albedo : source_color = vec4(1.0);

uniform sampler2D texture_albedo
	: source_color, filter_linear_mipmap, repeat_enable;

uniform float roughness
	: hint_range(0.0, 1.0) = 0.7;

uniform sampler2D texture_roughness
	: hint_roughness_r, filter_linear_mipmap, repeat_enable;

uniform float metallic
	: hint_range(0.0, 1.0) = 0.0;

uniform sampler2D texture_metallic
	: hint_default_white, filter_linear_mipmap, repeat_enable;

uniform vec4 metallic_texture_channel =
	vec4(1.0, 0.0, 0.0, 0.0);

uniform float specular
	: hint_range(0.0, 1.0, 0.01) = 0.5;

uniform vec3 uv1_scale = vec3(1.0);
uniform vec3 uv1_offset = vec3(0.0);


// Effect controls

uniform float progress
	: hint_range(0.0, 1.0) = 0.0;

uniform float progress_softness
	: hint_range(0.001, 0.3) = 0.08;

uniform float effect_scale
	: hint_range(0.001, 5.0) = 0.2;

uniform float dissolve_scale
	: hint_range(0.1, 20.0) = 1.5;


// Cracks

uniform float crack_scale
	: hint_range(0.5, 30.0) = 5.0;

uniform float crack_width
	: hint_range(0.001, 0.3) = 0.08;

uniform float crack_softness
	: hint_range(0.001, 0.2) = 0.025;

uniform float secondary_crack_scale
	: hint_range(0.5, 50.0) = 11.0;

uniform float secondary_crack_strength
	: hint_range(0.0, 1.0) = 0.3;


// Galaxy

uniform vec4 deep_purple : source_color =
	vec4(0.025, 0.002, 0.09, 1.0);

uniform vec4 galaxy_purple : source_color =
	vec4(0.3, 0.015, 0.85, 1.0);

uniform vec4 galaxy_magenta : source_color =
	vec4(0.95, 0.04, 0.75, 1.0);

uniform vec4 galaxy_blue : source_color =
	vec4(0.08, 0.25, 1.0, 1.0);

uniform vec4 crack_edge_color : source_color =
	vec4(0.75, 0.25, 1.0, 1.0);

uniform vec4 star_color : source_color =
	vec4(0.95, 0.9, 1.0, 1.0);

uniform float galaxy_scale
	: hint_range(0.1, 20.0) = 2.5;

uniform float galaxy_speed
	: hint_range(0.0, 2.0) = 0.1;

uniform float star_scale
	: hint_range(2.0, 100.0) = 28.0;

uniform float star_density
	: hint_range(0.8, 0.9999) = 0.985;

uniform float emission_strength
	: hint_range(0.0, 20.0) = 5.0;

uniform float edge_emission_strength
	: hint_range(0.0, 30.0) = 10.0;


varying vec3 object_position;


// Random functions

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


vec3 random_33(vec3 position) {
	return vec3(
		random_31(position),
		random_31(position + vec3(19.19, 73.73, 41.41)),
		random_31(position + vec3(47.47, 11.11, 89.89))
	);
}


// Seamless 3D value noise

float value_noise_3d(vec3 position) {
	vec3 cell = floor(position);
	vec3 local_point = fract(position);

	vec3 smooth_point = (
		local_point
		* local_point
		* (3.0 - 2.0 * local_point)
	);

	float n000 = random_31(cell + vec3(0.0, 0.0, 0.0));
	float n100 = random_31(cell + vec3(1.0, 0.0, 0.0));
	float n010 = random_31(cell + vec3(0.0, 1.0, 0.0));
	float n110 = random_31(cell + vec3(1.0, 1.0, 0.0));

	float n001 = random_31(cell + vec3(0.0, 0.0, 1.0));
	float n101 = random_31(cell + vec3(1.0, 0.0, 1.0));
	float n011 = random_31(cell + vec3(0.0, 1.0, 1.0));
	float n111 = random_31(cell + vec3(1.0, 1.0, 1.0));

	float x00 = mix(n000, n100, smooth_point.x);
	float x10 = mix(n010, n110, smooth_point.x);
	float x01 = mix(n001, n101, smooth_point.x);
	float x11 = mix(n011, n111, smooth_point.x);

	float y0 = mix(x00, x10, smooth_point.y);
	float y1 = mix(x01, x11, smooth_point.y);

	return mix(y0, y1, smooth_point.z);
}


float fractal_noise_3d(vec3 position) {
	float result = 0.0;
	float amplitude = 0.5;

	for (int octave = 0; octave < 4; octave++) {
		result += value_noise_3d(position) * amplitude;

		position = (
			position * 2.03
			+ vec3(17.1, 9.2, 13.7)
		);

		amplitude *= 0.5;
	}

	return result;
}


// Genuine 3D Voronoi boundaries.
// These remain connected across the entire mesh.

float voronoi_edge_3d(vec3 position) {
	vec3 cell = floor(position);
	vec3 cell_position = fract(position);

	float closest_distance = 10.0;
	float second_distance = 10.0;

	for (int z = -1; z <= 1; z++) {
		for (int y = -1; y <= 1; y++) {
			for (int x = -1; x <= 1; x++) {
				vec3 neighbour = vec3(
					float(x),
					float(y),
					float(z)
				);

				vec3 point = random_33(
					cell + neighbour
				);

				vec3 difference = (
					neighbour
					+ point
					- cell_position
				);

				float distance_to_point = length(
					difference
				);

				if (
					distance_to_point
					< closest_distance
				) {
					second_distance = closest_distance;
					closest_distance = distance_to_point;
				} else if (
					distance_to_point
					< second_distance
				) {
					second_distance = distance_to_point;
				}
			}
		}
	}

	return second_distance - closest_distance;
}


float create_cracks_3d(vec3 position) {
	vec3 warp = vec3(
		fractal_noise_3d(position * 1.3),
		fractal_noise_3d(
			position * 1.3 + vec3(17.2, 31.8, 9.4)
		),
		fractal_noise_3d(
			position * 1.3 + vec3(53.1, 7.7, 24.6)
		)
	);

	warp = (warp - 0.5) * 0.22;

	vec3 warped_position = position + warp;

	float main_edge = voronoi_edge_3d(
		warped_position * crack_scale
	);

	float main_cracks = 1.0 - smoothstep(
		crack_width,
		crack_width + crack_softness,
		main_edge
	);

	float secondary_edge = voronoi_edge_3d(
		warped_position * secondary_crack_scale
		+ vec3(13.7, 27.1, 8.9)
	);

	float secondary_cracks = 1.0 - smoothstep(
		crack_width * 0.55,
		crack_width * 0.55 + crack_softness,
		secondary_edge
	);

	secondary_cracks *= secondary_crack_strength;

	return clamp(
		max(main_cracks, secondary_cracks),
		0.0,
		1.0
	);
}


// Random noisy reveal rather than a moving line

float create_progress_mask_3d(vec3 position) {
	if (progress <= 0.001) {
		return 0.0;
	}

	if (progress >= 0.999) {
		return 1.0;
	}

	float dissolve_noise = fractal_noise_3d(
		position * dissolve_scale
	);

	float small_detail = value_noise_3d(
		position * dissolve_scale * 4.0
	);

	dissolve_noise = mix(
		dissolve_noise,
		small_detail,
		0.25
	);

	float threshold = 1.0 - progress;

	return smoothstep(
		threshold - progress_softness,
		threshold + progress_softness,
		dissolve_noise
	);
}


vec3 create_galaxy_3d(vec3 position) {
	float time_offset = TIME * galaxy_speed;

	vec3 galaxy_position = (
		position * galaxy_scale
		+ vec3(
			time_offset,
			-time_offset * 0.35,
			time_offset * 0.2
		)
	);

	float first_cloud = fractal_noise_3d(
		galaxy_position
	);

	float second_cloud = fractal_noise_3d(
		galaxy_position * 1.8
		+ vec3(
			first_cloud * 2.0,
			-first_cloud * 1.5,
			first_cloud
		)
	);

	float swirl = sin(
		galaxy_position.x * 1.7
		+ galaxy_position.y * 1.2
		+ galaxy_position.z
		+ second_cloud * 7.0
		+ time_offset
	);

	swirl = swirl * 0.5 + 0.5;

	vec3 colour = mix(
		deep_purple.rgb,
		galaxy_purple.rgb,
		smoothstep(0.18, 0.72, first_cloud)
	);

	colour = mix(
		colour,
		galaxy_magenta.rgb,
		smoothstep(0.55, 0.88, second_cloud)
	);

	colour = mix(
		colour,
		galaxy_blue.rgb,
		smoothstep(0.7, 1.0, swirl) * second_cloud
	);

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
		0.16,
		random_31(star_cell + vec3(7.3))
	);

	star *= 1.0 - smoothstep(
		star_size,
		star_size * 2.5,
		length(star_position)
	);

	float twinkle = (
		sin(TIME * 4.0 + star_random * TAU)
		* 0.25
		+ 0.75
	);

	colour += (
		star_color.rgb
		* star
		* twinkle
		* 4.0
	);

	return colour;
}


void vertex() {
	UV = UV * uv1_scale.xy + uv1_offset.xy;
	object_position = VERTEX;
}


void fragment() {
	vec2 base_uv = UV;

	vec4 albedo_texture = texture(
		texture_albedo,
		base_uv
	);

	vec3 base_colour = (
		albedo.rgb
		* albedo_texture.rgb
	);

	float metallic_texture_value = dot(
		texture(texture_metallic, base_uv),
		metallic_texture_channel
	);

	float roughness_texture_value = texture(
		texture_roughness,
		base_uv
	).r;

	vec3 effect_position = (
		object_position * effect_scale
	);

	float crack_shape = create_cracks_3d(
		effect_position
	);

	float progress_mask = create_progress_mask_3d(
		effect_position
	);

	float crack_mask = (
		crack_shape * progress_mask
	);

	// A slightly wider mask around the main cracks.
	float wide_crack_mask = smoothstep(
		0.0,
		0.75,
		crack_shape
	);

	wide_crack_mask *= progress_mask;

	float crack_edge = clamp(
		wide_crack_mask - crack_mask * 0.65,
		0.0,
		1.0
	);

	vec3 galaxy_colour = create_galaxy_3d(
		effect_position
	);

	vec3 final_colour = mix(
		base_colour,
		galaxy_colour,
		crack_mask
	);

	final_colour = mix(
		final_colour,
		crack_edge_color.rgb,
		crack_edge * 0.6
	);

	ALBEDO = final_colour;

	EMISSION = (
		galaxy_colour
		* crack_mask
		* emission_strength
		+ crack_edge_color.rgb
		* crack_edge
		* edge_emission_strength
	);

	METALLIC = mix(
		metallic_texture_value * metallic,
		0.15,
		crack_mask
	);

	SPECULAR = specular;

	ROUGHNESS = mix(
		roughness_texture_value * roughness,
		0.2,
		crack_mask
	);
}