extends DetachableProp

@onready var fires: Node3D = $RigidBody3D/Fires


func play_effect(body: Node3D) -> void:
  if body.is_in_group("CanCrash"):
    physics_body.apply_central_impulse(Vector3.UP * 100)
    for fire in fires.get_children():
      fire.emitting = true


func stop_effect() -> void:
  for fire in fires.get_children():
    fire.emitting = false
