class_name DriveableVehicle extends Vehicle

enum SurfaceTypes { ROAD = 0, GRASS = 1, DIRT = 2, SAND = 3, ROCK = 4 }

@export var lights_on := false
@export var downforce_multiplier := 4.0
@export var owned_by_player := false
var vehicle_name := "[Vehicle Name]"
var vehicle_category := "[Vehicle Category]"
var headlight_energy := 10.0
var brake_light_energy := 5.0
var reverse_light_energy := 1.0
var _previous_handbrake_input := 0.0
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
@export var astar_traffic_manager: AStarTrafficManager
@export var astar_road_agent: AStarRoadAgent
@export var contextual_steering_unit: ContextualSteeringUnit
var current_hit_points: float
var has_caught_fire := false
## Timer that runs after this vehicle is requested to stop by something else
var request_stop_timer: SceneTreeTimer = null
## Velocity to apply to the car after spawning in
var _starting_velocity: Vector3 = Vector3.ZERO
## Velocity as of the last physics tick
var _previous_velocity: Vector3 = Vector3.ZERO

## The speed limit on this road
var path_max_speed := 20.0
## The speed limit when reversing on this road
var path_reversing_speed := 5.0
## Vehicle will try to stay within this distance from the path
var path_distance_limit := 10.0
## Vehicle is considered to be stopped when below this speed
var min_speed := 0.1
## How much braking should be applied
var braking_multiplier := 0.5
## Indicates that this vehicle is close to the path and facing the right direction
var is_on_path := false
## This vehicle will not calculate avoidance & inputs for the next X ticks
var ticks_to_skip: int = 0
## Increased by the TrafficManager when this prop fails a hearing & line-of-sight check
var despawn_weight := 0.0

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
@onready var handbrake_up_audio := $HandbrakeUpAudio
@onready var handbrake_down_audio := $HandbrakeDownAudio
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
	handbrake_input = 1.0
	_previous_handbrake_input = handbrake_input
	current_hit_points = max_hit_points
	await get_tree().create_timer(0.2).timeout
	unfreeze_bodies()
	linear_velocity = _starting_velocity
	return


func _process(_delta: float) -> void:
	# Update the debug label, if it's set to visible
	if debug_label.visible:
		debug_label.text = "Speed: " + "%.2f" % speed + "m/s\n"
		debug_label.text += "Speed: " + "%.2f" % (speed * 2.23694) + "mph\n"
		debug_label.text += "Gear: " + "%.2f" % current_gear + "\n"
		#debug_label.text += "Accel: " + "%.2f" % throttle_amount + "\n"
		#debug_label.text += "Cltch: " + "%.2f" % clutch_amount + "\n"
		#debug_label.text += "Brake: " + "%.2f" % brake_amount + "\n"
		#debug_label.text += "RPM: " + "%.2f" % motor_rpm + "\n"
		#debug_label.text += "Steer: " + "%.2f" % steering_amount


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
	
	if handbrake_input > _previous_handbrake_input:
		handbrake_up_audio.play()
	elif handbrake_input < _previous_handbrake_input:
		handbrake_down_audio.play()
	_previous_handbrake_input = handbrake_input

	if astar_road_agent and len(astar_road_agent.id_path) > 0:
		set_inputs()

	return


func process_transmission(delta : float):
	if is_shifting:
		if delta_time > complete_shift_delta_time:
			complete_shift()
		return
	
	## For automatic transmissions to determine when to shift the current wheel speed and 
	## what the wheel speed would be without slip are used. This allows vehicles to spin the
	## tires without immidiately shifting to the next gear.
	
	if automatic_transmission:
		var reversing := false
		var ideal_wheel_spin := speed / average_drive_wheel_radius
		var drivetrain_spin := get_drivetrain_spin()
		var real_wheel_spin := drivetrain_spin * get_gear_ratio(current_gear)
		var current_ideal_gear_rpm := gear_ratios[current_gear - 1] * final_drive * ideal_wheel_spin * ANGULAR_VELOCITY_TO_RPM
		var current_real_gear_rpm = real_wheel_spin * ANGULAR_VELOCITY_TO_RPM
		
		if current_gear == -1:
			reversing = true
		
		if not reversing:
			var next_gear_rpm := 0.0
			if current_gear < gear_ratios.size():
				next_gear_rpm = get_gear_ratio(current_gear + 1) * ideal_wheel_spin * ANGULAR_VELOCITY_TO_RPM
			var previous_gear_rpm := 0.0
			if current_gear - 1 > 0:
				previous_gear_rpm = get_gear_ratio(current_gear - 1) * maxf(drivetrain_spin, ideal_wheel_spin) * ANGULAR_VELOCITY_TO_RPM
			
			
			if current_gear < gear_ratios.size():
				if current_gear > 0:
					if current_ideal_gear_rpm > max_rpm:
						if delta_time - last_shift_delta_time > shift_time:
							shift(1)
					if current_ideal_gear_rpm > max_rpm * 0.8 and current_real_gear_rpm > max_rpm:
						if delta_time - last_shift_delta_time > shift_time:
							shift(1)
				elif current_gear == 0 and motor_rpm > clutch_out_rpm:
					shift(1)
			if current_gear - 1 > 0:
				if current_gear > 1 and previous_gear_rpm < 0.75 * max_rpm:
					if delta_time - last_shift_delta_time > shift_time:
						shift(-1)

		if brake_input > 0.75:
			if not reversing:
				if current_gear == 0 or local_velocity.z > 0.0:
					if delta_time - last_shift_delta_time > shift_time:
						if current_gear == 0:
							shift(-1)
						else:
							shift(-current_gear - 1)
			else:
				if current_gear == 0 or local_velocity.z < 0.0:
					if delta_time - last_shift_delta_time > shift_time:
						shift(1)


