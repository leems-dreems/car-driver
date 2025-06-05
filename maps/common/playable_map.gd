extends Node3D

@onready var road_manager: RoadManager = $RoadManager
const road_physics_material := preload("res://assets/materials/road_physics_material.tres")
const compact_car_scene := preload("res://cars/compact/compact.tscn")


func _ready() -> void:
	TrafficManager.vehicle_container_node = $VehicleContainer
	TrafficManager.add_spawn_points()
	PedestrianManager.pedestrian_container_node = $PedestrianContainer
	PedestrianManager.add_spawn_points()
	Game.physics_item_container = $PhysicsItemContainer
	Game.current_environment = $WorldEnvironment
	Game.current_sun = $DirectionalLight3D

	for _child_terrain: Terrain3D in find_children("Terrain3D", "Terrain3D"):
		Game.active_terrain = _child_terrain
	await get_tree().create_timer(1.0).timeout
	for _road_mesh: MeshInstance3D in find_children("road_mesh", "MeshInstance3D", true, false):
		_road_mesh.set_layer_mask_value(11, true)
		_road_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON

	return


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_PAUSED:
			RenderingServer.global_shader_parameter_set("TIME_SCALE", 0)
		NOTIFICATION_UNPAUSED:
			RenderingServer.global_shader_parameter_set("TIME_SCALE", 1)
	return


func summon_car(_global_position: Vector3 = Vector3.INF) -> void:
	for _car: DriveableVehicle in $VehicleContainer.find_children("*", "DriveableVehicle", false, false):
		if _car.owned_by_player:
			_car.queue_free()

	var _summoned_car := compact_car_scene.instantiate()
	_summoned_car.owned_by_player = true
	if _global_position != Vector3.INF:
		_summoned_car.global_position = _global_position
	else:
		_summoned_car.global_position = $Player.global_position
		_summoned_car.position.y += 4
	$VehicleContainer.add_child.call_deferred(_summoned_car)
	return
