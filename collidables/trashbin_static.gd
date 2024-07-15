extends Area3D

@export var resetTime = 15
@export var physicsBin: PackedScene
@onready var collision_shape_3d: CollisionShape3D = $CollisionShape3D
@onready var mesh_instance_3d: MeshInstance3D = $MeshInstance3D
var readyToHit: bool = true
var physicsChild : RigidBody3D

func _on_body_entered(body: Node3D) -> void:
    if body.is_in_group("CanCrash") && readyToHit:
        gethit()

func gethit():
    readyToHit = false
    physicsChild = physicsBin.instantiate()
    add_child(physicsChild)
    physicsChild.global_position = global_position
    collision_shape_3d.visible = false
    mesh_instance_3d.visible = false
    await get_tree().create_timer(resetTime).timeout
    reset()

func reset():
    readyToHit = true
    collision_shape_3d.visible = true
    mesh_instance_3d.visible = true
    physicsChild.queue_free()
