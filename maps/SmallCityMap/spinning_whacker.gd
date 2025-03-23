class_name SpinningWhacker extends Node3D

var request_stop_timer: SceneTreeTimer = null

## Ask this whacker to stop spinning
func request_stop(_duration: float = 5.0) -> void:
	if request_stop_timer == null:
		request_stop_timer = get_tree().create_timer(_duration)
		$Generic6DOFJoint3D.set_flag_y(Generic6DOFJoint3D.FLAG_ENABLE_MOTOR, false)
		request_stop_timer.timeout.connect(func():
			request_stop_timer = null
			$Generic6DOFJoint3D.set_flag_y(Generic6DOFJoint3D.FLAG_ENABLE_MOTOR, true)
		)
	else:
		request_stop_timer.time_left = _duration
