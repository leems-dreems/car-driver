class_name Pedestrian extends RigidBody3D

## Character maximum run speed on the ground.
@export var move_speed := 4.0
## Movement acceleration (how fast character achieve maximum speed)
@export var acceleration := 30.0
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

@onready var _rotation_root: Node3D = $CharacterRotationRoot
@onready var _ground_shapecast: ShapeCast3D = $GroundShapeCast
@onready var _dummy_skin: DummyCharacterSkin = $CharacterRotationRoot/DummyRigAnimated
@onready var ragdoll_skeleton: Skeleton3D = $DummyRigPhysical/Rig/Skeleton3D
@onready var _ragdoll_tracker_bone: PhysicalBone3D = $"DummyRigPhysical/Rig/Skeleton3D/Physical Bone spine"
#@onready var _bone_simulator: PhysicalBoneSimulator3D = $CharacterRotationRoot/DummySkin_Physical/Rig/Skeleton3D/PhysicalBoneSimulator3D
@onready var _step_sound: AudioStreamPlayer3D = $StepSound
@onready var _landing_sound: AudioStreamPlayer3D = $LandingSound
@onready var ground_collider := $GroundCollider
@onready var _nav_agent: NavigationAgent3D = $NavigationAgent3D

var _move_direction := Vector3.ZERO
var _last_strong_direction := Vector3.FORWARD
var _ground_height: float = 0.0
var _default_collision_layer := collision_layer
var _is_on_floor_buffer := false

var is_ragdolling := false
var is_waiting_to_reset := false
var _starting_velocity := Vector3.ZERO
## Target position to move towards, in global coordinates
var _target_position: Vector3
## Velocity as of the last physics tick
var _previous_velocity: Vector3 = Vector3.ZERO
## Timer used to space out how often we check if we can exit ragdoll
var _ragdoll_reset_timer: SceneTreeTimer = null


func _ready() -> void:
  start_ragdoll()


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


func _on_velocity_computed(_safe_velocity: Vector3) -> void:
  #linear_velocity = _safe_velocity
  apply_central_force(_safe_velocity * acceleration * mass)
  return


func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
  if is_waiting_to_reset and _ragdoll_reset_timer == null:
    if can_stand_up():
      is_ragdolling = false
      collision_layer = _default_collision_layer
      global_position = get_skeleton_position()
      state.linear_velocity = Vector3.ZERO
      state.angular_velocity = Vector3.ZERO
      is_waiting_to_reset = false
    else:
      _ragdoll_reset_timer = get_tree().create_timer(1.0)
      _ragdoll_reset_timer.timeout.connect(func():
        _ragdoll_reset_timer = null
      )


func _physics_process(delta: float) -> void:
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

  var is_just_on_floor := _is_on_ground and not _is_on_floor_buffer

  _is_on_floor_buffer = _is_on_ground

  _target_position = _nav_agent.get_next_path_position()
  var _position_difference := _target_position - global_position
  _move_direction = _position_difference.normalized() * clampf(_position_difference.length(), 0, 1)

  if _position_difference.length_squared() > 0:
    _orient_character_to_direction(_move_direction, delta)
  _nav_agent.set_velocity(_move_direction.clampf(-move_speed, move_speed))
  #apply_central_force(_move_direction * acceleration * mass)
  if not _is_on_ground and linear_velocity.y < 0:
    _dummy_skin.fall()
  elif _is_on_ground:
    var xz_velocity := Vector3(linear_velocity.x, 0, linear_velocity.z)
    if xz_velocity.length() > stopping_speed:
      _dummy_skin.set_moving(true)
      _dummy_skin.set_moving_speed(inverse_lerp(0.0, move_speed, xz_velocity.length()))
    else:
      _dummy_skin.set_moving(false)
  if is_just_on_floor:
    _landing_sound.play()
  return


func play_foot_step_sound() -> void:
  _step_sound.pitch_scale = randfn(1.2, 0.2)
  _step_sound.play()


func _orient_character_to_direction(direction: Vector3, delta: float) -> void:
  #var _target_basis := _rotation_root.global_transform.looking_at(_target_position, Vector3.UP, true).basis
  #_rotation_root.global_transform.basis = _rotation_root.global_transform.basis.slerp(_target_basis, delta * rotation_speed)
  var _look_direction := (_target_position - _rotation_root.global_position).normalized()
  var left_axis := Vector3.UP.cross(_look_direction)
  var rotation_basis := Basis(left_axis, Vector3.UP, _look_direction).get_rotation_quaternion()
  var model_scale := _rotation_root.transform.basis.get_scale()
  _rotation_root.transform.basis = Basis(_rotation_root.transform.basis.get_rotation_quaternion().slerp(rotation_basis, delta * rotation_speed)).scaled(
    model_scale
  )


func start_ragdoll() -> void:
  var _bone_names: Array[StringName] = []
  for _bone: Node in ragdoll_skeleton.get_children(): 
    if _bone is PhysicalBone3D:
      _bone_names.push_back(_bone.name)
  ragdoll_skeleton.physical_bones_start_simulation(_bone_names)


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


func can_stand_up() -> bool:
  return _ragdoll_tracker_bone.linear_velocity.length() < stopping_speed


func get_skeleton_position() -> Vector3:
  return _ragdoll_tracker_bone.global_position


func despawn() -> void:
  queue_free()
  return
