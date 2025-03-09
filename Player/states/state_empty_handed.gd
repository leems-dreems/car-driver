extends PlayerState


func physics_update(_delta: float) -> void:
	player.process_pickup_button()
	#update_pickup_target()

	player.process_interact_button()

	#update_interact_target()
	return


func enter(previous_state_path: String, data := {}) -> void:
	player.camera_controller.set_pivot(CameraController.CAMERA_PIVOT.THIRD_PERSON)
	player.update_interact_target(true)
	return


func exit() -> void:
	player.set_pickup_marker_borders(false)
	player.pickup_marker.visible = false
	player.long_press_marker.visible = false
	for _pickup in player.pickups_in_range:
		if _pickup.is_highlighted:
			_pickup.unhighlight()
	return
