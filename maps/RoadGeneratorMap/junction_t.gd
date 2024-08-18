@tool
extends RoadContainer

var green_material := preload("res://assets/materials/raycast_debug.tres")
var red_material := preload("res://assets/materials/raycast_debug_red.tres")
@export var path_entering_RP_001: TrafficPath
@export var path_exiting_RP_001: TrafficPath
@export var path_entering_RP_002: TrafficPath
@export var path_exiting_RP_002: TrafficPath
@export var path_entering_RP_003: TrafficPath
@export var path_exiting_RP_003: TrafficPath
var green_light_energy := 5.0
var red_light_energy := 5.0
var light_fade_time := 0.2


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
  var _tween := get_tree().create_tween()
  $"TrafficPaths/TP_t_junction_1-2".is_blocked = false
  $"TrafficPaths/TP_t_junction_1-3".is_blocked = false
  _tween.tween_property($SpringyPropsManager/TrafficLightA_1/GreenLight, "light_energy", green_light_energy, light_fade_time)
  _tween.parallel().tween_property($SpringyPropsManager/TrafficLightA_1/RedLight, "light_energy", 0, light_fade_time)
  _tween.parallel().tween_property($SpringyPropsManager/TrafficLightA_2/GreenLight, "light_energy", 0.0, light_fade_time)
  _tween.parallel().tween_property($SpringyPropsManager/TrafficLightA_2/RedLight, "light_energy", red_light_energy, light_fade_time)
  $"TrafficPaths/TP_t_junction_2-1".is_blocked = true
  $"TrafficPaths/TP_t_junction_2-3".is_blocked = true
  _tween.parallel().tween_property($SpringyPropsManager/TrafficLightA_3/GreenLight, "light_energy", 0.0, light_fade_time)
  _tween.parallel().tween_property($SpringyPropsManager/TrafficLightA_3/RedLight, "light_energy", red_light_energy, light_fade_time)
  $"TrafficPaths/TP_t_junction_3-1".is_blocked = true
  $"TrafficPaths/TP_t_junction_3-2".is_blocked = true


func green_light_rp_2() -> void:
  var _tween := get_tree().create_tween()
  $"TrafficPaths/TP_t_junction_1-2".is_blocked = true
  $"TrafficPaths/TP_t_junction_1-3".is_blocked = true
  _tween.tween_property($SpringyPropsManager/TrafficLightA_1/GreenLight, "light_energy", 0.0, light_fade_time)
  _tween.parallel().tween_property($SpringyPropsManager/TrafficLightA_1/RedLight, "light_energy", red_light_energy, light_fade_time)
  $"TrafficPaths/TP_t_junction_2-1".is_blocked = false
  $"TrafficPaths/TP_t_junction_2-3".is_blocked = false
  _tween.parallel().tween_property($SpringyPropsManager/TrafficLightA_2/GreenLight, "light_energy", green_light_energy, light_fade_time)
  _tween.parallel().tween_property($SpringyPropsManager/TrafficLightA_2/RedLight, "light_energy", 0, light_fade_time)
  $"TrafficPaths/TP_t_junction_3-1".is_blocked = true
  $"TrafficPaths/TP_t_junction_3-2".is_blocked = true
  _tween.parallel().tween_property($SpringyPropsManager/TrafficLightA_3/GreenLight, "light_energy", 0.0, light_fade_time)
  _tween.parallel().tween_property($SpringyPropsManager/TrafficLightA_3/RedLight, "light_energy", red_light_energy, light_fade_time)


func green_light_rp_3() -> void:
  var _tween := get_tree().create_tween()
  $"TrafficPaths/TP_t_junction_1-2".is_blocked = true
  $"TrafficPaths/TP_t_junction_1-3".is_blocked = true
  _tween.tween_property($SpringyPropsManager/TrafficLightA_1/GreenLight, "light_energy", 0.0, light_fade_time)
  _tween.parallel().tween_property($SpringyPropsManager/TrafficLightA_1/RedLight, "light_energy", red_light_energy, light_fade_time)
  $"TrafficPaths/TP_t_junction_2-1".is_blocked = true
  $"TrafficPaths/TP_t_junction_2-3".is_blocked = true
  _tween.parallel().tween_property($SpringyPropsManager/TrafficLightA_2/GreenLight, "light_energy", 0.0, light_fade_time)
  _tween.parallel().tween_property($SpringyPropsManager/TrafficLightA_2/RedLight, "light_energy", red_light_energy, light_fade_time)
  $"TrafficPaths/TP_t_junction_3-1".is_blocked = false
  $"TrafficPaths/TP_t_junction_3-2".is_blocked = false
  _tween.parallel().tween_property($SpringyPropsManager/TrafficLightA_3/GreenLight, "light_energy", green_light_energy, light_fade_time)
  _tween.parallel().tween_property($SpringyPropsManager/TrafficLightA_3/RedLight, "light_energy", 0, light_fade_time)
