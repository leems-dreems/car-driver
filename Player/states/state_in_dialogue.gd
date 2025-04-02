extends PlayerState

var npc_interact_area: NPCInteractArea


func update(_delta: float) -> void:

	return


func physics_update(_delta: float) -> void:
	#player.process_interact_button()
	return


func enter(_previous_state_path: String, _data := {}) -> void:
	npc_interact_area = player.targeted_interactable
	npc_interact_area.ink_player.ended.connect(handle_dialogue_end)
	return


func exit() -> void:
	npc_interact_area.ink_player.ended.disconnect(handle_dialogue_end)
	return


func handle_dialogue_end() -> void:
	npc_interact_area.dialogue_bubble.visible = false
	npc_interact_area.ink_player.reset()
	if player._carried_item == null:
		finished.emit(EMPTY_HANDED)
	else:
		finished.emit(CARRYING)
	return
