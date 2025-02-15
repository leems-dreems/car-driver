extends PlayerState


func physics_update(_delta: float) -> void:
	if Input.is_action_just_pressed("pickup_drop"):
		player.drop_item()
		finished.emit(EMPTY_HANDED)
	if player.is_on_ground() and Input.is_action_pressed("aim"):
		finished.emit(AIMING_THROW)
	update_use_target()
	return


func enter(previous_state_path: String, data := {}) -> void:
	player.camera_controller.set_pivot(CameraController.CAMERA_PIVOT.THIRD_PERSON)
	return
