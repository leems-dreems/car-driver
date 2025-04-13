extends PlayerState


func handle_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") and not event.is_echo():
		player.handle_interact_button_pressed()
	elif event.is_action_released("interact"):
		player.handle_interact_button_released()
	elif event.is_action_pressed("pickup_drop") and not event.is_echo():
		player.handle_pickup_button_pressed()
	return


func physics_update(_delta: float) -> void:
	player.process_on_foot_controls(_delta)
	if not Input.is_action_pressed("interact") and player.interact_short_press_timer.is_stopped() and player.interact_long_press_timer.is_stopped():
		player.update_interact_target()
	if not Input.is_action_pressed("pickup_drop") and player.pickup_short_press_timer.is_stopped():
		player.update_pickup_target()
	#player.process_pickup_button()
	#player.process_interact_button()
	return


func enter(_previous_state_path: String, _data := {}) -> void:
	#set_process_unhandled_input(true)
	player.set_throw_arc_visible(false)
	player.camera_controller.set_pivot(CameraController.CAMERA_PIVOT.THIRD_PERSON)
	player.update_interact_target(true)
	return


func exit() -> void:
	#set_process_unhandled_input(false)
	player.set_pickup_marker_borders(false)
	player.pickup_marker.visible = false
	player.long_press_marker.visible = false
	for _pickup in player.pickups_in_range:
		if _pickup.is_highlighted:
			_pickup.unhighlight()
	return
