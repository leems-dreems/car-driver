class_name CarryableItem extends RigidBody3D

enum ITEM_SIZE { SMALL, MEDIUM, LARGE }
@export var item_name: String
@export var item_size: ITEM_SIZE
@onready var audio_player: AudioStreamPlayer = $AudioStreamPlayer
var is_highlighted := false
const outline_material := preload("res://assets/materials/outline_material_overlay.tres")


func highlight() -> void:
	is_highlighted = true
	$MeshInstance3D.material_overlay = outline_material
	return


func unhighlight() -> void:
	is_highlighted = false
	$MeshInstance3D.material_overlay = null
	return


func get_mesh() -> MeshInstance3D:
	return $MeshInstance3D


func get_collider() -> CollisionShape3D:
	return $CollisionShape3D


func play_pickup_effect() -> void:
	audio_player.seek(0)
	audio_player.play()
	return
