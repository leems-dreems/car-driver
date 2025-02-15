class_name Player extends RigidBody3D

## Character maximum run speed on the ground.
@export var move_speed := 8.0
## Movement acceleration (how fast character achieve maximum speed)
@export var acceleration := 30.0
## Jump impulse
@export var jump_initial_impulse := 8.0
## Jump impulse when player keeps pressing jump
@export var jump_additional_force := 24.0
## Player model rotation speed
@export var rotation_speed := 12.0
## Minimum horizontal speed on the ground. This controls when the character's animation tree changes
## between the idle and running states.
@export var stopping_speed := 1.0
## Speed to switch from walking to running
@export var running_speed := 4.0
## Minimum impact force that will cause player to start ragdolling
@export var impact_resistance := 10.0
## Minimum time the player will ragdoll for after getting hit
@export var min_ragdoll_time := 4.0
## Vehicle the player is currently in
@export var current_vehicle : DriveableVehicle = null
@export var current_mission : Mission = null

@onready var _rotation_root: Node3D = $square_guy
@onready var _vehicle_controller: VehicleController = $VehicleController
@onready var camera_controller: CameraController = $CameraController
@onready var _ground_shapecast: ShapeCast3D = $GroundShapeCast
@onready var _pickup_collider: Area3D = $square_guy/PickupCollider
@onready var ragdoll_skeleton: Skeleton3D = $square_guy/metarig/Skeleton3D
@onready var _ragdoll_tracker_bone: PhysicalBone3D = $"square_guy/metarig/Skeleton3D/Physical Bone spine"
#@onready var _bone_simulator: PhysicalBoneSimulator3D = $CharacterRotationRoot/DummySkin_Physical/Rig/Skeleton3D/PhysicalBoneSimulator3D
@onready var _step_raycast: RayCast3D = $square_guy/StepRayCast3D
@onready var _step_sound: AudioStreamPlayer3D = $StepSound
@onready var _grass_step_sound: AudioStreamPlayer3D = $GrassStepSound
@onready var _dirt_step_sound: AudioStreamPlayer3D = $DirtStepSound
@onready var _landing_sound: AudioStreamPlayer3D = $LandingSound
@onready var ground_collider := $GroundCollider
@onready var _nav_agent: NavigationAgent3D = $NavigationAgent3D
@onready var _animation_tree: AnimationTree = $square_guy/AnimationTree
@onready var _playback: AnimationNodeStateMachinePlayback = _animation_tree.get("parameters/playback")
@onready var use_label: Sprite3D = $UseLabel

var _move_direction := Vector3.ZERO
var _last_strong_direction := Vector3.FORWARD
var _ground_height: float = 0.0
var _default_collision_layer := collision_layer
var _is_on_floor_buffer := false

var is_ragdolling := false
var is_waiting_to_reset := false
## Velocity as of the last physics tick
var _previous_velocity: Vector3 = Vector3.ZERO
## Timer used to space out how often we check if we can exit ragdoll
var _ragdoll_reset_timer: SceneTreeTimer = null
## Carryable items in pickup range
var _pickups_in_range: Array[Node3D]
## Useable items in range
var _useables_in_range: Array[Node3D]
var _carried_item: CarryableItem = null
var _carried_mesh: MeshInstance3D = null
var _right_hand_bone_idx: int
var _left_hand_bone_idx: int
@onready var _carried_mesh_container := $CarriedItem


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	camera_controller.setup(self)
	PropRespawnManager.camera = camera_controller.camera
	TrafficManager.camera = camera_controller.camera
	PedestrianManager.camera = camera_controller.camera
	TrafficManager.spawn_include_area = $CameraController/PlayerCamera/TrafficSpawnIncludeArea
	TrafficManager.spawn_exclude_area = $CameraController/PlayerCamera/TrafficSpawnExcludeArea
	PedestrianManager.spawn_include_area = $CameraController/PlayerCamera/PedestrianSpawnIncludeArea
	camera_controller.top_level = true
	$CameraController/PlayerCamera.top_level = true
	PauseAndHud.player = self
	_right_hand_bone_idx = ragdoll_skeleton.find_bone("hand.R")
	_left_hand_bone_idx = ragdoll_skeleton.find_bone("hand.L")
	_pickup_collider.body_exited.connect(func(_body: Node3D):
		if _body.has_method("unhighlight") and _body.is_highlighted:
			_body.unhighlight()
	)
	return


func _on_body_entered(_body: Node) -> void:
	if not is_ragdolling and _body is StaticBody3D or _body is CSGShape3D or _body is RigidBody3D:
		var _impact_force := (_previous_velocity - linear_velocity).length()
		if _impact_force > impact_resistance:
			go_limp()
			if _body is DriveableVehicle:
				_body.request_stop()
			elif _body.get_parent() is SpinningWhacker:
				_body.get_parent().request_stop()
	return


