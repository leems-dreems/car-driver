class_name CarDoorInteractArea extends InteractableArea

@export var is_enterable := true ## Whether player can enter vehicle through this door
@export var door_name := "door"
@export var car_door: CarDoor
var block_short_press_timer: SceneTreeTimer = null
const block_short_press_delay := 0.5


func _init() -> void:
	short_press_text = "open " + door_name
	long_press_text = "get in car"
	return


func _ready() -> void:
	if not car_door.is_shut:
		short_press_text = "Shut " + door_name
	else:
		short_press_text = "Open " + door_name
	return


func highlight() -> void:
	is_highlighted = true
	car_door.shut_door_mesh.material_overlay = car_door.outline_material
	car_door.open_door_mesh.material_overlay = car_door.outline_material
	return


func unhighlight() -> void:
	is_highlighted = false
	car_door.shut_door_mesh.material_overlay = null
	car_door.open_door_mesh.material_overlay = null
	return


func can_interact_short_press() -> bool:
	return block_short_press_timer == null


func interact_short_press() -> void:
	if block_short_press_timer != null:
		return
	set_deferred("monitorable", false)
	block_short_press_timer = get_tree().create_timer(block_short_press_delay)
	block_short_press_timer.timeout.connect(func():
		set_deferred("monitorable", true)
		block_short_press_timer = null
	)
	if car_door.is_shut:
		set_deferred("short_press_text", "Shut " + door_name)
	else:
		set_deferred("short_press_text", "Open " + door_name)
	car_door.open_or_shut()
	return


func can_interact_long_press(_carried_item: CarryableItem = null) -> bool:
	return is_enterable
