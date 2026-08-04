shader_type sky;

uniform vec3 zenith_color : source_color =
	vec3(0.012, 0.002, 0.055);

uniform vec3 upper_color : source_color =
	vec3(0.085, 0.012, 0.22);

uniform vec3 horizon_color : source_color =
	vec3(0.42, 0.055, 0.65);

uniform vec3 lower_color : source_color =
	vec3(0.035, 0.003, 0.09);

uniform vec3 nebula_color : source_color =
	vec3(0.55, 0.06, 1.0);

uniform vec3 nebula_highlight : source_color =
	vec3(1.0, 0.32, 0.95);

uniform vec3 aurora_color : source_color =
	vec3(0.4, 0.15, 1.0);

uniform vec3 star_color : source_color =
	vec3(0.95, 0.72, 1.0);

uniform vec3 moon_color : source_color =
	vec3(0.88, 0.62, 1.0);

uniform float animation_speed :
	hint_range(0.0, 2.0) = 0.08;

uniform float nebula_strength :
	hint_range(0.0, 3.0) = 0.85;

uniform float aurora_strength :
	hint_range(0.0, 3.0) = 0.5;

uniform float star_strength :
	hint_range(0.0, 5.0) = 1.4;

uniform float star_density :
	hint_range(0.8, 0.999) = 0.975;

uniform float moon_size :
	hint_range(0.001, 0.2) = 0.045;

uniform float moon_glow_size :
	hint_range(0.01, 0.4) = 0.14;

uniform float brightness :
	hint_range(0.0, 3.0) = 1.0;


float hash_3d(vec3 position) {
	position = fract(
		position * 0.1031
	);

	position += dot(
		position,
		position.yzx + 33.33
	);

	return fract(
		(position.x + position.y)
		* position.z
	);
}


float noise_3d(vec3 position) {
	vec3 cell = floor(position);
	vec3 fraction = fract(position);

	fraction =
		fraction
		* fraction
		* (3.0 - 2.0 * fraction);

	float n000 = hash_3d(
		cell + vec3(0.0, 0.0, 0.0)
	);

	float n100 = hash_3d(
		cell + vec3(1.0, 0.0, 0.0)
	);

	float n010 = hash_3d(
		cell + vec3(0.0, 1.0, 0.0)
	);

	float n110 = hash_3d(
		cell + vec3(1.0, 1.0, 0.0)
	);

	float n001 = hash_3d(
		cell + vec3(0.0, 0.0, 1.0)
	);

	float n101 = hash_3d(
		cell + vec3(1.0, 0.0, 1.0)
	);

	float n011 = hash_3d(
		cell + vec3(0.0, 1.0, 1.0)
	);

	float n111 = hash_3d(
		cell + vec3(1.0, 1.0, 1.0)
	);

	float bottom = mix(
		mix(
			n000,
			n100,
			fraction.x
		),
		mix(
			n010,
			n110,
			fraction.x
		),
		fraction.y
	);

	float top = mix(
		mix(
			n001,
			n101,
			fraction.x
		),
		mix(
			n011,
			n111,
			fraction.x
		),
		fraction.y
	);

	return mix(
		bottom,
		top,
		fraction.z
	);
}


float fbm(vec3 position) {
	float value = 0.0;
	float amplitude = 0.5;

	for (int index = 0; index < 5; index++) {
		value +=
			noise_3d(position)
			* amplitude;

		position =
			position * 2.03
			+ vec3(7.3, 11.7, 5.2);

		amplitude *= 0.5;
	}

	return value;
}


vec2 rotate_2d(
	vec2 position,
	float angle
) {
	float angle_cosine = cos(angle);
	float angle_sine = sin(angle);

	return vec2(
		position.x * angle_cosine
			- position.y * angle_sine,
		position.x * angle_sine
			+ position.y * angle_cosine
	);
}


