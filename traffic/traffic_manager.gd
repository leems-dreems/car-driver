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
var hearing_range := 60.0
var followers: Array[TrafficPathFollower] = []
var traffic_paths: Array[TrafficPath] = []
## Index of the most recent follower to be updated
var last_follower_updated: int = 0
## Parameters for line-of-sight checks on physics props
@onready var vehicle_ray_query_params := PhysicsRayQueryParameters3D.create(Vector3.ZERO, Vector3.ZERO, 2)


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
  var _vehicle_scene: DriveableVehicle = vehicle_scenes.pick_random().instantiate()
  _follower.vehicle = _vehicle_scene
  _follower.vehicle.position = to_local(_follower.global_position)
  _follower.vehicle.rotation = _follower.rotation
  add_child(_follower.vehicle)
  _follower.vehicle.start_ai()


func adjust_respawn_weight(_follower: TrafficPathFollower) -> void:
  var _can_see_or_hear_prop := false
  if _follower.vehicle.global_position.distance_to(camera.global_position) < hearing_range:
    _can_see_or_hear_prop = true
  elif camera.is_position_in_frustum(_follower.vehicle.global_position):
    vehicle_ray_query_params.from = camera.global_position
    vehicle_ray_query_params.to = _follower.vehicle.global_position
    var _space_state := get_world_3d().direct_space_state
    var _raycast_result := _space_state.intersect_ray(vehicle_ray_query_params)
    if not _raycast_result.is_empty():
      var _collider: RigidBody3D = _raycast_result.collider
      if _collider.get_parent() == _follower:
        _can_see_or_hear_prop = true
      
  if _can_see_or_hear_prop:
    _follower.respawn_weight = 0
  else:
    _follower.respawn_weight += 1
    if _follower.respawn_weight > respawn_delay:
      _follower.despawn()
