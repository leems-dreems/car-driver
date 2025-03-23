@tool
extends RoadContainer

@export_group("TrafficPath Connections")
@export var path_entering_RP_001: TrafficPath ## The TrafficPath entering RoadPoint 001
@export var path_exiting_RP_001: TrafficPath  ## The TrafficPath exiting RoadPoint 001
@export var path_entering_RP_002: TrafficPath ## The TrafficPath entering RoadPoint 002
@export var path_exiting_RP_002: TrafficPath  ## The TrafficPath exiting RoadPoint 002
@export var path_entering_RP_003: TrafficPath ## The TrafficPath entering RoadPoint 003
@export var path_exiting_RP_003: TrafficPath  ## The TrafficPath exiting RoadPoint 003
@export var path_entering_RP_004: TrafficPath ## The TrafficPath entering RoadPoint 004
@export var path_exiting_RP_004: TrafficPath  ## The TrafficPath exiting RoadPoint 004
@export_group("TrafficLightProp Connections")
## How long to wait between closing one entry point and opening another
@export var green_light_delay := 1.0
## Array of TrafficLightProps that will turn green when RoadPoint 001 is open
@export var traffic_lights_RP_001: Array[TrafficLightProp]
## Array of TrafficLightProps that will turn green when RoadPoint 002 is open
@export var traffic_lights_RP_002: Array[TrafficLightProp]
## Array of TrafficLightProps that will turn green when RoadPoint 003 is open
@export var traffic_lights_RP_003: Array[TrafficLightProp]
## Array of TrafficLightProps that will turn green when RoadPoint 004 is open
@export var traffic_lights_RP_004: Array[TrafficLightProp]


func _ready() -> void:
	if Engine.is_editor_hint():
		return

	$Label3D.visible = false
	$Label3D2.visible = false
	$Label3D3.visible = false
	$Label3D4.visible = false

	# Skip animation player forward a few seconds
	$AnimationPlayer.seek(randf_range(0, 9))

	if path_entering_RP_001:
		path_entering_RP_001.next_traffic_paths.push_back($"TrafficPaths/TP_4_junction_1-2")
		path_entering_RP_001.next_traffic_paths.push_back($"TrafficPaths/TP_4_junction_1-3")
		path_entering_RP_001.next_traffic_paths.push_back($"TrafficPaths/TP_4_junction_1-4")
	if path_exiting_RP_001:
		$"TrafficPaths/TP_4_junction_2-1".next_traffic_paths.push_back(path_exiting_RP_001)
		$"TrafficPaths/TP_4_junction_3-1".next_traffic_paths.push_back(path_exiting_RP_001)
		$"TrafficPaths/TP_4_junction_4-1".next_traffic_paths.push_back(path_exiting_RP_001)
	if path_entering_RP_002:
		path_entering_RP_002.next_traffic_paths.push_back($"TrafficPaths/TP_4_junction_2-1")
		path_entering_RP_002.next_traffic_paths.push_back($"TrafficPaths/TP_4_junction_2-3")
		path_entering_RP_002.next_traffic_paths.push_back($"TrafficPaths/TP_4_junction_2-4")
	if path_exiting_RP_002:
		$"TrafficPaths/TP_4_junction_1-2".next_traffic_paths.push_back(path_exiting_RP_002)
		$"TrafficPaths/TP_4_junction_3-2".next_traffic_paths.push_back(path_exiting_RP_002)
		$"TrafficPaths/TP_4_junction_4-2".next_traffic_paths.push_back(path_exiting_RP_002)
	if path_entering_RP_003:
		path_entering_RP_003.next_traffic_paths.push_back($"TrafficPaths/TP_4_junction_3-1")
		path_entering_RP_003.next_traffic_paths.push_back($"TrafficPaths/TP_4_junction_3-2")
		path_entering_RP_003.next_traffic_paths.push_back($"TrafficPaths/TP_4_junction_3-4")
	if path_exiting_RP_003:
		$"TrafficPaths/TP_4_junction_1-3".next_traffic_paths.push_back(path_exiting_RP_003)
		$"TrafficPaths/TP_4_junction_2-3".next_traffic_paths.push_back(path_exiting_RP_003)
		$"TrafficPaths/TP_4_junction_4-3".next_traffic_paths.push_back(path_exiting_RP_003)
	if path_entering_RP_004:
		path_entering_RP_004.next_traffic_paths.push_back($"TrafficPaths/TP_4_junction_4-1")
		path_entering_RP_004.next_traffic_paths.push_back($"TrafficPaths/TP_4_junction_4-2")
		path_entering_RP_004.next_traffic_paths.push_back($"TrafficPaths/TP_4_junction_4-3")
	if path_exiting_RP_004:
		$"TrafficPaths/TP_4_junction_1-4".next_traffic_paths.push_back(path_exiting_RP_004)
		$"TrafficPaths/TP_4_junction_2-4".next_traffic_paths.push_back(path_exiting_RP_004)
		$"TrafficPaths/TP_4_junction_3-4".next_traffic_paths.push_back(path_exiting_RP_004)


