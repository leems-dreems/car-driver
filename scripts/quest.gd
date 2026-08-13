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
@export var item_types: Array[Globals.Item_Types]:
	set(value):
		item_types = value
		if is_node_ready():
			changed.emit()
@export var items: Array[CarryableItem]:
	set(value):
		items = value
		if is_node_ready():
			changed.emit()
@export var actions: Array[Globals.Actions]:
	set(value):
		actions = value
		if is_node_ready():
			changed.emit()
@export var target_markers: Array[InteractableArea]:
	set(value):
		target_markers = value
		if is_node_ready():
			changed.emit()
@export var target_npcs: Array[NPC]:
	set(value):
		target_npcs = value
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
		_item_types: Array[Globals.Item_Types] = [],
		_items: Array[CarryableItem] = [],
		_actions: Array[Globals.Actions] = [],
		_target_markers: Array[InteractableArea] = [],
		_target_npcs: Array[NPC] = [],
		_target_vehicles: Array[DriveableVehicle] = []
		) -> void:
	quest_name = _quest_name
	quest_giver = _quest_giver
	item_types = _item_types
	items = _items
	actions = _actions
	target_markers = _target_markers
	target_npcs = _target_npcs
	target_vehicles = _target_vehicles
	return


func mark_completed() -> void:
	completed.emit()
	return
