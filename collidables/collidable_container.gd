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
var _label_show_timer: SceneTreeTimer = null
const _label_show_duration := 3.0
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


func can_interact_short_press() -> bool:
	return true

## Handle a short-press of the interact button
func interact_short_press() -> void:
	if _label_show_timer != null:
		_label_show_timer.time_left = _label_show_duration
		return
	_label.transparency = 1
	_label.visible = true
	_label_show_timer = get_tree().create_timer(_label_show_duration)
	create_tween().tween_property(_label, "transparency", 0, 0.2)
	_label_show_timer.timeout.connect(func():
		create_tween().tween_property(_label, "transparency", 1, 0.2)
		_label_show_timer = null
	)
	return


func can_interact_long_press() -> bool:
	return total_count > 0

## Handle a long-press of the interact button
func interact_long_press() -> void:
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
