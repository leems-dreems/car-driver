class_name Player extends RigidBody3D

## Maximum movement speed for the player, as the square of our linear velocity
@export var move_speed := 200
## Movement acceleration (how fast character achieve maximum speed)
@export var acceleration := 20.0
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
@export var impact_resistance := 15.0
## Minimum time the player will ragdoll for after getting hit
@export var min_ragdoll_time := 1.5
## Vehicle the player is currently in
@export var current_vehicle : DriveableVehicle = null
@export var current_mission : Mission = null

@onready var _rotation_root: Node3D = $square_guy
@onready var _vehicle_controller: VehicleController = $VehicleController
@onready var camera_controller: CameraController = $CameraController
@onready var _ground_shapecast: ShapeCast3D = $GroundShapeCast
@onready var _pickup_collider: Area3D = $square_guy/PickupCollider
@onready var _npc_awareness_area: Area3D = $NPCAwarenessArea
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

@onready var pickup_marker: Sprite3D = $PickupMarker
@onready var long_press_marker: Sprite3D = $ContainerMarker
@onready var long_press_anim: AnimationPlayer = $ContainerMarker/AnimationPlayer
@onready var _carried_mesh_container := $CarriedItem
@onready var state_machine: StateMachine = $StateMachine

@onready var interact_short_press_timer: Timer = $TimerNodes/InteractShortPressTimer
@onready var interact_long_press_timer: Timer = $TimerNodes/InteractLongPressTimer
@onready var interact_target_timer: Timer = $TimerNodes/InteractTargetTimer
@onready var pickup_short_press_timer: Timer = $TimerNodes/PickupShortPressTimer
@onready var pickup_target_timer: Timer = $TimerNodes/PickupTargetTimer
@onready var drop_target_timer: Timer = $TimerNodes/DropTargetTimer
@onready var push_vehicle_timer: Timer = $TimerNodes/PushVehicleTimer
@onready var transition_timer: Timer = $TimerNodes/TransitionTimer

const _push_vehicle_button_delay := 1.0
const _interact_button_short_press_delay := 0.2
const _interact_button_long_press_delay := 0.4
const _interact_target_delay := 0.2 ## How long to wait after targeting an interactable before looking for a new target
const _pickup_button_short_press_delay := 0.2
const _pickup_target_delay := 0.2 ## How long to wait after targeting a pickup before looking for a new target
const _drop_target_delay := 0.2 ## How long to wait after targeting a drop target before looking for a new target

const _trajectory_sample_size: int = 20
const _trajectory_dot_scene := preload("res://Player/trajectory_dot.tscn")

var should_jump := false
var _move_direction := Vector3.ZERO
var _last_strong_direction := Vector3.FORWARD
var _ground_height: float = 0.0
var _default_collision_layer := collision_layer
var _is_on_floor_buffer := false
const push_force := 3000

var _initial_transform: Transform3D
var is_ragdolling := false
var is_waiting_to_reset := false
## Velocity as of the last physics tick
var _previous_velocity: Vector3 = Vector3.ZERO
## Timer used to space out how often we check if we can exit ragdoll
var _ragdoll_reset_timer: SceneTreeTimer = null
## Carryable items in pickup range
var pickups_in_range: Array[Node3D]
## Useable items in range
var interactables_in_range: Array[Node3D]
## Pushable/grabbable vehicles in range
var vehicles_in_range: Array[DriveableVehicle]
## Item containers in range
var drop_targets: Array[Node3D]
## Container being targeted by a long-press action
var drop_target: Node3D = null
## Interactable item being targeted
var targeted_interactable: Node3D = null
## CarryableItem being targeted by a long-press action
var targeted_pickup: CarryableItem = null

var _carried_item: CarryableItem = null
var _carried_mesh: MeshInstance3D = null
var _right_hand_bone_idx: int
var _left_hand_bone_idx: int

