class_name CameraController
extends Node3D

enum CAMERA_PIVOT { OVER_SHOULDER, THIRD_PERSON }

@export_node_path var player_path : NodePath
@export var invert_mouse_y := false
@export_range(0.0, 1.0) var mouse_sensitivity := 0.1
@export_range(0.0, 8.0) var joystick_sensitivity := 2.0
@export var tilt_upper_limit := deg_to_rad(-60.0)
@export var tilt_lower_limit := deg_to_rad(60.0)
@export var player_camera_distance := 10.0
@export var vehicle_camera_distance := 15.0
@export var camera_distance_change_speed := 1.5
@export var player_camera_stiffness := 10.0
@export var follow_cam_min_velocity := 1.0
@export var follow_cam_stiffness := 0.25
@export var follow_cam_delay := 2.0

@onready var camera: Camera3D = $PlayerCamera
@onready var _over_shoulder_pivot: Node3D = $CameraOverShoulderPivot
@onready var _camera_spring_arm: SpringArm3D = $CameraSpringArm
@onready var _third_person_pivot: Node3D = $CameraSpringArm/CameraThirdPersonPivot
@onready var _interact_raycast: RayCast3D = $PlayerCamera/InteractRayCast
@onready var _foliage_fade_area: Area3D = $PlayerCamera/FoliageFadeArea
@onready var _foliage_fade_collider: CollisionShape3D = $PlayerCamera/FoliageFadeArea/CollisionShape3D
var _colliding_trees: Array[MeshInstance3D] = []
var _fadein_trees: Array[MeshInstance3D] = []

var _aim_target : Vector3
var _aim_collider: Node
var _pivot: Node3D
var _current_pivot_type: CAMERA_PIVOT
var _rotation_input: float
var _tilt_input: float
var _mouse_input := false
var _offset: Vector3
var _anchor: Player
var _euler_rotation : Vector3
var input_timer : SceneTreeTimer = null


func _ready() -> void:
	_foliage_fade_area.body_entered.connect(func(_body: Node3D):
		var _mesh := _body.get_parent() as MeshInstance3D
		if _mesh == null:
			return
		if not _colliding_trees.has(_mesh):
			_colliding_trees.push_back(_mesh)
		if _fadein_trees.has(_mesh):
			_fadein_trees.erase(_mesh)
	)
	_foliage_fade_area.body_exited.connect(func(_body: Node3D):
		var _mesh := _body.get_parent() as MeshInstance3D
		if _mesh == null:
			return
		if _colliding_trees.has(_mesh):
			_colliding_trees.erase(_mesh)
		if not _fadein_trees.has(_mesh):
			_fadein_trees.push_back(_mesh)
		#var _multimesh := _body.get_parent() as MultiMeshInstance3D
		#if _multimesh == null:
			#return
		#if _multimesh_tweens.has(_multimesh.get_instance_id()) and _multimesh_tweens[_multimesh.get_instance_id()].is_running():
			#_multimesh_tweens[_multimesh.get_instance_id()].kill()
		#_multimesh_tweens[_multimesh.get_instance_id()] = get_tree().create_tween()
		#_multimesh_tweens[_multimesh.get_instance_id()].tween_property(_multimesh, "transparency", 0, 0.1)
	)
	return


func _unhandled_input(event: InputEvent) -> void:
	_mouse_input = event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED
	if _mouse_input:
		_rotation_input = -event.relative.x * mouse_sensitivity
		_tilt_input = -event.relative.y * mouse_sensitivity


