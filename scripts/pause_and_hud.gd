extends CanvasLayer

@export var vehicle : Vehicle
@export var player : Player:
	set(_player):
		player = _player
		connect_to_player(_player)
		show_prompts_for_state(_player.state_machine.state.name)
@onready var vehicle_hud_label := $HUD/VehicleInfoLabel
@onready var mission_label := $HUD/MissionLabelContainer/MissionLabel
@onready var paused_UI := $PausedUI
@onready var pause_menu := $PausedUI/PauseMenu
@onready var pause_menu_buttons := $PausedUI/PauseMenu/MarginContainer/VBoxContainer/PauseMenuButtons
@onready var pause_menu_slider := $PausedUI/PauseMenu/MarginContainer
@onready var options_menu := $PausedUI/OptionsMenu
@onready var _pickup_label := $HUD/VBoxContainer/Pickup_HBoxContainer/Label
@onready var _interact_short_press_label := $HUD/VBoxContainer/Interact_HBoxContainer/Label
@onready var _interact_long_press_label := $HUD/VBoxContainer/Interact_LongPress_HBoxContainer/Label
@onready var _interact_long_press_bar := $HUD/VBoxContainer/Interact_LongPress_Bar_HBoxContainer/ColorRect
@onready var _push_vehicle_label := $HUD/VBoxContainer/Push_HBoxContainer/Label
@onready var _push_prompt: HBoxContainer = $HUD/VBoxContainer/Push_HBoxContainer
@onready var _pickup_prompt: HBoxContainer = $HUD/VBoxContainer/Pickup_HBoxContainer
@onready var _interact_prompt: HBoxContainer = $HUD/VBoxContainer/Interact_HBoxContainer
@onready var _interact_longpress_prompt: HBoxContainer = $HUD/VBoxContainer/Interact_LongPress_HBoxContainer
@onready var _handbrake_prompt: MarginContainer = $Handbrake_MarginContainer
@onready var _aim_prompt := $HUD/VBoxContainer/Aim_HBoxContainer
@onready var _throw_prompt := $HUD/VBoxContainer/Throw_HBoxContainer
const _interact_long_press_time := 0.4 ## This should match the value in Player.gd
var _long_press_bar_tween: Tween
var paused_timer: SceneTreeTimer = null
var is_opening := false
var is_closing := false
var modulate_opaque := Color(1, 1, 1, 1)
var modulate_transparent := Color(1, 1, 1, 0)
enum INPUT_METHODS { GAMEPAD, KEYBOARD }
var last_input_method: INPUT_METHODS
var _carried_item_name := ""
var input_switch_timer: SceneTreeTimer = null
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


func _unhandled_input(event: InputEvent) -> void:
	if get_tree().paused and event.is_action_pressed("Pause") and not event.is_echo() and not (is_closing or is_opening):
		animate_closed()
		return
	return


func _process(_delta: float) -> void:
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
		_handbrake_prompt.visible = false
		$HUD.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if not paused_UI.visible:
			animate_open()
		$PausedUI.mouse_filter = Control.MOUSE_FILTER_STOP

		var _focussed_control := get_viewport().gui_get_focus_owner()
		if Input.is_action_just_pressed("ui_down") and _focussed_control == null:
			$PausedUI/PauseMenu/MarginContainer/VBoxContainer/PauseMenuButtons/ResumeButton.grab_focus.call_deferred()
		elif Input.is_action_just_pressed("ui_up") and _focussed_control == null:
			$PausedUI/PauseMenu/MarginContainer/VBoxContainer/PauseMenuButtons/QuitButton.grab_focus.call_deferred()
	else:
		options_menu.visible = false
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		$HUD.visible = true
		_handbrake_prompt.visible = true
		$HUD.mouse_filter = Control.MOUSE_FILTER_PASS
		$PausedUI.visible = false
		$PausedUI.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if player.current_vehicle != null:
			_handbrake_prompt.rotation = lerpf(0, PI / 4, player.current_vehicle.handbrake_input)
		_update_hud()

	set_aim_key_pressed(Input.is_action_pressed("aim"))
	set_throw_key_pressed(Input.is_action_pressed("throw"))
	set_push_key_pressed(Input.is_action_pressed("push_vehicle"))
	set_pickup_key_pressed(Input.is_action_pressed("pickup_drop"))
	set_interact_key_pressed(Input.is_action_pressed("interact"))
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
	_interact_short_press_label.modulate = Color(0.6, 0.6, 0.6, 1.0)
	_interact_short_press_label.text = "Interact"
	_pickup_label.modulate = Color(0.6, 0.6, 0.6, 1.0)
	_pickup_label.text = "Take"
	_interact_long_press_label.modulate = Color(0.6, 0.6, 0.6, 1.0)
	_interact_long_press_label.text = "(Hold)"
	_push_vehicle_label.modulate = Color(0.6, 0.6, 0.6, 1.0)
	_handbrake_prompt.pivot_offset = _handbrake_prompt.size - Vector2(_handbrake_prompt.get_theme_constant("margin_right"), _handbrake_prompt.get_theme_constant("margin_bottom"))
	return


