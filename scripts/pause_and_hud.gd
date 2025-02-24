extends CanvasLayer

@export var vehicle : Vehicle
@export var player : Player:
	set(_player):
		player = _player
		connect_to_player(_player)
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
enum INPUT_METHODS { GAMEPAD, KEYBOARD }
var last_input_method: INPUT_METHODS
var _carried_item_name := ""
var input_switch_timer: SceneTreeTimer = null
var _pickup_press_timer: SceneTreeTimer = null
var _interact_press_timer: SceneTreeTimer = null
const _button_minimum_press_time := 0.2


func _ready() -> void:
	paused_UI.visible = false
	paused_UI.modulate = modulate_transparent
	pause_menu.visible = true
	options_menu.visible = false
	vehicle_hud_label.text = ""
	for _pause_menu_button in pause_menu_buttons.get_children():
		_pause_menu_button.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_pause_menu_button.focus_mode = Control.FOCUS_NONE
	reset_controls()
	return


func _process(_delta: float) -> void:
	# Respond to pause button
	if get_tree().paused and Input.is_action_just_pressed("Pause") and not (is_closing or is_opening):
		animate_closed()
	if input_switch_timer == null:
		match last_input_method:
			INPUT_METHODS.GAMEPAD:
				if Input.is_action_pressed("keyboard_input") or Input.get_last_mouse_velocity().length_squared() > 10000:
					last_input_method = INPUT_METHODS.KEYBOARD
					input_switch_timer = get_tree().create_timer(1.0)
					input_switch_timer.timeout.connect(func(): input_switch_timer = null)
			INPUT_METHODS.KEYBOARD:
				if Input.is_action_pressed("gamepad_input") or Input.get_action_strength("gamepad_axes") > 0 or Input.get_action_strength("gamepad_axes_n") > 0:
					last_input_method = INPUT_METHODS.GAMEPAD
					input_switch_timer = get_tree().create_timer(1.0)
					input_switch_timer.timeout.connect(func(): input_switch_timer = null)
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

	#if Input.is_action_just_pressed("pickup_drop"):
		#_pickup_press_timer = get_tree().create_timer(_button_minimum_press_time)
		#_pickup_press_timer.timeout.connect(func(): _pickup_press_timer = null)
	#if Input.is_action_just_pressed("interact"):
		#_interact_press_timer = get_tree().create_timer(_button_minimum_press_time)
		#_interact_press_timer.timeout.connect(func(): _interact_press_timer = null)
	set_pickup_key_pressed(Input.is_action_pressed("pickup_drop") or _pickup_press_timer != null)
	set_interact_key_pressed(Input.is_action_pressed("interact") or _interact_press_timer != null)
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
	return


func reset_controls() -> void:
	$HUD/VBoxContainer/Interact_HBoxContainer/Label.modulate = Color(0.6, 0.6, 0.6, 1.0)
	$HUD/VBoxContainer/Interact_HBoxContainer/Label.text = "Interact"
	$HUD/VBoxContainer/Pickup_HBoxContainer/Label.modulate = Color(0.6, 0.6, 0.6, 1.0)
	$HUD/VBoxContainer/Pickup_HBoxContainer/Label.text = "Pickup"
	$HUD/VBoxContainer/PickupLongPress_HBoxContainer/Label.modulate = Color(0.6, 0.6, 0.6, 1.0)
	$HUD/VBoxContainer/PickupLongPress_HBoxContainer/Label.text = "(Hold)"
	return


