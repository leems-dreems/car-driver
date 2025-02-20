## An item container that is itself a physics object. May be a child of a StandalonePropBodies node.
class_name VehicleItemContainer extends RigidBody3D

@export var container_name := "container"
var is_highlighted := false
var contained_items := {}
var total_count: int = 0
var vehicle: DriveableVehicle
const outline_material := preload("res://assets/materials/outline_material_overlay.tres")
const _small_can_scene := preload("res://items/small/small_can_item.tscn")
const _bin_bag_scene := preload("res://items/medium/bin_bag.tscn")
@onready var _item_placement_marker: Marker3D = $Marker3D


func _ready() -> void:
	await owner.ready
	vehicle = owner as Vehicle
	assert(vehicle != null, "The VehicleItemContainer node must be the child of a DriveableVehicle node")
	container_name = vehicle.vehicle_name
	return


func highlight() -> void:
	is_highlighted = true
	vehicle.body_mesh_instance.material_overlay = outline_material
	return


func unhighlight() -> void:
	is_highlighted = false
	vehicle.body_mesh_instance.material_overlay = null
	return


func deposit_item(_item: CarryableItem) -> void:
	if not contained_items.has(_item.item_name):
		contained_items[_item.item_name] = 0
	contained_items[_item.item_name] += 1
	
	match _item.item_name:
		"small can":
			var _new_can := _small_can_scene.instantiate()
			_new_can.global_transform = _item_placement_marker.global_transform
			_new_can.collision_layer = 65536
			_new_can.collision_mask = 524288
			_new_can.container_node = self
			Game.physics_item_container.add_child(_new_can)
		"bin bag":
			var _new_bin_bag := _bin_bag_scene.instantiate()
			_new_bin_bag.global_transform = _item_placement_marker.global_transform
			_new_bin_bag.collision_layer = 65536
			_new_bin_bag.collision_mask = 524288
			_new_bin_bag.container_node = self
			Game.physics_item_container.add_child(_new_bin_bag)
	
	total_count = 0
	for _key in contained_items.keys():
		total_count += contained_items[_key]

	return

## Checks if this container is a valid target for emptying
func can_be_emptied() -> bool:
	return false
