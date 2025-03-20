class_name DriveableVehicle extends Vehicle

enum SurfaceTypes { ROAD = 0, GRASS = 1, DIRT = 2, SAND = 3, ROCK = 4 }

@export var lights_on := false
@export var downforce_multiplier := 4.0
var vehicle_name := "[Vehicle Name]"
var vehicle_category := "[Vehicle Category]"
var headlight_energy := 10.0
var brake_light_energy := 5.0
var reverse_light_energy := 1.0
var is_being_driven := false
var is_ai_on := false
var waiting_to_respawn := false
## Vehicle will calculate & play "scrape" effects if this is true
var play_scrape_effects := false
## Damage this vehicle can take before setting on fire and exploding
@export var max_hit_points := 5.0
@export var impact_force_threshold_1 := 0.3
@export var impact_force_threshold_2 := 0.6
@export var impact_force_threshold_3 := 1.5
var current_hit_points: float
var has_caught_fire := false
## Timer that runs after this vehicle is requested to stop by something else
var request_stop_timer: SceneTreeTimer = null
## Velocity to apply to the car after spawning in
var _starting_velocity: Vector3 = Vector3.ZERO
## Velocity as of the last physics tick
var _previous_velocity: Vector3 = Vector3.ZERO
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
## Show the debug label for this vehicle
var show_debug_label := false
@onready var debug_label: Label3D = $DebugLabel3D
@onready var body_mesh_instance: MeshInstance3D = $Body
@onready var door_left: CarDoor = $ColliderBits/DoorLeft/OpenDoorLeft
@onready var door_right: CarDoor = $ColliderBits/DoorRight/OpenDoorRight
# Lights
@onready var headlight_left: SpotLight3D = $HeadlightLeft/SpotLight3D
@onready var headlight_right: SpotLight3D = $HeadlightRight/SpotLight3D
#@onready var brake_light_left: OmniLight3D = $BrakeLightLeft
#@onready var brake_light_right: OmniLight3D = $BrakeLightRight
#@onready var reverse_light_left: OmniLight3D = $ReverseLightLeft
#@onready var reverse_light_right: OmniLight3D = $ReverseLightRight
@export var brake_light_left_mesh: MeshInstance3D
@export var brake_light_right_mesh: MeshInstance3D
@export var reverse_light_left_mesh: MeshInstance3D
@export var reverse_light_right_mesh: MeshInstance3D
# Audio streams
@onready var collision_audio_1: AudioStreamPlayer3D = $AudioStreams/CollisionAudio1
# Particle emitters
@onready var engine_black_smoke_emitter: GPUParticles3D = $EngineSmokeBlack
@onready var engine_white_smoke_emitter: GPUParticles3D = $EngineSmokeWhite
@onready var engine_fire_emitter: GPUParticles3D = $Fire
# Explosion
var explosion: Explosion = null
const explosion_scene := preload("res://effects/explosion.tscn")
@export var explosion_position: Vector3


func _ready () -> void:
	super()
	if show_debug_label:
		debug_label.visible = true
	if lights_on:
		headlight_left.light_energy = headlight_energy
		headlight_right.light_energy = headlight_energy
	current_hit_points = max_hit_points
	await get_tree().create_timer(0.2).timeout
	unfreeze_bodies()
	linear_velocity = _starting_velocity
	return


func _process(_delta: float) -> void:
	# Update the debug label, if it's set to visible
	if debug_label.visible:
		debug_label.text = "Speed: " + "%.2f" % speed + "\n"
		debug_label.text += "Gear: " + "%.2f" % current_gear + "\n"
		debug_label.text += "Accel: " + "%.2f" % throttle_amount + "\n"
		debug_label.text += "Cltch: " + "%.2f" % clutch_amount + "\n"
		debug_label.text += "Brake: " + "%.2f" % brake_amount + "\n"
		debug_label.text += "RPM: " + "%.2f" % motor_rpm + "\n"
		debug_label.text += "Steer: " + "%.2f" % steering_amount


