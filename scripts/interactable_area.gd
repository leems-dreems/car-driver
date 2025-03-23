## Base class for objects that can be interacted with.
class_name InteractableArea extends Area3D

@export var interactable_noun := "InteractableArea"
@export var short_press_text := "interact with"
@export var long_press_text := "interact with"
var is_highlighted := false

## Visually highlight this object, because it is being targeted for an interact
func highlight() -> void:
	return

## Remove visual highlight
func unhighlight() -> void:
	return

## Return true if this object is a valid target for a short-press of the interact button
func can_interact_short_press() -> bool:
	return false

## Handle a short-press of the interact button
func interact_short_press() -> void:
	return

## Return true if this object is a valid target for a long-press of the interact button
func can_interact_long_press(_carried_item: CarryableItem = null) -> bool:
	return false

## Handle a long-press of the interact button
func interact_long_press() -> void:
	return
