@tool
class_name TrafficPath extends Path3D
## Supports [TrafficPathFollower] nodes, which spawn & control AI-driven vehicles

var traffic_follower_scene := preload("res://traffic/traffic_path_follower.tscn")

@export_group("Path Settings")
## If true, TrafficManager will spawn vehicles on this path
@export var spawn_vehicles := false
## The maximum number of vehicles that this path can support at a time
@export var number_of_vehicles := 1
## Array of paths that this path connects to. If more than 1 path is connected, TrafficPathFollower 
## will pick one at random when reaching the end of this path
@export var next_traffic_paths: Array[TrafficPath] = []

@export_group("Follower Settings")
## The speed limit on this path
@export var path_max_speed := 15.0
## The speed to aim for when reversing on this path
@export var path_reversing_speed := -5.0
## Vehicles will aim to stay this close to this path
@export var path_distance_limit := 2.0
## Vehicles on this path will display their inputs above themselves
@export var show_vehicle_inputs := false

## Follower nodes currently assigned to this TrafficPath
var followers: Array[TrafficPathFollower] = []
## Index of the last vehicle that this TrafficPath processed avoidance & inputs for
var last_follower_updated_index := -1
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
  path_length = curve.get_baked_length()
  for _child in get_children():
    if _child is TrafficPathFollower:
      followers.push_back(_child)
  return


func spawn_follower(vehicle_container: Node3D = null) -> TrafficPathFollower:
  var _follower: TrafficPathFollower = traffic_follower_scene.instantiate()
  _follower.copy_path_settings(self)
  followers.push_back(_follower)
  add_child(_follower)
  return _follower
