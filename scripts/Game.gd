extends Node

signal player_changed_vehicle
var active_terrain: Terrain3D = null


func change_window_mode(toggle_on: bool) -> void:
	if toggle_on:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	return
