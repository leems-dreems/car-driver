extends PlayerState

var _button_hold_timer: SceneTreeTimer = null
const _button_hold_delay := 1.0


func physics_update(_delta: float) -> void:
	if Input.is_action_just_released("pickup_drop"):
		_button_hold_timer.free()
		_button_hold_timer = null
	if Input.is_action_just_pressed("pickup_drop") and len(player.containers_in_range) > 0:
		_button_hold_timer = get_tree().create_timer(_button_hold_delay)
	if Input.is_action_pressed("pickup_drop") and _button_hold_timer != null:
		return
	# ?
	if Input.is_action_just_pressed("pickup_drop") and len(player.pickups_in_range) > 0:
		player.pickup_item(player.pickups_in_range[0])
		finished.emit(CARRYING)
	else:
		# Get pickups in range, and sort by distance to pickup collider
		player.pickups_in_range = []
		for _body: Node3D in player._pickup_collider.get_overlapping_bodies():
			if _body is CarryableItem:
				player.pickups_in_range.push_back(_body)
		if len(player.pickups_in_range) > 0:
			var _pickup_distances := {}
			for _pickup: CarryableItem in player.pickups_in_range:
				_pickup_distances[_pickup.get_instance_id()] = _pickup.global_position.distance_squared_to(player._pickup_collider.global_position)
			player.pickups_in_range.sort_custom(func(a: Node3D, b: Node3D):
				return _pickup_distances[a.get_instance_id()] < _pickup_distances[b.get_instance_id()]
			)
			var i: int = 0
			for _pickup in player.pickups_in_range:
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

	if Input.is_action_just_pressed("interact"):
		if len(player.useables_in_range) > 0:
			use_aim_target(player.useables_in_range[0])
	else:
		player.useables_in_range = []
		for _body: Node3D in player._pickup_collider.get_overlapping_bodies():
			if _body is not CarryableItem and _body is not CollidableContainer:
				player.useables_in_range.push_back(_body)
		var _useable_distances := {}
		for _useable: Node3D in player.useables_in_range:
			var _useable_position: Vector3
			if _useable is CarDoor:
				_useable_position = _useable.interact_target.global_position
			else:
				_useable_position = _useable.global_position
			_useable_distances[_useable.get_instance_id()] = _useable_position.distance_squared_to(player._pickup_collider.global_position)
		player.useables_in_range.sort_custom(func(a: Node3D, b: Node3D):
			return _useable_distances[a.get_instance_id()] < _useable_distances[b.get_instance_id()]
		)

	update_interact_target()
	return


func enter(previous_state_path: String, data := {}) -> void:
	player.camera_controller.set_pivot(CameraController.CAMERA_PIVOT.THIRD_PERSON)
	return


func exit() -> void:
	player.use_label.visible = false
	for _pickup in player.pickups_in_range:
		if _pickup.is_highlighted:
			_pickup.unhighlight()
	return
