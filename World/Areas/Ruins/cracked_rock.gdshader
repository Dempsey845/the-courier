shader_type spatial;

render_mode cull_back, depth_draw_opaque,
	diffuse_burley, specular_schlick_ggx;


// Appearance

uniform vec4 rock_color : source_color =
	vec4(0.30, 0.28, 0.25, 1.0);

uniform vec4 rock_highlight : source_color =
	vec4(0.48, 0.44, 0.38, 1.0);

uniform vec4 crack_color : source_color =
	vec4(0.035, 0.025, 0.02, 1.0);


// Crack shape

uniform float texture_scale :
	hint_range(1.0, 50.0, 0.1) = 8.0;

uniform float crack_width :
	hint_range(0.001, 0.25, 0.001) = 0.065;

uniform float crack_softness :
	hint_range(0.001, 0.1, 0.001) = 0.015;

uniform float crack_depth :
	hint_range(0.0, 1.0, 0.01) = 0.35;


// Surface variation

uniform float color_variation :
	hint_range(0.0, 1.0, 0.01) = 0.25;

uniform float normal_strength :
	hint_range(0.0, 8.0, 0.1) = 2.5;

uniform float roughness :
	hint_range(0.0, 1.0, 0.01) = 0.9;


// Random value for each grid cell.

vec2 random_vec2(vec2 position) {
	vec2 result = vec2(
		dot(position, vec2(127.1, 311.7)),
		dot(position, vec2(269.5, 183.3))
	);

	return fract(sin(result) * 43758.5453);
}


// Basic value noise.

float value_noise(vec2 position) {
	vec2 cell = floor(position);
	vec2 local_position = fract(position);

	vec2 smooth_position =
		local_position * local_position *
		(3.0 - 2.0 * local_position);

	float bottom_left =
		random_vec2(cell).x;

	float bottom_right =
		random_vec2(cell + vec2(1.0, 0.0)).x;

	float top_left =
		random_vec2(cell + vec2(0.0, 1.0)).x;

	float top_right =
		random_vec2(cell + vec2(1.0, 1.0)).x;

	float bottom = mix(
		bottom_left,
		bottom_right,
		smooth_position.x
	);

	float top = mix(
		top_left,
		top_right,
		smooth_position.x
	);

	return mix(bottom, top, smooth_position.y);
}


// Returns the distance between the two nearest Voronoi points.
// Values close to zero are cell borders, which become cracks.

float voronoi_edge(vec2 position) {
	vec2 base_cell = floor(position);
	vec2 local_position = fract(position);

	float closest = 10.0;
	float second_closest = 10.0;

	for (int y = -1; y <= 1; y++) {
		for (int x = -1; x <= 1; x++) {
			vec2 neighbour = vec2(float(x), float(y));

			vec2 point =
				neighbour +
				random_vec2(base_cell + neighbour);

			float distance_to_point =
				length(point - local_position);

			if (distance_to_point < closest) {
				second_closest = closest;
				closest = distance_to_point;
			} else if (
				distance_to_point < second_closest
			) {
				second_closest = distance_to_point;
			}
		}
	}

	return second_closest - closest;
}


float get_cracks(vec2 uv) {
	vec2 distorted_uv = uv;

	// Warping prevents the cracks from looking like a grid.
	float distortion_x =
		value_noise(uv * 2.7 + vec2(4.3, 1.7));

	float distortion_y =
		value_noise(uv * 2.7 + vec2(8.1, 6.2));

	distorted_uv +=
		(vec2(distortion_x, distortion_y) - 0.5) * 0.5;

	float edge = voronoi_edge(
		distorted_uv * texture_scale
	);

	return 1.0 - smoothstep(
		crack_width,
		crack_width + crack_softness,
		edge
	);
}


void fragment() {
	vec2 rock_uv = UV;

	float cracks = get_cracks(rock_uv);

	// Large and small colour variation.
	float large_noise =
		value_noise(rock_uv * texture_scale * 0.45);

	float small_noise =
		value_noise(rock_uv * texture_scale * 3.5);

	float surface_noise =
		mix(large_noise, small_noise, 0.3);

	vec3 surface_color = mix(
		rock_color.rgb,
		rock_highlight.rgb,
		surface_noise * color_variation
	);

	ALBEDO = mix(
		surface_color,
		crack_color.rgb,
		cracks
	);

	ROUGHNESS = mix(
		roughness,
		1.0,
		cracks
	);

	SPECULAR = 0.12;

	// Creates the illusion that the cracks are recessed.
	float surface_height =
		surface_noise * 0.15 -
		cracks * crack_depth;

	float height_x = dFdx(surface_height);
	float height_y = dFdy(surface_height);

	NORMAL_MAP = normalize(vec3(
		-height_x * normal_strength,
		-height_y * normal_strength,
		1.0
	));

	NORMAL_MAP_DEPTH = normal_strength;
}