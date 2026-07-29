shader_type spatial;

uniform vec4 bottom_color : source_color = vec4(0.15, 0.35, 0.12, 1.0);
uniform vec4 top_color : source_color = vec4(0.55, 0.85, 0.35, 1.0);

uniform float gradient_bottom = -1.0;
uniform float gradient_top = 1.0;

varying float height;

void vertex() {
	height = VERTEX.y;
}

void fragment() {
	float gradient = smoothstep(
		gradient_bottom,
		gradient_top,
		height
	);

	ALBEDO = mix(bottom_color.rgb, top_color.rgb, gradient);
}