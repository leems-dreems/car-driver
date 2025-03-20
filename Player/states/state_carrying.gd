extends PlayerState


func physics_update(_delta: float) -> void:
	if player.is_on_ground() and Input.is_action_pressed("aim"):
		finished.emit(AIMING_THROW)
		return

	player.process_drop_button()
	player.process_interact_button()
	return


func enter(_previous_state_path: String, _data := {}) -> void:
	player.camera_controller.set_pivot(CameraController.CAMERA_PIVOT.THIRD_PERSON)
	player.update_interact_target(true)
	player.update_drop_target(true)
	return
