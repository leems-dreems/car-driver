class_name PlayerState extends State

const EMPTY_HANDED = "EmptyHanded"
const CARRYING = "Carrying"
const PLACING = "Placing"
const AIMING_THROW = "Aiming"
const THROWING = "Throwing"
const OPENING_DOOR = "Opening"

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
	elif _aim_target is ObjectiveArea:
		if _aim_target.start_mission:
			player.current_mission = _aim_target.get_parent()
		_aim_target.trigger(self)
	elif _aim_target is VehicleDispenserButton:
		var dispenser: VehicleDispenser = _aim_target.get_parent()
		dispenser.spawn_vehicle(_aim_target.vehicle_type)
	return
