@tool
extends RoadContainer

@export_group("TrafficPath Connections")
@export var path_entering_RP_001: TrafficPath ## The TrafficPath entering RoadPoint 001
@export var path_exiting_RP_001: TrafficPath  ## The TrafficPath exiting RoadPoint 001
@export var path_entering_RP_002: TrafficPath ## The TrafficPath entering RoadPoint 002
@export var path_exiting_RP_002: TrafficPath  ## The TrafficPath exiting RoadPoint 002
@export var path_entering_RP_003: TrafficPath ## The TrafficPath entering RoadPoint 003
@export var path_exiting_RP_003: TrafficPath  ## The TrafficPath exiting RoadPoint 003
@export_group("TrafficLightProp Connections")
## Array of TrafficLightProps that will turn green when RoadPoint 001 is open
@export var traffic_lights_RP_001: Array[TrafficLightProp]
## Array of TrafficLightProps that will turn green when RoadPoint 002 is open
@export var traffic_lights_RP_002: Array[TrafficLightProp]
## Array of TrafficLightProps that will turn green when RoadPoint 003 is open
@export var traffic_lights_RP_003: Array[TrafficLightProp]


func _ready() -> void:
  if Engine.is_editor_hint():
    return

  path_entering_RP_001.next_traffic_paths.push_back($"TrafficPaths/TP_t_junction_1-2")
  path_entering_RP_001.next_traffic_paths.push_back($"TrafficPaths/TP_t_junction_1-3")
  $"TrafficPaths/TP_t_junction_3-1".next_traffic_paths.push_back(path_exiting_RP_001)
  $"TrafficPaths/TP_t_junction_2-1".next_traffic_paths.push_back(path_exiting_RP_001)
  path_entering_RP_002.next_traffic_paths.push_back($"TrafficPaths/TP_t_junction_2-1")
  path_entering_RP_002.next_traffic_paths.push_back($"TrafficPaths/TP_t_junction_2-3")
  $"TrafficPaths/TP_t_junction_3-2".next_traffic_paths.push_back(path_exiting_RP_002)
  $"TrafficPaths/TP_t_junction_1-2".next_traffic_paths.push_back(path_exiting_RP_002)
  path_entering_RP_003.next_traffic_paths.push_back($"TrafficPaths/TP_t_junction_3-1")
  path_entering_RP_003.next_traffic_paths.push_back($"TrafficPaths/TP_t_junction_3-2")
  $"TrafficPaths/TP_t_junction_1-3".next_traffic_paths.push_back(path_exiting_RP_003)
  $"TrafficPaths/TP_t_junction_2-3".next_traffic_paths.push_back(path_exiting_RP_003)


func green_light_rp_1() -> void:
  $"TrafficPaths/TP_t_junction_1-2".is_blocked = false
  $"TrafficPaths/TP_t_junction_1-3".is_blocked = false
  $"TrafficPaths/TP_t_junction_2-1".is_blocked = true
  $"TrafficPaths/TP_t_junction_2-3".is_blocked = true
  $"TrafficPaths/TP_t_junction_3-1".is_blocked = true
  $"TrafficPaths/TP_t_junction_3-2".is_blocked = true
  for _traffic_light in traffic_lights_RP_001:
    _traffic_light.green_light()
  for _traffic_light in traffic_lights_RP_002:
    _traffic_light.red_light()
  for _traffic_light in traffic_lights_RP_003:
    _traffic_light.red_light()


func green_light_rp_2() -> void:
  $"TrafficPaths/TP_t_junction_1-2".is_blocked = true
  $"TrafficPaths/TP_t_junction_1-3".is_blocked = true
  $"TrafficPaths/TP_t_junction_2-1".is_blocked = false
  $"TrafficPaths/TP_t_junction_2-3".is_blocked = false
  $"TrafficPaths/TP_t_junction_3-1".is_blocked = true
  $"TrafficPaths/TP_t_junction_3-2".is_blocked = true
  for _traffic_light in traffic_lights_RP_001:
    _traffic_light.red_light()
  for _traffic_light in traffic_lights_RP_002:
    _traffic_light.green_light()
  for _traffic_light in traffic_lights_RP_003:
    _traffic_light.red_light()


func green_light_rp_3() -> void:
  $"TrafficPaths/TP_t_junction_1-2".is_blocked = true
  $"TrafficPaths/TP_t_junction_1-3".is_blocked = true
  $"TrafficPaths/TP_t_junction_2-1".is_blocked = true
  $"TrafficPaths/TP_t_junction_2-3".is_blocked = true
  $"TrafficPaths/TP_t_junction_3-1".is_blocked = false
  $"TrafficPaths/TP_t_junction_3-2".is_blocked = false
  for _traffic_light in traffic_lights_RP_001:
    _traffic_light.red_light()
  for _traffic_light in traffic_lights_RP_002:
    _traffic_light.red_light()
  for _traffic_light in traffic_lights_RP_003:
    _traffic_light.green_light()
