extends DriveableVehicle

var paintjobs := [
	{
		"skin_name": "blue",
		"material": preload("res://assets/materials/paint/blue.tres")
	},
	{
		"skin_name": "green",
		"material": preload("res://assets/materials/paint/green.tres")
	},
	{
		"skin_name": "purple",
		"material": preload("res://assets/materials/paint/purple.tres")
	},
	{
		"skin_name": "red",
		"material": preload("res://assets/materials/paint/red.tres")
	},
	{
		"skin_name": "yellow",
		"material": preload("res://assets/materials/paint/yellow.tres")
	}
]
var burnt_material: StandardMaterial3D
#@onready var bonnet: CarDoor = $ColliderBits/Bonnet/OpenBonnet
@onready var boot: CarDoor = $ColliderBits/Boot/OpenBoot
@onready var bump_audio: AudioStreamPlayer3D = $AudioStreams/BumpAudio
@onready var metal_impact_audio: AudioStreamPlayer3D = $AudioStreams/MetalImpactAudio
@onready var crash_audio: AudioStreamPlayer3D = $AudioStreams/JunkCrashAudio
@onready var glass_break_audio: AudioStreamPlayer3D = $AudioStreams/GlassBreakAudio
@onready var contact_checker: CarContactChecker = $ContactChecker
@onready var vehicle_item_container: VehicleItemContainer = $VehicleItemContainer


func _ready() -> void:
	vehicle_name = "Cricket"
	vehicle_category = "Car"
	var _paintjob: Dictionary = paintjobs.pick_random()
	contact_checker.vehicle = self
	#burnt_material = _skin.burnt_material
	$Body.set_surface_override_material(0, _paintjob.material)
	$ColliderBits/DoorLeft/ShutDoorLeft.set_surface_override_material(0, _paintjob.material)
	$ColliderBits/DoorLeft/OpenDoorLeft/MeshInstance3D.set_surface_override_material(0, _paintjob.material)
	$ColliderBits/DoorRight/ShutDoorRight.set_surface_override_material(0, _paintjob.material)
	$ColliderBits/DoorRight/OpenDoorRight/MeshInstance3D.set_surface_override_material(0, _paintjob.material)
	#$ColliderBits/Bonnet/ShutBonnet.set_surface_override_material(0, _paintjob.material)
	#$ColliderBits/Bonnet/OpenBonnet/MeshInstance3D.set_surface_override_material(0, _paintjob.material)
	$ColliderBits/Boot/ShutBoot.set_surface_override_material(0, _paintjob.material)
	$ColliderBits/Boot/OpenBoot/MeshInstance3D.set_surface_override_material(0, _paintjob.material)

	boot.door_open.connect(func():
		vehicle_item_container.connect_item_listeners()
	)
	boot.door_shut.connect(func():
		vehicle_item_container.disconnect_item_listeners()
	)

	super()
	return


func apply_burnt_material() -> void:
	$Body.set_surface_override_material(0, burnt_material)
	$ColliderBits/DoorLeft/ShutDoorLeft.set_surface_override_material(0, burnt_material)
	$ColliderBits/DoorLeft/OpenDoorLeft/MeshInstance3D.set_surface_override_material(0, burnt_material)
	$ColliderBits/DoorRight/ShutDoorRight.set_surface_override_material(0, burnt_material)
	$ColliderBits/DoorRight/OpenDoorRight/MeshInstance3D.set_surface_override_material(0, burnt_material)
	#$ColliderBits/Bonnet/ShutBonnet.set_surface_override_material(0, burnt_material)
	#$ColliderBits/Bonnet/OpenBonnet/MeshInstance3D.set_surface_override_material(0, burnt_material)
	$ColliderBits/Boot/ShutBoot.set_surface_override_material(0, burnt_material)
	$ColliderBits/Boot/OpenBoot/MeshInstance3D.set_surface_override_material(0, burnt_material)
	return

## Connect the vehicle's `body_entered` signal to this method
func _on_body_entered(_body: Node) -> void:
	if _body is StaticBody3D or _body is CSGShape3D or _body is RigidBody3D or _body is Terrain3D:
		var _velocity_change := _previous_velocity - linear_velocity
		var _impact_force := _velocity_change.length() * 0.1
		if _impact_force > impact_force_threshold_1:
			#react_to_collision(_velocity_change)
			bump_audio.volume_db = linear_to_db(clampf(_impact_force, 0.0, 1.0))
			bump_audio.play()
			current_hit_points -= _impact_force
		if _impact_force > impact_force_threshold_2:
			glass_break_audio.play()
		if _impact_force > impact_force_threshold_3:
			crash_audio.play()
	return


func react_to_collision(velocity_change: Vector3) -> void:
	velocity_change = velocity_change.normalized()
	var _dot_with_x := velocity_change.dot(global_transform.basis.x)
	if not door_right.is_detached and _dot_with_x > 0.5:
		door_right.fall_open()
	elif not door_left.is_detached and _dot_with_x < -0.5:
		door_left.fall_open()
	var _dot_with_y := velocity_change.dot(global_transform.basis.y)
	if _dot_with_y > 0.5:
		#if not bonnet.is_detached:
			#bonnet.fall_open()
		if not boot.is_detached:
			boot.fall_open()
	var _dot_with_z := velocity_change.dot(global_transform.basis.z)
	if not boot.is_detached and _dot_with_z > 0.5:
		boot.fall_open()
	return


func explode() -> void:
	door_left.fall_open()
	door_right.fall_open()
	#bonnet.fall_open()
	boot.fall_open()
	super()
	return


## Freeze the car, as well as the various bodies attached to it
func freeze_bodies() -> void:
	freeze = true
	door_left.top_level = false
	door_left.freeze = true
	door_right.top_level = false
	door_right.freeze = true
	#bonnet.top_level = false
	#bonnet.freeze = true
	boot.top_level = false
	boot.freeze = true
	return

## Unfreeze the car. Attached bodies seem to behave more realistically when set to be `top_level`
func unfreeze_bodies() -> void:
	freeze = false
	return
