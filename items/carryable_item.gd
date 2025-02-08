class_name CarryableItem extends RigidBody3D

@export var item_name: String
var is_highlighted := false


func highlight() -> void:
	$AnimationPlayer.play("highlight")
	is_highlighted = true
	return


func unhighlight() -> void:
	$AnimationPlayer.play("un_highlight")
	is_highlighted = false
	return


func get_mesh() -> MeshInstance3D:
	return $MeshInstance3D


func get_collider() -> CollisionShape3D:
	return $CollisionShape3D
