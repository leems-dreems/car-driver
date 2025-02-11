extends CanvasLayer

@export var vehicle : Vehicle
@export var player : Player
@onready var vehicle_hud_label := $HUD/VehicleInfoLabel
@onready var mission_label := $HUD/MissionLabelContainer/MissionLabel
@onready var paused_UI := $PausedUI
@onready var pause_menu := $PausedUI/PauseMenu
@onready var pause_menu_buttons := $PausedUI/PauseMenu/MarginContainer/VBoxContainer/PauseMenuButtons
@onready var pause_menu_slider := $PausedUI/PauseMenu/MarginContainer
@onready var options_menu := $PausedUI/OptionsMenu
var paused_timer: SceneTreeTimer = null
var is_opening := false
var is_closing := false
var modulate_opaque := Color(1, 1, 1, 1)
var modulate_transparent := Color(1, 1, 1, 0)


func _ready() -> void:
	paused_UI.visible = false
	paused_UI.modulate = modulate_transparent
	pause_menu.visible = true
	options_menu.visible = false
	vehicle_hud_label.text = ""
	for _pause_menu_button in pause_menu_buttons.get_children():
		_pause_menu_button.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_pause_menu_button.focus_mode = Control.FOCUS_NONE
	return


func _process(_delta: float) -> void:
	# Respond to pause button
	if get_tree().paused and Input.is_action_just_pressed("Pause") and not (is_closing or is_opening):
		animate_closed()
	if get_tree().paused:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		$HUD.visible = false
		$HUD.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if not paused_UI.visible:
			animate_open()
		$PausedUI.mouse_filter = Control.MOUSE_FILTER_STOP
	else:
		options_menu.visible = false
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		$HUD.visible = true
		$HUD.mouse_filter = Control.MOUSE_FILTER_PASS
		$PausedUI.visible = false
		$PausedUI.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_update_hud()
	var _focussed_control := get_viewport().gui_get_focus_owner()
	if Input.is_action_just_pressed("ui_down") and _focussed_control == null:
		$PausedUI/PauseMenu/MarginContainer/VBoxContainer/PauseMenuButtons/ResumeButton.grab_focus.call_deferred()
	elif Input.is_action_just_pressed("ui_up") and _focussed_control == null:
		$PausedUI/PauseMenu/MarginContainer/VBoxContainer/PauseMenuButtons/QuitButton.grab_focus.call_deferred()
	if Input.is_action_pressed("use"):
		$HUD/VBoxContainer/Use_HBoxContainer/Unpressed_TextureRect.visible = false
		$HUD/VBoxContainer/Use_HBoxContainer/Pressed_TextureRect.visible = true
	else:
		$HUD/VBoxContainer/Use_HBoxContainer/Unpressed_TextureRect.visible = true
		$HUD/VBoxContainer/Use_HBoxContainer/Pressed_TextureRect.visible = false
	return


func animate_open() -> void:
	is_opening = true
	paused_UI.visible = true
	var _fade_tween = create_tween()
	_fade_tween.tween_property(paused_UI, "modulate", modulate_opaque, .1)
	_fade_tween.tween_callback(func():
		is_opening = false
		for _pause_menu_button in pause_menu_buttons.get_children():
			_pause_menu_button.mouse_filter = Control.MOUSE_FILTER_STOP
			_pause_menu_button.focus_mode = Control.FOCUS_ALL
		$PausedUI/PauseMenu/MarginContainer/VBoxContainer/PauseMenuButtons/ResumeButton.grab_focus.call_deferred()
	)
	return


func animate_closed() -> void:
	is_closing = true
	var _fade_tween = create_tween()
	_fade_tween.tween_property(paused_UI, "modulate", modulate_transparent, .1)
	_fade_tween.parallel().tween_property(pause_menu_slider, "modulate", modulate_opaque, 0.15)
	_fade_tween.parallel().tween_property(pause_menu_slider, "theme_override_constants/margin_left", 0, 0.15)
	_fade_tween.tween_callback(func():
		paused_UI.visible = false
		get_tree().paused = false
		is_closing = false
		options_menu.visible = false
		for _pause_menu_button in pause_menu_buttons.get_children():
			_pause_menu_button.mouse_filter = Control.MOUSE_FILTER_IGNORE
			_pause_menu_button.focus_mode = Control.FOCUS_NONE
	)
	return


