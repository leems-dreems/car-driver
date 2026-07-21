extends LimboHSM

@onready var idle_state: LimboState = $IdleState
@export var npc: Pedestrian


func _ready() -> void:
	initial_state = idle_state
	initialize(npc)
	set_active(true)
	return