func shift(count : int):
	if is_shifting and current_gear + count >= 0:
		return
	
	## Handles gear change requests and timings
	requested_gear = current_gear + count
	
	if requested_gear <= gear_ratios.size() and requested_gear >= -1:
		if current_gear == 0:
			complete_shift()
		else:
			complete_shift_delta_time = delta_time + shift_time
			clutch_amount = 1.0
			is_shifting = true
			if count > 0:
				is_up_shifting = true

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


func start_navigating_to(global_target_position: Vector3) -> void:
	contextual_steering_unit.enable_raycasting()
	var id_path := astar_traffic_manager.get_route(global_position, global_target_position)
	astar_road_agent.set_id_path(id_path)
	return

## Update interest vectors & avoidance info for the vehicle, then adjust its inputs accordingly
func set_inputs() -> void:
	if ticks_to_skip > 0:
		ticks_to_skip -= 1
		return

	if get_wheel_contact_count() >= 3:
		var _is_path_ahead_blocked := false
		astar_road_agent.snap_to_nearest_offset(global_position)
		var _distance_to_path := global_position.distance_to(astar_road_agent.global_position)
		if _distance_to_path < path_distance_limit:
			astar_road_agent.advance_lane_offset(speed / 2)

		var target_speed := path_max_speed

		# Get the difference in rotation on the Y axis between this TrafficAgent and its vehicle
		var _angle_to_vehicle := global_transform.basis.z.signed_angle_to(global_transform.basis.z, Vector3.UP)
		if _distance_to_path < path_distance_limit and _angle_to_vehicle > -0.1 and _angle_to_vehicle < 0.1:
			is_on_path = true
		else:
			is_on_path = false

		# Set the vehicle's interest vectors and calculate the overall direction of interest
		var interest_vector := contextual_steering_unit.get_interest_vector(astar_road_agent.global_position)
		var turning_angle := Vector3.FORWARD.signed_angle_to(interest_vector, Vector3.UP)

		var _vehicle_in_front := astar_road_agent.collision_area.get_overlapping_bodies().any(func(_body: Node3D):
			return (_body is DriveableVehicle and _body != self) or _body is Player or _body is PlayerPhysicalBone
		)

		# Adjust our target_speed based on direction of interest and turning angle
		# Note: vehicles face towards -Z, so a positive Z value means the interest vector is to the rear
		if _is_path_ahead_blocked or _vehicle_in_front or request_stop_timer != null:
			target_speed = 0.0
		elif interest_vector.z > contextual_steering_unit.steering_ray_length * 0.75: # Interest vector is strongly to the rear
			if not is_on_path and linear_velocity.z < min_speed and not _vehicle_in_front:
				target_speed = path_reversing_speed # If we are stopped and not on the road, start reversing
			else:
				target_speed = 0.0 # If we are on the road, slow to a stop
		elif turning_angle < -PI / 16 or turning_angle > PI / 16:
			target_speed *= 0.5 # Slow down for turn

		# Use our adjusted target_speed to set throttle and brake inputs
		if target_speed == path_reversing_speed: # We are trying to reverse
			if speed < min_speed and not is_shifting and current_gear > -1:
				shift(-1)
			elif current_gear == -1:
				throttle_input = 0.5
				brake_input = 0.0
				handbrake_input = 0.0
		else: # We are either stopped or going forward
			if current_gear < 1 and not is_shifting:
				shift(1)
			elif target_speed == 0.0: # We are trying to stop
				throttle_input = 0.0
				if speed < min_speed:
					# Let off the brakes when we're stopped, because brake_input doubles as reversing input
					brake_input = 0.0
					ticks_to_skip = 10 # Skip the next 10 physics ticks
				else:
					brake_input = 1.0
				handbrake_input = 1.0
			elif speed < target_speed: # Our speed is lower than the target speed
				if speed < target_speed / 2: # Our speed is less than half the target speed
					throttle_input = 0.75
					brake_input = 0.0
					handbrake_input = 0.0
				else:
					throttle_input = 1.0 - clampf(speed / target_speed, 0.5, 1.0)
					brake_input = 0.0
					handbrake_input = 0.0
			elif speed > target_speed * 1.2: # Our speed is higher than the target speed
				throttle_input = 0.0
				brake_input = braking_multiplier
				handbrake_input = 0.0
			else: # Set all inputs to 0 and coast
				throttle_input = 0.0
				brake_input = 0.0
				handbrake_input = 0.0

		if throttle_input > 0.0:
			ignition_on = true

		# Steer to match the rotation of the nearest path position
		steering_input = clampf(turning_angle * 2, -1.0, 1.0)
		if current_gear == -1: # Flip steering input if we're reversing
			# TODO: subtract turning angle from either PI or -PI to allow reversing in a straight line
			# The vehicle will currently always steer while reversing, which is fine for getting un-stuck from props
			steering_input = -steering_input

	else: # Take our hands off the steering wheel until 3 tires are touching the ground
		steering_input = 0.0
		throttle_input = 0.0

	# Engage clutch if we're not throttling, to reduce oversteer
	clutch_input = 1.0 - throttle_input
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


func despawn() -> void:
	queue_free()
	return

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
