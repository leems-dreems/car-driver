@tool
class_name TrafficPath extends Path3D
## Supports [TrafficAgent] nodes, which spawn & control AI-driven vehicles

@export_group("TrafficPath Settings")
## If true, TrafficManager will spawn vehicles on this path
@export var spawn_vehicles := false
## Array of paths that this path connects to. If more than 1 path is connected, TrafficAgent
## will pick one at random when reaching the end of this path
@export var next_traffic_paths: Array[TrafficPath] = []

@export_group("TrafficAgent Settings")
## The speed limit on this path
@export var path_max_speed := 15.0
## The speed to aim for when reversing on this path
@export var path_reversing_speed := -5.0
## Vehicles will aim to stay this close to this path
@export var path_distance_limit := 2.0

## Length of this path
var path_length: float
## When set to true, vehicles will not move onto this path
var is_blocked := false


func _ready() -> void:
  if Engine.is_editor_hint():
    var entrance_label := Label3D.new()
    entrance_label.text = name
    var _baked_curve_points := curve.get_baked_points()
    entrance_label.position = _baked_curve_points[len(_baked_curve_points) / 2]
    entrance_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    entrance_label.font_size = 180
    add_child(entrance_label)
  else:
    if spawn_vehicles:
      TrafficManager.traffic_paths.push_back(self)
    path_length = curve.get_baked_length()
  return
