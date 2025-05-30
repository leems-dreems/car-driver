extends SettingSlider

@export var bus_name := "Master"
var bus_index: int


func _ready() -> void:
	super()
	bus_index = AudioServer.get_bus_index(bus_name)
	assert(bus_index > -1, "Bus name not found: " + bus_name)
	$ClickAudio.bus = bus_name
	$StepAudio.bus = bus_name
	return


func apply_value() -> void:
	AudioServer.set_bus_volume_linear(bus_index, value)
	return
