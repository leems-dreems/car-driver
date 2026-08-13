class_name InteractQuest extends Quest


func _init(
		_quest_name: String = "Unnamed Quest",
		_quest_giver: NPC = null,
		_sub_quests: Array[Quest] = [],
		_target_markers: Array[InteractableArea] = [],
		_action_type: Globals.Actions = Globals.Actions.INTERACT
		) -> void:
	return
