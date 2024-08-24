extends DriveableVehicle

var skins := [
  {
    "skin_name": "green",
    "material": preload("res://cars/sedan/sedan_green_material_3d.tres"),
    "burnt_material": preload("res://cars/sedan/sedan_green_burnt_material_3d.tres")
  },
  {
    "skin_name": "red",
    "material": preload("res://cars/sedan/sedan_red_material_3d.tres"),
    "burnt_material": preload("res://cars/sedan/sedan_red_burnt_material_3d.tres")
  },
  {
    "skin_name": "grey",
    "material": preload("res://cars/sedan/sedan_grey_material_3d.tres"),
    "burnt_material": preload("res://cars/sedan/sedan_grey_burnt_material_3d.tres")
  }
]

var burnt_material: StandardMaterial3D


func _ready() -> void:
  var _skin : Dictionary = skins.pick_random()
  burnt_material = _skin.burnt_material
  $body.set_surface_override_material(0, _skin.material)
  $ColliderBits/ShutDoorLeft.set_surface_override_material(0, _skin.material)
  $ColliderBits/ShutDoorLeft.set_surface_override_material(1, _skin.material)
  $ColliderBits/OpenDoorLeft/MeshInstance3D.set_surface_override_material(0, _skin.material)
  $ColliderBits/OpenDoorLeft/MeshInstance3D.set_surface_override_material(1, _skin.material)
  $ColliderBits/ShutDoorRight.set_surface_override_material(0, _skin.material)
  $ColliderBits/ShutDoorRight.set_surface_override_material(1, _skin.material)
  $ColliderBits/OpenDoorRight/MeshInstance3D.set_surface_override_material(0, _skin.material)
  $ColliderBits/OpenDoorRight/MeshInstance3D.set_surface_override_material(1, _skin.material)
  super()


func apply_burnt_material() -> void:
  $body.set_surface_override_material(0, burnt_material)
  $ColliderBits/ShutDoorLeft.set_surface_override_material(0, burnt_material)
  $ColliderBits/ShutDoorLeft.set_surface_override_material(1, burnt_material)
  $ColliderBits/OpenDoorLeft/MeshInstance3D.set_surface_override_material(0, burnt_material)
  $ColliderBits/OpenDoorLeft/MeshInstance3D.set_surface_override_material(1, burnt_material)
  $ColliderBits/ShutDoorRight.set_surface_override_material(0, burnt_material)
  $ColliderBits/ShutDoorRight.set_surface_override_material(1, burnt_material)
  $ColliderBits/OpenDoorRight/MeshInstance3D.set_surface_override_material(0, burnt_material)
  $ColliderBits/OpenDoorRight/MeshInstance3D.set_surface_override_material(1, burnt_material)
