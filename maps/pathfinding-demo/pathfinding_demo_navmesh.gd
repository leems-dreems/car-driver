extends Node3D

@onready var nav_links := $Waypoints_NavigationRegion3D/RoadLaneNavLinks
@onready var path_start_marker := $PathStartMarker
@onready var path_end_marker := $PathEndMarker
@onready var nav_parent := $NavParent
@onready var nav_agent := $NavParent/NavigationAgent3D

@export var movement_speed := 50.0

const road_waypoint_scene := preload("res://maps/pathfinding-demo/road_waypoint_mesh.tscn")
const search_radius_squared := 100 ## Pathfinding will find the nearest graph point, and then try out other points within this radius
const waypoint_interval := 25.0

var agent_is_navigating := false
var agent_is_following_link := false
var lane_to_follow: RoadLane = null


func _ready() -> void:
	PauseAndHud.hide_hud()

	nav_agent.velocity_computed.connect(func(safe_velocity: Vector3):
		nav_parent.global_position += safe_velocity * movement_speed
		nav_parent.transform.basis = nav_parent.transform.basis.looking_at(safe_velocity)
	)
	nav_agent.waypoint_reached.connect(func(details: Dictionary):
		if details.owner is NavigationLink3D:
			return
		print("waypoint reached")
		lane_to_follow = null
		agent_is_following_link = false
	)
	nav_agent.link_reached.connect(func(details: Dictionary):
		prints("link reached", details.owner)
		lane_to_follow = details.owner.get_meta("RoadLane")
		agent_is_following_link = true
	)
	nav_agent.navigation_finished.connect(func():
		stop_agent_navigating()
	)

	var waypoints_map_rid := NavigationServer3D.map_create()
	NavigationServer3D.map_set_cell_size(waypoints_map_rid, 0.25)
	NavigationServer3D.map_set_cell_height(waypoints_map_rid, 0.5)
	$Waypoints_NavigationRegion3D.set_navigation_map(waypoints_map_rid)
	NavigationServer3D.map_set_active(waypoints_map_rid, true)

	var road_lanes: Array[Node] = find_children("*", "RoadLane", true, false)
	$RoadLanes_Label3D.text += str(len(road_lanes))

	for road_lane: RoadLane in road_lanes:
		var _lane_points := road_lane.curve.get_baked_points()
		var _increment_amount := ceili(waypoint_interval / road_lane.curve.bake_interval)
		var _previous_point_id: int

		# Add navmesh island at intervals along the lane's curve, and connect them with navlinks
		var _start_waypoint_mesh := road_waypoint_scene.instantiate()
		nav_links.add_child(_start_waypoint_mesh)
		_start_waypoint_mesh.global_position = road_lane.to_global(road_lane.curve.get_point_position(0))

		var _idx: int = 0
		var _previous_idx := _idx
		var lane_parent := road_lane.get_parent()
		while lane_parent is not RoadContainer:
			lane_parent = lane_parent.get_parent()
			assert(lane_parent != get_tree().root, "RoadLane has no RoadContainer ancestor")

		if lane_parent.is_intersection:
			var _waypoint_mesh := road_waypoint_scene.instantiate()
			nav_links.add_child(_waypoint_mesh)
			_waypoint_mesh.global_position = road_lane.to_global(_lane_points[_idx])

		else:
			while _idx < len(_lane_points) - 2:
				var _waypoint_mesh := road_waypoint_scene.instantiate()
				nav_links.add_child(_waypoint_mesh)
				_waypoint_mesh.global_position = road_lane.to_global(_lane_points[_idx])

				if _idx > 0:
					var _start_position = road_lane.to_global(_lane_points[_previous_idx])
					var _end_position = road_lane.to_global(_lane_points[_idx])
					add_nav_link(_start_position, _end_position, road_lane, lane_parent)
				_previous_idx = _idx
				_idx += _increment_amount

		var _start_position = road_lane.to_global(_lane_points[_previous_idx])
		var _end_position = road_lane.to_global(_lane_points[len(_lane_points) - 1])
		add_nav_link(_start_position, _end_position, road_lane, lane_parent)

	$Waypoints_NavigationRegion3D.bake_navigation_mesh()
	$Road_NavigationRegion3D.bake_navigation_mesh()
	return


func _physics_process(delta: float) -> void:
	if agent_is_navigating:
		var next_path_position: Vector3 = nav_agent.get_next_path_position()
		if agent_is_following_link and lane_to_follow == null:
			agent_is_following_link = false
		if agent_is_following_link:
			var nearest_offset := lane_to_follow.curve.get_closest_offset(lane_to_follow.to_local(nav_parent.global_position))
			var nearest_normal := lane_to_follow.curve.sample_baked_with_rotation(nearest_offset).basis.z
			var new_velocity: Vector3 = nearest_normal * delta
			new_velocity = new_velocity.rotated(Vector3.UP, -lane_to_follow.global_rotation.y)
			nav_agent.set_velocity(new_velocity)
		else:
			var new_velocity: Vector3 = nav_parent.global_position.direction_to(next_path_position) * delta
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
	return


func start_agent_navigating() -> void:
	agent_is_navigating = true
	return


func stop_agent_navigating() -> void:
	agent_is_navigating = false
	agent_is_following_link = false
	return

## Add a nav link to the scene. Start and end positions should be global
func add_nav_link(start_position: Vector3, end_position: Vector3, road_lane: RoadLane, road_container: RoadContainer) -> void:
	var lane_nav_link := NavigationLink3D.new()
	lane_nav_link.bidirectional = false
	lane_nav_link.set_navigation_layer_value(1, false)
	lane_nav_link.set_navigation_layer_value(2, true)
	#lane_nav_link.travel_cost = 0.01
	lane_nav_link.enter_cost = 10.0
	lane_nav_link.start_position = start_position
	lane_nav_link.end_position = end_position
	lane_nav_link.set_meta("RoadLane", road_lane)
	lane_nav_link.set_meta("RoadContainer", road_container)
	nav_links.add_child(lane_nav_link)
	return
