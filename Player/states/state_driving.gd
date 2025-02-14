extends PlayerState


func physics_update(_delta: float) -> void:
	if Input.is_action_just_pressed("use"):
		player.exitVehicle()
		finished.emit(EMPTY_HANDED)
	return


func enter(previous_state_path: String, data := {}) -> void:
	unhighlight_all_useables()
	if player._carried_item != null:
		player.drop_item()
	return
