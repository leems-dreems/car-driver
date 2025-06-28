extends CheckButton


func _ready() -> void:
	await get_tree().create_timer(1.0).timeout
	if Game.current_environment == null:
		disabled = true
		return
	button_pressed = Game.current_environment.environment.ssao_enabled
	toggled.connect(func(toggled_on: bool):
		Game.current_environment.environment.ssao_enabled = toggled_on
	)
	return
