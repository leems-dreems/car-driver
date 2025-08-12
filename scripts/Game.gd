extends Node

signal minute_reached(minute: int)

var active_terrain: Terrain3D = null
var physics_item_container: Node3D = null
var current_environment: WorldEnvironment = null
var current_sun: DirectionalLight3D = null
var current_time: float
var max_time: float = 2400.0
var time_speed: float = 0.0
var next_minute: int
@onready var minutes := range(0, roundi(max_time))


func _physics_process(delta: float) -> void:
	current_time += delta * time_speed

	if current_time >= next_minute:
		minute_reached.emit(next_minute)
		next_minute += 1
		if next_minute >= max_time:
			next_minute = 0

	if current_time > max_time:
		current_time -= max_time
	return


func summon_car(_global_position: Vector3 = Vector3.INF) -> void:
	if get_tree().current_scene.has_method("summon_car"):
		get_tree().current_scene.summon_car(_global_position)
	else:
		print("Current scene has no summon_car method")
	return


## Returns the current time in 24-hour format (e.g. 1300 = 1PM)
func get_current_time() -> int:
	return roundi(current_time)


func set_current_time(_current_time: float) -> void:
	current_time = _current_time
	next_minute = ceili(current_time)
	if next_minute >= max_time:
		next_minute = 0
	return


func set_time_speed(_time_speed: float) -> void:
	time_speed = _time_speed
	return
