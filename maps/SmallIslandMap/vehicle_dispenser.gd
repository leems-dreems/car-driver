class_name VehicleDispenser extends Node3D

enum VehicleTypes { COMPACT, VAN }
@export var show_debug_label := false
var compact_scene := preload("res://cars/compact/compact.tscn")
var van_scene := preload("res://cars/Van/van.tscn")
@onready var vehicle_platform: CSGBox3D = $VehiclePlatform


func spawn_vehicle(vehicle_type: VehicleTypes) -> void:
  var _vehicle: DriveableVehicle
  match vehicle_type:
    VehicleTypes.COMPACT:
      _vehicle = compact_scene.instantiate()
    VehicleTypes.VAN:
      _vehicle = van_scene.instantiate()
  _vehicle.position = vehicle_platform.position
  _vehicle.position.y += 2
  _vehicle.rotation = vehicle_platform.rotation
  if show_debug_label:
    _vehicle.show_debug_label = true
  add_child(_vehicle)
  return
