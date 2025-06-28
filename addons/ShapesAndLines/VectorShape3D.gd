@tool

class_name VectorShape3D
extends Polyline3D

@export_range(3, 24) var sides: int = 4:
	set(value):
		sides = value
		regenerateShape()

@export var radius: float = 10.0:
	set(value):
		radius = value
		regenerateShape()

func regenerateShape() -> void:
	var newPoints: PackedVector3Array = [];
	for i in range(sides+2): # +2 to close the shape as a workaround for now
		var angle := (i + 0.5) * 2 * PI / sides
		newPoints.append(Vector3(sin(angle) * radius, 0.0, cos(angle) * radius))

	points = newPoints;