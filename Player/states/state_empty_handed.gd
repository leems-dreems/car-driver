extends PlayerState


func physics_update(_delta: float) -> void:
	process_pickup_button()
	update_pickup_target()

	if Input.is_action_just_pressed("interact"):
		if len(player.useables_in_range) > 0:
			use_aim_target(player.useables_in_range[0])

	update_interact_target()
	return


func enter(previous_state_path: String, data := {}) -> void:
	player.camera_controller.set_pivot(CameraController.CAMERA_PIVOT.THIRD_PERSON)
	return


func exit() -> void:
	player.pickup_marker.visible = false
	player.long_press_marker.visible = false
	for _pickup in player.pickups_in_range:
		if _pickup.is_highlighted:
			_pickup.unhighlight()
	player.pickups_in_range = []
	player.useables_in_range = []
	player.containers_in_range = []
	return
