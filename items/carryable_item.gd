class_name CarryableItem extends RigidBody3D

enum ITEM_SIZE { SMALL, MEDIUM, LARGE }
@export var item_name: String
@export var item_size: ITEM_SIZE
@onready var audio_player: AudioStreamPlayer = $AudioStreamPlayer
var is_highlighted := false
## The container this item is currently in, if any
var container_node: Node3D = null
var _default_collision_layer: int
var _default_collision_mask: int
const outline_material := preload("res://assets/materials/outline_material_overlay.tres")


func _init() -> void:
	_default_collision_layer = collision_layer
	_default_collision_mask = collision_mask
	return


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
