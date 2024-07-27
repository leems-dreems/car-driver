class_name TrafficPath extends Path3D
## A path that spawns traffic driving along it

@export var number_of_vehicles := 5
@export var target_speed := 20.0
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
    if follower.vehicle != null and not follower.vehicle.is_being_driven:
      if follower.vehicle.get_wheel_contact_count() >= 3:
        follower.vehicle.ignition_on = true
        var speed := follower.vehicle.linear_velocity.length()
        if speed < target_speed:
          if speed < target_speed / 2:
            follower.vehicle.throttle_input = 0.5
          else:
            follower.vehicle.throttle_input = clampf(1 - (target_speed / speed), 0.0, 0.5)
      else:
        follower.vehicle.throttle_input = 0.0
    else:
      if follower.just_moved == false:
        follower.progress = randf_range(0, path_length)
        follower.just_moved = true
      elif not (follower.collision_area.has_overlapping_areas() or follower.collision_area.has_overlapping_bodies()):
        var new_vehicle: Vehicle = compact_car_scene.instantiate()
        follower.vehicle = new_vehicle
        new_vehicle.position = follower.position
        new_vehicle.rotation = follower.rotation
        add_child(new_vehicle)
        # Break so as to avoid adding 2 vehicles in the same frame
        break
      else:
        follower.just_moved = false
  return
