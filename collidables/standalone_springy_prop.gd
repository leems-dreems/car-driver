class_name StandaloneSpringyProp extends Node3D

@export var reset_time := 5.0
@export var linear_breaking_point := 0.1
@onready var _bodies: StandalonePropBodies = $StandalonePropBodies
var _bodies_scene := preload("res://collidables/standalone_prop_bodies.tscn")
var reset_timer : SceneTreeTimer = null
var is_detached := false
## Increased by the prop respawn manager when this prop fails a hearing & line-of-sight check
var respawn_weight := 0.0


func _ready() -> void:
  return


func _physics_process(_delta: float) -> void:
  if is_detached:
    if _bodies == null:
      respawn()
    return
  if _bodies and _bodies.rigid_body.global_position.distance_to(global_position) > linear_breaking_point:
    detach()

## Detaches this prop from its anchor
func detach() -> void:
  is_detached = true
  _bodies.is_detached_from_parent = true
  _bodies.rigid_body.gravity_scale = 1
  _bodies.rigid_body.axis_lock_angular_x = false
  _bodies.rigid_body.axis_lock_angular_y = false
  _bodies.rigid_body.axis_lock_angular_z = false
  _bodies.joint.set_flag_x(JoltGeneric6DOFJoint3D.FLAG_ENABLE_LINEAR_LIMIT, false)
  _bodies.joint.set_flag_y(JoltGeneric6DOFJoint3D.FLAG_ENABLE_LINEAR_LIMIT, false)
  _bodies.joint.set_flag_z(JoltGeneric6DOFJoint3D.FLAG_ENABLE_LINEAR_LIMIT, false)
  _bodies.joint.set_flag_x(JoltGeneric6DOFJoint3D.FLAG_ENABLE_LINEAR_SPRING, false)
  _bodies.joint.set_flag_y(JoltGeneric6DOFJoint3D.FLAG_ENABLE_LINEAR_SPRING, false)
  _bodies.joint.set_flag_z(JoltGeneric6DOFJoint3D.FLAG_ENABLE_LINEAR_SPRING, false)
  _bodies.joint.set_flag_x(JoltGeneric6DOFJoint3D.FLAG_ENABLE_ANGULAR_LIMIT, false)
  _bodies.joint.set_flag_y(JoltGeneric6DOFJoint3D.FLAG_ENABLE_ANGULAR_LIMIT, false)
  _bodies.joint.set_flag_z(JoltGeneric6DOFJoint3D.FLAG_ENABLE_ANGULAR_LIMIT, false)
  play_effect()
  PropRespawnManager.waiting_to_respawn.push_back(self)
  return


func despawn() -> void:
  _bodies.queue_free()
  _bodies = null
  respawn_weight = 0.0
  return


func respawn() -> void:
  _bodies = _bodies_scene.instantiate()
  _bodies.position = Vector3.ZERO
  _bodies.rotation = Vector3.ZERO
  add_child(_bodies)
  is_detached = false
  return

## Can be overridden to play effects etc when something collides with [physics_body]
func play_effect() -> void:
  pass


func stop_effect() -> void:
  pass
