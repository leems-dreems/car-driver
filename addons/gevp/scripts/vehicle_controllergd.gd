class_name VehicleController extends Node3D

@export var vehicle_node : DriveableVehicle
const handbrake_scroll_multiplier := 0.2

#func _physics_process(_delta: float) -> void:
	#if not vehicle_node: return
	#if not vehicle_node.is_being_driven:
		#vehicle_node.ignition_on = false
		#return
#
	#vehicle_node.brake_input = Input.get_action_strength("Brake or Reverse")
	#vehicle_node.steering_input = Input.get_action_strength("Steer Left") - Input.get_action_strength("Steer Right")
	#vehicle_node.throttle_input = pow(Input.get_action_strength("Accelerate"), 2.0)
	##vehicle_node.handbrake_input = Input.get_action_strength("Handbrake")
	##vehicle_node.clutch_input = clampf(Input.get_action_strength("Clutch") + Input.get_action_strength("Handbrake"), 0.0, 1.0)
#
	#if Input.is_action_just_pressed("Toggle Transmission"):
		#vehicle_node.automatic_transmission = !vehicle_node.automatic_transmission
	#
	#if Input.is_action_just_pressed("Headlights"):
		#vehicle_node.lights_on = !vehicle_node.lights_on
#
	##if Input.is_action_just_pressed("Shift Up"):
		##vehicle_node.manual_shift(1)
	##
	##if Input.is_action_just_pressed("Shift Down"):
		##vehicle_node.manual_shift(-1)
	#
	#if vehicle_node.current_gear == -1:
		#vehicle_node.brake_input = Input.get_action_strength("Accelerate")
		#vehicle_node.throttle_input = Input.get_action_strength("Brake or Reverse")
#
	##vehicle_node.clutch_input = 1.0 - pow(vehicle_node.throttle_input, 2.0)
#
	#if vehicle_node.ignition_on == false and vehicle_node.throttle_input > 0 and vehicle_node.current_hit_points > 0:
		#vehicle_node.ignition_on = true


#func _unhandled_input(event: InputEvent) -> void:
	#if not vehicle_node or not vehicle_node.is_being_driven:
		#return
	#if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_WHEEL_UP:
		#vehicle_node.handbrake_input = minf(vehicle_node.handbrake_input + (event.factor * handbrake_scroll_multiplier), 1.0)
	#elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
		#vehicle_node.handbrake_input = maxf(0.0, vehicle_node.handbrake_input - (event.factor * handbrake_scroll_multiplier))
	#return
