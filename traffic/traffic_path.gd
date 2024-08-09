class_name TrafficPath extends Path3D
## A path that spawns traffic driving along it

@export var number_of_vehicles := 1
@export var road_speed := 20.0
@export var road_reversing_speed := -5.0
var compact_car_scene:= preload("res://cars/compact.tscn")
var traffic_follower_scene:= preload("res://traffic/traffic_path_follower.tscn")
var followers: Array[TrafficPathFollower] = []
var path_length: float
var path_distance_limit := 1.0


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
        var speed := follower.vehicle.linear_velocity.length()
        # Get the Y axis rotation of the nearest position on the path
        follower.progress = closest_offset + speed
        var closest_path_rotation_y: float = follower.rotation.y
        var target_speed := road_speed
        # If we are far from the path, aim towards nearby path point
        var _closest_position := curve.get_closest_point(follower.vehicle.position)
        if _closest_position.distance_to(follower.vehicle.position) < path_distance_limit:
          # Move TrafficPathFollower forward a bit, then aim for it
          follower.progress += follower.progress + speed
        follower.vehicle.set_interest_vectors(follower.global_transform.origin)
        follower.vehicle.set_summed_interest_vector()
        var _interest_vector := follower.vehicle.summed_interest_vector
        var _interest_strength := clampf(_interest_vector.length() / follower.vehicle.steering_ray_length, 0.0, 1.0)
        if _interest_vector.z > follower.vehicle.steering_ray_length * 1.0:
          if follower.vehicle.linear_velocity.z < 0.1:
            target_speed = road_reversing_speed
          else:
            target_speed = 0.0
        elif _interest_vector.z > follower.vehicle.steering_ray_length * 0.25:
          target_speed *= 0.25
        elif _interest_vector.z > follower.vehicle.steering_ray_length * 0.75:
          target_speed *= 0.5

        follower.vehicle.ignition_on = true
        if target_speed == road_reversing_speed:
          if not follower.vehicle.is_shifting and not follower.vehicle.current_gear == -1:
            follower.vehicle.shift(-1)
          else:
            follower.vehicle.throttle_input = 0.5
            follower.vehicle.brake_input = 0.0
            follower.vehicle.handbrake_input = 0.0
        else:
          if not follower.vehicle.is_shifting and follower.vehicle.current_gear < 1:
            follower.vehicle.shift(1)  
          elif target_speed == 0.0:
            follower.vehicle.throttle_input = 0.0
            follower.vehicle.brake_input = 0.0
            follower.vehicle.handbrake_input = 1.0
          elif speed < target_speed:
            if speed < target_speed / 2:
              follower.vehicle.throttle_input = 0.5
              follower.vehicle.brake_input = 0.0
              follower.vehicle.handbrake_input = 0.0
            else:
              follower.vehicle.throttle_input = clampf(1 - (target_speed / speed), 0.0, 0.5)
              follower.vehicle.brake_input = 0.0
              follower.vehicle.handbrake_input = 0.0
          elif speed > target_speed * 1.2:
            follower.vehicle.throttle_input = 0.0
            follower.vehicle.brake_input = 0.2
            follower.vehicle.handbrake_input = 0.0
          else:
            follower.vehicle.throttle_input = 0.0
            follower.vehicle.brake_input = 0.0
            follower.vehicle.handbrake_input = 0.0
          # Steer to match the rotation of the nearest path position
        var turning_angle := follower.vehicle.get_interest_angle()
        if turning_angle > PI / 128:
          follower.vehicle.steering_input = clampf(turning_angle, 0.1, 1.0)
        elif turning_angle < -PI / 128:
          follower.vehicle.steering_input = clampf(turning_angle, -1.0, -0.1)
        else:
          follower.vehicle.steering_input = 0.0
      else:
        follower.vehicle.steering_input = 0.0
        follower.vehicle.throttle_input = 0.0
    else:
      if follower.just_moved == false:
        follower.progress = randf_range(0, path_length)
        follower.just_moved = true
      elif not (follower.collision_area.has_overlapping_areas() or follower.collision_area.has_overlapping_bodies()):
        var new_vehicle: DriveableVehicle = compact_car_scene.instantiate()
        follower.vehicle = new_vehicle
        new_vehicle.position = follower.position
        new_vehicle.rotation = follower.rotation
        add_child(new_vehicle)
        new_vehicle.start_ai()
        # Break so as to avoid adding 2 vehicles in the same physics step
        break
      else:
        follower.just_moved = false
  return
