class_name NPCInteractArea extends InteractableArea

@export var ink_player: InkPlayer
@export var dialogue_bubble: DialogueBubble
var npc: Pedestrian


func _ready() -> void:
	await owner.ready
	npc = owner as Pedestrian
	assert(npc != null, "Owner of NPC interact area needs to be a Pedestrian node")

	dialogue_bubble.control.set_npc_name(npc.npc_name)

	ink_player.loaded.connect(func(_success: bool):
		if not _success:
			print("Ink story loading was unsuccessful")
			return
		print("Loaded Ink story")
	)
	ink_player.create_story()
	return


func can_interact_short_press() -> bool:
	return true


func interact_short_press() -> void:
	if not ink_player.can_continue:
		print("Ink story cannot continue")
		return
	var _new_text := ink_player.continue_story()
	while _new_text == "\n":
		_new_text = ink_player.continue_story()
	print(_new_text.trim_suffix("\n"))
	dialogue_bubble.control.show_dialogue(_new_text)
	dialogue_bubble.control.show_choices(ink_player.current_choices)
	if ink_player.has_choices:
		prints("Ink story has", str(len(ink_player.current_choices)), "choices")
	return