func set_aim_key_pressed(_pressed: bool) -> void:
	match last_input_method:
		INPUT_METHODS.GAMEPAD:
			$HUD/VBoxContainer/Aim_HBoxContainer/Gamepad_Unpressed.visible = not _pressed
			$HUD/VBoxContainer/Aim_HBoxContainer/Gamepad_Pressed.visible = _pressed
			$HUD/VBoxContainer/Aim_HBoxContainer/Keyboard_Unpressed.visible = false
			$HUD/VBoxContainer/Aim_HBoxContainer/Keyboard_Pressed.visible = false
		INPUT_METHODS.KEYBOARD:
			$HUD/VBoxContainer/Aim_HBoxContainer/Keyboard_Unpressed.visible = not _pressed
			$HUD/VBoxContainer/Aim_HBoxContainer/Keyboard_Pressed.visible = _pressed
			$HUD/VBoxContainer/Aim_HBoxContainer/Gamepad_Unpressed.visible = false
			$HUD/VBoxContainer/Aim_HBoxContainer/Gamepad_Pressed.visible = false
	return


func set_throw_key_pressed(_pressed: bool) -> void:
	match last_input_method:
		INPUT_METHODS.GAMEPAD:
			$HUD/VBoxContainer/Throw_HBoxContainer/Gamepad_Unpressed.visible = not _pressed
			$HUD/VBoxContainer/Throw_HBoxContainer/Gamepad_Pressed.visible = _pressed
			$HUD/VBoxContainer/Throw_HBoxContainer/Keyboard_Unpressed.visible = false
			$HUD/VBoxContainer/Throw_HBoxContainer/Keyboard_Pressed.visible = false
		INPUT_METHODS.KEYBOARD:
			$HUD/VBoxContainer/Throw_HBoxContainer/Keyboard_Unpressed.visible = not _pressed
			$HUD/VBoxContainer/Throw_HBoxContainer/Keyboard_Pressed.visible = _pressed
			$HUD/VBoxContainer/Throw_HBoxContainer/Gamepad_Unpressed.visible = false
			$HUD/VBoxContainer/Throw_HBoxContainer/Gamepad_Pressed.visible = false
	return


func set_push_key_pressed(_pressed: bool) -> void:
	match last_input_method:
		INPUT_METHODS.GAMEPAD:
			$HUD/VBoxContainer/Push_HBoxContainer/Gamepad_Unpressed.visible = not _pressed
			$HUD/VBoxContainer/Push_HBoxContainer/Gamepad_Pressed.visible = _pressed
			$HUD/VBoxContainer/Push_HBoxContainer/Keyboard_Unpressed.visible = false
			$HUD/VBoxContainer/Push_HBoxContainer/Keyboard_Pressed.visible = false
		INPUT_METHODS.KEYBOARD:
			$HUD/VBoxContainer/Push_HBoxContainer/Keyboard_Unpressed.visible = not _pressed
			$HUD/VBoxContainer/Push_HBoxContainer/Keyboard_Pressed.visible = _pressed
			$HUD/VBoxContainer/Push_HBoxContainer/Gamepad_Unpressed.visible = false
			$HUD/VBoxContainer/Push_HBoxContainer/Gamepad_Pressed.visible = false
	return


