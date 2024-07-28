class_name TrafficPath extends Path3D
## A path that spawns traffic driving along it

@export var number_of_vehicles := 10
@export var road_speed := 20.0
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
        var closest_offset := curve.get_closest_offset(follower.vehicle.position)
        # Get the Y axis rotation of the nearest position on the path
        follower.progress = closest_offset + 5.0
        var closest_path_transform := Transform3D(follower.transform)
        var closest_path_rotation_y: float = follower.rotation.y
        # Get the Y axis rotation of a position some distance along the path
        follower.progress += 10.0
        var future_path_rotation_y: float = follower.rotation.y
        # Compare the rotations and calculate vehicle inputs
        var path_angle_difference := angle_difference(follower.vehicle.rotation.y, future_path_rotation_y)
        var speed := follower.vehicle.linear_velocity.length()
        var target_speed: float
        if path_angle_difference > PI / 4:
          target_speed = 5.0
        else:
          target_speed = road_speed
        follower.vehicle.ignition_on = true
        if speed < target_speed:
          if speed < target_speed / 2:
            follower.vehicle.throttle_input = 0.5
          else:
            follower.vehicle.throttle_input = clampf(1 - (target_speed / speed), 0.0, 0.5)
        elif speed > target_speed * 2.0:
          follower.vehicle.throttle_input = 0.0
          follower.vehicle.brake_input = 0.2

        # Steer to match the rotation of the nearest path position
        var turning_angle := angle_difference(follower.vehicle.rotation.y, closest_path_rotation_y)
        var looking_at_path_transform := follower.vehicle.transform.looking_at(closest_path_transform.origin)
        var lanekeeping_angle := angle_difference(follower.vehicle.rotation.y, looking_at_path_transform.basis.get_euler().y)
        if turning_angle > PI / 64:
          follower.vehicle.steering_input = clampf(turning_angle, 0.1, 1.0)
        elif turning_angle < -PI / 64:
          follower.vehicle.steering_input = clampf(turning_angle, -0.1, -1.0)
        else:
          if lanekeeping_angle > PI / 64:
            follower.vehicle.steering_input = clampf(lanekeeping_angle, 0.0, 1.0)
          elif lanekeeping_angle < -PI / 64:
            follower.vehicle.steering_input = clampf(lanekeeping_angle, 0.0, -1.0)
          else:
            follower.vehicle.steering_input = 0.0
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
        # Break so as to avoid adding 2 vehicles in the same physics step
        break
      else:
        follower.just_moved = false
  return
