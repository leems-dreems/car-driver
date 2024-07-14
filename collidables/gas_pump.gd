extends RigidBody3D

func _on_body_entered(body: Node) -> void:
    if body.is_in_group("CanCrash"):
        apply_impulse(body.global_transform.basis * 100)
