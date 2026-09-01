extends Node

signal quest_accepted(quest: Quest)
signal quest_completed(quest: Quest)

var active_quests: Array[Quest]
var player: Player


func accept_quest(quest_id: int) -> void:
	var quest: Quest = instance_from_id(quest_id) as Quest
	print("Quest ID", quest_id)
	if quest == null:
		push_warning("Quest object ID not found")
		return
	elif active_quests.has(quest):
		push_warning("Quest has already been accepted")
		return
	else:
		prints("Accepted quest", quest.quest_name)

	active_quests.push_back(quest)
	quest_accepted.emit(quest)
	print(active_quests)

	if quest is InteractQuest:
		for target_marker: InteractableArea in quest.target_markers:
			target_marker.was_interacted_with.connect(func():
				prints("target marker", target_marker, "was interacted with")
				complete_quest(quest_id)
			, 4)
	elif quest is DeliverQuest:
		player.item_delivered.connect(func(item: CarryableItem, delivery_target: Node):
			prints("delivered", item.name, "to", delivery_target.name)
			complete_quest(quest_id)
		, 4)
	return


func complete_quest(quest_id: int) -> void:
	var quest: Quest = instance_from_id(quest_id) as Quest
	prints("Completed quest", quest_id)
	active_quests.erase(quest)
	quest_completed.emit(quest)
	print(active_quests)
	return


func item_picked_up(item: CarryableItem, picked_up_by: Node) -> void:
	# get current subquest of each top level quest
	var filtered_quests: Array[Quest] = active_quests.filter(func(quest: Quest):
		return quest.items.has(item)
	)
	#for quest in filtered_quests:
		#quest.completed
	return


func item_delivered(delivered_by: Node, item: CarryableItem, delivered_to: Node) -> void:
	prints(delivered_by, 'delivered', item, 'to', delivered_to)
	return