# Signals used to update the HUD
signal short_press_pickup_highlight(_target: Node3D)
signal short_press_pickup_unhighlight
signal short_press_pickup_start
signal short_press_pickup_finish
signal item_picked_up(_item: CarryableItem)
signal item_dropped
signal short_press_drop_highlight(_target: Node3D)
signal short_press_drop_unhighlight
signal short_press_drop_start
signal short_press_drop_finish
signal short_press_interact_highlight(_interactable_area: InteractableArea)
signal short_press_interact_unhighlight
signal short_press_interact_start
signal short_press_interact_finish
signal long_press_interact_highlight(_target: Node3D)
signal long_press_interact_unhighlight
signal long_press_interact_start
signal long_press_interact_cancel
signal long_press_interact_finish
signal push_vehicle_highlight(_vehicle: DriveableVehicle)
signal push_vehicle_unhighlight
signal push_vehicle_start
signal vehicle_entered(_vehicle: DriveableVehicle)
signal vehicle_exited
signal state_changed(_state: String)


func _ready() -> void:
	_initial_transform = transform
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

	_pickup_collider.area_entered.connect(func(_area: Area3D):
		if _area is InteractableArea and not interactables_in_range.has(_area):
			interactables_in_range.push_back(_area)
		if _area is DetachableBinArea and not drop_targets.has(_area):
			if _carried_item != null and _area.can_deposit_item(_carried_item):
				drop_targets.push_back(_area)
	)
	_pickup_collider.body_entered.connect(func(_body: Node3D):
		if _body is CarryableItem and not pickups_in_range.has(_body):
			pickups_in_range.push_back(_body)
		if _body is DriveableVehicle and not vehicles_in_range.has(_body):
			vehicles_in_range.push_back(_body)
			if len(vehicles_in_range) == 1:
				push_vehicle_highlight.emit()
	)
	_pickup_collider.area_exited.connect(func(_area: Area3D):
		if _area == targeted_interactable:
			targeted_interactable = null
		if _area is InteractableArea:
			var _index := interactables_in_range.find(_area)
			if _index != -1:
				interactables_in_range.remove_at(_index)
			if _area is DetachableBinArea:
				if _area == drop_target:
					drop_target = null
				var _drop_target_index := drop_targets.find(_area)
				if _drop_target_index != -1:
					drop_targets.remove_at(_drop_target_index)
			if _area.is_highlighted:
				short_press_interact_unhighlight.emit()
				long_press_interact_unhighlight.emit()
				if _area is DetachableBinArea and _carried_item != null:
					short_press_drop_unhighlight.emit()
				_area.unhighlight()
	)
	_pickup_collider.body_exited.connect(func(_body: Node3D):
		if _body is CarryableItem:
			if _body == targeted_pickup:
				targeted_pickup = null
				pickup_marker.visible = false
				short_press_pickup_unhighlight.emit()
			var _index := pickups_in_range.find(_body)
			if _index != -1:
				pickups_in_range.remove_at(_index)
			if _body.is_highlighted:
				short_press_pickup_unhighlight.emit()
				_body.unhighlight()
		elif _body is DriveableVehicle and vehicles_in_range.has(_body):
			vehicles_in_range.erase(_body)
			if len(vehicles_in_range) == 0 and push_vehicle_timer.is_stopped():
				push_vehicle_unhighlight.emit()
	)

	_npc_awareness_area.body_entered.connect(func(_body: Node3D):
		if _body is Pedestrian and _body.face_player:
			_body.look_target = self
	)
	_npc_awareness_area.body_exited.connect(func(_body: Node3D):
		if _body is Pedestrian and _body.face_player:
			_body.look_target = null
	)

	interact_long_press_timer.timeout.connect(interact_long_press_timeout)
	interact_short_press_timer.timeout.connect(interact_short_press_timeout)
	interact_target_timer.timeout.connect(func(): interact_target_timer.stop())
	pickup_short_press_timer.timeout.connect(pickup_short_press_timeout)
	pickup_target_timer.timeout.connect(func(): pickup_target_timer.stop())
	drop_target_timer.timeout.connect(func(): drop_target_timer.stop())
	push_vehicle_timer.timeout.connect(func(): push_vehicle_timer.stop())

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
			ragdoll_skeleton.physical_bones_stop_simulation()
			is_ragdolling = false
			collision_layer = _default_collision_layer
			global_position = get_skeleton_position()
			state.linear_velocity = Vector3.ZERO
			state.angular_velocity = Vector3.ZERO
			for _bone: PhysicalBone3D in ragdoll_skeleton.find_children("*", "PhysicalBone3D"):
				var _target_bone_transform := ragdoll_skeleton.get_bone_global_pose(_bone.get_bone_id())
				_bone.global_transform = ragdoll_skeleton.global_transform * _target_bone_transform
			freeze = false
			is_waiting_to_reset = false
		else:
			_ragdoll_reset_timer = get_tree().create_timer(1.0)
			_ragdoll_reset_timer.timeout.connect(func():
				_ragdoll_reset_timer = null
			)


