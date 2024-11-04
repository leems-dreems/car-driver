extends CanvasLayer

@export var vehicle : Vehicle
@export var player : Player
@onready var vehicle_hud_label := $HUD/VehicleInfoLabel
@onready var use_label := $HUD/UseLabelContainer/UseLabel
@onready var mission_label := $HUD/MissionLabelContainer/MissionLabel
@onready var paused_UI := $PausedUI
@onready var pause_menu := $PausedUI/PauseMenu
@onready var options_menu := $PausedUI/OptionsMenu
var paused_timer: SceneTreeTimer = null



func _ready() -> void:
  paused_UI.visible = false
  pause_menu.visible = true
  options_menu.visible = false
  return


func _process(_delta: float) -> void:
  # Respond to pause button
  if get_tree().paused and Input.is_action_just_pressed("Pause"):
    get_tree().paused = false
  if get_tree().paused:
    Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
    $HUD.visible = false
    $HUD.mouse_filter = Control.MOUSE_FILTER_IGNORE
    $PausedUI.visible = true
    $PausedUI.mouse_filter = Control.MOUSE_FILTER_STOP
  else:
    options_menu.visible = false
    Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
    $HUD.visible = true
    $HUD.mouse_filter = Control.MOUSE_FILTER_PASS
    $PausedUI.visible = false
    $PausedUI.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _update_hud()
  return


func _update_hud() -> void:
  if player.current_mission != null:
    var current_objective := player.current_mission.get_current_objective()
    if current_objective == null:
      mission_label.text = "Mission complete"
    else:
      mission_label.text = current_objective.objective_text
  
  if player.current_vehicle != null:
    vehicle_hud_label.text = "Speed: " + str(int(player.current_vehicle.linear_velocity.length()))
    vehicle_hud_label.text += "\nGear: " + str(player.current_vehicle.current_gear)
  else:
    vehicle_hud_label.text = ""

  if player.useable_target != null:
    use_label.visible = true
    if player.useable_target.has_method("get_use_label"):
      use_label.text = player.useable_target.get_use_label()
    elif player.useable_target is ObjectiveArea:
      use_label.text = player.useable_target.objective_text
    else:
      use_label.text = "Use"
  else:
    use_label.visible = false
    use_label.text = ""
  return


func handle_resume_button() -> void:
  get_tree().paused = false
  return


func handle_options_button() -> void:
  if options_menu.visible:
    options_menu.visible = false
  else:
    options_menu.visible = true
  return


func handle_quit_button() -> void:
  get_tree().quit()
  return


func handle_fullscreen_toggle(toggle_on: bool) -> void:
  Game.change_window_mode(toggle_on)
  return

#func _on_stage_select_button_pressed() -> void:
  #var menu := stageMenu.instantiate()
  #add_child(menu)
  #return