func _update_hud() -> void:
	if player.current_mission != null:
		var current_objective := player.current_mission.get_current_objective()
		if current_objective == null:
			mission_label.text = "Mission complete"
		else:
			mission_label.text = current_objective.objective_text
	
	#if player.current_vehicle != null:
		#vehicle_hud_label.text = "Speed: " + str(int(player.current_vehicle.linear_velocity.length()))
		#vehicle_hud_label.text += "\nGear: " + str(player.current_vehicle.current_gear)
	#else:
		#vehicle_hud_label.text = ""

	if player.useable_target != null:
		$HUD/VBoxContainer/Use_HBoxContainer/Label.modulate = Color(1.0, 1.0, 1.0, 1.0)
		$HUD/VBoxContainer/Use_HBoxContainer/Label.text = "Use"
		if player.useable_target.has_method("get_use_label"):
			$HUD/VBoxContainer/Use_HBoxContainer/Label.text = player.useable_target.get_use_label()
		elif player.useable_target is ObjectiveArea:
			$HUD/VBoxContainer/Use_HBoxContainer/Label.text = player.useable_target.objective_text
		else:
			$HUD/VBoxContainer/Use_HBoxContainer/Label.text = "Use"
	elif len(player._pickups_in_range) > 0:
		$HUD/VBoxContainer/Use_HBoxContainer/Label.modulate = Color(1.0, 1.0, 1.0, 1.0)
		$HUD/VBoxContainer/Use_HBoxContainer/Label.text = "Pickup " + player._pickups_in_range[0].item_name
	else:
		$HUD/VBoxContainer/Use_HBoxContainer/Label.modulate = Color(0.6, 0.6, 0.6, 1.0)
		$HUD/VBoxContainer/Use_HBoxContainer/Label.text = "Use"
	return


func handle_resume_button() -> void:
	get_tree().paused = false
	return


func handle_options_button() -> void:
	var _slider_tween := create_tween()
	_slider_tween.tween_property(pause_menu_slider, "theme_override_constants/margin_left", -700, 0.15)
	_slider_tween.parallel().tween_property(pause_menu_slider, "modulate", modulate_transparent, 0.15)
	_slider_tween.parallel().tween_property(options_menu, "modulate", modulate_opaque, 0.15)
	options_menu.visible = true
	for _pause_menu_button in pause_menu_buttons.get_children():
		_pause_menu_button.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_pause_menu_button.focus_mode = Control.FOCUS_NONE
	_slider_tween.tween_callback(func():
		options_menu.mouse_filter = Control.MOUSE_FILTER_STOP
		options_menu.focus_mode = Control.FOCUS_ALL
		$PausedUI/OptionsMenu/VBoxContainer/BackButton.grab_focus.call_deferred()
	)
	return


func handle_quit_button() -> void:
	if $ClickAudio.playing:
		await $ClickAudio.finished
	get_tree().quit()
	return


func handle_fullscreen_toggle(toggle_on: bool) -> void:
	Game.change_window_mode(toggle_on)
	return


func handle_options_back_button() -> void:
	var _slider_tween := create_tween()
	_slider_tween.tween_property(pause_menu_slider, "theme_override_constants/margin_left", 0, 0.15)
	_slider_tween.parallel().tween_property(pause_menu_slider, "modulate", modulate_opaque, 0.15)
	_slider_tween.parallel().tween_property(options_menu, "modulate", modulate_transparent, 0.15)
	options_menu.visible = false
	options_menu.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_slider_tween.tween_callback(func():
		options_menu.visible = false
		options_menu.focus_mode = Control.FOCUS_NONE
		$PausedUI/PauseMenu/MarginContainer/VBoxContainer/PauseMenuButtons/OptionsButton.grab_focus.call_deferred()
		for _pause_menu_button in pause_menu_buttons.get_children():
			_pause_menu_button.mouse_filter = Control.MOUSE_FILTER_STOP
			_pause_menu_button.focus_mode = Control.FOCUS_ALL
	)
	return


func on_button_pressed() -> void:
	$ClickAudio.play()
	return


func on_button_focussed() -> void:
	$FocusAudio.play()
	return


func on_pause_menu_mouse_entered() -> void:
	for _button in pause_menu_buttons.get_children():
		_button.release_focus.call_deferred()
	return
