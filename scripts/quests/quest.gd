class_name Quest extends Node

@export var quest_name: String
@export var quest_giver: NPC
@export var item_types: Array[Globals.Item_Types]
@export var items: Array[CarryableItem]
@export var target_npcs: Array[NPC]
@export var drop_target_nodes: Array[Node]:
	set(_nodes):
		drop_target_nodes = _nodes
		drop_target_areas = []
		for _node in _nodes:
			if _node is StandaloneSpringyProp:
				drop_target_areas.push_back(_node.get_interact_target())
@export var target_markers: Array[InteractableArea]
@export var target_vehicles: Array[DriveableVehicle]

var is_sub_quest := false
var is_complete := false
var completed_by: Node = null
var drop_target_areas: Array[InteractableArea] = []

signal completed


func _init(
		_quest_name: String = "Unnamed Quest",
		_quest_giver: NPC = null,
		) -> void:
	quest_name = _quest_name
	quest_giver = _quest_giver
	return


func _ready() -> void:
	if get_parent() is Quest:
		is_sub_quest = true
	return

## Returns the first subquest which hasn't been completed, or self if all are complete
func get_active_quest() -> Quest:
	if is_complete:
		return null

	var sub_quests := find_children("*")
	var quest_index := sub_quests.find_custom(func(_quest: Quest): return !_quest.is_complete)
	if quest_index != -1:
		return sub_quests[quest_index]

	return self


func mark_completed() -> void:
	completed.emit()
	return
