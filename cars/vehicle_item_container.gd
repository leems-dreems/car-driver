class_name VehicleItemContainer extends RigidBody3D

var total_count: int = 0
var vehicle: DriveableVehicle
@onready var capture_item_area: Area3D = $CaptureArea3D
@onready var escape_item_area: Area3D = $EscapeArea3D
@onready var _label: Label3D = $Label3D


func _ready() -> void:
	await owner.ready
	vehicle = owner as Vehicle
	assert(vehicle != null, "The VehicleItemContainer node must be the child of a DriveableVehicle node")

	return


func connect_item_listeners() -> void:
	capture_item_area.body_entered.connect(_handle_item_entered)
	escape_item_area.body_exited.connect(_handle_item_exited)
	return


func disconnect_item_listeners() -> void:
	capture_item_area.body_entered.disconnect(_handle_item_entered)
	escape_item_area.body_exited.disconnect(_handle_item_exited)
	return


func _handle_item_entered(_body: Node3D) -> void:
	if _body is CarryableItem:
		_body.collision_layer = pow(2, 16-1)
		_body.collision_mask = pow(2, 16-1) + pow(2, 20-1)
		total_count += 1
		_label.text = str(total_count)
	return


func _handle_item_exited(_body: Node3D) -> void:
	if _body is CarryableItem:
		_body.collision_layer = _body._default_collision_layer
		_body.collision_mask = _body._default_collision_mask
		total_count -= 1
		_label.text = str(total_count)
	return
