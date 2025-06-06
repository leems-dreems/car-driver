class_name DetachableBinArea extends InteractableArea

@export var container_name := "bin"
@export var short_press_verb := "kick"
@export var long_press_verb := "empty"
var bin_rigidbody: RigidBinContainer
var block_short_press_timer: SceneTreeTimer = null
const block_short_press_delay := 0.5


func _init() -> void:
	short_press_text = "kick bin"
	long_press_text = "empty bin"
	return


func _ready() -> void:
	await owner.ready
	bin_rigidbody = get_parent_node_3d() as RigidBinContainer
	assert(bin_rigidbody != null, "This class needs the owner to be a RigidBinContainer node.")
	return


func highlight() -> void:
	is_highlighted = true
	bin_rigidbody._mesh_instance.material_overlay = bin_rigidbody.outline_material
	return


func unhighlight() -> void:
	is_highlighted = false
	bin_rigidbody._mesh_instance.material_overlay = null
	return


func can_interact_short_press() -> bool:
	return block_short_press_timer == null


func interact_short_press() -> void:
	if block_short_press_timer != null or bin_rigidbody.total_count == 0:
		return
	block_short_press_timer = get_tree().create_timer(block_short_press_delay)
	block_short_press_timer.timeout.connect(func(): block_short_press_timer = null)
	bin_rigidbody.show_status()
	return


func can_interact_long_press(_carried_item: CarryableItem = null) -> bool:
	return _carried_item == null and bin_rigidbody.total_count > 0

## Handle a long-press of the interact button
func interact_long_press() -> void:
	var _bin_bag := bin_rigidbody.bin_bag_scene.instantiate()
	_bin_bag.contained_items = bin_rigidbody.contained_items
	_bin_bag.total_count = bin_rigidbody.total_count
	Game.physics_item_container.add_child(_bin_bag)
	_bin_bag.global_position = bin_rigidbody.global_position
	_bin_bag.global_position.y += 2

	bin_rigidbody.contained_items = {}
	bin_rigidbody.total_count = 0
	bin_rigidbody.label.text = ""
	bin_rigidbody.item_blocker_shape.disabled = true
	return


func can_deposit_item(_item: CarryableItem) -> bool:
	return bin_rigidbody.can_deposit_item(_item)


func deposit_item(_item: CarryableItem) -> void:
	bin_rigidbody.deposit_item(_item)
	bin_rigidbody.show_status()
	return

## Checks if this container is a valid target for emptying
func can_be_emptied() -> bool:
	return bin_rigidbody.total_count > 0
