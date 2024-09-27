class_name PedestrianPath extends Path3D
## Supports [Pedestrian] nodes, which spawn & control pedestrian NPCs

var path_length: float


func _ready() -> void:
  PedestrianManager.pedestrian_paths.push_back(self)
  path_length = curve.get_baked_length()
  return