func _process(_delta: float) -> void:
	if _carried_item != null:
		_carried_mesh.global_transform = ragdoll_skeleton.global_transform * ragdoll_skeleton.get_bone_global_pose(_right_hand_bone_idx)
	return


func _physics_process(_delta: float) -> void:
	_nav_agent.get_next_path_position()
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

	return


func process_on_foot_controls(delta: float, can_sprint := true, speed_ratio: float = 1.0) -> void:
	var _is_on_ground := is_on_ground()
	var is_just_jumping := not is_ragdolling and should_jump and _is_on_ground
	should_jump = false
	var is_just_on_floor := _is_on_ground and not _is_on_floor_buffer
	if Input.is_action_just_pressed("Ragdoll"):
		go_limp()

	_is_on_floor_buffer = _is_on_ground
	_move_direction = _get_camera_oriented_input()

	linear_damp = 2 if _is_on_ground else 0

	# To not orient quickly to the last input, we save a last strong direction,
	# this also ensures a good normalized value for the rotation basis.
	if _move_direction.length() > 0.2:
		_last_strong_direction = _move_direction.normalized()
	if camera_controller._current_pivot_type == CameraController.CAMERA_PIVOT.THIRD_PERSON:
		_orient_character_to_direction(_last_strong_direction, delta)
	else:
		_orient_character_to_direction(camera_controller.global_transform.basis.z, delta)

	if linear_velocity.length_squared() < move_speed * speed_ratio:
		if can_sprint and Input.is_action_pressed("sprint"):
			apply_central_force(_move_direction * (acceleration * 2) * mass)
		else:
			apply_central_force(_move_direction * acceleration * mass)

	if is_just_jumping:
		apply_central_impulse(Vector3.UP * jump_initial_impulse * mass)

	# Set character animation
	if not _is_on_ground:
		_playback.travel("MidairBlendSpace1D")
		_animation_tree.set("parameters/MidairBlendSpace1D/blend_position", clampf(-linear_velocity.y, -1, 1))
	elif _is_on_ground:
		var xz_velocity: Vector3
		if _move_direction.length_squared() > 0.2:
			xz_velocity = Vector3(linear_velocity.x, 0, linear_velocity.z)
		else:
			xz_velocity = Vector3.ZERO
		var _xz_speed := xz_velocity.length()
		_playback.travel("Moving_BlendTree")
		_animation_tree.set("parameters/Moving_BlendTree/BlendSpace1D/blend_position", clampf(_xz_speed, 0.0, 8.0))
		if _xz_speed > stopping_speed:
			_animation_tree.set("parameters/Moving_BlendTree/TimeScale/scale", clampf(_xz_speed, 0.0, 2.0))
		else:
			_animation_tree.set("parameters/Moving_BlendTree/TimeScale/scale", 1)
	return


func process_vehicle_controls(_delta: float) -> void:
	_animation_tree.set("parameters/Moving_BlendTree/TimeScale/scale", 0)
	global_position = current_vehicle.global_position
	current_vehicle.brake_input = Input.get_action_strength("Brake or Reverse")
	current_vehicle.steering_input = Input.get_action_strength("Steer Left") - Input.get_action_strength("Steer Right")
	current_vehicle.throttle_input = pow(Input.get_action_strength("Accelerate"), 2.0)
	#current_vehicle.handbrake_input = Input.get_action_strength("Handbrake")

	# Shift to neutral if we are stationary and braking
	if current_vehicle.current_gear > 0 and current_vehicle.speed < 1:
		if current_vehicle.handbrake_input >= 1 or current_vehicle.brake_input > 0.5:
			current_vehicle.shift(-current_vehicle.current_gear)

	if current_vehicle.current_gear == -1:
		current_vehicle.brake_input = Input.get_action_strength("Accelerate")
		current_vehicle.throttle_input = Input.get_action_strength("Brake or Reverse")

	if current_vehicle.ignition_on == false and current_vehicle.throttle_input > 0 and current_vehicle.current_hit_points > 0:
		current_vehicle.ignition_on = true

	return


