class_name EnterVehicleCollider extends StaticBody3D

@export var vehicle_name := 'Vehicle'
var vehicle : DriveableVehicle = null

func get_use_label () -> String:
  return 'Drive ' + vehicle_name
