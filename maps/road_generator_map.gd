extends Node3D

@onready var road_manager: RoadManager = $RoadManager


func _ready() -> void:
  pass
  #await get_tree().create_timer(1.0).timeout
  #for _road_static_body in find_children("road_mesh_col", "StaticBody3D"):
    #_road_static_body.add_to_group("Road")
