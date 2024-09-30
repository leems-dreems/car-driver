extends Node3D
## Spawns and despawns pedestrian NPCs around the camera

const pedestrian_spawn_point_scene := preload("res://npcs/pedestrian_spawn_point.tscn")
const pedestrian_scene := preload("res://npcs/pedestrian.tscn")
const pedestrian_agent_scene := preload("res://npcs/pedestrian_agent.tscn")
## How many pedestrians to spawn
var pedestrian_count: int = 2
## The Camera3D to use for line-of-sight and hearing range checks
var camera: Camera3D
## Area3D node used to look for PedestrianSpawnPoints around the camera/player
var spawn_include_area: Area3D
## Node that spawned pedestrians will be added to as children
var pedestrian_container_node: Node3D
## Pedestrians won't be despawned until their `despawn_weight` is greater than this
var despawn_delay: int = 600
## Pedestrians within this distance will not be despawned
var hearing_range := 20.0
## Minimum distance from the camera pedestrians will be spawned
var min_spawn_radius := 20.0
## Maximum distance from the camera pedestrians will be spawned
var max_spawn_radius := 160.0
## PedestrianAgents being managed
var _agents: Array[PedestrianAgent] = []
## All the PedestrianPaths that this manager will consider spawning pedestrians on
var pedestrian_paths: Array[PedestrianPath] = []
## Distance to move before updating our list of nearby PedestrianSpawnPoints
var _spawn_points_update_distance := 80.0
## Global position of the camera the last time we updated the list of nearby PedestrianSpawnPoints
var _camera_position_at_last_update := Vector3.INF
## An array of PedestrianSpawnPoints within a certain range of distance
var _nearby_spawn_points: Array[PedestrianSpawnPoint] = []
## Index of the last path checked from the _nearby_pedestrian_paths array
var _last_spawn_point_checked: int = -1
## How long to keep skipping a spawn point for after it has been on-camera
var _spawn_point_sighted_delay := 8.0
## Distance in metres between spawn points
var _spawn_point_interval := 20
## Maximum number of pedestrians that have active ragdoll enabled at one time
var _active_ragdoll_count: int = 2
## Interval at which to turn active ragdolls on/off based on pedestrian distance
var _active_ragdoll_check_interval := 1.0
## Time that the active ragdoll check was last carried out
var _time_since_active_ragdoll_check := 1.0
## Index of the most recent PedestrianAgent to be updated
var last_agent_updated: int = 0
## Time elapsed since PedestrianManager started. Incremented by the delta of _physics_process each step
var _time_elapsed := 10.0
## Parameters for line-of-sight checks on physics props
@onready var pedestrian_ray_query_params := PhysicsRayQueryParameters3D.create(Vector3.ZERO, Vector3.ZERO, 17)
## Parameters for line-of-sight checks on paths
@onready var terrain_ray_query_params := PhysicsRayQueryParameters3D.create(Vector3.ZERO, Vector3.ZERO, 1)


func _physics_process(delta: float) -> void:
  _time_elapsed += delta
  _time_since_active_ragdoll_check += delta
  if len(pedestrian_paths) == 0:
    return
  # If enough time has passed, sort pedestrians by distance and turn active ragdolls on/off
  if _time_since_active_ragdoll_check > _active_ragdoll_check_interval:
    # TODO: Attach distance to each pedestrian in this map loop
    var _pedestrians := _agents.map(func(_agent: PedestrianAgent) -> Pedestrian:
      return _agent.pedestrian
    )
    _pedestrians.sort_custom(func(a: Pedestrian, b: Pedestrian):
      if a == null: return true
      if b == null: return false
      return a.global_position.distance_squared_to(camera.global_position) < b.global_position.distance_squared_to(camera.global_position)
    )
    
  # Update our list of nearby paths if we've moved since checking last
  if _camera_position_at_last_update.distance_to(camera.global_position) > _spawn_points_update_distance:
    update_nearby_spawn_points()
    return
  if _last_spawn_point_checked >= len(_nearby_spawn_points) - 1:
    _last_spawn_point_checked = 0
  else:
    _last_spawn_point_checked += 1
  var _spawn_point: PedestrianSpawnPoint
  if len(_nearby_spawn_points) > 0:
    _spawn_point = _nearby_spawn_points[_last_spawn_point_checked]
    if is_spawn_point_visible(_spawn_point):
      _spawn_point.time_last_seen = _time_elapsed
  if pedestrian_count > 0 and len(_agents) < pedestrian_count:
    # Sort pedestrian paths by number of children, descending
    pedestrian_paths.sort_custom(func(a: PedestrianPath, b: PedestrianPath):
      return a.get_child_count() < b.get_child_count()
    )
    # Spawn a new pedestrian agent, and add it to our _agents array
    _agents.push_back(pedestrian_agent_scene.instantiate())
    return
  else:
    if last_agent_updated >= len(_agents):
      last_agent_updated = 0
    var _pedestrian_agent = _agents[last_agent_updated]
    if _pedestrian_agent.pedestrian == null:
      # Spawn a new pedestrian at the spawn point being checked, if the spawn point has been out of
      # sight for a while and is not colliding with anything
      if _spawn_point and _time_elapsed - _spawn_point.time_last_seen > _spawn_point_sighted_delay:
        if not (is_spawn_point_colliding(_spawn_point)):
          _pedestrian_agent.add_to_path(_spawn_point.get_parent_node_3d())
          _pedestrian_agent.progress_ratio = _spawn_point.progress_ratio
          _add_pedestrian(_spawn_point, _pedestrian_agent)
        _spawn_point.highlight()
    else:
      _pedestrian_agent.set_nav_target()
      _adjust_despawn_weight(_pedestrian_agent)
    last_agent_updated += 1
  return