func set_pickup_key_pressed(_pressed: bool) -> void:
	match last_input_method:
		INPUT_METHODS.GAMEPAD:
			$HUD/VBoxContainer/Pickup_HBoxContainer/Gamepad_Unpressed.visible = not _pressed
			$HUD/VBoxContainer/Pickup_HBoxContainer/Gamepad_Pressed.visible = _pressed
			$HUD/VBoxContainer/Pickup_HBoxContainer/Keyboard_Unpressed.visible = false
			$HUD/VBoxContainer/Pickup_HBoxContainer/Keyboard_Pressed.visible = false
		INPUT_METHODS.KEYBOARD:
			$HUD/VBoxContainer/Pickup_HBoxContainer/Keyboard_Unpressed.visible = not _pressed
			$HUD/VBoxContainer/Pickup_HBoxContainer/Keyboard_Pressed.visible = _pressed
			$HUD/VBoxContainer/Pickup_HBoxContainer/Gamepad_Unpressed.visible = false
			$HUD/VBoxContainer/Pickup_HBoxContainer/Gamepad_Pressed.visible = false
	return


func set_interact_key_pressed(_pressed: bool) -> void:
	match last_input_method:
		INPUT_METHODS.GAMEPAD:
			$HUD/VBoxContainer/Interact_HBoxContainer/Gamepad_Unpressed.visible = not _pressed
			$HUD/VBoxContainer/Interact_HBoxContainer/Gamepad_Pressed.visible = _pressed
			$HUD/VBoxContainer/Interact_HBoxContainer/Keyboard_Unpressed.visible = false
			$HUD/VBoxContainer/Interact_HBoxContainer/Keyboard_Pressed.visible = false
			$HUD/VBoxContainer/Interact_LongPress_HBoxContainer/Gamepad_Unpressed.visible = not _pressed
			$HUD/VBoxContainer/Interact_LongPress_HBoxContainer/Gamepad_Pressed.visible = _pressed
			$HUD/VBoxContainer/Interact_LongPress_HBoxContainer/Keyboard_Unpressed.visible = false
			$HUD/VBoxContainer/Interact_LongPress_HBoxContainer/Keyboard_Pressed.visible = false
			$Handbrake_MarginContainer/HBoxContainer/DpadSprite.visible = true
			$Handbrake_MarginContainer/HBoxContainer/MouseSprite.visible = false
		INPUT_METHODS.KEYBOARD:
			$HUD/VBoxContainer/Interact_HBoxContainer/Keyboard_Unpressed.visible = not _pressed
			$HUD/VBoxContainer/Interact_HBoxContainer/Keyboard_Pressed.visible = _pressed
			$HUD/VBoxContainer/Interact_HBoxContainer/Gamepad_Unpressed.visible = false
			$HUD/VBoxContainer/Interact_HBoxContainer/Gamepad_Pressed.visible = false
			$HUD/VBoxContainer/Interact_LongPress_HBoxContainer/Keyboard_Unpressed.visible = not _pressed
			$HUD/VBoxContainer/Interact_LongPress_HBoxContainer/Keyboard_Pressed.visible = _pressed
			$HUD/VBoxContainer/Interact_LongPress_HBoxContainer/Gamepad_Unpressed.visible = false
			$HUD/VBoxContainer/Interact_LongPress_HBoxContainer/Gamepad_Pressed.visible = false
			$Handbrake_MarginContainer/HBoxContainer/DpadSprite.visible = false
			$Handbrake_MarginContainer/HBoxContainer/MouseSprite.visible = true
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


func handle_reset_button() -> void:
	player.freeze = true
	player.set_deferred("transform", player._initial_transform)
	player.set_deferred("freeze", false)
	return


func handle_quit_button() -> void:
	if $ClickAudio.playing:
		await $ClickAudio.finished
	get_tree().quit()
	return


func handle_options_back_button() -> void:
	var _slider_tween := create_tween()
	_slider_tween.tween_property(pause_menu_slider, "theme_override_constants/margin_left", 0, 0.15)
	_slider_tween.parallel().tween_property(pause_menu_slider, "modulate", modulate_opaque, 0.15)
	_slider_tween.parallel().tween_property(options_menu, "modulate", modulate_transparent, 0.15)
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

