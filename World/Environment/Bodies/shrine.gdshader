shader_type spatial;

render_mode blend_mix, depth_draw_opaque, cull_disabled,
	diffuse_burley, specular_schlick_ggx;


// Original material

uniform vec4 albedo : source_color = vec4(1.0);

uniform sampler2D texture_albedo :
	source_color, filter_linear_mipmap, repeat_enable;

uniform ivec2 albedo_texture_size;

uniform float point_size :
	hint_range(0.1, 128.0, 0.1) = 1.0;

uniform float roughness :
	hint_range(0.0, 1.0) = 0.8;

uniform sampler2D texture_metallic :
	hint_default_white, filter_linear_mipmap, repeat_enable;

uniform vec4 metallic_texture_channel =
	vec4(1.0, 0.0, 0.0, 0.0);

uniform sampler2D texture_roughness :
	hint_roughness_r, filter_linear_mipmap, repeat_enable;

uniform float specular :
	hint_range(0.0, 1.0, 0.01) = 0.5;

uniform float metallic :
	hint_range(0.0, 1.0, 0.01) = 0.0;

uniform vec3 uv1_scale = vec3(1.0);
uniform vec3 uv1_offset = vec3(0.0);

uniform vec3 uv2_scale = vec3(1.0);
uniform vec3 uv2_offset = vec3(0.0);


// Magical cracks

uniform vec4 crack_color : source_color =
	vec4(0.58, 0.08, 1.0, 1.0);

uniform vec4 crack_highlight_color : source_color =
	vec4(1.0, 0.55, 1.0, 1.0);

uniform float crack_scale :
	hint_range(1.0, 100.0) = 14.0;

uniform float crack_width :
	hint_range(0.001, 0.2) = 0.035;

uniform float crack_softness :
	hint_range(0.001, 0.1) = 0.012;

uniform float crack_amount :
	hint_range(0.0, 1.0) = 0.7;

uniform float crack_brightness :
	hint_range(0.0, 20.0) = 4.0;

uniform float crack_animation_speed :
	hint_range(0.0, 10.0) = 1.5;

uniform float pulse_strength :
	hint_range(0.0, 3.0) = 0.6;

uniform float surface_glow :
	hint_range(0.0, 1.0) = 0.15;


// Random functions

vec2 random_vec2(vec2 position) {
	position = vec2(
		dot(position, vec2(127.1, 311.7)),
		dot(position, vec2(269.5, 183.3))
	);

	return fract(
		sin(position) * 43758.5453
	);
}


float random_float(vec2 position) {
	return fract(
		sin(dot(position, vec2(41.37, 289.91)))
		* 43758.5453
	);
}


// Returns the distance between the nearest and second-nearest
// Voronoi cells. Small values occur along cell boundaries.

float voronoi_edge(vec2 position) {
	vec2 base_cell = floor(position);
	vec2 local_position = fract(position);

	float nearest_distance = 10.0;
	float second_nearest_distance = 10.0;

	for (int y = -1; y <= 1; y++) {
		for (int x = -1; x <= 1; x++) {
			vec2 neighbouring_cell =
				vec2(float(x), float(y));

			vec2 point =
				random_vec2(
					base_cell + neighbouring_cell
				);

			// Slightly reposition points to make the cracks
			// less geometrically perfect.
			point = 0.2 + point * 0.6;

			vec2 difference =
				neighbouring_cell
				+ point
				- local_position;

			float distance_to_point =
				length(difference);

			if (distance_to_point < nearest_distance) {
				second_nearest_distance =
					nearest_distance;

				nearest_distance =
					distance_to_point;
			} else if (
				distance_to_point
				< second_nearest_distance
			) {
				second_nearest_distance =
					distance_to_point;
			}
		}
	}

	return second_nearest_distance
		- nearest_distance;
}


float value_noise(vec2 position) {
	vec2 cell = floor(position);
	vec2 fraction = fract(position);

	fraction =
		fraction * fraction
		* (3.0 - 2.0 * fraction);

	float bottom_left =
		random_float(cell);

	float bottom_right =
		random_float(cell + vec2(1.0, 0.0));

	float top_left =
		random_float(cell + vec2(0.0, 1.0));

	float top_right =
		random_float(cell + vec2(1.0, 1.0));

	return mix(
		mix(
			bottom_left,
			bottom_right,
			fraction.x
		),
		mix(
			top_left,
			top_right,
			fraction.x
		),
		fraction.y
	);
}


float fbm(vec2 position) {
	float result = 0.0;
	float amplitude = 0.5;

	for (int index = 0; index < 4; index++) {
		result += value_noise(position) * amplitude;

		position =
			position * 2.03
			+ vec2(13.7, 8.9);

		amplitude *= 0.5;
	}

	return result;
}


void vertex() {
	UV =
		UV * uv1_scale.xy
		+ uv1_offset.xy;
}


void fragment() {
	vec2 base_uv = UV;


	// Original material

	vec4 albedo_tex =
		texture(texture_albedo, base_uv);

	vec3 base_color =
		albedo.rgb * albedo_tex.rgb;

	float metallic_tex = dot(
		texture(texture_metallic, base_uv),
		metallic_texture_channel
	);

	METALLIC = metallic_tex * metallic;
	SPECULAR = specular;

	vec4 roughness_texture_channel =
		vec4(1.0, 0.0, 0.0, 0.0);

	float roughness_tex = dot(
		texture(texture_roughness, base_uv),
		roughness_texture_channel
	);

	ROUGHNESS = roughness_tex * roughness;


	// Distort the coordinates before creating the cracks.

	float distortion = fbm(
		base_uv * crack_scale * 0.35
	);

	vec2 crack_uv =
		base_uv * crack_scale;

	crack_uv += vec2(
		distortion,
		fbm(
			base_uv * crack_scale * 0.35
			+ vec2(7.2, 3.8)
		)
	) * 1.5;


	// Primary crack network

	float edge_distance =
		voronoi_edge(crack_uv);

	float cracks =
		1.0 - smoothstep(
			crack_width,
			crack_width + crack_softness,
			edge_distance
		);


	


	// Remove random sections so the cracks are broken and natural.

	float crack_breakup = fbm(
		base_uv * crack_scale * 0.8
		+ vec2(31.7, 12.4)
	);

	float visibility = smoothstep(
		1.0 - crack_amount,
		1.0,
		crack_breakup
	);

	cracks *= visibility;


	// Animated magical energy travelling through the cracks.

	float travelling_energy = sin(
		base_uv.y * 35.0
		- TIME * crack_animation_speed * 5.0
		+ distortion * 10.0
	);

	travelling_energy =
		travelling_energy * 0.5 + 0.5;

	float global_pulse = sin(
		TIME * crack_animation_speed
	) * 0.5 + 0.5;

	float energy =
		1.0
		+ travelling_energy * pulse_strength
		+ global_pulse * pulse_strength * 0.5;


	// Bright centre with a softer surrounding purple colour.

	float crack_core =
		pow(cracks, 3.0);

	vec3 magical_color = mix(
		crack_color.rgb,
		crack_highlight_color.rgb,
		crack_core
	);


	// Slightly tint the surface immediately around the cracks.

	vec3 surface_color = mix(
		base_color,
		crack_color.rgb,
		cracks * surface_glow
	);

	ALBEDO = surface_color;

	EMISSION =
		magical_color
		* cracks
		* crack_brightness
		* energy;
}