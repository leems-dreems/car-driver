@tool
extends RoadContainer

@export var path_entering_RP_001: TrafficPath
@export var path_exiting_RP_001: TrafficPath
@export var path_entering_RP_002: TrafficPath
@export var path_exiting_RP_002: TrafficPath
@export var path_entering_RP_003: TrafficPath
@export var path_exiting_RP_003: TrafficPath


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
