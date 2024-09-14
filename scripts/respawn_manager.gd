extends Node3D
## Respawns tracked Props if they are off-camera and out of hearing range

## The Camera3D to use for line-of-sight and hearing range checks
var camera: Camera3D
## Props won't be respawned until their `respawn_weight` is greater than this
var respawn_delay: int = 120
## Props within this distance will not be despawned
var hearing_range := 60.0
## List of props that are waiting to respawn
var waiting_to_respawn: Array[StandaloneSpringyProp] = []
## Index of the next prop to attempt to respawn
var prop_check_index: int = 0
## Parameters for line-of-sight checks on physics props
@onready var prop_ray_query_params := PhysicsRayQueryParameters3D.create(Vector3.ZERO, Vector3.ZERO, 64)
## Parameters for line-of-sight checks on prop respawn areas
@onready var respawn_ray_query_params := PhysicsRayQueryParameters3D.create(Vector3.ZERO, Vector3.ZERO, 256)


func _ready() -> void:
  respawn_ray_query_params.collide_with_areas = true

## Loop over one prop each tick, check if it can be seen or heard. Reset its `respawn_weight` if it
## can, and increase the weight if it can't. Once weight reaches a threshold, despawn the prop
func _physics_process(_delta: float) -> void:
  if not camera:
    return
  var prop_count := len(waiting_to_respawn)
  if prop_count == 0:
    return
  if prop_check_index > prop_count - 1:
    prop_check_index = 0

  var prop := waiting_to_respawn[prop_check_index]
  var _can_see_or_hear_prop := false
  if prop._bodies.rigid_body.global_position.distance_to(camera.global_position) < hearing_range:
    _can_see_or_hear_prop = true
  elif camera.is_position_in_frustum(prop._bodies.rigid_body.global_position):
    prop_ray_query_params.from = camera.global_position
    prop_ray_query_params.to = prop._bodies.rigid_body.global_position
    var _space_state := get_world_3d().direct_space_state
    var _raycast_result := _space_state.intersect_ray(prop_ray_query_params)
    if not _raycast_result.is_empty():
      var _collider: RigidBody3D = _raycast_result.collider
      if _collider.get_parent() == prop._bodies:
        _can_see_or_hear_prop = true
  if not _can_see_or_hear_prop and camera.is_position_in_frustum(prop._bodies.respawn_area.global_position):
    respawn_ray_query_params.from = camera.global_position
    respawn_ray_query_params.to = prop._bodies.respawn_area.global_position
    var _space_state := get_world_3d().direct_space_state
    var _raycast_result := _space_state.intersect_ray(respawn_ray_query_params)
    if not _raycast_result.is_empty():
      var _collider: Area3D = _raycast_result.collider
      if _collider.get_parent() == prop._bodies:
        _can_see_or_hear_prop = true
    
  if _can_see_or_hear_prop:
    prop.respawn_weight = 0
    prop_check_index += 1
  else:
    prop.respawn_weight += len(waiting_to_respawn)
    if prop.respawn_weight > respawn_delay:
      prop.despawn()
      waiting_to_respawn.erase(prop)
