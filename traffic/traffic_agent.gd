class_name TrafficAgent extends PathFollow3D
## This class is instantiated by [TrafficPath] nodes, and acts as a guide for AI traffic vehicles.

@export var vehicle: DriveableVehicle = null
## Used to check if a vehicle can be spawned here
@onready var collision_area: Area3D = $Area3D
## The speed limit on this road
var path_max_speed: float
## The speed limit when reversing on this road
var path_reversing_speed: float
## Vehicle will try to stay within this distance from the path
var path_distance_limit: float
## Vehicle is considered to be stopped when below this speed
var min_speed := 0.1
## How much braking should be applied
var brake_force := 0.5
## The Curve3D of the parent TrafficPath
var parent_curve: Curve3D
## Baked length of the parent_curve
var parent_curve_length: float
## Indicates that this vehicle is close to the path and facing the right direction
var _is_on_path := false
## This vehicle will not calculate avoidance & inputs for the next X ticks
var ticks_to_skip: int = 0
## Increased by the TrafficManager when this prop fails a hearing & line-of-sight check
var despawn_weight := 0.0

## Copy settings from [traffic_path]. 
func copy_path_settings(traffic_path: Path3D) -> void:
	path_max_speed = traffic_path.path_max_speed
	path_reversing_speed = traffic_path.path_reversing_speed
	path_distance_limit = traffic_path.path_distance_limit
	parent_curve = traffic_path.curve
	parent_curve_length = traffic_path.path_length
	return


func add_to_path(_traffic_path: TrafficPath) -> void:
	if is_inside_tree():
		get_parent_node_3d().remove_child(self)
	copy_path_settings(_traffic_path)
	_traffic_path.add_child(self)
