class_name TrafficPath extends Path3D
## A path that spawns traffic driving along it

@export var number_of_vehicles := 1
var compact_car_scene:= preload("res://cars/compact.tscn")
var traffic_follower_scene:= preload("res://traffic/traffic_path_follower.tscn")
var followers: Array[TrafficPathFollower] = []
var path_length: float


func _ready() -> void:
  path_length = curve.get_baked_length()
  for _child in get_children():
    if _child is TrafficPathFollower:
      followers.push_back(_child)
  return


func _physics_process(_delta: float) -> void:
  if len(followers) < number_of_vehicles:
    var new_follower: TrafficPathFollower = traffic_follower_scene.instantiate()
    followers.push_back(new_follower)
    add_child(new_follower)
  for follower in followers:
    if follower.vehicle != null: continue
    follower.progress = randf_range(0, path_length)
    var new_vehicle: Vehicle = compact_car_scene.instantiate()
    follower.vehicle = new_vehicle
    new_vehicle.position = follower.position
    new_vehicle.rotation = follower.rotation
    add_child(new_vehicle)
  return
