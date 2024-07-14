extends CanvasLayer

@export var vehicle : Vehicle
@export var player : Player


func _process (_delta: float) -> void:
  if player.current_vehicle != null:
    $MarginContainer/Label.text = 'Throttle: ' + '%.2f' % vehicle.throttle_input
    $MarginContainer/Label.text += '\nBrake: ' + '%.2f' % vehicle.brake_input
    $MarginContainer/Label.text += '\nHandbrake: ' + str(vehicle.handbrake_input)
    $MarginContainer/Label.text += '\nSteer: ' + '%.2f' % vehicle.steering_input
    $MarginContainer/Label.text += '\nGear: ' + str(vehicle.current_gear)
  else:
    $MarginContainer/Label.text = ''

  if player.useable_target != null:
    if player.useable_target.has_method('get_use_label'):
      $UseLabel.text = player.useable_target.get_use_label()
    else:
      $UseLabel.text = 'Use'
  else:
    $UseLabel.text = ''
