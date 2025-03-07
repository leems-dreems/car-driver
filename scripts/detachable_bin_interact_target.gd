extends InteractableArea

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
	if bin_rigidbody.label_show_timer != null:
		bin_rigidbody.label_show_timer.time_left = bin_rigidbody.label_show_duration
		return
	bin_rigidbody.label.transparency = 1
	bin_rigidbody.label.visible = true
	bin_rigidbody.label_show_timer = get_tree().create_timer(bin_rigidbody.label_show_duration)
	create_tween().tween_property(bin_rigidbody.label, "transparency", 0, 0.2)
	bin_rigidbody.label_show_timer.timeout.connect(func():
		create_tween().tween_property(bin_rigidbody.label, "transparency", 1, 0.2)
		bin_rigidbody.label_show_timer = null
	)
	return


func can_interact_long_press() -> bool:
	return bin_rigidbody.total_count > 0

## Handle a long-press of the interact button
func interact_long_press() -> void:
	bin_rigidbody.contained_items = {}
	bin_rigidbody.total_count = 0
	bin_rigidbody.label.text = ""
	var _bin_bag := bin_rigidbody.bin_bag_scene.instantiate()
	Game.physics_item_container.add_child(_bin_bag)
	_bin_bag.global_position = global_position
	_bin_bag.global_position.y += 2
	return