func _get_camera_oriented_input() -> Vector3:
	if is_ragdolling:
		return Vector3.ZERO
 
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
		_bone.apply_central_impulse(linear_velocity * _bone.mass)
	ragdoll_skeleton.physical_bones_start_simulation()
	for _bone: PhysicalBone3D in ragdoll_skeleton.find_children("*", "PhysicalBone3D"):
		_bone.apply_central_impulse(linear_velocity * _bone.mass)
	#_ragdoll_tracker_bone.apply_central_impulse(linear_velocity * _ragdoll_tracker_bone.mass)
	is_ragdolling = true
	freeze = true
	collision_layer = 0
	get_tree().create_timer(min_ragdoll_time).timeout.connect(func():
		is_waiting_to_reset = true
	)
	return


func is_on_ground() -> bool:
	return len(ground_collider.get_overlapping_bodies()) > 0


func can_stand_up() -> bool:
	return _ragdoll_tracker_bone.linear_velocity.length() < stopping_speed


func get_skeleton_position() -> Vector3:
	return _ragdoll_tracker_bone.global_position


func enterVehicle(vehicle: DriveableVehicle) -> void:
	current_vehicle = vehicle
	_vehicle_controller.vehicle_node = vehicle
	vehicle.is_being_driven = true
	$CharacterCollisionShape.disabled = true
	_pickup_collider.process_mode = Node.PROCESS_MODE_DISABLED
	visible = false
	state_machine.state.finished.emit(PlayerState.DRIVING)
	vehicle_entered.emit(vehicle)
	return


func exitVehicle () -> void:
	current_vehicle.is_being_driven = false
	current_vehicle.steering_input = 0
	current_vehicle.throttle_input = 0
	current_vehicle.clutch_input = 0
	current_vehicle.brake_input = 0
	_vehicle_controller.vehicle_node = null

	freeze = true
	set_deferred("global_position", current_vehicle.global_transform.translated_local(Vector3(1.5, 0, 0)).origin)
	set_deferred("freeze", false)
	set_deferred("linear_velocity", current_vehicle.linear_velocity)
	current_vehicle = null
	$CharacterCollisionShape.set_deferred("disabled", false)
	_pickup_collider.set_deferred("process_mode", Node.PROCESS_MODE_INHERIT)
	set_deferred("visible", true)
	vehicle_exited.emit()
	return


func pickup_item(_item: CarryableItem) -> void:
	if _carried_item != null:
		print("attempted duplicate pickup")
		return
	item_picked_up.emit(_item)
	_item.play_pickup_effect()
	_carried_item = _item
	_carried_mesh = _item.get_mesh().duplicate()
	_carried_item.get_collider().disabled = true
	_carried_item.freeze = true
	_carried_item.visible = false
	_carried_mesh_container.add_child(_carried_mesh)
	_carried_mesh.set_disable_scale(true)
	_carried_item.collision_layer = _carried_item._default_collision_layer
	_carried_item.collision_mask = _carried_item._default_collision_mask
	_carried_item.container_node = null
	var _index := pickups_in_range.find(_item)
	if _index != -1:
		pickups_in_range.remove_at(_index)
	state_machine.state.finished.emit(PlayerState.CARRYING)
	return


func drop_item() -> void:
	if _carried_item == null:
		print("attempted to drop nothing")
		return
	item_dropped.emit()
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
	item_dropped.emit()
	_carried_item.global_transform = $CameraController/ThrowOrigin.global_transform
	_carried_mesh.queue_free()
	_carried_item.get_collider().disabled = false
	_carried_item.freeze = false
	_carried_item.visible = true
	var _throw_vector := get_throw_vector()
	_carried_item.apply_central_impulse(_throw_vector)
	_carried_item.apply_torque_impulse(_throw_vector.rotated(Vector3.UP, -PI / 2) * _carried_item.mass)
	_carried_mesh = null
	_carried_item = null
	return


