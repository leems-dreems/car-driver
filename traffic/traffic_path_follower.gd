class_name TrafficPathFollower extends PathFollow3D
## This class is instantiated by [TrafficPath] nodes, and acts as a guide for AI traffic vehicles.

@export var vehicle: DriveableVehicle = null
## Used to check if a vehicle can be spawned here
@onready var collision_area: Area3D = $Area3D
## The speed limit on this road
var path_max_speed: float
## The speed limit when reversing on this road
var path_reversing_speed: float
## Vehicle will try to stay within this distance from the path
var path_distance_limit: float
## Vehicle is considered to be stopped when below this speed
var min_speed := 0.1
## How much braking should be applied
var brake_force := 0.5
## The Curve3D of the parent TrafficPath
var parent_curve: Curve3D
## Baked length of the parent_curve
var parent_curve_length: float
## Indicates that this vehicle is close to the path and facing the right direction
var _is_on_path := false

## Copy settings from [traffic_path]. 
func copy_path_settings(traffic_path: Path3D) -> void:
  path_max_speed = traffic_path.path_max_speed
  path_reversing_speed = traffic_path.path_reversing_speed
  path_distance_limit = traffic_path.path_distance_limit
  parent_curve = traffic_path.curve
  parent_curve_length = traffic_path.path_length
  return

## Update interest vectors & avoidance info for the vehicle, then adjust its inputs accordingly
func set_inputs() -> void:
  if vehicle.get_wheel_contact_count() >= 3:
    var _is_path_ahead_blocked := false
    if progress_ratio >= 1.0: # If follower has reached end of path, move to next path
      var _next_paths: Array = get_parent_node_3d().next_traffic_paths
      if len(_next_paths) > 0:
        var _chosen_path: Path3D = _next_paths.pick_random()
        if _chosen_path.is_blocked:
          _is_path_ahead_blocked = true
        else:
          get_parent_node_3d().remove_child(self)
          copy_path_settings(_chosen_path)
          _chosen_path.add_child(self)
          progress = 0

    var _local_vehicle_position := get_parent_node_3d().to_local(vehicle.global_position)
    var _closest_offset: float = parent_curve.get_closest_offset(_local_vehicle_position)
    var _closest_point: Vector3 = parent_curve.get_closest_point(_local_vehicle_position)
    var _distance_to_path := _closest_point.distance_to(_local_vehicle_position)
    var target_speed := path_max_speed

    if not _is_path_ahead_blocked:
      # Move this TrafficPathFollower forward along the path
      if _distance_to_path < path_distance_limit:
        progress = _closest_offset + (vehicle.speed * 0.75)
      else:
        progress = _closest_offset + 2

    # Get the difference in rotation on the Y axis between this TrafficPathFollower and its vehicle
    var _angle_to_vehicle := vehicle.global_transform.basis.z.signed_angle_to(global_transform.basis.z, Vector3.UP)
    if _distance_to_path < path_distance_limit and _angle_to_vehicle > -0.1 and _angle_to_vehicle < 0.1:
      _is_on_path = true
    else:
      _is_on_path = false

    # Set the vehicle's interest vectors and calculate the overall direction of interest
    vehicle.set_interest_vectors(global_transform.origin)
    vehicle.set_summed_interest_vector()
    var _turning_angle := vehicle.get_interest_angle()
    var _interest_vector := vehicle.summed_interest_vector

    # Check if this Follower is colliding with another Follower ahead
    var _vehicle_in_front := collision_area.get_overlapping_areas().any(func(_area: Area3D):
      return _area.get_parent_node_3d() != vehicle and _area.get_collision_layer_value(11)
    )

    # Adjust our target_speed based on direction of interest and turning angle
    # Note: vehicles face towards -Z, so a positive Z value means the interest vector is to the rear
    if _is_path_ahead_blocked or _vehicle_in_front:
      target_speed = 0.0
    elif _interest_vector.z > vehicle.steering_ray_length * 0.75: # Interest vector is strongly to the rear
      if not _is_on_path and vehicle.linear_velocity.z < min_speed and not _vehicle_in_front:
        target_speed = path_reversing_speed # If we are stopped and not on the road, start reversing
      else:
        target_speed = 0.0 # If we are on the road, slow to a stop
    elif _turning_angle < -PI / 16 or _turning_angle > PI / 16:
      target_speed *= 0.5 # Slow down for turn

    # Use our adjusted target_speed to set throttle and brake inputs
    if target_speed == path_reversing_speed: # We are trying to reverse
      if vehicle.speed < min_speed and not vehicle.is_shifting and vehicle.current_gear > -1:
        vehicle.shift(-1)
      elif vehicle.current_gear == -1:
        vehicle.throttle_input = 0.5
        vehicle.brake_input = 0.0
        vehicle.handbrake_input = 0.0
    else: # We are either stopped or going forward
      if vehicle.current_gear < 1 and not vehicle.is_shifting:
        vehicle.shift(1)
      elif target_speed == 0.0: # We are trying to stop
        vehicle.throttle_input = 0.0
        if vehicle.speed < min_speed:
          # Let off the brakes when we're stopped, because brake_input doubles as reversing input
          vehicle.brake_input = 0.0
        else:
          vehicle.brake_input = 1.0
        vehicle.handbrake_input = 1.0
      elif vehicle.speed < target_speed: # Our speed is lower than the target speed
        if vehicle.speed < target_speed / 2: # Our speed is less than half the target speed
          vehicle.throttle_input = 0.75
          vehicle.brake_input = 0.0
          vehicle.handbrake_input = 0.0
        else:
          vehicle.throttle_input = clampf(vehicle.speed / target_speed, 0.5, 1.0)
          vehicle.brake_input = 0.0
          vehicle.handbrake_input = 0.0
      elif vehicle.speed > target_speed * 1.2: # Our speed is higher than the target speed
        vehicle.throttle_input = 0.0
        vehicle.brake_input = brake_force
        vehicle.handbrake_input = 0.0
      else: # Set all inputs to 0 and coast
        vehicle.throttle_input = 0.0
        vehicle.brake_input = 0.0
        vehicle.handbrake_input = 0.0

    if vehicle.throttle_input > 0.0:
      vehicle.ignition_on = true

    # Steer to match the rotation of the nearest path position
    vehicle.steering_input = clampf(_turning_angle, -1.0, 1.0)
    if vehicle.current_gear == -1: # Flip steering input if we're reversing
      # TODO: subtract turning angle from either PI or -PI to allow reversing in a straight line
      # The vehicle will currently always steer while reversing, which is fine for getting un-stuck from props
      vehicle.steering_input = -vehicle.steering_input

  else: # Take our hands off the steering wheel until 3 tires are touching the ground
    vehicle.steering_input = 0.0
    vehicle.throttle_input = 0.0
