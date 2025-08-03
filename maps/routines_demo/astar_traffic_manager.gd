class_name AStarTrafficManager
extends Node3D
## Manages AI traffic in the scene
##
## Builds an AStar3D graph based on the connected RoadManager.
## Used by AStarRoadAgent nodes, to get astar paths and their associated lanes.

## RoadManager node used to identify RoadLanes and respond to updates.
@export var road_manager: RoadManager
## Pathfinding will look for alternate start/endpoints within this radius.
@export var path_search_radius := 10.0
## When reloading the AStar3D graph, lanes whose start & end points are closer
## than this will be connected to each other.
@export var lane_connection_distance := 1.0
## When reloading the graph, AStar3D points will be placed along each RoadLane
## with this much distance between them (except for the final point).
@export var astar_point_interval := 10.0

## Used to track the AStar3D indices of the start & end points of each RoadLane.
var endpoints_dict: Dictionary[int, RoadLane] = {}
## Lookup for matching an AStar3D point to a RoadLane.
var lanes_by_id: Dictionary[int, RoadLane]
## Lookup for finding the last astar point on a RoadLane.
var endpoint_ids_by_lane: Dictionary[RoadLane, int]

@onready var path_search_radius_squared := pow(path_search_radius, 2)
@onready var lane_connection_distance_squared := pow(lane_connection_distance, 2)
@onready var astar3d := AStar3D.new()


func _ready() -> void:
	reload_graph()
	return

## Reload our astar graph.
func reload_graph() -> void:
	if not is_instance_valid(road_manager):
		push_error("RoadManager not defined")
		return

	var road_lanes: Array[Node] = get_tree().get_nodes_in_group(road_manager.ai_lane_group)
	prints(str(len(road_lanes)), "RoadLane nodes in scene")

	# Loop over RoadLanes, and place AStar3D points at intervals along each curve
	for road_lane: RoadLane in road_lanes:
		var lane_points := road_lane.curve.get_baked_points()
		var increment_amount := ceili(
				astar_point_interval / road_lane.curve.bake_interval)
		var idx: int = 0
		var previous_point_id: int

		while idx < len(lane_points) - 1:
			var new_id := astar3d.get_available_point_id()
			astar3d.add_point(new_id, road_lane.to_global(lane_points[idx]))

			if idx == 0: # If this is the first point on this lane, store its id
				endpoints_dict[new_id] = road_lane
			else: # Make a one-way connection from the previous point to this one
				astar3d.connect_points(previous_point_id, new_id, false)
			previous_point_id = new_id
			lanes_by_id[new_id] = road_lane
			idx += increment_amount

		# Add an astar point at the end of the lane's curve
		var endpoint_id := astar3d.get_available_point_id()
		astar3d.add_point(endpoint_id,
				road_lane.to_global(lane_points[len(lane_points) - 1]))
		astar3d.connect_points(previous_point_id, endpoint_id, false)
		lanes_by_id[endpoint_id] = road_lane
		endpoint_ids_by_lane[road_lane] = endpoint_id

		endpoints_dict[endpoint_id] = road_lane # Store the id of this endpoint

	# Loop over endpoints and connect lanes to each other
	for point_idx: int in endpoints_dict.keys():
		var point_pos := astar3d.get_point_position(point_idx)
		var road_lane: RoadLane = endpoints_dict[point_idx]
		if point_pos == road_lane.to_global(road_lane.curve.get_point_position(0)):
			# Find nearby endpoints and connect them to this one
			var overlapping_indices := endpoints_dict.keys().filter(func(i):
				var other_point_pos := astar3d.get_point_position(i)
				var other_lane: RoadLane = endpoints_dict[i]
				var other_lane_end_pos := other_lane.to_global(
					other_lane.curve.get_point_position(other_lane.curve.point_count - 1)
				)
				if other_point_pos != other_lane_end_pos:
					return false
				return other_point_pos.distance_squared_to(point_pos) < lane_connection_distance_squared
			)
			for overlapping_index in overlapping_indices:
				astar3d.connect_points(overlapping_index, point_idx, false)

	prints(str(astar3d.get_point_count()), "points in AStar3D graph")
	return

## Return an array of astar point ids, representing a path through our astar graph.
func get_route(from: Vector3, to: Vector3) -> PackedInt64Array:
	var possible_starts: PackedInt64Array
	var possible_ends: PackedInt64Array
	var nearest_start := astar3d.get_point_position(
			astar3d.get_closest_point(from))
	var nearest_end := astar3d.get_point_position(
			astar3d.get_closest_point(to))

	for point_id in astar3d.get_point_ids(): # Get alternate start and end points
		if (
				astar3d.get_point_position(point_id)
				.distance_squared_to(nearest_start) < path_search_radius_squared
		):
			possible_starts.push_back(point_id)
		if (
				astar3d.get_point_position(point_id)
				.distance_squared_to(nearest_end) < path_search_radius_squared
		):
			possible_ends.push_back(point_id)

	var lowest_cost := INF
	var shortest_id_path: PackedInt64Array
	# Loop over possible start & end points to find shortest path
	for possible_start in possible_starts:
		for possible_end in possible_ends:
			var test_id_path := astar3d.get_id_path(possible_start, possible_end)
			if len(test_id_path) == 0: continue
			var path_cost := get_path_cost(test_id_path)
			if path_cost < lowest_cost:
				lowest_cost = path_cost
				shortest_id_path = test_id_path

	prints("Path cost:", str(roundi(lowest_cost)))
	return shortest_id_path

## Calculate the cost of a given astar path.
func get_path_cost(_id_path: PackedInt64Array) -> float:
	var path_cost := 0.0
	var i: int = 0
	while i < len(_id_path) - 2:
		path_cost += astar3d.get_point_position(_id_path[i]).distance_to(
				astar3d.get_point_position(_id_path[i + 1])) * astar3d.get_point_weight_scale(_id_path[i + 1])
		i += 1
	return path_cost
