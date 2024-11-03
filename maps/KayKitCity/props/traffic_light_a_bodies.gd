class_name TrafficLightBodies extends StandalonePropBodies

var light_fade_time := 0.2
var make_noise_force := 0.1
var break_apart_force := 0.5
var has_broken_apart := false
## Velocity as of the last physics tick
var _previous_velocity: Vector3 = Vector3.ZERO
@onready var _head_rigid_body := $Head
@onready var _pole_rigid_body := $RigidBody3D
@onready var _head_pole_joint := $HeadJoltGeneric6DOFJoint3D
@onready var snap_audio := $SnapOffAudio
@onready var head_impact_audio := $Head/MetalImpactAudio
@onready var pole_impact_audio := $RigidBody3D/MetalImpactAudio


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
  snap_audio.play()
  _head_rigid_body.connect("body_entered", react_to_head_impact)
  _pole_rigid_body.connect("body_entered", react_to_pole_impact)
  return


func react_to_head_impact(_node: Node) -> void:
  var _impact_force: float = (_previous_velocity - _head_rigid_body.linear_velocity).length_squared()
  if _impact_force > make_noise_force:
    print(_impact_force)
    head_impact_audio.unit_size = clampf(_impact_force * 0.5, 0.01, 2)
    head_impact_audio.play()
  if _impact_force > break_apart_force:
    if not has_broken_apart:
      break_apart()
  return


func react_to_pole_impact(_node: Node) -> void:
  var _impact_force: float = (_previous_velocity - _head_rigid_body.linear_velocity).length_squared()
  if _impact_force > make_noise_force:
    pole_impact_audio.unit_size = clampf(_impact_force * 0.5, 0.01, 2)
    pole_impact_audio.play()
  if _impact_force > break_apart_force:
    if not has_broken_apart:
      break_apart()
  return


func break_apart() -> void:
  has_broken_apart = true
  _head_pole_joint.set_flag_x(JoltGeneric6DOFJoint3D.FLAG_ENABLE_ANGULAR_LIMIT, false)
  _head_pole_joint.set_flag_y(JoltGeneric6DOFJoint3D.FLAG_ENABLE_ANGULAR_LIMIT, false)
  _head_pole_joint.set_flag_z(JoltGeneric6DOFJoint3D.FLAG_ENABLE_ANGULAR_LIMIT, false)
  _head_pole_joint.set_flag_x(JoltGeneric6DOFJoint3D.FLAG_ENABLE_LINEAR_LIMIT, false)
  _head_pole_joint.set_flag_y(JoltGeneric6DOFJoint3D.FLAG_ENABLE_LINEAR_LIMIT, false)
  _head_pole_joint.set_flag_z(JoltGeneric6DOFJoint3D.FLAG_ENABLE_LINEAR_LIMIT, false)
  return
