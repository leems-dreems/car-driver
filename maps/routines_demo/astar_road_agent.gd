class_name AStarRoadAgent
extends Node3D
## This node will follow a given AStar3D path through a RoadManager network.

@export var traffic_manager: AStarTrafficManager
@export var collision_area: Area3D

## The path being followed, represented as an array of AStar3D point ids.
var id_path: PackedInt64Array:
	set = set_id_path
## RoadLane that this agent is currently following.
var current_lane: RoadLane
## Progress along current RoadLane
var lane_offset: float


func set_lane(road_lane: RoadLane) -> void:
	current_lane = road_lane
	return


func set_id_path(_id_path: PackedInt64Array) -> void:
	id_path = _id_path
	set_lane(traffic_manager.lanes_by_id[id_path[0]])
	return


## Move the offset forward along the current lane's curve, and switch to the
## next lane on the path if we hit the end.
func advance_lane_offset(distance: float) -> void:
	lane_offset += distance
	global_transform = (
			current_lane.global_transform *
			current_lane.curve.sample_baked_with_rotation(lane_offset)
	)
	if lane_offset > current_lane.curve.get_baked_length():
		var endpoint_id := traffic_manager.endpoint_ids_by_lane[current_lane]
		var endpoint_index := id_path.find(endpoint_id)
		if endpoint_index >= len(id_path) - 1:
			print("Reached end of path")
		else:
			current_lane = traffic_manager.lanes_by_id[id_path[endpoint_index + 1]]
	return


## Snap this node to the nearest point on the current lane's curve.
func snap_to_nearest_offset(vehicle_position: Vector3) -> void:
	lane_offset = current_lane.curve.get_closest_offset(
			current_lane.to_local(vehicle_position))
	global_transform = (
			current_lane.global_transform *
			current_lane.curve.sample_baked_with_rotation(lane_offset)
	)
	return
