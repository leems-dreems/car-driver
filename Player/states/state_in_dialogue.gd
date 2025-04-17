extends PlayerState

var npc_interact_area: NPCInteractArea


func enter(_previous_state_path: String, _data := {}) -> void:
	npc_interact_area = player.targeted_interactable
	npc_interact_area.ink_player.ended.connect(handle_dialogue_end)
	if player.targeted_interactable != null:
		player.short_press_interact_unhighlight.emit()
		player.long_press_interact_unhighlight.emit()
		player.targeted_interactable.unhighlight()
		player.targeted_interactable = null
	return


func exit() -> void:
	npc_interact_area.ink_player.ended.disconnect(handle_dialogue_end)
	return


func handle_dialogue_end() -> void:
	get_viewport().gui_release_focus()
	npc_interact_area.dialogue_bubble.visible = false
	npc_interact_area.dialogue_bubble.control.visible = false
#	npc_interact_area.ink_player.reset()
	if player._carried_item == null:
		finished.emit(EMPTY_HANDED)
	else:
		finished.emit(CARRYING)
	return
