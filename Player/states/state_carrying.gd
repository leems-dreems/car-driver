extends PlayerState


func physics_update(_delta: float) -> void:
	if Input.is_action_just_pressed("use"):
		player.drop_item()
		finished.emit(EMPTY_HANDED)
	return
