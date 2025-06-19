extends PlayerState

## Timer used to delay switching back to the empty-handed state after a throw
var _hold_timer: SceneTreeTimer = null
var _item_mass := 1.0


func handle_input(event: InputEvent) -> void:
	if event.is_action_pressed("Pause") and not event.is_echo():
		player.handle_pause_button_pressed()
		return
	if event.is_action_pressed("jump") and not event.is_echo():
		player.should_jump = true
	if event.is_action_pressed("interact") and not event.is_echo():
		player.handle_interact_button_pressed()
	elif event.is_action_released("interact"):
		player.handle_interact_button_released()
	elif event.is_action_pressed("pickup_drop") and not event.is_echo():
		player.handle_drop_button_pressed()
	elif event.is_action_pressed("throw") and _hold_timer == null:
		player._last_strong_direction = player.camera_controller.global_transform.basis.z
		player.throw_item()
		finished.emit(EMPTY_HANDED)
	elif event.is_action_released("aim"):
		player._last_strong_direction = player.camera_controller.global_transform.basis.z
		if player._carried_item != null:
			finished.emit(CARRYING)
		else:
			finished.emit(EMPTY_HANDED)
	return


func physics_update(_delta: float) -> void:
	player.process_on_foot_controls(_delta, false, (1 / maxf(1.0, _item_mass)) * 0.75)
	player.draw_throw_arc()
	return


func enter(_previous_state_path: String, _data := {}) -> void:
	player.transition_timer.start()
	player.should_jump = false
	_item_mass = player._carried_item.mass
	player.camera_controller.set_pivot(CameraController.CAMERA_PIVOT.OVER_SHOULDER)
	player.update_interact_target(true)
	player.update_drop_target(true)
	return


func exit() -> void:
	player.transition_timer.start()
	player.hide_throw_arc()
	player.should_jump = false
	return
