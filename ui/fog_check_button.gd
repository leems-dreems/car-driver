extends CheckButton


func _ready() -> void:
	await get_tree().create_timer(1.0).timeout
	button_pressed = Game.current_environment.environment.volumetric_fog_enabled
	toggled.connect(func(toggled_on: bool):
		Game.current_environment.environment.volumetric_fog_enabled = toggled_on
	)
	return
