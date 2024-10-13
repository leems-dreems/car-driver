class_name TrafficLightBodies extends StandalonePropBodies

var light_fade_time := 0.2
## Velocity as of the last physics tick
var _previous_velocity: Vector3 = Vector3.ZERO
@onready var _head_rigid_body := $Head
@onready var _pole_rigid_body := $RigidBody3D


func _physics_process(_delta: float) -> void:
  _previous_velocity = Vector3(_head_rigid_body.linear_velocity)
  return


func no_lights() -> void:
  var _tween = get_tree().create_tween()
  _tween.parallel().tween_property($Head/GreenLight/MeshInstance3D, "transparency", 1.0, light_fade_time)
  _tween.parallel().tween_property($Head/RedLight/MeshInstance3D, "transparency", 1.0, light_fade_time)
  return


func green_light() -> void:
  var _tween = get_tree().create_tween()
  _tween.parallel().tween_property($Head/GreenLight/MeshInstance3D, "transparency", 0.0, light_fade_time)
  _tween.parallel().tween_property($Head/RedLight/MeshInstance3D, "transparency", 1.0, light_fade_time)
  return


func red_light() -> void:
  var _tween = get_tree().create_tween()
  _tween.parallel().tween_property($Head/GreenLight/MeshInstance3D, "transparency", 1.0, light_fade_time)
  _tween.parallel().tween_property($Head/RedLight/MeshInstance3D, "transparency", 0.0, light_fade_time)
  return


func prepare_to_break_apart() -> void:
  _head_rigid_body.connect("body_entered", break_if_hit_hard)
  _pole_rigid_body.connect("body_entered", break_if_hit_hard)
  return


func break_if_hit_hard(_node: Node) -> void:
  var _impact_force: float = (_previous_velocity - _head_rigid_body.linear_velocity).length() * 0.1
  if _impact_force > 0.5:
    break_apart()
  return


func break_apart() -> void:
  _head_rigid_body.disconnect("body_entered", break_if_hit_hard)
  _pole_rigid_body.disconnect("body_entered", break_if_hit_hard)
  $HeadJoltGeneric6DOFJoint3D.set_flag_x(JoltGeneric6DOFJoint3D.FLAG_ENABLE_ANGULAR_LIMIT, false)
  $HeadJoltGeneric6DOFJoint3D.set_flag_y(JoltGeneric6DOFJoint3D.FLAG_ENABLE_ANGULAR_LIMIT, false)
  $HeadJoltGeneric6DOFJoint3D.set_flag_z(JoltGeneric6DOFJoint3D.FLAG_ENABLE_ANGULAR_LIMIT, false)
  $HeadJoltGeneric6DOFJoint3D.set_flag_x(JoltGeneric6DOFJoint3D.FLAG_ENABLE_LINEAR_LIMIT, false)
  $HeadJoltGeneric6DOFJoint3D.set_flag_y(JoltGeneric6DOFJoint3D.FLAG_ENABLE_LINEAR_LIMIT, false)
  $HeadJoltGeneric6DOFJoint3D.set_flag_z(JoltGeneric6DOFJoint3D.FLAG_ENABLE_LINEAR_LIMIT, false)
  return
