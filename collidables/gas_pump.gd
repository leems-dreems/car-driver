extends RigidBody3D

@onready var fires: Node3D = $Fires

func _on_body_entered(body: Node) -> void:
    if body.is_in_group("CanCrash"):
        apply_impulse(body.global_transform.basis * 100)

func _ready() -> void:
    emit_fire()

func emit_fire() -> void:
    for fire in fires.get_children():
        fire.emitting = true
