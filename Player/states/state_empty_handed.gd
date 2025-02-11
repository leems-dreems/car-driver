extends PlayerState


func physics_update(_delta: float) -> void:
	# Try to get a useable target from the camera raycast
	var aim_collider := player.camera_controller.get_aim_collider()
	player.useable_target = aim_collider
# Try to use whatever we're aiming at
	if Input.is_action_just_pressed("use"):
		if aim_collider != null:
			use_aim_target(aim_collider)
		elif len(player._pickups_in_range) > 0:
			player.pickup_item(player._pickups_in_range[0])
			finished.emit(CARRYING)
	else:
		# Get pickups in range, and sort by distance to pickup collider
		player._pickups_in_range = player._pickup_collider.get_overlapping_bodies().filter(func(_body: Node3D):
			return _body is CarryableItem
		)
		if len(player._pickups_in_range) > 0:
			var _pickup_distances := {}
			for _pickup: CarryableItem in player._pickups_in_range:
				_pickup_distances[_pickup.get_instance_id()] = _pickup.global_position.distance_squared_to(player._pickup_collider.global_position)
			player._pickups_in_range.sort_custom(func(a: Node3D, b: Node3D):
				return _pickup_distances[a.get_instance_id()] < _pickup_distances[b.get_instance_id()]
			)
			var i: int = 0
			for _pickup in player._pickups_in_range:
				if i == 0:
					player.use_label.visible = true
					player.use_label.global_position = _pickup.global_position
					player.use_label.position.y += 0.5
					if not _pickup.is_highlighted:
						_pickup.highlight()
				else:
					_pickup.unhighlight()
				i += 1
		else:
			player.use_label.visible = false
	return


func enter(previous_state_path: String, data := {}) -> void:
	player.camera_controller.set_pivot(CameraController.CAMERA_PIVOT.THIRD_PERSON)
	return


func exit() -> void:
	player.use_label.visible = false
	for _pickup in player._pickups_in_range:
		if _pickup.is_highlighted:
			_pickup.unhighlight()
	return
