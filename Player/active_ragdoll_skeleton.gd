extends Skeleton3D

@export var target_skeleton: Skeleton3D

@export var linear_spring_stiffness: float = 500.0
@export var linear_spring_damping: float = 40.0
@export var max_linear_force: float = 1000.0

@export var angular_spring_stiffness: float = 5000.0
@export var angular_spring_damping: float = 80.0
@export var max_angular_force: float = 1000.0

var physics_bones: Array[PhysicalBone3D]


func _ready() -> void:
  for _bone: PhysicalBone3D in find_children("*", "PhysicalBone3D"):
    physics_bones.push_back(_bone)
  #physical_bone_simulator = find_child("PhysicalBoneSimulator3D")
  return


func _physics_process(delta: float) -> void:
  #if not is_simulating_physics():
    #return

  for b in physics_bones:
    var _target_bone_transform := target_skeleton.get_bone_global_pose(b.get_bone_id())
    var target_transform: Transform3D = target_skeleton.global_transform * _target_bone_transform

    var current_transform: Transform3D = global_transform * get_bone_global_pose(b.get_bone_id())

    var rotation_difference: Basis = (target_transform.basis * current_transform.basis.inverse())
    var position_difference: Vector3 = target_transform.origin - current_transform.origin

    #if position_difference.length_squared() > 1.0:
      #b.global_position = target_transform.origin
    #else:
    var force: Vector3 = hookes_law(position_difference, b.linear_velocity, linear_spring_stiffness, linear_spring_damping)
    force = force.limit_length(max_linear_force)
    b.target_linear_velocity = force

    var torque = hookes_law(rotation_difference.get_euler(), b.angular_velocity, angular_spring_stiffness, angular_spring_damping)
    torque = torque.limit_length(max_angular_force)
    b.target_angular_velocity = torque * delta

    b.target_transform = target_transform
  return


func hookes_law(displacement: Vector3, current_velocity: Vector3, stiffness: float, damping: float) -> Vector3:
  return (stiffness * displacement) - (damping * current_velocity)