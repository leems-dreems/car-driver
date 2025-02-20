## An item container that is itself a physics object. May be a child of a StandalonePropBodies node.
class_name RigidBinContainer extends RigidBody3D

@export var container_name := "container"
var is_highlighted := false
var contained_items := {}
var total_count: int = 0
const outline_material := preload("res://assets/materials/outline_material_overlay.tres")
const bin_bag_scene := preload("res://items/medium/bin_bag.tscn")
@onready var _label: Label3D = $Label3D
@onready var _mesh_instance: MeshInstance3D = $MeshInstance3D


func highlight() -> void:
	is_highlighted = true
	_mesh_instance.material_overlay = outline_material
	return


func unhighlight() -> void:
	is_highlighted = false
	_mesh_instance.material_overlay = null
	return

## Respond to the player long-pressing the pickup button
func long_press_pickup() -> void:
	contained_items = {}
	total_count = 0
	_label.text = ""
	var _bin_bag := bin_bag_scene.instantiate()
	Game.physics_item_container.add_child(_bin_bag)
	_bin_bag.global_position = global_position
	_bin_bag.global_position.y += 2
	return


func deposit_item(_item: CarryableItem) -> void:
	if not contained_items.has(_item.item_name):
		contained_items[_item.item_name] = 0
	contained_items[_item.item_name] += 1
	
	total_count = 0
	for _key in contained_items.keys():
		total_count += contained_items[_key]
	
	_label.text = ""
	var i: int = 0
	for _key in contained_items.keys():
		if i > 0:
			_label.text += "\n"
		_label.text += _key + ": " + str(contained_items[_key])
		i += 1
	_label.text += "\nTotal: " + str(total_count)
	return

## Checks if this container is a valid target for emptying
func can_be_emptied() -> bool:
	return total_count > 0
