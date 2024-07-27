class_name DriveableVehicle extends Vehicle

var is_being_driven := false
var starting_origin: Vector3
var starting_basis: Basis
var waiting_to_respawn := false
@onready var door_left: RigidBody3D = $ColliderBits/OpenDoorLeft
@onready var door_right: RigidBody3D = $ColliderBits/OpenDoorRight


func _ready () -> void:
  super()
  starting_origin = global_position
  starting_basis = Basis(transform.basis)
  $ColliderBits/EnterCarCollider.vehicle = self
  await get_tree().create_timer(0.2).timeout
  unfreeze_bodies()
  return

## Used to reset the position of the car without upsetting the physics engine
func _integrate_forces (state: PhysicsDirectBodyState3D) -> void:
  if waiting_to_respawn:
    freeze_bodies()
    state.transform.origin = starting_origin
    state.transform.basis = starting_basis
    state.linear_velocity = Vector3.ZERO
    state.angular_velocity = Vector3.ZERO
    waiting_to_respawn = false

    await get_tree().create_timer(1.0).timeout
    unfreeze_bodies()


func respawn () -> void:
  waiting_to_respawn = true


func freeze_bodies() -> void:
  freeze = true
  door_left.top_level = false
  door_left.freeze = true
  door_right.top_level = false
  door_right.freeze = true


func unfreeze_bodies() -> void:
  freeze = false
  door_left.top_level = true
  door_left.freeze = false
  door_right.top_level = true
  door_right.freeze = false
