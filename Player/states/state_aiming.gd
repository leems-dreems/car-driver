extends PlayerState

## Timer used to delay switching back to the empty-handed state after a throw
var _hold_timer: SceneTreeTimer = null
var _item_mass := 1.0


func physics_update(_delta: float) -> void:
	player.process_on_foot_controls(_delta, false, (1 / maxf(1.0, _item_mass)) * 0.75)
	if _hold_timer != null:
		return
	player.process_interact_button()
	player.process_drop_button()
	if not Input.is_action_pressed("aim") or not player.is_on_ground():
		player._last_strong_direction = player.camera_controller.global_transform.basis.z
		finished.emit(CARRYING)
	if Input.is_action_just_pressed("throw"):
		player._last_strong_direction = player.camera_controller.global_transform.basis.z
		player.throw_item()
		_hold_timer = get_tree().create_timer(0.5)
		await _hold_timer.timeout
		_hold_timer = null
		finished.emit(EMPTY_HANDED)
	return


func enter(_previous_state_path: String, _data := {}) -> void:
	_item_mass = player._carried_item.mass
	player.set_throw_arc_visible(true)
	player.camera_controller.set_pivot(CameraController.CAMERA_PIVOT.OVER_SHOULDER)
	player.update_interact_target(true)
	player.update_drop_target(true)
	return
