extends Node

signal quest_accepted


func emit_quest_accepted(quest_name: String) -> void:
	quest_accepted.emit(quest_name)
