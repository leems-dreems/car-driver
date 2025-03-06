class_name PlayerState extends State

const EMPTY_HANDED = "EmptyHanded"
const CARRYING = "Carrying"
const PLACING = "Placing"
const AIMING_THROW = "Aiming"
const THROWING = "Throwing"
const OPENING_DOOR = "Opening"
const DRIVING = "Driving"

var player: Player
## Node that will be interacted with if interact button is short-pressed
var short_press_interact_target: Node3D = null
## Node that will be interacted with if interact button is long-pressed
var long_press_interact_target: Node3D = null
## Player won't update the interact target while this timer is running
var _interact_target_timer: SceneTreeTimer = null
const _interact_target_delay := 0.2
## Timer used for short presses of the interact key/button
var _interact_button_short_press_timer: SceneTreeTimer = null
const _interact_button_short_press_delay := 0.2
## Timer used for long presses of the interact key/button
var _interact_button_long_press_timer: SceneTreeTimer = null
const _interact_button_long_press_delay := 1.0

## Item that will be picked up if pickup button is pressed
var pickup_target: Node3D = null
## Container that the carried item will be put into if drop button is pressed
var drop_target: Node3D = null
## Timer used for short presses of the pickup key/button
var _pickup_button_long_press_timer: SceneTreeTimer = null
const _pickup_button_short_press_delay := 0.2
var _pickup_button_short_press_timer: SceneTreeTimer = null
const _pickup_button_long_press_delay := 1.0
## Player won't update the drop target while this timer is running
var _drop_target_timer: SceneTreeTimer = null
const _drop_target_delay := 0.2


func _ready() -> void:
	await owner.ready
	player = owner as Player
	assert(player != null, "The PlayerState state type must be used only in the player scene. It needs the owner to be a Player node.")
	return


func use_aim_target(_aim_target: Node) -> void:
	if _interact_button_short_press_timer != null:
		print("Attempted to interact while previous interaction was still going")
		return
	player.short_press_interact_start.emit()
	_interact_button_short_press_timer = get_tree().create_timer(_interact_button_short_press_delay)

	_interact_button_short_press_timer.timeout.connect(func():
		_interact_button_short_press_timer = null
		if _interact_button_long_press_timer != null:
			return
		player.short_press_interact_finish.emit()
		if _aim_target.has_method("unhighlight"):
			_aim_target.unhighlight()
		if _aim_target.has_method("open_or_shut"):
			_aim_target.open_or_shut()
		elif _aim_target is EnterVehicleCollider:
			player.enterVehicle(_aim_target.vehicle)
			finished.emit(DRIVING)
		elif _aim_target is ObjectiveArea:
			if _aim_target.start_mission:
				player.current_mission = _aim_target.get_parent()
			_aim_target.trigger(self)
		elif _aim_target is VehicleDispenserButton:
			var dispenser: VehicleDispenser = _aim_target.get_parent()
			dispenser.spawn_vehicle(_aim_target.vehicle_type)
	)
	return


#func update_interact_target() -> void:
	#if _interact_target_timer != null or _interact_button_short_press_timer != null or _interact_button_long_press_timer != null:
		#return
#
	#player.interactables_in_range = []
	#for _body: Node3D in player._pickup_collider.get_overlapping_bodies():
		#if _body.has_method("interact_short_press") and _body.has_method("interact_long_press"):
			#player.interactables_in_range.push_back(_body)
	#var _useable_distances := {}
	#for _useable: Node3D in player.interactables_in_range:
		#var _useable_position: Vector3
		#if _useable is CarDoor:
			#_useable_position = _useable.interact_target.global_position
		#else:
			#_useable_position = _useable.global_position
		#_useable_distances[_useable.get_instance_id()] = _useable_position.distance_squared_to(player._pickup_collider.global_position)
	#player.interactables_in_range.sort_custom(func(a: Node3D, b: Node3D):
		#return _useable_distances[a.get_instance_id()] < _useable_distances[b.get_instance_id()]
	#)
#
	#if len(player.interactables_in_range) > 0:
		#_interact_target_timer = get_tree().create_timer(_interact_target_delay)
		#_interact_target_timer.timeout.connect(func(): _interact_target_timer = null)
#
		#var i: int = 0
		#for _interactable in player.interactables_in_range:
			#if i == 0:
				#player.targeted_interactable = _interactable
				#if not _interactable.is_highlighted:
					#player.targeted_interactable = _interactable
					#player.short_press_interact_highlight.emit(_interactable)
					#_interactable.highlight()
			#elif _interactable.is_highlighted:
				#_interactable.unhighlight()
			#i += 1
	#elif player.targeted_interactable != null:
		#player.targeted_interactable = null
		#player.short_press_interact_unhighlight.emit()
	#return


