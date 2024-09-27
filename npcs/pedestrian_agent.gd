class_name PedestrianAgent extends PathFollow3D
## This class is instantiated by the [PedestrianManager]

## Used to check if a pedestrian can be spawned here
@onready var collision_area: Area3D = $Area3D
var pedestrian: Pedestrian = null
## The Curve3D of the PedestrianPath this agent is following
var parent_curve: Curve3D
## Baked length of the parent_curve
var parent_curve_length: float
## Increased by the PedestrianManager when this prop fails a hearing & line-of-sight check
var despawn_weight := 0.0


func copy_path_settings(_pedestrian_path: PedestrianPath) -> void:
  parent_curve = _pedestrian_path.curve
  parent_curve_length = _pedestrian_path.path_length
  return


func add_to_path(_pedestrian_path: PedestrianPath) -> void:
  if is_inside_tree():
    get_parent_node_3d().remove_child(self)
  copy_path_settings(_pedestrian_path)
  _pedestrian_path.add_child(self)
