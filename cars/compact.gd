extends DriveableVehicle

var skins := [
  {
    "skin_name": "default",
    "body_mesh": preload("res://assets/models/car_cricket_body.obj"),
    "door_mesh_FR": preload("res://assets/models/car_cricket_door_FR.obj"),
    "door_mesh_FL": preload("res://assets/models/car_cricket_door_FL.obj")
  },
  {
    "skin_name": "red",
    "body_mesh": preload("res://assets/models/car_cricket_red_body.obj"),
    "door_mesh_FR": preload("res://assets/models/car_cricket_red_door_FR.obj"),
    "door_mesh_FL": preload("res://assets/models/car_cricket_red_door_FL.obj")
  },
  {
    "skin_name": "yellow",
    "body_mesh": preload("res://assets/models/car_cricket_yellow_body.obj"),
    "door_mesh_FR": preload("res://assets/models/car_cricket_yellow_door_FR.obj"),
    "door_mesh_FL": preload("res://assets/models/car_cricket_yellow_door_FL.obj")
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
