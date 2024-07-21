class_name ObjectiveArea extends Area3D
## Represents an objective marker in a [Mission]. Should be added to the Mission's `objectives`.

enum Trigger_methods {
  ON_ENTER,
  ON_USE
}
@export var objective_text := ''
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

## Call to complete this objective
func trigger(_body: Node3D) -> void:
  is_completed = true
  deactivate()

## Activate an objective when the previous objective has been completed
func activate() -> void:
  visible = true
  monitoring = true
  monitorable = true
  for child: Node in get_children():
    if child is CollisionShape3D:
      child.disabled = false


func deactivate() -> void:
  visible = false
  monitoring = false
  monitorable = false
  for child: Node in get_children():
    if child is CollisionShape3D:
      child.disabled = true