func set_pickup_key_pressed(_pressed: bool) -> void:
	match last_input_method:
		INPUT_METHODS.GAMEPAD:
			$HUD/VBoxContainer/Pickup_HBoxContainer/Gamepad_Unpressed.visible = not _pressed
			$HUD/VBoxContainer/Pickup_HBoxContainer/Gamepad_Pressed.visible = _pressed
			$HUD/VBoxContainer/Pickup_HBoxContainer/Keyboard_Unpressed.visible = false
			$HUD/VBoxContainer/Pickup_HBoxContainer/Keyboard_Pressed.visible = false
			$HUD/VBoxContainer/PickupLongPress_HBoxContainer/Gamepad_Unpressed.visible = not _pressed
			$HUD/VBoxContainer/PickupLongPress_HBoxContainer/Gamepad_Pressed.visible = _pressed
			$HUD/VBoxContainer/PickupLongPress_HBoxContainer/Keyboard_Unpressed.visible = false
			$HUD/VBoxContainer/PickupLongPress_HBoxContainer/Keyboard_Pressed.visible = false
		INPUT_METHODS.KEYBOARD:
			$HUD/VBoxContainer/Pickup_HBoxContainer/Keyboard_Unpressed.visible = not _pressed
			$HUD/VBoxContainer/Pickup_HBoxContainer/Keyboard_Pressed.visible = _pressed
			$HUD/VBoxContainer/Pickup_HBoxContainer/Gamepad_Unpressed.visible = false
			$HUD/VBoxContainer/Pickup_HBoxContainer/Gamepad_Pressed.visible = false
			$HUD/VBoxContainer/PickupLongPress_HBoxContainer/Keyboard_Unpressed.visible = not _pressed
			$HUD/VBoxContainer/PickupLongPress_HBoxContainer/Keyboard_Pressed.visible = _pressed
			$HUD/VBoxContainer/PickupLongPress_HBoxContainer/Gamepad_Unpressed.visible = false
			$HUD/VBoxContainer/PickupLongPress_HBoxContainer/Gamepad_Pressed.visible = false
	return


func set_interact_key_pressed(_pressed: bool) -> void:
	match last_input_method:
		INPUT_METHODS.GAMEPAD:
			$HUD/VBoxContainer/Interact_HBoxContainer/Gamepad_Unpressed.visible = not _pressed
			$HUD/VBoxContainer/Interact_HBoxContainer/Gamepad_Pressed.visible = _pressed
			$HUD/VBoxContainer/Interact_HBoxContainer/Keyboard_Unpressed.visible = false
			$HUD/VBoxContainer/Interact_HBoxContainer/Keyboard_Pressed.visible = false
		INPUT_METHODS.KEYBOARD:
			$HUD/VBoxContainer/Interact_HBoxContainer/Keyboard_Unpressed.visible = not _pressed
			$HUD/VBoxContainer/Interact_HBoxContainer/Keyboard_Pressed.visible = _pressed
			$HUD/VBoxContainer/Interact_HBoxContainer/Gamepad_Unpressed.visible = false
			$HUD/VBoxContainer/Interact_HBoxContainer/Gamepad_Pressed.visible = false
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


