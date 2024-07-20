class_name SpringyProp extends Node3D

@export var reset_time := 5.0
@export var linear_breaking_point := 1.0
@onready var physics_body : RigidBody3D = $RigidBody3D
@onready var joint : Generic6DOFJoint3D = $Generic6DOFJoint3D
var springy_props_manager_node : Node3D
var reset_timer : SceneTreeTimer = null
var is_detached := false

func _ready() -> void:
  if get_parent_node_3d().has_method("add_base_springy_prop"):
    springy_props_manager_node = get_parent_node_3d()
  return

func _physics_process(_delta: float) -> void:
  if is_detached: return
  if physics_body.global_position.distance_to(global_position) > linear_breaking_point:
    detach()

## Detaches this prop from its anchor
func detach() -> void:
  is_detached = true
  physics_body.gravity_scale = 1
  physics_body.axis_lock_angular_x = false
  physics_body.axis_lock_angular_y = false
  physics_body.axis_lock_angular_z = false
  joint.set_flag_x(Generic6DOFJoint3D.FLAG_ENABLE_LINEAR_LIMIT, false)
  joint.set_flag_y(Generic6DOFJoint3D.FLAG_ENABLE_LINEAR_LIMIT, false)
  joint.set_flag_z(Generic6DOFJoint3D.FLAG_ENABLE_LINEAR_LIMIT, false)
  play_effect()
  if reset_timer == null:
    reset_timer = get_tree().create_timer(reset_time)
    await reset_timer.timeout
    springy_props_manager_node.add_base_springy_prop(global_position, global_rotation)
    queue_free()
  return

## Can be overridden to play effects etc when something collides with [physics_body]
func play_effect() -> void:
  pass

func stop_effect() -> void:
  pass
