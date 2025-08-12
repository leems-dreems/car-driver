class_name AStarRoadAgent
extends Node3D
## This node will follow a given AStar3D path through a RoadManager network.

signal reached_end ## Reached the end of the AStar3D path.

@export var traffic_manager: AStarTrafficManager
@export var collision_area: Area3D

## The path being followed, represented as an array of AStar3D point ids.
var id_path: PackedInt64Array:
	set = set_id_path
## The remainder of the current path - points are removed when reached.
var remaining_path: PackedInt64Array
## RoadLane that this agent is currently following.
var current_lane: RoadLane
## Progress along current RoadLane
var lane_offset: float
var has_reached_end: bool


func _ready() -> void:
	collision_area.area_entered.connect(func(area: Area3D):
		if area.is_in_group("AStarPointCollisionArea"):
			var point_id: int = area.get_meta("point_id")
			var point_index := id_path.find(point_id)
			if point_index > -1:
				remaining_path = id_path.slice(point_index)
				if len(remaining_path) <= 1:
					reached_end.emit()
	)

	reached_end.connect(func():
		has_reached_end = true
		collision_area.set_deferred("monitoring", false)
		visible = false
	)
	return


func set_lane(road_lane: RoadLane) -> void:
	current_lane = road_lane
	return


func set_id_path(_id_path: PackedInt64Array) -> void:
	has_reached_end = false
	collision_area.set_deferred("monitoring", true)
	visible = true

	id_path = _id_path
	traffic_manager.spawn_colliders_along(id_path)
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

	# TODO: Need to register individual astar points, not just end-of-lane, to be
	# able to detect when end of path has been reached. Add collision spheres to
	# astar points? Could enable & disable colliders as paths are set & cleared.
	# Same logic could be used for path debug visualisation.
	if lane_offset > current_lane.curve.get_baked_length():
		var endpoint_id := traffic_manager.endpoint_ids_by_lane[current_lane]
		var endpoint_index := id_path.find(endpoint_id)
		if endpoint_index < len(id_path) - 1:
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
