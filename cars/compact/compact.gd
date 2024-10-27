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


func _ready() -> void:
  var _paintjob: Dictionary = paintjobs.pick_random()
  #burnt_material = _skin.burnt_material
  $body.set_surface_override_material(0, _paintjob.material)
  $ColliderBits/ShutDoorLeft.set_surface_override_material(0, _paintjob.material)
  $ColliderBits/OpenDoorLeft/MeshInstance3D.set_surface_override_material(0, _paintjob.material)
  $ColliderBits/ShutDoorRight.set_surface_override_material(0, _paintjob.material)
  $ColliderBits/OpenDoorRight/MeshInstance3D.set_surface_override_material(0, _paintjob.material)
  super()


func apply_burnt_material() -> void:
  $body.set_surface_override_material(0, burnt_material)
  $ColliderBits/ShutDoorLeft.set_surface_override_material(0, burnt_material)
  $ColliderBits/OpenDoorLeft/MeshInstance3D.set_surface_override_material(0, burnt_material)
  $ColliderBits/ShutDoorRight.set_surface_override_material(0, burnt_material)
  $ColliderBits/OpenDoorRight/MeshInstance3D.set_surface_override_material(0, burnt_material)
