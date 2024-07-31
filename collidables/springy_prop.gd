class_name SpringyProp extends Node3D

@export var reset_time := 5.0
@export var linear_breaking_point := 0.1
@onready var physics_body : RigidBody3D = $RigidBody3D
@onready var joint : Generic6DOFJoint3D = $Generic6DOFJoint3D
var springy_props_manager_node : Node3D = null
var reset_timer : SceneTreeTimer = null
var is_detached := false

func _ready() -> void:
  var com_marker: Marker3D = get_node("CenterOfMassMarker")
  if com_marker:
    physics_body.center_of_mass_mode = RigidBody3D.CENTER_OF_MASS_MODE_CUSTOM
    physics_body.center_of_mass = com_marker.position
  physics_body.gravity_scale = 0
  register_scene_with_manager()
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
    respawn()
    queue_free()
  return

## This method should be overridden. Add a new method and scene preload var to
## [SpringyPropsManager] for new props, then replace the method name in the example function here.
func register_scene_with_manager() -> void:
  if get_parent_node_3d().has_method("add_base_springy_prop"):
    springy_props_manager_node = get_parent_node_3d()
  return

## This method should also be overridden to call the method defined above.
func respawn() -> void:
  if springy_props_manager_node != null:
    springy_props_manager_node.add_base_springy_prop(global_position, global_rotation)

## Can be overridden to play effects etc when something collides with [physics_body]
func play_effect() -> void:
  pass

func stop_effect() -> void:
  pass
