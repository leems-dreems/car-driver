class_name ObjectiveArea extends Area3D
## Represents an objective marker in a [Mission]. Should be added to the Mission's `objectives`.

enum Trigger_methods {
	ON_ENTER,
	ON_USE
}
@export var objective_text := ''
@export var start_mission := false
@export var trigger_in_vehicle := false
@export var trigger_on_foot := false
@export var trigger_method := Trigger_methods.ON_ENTER
var is_completed := false


func _ready() -> void:
	match trigger_method:
		Trigger_methods.ON_ENTER:
			connect("body_entered", trigger)
		Trigger_methods.ON_USE:
			set_collision_layer_value(4, true)
	#Game.player_changed_vehicle.connect(func ():
		#check_colliding_bodies()
	#)
	return

## Check to see if [_body] meets the requirements to complete this objective
func trigger(_body: Node3D) -> void:
	if not (_body is Player or _body is DriveableVehicle):
		return
	if trigger_in_vehicle and _body is DriveableVehicle and _body.is_being_driven:
		complete_objective()
	elif trigger_on_foot and _body is Player:
		complete_objective()
	return

## See if any colliding bodies can complete this objective. This is a manual check for e.g. when
## the player gets in/out of a vehicle that is in this ObjectiveArea
func check_colliding_bodies() -> void:
	if not monitoring:
		return
	for _body: Node3D in get_overlapping_bodies():
		trigger(_body)
		if is_completed: break
	return

## Mark this objective as complete, make it invisible and turn off collision
func complete_objective() -> void:
	is_completed = true
	deactivate()
	return

## Activate an objective when the previous objective has been completed
func activate() -> void:
	visible = true
	set_deferred("monitoring", true)
	set_deferred("monitorable", true)
	for child: Node in get_children():
		if child is CollisionShape3D:
			child.set_deferred("disabled", false)
	return


func deactivate() -> void:
	visible = false
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
	for child: Node in get_children():
		if child is CollisionShape3D:
			child.set_deferred("disabled", true)
	return
