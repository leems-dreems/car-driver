class_name TrafficManager extends Node3D

var compact_car_scene := preload("res://cars/compact.tscn")

@export var vehicle_count: int = 10             ## How many vehicles to spawn
var followers: Array[TrafficPathFollower] = []
var traffic_paths: Array[TrafficPath] = []
var last_follower_updated: int = 0              ## Index of the most recent follower to be updated


func _ready() -> void:
  await get_tree().create_timer(1.0).timeout
  for _traffic_path: TrafficPath in get_tree().current_scene.find_children("*", "TrafficPath"):
    if _traffic_path.spawn_vehicles:
      traffic_paths.push_back(_traffic_path)
  return


func _physics_process(_delta: float) -> void:
  if len(traffic_paths) == 0:
    return
  if vehicle_count > 0 and len(followers) < vehicle_count:
    # Sort traffic paths by number of children, descending
    traffic_paths.sort_custom(func(a: TrafficPath, b: TrafficPath):
      return a.get_child_count() < b.get_child_count()
    )
    # Spawn a new follower, and add it to our followers array
    followers.push_back(traffic_paths[0].spawn_follower())
    return
  else:
    if last_follower_updated >= len(followers):
      last_follower_updated = 0

    var _follower = followers[last_follower_updated]
    if _follower.vehicle == null:
      # If this follower's collision Area3D isn't overlapping anything else, spawn a vehicle
      if _follower.collision_area.has_overlapping_areas() or _follower.collision_area.has_overlapping_bodies():
        _follower.progress_ratio = randf_range(0, 1) # Move follower to a random position on the path
      else:
        _add_vehicle(_follower)
    elif not _follower.vehicle.is_being_driven:
      _follower.set_inputs()

    last_follower_updated += 1
  return


func _add_vehicle(_follower: TrafficPathFollower) -> void:
  _follower.vehicle = compact_car_scene.instantiate()
  _follower.vehicle.position = to_local(_follower.global_position)
  _follower.vehicle.rotation = _follower.rotation
  add_child(_follower.vehicle)
  _follower.vehicle.start_ai()