func green_light_rp_1() -> void:
	$"TrafficPaths/TP_4_junction_2-1".is_blocked = true
	$"TrafficPaths/TP_4_junction_2-3".is_blocked = true
	$"TrafficPaths/TP_4_junction_2-4".is_blocked = true
	$"TrafficPaths/TP_4_junction_3-1".is_blocked = true
	$"TrafficPaths/TP_4_junction_3-2".is_blocked = true
	$"TrafficPaths/TP_4_junction_3-4".is_blocked = true
	$"TrafficPaths/TP_4_junction_4-1".is_blocked = true
	$"TrafficPaths/TP_4_junction_4-2".is_blocked = true
	$"TrafficPaths/TP_4_junction_4-3".is_blocked = true
	for _traffic_light in traffic_lights_RP_002:
		_traffic_light.red_light()
	for _traffic_light in traffic_lights_RP_003:
		_traffic_light.red_light()
	for _traffic_light in traffic_lights_RP_004:
		_traffic_light.red_light()

	await get_tree().create_timer(green_light_delay).timeout
	$"TrafficPaths/TP_4_junction_1-2".is_blocked = false
	$"TrafficPaths/TP_4_junction_1-3".is_blocked = false
	$"TrafficPaths/TP_4_junction_1-4".is_blocked = false
	for _traffic_light in traffic_lights_RP_001:
		_traffic_light.green_light()
	return


func green_light_rp_2() -> void:
	$"TrafficPaths/TP_4_junction_1-2".is_blocked = true
	$"TrafficPaths/TP_4_junction_1-3".is_blocked = true
	$"TrafficPaths/TP_4_junction_1-4".is_blocked = true
	$"TrafficPaths/TP_4_junction_3-1".is_blocked = true
	$"TrafficPaths/TP_4_junction_3-2".is_blocked = true
	$"TrafficPaths/TP_4_junction_3-4".is_blocked = true
	$"TrafficPaths/TP_4_junction_4-1".is_blocked = true
	$"TrafficPaths/TP_4_junction_4-2".is_blocked = true
	$"TrafficPaths/TP_4_junction_4-3".is_blocked = true
	for _traffic_light in traffic_lights_RP_001:
		_traffic_light.red_light()
	for _traffic_light in traffic_lights_RP_003:
		_traffic_light.red_light()
	for _traffic_light in traffic_lights_RP_004:
		_traffic_light.red_light()

	await get_tree().create_timer(green_light_delay).timeout
	$"TrafficPaths/TP_4_junction_2-1".is_blocked = false
	$"TrafficPaths/TP_4_junction_2-3".is_blocked = false
	$"TrafficPaths/TP_4_junction_2-4".is_blocked = false
	for _traffic_light in traffic_lights_RP_002:
		_traffic_light.green_light()
	return


func green_light_rp_3() -> void:
	$"TrafficPaths/TP_4_junction_1-2".is_blocked = true
	$"TrafficPaths/TP_4_junction_1-3".is_blocked = true
	$"TrafficPaths/TP_4_junction_1-4".is_blocked = true
	$"TrafficPaths/TP_4_junction_2-1".is_blocked = true
	$"TrafficPaths/TP_4_junction_2-3".is_blocked = true
	$"TrafficPaths/TP_4_junction_2-4".is_blocked = true
	$"TrafficPaths/TP_4_junction_4-1".is_blocked = true
	$"TrafficPaths/TP_4_junction_4-2".is_blocked = true
	$"TrafficPaths/TP_4_junction_4-3".is_blocked = true
	for _traffic_light in traffic_lights_RP_001:
		_traffic_light.red_light()
	for _traffic_light in traffic_lights_RP_002:
		_traffic_light.red_light()
	for _traffic_light in traffic_lights_RP_004:
		_traffic_light.red_light()

	await get_tree().create_timer(green_light_delay).timeout
	$"TrafficPaths/TP_4_junction_3-1".is_blocked = false
	$"TrafficPaths/TP_4_junction_3-2".is_blocked = false
	$"TrafficPaths/TP_4_junction_3-4".is_blocked = false
	for _traffic_light in traffic_lights_RP_003:
		_traffic_light.green_light()
	return


func green_light_rp_4() -> void:
	$"TrafficPaths/TP_4_junction_1-2".is_blocked = true
	$"TrafficPaths/TP_4_junction_1-3".is_blocked = true
	$"TrafficPaths/TP_4_junction_1-4".is_blocked = true
	$"TrafficPaths/TP_4_junction_2-1".is_blocked = true
	$"TrafficPaths/TP_4_junction_2-3".is_blocked = true
	$"TrafficPaths/TP_4_junction_2-4".is_blocked = true
	$"TrafficPaths/TP_4_junction_3-1".is_blocked = true
	$"TrafficPaths/TP_4_junction_3-2".is_blocked = true
	$"TrafficPaths/TP_4_junction_3-4".is_blocked = true
	for _traffic_light in traffic_lights_RP_001:
		_traffic_light.red_light()
	for _traffic_light in traffic_lights_RP_002:
		_traffic_light.red_light()
	for _traffic_light in traffic_lights_RP_003:
		_traffic_light.red_light()

	await get_tree().create_timer(green_light_delay).timeout
	$"TrafficPaths/TP_4_junction_4-1".is_blocked = false
	$"TrafficPaths/TP_4_junction_4-2".is_blocked = false
	$"TrafficPaths/TP_4_junction_4-3".is_blocked = false
	for _traffic_light in traffic_lights_RP_004:
		_traffic_light.green_light()
	return
