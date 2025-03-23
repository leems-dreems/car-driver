extends PlayerState


func physics_update(_delta: float) -> void:
	player.process_on_foot_controls(_delta)
	player.process_pickup_button()
	player.process_interact_button()
	return


func enter(_previous_state_path: String, _data := {}) -> void:
	player.set_throw_arc_visible(false)
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
