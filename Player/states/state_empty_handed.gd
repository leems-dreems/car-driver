extends PlayerState

const _pickup_button_delay := 1.0 ## How long pickup button needs to be held for long-press actions
var _pickup_button_timer: SceneTreeTimer = null


func physics_update(_delta: float) -> void:
	if Input.is_action_just_released("pickup_drop"):
		if _pickup_button_timer != null:
			_pickup_button_timer.timeout.disconnect(_on_pickup_long_press)
			_pickup_button_timer = null
			player.targeted_container = null
			player.targeted_item = null
			player.long_press_anim.stop()
			player.long_press_anim.seek(0)
			if len(player.pickups_in_range) > 0 and player.pickups_in_range[0].container_node == null:
				player.pickups_in_range[0].unhighlight()
				player.pickup_item(player.pickups_in_range[0])
				finished.emit(CARRYING)
				return
	elif Input.is_action_just_pressed("pickup_drop"):
		if len(player.containers_in_range) > 0:
			player.long_press_anim.play("long_press")
			_pickup_button_timer = get_tree().create_timer(_pickup_button_delay)
			player.targeted_container = player.containers_in_range[0]
			_pickup_button_timer.timeout.connect(_on_pickup_long_press)
		elif len(player.pickups_in_range) > 0:
			if player.pickups_in_range[0].container_node != null:
				player.long_press_anim.play("long_press")
				_pickup_button_timer = get_tree().create_timer(_pickup_button_delay)
				player.targeted_item = player.pickups_in_range[0]
				_pickup_button_timer.timeout.connect(_on_pickup_long_press)
			else:
				player.pickups_in_range[0].unhighlight()
				player.pickup_item(player.pickups_in_range[0])
				finished.emit(CARRYING)
				return

	if not Input.is_action_pressed("pickup_drop"):
		player.containers_in_range = []
		for _body: Node3D in player._pickup_collider.get_overlapping_bodies():
			if _body is RigidBinContainer and _body.total_count > 0:
				player.containers_in_range.push_back(_body)

		if len(player.containers_in_range) > 0:
			var _container_distances := {}
			for _container: RigidBinContainer in player.containers_in_range:
				_container_distances[_container.get_instance_id()] = _container.global_position.distance_squared_to(player._pickup_collider.global_position)
			player.containers_in_range.sort_custom(func(a: Node3D, b: Node3D):
				return _container_distances[a.get_instance_id()] < _container_distances[b.get_instance_id()]
			)
			var i: int = 0
			for _container in player.containers_in_range:
				if i == 0:
					player.container_marker.visible = true
					player.container_marker.global_position = _container.global_position
					player.container_marker.position.y += 3
					if not _container.is_highlighted:
						_container.highlight()
				else:
					_container.unhighlight()
				i += 1
		else:
			player.container_marker.visible = false

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
				player.pickup_marker.visible = true
				player.pickup_marker.global_position = _pickup.global_position
				player.pickup_marker.position.y += 0.5
				if not _pickup.is_highlighted:
					_pickup.highlight()
			else:
				_pickup.unhighlight()
			i += 1
	else:
		player.pickup_marker.visible = false

	if Input.is_action_just_pressed("interact"):
		if len(player.useables_in_range) > 0:
			use_aim_target(player.useables_in_range[0])
	else:
		player.useables_in_range = []
		for _body: Node3D in player._pickup_collider.get_overlapping_bodies():
			if _body is not CarryableItem and _body is not RigidBinContainer and _body is not VehicleItemContainer:
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
	player.pickup_marker.visible = false
	for _pickup in player.pickups_in_range:
		if _pickup.is_highlighted:
			_pickup.unhighlight()
	player.pickups_in_range = []
	player.useables_in_range = []
	player.containers_in_range = []
	return


func _on_pickup_long_press() -> void:
	_pickup_button_timer = null
	player.long_press_anim.stop()
	player.long_press_anim.seek(0)
	if player.targeted_container != null:
		if player.targeted_container.has_method("long_press_pickup"):
			player.targeted_container.long_press_pickup()
	elif player.targeted_item != null:
		player.pickups_in_range[0].unhighlight()
		player.pickup_item(player.targeted_item)
		finished.emit(CARRYING)
	return
