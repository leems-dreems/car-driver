class_name TrafficPath extends Path3D
## A path that spawns traffic driving along it

@export var number_of_vehicles := 1
@export var road_speed := 20.0
@export var road_reversing_speed := -5.0
var min_speed := 0.1
var brake_force := 0.5
var compact_car_scene:= preload("res://cars/compact.tscn")
var traffic_follower_scene:= preload("res://traffic/traffic_path_follower.tscn")
var followers: Array[TrafficPathFollower] = []
## Tracks the last vehicle that this TrafficPath processed avoidance & inputs for
var last_follower_updated_index := -1
var path_length: float
var path_distance_limit := 2.0


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
    if last_follower_updated_index >= len(followers) - 1:
      last_follower_updated_index = -1
    if follower.vehicle != null and not follower.vehicle.is_being_driven:
      var _follower_index := followers.find(follower)
      if last_follower_updated_index >= _follower_index:
        continue
      else:
        last_follower_updated_index = _follower_index
      if follower.vehicle.get_wheel_contact_count() >= 3:
        var closest_offset := curve.get_closest_offset(follower.vehicle.position)
        var _speed := follower.vehicle.speed
        follower.progress = closest_offset + _speed
        var target_speed := road_speed
        # If we are far from the path, aim towards nearby path point
        var _distance_to_path := curve.get_closest_point(follower.vehicle.position).distance_to(follower.vehicle.position)
        var _angle_to_path := follower.vehicle.transform.basis.z.signed_angle_to(follower.transform.basis.z, Vector3.UP)
        if _distance_to_path < path_distance_limit and _angle_to_path > -0.1 and _angle_to_path < 0.1:
          # Move TrafficPathFollower forward a bit, then aim for it
          follower.vehicle.is_on_path = true
        else:
          follower.vehicle.is_on_path = false
        # Set the vehicle's interest vectors and calculate the average direction of interest
        follower.vehicle.set_interest_vectors(follower.global_transform.origin)
        follower.vehicle.set_summed_interest_vector()
        var _turning_angle := follower.vehicle.get_interest_angle()
        var _interest_vector := follower.vehicle.summed_interest_vector

        if _interest_vector.z > follower.vehicle.steering_ray_length * 0.75:
          if not follower.vehicle.is_on_path and follower.vehicle.linear_velocity.z < min_speed:
            target_speed = road_reversing_speed
          else:
            target_speed = 0.0
        elif _turning_angle < -PI / 8 or _turning_angle > PI / 8:
          target_speed *= 0.25

        if target_speed == road_reversing_speed:
          if _speed < 0.5 and not follower.vehicle.is_shifting and not follower.vehicle.current_gear == -1:
            follower.vehicle.shift(-1)
          else:
            follower.vehicle.throttle_input = 0.5
            follower.vehicle.brake_input = 0.0
            follower.vehicle.handbrake_input = 0.0
        else:
          if follower.vehicle.current_gear < 1 and not follower.vehicle.is_shifting:
            follower.vehicle.shift(1)
          elif target_speed == 0.0:
            follower.vehicle.throttle_input = 0.0
            if _speed < min_speed:
              follower.vehicle.brake_input = 0.0
            else:
              follower.vehicle.brake_input = 1.0
            follower.vehicle.handbrake_input = 1.0
          elif _speed < target_speed:
            if _speed < target_speed / 2:
              follower.vehicle.throttle_input = 0.75
              follower.vehicle.brake_input = 0.0
              follower.vehicle.handbrake_input = 0.0
            else:
              follower.vehicle.throttle_input = clampf(_speed / target_speed, 0.5, 1.0)
              follower.vehicle.brake_input = 0.0
              follower.vehicle.handbrake_input = 0.0
          elif _speed > target_speed * 1.2:
            follower.vehicle.throttle_input = 0.0
            follower.vehicle.brake_input = brake_force
            follower.vehicle.handbrake_input = 0.0
          else:
            follower.vehicle.throttle_input = 0.0
            follower.vehicle.brake_input = 0.0
            follower.vehicle.handbrake_input = 0.0

        if follower.vehicle.throttle_input > 0.0:
          follower.vehicle.ignition_on = true

        # Steer to match the rotation of the nearest path position
        if _turning_angle > -PI * 0.8 and _turning_angle < PI * 0.8:
          follower.vehicle.steering_input = clampf(_turning_angle, -1.0, 1.0)
        else:
          follower.vehicle.steering_input = 0.0
        if follower.vehicle.current_gear == -1:
          follower.vehicle.steering_input = -follower.vehicle.steering_input
        break
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