func update_pickup_target() -> void:
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
				pickup_target = _pickup
				#if _pickup.container_node != null:
					#if player.targeted_item == null:
						#player.set_pickup_marker_borders(true)
						#player.set_pickup_marker_text(_pickup.item_name.capitalize())
						#player.long_press_pickup_highlight.emit(_pickup)
					##player.long_press_marker.visible = true
					##player.long_press_marker.global_position = _pickup.global_position
					##player.long_press_marker.position.y += 3
					#player.pickup_marker.visible = true
					#player.pickup_marker.global_position = _pickup.global_position
					#player.pickup_marker.position.y += 0.5
				#else:
				if not _pickup.is_highlighted:
					player.set_pickup_marker_borders(false)
					player.set_pickup_marker_text(_pickup.item_name.capitalize())
					player.short_press_pickup_highlight.emit(_pickup)
				player.pickup_marker.visible = true
				player.pickup_marker.global_position = _pickup.global_position
				player.pickup_marker.position.y += 0.5
				_pickup.highlight()
			else:
				_pickup.unhighlight()
			i += 1
	else:
		pickup_target = null
		player.short_press_pickup_unhighlight.emit()
		player.pickup_marker.visible = false
		player.set_pickup_marker_borders(false)


func update_drop_target() -> void:
	if _drop_target_timer != null:
		return

	if len(player.containers_in_range) > 0:
		_drop_target_timer = get_tree().create_timer(_drop_target_delay)
		_drop_target_timer.timeout.connect(func(): _drop_target_timer = null)

		var i: int = 0
		for _container in player.containers_in_range:
			if i == 0:
				if _container.has_method("highlight") and not _container.is_highlighted:
					player.short_press_drop_highlight.emit(_container)
					drop_target = _container
					_container.highlight()
			elif _container.has_method("unhighlight"):
				_container.unhighlight()
			i += 1
	elif drop_target != null:
		drop_target = null
		player.short_press_drop_unhighlight.emit()
	return


func unhighlight_all_useables() -> void:
	player.short_press_interact_unhighlight.emit()
	for _useable in player.interactables_in_range:
		if _useable.has_method("unhighlight") and _useable.is_highlighted:
			_useable.unhighlight()
	return

# TODO: Move this code into Player class, create dedicated Timer nodes
#func process_interact_button() -> void:
	#if Input.is_action_just_released("interact"):
		#if _interact_button_short_press_timer != null:
			#_interact_button_short_press_timer == null
			#player.short_press_interact_finish.emit()
			#player.targeted_interactable.interact_short_press()
		#if _interact_button_long_press_timer != null:
			#_interact_button_long_press_timer.timeout.disconnect(_on_interact_long_press)
			#_interact_button_long_press_timer = null
			#player.long_press_interact_cancel.emit()
			#player.targeted_interactable = null
#
	#elif Input.is_action_just_pressed("interact") and _pickup_button_short_press_timer == null and _pickup_button_long_press_timer == null:
		#if player.targeted_interactable.has_method("interact_short_press"):
			#player.short_press_interact_start.emit()
			#_interact_button_short_press_timer = get_tree().create_timer(_interact_button_short_press_delay)
#
			#_interact_button_short_press_timer.timeout.connect(func():
				#if _interact_button_short_press_timer == null:
					#return
				#_interact_button_short_press_timer = null
				#if player.targeted_interactable.has_method("interact_long_press"):
					#player.long_press_interact_start.emit()
					#_interact_button_long_press_timer = get_tree().create_timer(_interact_button_long_press_delay)
#
					#_interact_button_long_press_timer.timeout.connect(func():
						#if _interact_button_long_press_timer == null:
							#return
						#_interact_button_long_press_timer = null
						#player.long_press_interact_finish.emit()
						#player.targeted_interactable.interact_long_press()
					#)
				#else:
					#player.short_press_interact_finish.emit()
					#player.targeted_interactable.interact_short_press()
			#)
		#elif player.targeted_interactable.has_method("interact_long_press"):
			#player.long_press_interact_start.emit()
			#_interact_button_long_press_timer = get_tree().create_timer(_interact_button_long_press_delay)
#
			#_interact_button_long_press_timer.timeout.connect(func():
				#if _interact_button_long_press_timer == null:
					#return
				#_interact_button_long_press_timer = null
				#player.long_press_interact_finish.emit()
				#player.targeted_interactable.interact_long_press()
			#)
	#
	#else:
		#update_interact_target()
		
		#if len(player.containers_in_range) > 0:
			#player.long_press_pickup_start.emit()
			#player.long_press_anim.play("long_press")
			#_pickup_button_long_press_timer = get_tree().create_timer(_pickup_button_long_press_delay)
			#player.targeted_container = player.containers_in_range[0]
			#_pickup_button_long_press_timer.timeout.connect(_on_pickup_long_press)
		#elif len(player.interactables_in_range) > 0:
			#
			#if player.interactables_in_range[0].container_node != null:
				#player.long_press_pickup_start.emit()
				#player.long_press_anim.play("long_press")
				#_pickup_button_long_press_timer = get_tree().create_timer(_pickup_button_long_press_delay)
				#player.targeted_item = player.interactables_in_range[0]
				#_pickup_button_long_press_timer.timeout.connect(_on_pickup_long_press)
			#else:
				#player.short_press_pickup_start.emit()
				#_pickup_button_short_press_timer = get_tree().create_timer(_pickup_button_short_press_delay)
				#_pickup_button_short_press_timer.timeout.connect(func():
					#_pickup_button_short_press_timer = null
					#player.short_press_pickup_finish.emit()
					#player.interactables_in_range[0].unhighlight()
					#player.pickup_item(player.interactables_in_range[0])
					#finished.emit(CARRYING)
				#)
				#return

