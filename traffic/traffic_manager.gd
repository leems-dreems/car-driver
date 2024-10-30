extends Node3D
## TrafficManager is a singleton that spawns and control AI traffic vehicles

const vehicle_scenes: Array[PackedScene] = [
  preload("res://cars/compact/compact.tscn")
  #preload("res://cars/sedan/sedan.tscn")
]
const traffic_spawn_point_scene := preload("res://traffic/traffic_spawn_point.tscn")
const traffic_agent_scene := preload("res://traffic/traffic_agent.tscn")
## How many vehicles to spawn
var vehicle_count: int = 7
## The Camera3D to use for line-of-sight and hearing range checks
var camera: Camera3D
## Area3D node used to look for TrafficSpawnPoints around the camera/player
var spawn_include_area: Area3D
## Smaller Area3D node used to exclude closer spawn points from the include list
var spawn_exclude_area: Area3D
## Node that spawned vehicles will be added to as children
var vehicle_container_node: Node3D
## Vehicles won't be despawned until their `despawn_weight` is greater than this
var despawn_delay: int = 60
## Vehicles within this distance will not be despawned
var hearing_range := 160.0
## Minimum distance from the camera vehicles will be spawned
var min_spawn_radius := 80.0
## Maximum distance from the camera vehicles will be spawned
var max_spawn_radius := 160.0
## TrafficAgents being managed
var _agents: Array[TrafficAgent] = []
## All the TrafficPaths that this manager will consider spawning traffic on
var traffic_paths: Array[TrafficPath] = []
## Distance to move before updating our list of nearby TrafficSpawnPoints
var _spawn_points_update_distance := 80.0
## Global position of the camera the last time we updated the list of nearby TrafficSpawnPoints
var _camera_position_at_last_update := Vector3.INF
## An array of TrafficSpawnPoints within a certain range of distance
var _nearby_spawn_points: Array[TrafficSpawnPoint] = []
## Index of the last path checked from the _nearby_traffic_paths array
var _last_spawn_point_checked: int = -1
## How long to keep skipping a spawn point for after it has been on-camera
var _spawn_point_sighted_delay := 8.0
## Distance in metres between spawn points
var _spawn_point_interval := 20
## Index of the most recent TrafficAgent to be updated
var last_agent_updated: int = 0
## Time elapsed since TrafficManager started. Incremented by the delta of _physics_process each step
var _time_elapsed := 10.0
## Parameters for line-of-sight checks on physics props
@onready var vehicle_ray_query_params := PhysicsRayQueryParameters3D.create(Vector3.ZERO, Vector3.ZERO, 3)
## Parameters for line-of-sight checks on paths
@onready var terrain_ray_query_params := PhysicsRayQueryParameters3D.create(Vector3.ZERO, Vector3.ZERO, 1)


func _physics_process(delta: float) -> void:
  _time_elapsed += delta
  if len(traffic_paths) == 0:
    return
  # Update our list of nearby paths if we've moved since checking last
  if _camera_position_at_last_update.distance_to(camera.global_position) > _spawn_points_update_distance:
    update_nearby_spawn_points()
    return
  if _last_spawn_point_checked >= len(_nearby_spawn_points) - 1:
    _last_spawn_point_checked = 0
  else:
    _last_spawn_point_checked += 1
  var _spawn_point: TrafficSpawnPoint
  if len(_nearby_spawn_points) > 0:
    _spawn_point = _nearby_spawn_points[_last_spawn_point_checked]
    if is_spawn_point_visible(_spawn_point):
      _spawn_point.time_last_seen = _time_elapsed
  if vehicle_count > 0 and len(_agents) < vehicle_count:
    # Sort traffic paths by number of children, descending
    traffic_paths.sort_custom(func(a: TrafficPath, b: TrafficPath):
      return a.get_child_count() < b.get_child_count()
    )
    # Spawn a new traffic agent, and add it to our _agents array
    _agents.push_back(traffic_agent_scene.instantiate())
    return
  else:
    if last_agent_updated >= len(_agents):
      last_agent_updated = 0
    var _traffic_agent = _agents[last_agent_updated]
    if _traffic_agent.vehicle == null:
      # Spawn a new vehicle at the spawn point being checked, if the spawn point has been out of
      # sight for a while and is not colliding with anything
      if _spawn_point and _time_elapsed - _spawn_point.time_last_seen > _spawn_point_sighted_delay:
        if not (is_spawn_point_colliding(_spawn_point)):
          _traffic_agent.add_to_path(_spawn_point.get_parent_node_3d())
          _traffic_agent.progress_ratio = _spawn_point.progress_ratio
          _add_vehicle(_spawn_point, _traffic_agent)
        _spawn_point.highlight()
    elif not _traffic_agent.vehicle.is_being_driven:
      _traffic_agent.set_inputs()
      _adjust_despawn_weight(_traffic_agent)
    last_agent_updated += 1
  return

