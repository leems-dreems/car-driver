extends RigidBody3D

@export var shutDoorMesh : MeshInstance3D
@export var hingeJoint : HingeJoint3D
var closedBasis : Basis
var hingeMaxAngle : float
var hingeMinAngle : float

func _ready ():
  closedBasis = Basis(transform.basis)
  hingeMaxAngle = hingeJoint.get_param(HingeJoint3D.PARAM_LIMIT_UPPER)
  hingeMinAngle = hingeJoint.get_param(HingeJoint3D.PARAM_LIMIT_LOWER)
  hingeJoint.set_param(HingeJoint3D.PARAM_LIMIT_UPPER, 0)
  hingeJoint.set_param(HingeJoint3D.PARAM_LIMIT_LOWER, 0)
  visible = false
