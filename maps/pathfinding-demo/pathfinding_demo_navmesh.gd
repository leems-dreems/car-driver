extends Node3D

@onready var nav_links := $Waypoints_NavigationRegion3D/RoadLaneNavLinks
@onready var path_start_marker := $PathStartMarker
@onready var path_end_marker := $PathEndMarker
@onready var nav_parent := $NavParent
@onready var nav_agent := $NavParent/NavigationAgent3D
@onready var astar := AStar3D.new()

@export var movement_speed := 50.0

const road_waypoint_scene := preload("res://maps/pathfinding-demo/road_waypoint_mesh.tscn")
const path_dot_scene := preload("pathfinding_dot.tscn")
const yellow_debug_material := preload("res://assets/materials/debug_materials/flat_yellow.tres")
const search_radius_squared := 100 ## Pathfinding will find the nearest graph point, and then try out other points within this radius
const astar_point_interval := 25.0
var endpoints_dict: Dictionary[int, RoadLane] = {} ## Used to track the astar indices of the start & end points of each RoadLane
var agent_is_navigating := false


func _ready() -> void:
	PauseAndHud.hide_hud()

	nav_agent.velocity_computed.connect(func(safe_velocity: Vector3):
		nav_parent.global_position += safe_velocity * movement_speed
		nav_parent.transform.basis = nav_parent.transform.basis.looking_at(safe_velocity)
	)
	nav_agent.navigation_finished.connect(func():
		stop_agent_navigating()
	)

	var waypoints_map_rid := NavigationServer3D.map_create()
	NavigationServer3D.map_set_cell_size(waypoints_map_rid, 0.25)
	NavigationServer3D.map_set_cell_height(waypoints_map_rid, 0.5)
	$Waypoints_NavigationRegion3D.set_navigation_map(waypoints_map_rid)
	NavigationServer3D.map_set_active(waypoints_map_rid, true)

	var _road_lanes: Array[Node] = find_children("*", "RoadLane", true, false)
	$RoadLanes_Label3D.text += str(len(_road_lanes))

	for _road_lane: RoadLane in _road_lanes:
		var _lane_points := _road_lane.curve.get_baked_points()
		var _increment_amount := ceili(astar_point_interval / _road_lane.curve.bake_interval)
		var _previous_point_id: int

		# Add navmesh island at intervals along the lane's curve, and connect them with navlinks
		var _start_waypoint_mesh := road_waypoint_scene.instantiate()
		nav_links.add_child(_start_waypoint_mesh)
		_start_waypoint_mesh.global_position = _road_lane.to_global(_road_lane.curve.get_point_position(0))

		var _idx: int = 0
		var _previous_idx: int
		while _idx < len(_lane_points) - 2:
			var _waypoint_mesh := road_waypoint_scene.instantiate()
			nav_links.add_child(_waypoint_mesh)
			_waypoint_mesh.global_position = _road_lane.to_global(_lane_points[_idx])

			if _idx > 0:
				var _start_position = _road_lane.to_global(_lane_points[_previous_idx])
				var _end_position = _road_lane.to_global(_lane_points[_idx])
				add_nav_link(_start_position, _end_position)

			_previous_idx = _idx
			_idx += _increment_amount

		var _start_position = _road_lane.to_global(_lane_points[_previous_idx])
		var _end_position = _road_lane.to_global(_lane_points[len(_lane_points) - 1])
		add_nav_link(_start_position, _end_position)

	$Waypoints_NavigationRegion3D.bake_navigation_mesh()
	$Road_NavigationRegion3D.bake_navigation_mesh()
	return


func _physics_process(delta: float) -> void:
	if agent_is_navigating:
		var new_velocity: Vector3 = nav_parent.global_position.direction_to(nav_agent.get_next_path_position()) * delta
		nav_agent.set_velocity(new_velocity)
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
			nav_parent.global_position = path_start_marker.global_position
			nav_agent.target_position = path_end_marker.global_position
			start_agent_navigating()

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
			path_start_marker.global_position = nav_parent.global_position
			nav_agent.target_position = path_end_marker.global_position
			start_agent_navigating()

	if event.is_action_pressed("ui_accept") and not event.is_echo():
		start_agent_navigating()
	return


func start_agent_navigating() -> void:
	agent_is_navigating = true
	print("start navigating")
	return


func stop_agent_navigating() -> void:
	agent_is_navigating = false
	print("stop navigating")
	return


## Add a nav link to the scene. Start and end positions should be global
func add_nav_link(_start_position: Vector3, _end_position: Vector3) -> void:
	var _lane_nav_link := NavigationLink3D.new()
	_lane_nav_link.bidirectional = false
	_lane_nav_link.set_navigation_layer_value(1, false)
	_lane_nav_link.set_navigation_layer_value(2, true)
	_lane_nav_link.travel_cost = 0.01
	_lane_nav_link.start_position = _start_position
	_lane_nav_link.end_position = _end_position
	nav_links.add_child(_lane_nav_link)
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
