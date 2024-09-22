extends Node3D

@onready var road_manager: RoadManager = $RoadManager
var road_physics_material := preload("res://assets/materials/road_physics_material.tres")


func _ready() -> void:
  TrafficManager.vehicle_container_node = $VehicleContainer
  TrafficManager.add_traffic_spawn_points()
  await get_tree().create_timer(1.0).timeout
  for _road_static_body: StaticBody3D in find_children("road_mesh_col", "StaticBody3D", true, false):
    _road_static_body.add_to_group("Road")
    _road_static_body.physics_material_override = road_physics_material
  for _road_mesh: MeshInstance3D in find_children("road_mesh", "MeshInstance3D", true, false):
    _road_mesh.set_layer_mask_value(11, true)
    _road_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
