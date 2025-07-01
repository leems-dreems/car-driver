extends Node3D

@onready var nav_links := $NavigationRegion3D/RoadLaneNavLinks
@onready var path_start_marker := $PathStartMarker
@onready var path_end_marker := $PathEndMarker
@onready var nav_agent := $NavigationRegion3D/NavParent/NavigationAgent3D
@onready var astar := AStar3D.new()
const path_dot_scene := preload("pathfinding_dot.tscn")
const yellow_debug_material := preload("res://assets/materials/debug_materials/flat_yellow.tres")
const search_radius_squared := 100 ## Pathfinding will find the nearest graph point, and then try out other points within this radius
const astar_point_interval := 10.0
var endpoints_dict: Dictionary[int, RoadLane] = {} ## Used to track the astar indices of the start & end points of each RoadLane


func _ready() -> void:
	PauseAndHud.hide_hud()

	var _road_lanes: Array[Node] = find_children("*", "RoadLane", true, false)
	$RoadLanes_Label3D.text += str(len(_road_lanes))

	for _road_lane: RoadLane in _road_lanes:
		var _lane_points := _road_lane.curve.get_baked_points()
		var _increment_amount := ceili(astar_point_interval / _road_lane.curve.bake_interval)
		var _index: int = 0
		var _previous_point_id: int

		while _index < len(_lane_points) - 1: # Add astar points at intervals along the lane's curve
			var _new_id := astar.get_available_point_id()
			astar.add_point(_new_id, _road_lane.to_global(_lane_points[_index]))
			var _marker := path_dot_scene.instantiate()
			_marker.add_to_group("AStarPathDot")
			nav_links.add_child(_marker)
			_marker.global_position = _road_lane.to_global(_lane_points[_index])
			_marker.set_meta("point_id", _new_id)
			if _index == 0: # If this is the first point on this lane, store its index
				endpoints_dict[_new_id] = _road_lane
			elif _index > 0: # Make a one-way connection from the previous point to this one
				astar.connect_points(_previous_point_id, _new_id, false)
				draw_line(astar.get_point_position(_previous_point_id), astar.get_point_position(_new_id))
			_previous_point_id = _new_id
			_index += _increment_amount

		# Add astar point for end of lane's curve
		var _endpoint_id := astar.get_available_point_id()
		astar.add_point(_endpoint_id, _road_lane.to_global(_lane_points[len(_lane_points) - 1]))
		astar.connect_points(_previous_point_id, _endpoint_id, false)
		draw_line(astar.get_point_position(_previous_point_id), astar.get_point_position(_endpoint_id))
		endpoints_dict[_endpoint_id] = _road_lane
		var _end_marker := path_dot_scene.instantiate()
		nav_links.add_child(_end_marker)
		_end_marker.global_position = _road_lane.to_global(_lane_points[len(_lane_points) - 1])
		_end_marker.add_to_group("AStarPathDot")
		_end_marker.set_meta("point_id", _endpoint_id)

	for _point_idx: int in endpoints_dict.keys():
		var _point_position := astar.get_point_position(_point_idx)
		var _lane := endpoints_dict[_point_idx]
		if _point_position == _lane.to_global(_lane.curve.get_point_position(0)):
			var _overlapping_indices := endpoints_dict.keys().filter(func(i):
				var _other_point_position := astar.get_point_position(i)
				var _other_lane := endpoints_dict[i]
				if _other_point_position != _other_lane.to_global(_other_lane.curve.get_point_position(_other_lane.curve.point_count - 1)):
					return false
				return _other_point_position.distance_squared_to(_point_position) < 1
			)
			for _overlapping_index in _overlapping_indices:
				astar.connect_points(_overlapping_index, _point_idx, false)
				draw_line(astar.get_point_position(_overlapping_index), astar.get_point_position(_point_idx))

	$NavLinks_Label3D.text += str(astar.get_point_count())
	return


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("set_pathfind_start") and not event.is_echo():
		var _space_state = get_world_3d().direct_space_state
		var _ray_params := PhysicsRayQueryParameters3D.new()
		_ray_params.from = $Camera3D.project_ray_origin(DisplayServer.mouse_get_position())
		_ray_params.to = _ray_params.from + $Camera3D.project_ray_normal(get_viewport().get_mouse_position()) * $Camera3D.far

		var _result = _space_state.intersect_ray(_ray_params)
		if _result.size() > 0:
			path_start_marker.visible = true
			path_start_marker.position = _result.position
			path_start_marker.position.y += 2
			plot_route()

	if event.is_action_pressed("set_pathfind_end") and not event.is_echo():
		var _space_state = get_world_3d().direct_space_state
		var _ray_params := PhysicsRayQueryParameters3D.new()
		_ray_params.from = $Camera3D.project_ray_origin(DisplayServer.mouse_get_position())
		_ray_params.to = _ray_params.from + $Camera3D.project_ray_normal(get_viewport().get_mouse_position()) * $Camera3D.far

		var _result = _space_state.intersect_ray(_ray_params)
		if _result.size() > 0:
			path_end_marker.visible = true
			path_end_marker.position = _result.position
			path_end_marker.position.y += 2
			plot_route()
	return


