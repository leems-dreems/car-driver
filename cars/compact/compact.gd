extends DriveableVehicle

var paintjobs := [
  {
    "skin_name": "blue",
    "material": preload("res://assets/materials/paint/blue.tres")
  },
  {
    "skin_name": "green",
    "material": preload("res://assets/materials/paint/green.tres")
  },
  {
    "skin_name": "purple",
    "material": preload("res://assets/materials/paint/purple.tres")
  },
  {
    "skin_name": "red",
    "material": preload("res://assets/materials/paint/red.tres")
  },
  {
    "skin_name": "yellow",
    "material": preload("res://assets/materials/paint/yellow.tres")
  }
]

var burnt_material: StandardMaterial3D
@onready var _body_mesh_instance: MeshInstance3D = $body
@onready var bonnet: CarDoor = $ColliderBits/Bonnet/OpenBonnet
@onready var boot: CarDoor = $ColliderBits/Boot/OpenBoot


func _ready() -> void:
  var _paintjob: Dictionary = paintjobs.pick_random()
  #burnt_material = _skin.burnt_material
  $body.set_surface_override_material(0, _paintjob.material)
  $ColliderBits/DoorLeft/ShutDoorLeft.set_surface_override_material(0, _paintjob.material)
  $ColliderBits/DoorLeft/OpenDoorLeft/MeshInstance3D.set_surface_override_material(0, _paintjob.material)
  $ColliderBits/DoorRight/ShutDoorRight.set_surface_override_material(0, _paintjob.material)
  $ColliderBits/DoorRight/OpenDoorRight/MeshInstance3D.set_surface_override_material(0, _paintjob.material)
  $ColliderBits/Bonnet/ShutBonnet.set_surface_override_material(0, _paintjob.material)
  $ColliderBits/Bonnet/OpenBonnet/MeshInstance3D.set_surface_override_material(0, _paintjob.material)
  $ColliderBits/Boot/ShutBoot.set_surface_override_material(0, _paintjob.material)
  $ColliderBits/Boot/OpenBoot/MeshInstance3D.set_surface_override_material(0, _paintjob.material)
  super()
  return


func apply_burnt_material() -> void:
  $body.set_surface_override_material(0, burnt_material)
  $ColliderBits/DoorLeft/ShutDoorLeft.set_surface_override_material(0, burnt_material)
  $ColliderBits/DoorLeft/OpenDoorLeft/MeshInstance3D.set_surface_override_material(0, burnt_material)
  $ColliderBits/DoorRight/ShutDoorRight.set_surface_override_material(0, burnt_material)
  $ColliderBits/DoorRight/OpenDoorRight/MeshInstance3D.set_surface_override_material(0, burnt_material)
  $ColliderBits/Bonnet/ShutBonnet.set_surface_override_material(0, burnt_material)
  $ColliderBits/Bonnet/OpenBonnet/MeshInstance3D.set_surface_override_material(0, burnt_material)
  $ColliderBits/Boot/ShutBoot.set_surface_override_material(0, burnt_material)
  $ColliderBits/Boot/OpenBoot/MeshInstance3D.set_surface_override_material(0, burnt_material)
  return


func react_to_collision(velocity_change: Vector3) -> void:
  velocity_change = velocity_change.normalized()
  var _dot_with_x := velocity_change.dot(global_transform.basis.x)
  if _dot_with_x > 0.5:
    door_right.fall_open()
  elif _dot_with_x < -0.5:
    door_left.fall_open()
  var _dot_with_y := velocity_change.dot(global_transform.basis.y)
  if _dot_with_y > 0.1:
    bonnet.fall_open()
    boot.fall_open()
  var _dot_with_z := velocity_change.dot(global_transform.basis.z)
  if _dot_with_z > 0.5:
    boot.fall_open()
  return

## Freeze the car, as well as the various bodies attached to it
func freeze_bodies() -> void:
  freeze = true
  door_left.top_level = false
  door_left.freeze = true
  door_right.top_level = false
  door_right.freeze = true
  bonnet.top_level = false
  bonnet.freeze = true
  boot.top_level = false
  boot.freeze = true
  return

## Unfreeze the car. Attached bodies seem to behave more realistically when set to be `top_level`
func unfreeze_bodies() -> void:
  freeze = false
  door_left.top_level = true
  door_left.freeze = false
  door_right.top_level = true
  door_right.freeze = false
  bonnet.top_level = true
  bonnet.freeze = false
  boot.top_level = true
  boot.freeze = false
  return
