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
## The useable target the player is looking at
var useable_target : Node3D = null

@onready var _rotation_root: Node3D = $square_guy
@onready var _vehicle_controller: VehicleController = $VehicleController
@onready var camera_controller: CameraController = $CameraController
@onready var _ground_shapecast: ShapeCast3D = $GroundShapeCast
@onready var ragdoll_skeleton: Skeleton3D = $square_guy/metarig/Skeleton3D
@onready var _ragdoll_tracker_bone: PhysicalBone3D = $"square_guy/metarig/Skeleton3D/Physical Bone spine"
#@onready var _bone_simulator: PhysicalBoneSimulator3D = $CharacterRotationRoot/DummySkin_Physical/Rig/Skeleton3D/PhysicalBoneSimulator3D
@onready var _step_sound: AudioStreamPlayer3D = $StepSound
@onready var _landing_sound: AudioStreamPlayer3D = $LandingSound
@onready var ground_collider := $GroundCollider
@onready var _nav_agent: NavigationAgent3D = $NavigationAgent3D
@onready var _animation_tree: AnimationTree = $square_guy/AnimationTree
@onready var _playback: AnimationNodeStateMachinePlayback = _animation_tree.get("parameters/playback")

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
  var is_using := Input.is_action_just_pressed("use")

  _is_on_floor_buffer = _is_on_ground
  _move_direction = _get_camera_oriented_input()

  # To not orient quickly to the last input, we save a last strong direction,
  # this also ensures a good normalized value for the rotation basis.
  if _move_direction.length() > 0.2:
    _last_strong_direction = _move_direction.normalized()

  _orient_character_to_direction(_last_strong_direction, delta)

  if is_in_vehicle:
    useable_target = null
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

    if is_using:
      exitVehicle()
  else:
    if linear_velocity.length() < move_speed:
      apply_central_force(_move_direction * acceleration * mass)

    # Try to get a useable target from the camera raycast
    var aim_collider := camera_controller.get_aim_collider()
    useable_target = aim_collider

    # Try to use whatever we're aiming at
    if is_using and useable_target != null:
      if useable_target.has_method("open_or_shut"):
        useable_target.open_or_shut()
      elif useable_target is EnterVehicleCollider:
        enterVehicle(useable_target.vehicle)
      elif useable_target is ObjectiveArea:
        if useable_target.start_mission:
          current_mission = useable_target.get_parent()
        useable_target.trigger(self)
      elif useable_target is VehicleDispenserButton:
        var dispenser: VehicleDispenser = useable_target.get_parent()
        dispenser.spawn_vehicle(useable_target.vehicle_type)

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
  _step_sound.pitch_scale = randfn(1.2, 0.2)
  _step_sound.play()


func _orient_character_to_direction(direction: Vector3, delta: float) -> void:
  var left_axis := Vector3.UP.cross(direction)
  var rotation_basis := Basis(left_axis, Vector3.UP, direction).get_rotation_quaternion()
  var model_scale := _rotation_root.transform.basis.get_scale()
  _rotation_root.transform.basis = Basis(_rotation_root.transform.basis.get_rotation_quaternion().slerp(rotation_basis, delta * rotation_speed)).scaled(
    model_scale
  )


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
