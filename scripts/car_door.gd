extends RigidBody3D

@export var shutDoorMesh : MeshInstance3D
@export var hingeJoint : HingeJoint3D
@export var doorOpenSFX : AudioStreamPlayer3D
@export var doorShutSFX : AudioStreamPlayer3D
@export var enter_car_collision_shape : CollisionShape3D
@export var door_latch : Area3D
@export var body_latch : Area3D
var shutBasis : Basis
var hinge_limit_upper : float
var hinge_limit_lower : float
var motor_target_velocity : float
var is_shut : bool
var open_timer : SceneTreeTimer
var shut_timer : SceneTreeTimer

func _ready ():
  shutBasis = Basis(transform.basis)
  hinge_limit_upper = hingeJoint.get_param(HingeJoint3D.PARAM_LIMIT_UPPER)
  hinge_limit_lower = hingeJoint.get_param(HingeJoint3D.PARAM_LIMIT_LOWER)
  motor_target_velocity = hingeJoint.get_param(HingeJoint3D.PARAM_MOTOR_TARGET_VELOCITY)
  hingeJoint.set_param(HingeJoint3D.PARAM_LIMIT_UPPER, 0)
  hingeJoint.set_param(HingeJoint3D.PARAM_LIMIT_LOWER, 0)
  is_shut = true
  visible = false
  shutDoorMesh.visible = true
  set_collision_layer_value(19, false)


func _physics_process (_delta: float) -> void:
  if is_shut or open_timer != null: return
  if door_latch.overlaps_area(body_latch): shut()
  

func open () -> void:
  hingeJoint.set_param(HingeJoint3D.PARAM_LIMIT_UPPER, hinge_limit_upper)
  hingeJoint.set_param(HingeJoint3D.PARAM_LIMIT_LOWER, hinge_limit_lower)
  is_shut = false
  visible = true
  hingeJoint.set_param(HingeJoint3D.PARAM_MOTOR_TARGET_VELOCITY, motor_target_velocity)
  hingeJoint.set_flag(HingeJoint3D.FLAG_ENABLE_MOTOR, true)
  shutDoorMesh.visible = false
  doorOpenSFX.play()
  enter_car_collision_shape.disabled = false
  set_collision_layer_value(19, true)

  open_timer = get_tree().create_timer(0.5)
  open_timer.timeout.connect(func ():
    hingeJoint.set_flag(HingeJoint3D.FLAG_ENABLE_MOTOR, false)
    open_timer = null
  )


func shut () -> void:
  hingeJoint.set_param(HingeJoint3D.PARAM_LIMIT_UPPER, 0)
  hingeJoint.set_param(HingeJoint3D.PARAM_LIMIT_LOWER, 0)
  hingeJoint.set_flag(HingeJoint3D.FLAG_ENABLE_MOTOR, false)
  is_shut = true
  visible = false
  shutDoorMesh.visible = true
  doorShutSFX.play()
  enter_car_collision_shape.disabled = true
  set_collision_layer_value(19, false)


func open_or_shut () -> void:
  if open_timer != null: return
  if is_shut:
    open()
  else:
    hingeJoint.set_param(HingeJoint3D.PARAM_MOTOR_TARGET_VELOCITY, -motor_target_velocity)
    hingeJoint.set_flag(HingeJoint3D.FLAG_ENABLE_MOTOR, true)
    shut_timer = get_tree().create_timer(0.2)
    shut_timer.timeout.connect(func ():
      hingeJoint.set_flag(HingeJoint3D.FLAG_ENABLE_MOTOR, false)
      shut_timer = null
    )

func get_use_label () -> String:
  if is_shut:
    return 'Open Door'
  else:
    return 'Shut Door'