func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	if is_waiting_to_reset and _ragdoll_reset_timer == null:
		if can_stand_up():
			is_ragdolling = false
			collision_layer = _default_collision_layer
			global_position = get_skeleton_position()
			state.linear_velocity = Vector3.ZERO
			state.angular_velocity = Vector3.ZERO
			for _bone: PhysicalBone3D in ragdoll_skeleton.find_children("*", "PhysicalBone3D"):
				var _target_bone_transform := ragdoll_skeleton.get_bone_global_pose(_bone.get_bone_id())
				_bone.global_transform = ragdoll_skeleton.global_transform * _target_bone_transform
			is_waiting_to_reset = false
		else:
			_ragdoll_reset_timer = get_tree().create_timer(1.0)
			_ragdoll_reset_timer.timeout.connect(func():
				_ragdoll_reset_timer = null
			)


func _process(delta: float) -> void:
	if _carried_item != null:
		_carried_mesh.global_transform = ragdoll_skeleton.global_transform * ragdoll_skeleton.get_bone_global_pose(_right_hand_bone_idx)
	return


func _physics_process(delta: float) -> void:
	_nav_agent.get_next_path_position()
	var _is_on_ground := is_on_ground()
	# Record current velocity, to refer to when processing collision signals
	_previous_velocity = Vector3(linear_velocity)
	# Calculate ground height for camera controller
	if _ground_shapecast.get_collision_count() > 0:
		for collision_result in _ground_shapecast.collision_result:
			_ground_height = max(_ground_height, collision_result.point.y)
	else:
		_ground_height = global_position.y + _ground_shapecast.target_position.y
	if global_position.y < _ground_height:
		_ground_height = global_position.y

	if _is_on_ground:
		linear_damp = 5
	else:
		linear_damp = 0

	# Get input and movement state
	var is_just_jumping := Input.is_action_just_pressed("jump") and _is_on_ground
	var is_just_on_floor := _is_on_ground and not _is_on_floor_buffer
	if Input.is_action_just_pressed("Ragdoll"):
		go_limp()

	# Respond to pause button
	var is_pausing := Input.is_action_just_pressed("Pause")
	if not get_tree().paused and is_pausing:
		get_tree().create_timer(.1).timeout.connect(func():
			get_tree().paused = true
		)

	var is_in_vehicle := current_vehicle != null
	var is_using := Input.is_action_just_pressed("pickup_drop")

	_is_on_floor_buffer = _is_on_ground
	_move_direction = _get_camera_oriented_input()

	# To not orient quickly to the last input, we save a last strong direction,
	# this also ensures a good normalized value for the rotation basis.
	if _move_direction.length() > 0.2:
		_last_strong_direction = _move_direction.normalized()
	if camera_controller._current_pivot_type == CameraController.CAMERA_PIVOT.THIRD_PERSON:
		_orient_character_to_direction(_last_strong_direction, delta)
	else:
		_orient_character_to_direction(camera_controller.global_transform.basis.z, delta)

	if is_in_vehicle:
		global_position = current_vehicle.global_position
		current_vehicle.brake_input = Input.get_action_strength("Brake or Reverse")
		current_vehicle.steering_input = Input.get_action_strength("Steer Left") - Input.get_action_strength("Steer Right")
		current_vehicle.throttle_input = pow(Input.get_action_strength("Accelerate"), 2.0)
		current_vehicle.handbrake_input = Input.get_action_strength("Handbrake")

		# Shift to neutral if we are stationary and braking
		if current_vehicle.current_gear > 0 and current_vehicle.speed < 1:
			if current_vehicle.handbrake_input >= 1 or current_vehicle.brake_input > 0.5:
				current_vehicle.shift(-current_vehicle.current_gear)

		if current_vehicle.current_gear == -1:
			current_vehicle.brake_input = Input.get_action_strength("Accelerate")
			current_vehicle.throttle_input = Input.get_action_strength("Brake or Reverse")
	else:
		if linear_velocity.length() < move_speed:
			apply_central_force(_move_direction * acceleration * mass)

		if is_just_jumping:
			apply_central_impulse(Vector3.UP * jump_initial_impulse * mass)

		# Set character animation
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


func _get_camera_oriented_input() -> Vector3:
	var raw_input := Input.get_vector("move_left", "move_right", "move_up", "move_down")

	var input := Vector3.ZERO
	# This is to ensure that diagonal input isn't stronger than axis aligned input
	input.x = -raw_input.x * sqrt(1.0 - raw_input.y * raw_input.y / 2.0)
	input.z = -raw_input.y * sqrt(1.0 - raw_input.x * raw_input.x / 2.0)

	input = camera_controller.global_transform.basis * input
	input.y = 0.0
	return input


