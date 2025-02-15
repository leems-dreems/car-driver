class_name StandalonePropBodies extends Node3D
## A collection of physics bodies representing a breakable prop. Used by [StandaloneSpringyProp]
## nodes to make respawning easier to manage

var is_detached_from_parent := false
@onready var rigid_body := $RigidBody3D
@onready var joint: JoltGeneric6DOFJoint3D = $JoltGeneric6DOFJoint3D
@onready var static_body := $StaticBody3D
@onready var respawn_area := $Area3D


func _ready() -> void:
	var com_marker: Marker3D = find_child("CenterOfMassMarker")
	if com_marker:
		rigid_body.center_of_mass_mode = RigidBody3D.CENTER_OF_MASS_MODE_CUSTOM
		rigid_body.center_of_mass = com_marker.position
	rigid_body.gravity_scale = 0
	return


func play_effect() -> void:
	pass


func stop_effect() -> void:
	pass
