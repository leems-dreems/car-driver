extends Area3D

@export var sea_level := 1.0 
var _colliding_bodies: Array[RigidBody3D] = []


func _ready() -> void:
	body_entered.connect(func(_body: Node3D):
		if _body is RigidBody3D and not _colliding_bodies.has(_body):
			_colliding_bodies.push_back(_body)
	)
	body_exited.connect(func(_body: Node3D):
		if _body is RigidBody3D and _colliding_bodies.has(_body):
			_colliding_bodies.erase(_body)
	)
	return


func _physics_process(delta: float) -> void:
	for _rigidbody in _colliding_bodies:
		var _center_of_mass := _rigidbody.global_transform.translated_local(_rigidbody.center_of_mass).origin
		var _depth := maxf(0, sea_level - _center_of_mass.y)
		_rigidbody.apply_central_force(Vector3.UP * (_depth * _rigidbody.mass * delta * 5000))
	return
