class_name DriveableVehicle extends Vehicle

var is_being_driven := false
var is_ai_on := false
var starting_origin: Vector3
var starting_basis: Basis
var waiting_to_respawn := false
var steering_ray_count : int = 32
var steering_ray_length := 8
var antenna_length := 16
var antenna_angle := PI / 32
var avoidance_multiplier := 2
var antenna_multiplier := 64
var left_antenna_mesh: MeshInstance3D
var right_antenna_mesh: MeshInstance3D
var antenna_raycasts: Array[RayCast3D] = []
var steering_raycasts: Array[RayCast3D] = []
var interest_vectors: Array[Vector3] = []
var summed_interest_vector := Vector3.ZERO
var steering_ray_group := "SteeringRayCast"
var steering_ray_collision_masks: Array[int] = [1, 2, 5, 7, 8]
var interest_direction_mesh: MeshInstance3D
@onready var door_left: RigidBody3D = $ColliderBits/OpenDoorLeft
@onready var door_right: RigidBody3D = $ColliderBits/OpenDoorRight


func _ready () -> void:
  super()
  starting_origin = global_position
  starting_basis = Basis(transform.basis)
  $ColliderBits/EnterCarCollider.vehicle = self
  await get_tree().create_timer(0.2).timeout
  unfreeze_bodies()
  return


func respawn () -> void:
  waiting_to_respawn = true

## Freeze the car, as well as the various bodies attached to it
func freeze_bodies() -> void:
  freeze = true
  door_left.top_level = false
  door_left.freeze = true
  door_right.top_level = false
  door_right.freeze = true
  return

## Unfreeze the car. Attached bodies seem to behave more realistically when set to be `top_level`
func unfreeze_bodies() -> void:
  freeze = false
  door_left.top_level = true
  door_left.freeze = false
  door_right.top_level = true
  door_right.freeze = false
  return

## Enables AI for this vehicle
func start_ai() -> void:
  is_ai_on = true
  # Check if first-time setup is required, and perform it if so
  if len(steering_raycasts) != steering_ray_count:
    for _node: Node in get_children():
      if _node is RayCast3D and _node.is_in_group(steering_ray_group):
        _node.enabled = false
        _node.queue_free()
    steering_raycasts = []
    for i: int in steering_ray_count:
      var _new_raycast := RayCast3D.new()
      _new_raycast.add_to_group(steering_ray_group)
      _new_raycast.position = Vector3(0, 0, 0)
      for _mask_value in steering_ray_collision_masks:
        _new_raycast.set_collision_mask_value(_mask_value, true)
      var _angle := (i * (2 * PI)) / steering_ray_count
      _new_raycast.target_position = Vector3.FORWARD.rotated(Vector3.UP, _angle) * steering_ray_length
      add_child(_new_raycast)
      steering_raycasts.push_back(_new_raycast)

   # Add antenna raycasts
    antenna_raycasts = []
    for i: int in [-1, 1]:
      var _new_raycast := RayCast3D.new()
      _new_raycast.add_to_group(steering_ray_group)
      _new_raycast.position = Vector3.ZERO
      for _mask_value in steering_ray_collision_masks:
        _new_raycast.set_collision_mask_value(_mask_value, true)
      var _angle := i * antenna_angle
      _new_raycast.target_position = Vector3.FORWARD.rotated(Vector3.UP, _angle) * antenna_length
      add_child(_new_raycast)
      antenna_raycasts.push_back(_new_raycast)
      var _line_mesh := MeshInstance3D.new()
      var _cylinder_mesh := CylinderMesh.new()
      _cylinder_mesh.height = antenna_length
      _cylinder_mesh.top_radius = 0.02
      _cylinder_mesh.bottom_radius = 0.02
      _line_mesh.mesh = _cylinder_mesh
      _line_mesh.position = _new_raycast.target_position / 2
      _line_mesh.rotate_x(PI / 2)
      _line_mesh.rotate_y(_angle)
      add_child(_line_mesh)
      if _new_raycast.target_position.x < 0:
        left_antenna_mesh = _line_mesh
      else:
        right_antenna_mesh = _line_mesh

  for _raycast in steering_raycasts:
    _raycast.enabled = true
  for _raycast in antenna_raycasts:
    _raycast.enabled = true

  ## Add interest direction pointer mesh
  #interest_direction_mesh = MeshInstance3D.new()
  #var _cylinder_mesh := CylinderMesh.new()
  #_cylinder_mesh.height = 0.01
  #_cylinder_mesh.top_radius = 0.05
  #_cylinder_mesh.bottom_radius = 0.05
  #interest_direction_mesh.mesh = _cylinder_mesh
  #interest_direction_mesh.rotate_x(PI / 2)
  #add_child(interest_direction_mesh)

  return

