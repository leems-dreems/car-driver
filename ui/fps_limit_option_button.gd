extends SettingOptionButton

const option_values: Array[int] = [
	0, 30, 60, 120, 180, 240
]


func _ready() -> void:
	super()
	# Get the nearest menu option to the current value of max_fps
	var max_fps: int = Engine.max_fps
	var nearest_value: int = 1000
	var nearest_index: int = 0
	var i: int = 0
	for _value in option_values:
		var _diff := absi(max_fps - _value)
		if _diff < nearest_value:
			nearest_value = _diff
			nearest_index = i
		i += 1

	select(nearest_index)
	apply_value(nearest_index)
	return


func apply_value(_index: int) -> void:
	Engine.max_fps = option_values[_index]
	return
