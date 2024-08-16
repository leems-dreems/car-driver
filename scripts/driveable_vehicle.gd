class_name DriveableVehicle extends Vehicle

var is_being_driven := false
var is_ai_on := false
var waiting_to_respawn := false
## The number of RayCast3Ds that this vehicle uses for close avoidance
var steering_ray_count: int = 16
## The index of the steering ray which points left. Set to 3/4 of `steering_ray_count`
var steering_ray_index_left: int = 12
## The index of the steering ray which points right. Set to 1/4 of `steering_ray_count`
var steering_ray_index_right: int = 4
## The index of the steering ray which points behind. Set to 1/2 of `steering_ray_count`
var steering_ray_index_behind: int = 8
## The radius for close avoidance steering raycasts
var steering_ray_length := 8
## The maximum length that the antenna raycasts will extend
var max_antenna_length := 16
## The minimum length of the antenna raycasts
var min_antenna_length := 8
var antenna_angle := PI / 32
# Multiplier applied to the opposite vector when a steering raycast collides with something
var avoidance_multiplier := 2
# Multiplier applied to the side & behind vectors when an antenna raycast collides with something
var antenna_multiplier := 32
var left_antenna_mesh: MeshInstance3D
var right_antenna_mesh: MeshInstance3D
var antenna_raycasts: Array[RayCast3D] = []
var steering_raycasts: Array[RayCast3D] = []
var interest_vectors: Array[Vector3] = []
## The localized vector of the overall direction of interest for this vehicle's AI
var summed_interest_vector := Vector3.ZERO
## The group that steering & avoidance raycasts belong to, used for cleanup when stopping AI
var steering_ray_group := "SteeringRayCast"
## The collision layers this vehicle's steering rays collide with
var steering_ray_collision_masks: Array[int] = [1, 2, 5, 7, 8]
var interest_direction_mesh: MeshInstance3D
# Debug
var _show_antennae := false
var raycast_debug_material := preload('res://assets/materials/raycast_debug.tres')
@onready var debug_label: Label3D = $DebugLabel3D
@onready var door_left: RigidBody3D = $ColliderBits/OpenDoorLeft
@onready var door_right: RigidBody3D = $ColliderBits/OpenDoorRight


func _ready () -> void:
  super()
  $ColliderBits/EnterCarCollider.vehicle = self
  await get_tree().create_timer(0.2).timeout
  unfreeze_bodies()
  return


func _process(_delta: float) -> void:
  # Update the debug label, if it's set to visible
  if debug_label.visible:
    if is_ai_on:
      debug_label.text = "Speed: " + "%.2f" % speed + "\n"
      debug_label.text += "Accel: " + "%.2f" % throttle_input + "\n"
      debug_label.text += "Brake: " + "%.2f" % brake_input + "\n"
      debug_label.text += "Steer: " + "%.2f" % steering_input
    else:
      debug_label.text = ""


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
    # Delete existing AI raycasts
    for _node: Node in get_children():
      if _node is RayCast3D and _node.is_in_group(steering_ray_group):
        _node.enabled = false
        _node.queue_free()
    steering_raycasts = []
    antenna_raycasts = []
    # Add steering raycasts for close avoidance
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
    # Add antenna raycasts for far avoidance
    for i: int in [-1, 1]:
      var _new_raycast := RayCast3D.new()
      _new_raycast.add_to_group(steering_ray_group)
      _new_raycast.position = Vector3.ZERO
      for _mask_value in steering_ray_collision_masks:
        _new_raycast.set_collision_mask_value(_mask_value, true)
      var _angle := i * antenna_angle
      _new_raycast.target_position = Vector3.FORWARD.rotated(Vector3.UP, _angle) * max_antenna_length
      add_child(_new_raycast)
      antenna_raycasts.push_back(_new_raycast)

      if _show_antennae:
        # Add visible antenna meshes
        var _line_mesh := MeshInstance3D.new()
        var _cylinder_mesh := CylinderMesh.new()
        _cylinder_mesh.height = max_antenna_length
        _cylinder_mesh.top_radius = 0.05
        _cylinder_mesh.bottom_radius = 0.05
        _line_mesh.mesh = _cylinder_mesh
        _line_mesh.position = _new_raycast.target_position / 2
        _line_mesh.rotate_x(PI / 2)
        _line_mesh.rotate_y(_angle)
        _line_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
        _line_mesh.set_surface_override_material(0, raycast_debug_material)
        add_child(_line_mesh)
        if _new_raycast.target_position.x < 0:
          left_antenna_mesh = _line_mesh
        else:
          right_antenna_mesh = _line_mesh

  for _raycast in steering_raycasts:
    _raycast.enabled = true
  for _raycast in antenna_raycasts:
    _raycast.enabled = true
  return

