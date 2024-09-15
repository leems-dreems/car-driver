extends Node3D
## TrafficManager is a singleton that spawns and control AI traffic vehicles

const vehicle_scenes: Array[PackedScene] = [
  preload("res://cars/compact/compact.tscn"),
  preload("res://cars/sedan/sedan.tscn")
]
## How many vehicles to spawn
@export var vehicle_count: int = 10
## The Camera3D to use for line-of-sight and hearing range checks
var camera: Camera3D
## Vehicles won't be respawned until their `respawn_weight` is greater than this
var respawn_delay: int = 12
## Vehicles within this distance will not be despawned
var hearing_range := 160.0
## Minimum distance from the camera vehicles will be spawned
var min_spawn_radius := 80.0
## Maximum distance from the camera vehicles will be spawned
var max_spawn_radius := 160.0 
var _agents: Array[TrafficAgent] = []
var _traffic_paths: Array[TrafficPath] = []
## Index of the most recent follower to be updated
var last_follower_updated: int = 0
## Parameters for line-of-sight checks on physics props
@onready var vehicle_ray_query_params := PhysicsRayQueryParameters3D.create(Vector3.ZERO, Vector3.ZERO, 3)
## Parameters for line-of-sight checks on paths
@onready var terrain_ray_query_params := PhysicsRayQueryParameters3D.create(Vector3.ZERO, Vector3.ZERO, 1)
## Used to check possible spawn positions on TrafficPaths
@onready var path_follower := PathFollow3D.new()


func _physics_process(_delta: float) -> void:
  if len(_traffic_paths) == 0:
    return
  if vehicle_count > 0 and len(_agents) < vehicle_count:
    # Sort traffic paths by number of children, descending
    _traffic_paths.sort_custom(func(a: TrafficPath, b: TrafficPath):
      return a.get_child_count() < b.get_child_count()
    )
    # Spawn a new follower, and add it to our _agents array
    _agents.push_back(_traffic_paths[0].spawn_follower())
    return
  else:
    if last_follower_updated >= len(_agents):
      last_follower_updated = 0

    var _follower = _agents[last_follower_updated]
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


func _add_vehicle(_follower: TrafficAgent) -> void:
  var _vehicle_scene: DriveableVehicle = vehicle_scenes.pick_random().instantiate()
  _follower.vehicle = _vehicle_scene
  _follower.vehicle.position = to_local(_follower.global_position)
  _follower.vehicle.rotation = _follower.rotation
  add_child(_follower.vehicle)
  _follower.vehicle.start_ai()


func adjust_respawn_weight(_follower: TrafficAgent) -> void:
  var _can_see_or_hear_vehicle := false
  if _follower.vehicle.global_position.distance_to(camera.global_position) < hearing_range:
    _can_see_or_hear_vehicle = true
  elif camera.is_position_in_frustum(_follower.vehicle.global_position):
    vehicle_ray_query_params.from = camera.global_position
    vehicle_ray_query_params.to = _follower.vehicle.global_position
    var _space_state := get_world_3d().direct_space_state
    var _raycast_result := _space_state.intersect_ray(vehicle_ray_query_params)
    if not _raycast_result.is_empty():
      var _collider: RigidBody3D = _raycast_result.collider
      if _collider.get_parent() == _follower:
        _can_see_or_hear_vehicle = true
  if _can_see_or_hear_vehicle:
    _follower.respawn_weight = 0
  else:
    _follower.respawn_weight += 1
    if _follower.respawn_weight > respawn_delay:
      _follower.despawn()

## Check a few random positions along the path to see if a vehicle can be spawned there. If a valid
## spawn position is found, return the PathFollow3D's `progress` value, or -1 if none found
func find_spawn_point_on_path(_traffic_path: TrafficPath) -> float:
  if path_follower.is_inside_tree():
    path_follower.get_parent_node_3d().remove_child(path_follower)
  _traffic_path.add_child(path_follower)
  for _progress_range in [[0, 20], [20, 40], [40, 60], [60, 80], [80, 100]]:
    path_follower.progress = randf_range(_progress_range[0], _progress_range[1])
    if check_spawn_position_is_valid(path_follower.global_position):
      return path_follower.progress
  return -1

## Check if a position is out of sight and within a certain range of distance from the camera
func check_spawn_position_is_valid(_spawn_position: Vector3) -> bool:
  var _camera_distance := camera.global_position.distance_to(_spawn_position)
  if _camera_distance < min_spawn_radius or _camera_distance > max_spawn_radius:
    return false
  if not camera.is_position_in_frustum(_spawn_position):
    return true
  terrain_ray_query_params.from = camera.global_position
  terrain_ray_query_params.to = _spawn_position
  var _space_state := get_world_3d().direct_space_state
  var _raycast_result := _space_state.intersect_ray(terrain_ray_query_params)
  if _raycast_result.is_empty():
    return true
  return false
