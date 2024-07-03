extends VehicleBody3D

var max_rpm := 1000.0
var max_torque := 4000.0

func _physics_process (delta: float) -> void:
  steering = lerp(steering, Input.get_axis('Steer Right', 'Steer Left') * 0.5, 5 * delta)
  var acceleration := Input.get_axis('Brake or Reverse', 'Accelerate')
  if Input.is_action_pressed('Handbrake'):
    $VehicleWheel3D_RL.brake = 30
    $VehicleWheel3D_RR.brake = 30
    $VehicleWheel3D_RL.engine_force = 0
    $VehicleWheel3D_RR.engine_force = 0
  else:
    $VehicleWheel3D_RL.brake = 0
    $VehicleWheel3D_RR.brake = 0
    var rpm : float = $VehicleWheel3D_RL.get_rpm()
    $VehicleWheel3D_RL.engine_force = acceleration * max_torque * (1 - rpm / max_rpm)
    rpm = $VehicleWheel3D_RR.get_rpm()
    $VehicleWheel3D_RR.engine_force = acceleration * max_torque * (1 - rpm / max_rpm)
