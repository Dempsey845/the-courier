extends Node


enum GraphicsMode {
	VERY_LOW,
	LOW,
	MEDIUM,
	HIGH,
	ULTRA
}


@export_category("Graphics Preset")
@export var graphics_mode: GraphicsMode = GraphicsMode.MEDIUM

@export_category("Behaviour")
## Apply the selected preset automatically when this node starts.
@export var apply_on_ready: bool = true

## Prints the applied preset to the output.
@export var debug_logging: bool = true


func _ready() -> void:
	if apply_on_ready:
		apply_graphics_mode(graphics_mode)


func apply_graphics_mode(mode: GraphicsMode) -> void:
	graphics_mode = mode

	match mode:
		GraphicsMode.VERY_LOW:
			_apply_very_low()
		GraphicsMode.LOW:
			_apply_low()
		GraphicsMode.MEDIUM:
			_apply_medium()
		GraphicsMode.HIGH:
			_apply_high()
		GraphicsMode.ULTRA:
			_apply_ultra()

	if debug_logging:
		print("Graphics preset applied: ", GraphicsMode.keys()[mode])


# VERY LOW
# Intended for weak laptops / integrated graphics.

func _apply_very_low() -> void:
	# Resolution / scaling
	_set_3d_scale(0.50)

	# Anti-aliasing
	_set_msaa(Viewport.MSAA_DISABLED)
	_set_screen_space_aa(Viewport.SCREEN_SPACE_AA_DISABLED)
	_set_taa(false)

	# Texture filtering
	_set_texture_filter(
		Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_LINEAR
	)
	_set_anisotropic_filtering(1)

	# Mesh LOD
	_set_mesh_lod_threshold(4.0)

	# Shadows
	_set_directional_shadow_size(1024)
	_set_positional_shadow_size(512)
	_set_shadow_filter(
		RenderingServer.SHADOW_QUALITY_HARD
	)

	# Expensive rendering
	_set_sdfgi(false)
	_set_ssao(false)
	_set_ssil(false)
	_set_ssr(false)
	_set_volumetric_fog(false)
	_set_glow(false)

	# Project settings
	_set_project_setting(
		"rendering/lights_and_shadows/directional_shadow/size",
		1024
	)

	_set_project_setting(
		"rendering/lights_and_shadows/positional_shadow/atlas_size",
		512
	)

	_set_project_setting(
		"rendering/lights_and_shadows/directional_shadow/soft_shadow_filter_quality",
		0
	)

	_set_project_setting(
		"rendering/lights_and_shadows/positional_shadow/soft_shadow_filter_quality",
		0
	)


# LOW
# Large performance improvement while retaining core visuals.

func _apply_low() -> void:
	_set_3d_scale(0.67)

	_set_msaa(Viewport.MSAA_DISABLED)
	_set_screen_space_aa(Viewport.SCREEN_SPACE_AA_FXAA)
	_set_taa(false)

	_set_anisotropic_filtering(2)
	_set_mesh_lod_threshold(2.5)

	_set_directional_shadow_size(1024)
	_set_positional_shadow_size(1024)
	_set_shadow_filter(
		RenderingServer.SHADOW_QUALITY_HARD
	)

	_set_sdfgi(false)
	_set_ssao(false)
	_set_ssil(false)
	_set_ssr(false)
	_set_volumetric_fog(false)

	# Glow is relatively affordable compared with GI/SSR,
	# so keep it for your stylised look.
	_set_glow(true)

	_set_project_setting(
		"rendering/lights_and_shadows/directional_shadow/size",
		1024
	)

	_set_project_setting(
		"rendering/lights_and_shadows/positional_shadow/atlas_size",
		1024
	)

	_set_project_setting(
		"rendering/lights_and_shadows/directional_shadow/soft_shadow_filter_quality",
		0
	)

	_set_project_setting(
		"rendering/lights_and_shadows/positional_shadow/soft_shadow_filter_quality",
		0
	)


# MEDIUM
# Good default for average hardware.

func _apply_medium() -> void:
	_set_3d_scale(0.85)

	_set_msaa(Viewport.MSAA_2X)
	_set_screen_space_aa(Viewport.SCREEN_SPACE_AA_FXAA)
	_set_taa(false)

	_set_anisotropic_filtering(4)
	_set_mesh_lod_threshold(1.5)

	_set_directional_shadow_size(2048)
	_set_positional_shadow_size(2048)
	_set_shadow_filter(
		RenderingServer.SHADOW_QUALITY_SOFT_LOW
	)

	_set_sdfgi(false)
	_set_ssao(true)
	_set_ssil(false)
	_set_ssr(false)
	_set_volumetric_fog(false)
	_set_glow(true)

	_set_project_setting(
		"rendering/lights_and_shadows/directional_shadow/size",
		2048
	)

	_set_project_setting(
		"rendering/lights_and_shadows/positional_shadow/atlas_size",
		2048
	)

	_set_project_setting(
		"rendering/lights_and_shadows/directional_shadow/soft_shadow_filter_quality",
		1
	)

	_set_project_setting(
		"rendering/lights_and_shadows/positional_shadow/soft_shadow_filter_quality",
		1
	)


# HIGH
# Intended presentation quality.