func _process(delta: float) -> void:
	if not _anchor:
		return

	_rotation_input += Input.get_axis("camera_right", "camera_left") * joystick_sensitivity
	_tilt_input += Input.get_axis("camera_down", "camera_up") * joystick_sensitivity

	if invert_mouse_y:
		_tilt_input *= -1

	fade_multimeshes(delta)

	var _camera_distance := camera.global_position.distance_to(_anchor.global_position)
	_foliage_fade_collider.shape.height = _camera_distance * 0.8
	_foliage_fade_collider.shape.radius = minf(5.0, _foliage_fade_collider.shape.height / 2)
	_foliage_fade_area.global_position = camera.global_position.lerp(_anchor.global_position, 0.35)

	if _interact_raycast.is_colliding():
		_aim_target = _interact_raycast.get_collision_point()
		_aim_collider = _interact_raycast.get_collider()
	else:
		_aim_target = _interact_raycast.global_transform * _interact_raycast.target_position
		_aim_collider = null

	if _anchor.current_vehicle != null:
		global_position = _anchor.global_position + _offset
		_camera_spring_arm.spring_length = lerpf(_camera_spring_arm.spring_length, vehicle_camera_distance, delta * camera_distance_change_speed)
		if _rotation_input != 0 or _tilt_input != 0:
			if input_timer == null:
				input_timer = get_tree().create_timer(follow_cam_delay)
				input_timer.timeout.connect(func ():
					input_timer = null
				)
			else:
				input_timer.time_left = follow_cam_delay

		if input_timer == null:
			var vehicle_velocity := _anchor.current_vehicle.linear_velocity
			if vehicle_velocity.length() > follow_cam_min_velocity:
				var camera_euler: Vector3
				if _anchor.current_vehicle.throttle_input > 0.0 or _anchor.current_vehicle.steering_input != 0.0:
					# Look at the midpoint of where the car is pointing and its direction of travel
					if _anchor.current_vehicle.current_gear == -1:
						camera_euler = lerp(Basis.looking_at(vehicle_velocity), _anchor.current_vehicle.transform.basis.rotated(_anchor.current_vehicle.transform.basis.y, PI), follow_cam_stiffness).get_euler()
					else:
						camera_euler = lerp(Basis.looking_at(vehicle_velocity), _anchor.current_vehicle.transform.basis, follow_cam_stiffness).get_euler()
					_euler_rotation.y = lerp_angle(_euler_rotation.y, camera_euler.y + PI, delta * 3)
				elif input_timer == null:
					# Look at direction car is heading in
					camera_euler = Basis.looking_at(vehicle_velocity).get_euler()
					_euler_rotation.y = lerp_angle(_euler_rotation.y, camera_euler.y + PI, delta / 2)
	else:
		# Set camera controller to current ground level for the character
		var target_position: Vector3
		if _anchor.is_ragdolling:
			target_position = _anchor.get_skeleton_position() + _offset
		else:
			target_position = _anchor.global_position + _offset
			target_position.y = lerp(global_position.y, _anchor._ground_height, 0.1)
		global_position = target_position
		# Lerp camera distance
		_camera_spring_arm.spring_length = lerpf(_camera_spring_arm.spring_length, player_camera_distance, delta * camera_distance_change_speed)

	if _rotation_input != 0.0 or _tilt_input != 0.0:
		_euler_rotation.x += _tilt_input * delta
		_euler_rotation.x = clamp(_euler_rotation.x, tilt_lower_limit, tilt_upper_limit)
		_euler_rotation.y += _rotation_input * delta

	# CameraController and PlayerCamera exist in global space, pivots are local
	transform.basis = Basis.from_euler(_euler_rotation)
	if _anchor.current_vehicle != null:
		camera.global_transform = _pivot.global_transform
	else:
		camera.global_transform.basis = camera.global_transform.basis.slerp(_pivot.global_transform.basis.orthonormalized(), delta * player_camera_stiffness)
		camera.global_position = camera.global_position.slerp(_pivot.global_position, delta * player_camera_stiffness)
	camera.rotation.z = 0

	_rotation_input = 0.0
	_tilt_input = 0.0


func setup(anchor: Player) -> void:
	_anchor = anchor
	global_transform = _anchor.global_transform
	_offset = global_transform.origin - anchor.global_transform.origin
	set_pivot(CAMERA_PIVOT.THIRD_PERSON)
	camera.global_transform = camera.global_transform.interpolate_with(_pivot.global_transform, 0.1)
	_camera_spring_arm.add_excluded_object(_anchor.get_rid())
	_interact_raycast.add_exception_rid(_anchor.get_rid())


func set_pivot(pivot_type: CAMERA_PIVOT) -> void:
	if pivot_type == _current_pivot_type:
		return

	match(pivot_type):
		CAMERA_PIVOT.OVER_SHOULDER:
			_over_shoulder_pivot.look_at(_aim_target)
			_pivot = _over_shoulder_pivot
		CAMERA_PIVOT.THIRD_PERSON:
			_pivot = _third_person_pivot

	_current_pivot_type = pivot_type


func get_aim_target() -> Vector3:
	return _aim_target


func get_aim_collider() -> Node:
	if is_instance_valid(_aim_collider):
		return _aim_collider
	else:
		return null


func fade_multimeshes(delta: float) -> void:
	for _colliding_tree in _colliding_trees:
		var _screen_position := camera.unproject_position(_colliding_tree.global_position)
		if _screen_position.x < 0 or _screen_position.x > get_viewport().size.x:
			continue
		var _screen_width: float = get_viewport().size.x
		#var _x_ratio := _screen_width - _screen_position.x
		var _distance_from_center := absf(_screen_position.x - (_screen_width / 2))
		_colliding_tree.transparency = lerpf(_colliding_tree.transparency, minf(0.85, 1 - (_distance_from_center / (_screen_width / 2))), delta * 10)
		prints(_screen_width, _screen_position.x, _distance_from_center, _colliding_tree.transparency)

	for _fadein_tree: MeshInstance3D in _fadein_trees:
		_fadein_tree.transparency = lerpf(_fadein_tree.transparency, 0, delta * 10)
		if _fadein_tree.transparency < 0.05:
			_fadein_tree.transparency = 0
			_fadein_trees.erase(_fadein_tree)

	#for _multimesh_id in _multimesh_fadeouts:
		#var _multimesh_instance: MultiMeshInstance3D = _multimesh_fadeouts[_multimesh_id].multimesh_instance
		#for _instance: int in _multimesh_fadeouts[_multimesh_id].instances:
			#var _position: Vector3 = (_multimesh_instance.global_transform * _multimesh_instance.multimesh.get_instance_transform(_instance)).origin
			#var _screen_position := camera.unproject_position(_position)
			#var _screen_width := DisplayServer.screen_get_size().x
			#var _distance_from_center := absf(_screen_position.x - _screen_width)
			#var _alpha_ratio := maxf(0.01, (_screen_width / 2) / _distance_from_center)
			#_multimesh_instance.multimesh.set_instance_color(_instance, Color(Color.WHITE, _alpha_ratio))
	return
