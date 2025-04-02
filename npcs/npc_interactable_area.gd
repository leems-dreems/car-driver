class_name NPCInteractArea extends InteractableArea

@export var ink_player: InkPlayer
@export var dialogue_bubble: DialogueBubble
var npc: Pedestrian


func _ready() -> void:
	await owner.ready
	npc = owner as Pedestrian
	assert(npc != null, "Owner of NPC interact area needs to be a Pedestrian node")

	dialogue_bubble.visible = false
	dialogue_bubble.control.set_npc_name(npc.npc_name)
	dialogue_bubble.control.choice_selected.connect(on_choice_selected)
	dialogue_bubble.control.continue_dialogue.connect(continue_story)

	ink_player.loaded.connect(func(_success: bool):
		if not _success:
			print("Ink story loading was unsuccessful")
			return
		print("Loaded Ink story")
	)

	ink_player.create_story()
	return


func continue_story() -> void:
	var _new_text := ink_player.continue_story()
	while _new_text == "\n":
		_new_text = ink_player.continue_story()
	print(_new_text.trim_suffix("\n"))
	dialogue_bubble.control.show_dialogue(_new_text)
	dialogue_bubble.control.show_choices(ink_player.current_choices)
	if ink_player.has_choices:
		prints("Ink story has", str(len(ink_player.current_choices)), "choices")
	return


func can_interact_short_press() -> bool:
	return true


func interact_short_press() -> void:
	dialogue_bubble.visible = true
	continue_story()
	return


func on_choice_selected(_choice: InkChoice) -> void:
	ink_player.choose_choice_index(_choice.index)
	continue_story()
	return
