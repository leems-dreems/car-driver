class_name TrafficPathFollower extends PathFollow3D
## Used by the parent [TrafficPath] to act as a guide for traffic vehicles.

@export var vehicle: Vehicle = null
## Used to check if a vehicle can be spawned here
@onready var collision_area: Area3D = $Area3D
## This bool is flipped after this follower is moved, so that we can get overlapping bodies/areas
## during the next physics step
var just_moved := false
