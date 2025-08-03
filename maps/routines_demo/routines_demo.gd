extends "res://maps/common/playable_map.gd"


func _ready() -> void:
	super()
	var compact_car: DriveableVehicle = $VehicleContainer/CompactCar
	compact_car.start_navigating_to($Landmarks/LighthouseLabel.global_position)
	return
