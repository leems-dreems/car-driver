extends CanvasLayer

@export var vehicle : Vehicle
@export var player : Player
@export var stageMenu : PackedScene
@onready var vehicle_hud_label := $HUD/VehicleInfoLabel
@onready var use_label := $HUD/UseLabelContainer/UseLabel
@onready var mission_label := $HUD/MissionLabelContainer/MissionLabel


func _process(_delta: float) -> void:
  if Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
    $HUD.visible = false
    $HUD.mouse_filter = Control.MOUSE_FILTER_IGNORE
    $PauseMenu.visible = true
    $PauseMenu.mouse_filter = Control.MOUSE_FILTER_STOP
  else:
    $HUD.visible = true
    $HUD.mouse_filter = Control.MOUSE_FILTER_PASS
    $PauseMenu.visible = false
    $PauseMenu.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _update_hud()


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


func handle_resume_button() -> void:
  Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func handle_quit_button() -> void:
  get_tree().quit()

func _on_stage_select_button_pressed() -> void:
    var menu = stageMenu.instantiate()
    add_child(menu)
