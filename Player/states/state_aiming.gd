extends PlayerState


func physics_update(_delta: float) -> void:
	if Input.is_action_just_pressed("use"):
		player.drop_item()
		finished.emit(EMPTY_HANDED)
	if not Input.is_action_pressed("aim"):
		player._last_strong_direction = player.camera_controller.global_transform.basis.z
		finished.emit(CARRYING)
	if Input.is_action_just_pressed("throw"):
		player.throw_item()
	return


func enter(previous_state_path: String, data := {}) -> void:
	player.camera_controller.set_pivot(CameraController.CAMERA_PIVOT.OVER_SHOULDER)
	return
