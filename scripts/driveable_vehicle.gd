class_name DriveableVehicle extends Vehicle

var is_being_driven := false
var is_ai_on := false
var starting_origin: Vector3
var starting_basis: Basis
var waiting_to_respawn := false
var steering_ray_count : int = 32
var steering_ray_distance := 8
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
      _new_raycast.position = Vector3(0, 2, 0)
      for _mask_value in steering_ray_collision_masks:
        _new_raycast.set_collision_mask_value(_mask_value, true)
      var _angle := (i * (2 * PI)) / steering_ray_count
      _new_raycast.target_position = Vector3.FORWARD.rotated(Vector3.UP, _angle) * steering_ray_distance
      add_child(_new_raycast)
      steering_raycasts.push_back(_new_raycast)
  for _raycast in steering_raycasts:
    _raycast.enabled = true

  # Add interest direction pointer mesh
  interest_direction_mesh = MeshInstance3D.new()
  var _cylinder_mesh := CylinderMesh.new()
  _cylinder_mesh.height = 0.01
  _cylinder_mesh.top_radius = 0.05
  _cylinder_mesh.bottom_radius = 0.05
  interest_direction_mesh.mesh = _cylinder_mesh
  interest_direction_mesh.rotate_x(PI / 2)
  add_child(interest_direction_mesh)

  return

## Disables AI for this vehicle
func stop_ai() -> void:
  is_ai_on = false
  for _node: Node in get_children():
    if _node is RayCast3D and _node.is_in_group(steering_ray_group):
      _node.enabled = false
  return

## Calculate the amount of interest in each direction
func set_interest_vectors(_path_vector: Vector3) -> void:
  _path_vector = _path_vector.normalized()
  interest_vectors = []
  for _raycast in steering_raycasts:
    # The dot product of two aligned vectors is 1, and for two perpendicular vectors it’s 0
    var _interest_amount := _raycast.target_position.normalized().dot(_path_vector)
    _interest_amount = maxf(0, _interest_amount)
    var _danger_amount := 0.0
    if _raycast.is_colliding():
      # TODO: Danger amount should decrease with distance from collision point
      _danger_amount = 1.0
    interest_vectors.push_back(_raycast.target_position.normalized() * _interest_amount * (1 - _danger_amount))
  return

## Sum up our interest vectors to get the direction of travel
func set_summed_interest_vector() -> void:
  var _summed_interest_vector := Vector3.ZERO
  for _interest_vector in interest_vectors:
    _summed_interest_vector += _interest_vector
  summed_interest_vector = _summed_interest_vector.reflect(Vector3.FORWARD)

  interest_direction_mesh.position = (_summed_interest_vector / 2)
  print(_summed_interest_vector)
  interest_direction_mesh.rotation.y = Vector3.FORWARD.signed_angle_to(_summed_interest_vector, Vector3.UP)
  interest_direction_mesh.mesh.height = _summed_interest_vector.length()

  return

## Get the angle difference on the Y axis between the car's rotation and the interest vector
func get_interest_vector_y_difference() -> float:
  return transform.looking_at(to_global(summed_interest_vector)).basis.rotated(Vector3.UP, PI).get_euler().y
