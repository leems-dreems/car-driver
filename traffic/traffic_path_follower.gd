class_name TrafficPathFollower extends PathFollow3D
## This class is instantiated by [TrafficPath] nodes, and acts as a guide for AI traffic vehicles.

@export var vehicle: DriveableVehicle = null
## Used to check if a vehicle can be spawned here
@onready var collision_area: Area3D = $Area3D
## This bool is flipped after this follower is moved, so that we can get overlapping bodies/areas
## during the next physics step
var just_moved := false
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
## Indicates that this vehicle is close to the path and facing the right direction
var _is_on_path := false

## Update interest vectors & avoidance info for the vehicle, then adjust its inputs accordingly
func set_inputs() -> void:
  if vehicle.get_wheel_contact_count() >= 3:
    var _closest_offset: float = parent_curve.get_closest_offset(vehicle.position)
    var _closest_point: Vector3 = parent_curve.get_closest_point(vehicle.position)
    var target_speed := path_max_speed
    var _distance_to_path := _closest_point.distance_to(vehicle.position)

    # Move this TrafficPathFollower forward along the path
    progress = _closest_offset + vehicle.speed
    # Get the difference in rotation on the Y axis between this TrafficPathFollower and its vehicle
    var _angle_to_vehicle := vehicle.transform.basis.z.signed_angle_to(transform.basis.z, Vector3.UP)
    if _distance_to_path < path_distance_limit and _angle_to_vehicle > -0.1 and _angle_to_vehicle < 0.1:
      _is_on_path = true
    else:
      _is_on_path = false

    # Set the vehicle's interest vectors and calculate the average direction of interest
    vehicle.set_interest_vectors(global_transform.origin)
    vehicle.set_summed_interest_vector()
    var _turning_angle := vehicle.get_interest_angle()
    var _interest_vector := vehicle.summed_interest_vector

    if _interest_vector.z > vehicle.steering_ray_length * 0.75:
      if not _is_on_path and vehicle.linear_velocity.z < min_speed:
        target_speed = path_reversing_speed
      else:
        target_speed = 0.0
    elif _turning_angle < -PI / 8 or _turning_angle > PI / 8:
      target_speed *= 0.25

    if target_speed == path_reversing_speed:
      if vehicle.speed < 0.5 and not vehicle.is_shifting and not vehicle.current_gear == -1:
        vehicle.shift(-1)
      else:
        vehicle.throttle_input = 0.5
        vehicle.brake_input = 0.0
        vehicle.handbrake_input = 0.0
    else:
      if vehicle.current_gear < 1 and not vehicle.is_shifting:
        vehicle.shift(1)
      elif target_speed == 0.0:
        vehicle.throttle_input = 0.0
        if vehicle.speed < min_speed:
          vehicle.brake_input = 0.0
        else:
          vehicle.brake_input = 1.0
        vehicle.handbrake_input = 1.0
      elif vehicle.speed < target_speed:
        if vehicle.speed < target_speed / 2:
          vehicle.throttle_input = 0.75
          vehicle.brake_input = 0.0
          vehicle.handbrake_input = 0.0
        else:
          vehicle.throttle_input = clampf(vehicle.speed / target_speed, 0.5, 1.0)
          vehicle.brake_input = 0.0
          vehicle.handbrake_input = 0.0
      elif vehicle.speed > target_speed * 1.2:
        vehicle.throttle_input = 0.0
        vehicle.brake_input = brake_force
        ## How much braking should be applied = brake_force
        vehicle.handbrake_input = 0.0
      else:
        vehicle.throttle_input = 0.0
        vehicle.brake_input = 0.0
        vehicle.handbrake_input = 0.0

    if vehicle.throttle_input > 0.0:
      vehicle.ignition_on = true

    # Steer to match the rotation of the nearest path position
    if _turning_angle > -PI * 0.8 and _turning_angle < PI * 0.8:
      vehicle.steering_input = clampf(_turning_angle, -1.0, 1.0)
    else:
      vehicle.steering_input = 0.0
    if vehicle.current_gear == -1:
      vehicle.steering_input = -vehicle.steering_input
  else:
    vehicle.steering_input = 0.0
    vehicle.throttle_input = 0.0
