shader_type spatial;

render_mode cull_disabled;


// Colours

uniform vec4 bottom_color : source_color =
	vec4(0.15, 0.35, 0.12, 1.0);

uniform vec4 top_color : source_color =
	vec4(0.55, 0.85, 0.35, 1.0);

uniform float gradient_bottom = -0.15;
uniform float gradient_top = 2.5;


// Player interaction
// This position must be supplied in the grass mesh's local space.

uniform vec3 player_position = vec3(0.0);
uniform float interaction_radius : hint_range(0.1, 5.0) = 1.5;
uniform float interaction_strength : hint_range(0.0, 2.0) = 0.7;


// Wind

uniform float wind_strength : hint_range(0.0, 1.0) = 0.08;
uniform float wind_speed : hint_range(0.0, 10.0) = 2.0;
uniform float wind_scale : hint_range(0.0, 5.0) = 0.8;


varying float height;


void vertex() {
	height = VERTEX.y;

	// 0 at the grass base and 1 at the tip.
	float height_mask = smoothstep(
		gradient_bottom,
		gradient_top,
		VERTEX.y
	);

	// Makes the base more resistant to movement.
	height_mask *= height_mask;

	vec2 player_difference =
		VERTEX.xz - player_position.xz;

	float distance_to_player =
		length(player_difference);

	vec2 push_direction = vec2(0.0);

	if (distance_to_player > 0.001) {
		push_direction =
			player_difference / distance_to_player;
	}

	float interaction_amount = smoothstep(
		interaction_radius,
		0.0,
		distance_to_player
	);

	interaction_amount = pow(interaction_amount, 0.5);

	vec2 interaction_offset =
		push_direction
		* interaction_amount
		* interaction_strength
		* height_mask;

	vec3 world_position = (
		MODEL_MATRIX * vec4(VERTEX, 1.0)
	).xyz;

	float wind_wave = sin(
		TIME * wind_speed
		+ world_position.x * wind_scale
		+ world_position.z * wind_scale * 0.7
	);

	vec2 wind_offset =
		vec2(wind_wave, wind_wave * 0.4)
		* wind_strength
		* height_mask;

	VERTEX.xz += interaction_offset + wind_offset;
}


void fragment() {
	float gradient = smoothstep(
		gradient_bottom,
		gradient_top,
		height
	);

	ALBEDO = mix(
		bottom_color.rgb,
		top_color.rgb,
		gradient
	);

	ROUGHNESS = 0.9;
}