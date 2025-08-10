class_name DailyRoutine
extends Resource

## A dictionary of nodes this actor should travel to, indexed by the 24-hour
## time (e.g. 400 = 4AM, 1800 = 6PM)
@export var appointments: Dictionary[int, NodePath]


func get_next_appointment(from_time: int = Game.get_current_time()) -> NodePath:
	assert(from_time >= 0 and from_time <= 2400)
	var next_appointment: NodePath
	for time: int in appointments.keys():
		if from_time < time:
			return appointments[time]
	return ""
