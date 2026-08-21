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

// This is now measured in world space.
// Higher values produce smaller, more frequent cracks.
uniform float texture_scale :
	hint_range(0.05, 10.0, 0.05) = 1.2;

uniform float crack_width :
	hint_range(0.001, 0.25, 0.001) = 0.065;

uniform float crack_softness :
	hint_range(0.001, 0.1, 0.001) = 0.015;

uniform float crack_depth :
	hint_range(0.0, 1.0, 0.01) = 0.35;


// Triplanar mapping

uniform float triplanar_sharpness :
	hint_range(1.0, 16.0, 0.1) = 5.0;

uniform vec3 world_offset = vec3(0.0);


// Surface variation

uniform float color_variation :
	hint_range(0.0, 1.0, 0.01) = 0.25;

uniform float normal_strength :
	hint_range(0.0, 8.0, 0.1) = 2.5;

uniform float roughness :
	hint_range(0.0, 1.0, 0.01) = 0.9;


varying vec3 world_position;
varying vec3 world_normal;


void vertex() {
	world_position = (
		MODEL_MATRIX * vec4(VERTEX, 1.0)
	).xyz;

	world_normal = normalize(
		MODEL_NORMAL_MATRIX * NORMAL
	);
}


// Random value for each grid cell.

vec2 random_vec2(vec2 position) {
	vec2 result = vec2(
		dot(position, vec2(127.1, 311.7)),
		dot(position, vec2(269.5, 183.3))
	);

	return fract(
		sin(result) * 43758.5453
	);
}


// Basic value noise.

float value_noise(vec2 position) {
	vec2 cell = floor(position);
	vec2 local_position = fract(position);

	vec2 smooth_position =
		local_position *
		local_position *
		(3.0 - 2.0 * local_position);

	float bottom_left =
		random_vec2(cell).x;

	float bottom_right =
		random_vec2(
			cell + vec2(1.0, 0.0)
		).x;

	float top_left =
		random_vec2(
			cell + vec2(0.0, 1.0)
		).x;

	float top_right =
		random_vec2(
			cell + vec2(1.0, 1.0)
		).x;

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

	return mix(
		bottom,
		top,
		smooth_position.y
	);
}


// Returns the distance between the two nearest
// Voronoi points. Values near zero are borders.

float voronoi_edge(vec2 position) {
	vec2 base_cell = floor(position);
	vec2 local_position = fract(position);

	float closest = 10.0;
	float second_closest = 10.0;

	for (int y = -1; y <= 1; y++) {
		for (int x = -1; x <= 1; x++) {
			vec2 neighbour = vec2(
				float(x),
				float(y)
			);

			vec2 point =
				neighbour +
				random_vec2(
					base_cell + neighbour
				);

			float distance_to_point =
				length(
					point - local_position
				);

			if (distance_to_point < closest) {
				second_closest = closest;
				closest = distance_to_point;
			} else if (
				distance_to_point <
				second_closest
			) {
				second_closest =
					distance_to_point;
			}
		}
	}

	return second_closest - closest;
}


float get_cracks(vec2 position) {
	vec2 distorted_position = position;

	float distortion_x =
		value_noise(
			position * 2.7 +
			vec2(4.3, 1.7)
		);

	float distortion_y =
		value_noise(
			position * 2.7 +
			vec2(8.1, 6.2)
		);

	distorted_position += (
		vec2(
			distortion_x,
			distortion_y
		) - 0.5
	) * 0.5;

	float edge = voronoi_edge(
		distorted_position * texture_scale
	);

	return 1.0 - smoothstep(
		crack_width,
		crack_width + crack_softness,
		edge
	);
}


float get_surface_noise(vec2 position) {
	float large_noise = value_noise(
		position * texture_scale * 0.45
	);

	float small_noise = value_noise(
		position * texture_scale * 3.5
	);

	return mix(
		large_noise,
		small_noise,
		0.3
	);
}


vec3 get_triplanar_weights(vec3 normal) {
	vec3 weights = pow(
		abs(normal),
		vec3(triplanar_sharpness)
	);

	return weights / max(
		weights.x + weights.y + weights.z,
		0.0001
	);
}


void fragment() {
	vec3 position =
		world_position + world_offset;

	vec3 weights = get_triplanar_weights(
		normalize(world_normal)
	);

	// X-facing surfaces project along Z/Y.
	vec2 projection_x = position.zy;

	// Y-facing surfaces project along X/Z.
	vec2 projection_y = position.xz;

	// Z-facing surfaces project along X/Y.
	vec2 projection_z = position.xy;


	float cracks_x = get_cracks(
		projection_x
	);

	float cracks_y = get_cracks(
		projection_y
	);

	float cracks_z = get_cracks(
		projection_z
	);

	float cracks =
		cracks_x * weights.x +
		cracks_y * weights.y +
		cracks_z * weights.z;


	float noise_x = get_surface_noise(
		projection_x
	);

	float noise_y = get_surface_noise(
		projection_y
	);

	float noise_z = get_surface_noise(
		projection_z
	);

	float surface_noise =
		noise_x * weights.x +
		noise_y * weights.y +
		noise_z * weights.z;


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


	// Recessed crack illusion.

	float surface_height =
		surface_noise * 0.15 -
		cracks * crack_depth;

	float height_x = dFdx(
		surface_height
	);

	float height_y = dFdy(
		surface_height
	);

	NORMAL_MAP = normalize(vec3(
		-height_x * normal_strength,
		-height_y * normal_strength,
		1.0
	));

	NORMAL_MAP_DEPTH = normal_strength;
}