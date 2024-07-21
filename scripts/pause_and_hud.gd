extends CanvasLayer

@export var vehicle : Vehicle
@export var player : Player


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
  if player.current_vehicle != null:
    $HUD/MarginContainer/Label.text = 'Throttle: ' + '%.2f' % player.current_vehicle.throttle_input
    $HUD/MarginContainer/Label.text += '\nBrake: ' + '%.2f' % player.current_vehicle.brake_input
    $HUD/MarginContainer/Label.text += '\nHandbrake: ' + str(player.current_vehicle.handbrake_input)
    $HUD/MarginContainer/Label.text += '\nSteer: ' + '%.2f' % player.current_vehicle.steering_input
    $HUD/MarginContainer/Label.text += '\nGear: ' + str(player.current_vehicle.current_gear)
  else:
    var current_mission := player.mission_manager.get_current_mission()
    if current_mission == null:
      $HUD/MarginContainer/Label.text = "No current mission"
    else:
      var current_objective := current_mission.get_current_objective()
      $HUD/MarginContainer/Label.text = current_objective.objective_text

  if player.useable_target != null:
    if player.useable_target.has_method('get_use_label'):
      $HUD/UseLabel.text = player.useable_target.get_use_label()
    elif player.useable_target is ObjectiveArea:
      $HUD/UseLabel.text = 'Use Objective Marker'
    else:
      $HUD/UseLabel.text = 'Use'
  else:
    $HUD/UseLabel.text = ''


func handle_resume_button() -> void:
  Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func handle_quit_button() -> void:
  get_tree().quit()
