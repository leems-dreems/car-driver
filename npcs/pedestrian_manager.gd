extends Node
## Spawns and despawns pedestrian NPCs around the camera

const pedestrian_spawn_point_scene := preload("res://npcs/pedestrian_spawn_point.tscn")
const traffic_agent_scene := preload("res://npcs/pedestrian.tscn")
## How many vehicles to spawn
var vehicle_count: int = 7
## The Camera3D to use for line-of-sight and hearing range checks
var camera: Camera3D
## Area3D node used to look for TrafficSpawnPoints around the camera/player
var spawn_include_area: Area3D
## Smaller Area3D node used to exclude closer spawn points from the include list
var spawn_exclude_area: Area3D
## Node that spawned vehicles will be added to as children
var vehicle_container_node: Node3D
## Vehicles won't be despawned until their `despawn_weight` is greater than this
var despawn_delay: int = 60
## Vehicles within this distance will not be despawned
var hearing_range := 160.0
## Minimum distance from the camera vehicles will be spawned
var min_spawn_radius := 80.0
## Maximum distance from the camera vehicles will be spawned
var max_spawn_radius := 160.0
## TrafficAgents being managed
var _agents: Array[TrafficAgent] = []
## All the TrafficPaths that this manager will consider spawning traffic on
var traffic_paths: Array[TrafficPath] = []
## Distance to move before updating our list of nearby TrafficSpawnPoints
var _spawn_points_update_distance := 80.0
## Global position of the camera the last time we updated the list of nearby TrafficSpawnPoints
var _camera_position_at_last_update := Vector3.INF
## An array of TrafficSpawnPoints within a certain range of distance
var _nearby_spawn_points: Array[TrafficSpawnPoint] = []
## Index of the last path checked from the _nearby_traffic_paths array
var _last_spawn_point_checked: int = -1
## How long to keep skipping a spawn point for after it has been on-camera
var _spawn_point_sighted_delay := 8.0
## Distance in metres between spawn points
var _spawn_point_interval := 20
## Index of the most recent TrafficAgent to be updated
var last_agent_updated: int = 0
## Time elapsed since TrafficManager started. Incremented by the delta of _physics_process each step
var _time_elapsed := 10.0
## Parameters for line-of-sight checks on physics props
@onready var vehicle_ray_query_params := PhysicsRayQueryParameters3D.create(Vector3.ZERO, Vector3.ZERO, 3)
## Parameters for line-of-sight checks on paths
@onready var terrain_ray_query_params := PhysicsRayQueryParameters3D.create(Vector3.ZERO, Vector3.ZERO, 1)
