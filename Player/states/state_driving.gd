extends PlayerState


func handle_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		player.exitVehicle()
		finished.emit(EMPTY_HANDED)
	return


func physics_update(_delta: float) -> void:
	player.process_vehicle_controls(_delta)
	return


func enter(_previous_state_path: String, _data := {}) -> void:
	player.set_throw_arc_visible(false)
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