# TODO: Move each block into its own function, then connect those functions to new player signals e.g. interact, pickup etc
func connect_to_player(_player: Player) -> void:
	_player.state_changed.connect(show_prompts_for_state)

	_player.short_press_interact_highlight.connect(func(_target: InteractableArea):
		_interact_short_press_label.modulate = Color(1.0, 1.0, 1.0, 1.0)
		_interact_short_press_label.text = _target.short_press_text.capitalize()
	)
	_player.short_press_interact_unhighlight.connect(func():
		_interact_short_press_label.modulate = Color(0.6, 0.6, 0.6, 1.0)
		_interact_short_press_label.text = "Interact"
	)
	_player.short_press_interact_start.connect(func():
		_interact_short_press_label.modulate = Color(0.91, 0.94, 0.01, 1.0)
	)
	_player.short_press_interact_finish.connect(func():
		_interact_short_press_label.modulate = Color(0.6, 0.6, 0.6, 1.0)
		_interact_short_press_label.text = "Interact"
	)

	_player.long_press_interact_highlight.connect(func(_target: Node3D):
		_interact_long_press_label.modulate = Color(1.0, 1.0, 1.0, 1.0)
		_interact_long_press_label.text = "(Hold) " + _target.long_press_text.capitalize()
	)
	_player.long_press_interact_unhighlight.connect(func():
		_interact_long_press_label.modulate = Color(0.6, 0.6, 0.6, 1.0)
		_interact_long_press_label.text = "(Hold)"
	)
	_player.long_press_interact_start.connect(func(start_ratio := 0.0):
		_interact_long_press_label.modulate = Color(0.91, 0.94, 0.01, 1.0)
		start_ratio = clampf(start_ratio, 0.0, 1.0)
		if start_ratio > 0:
			_interact_long_press_bar.custom_minimum_size = Vector2(0, _interact_long_press_bar.get_parent().size.y).lerp(_interact_long_press_bar.get_parent().size, start_ratio)
		_long_press_bar_tween = get_tree().create_tween()
		_long_press_bar_tween.tween_property(_interact_long_press_bar, "custom_minimum_size", _interact_long_press_bar.get_parent().size, _interact_long_press_time)
#		_long_press_bar_tween
	)
	_player.long_press_interact_cancel.connect(func():
		_interact_long_press_label.modulate = Color(0.6, 0.6, 0.6, 1.0)
		_interact_long_press_label.text = "(Hold)"
		_long_press_bar_tween.kill()
		_interact_long_press_bar.custom_minimum_size = _interact_long_press_bar.get_parent().custom_minimum_size
	)
	_player.long_press_interact_finish.connect(func():
		_interact_long_press_label.modulate = Color(0.6, 0.6, 0.6, 1.0)
		_interact_long_press_label.text = "(Hold)"
		_long_press_bar_tween.kill()
		_interact_long_press_bar.custom_minimum_size = _interact_long_press_bar.get_parent().custom_minimum_size
	)

	_player.short_press_pickup_highlight.connect(func(_target: Node3D):
		_pickup_label.modulate = Color(1.0, 1.0, 1.0, 1.0)
		_pickup_label.text = "Take"
	)
	_player.short_press_pickup_unhighlight.connect(func():
		_pickup_label.modulate = Color(0.6, 0.6, 0.6, 1.0)
		_pickup_label.text = "Take"
	)
	_player.short_press_pickup_start.connect(func():
		_pickup_label.modulate = Color(0.91, 0.94, 0.01, 1.0)
	)

	_player.item_picked_up.connect(func(_item: CarryableItem):
		_carried_item_name = _item.item_name
		_pickup_label.modulate = Color(1.0, 1.0, 1.0, 1.0)
		_pickup_label.text = "Drop " + _carried_item_name
	)
	_player.item_dropped.connect(func():
		_carried_item_name = ""
		_pickup_label.modulate = Color(0.6, 0.6, 0.6, 1.0)
		_pickup_label.text = "Take"
	)
	_player.short_press_drop_highlight.connect(func(_target: Node3D):
		_pickup_label.modulate = Color(1.0, 1.0, 1.0, 1.0)
		_pickup_label.text = "Put " + _carried_item_name + " in " + _target.container_name
	)
	_player.short_press_drop_unhighlight.connect(func():
		_pickup_label.modulate = Color(1.0, 1.0, 1.0, 1.0)
		_pickup_label.text = "Drop " + _carried_item_name
	)
	_player.short_press_drop_start.connect(func():
		_pickup_label.modulate = Color(0.91, 0.94, 0.01, 1.0)
	)

	_player.push_vehicle_highlight.connect(func():
		_push_vehicle_label.modulate = Color(1.0, 1.0, 1.0, 1.0)
	)
	_player.push_vehicle_unhighlight.connect(func():
		_push_vehicle_label.modulate = Color(0.6, 0.6, 0.6, 1.0)
	)
	_player.push_vehicle_start.connect(func():
		_push_vehicle_label.modulate = Color(0.91, 0.94, 0.01, 1.0)
	)

	_player.vehicle_entered.connect(func(_vehicle: DriveableVehicle):
		reset_controls()
		$PausedUI/PauseMenu/MarginContainer/VBoxContainer/PauseMenuButtons/ResetButton.disabled = true
		_interact_short_press_label.modulate = Color(1.0, 1.0, 1.0, 1.0)
		_interact_short_press_label.text = "Exit " + _vehicle.vehicle_category
		set_handbrake_prompt_visible(true)
	)
	_player.vehicle_exited.connect(func():
		reset_controls()
		$HUD/VBoxContainer/Push_HBoxContainer.visible = true
		$HUD/VBoxContainer/Pickup_HBoxContainer.visible = true
		$HUD/VBoxContainer/Interact_LongPress_HBoxContainer.visible = true
		$PausedUI/PauseMenu/MarginContainer/VBoxContainer/PauseMenuButtons/ResetButton.disabled = false
		set_handbrake_prompt_visible(false)
	)
	return


