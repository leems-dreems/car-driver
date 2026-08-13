class_name Quest extends Node

@export var quest_name: String:
	set(value):
		quest_name = value
		if is_node_ready():
			changed.emit()
@export var quest_giver: NPC:
	set(value):
		quest_giver = value
		if is_node_ready():
			changed.emit()
@export var sub_quests: Array[Quest]:
	set(value):
		sub_quests = value
		if is_node_ready():
			changed.emit()
@export var target_markers: Array[InteractableArea]:
	set(value):
		target_markers = value
		if is_node_ready():
			changed.emit()
@export var target_vehicles: Array[DriveableVehicle]:
	set(value):
		target_vehicles = value
		if is_node_ready():
			changed.emit()

signal completed
signal changed


func _init(
		_quest_name: String = "Unnamed Quest",
		_quest_giver: NPC = null,
		_sub_quests: Array[Quest] = [],
		_target_markers: Array[InteractableArea] = [],
		_target_vehicles: Array[DriveableVehicle] = []
		) -> void:
	quest_name = _quest_name
	quest_giver = _quest_giver
	sub_quests = _sub_quests
	target_markers = _target_markers
	target_vehicles = _target_vehicles
	return


func mark_completed() -> void:
	completed.emit()
	return
