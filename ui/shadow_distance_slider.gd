extends HSlider

const shadow_distances := [
	50,
	100,
	200,
	350,
	500
]

func _ready() -> void:
	drag_started.connect(func(): $ClickAudio.play())
	drag_ended.connect(func(_new_value: float):
		$ClickAudio.play()
		var i := roundi(value)
		Game.current_sun.directional_shadow_max_distance = shadow_distances[i]
	)
	value_changed.connect(func(_new_value: float): $StepAudio.play())

	return