## Add a vehicle at [_spawn_point] and let it be controlled by [_agent]
func _add_vehicle(_spawn_point: TrafficSpawnPoint, _agent: TrafficAgent) -> void:
  var _new_vehicle: DriveableVehicle = vehicle_scenes.pick_random().instantiate()
  _new_vehicle.position = _spawn_point.global_position
  _new_vehicle.rotation = _spawn_point.global_rotation
  _agent.vehicle = _new_vehicle
  vehicle_container_node.add_child(_agent.vehicle)
  _agent.vehicle._starting_velocity = Vector3.FORWARD.rotated(Vector3.UP, _new_vehicle.rotation.y) * _spawn_point.starting_speed
  _agent.vehicle.start_ai()
  return

## Adjust the despawn weight for this traffic agent, and despawn if it's above the threshold
func _adjust_despawn_weight(_agent: TrafficAgent) -> void:
  var _can_see_or_hear_vehicle := false
  if _agent.vehicle.global_position.distance_to(camera.global_position) < hearing_range:
    _can_see_or_hear_vehicle = true
  elif camera.is_position_in_frustum(_agent.vehicle.global_position):
    vehicle_ray_query_params.from = camera.global_position
    vehicle_ray_query_params.to = _agent.vehicle.global_position
    var _space_state := get_world_3d().direct_space_state
    var _raycast_result := _space_state.intersect_ray(vehicle_ray_query_params)
    if not _raycast_result.is_empty():
      if _raycast_result.collider == _agent.vehicle:
        _can_see_or_hear_vehicle = true
  if _can_see_or_hear_vehicle:
    _agent.despawn_weight = 0
  else:
    _agent.despawn_weight += 1
    if _agent.despawn_weight > despawn_delay:
      _agent.vehicle.despawn()
      _agent.despawn_weight = 0
  return

## Update our array of nearby spawn points, excluding ones that are too close
func update_nearby_spawn_points() -> void:
  if len(_nearby_spawn_points) > 0:
    _camera_position_at_last_update = camera.global_position
  var _spawn_points_to_include := spawn_include_area.get_overlapping_areas()
  var _spawn_points_to_exclude := spawn_exclude_area.get_overlapping_areas()
  var _nearby_spawn_point_areas: Array[Area3D] = _spawn_points_to_include.filter(func(_spawn_point: Area3D):
    return not _spawn_points_to_exclude.has(_spawn_point)
  )
  _nearby_spawn_points = []
  for _nearby_spawn_point_area in _nearby_spawn_point_areas:
    var _spawn_point_to_add: TrafficSpawnPoint = _nearby_spawn_point_area.get_parent_node_3d()
    _nearby_spawn_points.push_back(_nearby_spawn_point_area.get_parent_node_3d())
  _nearby_spawn_points.shuffle()
  _last_spawn_point_checked = 0
  return

## Add TrafficSpawnPoints to managed TrafficPaths
func add_spawn_points() -> void:
  for _traffic_path: TrafficPath in traffic_paths:
    if _traffic_path.get_children().any(func(_child: Node): return _child is TrafficSpawnPoint):
      continue # Skip this path if it already has one or more spawn points
    for _progress_interval in range(floor(_traffic_path.path_length / _spawn_point_interval)):
      var _spawn_point := traffic_spawn_point_scene.instantiate()
      _traffic_path.add_child(_spawn_point)
      _spawn_point.progress = _progress_interval * _spawn_point_interval
      # TODO: Take speed limit of next path into account when setting starting speed
      _spawn_point.starting_speed = _traffic_path.path_max_speed
      if _traffic_path.path_length - _spawn_point.progress < _traffic_path.path_max_speed:
        _spawn_point.starting_speed *= 0.25 # Reduce speed if we are nearly at the end of the path
  return

## Check if a spawn point is colliding with anything
func is_spawn_point_colliding(_traffic_spawn_point: TrafficSpawnPoint) -> bool:
  return _traffic_spawn_point.collision_area.has_overlapping_areas() or _traffic_spawn_point.collision_area.has_overlapping_bodies()

## Check if a spawn point can be seen by the camera
func is_spawn_point_visible(_traffic_spawn_point: TrafficSpawnPoint) -> bool:
  if not camera.is_position_in_frustum(_traffic_spawn_point.global_position):
    return false
  terrain_ray_query_params.from = camera.global_position
  terrain_ray_query_params.to = _traffic_spawn_point.global_position
  var _space_state := get_world_3d().direct_space_state
  var _raycast_result := _space_state.intersect_ray(terrain_ray_query_params)
  return _raycast_result.is_empty()
