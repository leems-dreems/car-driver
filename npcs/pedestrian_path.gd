class_name PedestrianPath extends Path3D
## Supports [Pedestrian] nodes, which spawn & control pedestrian NPCs

@export var spawn_pedestrians := true
var path_length: float


func _ready() -> void:
  if spawn_pedestrians:
    PedestrianManager.pedestrian_paths.push_back(self)
  path_length = curve.get_baked_length()
  return
