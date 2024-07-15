extends Node3D

@export var start_level: PackedScene = null



func _on_start_game_button_pressed() -> void:
    get_tree().change_scene_to_packed(start_level)


func _on_quit_game_button_pressed() -> void:
    get_tree().quit()