func _apply_high() -> void:
	_set_3d_scale(1.0)

	_set_msaa(Viewport.MSAA_4X)
	_set_screen_space_aa(Viewport.SCREEN_SPACE_AA_DISABLED)
	_set_taa(true)

	_set_anisotropic_filtering(8)
	_set_mesh_lod_threshold(1.0)

	_set_directional_shadow_size(4096)
	_set_positional_shadow_size(4096)
	_set_shadow_filter(
		RenderingServer.SHADOW_QUALITY_SOFT_MEDIUM
	)

	_set_sdfgi(true)
	_set_ssao(true)
	_set_ssil(true)
	_set_ssr(true)
	_set_volumetric_fog(true)
	_set_glow(true)

	_set_project_setting(
		"rendering/lights_and_shadows/directional_shadow/size",
		4096
	)

	_set_project_setting(
		"rendering/lights_and_shadows/positional_shadow/atlas_size",
		4096
	)

	_set_project_setting(
		"rendering/lights_and_shadows/directional_shadow/soft_shadow_filter_quality",
		2
	)

	_set_project_setting(
		"rendering/lights_and_shadows/positional_shadow/soft_shadow_filter_quality",
		2
	)


# ULTRA
# Expensive. Primarily for strong desktop GPUs/screenshots.

func _apply_ultra() -> void:
	_set_3d_scale(1.0)

	_set_msaa(Viewport.MSAA_8X)
	_set_screen_space_aa(Viewport.SCREEN_SPACE_AA_DISABLED)
	_set_taa(true)

	_set_anisotropic_filtering(16)
	_set_mesh_lod_threshold(0.5)

	_set_directional_shadow_size(8192)
	_set_positional_shadow_size(8192)
	_set_shadow_filter(
		RenderingServer.SHADOW_QUALITY_SOFT_ULTRA
	)

	_set_sdfgi(true)
	_set_ssao(true)
	_set_ssil(true)
	_set_ssr(true)
	_set_volumetric_fog(true)
	_set_glow(true)

	_set_project_setting(
		"rendering/lights_and_shadows/directional_shadow/size",
		8192
	)

	_set_project_setting(
		"rendering/lights_and_shadows/positional_shadow/atlas_size",
		8192
	)

	_set_project_setting(
		"rendering/lights_and_shadows/directional_shadow/soft_shadow_filter_quality",
		3
	)

	_set_project_setting(
		"rendering/lights_and_shadows/positional_shadow/soft_shadow_filter_quality",
		3
	)


# RENDERING FUNCTIONS

func _set_3d_scale(value: float) -> void:
	get_viewport().scaling_3d_scale = value


func _set_msaa(value: Viewport.MSAA) -> void:
	get_viewport().msaa_3d = value


func _set_screen_space_aa(value: Viewport.ScreenSpaceAA) -> void:
	get_viewport().screen_space_aa = value


func _set_taa(enabled: bool) -> void:
	get_viewport().use_taa = enabled


func _set_mesh_lod_threshold(value: float) -> void:
	get_viewport().mesh_lod_threshold = value


func _set_texture_filter(
	filter: Viewport.DefaultCanvasItemTextureFilter
) -> void:
	get_viewport().canvas_item_default_texture_filter = filter


func _set_anisotropic_filtering(level: int) -> void:
	# Changes the global anisotropic filtering level.
	var value := 0

	match level:
		1:
			value = 0
		2:
			value = 1
		4:
			value = 2
		8:
			value = 3
		16:
			value = 4

	_set_project_setting(
		"rendering/textures/default_filters/use_nearest_mipmap_filter",
		level <= 1
	)

	_set_project_setting(
		"rendering/textures/default_filters/anisotropic_filtering_level",
		value
	)


# SHADOWS

func _set_directional_shadow_size(size: int) -> void:
	RenderingServer.directional_shadow_atlas_set_size(size, true)


func _set_positional_shadow_size(size: int) -> void:
	get_viewport().positional_shadow_atlas_size = size


func _set_shadow_filter(quality: RenderingServer.ShadowQuality) -> void:
	RenderingServer.directional_soft_shadow_filter_set_quality(quality)
	RenderingServer.positional_soft_shadow_filter_set_quality(quality)


# WORLD ENVIRONMENT

func _get_environment() -> Environment:
	var world := get_viewport().world_3d

	if world == null:
		return null

	return world.environment


func _set_sdfgi(enabled: bool) -> void:
	var env := _get_environment()

	if env:
		env.sdfgi_enabled = enabled


func _set_ssao(enabled: bool) -> void:
	var env := _get_environment()

	if env:
		env.ssao_enabled = enabled


func _set_ssil(enabled: bool) -> void:
	var env := _get_environment()

	if env:
		env.ssil_enabled = enabled


func _set_ssr(enabled: bool) -> void:
	var env := _get_environment()

	if env:
		env.ssr_enabled = enabled


func _set_volumetric_fog(enabled: bool) -> void:
	var env := _get_environment()

	if env:
		env.volumetric_fog_enabled = enabled


func _set_glow(enabled: bool) -> void:
	var env := _get_environment()

	if env:
		env.glow_enabled = enabled


# PROJECT SETTINGS

func _set_project_setting(path: String, value: Variant) -> void:
	if ProjectSettings.has_setting(path):
		ProjectSettings.set_setting(path, value)


# PUBLIC API
# Useful for your settings menu.

func set_graphics_mode(mode: GraphicsMode) -> void:
	apply_graphics_mode(mode)


func get_graphics_mode() -> GraphicsMode:
	return graphics_mode


func get_graphics_mode_name() -> String:
	return GraphicsMode.keys()[graphics_mode]


func get_available_modes() -> Array[String]:
	return [
		"Very Low",
		"Low",
		"Medium",
		"High",
		"Ultra"
	]