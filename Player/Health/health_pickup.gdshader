shader_type spatial;
render_mode unshaded;

uniform vec3 gold_color : source_color = vec3(1.0, 0.68, 0.015);
uniform vec3 bright_color : source_color = vec3(1.0, 0.9, 0.12);
uniform vec3 orange_color : source_color = vec3(0.95, 0.38, 0.005);
uniform vec3 rim_color : source_color = vec3(1.0, 0.87, 0.25);
uniform vec3 outline_color : source_color = vec3(0.22, 0.095, 0.005);
uniform vec3 highlight_color : source_color = vec3(1.0, 0.97, 0.65);

uniform float rim_start : hint_range(0.0, 1.0) = 0.62;
uniform float outline_start : hint_range(0.0, 1.0) = 0.91;
uniform float highlight_strength : hint_range(0.0, 1.0) = 0.9;
uniform float shading_steps : hint_range(2.0, 12.0, 1.0) = 5.0;

// Directions are relative to the camera.
uniform vec3 main_highlight_direction = vec3(-0.45, 0.55, 0.7);
uniform vec3 small_highlight_direction = vec3(0.65, 0.15, 0.75);

void fragment() {
	vec3 normal = normalize(NORMAL);
	vec3 view_direction = normalize(VIEW);

	// Camera-relative lighting keeps the pickup readable.
	vec3 light_direction = normalize(vec3(-0.35, 0.7, 0.65));
	float lighting = clamp(
		dot(normal, light_direction) * 0.5 + 0.5,
		0.0,
		1.0
	);

	float stepped_light = floor(lighting * shading_steps)
		/ shading_steps;

	vec3 color = mix(
		orange_color,
		gold_color,
		smoothstep(0.15, 0.65, stepped_light)
	);

	color = mix(
		color,
		bright_color,
		smoothstep(0.55, 1.0, stepped_light)
	);

	// Pale inner border followed by a dark outer edge.
	float edge = 1.0 - clamp(
		dot(normal, view_direction),
		0.0,
		1.0
	);

	float rim = smoothstep(rim_start, rim_start + 0.08, edge);
	color = mix(color, rim_color, rim);

	float outline = smoothstep(outline_start, 1.0, edge);
	color = mix(color, outline_color, outline);

	// Two stylized patches of reflected light.
	float main_dot = dot(
		normal,
		normalize(main_highlight_direction)
	);
	float main_highlight = smoothstep(0.91, 0.96, main_dot);

	float small_dot = dot(
		normal,
		normalize(small_highlight_direction)
	);
	float small_highlight = smoothstep(0.984, 0.996, small_dot);

	float highlight = max(main_highlight, small_highlight);
	highlight *= highlight_strength * (1.0 - rim);

	ALBEDO = mix(color, highlight_color, highlight);
}