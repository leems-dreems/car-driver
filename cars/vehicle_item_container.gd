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

	capture_item_area.body_entered.connect(func(_body: Node3D):
		if _body is CarryableItem:
			_body.collision_layer = pow(2, 16-1)
			_body.collision_mask = pow(2, 16-1) + pow(2, 20-1)
			total_count += 1
			_label.text = str(total_count)
	)
	escape_item_area.body_exited.connect(func(_body: Node3D):
		if _body is CarryableItem:
			_body.collision_layer = _body._default_collision_layer
			_body.collision_mask = _body._default_collision_mask
			total_count -= 1
			_label.text = str(total_count)
	)

	return
