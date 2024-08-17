class_name TrafficPath extends Path3D
## Supports [TrafficPathFollower] nodes, which spawn & control AI-driven vehicles

var compact_car_scene := preload("res://cars/compact.tscn")
var traffic_follower_scene := preload("res://traffic/traffic_path_follower.tscn")

@export_group("Path Settings")
## The maximum number of vehicles that this path can support at a time
@export var number_of_vehicles := 1

@export_group("Follower Settings")
## The speed limit on this path
@export var path_max_speed := 20.0
## The speed to aim for when reversing on this path
@export var path_reversing_speed := -5.0
## Vehicles will aim to stay this close to this path
@export var path_distance_limit := 2.0

## Follower nodes currently assigned to this TrafficPath
var followers: Array[TrafficPathFollower] = []
## Index of the last vehicle that this TrafficPath processed avoidance & inputs for
var last_follower_updated_index := -1
## Length of this path
var path_length: float


func _ready() -> void:
  path_length = curve.get_baked_length()
  for _child in get_children():
    if _child is TrafficPathFollower:
      followers.push_back(_child)
  return


func _physics_process(_delta: float) -> void:
  while len(followers) < number_of_vehicles:
    var new_follower: TrafficPathFollower = traffic_follower_scene.instantiate()
    new_follower.path_max_speed = path_max_speed
    new_follower.path_reversing_speed = path_reversing_speed
    new_follower.path_distance_limit = path_distance_limit
    new_follower.parent_curve = curve
    followers.push_back(new_follower)
    add_child(new_follower)

  # Loop through one vehicle each physics tick, updating interest vectors and input values
  if last_follower_updated_index >= len(followers) - 1:
    last_follower_updated_index = -1
  last_follower_updated_index += 1
  var _follower := followers[last_follower_updated_index]

  if _follower.vehicle == null:
    # Note: Area3Ds update their lists of overlapping areas/bodies once at the start of each physics
    # tick, so moving the follower and then looking for collisions in the same tick won't work
    if _follower.collision_area.has_overlapping_areas() or _follower.collision_area.has_overlapping_bodies():
      _follower.progress = randf_range(0, path_length) # Move to a random position on the path
    else: # Spawn a vehicle and start its AI
      var new_vehicle: DriveableVehicle = compact_car_scene.instantiate()
      _follower.vehicle = new_vehicle
      new_vehicle.position = _follower.position
      new_vehicle.rotation = _follower.rotation
      add_child(new_vehicle)
      new_vehicle.start_ai()
  elif not _follower.vehicle.is_being_driven:
    _follower.set_inputs()

  return
