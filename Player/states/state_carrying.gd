extends PlayerState


func physics_update(_delta: float) -> void:
	if player.is_on_ground() and Input.is_action_pressed("aim"):
		finished.emit(AIMING_THROW)
		return

	if Input.is_action_just_pressed("pickup_drop"):
		if len(player.containers_in_range) > 0 and player.containers_in_range[0].has_method("deposit_item"):
			player.containers_in_range[0].deposit_item(player._carried_item)
			player._carried_item.queue_free()
			player.drop_item()
			finished.emit(EMPTY_HANDED)
		else:
			player.drop_item()
			finished.emit(EMPTY_HANDED)
	else:
		player.containers_in_range = []
		for _body: Node3D in player._pickup_collider.get_overlapping_bodies():
			if _body is CollidableContainer:
				player.containers_in_range.push_back(_body)
		var _container_distances := {}
		for _container: Node3D in player.containers_in_range:
			_container_distances[_container.get_instance_id()] = _container.global_position.distance_squared_to(player._pickup_collider.global_position)
		player.containers_in_range.sort_custom(func(a: Node3D, b: Node3D):
			return _container_distances[a.get_instance_id()] < _container_distances[b.get_instance_id()]
		)

	update_drop_target()
	update_interact_target()
	return


func enter(previous_state_path: String, data := {}) -> void:
	player.camera_controller.set_pivot(CameraController.CAMERA_PIVOT.THIRD_PERSON)
	return
