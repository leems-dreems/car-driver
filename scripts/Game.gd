extends Node

var active_terrain: Terrain3D = null
var physics_item_container: Node3D = null
var current_environment: WorldEnvironment = null
var current_sun: DirectionalLight3D = null


func summon_car(_global_position: Vector3 = Vector3.INF) -> void:
	if get_tree().current_scene.has_method("summon_car"):
		get_tree().current_scene.summon_car(_global_position)
	else:
		print("Current scene has no summon_car method")
	return
