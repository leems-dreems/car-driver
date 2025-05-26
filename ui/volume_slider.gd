extends HSlider

@export var bus_name := "Master"
var bus_index: int

func _ready() -> void:
	bus_index = AudioServer.get_bus_index(bus_name)
	assert(bus_index > -1, "Bus name not found: " + bus_name)

	$ClickAudio.bus = bus_name
	$StepAudio.bus = bus_name

	drag_started.connect(func(): $ClickAudio.play())
	drag_ended.connect(func(_new_value: float): $ClickAudio.play())
	value_changed.connect(func(_new_value: float):
		$StepAudio.play()
		AudioServer.set_bus_volume_linear(bus_index, _new_value)
	)

	return