func connect_to_player(_player: Player) -> void:
	_player.short_press_interact_highlight.connect(func(_target: Node3D):
		$HUD/VBoxContainer/Interact_HBoxContainer/Label.modulate = Color(1.0, 1.0, 1.0, 1.0)
		if _target.has_method("get_use_label"):
			$HUD/VBoxContainer/Interact_HBoxContainer/Label.text = _target.get_use_label()
		elif _target is ObjectiveArea:
			$HUD/VBoxContainer/Interact_HBoxContainer/Label.text = _target.objective_text
		else:
			$HUD/VBoxContainer/Interact_HBoxContainer/Label.text = "Interact"
	)
	_player.short_press_interact_unhighlight.connect(func():
		$HUD/VBoxContainer/Interact_HBoxContainer/Label.modulate = Color(0.6, 0.6, 0.6, 1.0)
		$HUD/VBoxContainer/Interact_HBoxContainer/Label.text = "Interact"
	)
	_player.short_press_interact_start.connect(func():
		$HUD/VBoxContainer/Interact_HBoxContainer/Label.modulate = Color(0.91, 0.94, 0.01, 1.0)
	)
	_player.short_press_interact_finish.connect(func():
		$HUD/VBoxContainer/Interact_HBoxContainer/Label.modulate = Color(0.6, 0.6, 0.6, 1.0)
		$HUD/VBoxContainer/Interact_HBoxContainer/Label.text = "Interact"
	)

	_player.short_press_pickup_highlight.connect(func(_target: Node3D):
		$HUD/VBoxContainer/Pickup_HBoxContainer/Label.modulate = Color(1.0, 1.0, 1.0, 1.0)
		$HUD/VBoxContainer/Pickup_HBoxContainer/Label.text = "Pickup " + _target.item_name
	)
	_player.short_press_pickup_unhighlight.connect(func():
		$HUD/VBoxContainer/Pickup_HBoxContainer/Label.modulate = Color(0.6, 0.6, 0.6, 1.0)
		$HUD/VBoxContainer/Pickup_HBoxContainer/Label.text = "Pickup"
	)
	_player.short_press_pickup_start.connect(func():
		$HUD/VBoxContainer/Pickup_HBoxContainer/Label.modulate = Color(0.91, 0.94, 0.01, 1.0)
	)

	_player.item_picked_up.connect(func(_item: CarryableItem):
		_carried_item_name = _item.item_name
		$HUD/VBoxContainer/Pickup_HBoxContainer/Label.modulate = Color(1.0, 1.0, 1.0, 1.0)
		$HUD/VBoxContainer/Pickup_HBoxContainer/Label.text = "Drop " + _carried_item_name
	)
	_player.item_dropped.connect(func():
		_carried_item_name = ""
		$HUD/VBoxContainer/Pickup_HBoxContainer/Label.modulate = Color(0.6, 0.6, 0.6, 1.0)
		$HUD/VBoxContainer/Pickup_HBoxContainer/Label.text = "Pickup"
	)
	_player.short_press_drop_highlight.connect(func(_target: Node3D):
		$HUD/VBoxContainer/Pickup_HBoxContainer/Label.modulate = Color(1.0, 1.0, 1.0, 1.0)
		$HUD/VBoxContainer/Pickup_HBoxContainer/Label.text = "Put " + _carried_item_name + " in " + _target.container_name
	)
	_player.short_press_drop_unhighlight.connect(func():
		$HUD/VBoxContainer/Pickup_HBoxContainer/Label.modulate = Color(1.0, 1.0, 1.0, 1.0)
		$HUD/VBoxContainer/Pickup_HBoxContainer/Label.text = "Drop " + _carried_item_name
	)
	_player.short_press_drop_start.connect(func():
		$HUD/VBoxContainer/Pickup_HBoxContainer/Label.modulate = Color(0.91, 0.94, 0.01, 1.0)
	)

	_player.long_press_pickup_highlight.connect(func(_target: Node3D):
		$HUD/VBoxContainer/PickupLongPress_HBoxContainer/Label.modulate = Color(1.0, 1.0, 1.0, 1.0)
		if _target is CarryableItem:
			$HUD/VBoxContainer/PickupLongPress_HBoxContainer/Label.text = "(Hold) Take " + _target.item_name + " from " + _target.container_node.container_name
		elif _target is RigidBinContainer:
			$HUD/VBoxContainer/PickupLongPress_HBoxContainer/Label.text = "(Hold) Empty " + _target.container_name
	)
	_player.long_press_pickup_unhighlight.connect(func():
		$HUD/VBoxContainer/PickupLongPress_HBoxContainer/Label.modulate = Color(0.6, 0.6, 0.6, 1.0)
		$HUD/VBoxContainer/PickupLongPress_HBoxContainer/Label.text = "(Hold)"
	)
	_player.long_press_pickup_start.connect(func():
		$HUD/VBoxContainer/PickupLongPress_HBoxContainer/Label.modulate = Color(0.91, 0.94, 0.01, 1.0)
	)
	_player.long_press_pickup_cancel.connect(func():
		$HUD/VBoxContainer/PickupLongPress_HBoxContainer/Label.modulate = Color(0.6, 0.6, 0.6, 1.0)
		$HUD/VBoxContainer/PickupLongPress_HBoxContainer/Label.text = "(Hold)"
	)
	_player.long_press_pickup_finish.connect(func():
		$HUD/VBoxContainer/PickupLongPress_HBoxContainer/Label.modulate = Color(0.6, 0.6, 0.6, 1.0)
		$HUD/VBoxContainer/PickupLongPress_HBoxContainer/Label.text = "(Hold)"
	)

	_player.vehicle_entered.connect(func(_vehicle: DriveableVehicle):
		$HUD/VBoxContainer/Pickup_HBoxContainer.visible = false
		$HUD/VBoxContainer/PickupLongPress_HBoxContainer.visible = false
		$HUD/VBoxContainer/Interact_HBoxContainer/Label.modulate = Color(1.0, 1.0, 1.0, 1.0)
		$HUD/VBoxContainer/Interact_HBoxContainer/Label.text = "Exit " + _vehicle.vehicle_name
	)
	_player.vehicle_exited.connect(func():
		$HUD/VBoxContainer/Pickup_HBoxContainer.visible = true
		$HUD/VBoxContainer/PickupLongPress_HBoxContainer.visible = true
	)
	return
