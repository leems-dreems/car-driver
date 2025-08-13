extends "res://maps/common/playable_map.gd"

## Number of in-game minutes between each time_changed signal being emitted.
## Make sure that DailyRoutines match up with this interval.
@export var time_interval: int = 10

var current_car_index: int = 0
var cars: Array[DriveableVehicle] = []

func _ready() -> void:
	super()

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

	setup_day_night_animation(59)
	return


func _physics_process(delta: float) -> void:
	var vehicle := cars[current_car_index]
	vehicle.set_inputs()
	current_car_index += 1
	if current_car_index > len(cars) - 1:
		current_car_index = 0
	return


## This function mainly exists so that the day/night animation can call it
func set_current_time(current_time: int) -> void:
	Game.set_current_time(current_time)
	return


## Add keys to the day/night animation's method track to update the game time.
## Using the Animation editor, add an example key to the method track at the
## start of the animation so that this method has something to copy.
func setup_day_night_animation(start_time: float = 0.0) -> void:
	# Get or create the animation the target method will be called from.
	var animation: Animation = $DirectionalLight3D/AnimationPlayer.get_animation("day_night_cycle")
	# Get or create the target method's animation track.
	var track_index := animation.add_track(Animation.TYPE_METHOD)
	# Set scene-tree path to node with target method.
	animation.track_set_path(track_index, get_path())

	for i in range(0, roundi(1440 / time_interval)): # 1440 minutes in a day
		# Get or create a dictionary with the target method's name and arguments.
		var method_dictionary := {
			"method": "set_current_time",
			"args": [roundi((i * time_interval) * 1.6666666666)],
		}
		# Add the dictionary as the animation method track's key.
		var key_time := 0.0
		if i > 0:
			key_time = animation.length / (1440 / time_interval) * i
		animation.track_insert_key(track_index, key_time, method_dictionary, 0)
		prints(i, key_time)

	print(str(animation.track_get_key_count(track_index)))

	$DirectionalLight3D/AnimationPlayer.play("day_night_cycle")
	$DirectionalLight3D/AnimationPlayer.seek(start_time)
	return
