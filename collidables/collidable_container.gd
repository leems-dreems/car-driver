## An item container that is itself a physics object. May be a child of a StandalonePropBodies node.
class_name CollidableContainer extends RigidBody3D

@export var container_name := "container"
var is_highlighted := false
var _prop_bodies: StandalonePropBodies
var _contained_items := {}
var _label: Label3D = null
const outline_material := preload("res://assets/materials/outline_material_overlay.tres")
@onready var _mesh_instance: MeshInstance3D = $MeshInstance3D


func _ready() -> void:
	await owner.ready
	_prop_bodies = owner as StandalonePropBodies
	_label = find_child("Label3D")
	return


func _physics_process(delta: float) -> void:
	if _prop_bodies and not _prop_bodies.is_detached_from_parent:
		return
	return


func highlight() -> void:
	is_highlighted = true
	_mesh_instance.material_overlay = outline_material
	return


func unhighlight() -> void:
	is_highlighted = false
	_mesh_instance.material_overlay = null
	return


func deposit_item(_item: CarryableItem) -> void:
	if not _contained_items.has(_item.item_name):
		_contained_items[_item.item_name] = 0
	_contained_items[_item.item_name] += 1
	_label.text = ""
	var i: int = 0
	for _key in _contained_items.keys():
		if i > 0:
			_label.text += "\n"
		_label.text += _key + ": " + str(_contained_items[_key])
	return
