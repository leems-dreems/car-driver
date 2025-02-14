class_name PlayerState extends State

const EMPTY_HANDED = "EmptyHanded"
const CARRYING = "Carrying"
const PLACING = "Placing"
const AIMING_THROW = "Aiming"
const THROWING = "Throwing"
const OPENING_DOOR = "Opening"
const DRIVING = "Driving"

var player: Player


func _ready() -> void:
	await owner.ready
	player = owner as Player
	assert(player != null, "The PlayerState state type must be used only in the player scene. It needs the owner to be a Player node.")
	return


func use_aim_target(_aim_target: Node) -> void:
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
	return


func update_use_target() -> void:
	if len(player._useables_in_range) > 0:
		var _useable_distances := {}
		for _useable: Node3D in player._useables_in_range:
			_useable_distances[_useable.get_instance_id()] = _useable.global_position.distance_squared_to(player._pickup_collider.global_position)
		player._useables_in_range.sort_custom(func(a: Node3D, b: Node3D):
			return _useable_distances[a.get_instance_id()] < _useable_distances[b.get_instance_id()]
		)
		var i: int = 0
		for _useable in player._useables_in_range:
			if i == 0:
				if _useable.has_method("highlight") and not _useable.is_highlighted:
					_useable.highlight()
			elif _useable.has_method("unhighlight"):
				_useable.unhighlight()
			i += 1
	return


func highlight_use_target() -> void:
	if len(player._useables_in_range) > 0:
		var _useable := player._useables_in_range[0]
		if _useable.has_method("highlight") and not _useable.is_highlighted:
			_useable.highlight()
	return


func unhighlight_all_useables() -> void:
	for _useable in player._useables_in_range:
		if _useable.has_method("unhighlight") and _useable.is_highlighted:
			_useable.unhighlight()
	return
