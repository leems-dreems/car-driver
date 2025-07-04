extends PlayerState

var _item_mass := 1.0


func handle_input(event: InputEvent) -> void:
	if event.is_action_pressed("Pause") and not event.is_echo():
		player.handle_pause_button_pressed()
		return
	if event.is_action_pressed("jump") and not event.is_echo():
		player.should_jump = true
	if event.is_action_pressed("push_vehicle") and not event.is_echo():
		player.handle_push_vehicle_button_pressed()
	if event.is_action_pressed("interact") and not event.is_echo():
		player.handle_interact_button_pressed()
	elif event.is_action_released("interact"):
		player.handle_interact_button_released()
	elif event.is_action_pressed("pickup_drop") and not event.is_echo():
		player.handle_drop_button_pressed()
	return


func physics_update(_delta: float) -> void:
	player.process_on_foot_controls(_delta, true, 0.25 + (1 / maxf(1.0, _item_mass)) * 0.75)
	if Input.is_action_pressed("aim"):
		finished.emit(AIMING_THROW)
		return

	if not Input.is_action_pressed("interact") and player.interact_short_press_timer.is_stopped() and player.interact_long_press_timer.is_stopped():
		player.update_interact_target()
	player.update_drop_target()
	player.update_push_target()
	return


func enter(_previous_state_path: String, _data := {}) -> void:
	player.should_jump = false
	_item_mass = player._carried_item.mass
	player.camera_controller.set_pivot(CameraController.CAMERA_PIVOT.THIRD_PERSON)
	player.update_interact_target(true)
	player.update_drop_target(true)
	return


func exit() -> void:
	player.should_jump = false
	return
