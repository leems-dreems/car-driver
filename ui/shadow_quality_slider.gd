extends SettingSlider

const shadow_sizes := [
	1024,
	2048,
	4096,
	8192
]
const shadow_filter_qualities := [
	RenderingServer.ShadowQuality.SHADOW_QUALITY_HARD,
	RenderingServer.ShadowQuality.SHADOW_QUALITY_SOFT_LOW,
	RenderingServer.ShadowQuality.SHADOW_QUALITY_SOFT_HIGH,
	RenderingServer.ShadowQuality.SHADOW_QUALITY_SOFT_ULTRA
]
const shadow_modes := [
	DirectionalLight3D.SHADOW_ORTHOGONAL,
	DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS,
	DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS,
	DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
]


func apply_value() -> void:
	var i := roundi(value)
	RenderingServer.directional_soft_shadow_filter_set_quality(shadow_filter_qualities[i])
	RenderingServer.positional_soft_shadow_filter_set_quality(shadow_filter_qualities[i])
	RenderingServer.directional_shadow_atlas_set_size(shadow_sizes[i], true)
	RenderingServer.viewport_set_positional_shadow_atlas_size(get_viewport().get_viewport_rid(), shadow_sizes[i], true)
	Game.current_sun.directional_shadow_mode = shadow_modes[i]
	return
