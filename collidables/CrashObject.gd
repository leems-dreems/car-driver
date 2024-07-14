extends CollisionObject3D

var crashScene: PackedScene
@export var resetTime = 15
var collision_shape_3d: CollisionShape3D
var mesh_instance_3d: MeshInstance3D
var readyToHit: bool = true
var physicsChild : RigidBody3D
var spawnPoint: Vector3

func _ready() -> void:
    var child = get_child(0)
    if child.is_in_group("CrashScene"):
        intializeCrashObject(child)

func intializeCrashObject(child):
    for grandchild in child.get_children():
        if grandchild is MeshInstance3D:
            var mesh = grandchild.duplicate()
            add_child(mesh)
            mesh_instance_3d = mesh
            mesh.global_position = grandchild.global_position
            spawnPoint = grandchild.global_position
        elif grandchild is CollisionShape3D:
            var collision = grandchild.duplicate()
            add_child(collision)
            collision.global_position = grandchild.global_position
            collision_shape_3d = collision
            self.connect("body_entered", _on_body_entered)
    
    for i in range(1,32):
        set_collision_layer_value(i, child.get_collision_layer_value(i))
        set_collision_mask_value(i, child.get_collision_mask_value(i))
        
    crashScene = PackedScene.new()
    crashScene.pack(child)
    child.queue_free()  



func _on_body_entered(body: Node3D) -> void:
    if body.is_in_group("CanCrash") && readyToHit:
        gethit()

func gethit():
    readyToHit = false
    physicsChild = crashScene.instantiate()
    add_child(physicsChild)
    physicsChild.global_position = spawnPoint
    collision_shape_3d.visible = false
    mesh_instance_3d.visible = false
    await get_tree().create_timer(resetTime).timeout
    reset()

func reset():
    readyToHit = true
    collision_shape_3d.visible = true
    mesh_instance_3d.visible = true
    physicsChild.queue_free()
