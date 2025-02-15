class_name CarryableItem extends RigidBody3D

enum ITEM_SIZE { SMALL, MEDIUM, LARGE }
@export var item_name: String
@export var item_size: ITEM_SIZE
var is_highlighted := false
const outline_material := preload("res://assets/materials/outline_material_overlay.tres")


func highlight() -> void:
	$MeshInstance3D.material_overlay = outline_material
	return


func unhighlight() -> void:
	$MeshInstance3D.material_overlay = null
	return


func get_mesh() -> MeshInstance3D:
	return $MeshInstance3D


func get_collider() -> CollisionShape3D:
	return $CollisionShape3D
