extends Node

var active_quests: Array[Quest]


func accept_quest(quest_id: int) -> void:
	var quest: Quest = instance_from_id(quest_id) as Quest
	print("Quest ID", quest_id)
	if quest == null:
		push_warning("Quest object ID not found")
	elif active_quests.has(quest):
		push_warning("Quest has already been accepted")
	else:
		prints("Accepted quest", quest.quest_name)
	return
