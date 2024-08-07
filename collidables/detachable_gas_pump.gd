extends DetachableProp

@export var explosion_impulse := 5.0
@onready var fires: Node3D = $RigidBody3D/Fires


func play_effect(body: Node3D) -> void:
  if body.is_in_group("CanCrash"):
    physics_body.apply_central_impulse(Vector3.UP * explosion_impulse * physics_body.mass)
    for fire in fires.get_children():
      fire.emitting = true


func stop_effect() -> void:
  for fire in fires.get_children():
    fire.emitting = false