func show_prompts_for_state(_state_name: String) -> void:
	match _state_name:
		"EmptyHanded":
			set_push_prompt_visible(true)
			set_pickup_prompt_visible(true)
			set_interact_prompt_visible(true)
			set_interact_longpress_prompt_visible(true)
			set_handbrake_prompt_visible(false)
			set_aim_prompt_visible(false)
			set_throw_prompt_visible(false)
		"Carrying":
			set_push_prompt_visible(true)
			set_pickup_prompt_visible(true)
			set_interact_prompt_visible(true)
			set_interact_longpress_prompt_visible(false)
			set_handbrake_prompt_visible(false)
			set_aim_prompt_visible(true)
			set_throw_prompt_visible(false)
		"Aiming":
			set_push_prompt_visible(true)
			set_pickup_prompt_visible(true)
			set_interact_prompt_visible(true)
			set_interact_longpress_prompt_visible(false)
			set_handbrake_prompt_visible(false)
			set_aim_prompt_visible(false)
			set_throw_prompt_visible(true)
		"Driving":
			set_push_prompt_visible(false)
			set_pickup_prompt_visible(false)
			set_interact_prompt_visible(true)
			set_interact_longpress_prompt_visible(false)
			set_handbrake_prompt_visible(true)
			set_aim_prompt_visible(false)
			set_throw_prompt_visible(false)
		"InDialogue":
			set_push_prompt_visible(false)
			set_pickup_prompt_visible(false)
			set_interact_prompt_visible(false)
			set_interact_longpress_prompt_visible(false)
			set_handbrake_prompt_visible(false)
			set_aim_prompt_visible(false)
			set_throw_prompt_visible(false)
		_:
			prints("HUD doesn't know which prompts to show for player state:", _state_name)
	return


func set_push_prompt_visible(_visible: bool) -> void:
	_push_prompt.visible = true if _visible else false
	return


func set_pickup_prompt_visible(_visible: bool) -> void:
	_pickup_prompt.visible = true if _visible else false
	return


func set_interact_prompt_visible(_visible: bool) -> void:
	_interact_prompt.visible = true if _visible else false
	return


func set_interact_longpress_prompt_visible(_visible: bool) -> void:
	_interact_longpress_prompt.visible = true if _visible else false
	return


func set_handbrake_prompt_visible(_visible: bool) -> void:
	_handbrake_prompt.modulate = Color.WHITE if _visible else Color(1.0, 1.0, 1.0, 0.0)
	return


func set_aim_prompt_visible(_visible: bool) -> void:
	_aim_prompt.visible = true if _visible else false
	return


func set_throw_prompt_visible(_visible: bool) -> void:
	_throw_prompt.visible = true if _visible else false
	return