func get_throw_vector() -> Vector3:
	if _carried_item == null:
		return Vector3.ZERO
	var _throw_vector: Vector3 = $CameraController/ThrowTarget.global_position - $CameraController/ThrowOrigin.global_position
	_throw_vector *= 7 * _carried_item.mass
	return _throw_vector

## Draws the trajectory of the carried item if it was thrown
func draw_throw_arc() -> void:
	var _throw_vector := get_throw_vector()
	if _throw_vector == Vector3.ZERO:
		$CameraController/TrajectoryDots.visible = false
		return
	$CameraController/TrajectoryDots.visible = true
	var _trajectory_samples := TrajectoryLib.samples($CameraController/ThrowOrigin.global_position, _throw_vector, get_gravity(), 1.0, _trajectory_sample_size)
	var _dots := $CameraController/TrajectoryDots.get_children()
	if len(_dots) != _trajectory_sample_size:
		for _dot: Node in _dots:
			_dot.queue_free()
		for i in _trajectory_sample_size:
			$CameraController/TrajectoryDots.add_child(_trajectory_dot_scene.instantiate())
		_dots = $CameraController/TrajectoryDots.get_children()
	var j: int = 0
	for _dot: MeshInstance3D in _dots:
		_dot.global_position = _trajectory_samples[j].position
		j += 1
	return


func hide_throw_arc() -> void:
	$CameraController/TrajectoryDots.visible = false
	return


func set_pickup_marker_text(_text: String) -> void:
	$PickupMarker/SubViewport/CenterContainer/PanelContainer/MarginContainer/Label.text = _text
	return


func set_pickup_marker_borders(_visible: bool) -> void:
	if _visible:
		$PickupMarker/AnimationPlayer.play("show_borders")
	else:
		$PickupMarker/AnimationPlayer.play("hide_borders")
	return


func handle_push_vehicle_button_pressed() -> void:
	if not push_vehicle_timer.is_stopped():
		return
	if len(vehicles_in_range) == 0:
		return
	push_vehicle_start.emit()
	var _target_vehicle := vehicles_in_range[0]
	var _push_target_position := _target_vehicle.global_transform.translated_local(_target_vehicle.center_of_mass).origin
	_target_vehicle.apply_impulse((_push_target_position - global_position).normalized() * push_force, Vector3(0, 1, 0))
	push_vehicle_timer.start(_push_vehicle_button_delay)
	await push_vehicle_timer.timeout
	push_vehicle_unhighlight.emit()
	update_push_target(true)
	if len(vehicles_in_range) > 0:
		push_vehicle_highlight.emit.call_deferred()
	return


func update_push_target(_force_update := false) -> void:
	if _force_update:
		vehicles_in_range = []
		for _body in _pickup_collider.get_overlapping_bodies():
			if _body is DriveableVehicle and not vehicles_in_range.has(_body):
				vehicles_in_range.push_back(_body)

	if not push_vehicle_timer.is_stopped():
		return

	if len(vehicles_in_range) > 0:
		var vehicle_distances := {}
		for _vehicle: Node3D in vehicles_in_range:
			vehicle_distances[_vehicle.get_instance_id()] = _vehicle.global_position.distance_squared_to(_pickup_collider.global_position)
		vehicles_in_range.sort_custom(func(a: Node3D, b: Node3D):
			return vehicle_distances[a.get_instance_id()] < vehicle_distances[b.get_instance_id()]
		)
	return


func handle_pickup_button_pressed() -> void:
	if not pickup_short_press_timer.is_stopped():
		return
	if targeted_pickup == null:
		return
	short_press_pickup_start.emit()
	pickup_short_press_timer.start(_pickup_button_short_press_delay)
	pickup_item(targeted_pickup)
	targeted_pickup.unhighlight()
	targeted_pickup = null
	return


func pickup_short_press_timeout() -> void:
	pickup_short_press_timer.stop()
	short_press_pickup_finish.emit()
	return


