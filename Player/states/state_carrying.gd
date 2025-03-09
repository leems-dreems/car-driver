extends PlayerState

const _drop_button_short_press_delay := 0.2 ## How long drop button will be locked for after a short press
var _drop_button_short_press_timer: SceneTreeTimer = null


func physics_update(_delta: float) -> void:
	if player.is_on_ground() and Input.is_action_pressed("aim"):
		finished.emit(AIMING_THROW)
		return

	player.process_drop_button()
	return


func enter(previous_state_path: String, data := {}) -> void:
	player.camera_controller.set_pivot(CameraController.CAMERA_PIVOT.THIRD_PERSON)
	player.update_interact_target(true)
	player.update_drop_target(true)
	return


func exit() -> void:
	return