## Disables AI for this vehicle
func stop_ai() -> void:
  is_ai_on = false
  for _node: Node in get_children():
    if _node is RayCast3D and _node.is_in_group(steering_ray_group):
      _node.enabled = false
  return

## Calculate the amount of interest in each direction
func set_interest_vectors(_target_global_position: Vector3) -> void:
  var _target_position := to_local(_target_global_position)
  _target_position.y = 0
  _target_position = _target_position.normalized()
  interest_vectors = []
  for _raycast in steering_raycasts:
    # The dot product of two aligned vectors is 1, and for two perpendicular vectors it’s 0
    var _interest_amount := _raycast.target_position.normalized().dot(_target_position)
    _interest_amount = maxf(0, _interest_amount)
    interest_vectors.push_back(_raycast.target_position.normalized() * _interest_amount)

    # Loop through again looking for danger
  var i := 0
  for _raycast in steering_raycasts:
    if _raycast.is_colliding():
      var _danger_distance: float = _raycast.get_collision_point().distance_to(_raycast.global_position)
      var _danger_amount = clampf(_danger_distance / steering_ray_length, 0.01, 1.0)
      interest_vectors[i] *= _danger_amount
      if i <= (steering_ray_count / 2) - 1:
        interest_vectors[i + (steering_ray_count / 2)] /= _danger_amount * avoidance_multiplier
      else:
        interest_vectors[i - (steering_ray_count / 2)] /= _danger_amount * avoidance_multiplier
    i += 1

  # Check "antenna" raycasts
  var _danger_amount_left := 0.0
  var _danger_amount_right := 0.0
  for _raycast in antenna_raycasts:
    if _raycast.is_colliding():
      var _danger_distance: float = _raycast.get_collision_point().distance_to(_raycast.global_position)
      if _raycast.target_position.x < 0:
        _danger_amount_left = 1 - clampf(_danger_distance / antenna_length, 0.0, 1.0)
      else:
        _danger_amount_right = 1 - clampf(_danger_distance / antenna_length, 0.0, 1.0)
  left_antenna_mesh.transparency = 1 - clampf(_danger_amount_left, 0.1, 1.0)
  right_antenna_mesh.transparency = 1 - clampf(_danger_amount_right, 0.1, 1.0)
  if _danger_amount_left > 0.0:
    interest_vectors[steering_ray_count / 4] *= _danger_amount_left * antenna_multiplier
    interest_vectors[steering_ray_count / 2].z = maxf(1.0, interest_vectors[steering_ray_count / 2].z)
    interest_vectors[steering_ray_count / 2] *= _danger_amount_left * antenna_multiplier
  if _danger_amount_right > 0.0:
    interest_vectors[(steering_ray_count / 4) * 3] *= _danger_amount_right * antenna_multiplier
    interest_vectors[steering_ray_count / 2].z = maxf(1.0, interest_vectors[steering_ray_count / 2].z)
    interest_vectors[steering_ray_count / 2] *= _danger_amount_right * antenna_multiplier

  return

## Sum up our interest vectors to get the direction of travel
func set_summed_interest_vector() -> void:
  var _summed_interest_vector := Vector3.ZERO
  for _interest_vector in interest_vectors:
    _summed_interest_vector += _interest_vector
  summed_interest_vector = _summed_interest_vector

  #interest_direction_mesh.position = (summed_interest_vector / 2)
  #interest_direction_mesh.rotation.y = get_interest_angle()
  #interest_direction_mesh.mesh.height = summed_interest_vector.length()

  return

## Get the angle difference on the Y axis between the car's rotation and the interest vector
func get_interest_angle() -> float:
  return Vector3.FORWARD.signed_angle_to(summed_interest_vector, Vector3.UP)
