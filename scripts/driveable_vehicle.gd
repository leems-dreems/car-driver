class_name DriveableVehicle extends Vehicle

var is_being_driven := false
var starting_origin : Vector3
var starting_basis : Basis
var waiting_to_respawn := false

func _ready () -> void:
  super()
  starting_origin = global_position
  starting_basis = Basis(transform.basis)
  $EnterCarCollider.vehicle = self
  return

## Used to reset the position of the car without upsetting the physics engine
func _integrate_forces (state: PhysicsDirectBodyState3D) -> void:
  if waiting_to_respawn:
    freeze = true
    state.transform.origin = starting_origin
    state.transform.basis = starting_basis
    state.linear_velocity = Vector3.ZERO
    state.angular_velocity = Vector3.ZERO
    waiting_to_respawn = false

    await get_tree().create_timer(1.0).timeout
    freeze = false


func respawn () -> void:
  waiting_to_respawn = true
