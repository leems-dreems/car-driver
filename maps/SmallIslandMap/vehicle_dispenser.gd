class_name VehicleDispenser extends Node3D

enum VehicleTypes { COMPACT, SEDAN }
@export var show_debug_label := false
var compact_scene := preload("res://cars/compact/compact.tscn")
var sedan_scene := preload("res://cars/sedan/sedan.tscn")
@onready var vehicle_platform: CSGBox3D = $VehiclePlatform


func spawn_vehicle(vehicle_type: VehicleTypes) -> void:
  var _vehicle: DriveableVehicle
  match vehicle_type:
    VehicleTypes.COMPACT:
      _vehicle = compact_scene.instantiate()
    VehicleTypes.SEDAN:
      _vehicle = sedan_scene.instantiate()
  _vehicle.position = vehicle_platform.position
  _vehicle.position.y += 2
  _vehicle.rotation = vehicle_platform.rotation
  if show_debug_label:
    _vehicle.show_debug_label = true
  add_child(_vehicle)
  return
