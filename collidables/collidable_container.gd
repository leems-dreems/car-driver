## An item container that is itself a physics object. May be a child of a StandalonePropBodies node.
class_name RigidBinContainer extends RigidBody3D

@export var container_name := "container"
@export var short_press_verb := "interact with"
@export var long_press_verb := "interact with"
var is_highlighted := false
var contained_items := {}
var total_count: int = 0
const outline_material := preload("res://assets/materials/outline_material_overlay.tres")
const bin_bag_scene := preload("res://items/medium/bin_bag.tscn")
var label_show_timer: SceneTreeTimer = null
const label_show_duration := 3.0
@onready var label: Label3D = $Label3D
@onready var _mesh_instance: MeshInstance3D = $MeshInstance3D


func highlight() -> void:
	is_highlighted = true
	_mesh_instance.material_overlay = outline_material
	return


func unhighlight() -> void:
	is_highlighted = false
	_mesh_instance.material_overlay = null
	return


func can_deposit_item(_item: CarryableItem) -> bool:
	match _item.item_size:
		CarryableItem.ITEM_SIZE.SMALL: return true
		_: return false


func deposit_item(_item: CarryableItem) -> void:
	if not contained_items.has(_item.item_name):
		contained_items[_item.item_name] = 0
	contained_items[_item.item_name] += 1
	
	total_count = 0
	for _key in contained_items.keys():
		total_count += contained_items[_key]
	
	label.text = ""
	var i: int = 0
	for _key in contained_items.keys():
		if i > 0:
			label.text += "\n"
		label.text += _key + ": " + str(contained_items[_key])
		i += 1
	label.text += "\nTotal: " + str(total_count)
	return

## Checks if this container is a valid target for emptying
func can_be_emptied() -> bool:
	return total_count > 0
