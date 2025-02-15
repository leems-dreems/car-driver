class_name PlayerState extends State

const EMPTY_HANDED = "EmptyHanded"
const CARRYING = "Carrying"
const PLACING = "Placing"
const AIMING_THROW = "Aiming"
const THROWING = "Throwing"
const OPENING_DOOR = "Opening"
const DRIVING = "Driving"

var player: Player
## Player won't update the interact target while this timer is running
var _interact_target_timer: SceneTreeTimer = null
const _interact_target_delay := 0.2
## Player won't update the drop target while this timer is running
var _drop_target_timer: SceneTreeTimer = null
const _drop_target_delay := 0.2


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


func update_interact_target() -> void:
	if _interact_target_timer != null:
		return

	if len(player.useables_in_range) > 0:
		_interact_target_timer = get_tree().create_timer(_interact_target_delay)
		_interact_target_timer.timeout.connect(func(): _interact_target_timer = null)

		var i: int = 0
		for _useable in player.useables_in_range:
			if i == 0:
				if _useable.has_method("highlight") and not _useable.is_highlighted:
					_useable.highlight()
			elif _useable.has_method("unhighlight"):
				_useable.unhighlight()
			i += 1
	return


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
					_container.highlight()
			elif _container.has_method("unhighlight"):
				_container.unhighlight()
			i += 1
	return


func highlight_use_target() -> void:
	if len(player.useables_in_range) > 0:
		var _useable := player.useables_in_range[0]
		if _useable.has_method("highlight") and not _useable.is_highlighted:
			_useable.highlight()
	return


func unhighlight_all_useables() -> void:
	for _useable in player.useables_in_range:
		if _useable.has_method("unhighlight") and _useable.is_highlighted:
			_useable.unhighlight()
	return