func plot_route() -> void:
	var _possible_starts: PackedInt64Array
	var _possible_ends: PackedInt64Array
	var _nearest_start := astar.get_point_position(astar.get_closest_point(path_start_marker.position))
	var _nearest_end := astar.get_point_position(astar.get_closest_point(path_end_marker.position))

	for _id in astar.get_point_ids():
		if astar.get_point_position(_id).distance_squared_to(_nearest_start) < search_radius_squared:
			_possible_starts.push_back(_id)
		if astar.get_point_position(_id).distance_squared_to(_nearest_end) < search_radius_squared:
			_possible_ends.push_back(_id)
	
	var _lowest_cost := INF
	var _id_path: PackedInt64Array
	for _possible_start in _possible_starts:
		for _possible_end in _possible_ends:
			var _test_id_path := astar.get_id_path(_possible_start, _possible_end)
			if len(_test_id_path) == 0: continue
			var _cost := get_path_cost(_test_id_path)
			if _cost < _lowest_cost:
				_lowest_cost = _cost
				_id_path = _test_id_path

	var _markers := get_tree().get_nodes_in_group("AStarPathDot")
	for _marker: MeshInstance3D in _markers:
		if _marker.get_meta("point_id") in _id_path:
			_marker.set_surface_override_material(0, yellow_debug_material)
			_marker.scale = Vector3(2, 2, 2)
		else:
			_marker.set_surface_override_material(0, null)
			_marker.scale = Vector3.ONE

	$Path_Start_Polyline3D.points.clear()
	$Path_Start_Polyline3D.points.push_back(path_start_marker.position)
	$Path_Start_Polyline3D.points.push_back(astar.get_point_position(_id_path[0]))
	$Path_Start_Polyline3D.regenerateMesh()
	$Path_End_Polyline3D.points.clear()
	$Path_End_Polyline3D.points.push_back(astar.get_point_position(_id_path[len(_id_path) - 1]))
	$Path_End_Polyline3D.points.push_back(path_end_marker.position)
	$Path_End_Polyline3D.regenerateMesh()

	$Path_Cost_Label3D.text = "Path cost: " + str(roundi(_lowest_cost))

	return


func draw_line(_from: Vector3, _to: Vector3) -> void:
	var _poly_line := Polyline3D.new()
	nav_links.add_child(_poly_line)
	_poly_line.points.clear()
	_poly_line.points.push_back(_from)
	_poly_line.points.push_back(_to)
	_poly_line.debug = true
	_poly_line.regenerateMesh()
	return


func get_path_cost(id_path: PackedInt64Array) -> float:
	var _path_cost := 0.0
	var i: int = 0
	while i < len(id_path) - 2:
		_path_cost += astar.get_point_position(id_path[i]).distance_to(astar.get_point_position(id_path[i + 1])) * astar.get_point_weight_scale(id_path[i + 1])
		i += 1
	return _path_cost
