class_name Player
extends CharacterBody3D

## Character maximum run speed on the ground.
@export var move_speed := 8.0
## Movement acceleration (how fast character achieve maximum speed)
@export var acceleration := 4.0
## Jump impulse
@export var jump_initial_impulse := 12.0
## Jump impulse when player keeps pressing jump
@export var jump_additional_force := 24.0
## Player model rotation speed
@export var rotation_speed := 12.0
## Minimum horizontal speed on the ground. This controls when the character's animation tree changes
## between the idle and running states.
@export var stopping_speed := 1.0
## Speed to switch from walking to running
@export var running_speed := 4.0

## Vehicle the player is currently in
@export var current_vehicle : DriveableVehicle = null
@export var current_mission : Mission = null
## The useable target the player is looking at
var useable_target : Node3D = null

@onready var _rotation_root: Node3D = $CharacterRotationRoot
@onready var _vehicle_controller: VehicleController = $VehicleController
@onready var _camera_controller: CameraController = $CameraController
@onready var _ground_shapecast: ShapeCast3D = $GroundShapeCast
@onready var _dummy_skin: DummyCharacterSkin = $CharacterRotationRoot/DummySkin_Animated
@onready var _ragdoll_skeleton: Skeleton3D = $CharacterRotationRoot/DummySkin_Physical/Rig/Skeleton3D
#@onready var _bone_simulator: PhysicalBoneSimulator3D = $CharacterRotationRoot/DummySkin_Physical/Rig/Skeleton3D/PhysicalBoneSimulator3D
@onready var _step_sound: AudioStreamPlayer3D = $StepSound
@onready var _landing_sound: AudioStreamPlayer3D = $LandingSound

@onready var _move_direction := Vector3.ZERO
@onready var _last_strong_direction := Vector3.FORWARD
@onready var _gravity: float = -30.0
@onready var _ground_height: float = 0.0
@onready var _start_position := global_transform.origin
@onready var _is_on_floor_buffer := false

var is_ragdolling := false


func _ready() -> void:
  Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
  _camera_controller.setup(self)


func _physics_process(delta: float) -> void:
  # Calculate ground height for camera controller
  if _ground_shapecast.get_collision_count() > 0:
    for collision_result in _ground_shapecast.collision_result:
      _ground_height = max(_ground_height, collision_result.point.y)
  else:
    _ground_height = global_position.y + _ground_shapecast.target_position.y
  if global_position.y < _ground_height:
    _ground_height = global_position.y

  # Get input and movement state
  var is_just_jumping := Input.is_action_just_pressed("jump") and is_on_floor()
  var is_air_boosting := Input.is_action_pressed("jump") and not is_on_floor() and velocity.y > 0.0
  var is_just_on_floor := is_on_floor() and not _is_on_floor_buffer
  var should_ragdoll := Input.is_action_just_pressed("Ragdoll")

  if not is_ragdolling and should_ragdoll:
    #_ragdoll_skeleton.physical_bones_start_simulation()
    # Get list of bone names, remove names we don't want to simulate
    var _bone_names: Array[StringName] = []
    for _bone: Node in _ragdoll_skeleton.get_children():
      if _bone is PhysicalBone3D:
        _bone_names.push_back(_bone.name)
    _ragdoll_skeleton.physical_bones_start_simulation(_bone_names)
    is_ragdolling = true
    get_tree().create_timer(10.0).timeout.connect(func():
      #_ragdoll_skeleton.physical_bones_stop_simulation()
      _ragdoll_skeleton.physical_bones_stop_simulation()
      is_ragdolling = false
    )

  # Respond to pause button
  var is_pausing := Input.is_action_just_pressed("Pause")
  if is_pausing:
    if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
      Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
    else:
      Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

  var is_in_vehicle := current_vehicle != null
  var is_using := Input.is_action_just_pressed("use")

  _is_on_floor_buffer = is_on_floor()
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
    # We separate out the y velocity to not interpolate on the gravity
    var y_velocity := velocity.y
    velocity.y = 0.0
    velocity = velocity.lerp(_move_direction * move_speed, acceleration * delta)
    if _move_direction.length() == 0 and velocity.length() < stopping_speed:
      velocity = Vector3.ZERO
    velocity.y = y_velocity

    # Try to get a useable target from the camera raycast
    var aim_collider := _camera_controller.get_aim_collider()
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

    velocity.y += _gravity * delta

    if is_just_jumping:
      velocity.y += jump_initial_impulse
    elif is_air_boosting:
      velocity.y += jump_additional_force * delta

    # Set character animation
    if is_just_jumping:
      _dummy_skin.jump()
    elif not is_on_floor() and velocity.y < 0:
      _dummy_skin.fall()
    elif is_on_floor():
      var xz_velocity := Vector3(velocity.x, 0, velocity.z)
      if xz_velocity.length() > stopping_speed:
        _dummy_skin.set_moving(true)
        _dummy_skin.set_moving_speed(inverse_lerp(0.0, move_speed, xz_velocity.length()))
      else:
        _dummy_skin.set_moving(false)

    if is_just_on_floor:
      _landing_sound.play()

    var position_before := global_position
    move_and_slide()
    var position_after := global_position

    # If velocity is not 0 but the difference of positions after move_and_slide is,
    # character might be stuck somewhere!
    var delta_position := position_after - position_before
    var epsilon := 0.001
    if delta_position.length() < epsilon and velocity.length() > epsilon:
      global_position += get_wall_normal() * 0.1


func reset_position() -> void:
  transform.origin = _start_position


func _get_camera_oriented_input() -> Vector3:
  var raw_input := Input.get_vector("move_left", "move_right", "move_up", "move_down")

  var input := Vector3.ZERO
  # This is to ensure that diagonal input isn't stronger than axis aligned input
  input.x = -raw_input.x * sqrt(1.0 - raw_input.y * raw_input.y / 2.0)
  input.z = -raw_input.y * sqrt(1.0 - raw_input.x * raw_input.x / 2.0)

  input = _camera_controller.global_transform.basis * input
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