void sky() {
	vec3 direction = normalize(EYEDIR);

	float time =
		TIME * animation_speed;

	float height = direction.y;

	float upper_height = clamp(
		height,
		0.0,
		1.0
	);

	float lower_height = clamp(
		-height,
		0.0,
		1.0
	);

	float horizon = pow(
		1.0 - abs(height),
		5.0
	);


	vec3 color = mix(
		upper_color,
		zenith_color,
		pow(
			upper_height,
			0.65
		)
	);

	color = mix(
		color,
		lower_color,
		pow(
			lower_height,
			0.7
		)
	);

	color = mix(
		color,
		horizon_color,
		horizon * 0.72
	);


	vec3 moving_direction = direction;

	vec2 rotated_direction = rotate_2d(
		moving_direction.xz,
		time
	);

	moving_direction.x = rotated_direction.x;
	moving_direction.z = rotated_direction.y;


	float large_nebula = fbm(
		moving_direction * 2.7
		+ vec3(
			time * 0.4,
			-time * 0.25,
			time * 0.3
		)
	);

	float fine_nebula = fbm(
		moving_direction * 7.5
		- vec3(
			time * 0.7,
			time * 0.15,
			time * 0.45
		)
	);

	float nebula =
		large_nebula * 0.7
		+ fine_nebula * 0.4;

	nebula = smoothstep(
		0.48,
		0.86,
		nebula
	);

	float sky_angle = atan(
		direction.z,
		direction.x
	);

	float nebula_curve =
		direction.y
		+ sin(
			sky_angle * 1.5
			+ time
		) * 0.17;

	float nebula_band = pow(
		clamp(
			1.0 - abs(nebula_curve),
			0.0,
			1.0
		),
		3.0
	);

	nebula *= nebula_band;

	vec3 current_nebula_color = mix(
		nebula_color,
		nebula_highlight,
		fine_nebula * nebula
	);

	color +=
		current_nebula_color
		* nebula
		* nebula_strength;


	float aurora_noise = fbm(
		direction * 8.0
		+ vec3(
			time * 1.2,
			0.0,
			-time * 0.8
		)
	);

	float aurora_wave = sin(
		sky_angle * 5.0
		+ direction.y * 11.0
		- time * 4.0
		+ aurora_noise * 4.0
	);

	aurora_wave = smoothstep(
		0.42,
		1.0,
		aurora_wave
	);

	float aurora_region = smoothstep(
		-0.05,
		0.35,
		direction.y
	);

	aurora_region *=
		1.0 - smoothstep(
			0.35,
			0.82,
			direction.y
		);

	float aurora =
		aurora_wave
		* aurora_region
		* aurora_noise;

	color +=
		aurora_color
		* aurora
		* aurora_strength;


	vec3 star_cell = floor(
		direction * 620.0
	);

	float star_random = hash_3d(
		star_cell
	);

	float stars = smoothstep(
		star_density,
		1.0,
		star_random
	);

	float star_shape = noise_3d(
		direction * 1250.0
	);

	stars *= smoothstep(
		0.46,
		0.76,
		star_shape
	);

	float twinkle =
		0.72
		+ 0.28
		* sin(
			TIME * 1.8
			+ star_random * 35.0
		);

	stars *= twinkle;

	stars *= mix(
		0.4,
		1.0,
		upper_height
	);

	color +=
		star_color
		* stars
		* star_strength;


	vec3 moon_direction = normalize(
		vec3(
			0.3,
			0.743,
			-0.548
		)
	);

	float moon_distance =
		1.0
		- dot(
			direction,
			moon_direction
		);

	float moon =
		1.0 - smoothstep(
			moon_size * 0.72,
			moon_size,
			moon_distance
		);

	float moon_texture = fbm(
		direction * 85.0
	);

	vec3 moon_surface = mix(
		moon_color * 0.62,
		moon_color,
		moon_texture
	);

	float moon_glow =
		1.0 - smoothstep(
			moon_size,
			moon_glow_size,
			moon_distance
		);

	moon_glow = pow(
		moon_glow,
		2.0
	);

	color +=
		moon_color
		* moon_glow
		* 1.25;

	color = mix(
		color,
		moon_surface * 2.0,
		moon
	);


	float horizon_sparkle = noise_3d(
		direction * 90.0
		+ vec3(
			0.0,
			time,
			0.0
		)
	);

	horizon_sparkle = smoothstep(
		0.72,
		0.95,
		horizon_sparkle
	);

	color +=
		nebula_highlight
		* horizon_sparkle
		* horizon
		* 0.18;


	COLOR = color * brightness;
}