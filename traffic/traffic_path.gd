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
    return
  # Loop through one vehicle each physics tick, updating interest vectors and input values
  if last_follower_updated_index >= len(followers) - 1:
    last_follower_updated_index = -1
  last_follower_updated_index += 1
  var _follower := followers[last_follower_updated_index]
  var _vehicle := _follower.vehicle
  if _vehicle != null and not _vehicle.is_being_driven:
    if _vehicle.get_wheel_contact_count() >= 3:
      var closest_offset := curve.get_closest_offset(_vehicle.position)
      var _speed := _vehicle.speed
      _follower.progress = closest_offset + _speed
      var target_speed := road_speed
      # If we are far from the path, aim towards nearby path point
      var _distance_to_path := curve.get_closest_point(_vehicle.position).distance_to(_vehicle.position)
      var _angle_to_path := _vehicle.transform.basis.z.signed_angle_to(_follower.transform.basis.z, Vector3.UP)
      if _distance_to_path < path_distance_limit and _angle_to_path > -0.1 and _angle_to_path < 0.1:
        # Move TrafficPathFollower forward a bit, then aim for it
        _vehicle.is_on_path = true
      else:
        _vehicle.is_on_path = false
      # Set the vehicle's interest vectors and calculate the average direction of interest
      _vehicle.set_interest_vectors(_follower.global_transform.origin)
      _vehicle.set_summed_interest_vector()
      var _turning_angle := _vehicle.get_interest_angle()
      var _interest_vector := _vehicle.summed_interest_vector

      if _interest_vector.z > _vehicle.steering_ray_length * 0.75:
        if not _vehicle.is_on_path and _vehicle.linear_velocity.z < min_speed:
          target_speed = road_reversing_speed
        else:
          target_speed = 0.0
      elif _turning_angle < -PI / 8 or _turning_angle > PI / 8:
        target_speed *= 0.25

      if target_speed == road_reversing_speed:
        if _speed < 0.5 and not _vehicle.is_shifting and not _vehicle.current_gear == -1:
          _vehicle.shift(-1)
        else:
          _vehicle.throttle_input = 0.5
          _vehicle.brake_input = 0.0
          _vehicle.handbrake_input = 0.0
      else:
        if _vehicle.current_gear < 1 and not _vehicle.is_shifting:
          _vehicle.shift(1)
        elif target_speed == 0.0:
          _vehicle.throttle_input = 0.0
          if _speed < min_speed:
            _vehicle.brake_input = 0.0
          else:
            _vehicle.brake_input = 1.0
          _vehicle.handbrake_input = 1.0
        elif _speed < target_speed:
          if _speed < target_speed / 2:
            _vehicle.throttle_input = 0.75
            _vehicle.brake_input = 0.0
            _vehicle.handbrake_input = 0.0
          else:
            _vehicle.throttle_input = clampf(_speed / target_speed, 0.5, 1.0)
            _vehicle.brake_input = 0.0
            _vehicle.handbrake_input = 0.0
        elif _speed > target_speed * 1.2:
          _vehicle.throttle_input = 0.0
          _vehicle.brake_input = brake_force
          _vehicle.handbrake_input = 0.0
        else:
          _vehicle.throttle_input = 0.0
          _vehicle.brake_input = 0.0
          _vehicle.handbrake_input = 0.0

      if _vehicle.throttle_input > 0.0:
        _vehicle.ignition_on = true

      # Steer to match the rotation of the nearest path position
      if _turning_angle > -PI * 0.8 and _turning_angle < PI * 0.8:
        _vehicle.steering_input = clampf(_turning_angle, -1.0, 1.0)
      else:
        _vehicle.steering_input = 0.0
      if _vehicle.current_gear == -1:
        _vehicle.steering_input = -_vehicle.steering_input
    else:
      _vehicle.steering_input = 0.0
      _vehicle.throttle_input = 0.0
  else:
    if _follower.just_moved == false:
      _follower.progress = randf_range(0, path_length)
      _follower.just_moved = true
    elif not (_follower.collision_area.has_overlapping_areas() or _follower.collision_area.has_overlapping_bodies()):
      var new_vehicle: DriveableVehicle = compact_car_scene.instantiate()
      _follower.vehicle = new_vehicle
      new_vehicle.position = _follower.position
      new_vehicle.rotation = _follower.rotation
      add_child(new_vehicle)
      new_vehicle.start_ai()
    else:
      _follower.vehicle.just_moved = false
  return
