class_name CarDoor extends RigidBody3D

@export var parent_car: DriveableVehicle
@export var shut_door_mesh: MeshInstance3D
@export var shut_door_colliders: Array[CollisionShape3D]
@export var hinge_joint: HingeJoint3D
@export var door_open_SFX: AudioStreamPlayer3D
@export var door_shut_SFX: AudioStreamPlayer3D
## If the "latch" areas overlap, the door will shut (if moving fast enough)
@export var door_latch: Area3D
@export var body_latch: Area3D
## Door will only shut if the `length_squared()` of the velocity difference between car and door is above this
@export var latch_velocity_threshold: float = 1.5
@export var is_openable: bool = true
@export var is_detachable := false
@export var hide_rigidbody_when_shut: bool = true
## If the hinge separation colliders move apart, the door will detach
@export var hinge_separation_collider_A: Area3D
@export var hinge_separation_collider_B: Area3D
## When opening, hinge motor will be turned on for this long. Set to -1 and motor will stay on
@export var hinge_open_motor_duration := 0.2
## When closing, hinge motor will be turned on for this long. Set to -1 and motor won't turn off until door is latched shut
@export var hinge_close_motor_duration := 0.2 
const outline_material := preload("res://assets/materials/outline_material_overlay.tres")
@onready var open_door_mesh: MeshInstance3D = $MeshInstance3D
@onready var _collider := $CollisionShape3D

signal door_open
signal door_shut

var shut_basis: Basis
var hinge_limit_upper: float
var hinge_limit_lower: float
var motor_target_velocity: float
var is_shut := true
var is_detached := false
var open_timer: SceneTreeTimer
var shut_timer: SceneTreeTimer
var is_highlighted := false
var _initial_mass: float
var _initial_transform: Transform3D


func _init() -> void:
	_initial_mass = mass
	return


func _ready():
	_initial_transform = transform
	if not is_openable:
		set_collision_layer_value(4, false)
	shut_basis = Basis(transform.basis)
	hinge_limit_upper = hinge_joint.get_param(HingeJoint3D.PARAM_LIMIT_UPPER)
	hinge_limit_lower = hinge_joint.get_param(HingeJoint3D.PARAM_LIMIT_LOWER)
	motor_target_velocity = hinge_joint.get_param(HingeJoint3D.PARAM_MOTOR_TARGET_VELOCITY)
	hinge_joint.set_param(HingeJoint3D.PARAM_LIMIT_UPPER, 0)
	hinge_joint.set_param(HingeJoint3D.PARAM_LIMIT_LOWER, 0)
	#mass = 0.1
	is_shut = true
	visible = !hide_rigidbody_when_shut
	shut_door_mesh.visible = hide_rigidbody_when_shut
	disable_colliders()

	set_collision_layer_value(19, false)
	set_latches_active(false)
	if is_detachable and hinge_separation_collider_A:
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
	door_open.emit()
	enable_colliders()
	hinge_joint.limit_upper = hinge_limit_upper
	hinge_joint.limit_lower = hinge_limit_lower
	is_shut = false
	visible = true
	#hinge_joint.enabled = true
	
	if hinge_open_motor_duration == 0:
		hinge_joint.motor_enabled = false
		set_latches_active(true)
	else:
		hinge_joint.motor_target_velocity = motor_target_velocity
		hinge_joint.motor_enabled = true
		if hinge_open_motor_duration != -1:
			open_timer = get_tree().create_timer(hinge_open_motor_duration)
			set_latches_active(false)
			open_timer.timeout.connect(func():
				set_latches_active(true)
				hinge_joint.motor_enabled = false
				open_timer = null
			)
		else:
			open_timer = get_tree().create_timer(0.5)
			set_latches_active(false)
			open_timer.timeout.connect(func():
				set_latches_active(true)
				open_timer = null
			)

	shut_door_mesh.visible = false
	door_open_SFX.play()
	for _shut_door_collider in shut_door_colliders:
		_shut_door_collider.disabled = true
	_collider.disabled = false
	set_collision_layer_value(19, true)
	return


func fall_open() -> void:
	door_open.emit()
	enable_colliders()
	hinge_joint.limit_upper = hinge_limit_upper
	hinge_joint.limit_lower = hinge_limit_lower
	is_shut = false
	visible = true
	#hinge_joint.enabled = true
	
	if hinge_open_motor_duration == 0:
		hinge_joint.motor_enabled = false
		set_latches_active(true)
	else:
		hinge_joint.motor_target_velocity = motor_target_velocity
		hinge_joint.motor_enabled = true
		if hinge_open_motor_duration != -1:
			open_timer = get_tree().create_timer(hinge_open_motor_duration)
			set_latches_active(false)
			open_timer.timeout.connect(func():
				set_latches_active(true)
				hinge_joint.motor_enabled = false
				open_timer = null
			)
		else:
			open_timer = get_tree().create_timer(0.5)
			set_latches_active(false)
			open_timer.timeout.connect(func():
				set_latches_active(true)
				open_timer = null
			)

	shut_door_mesh.visible = false
	door_open_SFX.play()
	for _shut_door_collider in shut_door_colliders:
		_shut_door_collider.disabled = true
	set_collision_layer_value(19, true)
	_collider.disabled = false
	return


func shut() -> void:
	door_shut.emit()
	hinge_joint.limit_upper = 0
	hinge_joint.limit_lower = 0
	#hinge_joint.enabled = false
	hinge_joint.motor_enabled = false
	is_shut = true
	visible = !hide_rigidbody_when_shut
	shut_door_mesh.visible = hide_rigidbody_when_shut
	door_shut_SFX.play()
	for _shut_door_collider in shut_door_colliders:
		_shut_door_collider.disabled = false
	set_collision_layer_value(19, false)
	set_latches_active(false)
	disable_colliders()
	return


func open_or_shut() -> void:
	if open_timer != null: return
	if is_shut:
		pull_open()
	else:
		if hinge_close_motor_duration == 0:
			hinge_joint.motor_enabled = false
			set_latches_active(true)
		else:
			hinge_joint.motor_target_velocity = -motor_target_velocity
			hinge_joint.motor_enabled = true
			set_latches_active(true)
			if hinge_close_motor_duration != -1:
				shut_timer = get_tree().create_timer(hinge_close_motor_duration)
				shut_timer.timeout.connect(func():
					hinge_joint.motor_enabled = false
					shut_timer = null
				)
	return


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
	door_open.emit()
	hinge_joint.node_a = ""
	hinge_joint.node_b = ""
	hinge_joint.motor_enabled = false
	mass = _initial_mass
	is_detached = true
	return


func enable_colliders() -> void:
	transform = _initial_transform
	linear_velocity = parent_car.linear_velocity
	hinge_joint.node_a = parent_car.get_path()
	hinge_joint.node_b = self.get_path()
	_collider.set_deferred("disabled", false)
	freeze = false
	return


func disable_colliders() -> void:
	hinge_joint.node_a = ""
	hinge_joint.node_b = ""
	_collider.set_deferred("disabled", true)
	freeze = true
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
