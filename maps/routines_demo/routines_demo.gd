extends "res://maps/common/playable_map.gd"

var current_car_index: int = 0
var cars: Array[DriveableVehicle] = []

func _ready() -> void:
	super()

	Game.set_current_time(0675) # 06:45
	Game.time_speed = 5.0

	cars.push_back($VehicleContainer/CompactCar)
	cars.push_back($VehicleContainer/CompactCar2)
	cars.push_back($VehicleContainer/CompactCar3)
	cars.push_back($VehicleContainer/CompactCar4)
	cars.push_back($VehicleContainer/CompactCar5)
	cars.push_back($VehicleContainer/CompactCar6)
	cars.push_back($VehicleContainer/CompactCar7)
	cars.push_back($VehicleContainer/CompactCar8)
	cars.push_back($VehicleContainer/CompactCar9)
	cars.push_back($VehicleContainer/CompactCar10)
	return


func _physics_process(delta: float) -> void:
	var vehicle := cars[current_car_index]
	if vehicle.astar_road_agent and len(vehicle.astar_road_agent.id_path) > 0:
		vehicle.set_inputs()
	current_car_index += 1
	if current_car_index > len(cars) - 1:
		current_car_index = 0
	return
