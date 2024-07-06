extends CanvasLayer

@export var vehicle : Vehicle
@export var player : Player


func _process (_delta: float) -> void:
  $MarginContainer/Label.text = 'Throttle: ' + '%.2f' % vehicle.throttle_input
  $MarginContainer/Label.text += '\nBrake: ' + '%.2f' % vehicle.brake_input
  $MarginContainer/Label.text += '\nHandbrake: ' + str(vehicle.handbrake_input)
  $MarginContainer/Label.text += '\nSteer: ' + '%.2f' % vehicle.steering_input
  $MarginContainer/Label.text += '\nGear: ' + str(vehicle.current_gear)

  if player.useable_target != null:
    $UseLabel.text = 'Open Door'
  else:
    $UseLabel.text = ''