func update_pickup_target(_force_update := false) -> void:
	if _force_update:
		pickups_in_range = []
		for _body in _pickup_collider.get_overlapping_bodies():
			if _body is CarryableItem and not pickups_in_range.has(_body):
				pickups_in_range.push_back(_body)

	if not pickup_target_timer.is_stopped() or not pickup_short_press_timer.is_stopped():
		return

	if len(pickups_in_range) > 0:
		var pickup_distances := {}
		for _pickup: Node3D in pickups_in_range:
			pickup_distances[_pickup.get_instance_id()] = _pickup.global_position.distance_squared_to(_pickup_collider.global_position)
		pickups_in_range.sort_custom(func(a: Node3D, b: Node3D):
			return pickup_distances[a.get_instance_id()] < pickup_distances[b.get_instance_id()]
		)

		var i: int = 0
		for _pickup in pickups_in_range:
			if i == 0:
				targeted_pickup = _pickup
				if _force_update or not _pickup.is_highlighted:
					pickup_target_timer.start()
					set_pickup_marker_text(_pickup.item_name.capitalize())
					short_press_pickup_highlight.emit(_pickup)
					pickup_marker.visible = true
					pickup_marker.global_position = _pickup.global_position
					pickup_marker.position.y += 0.5
					_pickup.highlight()
			elif _pickup.is_highlighted:
				_pickup.unhighlight()
			i += 1
	elif targeted_pickup != null:
		targeted_pickup = null
		pickup_marker.visible = false
		short_press_pickup_unhighlight.emit()
	return


func handle_interact_button_pressed() -> void:
	if targeted_interactable == null:
		return

	if not interact_short_press_timer.is_stopped() or not interact_long_press_timer.is_stopped():
		return
	if targeted_interactable.can_interact_short_press():
		short_press_interact_start.emit()
		interact_short_press_timer.start(_interact_button_short_press_delay)
	elif targeted_interactable.can_interact_long_press(_carried_item):
		long_press_interact_start.emit()
		interact_long_press_timer.start(_interact_button_long_press_delay)
	return


func handle_interact_button_released() -> void:
	if targeted_interactable == null:
		return

	if not interact_short_press_timer.is_stopped():
		interact_short_press_timer.stop()
		short_press_interact_finish.emit()
		targeted_interactable.interact_short_press()
		if targeted_interactable is NPCInteractArea:
			state_machine.state.finished.emit(PlayerState.IN_DIALOGUE)
			return
		if _pickup_collider.overlaps_area(targeted_interactable):
			short_press_interact_highlight.emit(targeted_interactable)
		else:
			targeted_interactable.unhighlight()
			targeted_interactable = null

	if not interact_long_press_timer.is_stopped():
		interact_long_press_timer.stop()
		long_press_interact_cancel.emit()
		if _pickup_collider.overlaps_area(targeted_interactable):
			long_press_interact_highlight.emit(targeted_interactable)
		else:
			targeted_interactable.unhighlight()
			targeted_interactable = null
	return


func interact_short_press_timeout() -> void:
	interact_short_press_timer.stop()
	if targeted_interactable != null and targeted_interactable.can_interact_long_press(_carried_item):
		short_press_interact_finish.emit()
		long_press_interact_start.emit(_interact_button_short_press_delay / _interact_button_long_press_delay)
		interact_long_press_timer.start(_interact_button_long_press_delay)
		if _pickup_collider.overlaps_area(targeted_interactable):
			short_press_interact_highlight.emit(targeted_interactable)
	else:
		short_press_interact_finish.emit()
		if targeted_interactable != null:
			targeted_interactable.interact_short_press()
			if targeted_interactable is NPCInteractArea:
				state_machine.state.finished.emit(PlayerState.IN_DIALOGUE)
			if _pickup_collider.overlaps_area(targeted_interactable):
				short_press_interact_highlight.emit(targeted_interactable)
			else:
				targeted_interactable.unhighlight()
				targeted_interactable = null
	return


