class_name StandalonePropBodies extends Node3D
## A collection of physics bodies representing a breakable prop. Used by [StandaloneSpringyProp]
## nodes to make respawning easier to manage

@onready var rigid_body := $RigidBody3D
@onready var joint: JoltGeneric6DOFJoint3D = $JoltGeneric6DOFJoint3D
@onready var static_body := $StaticBody3D


func _ready() -> void:
  var com_marker: Marker3D = $CenterOfMassMarker
  if com_marker:
    rigid_body.center_of_mass_mode = RigidBody3D.CENTER_OF_MASS_MODE_CUSTOM
    rigid_body.center_of_mass = com_marker.position
  rigid_body.gravity_scale = 0
  return
