extends PlayerState

var npc_interact_area: NPCInteractArea


func enter(_previous_state_path: String, _data := {}) -> void:
	npc_interact_area = player.targeted_interactable
	DialogueManager.dialogue_ended.connect(handle_dialogue_end)
	if player.targeted_interactable != null:
		player.short_press_interact_unhighlight.emit()
		player.long_press_interact_unhighlight.emit()
		player.targeted_interactable.unhighlight()
		player.targeted_interactable = null
	return


func exit() -> void:
	DialogueManager.dialogue_ended.disconnect(handle_dialogue_end)
	return


func handle_dialogue_end(_resource: DialogueResource) -> void:
	get_viewport().gui_release_focus()
#	npc_interact_area.ink_player.reset()
	if player._carried_item == null:
		finished.emit(EMPTY_HANDED)
	else:
		finished.emit(CARRYING)
	return
