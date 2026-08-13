class_name NPCInteractArea extends InteractableArea

@export var dialogue_resource: DialogueResource
var npc: NPC


func _ready() -> void:
	await owner.ready
	npc = owner as NPC
	assert(npc != null, "Owner of NPC interact area needs to be an NPC node")
	return


func can_interact_short_press() -> bool:
	return true


func interact_short_press() -> void:
	DialogueManager.show_dialogue_balloon(dialogue_resource)
	Game.start_speaking_to(npc)
	return