func interact_long_press_timeout() -> void:
	interact_long_press_timer.stop()
	long_press_interact_finish.emit()
	if targeted_interactable != null and targeted_interactable.can_interact_long_press(_carried_item):
		if targeted_interactable is CarDoorInteractArea:
			enterVehicle(targeted_interactable.car_door.parent_car)
		else:
			targeted_interactable.interact_long_press()
			targeted_interactable.unhighlight()
			targeted_interactable = null
	return


func update_interact_target(_force_update := false) -> void:
	if _force_update:
		interactables_in_range = []
		for _area: Area3D in _pickup_collider.get_overlapping_areas():
			if _area is InteractableArea and not interactables_in_range.has(_area):
				interactables_in_range.push_back(_area)

	if not interact_target_timer.is_stopped() or not interact_short_press_timer.is_stopped() or not interact_long_press_timer.is_stopped():
		return

	if len(interactables_in_range) > 0:
		var _useable_distances := {}
		for _useable: Node3D in interactables_in_range:
			var _useable_position: Vector3
			if _useable is CarDoor:
				_useable_position = _useable.interact_target.global_position
			else:
				_useable_position = _useable.global_position
			_useable_distances[_useable.get_instance_id()] = _useable_position.distance_squared_to(_pickup_collider.global_position)

		interactables_in_range.sort_custom(func(a: Node3D, b: Node3D):
			return _useable_distances[a.get_instance_id()] < _useable_distances[b.get_instance_id()]
		)

		var i: int = 0
		for _interactable in interactables_in_range:
			if i == 0:
				if _force_update or targeted_interactable != _interactable:
					short_press_interact_unhighlight.emit()
					long_press_interact_unhighlight.emit()
					targeted_interactable = _interactable
					interact_target_timer.start()
					if _interactable.can_interact_short_press():
						short_press_interact_highlight.emit(_interactable)
					if _interactable.can_interact_long_press(_carried_item):
						long_press_interact_highlight.emit(_interactable)
					_interactable.highlight()
			elif _interactable.is_highlighted:
				_interactable.unhighlight()
			i += 1
	elif targeted_interactable != null:
		targeted_interactable = null
		short_press_interact_unhighlight.emit()
		long_press_interact_unhighlight.emit()
	return


func handle_drop_button_pressed() -> void:
	short_press_drop_start.emit()
	var _item := _carried_item
	drop_item()
	if len(drop_targets) > 0 and drop_targets[0].has_method("deposit_item"):
		drop_targets[0].deposit_item(_item)
		_item.queue_free()
		drop_targets[0].unhighlight()
	short_press_drop_finish.emit()
	state_machine.state.finished.emit(PlayerState.EMPTY_HANDED)
	return


func update_drop_target(_force_update := false) -> void:
	if _force_update:
		drop_targets = []
		for _area: Node3D in _pickup_collider.get_overlapping_areas():
			if _area is DetachableBinArea and not drop_targets.has(_area):
				if _carried_item != null and _area.can_deposit_item(_carried_item):
					drop_targets.push_back(_area)

	if not drop_target_timer.is_stopped():
		return

	var _drop_target_distances := {}
	for _drop_target: Node3D in drop_targets:
		if _drop_target.can_deposit_item(_carried_item):
			_drop_target_distances[_drop_target.get_instance_id()] = _drop_target.global_position.distance_squared_to(_pickup_collider.global_position)
	drop_targets.sort_custom(func(a: Node3D, b: Node3D):
		return _drop_target_distances[a.get_instance_id()] < _drop_target_distances[b.get_instance_id()]
	)

	if len(drop_targets) > 0:
		var i: int = 0
		for _drop_target in drop_targets:
			if i == 0:
				if _drop_target.has_method("highlight") and (_force_update or drop_target_timer.is_stopped()):
					drop_target_timer.start()
					short_press_drop_highlight.emit(_drop_target)
					drop_target = _drop_target
					_drop_target.highlight()
			elif _drop_target.has_method("unhighlight"):
				_drop_target.unhighlight()
			i += 1
	else:
		if drop_target != null:
			short_press_drop_unhighlight.emit()
		drop_target = null
	return


func handle_pause_button_pressed() -> void:
	get_tree().create_timer(.1).timeout.connect(func():
		get_tree().paused = true
	)
	return
