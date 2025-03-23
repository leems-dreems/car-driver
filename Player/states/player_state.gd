class_name PlayerState extends State

const EMPTY_HANDED = "EmptyHanded"
const CARRYING = "Carrying"
const PLACING = "Placing"
const AIMING_THROW = "Aiming"
const THROWING = "Throwing"
const OPENING_DOOR = "Opening"
const DRIVING = "Driving"
const IN_DIALOGUE = "InDialogue"

var player: Player


func _ready() -> void:
	await owner.ready
	player = owner as Player
	assert(player != null, "The PlayerState state type must be used only in the player scene. It needs the owner to be a Player node.")
	return