# TODO
func _on_interact_long_press() -> void:
	_interact_button_long_press_timer = null
	player.long_press_interact_finish.emit()
	player.long_press_anim.stop()
	player.long_press_anim.seek(0)

	return


func process_pickup_button() -> void:
	if Input.is_action_just_released("pickup_drop"):
		if _pickup_button_long_press_timer != null:
			_pickup_button_long_press_timer.timeout.disconnect(_on_pickup_long_press)
			_pickup_button_long_press_timer = null
			player.long_press_pickup_cancel.emit()
			player.targeted_container = null
			player.targeted_item = null
			player.long_press_anim.stop()
			player.long_press_anim.seek(0)
			if len(player.pickups_in_range) > 0 and player.pickups_in_range[0].container_node == null:
				player.short_press_pickup_start.emit()
				player.pickups_in_range[0].unhighlight()
				player.pickup_item(player.pickups_in_range[0])
				finished.emit(CARRYING)
				return
	elif Input.is_action_just_pressed("pickup_drop") and _pickup_button_short_press_timer == null:
		#if len(player.containers_in_range) > 0:
			#player.long_press_pickup_start.emit()
			#player.long_press_anim.play("long_press")
			#_pickup_button_long_press_timer = get_tree().create_timer(_pickup_button_long_press_delay)
			#player.targeted_container = player.containers_in_range[0]
			#_pickup_button_long_press_timer.timeout.connect(_on_pickup_long_press)
		if len(player.pickups_in_range) > 0:
			#if player.pickups_in_range[0].container_node != null:
				#player.long_press_pickup_start.emit()
				#player.long_press_anim.play("long_press")
				#_pickup_button_long_press_timer = get_tree().create_timer(_pickup_button_long_press_delay)
				#player.targeted_item = player.pickups_in_range[0]
				#_pickup_button_long_press_timer.timeout.connect(_on_pickup_long_press)
			#else:
			player.short_press_pickup_start.emit()
			_pickup_button_short_press_timer = get_tree().create_timer(_pickup_button_short_press_delay)
			_pickup_button_short_press_timer.timeout.connect(func():
				_pickup_button_short_press_timer = null
				player.short_press_pickup_finish.emit()
				player.pickups_in_range[0].unhighlight()
				player.pickup_item(player.pickups_in_range[0])
				finished.emit(CARRYING)
			)
			return
	#elif not Input.is_action_pressed("pickup_drop"):
		#player.containers_in_range = []
		#for _body: Node3D in player._pickup_collider.get_overlapping_bodies():
			#if _body is RigidBinContainer and _body.total_count > 0:
				#player.containers_in_range.push_back(_body)
#
		#if len(player.containers_in_range) > 0:
			#var _container_distances := {}
			#for _container: RigidBinContainer in player.containers_in_range:
				#_container_distances[_container.get_instance_id()] = _container.global_position.distance_squared_to(player._pickup_collider.global_position)
			#player.containers_in_range.sort_custom(func(a: Node3D, b: Node3D):
				#return _container_distances[a.get_instance_id()] < _container_distances[b.get_instance_id()]
			#)
			#var i: int = 0
			#for _container in player.containers_in_range:
				#if i == 0:
					#player.long_press_pickup_highlight.emit(_container)
					#player.long_press_marker.visible = true
					#player.long_press_marker.global_position = _container.global_position
					#player.long_press_marker.position.y += 3
					#if not _container.is_highlighted:
						#_container.highlight()
				#else:
					#_container.unhighlight()
				#i += 1
		#else:
			#player.long_press_pickup_unhighlight.emit()
			#player.long_press_marker.visible = false


func _on_pickup_long_press() -> void:
	_pickup_button_long_press_timer = null
	player.long_press_pickup_finish.emit()
	player.long_press_anim.stop()
	player.long_press_anim.seek(0)
	if player.targeted_container != null:
		if player.targeted_container.has_method("long_press_pickup"):
			player.targeted_container.long_press_pickup()
			player.targeted_container = null
	elif player.targeted_item != null:
		player.targeted_item.unhighlight()
		player.pickup_item(player.targeted_item)
		finished.emit(CARRYING)
	return