func _physics_process(delta: float) -> void:
	super(delta)
	# Record current velocity, to refer to when processing collision signals
	_previous_velocity = Vector3(linear_velocity)
	# Apply downforce if 2 or more wheels are touching the ground
	#if get_wheel_contact_count() > 1:
		# Get Z rotation, then get the square-root of its square to ensure that it's positive
		#var _angle_from_upright := (PI / 2) - sqrt(pow(rotation.z, 2))
		#if _angle_from_upright > 0:
			#apply_central_force(-basis.y * _angle_from_upright * downforce_multiplier * pow(speed, 2))
	brake_light_left_mesh.transparency = 1.0 - brake_amount
	brake_light_right_mesh.transparency = 1.0 - brake_amount
	if current_gear == -1:
		reverse_light_left_mesh.transparency = lerpf(reverse_light_left_mesh.transparency, 0.0, delta * 10)
		reverse_light_right_mesh.transparency = lerpf(reverse_light_right_mesh.transparency, 0.0, delta * 10)
	else:
		#if is_being_driven:
			#var _current_reverse_light_energy := lerpf(reverse_light_left.light_energy, 0.0, delta * 10)
			#reverse_light_left.light_energy = _current_reverse_light_energy
			#reverse_light_right.light_energy = _current_reverse_light_energy
		reverse_light_left_mesh.transparency = lerpf(reverse_light_left_mesh.transparency, 1.0, delta * 10)
		reverse_light_right_mesh.transparency = lerpf(reverse_light_right_mesh.transparency, 1.0, delta * 10)
	var _target_headlight_energy := 0.0
	if lights_on:
		_target_headlight_energy = headlight_energy
	var _current_headlight_energy := lerpf(headlight_left.light_energy, _target_headlight_energy, delta * 10)
	headlight_left.light_energy = _current_headlight_energy
	headlight_right.light_energy = _current_headlight_energy
	# Adjust engine smoke level to reflect damage
	var damage_ratio := 1.0 - (current_hit_points / max_hit_points)
	if damage_ratio > 0.1:
		engine_white_smoke_emitter.amount_ratio = damage_ratio
	if damage_ratio > 0.5:
		engine_black_smoke_emitter.amount_ratio = damage_ratio
	if damage_ratio > 0.75:
		engine_white_smoke_emitter.amount_ratio = 0
	# Turn engine off & catch fire if hit points are low
	if current_hit_points <= 0:
		ignition_on = false
		if not engine_fire_emitter.emitting and not has_caught_fire:
			has_caught_fire = true
			engine_fire_emitter.emitting = true
			await get_tree().create_timer(5.0).timeout
			engine_fire_emitter.emitting = false
			explode()
	return

## Connect the vehicle's `body_entered` signal to this method
func _on_body_entered(_body: Node) -> void:
	if _body is StaticBody3D or _body is CSGShape3D or _body is RigidBody3D or _body is Terrain3D:
		if collision_audio_1.playing == false:
			var _velocity_change := _previous_velocity - linear_velocity
			var _impact_force := _velocity_change.length() * 0.1
			if _impact_force > impact_force_threshold_1:
				react_to_collision(_velocity_change)
				collision_audio_1.volume_db = linear_to_db(clampf(_impact_force, 0.0, 1.0))
				collision_audio_1.play()
				current_hit_points -= _impact_force
	return


func respawn() -> void:
	waiting_to_respawn = true
	return


func explode() -> void:
	explosion = explosion_scene.instantiate()
	add_child(explosion)
	explosion.position = explosion_position
	explosion.top_level = true
	explosion.start_explosion()
	apply_burnt_material()
	await get_tree().create_timer(7.0).timeout
	despawn()
	return

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

## Disables AI for this vehicle
func stop_ai() -> void:
	is_ai_on = false
	for _node: Node in get_children():
		if _node is RayCast3D and _node.is_in_group(steering_ray_group):
			_node.enabled = false
	return


func despawn() -> void:
	queue_free()
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
		_raycast.enabled = true
		_raycast.force_raycast_update()
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
		_raycast.enabled = false
		i += 1
	# Check "antenna" raycasts
	var _danger_amount_left := 0.0
	var _danger_amount_right := 0.0
	var current_antenna_length := clampf(speed, min_antenna_length, max_antenna_length)
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
		_raycast.enabled = false
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

## Override to apply a different material when the vehicle has exploded
func apply_burnt_material() -> void:
	pass

## Ask this vehicle to stop
func request_stop(_duration: float = 5.0) -> void:
	if request_stop_timer == null:
		request_stop_timer = get_tree().create_timer(_duration)
		request_stop_timer.timeout.connect(func():
			request_stop_timer = null
		)
	else:
		request_stop_timer.time_left = _duration


## Virtual method. Override to e.g. play FX, detach parts when colliding
func react_to_collision(_velocity_change: Vector3) -> void:
	pass