func play_foot_step_sound() -> void:
	var _step_collider := _step_raycast.get_collider()
	var _step_collision_point := _step_raycast.get_collision_point()
	var _step_surface: DriveableVehicle.SurfaceTypes
	if _step_collider is Terrain3D:
		if _step_collider.data.get_control_auto(_step_collision_point):
			# This part of the terrain is autoshaded, so we look for the texture blend value
			if Game.active_terrain.data.get_texture_id(_step_collision_point)[2] < 0.5:
				_step_surface = DriveableVehicle.SurfaceTypes.ROCK
			else:
				_step_surface = DriveableVehicle.SurfaceTypes.GRASS
		else:
			# This part of the terrain is manually shaded, so get the base texture id
			match _step_collider.data.get_control_base_id(_step_collision_point):
				0: _step_surface = DriveableVehicle.SurfaceTypes.ROCK
				1: _step_surface = DriveableVehicle.SurfaceTypes.GRASS
				2: _step_surface = DriveableVehicle.SurfaceTypes.SAND
				3: _step_surface = DriveableVehicle.SurfaceTypes.DIRT
				4: _step_surface = DriveableVehicle.SurfaceTypes.GRASS
				5: _step_surface = DriveableVehicle.SurfaceTypes.ROAD

	match _step_surface:
		DriveableVehicle.SurfaceTypes.DIRT:
			_dirt_step_sound.unit_size = clampf(linear_velocity.length(), 1, 4)
			_dirt_step_sound.play()
		DriveableVehicle.SurfaceTypes.GRASS:
			_grass_step_sound.unit_size = clampf(linear_velocity.length(), 1, 4)
			_grass_step_sound.play()
		_:
			_step_sound.unit_size = clampf(linear_velocity.length(), 1, 4)
			_step_sound.play()
	return


func _orient_character_to_direction(direction: Vector3, delta: float) -> void:
	var left_axis := Vector3.UP.cross(direction)
	var rotation_basis := Basis(left_axis, Vector3.UP, direction).get_rotation_quaternion()
	var model_scale := _rotation_root.transform.basis.get_scale()
	_rotation_root.transform.basis = Basis(_rotation_root.transform.basis.get_rotation_quaternion().slerp(rotation_basis, delta * rotation_speed)).scaled(
		model_scale
	)
	return


func go_limp() -> void:
	$HitSound.play()
	for _bone: PhysicalBone3D in ragdoll_skeleton.find_children("*", "PhysicalBone3D"):
		var _target_bone_transform := ragdoll_skeleton.get_bone_global_pose(_bone.get_bone_id())
		_bone.global_transform = ragdoll_skeleton.global_transform * _target_bone_transform
	ragdoll_skeleton.physical_bones_start_simulation()
	is_ragdolling = true
	freeze = true
	collision_layer = 0
	get_tree().create_timer(min_ragdoll_time).timeout.connect(func():
		freeze = false
		ragdoll_skeleton.physical_bones_stop_simulation()
		is_waiting_to_reset = true
	)
	return


func is_on_ground() -> bool:
	return len(ground_collider.get_overlapping_bodies()) > 0


func can_stand_up() -> bool:
	return _ragdoll_tracker_bone.linear_velocity.length() < stopping_speed


func get_skeleton_position() -> Vector3:
	return _ragdoll_tracker_bone.global_position


func enterVehicle (vehicle: DriveableVehicle) -> void:
	current_vehicle = vehicle
	_vehicle_controller.vehicle_node = vehicle
	vehicle.is_being_driven = true
	$CharacterCollisionShape.disabled = true
	visible = false
	Game.player_changed_vehicle.emit()


func exitVehicle () -> void:
	current_vehicle.is_being_driven = false
	current_vehicle.steering_input = 0
	current_vehicle.throttle_input = 0
	current_vehicle.clutch_input = 0
	current_vehicle.brake_input = 0
	_vehicle_controller.vehicle_node = null
	global_position = current_vehicle.global_position
	global_position.y += 5
	current_vehicle = null
	Game.player_changed_vehicle.emit()
	await get_tree().create_timer(0.1).timeout
	$CharacterCollisionShape.disabled = false
	visible = true


func pickup_item(_item: CarryableItem) -> void:
	if _carried_item != null:
		print("attempted duplicate pickup")
		return
	_carried_item = _item
	_carried_mesh = _item.get_mesh().duplicate()
	_carried_item.get_collider().disabled = true
	_carried_item.freeze = true
	_carried_item.visible = false
	_carried_mesh_container.add_child(_carried_mesh)
	_carried_mesh.set_disable_scale(true)
	_pickups_in_range = []
	return


func drop_item() -> void:
	if _carried_item == null:
		print("attempted to drop nothing")
		return
	_carried_item.global_transform = _carried_mesh.global_transform
	_carried_mesh.queue_free()
	_carried_item.get_collider().disabled = false
	_carried_item.freeze = false
	_carried_item.visible = true
	_carried_mesh = null
	_carried_item = null
	return


func throw_item() -> void:
	if _carried_item == null:
		print("attempted to throw nothing")
		return
	_carried_item.global_transform = $CameraController/ThrowOrigin.global_transform
	_carried_mesh.queue_free()
	_carried_item.get_collider().disabled = false
	_carried_item.freeze = false
	_carried_item.visible = true
	var _throw_vector: Vector3 = $CameraController/ThrowTarget.global_position - $CameraController/ThrowOrigin.global_position
	_carried_item.apply_central_impulse(_throw_vector * 7)
	_carried_mesh = null
	_carried_item = null
	return
