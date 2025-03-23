extends PlayerState

var _item_mass := 1.0


func physics_update(_delta: float) -> void:
	player.process_on_foot_controls(_delta, true, 0.25 + (1 / maxf(1.0, _item_mass)) * 0.75)
	if player.is_on_ground() and Input.is_action_pressed("aim"):
		finished.emit(AIMING_THROW)
		return

	player.process_drop_button()
	player.process_interact_button()
	return


func enter(_previous_state_path: String, _data := {}) -> void:
	_item_mass = player._carried_item.mass
	player.set_throw_arc_visible(false)
	player.camera_controller.set_pivot(CameraController.CAMERA_PIVOT.THIRD_PERSON)
	player.update_interact_target(true)
	player.update_drop_target(true)
	return
