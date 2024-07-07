extends RigidBody3D

@export var shutDoorMesh : MeshInstance3D
@export var hingeJoint : HingeJoint3D
@export var doorOpenSFX : AudioStreamPlayer3D
@export var doorShutSFX : AudioStreamPlayer3D
@export var enter_car_collision_shape : CollisionShape3D
var shutBasis : Basis
var hinge_limit_upper : float
var hinge_limit_lower : float
var is_shut : bool
var use_timer : SceneTreeTimer

func _ready ():
  shutBasis = Basis(transform.basis)
  hinge_limit_upper = hingeJoint.get_param(HingeJoint3D.PARAM_LIMIT_UPPER)
  hinge_limit_lower = hingeJoint.get_param(HingeJoint3D.PARAM_LIMIT_LOWER)
  hingeJoint.set_param(HingeJoint3D.PARAM_LIMIT_UPPER, 0)
  hingeJoint.set_param(HingeJoint3D.PARAM_LIMIT_LOWER, 0)
  is_shut = true
  visible = false
  shutDoorMesh.visible = true


func open_or_shut () -> void:
  if use_timer != null: return

  if is_shut:
    hingeJoint.set_param(HingeJoint3D.PARAM_LIMIT_UPPER, hinge_limit_upper)
    hingeJoint.set_param(HingeJoint3D.PARAM_LIMIT_LOWER, hinge_limit_lower)
    is_shut = false
    visible = true
    hingeJoint.set_flag(HingeJoint3D.FLAG_ENABLE_MOTOR, true)
    shutDoorMesh.visible = false
    doorOpenSFX.play()
    enter_car_collision_shape.disabled = false

    use_timer = get_tree().create_timer(0.5)
    use_timer.timeout.connect(func ():
      hingeJoint.set_flag(HingeJoint3D.FLAG_ENABLE_MOTOR, false)
      use_timer = null
    )
  else:
    hingeJoint.set_param(HingeJoint3D.PARAM_LIMIT_UPPER, 0)
    hingeJoint.set_param(HingeJoint3D.PARAM_LIMIT_LOWER, 0)
    is_shut = true
    visible = false
    shutDoorMesh.visible = true
    doorShutSFX.play()
    enter_car_collision_shape.disabled = true


func get_use_label () -> String:
  if is_shut:
    return 'Open Door'
  else:
    return 'Shut Door'
