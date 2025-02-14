class_name CarDoor extends RigidBody3D

@export var parent_car: DriveableVehicle
@export var shut_door_mesh: MeshInstance3D
@export var hinge_joint: JoltHingeJoint3D
@export var door_open_SFX: AudioStreamPlayer3D
@export var door_shut_SFX: AudioStreamPlayer3D
@export var enter_car_collision_shape: CollisionShape3D
## If the "latch" areas overlap, the door will shut (if moving fast enough)
@export var door_latch: Area3D
@export var body_latch: Area3D
## Door will only shut if the `length_squared()` of the velocity difference between car and door is above this
@export var latch_velocity_threshold: float = 1.5
@export var is_openable: bool = true
@export var hide_rigidbody_when_shut: bool = true
## If the hinge separation colliders move apart, the door will detach
@export var hinge_separation_collider_A: Area3D
@export var hinge_separation_collider_B: Area3D
const outline_material := preload("res://assets/materials/outline_material_overlay.tres")
@onready var open_door_mesh: MeshInstance3D = $MeshInstance3D
var shut_basis: Basis
var hinge_limit_upper: float
var hinge_limit_lower: float
var motor_target_velocity: float
var is_shut: bool
var open_timer: SceneTreeTimer
var shut_timer: SceneTreeTimer
var is_highlighted := false


func _ready():
	if not is_openable:
		set_collision_layer_value(4, false)
	shut_basis = Basis(transform.basis)
	hinge_limit_upper = hinge_joint.limit_upper
	hinge_limit_lower = hinge_joint.limit_lower
	motor_target_velocity = hinge_joint.motor_target_velocity
	hinge_joint.limit_upper = 0
	hinge_joint.limit_lower = 0
	is_shut = true
	visible = !hide_rigidbody_when_shut
	shut_door_mesh.visible = hide_rigidbody_when_shut
	set_collision_layer_value(19, false)
	set_latches_active(false)
	if hinge_separation_collider_A:
		hinge_separation_collider_A.area_exited.connect(func(_area: Area3D):
			if not is_shut and _area == hinge_separation_collider_B:
				detach()
		)
	if door_latch:
		door_latch.area_entered.connect(func(_area: Area3D):
			if is_shut or open_timer != null or _area != body_latch:
				return
			if (linear_velocity - parent_car.linear_velocity).length_squared() > latch_velocity_threshold:
				shut()
		)
	return


func _physics_process (_delta: float) -> void:
	#if is_shut or open_timer != null:
		#return
	#if door_latch.overlaps_area(body_latch):
		#shut()
	return
	

func pull_open() -> void:
	hinge_joint.limit_upper = hinge_limit_upper
	hinge_joint.limit_lower = hinge_limit_lower
	is_shut = false
	visible = true
	hinge_joint.motor_target_velocity = motor_target_velocity
	hinge_joint.motor_enabled = true
	shut_door_mesh.visible = false
	door_open_SFX.play()
	enter_car_collision_shape.disabled = false
	set_collision_layer_value(19, true)
	set_latches_active(true)
	open_timer = get_tree().create_timer(0.05)
	open_timer.timeout.connect(func():
		hinge_joint.motor_enabled = false
		open_timer = null
	)


func fall_open() -> void:
	hinge_joint.limit_upper = hinge_limit_upper
	hinge_joint.limit_lower = hinge_limit_lower
	is_shut = false
	visible = true
	hinge_joint.motor_target_velocity = motor_target_velocity
	hinge_joint.motor_enabled = true
	shut_door_mesh.visible = false
	door_open_SFX.play()
	enter_car_collision_shape.disabled = false
	set_collision_layer_value(19, true)
	set_latches_active(true)
	open_timer = get_tree().create_timer(0.05)
	open_timer.timeout.connect(func():
		hinge_joint.motor_enabled = false
		open_timer = null
	)


func shut() -> void:
	hinge_joint.limit_upper = 0
	hinge_joint.limit_lower = 0
	hinge_joint.motor_enabled = false
	is_shut = true
	visible = !hide_rigidbody_when_shut
	shut_door_mesh.visible = hide_rigidbody_when_shut
	door_shut_SFX.play()
	enter_car_collision_shape.disabled = true
	set_collision_layer_value(19, false)
	set_latches_active(false)


func open_or_shut() -> void:
	if open_timer != null: return
	if is_shut:
		pull_open()
	else:
		hinge_joint.motor_target_velocity = -motor_target_velocity
		hinge_joint.motor_enabled = true
		shut_timer = get_tree().create_timer(0.2)
		shut_timer.timeout.connect(func():
			hinge_joint.motor_enabled = false
			shut_timer = null
		)


func set_latches_active(_active: bool) -> void:
	body_latch.set_deferred("monitoring", _active)
	body_latch.set_deferred("monitorable", _active)
	door_latch.set_deferred("monitoring", _active)
	door_latch.set_deferred("monitorable", _active)
	if hinge_separation_collider_A:
		hinge_separation_collider_A.set_deferred("monitoring", _active)
		hinge_separation_collider_A.set_deferred("monitorable", _active)
		hinge_separation_collider_B.set_deferred("monitoring", _active)
		hinge_separation_collider_B.set_deferred("monitorable", _active)
	return


func detach() -> void:
	hinge_joint.motor_enabled = false
	hinge_joint.limit_enabled = false
	hinge_joint.enabled = false
	return


func get_use_label() -> String:
	if is_shut:
		return 'Open Door'
	else:
		return 'Shut Door'


func highlight() -> void:
	is_highlighted = true
	shut_door_mesh.material_overlay = outline_material
	open_door_mesh.material_overlay = outline_material
	return


func unhighlight() -> void:
	is_highlighted = false
	shut_door_mesh.material_overlay = null
	open_door_mesh.material_overlay = null
	return