## Add a pedestrian at [_spawn_point] and let it be controlled by [_agent]
func _add_pedestrian(_spawn_point: PedestrianSpawnPoint, _agent: PedestrianAgent) -> void:
  var _new_pedestrian: Pedestrian = pedestrian_scene.instantiate()
  _new_pedestrian.position = _spawn_point.global_position
  #_new_pedestrian.rotation = _spawn_point.global_rotation
  _agent.pedestrian = _new_pedestrian
  pedestrian_container_node.add_child(_agent.pedestrian)
  _agent.pedestrian._starting_velocity = Vector3.FORWARD.rotated(Vector3.UP, _new_pedestrian.rotation.y) * _spawn_point.starting_speed
  return

## Adjust the despawn weight for this pedestrian agent, and despawn if it's above the threshold
func _adjust_despawn_weight(_agent: PedestrianAgent) -> void:
  var _can_see_or_hear := false
  if _agent.pedestrian.global_position.distance_to(camera.global_position) < hearing_range:
    _can_see_or_hear = true
  elif camera.is_position_in_frustum(_agent.pedestrian.global_position):
    pedestrian_ray_query_params.from = camera.global_position
    pedestrian_ray_query_params.to = _agent.pedestrian.global_position
    pedestrian_ray_query_params.to.y += 1.5
    var _space_state := get_world_3d().direct_space_state
    var _raycast_result := _space_state.intersect_ray(pedestrian_ray_query_params)
    if not _raycast_result.is_empty():
      if _raycast_result.collider == _agent.pedestrian:
        _can_see_or_hear = true
  if _can_see_or_hear:
    _agent.despawn_weight = 0
  else:
    _agent.despawn_weight += 1
    if _agent.despawn_weight > despawn_delay:
      _agent.pedestrian.despawn()
      _agent.despawn_weight = 0
  return

## Update our array of nearby spawn points, excluding ones that are too close
func update_nearby_spawn_points() -> void:
  if len(_nearby_spawn_points) > 0:
    _camera_position_at_last_update = camera.global_position
  var _spawn_points_to_include := spawn_include_area.get_overlapping_areas()
  var _nearby_spawn_point_areas: Array[Area3D] = _spawn_points_to_include.filter(func(_spawn_point: Area3D):
    return camera.global_position.distance_to(_spawn_point.global_position) > min_spawn_radius
  )
  _nearby_spawn_points = []
  for _nearby_spawn_point_area in _nearby_spawn_point_areas:
    var _spawn_point_to_add: PedestrianSpawnPoint = _nearby_spawn_point_area.get_parent_node_3d()
    _nearby_spawn_points.push_back(_nearby_spawn_point_area.get_parent_node_3d())
  _nearby_spawn_points.shuffle()
  _last_spawn_point_checked = 0
  return

## Add PedestrianSpawnPoints to managed PedestrianPaths
func add_spawn_points() -> void:
  for _pedestrian_path: PedestrianPath in pedestrian_paths:
    if _pedestrian_path.get_children().any(func(_child: Node): return _child is PedestrianSpawnPoint):
      continue # Skip this path if it already has one or more spawn points
    for _progress_interval in range(floor(_pedestrian_path.path_length / _spawn_point_interval)):
      var _spawn_point := pedestrian_spawn_point_scene.instantiate()
      _pedestrian_path.add_child(_spawn_point)
      _spawn_point.progress = _progress_interval * _spawn_point_interval
  return

## Check if a spawn point is colliding with anything
func is_spawn_point_colliding(_pedestrian_spawn_point: PedestrianSpawnPoint) -> bool:
  return _pedestrian_spawn_point.collision_area.has_overlapping_areas() or _pedestrian_spawn_point.collision_area.has_overlapping_bodies()

## Check if a spawn point can be seen by the camera
func is_spawn_point_visible(_pedestrian_spawn_point: PedestrianSpawnPoint) -> bool:
  if not camera.is_position_in_frustum(_pedestrian_spawn_point.global_position):
    return false
  terrain_ray_query_params.from = camera.global_position
  terrain_ray_query_params.to = _pedestrian_spawn_point.global_position
  var _space_state := get_world_3d().direct_space_state
  var _raycast_result := _space_state.intersect_ray(terrain_ray_query_params)
  return _raycast_result.is_empty()
