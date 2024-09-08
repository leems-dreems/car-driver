class_name PlayerPhysicalBone extends PhysicalBone3D

var target_linear_velocity := Vector3.ZERO
var target_angular_velocity := Vector3.ZERO
var target_transform: Transform3D
var starting_offset: Transform3D


func _ready() -> void:
  starting_offset = Transform3D(body_offset)


func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
  state.apply_central_force(target_linear_velocity)
  state.angular_velocity += target_angular_velocity
  target_linear_velocity = Vector3.ZERO
  target_angular_velocity = Vector3.ZERO
