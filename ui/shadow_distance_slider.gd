extends SettingSlider

const shadow_distances := [
	50,
	100,
	200,
	350,
	500
]


func apply_value() -> void:
	var i := roundi(value)
	Game.current_sun.directional_shadow_max_distance = shadow_distances[i]
	return
