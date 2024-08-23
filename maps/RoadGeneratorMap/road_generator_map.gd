extends Node3D

@onready var road_manager: RoadManager = $RoadManager


func _ready() -> void:
  await get_tree().create_timer(1.0).timeout
  for _road_static_body in find_children("road_mesh_col", "StaticBody3D", true, false):
    _road_static_body.add_to_group("Road")
