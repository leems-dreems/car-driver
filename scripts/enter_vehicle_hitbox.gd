class_name EnterVehicleCollider extends StaticBody3D

@export var vehicle_name := 'Vehicle'
const outline_material := preload("res://assets/materials/outline_material_overlay.tres")
var vehicle : DriveableVehicle = null
var is_highlighted := false


func get_use_label() -> String:
	return 'Drive ' + vehicle_name


func highlight() -> void:
	is_highlighted = true
	vehicle.body_mesh_instance.material_overlay = outline_material
	return


func unhighlight() -> void:
	is_highlighted = false
	vehicle.body_mesh_instance.material_overlay = null
	return
