class_name Pedestrian extends RigidBody3D

## Character maximum run speed on the ground.
@export var move_speed := 8.0
## Movement acceleration (how fast character achieve maximum speed)
@export var acceleration := 20.0
## Jump impulse
@export var jump_initial_impulse := 8.0
## Jump impulse when player keeps pressing jump
@export var jump_additional_force := 24.0
## Character model rotation speed
@export var rotation_speed := 12.0
## Minimum horizontal speed on the ground. This controls when the character's animation tree changes
## between the idle and running states.
@export var stopping_speed := 1.0
## Speed to switch from walking to running
@export var running_speed := 4.0
## Minimum impact force that will cause character to start ragdolling
@export var impact_resistance := 10.0
## Minimum time the character will ragdoll for after getting hit
@export var min_ragdoll_time := 4.0

@onready var _rotation_root: Node3D = $square_guy
#@onready var ragdoll_skeleton: Skeleton3D = $DummyRigPhysical/Rig/Skeleton3D
#@onready var _ragdoll_tracker_bone: PhysicalBone3D = $"DummyRigPhysical/Rig/Skeleton3D/Physical Bone spine"
#@onready var _bone_simulator: PhysicalBoneSimulator3D = $CharacterRotationRoot/DummySkin_Physical/Rig/Skeleton3D/PhysicalBoneSimulator3D
@onready var _step_sound: AudioStreamPlayer3D = $StepSound
@onready var _landing_sound: AudioStreamPlayer3D = $LandingSound
@onready var ground_collider := $GroundCollider
@onready var _nav_agent: NavigationAgent3D = $NavigationAgent3D
@onready var _animation_tree: AnimationTree = $square_guy/AnimationTree
@onready var _playback: AnimationNodeStateMachinePlayback = _animation_tree.get("parameters/playback")

var _move_direction := Vector3.ZERO
var _is_on_floor_buffer := false

var is_ragdolling := false
var is_waiting_to_reset := false
## Target position to move towards, in global coordinates
var _target_position: Vector3
## Velocity as of the last physics tick
var _previous_velocity: Vector3 = Vector3.ZERO


func _on_body_entered(_body: Node) -> void:
	if not is_ragdolling and _body is StaticBody3D or _body is CSGShape3D or _body is RigidBody3D:
		var _impact_force := (_previous_velocity - linear_velocity).length()
		if _impact_force > impact_resistance:
			#go_limp()
			if _body is DriveableVehicle:
				_body.request_stop()
			elif _body.get_parent() is SpinningWhacker:
				_body.get_parent().request_stop()
	return


func _on_velocity_computed(_safe_velocity: Vector3) -> void:
	#linear_velocity = _safe_velocity
	apply_central_force(_safe_velocity * acceleration * mass)
	return


#func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	#if is_waiting_to_reset and _ragdoll_reset_timer == null:
		#if can_stand_up():
			#is_ragdolling = false
			#collision_layer = _default_collision_layer
			#global_position = get_skeleton_position()
			#state.linear_velocity = Vector3.ZERO
			#state.angular_velocity = Vector3.ZERO
			#is_waiting_to_reset = false
		#else:
			#_ragdoll_reset_timer = get_tree().create_timer(1.0)
			#_ragdoll_reset_timer.timeout.connect(func():
				#_ragdoll_reset_timer = null
			#)


func _physics_process(delta: float) -> void:
	var _is_on_ground := is_on_ground()
	# Record current velocity, to refer to when processing collision signals
	_previous_velocity = Vector3(linear_velocity)
	# Calculate ground height for camera controller

	if _is_on_ground:
		linear_damp = 5
	else:
		linear_damp = 0

	var is_just_on_floor := _is_on_ground and not _is_on_floor_buffer

	_is_on_floor_buffer = _is_on_ground

	_target_position = _nav_agent.get_next_path_position()
	var _position_difference := _target_position - global_position
	_move_direction = _position_difference.normalized() * clampf(_position_difference.length(), 0, 1)
	_move_direction.y = 0

	if _position_difference.length_squared() > 0:
		_orient_character_to_direction(_move_direction, delta)
	_nav_agent.set_velocity(_move_direction)
	#apply_central_force(_move_direction * acceleration * mass)
	if not _is_on_ground:
		_playback.travel("MidairBlendSpace1D")
		_animation_tree.set("parameters/MidairBlendSpace1D/blend_position", clampf(-linear_velocity.y, -1, 1))
	elif _is_on_ground:
		var xz_velocity := Vector3(linear_velocity.x, 0, linear_velocity.z)
		var _xz_speed := xz_velocity.length()
		_playback.travel("Moving_BlendTree")
		_animation_tree.set("parameters/Moving_BlendTree/BlendSpace1D/blend_position", clampf(_xz_speed, 0.0, 8.0))
		if _xz_speed > stopping_speed:
			_animation_tree.set("parameters/Moving_BlendTree/TimeScale/scale", clampf(_xz_speed, 0.0, 2.0))
		else:
			_animation_tree.set("parameters/Moving_BlendTree/TimeScale/scale", 1)

	if is_just_on_floor:
		_landing_sound.play()
	return


func play_foot_step_sound() -> void:
	_step_sound.pitch_scale = randfn(1.2, 0.2)
	_step_sound.play()


func _orient_character_to_direction(_direction: Vector3, delta: float) -> void:
	#var _target_basis := _rotation_root.global_transform.looking_at(_target_position, Vector3.UP, true).basis
	#_rotation_root.global_transform.basis = _rotation_root.global_transform.basis.slerp(_target_basis, delta * rotation_speed)
	if linear_velocity == Vector3.ZERO:
		return
	var _look_direction := linear_velocity.normalized()
	_look_direction.y = 0
	var left_axis := Vector3.UP.cross(_look_direction)
	var rotation_basis := Basis(left_axis, Vector3.UP, _look_direction).get_rotation_quaternion()
	var model_scale := _rotation_root.transform.basis.get_scale()
	_rotation_root.transform.basis = Basis(_rotation_root.transform.basis.get_rotation_quaternion().slerp(rotation_basis, delta * rotation_speed)).scaled(
		model_scale
	)


func go_limp() -> void:
	$HitSound.play()
	is_ragdolling = true
	freeze = true
	collision_layer = 0
	get_tree().create_timer(min_ragdoll_time).timeout.connect(func():
		freeze = false
		is_waiting_to_reset = true
	)


func is_on_ground() -> bool:
	return len(ground_collider.get_overlapping_bodies()) > 0


func despawn() -> void:
	queue_free()
	return
