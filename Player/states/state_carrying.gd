extends PlayerState

var _item_mass := 1.0


func handle_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		player.handle_interact_button_pressed()
	elif event.is_action_released("interact"):
		player.handle_interact_button_released()
	elif event.is_action_pressed("pickup_drop"):
		player.handle_drop_button_pressed()
	return


func physics_update(_delta: float) -> void:
	player.process_on_foot_controls(_delta, true, 0.25 + (1 / maxf(1.0, _item_mass)) * 0.75)
	if player.is_on_ground() and Input.is_action_pressed("aim"):
		finished.emit(AIMING_THROW)
		return

	if not Input.is_action_pressed("interact") and player.interact_short_press_timer.is_stopped() and player.interact_long_press_timer.is_stopped():
		player.update_interact_target()
	#if not Input.is_action_pressed("pickup_drop"):
	player.update_drop_target()
	return


func enter(_previous_state_path: String, _data := {}) -> void:
	_item_mass = player._carried_item.mass
	player.set_throw_arc_visible(false)
	player.camera_controller.set_pivot(CameraController.CAMERA_PIVOT.THIRD_PERSON)
	player.update_interact_target(true)
	player.update_drop_target(true)
	return
