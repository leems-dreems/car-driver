class_name ContextualSteeringUnit
extends Node3D
## Uses a number of raycasts to calculate an 'interest vector' for the parent
## vehicle, using the 'context-based steering' technique.

var current_speed: float
var is_ai_on := false
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
var antenna_raycasts: Array[RayCast3D] = []
var steering_raycasts: Array[RayCast3D] = []
var interest_vectors: Array[Vector3] = []
## The localized vector of the overall direction of interest for this vehicle's AI
var summed_interest_vector := Vector3.ZERO
## The group that steering & avoidance raycasts belong to, used for cleanup when stopping AI
var steering_ray_group := "SteeringRayCast"
## The collision layers this vehicle's steering rays collide with
var steering_ray_collision_masks: Array[int] = [2, 5, 7, 8, 11]


func enable_raycasting() -> void:
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
			_new_raycast.collision_mask = 0
			for _mask_value in steering_ray_collision_masks: # 1235
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
			_new_raycast.collision_mask = 0
			for _mask_value in steering_ray_collision_masks:
				_new_raycast.set_collision_mask_value(_mask_value, true)
			var _angle := i * antenna_angle
			_new_raycast.target_position = Vector3.FORWARD.rotated(Vector3.UP, _angle) * max_antenna_length
			_new_raycast.debug_shape_custom_color = Color(0, 1, 0, 1)
			add_child(_new_raycast)
			antenna_raycasts.push_back(_new_raycast)

	for _raycast in steering_raycasts:
		_raycast.enabled = true
	for _raycast in antenna_raycasts:
		_raycast.enabled = true
	return

## Disable raycasting for this vehicle.
func disable_raycasting() -> void:
	is_ai_on = false
	for _node: Node in get_children():
		if _node is RayCast3D and _node.is_in_group(steering_ray_group):
			_node.enabled = false
	return

## Calculate the amount of interest in each direction by comparing it to the target vector
func get_interest_vector(_target_global_position: Vector3) -> Vector3:
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
		_raycast.enabled = true
		_raycast.force_raycast_update()
		if _raycast.is_colliding():
			# Use the distance to the collision point to reduce the aligned interest vector
			var _danger_distance: float = _raycast.get_collision_point().distance_to(_raycast.global_position)
			var _danger_amount = clampf(_danger_distance / steering_ray_length, 0.01, 1.0)
			interest_vectors[i] *= _danger_amount
			# Multiply the vector which points away from the danger
			if i <= steering_ray_index_behind - 1:
				interest_vectors[i + steering_ray_index_behind] /= _danger_amount * avoidance_multiplier
			else:
				interest_vectors[i - steering_ray_index_behind] /= _danger_amount * avoidance_multiplier
		#_raycast.enabled = false
		i += 1
	# Check "antenna" raycasts
	var _danger_amount_left := 0.0
	var _danger_amount_right := 0.0
	var current_antenna_length := clampf(current_speed, min_antenna_length, max_antenna_length)
	for _raycast in antenna_raycasts:
		_raycast.enabled = true
		_raycast.force_raycast_update()
		if _raycast.target_position.x < 0:
			var _antenna_position := Vector3.FORWARD.rotated(Vector3.UP, 1 * antenna_angle) * current_antenna_length
			_raycast.target_position = _antenna_position
		else:
			var _antenna_position := Vector3.FORWARD.rotated(Vector3.UP, -1 * antenna_angle) * current_antenna_length
			_raycast.target_position = _antenna_position
		if _raycast.is_colliding():
			var _danger_distance: float = _raycast.get_collision_point().distance_to(_raycast.global_position)
			if _raycast.target_position.x < 0:
				_danger_amount_left = 1 - clampf(_danger_distance / current_antenna_length, 0.0, 1.0)
			else:
				_danger_amount_right = 1 - clampf(_danger_distance / current_antenna_length, 0.0, 1.0)
		#_raycast.enabled = false
	if _danger_amount_left > 0.0:
		interest_vectors[steering_ray_index_right] *= _danger_amount_left * antenna_multiplier
	if _danger_amount_right > 0.0:
		interest_vectors[steering_ray_index_left] *= _danger_amount_right * antenna_multiplier
	if _danger_amount_left > 0.0 or _danger_amount_right > 0.0:
		interest_vectors[steering_ray_index_behind].z = maxf(1.0, interest_vectors[steering_ray_index_behind].z)
		interest_vectors[steering_ray_index_behind] *= (_danger_amount_left + _danger_amount_right) * antenna_multiplier

	var _summed_interest_vector := Vector3.ZERO
	for _interest_vector in interest_vectors:
		_summed_interest_vector += _interest_vector
	summed_interest_vector = _summed_interest_vector

	return summed_interest_vector

## Get the angle difference on the Y axis between the car's rotation and the interest vector
func get_interest_angle() -> float:
	return Vector3.FORWARD.signed_angle_to(summed_interest_vector, Vector3.UP)
