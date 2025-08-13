extends Node

signal time_changed(minute: int)

var active_terrain: Terrain3D = null
var physics_item_container: Node3D = null
var current_environment: WorldEnvironment = null
var current_sun: DirectionalLight3D = null
var current_time: float
var max_time: float = 2400.0
var time_speed: float = 0.0
var next_minute: int
@onready var minutes := range(0, roundi(max_time))


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
	time_changed.emit(roundi(current_time))
	return


func set_time_speed(_time_speed: float) -> void:
	time_speed = _time_speed
	return
