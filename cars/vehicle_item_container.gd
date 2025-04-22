class_name VehicleItemContainer extends RigidBody3D

var total_count: int = 0
var vehicle: DriveableVehicle
var items: Array[Node3D] = []
@onready var capture_item_area: Area3D = $CaptureArea3D
@onready var escape_item_area: Area3D = $EscapeArea3D
@onready var _label: Label3D = $Label3D


func _ready() -> void:
	await owner.ready
	vehicle = owner as Vehicle
	assert(vehicle != null, "The VehicleItemContainer node must be the child of a DriveableVehicle node")
	return


func connect_item_listeners() -> void:
	for _item in items:
		if _item is CarryableItem:
			_item.set_collision_layer_value(17, true)
	capture_item_area.body_entered.connect(_handle_item_entered)
	escape_item_area.body_exited.connect(_handle_item_exited)
	return


func disconnect_item_listeners() -> void:
	capture_item_area.body_entered.disconnect(_handle_item_entered)
	escape_item_area.body_exited.disconnect(_handle_item_exited)
	for _item in items:
		if _item is CarryableItem:
			_item.set_collision_layer_value(17, false)
	return


func _handle_item_entered(_body: Node3D) -> void:
	if _body is CarryableItem:
		if not items.has(_body):
			items.push_back(_body)
		_body.collision_layer = pow(2, 16-1) + pow(2, 17-1)
		_body.collision_mask = pow(2, 16-1) + pow(2, 20-1)
		_label.text = str(len(items))
	return


func _handle_item_exited(_body: Node3D) -> void:
	if _body is CarryableItem:
		if items.has(_body):
			items.erase(_body)
		_body.collision_layer = _body._default_collision_layer
		_body.collision_mask = _body._default_collision_mask
		_label.text = str(len(items))
	return
