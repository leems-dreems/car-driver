extends PlayerState

var npc_interact_area: NPCInteractArea


func update(_delta: float) -> void:
	
	return


func physics_update(_delta: float) -> void:
	player.process_interact_button()
	return


func enter(_previous_state_path: String, _data := {}) -> void:
	npc_interact_area = player.targeted_interactable
	return
