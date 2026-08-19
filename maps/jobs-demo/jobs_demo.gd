extends "res://maps/common/playable_map.gd"

@export var intro_dialogue: DialogueResource
@export var outro_dialogue: DialogueResource

var quests: Array[Node] = []
var completed_quests: Array[Quest] = []


func _ready() -> void:
	super()

	quests = find_children("*").filter(func(node: Node):
			return node is Quest)
	print(quests)
	QuestManager.quest_completed.connect(func(quest: Quest):
		completed_quests.push_back(quest)
		if len(completed_quests) >= len(quests):
			DialogueManager.show_dialogue_balloon(outro_dialogue))

	DialogueManager.show_dialogue_balloon(intro_dialogue)
	return