## Disables AI for this vehicle
func stop_ai() -> void:
  is_ai_on = false
  for _node: Node in get_children():
    if _node is RayCast3D and _node.is_in_group(steering_ray_group):
      _node.enabled = false
  return

## Calculate the amount of interest in each direction by comparing it to the target vector
func set_interest_vectors(_target_global_position: Vector3) -> void:
  var _target_position := to_local(_target_global_position)
  _target_position.y = 0
  _target_position = _target_position.normalized()
  interest_vectors = []
  # Loop through raycasts and compare their normalized vector to the normalized & localized target vector
  for _raycast in steering_raycasts:
    # The dot product of two aligned vectors is 1, and for two perpendicular vectors it’s 0
    var _interest_amount := _raycast.target_position.normalized().dot(_target_position)
    _interest_amount = maxf(0, _interest_amount)
    interest_vectors.push_back(_raycast.target_position.normalized() * _interest_amount)
  # Loop through raycasts again and check for danger to avoid
  var i := 0
  for _raycast in steering_raycasts:
    if _raycast.is_colliding():
      # Use the distance to the collision point to reduce the aligned interest vector
      var _danger_distance: float = _raycast.get_collision_point().distance_to(_raycast.global_position)
      var _danger_amount = clampf(_danger_distance / steering_ray_length, 0.01, 1.0)
      interest_vectors[i] *= _danger_amount
      # Multiply the vector which points away from the danger
      if i <= (steering_ray_index_behind) - 1:
        interest_vectors[i + (steering_ray_index_behind)] /= _danger_amount * avoidance_multiplier
      else:
        interest_vectors[i - (steering_ray_index_behind)] /= _danger_amount * avoidance_multiplier
    i += 1
  # Check "antenna" raycasts
  var _danger_amount_left := 0.0
  var _danger_amount_right := 0.0
  var current_antenna_length := clampf(speed, min_antenna_length, max_antenna_length)
  for _raycast in antenna_raycasts:
    if _raycast.target_position.x < 0:
      var _antenna_position := Vector3.FORWARD.rotated(Vector3.UP, 1 * antenna_angle) * current_antenna_length
      _raycast.target_position = _antenna_position
      if _show_antennae:
        left_antenna_mesh.mesh.height = current_antenna_length
        left_antenna_mesh.position = _antenna_position / 2
    else:
      var _antenna_position := Vector3.FORWARD.rotated(Vector3.UP, -1 * antenna_angle) * current_antenna_length
      _raycast.target_position = _antenna_position
      if _show_antennae:
        right_antenna_mesh.mesh.height = current_antenna_length
        right_antenna_mesh.position = _antenna_position / 2
    if _raycast.is_colliding():
      var _danger_distance: float = _raycast.get_collision_point().distance_to(_raycast.global_position)
      if _raycast.target_position.x < 0:
        _danger_amount_left = 1 - clampf(_danger_distance / current_antenna_length, 0.0, 1.0)
      else:
        _danger_amount_right = 1 - clampf(_danger_distance / current_antenna_length, 0.0, 1.0)
  if _show_antennae:
    left_antenna_mesh.transparency = 1 - clampf(_danger_amount_left, 0.05, 1.0)
    right_antenna_mesh.transparency = 1 - clampf(_danger_amount_right, 0.05, 1.0)
  if _danger_amount_left > 0.0:
    interest_vectors[steering_ray_index_right] *= _danger_amount_left * antenna_multiplier
  if _danger_amount_right > 0.0:
    interest_vectors[steering_ray_index_left] *= _danger_amount_right * antenna_multiplier
  if _danger_amount_left > 0.0 or _danger_amount_right > 0.0:
    interest_vectors[steering_ray_index_behind].z = maxf(1.0, interest_vectors[steering_ray_index_behind].z)
    interest_vectors[steering_ray_index_behind] *= (_danger_amount_left + _danger_amount_right) * antenna_multiplier
  return

## Sum up our interest vectors to get the direction of travel
func set_summed_interest_vector() -> void:
  var _summed_interest_vector := Vector3.ZERO
  for _interest_vector in interest_vectors:
    _summed_interest_vector += _interest_vector
  summed_interest_vector = _summed_interest_vector
  return

## Get the angle difference on the Y axis between the car's rotation and the interest vector
func get_interest_angle() -> float:
  return Vector3.FORWARD.signed_angle_to(summed_interest_vector, Vector3.UP)
