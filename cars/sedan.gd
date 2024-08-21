extends DriveableVehicle

var skins := [
  {
    "skin_name": "green",
    "body_mesh": preload("res://cars/sedan/sedan_green_body.obj"),
    "door_mesh_FR": preload("res://cars/sedan/sedan_green_door_FR.obj"),
    "door_mesh_FL": preload("res://cars/sedan/sedan_green_door_FL.obj")
  },
  {
    "skin_name": "red",
    "body_mesh": preload("res://cars/sedan/sedan_red_body.obj"),
    "door_mesh_FR": preload("res://cars/sedan/sedan_red_door_FR.obj"),
    "door_mesh_FL": preload("res://cars/sedan/sedan_red_door_FL.obj")
  }
]


func _ready() -> void:
  var _skin : Dictionary = skins.pick_random()
  $body.mesh = _skin.body_mesh
  $ColliderBits/OpenDoorRight/MeshInstance3D.mesh = _skin.door_mesh_FR
  $ColliderBits/ShutDoorRight.mesh = _skin.door_mesh_FR
  $ColliderBits/OpenDoorLeft/MeshInstance3D.mesh = _skin.door_mesh_FL
  $ColliderBits/ShutDoorLeft.mesh = _skin.door_mesh_FL
  super()
