extends PlayerState

const handbrake_scroll_multiplier := 0.2
const handbrake_dpad_multiplier := 0.5


func handle_input(event: InputEvent) -> void:
	if event.is_action_pressed("Pause") and not event.is_echo():
		player.handle_pause_button_pressed()
		return

	var _vehicle := player.current_vehicle as DriveableVehicle
	if _vehicle == null:
		return

	if event.is_action_pressed("handbrake_up"):
		if event is InputEventMouseButton:
			_vehicle.handbrake_input = minf(_vehicle.handbrake_input + (event.factor * handbrake_scroll_multiplier), 1.0)
		else:
			_vehicle.handbrake_input = minf(_vehicle.handbrake_input + handbrake_dpad_multiplier, 1.0)
	elif event.is_action_pressed("handbrake_down"):
		if event is InputEventMouseButton:
			_vehicle.handbrake_input = maxf(0, _vehicle.handbrake_input - (event.factor * handbrake_scroll_multiplier))
		else:
			_vehicle.handbrake_input = maxf(0, _vehicle.handbrake_input - handbrake_dpad_multiplier)
	elif event.is_action_pressed("interact"):
		player.exitVehicle()
		finished.emit(EMPTY_HANDED)
	return


func physics_update(_delta: float) -> void:
	player.process_vehicle_controls(_delta)
	return


func enter(_previous_state_path: String, _data := {}) -> void:
	player.transition_timer.start()
	if player.targeted_interactable != null:
		player.short_press_interact_unhighlight.emit()
		player.long_press_interact_unhighlight.emit()
		player.targeted_interactable.unhighlight()
		player.targeted_interactable = null
	if player.targeted_pickup != null:
		player.short_press_pickup_unhighlight.emit()
		player.targeted_pickup.unhighlight()
		player.targeted_pickup = null
	if player.drop_target != null:
		player.short_press_drop_unhighlight.emit()
		player.drop_target.unhighlight()
		player.drop_target = null
	if player._carried_item != null:
		player.drop_item()
	return


func exit() -> void:
	player.transition_timer.start()
	return
